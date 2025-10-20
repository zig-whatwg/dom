// META: title=Comment.data

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Comment.data initial value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("test comment", comment.data);
}

test "Comment.data empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("", comment.data);
}

test "Comment.data can be modified" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("first");
    defer comment.prototype.release();

    try comment.prototype.setNodeValue("second");
    try std.testing.expectEqualStrings("second", comment.data);
}
