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

/// String interning pool for per-document string deduplication.
///
/// Stores commonly used strings (tag names, attribute names, etc.) to reduce
/// memory usage. Strings are freed when the document is destroyed.
pub const StringPool = struct {
    /// Common HTML element tag names (compile-time constants)
    pub const Common = struct {
        // Most common HTML tags
        pub const div = "div";
        pub const span = "span";
        pub const p = "p";
        pub const a = "a";
        pub const img = "img";
        pub const input = "input";
        pub const button = "button";
        pub const form = "form";
        pub const table = "table";
        pub const tr = "tr";
        pub const td = "td";
        pub const th = "th";
        pub const ul = "ul";
        pub const ol = "ol";
        pub const li = "li";
        pub const h1 = "h1";
        pub const h2 = "h2";
        pub const h3 = "h3";
        pub const h4 = "h4";
        pub const h5 = "h5";
        pub const h6 = "h6";
        pub const section = "section";
        pub const article = "article";
        pub const header = "header";
        pub const footer = "footer";
        pub const nav = "nav";
        pub const main = "main";
        pub const aside = "aside";

        // Common attributes
        pub const id = "id";
        pub const class = "class";
        pub const style = "style";
        pub const href = "href";
        pub const src = "src";
        pub const @"type" = "type";
        pub const value = "value";
        pub const name = "name";
        pub const title = "title";
        pub const alt = "alt";
        pub const data = "data";
    };

    /// Runtime interned strings (for rare/custom strings)
    rare_strings: std.StringHashMap([]const u8),
    allocator: Allocator,

    pub fn init(allocator: Allocator) StringPool {
        return .{
            .rare_strings = std.StringHashMap([]const u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *StringPool) void {
        // Free all rare strings
        var it = self.rare_strings.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.value_ptr.*);
        }
        self.rare_strings.deinit();
    }

    /// Interns a string, returning a pointer to the canonical copy.
    ///
    /// Fast path: Check common strings first (comptime, no hash lookup)
    /// Slow path: Check rare strings hash table
    ///
    /// ## Returns
    /// Pointer to interned string (valid until document destroyed)
    pub fn intern(self: *StringPool, str: []const u8) ![]const u8 {
        // Fast path: check common strings (comptime iteration, no runtime cost)
        inline for (comptime std.meta.declarations(Common)) |decl| {
            const value = @field(Common, decl.name);
            if (std.mem.eql(u8, str, value)) {
                return value; // Return comptime constant
            }
        }

        // Slow path: rare strings (hash table)
        const result = try self.rare_strings.getOrPut(str);
        if (!result.found_existing) {
            // New string, duplicate and store
            result.value_ptr.* = try self.allocator.dupe(u8, str);
        }
        return result.value_ptr.*;
    }

    /// Returns the number of rare (non-common) strings interned.
    pub fn rareStringCount(self: *const StringPool) usize {
        return self.rare_strings.count();
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

            if (external_refs == 0) {
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

    // === Private implementation ===

    /// Allocates the next available node ID.
    fn allocateNodeId(self: *Document) u16 {
        const id = self.next_node_id;
        self.next_node_id +%= 1; // Wrapping add (unlikely to overflow)
        return id;
    }

    /// Clears internal references when external refs reach 0 but nodes still exist.
    fn clearInternalReferences(self: *Document) void {
        // TODO: Walk tree and clear ownerDocument pointers
        // For now, nodes will hold references until they're destroyed
        _ = self;
    }

    /// Internal cleanup (called when both ref counts reach 0).
    /// Recursively clears owner_document for node and all descendants.
    /// Used during document destruction to prevent circular references.
    fn clearOwnerDocumentRecursive(node: *Node) void {
        node.owner_document = null;
        var current = node.first_child;
        while (current) |child| {
            clearOwnerDocumentRecursive(child);
            current = child.next_sibling;
        }
    }

    fn deinitInternal(self: *Document) void {
        // Clean up rare data if allocated
        self.node.deinitRareData();

        // Destroy all children (first clear owner_document recursively to avoid circular refs)
        var current = self.node.first_child;
        while (current) |child| {
            clearOwnerDocumentRecursive(child);
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

test "StringPool - common strings" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Intern common strings (should use comptime constants)
    const div1 = try pool.intern("div");
    const div2 = try pool.intern("div");

    // Should return same pointer (comptime constant)
    try std.testing.expectEqual(div1.ptr, div2.ptr);
    try std.testing.expectEqualStrings("div", div1);

    // Multiple common strings
    const span = try pool.intern("span");
    const class = try pool.intern("class");
    try std.testing.expectEqualStrings("span", span);
    try std.testing.expectEqualStrings("class", class);

    // No rare strings allocated
    try std.testing.expectEqual(@as(usize, 0), pool.rareStringCount());
}

test "StringPool - rare strings" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Intern custom element name (rare)
    const custom1 = try pool.intern("my-custom-element");
    const custom2 = try pool.intern("my-custom-element");

    // Should return same pointer (from hash table)
    try std.testing.expectEqual(custom1.ptr, custom2.ptr);
    try std.testing.expectEqualStrings("my-custom-element", custom1);

    // One rare string allocated
    try std.testing.expectEqual(@as(usize, 1), pool.rareStringCount());

    // Another rare string
    _ = try pool.intern("another-custom");
    try std.testing.expectEqual(@as(usize, 2), pool.rareStringCount());
}

test "StringPool - mixed common and rare" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Mix of common and rare
    const div = try pool.intern("div");
    const custom = try pool.intern("custom-element");
    const span = try pool.intern("span");

    try std.testing.expectEqualStrings("div", div);
    try std.testing.expectEqualStrings("custom-element", custom);
    try std.testing.expectEqualStrings("span", span);

    // Only rare string allocated
    try std.testing.expectEqual(@as(usize, 1), pool.rareStringCount());
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
    const elem = try doc.createElement("div");
    defer elem.node.release();

    // Verify element properties
    try std.testing.expectEqualStrings("div", elem.tag_name);
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

test "Document - string interning in createElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create multiple elements with same tag
    const div1 = try doc.createElement("div");
    defer div1.node.release();

    const div2 = try doc.createElement("div");
    defer div2.node.release();

    // Tag names should point to same interned string
    try std.testing.expectEqual(div1.tag_name.ptr, div2.tag_name.ptr);

    // No rare strings should be allocated (div is common)
    try std.testing.expectEqual(@as(usize, 0), doc.string_pool.rareStringCount());
}

test "Document - multiple node types" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create various nodes
    const elem = try doc.createElement("div");
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

        const elem1 = try doc.createElement("div");
        defer elem1.node.release();

        const elem2 = try doc.createElement("span");
        defer elem2.node.release();
    }

    // Test 3: Document with all node types
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const elem = try doc.createElement("div");
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

        // Common strings
        const div1 = try doc.createElement("div");
        defer div1.node.release();

        const span = try doc.createElement("span");
        defer span.node.release();

        const div2 = try doc.createElement("div"); // Reuse interned
        defer div2.node.release();

        // Custom element (rare string)
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
    const html = try doc.createElement("html");
    defer html.node.release();

    // Manually add to document children
    doc.node.first_child = &html.node;
    doc.node.last_child = &html.node;
    html.node.parent_node = &doc.node;
    html.node.setHasParent(true);

    // documentElement should return the html element
    const root = doc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqual(html, root.?);
    try std.testing.expectEqualStrings("html", root.?.tag_name);

    // Clean up manual connection
    doc.node.first_child = null;
    doc.node.last_child = null;
    html.node.parent_node = null;
    html.node.setHasParent(false);
}

test "Document - documentElement with mixed children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create comment (before html)
    const comment = try doc.createComment(" DOCTYPE ");
    defer comment.node.release();

    // Create html element
    const html = try doc.createElement("html");
    defer html.node.release();

    // Manually add both to document (comment first, then html)
    doc.node.first_child = &comment.node;
    doc.node.last_child = &html.node;
    comment.node.next_sibling = &html.node;
    comment.node.parent_node = &doc.node;
    html.node.parent_node = &doc.node;
    html.node.setHasParent(true);
    comment.node.setHasParent(true);

    // documentElement should skip comment and return html
    const root = doc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqual(html, root.?);

    // Clean up manual connections
    doc.node.first_child = null;
    doc.node.last_child = null;
    comment.node.next_sibling = null;
    comment.node.parent_node = null;
    html.node.parent_node = null;
    html.node.setHasParent(false);
    comment.node.setHasParent(false);
}
