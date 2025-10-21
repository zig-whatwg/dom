// META: title=Element.localName with namespace
// META: link=https://dom.spec.whatwg.org/#dom-element-localname

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.localName for element without namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("test", elem.localName());
}

test "Element.localName for namespaced element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://example.com/ns", "test");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("test", elem.localName());
}

test "Element.localName for prefixed element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://example.com/ns", "prefix:localName");
    defer elem.prototype.release();

    // localName should be just the part after the colon
    try std.testing.expectEqualStrings("localName", elem.localName());
}

test "Element.localName preserves case in generic DOM" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("TEST");
    defer elem.prototype.release();

    // Generic DOM preserves case (unlike HTML documents)
    // HTML-specific case normalization would require HTML document type
    try std.testing.expectEqualStrings("TEST", elem.localName());
}
