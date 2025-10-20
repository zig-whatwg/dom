//! NodeIterator Interface (WHATWG DOM)
//!
//! This module implements the NodeIterator interface as specified by the WHATWG DOM Standard.
//! NodeIterator provides forward and backward iteration through a filtered view of the DOM tree
//! in document order.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **NodeIterator**: https://dom.spec.whatwg.org/#interface-nodeiterator
//! - **Traversal Algorithms**: https://dom.spec.whatwg.org/#concept-nodeiterator-traverse
//!
//! ## MDN Documentation
//!
//! - NodeIterator: https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator
//! - NodeIterator.nextNode(): https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/nextNode
//! - NodeIterator.previousNode(): https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/previousNode
//!
//! ## Core Features
//!
//! ### Iterating Through Nodes
//! ```zig
//! const iterator = try doc.createNodeIterator(
//!     root,
//!     NodeFilter.SHOW_ELEMENT,
//!     null // No custom filter
//! );
//! defer iterator.deinit();
//!
//! // Forward iteration
//! while (iterator.nextNode()) |node| {
//!     std.debug.print("Element: {s}\n", .{node.nodeName()});
//! }
//!
//! // Backward iteration
//! while (iterator.previousNode()) |node| {
//!     std.debug.print("Element: {s}\n", .{node.nodeName()});
//! }
//! ```
//!
//! ## Architecture
//!
//! NodeIterator maintains:
//! - Root node (traversal boundary)
//! - Reference node (current position)
//! - Pointer before reference node flag (position relative to reference)
//! - whatToShow bitfield (node type filter)
//! - Optional custom filter callback
//!
//! ## Spec Compliance
//!
//! This implementation follows WHATWG DOM §6.1 exactly:
//! - ✅ Depth-first pre-order traversal
//! - ✅ Reference node tracking
//! - ✅ Pointer before/after reference node
//! - ✅ whatToShow filtering
//! - ✅ Custom filter support
//! - ✅ detach() method (no-op per spec)
//!
//! ## JavaScript Bindings
//!
//! NodeIterator provides forward and backward iteration through a filtered DOM tree view.
//!
//! ### Creation
//! NodeIterator is typically created via `Document.createNodeIterator()`:
//! ```javascript
//! // Per WebIDL: NodeIterator createNodeIterator(Node root, optional unsigned long whatToShow = 0xFFFFFFFF, optional NodeFilter? filter = null);
//! const iterator = document.createNodeIterator(
//!   rootNode,
//!   NodeFilter.SHOW_ELEMENT,  // Optional: defaults to 0xFFFFFFFF (all nodes)
//!   null                       // Optional: custom filter function
//! );
//! ```
//!
//! ### Instance Properties (Readonly)
//! ```javascript
//! // Per WebIDL: [SameObject] readonly attribute Node root;
//! Object.defineProperty(NodeIterator.prototype, 'root', {
//!   get: function() { return wrapNode(zig.nodeiterator_get_root(this._ptr)); }
//! });
//!
//! // Per WebIDL: readonly attribute Node referenceNode;
//! Object.defineProperty(NodeIterator.prototype, 'referenceNode', {
//!   get: function() { return wrapNode(zig.nodeiterator_get_referenceNode(this._ptr)); }
//! });
//!
//! // Per WebIDL: readonly attribute boolean pointerBeforeReferenceNode;
//! Object.defineProperty(NodeIterator.prototype, 'pointerBeforeReferenceNode', {
//!   get: function() { return zig.nodeiterator_get_pointerBeforeReferenceNode(this._ptr); }
//! });
//!
//! // Per WebIDL: readonly attribute unsigned long whatToShow;
//! Object.defineProperty(NodeIterator.prototype, 'whatToShow', {
//!   get: function() { return zig.nodeiterator_get_whatToShow(this._ptr); }
//! });
//!
//! // Per WebIDL: readonly attribute NodeFilter? filter;
//! Object.defineProperty(NodeIterator.prototype, 'filter', {
//!   get: function() {
//!     const ptr = zig.nodeiterator_get_filter(this._ptr);
//!     return ptr ? wrapNodeFilter(ptr) : null;
//!   }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // Per WebIDL: Node? nextNode();
//! NodeIterator.prototype.nextNode = function() {
//!   const nodePtr = zig.nodeiterator_nextNode(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//!
//! // Per WebIDL: Node? previousNode();
//! NodeIterator.prototype.previousNode = function() {
//!   const nodePtr = zig.nodeiterator_previousNode(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//!
//! // Per WebIDL: undefined detach();
//! NodeIterator.prototype.detach = function() {
//!   zig.nodeiterator_detach(this._ptr); // No-op per spec, exists for historical reasons
//! };
//! ```
//!
//! ### Usage Examples
//! ```javascript
//! // Create iterator for all element nodes
//! const root = document.createElement('container');
//! const child1 = document.createElement('item');
//! const child2 = document.createElement('item');
//! root.appendChild(child1);
//! root.appendChild(child2);
//!
//! const iterator = document.createNodeIterator(
//!   root,
//!   NodeFilter.SHOW_ELEMENT
//! );
//!
//! // Forward iteration
//! let node;
//! while (node = iterator.nextNode()) {
//!   console.log('Found:', node.nodeName);
//!   console.log('Reference:', iterator.referenceNode === node); // true
//! }
//!
//! // Backward iteration
//! while (node = iterator.previousNode()) {
//!   console.log('Found:', node.nodeName);
//! }
//!
//! // Iterator state
//! console.log('Root:', iterator.root);
//! console.log('Current reference:', iterator.referenceNode);
//! console.log('Pointer before reference:', iterator.pointerBeforeReferenceNode);
//! console.log('What to show:', iterator.whatToShow);
//!
//! // Custom filter
//! const filtered = document.createNodeIterator(
//!   root,
//!   NodeFilter.SHOW_ELEMENT,
//!   {
//!     acceptNode: function(node) {
//!       return node.nodeName === 'ITEM' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
//!     }
//!   }
//! );
//!
//! // Iterate only 'item' elements
//! while (node = filtered.nextNode()) {
//!   console.log('Filtered node:', node.nodeName); // Only 'ITEM' elements
//! }
//!
//! // detach() is a no-op (historical API)
//! iterator.detach(); // Does nothing, modern code shouldn't call this
//! ```
//!
//! ### NodeFilter Constants
//! ```javascript
//! // whatToShow bitfield values
//! NodeFilter.SHOW_ALL = 0xFFFFFFFF;
//! NodeFilter.SHOW_ELEMENT = 0x1;
//! NodeFilter.SHOW_ATTRIBUTE = 0x2;
//! NodeFilter.SHOW_TEXT = 0x4;
//! NodeFilter.SHOW_CDATA_SECTION = 0x8;
//! NodeFilter.SHOW_PROCESSING_INSTRUCTION = 0x40;
//! NodeFilter.SHOW_COMMENT = 0x80;
//! NodeFilter.SHOW_DOCUMENT = 0x100;
//! NodeFilter.SHOW_DOCUMENT_TYPE = 0x200;
//! NodeFilter.SHOW_DOCUMENT_FRAGMENT = 0x400;
//!
//! // Filter return values
//! NodeFilter.FILTER_ACCEPT = 1;
//! NodeFilter.FILTER_REJECT = 2;  // Skip node and descendants (TreeWalker only)
//! NodeFilter.FILTER_SKIP = 3;    // Skip node but not descendants
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeFilter = @import("node_filter.zig").NodeFilter;
const FilterResult = @import("node_filter.zig").FilterResult;

/// NodeIterator - Forward/backward iteration through filtered DOM tree.
///
/// Implements WHATWG DOM NodeIterator per DOM spec.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=Window]
/// interface NodeIterator {
///   [SameObject] readonly attribute Node root;
///   readonly attribute Node referenceNode;
///   readonly attribute boolean pointerBeforeReferenceNode;
///   readonly attribute unsigned long whatToShow;
///   readonly attribute NodeFilter? filter;
///
///   Node? nextNode();
///   Node? previousNode();
///
///   undefined detach();
/// };
/// ```
///
/// ## Spec References
/// - Interface: https://dom.spec.whatwg.org/#interface-nodeiterator
/// - WebIDL: dom.idl:535-546
pub const NodeIterator = struct {
    /// Allocator for iterator cleanup
    allocator: Allocator,

    /// Root node of traversal (boundary)
    root: *Node,

    /// Current reference node
    reference_node: *Node,

    /// True if pointer is before reference node, false if after
    pointer_before_reference_node: bool,

    /// Bitfield of node types to show
    what_to_show: u32,

    /// Optional custom filter
    node_filter: ?NodeFilter,

    /// Creates a new NodeIterator.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `root`: Root node of traversal
    /// - `what_to_show`: Bitfield of node types to show
    /// - `node_filter`: Optional custom filter
    ///
    /// ## Returns
    /// New NodeIterator positioned before root
    ///
    /// ## Example
    /// ```zig
    /// const iterator = try NodeIterator.init(
    ///     allocator,
    ///     root,
    ///     NodeFilter.SHOW_ELEMENT,
    ///     null
    /// );
    /// defer iterator.deinit();
    /// ```
    pub fn init(
        allocator: Allocator,
        root: *Node,
        what_to_show: u32,
        node_filter: ?NodeFilter,
    ) !*NodeIterator {
        const iterator = try allocator.create(NodeIterator);
        iterator.* = .{
            .allocator = allocator,
            .root = root,
            .reference_node = root,
            .pointer_before_reference_node = true,
            .what_to_show = what_to_show,
            .node_filter = node_filter,
        };
        return iterator;
    }

    /// Frees the iterator.
    pub fn deinit(self: *NodeIterator) void {
        self.allocator.destroy(self);
    }

    /// Returns the next node in document order, or null if exhausted.
    ///
    /// ## WebIDL
    /// ```webidl
    /// Node? nextNode();
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §6.1)
    /// 1. Let node be reference node
    /// 2. Let before be pointer before reference node
    /// 3. While true:
    ///    a. If before is false, let node be first node following node in tree order (that is not an ancestor of root)
    ///    b. If node is null, return null
    ///    c. If node is a descendant of root:
    ///       i. Set before to false
    ///       ii. If node matches filter, set reference node to node and return it
    ///    d. Otherwise return null
    ///
    /// ## Returns
    /// Next matching node, or null if no more nodes
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-nodeiterator-nextnode
    /// - WebIDL: dom.idl:542
    pub fn nextNode(self: *NodeIterator) ?*Node {
        var node = self.reference_node;
        var before_node = self.pointer_before_reference_node;

        while (true) {
            // Step 3a: If not before node, advance to next node in tree order
            if (!before_node) {
                node = traverseFollowing(node, self.root) orelse {
                    return null;
                };
            }

            // Step 3b: Check if node is within root's subtree
            if (!isDescendantOf(node, self.root) and node != self.root) {
                return null;
            }

            // Step 3c: Set before to false
            before_node = false;

            // Step 3c.ii: Filter the node
            const result = filterNode(self, node);
            if (result == .accept) {
                self.reference_node = node;
                self.pointer_before_reference_node = false;
                return node;
            }
            // Continue to next node
        }
    }

    /// Returns the previous node in document order, or null if exhausted.
    ///
    /// ## WebIDL
    /// ```webidl
    /// Node? previousNode();
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §6.1)
    /// Similar to nextNode but traverses in reverse document order.
    ///
    /// ## Returns
    /// Previous matching node, or null if no more nodes
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-nodeiterator-previousnode
    /// - WebIDL: dom.idl:543
    pub fn previousNode(self: *NodeIterator) ?*Node {
        var node = self.reference_node;
        var before_node = self.pointer_before_reference_node;

        while (true) {
            // If before node, advance to previous node in tree order
            if (before_node) {
                node = traversePreceding(node, self.root) orelse {
                    return null;
                };
            }

            // Check if node is within root's subtree
            if (!isDescendantOf(node, self.root) and node != self.root) {
                return null;
            }

            // Set before to true
            before_node = true;

            // Filter the node
            const result = filterNode(self, node);
            if (result == .accept) {
                self.reference_node = node;
                self.pointer_before_reference_node = true;
                return node;
            }
            // Continue to previous node
        }
    }

    /// Detaches the iterator (no-op per spec).
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined detach();
    /// ```
    ///
    /// ## Note
    /// This method exists for historical reasons and does nothing.
    /// Modern code should not call it.
    ///
    /// ## Spec References
    /// - Method: https://dom.spec.whatwg.org/#dom-nodeiterator-detach
    /// - WebIDL: dom.idl:545
    pub fn detach(self: *NodeIterator) void {
        _ = self;
        // No-op per spec
    }

    // ========================================================================
    // Helper Functions
    // ========================================================================

    /// Filters a node based on whatToShow and custom filter.
    fn filterNode(self: *const NodeIterator, node: *Node) FilterResult {
        // Check whatToShow bitfield
        if (!NodeFilter.isNodeVisible(node, self.what_to_show)) {
            return .skip;
        }

        // Apply custom filter if present
        if (self.node_filter) |filter| {
            return filter.acceptNode(node);
        }

        return .accept;
    }

    /// Returns the next node in document order (depth-first pre-order).
    fn traverseFollowing(node: *Node, root: *const Node) ?*Node {
        // If node has children, return first child
        if (node.first_child) |child| {
            return child;
        }

        // Otherwise, go to next sibling or ancestor's next sibling
        var current: *Node = node;
        while (current != root) {
            if (current.next_sibling) |sibling| {
                return sibling;
            }
            // Go to parent
            current = current.parent_node orelse break;
        }

        return null;
    }

    /// Returns the previous node in document order (reverse depth-first pre-order).
    fn traversePreceding(node: *Node, root: *const Node) ?*Node {
        // If node is root, no previous node
        if (node == root) {
            return null;
        }

        // If node has previous sibling, return its last descendant
        if (node.previous_sibling) |sibling| {
            return lastDescendant(sibling);
        }

        // Otherwise, return parent
        return node.parent_node;
    }

    /// Returns the last descendant of a node (deepest rightmost node).
    fn lastDescendant(node: *Node) *Node {
        var current = node;
        while (current.last_child) |child| {
            current = child;
        }
        return current;
    }

    /// Checks if node is a descendant of ancestor (or equal).
    fn isDescendantOf(node: *const Node, ancestor: *const Node) bool {
        if (node == ancestor) return true;

        var current = node.parent_node;
        while (current) |parent| {
            if (parent == ancestor) return true;
            current = parent.parent_node;
        }
        return false;
    }
};
