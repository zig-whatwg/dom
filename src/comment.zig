//! Comment node implementation - represents comments in the DOM tree.
//!
//! This module implements the WHATWG DOM Comment interface with:
//! - Mutable comment text storage
//! - Character data manipulation methods (inherited pattern from Text)
//! - Vtable implementation for polymorphic Node behavior
//!
//! Spec: WHATWG DOM §4.8 (https://dom.spec.whatwg.org/#interface-comment)

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;

/// Comment node representing HTML/XML comments in the DOM.
///
/// Comment nodes store mutable string content and provide methods for
/// character data manipulation, similar to Text nodes.
///
/// ## Memory Layout
/// - Embeds Node as first field (for vtable polymorphism)
/// - Stores comment data as owned string (allocated)
/// - Comment content can be modified via nodeValue or data accessors
pub const Comment = struct {
    /// Base Node (MUST be first field for @fieldParentPtr to work)
    node: Node,

    /// Comment content (owned string, 16 bytes)
    /// Allocated and freed by this Comment node
    data: []u8,

    /// Vtable for Comment nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
    };

    /// Creates a new Comment node with the specified content.
    ///
    /// ## Memory Management
    /// Returns Comment with ref_count=1. Caller MUST call `comment.node.release()`.
    /// Comment content is duplicated and owned by the Comment node.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    /// - `content`: Initial comment content (will be duplicated)
    ///
    /// ## Returns
    /// New comment node with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const comment = try Comment.create(allocator, " TODO: implement this ");
    /// defer comment.node.release();
    /// ```
    pub fn create(allocator: Allocator, content: []const u8) !*Comment {
        const comment = try allocator.create(Comment);
        errdefer allocator.destroy(comment);

        // Duplicate comment content (owned by this node)
        const data = try allocator.dupe(u8, content);
        errdefer allocator.free(data);

        // Initialize base Node
        comment.node = .{
            .vtable = &vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .comment,
            .flags = 0,
            .node_id = 0,
            .generation = 0,
            .allocator = allocator,
            .parent_node = null,
            .previous_sibling = null,
            .first_child = null,
            .last_child = null,
            .next_sibling = null,
            .owner_document = null,
            .rare_data = null,
        };

        // Initialize Comment-specific fields
        comment.data = data;

        return comment;
    }

    /// Returns the comment content length in bytes.
    pub fn length(self: *const Comment) usize {
        return self.data.len;
    }

    /// Returns a substring of the comment content.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for substring
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes (or null for rest of string)
    ///
    /// ## Returns
    /// Owned string slice. Caller must free with allocator.
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate substring
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn substringData(
        self: *const Comment,
        allocator: Allocator,
        offset: usize,
        count: ?usize,
    ) ![]u8 {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = if (count) |c|
            @min(offset + c, self.data.len)
        else
            self.data.len;

        return allocator.dupe(u8, self.data[offset..end]);
    }

    /// Appends text to the end of the comment.
    ///
    /// ## Parameters
    /// - `text_to_append`: Text to append
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    pub fn appendData(self: *Comment, text_to_append: []const u8) !void {
        const new_data = try std.mem.concat(
            self.node.allocator,
            u8,
            &[_][]const u8{ self.data, text_to_append },
        );

        self.node.allocator.free(self.data);
        self.data = new_data;
        self.node.generation += 1;
    }

    /// Inserts text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Byte offset where to insert
    /// - `text_to_insert`: Text to insert
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn insertData(self: *Comment, offset: usize, text_to_insert: []const u8) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const new_data = try std.mem.concat(
            self.node.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], text_to_insert, self.data[offset..] },
        );

        self.node.allocator.free(self.data);
        self.data = new_data;
        self.node.generation += 1;
    }

    /// Deletes text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes to delete
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn deleteData(self: *Comment, offset: usize, count: usize) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = @min(offset + count, self.data.len);

        const new_data = try std.mem.concat(
            self.node.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], self.data[end..] },
        );

        self.node.allocator.free(self.data);
        self.data = new_data;
        self.node.generation += 1;
    }

    /// Replaces text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes to replace
    /// - `replacement`: Replacement text
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn replaceData(
        self: *Comment,
        offset: usize,
        count: usize,
        replacement: []const u8,
    ) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = @min(offset + count, self.data.len);

        const new_data = try std.mem.concat(
            self.node.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], replacement, self.data[end..] },
        );

        self.node.allocator.free(self.data);
        self.data = new_data;
        self.node.generation += 1;
    }

    // === Private vtable implementations ===

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const comment: *Comment = @fieldParentPtr("node", node);

        // Release document reference if owned by a document
        if (comment.node.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                // Get Document from its node field (node is first field)
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("node", owner_doc);
                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        comment.node.deinitRareData();

        comment.node.allocator.free(comment.data);
        comment.node.allocator.destroy(comment);
    }

    /// Vtable implementation: node name (always "#comment")
    fn nodeNameImpl(_: *const Node) []const u8 {
        return "#comment";
    }

    /// Vtable implementation: node value (returns comment content)
    fn nodeValueImpl(node: *const Node) ?[]const u8 {
        const comment: *const Comment = @fieldParentPtr("node", node);
        return comment.data;
    }

    /// Vtable implementation: set node value (updates comment content)
    fn setNodeValueImpl(node: *Node, value: []const u8) !void {
        const comment: *Comment = @fieldParentPtr("node", node);

        // Allocate new content
        const new_data = try node.allocator.dupe(u8, value);

        // Free old and replace
        node.allocator.free(comment.data);
        comment.data = new_data;
        node.generation += 1;
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        const comment: *const Comment = @fieldParentPtr("node", node);

        // Comment nodes have no children, so deep is ignored
        _ = deep;

        // Create new comment with same content
        const cloned = try Comment.create(node.allocator, comment.data);
        return &cloned.node;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "Comment - creation and cleanup" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " TODO: implement ");
    defer comment.node.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.comment, comment.node.node_type);
    try std.testing.expectEqual(@as(u32, 1), comment.node.getRefCount());
    try std.testing.expectEqualStrings(" TODO: implement ", comment.data);
    try std.testing.expectEqual(@as(usize, 17), comment.length());

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("#comment", comment.node.nodeName());
    try std.testing.expectEqualStrings(" TODO: implement ", comment.node.nodeValue().?);
}

test "Comment - empty content" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, "");
    defer comment.node.release();

    try std.testing.expectEqual(@as(usize, 0), comment.length());
    try std.testing.expectEqualStrings("", comment.data);
}

test "Comment - set node value" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " original ");
    defer comment.node.release();

    try std.testing.expectEqualStrings(" original ", comment.data);

    // Change via nodeValue setter
    try comment.node.setNodeValue(" updated ");
    try std.testing.expectEqualStrings(" updated ", comment.data);

    // Verify generation incremented
    try std.testing.expect(comment.node.generation > 0);
}

test "Comment - character data operations" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " TODO");
    defer comment.node.release();

    // Append
    try comment.appendData(" fix this");
    try std.testing.expectEqualStrings(" TODO fix this", comment.data);

    // Insert
    try comment.insertData(5, ":");
    try std.testing.expectEqualStrings(" TODO: fix this", comment.data);
    // Now: " TODO: fix this" (15 chars)
    //      0123456789...

    // Replace " fix this" (9 chars starting at pos 6) with " done!"
    try comment.replaceData(6, 9, " done!");
    try std.testing.expectEqualStrings(" TODO: done!", comment.data);
    // Now: " TODO: done!" (12 chars)

    // Delete " done" (5 chars starting at pos 6)
    try comment.deleteData(6, 5);
    try std.testing.expectEqualStrings(" TODO:!", comment.data);
}

test "Comment - substringData" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " Hello World ");
    defer comment.node.release();

    // Substring with count
    {
        const sub = try comment.substringData(allocator, 1, 5);
        defer allocator.free(sub);
        try std.testing.expectEqualStrings("Hello", sub);
    }

    // Substring to end
    {
        const sub = try comment.substringData(allocator, 7, null);
        defer allocator.free(sub);
        try std.testing.expectEqualStrings("World ", sub);
    }

    // Out of bounds
    try std.testing.expectError(
        error.IndexOutOfBounds,
        comment.substringData(allocator, 100, 1),
    );
}

test "Comment - cloneNode" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " Original comment ");
    defer comment.node.release();

    // Clone
    const cloned_node = try comment.node.cloneNode(false);
    defer cloned_node.release();

    const cloned: *Comment = @fieldParentPtr("node", cloned_node);

    // Verify clone properties
    try std.testing.expectEqualStrings(" Original comment ", cloned.data);
    try std.testing.expectEqual(@as(u32, 1), cloned.node.getRefCount());

    // Verify independence
    try comment.appendData("!");
    try std.testing.expectEqualStrings(" Original comment !", comment.data);
    try std.testing.expectEqualStrings(" Original comment ", cloned.data); // Unchanged
}

test "Comment - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple creation
    {
        const comment = try Comment.create(allocator, " test ");
        defer comment.node.release();
    }

    // Test 2: Modifications
    {
        const comment = try Comment.create(allocator, " test ");
        defer comment.node.release();

        try comment.appendData("more");
        try comment.insertData(0, "prefix ");
        try comment.deleteData(0, 7);
        try comment.replaceData(0, 4, "TEST");
        try comment.node.setNodeValue(" final ");
    }

    // Test 3: Clone
    {
        const comment = try Comment.create(allocator, " original ");
        defer comment.node.release();

        const cloned = try comment.node.cloneNode(false);
        defer cloned.release();
    }

    // Test 4: Multiple acquire/release
    {
        const comment = try Comment.create(allocator, " test ");
        defer comment.node.release();

        comment.node.acquire();
        defer comment.node.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Comment - ref counting" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " test ");
    defer comment.node.release();

    // Initial ref count
    try std.testing.expectEqual(@as(u32, 1), comment.node.getRefCount());

    // Acquire
    comment.node.acquire();
    try std.testing.expectEqual(@as(u32, 2), comment.node.getRefCount());

    // Release
    comment.node.release();
    try std.testing.expectEqual(@as(u32, 1), comment.node.getRefCount());
}
