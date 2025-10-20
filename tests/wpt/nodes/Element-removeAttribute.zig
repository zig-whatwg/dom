// META: title=Element.prototype.removeAttribute
// META: link=https://dom.spec.whatwg.org/#dom-element-removeattribute

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

// TODO: Fix getAttribute/removeAttribute namespace handling
// Currently getAttribute(name) and removeAttribute(name) only match attributes with namespace_uri == null.
// Per WHATWG DOM spec, they should match the FIRST attribute whose qualified name is 'name',
// irrespective of namespace. This requires iterating attributes and matching on qualified name (prefix:localName).
// See: https://dom.spec.whatwg.org/#dom-element-getattribute
// See: https://dom.spec.whatwg.org/#dom-element-removeattribute

test "removeAttribute should remove the first attribute, irrespective of namespace, when the first attribute is not in a namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("element");
    defer el.prototype.release();

    try el.setAttribute("attr1", "first");
    try el.setAttributeNS("namespace1", "attr1", "second");

    try std.testing.expectEqual(@as(usize, 2), el.attributeCount());
    try std.testing.expectEqualStrings("first", el.getAttribute("attr1").?);
    try std.testing.expectEqualStrings("first", el.getAttributeNS(null, "attr1").?);
    try std.testing.expectEqualStrings("second", el.getAttributeNS("namespace1", "attr1").?);

    // removeAttribute removes the first attribute with name "attr1" that
    // we set on the element, irrespective of namespace.
    el.removeAttribute("attr1");

    // The only attribute remaining should be the second one.
    try std.testing.expectEqualStrings("second", el.getAttribute("attr1").?);
    try std.testing.expect(el.getAttributeNS(null, "attr1") == null);
    try std.testing.expectEqualStrings("second", el.getAttributeNS("namespace1", "attr1").?);
    try std.testing.expectEqual(@as(usize, 1), el.attributeCount());
}

test "removeAttribute should remove the first attribute, irrespective of namespace, when the first attribute is in a namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("element");
    defer el.prototype.release();

    try el.setAttributeNS("namespace1", "attr1", "first");
    try el.setAttributeNS("namespace2", "attr1", "second");

    try std.testing.expectEqual(@as(usize, 2), el.attributeCount());
    try std.testing.expectEqualStrings("first", el.getAttribute("attr1").?);
    try std.testing.expectEqualStrings("first", el.getAttributeNS("namespace1", "attr1").?);
    try std.testing.expectEqualStrings("second", el.getAttributeNS("namespace2", "attr1").?);

    // removeAttribute removes the first attribute with name "attr1" that
    // we set on the element, irrespective of namespace.
    el.removeAttribute("attr1");

    // The only attribute remaining should be the second one.
    try std.testing.expectEqualStrings("second", el.getAttribute("attr1").?);
    try std.testing.expect(el.getAttributeNS("namespace1", "attr1") == null);
    try std.testing.expectEqualStrings("second", el.getAttributeNS("namespace2", "attr1").?);
    try std.testing.expectEqual(@as(usize, 1), el.attributeCount());
}
