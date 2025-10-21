// META: title=Element.removeAttributeNS
// META: link=https://dom.spec.whatwg.org/#dom-element-removeattributens

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.removeAttributeNS removes namespaced attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns", "attr", "value");
    try std.testing.expect(elem.hasAttributeNS("http://example.com/ns", "attr"));

    elem.removeAttributeNS("http://example.com/ns", "attr");
    try std.testing.expect(!elem.hasAttributeNS("http://example.com/ns", "attr"));
}

test "Element.removeAttributeNS does nothing when attribute not present" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    // Should not error
    elem.removeAttributeNS("http://example.com/ns", "attr");
}

test "Element.removeAttributeNS distinguishes by namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns1", "attr", "value1");
    try elem.setAttributeNS("http://example.com/ns2", "attr", "value2");

    elem.removeAttributeNS("http://example.com/ns1", "attr");

    try std.testing.expect(!elem.hasAttributeNS("http://example.com/ns1", "attr"));
    try std.testing.expect(elem.hasAttributeNS("http://example.com/ns2", "attr"));
}

test "Element.removeAttributeNS with null namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttribute("attr", "value");
    elem.removeAttributeNS(null, "attr");

    try std.testing.expect(!elem.hasAttribute("attr"));
}
