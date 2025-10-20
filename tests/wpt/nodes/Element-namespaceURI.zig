// META: title=Element.namespaceURI

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.namespaceURI null for non-namespaced" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    try std.testing.expect(elem.namespace_uri == null);
}

test "Element.namespaceURI for namespaced elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://www.w3.org/2000/svg", "circle");
    defer elem.prototype.release();

    try std.testing.expect(elem.namespace_uri != null);
    try std.testing.expectEqualStrings("http://www.w3.org/2000/svg", elem.namespace_uri.?);
}

test "Element.namespaceURI with prefix" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://example.com/ns", "pre:item");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("http://example.com/ns", elem.namespace_uri.?);
    try std.testing.expectEqualStrings("pre", elem.prefix.?);
    try std.testing.expectEqualStrings("item", elem.local_name);
}
