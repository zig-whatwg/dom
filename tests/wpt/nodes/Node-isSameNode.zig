// WPT Test: Node-isSameNode
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Node-isSameNode.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

test "elements should be compared on reference" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const element1 = try doc.createElement("element");
    defer element1.prototype.release();
    const element2 = try doc.createElement("element");
    defer element2.prototype.release();

    // self-comparison
    try std.testing.expect(element1.prototype.isSameNode(&element1.prototype));

    // same properties but different nodes
    try std.testing.expect(!element1.prototype.isSameNode(&element2.prototype));

    // with null other node
    try std.testing.expect(!element1.prototype.isSameNode(null));
}

test "text nodes should be compared on reference" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("data");
    defer text1.prototype.release();
    const text2 = try doc.createTextNode("data");
    defer text2.prototype.release();

    // self-comparison
    try std.testing.expect(text1.prototype.isSameNode(&text1.prototype));

    // same properties but different nodes
    try std.testing.expect(!text1.prototype.isSameNode(&text2.prototype));

    // with null other node
    try std.testing.expect(!text1.prototype.isSameNode(null));
}

test "comments should be compared on reference" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const comment1 = try doc.createComment("data");
    defer comment1.prototype.release();
    const comment2 = try doc.createComment("data");
    defer comment2.prototype.release();

    // self-comparison
    try std.testing.expect(comment1.prototype.isSameNode(&comment1.prototype));

    // same properties but different nodes
    try std.testing.expect(!comment1.prototype.isSameNode(&comment2.prototype));

    // with null other node
    try std.testing.expect(!comment1.prototype.isSameNode(null));
}

test "document fragments should be compared on reference" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const documentFragment1 = try doc.createDocumentFragment();
    defer documentFragment1.prototype.release();
    const documentFragment2 = try doc.createDocumentFragment();
    defer documentFragment2.prototype.release();

    // self-comparison
    try std.testing.expect(documentFragment1.prototype.isSameNode(&documentFragment1.prototype));

    // same properties but different nodes
    try std.testing.expect(!documentFragment1.prototype.isSameNode(&documentFragment2.prototype));

    // with null other node
    try std.testing.expect(!documentFragment1.prototype.isSameNode(null));
}

test "documents should be compared on reference" {
    const allocator = std.testing.allocator;

    const document1 = try dom.Document.init(allocator);
    defer document1.release();

    const document2 = try dom.Document.init(allocator);
    defer document2.release();

    // self-comparison
    try std.testing.expect(document1.prototype.isSameNode(&document1.prototype));

    // another empty document
    try std.testing.expect(!document1.prototype.isSameNode(&document2.prototype));

    // with null other node
    try std.testing.expect(!document1.prototype.isSameNode(null));
}
