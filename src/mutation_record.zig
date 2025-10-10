//! MutationRecord - Record of a DOM Mutation
//!
//! WHATWG DOM Standard §4.3.3
//! https://dom.spec.whatwg.org/#interface-mutationrecord
//!
//! A MutationRecord represents a single mutation to the DOM tree.

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeList = @import("node_list.zig").NodeList;

/// MutationRecord represents a single mutation to the DOM
///
/// ## Specification
///
/// WHATWG DOM Standard §4.3.3
pub const MutationRecord = struct {
    /// Type of mutation
    type: MutationType,

    /// The node affected by the mutation
    target: *Node,

    /// Nodes added (for childList mutations)
    added_nodes: NodeList,

    /// Nodes removed (for childList mutations)
    removed_nodes: NodeList,

    /// Previous sibling of added/removed nodes
    previous_sibling: ?*Node,

    /// Next sibling of added/removed nodes
    next_sibling: ?*Node,

    /// Attribute name (for attributes mutations)
    attribute_name: ?[]const u8,

    /// Attribute namespace (for attributes mutations)
    attribute_namespace: ?[]const u8,

    /// Old value before mutation (if requested)
    old_value: ?[]const u8,

    /// Allocator for cleanup
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Type of mutation
    pub const MutationType = enum {
        attributes,
        character_data,
        child_list,

        pub fn toString(self: MutationType) []const u8 {
            return switch (self) {
                .attributes => "attributes",
                .character_data => "characterData",
                .child_list => "childList",
            };
        }
    };

    /// Initialize a MutationRecord
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `mutation_type`: Type of mutation
    /// - `target`: Node that was mutated
    ///
    /// ## Returns
    ///
    /// A new MutationRecord instance.
    pub fn init(
        allocator: std.mem.Allocator,
        mutation_type: MutationType,
        target: *Node,
    ) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        self.* = .{
            .type = mutation_type,
            .target = target,
            .added_nodes = NodeList.init(allocator),
            .removed_nodes = NodeList.init(allocator),
            .previous_sibling = null,
            .next_sibling = null,
            .attribute_name = null,
            .attribute_namespace = null,
            .old_value = null,
            .allocator = allocator,
        };

        return self;
    }

    /// Set added nodes for childList mutation
    ///
    /// ## Parameters
    ///
    /// - `nodes`: Array of nodes that were added
    pub fn setAddedNodes(self: *Self, nodes: []const *Node) !void {
        for (nodes) |node| {
            try self.added_nodes.append(node);
        }
    }

    /// Set removed nodes for childList mutation
    ///
    /// ## Parameters
    ///
    /// - `nodes`: Array of nodes that were removed
    pub fn setRemovedNodes(self: *Self, nodes: []const *Node) !void {
        for (nodes) |node| {
            try self.removed_nodes.append(node);
        }
    }

    /// Set attribute information
    ///
    /// ## Parameters
    ///
    /// - `name`: Attribute local name
    /// - `namespace`: Attribute namespace (optional)
    pub fn setAttributeInfo(self: *Self, name: []const u8, namespace: ?[]const u8) !void {
        self.attribute_name = try self.allocator.dupe(u8, name);
        if (namespace) |ns| {
            self.attribute_namespace = try self.allocator.dupe(u8, ns);
        }
    }

    /// Set old value
    ///
    /// ## Parameters
    ///
    /// - `value`: The old value before mutation
    pub fn setOldValue(self: *Self, value: ?[]const u8) !void {
        if (value) |v| {
            self.old_value = try self.allocator.dupe(u8, v);
        }
    }

    /// Clean up the mutation record
    pub fn deinit(self: *Self) void {
        self.added_nodes.deinit();
        self.removed_nodes.deinit();

        if (self.attribute_name) |name| {
            self.allocator.free(name);
        }
        if (self.attribute_namespace) |ns| {
            self.allocator.free(ns);
        }
        if (self.old_value) |value| {
            self.allocator.free(value);
        }

        self.allocator.destroy(self);
    }

    /// Get the type as a string
    pub fn getTypeString(self: *const Self) []const u8 {
        return self.type.toString();
    }
};

// Tests
test "MutationRecord creation" {
    const allocator = std.testing.allocator;

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    const record = try MutationRecord.init(allocator, .child_list, target);
    defer record.deinit();

    try std.testing.expectEqual(MutationRecord.MutationType.child_list, record.type);
    try std.testing.expectEqual(target, record.target);
    try std.testing.expectEqual(@as(usize, 0), record.added_nodes.length());
    try std.testing.expectEqual(@as(usize, 0), record.removed_nodes.length());
}

test "MutationRecord childList mutation" {
    const allocator = std.testing.allocator;

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    const added1 = try Node.init(allocator, .element_node, "span");
    defer added1.release();

    const added2 = try Node.init(allocator, .text_node, "text");
    defer added2.release();

    const record = try MutationRecord.init(allocator, .child_list, target);
    defer record.deinit();

    try record.setAddedNodes(&[_]*Node{ added1, added2 });

    try std.testing.expectEqual(@as(usize, 2), record.added_nodes.length());
    try std.testing.expectEqualStrings("childList", record.getTypeString());
}

test "MutationRecord attributes mutation" {
    const allocator = std.testing.allocator;

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    const record = try MutationRecord.init(allocator, .attributes, target);
    defer record.deinit();

    try record.setAttributeInfo("class", null);
    try record.setOldValue("old-class");

    try std.testing.expectEqualStrings("class", record.attribute_name.?);
    try std.testing.expect(record.attribute_namespace == null);
    try std.testing.expectEqualStrings("old-class", record.old_value.?);
    try std.testing.expectEqualStrings("attributes", record.getTypeString());
}

test "MutationRecord characterData mutation" {
    const allocator = std.testing.allocator;

    const target = try Node.init(allocator, .text_node, "new text");
    defer target.release();

    const record = try MutationRecord.init(allocator, .character_data, target);
    defer record.deinit();

    try record.setOldValue("old text");

    try std.testing.expectEqualStrings("old text", record.old_value.?);
    try std.testing.expectEqualStrings("characterData", record.getTypeString());
}

test "MutationRecord with siblings" {
    const allocator = std.testing.allocator;

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    const prev = try Node.init(allocator, .element_node, "prev");
    defer prev.release();

    const next = try Node.init(allocator, .element_node, "next");
    defer next.release();

    const record = try MutationRecord.init(allocator, .child_list, target);
    defer record.deinit();

    record.previous_sibling = prev;
    record.next_sibling = next;

    try std.testing.expectEqual(prev, record.previous_sibling.?);
    try std.testing.expectEqual(next, record.next_sibling.?);
}

test "MutationRecord memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const target = try Node.init(allocator, .element_node, "div");
        defer target.release();

        const record = try MutationRecord.init(allocator, .attributes, target);
        try record.setAttributeInfo("id", "http://example.com");
        try record.setOldValue("old-id");
        record.deinit();
    }
}
