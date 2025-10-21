// META: title=Document.implementation
// META: link=https://dom.spec.whatwg.org/#dom-document-implementation

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.implementation returns DOMImplementation" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    try std.testing.expect(@TypeOf(impl) == *dom.DOMImplementation);
}

test "Document.implementation is same object for same document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl1 = doc.getImplementation();
    const impl2 = doc.getImplementation();

    // Should be the same instance (same pointer per [SameObject])
    try std.testing.expect(impl1 == impl2);
}

test "Document.implementation from different documents" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const impl1 = doc1.getImplementation();
    const impl2 = doc2.getImplementation();

    // Different documents have different implementations (different pointers)
    try std.testing.expect(impl1 != impl2);
}
