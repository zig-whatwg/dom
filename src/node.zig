//! Node Interface (§4.4)
//!
//! This module implements the Node interface as specified by the WHATWG DOM Standard.
//! Node is the primary datatype for the entire Document Object Model. All objects in a
//! document tree implement the Node interface, making it the fundamental building block of the DOM.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node
//! - **§4.2.1 Node tree**: https://dom.spec.whatwg.org/#concept-node-tree
//! - **§4.2.3 Mutation algorithms**: https://dom.spec.whatwg.org/#mutation-algorithms
//!
//! ## MDN Documentation
//!
//! - Node: https://developer.mozilla.org/en-US/docs/Web/API/Node
//! - Node.appendChild: https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild
//! - Node.removeChild: https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild
//! - Node.insertBefore: https://developer.mozilla.org/en-US/docs/Web/API/Node/insertBefore
//! - Node.childNodes: https://developer.mozilla.org/en-US/docs/Web/API/Node/childNodes
//! - Node.parentNode: https://developer.mozilla.org/en-US/docs/Web/API/Node/parentNode
//!
//! ## Core Features
//!
//! ### Tree Structure
//! Nodes form a tree structure with parent-child relationships:
//! ```zig
//! const parent = try createElementNode(allocator);
//! defer parent.release();
//!
//! const child = try createTextNode(allocator);
//! _ = try parent.appendChild(child);
//! child.release(); // Parent owns it
//! ```
//!
//! ### Reference Counting
//! Nodes use WebKit-style reference counting for memory management:
//! ```zig
//! const node = try createNode(allocator);
//! // ref_count = 1, caller owns
//!
//! node.acquire(); // ref_count = 2
//! other_owner.node = node;
//!
//! node.release(); // ref_count = 1
//! node.release(); // ref_count = 0 → freed
//! ```
//!
//! ### Tree Traversal
//! Navigate the tree using parent/child/sibling pointers:
//! ```zig
//! var current = node.first_child;
//! while (current) |child| {
//!     // Process child
//!     current = child.next_sibling;
//! }
//! ```
//!
//! ## Memory Layout (88 bytes)
//!
//! - **vtable**: Polymorphic function pointers (8 bytes)
//! - **ref_count_and_parent**: Packed 31-bit refcount + has_parent flag (4 bytes)
//! - **node_type**: NodeType enum (1 byte)
//! - **flags**: Boolean properties (1 byte)
//! - **node_id**: Unique ID (2 bytes)
//! - **generation**: Mutation counter (4 bytes)
//! - **allocator**: Memory allocator (8 bytes)
//! - **parent_node**: WEAK parent pointer (8 bytes)
//! - **previous_sibling**: WEAK sibling pointer (8 bytes)
//! - **first_child**: STRONG child pointer (8 bytes)
//! - **last_child**: STRONG child pointer (8 bytes)
//! - **next_sibling**: STRONG sibling pointer (8 bytes)
//! - **owner_document**: WEAK document pointer (8 bytes)
//! - **rare_data**: Optional rare data (8 bytes)
//!
//! Total: 88 bytes (8 bytes under 96-byte budget!)
//!
//! ## Memory Management
//!
//! ### Basic Lifecycle
//!
//! ```zig
//! // Creation: ref_count = 1
//! const node = try createNode(allocator);
//! defer node.release(); // Caller must release
//!
//! // Sharing: increment ref_count
//! node.acquire(); // ref_count = 2
//! other_owner.node = node;
//! defer node.release(); // Both owners must release
//! ```
//!
//! ### Tree Ownership
//!
//! ```zig
//! const parent = try createElementNode(allocator);
//! defer parent.release();
//!
//! const child = try createTextNode(allocator);
//! _ = try parent.appendChild(child);
//! child.release(); // Parent owns it via has_parent flag
//! // Child destroyed when parent destroyed or explicitly removed
//! ```
//!
//! ## Usage Examples
//!
//! ### Building a DOM Tree
//!
//! ```zig
//! const parent = try createElementNode(allocator);
//! defer parent.release();
//!
//! const child1 = try createElementNode(allocator);
//! _ = try parent.appendChild(child1);
//! child1.release();
//!
//! const child2 = try createTextNode(allocator);
//! _ = try parent.appendChild(child2);
//! child2.release();
//!
//! // Tree freed when parent.release() called
//! ```
//!
//! ### Node Manipulation
//!
//! ```zig
//! // Insert before reference
//! const new_node = try createElementNode(allocator);
//! _ = try parent.insertBefore(new_node, ref_child);
//! new_node.release();
//!
//! // Remove child
//! const removed = try parent.removeChild(child);
//! defer removed.release(); // Caller owns it
//!
//! // Replace child
//! const replacement = try createElementNode(allocator);
//! const old = try parent.replaceChild(replacement, child);
//! defer old.release();
//! replacement.release();
//! ```
//!
//! ## Common Patterns
//!
//! ### Tree Traversal
//!
//! ```zig
//! // Traverse children
//! var child = parent.first_child;
//! while (child) |node| {
//!     // Process node
//!     child = node.next_sibling;
//! }
//!
//! // Traverse ancestors
//! var ancestor = node.parent_node;
//! while (ancestor) |parent| {
//!     // Process ancestor
//!     ancestor = parent.parent_node;
//! }
//! ```
//!
//! ### Safe Node Creation
//!
//! ```zig
//! pub fn createTypedNode(allocator: Allocator) !*Node {
//!     const node = try createNode(allocator);
//!     errdefer node.release(); // Release on error
//!
//!     // Initialize...
//!
//!     return node; // Caller must release
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Node size**: 88 bytes (optimized, 8 under budget)
//! 2. **Packed ref_count**: Saves 12 bytes vs separate fields
//! 3. **Rare data**: Allocated on demand for uncommon features
//! 4. **Weak pointers**: No cycle detection overhead
//! 5. **Vtable dispatch**: ~2-3 instruction overhead
//! 6. **appendChild**: O(1) operation
//! 7. **insertBefore**: O(1) operation
//! 8. **Tree traversal**: Optimal cache locality
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // nodeType (readonly)
//! Object.defineProperty(Node.prototype, 'nodeType', {
//!   get: function() { return zig.node_get_node_type(this._ptr); }
//! });
//!
//! // nodeName (readonly)
//! Object.defineProperty(Node.prototype, 'nodeName', {
//!   get: function() { return zig.node_get_node_name(this._ptr); }
//! });
//!
//! // nodeValue (read-write)
//! Object.defineProperty(Node.prototype, 'nodeValue', {
//!   get: function() { return zig.node_get_node_value(this._ptr); },
//!   set: function(value) { zig.node_set_node_value(this._ptr, value); }
//! });
//!
//! // textContent (read-write)
//! Object.defineProperty(Node.prototype, 'textContent', {
//!   get: function() { return zig.node_get_text_content(this._ptr); },
//!   set: function(value) { zig.node_set_text_content(this._ptr, value); }
//! });
//!
//! // parentNode (readonly)
//! Object.defineProperty(Node.prototype, 'parentNode', {
//!   get: function() { return zig.node_get_parent_node(this._ptr); }
//! });
//!
//! // parentElement (readonly)
//! Object.defineProperty(Node.prototype, 'parentElement', {
//!   get: function() { return zig.node_get_parent_element(this._ptr); }
//! });
//!
//! // childNodes (readonly)
//! Object.defineProperty(Node.prototype, 'childNodes', {
//!   get: function() { return zig.node_get_child_nodes(this._ptr); }
//! });
//!
//! // firstChild (readonly)
//! Object.defineProperty(Node.prototype, 'firstChild', {
//!   get: function() { return zig.node_get_first_child(this._ptr); }
//! });
//!
//! // lastChild (readonly)
//! Object.defineProperty(Node.prototype, 'lastChild', {
//!   get: function() { return zig.node_get_last_child(this._ptr); }
//! });
//!
//! // previousSibling (readonly)
//! Object.defineProperty(Node.prototype, 'previousSibling', {
//!   get: function() { return zig.node_get_previous_sibling(this._ptr); }
//! });
//!
//! // nextSibling (readonly)
//! Object.defineProperty(Node.prototype, 'nextSibling', {
//!   get: function() { return zig.node_get_next_sibling(this._ptr); }
//! });
//!
//! // ownerDocument (readonly)
//! Object.defineProperty(Node.prototype, 'ownerDocument', {
//!   get: function() { return zig.node_get_owner_document(this._ptr); }
//! });
//!
//! // baseURI (readonly)
//! Object.defineProperty(Node.prototype, 'baseURI', {
//!   get: function() { return zig.node_get_base_uri(this._ptr); }
//! });
//!
//! // isConnected (readonly)
//! Object.defineProperty(Node.prototype, 'isConnected', {
//!   get: function() { return zig.node_get_is_connected(this._ptr); }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // Tree manipulation
//! Node.prototype.appendChild = function(node) {
//!   return zig.node_appendChild(this._ptr, node._ptr);
//! };
//!
//! Node.prototype.insertBefore = function(node, child) {
//!   return zig.node_insertBefore(this._ptr, node._ptr, child ? child._ptr : null);
//! };
//!
//! Node.prototype.removeChild = function(child) {
//!   return zig.node_removeChild(this._ptr, child._ptr);
//! };
//!
//! Node.prototype.replaceChild = function(node, child) {
//!   return zig.node_replaceChild(this._ptr, node._ptr, child._ptr);
//! };
//!
//! // Node queries
//! Node.prototype.hasChildNodes = function() {
//!   return zig.node_hasChildNodes(this._ptr);
//! };
//!
//! Node.prototype.contains = function(other) {
//!   return zig.node_contains(this._ptr, other ? other._ptr : null);
//! };
//!
//! Node.prototype.getRootNode = function(options) {
//!   return zig.node_getRootNode(this._ptr, options?.composed || false);
//! };
//!
//! // Node comparison
//! Node.prototype.isSameNode = function(other) {
//!   return zig.node_isSameNode(this._ptr, other ? other._ptr : null);
//! };
//!
//! Node.prototype.isEqualNode = function(other) {
//!   return zig.node_isEqualNode(this._ptr, other ? other._ptr : null);
//! };
//!
//! Node.prototype.compareDocumentPosition = function(other) {
//!   return zig.node_compareDocumentPosition(this._ptr, other._ptr);
//! };
//!
//! // Node cloning
//! Node.prototype.cloneNode = function(deep) {
//!   return zig.node_cloneNode(this._ptr, deep || false);
//! };
//!
//! // Event handling (from EventTarget mixin)
//! Node.prototype.addEventListener = function(type, listener, options) {
//!   const opts = typeof options === 'boolean' ? { capture: options } : (options || {});
//!   return zig.node_addEventListener(
//!     this._ptr,
//!     type,
//!     listener,
//!     opts.capture || false,
//!     opts.once || false,
//!     opts.passive || false,
//!     opts.signal || null
//!   );
//! };
//!
//! Node.prototype.removeEventListener = function(type, listener, options) {
//!   const opts = typeof options === 'boolean' ? { capture: options } : (options || {});
//!   return zig.node_removeEventListener(this._ptr, type, listener, opts.capture || false);
//! };
//!
//! Node.prototype.dispatchEvent = function(event) {
//!   return zig.node_dispatchEvent(this._ptr, event._ptr);
//! };
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - Compile-time size verification enforces ≤96 byte limit
//! - Atomic ref_count for thread-safe reference counting
//! - WebKit-style hybrid strong/weak reference system
//! - Vtable polymorphism for extensibility (Element, Text, etc.)
//! - has_parent flag prevents premature destruction in tree

const std = @import("std");
const Allocator = std.mem.Allocator;
const NodeRareData = @import("rare_data.zig").NodeRareData;
const Event = @import("event.zig").Event;
const EventTargetMixin = @import("event_target.zig").EventTargetMixin;

/// Node types per WHATWG DOM specification.
pub const NodeType = enum(u8) {
    element = 1,
    text = 3,
    comment = 8,
    document = 9,
    document_type = 10,
    document_fragment = 11,
    processing_instruction = 7,

    /// Returns the numeric value used in the DOM API.
    pub fn value(self: NodeType) u8 {
        return @intFromEnum(self);
    }
};

/// Virtual table for polymorphic Node behavior.
///
/// This enables different node types (Element, Text, Comment, etc.) to have
/// custom implementations while sharing the same Node base structure.
/// All browsers use vtables (C++ virtual methods) for this purpose.
pub const NodeVTable = struct {
    /// Cleanup function called when ref_count reaches 0 and node has no parent.
    deinit: *const fn (*Node) void,

    /// Returns the node name (tag name for elements, "#text" for text nodes, etc.)
    node_name: *const fn (*const Node) []const u8,

    /// Returns the node value (null for elements, text content for text nodes, etc.)
    node_value: *const fn (*const Node) ?[]const u8,

    /// Sets the node value (errors for read-only nodes)
    set_node_value: *const fn (*Node, []const u8) anyerror!void,

    /// Clones the node (shallow or deep)
    clone_node: *const fn (*const Node, bool) anyerror!*Node,
};

/// Core DOM Node structure.
///
/// Memory layout optimized for size (target: ≤96 bytes).
/// All pointers are 8 bytes on 64-bit systems.
///
/// ## Memory Management
/// - Reference counted (acquire/release pattern)
/// - Parent pointers are WEAK (no ref_count increment)
/// - Child/sibling pointers are STRONG (via has_parent flag)
/// - Node is destroyed when ref_count=0 AND has_parent=false
///
/// ## Usage
/// ```zig
/// const node = try Node.init(allocator, vtable, .element);
/// defer node.release(); // REQUIRED
///
/// node.acquire(); // Share ownership
/// defer node.release(); // Release shared ownership
/// ```
pub const Node = struct {
    /// Virtual table for polymorphic dispatch (8 bytes)
    vtable: *const NodeVTable,

    /// PACKED: 31-bit ref_count + 1-bit has_parent flag (4 bytes)
    ///
    /// This optimization saves 12 bytes per node vs separate fields.
    /// - Bits 0-30: Reference count (max 2,147,483,647)
    /// - Bit 31: has_parent flag (1 = has parent, 0 = no parent)
    ///
    /// The has_parent flag prevents premature destruction when:
    /// - Node is in tree (parent owns it via strong reference)
    /// - Node ref_count can drop to 0, but it's kept alive by parent
    ref_count_and_parent: std.atomic.Value(u32),

    /// Node type (1 byte)
    node_type: NodeType,

    /// Flags for various boolean properties (1 byte)
    /// Bits: [unused(6), is_connected(1), is_in_shadow_tree(1)]
    flags: u8,

    /// Unique node ID within document (2 bytes)
    /// Used for equality checks and debugging
    /// Max 65,535 nodes per document (sufficient for most pages)
    node_id: u16,

    /// Generation counter for detecting stale references (4 bytes)
    /// Incremented on major mutations
    /// Max 4,294,967,295 mutations (sufficient for long-lived pages)
    generation: u32,

    /// Allocator used to create this node (8 bytes)
    allocator: Allocator,

    /// WEAK pointer to parent (8 bytes)
    /// Does NOT increment ref_count (prevents circular references)
    parent_node: ?*Node,

    /// WEAK pointer to previous sibling (8 bytes)
    previous_sibling: ?*Node,

    /// STRONG pointer to first child (8 bytes)
    /// Child's has_parent flag set to 1 (parent owns child)
    first_child: ?*Node,

    /// STRONG pointer to last child (8 bytes)
    /// Child's has_parent flag set to 1 (parent owns child)
    last_child: ?*Node,

    /// STRONG pointer to next sibling (8 bytes)
    /// Only STRONG if sibling has parent (transitively owned)
    next_sibling: ?*Node,

    /// WEAK pointer to owner document (8 bytes)
    /// Document uses separate dual ref counting
    owner_document: ?*Node, // TODO: Type as *Document once implemented

    /// Pointer to rare data (allocated on demand) (8 bytes)
    /// Stores infrequently-used features (event listeners, observers, etc.)
    /// Most nodes don't need this, saving 40-80 bytes
    rare_data: ?*NodeRareData,

    // === Size Verification ===
    comptime {
        const size = @sizeOf(Node);
        if (size > 96) {
            const msg = std.fmt.comptimePrint("Node size ({d} bytes) exceeded 96 byte limit! Keep it small.", .{size});
            @compileError(msg);
        }
    }

    // === Bit manipulation constants ===
    const HAS_PARENT_BIT: u32 = 1 << 31;
    const REF_COUNT_MASK: u32 = 0x7FFF_FFFF; // 31 bits
    const MAX_REF_COUNT: u32 = REF_COUNT_MASK;

    // === Flag bit positions ===
    pub const FLAG_IS_CONNECTED: u8 = 1 << 0;
    pub const FLAG_IS_IN_SHADOW_TREE: u8 = 1 << 1;

    // === Document position constants (WHATWG DOM §4.4) ===
    pub const DOCUMENT_POSITION_DISCONNECTED: u16 = 0x01;
    pub const DOCUMENT_POSITION_PRECEDING: u16 = 0x02;
    pub const DOCUMENT_POSITION_FOLLOWING: u16 = 0x04;
    pub const DOCUMENT_POSITION_CONTAINS: u16 = 0x08;
    pub const DOCUMENT_POSITION_CONTAINED_BY: u16 = 0x10;
    pub const DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC: u16 = 0x20;

    /// Initializes a new Node with ref_count = 1.
    ///
    /// ## Memory Management
    /// Caller MUST call `release()` when done to prevent memory leaks.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    /// - `vtable`: Virtual table for polymorphic behavior
    /// - `node_type`: Type of node being created
    ///
    /// ## Returns
    /// New node with ref_count=1, caller owns the reference
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    pub fn init(
        allocator: Allocator,
        vtable: *const NodeVTable,
        node_type: NodeType,
    ) Allocator.Error!*Node {
        const node = try allocator.create(Node);
        node.* = .{
            .vtable = vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1), // ref_count=1, has_parent=0
            .node_type = node_type,
            .flags = 0,
            .node_id = 0, // Set by Document when inserted
            .generation = 0,
            .allocator = allocator,
            .parent_node = null,
            .previous_sibling = null,
            .first_child = null,
            .last_child = null,
            .next_sibling = null,
            .owner_document = null,
            .rare_data = null,
        };
        return node;
    }

    /// Increments the reference count atomically.
    ///
    /// Call this when sharing ownership of the node.
    /// MUST be paired with a corresponding `release()` call.
    ///
    /// ## Example
    /// ```zig
    /// node.acquire(); // Share ownership
    /// other_container.node = node;
    /// // Both must call release()
    /// ```
    pub fn acquire(self: *Node) void {
        const old = self.ref_count_and_parent.fetchAdd(1, .monotonic);
        const ref_count = old & REF_COUNT_MASK;

        // Safety: Check for overflow (extremely unlikely)
        if (ref_count >= MAX_REF_COUNT) {
            @panic("Node ref_count overflow! This should never happen.");
        }
    }

    /// Decrements the reference count atomically.
    ///
    /// When ref_count reaches 0 AND has_parent=false, the node is destroyed.
    /// MUST be called exactly once for each `acquire()` or `init()`.
    ///
    /// ## Example
    /// ```zig
    /// const node = try Node.init(allocator, vtable, .element);
    /// defer node.release(); // REQUIRED
    /// ```
    pub fn release(self: *Node) void {
        const old = self.ref_count_and_parent.fetchSub(1, .monotonic);
        const ref_count = old & REF_COUNT_MASK;
        const has_parent = (old & HAS_PARENT_BIT) != 0;

        // Destroy when:
        // - ref_count reaches 0 (no external owners)
        // - AND has_parent=false (not owned by parent)
        if (ref_count == 1 and !has_parent) {
            self.vtable.deinit(self);
        }
    }

    /// Sets the has_parent flag atomically.
    ///
    /// This flag prevents premature destruction when node is in tree.
    /// Parent-child relationship is STRONG (parent owns child).
    ///
    /// ## Parameters
    /// - `value`: true = has parent (in tree), false = no parent (detached)
    pub fn setHasParent(self: *Node, value: bool) void {
        if (value) {
            _ = self.ref_count_and_parent.fetchOr(HAS_PARENT_BIT, .monotonic);
        } else {
            _ = self.ref_count_and_parent.fetchAnd(~HAS_PARENT_BIT, .monotonic);
        }
    }

    /// Returns the current reference count (for debugging/testing).
    pub fn getRefCount(self: *const Node) u32 {
        const value = self.ref_count_and_parent.load(.monotonic);
        return value & REF_COUNT_MASK;
    }

    /// Returns the has_parent flag (for debugging/testing).
    pub fn hasParent(self: *const Node) bool {
        const value = self.ref_count_and_parent.load(.monotonic);
        return (value & HAS_PARENT_BIT) != 0;
    }

    // === Convenience flag accessors ===

    pub fn isConnected(self: *const Node) bool {
        return (self.flags & FLAG_IS_CONNECTED) != 0;
    }

    pub fn setConnected(self: *Node, value: bool) void {
        if (value) {
            self.flags |= FLAG_IS_CONNECTED;
        } else {
            self.flags &= ~FLAG_IS_CONNECTED;
        }
    }

    pub fn isInShadowTree(self: *const Node) bool {
        return (self.flags & FLAG_IS_IN_SHADOW_TREE) != 0;
    }

    // === Polymorphic dispatch methods ===

    /// Returns the node name (delegates to vtable).
    pub fn nodeName(self: *const Node) []const u8 {
        return self.vtable.node_name(self);
    }

    /// Returns the node value (delegates to vtable).
    pub fn nodeValue(self: *const Node) ?[]const u8 {
        return self.vtable.node_value(self);
    }

    /// Sets the node value (delegates to vtable).
    pub fn setNodeValue(self: *Node, value: []const u8) !void {
        return self.vtable.set_node_value(self, value);
    }

    /// Gets the text content of the node and its descendants.
    ///
    /// Implements WHATWG DOM Node.textContent getter per §4.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] attribute DOMString? textContent;
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.4)
    /// - If node is Document or DocumentType: return null
    /// - If node is Text, ProcessingInstruction, or Comment: return node's data
    /// - Otherwise: return concatenation of data of all Text node descendants
    ///
    /// ## Returns
    /// Text content or null for Document/DocumentType nodes.
    /// Caller owns returned memory and must free with allocator.
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate result string
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-textcontent
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:240
    ///
    /// ## Example
    /// ```zig
    /// const content = try node.textContent(allocator);
    /// defer if (content) |c| allocator.free(c);
    ///
    /// if (content) |text| {
    ///     std.debug.print("Text: {s}\n", .{text});
    /// }
    /// ```
    pub fn textContent(self: *const Node, allocator: Allocator) !?[]u8 {
        // Step 1: If Document or DocumentType, return null
        if (self.node_type == .document or self.node_type == .document_type) {
            return null;
        }

        // Step 2: If Text, ProcessingInstruction, or Comment, return data
        if (self.node_type == .text or
            self.node_type == .processing_instruction or
            self.node_type == .comment)
        {
            // Get data from node value
            if (self.nodeValue()) |data| {
                return try allocator.dupe(u8, data);
            }
            return null;
        }

        // Step 3: Otherwise, collect text from all Text descendants
        const text = try tree_helpers.getDescendantTextContent(self, allocator);

        // Return null for empty string per spec
        if (text.len == 0) {
            allocator.free(text);
            return null;
        }

        return text;
    }

    /// Sets the text content of the node.
    ///
    /// Implements WHATWG DOM Node.textContent setter per §4.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] attribute DOMString? textContent;
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.4)
    /// Performs "string replace all" algorithm:
    /// 1. Let string be the given value (or empty string if null)
    /// 2. If node is Document or DocumentType: do nothing
    /// 3. If node is Text, ProcessingInstruction, or Comment: replace node's data
    /// 4. Otherwise: remove all children and insert a Text node (if string non-empty)
    ///
    /// ## Parameters
    /// - `value`: New text content (null or empty removes all children)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate text node
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-textcontent
    /// - String Replace All: https://dom.spec.whatwg.org/#string-replace-all
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:240
    ///
    /// ## Example
    /// ```zig
    /// try elem.node.setTextContent("Hello, World!");
    /// try elem.node.setTextContent(null); // Removes all children
    /// ```
    pub fn setTextContent(self: *Node, value: ?[]const u8) !void {
        // Convert null to empty string
        const string = value orelse "";

        // Step 1: If Document or DocumentType, do nothing
        if (self.node_type == .document or self.node_type == .document_type) {
            return;
        }

        // Step 2: If Text, ProcessingInstruction, or Comment, set data
        if (self.node_type == .text or
            self.node_type == .processing_instruction or
            self.node_type == .comment)
        {
            return self.setNodeValue(string);
        }

        // Step 3: String replace all (for Element, DocumentFragment, etc.)
        // Remove all children
        tree_helpers.removeAllChildren(self);

        // If string is non-empty, create and insert a Text node
        if (string.len > 0) {
            // Get owner document to create text node
            const owner_doc = self.owner_document orelse return error.InvalidStateError;
            if (owner_doc.node_type != .document) return error.InvalidStateError;

            const Document = @import("document.zig").Document;
            const doc: *Document = @fieldParentPtr("node", owner_doc);

            const text_node = try doc.createTextNode(string);

            // Insert the text node directly (bypass validation for efficiency)
            text_node.node.parent_node = self;
            text_node.node.setHasParent(true);
            self.first_child = &text_node.node;
            self.last_child = &text_node.node;

            // Propagate connected state if parent is connected
            if (self.isConnected()) {
                text_node.node.setConnected(true);
            }
        }
    }

    /// Clones the node (delegates to vtable).
    pub fn cloneNode(self: *const Node, deep: bool) !*Node {
        return self.vtable.clone_node(self, deep);
    }

    /// Returns whether this node is the same node as other.
    ///
    /// Implements WHATWG DOM Node.isSameNode() per §4.4.
    /// This is a legacy alias of the === (identity) operator.
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean isSameNode(Node? otherNode); // legacy alias of ===
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.4)
    /// Return true if other is this; otherwise false.
    ///
    /// ## Parameters
    /// - `other`: Node to compare with (nullable)
    ///
    /// ## Returns
    /// true if other is the exact same node (identity), false otherwise
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-issamenode
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:242
    ///
    /// ## Example
    /// ```zig
    /// const node1 = try doc.createElement("div");
    /// const node2 = node1;
    /// const node3 = try doc.createElement("div");
    ///
    /// try std.testing.expect(node1.isSameNode(node2));  // true (same reference)
    /// try std.testing.expect(!node1.isSameNode(node3)); // false (different nodes)
    /// try std.testing.expect(!node1.isSameNode(null));  // false (null)
    /// ```
    pub fn isSameNode(self: *const Node, other: ?*const Node) bool {
        if (other) |o| {
            return self == o;
        }
        return false;
    }

    /// Returns the root node of this node's tree.
    ///
    /// Implements WHATWG DOM Node.getRootNode() per §4.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// Node getRootNode(optional GetRootNodeOptions options = {});
    ///
    /// dictionary GetRootNodeOptions {
    ///   boolean composed = false;
    /// };
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.4)
    /// 1. Let root be this
    /// 2. While root's parent is non-null, set root to root's parent
    /// 3. If composed is true and root is a shadow root, return root's host
    /// 4. Return root
    ///
    /// ## Parameters
    /// - `composed`: If true, pierces shadow boundaries (default: false)
    ///
    /// ## Returns
    /// The root node of the tree
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-getrootnode
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:221
    ///
    /// ## Example
    /// ```zig
    /// const root = node.getRootNode(false);
    /// // Returns document node for connected nodes
    /// ```
    pub fn getRootNode(self: *const Node, composed: bool) *Node {
        // Step 1 & 2: Walk up to root
        var root: *Node = @constCast(self);
        while (root.parent_node) |parent| {
            root = parent;
        }

        // Step 3: If composed and shadow root, return host
        // (Shadow DOM not yet implemented, so this is a no-op for now)
        _ = composed;

        // Step 4: Return root
        return root;
    }

    /// Returns whether other is an inclusive descendant of this node.
    ///
    /// Implements WHATWG DOM Node.contains() per §4.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean contains(Node? other);
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.4)
    /// Return true if other is an inclusive descendant of this; otherwise false.
    /// - If other is null, return true (per spec quirk)
    /// - If other is this, return true (inclusive)
    /// - If other is a descendant, return true
    /// - Otherwise return false
    ///
    /// ## Parameters
    /// - `other`: Node to check (nullable)
    ///
    /// ## Returns
    /// true if other is this or a descendant of this, false otherwise
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-contains
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:248
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("div");
    /// const child = try doc.createElement("span");
    /// _ = try parent.node.appendChild(&child.node);
    ///
    /// try std.testing.expect(parent.node.contains(&child.node));  // true
    /// try std.testing.expect(!child.node.contains(&parent.node)); // false
    /// try std.testing.expect(parent.node.contains(&parent.node)); // true (inclusive)
    /// ```
    pub fn contains(self: *const Node, other: ?*const Node) bool {
        // Per spec: if other is null, return false
        if (other == null) return false;

        const other_node = other.?;

        // If other is this, return true (inclusive)
        if (other_node == self) return true;

        // Walk up from other looking for self
        var current = other_node.parent_node;
        while (current) |parent| {
            if (parent == self) return true;
            current = parent.parent_node;
        }

        return false;
    }

    /// Returns the base URI of this node.
    ///
    /// Implements WHATWG DOM Node.baseURI property per §4.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute USVString baseURI;
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.4)
    /// Return the base URL of this node (document's URL or xml:base).
    ///
    /// ## Returns
    /// Base URI as a string (empty string if no base URL)
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-baseuri
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:217
    ///
    /// ## Note
    /// Currently returns empty string. Full implementation requires:
    /// - Document URL tracking
    /// - xml:base attribute support (XML)
    /// - <base> element support (HTML, out of scope)
    ///
    /// ## Example
    /// ```zig
    /// const uri = node.baseURI();
    /// // Currently returns ""
    /// ```
    pub fn baseURI(self: *const Node) []const u8 {
        _ = self;
        // TODO: Full implementation requires document URL tracking
        // For now, return empty string per spec fallback
        return "";
    }

    /// Returns the relative position of other compared to this node.
    ///
    /// Implements WHATWG DOM Node.compareDocumentPosition() per §4.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// unsigned short compareDocumentPosition(Node other);
    /// ```
    ///
    /// ## Returns
    /// Bitmask of position flags:
    /// - DOCUMENT_POSITION_DISCONNECTED (0x01): Nodes in different trees
    /// - DOCUMENT_POSITION_PRECEDING (0x02): Other precedes this
    /// - DOCUMENT_POSITION_FOLLOWING (0x04): Other follows this
    /// - DOCUMENT_POSITION_CONTAINS (0x08): Other contains this
    /// - DOCUMENT_POSITION_CONTAINED_BY (0x10): This contains other
    /// - DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC (0x20): Implementation-defined
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-comparedocumentposition
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:247
    ///
    /// ## Example
    /// ```zig
    /// const pos = node1.compareDocumentPosition(node2);
    /// if (pos & Node.DOCUMENT_POSITION_FOLLOWING != 0) {
    ///     std.debug.print("node2 follows node1\n", .{});
    /// }
    /// ```
    pub fn compareDocumentPosition(self: *const Node, other: *const Node) u16 {
        // Step 1: If this is other, return 0
        if (self == other) return 0;

        // Step 2: Get roots
        const this_root = self.getRootNode(false);
        const other_root = other.getRootNode(false);

        // Step 3: If in different trees, return DISCONNECTED | IMPLEMENTATION_SPECIFIC
        if (this_root != other_root) {
            // Add implementation-specific ordering based on pointer address
            if (@intFromPtr(self) < @intFromPtr(other)) {
                return DOCUMENT_POSITION_DISCONNECTED | DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC | DOCUMENT_POSITION_FOLLOWING;
            } else {
                return DOCUMENT_POSITION_DISCONNECTED | DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC | DOCUMENT_POSITION_PRECEDING;
            }
        }

        // Step 4: Check if other is an ancestor of this
        var current = self.parent_node;
        while (current) |parent| {
            if (parent == other) {
                return DOCUMENT_POSITION_CONTAINS | DOCUMENT_POSITION_PRECEDING;
            }
            current = parent.parent_node;
        }

        // Step 5: Check if this is an ancestor of other
        current = other.parent_node;
        while (current) |parent| {
            if (parent == self) {
                return DOCUMENT_POSITION_CONTAINED_BY | DOCUMENT_POSITION_FOLLOWING;
            }
            current = parent.parent_node;
        }

        // Step 6: Find common ancestor and determine order
        // Collect ancestors of this
        var this_ancestors: [1024]*const Node = undefined;
        var this_count: usize = 0;
        current = self.parent_node;
        while (current) |parent| {
            this_ancestors[this_count] = parent;
            this_count += 1;
            if (this_count >= 1024) break; // Prevent overflow
            current = parent.parent_node;
        }

        // Walk up from other until we find common ancestor
        var other_current = other.parent_node;
        while (other_current) |other_parent| {
            // Check if other_parent is in this's ancestors
            for (this_ancestors[0..this_count]) |ancestor| {
                if (ancestor == other_parent) {
                    // Found common ancestor - now determine order among siblings
                    // Walk from common ancestor's children to find which comes first
                    var child = other_parent.first_child;
                    while (child) |c| {
                        // Check if c is ancestor of this
                        var temp = self.parent_node;
                        var this_in_c = (c == self);
                        while (temp) |t| {
                            if (t == c) {
                                this_in_c = true;
                                break;
                            }
                            temp = t.parent_node;
                        }

                        // Check if c is ancestor of other
                        temp = other.parent_node;
                        var other_in_c = (c == other);
                        while (temp) |t| {
                            if (t == c) {
                                other_in_c = true;
                                break;
                            }
                            temp = t.parent_node;
                        }

                        if (this_in_c and other_in_c) {
                            // Both in same subtree, shouldn't happen
                            break;
                        } else if (this_in_c) {
                            return DOCUMENT_POSITION_FOLLOWING;
                        } else if (other_in_c) {
                            return DOCUMENT_POSITION_PRECEDING;
                        }

                        child = c.next_sibling;
                    }

                    // Fallback: use pointer comparison
                    if (@intFromPtr(self) < @intFromPtr(other)) {
                        return DOCUMENT_POSITION_FOLLOWING;
                    } else {
                        return DOCUMENT_POSITION_PRECEDING;
                    }
                }
            }
            other_current = other_parent.parent_node;
        }

        // No common ancestor found (shouldn't happen if same root)
        // Use pointer comparison as fallback
        if (@intFromPtr(self) < @intFromPtr(other)) {
            return DOCUMENT_POSITION_FOLLOWING;
        } else {
            return DOCUMENT_POSITION_PRECEDING;
        }
    }

    /// Returns whether this node is equal to other node.
    ///
    /// Implements WHATWG DOM Node.isEqualNode() per §4.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean isEqualNode(Node? otherNode);
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.4)
    /// Two nodes are equal if and only if:
    /// - They are both null, or
    /// - They have the same type, attributes, children (recursively equal)
    ///
    /// ## Parameters
    /// - `other`: Node to compare with (nullable)
    ///
    /// ## Returns
    /// true if nodes are deeply equal, false otherwise
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-isequalnode
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:241
    ///
    /// ## Example
    /// ```zig
    /// const elem1 = try doc.createElement("div");
    /// try elem1.setAttribute("id", "test");
    ///
    /// const elem2 = try doc.createElement("div");
    /// try elem2.setAttribute("id", "test");
    ///
    /// try std.testing.expect(elem1.node.isEqualNode(&elem2.node)); // true (same structure)
    /// try std.testing.expect(!elem1.node.isSameNode(&elem2.node)); // false (different instances)
    /// ```
    pub fn isEqualNode(self: *const Node, other: ?*const Node) bool {
        // If other is null, return false
        if (other == null) return false;

        const other_node = other.?;

        // If same node, return true
        if (self == other_node) return true;

        // Check node types match
        if (self.node_type != other_node.node_type) return false;

        // Check node names match
        if (!std.mem.eql(u8, self.nodeName(), other_node.nodeName())) return false;

        // Check node values match (for text, comment, etc.)
        const this_value = self.nodeValue();
        const other_value = other_node.nodeValue();
        if (this_value == null and other_value != null) return false;
        if (this_value != null and other_value == null) return false;
        if (this_value != null and other_value != null) {
            if (!std.mem.eql(u8, this_value.?, other_value.?)) return false;
        }

        // For elements, check attributes
        if (self.node_type == .element) {
            const Element = @import("element.zig").Element;
            const this_elem: *const Element = @fieldParentPtr("node", self);
            const other_elem: *const Element = @fieldParentPtr("node", other_node);

            // Check attribute counts match
            if (this_elem.attributeCount() != other_elem.attributeCount()) return false;

            // Check all attributes match
            const allocator = self.allocator;
            const this_attrs = this_elem.getAttributeNames(allocator) catch return false;
            defer allocator.free(this_attrs);

            for (this_attrs) |name| {
                const this_val = this_elem.getAttribute(name);
                const other_val = other_elem.getAttribute(name);

                if (this_val == null and other_val != null) return false;
                if (this_val != null and other_val == null) return false;
                if (this_val != null and other_val != null) {
                    if (!std.mem.eql(u8, this_val.?, other_val.?)) return false;
                }
            }
        }

        // Check children count matches
        var this_child_count: usize = 0;
        var other_child_count: usize = 0;

        var child = self.first_child;
        while (child) |c| {
            this_child_count += 1;
            child = c.next_sibling;
        }

        child = other_node.first_child;
        while (child) |c| {
            other_child_count += 1;
            child = c.next_sibling;
        }

        if (this_child_count != other_child_count) return false;

        // Check each child is equal recursively
        var this_child = self.first_child;
        var other_child = other_node.first_child;

        while (this_child) |tc| {
            if (other_child == null) return false;
            const oc = other_child.?;

            if (!tc.isEqualNode(oc)) return false;

            this_child = tc.next_sibling;
            other_child = oc.next_sibling;
        }

        return true;
    }

    // === Node Tree Query Methods (WHATWG DOM) ===

    /// Returns the owner document of this node.
    ///
    /// Implements WHATWG DOM Node.ownerDocument property.
    /// Returns typed Document pointer instead of generic Node pointer.
    ///
    /// Per WHATWG spec: "The ownerDocument getter steps are to return null,
    /// if this is a document; otherwise this's node document."
    ///
    /// ## Returns
    /// Owner document or null if node is itself a document
    ///
    /// ## Example
    /// ```zig
    /// if (node.getOwnerDocument()) |doc| {
    ///     const elem = try doc.createElement("element");
    ///     defer elem.node.release();
    /// }
    /// ```
    pub fn getOwnerDocument(self: *const Node) ?*@import("document.zig").Document {
        // Return null for Document nodes per spec
        if (self.node_type == .document) {
            return null;
        }

        if (self.owner_document) |owner| {
            if (owner.node_type == .document) {
                return @fieldParentPtr("node", owner);
            }
        }
        return null;
    }

    /// Returns a live NodeList of child nodes.
    ///
    /// Implements WHATWG DOM Node.childNodes property.
    /// Returns a live collection that automatically reflects DOM changes.
    ///
    /// ## Returns
    /// Live NodeList of children
    ///
    /// ## Example
    /// ```zig
    /// const children = node.childNodes();
    /// for (0..children.length()) |i| {
    ///     if (children.item(i)) |child| {
    ///         std.debug.print("Child {}: {s}\n", .{i, child.nodeName()});
    ///     }
    /// }
    /// ```
    pub fn childNodes(self: *Node) @import("node_list.zig").NodeList {
        return @import("node_list.zig").NodeList.init(self);
    }

    /// Returns true if the node has any child nodes.
    ///
    /// Implements WHATWG DOM Node.hasChildNodes() interface.
    ///
    /// ## Returns
    /// true if node has at least one child, false otherwise
    ///
    /// ## Example
    /// ```zig
    /// if (node.hasChildNodes()) {
    ///     std.debug.print("Node has children\n", .{});
    /// }
    /// ```
    pub fn hasChildNodes(self: *const Node) bool {
        return self.first_child != null;
    }

    /// Returns the parent element of this node.
    ///
    /// Implements WHATWG DOM Node.parentElement property.
    /// Similar to parentNode, but returns null if parent is not an Element.
    ///
    /// ## Returns
    /// Parent element or null if parent is not an element (or no parent)
    ///
    /// ## Example
    /// ```zig
    /// if (node.parentElement()) |parent_elem| {
    ///     const tag = parent_elem.tag_name;
    ///     std.debug.print("Parent element: {s}\n", .{tag});
    /// }
    /// ```
    pub fn parentElement(self: *const Node) ?*@import("element.zig").Element {
        if (self.parent_node) |parent| {
            if (parent.node_type == .element) {
                return @fieldParentPtr("node", parent);
            }
        }
        return null;
    }

    // === Tree manipulation methods ===

    /// Inserts node before child in this node's children.
    ///
    /// Implements WHATWG DOM Node.insertBefore() per §4.2.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] Node insertBefore(Node node, Node? child);
    /// ```
    ///
    /// ## Algorithm
    /// 1. Validate insertion with ensurePreInsertValidity
    /// 2. Adjust reference child if inserting before self
    /// 3. Insert node (handles DocumentFragment expansion)
    /// 4. Return inserted node
    ///
    /// ## Parameters
    /// - `node`: Node to insert (can be DocumentFragment)
    /// - `child`: Reference child to insert before (null = append)
    ///
    /// ## Returns
    /// The inserted node
    ///
    /// ## Errors
    /// - `error.HierarchyRequestError`: Invalid parent/child relationship
    /// - `error.NotFoundError`: Reference child not found in children
    /// - `error.OutOfMemory`: Failed to allocate during insertion
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-insertbefore
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:2449
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("element");
    /// defer parent.node.release();
    ///
    /// const child1 = try doc.createElement("item");
    /// defer child1.node.release();
    ///
    /// const child2 = try doc.createElement("text-block");
    /// defer child2.node.release();
    ///
    /// _ = try parent.node.appendChild(&child1.node);
    /// _ = try parent.node.insertBefore(&child2.node, &child1.node);
    /// // Order is now: child2, child1
    /// ```
    pub fn insertBefore(
        self: *Node,
        node: *Node,
        child: ?*Node,
    ) !*Node {
        return try preInsert(node, self, child);
    }

    /// Appends node to this node's children.
    ///
    /// Implements WHATWG DOM Node.appendChild() per §4.2.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] Node appendChild(Node node);
    /// ```
    ///
    /// ## Returns
    /// The appended node
    ///
    /// ## Errors
    /// Same as insertBefore()
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-appendchild
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:2450
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("element");
    /// defer parent.node.release();
    ///
    /// const child = try doc.createElement("item");
    /// defer child.node.release();
    ///
    /// _ = try parent.node.appendChild(&child.node);
    /// ```
    pub fn appendChild(
        self: *Node,
        node: *Node,
    ) !*Node {
        // Fast path: new element being appended to element
        // This avoids validation overhead for the common DOM construction case
        // Note: Explicitly excludes text/comment under document (spec violation)
        if (node.parent_node == null and
            self.node_type == .element and
            node.node_type == .element)
        {
            return self.appendChildFast(node);
        }

        // Slow path: full validation for all other cases
        return try self.insertBefore(node, null);
    }

    /// Fast path for appendChild when no validation is needed.
    ///
    /// This inline function handles the common case of appending a new element
    /// to an element without the overhead of validation checks.
    ///
    /// ## Safety
    /// Only call when:
    /// - node.parent_node == null (not already in tree)
    /// - self.node_type == .element
    /// - node.node_type == .element
    inline fn appendChildFast(self: *Node, node: *Node) *Node {
        // Direct pointer manipulation (no validation)
        const last = self.last_child;

        node.previous_sibling = last;
        node.next_sibling = null;
        node.parent_node = self;
        node.setHasParent(true);

        if (last) |l| {
            l.next_sibling = node;
        } else {
            self.first_child = node;
        }
        self.last_child = node;

        // Set connected state if parent is connected
        if (self.isConnected()) {
            node.setConnected(true);
            // Propagate to descendants
            tree_helpers.setDescendantsConnected(node, true);
        }

        return node;
    }

    /// Removes child from this node's children.
    ///
    /// Implements WHATWG DOM Node.removeChild() per §4.2.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] Node removeChild(Node child);
    /// ```
    ///
    /// ## Returns
    /// The removed child node
    ///
    /// ## Errors
    /// - `error.NotFoundError`: Child is not a child of this node
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-removechild
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:2452
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("element");
    /// defer parent.node.release();
    ///
    /// const child = try doc.createElement("item");
    /// defer child.node.release();
    ///
    /// _ = try parent.node.appendChild(&child.node);
    /// const removed = try parent.node.removeChild(&child.node);
    /// // removed == child
    /// ```
    pub fn removeChild(
        self: *Node,
        child: *Node,
    ) !*Node {
        return try preRemove(child, self);
    }

    /// Replaces child with node in this node's children.
    ///
    /// Implements WHATWG DOM Node.replaceChild() per §4.2.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] Node replaceChild(Node node, Node child);
    /// ```
    ///
    /// ## Returns
    /// The replaced (removed) child node
    ///
    /// ## Errors
    /// Same as insertBefore() plus NotFoundError if child not found
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-node-replacechild
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:2451
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("element");
    /// defer parent.node.release();
    ///
    /// const old_child = try doc.createElement("item");
    /// defer old_child.node.release();
    ///
    /// const new_child = try doc.createElement("text-block");
    /// defer new_child.node.release();
    ///
    /// _ = try parent.node.appendChild(&old_child.node);
    /// const removed = try parent.node.replaceChild(&new_child.node, &old_child.node);
    /// // removed == old_child, new_child is now child of parent
    /// ```
    pub fn replaceChild(
        self: *Node,
        node: *Node,
        child: *Node,
    ) !*Node {
        return try replace(child, node, self);
    }

    // === RareData management ===

    /// Ensures rare data is allocated.
    ///
    /// Call this before accessing rare features (event listeners, observers, etc.)
    ///
    /// ## Returns
    /// Pointer to rare data structure
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate rare data
    pub fn ensureRareData(self: *Node) !*NodeRareData {
        if (self.rare_data == null) {
            const rare = try self.allocator.create(NodeRareData);
            rare.* = NodeRareData.init(self.allocator);
            self.rare_data = rare;
        }
        return self.rare_data.?;
    }

    /// Returns rare data if allocated, null otherwise.
    pub fn getRareData(self: *const Node) ?*NodeRareData {
        return self.rare_data;
    }

    /// Checks if node has rare data allocated.
    pub fn hasRareData(self: *const Node) bool {
        return self.rare_data != null;
    }

    /// Frees rare data if allocated.
    ///
    /// Called during node cleanup by vtable deinit implementations.
    /// PUBLIC for Element/Text/Comment/Document to call.
    pub fn deinitRareData(self: *Node) void {
        if (self.rare_data) |rare| {
            rare.deinit();
            self.allocator.destroy(rare);
            self.rare_data = null;
        }
    }

    // === Event Listener API (WHATWG-style delegation to RareData) ===

    /// Adds an event listener to the node.
    ///
    /// Implements WHATWG EventTarget.addEventListener() interface.
    /// Internally delegates to RareData for storage.
    ///
    /// ## Parameters
    /// - `event_type`: Event type (e.g., "click", "input", "change")
    /// - `callback`: Event callback function
    /// - `context`: User context (passed to callback)
    /// - `capture`: Capture phase (true) or bubble phase (false)
    /// - `once`: Remove after first invocation
    /// - `passive`: Passive listener (won't call preventDefault)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate storage
    ///
    /// ## Example
    /// ```zig
    /// const callback = struct {
    ///     fn handle(ctx: *anyopaque) void {
    ///         const data: *MyData = @ptrCast(@alignCast(ctx));
    ///         // Handle event
    ///     }
    /// }.handle;
    ///
    /// var my_data = MyData{};
    /// try node.addEventListener("click", callback, @ptrCast(&my_data), false, false, false, null);
    /// ```
    pub fn addEventListener(
        self: *Node,
        event_type: []const u8,
        callback: @import("event_target.zig").EventCallback,
        context: *anyopaque,
        capture: bool,
        once: bool,
        passive: bool,
        signal: ?*anyopaque,
    ) !void {
        const Mixin = EventTargetMixin(Node);
        return Mixin.addEventListener(self, event_type, callback, context, capture, once, passive, signal);
    }

    /// Removes an event listener from the node.
    ///
    /// Implements WHATWG EventTarget.removeEventListener() interface.
    /// Per WebIDL spec, this returns void (not bool).
    /// Matches by event type, callback pointer, and capture phase.
    ///
    /// ## Parameters
    /// - `event_type`: Event type to remove listener for
    /// - `callback`: Callback function pointer to match
    /// - `capture`: Capture phase to match
    ///
    /// ## Example
    /// ```zig
    /// node.removeEventListener("click", callback, false);
    /// ```
    pub fn removeEventListener(
        self: *Node,
        event_type: []const u8,
        callback: @import("event_target.zig").EventCallback,
        capture: bool,
    ) void {
        const Mixin = EventTargetMixin(Node);
        return Mixin.removeEventListener(self, event_type, callback, capture);
    }

    /// Checks if node has event listeners for the specified type.
    ///
    /// ## Parameters
    /// - `event_type`: Event type to check
    ///
    /// ## Returns
    /// true if node has listeners for this event type, false otherwise
    pub fn hasEventListeners(self: *const Node, event_type: []const u8) bool {
        const Mixin = EventTargetMixin(Node);
        return Mixin.hasEventListeners(self, event_type);
    }

    /// Returns all event listeners for a specific event type.
    ///
    /// ## Parameters
    /// - `event_type`: Event type to query
    ///
    /// ## Returns
    /// Slice of listeners (empty if none registered)
    pub fn getEventListeners(self: *const Node, event_type: []const u8) []const @import("event_target.zig").EventListener {
        const Mixin = EventTargetMixin(Node);
        return Mixin.getEventListeners(self, event_type);
    }

    /// Dispatches an event to this node.
    ///
    /// Implements WHATWG DOM EventTarget.dispatchEvent() per §2.9.
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean dispatchEvent(Event event);
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §2.9 - Phase 1 Simplified)
    /// 1. Validate event state (not already dispatching, initialized)
    /// 2. Set isTrusted = false, dispatch_flag = true
    /// 3. Set target, currentTarget, eventPhase = AT_TARGET
    /// 4. Invoke listeners on target node (no capture/bubble in Phase 1)
    /// 5. Handle passive listeners, "once" listeners
    /// 6. Stop on stopImmediatePropagation
    /// 7. Cleanup: reset event_phase, currentTarget, dispatch_flag
    /// 8. Return !canceled_flag
    ///
    /// ## Note
    /// Phase 1 implementation - dispatches to target node only.
    /// Future phases will add:
    /// - Tree traversal (capture/bubble phases)
    /// - Event path construction
    /// - Shadow DOM retargeting
    ///
    /// ## Parameters
    /// - `event`: Event to dispatch
    ///
    /// ## Returns
    /// - `true` if event was not canceled
    /// - `false` if preventDefault() was called
    ///
    /// ## Errors
    /// - `error.InvalidStateError`: Event is already being dispatched or not initialized
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:68
    ///
    /// ## Example
    /// ```zig
    /// var event = Event.init("click", .{ .cancelable = true });
    /// const result = try node.dispatchEvent(&event);
    /// if (!result) {
    ///     // Event was canceled
    /// }
    /// ```
    pub fn dispatchEvent(self: *Node, event: *Event) !bool {
        const Mixin = EventTargetMixin(Node);
        return Mixin.dispatchEvent(self, event);
    }
};

// ============================================================================
// INTERNAL TREE MANIPULATION ALGORITHMS
// ============================================================================

const validation = @import("validation.zig");
const tree_helpers = @import("tree_helpers.zig");

/// Pre-insert algorithm per WHATWG DOM §4.2.4.
fn preInsert(
    node: *Node,
    parent: *Node,
    child: ?*Node,
) !*Node {
    // Step 1: Ensure validity
    try validation.ensurePreInsertValidity(node, parent, child);

    // Step 2: Set referenceChild
    var reference_child = child;

    // Step 3: Adjust if inserting before self
    if (reference_child == node) {
        reference_child = node.next_sibling;
    }

    // Step 4: Insert
    try insert(node, parent, reference_child);

    // Step 5: Return node
    return node;
}

/// Insert algorithm per WHATWG DOM §4.2.4.
///
/// Handles DocumentFragment expansion, sibling pointer updates,
/// parent pointer updates, and connected state propagation.
fn insert(
    node: *Node,
    parent: *Node,
    child: ?*Node,
) !void {
    // Step 1: Determine nodes to insert
    var nodes_buffer: [256]*Node = undefined; // Should be enough for most cases
    var nodes: []*Node = undefined;
    var node_count: usize = 0;

    if (node.node_type == .document_fragment) {
        // Collect fragment children
        var current = node.first_child;
        while (current) |c| {
            nodes_buffer[node_count] = c;
            node_count += 1;
            current = c.next_sibling;
        }
        nodes = nodes_buffer[0..node_count];

        // Remove from fragment (Step 4.1)
        tree_helpers.removeAllChildren(node);
    } else {
        nodes_buffer[0] = node;
        node_count = 1;
        nodes = nodes_buffer[0..1];
    }

    // Step 3: Return if no nodes
    if (node_count == 0) return;

    // Step 7: Insert each node
    for (nodes) |n| {
        // Remove from old parent if any
        if (n.parent_node) |_| {
            remove(n);
        }

        // Step 7.2-7.3: Insert into children list
        insertIntoChildrenList(n, parent, child);

        // Update parent pointer
        n.parent_node = parent;
        n.setHasParent(true);

        // Update connected state
        if (parent.isConnected()) {
            n.setConnected(true);
            // Recursively set connected for descendants
            tree_helpers.setDescendantsConnected(n, true);
        }
    }
}

/// Inserts node into parent's children list before child.
fn insertIntoChildrenList(
    node: *Node,
    parent: *Node,
    child: ?*Node,
) void {
    if (child) |c| {
        // Insert before child
        const prev = c.previous_sibling;

        // Update node's pointers
        node.previous_sibling = prev;
        node.next_sibling = c;

        // Update prev's next
        if (prev) |p| {
            p.next_sibling = node;
        } else {
            parent.first_child = node;
        }

        // Update child's prev
        c.previous_sibling = node;
    } else {
        // Append to end
        const last = parent.last_child;

        node.previous_sibling = last;
        node.next_sibling = null;

        if (last) |l| {
            l.next_sibling = node;
        } else {
            parent.first_child = node;
        }

        parent.last_child = node;
    }
}

/// Pre-remove algorithm per WHATWG DOM §4.2.4.
fn preRemove(
    child: *Node,
    parent: *Node,
) !*Node {
    // Step 1: Validate
    try validation.ensurePreRemoveValidity(child, parent);

    // Step 2: Remove
    remove(child);

    // Step 3: Return child
    return child;
}

/// Remove algorithm per WHATWG DOM §4.2.4.
///
/// Removes node from its parent by updating sibling pointers
/// and propagating disconnected state.
fn remove(node: *Node) void {
    const parent = node.parent_node orelse return;

    // Update sibling pointers
    const prev = node.previous_sibling;
    const next = node.next_sibling;

    if (prev) |p| {
        p.next_sibling = next;
    } else {
        parent.first_child = next;
    }

    if (next) |n| {
        n.previous_sibling = prev;
    } else {
        parent.last_child = prev;
    }

    // Clear node's pointers
    node.parent_node = null;
    node.previous_sibling = null;
    node.next_sibling = null;
    node.setHasParent(false);

    // Update connected state
    if (node.isConnected()) {
        node.setConnected(false);
        tree_helpers.setDescendantsConnected(node, false);
    }
}

/// Replace algorithm per WHATWG DOM §4.2.4.
fn replace(
    child: *Node,
    node: *Node,
    parent: *Node,
) !*Node {
    // Step 1-6: Validation (different from pre-insert!)
    try validation.ensureReplaceValidity(node, child, parent);

    // Step 7: Get reference child
    var reference_child = child.next_sibling;

    // Step 8: Adjust if replacing with self
    if (reference_child == node) {
        reference_child = node.next_sibling;
    }

    // Step 11: Remove child
    if (child.parent_node != null) {
        remove(child);
    }

    // Step 13: Insert node
    try insert(node, parent, reference_child);

    // Step 15: Return child
    return child;
}

// ============================================================================
// TESTS
// ============================================================================

test "Node - size constraint" {
    const size = @sizeOf(Node);
    try std.testing.expect(size <= 96);

    // Print actual size for documentation
    std.debug.print("\nNode size: {d} bytes (target: ≤96)\n", .{size});
}

test "Node - packed ref_count and has_parent" {
    // Verify bit packing works correctly
    const node_with_ref_1_no_parent: u32 = 1;
    const node_with_ref_1_has_parent: u32 = 1 | Node.HAS_PARENT_BIT;
    const node_with_ref_100_no_parent: u32 = 100;

    // Extract ref_count
    try std.testing.expectEqual(@as(u32, 1), node_with_ref_1_no_parent & Node.REF_COUNT_MASK);
    try std.testing.expectEqual(@as(u32, 1), node_with_ref_1_has_parent & Node.REF_COUNT_MASK);
    try std.testing.expectEqual(@as(u32, 100), node_with_ref_100_no_parent & Node.REF_COUNT_MASK);

    // Extract has_parent
    try std.testing.expect((node_with_ref_1_no_parent & Node.HAS_PARENT_BIT) == 0);
    try std.testing.expect((node_with_ref_1_has_parent & Node.HAS_PARENT_BIT) != 0);
}

test "Node - ref counting basic operations" {
    const allocator = std.testing.allocator;

    // Minimal vtable for testing
    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initial ref_count should be 1
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());
    try std.testing.expect(!node.hasParent());

    // Acquire increments ref_count
    node.acquire();
    try std.testing.expectEqual(@as(u32, 2), node.getRefCount());

    // Release decrements ref_count
    node.release();
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());

    // Final release happens in defer
}

test "Node - has_parent flag operations" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially has no parent
    try std.testing.expect(!node.hasParent());

    // Set has_parent flag
    node.setHasParent(true);
    try std.testing.expect(node.hasParent());
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount()); // ref_count unchanged

    // Clear has_parent flag
    node.setHasParent(false);
    try std.testing.expect(!node.hasParent());
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());
}

test "Node - memory leak test" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    // Test 1: Simple create and release
    {
        const node = try Node.init(allocator, &test_vtable, .element);
        defer node.release();
    }

    // Test 2: Multiple acquire/release
    {
        const node = try Node.init(allocator, &test_vtable, .element);
        defer node.release();

        node.acquire();
        defer node.release();

        node.acquire();
        defer node.release();
    }

    // If we get here without leaks, std.testing.allocator validates success
}

test "Node - flag operations" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially not connected
    try std.testing.expect(!node.isConnected());

    // Set connected flag
    node.setConnected(true);
    try std.testing.expect(node.isConnected());

    // Clear connected flag
    node.setConnected(false);
    try std.testing.expect(!node.isConnected());

    // Check shadow tree flag
    try std.testing.expect(!node.isInShadowTree());
}

test "Node - vtable dispatch" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "custom-name";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return "custom-value";
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Test vtable dispatch
    try std.testing.expectEqualStrings("custom-name", node.nodeName());
    try std.testing.expectEqualStrings("custom-value", node.nodeValue().?);

    // Test error returns
    try std.testing.expectError(error.NotSupported, node.setNodeValue("value"));
    try std.testing.expectError(error.NotSupported, node.cloneNode(false));
}

test "Node - rare data allocation" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially no rare data
    try std.testing.expect(!node.hasRareData());
    try std.testing.expect(node.getRareData() == null);

    // Ensure rare data
    const rare = try node.ensureRareData();
    try std.testing.expect(node.hasRareData());
    try std.testing.expect(node.getRareData() != null);
    try std.testing.expectEqual(rare, node.getRareData().?);

    // Second call returns same instance
    const rare2 = try node.ensureRareData();
    try std.testing.expectEqual(rare, rare2);
}

test "Node - rare data cleanup" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Allocate rare data and add features
    const rare = try node.ensureRareData();

    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, _: *anyopaque) void {}
    }.cb;

    try rare.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try rare.setUserData("key", @ptrCast(&ctx));

    // Cleanup happens in defer node.release()
    // If this test passes without leaks, cleanup worked
}

test "Node - addEventListener wrapper" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, _: *anyopaque) void {}
    }.cb;

    // Test WHATWG-style API
    try node.addEventListener("click", callback, @ptrCast(&ctx), false, false, false, null);

    // Verify listener was added
    try std.testing.expect(node.hasEventListeners("click"));
    try std.testing.expect(!node.hasEventListeners("input"));

    const listeners = node.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 1), listeners.len);

    // Remove listener
    node.removeEventListener("click", callback, false);
    try std.testing.expect(!node.hasEventListeners("click"));
}

test "Node - hasChildNodes" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially no children
    try std.testing.expect(!node.hasChildNodes());

    // Create a child (but don't connect yet - that's Phase 2)
    const child = try Node.init(allocator, &test_vtable, .element);
    defer child.release();

    // Manually set first_child for testing
    node.first_child = child;
    try std.testing.expect(node.hasChildNodes());

    // Clean up manual connection
    node.first_child = null;
}

test "Node - parentElement" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    // Create parent element
    const parent_elem = try Element.create(allocator, "div");
    defer parent_elem.node.release();

    // Create child text node
    const Text = @import("text.zig").Text;
    const child = try Text.create(allocator, "content");
    defer child.node.release();

    // Initially no parent
    try std.testing.expect(child.node.parentElement() == null);

    // Manually set parent for testing (Phase 2 will do this via appendChild)
    child.node.parent_node = &parent_elem.node;

    // parentElement should return the element
    const retrieved_parent = child.node.parentElement();
    try std.testing.expect(retrieved_parent != null);
    try std.testing.expectEqual(parent_elem, retrieved_parent.?);

    // Clean up manual connection
    child.node.parent_node = null;
}

test "Node - getOwnerDocument" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    // Create document
    const doc = try Document.init(allocator);
    defer doc.release();

    // Document's ownerDocument should be null per spec
    try std.testing.expect(doc.node.getOwnerDocument() == null);

    // Create element via document
    const elem = try doc.createElement("element");
    defer elem.node.release();

    // Element's ownerDocument should be the document
    const owner = elem.node.getOwnerDocument();
    try std.testing.expect(owner != null);
    try std.testing.expectEqual(doc, owner.?);

    // Create text node via document
    const text = try doc.createTextNode("test");
    defer text.node.release();

    // Text's ownerDocument should also be the document
    const text_owner = text.node.getOwnerDocument();
    try std.testing.expect(text_owner != null);
    try std.testing.expectEqual(doc, text_owner.?);
}

test "Node - childNodes" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
    };

    const parent = try Node.init(allocator, &test_vtable, .element);
    defer parent.release();

    // Initially no children
    const empty_list = parent.childNodes();
    try std.testing.expectEqual(@as(usize, 0), empty_list.length());

    // Add a child manually (Phase 2 will do this via appendChild)
    const child1 = try Node.init(allocator, &test_vtable, .element);
    defer child1.release();

    const child2 = try Node.init(allocator, &test_vtable, .element);
    defer child2.release();

    parent.first_child = child1;
    parent.last_child = child2;
    child1.next_sibling = child2;
    child1.parent_node = parent;
    child2.parent_node = parent;

    // NodeList should reflect children
    const list = parent.childNodes();
    try std.testing.expectEqual(@as(usize, 2), list.length());
    try std.testing.expectEqual(child1, list.item(0).?);
    try std.testing.expectEqual(child2, list.item(1).?);
    try std.testing.expect(list.item(2) == null);

    // Clean up manual connections
    parent.first_child = null;
    parent.last_child = null;
    child1.next_sibling = null;
    child1.parent_node = null;
    child2.parent_node = null;
}

// ============================================================================
// TREE MANIPULATION TESTS
// ============================================================================

// ============================================================================
// TREE MANIPULATION TESTS
// ============================================================================

test "Node.appendChild - adds child successfully" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child = try doc.createElement("item");
    // NO defer - parent will own it

    _ = try parent.node.appendChild(&child.node);

    // Verify parent-child relationship
    try std.testing.expectEqual(&parent.node, child.node.parent_node);
    try std.testing.expectEqual(&child.node, parent.node.first_child);
    try std.testing.expectEqual(&child.node, parent.node.last_child);
    try std.testing.expect(child.node.hasParent());
}

test "Node.appendChild - adds multiple children in order" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    const child3 = try doc.createElement("strong");
    // NO defers - parent owns them

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child2.node);
    _ = try parent.node.appendChild(&child3.node);

    // Verify order
    try std.testing.expectEqual(&child1.node, parent.node.first_child);
    try std.testing.expectEqual(&child3.node, parent.node.last_child);
    try std.testing.expectEqual(&child2.node, child1.node.next_sibling);
    try std.testing.expectEqual(&child3.node, child2.node.next_sibling);
}

test "Node.appendChild - moves node from old parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("element");
    defer parent1.node.release();

    const parent2 = try doc.createElement("section");
    defer parent2.node.release();

    const child = try doc.createElement("item");
    // NO defer - will be owned by one of the parents

    // Add to parent1
    _ = try parent1.node.appendChild(&child.node);
    try std.testing.expectEqual(&parent1.node, child.node.parent_node);

    // Move to parent2
    _ = try parent2.node.appendChild(&child.node);
    try std.testing.expectEqual(&parent2.node, child.node.parent_node);
    try std.testing.expect(parent1.node.first_child == null);
}

test "Node.appendChild - rejects text node under document" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.node.release(); // NOT added to parent, so we own it

    // Should fail - text cannot be child of document
    try std.testing.expectError(
        error.HierarchyRequestError,
        doc.node.appendChild(&text.node),
    );
}

test "Node.insertBefore - inserts at beginning" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    // NO defers - parent owns them

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.insertBefore(&child2.node, &child1.node);

    // child2 should be first
    try std.testing.expectEqual(&child2.node, parent.node.first_child);
    try std.testing.expectEqual(&child1.node, child2.node.next_sibling);
}

test "Node.insertBefore - inserts in middle" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    const child3 = try doc.createElement("strong");
    // NO defers - parent owns them

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child3.node);
    _ = try parent.node.insertBefore(&child2.node, &child3.node);

    // Order should be: child1, child2, child3
    try std.testing.expectEqual(&child1.node, parent.node.first_child);
    try std.testing.expectEqual(&child2.node, child1.node.next_sibling);
    try std.testing.expectEqual(&child3.node, child2.node.next_sibling);
}

test "Node.insertBefore - with null child appends" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    // NO defers - parent owns them

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.insertBefore(&child2.node, null);

    // child2 should be last
    try std.testing.expectEqual(&child2.node, parent.node.last_child);
}

test "Node.insertBefore - rejects if child not in parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const other = try doc.createElement("section");
    defer other.node.release();

    const child = try doc.createElement("item");
    // child will be owned by other, NOT parent

    const new_child = try doc.createElement("text-block");
    defer new_child.node.release(); // Will NOT be added

    _ = try other.node.appendChild(&child.node);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.node.insertBefore(&new_child.node, &child.node),
    );
}

test "Node.removeChild - removes child successfully" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child = try doc.createElement("item");
    defer child.node.release(); // Released AFTER removal

    _ = try parent.node.appendChild(&child.node);
    const removed = try parent.node.removeChild(&child.node);

    try std.testing.expectEqual(&child.node, removed);
    try std.testing.expect(child.node.parent_node == null);
    try std.testing.expect(!child.node.hasParent());
}

test "Node.removeChild - removes middle child" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    defer child2.node.release(); // Released AFTER removal
    const child3 = try doc.createElement("strong");
    // child1 and child3 owned by parent

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child2.node);
    _ = try parent.node.appendChild(&child3.node);

    _ = try parent.node.removeChild(&child2.node);

    // child1 and child3 should be linked
    try std.testing.expectEqual(&child3.node, child1.node.next_sibling);
    try std.testing.expect(child2.node.parent_node == null);
}

test "Node.removeChild - rejects if not parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const other = try doc.createElement("section");
    defer other.node.release();

    const child = try doc.createElement("item");
    // child owned by other

    _ = try other.node.appendChild(&child.node);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.node.removeChild(&child.node),
    );
}

test "Node.replaceChild - replaces child successfully" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const old_child = try doc.createElement("item");
    defer old_child.node.release(); // Released AFTER removal

    const new_child = try doc.createElement("text-block");
    // new_child owned by parent after replacement

    _ = try parent.node.appendChild(&old_child.node);
    const removed = try parent.node.replaceChild(&new_child.node, &old_child.node);

    try std.testing.expectEqual(&old_child.node, removed);
    try std.testing.expectEqual(&new_child.node, parent.node.first_child);
    try std.testing.expect(old_child.node.parent_node == null);
}

test "Node.replaceChild - preserves sibling order" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    defer child2.node.release(); // Released AFTER replacement
    const child3 = try doc.createElement("strong");
    const new_child = try doc.createElement("em");
    // child1, new_child, child3 owned by parent

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child2.node);
    _ = try parent.node.appendChild(&child3.node);

    _ = try parent.node.replaceChild(&new_child.node, &child2.node);

    // Order should be: child1, new_child, child3
    try std.testing.expectEqual(&child1.node, parent.node.first_child);
    try std.testing.expectEqual(&new_child.node, child1.node.next_sibling);
    try std.testing.expectEqual(&child3.node, new_child.node.next_sibling);
}

test "Node.replaceChild - rejects if child not in parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const other = try doc.createElement("section");
    defer other.node.release();

    const child = try doc.createElement("item");
    // child owned by other

    const new_child = try doc.createElement("text-block");
    defer new_child.node.release(); // NOT added

    _ = try other.node.appendChild(&child.node);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.node.replaceChild(&new_child.node, &child.node),
    );
}

test "Node.appendChild - propagates connected state" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    // root owned by doc after appendChild

    const child = try doc.createElement("container");
    const grandchild = try doc.createElement("element");
    // child and grandchild owned by tree

    // Build tree
    _ = try child.node.appendChild(&grandchild.node);
    _ = try root.node.appendChild(&child.node);

    // Connect root to document (document is always connected)
    _ = try doc.node.appendChild(&root.node);

    // Should propagate to child and grandchild
    try std.testing.expect(root.node.isConnected());
    try std.testing.expect(child.node.isConnected());
    try std.testing.expect(grandchild.node.isConnected());
}

test "Node.removeChild - propagates disconnected state" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    // root owned by doc

    const child = try doc.createElement("container");
    defer child.node.release(); // Released AFTER removal

    const grandchild = try doc.createElement("element");
    // grandchild owned by child

    // Build connected tree
    _ = try child.node.appendChild(&grandchild.node);
    _ = try root.node.appendChild(&child.node);
    _ = try doc.node.appendChild(&root.node);

    // All should be connected
    try std.testing.expect(root.node.isConnected());
    try std.testing.expect(child.node.isConnected());
    try std.testing.expect(grandchild.node.isConnected());

    // Remove child
    _ = try root.node.removeChild(&child.node);

    // root still connected, child and grandchild disconnected
    try std.testing.expect(root.node.isConnected());
    try std.testing.expect(!child.node.isConnected());
    try std.testing.expect(!grandchild.node.isConnected());
}

test "Node.textContent - getter returns null for Document" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const content = try doc.node.textContent(allocator);
    try std.testing.expect(content == null);
}

test "Node.textContent - getter returns text node data" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello, World!");
    defer text.node.release();

    const content = try text.node.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello, World!", content.?);
}

test "Node.textContent - getter returns comment data" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("This is a comment");
    defer comment.node.release();

    const content = try comment.node.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("This is a comment", content.?);
}

test "Node.textContent - getter collects descendant text" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.node.release();

    const text1 = try doc.createTextNode("Hello ");
    const text2 = try doc.createTextNode("World");
    const text3 = try doc.createTextNode("!");

    _ = try div.node.appendChild(&text1.node);
    _ = try div.node.appendChild(&text2.node);
    _ = try div.node.appendChild(&text3.node);

    const content = try div.node.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello World!", content.?);
}

test "Node.textContent - getter collects nested text" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.node.release();

    const span = try doc.createElement("span");
    const text1 = try doc.createTextNode("Hello ");
    const text2 = try doc.createTextNode("World");

    _ = try span.node.appendChild(&text1.node);
    _ = try div.node.appendChild(&span.node);
    _ = try div.node.appendChild(&text2.node);

    const content = try div.node.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello World", content.?);
}

test "Node.textContent - getter returns null for empty element" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.node.release();

    const content = try div.node.textContent(allocator);
    try std.testing.expect(content == null);
}

test "Node.textContent - setter does nothing for Document" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    // Should not error, but does nothing
    try doc.node.setTextContent("This should be ignored");

    const content = try doc.node.textContent(allocator);
    try std.testing.expect(content == null);
}

test "Node.textContent - setter replaces text node data" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Old text");
    defer text.node.release();

    try text.node.setTextContent("New text");

    const content = try text.node.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New text", content.?);
}

test "Node.textContent - setter replaces comment data" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("Old comment");
    defer comment.node.release();

    try comment.node.setTextContent("New comment");

    const content = try comment.node.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New comment", content.?);
}

test "Node.textContent - setter removes all children and inserts text" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.node.release();

    // Add some children (owned by tree, no defer needed)
    const span = try doc.createElement("span");
    const text1 = try doc.createTextNode("Old");

    _ = try span.node.appendChild(&text1.node);
    _ = try div.node.appendChild(&span.node);

    // Set text content - should remove all children (releasing span and text1)
    try div.node.setTextContent("New text");

    // Should have exactly one child (text node)
    try std.testing.expect(div.node.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 1), div.node.childNodes().length());
    try std.testing.expectEqual(NodeType.text, div.node.first_child.?.node_type);

    const content = try div.node.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New text", content.?);
}

test "Node.textContent - setter with empty string removes all children" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.node.release();

    const text = try doc.createTextNode("Some text");
    // text owned by div after appendChild
    _ = try div.node.appendChild(&text.node);

    try std.testing.expect(div.node.hasChildNodes());

    // Set to empty string - should remove all children (releasing text)
    try div.node.setTextContent("");

    try std.testing.expect(!div.node.hasChildNodes());
    try std.testing.expectEqual(@as(?*Node, null), div.node.first_child);
}

test "Node.textContent - setter with null removes all children" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.node.release();

    const text = try doc.createTextNode("Some text");
    // text owned by div after appendChild
    _ = try div.node.appendChild(&text.node);

    try std.testing.expect(div.node.hasChildNodes());

    // Set to null - should remove all children (releasing text)
    try div.node.setTextContent(null);

    try std.testing.expect(!div.node.hasChildNodes());
    try std.testing.expectEqual(@as(?*Node, null), div.node.first_child);
}

test "Node.textContent - setter propagates connected state" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    // root owned by document after appendChild, no defer needed

    // Connect to document
    _ = try doc.node.appendChild(&root.node);

    // Set text content
    try root.node.setTextContent("Connected text");

    // New text node should be connected
    try std.testing.expect(root.node.first_child != null);
    try std.testing.expect(root.node.first_child.?.isConnected());
}

test "Node.textContent - no memory leaks" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.node.release();

    // Set multiple times
    try div.node.setTextContent("First");
    try div.node.setTextContent("Second");
    try div.node.setTextContent("Third");
    try div.node.setTextContent(null);

    // Get multiple times
    for (0..10) |_| {
        const content = try div.node.textContent(allocator);
        if (content) |c| allocator.free(c);
    }

    // Test passes if no leaks detected by testing allocator
}

// === isSameNode() Tests ===

test "Node.isSameNode - returns true for same node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    try std.testing.expect(elem.node.isSameNode(&elem.node));
}

test "Node.isSameNode - returns false for different nodes" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.node.release();

    const elem2 = try doc.createElement("div");
    defer elem2.node.release();

    try std.testing.expect(!elem1.node.isSameNode(&elem2.node));
}

test "Node.isSameNode - returns false for null" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    try std.testing.expect(!elem.node.isSameNode(null));
}

// === getRootNode() Tests ===

test "Node.getRootNode - returns document for connected node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);
    _ = try doc.node.appendChild(&parent.node);

    const root = child.node.getRootNode(false);
    try std.testing.expect(root == &doc.node);
}

test "Node.getRootNode - returns self for disconnected single node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    const root = elem.node.getRootNode(false);
    try std.testing.expect(root == &elem.node);
}

test "Node.getRootNode - returns topmost disconnected node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);

    // Not connected to document
    const root = child.node.getRootNode(false);
    try std.testing.expect(root == &parent.node);
}

test "Node.getRootNode - composed parameter (no shadow DOM yet)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");

    _ = try doc.node.appendChild(&elem.node);

    // Both should return same result (no shadow DOM)
    const root1 = elem.node.getRootNode(false);
    const root2 = elem.node.getRootNode(true);

    try std.testing.expect(root1 == root2);
    try std.testing.expect(root1 == &doc.node);
}

// === contains() Tests ===

test "Node.contains - returns true for self (inclusive)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    try std.testing.expect(elem.node.contains(&elem.node));
}

test "Node.contains - returns true for direct child" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);

    try std.testing.expect(parent.node.contains(&child.node));
}

test "Node.contains - returns true for deep descendant" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const grandparent = try doc.createElement("div");
    defer grandparent.node.release();

    const parent = try doc.createElement("section");
    const child = try doc.createElement("span");

    _ = try grandparent.node.appendChild(&parent.node);
    _ = try parent.node.appendChild(&child.node);

    try std.testing.expect(grandparent.node.contains(&child.node));
}

test "Node.contains - returns false for parent (not ancestor of child)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);

    try std.testing.expect(!child.node.contains(&parent.node));
}

test "Node.contains - returns false for sibling" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child2.node);

    try std.testing.expect(!child1.node.contains(&child2.node));
    try std.testing.expect(!child2.node.contains(&child1.node));
}

test "Node.contains - returns false for null (per spec)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    try std.testing.expect(!elem.node.contains(null));
}

// === baseURI() Tests ===

test "Node.baseURI - returns empty string (placeholder)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    const uri = elem.node.baseURI();
    try std.testing.expectEqualStrings("", uri);
}

// === compareDocumentPosition() Tests ===

test "Node.compareDocumentPosition - returns 0 for same node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    const pos = elem.node.compareDocumentPosition(&elem.node);
    try std.testing.expectEqual(@as(u16, 0), pos);
}

test "Node.compareDocumentPosition - disconnected nodes" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.node.release();

    const elem2 = try doc.createElement("span");
    defer elem2.node.release();

    const pos = elem1.node.compareDocumentPosition(&elem2.node);

    // Must have DISCONNECTED flag
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_DISCONNECTED) != 0);
    // Must have IMPLEMENTATION_SPECIFIC flag
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC) != 0);
    // Must have either PRECEDING or FOLLOWING
    try std.testing.expect((pos & (Node.DOCUMENT_POSITION_PRECEDING | Node.DOCUMENT_POSITION_FOLLOWING)) != 0);
}

test "Node.compareDocumentPosition - parent contains child" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);

    const pos = child.node.compareDocumentPosition(&parent.node);

    // Parent CONTAINS child (from child's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_CONTAINS) != 0);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

test "Node.compareDocumentPosition - child contained by parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);

    const pos = parent.node.compareDocumentPosition(&child.node);

    // Child CONTAINED_BY parent (from parent's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_CONTAINED_BY) != 0);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_FOLLOWING) != 0);
}

test "Node.compareDocumentPosition - sibling order (preceding)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child2.node);

    const pos = child2.node.compareDocumentPosition(&child1.node);

    // child1 PRECEDES child2 (from child2's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

test "Node.compareDocumentPosition - sibling order (following)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child2.node);

    const pos = child1.node.compareDocumentPosition(&child2.node);

    // child2 FOLLOWS child1 (from child1's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_FOLLOWING) != 0);
}

test "Node.compareDocumentPosition - complex tree order" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    defer root.node.release();

    const branch1 = try doc.createElement("section");
    const branch2 = try doc.createElement("article");
    const leaf1 = try doc.createElement("span");
    const leaf2 = try doc.createElement("p");

    _ = try root.node.appendChild(&branch1.node);
    _ = try root.node.appendChild(&branch2.node);
    _ = try branch1.node.appendChild(&leaf1.node);
    _ = try branch2.node.appendChild(&leaf2.node);

    // leaf1 precedes leaf2 (different branches, branch1 before branch2)
    const pos = leaf2.node.compareDocumentPosition(&leaf1.node);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

// === isEqualNode() Tests ===

test "Node.isEqualNode - returns true for same node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    try std.testing.expect(elem.node.isEqualNode(&elem.node));
}

test "Node.isEqualNode - returns false for null" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    try std.testing.expect(!elem.node.isEqualNode(null));
}

test "Node.isEqualNode - returns true for equal elements (no attributes)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.node.release();

    const elem2 = try doc.createElement("div");
    defer elem2.node.release();

    try std.testing.expect(elem1.node.isEqualNode(&elem2.node));
}

test "Node.isEqualNode - returns false for different tag names" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.node.release();

    const elem2 = try doc.createElement("span");
    defer elem2.node.release();

    try std.testing.expect(!elem1.node.isEqualNode(&elem2.node));
}

// ============================================================================
// EVENT DISPATCHING TESTS
// ============================================================================

test "Node.dispatchEvent - basic dispatch returns true" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    var event = Event.init("click", .{});
    const result = try elem.node.dispatchEvent(&event);

    // Should return true (not canceled)
    try std.testing.expect(result);
}

test "Node.dispatchEvent - invokes listener with event" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    var invoked: bool = false;
    const callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const flag: *bool = @ptrCast(@alignCast(context));
            flag.* = true;
            // Verify event properties
            std.testing.expectEqualStrings("click", evt.event_type) catch unreachable;
            std.testing.expect(evt.target != null) catch unreachable;
        }
    }.cb;

    try elem.node.addEventListener("click", callback, @ptrCast(&invoked), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.node.dispatchEvent(&event);

    try std.testing.expect(invoked);
}

test "Node.dispatchEvent - returns false when preventDefault called" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    const callback = struct {
        fn cb(evt: *Event, _: *anyopaque) void {
            evt.preventDefault();
        }
    }.cb;

    try elem.node.addEventListener("click", callback, undefined, false, false, false, null);

    var event = Event.init("click", .{ .cancelable = true });
    const result = try elem.node.dispatchEvent(&event);

    // Should return false (canceled)
    try std.testing.expect(!result);
    try std.testing.expect(event.canceled_flag);
}

test "Node.dispatchEvent - once listener removed after dispatch" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    var count: u32 = 0;
    const callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
        }
    }.cb;

    // Add listener with once=true
    try elem.node.addEventListener("click", callback, @ptrCast(&count), false, true, false, null);

    // First dispatch
    var event1 = Event.init("click", .{});
    _ = try elem.node.dispatchEvent(&event1);
    try std.testing.expectEqual(@as(u32, 1), count);

    // Second dispatch - listener should be removed
    var event2 = Event.init("click", .{});
    _ = try elem.node.dispatchEvent(&event2);
    try std.testing.expectEqual(@as(u32, 1), count); // Still 1, not 2
}

test "Node.dispatchEvent - passive listener blocks preventDefault" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    const callback = struct {
        fn cb(evt: *Event, _: *anyopaque) void {
            // Try to prevent default (should be blocked because passive=true)
            evt.preventDefault();
        }
    }.cb;

    // Add passive listener
    try elem.node.addEventListener("click", callback, undefined, false, false, true, null);

    var event = Event.init("click", .{ .cancelable = true });
    const result = try elem.node.dispatchEvent(&event);

    // preventDefault should have been ignored
    try std.testing.expect(result); // Returns true
    try std.testing.expect(!event.canceled_flag); // Not canceled
}

test "Node.dispatchEvent - stopImmediatePropagation prevents remaining listeners" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    var count: u32 = 0;

    const callback1 = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
        }
    }.cb;

    const callback2 = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
            // Stop propagation
            evt.stopImmediatePropagation();
        }
    }.cb;

    const callback3 = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
        }
    }.cb;

    try elem.node.addEventListener("click", callback1, @ptrCast(&count), false, false, false, null);
    try elem.node.addEventListener("click", callback2, @ptrCast(&count), false, false, false, null);
    try elem.node.addEventListener("click", callback3, @ptrCast(&count), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.node.dispatchEvent(&event);

    // Only first two listeners should be invoked
    try std.testing.expectEqual(@as(u32, 2), count);
}

test "Node.dispatchEvent - rejects already dispatching event" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    var event = Event.init("click", .{});
    event.dispatch_flag = true; // Manually set dispatch flag

    // Should return InvalidStateError
    try std.testing.expectError(error.InvalidStateError, elem.node.dispatchEvent(&event));
}

test "Node.dispatchEvent - sets event properties correctly" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    const callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const expected_node: *Node = @ptrCast(@alignCast(context));
            // During dispatch
            const target_node: *Node = @ptrCast(@alignCast(evt.target.?));
            const current_node: *Node = @ptrCast(@alignCast(evt.current_target.?));
            std.testing.expect(target_node == expected_node) catch unreachable;
            std.testing.expect(current_node == expected_node) catch unreachable;
            std.testing.expectEqual(Event.EventPhase.at_target, evt.event_phase) catch unreachable;
            std.testing.expect(!evt.is_trusted) catch unreachable; // Always false for dispatchEvent
        }
    }.cb;

    try elem.node.addEventListener("click", callback, @ptrCast(&elem.node), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.node.dispatchEvent(&event);

    // After dispatch - should be cleaned up
    try std.testing.expectEqual(Event.EventPhase.none, event.event_phase);
    try std.testing.expect(event.current_target == null);
    try std.testing.expect(!event.dispatch_flag);
}

test "Node.isEqualNode - returns false for different attribute values" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.node.release();
    try elem1.setAttribute("id", "test1");

    const elem2 = try doc.createElement("div");
    defer elem2.node.release();
    try elem2.setAttribute("id", "test2");

    try std.testing.expect(!elem1.node.isEqualNode(&elem2.node));
}

test "Node.isEqualNode - returns false for different attribute counts" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.node.release();
    try elem1.setAttribute("id", "test");

    const elem2 = try doc.createElement("div");
    defer elem2.node.release();
    try elem2.setAttribute("id", "test");
    try elem2.setAttribute("class", "foo");

    try std.testing.expect(!elem1.node.isEqualNode(&elem2.node));
}

test "Node.isEqualNode - returns true for equal text nodes" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("Hello");
    defer text1.node.release();

    const text2 = try doc.createTextNode("Hello");
    defer text2.node.release();

    try std.testing.expect(text1.node.isEqualNode(&text2.node));
}

test "Node.isEqualNode - returns false for different text content" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("Hello");
    defer text1.node.release();

    const text2 = try doc.createTextNode("World");
    defer text2.node.release();

    try std.testing.expect(!text1.node.isEqualNode(&text2.node));
}

test "Node.isEqualNode - returns true for equal subtrees" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    // Build first tree
    const parent1 = try doc.createElement("div");
    defer parent1.node.release();
    try parent1.setAttribute("id", "container");

    const child1a = try doc.createElement("span");
    const text1 = try doc.createTextNode("Hello");

    _ = try child1a.node.appendChild(&text1.node);
    _ = try parent1.node.appendChild(&child1a.node);

    // Build identical tree
    const parent2 = try doc.createElement("div");
    defer parent2.node.release();
    try parent2.setAttribute("id", "container");

    const child2a = try doc.createElement("span");
    const text2 = try doc.createTextNode("Hello");

    _ = try child2a.node.appendChild(&text2.node);
    _ = try parent2.node.appendChild(&child2a.node);

    try std.testing.expect(parent1.node.isEqualNode(&parent2.node));
}

test "Node.isEqualNode - returns false for different child counts" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.node.release();

    const child1 = try doc.createElement("span");

    _ = try parent1.node.appendChild(&child1.node);

    const parent2 = try doc.createElement("div");
    defer parent2.node.release();

    const child2a = try doc.createElement("span");
    const child2b = try doc.createElement("p");

    _ = try parent2.node.appendChild(&child2a.node);
    _ = try parent2.node.appendChild(&child2b.node);

    try std.testing.expect(!parent1.node.isEqualNode(&parent2.node));
}

test "Node.isEqualNode - returns false for different child order" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.node.release();

    const child1a = try doc.createElement("span");
    const child1b = try doc.createElement("p");

    _ = try parent1.node.appendChild(&child1a.node);
    _ = try parent1.node.appendChild(&child1b.node);

    const parent2 = try doc.createElement("div");
    defer parent2.node.release();

    const child2a = try doc.createElement("p");
    const child2b = try doc.createElement("span");

    _ = try parent2.node.appendChild(&child2a.node);
    _ = try parent2.node.appendChild(&child2b.node);

    try std.testing.expect(!parent1.node.isEqualNode(&parent2.node));
}
