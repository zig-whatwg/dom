// WPT Test: CharacterData-substringData.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/CharacterData-substringData.html
//
// Tests CharacterData.substringData() behavior as specified in WHATWG DOM Standard § 4.10
// https://dom.spec.whatwg.org/#dom-characterdata-substringdata

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;
const Comment = dom.Comment;

test "Text.substringData() with invalid offset" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try std.testing.expectError(error.IndexOutOfBounds, node.substringData(allocator, 5, 0));
    try std.testing.expectError(error.IndexOutOfBounds, node.substringData(allocator, 6, 0));
}

test "Text.substringData() with in-bounds offset" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    {
        const result = try node.substringData(allocator, 0, 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("t", result);
    }
    {
        const result = try node.substringData(allocator, 1, 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("e", result);
    }
    {
        const result = try node.substringData(allocator, 2, 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("s", result);
    }
    {
        const result = try node.substringData(allocator, 3, 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("t", result);
    }
    {
        const result = try node.substringData(allocator, 4, 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("", result);
    }
}

test "Text.substringData() with zero count" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    {
        const result = try node.substringData(allocator, 0, 0);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("", result);
    }
    {
        const result = try node.substringData(allocator, 2, 0);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("", result);
    }
}

test "Text.substringData() with in-bounds count" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    {
        const result = try node.substringData(allocator, 0, 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("t", result);
    }
    {
        const result = try node.substringData(allocator, 0, 2);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("te", result);
    }
    {
        const result = try node.substringData(allocator, 0, 3);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("tes", result);
    }
    {
        const result = try node.substringData(allocator, 0, 4);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("test", result);
    }
}

test "Text.substringData() with large count" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    {
        const result = try node.substringData(allocator, 0, 5);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("test", result);
    }
    {
        const result = try node.substringData(allocator, 2, 20);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("st", result);
    }
}

test "Comment.substringData() with invalid offset" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqualStrings("test", node.data);

    try std.testing.expectError(error.IndexOutOfBounds, node.substringData(allocator, 5, 0));
}

test "Comment.substringData() with in-bounds offset" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    {
        const result = try node.substringData(allocator, 0, 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("t", result);
    }
    {
        const result = try node.substringData(allocator, 1, 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("e", result);
    }
}
