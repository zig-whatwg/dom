// META: title=Document.createElementNS
// META: link=https://dom.spec.whatwg.org/#dom-document-createelementns

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.createElementNS creates element with namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://example.com/ns", "elem");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("elem", elem.tag_name);
    try std.testing.expectEqualStrings("http://example.com/ns", elem.namespace_uri.?);
}

test "Document.createElementNS with null namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS(null, "elem");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("elem", elem.tag_name);
    try std.testing.expect(elem.namespace_uri == null);
}

test "Document.createElementNS creates different elements with same name but different namespaces" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElementNS("http://example.com/ns1", "elem");
    defer elem1.prototype.release();

    const elem2 = try doc.createElementNS("http://example.com/ns2", "elem");
    defer elem2.prototype.release();

    try std.testing.expectEqualStrings("http://example.com/ns1", elem1.namespace_uri.?);
    try std.testing.expectEqualStrings("http://example.com/ns2", elem2.namespace_uri.?);
}

test "Document.createElementNS sets owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://example.com/ns", "elem");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.owner_document == &doc.prototype);
}
