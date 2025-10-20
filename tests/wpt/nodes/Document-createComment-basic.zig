// META: title=Document.createComment basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.createComment creates comment node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("test comment", comment.data);
}

test "Document.createComment with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("", comment.data);
}

test "Document.createComment with special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("<!-- test -->");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("<!-- test -->", comment.data);
}

test "Document.createComment sets owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test");
    defer comment.prototype.release();

    try std.testing.expectEqual(&doc.prototype, comment.prototype.owner_document.?);
}
