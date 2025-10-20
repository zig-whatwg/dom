// META: title=Node.ownerDocument for various node types

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expectEqual(&doc.prototype, elem.prototype.owner_document.?);
}

test "Text.ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    try std.testing.expectEqual(&doc.prototype, text.prototype.owner_document.?);
}

test "Comment.ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("comment");
    defer comment.prototype.release();

    try std.testing.expectEqual(&doc.prototype, comment.prototype.owner_document.?);
}

test "DocumentFragment.ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expectEqual(&doc.prototype, frag.prototype.owner_document.?);
}

test "ProcessingInstruction.ownerDocument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqual(&doc.prototype, pi.prototype.prototype.owner_document.?);
}

test "Document.ownerDocument is self-referential" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Document's owner_document points to itself per our implementation
    try std.testing.expectEqual(&doc.prototype, doc.prototype.owner_document.?);
}
