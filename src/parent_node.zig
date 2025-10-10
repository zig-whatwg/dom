//! ParentNode Mixin (§4.2.6)
//!
//! This module implements the ParentNode mixin interface as specified by the WHATWG DOM Standard.
//! The ParentNode mixin provides convenient methods for manipulating children of a parent node.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#interface-parentnode
//! - **§4.2.3 Mutation algorithms**: https://dom.spec.whatwg.org/#mutation-algorithms
//!
//! ## MDN Documentation
//!
//! - ParentNode: https://developer.mozilla.org/en-US/docs/Web/API/ParentNode
//! - prepend(): https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend
//! - append(): https://developer.mozilla.org/en-US/docs/Web/API/Element/append
//! - replaceChildren(): https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceChildren
//!
//! ## Core Features
//!
//! ### Prepend Children
//! Insert one or more nodes at the beginning of children:
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! const child1 = try Element.create(allocator, "p");
//! const child2 = try Element.create(allocator, "span");
//! try ParentNode.prepend(parent, &[_]*Node{ child1, child2 });
//! // Result: parent → [child1, child2, ...existing children]
//! ```
//!
//! ### Append Children
//! Insert one or more nodes at the end of children:
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! const child = try Element.create(allocator, "p");
//! try ParentNode.append(parent, &[_]*Node{ child });
//! // Result: parent → [...existing children, child]
//! ```
//!
//! ### Replace All Children
//! Replace all children with new nodes:
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! const new1 = try Element.create(allocator, "p");
//! const new2 = try Element.create(allocator, "span");
//! try ParentNode.replaceChildren(parent, &[_]*Node{ new1, new2 });
//! // Result: all old children removed, parent → [new1, new2]
//! ```
//!
//! ### Move Child Before Reference
//! Move an existing child to a new position without removing from tree:
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! const child1 = try Element.create(allocator, "p");
//! const child2 = try Element.create(allocator, "span");
//! _ = try parent.appendChild(child1);
//! _ = try parent.appendChild(child2);
//! try ParentNode.moveBefore(parent, child2, child1);
//! // Result: parent → [child2, child1] (reordered without remove)
//! ```
//!
//! ## String Arguments
//!
//! Per the WHATWG spec, string arguments are converted to Text nodes. However,
//! this Zig implementation accepts only Node pointers for type safety. Users
//! should create Text nodes explicitly if needed:
//!
//! ```zig
//! const text = try Text.create(allocator, "Hello World");
//! try ParentNode.prepend(parent, &[_]*Node{ text });
//! ```
//!
//! ## Memory Management
//!
//! All methods use reference counting through the Node interface:
//! - Nodes are retained when added to a parent
//! - Nodes are released when removed from a parent
//! - Callers are responsible for initial reference management
//!
//! ## Specification Compliance
//!
//! This implementation follows WHATWG DOM Standard §4.2.6 ParentNode mixin.
//! The methods are designed to match browser behavior for DOM manipulation.

const std = @import("std");
const Node = @import("node.zig").Node;

/// ParentNode mixin provides methods for manipulating a parent's children.
///
/// ## Overview
///
/// The ParentNode mixin is implemented by Document, DocumentFragment, and Element
/// nodes. It provides convenient methods for adding, removing, and replacing
/// children in bulk operations.
///
/// ## Methods
///
/// - `prepend()` - Insert nodes at start of children
/// - `append()` - Insert nodes at end of children
/// - `replaceChildren()` - Replace all children with new nodes
/// - `moveBefore()` - Move child to new position without removing
///
/// ## Specification Reference
///
/// * WHATWG DOM Standard §4.2.6: https://dom.spec.whatwg.org/#interface-parentnode
pub const ParentNode = struct {
    /// Inserts nodes at the beginning of this node's children.
    ///
    /// ## Overview
    ///
    /// Inserts zero or more nodes before the first child of this node. This is
    /// equivalent to calling insertBefore() with the first child as the reference.
    ///
    /// ## Parameters
    ///
    /// - `self` - The parent node to prepend children to
    /// - `nodes` - Array of nodes to prepend (can be empty)
    ///
    /// ## Returns
    ///
    /// - `void` on success
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// const existing = try Element.create(allocator, "p");
    /// const new1 = try Element.create(allocator, "span");
    /// const new2 = try Element.create(allocator, "b");
    ///
    /// _ = try parent.appendChild(existing);
    /// try ParentNode.prepend(parent, &[_]*Node{ new1, new2 });
    /// // Parent's children: [new1, new2, existing]
    /// ```
    ///
    /// ## Specification
    ///
    /// WHATWG DOM Standard §4.2.6: https://dom.spec.whatwg.org/#dom-parentnode-prepend
    ///
    /// ## Notes
    ///
    /// - Nodes are inserted in the order provided
    /// - If a node is already in a tree, it is first removed from its old parent
    /// - Empty nodes array is valid (no-op)
    /// - If parent has no children, this is equivalent to append()
    pub fn prepend(self: *Node, nodes: []const *Node) !void {
        // Get first child as reference point
        const first_child = self.firstChild();

        // Insert each node before first child (or append if no children)
        for (nodes) |node| {
            _ = try self.insertBefore(node, first_child);
        }
    }

    /// Inserts nodes at the end of this node's children.
    ///
    /// ## Overview
    ///
    /// Inserts zero or more nodes after the last child of this node. This is
    /// equivalent to calling appendChild() for each node.
    ///
    /// ## Parameters
    ///
    /// - `self` - The parent node to append children to
    /// - `nodes` - Array of nodes to append (can be empty)
    ///
    /// ## Returns
    ///
    /// - `void` on success
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// const existing = try Element.create(allocator, "p");
    /// const new1 = try Element.create(allocator, "span");
    /// const new2 = try Element.create(allocator, "b");
    ///
    /// _ = try parent.appendChild(existing);
    /// try ParentNode.append(parent, &[_]*Node{ new1, new2 });
    /// // Parent's children: [existing, new1, new2]
    /// ```
    ///
    /// ## Specification
    ///
    /// WHATWG DOM Standard §4.2.6: https://dom.spec.whatwg.org/#dom-parentnode-append
    ///
    /// ## Notes
    ///
    /// - Nodes are appended in the order provided
    /// - If a node is already in a tree, it is first removed from its old parent
    /// - Empty nodes array is valid (no-op)
    pub fn append(self: *Node, nodes: []const *Node) !void {
        // Append each node to the end
        for (nodes) |node| {
            _ = try self.appendChild(node);
        }
    }

    /// Replaces all children of this node with new nodes.
    ///
    /// ## Overview
    ///
    /// Removes all existing children and inserts the provided nodes in their place.
    /// This is an atomic operation - all children are removed before new nodes are added.
    ///
    /// ## Parameters
    ///
    /// - `self` - The parent node whose children to replace
    /// - `nodes` - Array of nodes to insert (can be empty)
    ///
    /// ## Returns
    ///
    /// - `void` on success
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// const old1 = try Element.create(allocator, "p");
    /// const old2 = try Element.create(allocator, "span");
    /// const new1 = try Element.create(allocator, "h1");
    /// const new2 = try Element.create(allocator, "h2");
    ///
    /// _ = try parent.appendChild(old1);
    /// _ = try parent.appendChild(old2);
    ///
    /// try ParentNode.replaceChildren(parent, &[_]*Node{ new1, new2 });
    /// // Parent's children: [new1, new2] (old1, old2 removed)
    /// ```
    ///
    /// ## Specification
    ///
    /// WHATWG DOM Standard §4.2.6: https://dom.spec.whatwg.org/#dom-parentnode-replacechildren
    ///
    /// ## Notes
    ///
    /// - All existing children are removed first
    /// - New nodes are added in the order provided
    /// - Empty nodes array clears all children
    /// - If a new node is already in a tree, it is first removed from its old parent
    pub fn replaceChildren(self: *Node, nodes: []const *Node) !void {
        // Remove all existing children
        while (self.firstChild()) |child| {
            _ = try self.removeChild(child);
        }

        // Append all new nodes
        for (nodes) |node| {
            _ = try self.appendChild(node);
        }
    }

    /// Moves a child node before a reference node without removing it from the tree.
    ///
    /// ## Overview
    ///
    /// Moves an existing child to a new position within the same parent, or to a
    /// new parent, without first removing it. This preserves the node's state and
    /// is more efficient than remove + insert.
    ///
    /// ## Parameters
    ///
    /// - `self` - The parent node
    /// - `node` - The child node to move
    /// - `child` - The reference child to move before (null for end)
    ///
    /// ## Returns
    ///
    /// - `void` on success
    /// - `error.HierarchyRequestError` if constraints are violated
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// const child1 = try Element.create(allocator, "p");
    /// const child2 = try Element.create(allocator, "span");
    /// const child3 = try Element.create(allocator, "b");
    ///
    /// _ = try parent.appendChild(child1);
    /// _ = try parent.appendChild(child2);
    /// _ = try parent.appendChild(child3);
    ///
    /// // Move child3 before child1
    /// try ParentNode.moveBefore(parent, child3, child1);
    /// // Parent's children: [child3, child1, child2]
    /// ```
    ///
    /// ## Specification
    ///
    /// WHATWG DOM Standard §4.2.6: https://dom.spec.whatwg.org/#dom-parentnode-movebefore
    ///
    /// ## Notes
    ///
    /// - If child is null, moves node to the end
    /// - If node is already before child, this is a no-op
    /// - Node must be a child of self or another parent
    /// - More efficient than removeChild + insertBefore
    /// - Preserves node state (no remove/add cycle)
    ///
    /// ## Errors
    ///
    /// - `HierarchyRequestError` if node is self or an ancestor of self
    /// - `NotFoundError` if child is not null and not a child of self
    pub fn moveBefore(self: *Node, node: *Node, child: ?*Node) !void {
        // Validate: node cannot be self or an ancestor
        if (node == self) {
            return error.HierarchyRequestError;
        }

        // Check if node is ancestor of self
        var ancestor: ?*Node = self.parent_node;
        while (ancestor) |anc| {
            if (anc == node) {
                return error.HierarchyRequestError;
            }
            ancestor = anc.parent_node;
        }

        // If child is non-null, verify it's a child of self
        if (child) |c| {
            var found = false;
            for (self.child_nodes.items.items) |child_ptr| {
                const ch: *Node = @ptrCast(@alignCast(child_ptr));
                if (ch == c) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return error.NotFoundError;
            }
        }

        // If node is already in correct position, no-op
        if (child) |c| {
            if (node.nextSibling() == c) {
                return; // Already before child
            }
        } else {
            // child is null, check if node is already last
            if (self.lastChild() == node) {
                return; // Already at end
            }
        }

        // Remove node from its current parent (if any)
        if (node.parent_node) |old_parent| {
            // Remove from old parent's child list without releasing
            for (old_parent.child_nodes.items.items, 0..) |child_ptr, i| {
                const ch: *Node = @ptrCast(@alignCast(child_ptr));
                if (ch == node) {
                    node.parent_node = null;
                    old_parent.child_nodes.remove(i);
                    // Don't release - we're moving, not removing
                    break;
                }
            }
        }

        // Insert node before child in self
        node.parent_node = self;
        if (child) |c| {
            // Find child's index
            for (self.child_nodes.items.items, 0..) |child_ptr, i| {
                const ch: *Node = @ptrCast(@alignCast(child_ptr));
                if (ch == c) {
                    try self.child_nodes.items.insert(self.allocator, i, node);
                    return;
                }
            }
        } else {
            // Append to end
            try self.child_nodes.append(node);
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

const testing = std.testing;
const Element = @import("element.zig").Element;

test "ParentNode.prepend with single node" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const existing = try Element.create(allocator, "p");
    const new = try Element.create(allocator, "span");

    _ = try parent.appendChild(existing);

    try ParentNode.prepend(parent, &[_]*Node{new});

    // Verify order: new, existing
    try testing.expectEqual(@as(usize, 2), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));

    try testing.expectEqual(new, first);
    try testing.expectEqual(existing, second);
}

test "ParentNode.prepend with multiple nodes" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const existing = try Element.create(allocator, "p");
    const new1 = try Element.create(allocator, "span");
    const new2 = try Element.create(allocator, "b");

    _ = try parent.appendChild(existing);

    try ParentNode.prepend(parent, &[_]*Node{ new1, new2 });

    // Verify order: new1, new2, existing
    try testing.expectEqual(@as(usize, 3), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));

    try testing.expectEqual(new1, first);
    try testing.expectEqual(new2, second);
    try testing.expectEqual(existing, third);
}

test "ParentNode.prepend to empty parent" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "p");

    try ParentNode.prepend(parent, &[_]*Node{child});

    // Verify child was added
    try testing.expectEqual(@as(usize, 1), parent.child_nodes.items.items.len);
    try testing.expectEqual(child, parent.firstChild());
}

test "ParentNode.append with single node" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const existing = try Element.create(allocator, "p");
    const new = try Element.create(allocator, "span");

    _ = try parent.appendChild(existing);

    try ParentNode.append(parent, &[_]*Node{new});

    // Verify order: existing, new
    try testing.expectEqual(@as(usize, 2), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));

    try testing.expectEqual(existing, first);
    try testing.expectEqual(new, second);
}

test "ParentNode.append with multiple nodes" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const existing = try Element.create(allocator, "p");
    const new1 = try Element.create(allocator, "span");
    const new2 = try Element.create(allocator, "b");

    _ = try parent.appendChild(existing);

    try ParentNode.append(parent, &[_]*Node{ new1, new2 });

    // Verify order: existing, new1, new2
    try testing.expectEqual(@as(usize, 3), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));

    try testing.expectEqual(existing, first);
    try testing.expectEqual(new1, second);
    try testing.expectEqual(new2, third);
}

test "ParentNode.replaceChildren with new nodes" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const old1 = try Element.create(allocator, "p");
    const old2 = try Element.create(allocator, "span");
    const new1 = try Element.create(allocator, "h1");
    const new2 = try Element.create(allocator, "h2");

    _ = try parent.appendChild(old1);
    _ = try parent.appendChild(old2);

    try ParentNode.replaceChildren(parent, &[_]*Node{ new1, new2 });

    // Verify: only new nodes remain
    try testing.expectEqual(@as(usize, 2), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));

    try testing.expectEqual(new1, first);
    try testing.expectEqual(new2, second);

    // Verify old nodes were removed
    try testing.expect(old1.parent_node == null);
    try testing.expect(old2.parent_node == null);
}

test "ParentNode.replaceChildren with empty array clears all" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "p");
    const child2 = try Element.create(allocator, "span");

    _ = try parent.appendChild(child1);
    _ = try parent.appendChild(child2);

    try ParentNode.replaceChildren(parent, &[_]*Node{});

    // Verify: all children removed
    try testing.expectEqual(@as(usize, 0), parent.child_nodes.items.items.len);
    try testing.expect(child1.parent_node == null);
    try testing.expect(child2.parent_node == null);
}

test "ParentNode.moveBefore within same parent" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "p");
    const child2 = try Element.create(allocator, "span");
    const child3 = try Element.create(allocator, "b");

    _ = try parent.appendChild(child1);
    _ = try parent.appendChild(child2);
    _ = try parent.appendChild(child3);

    // Move child3 before child1
    try ParentNode.moveBefore(parent, child3, child1);

    // Verify order: child3, child1, child2
    try testing.expectEqual(@as(usize, 3), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));

    try testing.expectEqual(child3, first);
    try testing.expectEqual(child1, second);
    try testing.expectEqual(child2, third);
}

test "ParentNode.moveBefore to end with null child" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "p");
    const child2 = try Element.create(allocator, "span");
    const child3 = try Element.create(allocator, "b");

    _ = try parent.appendChild(child1);
    _ = try parent.appendChild(child2);
    _ = try parent.appendChild(child3);

    // Move child1 to end
    try ParentNode.moveBefore(parent, child1, null);

    // Verify order: child2, child3, child1
    try testing.expectEqual(@as(usize, 3), parent.child_nodes.items.items.len);

    const last: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));
    try testing.expectEqual(child1, last);
}

test "ParentNode.moveBefore from different parent" {
    const allocator = testing.allocator;

    const parent1 = try Element.create(allocator, "div");
    defer parent1.release();

    const parent2 = try Element.create(allocator, "section");
    defer parent2.release();

    const child1 = try Element.create(allocator, "p");
    const child2 = try Element.create(allocator, "span");
    const moving = try Element.create(allocator, "b");

    _ = try parent1.appendChild(moving);
    _ = try parent2.appendChild(child1);
    _ = try parent2.appendChild(child2);

    // Move from parent1 to parent2 before child2
    try ParentNode.moveBefore(parent2, moving, child2);

    // Verify moving is in parent2, not parent1
    try testing.expectEqual(@as(usize, 0), parent1.child_nodes.items.items.len);
    try testing.expectEqual(@as(usize, 3), parent2.child_nodes.items.items.len);

    const second: *Node = @ptrCast(@alignCast(parent2.child_nodes.items.items[1]));
    try testing.expectEqual(moving, second);
}

test "ParentNode.moveBefore node cannot be self" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const result = ParentNode.moveBefore(parent, parent, null);
    try testing.expectError(error.HierarchyRequestError, result);
}

test "ParentNode.moveBefore node cannot be ancestor" {
    const allocator = testing.allocator;

    const grandparent = try Element.create(allocator, "div");
    defer grandparent.release();

    const parent = try Element.create(allocator, "section");
    const child = try Element.create(allocator, "p");

    _ = try grandparent.appendChild(parent);
    _ = try parent.appendChild(child);

    // Try to move parent into its own child
    const result = ParentNode.moveBefore(child, parent, null);
    try testing.expectError(error.HierarchyRequestError, result);
}
