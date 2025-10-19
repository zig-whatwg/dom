// WPT Test: Node-nodeValue
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Node-nodeValue.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

test "Text.nodeValue" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const the_text = try doc.createTextNode("A span!");
    defer the_text.prototype.release();

    try std.testing.expectEqualStrings("A span!", the_text.prototype.nodeValue().?);
    try std.testing.expectEqualStrings("A span!", the_text.data);

    try the_text.prototype.setNodeValue("test again");
    try std.testing.expectEqualStrings("test again", the_text.prototype.nodeValue().?);
    try std.testing.expectEqualStrings("test again", the_text.data);

    try the_text.prototype.setNodeValue("");
    try std.testing.expectEqualStrings("", the_text.prototype.nodeValue().?);
    try std.testing.expectEqualStrings("", the_text.data);
}

test "Comment.nodeValue" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const the_comment = try doc.createComment("A comment!");
    defer the_comment.prototype.release();

    try std.testing.expectEqualStrings("A comment!", the_comment.prototype.nodeValue().?);
    try std.testing.expectEqualStrings("A comment!", the_comment.data);

    try the_comment.prototype.setNodeValue("test again");
    try std.testing.expectEqualStrings("test again", the_comment.prototype.nodeValue().?);
    try std.testing.expectEqualStrings("test again", the_comment.data);

    try the_comment.prototype.setNodeValue("");
    try std.testing.expectEqualStrings("", the_comment.prototype.nodeValue().?);
    try std.testing.expectEqualStrings("", the_comment.data);
}

// Note: ProcessingInstruction not implemented in generic DOM library

test "Element.nodeValue" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const the_link = try doc.createElement("a");
    defer the_link.prototype.release();

    try std.testing.expect(the_link.prototype.nodeValue() == null);

    try the_link.prototype.setNodeValue("foo");
    try std.testing.expect(the_link.prototype.nodeValue() == null);
}

test "Document.nodeValue" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    try std.testing.expect(doc.prototype.nodeValue() == null);

    try doc.prototype.setNodeValue("foo");
    try std.testing.expect(doc.prototype.nodeValue() == null);
}

test "DocumentFragment.nodeValue" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const the_frag = try doc.createDocumentFragment();
    defer the_frag.prototype.release();

    try std.testing.expect(the_frag.prototype.nodeValue() == null);

    try the_frag.prototype.setNodeValue("foo");
    try std.testing.expect(the_frag.prototype.nodeValue() == null);
}
