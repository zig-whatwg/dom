// WPT Test: CharacterData-replaceData.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/CharacterData-replaceData.html
//
// Tests CharacterData.replaceData() behavior as specified in WHATWG DOM Standard § 4.10
// https://dom.spec.whatwg.org/#dom-characterdata-replacedata

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;
const Comment = dom.Comment;

test "Text.replaceData() with invalid offset" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try std.testing.expectError(error.IndexOutOfBounds, node.replaceData(5, 1, "x"));
    try std.testing.expectError(error.IndexOutOfBounds, node.replaceData(5, 0, ""));
    try std.testing.expectEqualStrings("test", node.data);
}

test "Text.replaceData() with clamped count" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(2, 10, "yo");
    try std.testing.expectEqualStrings("teyo", node.data);
}

test "Text.replaceData() before the start" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(0, 0, "yo");
    try std.testing.expectEqualStrings("yotest", node.data);
}

test "Text.replaceData() at the start (shorter)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(0, 2, "y");
    try std.testing.expectEqualStrings("yst", node.data);
}

test "Text.replaceData() at the start (equal length)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(0, 2, "yo");
    try std.testing.expectEqualStrings("yost", node.data);
}

test "Text.replaceData() at the start (longer)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(0, 2, "yoa");
    try std.testing.expectEqualStrings("yoast", node.data);
}

test "Text.replaceData() in the middle (shorter)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(1, 2, "o");
    try std.testing.expectEqualStrings("tot", node.data);
}

test "Text.replaceData() in the middle (equal length)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(1, 2, "yo");
    try std.testing.expectEqualStrings("tyot", node.data);
}

test "Text.replaceData() in the middle (longer)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(1, 1, "waddup");
    try std.testing.expectEqualStrings("twaddupst", node.data);

    try node.replaceData(1, 1, "yup");
    try std.testing.expectEqualStrings("tyupaddupst", node.data);
}

test "Text.replaceData() at the end (shorter)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(1, 20, "yo");
    try std.testing.expectEqualStrings("tyo", node.data);
}

test "Text.replaceData() at the end (same length)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(2, 20, "yo");
    try std.testing.expectEqualStrings("teyo", node.data);
}

test "Text.replaceData() at the end (longer)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(4, 20, "yo");
    try std.testing.expectEqualStrings("testyo", node.data);
}

test "Comment.replaceData() with invalid offset" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try std.testing.expectError(error.IndexOutOfBounds, node.replaceData(5, 1, "x"));
}

test "Comment.replaceData() at the start" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(0, 2, "yo");
    try std.testing.expectEqualStrings("yost", node.data);
}

test "Comment.replaceData() in the middle" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.replaceData(1, 2, "yo");
    try std.testing.expectEqualStrings("tyot", node.data);
}
