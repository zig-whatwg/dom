// META: title=Node.ownerDocument

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.owner_document == &doc.prototype);
}

test "Text ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release();

    try std.testing.expect(text.prototype.owner_document == &doc.prototype);
}

test "Comment ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test");
    defer comment.prototype.release();

    try std.testing.expect(comment.prototype.owner_document == &doc.prototype);
}

test "DocumentFragment ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expect(frag.prototype.owner_document == &doc.prototype);
}
