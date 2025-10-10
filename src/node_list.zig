//! NodeList Implementation
//!
//! This module implements the WHATWG DOM Standard's `NodeList` interface (§4.2.10.1).
//! A NodeList is a collection of nodes, typically returned by various DOM methods such as
//! `childNodes`, `querySelectorAll`, and `getElementsByTagName`.
//!
//! ## WHATWG DOM Standard
//!
//! NodeList objects can be either **live** or **static**:
//! - **Live NodeLists**: Automatically update when the document changes (e.g., `childNodes`)
//! - **Static NodeLists**: Snapshots that don't update (e.g., `querySelectorAll`)
//!
//! This implementation provides the underlying collection mechanism that can support
//! both live and static NodeLists.
//!
//! ## Key Characteristics
//!
//! - **Indexed Access**: Elements accessed by numeric index (0-based)
//! - **Length Property**: Number of items in the collection
//! - **Array-Like**: Similar to JavaScript arrays but not true arrays
//! - **Read-Only**: In the spec, NodeLists are read-only (modifications happen through DOM methods)
//! - **Iterable**: Can be iterated over in order
//!
//! ## Common Sources of NodeLists
//!
//! ```javascript
//! // Live NodeList
//! element.childNodes  // Updates automatically
//!
//! // Static NodeLists
//! document.querySelectorAll('.class')  // Snapshot
//! document.getElementsByTagName('div')  // Actually HTMLCollection, but similar
//! ```
//!
//! ## Examples
//!
//! ### Basic Usage
//! ```zig
//! var list = NodeList.init(allocator);
//! defer list.deinit();
//!
//! try list.append(node1);
//! try list.append(node2);
//! try expect(list.length() == 2);
//! ```
//!
//! ### Accessing Items
//! ```zig
//! if (list.item(0)) |first| {
//!     // Use first node
//! }
//!
//! // Out of bounds returns null
//! try expect(list.item(100) == null);
//! ```
//!
//! ### Iteration Pattern
//! ```zig
//! var i: usize = 0;
//! while (i < list.length()) : (i += 1) {
//!     if (list.item(i)) |node| {
//!         // Process node
//!     }
//! }
//! ```
//!
//! ## Specification References
//!
//! - WHATWG DOM Standard §4.2.10.1: https://dom.spec.whatwg.org/#interface-nodelist
//! - MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/NodeList
//!
//! ## Implementation Notes
//!
//! This implementation uses `*anyopaque` for maximum flexibility, allowing it to store
//! any node type. Callers are responsible for type safety when retrieving items.
//!
//! ## Memory Management
//!
//! - Call `deinit()` when done with the NodeList to free internal storage
//! - The NodeList does NOT own the nodes themselves (no reference counting)
//! - Nodes must be managed separately by their owners

const std = @import("std");

/// NodeList represents an ordered collection of nodes.
///
/// ## WHATWG DOM Standard §4.2.10.1
///
/// NodeList is used throughout the DOM to represent collections of nodes.
/// It provides indexed access and a length property, similar to arrays.
///
/// ## Key Features
///
/// - **Indexed Access**: Get items by numeric index
/// - **Bounds Checking**: Out-of-bounds access returns null
/// - **Dynamic**: Can grow and shrink (implementation detail)
/// - **Order Preserving**: Maintains insertion order
///
/// ## Live vs Static
///
/// The DOM spec distinguishes between:
/// - **Live NodeLists**: Reflect current document state (e.g., `childNodes`)
/// - **Static NodeLists**: Snapshot at creation time (e.g., `querySelectorAll`)
///
/// This implementation provides the underlying storage for both types.
pub const NodeList = struct {
    const Self = @This();

    /// Internal storage for node pointers.
    /// Uses `*anyopaque` for type flexibility.
    items: std.ArrayList(*anyopaque),

    /// Allocator used for internal storage.
    allocator: std.mem.Allocator,

    /// Creates a new empty NodeList.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the list's internal storage
    ///
    /// ## Returns
    ///
    /// A new empty NodeList.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    /// try expect(list.length() == 0);
    /// ```
    ///
    /// ### With Immediate Use
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.append(node1);
    /// try list.append(node2);
    /// try expect(list.length() == 2);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.2.10.1: NodeList interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .items = std.ArrayList(*anyopaque){},
            .allocator = allocator,
        };
    }

    /// Releases the NodeList's internal storage.
    ///
    /// ## Important
    ///
    /// This method does NOT release the nodes themselves. The NodeList
    /// does not own the nodes - they must be managed separately.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit(); // Automatic cleanup
    ///
    /// try list.append(node);
    /// // ... use list ...
    /// ```
    ///
    /// ### Manual Cleanup
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// try list.append(node);
    /// // ... use list ...
    /// list.deinit(); // Manual cleanup
    /// ```
    pub fn deinit(self: *Self) void {
        self.items.deinit(self.allocator);
    }

    /// Returns the number of nodes in the list.
    ///
    /// ## Returns
    ///
    /// The number of items in the collection.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    /// try expect(list.length() == 0);
    ///
    /// try list.append(node);
    /// try expect(list.length() == 1);
    /// ```
    ///
    /// ### Iteration Pattern
    /// ```zig
    /// var i: usize = 0;
    /// while (i < list.length()) : (i += 1) {
    ///     if (list.item(i)) |node| {
    ///         // Process each node
    ///     }
    /// }
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.2.10.1: NodeList.length
    /// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/NodeList/length
    pub fn length(self: *const Self) usize {
        return self.items.items.len;
    }

    /// Returns the item at the specified index.
    ///
    /// ## Parameters
    ///
    /// - `index`: 0-based index of the item to retrieve
    ///
    /// ## Returns
    ///
    /// The node at the specified index, or `null` if index is out of bounds.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.append(node1);
    /// try list.append(node2);
    ///
    /// // Get first item
    /// const first = list.item(0);
    /// try expect(first != null);
    ///
    /// // Out of bounds returns null
    /// const invalid = list.item(100);
    /// try expect(invalid == null);
    /// ```
    ///
    /// ### Safe Access Pattern
    /// ```zig
    /// if (list.item(0)) |first_node| {
    ///     // Safely use first_node
    /// } else {
    ///     // List is empty or index invalid
    /// }
    /// ```
    ///
    /// ### Iteration
    /// ```zig
    /// for (0..list.length()) |i| {
    ///     if (list.item(i)) |node| {
    ///         // Process node
    ///     }
    /// }
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.2.10.1: NodeList.item()
    /// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/NodeList/item
    pub fn item(self: *const Self, index: usize) ?*anyopaque {
        if (index >= self.items.items.len) {
            return null;
        }
        return self.items.items[index];
    }

    /// Appends a node to the end of the list.
    ///
    /// ## Parameters
    ///
    /// - `node`: Pointer to the node to append
    ///
    /// ## Errors
    ///
    /// Returns an error if memory allocation fails.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.append(node1);
    /// try list.append(node2);
    /// try expect(list.length() == 2);
    /// ```
    ///
    /// ### Building a List
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// for (nodes) |node| {
    ///     try list.append(node);
    /// }
    /// ```
    ///
    /// ## Implementation Notes
    ///
    /// - The list does not take ownership of the node
    /// - The node must remain valid while in the list
    /// - Duplicate nodes are allowed
    pub fn append(self: *Self, node: *anyopaque) !void {
        try self.items.append(self.allocator, node);
    }

    /// Removes the node at the specified index.
    ///
    /// ## Parameters
    ///
    /// - `index`: 0-based index of the item to remove
    ///
    /// ## Behavior
    ///
    /// - If index is valid, removes the item and shifts subsequent items down
    /// - If index is out of bounds, does nothing (no error)
    /// - Does not release the removed node (caller's responsibility)
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.append(node1);
    /// try list.append(node2);
    /// try list.append(node3);
    ///
    /// list.remove(1); // Remove node2
    /// try expect(list.length() == 2);
    /// ```
    ///
    /// ### Safe Removal
    /// ```zig
    /// if (index < list.length()) {
    ///     list.remove(index);
    /// }
    /// ```
    ///
    /// ### Clear All Items
    /// ```zig
    /// while (list.length() > 0) {
    ///     list.remove(0);
    /// }
    /// ```
    ///
    /// ## Performance
    ///
    /// Uses `orderedRemove` which maintains order but requires shifting
    /// subsequent elements. O(n) complexity where n is the number of elements
    /// after the removed index.
    pub fn remove(self: *Self, index: usize) void {
        if (index < self.items.items.len) {
            _ = self.items.orderedRemove(index);
        }
    }

    /// Removes all items from the list.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.append(node1);
    /// try list.append(node2);
    /// try expect(list.length() == 2);
    ///
    /// list.clear();
    /// try expect(list.length() == 0);
    /// ```
    ///
    /// ## Implementation Notes
    ///
    /// Does not release the nodes themselves - only removes them from the list.
    pub fn clear(self: *Self) void {
        self.items.clearRetainingCapacity();
    }

    /// Returns true if the list contains the specified node.
    ///
    /// ## Parameters
    ///
    /// - `node`: Pointer to search for
    ///
    /// ## Returns
    ///
    /// True if the node is in the list, false otherwise.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.append(node1);
    /// try expect(list.contains(node1));
    /// try expect(!list.contains(node2));
    /// ```
    pub fn contains(self: *const Self, node: *anyopaque) bool {
        for (self.items.items) |list_item| {
            if (list_item == node) return true;
        }
        return false;
    }

    /// Returns the index of the first occurrence of the specified node.
    ///
    /// ## Parameters
    ///
    /// - `node`: Pointer to search for
    ///
    /// ## Returns
    ///
    /// The 0-based index of the node, or null if not found.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.append(node1);
    /// try list.append(node2);
    ///
    /// const idx = list.indexOf(node2);
    /// try expect(idx.? == 1);
    ///
    /// const not_found = list.indexOf(node3);
    /// try expect(not_found == null);
    /// ```
    pub fn indexOf(self: *const Self, node: *anyopaque) ?usize {
        for (self.items.items, 0..) |list_item, i| {
            if (list_item == node) return i;
        }
        return null;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "NodeList basic operations" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    try std.testing.expectEqual(@as(usize, 0), list.length());

    var dummy1: i32 = 1;
    var dummy2: i32 = 2;

    try list.append(&dummy1);
    try std.testing.expectEqual(@as(usize, 1), list.length());

    try list.append(&dummy2);
    try std.testing.expectEqual(@as(usize, 2), list.length());

    const item0 = list.item(0);
    try std.testing.expect(item0 != null);

    const item_out_of_range = list.item(10);
    try std.testing.expect(item_out_of_range == null);

    list.remove(0);
    try std.testing.expectEqual(@as(usize, 1), list.length());
}

test "NodeList empty list" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    try std.testing.expectEqual(@as(usize, 0), list.length());
    try std.testing.expect(list.item(0) == null);
}

test "NodeList append multiple items" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var items: [10]i32 = undefined;
    for (&items, 0..) |*item, i| {
        item.* = @intCast(i);
        try list.append(item);
    }

    try std.testing.expectEqual(@as(usize, 10), list.length());

    for (0..10) |i| {
        const item = list.item(i);
        try std.testing.expect(item != null);
    }
}

test "NodeList item access" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var dummy1: i32 = 1;
    var dummy2: i32 = 2;
    var dummy3: i32 = 3;

    try list.append(&dummy1);
    try list.append(&dummy2);
    try list.append(&dummy3);

    // Valid access
    try std.testing.expect(list.item(0) != null);
    try std.testing.expect(list.item(1) != null);
    try std.testing.expect(list.item(2) != null);

    // Invalid access
    try std.testing.expect(list.item(3) == null);
    try std.testing.expect(list.item(100) == null);
}

test "NodeList remove from middle" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var items: [5]i32 = .{ 1, 2, 3, 4, 5 };
    for (&items) |*item| {
        try list.append(item);
    }

    list.remove(2); // Remove middle item (3)
    try std.testing.expectEqual(@as(usize, 4), list.length());

    // Verify order is maintained
    const val1 = @as(*i32, @ptrCast(@alignCast(list.item(0).?))).*;
    const val2 = @as(*i32, @ptrCast(@alignCast(list.item(1).?))).*;
    const val3 = @as(*i32, @ptrCast(@alignCast(list.item(2).?))).*;
    const val4 = @as(*i32, @ptrCast(@alignCast(list.item(3).?))).*;

    try std.testing.expectEqual(@as(i32, 1), val1);
    try std.testing.expectEqual(@as(i32, 2), val2);
    try std.testing.expectEqual(@as(i32, 4), val3);
    try std.testing.expectEqual(@as(i32, 5), val4);
}

test "NodeList remove first and last" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var items: [3]i32 = .{ 1, 2, 3 };
    for (&items) |*item| {
        try list.append(item);
    }

    // Remove first
    list.remove(0);
    try std.testing.expectEqual(@as(usize, 2), list.length());

    // Remove last (now at index 1)
    list.remove(1);
    try std.testing.expectEqual(@as(usize, 1), list.length());
}

test "NodeList remove invalid index" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var dummy: i32 = 1;
    try list.append(&dummy);

    // Should not crash or error
    list.remove(10);
    try std.testing.expectEqual(@as(usize, 1), list.length());
}

test "NodeList clear" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var items: [5]i32 = .{ 1, 2, 3, 4, 5 };
    for (&items) |*item| {
        try list.append(item);
    }

    try std.testing.expectEqual(@as(usize, 5), list.length());

    list.clear();
    try std.testing.expectEqual(@as(usize, 0), list.length());
}

test "NodeList contains" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var dummy1: i32 = 1;
    var dummy2: i32 = 2;
    var dummy3: i32 = 3;

    try list.append(&dummy1);
    try list.append(&dummy2);

    try std.testing.expect(list.contains(&dummy1));
    try std.testing.expect(list.contains(&dummy2));
    try std.testing.expect(!list.contains(&dummy3));
}

test "NodeList indexOf" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var dummy1: i32 = 1;
    var dummy2: i32 = 2;
    var dummy3: i32 = 3;
    var dummy4: i32 = 4;

    try list.append(&dummy1);
    try list.append(&dummy2);
    try list.append(&dummy3);

    try std.testing.expectEqual(@as(?usize, 0), list.indexOf(&dummy1));
    try std.testing.expectEqual(@as(?usize, 1), list.indexOf(&dummy2));
    try std.testing.expectEqual(@as(?usize, 2), list.indexOf(&dummy3));
    try std.testing.expectEqual(@as(?usize, null), list.indexOf(&dummy4));
}

test "NodeList iteration pattern" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var items: [5]i32 = .{ 10, 20, 30, 40, 50 };
    for (&items) |*item| {
        try list.append(item);
    }

    var sum: i32 = 0;
    var i: usize = 0;
    while (i < list.length()) : (i += 1) {
        if (list.item(i)) |item_ptr| {
            const val = @as(*i32, @ptrCast(@alignCast(item_ptr))).*;
            sum += val;
        }
    }

    try std.testing.expectEqual(@as(i32, 150), sum);
}

test "NodeList duplicate items allowed" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var dummy: i32 = 42;

    try list.append(&dummy);
    try list.append(&dummy);
    try list.append(&dummy);

    try std.testing.expectEqual(@as(usize, 3), list.length());
    try std.testing.expect(list.item(0) == list.item(1));
    try std.testing.expect(list.item(1) == list.item(2));
}

test "NodeList memory leak test" {
    const allocator = std.testing.allocator;

    var iteration: usize = 0;
    while (iteration < 100) : (iteration += 1) {
        var list = NodeList.init(allocator);
        defer list.deinit();

        var items: [10]i32 = undefined;
        for (&items, 0..) |*item, i| {
            item.* = @intCast(i);
            try list.append(item);
        }

        // Test all operations
        _ = list.item(5);
        _ = list.contains(&items[3]);
        _ = list.indexOf(&items[7]);
        list.remove(5);
        list.clear();
    }
}

test "NodeList clear and reuse" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var items1: [3]i32 = .{ 1, 2, 3 };
    for (&items1) |*item| {
        try list.append(item);
    }
    try std.testing.expectEqual(@as(usize, 3), list.length());

    list.clear();
    try std.testing.expectEqual(@as(usize, 0), list.length());

    var items2: [2]i32 = .{ 4, 5 };
    for (&items2) |*item| {
        try list.append(item);
    }
    try std.testing.expectEqual(@as(usize, 2), list.length());
}

test "NodeList remove all items one by one" {
    const allocator = std.testing.allocator;

    var list = NodeList.init(allocator);
    defer list.deinit();

    var items: [5]i32 = .{ 1, 2, 3, 4, 5 };
    for (&items) |*item| {
        try list.append(item);
    }

    while (list.length() > 0) {
        list.remove(0);
    }

    try std.testing.expectEqual(@as(usize, 0), list.length());
}
