// META: title=Element.getAttributeNS
// META: link=https://dom.spec.whatwg.org/#dom-element-getattributens

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.getAttributeNS returns null when attribute not present" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    const value = elem.getAttributeNS("http://example.com/ns", "attr");
    try std.testing.expect(value == null);
}

test "Element.getAttributeNS returns attribute value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns", "attr", "testvalue");

    const value = elem.getAttributeNS("http://example.com/ns", "attr");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("testvalue", value.?);
}

test "Element.getAttributeNS distinguishes by namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns1", "attr", "value1");
    try elem.setAttributeNS("http://example.com/ns2", "attr", "value2");

    const value1 = elem.getAttributeNS("http://example.com/ns1", "attr");
    const value2 = elem.getAttributeNS("http://example.com/ns2", "attr");

    try std.testing.expectEqualStrings("value1", value1.?);
    try std.testing.expectEqualStrings("value2", value2.?);
}

test "Element.getAttributeNS with null namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttribute("attr", "value");

    const value = elem.getAttributeNS(null, "attr");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("value", value.?);
}

test "Element.getAttributeNS returns null after removal" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns", "attr", "value");
    elem.removeAttributeNS("http://example.com/ns", "attr");

    const value = elem.getAttributeNS("http://example.com/ns", "attr");
    try std.testing.expect(value == null);
}
