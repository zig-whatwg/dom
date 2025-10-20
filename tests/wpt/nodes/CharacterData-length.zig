// META: title=CharacterData.length

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Text.length returns data length" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    try std.testing.expectEqual(@as(usize, 11), text.length());
}

test "Text.length with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.prototype.release();

    try std.testing.expectEqual(@as(usize, 0), text.length());
}

test "Comment.length returns data length" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    defer comment.prototype.release();

    try std.testing.expectEqual(@as(usize, 12), comment.data.len);
}

test "Text.length after modification" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("initial");
    defer text.prototype.release();

    try std.testing.expectEqual(@as(usize, 7), text.length());

    try text.appendData(" more");
    try std.testing.expectEqual(@as(usize, 12), text.length());
}
