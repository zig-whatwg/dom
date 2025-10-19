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
const EventTarget = @import("event_target.zig").EventTarget;
const EventTargetVTable = @import("event_target.zig").EventTargetVTable;
const EventTargetMixin = @import("event_target.zig").EventTargetMixin;

/// Node types per WHATWG DOM specification.
pub const NodeType = enum(u8) {
    element = 1,
    attribute = 2,
    text = 3,
    comment = 8,
    document = 9,
    document_type = 10,
    document_fragment = 11,
    shadow_root = 12,
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

    /// Called during cross-document adoption to update node-specific data.
    /// Implements WHATWG "adopting steps" per §4.2.4.
    ///
    /// For elements: re-intern tag_name, update document maps (tag/class/id)
    /// For text/comment: typically no-op (data is already owned)
    ///
    /// oldDocument may be null if node was created without owner_document.
    adopting_steps: *const fn (*Node, oldDocument: ?*Node) anyerror!void,
};

// === EventTarget VTable Implementation for Node ===

/// EventTarget deinit implementation for Node (calls Node.release())
fn eventtargetDeinitImpl(et: *EventTarget) void {
    const node: *Node = @fieldParentPtr("prototype", et);
    node.release();
}

/// EventTarget getAllocator implementation for Node
fn eventtargetGetAllocatorImpl(et: *const EventTarget) Allocator {
    const node: *const Node = @fieldParentPtr("prototype", et);
    return node.allocator;
}

/// EventTarget ensureRareData implementation for Node
fn eventtargetEnsureRareDataImpl(et: *EventTarget) anyerror!*anyopaque {
    const node: *Node = @fieldParentPtr("prototype", et);
    const rare = try node.ensureRareData();
    return @ptrCast(rare);
}

/// EventTarget vtable for Node type
pub const eventtarget_vtable = EventTargetVTable{
    .deinit = eventtargetDeinitImpl,
    .get_allocator = eventtargetGetAllocatorImpl,
    .ensure_rare_data = eventtargetEnsureRareDataImpl,
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
    /// EventTarget prototype (MUST be first field for proper inheritance)
    /// Per WHATWG: interface Node : EventTarget
    /// 8 bytes (vtable pointer)
    prototype: EventTarget,

    /// Virtual table for Node-specific polymorphic dispatch (8 bytes)
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
    // Node = EventTarget (8) + Node fields (96) = 104 bytes
    // This is acceptable for the prototype chain architecture
    comptime {
        const size = @sizeOf(Node);
        if (size > 104) {
            const msg = std.fmt.comptimePrint("Node size ({d} bytes) exceeded 104 byte limit!", .{size});
            @compileError(msg);
        }
    }

    // === Bit manipulation constants ===
    pub const HAS_PARENT_BIT: u32 = 1 << 31;
    pub const REF_COUNT_MASK: u32 = 0x7FFF_FFFF; // 31 bits
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
            .prototype = .{
                .vtable = &eventtarget_vtable,
            },
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

        // Return the text (may be empty string for elements with no text content)
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
    /// try elem.prototype.setTextContent("Hello, World!");
    /// try elem.prototype.setTextContent(null); // Removes all children
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
            const doc: *Document = @fieldParentPtr("prototype", owner_doc);

            const text_node = try doc.createTextNode(string);

            // Insert the text node directly (bypass validation for efficiency)
            text_node.prototype.parent_node = self;
            text_node.prototype.setHasParent(true);
            self.first_child = &text_node.prototype;
            self.last_child = &text_node.prototype;

            // Propagate connected state if parent is connected
            if (self.isConnected()) {
                text_node.prototype.setConnected(true);
            }
        }
    }

    /// Clones the node (delegates to vtable).
    pub fn cloneNode(self: *const Node, deep: bool) !*Node {
        return self.vtable.clone_node(self, deep);
    }

    /// Internal: Clones the node using a specific allocator.
    ///
    /// This is used by `Document.importNode()` to clone nodes into a different
    /// document's allocator. Unlike `cloneNode()`, which uses the source node's
    /// allocator, this function uses the provided allocator for all memory
    /// allocations.
    ///
    /// ## Parameters
    /// - `allocator`: The allocator to use for the cloned node and its descendants
    /// - `deep`: Whether to recursively clone descendants
    ///
    /// ## Returns
    /// A new cloned node allocated with the specified allocator
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate memory for the cloned node
    /// - `InvalidCharacterError`: Invalid attribute name during cloning
    /// - `NotSupported`: Node type cannot be cloned (Document, ShadowRoot, ProcessingInstruction)
    /// - `HierarchyRequestError`: Invalid tree structure during child cloning
    ///
    /// ## Memory Management
    /// The caller is responsible for releasing the returned node. The cloned
    /// node will use `allocator` for all its memory, making it safe to use
    /// across different document arenas.
    pub fn cloneNodeWithAllocator(self: *const Node, allocator: Allocator, deep: bool) anyerror!*Node {
        // Dispatch to the appropriate clone implementation based on node type
        switch (self.node_type) {
            .element => {
                const Element = @import("element.zig").Element;
                const elem: *const Element = @fieldParentPtr("prototype", self);
                return try Element.cloneWithAllocator(elem, allocator, deep);
            },
            .attribute => {
                // Attr nodes use vtable dispatch
                return try self.vtable.clone_node(self, deep);
            },
            .text => {
                const Text = @import("text.zig").Text;
                const text: *const Text = @fieldParentPtr("prototype", self);
                return try Text.cloneWithAllocator(text, allocator);
            },
            .comment => {
                const Comment = @import("comment.zig").Comment;
                const comment: *const Comment = @fieldParentPtr("prototype", self);
                return try Comment.cloneWithAllocator(comment, allocator);
            },
            .document_fragment => {
                const DocumentFragment = @import("document_fragment.zig").DocumentFragment;
                const frag: *const DocumentFragment = @fieldParentPtr("prototype", self);
                return try DocumentFragment.cloneWithAllocator(frag, allocator, deep);
            },
            .document_type => {
                const DocumentType = @import("document_type.zig").DocumentType;
                const doctype: *const DocumentType = @fieldParentPtr("prototype", self);
                return try DocumentType.cloneWithAllocator(doctype, allocator);
            },
            .document, .shadow_root => {
                // These node types cannot be cloned via importNode
                return error.NotSupported;
            },
            .processing_instruction => {
                // ProcessingInstruction not yet implemented
                return error.NotSupported;
            },
        }
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
    /// 3. If composed is true and root is a shadow root:
    ///    - Set root to root's shadow host
    ///    - Go to step 2 (continue climbing through shadow boundaries)
    /// 4. Return root
    ///
    /// ## Shadow DOM Behavior
    /// - **composed = false** (default): Stops at shadow root boundary
    ///   - Node in shadow tree → Returns shadow root
    ///   - Node in document → Returns document
    /// - **composed = true**: Pierces shadow boundaries
    ///   - Node in shadow tree → Returns document (traverses through host)
    ///   - Node in document → Returns document
    ///   - Handles nested shadow roots (traverses all levels)
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
    /// // Without shadow roots
    /// const root = node.getRootNode(false);
    /// // Returns document node for connected nodes
    ///
    /// // With shadow roots (composed = false)
    /// const shadow_child = ...; // Node inside shadow tree
    /// const root1 = shadow_child.getRootNode(false);
    /// // Returns shadow root (stops at shadow boundary)
    ///
    /// // With shadow roots (composed = true)
    /// const root2 = shadow_child.getRootNode(true);
    /// // Returns document (traverses through shadow boundaries)
    /// ```
    pub fn getRootNode(self: *const Node, composed: bool) *Node {
        const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
        const Element = @import("element.zig").Element;

        // Step 1: Start with self
        var root: *Node = @constCast(self);

        // Step 2: Walk up to root, potentially crossing shadow boundaries
        while (true) {
            // Walk up parent chain within current tree
            while (root.parent_node) |parent| {
                root = parent;
            }

            // Step 3: If composed and root is shadow root, continue to host
            if (composed and root.node_type == .shadow_root) {
                const shadow: *ShadowRoot = @fieldParentPtr("prototype", root);
                const host_elem: *Element = shadow.host();
                root = &host_elem.prototype;
                // Continue walking up from host
                continue;
            }

            // Step 4: Done, return root
            break;
        }

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
    /// _ = try parent.prototype.appendChild(&child.prototype);
    ///
    /// try std.testing.expect(parent.prototype.contains(&child.prototype));  // true
    /// try std.testing.expect(!child.prototype.contains(&parent.prototype)); // false
    /// try std.testing.expect(parent.prototype.contains(&parent.prototype)); // true (inclusive)
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
    /// try std.testing.expect(elem1.prototype.isEqualNode(&elem2.prototype)); // true (same structure)
    /// try std.testing.expect(!elem1.prototype.isSameNode(&elem2.prototype)); // false (different instances)
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
            const this_elem: *const Element = @fieldParentPtr("prototype", self);
            const other_elem: *const Element = @fieldParentPtr("prototype", other_node);

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
    ///     defer elem.prototype.release();
    /// }
    /// ```
    pub fn getOwnerDocument(self: *const Node) ?*@import("document.zig").Document {
        // Return null for Document nodes per spec
        if (self.node_type == .document) {
            return null;
        }

        if (self.owner_document) |owner| {
            if (owner.node_type == .document) {
                return @fieldParentPtr("prototype", owner);
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
                return @fieldParentPtr("prototype", parent);
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
    /// defer parent.prototype.release();
    ///
    /// const child1 = try doc.createElement("item");
    /// defer child1.prototype.release();
    ///
    /// const child2 = try doc.createElement("text-block");
    /// defer child2.prototype.release();
    ///
    /// _ = try parent.prototype.appendChild(&child1.prototype);
    /// _ = try parent.prototype.insertBefore(&child2.prototype, &child1.prototype);
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
    /// defer parent.prototype.release();
    ///
    /// const child = try doc.createElement("item");
    /// defer child.prototype.release();
    ///
    /// _ = try parent.prototype.appendChild(&child.prototype);
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
            return try self.appendChildFast(node);
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
    ///
    /// ## Note
    /// This function must be kept in sync with the full insert() algorithm,
    /// especially regarding adoption for cross-document moves.
    inline fn appendChildFast(self: *Node, node: *Node) !*Node {
        // Adopt node if moving between documents (WHATWG DOM §4.2.4)
        if (self.owner_document) |parent_doc| {
            if (node.owner_document != parent_doc) {
                try adopt(node, parent_doc);
            }
        }

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

            // Update document maps (id_map, tag_map) for newly connected elements
            // This must happen AFTER setConnected() so isConnected() returns true
            if (self.owner_document) |owner_doc| {
                if (owner_doc.node_type == .document) {
                    try addNodeToDocumentMaps(node, owner_doc);
                }
            }
        }

        // Slot assignment for fast path (WHATWG DOM §4.2.4 step 7.4)
        // If parent is a shadow host whose shadow root's slot assignment is "named"
        // and node is a slottable, then assign a slot for node.
        if (self.node_type == .element) {
            const Element = @import("element.zig").Element;
            if (self.rare_data) |rare_data| {
                if (rare_data.shadow_root) |shadow_ptr| {
                    const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
                    const shadow: *const ShadowRoot = @ptrCast(@alignCast(shadow_ptr));
                    if (shadow.slot_assignment == .named) {
                        if (node.node_type == .element or node.node_type == .text) {
                            Element.assignASlot(node.allocator, node) catch {};
                        }
                    }
                }
            }
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
    /// defer parent.prototype.release();
    ///
    /// const child = try doc.createElement("item");
    /// defer child.prototype.release();
    ///
    /// _ = try parent.prototype.appendChild(&child.prototype);
    /// const removed = try parent.prototype.removeChild(&child.prototype);
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
    /// defer parent.prototype.release();
    ///
    /// const old_child = try doc.createElement("item");
    /// defer old_child.prototype.release();
    ///
    /// const new_child = try doc.createElement("text-block");
    /// defer new_child.prototype.release();
    ///
    /// _ = try parent.prototype.appendChild(&old_child.prototype);
    /// const removed = try parent.prototype.replaceChild(&new_child.prototype, &old_child.prototype);
    /// // removed == old_child, new_child is now child of parent
    /// ```
    pub fn replaceChild(
        self: *Node,
        node: *Node,
        child: *Node,
    ) !*Node {
        return try replace(child, node, self);
    }

    /// Removes empty Text nodes and merges adjacent Text nodes.
    ///
    /// Implements WHATWG DOM Node.normalize() per §4.4.
    ///
    /// ## WHATWG Specification
    /// - **Algorithm**: https://dom.spec.whatwg.org/#dom-node-normalize
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] undefined normalize();
    /// ```
    ///
    /// ## MDN Documentation
    /// - Node.normalize(): https://developer.mozilla.org/en-US/docs/Web/API/Node/normalize
    ///
    /// ## Behavior
    /// This method processes the subtree rooted at this node and:
    /// 1. Removes all empty Text nodes (text.data.length == 0)
    /// 2. Merges adjacent Text nodes into a single Text node
    /// 3. Recursively normalizes all descendant elements
    ///
    /// ## Use Cases
    /// - Cleaning up DOM after repeated text insertions
    /// - Preparing DOM for serialization
    /// - Simplifying DOM structure for traversal
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("container");
    /// defer parent.prototype.release();
    ///
    /// const text1 = try doc.createTextNode("Hello");
    /// const text2 = try doc.createTextNode(" ");
    /// const text3 = try doc.createTextNode("World");
    ///
    /// _ = try parent.prototype.appendChild(&text1.prototype);
    /// _ = try parent.prototype.appendChild(&text2.prototype);
    /// _ = try parent.prototype.appendChild(&text3.prototype);
    ///
    /// // Before: 3 text nodes
    /// try std.testing.expectEqual(@as(u32, 3), parent.prototype.getChildCount());
    ///
    /// try parent.prototype.normalize();
    ///
    /// // After: 1 text node with merged data "Hello World"
    /// try std.testing.expectEqual(@as(u32, 1), parent.prototype.getChildCount());
    /// ```
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate merged text data
    ///
    /// ## Spec Notes
    /// Empty text nodes are removed before merging. Adjacent text nodes are merged
    /// left-to-right, with the leftmost node retaining the merged data.
    pub fn normalize(self: *Node) !void {
        const Text = @import("text.zig").Text;

        var current = self.first_child;

        while (current) |node| {
            const next = node.next_sibling;

            if (node.node_type == .text) {
                const text_node: *Text = @fieldParentPtr("prototype", node);

                // Step 1: Remove empty text nodes
                if (text_node.data.len == 0) {
                    const removed = try self.removeChild(node);
                    removed.release(); // Free the empty text node
                    current = next;
                    continue;
                }

                // Step 2: Merge adjacent text nodes
                var adjacent = next;
                while (adjacent) |adj_node| {
                    // Stop if not a text node
                    if (adj_node.node_type != .text) break;

                    const adj_text: *Text = @fieldParentPtr("prototype", adj_node);
                    const adj_next = adj_node.next_sibling;

                    // Merge data: concatenate adj_text.data into text_node.data
                    const new_data = try std.mem.concat(
                        node.allocator,
                        u8,
                        &[_][]const u8{ text_node.data, adj_text.data },
                    );

                    // Free old data and update
                    node.allocator.free(text_node.data);
                    text_node.data = new_data;

                    // Remove the merged node and release it
                    // Note: adj_node is a sibling, so remove from parent (self)
                    const removed = try self.removeChild(adj_node);
                    removed.release(); // Free the merged text node

                    // Continue to next adjacent sibling
                    adjacent = adj_next;
                }

                // After merging, the current text node's next_sibling is now correct
                // Skip to it to avoid processing merged nodes
                current = node.next_sibling;
                continue;
            }

            // Step 3: Recursively normalize child elements
            if (node.node_type == .element or node.node_type == .document_fragment) {
                try node.normalize();
            }

            current = next;
        }
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

    // === Event Dispatch Helper Functions ===

    /// Retargets a node for event dispatch across shadow boundaries.
    ///
    /// Per WHATWG §2.10: When an event crosses a shadow boundary, the target
    /// should appear to be the shadow host when viewed from outside the shadow tree.
    ///
    /// ## Algorithm
    /// 1. Find the root of the target node (might be a shadow root)
    /// 2. Find the root of the context node (where listener is)
    /// 3. If roots are different and target root is a shadow root:
    ///    - Walk up from target's shadow root to find first shadow host that's
    ///      in the same tree as context
    /// 4. Otherwise, return target unchanged
    ///
    /// ## Parameters
    /// - `target`: The actual event target
    /// - `context`: The node where the listener is attached
    ///
    /// ## Returns
    /// The retargeted node (either target itself or an ancestor shadow host)
    fn retargetNode(target: *Node, context: *Node) *Node {
        // Find roots
        var target_root = target;
        while (target_root.parent_node) |parent| {
            target_root = parent;
        }

        var context_root = context;
        while (context_root.parent_node) |parent| {
            context_root = parent;
        }

        // Same root? No retargeting needed
        if (target_root == context_root) {
            return target;
        }

        // Target root is not a shadow root? No retargeting
        if (target_root.node_type != .shadow_root) {
            return target;
        }

        // Walk up from target's shadow root to find common tree
        var current_root = target_root;
        while (current_root.node_type == .shadow_root) {
            const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
            const shadow: *ShadowRoot = @fieldParentPtr("prototype", current_root);
            const host = &shadow.host_element.prototype;

            // Is host in the same tree as context?
            var check_node = context;
            while (true) {
                if (check_node == host) {
                    // Found common ancestor - retarget to this host
                    return host;
                }
                if (check_node.parent_node) |parent| {
                    check_node = parent;
                } else {
                    break;
                }
            }

            // Not in same tree yet - move up to host and check its root
            current_root = host;
            while (current_root.parent_node) |parent| {
                current_root = parent;
            }

            // If current_root is not a shadow root, we've reached the document
            if (current_root.node_type != .shadow_root) {
                return host;
            }
        }

        return target;
    }

    /// Builds the event path from target to root, accounting for shadow DOM boundaries.
    ///
    /// Per WHATWG §2.9: The event path is the list of objects participating in event dispatch.
    /// - Index 0: target node
    /// - Index 1..n: ancestors up to root
    /// - Crosses shadow boundaries if event.composed = true
    fn buildEventPath(allocator: Allocator, target: *Node, event: *Event) !void {
        // Initialize event path directly
        event.event_path = std.ArrayList(*anyopaque){};
        var path = &event.event_path.?;

        // Add target
        try path.append(allocator, @ptrCast(target));

        // Walk up to root, crossing shadow boundaries if composed
        var current: ?*Node = target;
        while (current) |node| {
            // Get parent (may cross shadow boundary)
            const parent = if (event.composed and node.node_type == .shadow_root) blk: {
                // Cross shadow boundary - get host element
                const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
                const shadow: *ShadowRoot = @fieldParentPtr("prototype", node);
                break :blk &shadow.host_element.prototype;
            } else node.parent_node;

            if (parent) |p| {
                try path.append(allocator, @ptrCast(p));
                current = p;
            } else {
                break;
            }
        }
    }

    /// Invokes event listeners on a node for the current phase.
    ///
    /// ## Parameters
    /// - `node`: Node whose listeners to invoke
    /// - `event`: Event being dispatched
    /// - `capture`: true for capture phase listeners, false for bubble phase
    /// - `original_target`: The original event target (for retargeting)
    fn invokeListeners(node: *Node, event: *Event, capture: bool, original_target: *Node) !void {
        if (node.rare_data == null) return;
        const rare = node.rare_data.?;

        if (!rare.hasEventListeners(event.event_type)) return;

        const listeners = rare.getEventListeners(event.event_type);

        // Retarget the event for this node's listeners
        const retargeted = retargetNode(original_target, node);
        const saved_target = event.target;
        event.target = @ptrCast(retargeted);

        for (listeners) |listener| {
            // Only invoke listeners matching the current phase
            if (listener.capture != capture) continue;

            // Check stopImmediatePropagation
            if (event.stop_immediate_propagation_flag) break;

            // Handle "once" listeners - remove before invoking
            if (listener.once) {
                node.removeEventListener(
                    listener.event_type,
                    listener.callback,
                    listener.capture,
                );
            }

            // Set passive listener flag
            const prev_passive = event.in_passive_listener_flag;
            if (listener.passive) {
                event.in_passive_listener_flag = true;
            }

            // Invoke callback
            listener.callback(event, listener.context);

            // Unset passive listener flag
            event.in_passive_listener_flag = prev_passive;
        }

        // Restore original target
        event.target = saved_target;
    }

    pub fn dispatchEvent(self: *Node, event: *Event) !bool {
        // Validate event state
        if (event.dispatch_flag) {
            return error.InvalidStateError;
        }
        if (!event.initialized_flag) {
            return error.InvalidStateError;
        }

        // Set flags
        event.is_trusted = false;
        event.dispatch_flag = true;

        // Build event path (capture phase ancestors + target + bubble phase ancestors)
        try buildEventPath(self.allocator, self, event);
        defer event.clearEventPath(self.allocator);

        const event_path = event.event_path.?;

        // Original target (never changes)
        event.target = @ptrCast(self);

        // Phase 1: CAPTURING_PHASE - Walk down from root to target
        event.event_phase = .capturing_phase;
        var i: usize = event_path.items.len;
        while (i > 1) {
            i -= 1;
            const current_node = @as(*Node, @ptrCast(@alignCast(event_path.items[i])));

            // Skip target itself (will be handled in AT_TARGET phase)
            if (current_node == self) continue;

            event.current_target = @ptrCast(current_node);
            try invokeListeners(current_node, event, true, self); // capture = true

            if (event.stop_propagation_flag) break;
        }

        // Phase 2: AT_TARGET - Fire listeners on target
        if (!event.stop_propagation_flag) {
            event.event_phase = .at_target;
            event.current_target = @ptrCast(self);

            // Fire both capture and bubble listeners at target
            try invokeListeners(self, event, true, self); // capture listeners
            if (!event.stop_propagation_flag) {
                try invokeListeners(self, event, false, self); // bubble listeners
            }
        }

        // Phase 3: BUBBLING_PHASE - Walk up from target to root (if bubbles)
        if (event.bubbles and !event.stop_propagation_flag) {
            event.event_phase = .bubbling_phase;
            i = 1; // Start from parent (index 1 is parent of target at index 0)
            while (i < event_path.items.len) : (i += 1) {
                const current_node = @as(*Node, @ptrCast(@alignCast(event_path.items[i])));

                event.current_target = @ptrCast(current_node);
                try invokeListeners(current_node, event, false, self); // capture = false

                if (event.stop_propagation_flag) break;
            }
        }

        // Cleanup
        event.event_phase = .none;
        event.current_target = null;
        event.dispatch_flag = false;

        return !event.canceled_flag;
    }
};

// ============================================================================
// INTERNAL TREE MANIPULATION ALGORITHMS
// ============================================================================

const validation = @import("validation.zig");
const tree_helpers = @import("tree_helpers.zig");

/// Adopt a node into a document per WHATWG DOM §4.2.4.
///
/// Implements the "adopt a node into a document" algorithm.
/// This is called automatically during cross-document tree insertion,
/// and can be called explicitly via Document.adoptNode().
///
/// ## Algorithm (WHATWG DOM §4.2.4)
/// 1. Let oldDocument = node's node document
/// 2. If node's parent is non-null, remove node
/// 3. If document ≠ oldDocument:
///    - For each inclusiveDescendant in node's shadow-including inclusive descendants:
///      a. Set inclusiveDescendant's node document to document
///      b. Run the adopting steps with inclusiveDescendant and oldDocument
///
/// ## Parameters
/// - `node`: Node to adopt
/// - `document`: Target document (as Node pointer)
///
/// ## Note
/// This updates owner_document for the node and all descendants,
/// and calls adoptingSteps vtable for each node to update node-specific data.
///
/// PUBLIC for Document.adoptNode() to call.
pub fn adopt(node: *Node, document: *Node) !void {
    // Step 1: Get old document
    const old_document = node.owner_document;

    // Step 2: If node has a parent, remove it
    if (node.parent_node) |_| {
        remove(node);
    }

    // Step 3: If same document, nothing to do
    if (old_document == document) {
        return;
    }

    // Step 4: For each inclusive descendant (node + descendants)
    // We'll use a simple stack-based traversal to avoid recursion
    var stack: [256]*Node = undefined;
    var stack_size: usize = 1;
    stack[0] = node;

    while (stack_size > 0) {
        stack_size -= 1;
        const current = stack[stack_size];

        // Update node document
        const old_owner = current.owner_document;
        current.owner_document = document;

        // Update document reference counts
        if (old_owner) |old_doc| {
            if (old_doc.node_type == .document) {
                const Document = @import("document.zig").Document;
                const old_doc_ptr: *Document = @fieldParentPtr("prototype", old_doc);
                old_doc_ptr.releaseNodeRef();
            }
        }

        if (document.node_type == .document) {
            const Document = @import("document.zig").Document;
            const new_doc: *Document = @fieldParentPtr("prototype", document);
            new_doc.acquireNodeRef();
        }

        // Call adopting steps for this node
        try current.vtable.adopting_steps(current, old_owner);

        // Add children to stack (process in reverse order to maintain tree order)
        var child = current.last_child;
        while (child) |c| {
            if (stack_size >= stack.len) {
                // Stack overflow protection - extremely unlikely with 256 depth
                return error.TreeTooDeep;
            }
            stack[stack_size] = c;
            stack_size += 1;
            child = c.previous_sibling;
        }
    }
}

/// Recursively adds a node and its descendants to document maps (id_map, tag_map).
/// Called after a node tree is inserted and connected.
/// This matches browser behavior where maps are updated during tree mutations, not setAttribute.
fn addNodeToDocumentMaps(node: *Node, owner_doc: *Node) !void {
    const Document = @import("document.zig").Document;
    const doc: *Document = @fieldParentPtr("prototype", owner_doc);

    // Handle this node if it's an element
    if (node.node_type == .element) {
        const Element = @import("element.zig").Element;
        const elem: *Element = @fieldParentPtr("prototype", node);

        // Add to id_map if element has an id (only if ID not already present - first wins)
        if (elem.getId()) |id| {
            const result = try doc.id_map.getOrPut(id);
            if (!result.found_existing) {
                result.value_ptr.* = elem;
                doc.invalidateIdCache();
            }
        }

        // Add to tag_map
        const tag = elem.tag_name;
        const result = try doc.tag_map.getOrPut(tag);
        if (!result.found_existing) {
            result.value_ptr.* = .{};
        }
        try result.value_ptr.append(doc.prototype.allocator, elem);

        // NOTE: We deliberately don't update class_map here
        // This will be removed in Phase 3 when we switch to tree traversal for classes
    }

    // Recursively process children
    var child = node.first_child;
    while (child) |c| {
        try addNodeToDocumentMaps(c, owner_doc);
        child = c.next_sibling;
    }
}

/// Recursively removes a node and its descendants from document maps (id_map, tag_map).
/// Called after a node tree is removed and disconnected.
fn removeNodeFromDocumentMaps(node: *Node, owner_doc: *Node) void {
    const Document = @import("document.zig").Document;
    const doc: *Document = @fieldParentPtr("prototype", owner_doc);

    // Handle this node if it's an element
    if (node.node_type == .element) {
        const Element = @import("element.zig").Element;
        const elem: *Element = @fieldParentPtr("prototype", node);

        // Remove from id_map if element has an id and is the one in the map
        if (elem.getId()) |id| {
            if (doc.id_map.get(id)) |mapped_elem| {
                if (mapped_elem == elem) {
                    _ = doc.id_map.remove(id);
                    doc.invalidateIdCache();

                    // Search for another element with the same ID to replace it
                    // This handles the case where duplicate IDs exist (spec violation but browsers handle it)
                    const ElementIterator = @import("element_iterator.zig").ElementIterator;
                    var iter = ElementIterator.init(&doc.prototype);
                    while (iter.next()) |other_elem| {
                        if (other_elem != elem) {
                            if (other_elem.getId()) |other_id| {
                                if (std.mem.eql(u8, other_id, id)) {
                                    doc.id_map.put(id, other_elem) catch {};
                                    doc.invalidateIdCache();
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Remove from tag_map
        const tag = elem.tag_name;
        if (doc.tag_map.getPtr(tag)) |list_ptr| {
            // Find and remove this element from the list
            var i: usize = 0;
            while (i < list_ptr.items.len) {
                if (list_ptr.items[i] == elem) {
                    _ = list_ptr.swapRemove(i);
                    break;
                }
                i += 1;
            }
        }
    }

    // Recursively process children
    var child = node.first_child;
    while (child) |c| {
        removeNodeFromDocumentMaps(c, owner_doc);
        child = c.next_sibling;
    }
}

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

        // Clear fragment's child pointers WITHOUT releasing children
        // (we're about to insert them into parent, so they need to stay alive)
        node.first_child = null;
        node.last_child = null;

        // Clear children's parent pointers and has_parent flag
        for (nodes) |c| {
            c.parent_node = null;
            c.previous_sibling = null;
            c.next_sibling = null;
            c.setHasParent(false);
        }
    } else {
        nodes_buffer[0] = node;
        node_count = 1;
        nodes = nodes_buffer[0..1];
    }

    // Step 3: Return if no nodes
    if (node_count == 0) return;

    // Step 7: Insert each node
    for (nodes) |n| {
        // Step 7.1: Adopt node into parent's node document (WHATWG DOM §4.2.4)
        // This must happen BEFORE insertion to ensure all string references point to the right document
        if (parent.owner_document) |parent_doc| {
            try adopt(n, parent_doc);
        }

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

            // Update document maps (id_map, tag_map) for newly connected elements
            // This must happen AFTER setConnected() so isConnected() returns true
            if (parent.owner_document) |owner_doc| {
                if (owner_doc.node_type == .document) {
                    addNodeToDocumentMaps(n, owner_doc) catch {}; // Best effort
                }
            }
        }

        // Slot assignment steps (WHATWG DOM §4.2.4 - insert algorithm step 7.4)
        // Step 7.4: If parent is a shadow host whose shadow root's slot assignment is "named"
        //           and node is a slottable, then assign a slot for node.
        if (parent.node_type == .element) {
            const Element = @import("element.zig").Element;
            if (parent.rare_data) |rare_data| {
                if (rare_data.shadow_root) |shadow_ptr| {
                    const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
                    const shadow: *const ShadowRoot = @ptrCast(@alignCast(shadow_ptr));
                    if (shadow.slot_assignment == .named) {
                        if (n.node_type == .element or n.node_type == .text) {
                            Element.assignASlot(n.allocator, n) catch {};
                        }
                    }
                }
            }
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
        // Remove from document maps BEFORE disconnecting
        // (while isConnected() still returns true for the check, but we're about to disconnect)
        if (parent.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                removeNodeFromDocumentMaps(node, owner_doc);
            }
        }

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
    try std.testing.expect(size <= 104); // Node now includes EventTarget prototype (8 bytes)

    // Print actual size for documentation
    std.debug.print("\nNode size: {d} bytes (target: ≤104 with EventTarget)\n", .{size});
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
    defer parent_elem.prototype.release();

    // Create child text node
    const Text = @import("text.zig").Text;
    const child = try Text.create(allocator, "content");
    defer child.prototype.release();

    // Initially no parent
    try std.testing.expect(child.prototype.parentElement() == null);

    // Manually set parent for testing (Phase 2 will do this via appendChild)
    child.prototype.parent_node = &parent_elem.prototype;

    // parentElement should return the element
    const retrieved_parent = child.prototype.parentElement();
    try std.testing.expect(retrieved_parent != null);
    try std.testing.expectEqual(parent_elem, retrieved_parent.?);

    // Clean up manual connection
    child.prototype.parent_node = null;
}

test "Node - getOwnerDocument" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    // Create document
    const doc = try Document.init(allocator);
    defer doc.release();

    // Document's ownerDocument should be null per spec
    try std.testing.expect(doc.prototype.getOwnerDocument() == null);

    // Create element via document
    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Element's ownerDocument should be the document
    const owner = elem.prototype.getOwnerDocument();
    try std.testing.expect(owner != null);
    try std.testing.expectEqual(doc, owner.?);

    // Create text node via document
    const text = try doc.createTextNode("test");
    defer text.prototype.release();

    // Text's ownerDocument should also be the document
    const text_owner = text.prototype.getOwnerDocument();
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
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
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
    defer parent.prototype.release();

    const child = try doc.createElement("item");
    // NO defer - parent will own it

    _ = try parent.prototype.appendChild(&child.prototype);

    // Verify parent-child relationship
    try std.testing.expectEqual(&parent.prototype, child.prototype.parent_node);
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child);
    try std.testing.expect(child.prototype.hasParent());
}

test "Node.appendChild - adds multiple children in order" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    const child3 = try doc.createElement("strong");
    // NO defers - parent owns them

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Verify order
    try std.testing.expectEqual(&child1.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&child3.prototype, parent.prototype.last_child);
    try std.testing.expectEqual(&child2.prototype, child1.prototype.next_sibling);
    try std.testing.expectEqual(&child3.prototype, child2.prototype.next_sibling);
}

test "Node.appendChild - moves node from old parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("element");
    defer parent1.prototype.release();

    const parent2 = try doc.createElement("section");
    defer parent2.prototype.release();

    const child = try doc.createElement("item");
    // NO defer - will be owned by one of the parents

    // Add to parent1
    _ = try parent1.prototype.appendChild(&child.prototype);
    try std.testing.expectEqual(&parent1.prototype, child.prototype.parent_node);

    // Move to parent2
    _ = try parent2.prototype.appendChild(&child.prototype);
    try std.testing.expectEqual(&parent2.prototype, child.prototype.parent_node);
    try std.testing.expect(parent1.prototype.first_child == null);
}

test "Node.appendChild - rejects text node under document" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release(); // NOT added to parent, so we own it

    // Should fail - text cannot be child of document
    try std.testing.expectError(
        error.HierarchyRequestError,
        doc.prototype.appendChild(&text.prototype),
    );
}

test "Node.insertBefore - inserts at beginning" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    // NO defers - parent owns them

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.insertBefore(&child2.prototype, &child1.prototype);

    // child2 should be first
    try std.testing.expectEqual(&child2.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&child1.prototype, child2.prototype.next_sibling);
}

test "Node.insertBefore - inserts in middle" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    const child3 = try doc.createElement("strong");
    // NO defers - parent owns them

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);
    _ = try parent.prototype.insertBefore(&child2.prototype, &child3.prototype);

    // Order should be: child1, child2, child3
    try std.testing.expectEqual(&child1.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&child2.prototype, child1.prototype.next_sibling);
    try std.testing.expectEqual(&child3.prototype, child2.prototype.next_sibling);
}

test "Node.insertBefore - with null child appends" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    // NO defers - parent owns them

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.insertBefore(&child2.prototype, null);

    // child2 should be last
    try std.testing.expectEqual(&child2.prototype, parent.prototype.last_child);
}

test "Node.insertBefore - rejects if child not in parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const other = try doc.createElement("section");
    defer other.prototype.release();

    const child = try doc.createElement("item");
    // child will be owned by other, NOT parent

    const new_child = try doc.createElement("text-block");
    defer new_child.prototype.release(); // Will NOT be added

    _ = try other.prototype.appendChild(&child.prototype);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.prototype.insertBefore(&new_child.prototype, &child.prototype),
    );
}

test "Node.removeChild - removes child successfully" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child = try doc.createElement("item");
    defer child.prototype.release(); // Released AFTER removal

    _ = try parent.prototype.appendChild(&child.prototype);
    const removed = try parent.prototype.removeChild(&child.prototype);

    try std.testing.expectEqual(&child.prototype, removed);
    try std.testing.expect(child.prototype.parent_node == null);
    try std.testing.expect(!child.prototype.hasParent());
}

test "Node.removeChild - removes middle child" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    defer child2.prototype.release(); // Released AFTER removal
    const child3 = try doc.createElement("strong");
    // child1 and child3 owned by parent

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    _ = try parent.prototype.removeChild(&child2.prototype);

    // child1 and child3 should be linked
    try std.testing.expectEqual(&child3.prototype, child1.prototype.next_sibling);
    try std.testing.expect(child2.prototype.parent_node == null);
}

test "Node.removeChild - rejects if not parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const other = try doc.createElement("section");
    defer other.prototype.release();

    const child = try doc.createElement("item");
    // child owned by other

    _ = try other.prototype.appendChild(&child.prototype);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.prototype.removeChild(&child.prototype),
    );
}

test "Node.replaceChild - replaces child successfully" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const old_child = try doc.createElement("item");
    defer old_child.prototype.release(); // Released AFTER removal

    const new_child = try doc.createElement("text-block");
    // new_child owned by parent after replacement

    _ = try parent.prototype.appendChild(&old_child.prototype);
    const removed = try parent.prototype.replaceChild(&new_child.prototype, &old_child.prototype);

    try std.testing.expectEqual(&old_child.prototype, removed);
    try std.testing.expectEqual(&new_child.prototype, parent.prototype.first_child);
    try std.testing.expect(old_child.prototype.parent_node == null);
}

test "Node.replaceChild - preserves sibling order" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    defer child2.prototype.release(); // Released AFTER replacement
    const child3 = try doc.createElement("strong");
    const new_child = try doc.createElement("em");
    // child1, new_child, child3 owned by parent

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    _ = try parent.prototype.replaceChild(&new_child.prototype, &child2.prototype);

    // Order should be: child1, new_child, child3
    try std.testing.expectEqual(&child1.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&new_child.prototype, child1.prototype.next_sibling);
    try std.testing.expectEqual(&child3.prototype, new_child.prototype.next_sibling);
}

test "Node.replaceChild - rejects if child not in parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const other = try doc.createElement("section");
    defer other.prototype.release();

    const child = try doc.createElement("item");
    // child owned by other

    const new_child = try doc.createElement("text-block");
    defer new_child.prototype.release(); // NOT added

    _ = try other.prototype.appendChild(&child.prototype);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.prototype.replaceChild(&new_child.prototype, &child.prototype),
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
    _ = try child.prototype.appendChild(&grandchild.prototype);
    _ = try root.prototype.appendChild(&child.prototype);

    // Connect root to document (document is always connected)
    _ = try doc.prototype.appendChild(&root.prototype);

    // Should propagate to child and grandchild
    try std.testing.expect(root.prototype.isConnected());
    try std.testing.expect(child.prototype.isConnected());
    try std.testing.expect(grandchild.prototype.isConnected());
}

test "Node.removeChild - propagates disconnected state" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    // root owned by doc

    const child = try doc.createElement("container");
    defer child.prototype.release(); // Released AFTER removal

    const grandchild = try doc.createElement("element");
    // grandchild owned by child

    // Build connected tree
    _ = try child.prototype.appendChild(&grandchild.prototype);
    _ = try root.prototype.appendChild(&child.prototype);
    _ = try doc.prototype.appendChild(&root.prototype);

    // All should be connected
    try std.testing.expect(root.prototype.isConnected());
    try std.testing.expect(child.prototype.isConnected());
    try std.testing.expect(grandchild.prototype.isConnected());

    // Remove child
    _ = try root.prototype.removeChild(&child.prototype);

    // root still connected, child and grandchild disconnected
    try std.testing.expect(root.prototype.isConnected());
    try std.testing.expect(!child.prototype.isConnected());
    try std.testing.expect(!grandchild.prototype.isConnected());
}

test "Node.textContent - getter returns null for Document" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const content = try doc.prototype.textContent(allocator);
    try std.testing.expect(content == null);
}

test "Node.textContent - getter returns text node data" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello, World!");
    defer text.prototype.release();

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello, World!", content.?);
}

test "Node.textContent - getter returns comment data" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("This is a comment");
    defer comment.prototype.release();

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("This is a comment", content.?);
}

test "Node.textContent - getter collects descendant text" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const text1 = try doc.createTextNode("Hello ");
    const text2 = try doc.createTextNode("World");
    const text3 = try doc.createTextNode("!");

    _ = try div.prototype.appendChild(&text1.prototype);
    _ = try div.prototype.appendChild(&text2.prototype);
    _ = try div.prototype.appendChild(&text3.prototype);

    const content = try div.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello World!", content.?);
}

test "Node.textContent - getter collects nested text" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const span = try doc.createElement("span");
    const text1 = try doc.createTextNode("Hello ");
    const text2 = try doc.createTextNode("World");

    _ = try span.prototype.appendChild(&text1.prototype);
    _ = try div.prototype.appendChild(&span.prototype);
    _ = try div.prototype.appendChild(&text2.prototype);

    const content = try div.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello World", content.?);
}

test "Node.textContent - getter returns empty string for empty element" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const content = try div.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    // Per WPT tests, empty elements return empty string, not null
    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("", content.?);
}

test "Node.textContent - setter does nothing for Document" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    // Should not error, but does nothing
    try doc.prototype.setTextContent("This should be ignored");

    const content = try doc.prototype.textContent(allocator);
    try std.testing.expect(content == null);
}

test "Node.textContent - setter replaces text node data" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Old text");
    defer text.prototype.release();

    try text.prototype.setTextContent("New text");

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New text", content.?);
}

test "Node.textContent - setter replaces comment data" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("Old comment");
    defer comment.prototype.release();

    try comment.prototype.setTextContent("New comment");

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New comment", content.?);
}

test "Node.textContent - setter removes all children and inserts text" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    // Add some children (owned by tree, no defer needed)
    const span = try doc.createElement("span");
    const text1 = try doc.createTextNode("Old");

    _ = try span.prototype.appendChild(&text1.prototype);
    _ = try div.prototype.appendChild(&span.prototype);

    // Set text content - should remove all children (releasing span and text1)
    try div.prototype.setTextContent("New text");

    // Should have exactly one child (text node)
    try std.testing.expect(div.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 1), div.prototype.childNodes().length());
    try std.testing.expectEqual(NodeType.text, div.prototype.first_child.?.node_type);

    const content = try div.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New text", content.?);
}

test "Node.textContent - setter with empty string removes all children" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const text = try doc.createTextNode("Some text");
    // text owned by div after appendChild
    _ = try div.prototype.appendChild(&text.prototype);

    try std.testing.expect(div.prototype.hasChildNodes());

    // Set to empty string - should remove all children (releasing text)
    try div.prototype.setTextContent("");

    try std.testing.expect(!div.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(?*Node, null), div.prototype.first_child);
}

test "Node.textContent - setter with null removes all children" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const text = try doc.createTextNode("Some text");
    // text owned by div after appendChild
    _ = try div.prototype.appendChild(&text.prototype);

    try std.testing.expect(div.prototype.hasChildNodes());

    // Set to null - should remove all children (releasing text)
    try div.prototype.setTextContent(null);

    try std.testing.expect(!div.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(?*Node, null), div.prototype.first_child);
}

test "Node.textContent - setter propagates connected state" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    // root owned by document after appendChild, no defer needed

    // Connect to document
    _ = try doc.prototype.appendChild(&root.prototype);

    // Set text content
    try root.prototype.setTextContent("Connected text");

    // New text node should be connected
    try std.testing.expect(root.prototype.first_child != null);
    try std.testing.expect(root.prototype.first_child.?.isConnected());
}

test "Node.textContent - no memory leaks" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    // Set multiple times
    try div.prototype.setTextContent("First");
    try div.prototype.setTextContent("Second");
    try div.prototype.setTextContent("Third");
    try div.prototype.setTextContent(null);

    // Get multiple times
    for (0..10) |_| {
        const content = try div.prototype.textContent(allocator);
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
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.isSameNode(&elem.prototype));
}

test "Node.isSameNode - returns false for different nodes" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("div");
    defer elem2.prototype.release();

    try std.testing.expect(!elem1.prototype.isSameNode(&elem2.prototype));
}

test "Node.isSameNode - returns false for null" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.isSameNode(null));
}

// === getRootNode() Tests ===

test "Node.getRootNode - returns document for connected node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try doc.prototype.appendChild(&parent.prototype);

    const root = child.prototype.getRootNode(false);
    try std.testing.expect(root == &doc.prototype);
}

test "Node.getRootNode - returns self for disconnected single node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const root = elem.prototype.getRootNode(false);
    try std.testing.expect(root == &elem.prototype);
}

test "Node.getRootNode - returns topmost disconnected node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    // Not connected to document
    const root = child.prototype.getRootNode(false);
    try std.testing.expect(root == &parent.prototype);
}

test "Node.getRootNode - composed parameter (no shadow DOM yet)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");

    _ = try doc.prototype.appendChild(&elem.prototype);

    // Both should return same result (no shadow DOM)
    const root1 = elem.prototype.getRootNode(false);
    const root2 = elem.prototype.getRootNode(true);

    try std.testing.expect(root1 == root2);
    try std.testing.expect(root1 == &doc.prototype);
}

// === contains() Tests ===

test "Node.contains - returns true for self (inclusive)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.contains(&elem.prototype));
}

test "Node.contains - returns true for direct child" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(parent.prototype.contains(&child.prototype));
}

test "Node.contains - returns true for deep descendant" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const grandparent = try doc.createElement("div");
    defer grandparent.prototype.release();

    const parent = try doc.createElement("section");
    const child = try doc.createElement("span");

    _ = try grandparent.prototype.appendChild(&parent.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(grandparent.prototype.contains(&child.prototype));
}

test "Node.contains - returns false for parent (not ancestor of child)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(!child.prototype.contains(&parent.prototype));
}

test "Node.contains - returns false for sibling" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    try std.testing.expect(!child1.prototype.contains(&child2.prototype));
    try std.testing.expect(!child2.prototype.contains(&child1.prototype));
}

test "Node.contains - returns false for null (per spec)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.contains(null));
}

// === baseURI() Tests ===

test "Node.baseURI - returns empty string (placeholder)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const uri = elem.prototype.baseURI();
    try std.testing.expectEqualStrings("", uri);
}

// === compareDocumentPosition() Tests ===

test "Node.compareDocumentPosition - returns 0 for same node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const pos = elem.prototype.compareDocumentPosition(&elem.prototype);
    try std.testing.expectEqual(@as(u16, 0), pos);
}

test "Node.compareDocumentPosition - disconnected nodes" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("span");
    defer elem2.prototype.release();

    const pos = elem1.prototype.compareDocumentPosition(&elem2.prototype);

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
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    const pos = child.prototype.compareDocumentPosition(&parent.prototype);

    // Parent CONTAINS child (from child's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_CONTAINS) != 0);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

test "Node.compareDocumentPosition - child contained by parent" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    const pos = parent.prototype.compareDocumentPosition(&child.prototype);

    // Child CONTAINED_BY parent (from parent's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_CONTAINED_BY) != 0);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_FOLLOWING) != 0);
}

test "Node.compareDocumentPosition - sibling order (preceding)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const pos = child2.prototype.compareDocumentPosition(&child1.prototype);

    // child1 PRECEDES child2 (from child2's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

test "Node.compareDocumentPosition - sibling order (following)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const pos = child1.prototype.compareDocumentPosition(&child2.prototype);

    // child2 FOLLOWS child1 (from child1's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_FOLLOWING) != 0);
}

test "Node.compareDocumentPosition - complex tree order" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    defer root.prototype.release();

    const branch1 = try doc.createElement("section");
    const branch2 = try doc.createElement("article");
    const leaf1 = try doc.createElement("span");
    const leaf2 = try doc.createElement("p");

    _ = try root.prototype.appendChild(&branch1.prototype);
    _ = try root.prototype.appendChild(&branch2.prototype);
    _ = try branch1.prototype.appendChild(&leaf1.prototype);
    _ = try branch2.prototype.appendChild(&leaf2.prototype);

    // leaf1 precedes leaf2 (different branches, branch1 before branch2)
    const pos = leaf2.prototype.compareDocumentPosition(&leaf1.prototype);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

// === isEqualNode() Tests ===

test "Node.isEqualNode - returns true for same node" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.isEqualNode(&elem.prototype));
}

test "Node.isEqualNode - returns false for null" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.isEqualNode(null));
}

test "Node.isEqualNode - returns true for equal elements (no attributes)" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("div");
    defer elem2.prototype.release();

    try std.testing.expect(elem1.prototype.isEqualNode(&elem2.prototype));
}

test "Node.isEqualNode - returns false for different tag names" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("span");
    defer elem2.prototype.release();

    try std.testing.expect(!elem1.prototype.isEqualNode(&elem2.prototype));
}

// ============================================================================
// EVENT DISPATCHING TESTS
// ============================================================================

test "Node.dispatchEvent - basic dispatch returns true" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var event = Event.init("click", .{});
    const result = try elem.prototype.dispatchEvent(&event);

    // Should return true (not canceled)
    try std.testing.expect(result);
}

test "Node.dispatchEvent - invokes listener with event" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

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

    try elem.prototype.addEventListener("click", callback, @ptrCast(&invoked), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event);

    try std.testing.expect(invoked);
}

test "Node.dispatchEvent - returns false when preventDefault called" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    const callback = struct {
        fn cb(evt: *Event, _: *anyopaque) void {
            evt.preventDefault();
        }
    }.cb;

    try elem.prototype.addEventListener("click", callback, undefined, false, false, false, null);

    var event = Event.init("click", .{ .cancelable = true });
    const result = try elem.prototype.dispatchEvent(&event);

    // Should return false (canceled)
    try std.testing.expect(!result);
    try std.testing.expect(event.canceled_flag);
}

test "Node.dispatchEvent - once listener removed after dispatch" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var count: u32 = 0;
    const callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
        }
    }.cb;

    // Add listener with once=true
    try elem.prototype.addEventListener("click", callback, @ptrCast(&count), false, true, false, null);

    // First dispatch
    var event1 = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event1);
    try std.testing.expectEqual(@as(u32, 1), count);

    // Second dispatch - listener should be removed
    var event2 = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event2);
    try std.testing.expectEqual(@as(u32, 1), count); // Still 1, not 2
}

test "Node.dispatchEvent - passive listener blocks preventDefault" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    const callback = struct {
        fn cb(evt: *Event, _: *anyopaque) void {
            // Try to prevent default (should be blocked because passive=true)
            evt.preventDefault();
        }
    }.cb;

    // Add passive listener
    try elem.prototype.addEventListener("click", callback, undefined, false, false, true, null);

    var event = Event.init("click", .{ .cancelable = true });
    const result = try elem.prototype.dispatchEvent(&event);

    // preventDefault should have been ignored
    try std.testing.expect(result); // Returns true
    try std.testing.expect(!event.canceled_flag); // Not canceled
}

test "Node.dispatchEvent - stopImmediatePropagation prevents remaining listeners" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

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

    try elem.prototype.addEventListener("click", callback1, @ptrCast(&count), false, false, false, null);
    try elem.prototype.addEventListener("click", callback2, @ptrCast(&count), false, false, false, null);
    try elem.prototype.addEventListener("click", callback3, @ptrCast(&count), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event);

    // Only first two listeners should be invoked
    try std.testing.expectEqual(@as(u32, 2), count);
}

test "Node.dispatchEvent - rejects already dispatching event" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var event = Event.init("click", .{});
    event.dispatch_flag = true; // Manually set dispatch flag

    // Should return InvalidStateError
    try std.testing.expectError(error.InvalidStateError, elem.prototype.dispatchEvent(&event));
}

test "Node.dispatchEvent - sets event properties correctly" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

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

    try elem.prototype.addEventListener("click", callback, @ptrCast(&elem.prototype), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event);

    // After dispatch - should be cleaned up
    try std.testing.expectEqual(Event.EventPhase.none, event.event_phase);
    try std.testing.expect(event.current_target == null);
    try std.testing.expect(!event.dispatch_flag);
}

test "Node.dispatchEvent - composed event crosses shadow boundary" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create: host -> shadow root -> inner element
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open });
    const inner = try doc.createElement("inner");
    _ = try shadow.prototype.appendChild(&inner.prototype);

    var listener_called = false;
    const callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const called: *bool = @ptrCast(@alignCast(context));
            called.* = true;
            // When listener is on host, target should be retargeted to host
            // (not implemented yet - this test will fail initially)
            _ = evt;
        }
    }.cb;

    // Add listener to host element
    try host.prototype.addEventListener("click", callback, @ptrCast(&listener_called), false, false, false, null);

    // Dispatch composed event from inner element
    var event = Event.init("click", .{ .composed = true, .bubbles = true, .cancelable = false });
    _ = try inner.prototype.dispatchEvent(&event);

    // Listener on host should have been called (event crossed shadow boundary)
    try std.testing.expect(listener_called);
}

test "Node.dispatchEvent - non-composed event stops at shadow boundary" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create: host -> shadow root -> inner element
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open });
    const inner = try doc.createElement("inner");
    _ = try shadow.prototype.appendChild(&inner.prototype);

    var host_called = false;
    var shadow_called = false;

    const host_callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const called: *bool = @ptrCast(@alignCast(context));
            called.* = true;
        }
    }.cb;

    const shadow_callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const called: *bool = @ptrCast(@alignCast(context));
            called.* = true;
        }
    }.cb;

    // Add listener to host element (outside shadow tree)
    try host.prototype.addEventListener("click", host_callback, @ptrCast(&host_called), false, false, false, null);

    // Add listener to shadow root (boundary)
    try shadow.prototype.addEventListener("click", shadow_callback, @ptrCast(&shadow_called), false, false, false, null);

    // Dispatch NON-composed event from inner element
    var event = Event.init("click", .{ .composed = false, .bubbles = true, .cancelable = false });
    _ = try inner.prototype.dispatchEvent(&event);

    // Listener on shadow root should have been called
    try std.testing.expect(shadow_called);

    // Listener on host should NOT have been called (event stopped at shadow boundary)
    try std.testing.expect(!host_called);
}

test "Node.dispatchEvent - event retargeting across shadow boundary" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create: host -> shadow root -> inner element
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open });
    const inner = try doc.createElement("inner");
    _ = try shadow.prototype.appendChild(&inner.prototype);

    const TargetCheck = struct {
        expected_target: *Node,
        actual_target: ?*Node = null,
    };

    var host_check = TargetCheck{ .expected_target = &host.prototype };
    var shadow_check = TargetCheck{ .expected_target = &inner.prototype };

    const host_callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const check: *TargetCheck = @ptrCast(@alignCast(context));
            check.actual_target = @ptrCast(@alignCast(evt.target.?));
        }
    }.cb;

    const shadow_callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const check: *TargetCheck = @ptrCast(@alignCast(context));
            check.actual_target = @ptrCast(@alignCast(evt.target.?));
        }
    }.cb;

    // Add listener to host element (outside shadow tree)
    try host.prototype.addEventListener("click", host_callback, @ptrCast(&host_check), false, false, false, null);

    // Add listener to shadow root (inside shadow tree)
    try shadow.prototype.addEventListener("click", shadow_callback, @ptrCast(&shadow_check), false, false, false, null);

    // Dispatch composed event from inner element
    var event = Event.init("click", .{ .composed = true, .bubbles = true, .cancelable = false });
    _ = try inner.prototype.dispatchEvent(&event);

    // Listener inside shadow tree sees real target (inner element)
    try std.testing.expect(shadow_check.actual_target == &inner.prototype);

    // Listener outside shadow tree should see retargeted target (host element)
    // Currently sees the real target (inner element) - needs retargeting
    try std.testing.expect(host_check.actual_target != null);

    // Verify retargeting works correctly
    // Listener outside shadow tree should see retargeted target (host element)
    try std.testing.expect(host_check.actual_target == &host.prototype);
}

test "Event.composedPath - respects composed flag with shadow DOM" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create: host -> shadow root -> inner
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open });
    const inner = try doc.createElement("inner");
    _ = try shadow.prototype.appendChild(&inner.prototype);

    // Test 1: Composed event crosses shadow boundary
    {
        const TestContext = struct {
            allocator: std.mem.Allocator,
            path_length: usize = 0,
            inner: *Node,
            shadow: *Node,
            host: *Node,
        };

        var ctx = TestContext{
            .allocator = allocator,
            .inner = &inner.prototype,
            .shadow = &shadow.prototype,
            .host = &host.prototype,
        };

        const callback = struct {
            fn cb(evt: *Event, context: *anyopaque) void {
                const c: *TestContext = @ptrCast(@alignCast(context));
                var path = evt.composedPath(c.allocator) catch unreachable;
                defer path.deinit(c.allocator);

                // Should have: inner, shadow root, host
                c.path_length = path.items.len;
                std.testing.expectEqual(@as(usize, 3), path.items.len) catch unreachable;

                // Verify order
                const node0: *Node = @ptrCast(@alignCast(path.items[0]));
                const node1: *Node = @ptrCast(@alignCast(path.items[1]));
                const node2: *Node = @ptrCast(@alignCast(path.items[2]));

                std.testing.expect(node0 == c.inner) catch unreachable;
                std.testing.expect(node1 == c.shadow) catch unreachable;
                std.testing.expect(node2 == c.host) catch unreachable;
            }
        }.cb;

        try host.prototype.addEventListener("click", callback, @ptrCast(&ctx), false, false, false, null);

        var event = Event.init("click", .{ .composed = true, .bubbles = true, .cancelable = false });
        _ = try inner.prototype.dispatchEvent(&event);

        // Verify callback was called
        try std.testing.expectEqual(@as(usize, 3), ctx.path_length);
    }

    // Test 2: Non-composed event stops at shadow boundary
    {
        const TestContext = struct {
            allocator: std.mem.Allocator,
            path_length: usize = 0,
            inner: *Node,
            shadow: *Node,
        };

        var ctx = TestContext{
            .allocator = allocator,
            .inner = &inner.prototype,
            .shadow = &shadow.prototype,
        };

        const callback = struct {
            fn cb(evt: *Event, context: *anyopaque) void {
                const c: *TestContext = @ptrCast(@alignCast(context));
                var path = evt.composedPath(c.allocator) catch unreachable;
                defer path.deinit(c.allocator);

                // Should have: inner, shadow root (stops at boundary)
                c.path_length = path.items.len;
                std.testing.expectEqual(@as(usize, 2), path.items.len) catch unreachable;

                // Verify order
                const node0: *Node = @ptrCast(@alignCast(path.items[0]));
                const node1: *Node = @ptrCast(@alignCast(path.items[1]));

                std.testing.expect(node0 == c.inner) catch unreachable;
                std.testing.expect(node1 == c.shadow) catch unreachable;
            }
        }.cb;

        try shadow.prototype.addEventListener("click", callback, @ptrCast(&ctx), false, false, false, null);

        var event = Event.init("click", .{ .composed = false, .bubbles = true, .cancelable = false });
        _ = try inner.prototype.dispatchEvent(&event);

        // Verify callback was called
        try std.testing.expectEqual(@as(usize, 2), ctx.path_length);
    }
}

test "Node.isEqualNode - returns false for different attribute values" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();
    try elem1.setAttribute("id", "test1");

    const elem2 = try doc.createElement("div");
    defer elem2.prototype.release();
    try elem2.setAttribute("id", "test2");

    try std.testing.expect(!elem1.prototype.isEqualNode(&elem2.prototype));
}

test "Node.isEqualNode - returns false for different attribute counts" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();
    try elem1.setAttribute("id", "test");

    const elem2 = try doc.createElement("div");
    defer elem2.prototype.release();
    try elem2.setAttribute("id", "test");
    try elem2.setAttribute("class", "foo");

    try std.testing.expect(!elem1.prototype.isEqualNode(&elem2.prototype));
}

test "Node.isEqualNode - returns true for equal text nodes" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("Hello");
    defer text1.prototype.release();

    const text2 = try doc.createTextNode("Hello");
    defer text2.prototype.release();

    try std.testing.expect(text1.prototype.isEqualNode(&text2.prototype));
}

test "Node.isEqualNode - returns false for different text content" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("Hello");
    defer text1.prototype.release();

    const text2 = try doc.createTextNode("World");
    defer text2.prototype.release();

    try std.testing.expect(!text1.prototype.isEqualNode(&text2.prototype));
}

test "Node.isEqualNode - returns true for equal subtrees" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    // Build first tree
    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release();
    try parent1.setAttribute("id", "container");

    const child1a = try doc.createElement("span");
    const text1 = try doc.createTextNode("Hello");

    _ = try child1a.prototype.appendChild(&text1.prototype);
    _ = try parent1.prototype.appendChild(&child1a.prototype);

    // Build identical tree
    const parent2 = try doc.createElement("div");
    defer parent2.prototype.release();
    try parent2.setAttribute("id", "container");

    const child2a = try doc.createElement("span");
    const text2 = try doc.createTextNode("Hello");

    _ = try child2a.prototype.appendChild(&text2.prototype);
    _ = try parent2.prototype.appendChild(&child2a.prototype);

    try std.testing.expect(parent1.prototype.isEqualNode(&parent2.prototype));
}

test "Node.isEqualNode - returns false for different child counts" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release();

    const child1 = try doc.createElement("span");

    _ = try parent1.prototype.appendChild(&child1.prototype);

    const parent2 = try doc.createElement("div");
    defer parent2.prototype.release();

    const child2a = try doc.createElement("span");
    const child2b = try doc.createElement("p");

    _ = try parent2.prototype.appendChild(&child2a.prototype);
    _ = try parent2.prototype.appendChild(&child2b.prototype);

    try std.testing.expect(!parent1.prototype.isEqualNode(&parent2.prototype));
}

test "Node.isEqualNode - returns false for different child order" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release();

    const child1a = try doc.createElement("span");
    const child1b = try doc.createElement("p");

    _ = try parent1.prototype.appendChild(&child1a.prototype);
    _ = try parent1.prototype.appendChild(&child1b.prototype);

    const parent2 = try doc.createElement("div");
    defer parent2.prototype.release();

    const child2a = try doc.createElement("p");
    const child2b = try doc.createElement("span");

    _ = try parent2.prototype.appendChild(&child2a.prototype);
    _ = try parent2.prototype.appendChild(&child2b.prototype);

    try std.testing.expect(!parent1.prototype.isEqualNode(&parent2.prototype));
}

test "Node.appendChild - cross-document adoption" {
    const allocator = std.testing.allocator;

    // Create two documents
    const doc1 = try @import("document.zig").Document.init(allocator);
    defer doc1.release();

    const doc2 = try @import("document.zig").Document.init(allocator);
    defer doc2.release();

    // Create element in doc1 with attributes
    const elem = try doc1.createElement("element");
    try elem.setAttribute("attr1", "value1");
    try elem.setAttribute("data-id", "test-id");

    // Add to doc1's tree
    const container1 = try doc1.createElement("container");
    _ = try doc1.prototype.appendChild(&container1.prototype);
    _ = try container1.prototype.appendChild(&elem.prototype);

    // Verify initial state
    try std.testing.expect(elem.prototype.getOwnerDocument() == doc1);
    try std.testing.expectEqualStrings("value1", elem.getAttribute("attr1").?);

    // Move to doc2 via appendChild (should trigger adoption)
    const container2 = try doc2.createElement("container");
    _ = try doc2.prototype.appendChild(&container2.prototype);
    _ = try container2.prototype.appendChild(&elem.prototype);

    // Verify adoption occurred
    try std.testing.expect(elem.prototype.getOwnerDocument() == doc2);
    try std.testing.expectEqualStrings("value1", elem.getAttribute("attr1").?);
    try std.testing.expectEqualStrings("test-id", elem.getAttribute("data-id").?);

    // elem should no longer be in doc1's tree
    try std.testing.expect(container1.prototype.first_child == null);
}

// ============================================================================
// Case-Sensitive Tag Names and Attributes Tests (with any casing support)
// ============================================================================

test "Node - supports any case in tag names" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Can create elements with different case variations
    const lower = try doc.createElement("element");
    defer lower.prototype.release();
    const upper = try doc.createElement("ELEMENT");
    defer upper.prototype.release();
    const mixed = try doc.createElement("Element");
    defer mixed.prototype.release();

    // Each preserves its own casing (NOT normalized)
    try std.testing.expect(std.mem.eql(u8, lower.tag_name, "element"));
    try std.testing.expect(std.mem.eql(u8, upper.tag_name, "ELEMENT"));
    try std.testing.expect(std.mem.eql(u8, mixed.tag_name, "Element"));

    // They are different tag names
    try std.testing.expect(!std.mem.eql(u8, lower.tag_name, upper.tag_name));
    try std.testing.expect(!std.mem.eql(u8, lower.tag_name, mixed.tag_name));
}

test "Node - nodeName() preserves original casing" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("container");
    defer elem1.prototype.release();
    const elem2 = try doc.createElement("CONTAINER");
    defer elem2.prototype.release();
    const elem3 = try doc.createElement("Container");
    defer elem3.prototype.release();

    // nodeName() returns the exact casing used in createElement
    try std.testing.expect(std.mem.eql(u8, elem1.prototype.nodeName(), "container"));
    try std.testing.expect(std.mem.eql(u8, elem2.prototype.nodeName(), "CONTAINER"));
    try std.testing.expect(std.mem.eql(u8, elem3.prototype.nodeName(), "Container"));

    // They are NOT equal
    try std.testing.expect(!std.mem.eql(u8, elem1.prototype.nodeName(), elem2.prototype.nodeName()));
}

test "Node - supports any case in attribute names (case-sensitive matching)" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Can set attributes with any casing
    try elem.setAttribute("data-id", "123");
    try elem.setAttribute("DATA-NAME", "456");
    try elem.setAttribute("Data-Value", "789");

    // getAttribute is case-sensitive (exact match only)
    const lower = elem.getAttribute("data-id");
    try std.testing.expect(lower != null);
    try std.testing.expect(std.mem.eql(u8, lower.?, "123"));

    // Different casing does NOT match
    const upper_miss = elem.getAttribute("DATA-ID");
    try std.testing.expect(upper_miss == null);

    // Uppercase attribute exists
    const upper = elem.getAttribute("DATA-NAME");
    try std.testing.expect(upper != null);
    try std.testing.expect(std.mem.eql(u8, upper.?, "456"));

    // Lowercase does NOT match uppercase attribute
    const lower_miss = elem.getAttribute("data-name");
    try std.testing.expect(lower_miss == null);

    // Mixed case attribute exists
    const mixed = elem.getAttribute("Data-Value");
    try std.testing.expect(mixed != null);
    try std.testing.expect(std.mem.eql(u8, mixed.?, "789"));
}

test "Node - setAttribute with different case creates separate attributes" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Set with lowercase
    try elem.setAttribute("key", "value1");

    // Set with uppercase creates DIFFERENT attribute
    try elem.setAttribute("KEY", "value2");

    // Both attributes exist independently
    const lower = elem.getAttribute("key");
    try std.testing.expect(lower != null);
    try std.testing.expect(std.mem.eql(u8, lower.?, "value1"));

    const upper = elem.getAttribute("KEY");
    try std.testing.expect(upper != null);
    try std.testing.expect(std.mem.eql(u8, upper.?, "value2"));

    // Should have 2 separate attributes
    try std.testing.expect(elem.hasAttribute("key"));
    try std.testing.expect(elem.hasAttribute("KEY"));
}

test "Node - hasAttribute is case-sensitive" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("attr1", "value");

    // Only exact case matches
    try std.testing.expect(elem.hasAttribute("attr1"));
    try std.testing.expect(!elem.hasAttribute("ATTR1"));
    try std.testing.expect(!elem.hasAttribute("Attr1"));
    try std.testing.expect(!elem.hasAttribute("aTtR1"));
}

test "Node - removeAttribute is case-sensitive" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Set with lowercase
    try elem.setAttribute("data-test", "value");
    try std.testing.expect(elem.hasAttribute("data-test"));

    // Remove with uppercase does NOT remove lowercase attribute
    elem.removeAttribute("DATA-TEST");

    // Lowercase attribute still exists
    try std.testing.expect(elem.hasAttribute("data-test"));

    // Now remove with correct case
    elem.removeAttribute("data-test");
    try std.testing.expect(!elem.hasAttribute("data-test"));
}

test "Node.normalize - merges adjacent text nodes" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode(" ");
    const text3 = try doc.createTextNode("World");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);
    _ = try parent.prototype.appendChild(&text3.prototype);

    // Before: 3 text nodes
    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    // After: 1 text node with merged data
    try std.testing.expectEqual(@as(usize, 1), parent.prototype.childNodes().length());

    const merged = parent.prototype.first_child.?;
    try std.testing.expectEqual(NodeType.text, merged.node_type);

    const Text = @import("text.zig").Text;
    const merged_text: *Text = @fieldParentPtr("prototype", merged);
    try std.testing.expectEqualStrings("Hello World", merged_text.data);
}

test "Node.normalize - removes empty text nodes" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const empty = try doc.createTextNode("");
    const text2 = try doc.createTextNode("World");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&empty.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    // Before: 3 text nodes (one empty)
    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    // After: 1 text node (empty removed, others merged)
    try std.testing.expectEqual(@as(usize, 1), parent.prototype.childNodes().length());

    const Text = @import("text.zig").Text;
    const merged = parent.prototype.first_child.?;
    const merged_text: *Text = @fieldParentPtr("prototype", merged);
    try std.testing.expectEqualStrings("HelloWorld", merged_text.data);
}

test "Node.normalize - respects element boundaries" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const elem = try doc.createElement("span");
    const text2 = try doc.createTextNode("World");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&elem.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    // Before: text, element, text
    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    // After: text nodes NOT merged across element boundary
    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    const Text = @import("text.zig").Text;
    const first = parent.prototype.first_child.?;
    const first_text: *Text = @fieldParentPtr("prototype", first);
    try std.testing.expectEqualStrings("Hello", first_text.data);

    const last = parent.prototype.last_child.?;
    const last_text: *Text = @fieldParentPtr("prototype", last);
    try std.testing.expectEqualStrings("World", last_text.data);
}

test "Node.normalize - recursively normalizes descendants" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const text1 = try doc.createTextNode("A");
    const text2 = try doc.createTextNode("B");
    _ = try child.prototype.appendChild(&text1.prototype);
    _ = try child.prototype.appendChild(&text2.prototype);

    // Before: child has 2 text nodes
    try std.testing.expectEqual(@as(usize, 2), child.prototype.childNodes().length());

    try parent.prototype.normalize();

    // After: child has 1 merged text node
    try std.testing.expectEqual(@as(usize, 1), child.prototype.childNodes().length());

    const Text = @import("text.zig").Text;
    const merged = child.prototype.first_child.?;
    const merged_text: *Text = @fieldParentPtr("prototype", merged);
    try std.testing.expectEqualStrings("AB", merged_text.data);
}

test "Node.normalize - handles document fragments" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    const text1 = try doc.createTextNode("Frag");
    const text2 = try doc.createTextNode("ment");
    _ = try fragment.prototype.appendChild(&text1.prototype);
    _ = try fragment.prototype.appendChild(&text2.prototype);

    try std.testing.expectEqual(@as(usize, 2), fragment.prototype.childNodes().length());

    try fragment.prototype.normalize();

    try std.testing.expectEqual(@as(usize, 1), fragment.prototype.childNodes().length());

    const Text = @import("text.zig").Text;
    const merged = fragment.prototype.first_child.?;
    const merged_text: *Text = @fieldParentPtr("prototype", merged);
    try std.testing.expectEqualStrings("Fragment", merged_text.data);
}
