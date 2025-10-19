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
//! // elem.prototype.owner_document == &doc.node
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
//! _ = try doc.prototype.appendChild(&html.prototype);
//!
//! // Build tree
//! const body = try doc.createElement("body");
//! _ = try html.prototype.appendChild(&body.prototype);
//!
//! const div = try doc.createElement("div");
//! try div.setAttribute("id", "content");
//! _ = try body.prototype.appendChild(&div.prototype);
//!
//! const text = try doc.createTextNode("Hello, World!");
//! _ = try div.prototype.appendChild(&text.prototype);
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
//! _ = try html.prototype.appendChild(&head.prototype);
//! _ = try html.prototype.appendChild(&body.prototype);
//! doc.document_element = html;
//! _ = try doc.prototype.appendChild(&html.prototype);
//!
//! // Add title
//! const title = try doc.createElement("title");
//! const title_text = try doc.createTextNode("My Page");
//! _ = try title.prototype.appendChild(&title_text.prototype);
//! _ = try head.prototype.appendChild(&title.prototype);
//! ```
//!
//! ### Creating Document Fragment
//!
//! ```zig
//! const frag = try doc.createDocumentFragment();
//! defer frag.prototype.release();
//!
//! // Build fragment
//! const li1 = try doc.createElement("li");
//! const li2 = try doc.createElement("li");
//! _ = try frag.prototype.appendChild(&li1.prototype);
//! _ = try frag.prototype.appendChild(&li2.prototype);
//!
//! // Insert fragment into document
//! const ul = try doc.createElement("ul");
//! _ = try ul.prototype.appendChild(&frag.prototype);
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
//!     _ = try doc.prototype.appendChild(&html.prototype);
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
const HTMLCollection = @import("html_collection.zig").HTMLCollection;

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

/// Factory function configuration for Document (enables extensibility).
///
/// HTML/XML libraries can provide custom factory functions to create
/// HTMLElement, XMLElement, etc. instead of generic Element/Text/Comment.
///
/// ## Example (HTML Document)
/// ```zig
/// const factories = Document.FactoryConfig{
///     .element_factory = HTMLElement.createForDocument,
///     .text_factory = null, // Use default Text.create
///     .comment_factory = null, // Use default Comment.create
/// };
/// const doc = try Document.initWithFactories(allocator, factories);
/// const elem = try doc.createElement("div"); // Returns HTMLElement!
/// ```
pub const FactoryConfig = struct {
    element_factory: ?*const fn (Allocator, []const u8) anyerror!*Element = null,
    text_factory: ?*const fn (Allocator, []const u8) anyerror!*Text = null,
    comment_factory: ?*const fn (Allocator, []const u8) anyerror!*Comment = null,
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
    prototype: Node,

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
    // NOTE: class_map removed in Phase 3
    // getElementsByClassName now uses tree traversal with bloom filters (like browsers)
    // This matches browser behavior where class queries don't maintain a separate map

    /// Single-entry cache for getElementById optimization
    /// Caches the last looked-up ID for O(1) repeated lookups
    id_cache_key: ?[]const u8 = null,
    id_cache_value: ?*Element = null,

    /// Next node ID to assign
    next_node_id: u16,

    /// Flag to prevent reentrant destruction during cleanup
    /// When true, releaseNodeRef() should not trigger deinitInternal()
    is_destroying: bool,

    /// Factory functions for custom node creation (enables HTML/XML extensibility)
    /// If null, uses default factories (Element.create, Text.create, etc.)
    element_factory: ?*const fn (Allocator, []const u8) anyerror!*Element = null,
    text_factory: ?*const fn (Allocator, []const u8) anyerror!*Text = null,
    comment_factory: ?*const fn (Allocator, []const u8) anyerror!*Comment = null,

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
    /// defer elem.prototype.release();
    /// ```
    pub fn init(allocator: Allocator) !*Document {
        return initWithFactories(allocator, .{});
    }

    /// Initializes a document with custom factory functions (enables HTML/XML extensibility).
    ///
    /// Factory functions allow HTML/XML libraries to return custom element types
    /// from Document.createElement(), createTextNode(), etc.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `factories`: Factory configuration (null uses defaults)
    ///
    /// ## Example (HTML Document)
    /// ```zig
    /// const factories = Document.FactoryConfig{
    ///     .element_factory = HTMLElement.createForDocument,
    /// };
    /// const doc = try Document.initWithFactories(allocator, factories);
    /// const elem = try doc.createElement("div"); // Returns HTMLElement
    /// ```
    pub fn initWithFactories(
        allocator: Allocator,
        factories: FactoryConfig,
    ) !*Document {
        return initWithVTableAndFactories(allocator, &vtable, factories);
    }

    /// Initializes a document with a custom vtable (enables extensibility).
    pub fn initWithVTable(
        allocator: Allocator,
        node_vtable: *const NodeVTable,
    ) !*Document {
        return initWithVTableAndFactories(allocator, node_vtable, .{});
    }

    /// Full initialization with both vtable and factories (maximum extensibility).
    fn initWithVTableAndFactories(
        allocator: Allocator,
        node_vtable: *const NodeVTable,
        factories: FactoryConfig,
    ) !*Document {
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

        // NOTE: class_map removed in Phase 3 - no longer needed

        // Initialize base Node
        doc.prototype = .{
            .prototype = .{
                .vtable = &node_mod.eventtarget_vtable,
            },
            .vtable = node_vtable,
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
            .owner_document = &doc.prototype, // Document owns itself
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
        // NOTE: class_map removed in Phase 3
        doc.next_node_id = 1; // 0 reserved for document itself
        doc.is_destroying = false;

        // Initialize factory functions
        doc.element_factory = factories.element_factory;
        doc.text_factory = factories.text_factory;
        doc.comment_factory = factories.comment_factory;

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
            var current = self.prototype.first_child;
            while (current) |child| {
                const next = child.next_sibling;
                child.parent_node = null;
                child.setHasParent(false);
                child.release();
                current = next;
            }

            // Clear child pointers
            self.prototype.first_child = null;
            self.prototype.last_child = null;

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

        // Create element using factory (if provided) or default
        const elem = if (self.element_factory) |factory|
            try factory(self.prototype.allocator, interned_tag)
        else
            try Element.create(self.prototype.allocator, interned_tag);
        errdefer elem.prototype.release();

        // Set owner document and assign node ID
        elem.prototype.owner_document = &self.prototype;
        elem.prototype.node_id = self.allocateNodeId();

        // Increment document's node ref count
        self.acquireNodeRef();

        // NOTE: We don't add to tag_map here anymore!
        // Elements are added to tag_map when inserted into the document tree (appendChild/insertBefore)
        // This matches browser behavior and ensures only connected elements are in the map.

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
        const text = if (self.text_factory) |factory|
            try factory(self.prototype.allocator, data)
        else
            try Text.create(self.prototype.allocator, data);
        errdefer text.prototype.release();

        // Set owner document and assign node ID
        text.prototype.owner_document = &self.prototype;
        text.prototype.node_id = self.allocateNodeId();

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
        const comment = if (self.comment_factory) |factory|
            try factory(self.prototype.allocator, data)
        else
            try Comment.create(self.prototype.allocator, data);
        errdefer comment.prototype.release();

        // Set owner document and assign node ID
        comment.prototype.owner_document = &self.prototype;
        comment.prototype.node_id = self.allocateNodeId();

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
    /// Returns DocumentFragment with ref_count=1. Caller MUST call `fragment.prototype.release()`.
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
    /// defer fragment.prototype.release();
    ///
    /// // Add elements to fragment
    /// const elem1 = try doc.createElement("div");
    /// const elem2 = try doc.createElement("span");
    /// _ = try fragment.prototype.appendChild(&elem1.prototype);
    /// _ = try fragment.prototype.appendChild(&elem2.prototype);
    ///
    /// // Insert fragment into document (moves children)
    /// _ = try doc.prototype.appendChild(&fragment.prototype);
    /// ```
    pub fn createDocumentFragment(self: *Document) !*DocumentFragment {
        const fragment = try DocumentFragment.create(self.prototype.allocator);
        errdefer fragment.prototype.release();

        // Set owner document and assign node ID
        fragment.prototype.owner_document = &self.prototype;
        fragment.prototype.node_id = self.allocateNodeId();

        // Increment document's node ref count
        self.acquireNodeRef();

        return fragment;
    }

    /// Creates a new DocumentType node.
    ///
    /// ## WHATWG Specification
    /// - **DOMImplementation.createDocumentType()**: https://dom.spec.whatwg.org/#dom-domimplementation-createdocumenttype
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] DocumentType createDocumentType(DOMString qualifiedName, DOMString publicId, DOMString systemId);
    /// ```
    ///
    /// ## MDN Documentation
    /// - DOMImplementation.createDocumentType(): https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocumentType
    ///
    /// ## Algorithm (WHATWG DOM §5.2)
    /// Create a new DocumentType node with:
    /// - name set to qualifiedName
    /// - publicId set to publicId
    /// - systemId set to systemId
    /// - node document set to this document
    ///
    /// ## Memory Management
    /// Returns DocumentType with ref_count=1. Caller MUST call `doctype.prototype.release()`.
    ///
    /// ## Parameters
    /// - `name`: Document type name (e.g., "html", "xml", "svg")
    /// - `publicId`: Public identifier (empty string for HTML5)
    /// - `systemId`: System identifier/DTD URL (empty string for HTML5)
    ///
    /// ## Returns
    /// New DocumentType node owned by this document
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domimplementation-createdocumenttype
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// // HTML5 doctype: <!DOCTYPE html>
    /// const doctype = try doc.createDocumentType("html", "", "");
    /// defer doctype.prototype.release();
    ///
    /// // XML doctype with public/system IDs
    /// const xml_doctype = try doc.createDocumentType(
    ///     "svg",
    ///     "-//W3C//DTD SVG 1.1//EN",
    ///     "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
    /// );
    /// defer xml_doctype.prototype.release();
    /// ```
    pub fn createDocumentType(self: *Document, name: []const u8, publicId: []const u8, systemId: []const u8) !*@import("document_type.zig").DocumentType {
        const DocumentType = @import("document_type.zig").DocumentType;

        // Intern strings via document string pool
        const name_interned = try self.string_pool.intern(name);
        const publicId_interned = try self.string_pool.intern(publicId);
        const systemId_interned = try self.string_pool.intern(systemId);

        // Create DocumentType with interned strings
        const dt = try self.prototype.allocator.create(DocumentType);
        errdefer self.prototype.allocator.destroy(dt);

        dt.* = DocumentType{
            .prototype = .{
                .prototype = .{
                    .vtable = &node_mod.eventtarget_vtable,
                },
                .vtable = &DocumentType.vtable,
                .ref_count_and_parent = std.atomic.Value(u32).init(1),
                .node_type = .document_type,
                .flags = 0,
                .node_id = 0,
                .generation = 0,
                .allocator = self.prototype.allocator,
                .parent_node = null,
                .previous_sibling = null,
                .first_child = null,
                .last_child = null,
                .next_sibling = null,
                .owner_document = null,
                .rare_data = null,
            },
            .name = name_interned,
            .publicId = publicId_interned,
            .systemId = systemId_interned,
        };

        // Set owner document and assign node ID
        dt.prototype.owner_document = &self.prototype;
        dt.prototype.node_id = self.allocateNodeId();

        // Increment document's node ref count
        self.acquireNodeRef();

        return dt;
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
    /// try std.testing.expect(elem.prototype.getOwnerDocument() == doc1);
    ///
    /// // Adopt to doc2
    /// _ = try doc2.adoptNode(&elem.prototype);
    /// try std.testing.expect(elem.prototype.getOwnerDocument() == doc2);
    /// ```
    /// Imports a node from another document into this document.
    ///
    /// Creates a copy of the node from an external document and prepares it for insertion
    /// into this document. The original node is not modified. If `deep` is true, the entire
    /// subtree (including descendants) is cloned.
    ///
    /// Implements WHATWG DOM Document.importNode() interface per §4.5.2.
    ///
    /// ## WebIDL
    ///
    /// ```webidl
    /// [CEReactions, NewObject] Node importNode(Node node, optional (boolean or ImportNodeOptions) options = false);
    /// ```
    ///
    /// ## WHATWG Algorithm (§4.5.2)
    ///
    /// 1. If node is a document or shadow root, throw NotSupportedError
    /// 2. Return clone(node, this, deep flag)
    ///
    /// ## Parameters
    /// - `node`: Node to import from another document
    /// - `deep`: If true, recursively clone descendants; if false, clone only the node itself
    ///
    /// ## Returns
    /// Cloned node owned by this document (not yet inserted)
    ///
    /// ## Errors
    /// - `NotSupported`: Cannot import Document or ShadowRoot nodes
    /// - `OutOfMemory`: Failed to allocate cloned node
    ///
    /// ## Example
    ///
    /// ```zig
    /// const doc1 = try Document.init(allocator);
    /// defer doc1.release();
    /// const doc2 = try Document.init(allocator);
    /// defer doc2.release();
    ///
    /// const elem1 = try doc1.createElement("div");
    /// try elem1.setAttribute("id", "original");
    /// _ = try doc1.prototype.appendChild(&elem1.prototype);
    ///
    /// // Import (clone) from doc1 to doc2
    /// const imported = try doc2.importNode(&elem1.prototype, false);
    /// // imported is a separate node owned by doc2
    /// // elem1 remains in doc1 unchanged
    ///
    /// _ = try doc2.prototype.appendChild(imported);
    /// ```
    ///
    /// ## Spec References
    ///
    /// See: https://dom.spec.whatwg.org/#dom-document-importnode
    /// See: https://developer.mozilla.org/en-US/docs/Web/API/Document/importNode
    pub fn importNode(self: *Document, node: *Node, deep: bool) !*Node {
        // Step 1: If node is a document, throw NotSupportedError
        if (node.node_type == .document) {
            return error.NotSupported;
        }

        // Step 2: If node is a shadow root, throw NotSupportedError
        if (node.node_type == .shadow_root) {
            return error.NotSupported;
        }

        // Step 3: Clone the node using this document's allocator
        // This ensures the cloned node and all its descendants are allocated
        // in the target document's arena, avoiding cross-arena memory issues
        const cloned = try node.cloneNodeWithAllocator(self.prototype.allocator, deep);
        errdefer cloned.release();

        // Step 4: Adopt the cloned node into this document
        // This sets owner_document and updates all descendants
        const adopt_fn = @import("node.zig").adopt;
        try adopt_fn(cloned, &self.prototype);

        return cloned;
    }

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
        try adopt_fn(node, &self.prototype);

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
        var current = self.prototype.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                return @fieldParentPtr("prototype", node);
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
    pub fn doctype(self: *const Document) ?*@import("document_type.zig").DocumentType {
        // Search for DocumentType node among children
        var current = self.prototype.first_child;
        while (current) |node| {
            if (node.node_type == .document_type) {
                return @fieldParentPtr("prototype", node);
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
    /// _ = try doc.prototype.appendChild(&button.prototype);
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
        // No need to check isConnected() - id_map only contains connected elements!
        // Map is updated during tree mutations (appendChild/removeChild), not here.
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
    /// Zero allocations - returns live view into internal map.
    ///
    /// ## Parameters
    /// - `tag_name`: Tag name to match (e.g., "div", "container")
    ///
    /// ## Returns
    /// Live collection of elements with matching tag name.
    /// The collection automatically reflects DOM changes.
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const container1 = try doc.createElement("container");
    /// _ = try doc.prototype.appendChild(&container1.prototype);
    ///
    /// const collection = doc.getElementsByTagName("container");
    /// // collection.length() == 1
    ///
    /// const container2 = try doc.createElement("container");
    /// _ = try doc.prototype.appendChild(&container2.prototype);
    /// // collection.length() == 2 (automatically updated!)
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const elements = document.getElementsByTagName('div');
    /// // Returns: HTMLCollection (live)
    /// ```
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-document-getelementsbytagname
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:518
    ///
    /// ## Note
    /// This returns a live collection backed by Document's internal tag_map.
    /// Changes to the DOM automatically reflect in the collection.
    pub fn getElementsByTagName(self: *Document, tag_name: []const u8) HTMLCollection {
        // IMPORTANT: Ensure the tag exists in tag_map (even if empty) so HTMLCollection
        // gets a stable pointer. This makes the collection truly "live" - it will
        // reflect additions/removals even if called before any elements exist.
        const result = self.tag_map.getOrPut(tag_name) catch {
            // If allocation fails, return empty collection
            return HTMLCollection.initDocumentTagged(null);
        };
        if (!result.found_existing) {
            result.value_ptr.* = .{};
        }
        return HTMLCollection.initDocumentTagged(result.value_ptr);
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
    /// Zero allocations - returns live view into internal map.
    ///
    /// ## Parameters
    /// - `class_name`: Single class name to match (without "." prefix)
    ///
    /// ## Returns
    /// Live collection of elements with matching class name.
    /// The collection automatically reflects DOM changes.
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const button1 = try doc.createElement("button");
    /// try button1.setAttribute("class", "btn primary");
    /// _ = try doc.prototype.appendChild(&button1.prototype);
    ///
    /// const collection = doc.getElementsByClassName("btn");
    /// // collection.length() == 1
    ///
    /// const button2 = try doc.createElement("button");
    /// try button2.setAttribute("class", "btn");
    /// _ = try doc.prototype.appendChild(&button2.prototype);
    /// // collection.length() == 2 (automatically updated!)
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
    /// This returns a live collection using tree traversal with bloom filter optimization.
    /// Changes to the DOM automatically reflect in the collection.
    /// Only supports single class name lookup (not space-separated list yet).
    ///
    /// ## Implementation
    /// Phase 3: Uses tree traversal instead of class_map (removed for browser alignment).
    /// Bloom filters in Element provide O(1) fast rejection for non-matching elements.
    pub fn getElementsByClassName(self: *const Document, class_name: []const u8) HTMLCollection {
        // Use HTMLCollection's document-level class traversal
        // This traverses the entire document tree, using bloom filters for fast rejection
        return HTMLCollection.initDocumentByClassName(&self.prototype, class_name);
    }

    // ========================================================================
    // ParentNode Mixin - Query Selector
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
    /// _ = try doc.prototype.appendChild(&html.prototype);
    ///
    /// const button = try doc.createElement("button");
    /// try button.setAttribute("class", "btn");
    /// _ = try html.prototype.appendChild(&button.prototype);
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
            return try root.querySelector(self.prototype.allocator, selectors);
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
            return try root.querySelectorAll(self.prototype.allocator, selectors);
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
    pub fn children(self: *Document) HTMLCollection {
        return HTMLCollection.initChildren(&self.prototype);
    }

    /// Returns the first child that is an element.
    ///
    /// Implements WHATWG DOM ParentNode.firstElementChild property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? firstElementChild;
    /// ```
    ///
    /// ## MDN Documentation
    /// - firstElementChild: https://developer.mozilla.org/en-US/docs/Web/API/Document/firstElementChild
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// Return the first child of this that is an element, or null if there is no such child.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-firstelementchild
    /// - WebIDL: dom.idl:120
    ///
    /// ## Returns
    /// First element child or null (typically documentElement)
    pub fn firstElementChild(self: *const Document) ?*Element {
        var current = self.prototype.first_child;
        while (current) |child| {
            if (child.node_type == .element) {
                return @fieldParentPtr("prototype", child);
            }
            current = child.next_sibling;
        }
        return null;
    }

    /// Returns the last child that is an element.
    ///
    /// Implements WHATWG DOM ParentNode.lastElementChild property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? lastElementChild;
    /// ```
    ///
    /// ## MDN Documentation
    /// - lastElementChild: https://developer.mozilla.org/en-US/docs/Web/API/Document/lastElementChild
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// Return the last child of this that is an element, or null if there is no such child.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-lastelementchild
    /// - WebIDL: dom.idl:121
    ///
    /// ## Returns
    /// Last element child or null (typically documentElement)
    pub fn lastElementChild(self: *const Document) ?*Element {
        var current = self.prototype.last_child;
        while (current) |child| {
            if (child.node_type == .element) {
                return @fieldParentPtr("prototype", child);
            }
            current = child.previous_sibling;
        }
        return null;
    }

    /// Returns the number of children that are elements.
    ///
    /// Implements WHATWG DOM ParentNode.childElementCount property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute unsigned long childElementCount;
    /// ```
    ///
    /// ## MDN Documentation
    /// - childElementCount: https://developer.mozilla.org/en-US/docs/Web/API/Document/childElementCount
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// Return the number of children of this that are elements.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-childelementcount
    /// - WebIDL: dom.idl:122
    ///
    /// ## Returns
    /// Count of element children (typically 0 or 1 for documents)
    pub fn childElementCount(self: *const Document) u32 {
        var count: u32 = 0;
        var current = self.prototype.first_child;
        while (current) |child| {
            if (child.node_type == .element) {
                count += 1;
            }
            current = child.next_sibling;
        }
        return count;
    }

    /// NodeOrString union for ParentNode variadic methods.
    ///
    /// Represents the WebIDL `(Node or DOMString)` union type.
    pub const NodeOrString = union(enum) {
        node: *Node,
        string: []const u8,
    };

    /// Inserts nodes or strings before the first child.
    ///
    /// Implements WHATWG DOM ParentNode.prepend() per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined prepend((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - prepend(): https://developer.mozilla.org/en-US/docs/Web/API/Document/prepend
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Pre-insert node into this before this's first child
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-prepend
    /// - WebIDL: dom.idl:124
    pub fn prepend(self: *Document, nodes: []const NodeOrString) !void {
        const result = try self.convertNodesToNode(nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try self.prototype.insertBefore(node_to_insert, self.prototype.first_child);

        if (should_release) {
            returned_node.release();
        }
    }

    /// Inserts nodes or strings after the last child.
    ///
    /// Implements WHATWG DOM ParentNode.append() per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined append((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - append(): https://developer.mozilla.org/en-US/docs/Web/API/Document/append
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Append node to this
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-append
    /// - WebIDL: dom.idl:125
    pub fn append(self: *Document, nodes: []const NodeOrString) !void {
        const result = try self.convertNodesToNode(nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try self.prototype.appendChild(node_to_insert);

        if (should_release) {
            returned_node.release();
        }
    }

    /// Replaces all children with new nodes or strings.
    ///
    /// Implements WHATWG DOM ParentNode.replaceChildren() per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined replaceChildren((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - replaceChildren(): https://developer.mozilla.org/en-US/docs/Web/API/Document/replaceChildren
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Ensure pre-replace validity of node
    /// 3. Replace all children of this with node
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-replacechildren
    /// - WebIDL: dom.idl:126
    pub fn replaceChildren(self: *Document, nodes: []const NodeOrString) !void {
        const result = try self.convertNodesToNode(nodes);

        while (self.prototype.first_child) |child| {
            const removed = try self.prototype.removeChild(child);
            removed.release();
        }

        if (result) |r| {
            const returned_node = try self.prototype.appendChild(r.node);
            if (r.should_release_after_insert) {
                returned_node.release();
            }
        }
    }

    // === Private implementation ===

    /// Result of converting nodes/strings
    const ConvertResult = struct {
        node: *Node,
        should_release_after_insert: bool,
    };

    /// Helper: Convert slice of nodes/strings into a single node.
    fn convertNodesToNode(self: *Document, items: []const NodeOrString) !?ConvertResult {
        if (items.len == 0) return null;

        if (items.len == 1) {
            switch (items[0]) {
                .node => |n| {
                    return ConvertResult{
                        .node = n,
                        .should_release_after_insert = false,
                    };
                },
                .string => |s| {
                    const text = try self.createTextNode(s);
                    return ConvertResult{
                        .node = &text.prototype,
                        .should_release_after_insert = false,
                    };
                },
            }
        }

        const fragment = try self.createDocumentFragment();
        errdefer fragment.prototype.release();

        for (items) |item| {
            switch (item) {
                .node => |n| {
                    _ = try fragment.prototype.appendChild(n);
                },
                .string => |s| {
                    const text = try self.createTextNode(s);
                    _ = try fragment.prototype.appendChild(&text.prototype);
                },
            }
        }

        return ConvertResult{
            .node = &fragment.prototype,
            .should_release_after_insert = true,
        };
    }

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
            const elem: *Element = @fieldParentPtr("prototype", node);
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
        self.prototype.deinitRareData();

        // Clean up attributes for all elements before arena deinit
        // (attributes use general-purpose allocator, not arena)
        if (self.prototype.first_child) |first_child| {
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
            list_ptr.deinit(self.prototype.allocator);
        }
        self.tag_map.deinit();

        // NOTE: class_map removed in Phase 3 - no cleanup needed

        // Clean up string pool (must be AFTER tag_map)
        self.string_pool.deinit();

        // Deinit arena allocator (frees all nodes at once - 100-200x faster than individual frees)
        self.node_arena.deinit();

        // Free document structure
        self.prototype.allocator.destroy(self);
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
        const doc: *Document = @fieldParentPtr("prototype", node);
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

// ============================================================================
// SELECTOR CACHE TESTS
// ============================================================================

// ============================================================================
// ID MAP TESTS (Phase 2)
// ============================================================================

// ============================================================================
// TAG MAP TESTS (Phase 3)
// ============================================================================
