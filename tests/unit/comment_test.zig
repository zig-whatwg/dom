const std = @import("std");
const dom = @import("dom");

// Import all commonly used types
const Node = dom.Node;
const NodeType = dom.NodeType;
const NodeVTable = dom.NodeVTable;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;
const ShadowRoot = dom.ShadowRoot;

test "Comment - creation and cleanup" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " TODO: implement ");
    defer comment.prototype.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.comment, comment.prototype.node_type);
    try std.testing.expectEqual(@as(u32, 1), comment.prototype.getRefCount());
    try std.testing.expectEqualStrings(" TODO: implement ", comment.data);
    try std.testing.expectEqual(@as(usize, 17), comment.length());

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("#comment", comment.prototype.nodeName());
    try std.testing.expectEqualStrings(" TODO: implement ", comment.prototype.nodeValue().?);
}

test "Comment - empty content" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, "");
    defer comment.prototype.release();

    try std.testing.expectEqual(@as(usize, 0), comment.length());
    try std.testing.expectEqualStrings("", comment.data);
}

test "Comment - set node value" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " original ");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings(" original ", comment.data);

    // Change via nodeValue setter
    try comment.prototype.setNodeValue(" updated ");
    try std.testing.expectEqualStrings(" updated ", comment.data);

    // Verify generation incremented
    try std.testing.expect(comment.prototype.generation > 0);
}

test "Comment - character data operations" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " TODO");
    defer comment.prototype.release();

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
    defer comment.prototype.release();

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
    defer comment.prototype.release();

    // Clone
    const cloned_node = try comment.prototype.cloneNode(false);
    defer cloned_node.release();

    const cloned: *Comment = @fieldParentPtr("prototype", cloned_node);

    // Verify clone properties
    try std.testing.expectEqualStrings(" Original comment ", cloned.data);
    try std.testing.expectEqual(@as(u32, 1), cloned.prototype.getRefCount());

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
        defer comment.prototype.release();
    }

    // Test 2: Modifications
    {
        const comment = try Comment.create(allocator, " test ");
        defer comment.prototype.release();

        try comment.appendData("more");
        try comment.insertData(0, "prefix ");
        try comment.deleteData(0, 7);
        try comment.replaceData(0, 4, "TEST");
        try comment.prototype.setNodeValue(" final ");
    }

    // Test 3: Clone
    {
        const comment = try Comment.create(allocator, " original ");
        defer comment.prototype.release();

        const cloned = try comment.prototype.cloneNode(false);
        defer cloned.release();
    }

    // Test 4: Multiple acquire/release
    {
        const comment = try Comment.create(allocator, " test ");
        defer comment.prototype.release();

        comment.prototype.acquire();
        defer comment.prototype.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Comment - ref counting" {
    const allocator = std.testing.allocator;

    const comment = try Comment.create(allocator, " test ");
    defer comment.prototype.release();

    // Initial ref count
    try std.testing.expectEqual(@as(u32, 1), comment.prototype.getRefCount());

    // Acquire
    comment.prototype.acquire();
    try std.testing.expectEqual(@as(u32, 2), comment.prototype.getRefCount());

    // Release
    comment.prototype.release();
    try std.testing.expectEqual(@as(u32, 1), comment.prototype.getRefCount());
}

