// META: title=Element.hasAttributeNS
// META: link=https://dom.spec.whatwg.org/#dom-element-hasattributens

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.hasAttributeNS returns false when attribute not present" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try std.testing.expect(!elem.hasAttributeNS("http://example.com/ns", "attr"));
}

test "Element.hasAttributeNS returns true when namespaced attribute present" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns", "attr", "value");

    try std.testing.expect(elem.hasAttributeNS("http://example.com/ns", "attr"));
}

test "Element.hasAttributeNS distinguishes by namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns1", "attr", "value1");
    try elem.setAttributeNS("http://example.com/ns2", "attr", "value2");

    try std.testing.expect(elem.hasAttributeNS("http://example.com/ns1", "attr"));
    try std.testing.expect(elem.hasAttributeNS("http://example.com/ns2", "attr"));
    try std.testing.expect(!elem.hasAttributeNS("http://example.com/ns3", "attr"));
}

test "Element.hasAttributeNS with null namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttribute("attr", "value");

    try std.testing.expect(elem.hasAttributeNS(null, "attr"));
}

test "Element.hasAttributeNS returns false after removal" {
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
