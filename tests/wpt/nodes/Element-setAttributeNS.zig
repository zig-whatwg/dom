// META: title=Element.setAttributeNS
// META: link=https://dom.spec.whatwg.org/#dom-element-setattributens

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.setAttributeNS creates namespaced attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns", "attr", "value");

    const value = elem.getAttributeNS("http://example.com/ns", "attr");
    try std.testing.expectEqualStrings("value", value.?);
}

test "Element.setAttributeNS updates existing attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns", "attr", "value1");
    try elem.setAttributeNS("http://example.com/ns", "attr", "value2");

    const value = elem.getAttributeNS("http://example.com/ns", "attr");
    try std.testing.expectEqualStrings("value2", value.?);
}

test "Element.setAttributeNS with different namespaces" {
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

test "Element.setAttributeNS with null namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS(null, "attr", "value");

    const value = elem.getAttributeNS(null, "attr");
    try std.testing.expectEqualStrings("value", value.?);
}

test "Element.setAttributeNS with empty string value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttributeNS("http://example.com/ns", "attr", "");

    const value = elem.getAttributeNS("http://example.com/ns", "attr");
    try std.testing.expectEqualStrings("", value.?);
}
