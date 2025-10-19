// WPT Test: Element-childElementCount-nochild.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Element-childElementCount-nochild.html
//
// Tests childElementCount when no element children exist
// WHATWG DOM Standard § 4.2.6 (ParentNode mixin)
// https://dom.spec.whatwg.org/#dom-parentnode-childelementcount

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "childElementCount is 0 with no children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    try std.testing.expectEqual(@as(u32, 0), parent.childElementCount());
}

test "childElementCount is 0 with only text children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add text node (not an element)
    const text = try doc.createTextNode("text content");
    _ = try parent.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(@as(u32, 0), parent.childElementCount());
}

test "childElementCount is 0 with only comment children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add comment node (not an element)
    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    try std.testing.expectEqual(@as(u32, 0), parent.childElementCount());
}

test "childElementCount is 0 with mixed non-element children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add text and comment
    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    try std.testing.expectEqual(@as(u32, 0), parent.childElementCount());
}
