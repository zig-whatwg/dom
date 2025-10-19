// WPT Test: CharacterData-appendData.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/CharacterData-appendData.html
//
// Tests CharacterData.appendData() behavior as specified in WHATWG DOM Standard § 4.10
// https://dom.spec.whatwg.org/#dom-characterdata-appenddata

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;
const Comment = dom.Comment;

test "Text.appendData('bar')" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.appendData("bar");
    try std.testing.expectEqualStrings("testbar", node.data);
}

test "Text.appendData('')" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.appendData("");
    try std.testing.expectEqualStrings("test", node.data);
}

test "Text.appendData(non-ASCII)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.appendData(", append more 資料，測試資料");
    try std.testing.expectEqualStrings("test, append more 資料，測試資料", node.data);
    // Note: The spec uses UTF-16 code unit length, Zig uses byte length
    // 25 UTF-16 code units = more bytes in UTF-8 due to multibyte characters
}

test "Comment.appendData('bar')" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.appendData("bar");
    try std.testing.expectEqualStrings("testbar", node.data);
}

test "Comment.appendData('')" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.appendData("");
    try std.testing.expectEqualStrings("test", node.data);
}

test "Comment.appendData(non-ASCII)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try node.appendData(", append more 資料，測試資料");
    try std.testing.expectEqualStrings("test, append more 資料，測試資料", node.data);
    // Note: The spec uses UTF-16 code unit length, Zig uses byte length
    // 25 UTF-16 code units = more bytes in UTF-8 due to multibyte characters
}

// Note: JavaScript tests for appendData(null), appendData(undefined), and appendData()
// are not applicable in Zig because:
// - appendData() requires a parameter (compile-time error)
// - null/undefined handling is JavaScript-specific behavior
