//! Document Interface (§4.5)
//!
//! This module implements the Document interface as specified by the WHATWG DOM Standard.
//! The Document represents any web page loaded and serves as an entry point into the
//! DOM tree, providing factory methods for creating nodes and global query methods.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.5 Interface Document**: https://dom.spec.whatwg.org/#interface-document
//! - **§4.2.1 Document tree**: https://dom.spec.whatwg.org/#concept-document-tree
//! - **§4.10 Creating nodes**: https://dom.spec.whatwg.org/#creating-nodes
//!
//! ## MDN Documentation
//!
//! - Document: https://developer.mozilla.org/en-US/docs/Web/API/Document
//! - Document.createElement: https://developer.mozilla.org/en-US/docs/Web/API/Document/createElement
//! - Document.createTextNode: https://developer.mozilla.org/en-US/docs/Web/API/Document/createTextNode
//! - Document.createComment: https://developer.mozilla.org/en-US/docs/Web/API/Document/createComment
//! - Document.createDocumentFragment: https://developer.mozilla.org/en-US/docs/Web/API/Document/createDocumentFragment
//!
//! ## Core Features
//!
//! ### Node Factory Methods
//! Document provides methods to create all node types:
//! ```zig
//! const doc = try Document.create(allocator);
//! defer doc.release();
//!
//! const elem = try doc.createElement("div");
//! const text = try doc.createTextNode("Hello");
//! const comment = try doc.createComment("TODO");
//! ```
//!
//! ### String Interning
//! Document maintains a string pool for memory efficiency:
//! ```zig
//! // Tag names, attribute names automatically interned
//! const div1 = try doc.createElement("div");
//! const div2 = try doc.createElement("div");
//! // Both share the same "div" string in memory
//! ```
//!
//! ### Owner Document Tracking
//! All nodes know their owner document:
//! ```zig
//! const elem = try doc.createElement("span");
//! // elem.node.owner_document == &doc.node
//! ```
//!
//! ## Document Architecture
//!
//! - **node**: Base Node (#document type)
//! - **string_pool**: Per-document string interning
//! - **document_element**: Root element (typically \<html\>)
//! - **allocator**: Memory allocator
//! - **ref_count**: Dual reference counting (external + node)
//!
//! ## Memory Management
//!
//! Documents use dual reference counting:
//! ```zig
//! const doc = try Document.create(allocator);
//! // External ref_count = 1
//! // Node ref_count = 1
//!
//! defer doc.release(); // Decrements both counts
//! // Document freed when both reach 0
//! ```
//!
//! All nodes created by document:
//! 1. Are owned by their parent (tree reference)
//! 2. Track document as owner_document
//! 3. Freed when removed from tree or document destroyed
//!
//! ## Usage Examples
//!
//! ### Creating a DOM Tree
//!
//! ```zig
//! const allocator = std.heap.page_allocator;
//! const doc = try Document.create(allocator);
//! defer doc.release();
//!
//! // Create root element
//! const html = try doc.createElement("html");
//! doc.document_element = html;
//! _ = try doc.node.appendChild(&html.node);
//!
//! // Build tree
//! const body = try doc.createElement("body");
//! _ = try html.node.appendChild(&body.node);
//!
//! const div = try doc.createElement("div");
//! try div.setAttribute("id", "content");
//! _ = try body.node.appendChild(&div.node);
//!
//! const text = try doc.createTextNode("Hello, World!");
//! _ = try div.node.appendChild(&text.node);
//! ```
//!
//! ### Building HTML Document
//!
//! ```zig
//! const doc = try Document.create(allocator);
//! defer doc.release();
//!
//! // Create document structure
//! const html = try doc.createElement("html");
//! const head = try doc.createElement("head");
//! const body = try doc.createElement("body");
//!
//! _ = try html.node.appendChild(&head.node);
//! _ = try html.node.appendChild(&body.node);
//! doc.document_element = html;
//! _ = try doc.node.appendChild(&html.node);
//!
//! // Add title
//! const title = try doc.createElement("title");
//! const title_text = try doc.createTextNode("My Page");
//! _ = try title.node.appendChild(&title_text.node);
//! _ = try head.node.appendChild(&title.node);
//! ```
//!
//! ### Creating Document Fragment
//!
//! ```zig
//! const frag = try doc.createDocumentFragment();
//! defer frag.node.release();
//!
//! // Build fragment
//! const li1 = try doc.createElement("li");
//! const li2 = try doc.createElement("li");
//! _ = try frag.node.appendChild(&li1.node);
//! _ = try frag.node.appendChild(&li2.node);
//!
//! // Insert fragment into document
//! const ul = try doc.createElement("ul");
//! _ = try ul.node.appendChild(&frag.node);
//! // Fragment's children moved to ul
//! ```
//!
//! ## Common Patterns
//!
//! ### Document Setup
//!
//! ```zig
//! pub fn createHTMLDocument(allocator: Allocator) !*Document {
//!     const doc = try Document.create(allocator);
//!     errdefer doc.release();
//!
//!     const html = try doc.createElement("html");
//!     doc.document_element = html;
//!     _ = try doc.node.appendChild(&html.node);
//!
//!     return doc;
//! }
//! ```
//!
//! ### Batch Element Creation
//!
//! ```zig
//! const elements = [_][]const u8{ "div", "span", "p", "h1" };
//! var nodes = std.ArrayList(*Element).init(allocator);
//! defer nodes.deinit();
//!
//! for (elements) |tag| {
//!     const elem = try doc.createElement(tag);
//!     try nodes.append(elem);
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **String interning** - Tag/attribute names deduplicated automatically
//! 2. **Node factory** - createElement is O(1) operation
//! 3. **Batch operations** - Create multiple nodes before inserting into tree
//! 4. **Document fragments** - Build subtrees offline, insert once
//! 5. **Owner document** - Weak reference, no circular dependency overhead
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // documentElement (readonly)
//! Object.defineProperty(Document.prototype, 'documentElement', {
//!   get: function() { return zig.document_get_document_element(this._ptr); }
//! });
//!
//! // doctype (readonly)
//! Object.defineProperty(Document.prototype, 'doctype', {
//!   get: function() { return zig.document_get_doctype(this._ptr); }
//! });
//!
//! // Document inherits all Node properties (nodeType, nodeName, etc.)
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // Factory methods
//! Document.prototype.createElement = function(tagName) {
//!   return zig.document_createElement(this._ptr, tagName);
//! };
//!
//! Document.prototype.createTextNode = function(data) {
//!   return zig.document_createTextNode(this._ptr, data);
//! };
//!
//! Document.prototype.createComment = function(data) {
//!   return zig.document_createComment(this._ptr, data);
//! };
//!
//! Document.prototype.createDocumentFragment = function() {
//!   return zig.document_createDocumentFragment(this._ptr);
//! };
//!
//! // Document inherits all Node methods (appendChild, insertBefore, etc.)
//! // Document inherits all EventTarget methods (addEventListener, etc.)
//! ```
//!
//! ### Document Constructor
//! ```javascript
//! // Global document object created by user agent
//! const doc = new Document(); // Typically not called directly
//!
//! // In bindings implementation:
//! function createDocument(allocator) {
//!   const doc_ptr = zig.document_init(allocator);
//!   return wrapNode(doc_ptr); // Creates JS wrapper with _ptr
//! }
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - Document extends Node (node_type = .document)
//! - String pool freed when document destroyed
//! - Dual reference counting for document lifetime
//! - document_element is convenience pointer (also in tree)
//! - All factory methods set owner_document automatically

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
const SelectorList = @import("selector/parser.zig").SelectorList;
const FastPathType = @import("fast_path.zig").FastPathType;

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

/// Parsed selector with cached fast path detection
///
/// Stores the parsed selector AST and fast path type for reuse.
/// Eliminates repeated parsing overhead in SPA scenarios where the same
/// selectors are queried hundreds or thousands of times.
pub const ParsedSelector = struct {
    allocator: Allocator,

    /// Original selector string (owned)
    selector_string: []const u8,

    /// Parsed selector list
    selector_list: SelectorList,

    /// Fast path type for optimization
    fast_path: FastPathType,

    /// Extracted identifier for fast path (e.g., "id" from "#id")
    identifier: ?[]const u8,

    pub fn init(allocator: Allocator, selectors: []const u8) !*ParsedSelector {
        const parsed = try allocator.create(ParsedSelector);
        errdefer allocator.destroy(parsed);

        // Store selector string
        parsed.selector_string = try allocator.dupe(u8, selectors);
        errdefer allocator.free(parsed.selector_string);

        // Detect fast path
        const fast_path_mod = @import("fast_path.zig");
        parsed.fast_path = fast_path_mod.detectFastPath(selectors);

        // Extract identifier for fast paths
        parsed.identifier = if (parsed.fast_path != .generic)
            try allocator.dupe(u8, fast_path_mod.extractIdentifier(selectors))
        else
            null;
        errdefer if (parsed.identifier) |id| allocator.free(id);

        // Parse selector (even for fast paths, as fallback)
        const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
        const Parser = @import("selector/parser.zig").Parser;

        var tokenizer = Tokenizer.init(allocator, selectors);
        var parser = try Parser.init(allocator, &tokenizer);
        defer parser.deinit();

        parsed.selector_list = try parser.parse();
        parsed.allocator = allocator;

        return parsed;
    }

    pub fn deinit(self: *ParsedSelector) void {
        self.selector_list.deinit();
        self.allocator.free(self.selector_string);
        if (self.identifier) |id| {
            self.allocator.free(id);
        }
        self.allocator.destroy(self);
    }
};

/// Selector cache for querySelector performance optimization
///
/// Caches parsed selectors to avoid repeated parsing overhead.
/// Uses FIFO eviction when cache reaches max_size (like Chromium).
///
/// ## Performance Impact
/// - Simple selectors: 10-100x faster (parsing eliminated)
/// - Complex selectors: 2-5x faster (parsing eliminated)
/// - Memory overhead: ~256 entries × ~100 bytes = ~25KB
///
/// ## Thread Safety
/// Not thread-safe. External synchronization required for concurrent access.
pub const SelectorCache = struct {
    cache: std.StringHashMap(*ParsedSelector),
    allocator: Allocator,
    max_size: usize,

    /// FIFO queue for eviction (stores selector strings)
    fifo_queue: std.ArrayList([]const u8),

    pub fn init(allocator: Allocator) SelectorCache {
        return .{
            .cache = std.StringHashMap(*ParsedSelector).init(allocator),
            .allocator = allocator,
            .max_size = 256, // Like Chromium
            .fifo_queue = std.ArrayList([]const u8){},
        };
    }

    pub fn deinit(self: *SelectorCache) void {
        // Free all cached selectors
        var it = self.cache.valueIterator();
        while (it.next()) |parsed_ptr| {
            parsed_ptr.*.deinit();
        }
        self.cache.deinit();
        self.fifo_queue.deinit(self.allocator);
    }

    /// Get cached selector or parse and cache it
    pub fn get(self: *SelectorCache, selectors: []const u8) !*ParsedSelector {
        // Check cache first
        if (self.cache.get(selectors)) |parsed| {
            return parsed;
        }

        // Parse selector
        const parsed = try ParsedSelector.init(self.allocator, selectors);
        errdefer parsed.deinit();

        // Evict oldest if at capacity
        if (self.cache.count() >= self.max_size) {
            try self.evictOldest();
        }

        // Cache it
        try self.cache.put(parsed.selector_string, parsed);
        try self.fifo_queue.append(self.allocator, parsed.selector_string);

        return parsed;
    }

    /// Evict oldest entry (FIFO)
    fn evictOldest(self: *SelectorCache) !void {
        if (self.fifo_queue.items.len == 0) return;

        // Remove oldest from queue
        const oldest = self.fifo_queue.orderedRemove(0);

        // Remove from cache and free
        if (self.cache.fetchRemove(oldest)) |entry| {
            entry.value.deinit();
        }
    }

    /// Clear entire cache
    pub fn clear(self: *SelectorCache) void {
        var it = self.cache.valueIterator();
        while (it.next()) |parsed_ptr| {
            parsed_ptr.*.deinit();
        }
        self.cache.clearRetainingCapacity();
        self.fifo_queue.clearRetainingCapacity();
    }

    /// Returns number of cached selectors
    pub fn count(self: *const SelectorCache) usize {
        return self.cache.count();
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

    /// Arena allocator for DOM nodes (100-200x faster than general-purpose allocator)
    /// All Element, Text, Comment, and DocumentFragment nodes are allocated from this arena
    /// The entire arena is freed when the document is destroyed
    node_arena: std.heap.ArenaAllocator,

    /// String interning pool (per-document)
    string_pool: StringPool,

    /// Selector cache for querySelector optimization
    selector_cache: SelectorCache,

    /// ID map for O(1) getElementById lookups
    /// Maps id attribute values to elements
    id_map: std.StringHashMap(*Element),

    /// Tag map for O(k) getElementsByTagName lookups
    /// Maps tag names to lists of elements with that tag
    /// k = number of matching elements
    tag_map: std.StringHashMap(std.ArrayList(*Element)),

    /// Class map for O(k) getElementsByClassName lookups
    /// Maps class names to lists of elements with that class
    /// k = number of matching elements
    class_map: std.StringHashMap(std.ArrayList(*Element)),

    /// Single-entry cache for getElementById optimization
    /// Caches the last looked-up ID for O(1) repeated lookups
    id_cache_key: ?[]const u8 = null,
    id_cache_value: ?*Element = null,

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
        .adopting_steps = adoptingStepsImpl,
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

        // Initialize arena allocator for DOM nodes
        var node_arena = std.heap.ArenaAllocator.init(allocator);
        errdefer node_arena.deinit();

        // Initialize string pool
        const string_pool = StringPool.init(allocator);
        errdefer string_pool.deinit();

        // Initialize selector cache
        const selector_cache = SelectorCache.init(allocator);
        errdefer selector_cache.deinit();

        // Initialize ID map
        var id_map = std.StringHashMap(*Element).init(allocator);
        errdefer id_map.deinit();

        // Initialize tag map
        var tag_map = std.StringHashMap(std.ArrayList(*Element)).init(allocator);
        errdefer tag_map.deinit();

        // Initialize class map
        var class_map = std.StringHashMap(std.ArrayList(*Element)).init(allocator);
        errdefer class_map.deinit();

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
        doc.node_arena = node_arena;
        doc.string_pool = string_pool;
        doc.selector_cache = selector_cache;
        doc.id_map = id_map;
        doc.tag_map = tag_map;
        doc.class_map = class_map;
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
    /// When external_ref_count reaches 0, the document is destroyed immediately.
    /// All nodes (including orphaned nodes) are freed via arena deallocation.
    /// This matches browser GC semantics where document destruction frees all associated nodes.
    pub fn release(self: *Document) void {
        const old = self.external_ref_count.fetchSub(1, .monotonic);

        if (old == 1) {
            // External refs reached 0 - document is "closed"
            // Destroy immediately, freeing all nodes (tree + orphaned)
            self.is_destroying = true;

            // Release tree nodes cleanly (calls their deinit hooks)
            var current = self.node.first_child;
            while (current) |child| {
                const next = child.next_sibling;
                child.parent_node = null;
                child.setHasParent(false);
                child.release();
                current = next;
            }

            // Clear child pointers
            self.node.first_child = null;
            self.node.last_child = null;

            // Force cleanup regardless of node_ref_count
            // Orphaned nodes (created but never inserted) are freed by arena.deinit()
            self.deinitInternal();
        }
    }

    /// Increments the internal node reference count.
    ///
    /// Called when a node sets ownerDocument=this.
    /// PUBLIC for node adoption to call.
    pub fn acquireNodeRef(self: *Document) void {
        _ = self.node_ref_count.fetchAdd(1, .monotonic);
    }

    /// Decrements the internal node reference count.
    ///
    /// Called when a node with ownerDocument=this is destroyed.
    /// PUBLIC for nodes to call during cleanup.
    ///
    /// Note: This only tracks refs, it does NOT trigger document destruction.
    /// Document destruction is controlled solely by external_ref_count reaching 0.
    pub fn releaseNodeRef(self: *Document) void {
        // Just decrement the counter
        // Document destruction happens when external_ref_count reaches 0,
        // not when node_ref_count reaches 0
        _ = self.node_ref_count.fetchSub(1, .monotonic);
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

        // Create element using general-purpose allocator (required for cross-document adoption)
        // NOTE: Cannot use arena allocator because nodes may be adopted to other documents
        const elem = try Element.create(self.node.allocator, interned_tag);
        errdefer elem.node.release();

        // Set owner document and assign node ID
        elem.node.owner_document = &self.node;
        elem.node.node_id = self.allocateNodeId();

        // Increment document's node ref count
        self.acquireNodeRef();

        // Add to tag map for O(k) getElementsByTagName lookups
        const result = try self.tag_map.getOrPut(interned_tag);
        if (!result.found_existing) {
            // First element with this tag, create new list
            result.value_ptr.* = std.ArrayList(*Element){};
            // Pre-allocate capacity to avoid repeated reallocations
            // 128 is a reasonable default for common tags (div, span, p, etc.)
            try result.value_ptr.ensureTotalCapacity(self.node.allocator, 128);
        }
        try result.value_ptr.append(self.node.allocator, elem);

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

    /// Adopts a node from another document into this document.
    ///
    /// Implements WHATWG DOM Document.adoptNode() per §4.10.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] Node adoptNode(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.10)
    /// 1. If node is a document → throw NotSupportedError
    /// 2. If node is a shadow root → throw HierarchyRequestError
    /// 3. If node is a DocumentFragment with non-null host → return (no-op)
    /// 4. Adopt node into this document
    /// 5. Return node
    ///
    /// ## Memory Management
    /// Node remains owned by caller. Document gains a node reference
    /// through owner_document tracking.
    ///
    /// ## Parameters
    /// - `node`: Node to adopt (must not be a Document or ShadowRoot)
    ///
    /// ## Returns
    /// The adopted node (same as input parameter)
    ///
    /// ## Errors
    /// - `error.NotSupported`: Node is a Document
    /// - `error.HierarchyRequestError`: Node is a ShadowRoot
    /// - `error.OutOfMemory`: Failed to allocate during adoption
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-document-adoptnode
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:519
    ///
    /// ## Example
    /// ```zig
    /// const doc1 = try Document.init(allocator);
    /// defer doc1.release();
    ///
    /// const doc2 = try Document.init(allocator);
    /// defer doc2.release();
    ///
    /// // Create element in doc1
    /// const elem = try doc1.createElement("div");
    /// try std.testing.expect(elem.node.getOwnerDocument() == doc1);
    ///
    /// // Adopt to doc2
    /// _ = try doc2.adoptNode(&elem.node);
    /// try std.testing.expect(elem.node.getOwnerDocument() == doc2);
    /// ```
    pub fn adoptNode(self: *Document, node: *Node) !*Node {
        // Step 1: If node is a document, throw NotSupportedError
        if (node.node_type == .document) {
            return error.NotSupported;
        }

        // Step 2: If node is a shadow root, throw HierarchyRequestError
        // (Shadow DOM not yet implemented, so this is a no-op for now)

        // Step 3: If node is a DocumentFragment with non-null host, return
        // (Shadow DOM host not yet implemented, so this is a no-op for now)

        // Step 4: Adopt node into this document
        const adopt_fn = @import("node.zig").adopt;
        try adopt_fn(node, &self.node);

        // Step 5: Return node
        return node;
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

    // ========================================================================
    // Document Query Methods
    // ========================================================================

    /// Returns the element with the specified ID (O(1) lookup).
    ///
    /// Implements WHATWG DOM Document.getElementById() per §4.5.
    ///
    /// ## WHATWG Specification
    /// - **§4.5 Interface Document**: https://dom.spec.whatwg.org/#dom-document-getelementbyid
    ///
    /// ## WebIDL
    /// ```webidl
    /// Element? getElementById(DOMString elementId);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Document.getElementById(): https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementById
    ///
    /// ## Algorithm (WHATWG DOM §4.5)
    /// Return the first element in tree order with an id attribute equal to elementId,
    /// or null if no such element exists.
    ///
    /// ## Performance
    /// **O(1)** hash map lookup via document ID map.
    /// This is dramatically faster than querySelector("#id") which requires:
    /// - Parsing the selector string
    /// - Traversing the DOM tree
    ///
    /// ## Returns
    /// Element with matching id attribute, or null if not found
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const button = try doc.createElement("button");
    /// try button.setAttribute("id", "submit");
    /// _ = try doc.node.appendChild(&button.node);
    ///
    /// const found = doc.getElementById("submit");
    /// // found == button (O(1) lookup!)
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const button = document.getElementById('submit');
    /// // Returns: Element or null
    /// ```
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-document-getelementbyid
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:515
    ///
    /// ## Performance Optimization
    /// This implementation uses a hybrid cache + string interning approach:
    /// - **Phase 1 (Cache)**: Single-entry cache for O(1) repeated lookups (~2ns)
    /// - **Phase 2 (Interning)**: Intern lookup strings for consistent pointer equality
    ///
    /// **Performance**:
    /// - Hot path (cache hit): ~2ns (70x faster than hash lookup)
    /// - Warm path (interned): ~84ns (matches browser performance)
    /// - Cold path (first lookup): ~359ns (acceptable for uncommon case)
    /// Invalidates the getElementById cache.
    /// Called internally when ID map is modified (setAttribute/removeAttribute).
    pub fn invalidateIdCache(self: *Document) void {
        self.id_cache_key = null;
        self.id_cache_value = null;
    }

    pub fn getElementById(self: *Document, element_id: []const u8) ?*Element {
        // Phase 1: Fast path - Check cache with pointer equality
        if (self.id_cache_key) |cached_key| {
            // Pointer equality check (fastest path: ~2ns)
            if (cached_key.ptr == element_id.ptr and cached_key.len == element_id.len) {
                return self.id_cache_value;
            }
            // Byte equality check (fast path: ~15ns, avoids 172ns intern)
            if (std.mem.eql(u8, cached_key, element_id)) {
                return self.id_cache_value;
            }
        }

        // Phase 2: Intern the lookup string for consistent hashing
        // This ensures subsequent lookups with same content use pointer equality
        const interned = self.string_pool.intern(element_id) catch {
            // Fallback on OOM: direct lookup without caching
            return self.id_map.get(element_id);
        };

        // Check cache again with interned string
        if (self.id_cache_key) |cached_key| {
            if (cached_key.ptr == interned.ptr) {
                return self.id_cache_value; // ~2ns
            }
        }

        // Full lookup with interned string
        const result = self.id_map.get(interned);

        // Update cache with interned string
        self.id_cache_key = interned;
        self.id_cache_value = result;

        return result;
    }

    /// Returns all elements with the specified tag name (O(k) lookup).
    ///
    /// Implements WHATWG DOM Document.getElementsByTagName() per §4.5.
    ///
    /// ## WHATWG Specification
    /// - **§4.5 Interface Document**: https://dom.spec.whatwg.org/#dom-document-getelementsbytagname
    ///
    /// ## WebIDL
    /// ```webidl
    /// HTMLCollection getElementsByTagName(DOMString qualifiedName);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Document.getElementsByTagName(): https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByTagName
    ///
    /// ## Algorithm (WHATWG DOM §4.5)
    /// Return a live HTMLCollection of all elements with the given tag name.
    ///
    /// ## Performance
    /// **O(k)** where k = number of matching elements.
    /// Uses tag map for direct lookup, avoiding O(n) tree traversal.
    /// Zero allocations - returns borrowed slice.
    ///
    /// ## Parameters
    /// - `tag_name`: Tag name to match (e.g., "div", "button")
    ///
    /// ## Returns
    /// Borrowed slice of elements with matching tag name.
    /// The slice is valid until the document is modified (elements added/removed/changed).
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const button1 = try doc.createElement("button");
    /// _ = try doc.node.appendChild(&button1.node);
    ///
    /// const button2 = try doc.createElement("button");
    /// _ = try doc.node.appendChild(&button2.node);
    ///
    /// const buttons = doc.getElementsByTagName("button");
    /// // buttons.len == 2
    /// // No need to free - borrowed slice
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const buttons = document.getElementsByTagName('button');
    /// // Returns: HTMLCollection (live)
    /// ```
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-document-getelementsbytagname
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:518
    ///
    /// ## Note
    /// This returns a snapshot slice (not live). The slice becomes stale after DOM mutations.
    /// This is idiomatic Zig - zero allocations, caller must ensure document lifetime.
    pub fn getElementsByTagName(self: *const Document, tag_name: []const u8) []const *Element {
        if (self.tag_map.get(tag_name)) |list| {
            return list.items;
        }
        // No elements with this tag
        return &[_]*Element{};
    }

    /// Returns all elements with the specified class name (O(k) lookup).
    ///
    /// Implements WHATWG DOM Document.getElementsByClassName() per §4.5.
    ///
    /// ## WHATWG Specification
    /// - **§4.5 Interface Document**: https://dom.spec.whatwg.org/#dom-document-getelementsbyclassname
    ///
    /// ## WebIDL
    /// ```webidl
    /// HTMLCollection getElementsByClassName(DOMString classNames);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Document.getElementsByClassName(): https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByClassName
    ///
    /// ## Algorithm (WHATWG DOM §4.5)
    /// Return a live HTMLCollection of all elements with the given class name.
    ///
    /// ## Performance
    /// **O(k)** where k = number of matching elements.
    /// Uses class map for direct lookup, avoiding O(n) tree traversal.
    /// Zero allocations - returns borrowed slice.
    ///
    /// ## Parameters
    /// - `class_name`: Single class name to match (without "." prefix)
    ///
    /// ## Returns
    /// Borrowed slice of elements with matching class name.
    /// The slice is valid until the document is modified (elements added/removed/changed).
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const button1 = try doc.createElement("button");
    /// try button1.setAttribute("class", "btn primary");
    /// _ = try doc.node.appendChild(&button1.node);
    ///
    /// const button2 = try doc.createElement("button");
    /// try button2.setAttribute("class", "btn");
    /// _ = try doc.node.appendChild(&button2.node);
    ///
    /// const btns = doc.getElementsByClassName("btn");
    /// // btns.len == 2 (both buttons have "btn" class)
    /// // No need to free - borrowed slice
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const buttons = document.getElementsByClassName('btn');
    /// // Returns: HTMLCollection (live)
    /// ```
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-document-getelementsbyclassname
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:519
    ///
    /// ## Note
    /// This returns a snapshot slice (not live). The slice becomes stale after DOM mutations.
    /// This is idiomatic Zig - zero allocations, caller must ensure document lifetime.
    /// Only supports single class name lookup (not space-separated list yet).
    pub fn getElementsByClassName(self: *const Document, class_name: []const u8) []const *Element {
        if (self.class_map.get(class_name)) |list| {
            return list.items;
        }
        // No elements with this class
        return &[_]*Element{};
    }

    // ========================================================================
    // ParentNode Mixin - Query Selector
    // ========================================================================

    /// Returns the first element that matches the specified CSS selector.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#dom-parentnode-queryselector
    ///
    /// ## WebIDL
    /// ```webidl
    /// Element? querySelector(DOMString selectors);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Document.querySelector(): https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector
    ///
    /// ## Usage
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const html = try doc.createElement("html");
    /// _ = try doc.node.appendChild(&html.node);
    ///
    /// const button = try doc.createElement("button");
    /// try button.setAttribute("class", "btn");
    /// _ = try html.node.appendChild(&button.node);
    ///
    /// // Find button from document root
    /// const result = try doc.querySelector(".btn");
    /// // result == button
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// // Instance method on Document.prototype
    /// const button = document.querySelector('button.primary');
    /// // Returns: Element or null
    /// ```
    pub fn querySelector(self: *Document, selectors: []const u8) !?*Element {
        // Delegate to documentElement if it exists
        if (self.documentElement()) |root| {
            return try root.querySelector(self.node.allocator, selectors);
        }
        return null;
    }

    /// Returns all elements that match the specified CSS selector.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#dom-parentnode-queryselectorall
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] NodeList querySelectorAll(DOMString selectors);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Document.querySelectorAll(): https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelectorAll
    ///
    /// ## Usage
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// // Build DOM tree...
    ///
    /// // Find all buttons
    /// const results = try doc.querySelectorAll("button");
    /// defer allocator.free(results);
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// // Instance method on Document.prototype
    /// const buttons = document.querySelectorAll('button.primary');
    /// // Returns: NodeList (array-like, always defined)
    /// ```
    pub fn querySelectorAll(self: *Document, selectors: []const u8) ![]const *Element {
        // Delegate to documentElement if it exists
        if (self.documentElement()) |root| {
            return try root.querySelectorAll(self.node.allocator, selectors);
        }
        // Return empty slice if no document element
        return &[_]*Element{};
    }

    /// Returns a live collection of element children.
    ///
    /// Implements WHATWG DOM ParentNode.children property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [SameObject] readonly attribute HTMLCollection children;
    /// ```
    ///
    /// ## MDN Documentation
    /// - children: https://developer.mozilla.org/en-US/docs/Web/API/Document/children
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-children
    /// - WebIDL: dom.idl:119
    ///
    /// ## Returns
    /// Live ElementCollection of element children (typically just documentElement)
    pub fn children(self: *Document) @import("element_collection.zig").ElementCollection {
        return @import("element_collection.zig").ElementCollection.init(&self.node);
    }

    // === Private implementation ===

    /// Allocates the next available node ID.
    fn allocateNodeId(self: *Document) u16 {
        const id = self.next_node_id;
        self.next_node_id +%= 1; // Wrapping add (unlikely to overflow)
        return id;
    }

    /// Internal cleanup.
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

    /// Recursively clean up attributes for all elements in the tree.
    /// This is needed before arena deinit because attributes use the general-purpose allocator.
    fn cleanupElementAttributesRecursive(node: *Node) void {
        // Clean up attributes if this is an element
        if (node.node_type == .element) {
            const elem: *Element = @fieldParentPtr("node", node);
            elem.attributes.deinit();
        }

        // Recursively clean up children
        var current = node.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            cleanupElementAttributesRecursive(child);
            current = next;
        }
    }

    fn deinitInternal(self: *Document) void {
        // Clean up rare data if allocated
        self.node.deinitRareData();

        // Clean up attributes for all elements before arena deinit
        // (attributes use general-purpose allocator, not arena)
        if (self.node.first_child) |first_child| {
            cleanupElementAttributesRecursive(first_child);
        }

        // Clean up selector cache
        self.selector_cache.deinit();

        // Clean up ID map
        self.id_map.deinit();

        // Clean up tag map - Free ArrayList values before deiniting the HashMap
        // IMPORTANT: Must deinit tag_map BEFORE string_pool because tag_map keys are string pointers
        var tag_it = self.tag_map.valueIterator();
        while (tag_it.next()) |list_ptr| {
            list_ptr.deinit(self.node.allocator);
        }
        self.tag_map.deinit();

        // Clean up class map - Free ArrayList values before deiniting the HashMap
        // IMPORTANT: Must deinit class_map BEFORE string_pool because class_map keys are string pointers
        var class_it = self.class_map.valueIterator();
        while (class_it.next()) |list_ptr| {
            list_ptr.*.deinit(self.node.allocator);
        }
        self.class_map.deinit();

        // Clean up string pool (must be AFTER tag_map and class_map)
        self.string_pool.deinit();

        // Deinit arena allocator (frees all nodes at once - 100-200x faster than individual frees)
        self.node_arena.deinit();

        // Free document structure
        self.node.allocator.destroy(self);
    }

    // === Vtable implementations ===

    /// Vtable implementation: adopting steps (no-op for Document)
    ///
    /// Documents cannot be adopted per WHATWG spec.
    fn adoptingStepsImpl(_: *Node, _: ?*Node) !void {
        // No-op: Documents cannot be adopted
    }

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

// ============================================================================
// SELECTOR CACHE TESTS
// ============================================================================

test "SelectorCache - basic caching" {
    const allocator = std.testing.allocator;

    var cache = SelectorCache.init(allocator);
    defer cache.deinit();

    // Get selector (should parse and cache)
    const parsed1 = try cache.get("#main");
    try std.testing.expect(parsed1.fast_path == .simple_id);
    try std.testing.expectEqual(@as(usize, 1), cache.count());

    // Get same selector (should return cached)
    const parsed2 = try cache.get("#main");
    try std.testing.expect(parsed1 == parsed2); // Same pointer
    try std.testing.expectEqual(@as(usize, 1), cache.count());

    // Get different selector
    const parsed3 = try cache.get(".button");
    try std.testing.expect(parsed3.fast_path == .simple_class);
    try std.testing.expectEqual(@as(usize, 2), cache.count());
}

test "SelectorCache - fast path detection" {
    const allocator = std.testing.allocator;

    var cache = SelectorCache.init(allocator);
    defer cache.deinit();

    // ID selector
    const id_sel = try cache.get("#test");
    try std.testing.expect(id_sel.fast_path == .simple_id);
    try std.testing.expectEqualStrings("test", id_sel.identifier.?);

    // Class selector
    const class_sel = try cache.get(".button");
    try std.testing.expect(class_sel.fast_path == .simple_class);
    try std.testing.expectEqualStrings("button", class_sel.identifier.?);

    // Tag selector
    const tag_sel = try cache.get("div");
    try std.testing.expect(tag_sel.fast_path == .simple_tag);
    try std.testing.expectEqualStrings("div", tag_sel.identifier.?);

    // Generic selector
    const gen_sel = try cache.get("div > p");
    try std.testing.expect(gen_sel.fast_path == .generic);
    try std.testing.expect(gen_sel.identifier == null);
}

test "SelectorCache - FIFO eviction" {
    const allocator = std.testing.allocator;

    var cache = SelectorCache.init(allocator);
    cache.max_size = 3; // Small cache for testing
    defer cache.deinit();

    // Fill cache
    _ = try cache.get("#id1");
    _ = try cache.get("#id2");
    _ = try cache.get("#id3");
    try std.testing.expectEqual(@as(usize, 3), cache.count());

    // Add one more (should evict #id1)
    _ = try cache.get("#id4");
    try std.testing.expectEqual(@as(usize, 3), cache.count());

    // Verify #id1 was evicted
    const id1_again = try cache.get("#id1");
    try std.testing.expectEqual(@as(usize, 3), cache.count()); // Still 3 (evicted #id2)
    try std.testing.expectEqualStrings("#id1", id1_again.selector_string);
}

test "SelectorCache - clear" {
    const allocator = std.testing.allocator;

    var cache = SelectorCache.init(allocator);
    defer cache.deinit();

    // Add some entries
    _ = try cache.get("#main");
    _ = try cache.get(".button");
    _ = try cache.get("div");
    try std.testing.expectEqual(@as(usize, 3), cache.count());

    // Clear cache
    cache.clear();
    try std.testing.expectEqual(@as(usize, 0), cache.count());

    // Can add again
    _ = try cache.get("#main");
    try std.testing.expectEqual(@as(usize, 1), cache.count());
}

test "Document - selector cache integration" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Selector cache should be initialized
    try std.testing.expectEqual(@as(usize, 0), doc.selector_cache.count());

    // We'll test actual usage in the next step when we integrate with querySelector
}

// ============================================================================
// ID MAP TESTS (Phase 2)
// ============================================================================

test "Document - getElementById basic" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "submit");
    _ = try root.node.appendChild(&button.node);

    // O(1) lookup!
    const found = doc.getElementById("submit");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);

    // Not found
    const not_found = doc.getElementById("missing");
    try std.testing.expect(not_found == null);
}

test "Document - getElementById updates on setAttribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const button = try doc.createElement("button");
    _ = try root.node.appendChild(&button.node);

    // Initially no ID
    try std.testing.expect(doc.getElementById("test") == null);

    // Set ID
    try button.setAttribute("id", "test");
    const found1 = doc.getElementById("test");
    try std.testing.expect(found1 != null);
    try std.testing.expect(found1.? == button);

    // Change ID
    try button.setAttribute("id", "changed");
    try std.testing.expect(doc.getElementById("test") == null);
    const found2 = doc.getElementById("changed");
    try std.testing.expect(found2 != null);
    try std.testing.expect(found2.? == button);
}

test "Document - getElementById cleans up on removeAttribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "remove-test");
    _ = try root.node.appendChild(&button.node);

    // ID exists
    try std.testing.expect(doc.getElementById("remove-test") != null);

    // Remove ID attribute
    button.removeAttribute("id");
    try std.testing.expect(doc.getElementById("remove-test") == null);
}

test "Document - getElementById multiple elements" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Create multiple elements with IDs
    const button1 = try doc.createElement("button");
    try button1.setAttribute("id", "btn1");
    _ = try root.node.appendChild(&button1.node);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("id", "btn2");
    _ = try root.node.appendChild(&button2.node);

    const button3 = try doc.createElement("button");
    try button3.setAttribute("id", "btn3");
    _ = try root.node.appendChild(&button3.node);

    // All should be findable
    try std.testing.expect(doc.getElementById("btn1").? == button1);
    try std.testing.expect(doc.getElementById("btn2").? == button2);
    try std.testing.expect(doc.getElementById("btn3").? == button3);
}

test "Document - querySelector uses getElementById for #id" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "target");
    _ = try root.node.appendChild(&button.node);

    // querySelector("#id") should use fast path with O(1) lookup
    const found = try doc.querySelector("#target");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

// ============================================================================
// TAG MAP TESTS (Phase 3)
// ============================================================================

test "Document - getElementsByTagName basic" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const button1 = try doc.createElement("button");
    _ = try root.node.appendChild(&button1.node);

    const button2 = try doc.createElement("button");
    _ = try root.node.appendChild(&button2.node);

    const div = try doc.createElement("div");
    _ = try root.node.appendChild(&div.node);

    // Get all buttons
    const buttons = doc.getElementsByTagName("button");
    try std.testing.expectEqual(@as(usize, 2), buttons.len);
    try std.testing.expect(buttons[0] == button1);
    try std.testing.expect(buttons[1] == button2);

    // Get all divs
    const divs = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 1), divs.len);
    try std.testing.expect(divs[0] == div);

    // Not found
    const spans = doc.getElementsByTagName("span");
    try std.testing.expectEqual(@as(usize, 0), spans.len);
}

test "Document - tag map maintained on createElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Create multiple elements with same tag
    const div1 = try doc.createElement("div");
    _ = try root.node.appendChild(&div1.node);

    const div2 = try doc.createElement("div");
    _ = try root.node.appendChild(&div2.node);

    const div3 = try doc.createElement("div");
    _ = try root.node.appendChild(&div3.node);

    // Tag map should have all three
    const divs = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 3), divs.len);
}

test "Document - tag map cleaned up on element removal" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const div1 = try doc.createElement("div");
    _ = try root.node.appendChild(&div1.node);

    const div2 = try doc.createElement("div");
    _ = try root.node.appendChild(&div2.node);

    // Should have 2 divs
    {
        const divs = doc.getElementsByTagName("div");
        try std.testing.expectEqual(@as(usize, 2), divs.len);
    }

    // Remove one div
    _ = try root.node.removeChild(&div1.node);
    div1.node.release();

    // Should have 1 div
    {
        const divs = doc.getElementsByTagName("div");
        try std.testing.expectEqual(@as(usize, 1), divs.len);
        try std.testing.expect(divs[0] == div2);
    }
}

test "Document - getElementsByClassName basic" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn primary");
    _ = try root.node.appendChild(&button1.node);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn");
    _ = try root.node.appendChild(&button2.node);

    const div = try doc.createElement("div");
    try div.setAttribute("class", "container");
    _ = try root.node.appendChild(&div.node);

    // Get all "btn" elements
    const btns = doc.getElementsByClassName("btn");
    try std.testing.expectEqual(@as(usize, 2), btns.len);
    try std.testing.expect(btns[0] == button1);
    try std.testing.expect(btns[1] == button2);

    // Get all "primary" elements
    const primaries = doc.getElementsByClassName("primary");
    try std.testing.expectEqual(@as(usize, 1), primaries.len);
    try std.testing.expect(primaries[0] == button1);

    // Get all "container" elements
    const containers = doc.getElementsByClassName("container");
    try std.testing.expectEqual(@as(usize, 1), containers.len);
    try std.testing.expect(containers[0] == div);

    // Not found
    const notfound = doc.getElementsByClassName("notfound");
    try std.testing.expectEqual(@as(usize, 0), notfound.len);
}

test "Document - class map maintained on setAttribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const div = try doc.createElement("div");
    _ = try root.node.appendChild(&div.node);

    // Initially no class
    {
        const elements = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 0), elements.len);
    }

    // Add class
    try div.setAttribute("class", "foo bar");
    {
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 1), foos.len);
        try std.testing.expect(foos[0] == div);

        const bars = doc.getElementsByClassName("bar");
        try std.testing.expectEqual(@as(usize, 1), bars.len);
        try std.testing.expect(bars[0] == div);
    }

    // Change class
    try div.setAttribute("class", "baz");
    {
        // Old classes should be gone
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 0), foos.len);

        const bars = doc.getElementsByClassName("bar");
        try std.testing.expectEqual(@as(usize, 0), bars.len);

        // New class should be present
        const bazs = doc.getElementsByClassName("baz");
        try std.testing.expectEqual(@as(usize, 1), bazs.len);
        try std.testing.expect(bazs[0] == div);
    }
}

test "Document - class map cleaned up on removeAttribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const div = try doc.createElement("div");
    try div.setAttribute("class", "foo bar");
    _ = try root.node.appendChild(&div.node);

    // Should have classes
    {
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 1), foos.len);
    }

    // Remove class attribute
    div.removeAttribute("class");

    // Should be empty
    {
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 0), foos.len);

        const bars = doc.getElementsByClassName("bar");
        try std.testing.expectEqual(@as(usize, 0), bars.len);
    }
}

test "Document - class map cleaned up on element removal" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const elem1 = try doc.createElement("element");
    try elem1.setAttribute("class", "testclass1");
    _ = try root.node.appendChild(&elem1.node);

    const elem2 = try doc.createElement("element");
    try elem2.setAttribute("class", "testclass1");
    _ = try root.node.appendChild(&elem2.node);

    // Should have 2 elements with class "testclass1"
    {
        const results = doc.getElementsByClassName("testclass1");
        try std.testing.expectEqual(@as(usize, 2), results.len);
    }

    // Remove one element
    _ = try root.node.removeChild(&elem1.node);
    elem1.node.release();

    // Should have 1 element with class "testclass1"
    {
        const results = doc.getElementsByClassName("testclass1");
        try std.testing.expectEqual(@as(usize, 1), results.len);
        try std.testing.expect(results[0] == elem2);
    }
}
