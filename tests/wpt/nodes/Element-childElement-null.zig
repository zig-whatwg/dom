// WPT Test: Element-childElement-null.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Element-childElement-null.html
//
// Tests that firstElementChild and lastElementChild return null when no element children exist
// WHATWG DOM Standard § 4.2.6 (ParentNode mixin)
// https://dom.spec.whatwg.org/#dom-parentnode-firstelementchild

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "firstElementChild and lastElementChild return null with no element children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Element with no children
    try std.testing.expectEqual(@as(?*dom.Element, null), parent.firstElementChild());
    try std.testing.expectEqual(@as(?*dom.Element, null), parent.lastElementChild());
}

test "firstElementChild and lastElementChild return null with only text children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add text node (not an element)
    const text = try doc.createTextNode("text content");
    _ = try parent.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(@as(?*dom.Element, null), parent.firstElementChild());
    try std.testing.expectEqual(@as(?*dom.Element, null), parent.lastElementChild());
}

test "firstElementChild and lastElementChild return null with only comment children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add comment node (not an element)
    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    try std.testing.expectEqual(@as(?*dom.Element, null), parent.firstElementChild());
    try std.testing.expectEqual(@as(?*dom.Element, null), parent.lastElementChild());
}
