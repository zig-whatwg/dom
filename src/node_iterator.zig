//! NodeIterator Interface - WHATWG DOM Standard §6.1
//! ==================================================
//!
//! NodeIterator provides forward-only tree traversal with filtering.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-nodeiterator
//! - **Section**: §6.1 Interface NodeIterator
//!
//! ## MDN Documentation
//! - **NodeIterator**: https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator
//!
//! ## Overview
//!
//! NodeIterator represents an iterator to traverse a filtered view of the DOM tree.
//! Unlike TreeWalker, NodeIterator only supports forward and backward traversal
//! (nextNode/previousNode) and maintains a reference node and pointer position.
//!
//! ## Usage Example
//!
//! ```zig
//! const iterator = try NodeIterator.init(allocator, root, SHOW_ELEMENT, null);
//! defer iterator.deinit();
//!
//! while (iterator.nextNode()) |node| {
//!     // Process node
//! }
//! ```

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeFilter = @import("node_filter.zig");

pub const NodeIterator = struct {
    /// The root node of the iterator
    root: *Node,

    /// The reference node
    reference_node: *Node,

    /// Whether the pointer is before the reference node
    pointer_before_reference: bool,

    /// Bitmask of node types to show
    what_to_show: u32,

    /// Optional filter callback
    filter: ?NodeFilter.FilterCallback,

    /// Memory allocator
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a new NodeIterator
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `root`: Root node for iteration
    /// - `what_to_show`: Bitmask of node types to show
    /// - `filter`: Optional filter callback
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created NodeIterator.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const iterator = try NodeIterator.init(
    ///     allocator,
    ///     root,
    ///     SHOW_TEXT,
    ///     null
    /// );
    /// defer iterator.deinit();
    /// ```
    pub fn init(
        allocator: std.mem.Allocator,
        root: *Node,
        what_to_show: u32,
        filter: ?NodeFilter.FilterCallback,
    ) !*Self {
        const self = try allocator.create(Self);

        self.* = .{
            .root = root,
            .reference_node = root,
            .pointer_before_reference = true,
            .what_to_show = what_to_show,
            .filter = filter,
            .allocator = allocator,
        };

        return self;
    }

    /// Get the next node
    ///
    /// Moves forward through the filtered tree and returns the next node.
    ///
    /// ## Returns
    ///
    /// The next node if found, null if at the end.
    ///
    /// ## Example
    ///
    /// ```zig
    /// while (iterator.nextNode()) |node| {
    ///     std.debug.print("Node: {s}\n", .{node.node_name});
    /// }
    /// ```
    pub fn nextNode(self: *Self) ?*Node {
        var node = self.reference_node;
        var before_node = self.pointer_before_reference;

        while (true) {
            if (!before_node) {
                // Move to next node in tree order
                const next = self.getNextNodeInTree(node);
                if (next) |n| {
                    node = n;
                } else {
                    return null;
                }
            } else {
                before_node = false;
            }

            // Filter the node
            const result = NodeFilter.filterNode(node, self.what_to_show, self.filter);
            if (result == NodeFilter.FILTER_ACCEPT) {
                self.reference_node = node;
                self.pointer_before_reference = before_node;
                return node;
            }

            // For FILTER_REJECT and FILTER_SKIP, continue to next node
        }
    }

    /// Get the previous node
    ///
    /// Moves backward through the filtered tree and returns the previous node.
    ///
    /// ## Returns
    ///
    /// The previous node if found, null if at the beginning.
    ///
    /// ## Example
    ///
    /// ```zig
    /// while (iterator.previousNode()) |node| {
    ///     std.debug.print("Node: {s}\n", .{node.node_name});
    /// }
    /// ```
    pub fn previousNode(self: *Self) ?*Node {
        var node = self.reference_node;
        var before_node = self.pointer_before_reference;

        while (true) {
            if (before_node) {
                // Move to previous node in tree order
                const prev = self.getPreviousNodeInTree(node);
                if (prev) |p| {
                    node = p;
                } else {
                    return null;
                }
            } else {
                before_node = true;
            }

            // Filter the node
            const result = NodeFilter.filterNode(node, self.what_to_show, self.filter);
            if (result == NodeFilter.FILTER_ACCEPT) {
                self.reference_node = node;
                self.pointer_before_reference = before_node;
                return node;
            }

            // For FILTER_REJECT and FILTER_SKIP, continue to previous node
        }
    }

    /// Detach the iterator (legacy)
    ///
    /// This method does nothing. It exists for compatibility.
    pub fn detach(self: *Self) void {
        _ = self;
        // No-op for compatibility
    }

    // Helper methods

    fn getNextNodeInTree(self: *Self, node: *Node) ?*Node {
        // Try first child
        if (node.child_nodes.length() > 0) {
            const child_ptr = node.child_nodes.item(0).?;
            return @ptrCast(@alignCast(child_ptr));
        }

        // Try next sibling or ancestor's sibling
        var current = node;
        while (current != self.root) {
            const sibling = self.getNextSibling(current);
            if (sibling) |sib| {
                return sib;
            }
            current = current.parent_node orelse return null;
        }

        return null;
    }

    fn getPreviousNodeInTree(self: *Self, node: *Node) ?*Node {
        // Can't go before root
        if (node == self.root) {
            return null;
        }

        // Try previous sibling's last descendant
        const sibling = self.getPreviousSibling(node);
        if (sibling) |sib| {
            return self.getLastDescendant(sib);
        }

        // Try parent
        return node.parent_node;
    }

    fn getLastDescendant(self: *Self, node: *Node) *Node {
        _ = self;
        var current = node;
        while (current.child_nodes.length() > 0) {
            const len = current.child_nodes.length();
            const child_ptr = current.child_nodes.item(len - 1).?;
            current = @ptrCast(@alignCast(child_ptr));
        }
        return current;
    }

    fn getNextSibling(self: *Self, node: *Node) ?*Node {
        _ = self;
        const parent = node.parent_node orelse return null;
        const len = parent.child_nodes.length();
        
        var i: usize = 0;
        while (i < len) : (i += 1) {
            const child: *Node = @ptrCast(@alignCast(parent.child_nodes.item(i).?));
            if (child == node and i + 1 < len) {
                const next: *Node = @ptrCast(@alignCast(parent.child_nodes.item(i + 1).?));
                return next;
            }
        }
        
        return null;
    }

    fn getPreviousSibling(self: *Self, node: *Node) ?*Node {
        _ = self;
        const parent = node.parent_node orelse return null;
        const len = parent.child_nodes.length();
        
        var i: usize = 0;
        while (i < len) : (i += 1) {
            const child: *Node = @ptrCast(@alignCast(parent.child_nodes.item(i).?));
            if (child == node and i > 0) {
                const prev: *Node = @ptrCast(@alignCast(parent.child_nodes.item(i - 1).?));
                return prev;
            }
        }
        
        return null;
    }

    /// Clean up resources
    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "NodeIterator creation" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const iterator = try NodeIterator.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer iterator.deinit();

    try std.testing.expectEqual(root, iterator.root);
    try std.testing.expectEqual(root, iterator.reference_node);
    try std.testing.expect(iterator.pointer_before_reference);
}

test "NodeIterator nextNode" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const child = try Node.init(allocator, .text_node, "text");
    _ = try root.appendChild(child);

    const iterator = try NodeIterator.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer iterator.deinit();

    const first = iterator.nextNode();
    try std.testing.expectEqual(root, first.?);

    const second = iterator.nextNode();
    try std.testing.expectEqual(child, second.?);
}

test "NodeIterator previousNode" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const child = try Node.init(allocator, .text_node, "text");
    _ = try root.appendChild(child);

    const iterator = try NodeIterator.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer iterator.deinit();

    // Go forward
    _ = iterator.nextNode();
    _ = iterator.nextNode();

    // Go backward
    const second = iterator.previousNode();
    try std.testing.expectEqual(child, second.?);

    const first = iterator.previousNode();
    try std.testing.expectEqual(root, first.?);
}

test "NodeIterator filtering by SHOW_TEXT" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const elem = try Node.init(allocator, .element_node, "span");
    _ = try root.appendChild(elem);

    const text = try Node.init(allocator, .text_node, "text");
    _ = try root.appendChild(text);

    const iterator = try NodeIterator.init(allocator, root, NodeFilter.SHOW_TEXT, null);
    defer iterator.deinit();

    // Should skip root and elem, only return text
    const first = iterator.nextNode();
    try std.testing.expectEqual(text, first.?);
}

test "NodeIterator with callback filter" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const child1 = try Node.init(allocator, .text_node, "accept");
    _ = try root.appendChild(child1);

    const child2 = try Node.init(allocator, .text_node, "reject");
    _ = try root.appendChild(child2);

    const Filter = struct {
        fn accept(node: *Node) u16 {
            // Accept nodes containing "accept"
            if (std.mem.indexOf(u8, node.node_name, "accept") != null) {
                return NodeFilter.FILTER_ACCEPT;
            }
            return NodeFilter.FILTER_REJECT;
        }
    };

    const iterator = try NodeIterator.init(allocator, root, NodeFilter.SHOW_TEXT, Filter.accept);
    defer iterator.deinit();

    const first = iterator.nextNode();
    try std.testing.expectEqual(child1, first.?);

    const second = iterator.nextNode();
    try std.testing.expect(second == null);
}

test "NodeIterator detach is no-op" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const iterator = try NodeIterator.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer iterator.deinit();

    // Should not crash
    iterator.detach();
}

test "NodeIterator memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const root = try Node.init(allocator, .element_node, "div");
        defer root.release();

        const iterator = try NodeIterator.init(allocator, root, NodeFilter.SHOW_ALL, null);
        iterator.deinit();
    }
}
