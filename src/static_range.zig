//! StaticRange - Immutable Range Interface
//!
//! WHATWG DOM Standard §5.4
//! https://dom.spec.whatwg.org/#interface-staticrange
//!
//! StaticRange represents an immutable range that doesn't update when the DOM changes.
//! Unlike Range objects, StaticRange is lightweight and doesn't track mutations.

const std = @import("std");
const Node = @import("node.zig").Node;

/// StaticRangeInit dictionary for initialization
pub const StaticRangeInit = struct {
    start_container: *Node,
    start_offset: usize,
    end_container: *Node,
    end_offset: usize,
};

/// StaticRange represents an immutable range
///
/// ## Specification
///
/// WHATWG DOM Standard §5.4
///
/// ## Differences from Range
///
/// - Immutable: Cannot be modified after creation
/// - Lightweight: No mutation tracking
/// - No validation: Can represent invalid ranges
/// - Faster: No overhead of live range maintenance
///
/// ## Example
///
/// ```zig
/// const static_range = try StaticRange.init(allocator, .{
///     .start_container = text_node,
///     .start_offset = 0,
///     .end_container = text_node,
///     .end_offset = 5,
/// });
/// defer static_range.deinit();
/// ```
pub const StaticRange = struct {
    /// Start boundary point - node
    start_container: *Node,

    /// Start boundary point - offset
    start_offset: usize,

    /// End boundary point - node
    end_container: *Node,

    /// End boundary point - offset
    end_offset: usize,

    /// Memory allocator
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a StaticRange
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `init`: Initialization parameters
    ///
    /// ## Returns
    ///
    /// A new StaticRange instance.
    ///
    /// ## Note
    ///
    /// Unlike Range, StaticRange does not validate the boundary points.
    /// It can represent invalid ranges (e.g., where start > end).
    pub fn init(allocator: std.mem.Allocator, init_params: StaticRangeInit) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .start_container = init_params.start_container,
            .start_offset = init_params.start_offset,
            .end_container = init_params.end_container,
            .end_offset = init_params.end_offset,
            .allocator = allocator,
        };
        return self;
    }

    /// Get the start container
    pub fn startContainer(self: *const Self) *Node {
        return self.start_container;
    }

    /// Get the start offset
    pub fn startOffset(self: *const Self) usize {
        return self.start_offset;
    }

    /// Get the end container
    pub fn endContainer(self: *const Self) *Node {
        return self.end_container;
    }

    /// Get the end offset
    pub fn endOffset(self: *const Self) usize {
        return self.end_offset;
    }

    /// Check if the range is collapsed
    ///
    /// A range is collapsed if start equals end.
    pub fn collapsed(self: *const Self) bool {
        return self.start_container == self.end_container and
            self.start_offset == self.end_offset;
    }

    /// Free the StaticRange
    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};

// Tests
test "StaticRange basic creation" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "#text");
    defer node.release();

    const range = try StaticRange.init(allocator, .{
        .start_container = node,
        .start_offset = 0,
        .end_container = node,
        .end_offset = 5,
    });
    defer range.deinit();

    try std.testing.expectEqual(node, range.startContainer());
    try std.testing.expectEqual(@as(usize, 0), range.startOffset());
    try std.testing.expectEqual(node, range.endContainer());
    try std.testing.expectEqual(@as(usize, 5), range.endOffset());
}

test "StaticRange collapsed" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "#text");
    defer node.release();

    const collapsed_range = try StaticRange.init(allocator, .{
        .start_container = node,
        .start_offset = 3,
        .end_container = node,
        .end_offset = 3,
    });
    defer collapsed_range.deinit();

    try std.testing.expect(collapsed_range.collapsed());

    const not_collapsed = try StaticRange.init(allocator, .{
        .start_container = node,
        .start_offset = 0,
        .end_container = node,
        .end_offset = 5,
    });
    defer not_collapsed.deinit();

    try std.testing.expect(!not_collapsed.collapsed());
}

test "StaticRange with different nodes" {
    const allocator = std.testing.allocator;

    const node1 = try Node.init(allocator, .text_node, "#text1");
    defer node1.release();

    const node2 = try Node.init(allocator, .text_node, "#text2");
    defer node2.release();

    const range = try StaticRange.init(allocator, .{
        .start_container = node1,
        .start_offset = 2,
        .end_container = node2,
        .end_offset = 4,
    });
    defer range.deinit();

    try std.testing.expectEqual(node1, range.startContainer());
    try std.testing.expectEqual(node2, range.endContainer());
    try std.testing.expect(!range.collapsed());
}

test "StaticRange allows invalid ranges" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "#text");
    defer node.release();

    // StaticRange allows start > end (invalid but permitted)
    const invalid_range = try StaticRange.init(allocator, .{
        .start_container = node,
        .start_offset = 10,
        .end_container = node,
        .end_offset = 5,
    });
    defer invalid_range.deinit();

    try std.testing.expectEqual(@as(usize, 10), invalid_range.startOffset());
    try std.testing.expectEqual(@as(usize, 5), invalid_range.endOffset());
}

test "StaticRange memory leak test" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "#text");
    defer node.release();

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const range = try StaticRange.init(allocator, .{
            .start_container = node,
            .start_offset = 0,
            .end_container = node,
            .end_offset = i,
        });
        range.deinit();
    }
}
