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
