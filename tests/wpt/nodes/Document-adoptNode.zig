// META: title=Document.adoptNode
// META: link=https://dom.spec.whatwg.org/#dom-document-adoptnode

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.adoptNode adopts element from another document" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const elem = try doc1.createElement("elem");
    try std.testing.expect(elem.prototype.owner_document == &doc1.prototype);

    const adopted = try doc2.adoptNode(&elem.prototype);
    defer adopted.release();

    try std.testing.expect(adopted.owner_document == &doc2.prototype);
}

test "Document.adoptNode returns same node" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const elem = try doc1.createElement("elem");

    const adopted = try doc2.adoptNode(&elem.prototype);
    defer adopted.release();

    try std.testing.expect(adopted == &elem.prototype);
}

test "Document.adoptNode adopts text node" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const text = try doc1.createTextNode("hello");
    try std.testing.expect(text.prototype.owner_document == &doc1.prototype);

    const adopted = try doc2.adoptNode(&text.prototype);
    defer adopted.release();

    try std.testing.expect(adopted.owner_document == &doc2.prototype);
}

test "Document.adoptNode removes node from original parent" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const parent = try doc1.createElement("parent");
    _ = try doc1.prototype.appendChild(&parent.prototype);

    const child = try doc1.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(child.prototype.parent_node == &parent.prototype);

    const adopted = try doc2.adoptNode(&child.prototype);
    defer adopted.release();

    try std.testing.expect(adopted.parent_node == null);
}
