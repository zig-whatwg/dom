//! Document node implementation - root of the DOM tree.
//!
//! This module implements the WHATWG DOM Document interface with:
//! - Dual reference counting (external refs + node refs)
//! - String interning pool (per-document)
//! - Node factory methods (createElement, createTextNode, createComment)
//! - Document-level indexes (ID map, tag lists - future)
//! - Owner document tracking for all child nodes
//!
//! Spec: WHATWG DOM §4.10 (https://dom.spec.whatwg.org/#interface-document)

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;
const Element = @import("element.zig").Element;
const Text = @import("text.zig").Text;
const Comment = @import("comment.zig").Comment;
const DocumentFragment = @import("document_fragment.zig").DocumentFragment;

/// String interning pool for per-document string deduplication.
///
/// Stores strings (tag names, attribute names, etc.) to reduce memory usage
/// through deduplication. Strings are freed when the document is destroyed.
///
/// HTML-specific optimizations (e.g., common tag name pools) should be
/// implemented in the HTML library, not here.
pub const StringPool = struct {
    /// Interned strings hash map
    strings: std.StringHashMap([]const u8),
    allocator: Allocator,

    pub fn init(allocator: Allocator) StringPool {
        return .{
            .strings = std.StringHashMap([]const u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *StringPool) void {
        // Free all interned strings
        var it = self.strings.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
        self.strings.deinit();
    }

    /// Interns a string, returning a pointer to the canonical copy.
    ///
    /// If the string has already been interned, returns the existing copy.
    /// Otherwise, duplicates the string and stores it in the pool.
    ///
    /// ## Returns
    /// Pointer to interned string (valid until document destroyed)
    pub fn intern(self: *StringPool, str: []const u8) ![]const u8 {
        const result = try self.strings.getOrPut(str);
        if (!result.found_existing) {
            // New string, duplicate and store
            result.value_ptr.* = try self.allocator.dupe(u8, str);
        }
        return result.value_ptr.*;
    }

    /// Returns the number of strings currently interned.
    pub fn count(self: *const StringPool) usize {
        return self.strings.count();
    }
};

/// Document node - root of the DOM tree.
///
/// Uses dual reference counting to handle two types of ownership:
/// 1. External references (from application code)
/// 2. Internal node references (from nodes with ownerDocument=this)
///
/// Document remains alive while EITHER count > 0.
pub const Document = struct {
    /// Base Node (MUST be first field for @fieldParentPtr)
    node: Node,

    /// External reference count (from application code)
    /// Atomic for thread safety
    external_ref_count: std.atomic.Value(usize),

    /// Internal reference count (from nodes with ownerDocument=this)
    /// Atomic for thread safety
    node_ref_count: std.atomic.Value(usize),

    /// String interning pool (per-document)
    string_pool: StringPool,

    /// Next node ID to assign
    next_node_id: u16,

    /// Flag to prevent reentrant destruction during cleanup
    /// When true, releaseNodeRef() should not trigger deinitInternal()
    is_destroying: bool,

    /// Vtable for Document nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
    };

    /// Creates a new Document.
    ///
    /// ## Memory Management
    /// Returns Document with external_ref_count=1. Caller MUST call `doc.release()`.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for document and all child nodes
    ///
    /// ## Returns
    /// New document with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const elem = try doc.createElement("div");
    /// defer elem.node.release();
    /// ```
    pub fn init(allocator: Allocator) !*Document {
        const doc = try allocator.create(Document);
        errdefer allocator.destroy(doc);

        // Initialize string pool
        const string_pool = StringPool.init(allocator);
        errdefer string_pool.deinit();

        // Initialize base Node
        doc.node = .{
            .vtable = &vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .document,
            .flags = Node.FLAG_IS_CONNECTED, // Document is always connected
            .node_id = 0,
            .generation = 0,
            .allocator = allocator,
            .parent_node = null,
            .previous_sibling = null,
            .first_child = null,
            .last_child = null,
            .next_sibling = null,
            .owner_document = &doc.node, // Document owns itself
            .rare_data = null,
        };

        // Initialize Document-specific fields
        doc.external_ref_count = std.atomic.Value(usize).init(1);
        doc.node_ref_count = std.atomic.Value(usize).init(0);
        doc.string_pool = string_pool;
        doc.next_node_id = 1; // 0 reserved for document itself
        doc.is_destroying = false;

        return doc;
    }

    /// Increments the external reference count.
    ///
    /// Call this when sharing ownership from application code.
    pub fn acquire(self: *Document) void {
        _ = self.external_ref_count.fetchAdd(1, .monotonic);
    }

    /// Decrements the external reference count.
    ///
    /// When external_ref_count reaches 0:
    /// - If node_ref_count=0: Document is destroyed
    /// - If node_ref_count>0: Internal references cleared, awaiting node cleanup
    pub fn release(self: *Document) void {
        const old = self.external_ref_count.fetchSub(1, .monotonic);

        if (old == 1) {
            // External refs reached 0
            const node_refs = self.node_ref_count.load(.monotonic);

            if (node_refs == 0) {
                // No internal refs either, destroy now
                self.deinitInternal();
            } else {
                // Internal refs exist, clear references and wait for nodes to clean up
                self.clearInternalReferences();
            }
        }
    }

    /// Increments the internal node reference count.
    ///
    /// Called when a node sets ownerDocument=this.
    /// Internal use only, not exposed in public API.
    fn acquireNodeRef(self: *Document) void {
        _ = self.node_ref_count.fetchAdd(1, .monotonic);
    }

    /// Decrements the internal node reference count.
    ///
    /// Called when a node with ownerDocument=this is destroyed.
    /// PUBLIC for nodes to call during cleanup.
    pub fn releaseNodeRef(self: *Document) void {
        const old = self.node_ref_count.fetchSub(1, .monotonic);

        if (old == 1) {
            // Internal refs reached 0
            const external_refs = self.external_ref_count.load(.monotonic);

            // Only destroy if not already in the middle of destruction
            // (prevents reentrant destruction during clearInternalReferences)
            if (external_refs == 0 and !self.is_destroying) {
                // No external refs either, destroy now
                self.deinitInternal();
            }
        }
    }

    /// Creates a new element with the specified tag name.
    ///
    /// Tag name is automatically interned via the document's string pool.
    ///
    /// ## Parameters
    /// - `tag_name`: Element tag name (e.g., "div", "span")
    ///
    /// ## Returns
    /// New element with ref_count=1, ownerDocument=this
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate element
    pub fn createElement(self: *Document, tag_name: []const u8) !*Element {
        // Intern tag name via string pool
        const interned_tag = try self.string_pool.intern(tag_name);

        // Create element
        const elem = try Element.create(self.node.allocator, interned_tag);
        errdefer elem.node.release();

        // Set owner document and assign node ID
        elem.node.owner_document = &self.node;
        elem.node.node_id = self.allocateNodeId();

        // Increment document's node ref count
        self.acquireNodeRef();

        return elem;
    }

    /// Creates a new text node with the specified content.
    ///
    /// ## Parameters
    /// - `data`: Text content
    ///
    /// ## Returns
    /// New text node with ref_count=1, ownerDocument=this
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate text node
    pub fn createTextNode(self: *Document, data: []const u8) !*Text {
        const text = try Text.create(self.node.allocator, data);
        errdefer text.node.release();

        // Set owner document and assign node ID
        text.node.owner_document = &self.node;
        text.node.node_id = self.allocateNodeId();

        // Increment document's node ref count
        self.acquireNodeRef();

        return text;
    }

    /// Creates a new comment node with the specified content.
    ///
    /// ## Parameters
    /// - `data`: Comment content
    ///
    /// ## Returns
    /// New comment node with ref_count=1, ownerDocument=this
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate comment node
    pub fn createComment(self: *Document, data: []const u8) !*Comment {
        const comment = try Comment.create(self.node.allocator, data);
        errdefer comment.node.release();

        // Set owner document and assign node ID
        comment.node.owner_document = &self.node;
        comment.node.node_id = self.allocateNodeId();

        // Increment document's node ref count
        self.acquireNodeRef();

        return comment;
    }

    /// Creates a new DocumentFragment node owned by this document.
    ///
    /// Implements WHATWG DOM Document.createDocumentFragment() per §4.10.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] DocumentFragment createDocumentFragment();
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.10)
    /// Create a new DocumentFragment node with its node document set to this.
    ///
    /// ## Memory Management
    /// Returns DocumentFragment with ref_count=1. Caller MUST call `fragment.node.release()`.
    ///
    /// ## Returns
    /// New document fragment owned by this document
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-document-createdocumentfragment
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:519
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const fragment = try doc.createDocumentFragment();
    /// defer fragment.node.release();
    ///
    /// // Add elements to fragment
    /// const elem1 = try doc.createElement("div");
    /// const elem2 = try doc.createElement("span");
    /// _ = try fragment.node.appendChild(&elem1.node);
    /// _ = try fragment.node.appendChild(&elem2.node);
    ///
    /// // Insert fragment into document (moves children)
    /// _ = try doc.node.appendChild(&fragment.node);
    /// ```
    pub fn createDocumentFragment(self: *Document) !*DocumentFragment {
        const fragment = try DocumentFragment.create(self.node.allocator);
        errdefer fragment.node.release();

        // Set owner document and assign node ID
        fragment.node.owner_document = &self.node;
        fragment.node.node_id = self.allocateNodeId();

        // Increment document's node ref count
        self.acquireNodeRef();

        return fragment;
    }

    /// Returns the document element (root element) of the document.
    ///
    /// Implements WHATWG DOM Document.documentElement property.
    /// Returns the first Element child of the document (typically <html>).
    ///
    /// ## Returns
    /// Root element or null if no element children exist
    ///
    /// ## Example
    /// ```zig
    /// if (doc.documentElement()) |root| {
    ///     std.debug.print("Root element: {s}\n", .{root.tag_name});
    /// }
    /// ```
    pub fn documentElement(self: *const Document) ?*Element {
        // Walk children looking for first element
        var current = self.node.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                return @fieldParentPtr("node", node);
            }
            current = node.next_sibling;
        }
        return null;
    }

    /// Returns the document's DocumentType node.
    ///
    /// Implements WHATWG DOM Document.doctype property per §4.10.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute DocumentType? doctype;
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.10)
    /// Return the first DocumentType node child of this document, or null if none exists.
    ///
    /// ## Returns
    /// The document's DocumentType node, or null if no doctype is present
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-document-doctype
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:512
    ///
    /// ## Note
    /// Currently returns null. Full implementation requires DocumentType struct.
    /// When DocumentType is implemented, this will search children for the doctype node.
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// if (doc.doctype()) |dt| {
    ///     std.debug.print("Doctype: {s}\n", .{dt.name});
    /// }
    /// ```
    pub fn doctype(self: *const Document) ?*Node {
        // TODO: Full implementation requires DocumentType struct
        // For now, search for DocumentType node among children
        var current = self.node.first_child;
        while (current) |node| {
            if (node.node_type == .document_type) {
                return node;
            }
            current = node.next_sibling;
        }
        return null;
    }

    // === Private implementation ===

    /// Allocates the next available node ID.
    fn allocateNodeId(self: *Document) u16 {
        const id = self.next_node_id;
        self.next_node_id +%= 1; // Wrapping add (unlikely to overflow)
        return id;
    }

    /// Clears internal references when external refs reach 0 but nodes still exist.
    fn clearInternalReferences(self: *Document) void {
        // External refs reached 0, but internal node refs still exist.
        // Destroy all children to trigger their releaseNodeRef() calls.

        // Set flag to prevent reentrant destruction
        self.is_destroying = true;

        // Release all children (this will trigger deinit which calls releaseNodeRef)
        // NOTE: We DON'T clear owner_document before releasing because Element.deinitImpl
        // needs to see owner_document to call releaseNodeRef(). The circular reference
        // is handled by the dual ref counting system.
        var current = self.node.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            child.parent_node = null;
            child.setHasParent(false);
            // Release will decrement ref_count, trigger deinit, which calls releaseNodeRef
            child.release();
            current = next;
        }

        // Clear child pointers so deinitInternal doesn't try to free them again
        self.node.first_child = null;
        self.node.last_child = null;

        // All children released. Now check if we should destroy the document.
        const node_refs = self.node_ref_count.load(.monotonic);
        if (node_refs == 0) {
            // All nodes released, safe to destroy
            self.deinitInternal();
        }
    }

    /// Internal cleanup (called when both ref counts reach 0).
    /// Recursively clears owner_document for node and all descendants.
    /// Used during document destruction to prevent circular references.
    fn clearOwnerDocumentRecursive(node: *Node) void {
        node.owner_document = null;
        var current = node.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            clearOwnerDocumentRecursive(child);
            current = next;
        }
    }

    fn deinitInternal(self: *Document) void {
        // Clean up rare data if allocated
        self.node.deinitRareData();

        // Only destroy children if they haven't been freed by clearInternalReferences
        // (clearInternalReferences sets first_child to null after freeing)
        if (self.node.first_child) |_| {
            // Destroy all children (first clear owner_document recursively to avoid circular refs)
            var current = self.node.first_child;
            while (current) |child| {
                const next = child.next_sibling;
                clearOwnerDocumentRecursive(child);
                current = next;
            }

            // Now destroy all children
            current = self.node.first_child;
            while (current) |child| {
                const next = child.next_sibling;
                child.parent_node = null;
                child.setHasParent(false);
                // Call vtable deinit directly
                child.vtable.deinit(child);
                current = next;
            }
        }

        // Clean up string pool
        self.string_pool.deinit();

        // Free document structure
        self.node.allocator.destroy(self);
    }

    // === Vtable implementations ===

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const doc: *Document = @fieldParentPtr("node", node);
        doc.release();
    }

    /// Vtable implementation: node name (always "#document")
    fn nodeNameImpl(_: *const Node) []const u8 {
        return "#document";
    }

    /// Vtable implementation: node value (always null for documents)
    fn nodeValueImpl(_: *const Node) ?[]const u8 {
        return null;
    }

    /// Vtable implementation: set node value (no-op for documents)
    fn setNodeValueImpl(_: *Node, _: []const u8) !void {
        // Documents don't have node values, this is a no-op per spec
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        _ = node;
        _ = deep;
        // TODO: Implement document cloning (requires full tree clone)
        return error.NotSupported;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "StringPool - string deduplication" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Intern same string twice
    const str1 = try pool.intern("test-element");
    const str2 = try pool.intern("test-element");

    // Should return same pointer (deduplicated)
    try std.testing.expectEqual(str1.ptr, str2.ptr);
    try std.testing.expectEqualStrings("test-element", str1);

    // Only one string allocated
    try std.testing.expectEqual(@as(usize, 1), pool.count());
}

test "StringPool - multiple strings" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Intern multiple different strings
    const custom1 = try pool.intern("my-custom-element");
    const custom2 = try pool.intern("my-custom-element");

    // Should return same pointer (deduplicated)
    try std.testing.expectEqual(custom1.ptr, custom2.ptr);
    try std.testing.expectEqualStrings("my-custom-element", custom1);

    // One string allocated
    try std.testing.expectEqual(@as(usize, 1), pool.count());

    // Add another string
    _ = try pool.intern("another-element");
    try std.testing.expectEqual(@as(usize, 2), pool.count());
}

test "StringPool - multiple unique strings" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Intern multiple unique strings
    const str1 = try pool.intern("element-one");
    const str2 = try pool.intern("custom-element");
    const str3 = try pool.intern("element-three");

    try std.testing.expectEqualStrings("element-one", str1);
    try std.testing.expectEqualStrings("custom-element", str2);
    try std.testing.expectEqualStrings("element-three", str3);

    // Three unique strings allocated
    try std.testing.expectEqual(@as(usize, 3), pool.count());
}

test "Document - creation and cleanup" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.document, doc.node.node_type);
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));
    try std.testing.expectEqual(@as(usize, 0), doc.node_ref_count.load(.monotonic));

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("#document", doc.node.nodeName());
    try std.testing.expect(doc.node.nodeValue() == null);
}

test "Document - dual ref counting" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Initial external refs
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));

    // Acquire external ref
    doc.acquire();
    try std.testing.expectEqual(@as(usize, 2), doc.external_ref_count.load(.monotonic));

    // Release external ref
    doc.release();
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));
}

test "Document - createElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create element
    const elem = try doc.createElement("test-element");
    defer elem.node.release();

    // Verify element properties
    try std.testing.expectEqualStrings("test-element", elem.tag_name);
    try std.testing.expectEqual(&doc.node, elem.node.owner_document.?);
    try std.testing.expect(elem.node.node_id > 0);

    // Verify document's node ref count incremented
    try std.testing.expectEqual(@as(usize, 1), doc.node_ref_count.load(.monotonic));
}

test "Document - createTextNode" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create text node
    const text = try doc.createTextNode("Hello World");
    defer text.node.release();

    // Verify text properties
    try std.testing.expectEqualStrings("Hello World", text.data);
    try std.testing.expectEqual(&doc.node, text.node.owner_document.?);
    try std.testing.expect(text.node.node_id > 0);

    // Verify document's node ref count incremented
    try std.testing.expectEqual(@as(usize, 1), doc.node_ref_count.load(.monotonic));
}

test "Document - createComment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create comment node
    const comment = try doc.createComment(" TODO: implement ");
    defer comment.node.release();

    // Verify comment properties
    try std.testing.expectEqualStrings(" TODO: implement ", comment.data);
    try std.testing.expectEqual(&doc.node, comment.node.owner_document.?);
    try std.testing.expect(comment.node.node_id > 0);

    // Verify document's node ref count incremented
    try std.testing.expectEqual(@as(usize, 1), doc.node_ref_count.load(.monotonic));
}

test "Document - createDocumentFragment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create document fragment
    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    // Verify fragment properties
    try std.testing.expect(fragment.node.node_type == .document_fragment);
    try std.testing.expectEqualStrings("#document-fragment", fragment.node.nodeName());
    try std.testing.expectEqual(&doc.node, fragment.node.owner_document.?);
    try std.testing.expect(fragment.node.node_id > 0);

    // Verify document's node ref count incremented
    try std.testing.expectEqual(@as(usize, 1), doc.node_ref_count.load(.monotonic));
}

test "Document - createDocumentFragment with children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    // Add children to fragment
    const elem1 = try doc.createElement("div");
    const elem2 = try doc.createElement("span");

    _ = try fragment.node.appendChild(&elem1.node);
    _ = try fragment.node.appendChild(&elem2.node);

    // Verify fragment has children
    try std.testing.expect(fragment.node.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), fragment.node.childNodes().length());
}

test "Document - string interning in createElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create multiple elements with same tag
    const elem1 = try doc.createElement("test-element");
    defer elem1.node.release();

    const elem2 = try doc.createElement("test-element");
    defer elem2.node.release();

    // Tag names should point to same interned string
    try std.testing.expectEqual(elem1.tag_name.ptr, elem2.tag_name.ptr);

    // One string should be interned
    try std.testing.expectEqual(@as(usize, 1), doc.string_pool.count());
}

test "Document - multiple node types" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create various nodes
    const elem = try doc.createElement("test-element");
    defer elem.node.release();

    const text = try doc.createTextNode("content");
    defer text.node.release();

    const comment = try doc.createComment(" note ");
    defer comment.node.release();

    // All should have unique IDs
    try std.testing.expect(elem.node.node_id != text.node.node_id);
    try std.testing.expect(text.node.node_id != comment.node.node_id);
    try std.testing.expect(elem.node.node_id != comment.node.node_id);

    // All should reference document
    try std.testing.expectEqual(&doc.node, elem.node.owner_document.?);
    try std.testing.expectEqual(&doc.node, text.node.owner_document.?);
    try std.testing.expectEqual(&doc.node, comment.node.owner_document.?);

    // Document should track 3 node refs
    try std.testing.expectEqual(@as(usize, 3), doc.node_ref_count.load(.monotonic));
}

test "Document - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple document
    {
        const doc = try Document.init(allocator);
        defer doc.release();
    }

    // Test 2: Document with elements
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const elem1 = try doc.createElement("element-one");
        defer elem1.node.release();

        const elem2 = try doc.createElement("element-two");
        defer elem2.node.release();
    }

    // Test 3: Document with all node types
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const elem = try doc.createElement("test-element");
        defer elem.node.release();

        const text = try doc.createTextNode("test");
        defer text.node.release();

        const comment = try doc.createComment(" test ");
        defer comment.node.release();
    }

    // Test 4: Document with string interning
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        // Create elements with interning
        const elem1 = try doc.createElement("test-element");
        defer elem1.node.release();

        const elem2 = try doc.createElement("another-element");
        defer elem2.node.release();

        const elem3 = try doc.createElement("test-element"); // Reuse interned
        defer elem3.node.release();

        // Custom element
        const custom = try doc.createElement("my-custom-element");
        defer custom.node.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Document - external ref counting" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Initial state
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));

    // Acquire multiple times
    doc.acquire();
    doc.acquire();
    try std.testing.expectEqual(@as(usize, 3), doc.external_ref_count.load(.monotonic));

    // Release
    doc.release();
    try std.testing.expectEqual(@as(usize, 2), doc.external_ref_count.load(.monotonic));

    doc.release();
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));
}

test "Document - documentElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Initially no document element
    try std.testing.expect(doc.documentElement() == null);

    // Create and add root element (Phase 2 will do this via appendChild)
    const root_elem = try doc.createElement("root");
    defer root_elem.node.release();

    // Manually add to document children
    doc.node.first_child = &root_elem.node;
    doc.node.last_child = &root_elem.node;
    root_elem.node.parent_node = &doc.node;
    root_elem.node.setHasParent(true);

    // documentElement should return the root element
    const root = doc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqual(root_elem, root.?);
    try std.testing.expectEqualStrings("root", root.?.tag_name);

    // Clean up manual connection
    doc.node.first_child = null;
    doc.node.last_child = null;
    root_elem.node.parent_node = null;
    root_elem.node.setHasParent(false);
}

test "Document - documentElement with mixed children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create comment (before root element)
    const comment = try doc.createComment(" metadata ");
    defer comment.node.release();

    // Create root element
    const root_elem = try doc.createElement("root");
    defer root_elem.node.release();

    // Manually add both to document (comment first, then root element)
    doc.node.first_child = &comment.node;
    doc.node.last_child = &root_elem.node;
    comment.node.next_sibling = &root_elem.node;
    comment.node.parent_node = &doc.node;
    root_elem.node.parent_node = &doc.node;
    root_elem.node.setHasParent(true);
    comment.node.setHasParent(true);

    // documentElement should skip comment and return root element
    const root = doc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqual(root_elem, root.?);

    // Clean up manual connections
    doc.node.first_child = null;
    doc.node.last_child = null;
    comment.node.next_sibling = null;
    comment.node.parent_node = null;
    root_elem.node.parent_node = null;
    root_elem.node.setHasParent(false);
    comment.node.setHasParent(false);
}

test "Document - doctype property returns null (no DocumentType yet)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // No DocumentType children, so doctype() should return null
    try std.testing.expect(doc.doctype() == null);
}

test "Document - doctype property with element children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Add an element child
    const elem = try doc.createElement("html");

    _ = try doc.node.appendChild(&elem.node);

    // Still no DocumentType, should return null
    try std.testing.expect(doc.doctype() == null);
}
