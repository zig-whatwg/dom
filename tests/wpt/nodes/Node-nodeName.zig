// WPT Test: Node-nodeName
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Node-nodeName.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

test "For Element nodes, nodeName should return the same as tagName" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    // Note: Generic DOM library doesn't support HTML namespace case normalization
    // HTML elements in our implementation use lowercase tag names
    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("div", elem.prototype.nodeName());

    // Test uppercase
    const elem2 = try doc.createElement("DIV");
    defer elem2.prototype.release();

    try std.testing.expectEqualStrings("DIV", elem2.prototype.nodeName());
}

test "For Text nodes, nodeName should return #text" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("foo");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("#text", text.prototype.nodeName());
}

test "For Comment nodes, nodeName should return #comment" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("foo");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("#comment", comment.prototype.nodeName());
}

test "For Document nodes, nodeName should return #document" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    try std.testing.expectEqualStrings("#document", doc.prototype.nodeName());
}

test "For DocumentFragment nodes, nodeName should return #document-fragment" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expectEqualStrings("#document-fragment", frag.prototype.nodeName());
}
