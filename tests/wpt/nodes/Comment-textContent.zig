// META: title=Comment.textContent
// META: link=https://dom.spec.whatwg.org/#dom-node-textcontent

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Comment.textContent returns comment data" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    defer comment.prototype.release();

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("test comment", content.?);
}

test "Comment.textContent set updates data" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("original");
    defer comment.prototype.release();

    try comment.prototype.setTextContent("updated");

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("updated", content.?);
}

test "Comment.textContent set to empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("original");
    defer comment.prototype.release();

    try comment.prototype.setTextContent("");

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("", content.?);
}
