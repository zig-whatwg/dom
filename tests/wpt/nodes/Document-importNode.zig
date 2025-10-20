// META: title=Document.importNode
// META: link=https://dom.spec.whatwg.org/#dom-document-importnode

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "importNode shallow (deep = false)" {
    const allocator = std.testing.allocator;
    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const div = try doc1.createElement("container");
    defer div.prototype.release();

    const span = try doc1.createElement("item");
    _ = try div.prototype.appendChild(&span.prototype);

    // Import shallow (don't copy children)
    const imported = try doc2.importNode(&div.prototype, false);
    defer imported.release();

    try std.testing.expect(imported.owner_document == &doc2.prototype);
    try std.testing.expect(imported.first_child == null);
    try std.testing.expect(div.prototype.owner_document == &doc1.prototype);
}

test "importNode deep (deep = true)" {
    const allocator = std.testing.allocator;
    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const div = try doc1.createElement("container");
    defer div.prototype.release();

    const span = try doc1.createElement("item");
    _ = try div.prototype.appendChild(&span.prototype);

    // Import deep (copy children)
    const imported = try doc2.importNode(&div.prototype, true);
    defer imported.release();

    try std.testing.expect(imported.owner_document == &doc2.prototype);
    try std.testing.expect(imported.first_child != null);
    try std.testing.expect(imported.first_child.?.owner_document == &doc2.prototype);
    try std.testing.expect(div.prototype.owner_document == &doc1.prototype);
}

test "importNode text node" {
    const allocator = std.testing.allocator;
    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const text = try doc1.createTextNode("test");
    defer text.prototype.release();

    const imported = try doc2.importNode(&text.prototype, false);
    defer imported.release();

    try std.testing.expect(imported.owner_document == &doc2.prototype);
}

test "importNode comment node" {
    const allocator = std.testing.allocator;
    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const comment = try doc1.createComment("test comment");
    defer comment.prototype.release();

    const imported = try doc2.importNode(&comment.prototype, false);
    defer imported.release();

    try std.testing.expect(imported.owner_document == &doc2.prototype);
}
