// META: title=Element.prefix

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.prefix is null for non-namespaced elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    try std.testing.expect(elem.prefix == null);
}

test "Element.prefix for namespaced elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://example.com", "pre:item");
    defer elem.prototype.release();

    try std.testing.expect(elem.prefix != null);
    try std.testing.expectEqualStrings("pre", elem.prefix.?);
}

test "Element.localName for namespaced elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://example.com", "pre:item");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("item", elem.local_name);
}
