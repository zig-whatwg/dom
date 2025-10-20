// META: title=Comment.data property

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Comment.data returns the comment text" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("test comment", comment.data);
}

test "Comment.data with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("", comment.data);
}

test "Comment.data modification via setNodeValue" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("original");
    defer comment.prototype.release();

    try comment.prototype.setNodeValue("modified");

    try std.testing.expectEqualStrings("modified", comment.data);
}
