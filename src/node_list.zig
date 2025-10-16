//! NodeList implementation - live collection of nodes.
//!
//! This module implements the WHATWG DOM NodeList interface with:
//! - Live collection semantics (reflects DOM changes)
//! - Index-based access via item(index)
//! - Length property
//!
//! Spec: WHATWG DOM §5.1 (https://dom.spec.whatwg.org/#interface-nodelist)

const std = @import("std");
const Node = @import("node.zig").Node;

/// NodeList - live collection of nodes.
///
/// This is a "live" collection that automatically reflects changes to the DOM tree.
/// For childNodes, the list is backed by the node's linked list of children.
///
/// ## Memory Management
/// NodeList does NOT own the nodes - it merely provides a view into the tree.
/// Nodes are owned by their parent via the tree structure.
pub const NodeList = struct {
    /// Parent node whose children this list represents
    parent: *Node,

    /// Creates a new NodeList viewing the children of a parent node.
    ///
    /// ## Parameters
    /// - `parent`: Parent node whose children to view
    ///
    /// ## Returns
    /// NodeList viewing parent's children
    pub fn init(parent: *Node) NodeList {
        return .{
            .parent = parent,
        };
    }

    /// Returns the number of nodes in the list.
    ///
    /// Implements WHATWG DOM NodeList.length property.
    /// This traverses the child linked list to count nodes (O(n)).
    ///
    /// ## Returns
    /// Number of nodes in the list
    pub fn length(self: *const NodeList) usize {
        var count: usize = 0;
        var current = self.parent.first_child;
        while (current) |node| {
            count += 1;
            current = node.next_sibling;
        }
        return count;
    }

    /// Returns the node at the specified index.
    ///
    /// Implements WHATWG DOM NodeList.item() method.
    /// This traverses the child linked list (O(n)).
    ///
    /// ## Parameters
    /// - `index`: Zero-based index of node to retrieve
    ///
    /// ## Returns
    /// Node at index or null if index >= length
    ///
    /// ## Example
    /// ```zig
    /// const child = list.item(0); // First child
    /// if (child) |node| {
    ///     std.debug.print("First child: {s}\n", .{node.nodeName()});
    /// }
    /// ```
    pub fn item(self: *const NodeList, index: usize) ?*Node {
        var count: usize = 0;
        var current = self.parent.first_child;
        while (current) |node| {
            if (count == index) {
                return node;
            }
            count += 1;
            current = node.next_sibling;
        }
        return null;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "NodeList - empty list" {
    const allocator = std.testing.allocator;

    // Minimal vtable for testing
    const test_vtable = @import("node.zig").NodeVTable{
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

    const parent = try Node.init(allocator, &test_vtable, .element);
    defer parent.release();

    const list = NodeList.init(parent);

    // Empty list
    try std.testing.expectEqual(@as(usize, 0), list.length());
    try std.testing.expect(list.item(0) == null);
}

test "NodeList - with children" {
    const allocator = std.testing.allocator;

    const test_vtable = @import("node.zig").NodeVTable{
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

    // Create three child nodes
    const child1 = try Node.init(allocator, &test_vtable, .element);
    defer child1.release();

    const child2 = try Node.init(allocator, &test_vtable, .element);
    defer child2.release();

    const child3 = try Node.init(allocator, &test_vtable, .element);
    defer child3.release();

    // Manually link children (Phase 2 will do this via appendChild)
    parent.first_child = child1;
    parent.last_child = child3;

    child1.next_sibling = child2;
    child2.next_sibling = child3;
    child3.next_sibling = null;

    child1.parent_node = parent;
    child2.parent_node = parent;
    child3.parent_node = parent;

    // Create NodeList
    const list = NodeList.init(parent);

    // Verify length
    try std.testing.expectEqual(@as(usize, 3), list.length());

    // Verify items
    try std.testing.expectEqual(child1, list.item(0).?);
    try std.testing.expectEqual(child2, list.item(1).?);
    try std.testing.expectEqual(child3, list.item(2).?);

    // Out of bounds
    try std.testing.expect(list.item(3) == null);

    // Clean up manual connections
    parent.first_child = null;
    parent.last_child = null;
    child1.next_sibling = null;
    child2.next_sibling = null;
    child1.parent_node = null;
    child2.parent_node = null;
    child3.parent_node = null;
}

test "NodeList - memory leak test" {
    const allocator = std.testing.allocator;

    const test_vtable = @import("node.zig").NodeVTable{
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

    // Test 1: Empty list
    {
        const parent = try Node.init(allocator, &test_vtable, .element);
        defer parent.release();

        const list = NodeList.init(parent);
        _ = list.length();
        _ = list.item(0);
    }

    // Test 2: List with children
    {
        const parent = try Node.init(allocator, &test_vtable, .element);
        defer parent.release();

        const child = try Node.init(allocator, &test_vtable, .element);
        defer child.release();

        parent.first_child = child;
        child.parent_node = parent;

        const list = NodeList.init(parent);
        _ = list.length();
        _ = list.item(0);

        // Clean up
        parent.first_child = null;
        child.parent_node = null;
    }

    // If we reach here without leaks, std.testing.allocator validates success
}
