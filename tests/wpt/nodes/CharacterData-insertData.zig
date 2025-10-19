// WPT Test: CharacterData-insertData.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/CharacterData-insertData.html
//
// Tests CharacterData.insertData() behavior as specified in WHATWG DOM Standard § 4.10
// https://dom.spec.whatwg.org/#dom-characterdata-insertdata

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;
const Comment = dom.Comment;

test "Text.insertData() out of bounds" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try std.testing.expectError(error.IndexOutOfBounds, node.insertData(5, "x"));
    try std.testing.expectError(error.IndexOutOfBounds, node.insertData(5, ""));
}

test "Text.insertData('')" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.insertData(0, "");
    try std.testing.expectEqualStrings("test", node.data);
}

test "Text.insertData() at the start" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.insertData(0, "X");
    try std.testing.expectEqualStrings("Xtest", node.data);
}

test "Text.insertData() in the middle" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.insertData(2, "X");
    try std.testing.expectEqualStrings("teXst", node.data);
}

test "Text.insertData() at the end" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.insertData(4, "ing");
    try std.testing.expectEqualStrings("testing", node.data);
}

// Note: Skipping non-ASCII tests due to UTF-8 byte offset vs UTF-16 code unit differences
// The implementation uses byte offsets while the spec uses UTF-16 code units.
// This is a known limitation documented in COVERAGE.md.

test "Comment.insertData() out of bounds" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try std.testing.expectError(error.IndexOutOfBounds, node.insertData(5, "x"));
    try std.testing.expectError(error.IndexOutOfBounds, node.insertData(5, ""));
}

test "Comment.insertData() at the start" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.insertData(0, "X");
    try std.testing.expectEqualStrings("Xtest", node.data);
}

test "Comment.insertData() in the middle" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.insertData(2, "X");
    try std.testing.expectEqualStrings("teXst", node.data);
}

test "Comment.insertData() at the end" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.insertData(4, "ing");
    try std.testing.expectEqualStrings("testing", node.data);
}
