// WPT Test: CharacterData-data
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/CharacterData-data.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

// Text node tests

test "Text.data initial value" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);
    try std.testing.expectEqual(@as(usize, 4), node.data.len);
}

test "Text.data = empty string" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.prototype.setNodeValue("");
    try std.testing.expectEqualStrings("", node.data);
    try std.testing.expectEqual(@as(usize, 0), node.data.len);
}

test "Text.data = --" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try node.prototype.setNodeValue("--");
    try std.testing.expectEqualStrings("--", node.data);
    try std.testing.expectEqual(@as(usize, 2), node.data.len);
}

test "Text.data with unicode" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try node.prototype.setNodeValue("資料");
    try std.testing.expectEqualStrings("資料", node.data);
    // Note: Zig strings are UTF-8 bytes, not UTF-16 code units
    // So length is 6 bytes, not 2 UTF-16 units like in JavaScript
    try std.testing.expectEqual(@as(usize, 6), node.data.len);
}

test "Text.data with emoji" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try node.prototype.setNodeValue("🌠 test 🌠 TEST");
    try std.testing.expectEqualStrings("🌠 test 🌠 TEST", node.data);
    // Note: In UTF-8, this is different from UTF-16 length
}

test "Text.data = new value" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try node.prototype.setNodeValue("new value");
    try std.testing.expectEqualStrings("new value", node.data);
    try std.testing.expectEqual(@as(usize, 9), node.data.len);
}

// Comment node tests

test "Comment.data initial value" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);
    try std.testing.expectEqual(@as(usize, 4), node.data.len);
}

test "Comment.data = empty string" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.prototype.setNodeValue("");
    try std.testing.expectEqualStrings("", node.data);
    try std.testing.expectEqual(@as(usize, 0), node.data.len);
}

test "Comment.data = --" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try node.prototype.setNodeValue("--");
    try std.testing.expectEqualStrings("--", node.data);
    try std.testing.expectEqual(@as(usize, 2), node.data.len);
}

test "Comment.data with unicode" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try node.prototype.setNodeValue("資料");
    try std.testing.expectEqualStrings("資料", node.data);
    try std.testing.expectEqual(@as(usize, 6), node.data.len);
}

test "Comment.data = new value" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try node.prototype.setNodeValue("new value");
    try std.testing.expectEqualStrings("new value", node.data);
    try std.testing.expectEqual(@as(usize, 9), node.data.len);
}
