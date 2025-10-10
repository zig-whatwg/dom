//! TreeWalker Interface - WHATWG DOM Standard §6.2
//! ================================================
//!
//! TreeWalker provides tree traversal with filtering capabilities.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-treewalker
//! - **Section**: §6.2 Interface TreeWalker
//!
//! ## MDN Documentation
//! - **TreeWalker**: https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker
//!
//! ## Overview
//!
//! TreeWalker represents an object to traverse a filtered view of the DOM tree.
//! Unlike NodeIterator, TreeWalker maintains a current node and provides methods
//! to navigate in any direction through the tree.
//!
//! ## Usage Example
//!
//! ```zig
//! const walker = try TreeWalker.init(allocator, root, SHOW_ELEMENT, null);
//! defer walker.deinit();
//!
//! // Navigate through elements
//! while (walker.nextNode()) |node| {
//!     // Process element
//! }
//! ```

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeFilter = @import("node_filter.zig");

pub const TreeWalker = struct {
    /// The root node of the tree
    root: *Node,

    /// The current node
    current_node: *Node,

    /// Bitmask of node types to show
    what_to_show: u32,

    /// Optional filter callback
    filter: ?NodeFilter.FilterCallback,

    /// Memory allocator
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a new TreeWalker
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `root`: Root node for traversal
    /// - `what_to_show`: Bitmask of node types to show
    /// - `filter`: Optional filter callback
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created TreeWalker.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const walker = try TreeWalker.init(
    ///     allocator,
    ///     root,
    ///     SHOW_ELEMENT,
    ///     null
    /// );
    /// defer walker.deinit();
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
            .current_node = root,
            .what_to_show = what_to_show,
            .filter = filter,
            .allocator = allocator,
        };

        return self;
    }

    /// Move to parent node
    ///
    /// ## Returns
    ///
    /// The parent node if found and accepted, null otherwise.
    pub fn parentNode(self: *Self) ?*Node {
        var node = self.current_node;

        while (node != self.root) {
            const parent = node.parent_node orelse return null;

            const result = NodeFilter.filterNode(parent, self.what_to_show, self.filter);
            if (result == NodeFilter.FILTER_ACCEPT) {
                self.current_node = parent;
                return parent;
            }

            node = parent;
        }

        return null;
    }

    /// Move to first child
    ///
    /// ## Returns
    ///
    /// The first child node if found and accepted, null otherwise.
    pub fn firstChild(self: *Self) ?*Node {
        return self.traverseChildren(true);
    }

    /// Move to last child
    ///
    /// ## Returns
    ///
    /// The last child node if found and accepted, null otherwise.
    pub fn lastChild(self: *Self) ?*Node {
        return self.traverseChildren(false);
    }

    /// Move to previous sibling
    ///
    /// ## Returns
    ///
    /// The previous sibling if found and accepted, null otherwise.
    pub fn previousSibling(self: *Self) ?*Node {
        return self.traverseSiblings(false);
    }

    /// Move to next sibling
    ///
    /// ## Returns
    ///
    /// The next sibling if found and accepted, null otherwise.
    pub fn nextSibling(self: *Self) ?*Node {
        return self.traverseSiblings(true);
    }

    /// Move to previous node in tree order
    ///
    /// ## Returns
    ///
    /// The previous node if found, null otherwise.
    pub fn previousNode(self: *Self) ?*Node {
        var node = self.current_node;

        while (node != self.root) {
            const sibling = self.getPreviousSibling(node);
            if (sibling) |sib| {
                // Find rightmost descendant
                var current = sib;
                while (true) {
                    const result = NodeFilter.filterNode(current, self.what_to_show, self.filter);
                    if (result == NodeFilter.FILTER_REJECT) break;

                    const last = self.getLastChild(current);
                    if (last) |l| {
                        current = l;
                    } else {
                        if (result == NodeFilter.FILTER_ACCEPT) {
                            self.current_node = current;
                            return current;
                        }
                        break;
                    }
                }
            }

            const parent = node.parent_node orelse return null;
            if (parent == self.root) return null;

            const result = NodeFilter.filterNode(parent, self.what_to_show, self.filter);
            if (result == NodeFilter.FILTER_ACCEPT) {
                self.current_node = parent;
                return parent;
            }

            node = parent;
        }

        return null;
    }

    /// Move to next node in tree order
    ///
    /// ## Returns
    ///
    /// The next node if found, null otherwise.
    pub fn nextNode(self: *Self) ?*Node {
        var node = self.current_node;

        while (true) {
            // Try to go to first child
            const child = self.getFirstChild(node);
            if (child) |c| {
                const result = NodeFilter.filterNode(c, self.what_to_show, self.filter);
                if (result == NodeFilter.FILTER_ACCEPT) {
                    self.current_node = c;
                    return c;
                }
                if (result == NodeFilter.FILTER_SKIP) {
                    node = c;
                    continue;
                }
            }

            // Try siblings and ancestors' siblings
            var current = node;
            while (current != self.root) {
                const sibling = self.getNextSibling(current);
                if (sibling) |sib| {
                    const result = NodeFilter.filterNode(sib, self.what_to_show, self.filter);
                    if (result == NodeFilter.FILTER_ACCEPT) {
                        self.current_node = sib;
                        return sib;
                    }
                    if (result == NodeFilter.FILTER_SKIP) {
                        node = sib;
                        break;
                    }
                }

                current = current.parent_node orelse return null;
            }

            if (current == self.root) return null;
        }

        return null;
    }

    // Helper methods

    fn traverseChildren(self: *Self, first: bool) ?*Node {
        var node = if (first) self.getFirstChild(self.current_node) else self.getLastChild(self.current_node);

        outer: while (node) |n| {
            const result = NodeFilter.filterNode(n, self.what_to_show, self.filter);

            if (result == NodeFilter.FILTER_ACCEPT) {
                self.current_node = n;
                return n;
            }

            if (result == NodeFilter.FILTER_SKIP) {
                const child = if (first) self.getFirstChild(n) else self.getLastChild(n);
                if (child) |c| {
                    node = c;
                    continue;
                }
            }

            // Try to find next/previous sibling, walking up tree if necessary
            var current = n;
            while (true) {
                const sibling = if (first) self.getNextSibling(current) else self.getPreviousSibling(current);
                if (sibling) |sib| {
                    node = sib;
                    continue :outer;
                }

                const parent = current.parent_node orelse return null;
                if (parent == self.current_node) return null;
                current = parent;
            }
        }

        return null;
    }

    fn traverseSiblings(self: *Self, next: bool) ?*Node {
        var node = if (next) self.getNextSibling(self.current_node) else self.getPreviousSibling(self.current_node);

        outer: while (node) |n| {
            const result = NodeFilter.filterNode(n, self.what_to_show, self.filter);

            if (result == NodeFilter.FILTER_ACCEPT) {
                self.current_node = n;
                return n;
            }

            if (result == NodeFilter.FILTER_SKIP) {
                const child = if (next) self.getFirstChild(n) else self.getLastChild(n);
                if (child) |c| {
                    node = c;
                    continue;
                }
            }

            // Try next sibling
            var current = n;
            while (true) {
                const sibling = if (next) self.getNextSibling(current) else self.getPreviousSibling(current);
                if (sibling) |sib| {
                    node = sib;
                    continue :outer;
                }

                const parent = current.parent_node orelse return null;
                if (parent == self.current_node or parent == self.root) return null;
                current = parent;
            }
        }

        return null;
    }

    fn getFirstChild(self: *Self, node: *Node) ?*Node {
        _ = self;
        if (node.child_nodes.length() == 0) return null;
        const child_ptr = node.child_nodes.item(0) orelse return null;
        return @ptrCast(@alignCast(child_ptr));
    }

    fn getLastChild(self: *Self, node: *Node) ?*Node {
        _ = self;
        const len = node.child_nodes.length();
        if (len == 0) return null;
        const child_ptr = node.child_nodes.item(len - 1) orelse return null;
        return @ptrCast(@alignCast(child_ptr));
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

test "TreeWalker creation" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const walker = try TreeWalker.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    try std.testing.expectEqual(root, walker.root);
    try std.testing.expectEqual(root, walker.current_node);
}

test "TreeWalker firstChild" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const child = try Node.init(allocator, .text_node, "text");
    _ = try root.appendChild(child);

    const walker = try TreeWalker.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    const first = walker.firstChild();
    try std.testing.expectEqual(child, first.?);
    try std.testing.expectEqual(child, walker.current_node);
}

test "TreeWalker lastChild" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const child1 = try Node.init(allocator, .text_node, "first");
    _ = try root.appendChild(child1);

    const child2 = try Node.init(allocator, .text_node, "last");
    _ = try root.appendChild(child2);

    const walker = try TreeWalker.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    const last = walker.lastChild();
    try std.testing.expectEqual(child2, last.?);
}

test "TreeWalker nextSibling" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const child1 = try Node.init(allocator, .text_node, "first");
    _ = try root.appendChild(child1);

    const child2 = try Node.init(allocator, .text_node, "second");
    _ = try root.appendChild(child2);

    const walker = try TreeWalker.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    _ = walker.firstChild();
    const next = walker.nextSibling();
    try std.testing.expectEqual(child2, next.?);
}

test "TreeWalker previousSibling" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const child1 = try Node.init(allocator, .text_node, "first");
    _ = try root.appendChild(child1);

    const child2 = try Node.init(allocator, .text_node, "second");
    _ = try root.appendChild(child2);

    const walker = try TreeWalker.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    _ = walker.lastChild();
    const prev = walker.previousSibling();
    try std.testing.expectEqual(child1, prev.?);
}

test "TreeWalker parentNode" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const child = try Node.init(allocator, .text_node, "text");
    _ = try root.appendChild(child);

    const walker = try TreeWalker.init(allocator, root, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    _ = walker.firstChild();
    const parent = walker.parentNode();
    try std.testing.expectEqual(root, parent.?);
}

test "TreeWalker filtering by SHOW_ELEMENT" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "div");
    defer root.release();

    const text = try Node.init(allocator, .text_node, "text");
    _ = try root.appendChild(text);

    const elem = try Node.init(allocator, .element_node, "span");
    _ = try root.appendChild(elem);

    const walker = try TreeWalker.init(allocator, root, NodeFilter.SHOW_ELEMENT, null);
    defer walker.deinit();

    // Should skip text node
    const first = walker.firstChild();
    try std.testing.expectEqual(elem, first.?);
}

test "TreeWalker memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const root = try Node.init(allocator, .element_node, "div");
        defer root.release();

        const walker = try TreeWalker.init(allocator, root, NodeFilter.SHOW_ALL, null);
        walker.deinit();
    }
}
