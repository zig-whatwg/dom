//! ChildNode Mixin (§4.2.8)
//!
//! This module implements the ChildNode mixin interface as specified by the WHATWG DOM Standard.
//! The ChildNode mixin provides convenient methods for manipulating nodes within their parent.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.2.8 Mixin ChildNode**: https://dom.spec.whatwg.org/#interface-childnode
//! - **§4.2.3 Mutation algorithms**: https://dom.spec.whatwg.org/#mutation-algorithms
//!
//! ## MDN Documentation
//!
//! - ChildNode: https://developer.mozilla.org/en-US/docs/Web/API/ChildNode
//! - before(): https://developer.mozilla.org/en-US/docs/Web/API/Element/before
//! - after(): https://developer.mozilla.org/en-US/docs/Web/API/Element/after
//! - replaceWith(): https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith
//! - remove(): https://developer.mozilla.org/en-US/docs/Web/API/Element/remove
//!
//! ## Core Features
//!
//! ### Insert Nodes Before Element
//! Insert one or more nodes before this element:
//! ```zig
//! const div = try Element.create(allocator, "div");
//! const p1 = try Element.create(allocator, "p");
//! const p2 = try Element.create(allocator, "p");
//! try ChildNode.before(div, &[_]*Node{ p1.asNode(), p2.asNode() });
//! // Result: p1, p2, div (in parent's children)
//! ```
//!
//! ### Insert Nodes After Element
//! Insert one or more nodes after this element:
//! ```zig
//! const div = try Element.create(allocator, "div");
//! const span = try Element.create(allocator, "span");
//! try ChildNode.after(div, &[_]*Node{ span.asNode() });
//! // Result: div, span (in parent's children)
//! ```
//!
//! ### Replace Element With Nodes
//! Replace this element with one or more nodes:
//! ```zig
//! const old = try Element.create(allocator, "div");
//! const new1 = try Element.create(allocator, "p");
//! const new2 = try Element.create(allocator, "span");
//! try ChildNode.replaceWith(old, &[_]*Node{ new1.asNode(), new2.asNode() });
//! // Result: old is removed, new1 and new2 are inserted in its place
//! ```
//!
//! ### Remove Element From Parent
//! Remove this element from its parent:
//! ```zig
//! const child = try Element.create(allocator, "div");
//! _ = try parent.appendChild(child.asNode());
//! try ChildNode.remove(child.asNode());
//! // Result: child is removed from parent
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
//! try ChildNode.before(element, &[_]*Node{ text.asNode() });
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
//! This implementation follows WHATWG DOM Standard §4.2.8 ChildNode mixin.
//! The methods are designed to match browser behavior for DOM manipulation.

const std = @import("std");
const Node = @import("node.zig").Node;

/// ChildNode mixin provides methods for manipulating nodes within their parent.
///
/// ## Overview
///
/// The ChildNode mixin is implemented by Element, CharacterData, and DocumentType
/// nodes. It provides convenient jQuery-style methods for DOM manipulation that
/// are more ergonomic than the traditional Node interface methods.
///
/// ## Methods
///
/// - `before()` - Insert nodes before this node
/// - `after()` - Insert nodes after this node
/// - `replaceWith()` - Replace this node with other nodes
/// - `remove()` - Remove this node from its parent
///
/// ## Specification Reference
///
/// * WHATWG DOM Standard §4.2.8: https://dom.spec.whatwg.org/#interface-childnode
pub const ChildNode = struct {
    /// Inserts nodes before this node in the parent's children list.
    ///
    /// ## Overview
    ///
    /// Inserts zero or more nodes immediately before this node in its parent's
    /// child list. This is equivalent to calling parent.insertBefore() for each
    /// node in the provided array.
    ///
    /// ## Parameters
    ///
    /// - `self` - The node before which to insert the new nodes
    /// - `nodes` - Array of nodes to insert (can be empty)
    ///
    /// ## Returns
    ///
    /// - `void` on success
    /// - `error.HierarchyRequestError` if this node has no parent
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// const ref = try Element.create(allocator, "p");
    /// const new1 = try Element.create(allocator, "span");
    /// const new2 = try Element.create(allocator, "b");
    ///
    /// _ = try parent.appendChild(ref.asNode());
    /// try ChildNode.before(ref.asNode(), &[_]*Node{ new1.asNode(), new2.asNode() });
    /// // Parent's children: [new1, new2, ref]
    /// ```
    ///
    /// ## Specification
    ///
    /// WHATWG DOM Standard §4.2.8: https://dom.spec.whatwg.org/#dom-childnode-before
    ///
    /// ## Notes
    ///
    /// - If this node has no parent, throws HierarchyRequestError
    /// - Nodes are inserted in the order provided
    /// - If a node is already in a tree, it is first removed from its old parent
    /// - Empty nodes array is valid (no-op)
    pub fn before(self: *Node, nodes: []const *Node) !void {
        const parent = self.parent_node orelse return error.HierarchyRequestError;

        // Insert each node before self
        for (nodes) |node| {
            _ = try parent.insertBefore(node, self);
        }
    }

    /// Inserts nodes after this node in the parent's children list.
    ///
    /// ## Overview
    ///
    /// Inserts zero or more nodes immediately after this node in its parent's
    /// child list. This is equivalent to calling parent.insertBefore() with
    /// this node's next sibling as the reference.
    ///
    /// ## Parameters
    ///
    /// - `self` - The node after which to insert the new nodes
    /// - `nodes` - Array of nodes to insert (can be empty)
    ///
    /// ## Returns
    ///
    /// - `void` on success
    /// - `error.HierarchyRequestError` if this node has no parent
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// const ref = try Element.create(allocator, "p");
    /// const new1 = try Element.create(allocator, "span");
    /// const new2 = try Element.create(allocator, "b");
    ///
    /// _ = try parent.appendChild(ref.asNode());
    /// try ChildNode.after(ref.asNode(), &[_]*Node{ new1.asNode(), new2.asNode() });
    /// // Parent's children: [ref, new1, new2]
    /// ```
    ///
    /// ## Specification
    ///
    /// WHATWG DOM Standard §4.2.8: https://dom.spec.whatwg.org/#dom-childnode-after
    ///
    /// ## Notes
    ///
    /// - If this node has no parent, throws HierarchyRequestError
    /// - Nodes are inserted in the order provided
    /// - If a node is already in a tree, it is first removed from its old parent
    /// - Empty nodes array is valid (no-op)
    /// - If this is the last child, nodes are appended to the end
    pub fn after(self: *Node, nodes: []const *Node) !void {
        const parent = self.parent_node orelse return error.HierarchyRequestError;

        // Find the next sibling - will be null if self is last child
        const next_sibling = self.nextSibling();

        // Insert each node before next_sibling (or at end if null)
        for (nodes) |node| {
            _ = try parent.insertBefore(node, next_sibling);
        }
    }

    /// Replaces this node with zero or more nodes.
    ///
    /// ## Overview
    ///
    /// Removes this node from its parent and inserts the provided nodes in its
    /// place. This is a common pattern when updating DOM structure.
    ///
    /// ## Parameters
    ///
    /// - `self` - The node to replace
    /// - `nodes` - Array of nodes to insert in place of this node (can be empty)
    ///
    /// ## Returns
    ///
    /// - `void` on success
    /// - `error.HierarchyRequestError` if this node has no parent
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// const old = try Element.create(allocator, "p");
    /// const new1 = try Element.create(allocator, "span");
    /// const new2 = try Element.create(allocator, "b");
    ///
    /// _ = try parent.appendChild(old.asNode());
    /// try ChildNode.replaceWith(old.asNode(), &[_]*Node{ new1.asNode(), new2.asNode() });
    /// // Parent's children: [new1, new2] (old is removed)
    /// ```
    ///
    /// ## Specification
    ///
    /// WHATWG DOM Standard §4.2.8: https://dom.spec.whatwg.org/#dom-childnode-replacewith
    ///
    /// ## Notes
    ///
    /// - If this node has no parent, throws HierarchyRequestError
    /// - Nodes are inserted in the order provided
    /// - If nodes array is empty, this node is simply removed (no replacement)
    /// - This node is removed from parent after new nodes are inserted
    /// - If a replacement node is already in a tree, it is first removed from its old parent
    pub fn replaceWith(self: *Node, nodes: []const *Node) !void {
        const parent = self.parent_node orelse return error.HierarchyRequestError;

        // Insert all new nodes before self
        for (nodes) |node| {
            _ = try parent.insertBefore(node, self);
        }

        // Now remove self
        _ = try parent.removeChild(self);
    }

    /// Removes this node from its parent.
    ///
    /// ## Overview
    ///
    /// Removes this node from its parent's child list. This is more convenient
    /// than calling parent.removeChild() directly.
    ///
    /// ## Parameters
    ///
    /// - `self` - The node to remove
    ///
    /// ## Returns
    ///
    /// - `void` on success
    /// - Does nothing if this node has no parent (no error)
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// const child = try Element.create(allocator, "p");
    ///
    /// _ = try parent.appendChild(child.asNode());
    /// try ChildNode.remove(child.asNode());
    /// // child is removed from parent
    ///
    /// // Safe to call multiple times
    /// try ChildNode.remove(child.asNode()); // No-op, no error
    /// ```
    ///
    /// ## Specification
    ///
    /// WHATWG DOM Standard §4.2.8: https://dom.spec.whatwg.org/#dom-childnode-remove
    ///
    /// ## Notes
    ///
    /// - If this node has no parent, this is a no-op (does not throw error)
    /// - After removal, this node's parent_node will be null
    /// - The node remains valid and can be inserted elsewhere
    /// - Reference count is decremented when removed
    pub fn remove(self: *Node) !void {
        const parent = self.parent_node orelse return; // No-op if no parent

        _ = try parent.removeChild(self);
    }
};

// ============================================================================
// Tests
// ============================================================================

const testing = std.testing;
const Element = @import("element.zig").Element;

test "ChildNode.before with single node" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const ref = try Element.create(allocator, "p");
    const new = try Element.create(allocator, "span");

    _ = try parent.appendChild(ref);

    try ChildNode.before(ref, &[_]*Node{new});

    // Verify order: new, ref
    try testing.expectEqual(@as(usize, 2), parent.child_nodes.items.items.len);

    const first_child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second_child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));

    try testing.expectEqual(new, first_child);
    try testing.expectEqual(ref, second_child);
}

test "ChildNode.before with multiple nodes" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const ref = try Element.create(allocator, "p");
    const new1 = try Element.create(allocator, "span");
    const new2 = try Element.create(allocator, "b");

    _ = try parent.appendChild(ref);

    try ChildNode.before(ref, &[_]*Node{ new1, new2 });

    // Verify order: new1, new2, ref
    try testing.expectEqual(@as(usize, 3), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));

    try testing.expectEqual(new1, first);
    try testing.expectEqual(new2, second);
    try testing.expectEqual(ref, third);
}

test "ChildNode.before with no parent" {
    const allocator = testing.allocator;

    const orphan = try Element.create(allocator, "div");
    defer orphan.release();

    const new = try Element.create(allocator, "span");
    defer new.release();

    const result = ChildNode.before(orphan, &[_]*Node{new});
    try testing.expectError(error.HierarchyRequestError, result);
}

test "ChildNode.after with single node" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const ref = try Element.create(allocator, "p");
    const new = try Element.create(allocator, "span");

    _ = try parent.appendChild(ref);

    try ChildNode.after(ref, &[_]*Node{new});

    // Verify order: ref, new
    try testing.expectEqual(@as(usize, 2), parent.child_nodes.items.items.len);

    const first_child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second_child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));

    try testing.expectEqual(ref, first_child);
    try testing.expectEqual(new, second_child);
}

test "ChildNode.after with multiple nodes" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const ref = try Element.create(allocator, "p");
    const new1 = try Element.create(allocator, "span");
    const new2 = try Element.create(allocator, "b");

    _ = try parent.appendChild(ref);

    try ChildNode.after(ref, &[_]*Node{ new1, new2 });

    // Verify order: ref, new1, new2
    try testing.expectEqual(@as(usize, 3), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    const third: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[2]));

    try testing.expectEqual(ref, first);
    try testing.expectEqual(new1, second);
    try testing.expectEqual(new2, third);
}

test "ChildNode.after as last child" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const ref = try Element.create(allocator, "p");
    const new = try Element.create(allocator, "span");

    _ = try parent.appendChild(ref);

    try ChildNode.after(ref, &[_]*Node{new});

    // Verify order: ref, new (ref was last child)
    try testing.expectEqual(@as(usize, 2), parent.child_nodes.items.items.len);

    const last: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));
    try testing.expectEqual(new, last);
}

test "ChildNode.replaceWith with single node" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const old = try Element.create(allocator, "p");
    const new = try Element.create(allocator, "span");

    _ = try parent.appendChild(old);

    try ChildNode.replaceWith(old, &[_]*Node{new});

    // Verify: only new remains
    try testing.expectEqual(@as(usize, 1), parent.child_nodes.items.items.len);

    const child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    try testing.expectEqual(new, child);

    // Verify old was removed from parent
    try testing.expect(old.parent_node == null);
}

test "ChildNode.replaceWith with multiple nodes" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const old = try Element.create(allocator, "p");
    const new1 = try Element.create(allocator, "span");
    const new2 = try Element.create(allocator, "b");

    _ = try parent.appendChild(old);

    try ChildNode.replaceWith(old, &[_]*Node{ new1, new2 });

    // Verify: new1, new2 (old removed)
    try testing.expectEqual(@as(usize, 2), parent.child_nodes.items.items.len);

    const first: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[0]));
    const second: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[1]));

    try testing.expectEqual(new1, first);
    try testing.expectEqual(new2, second);
    try testing.expect(old.parent_node == null);
}

test "ChildNode.replaceWith with empty array removes node" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "p");
    _ = try parent.appendChild(child);

    try ChildNode.replaceWith(child, &[_]*Node{});

    // Verify: child was removed, parent is empty
    try testing.expectEqual(@as(usize, 0), parent.child_nodes.items.items.len);
    try testing.expect(child.parent_node == null);
}

test "ChildNode.remove from parent" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "p");
    _ = try parent.appendChild(child);

    try ChildNode.remove(child);

    // Verify: child was removed
    try testing.expectEqual(@as(usize, 0), parent.child_nodes.items.items.len);
    try testing.expect(child.parent_node == null);
}

test "ChildNode.remove with no parent is no-op" {
    const allocator = testing.allocator;

    const orphan = try Element.create(allocator, "div");
    defer orphan.release();

    // Should not error
    try ChildNode.remove(orphan);

    try testing.expect(orphan.parent_node == null);
}

test "ChildNode.remove can be called multiple times" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "p");
    _ = try parent.appendChild(child);

    try ChildNode.remove(child);
    try ChildNode.remove(child); // Second call is no-op

    try testing.expectEqual(@as(usize, 0), parent.child_nodes.items.items.len);
}
