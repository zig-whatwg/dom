// META: title=Document.createDocumentFragment basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.createDocumentFragment creates fragment" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expectEqual(dom.NodeType.document_fragment, frag.prototype.node_type);
}

test "Document.createDocumentFragment is empty initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expect(frag.prototype.first_child == null);
    try std.testing.expect(frag.prototype.last_child == null);
}

test "Document.createDocumentFragment can have children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    const elem = try doc.createElement("child");
    _ = try frag.prototype.appendChild(&elem.prototype);

    try std.testing.expectEqual(&elem.prototype, frag.prototype.first_child.?);
}

test "Document.createDocumentFragment sets owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expectEqual(&doc.prototype, frag.prototype.owner_document.?);
}
