// META: title=Element.getAttribute variations

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.getAttribute returns null for missing attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(elem.getAttribute("missing") == null);
}

test "Element.getAttribute returns value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "value");
    const attr = elem.getAttribute("test");
    try std.testing.expect(attr != null);
    try std.testing.expectEqualStrings("value", attr.?);
}

test "Element.getAttribute with empty string value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "");
    const attr = elem.getAttribute("test");
    try std.testing.expect(attr != null);
    try std.testing.expectEqualStrings("", attr.?);
}

test "Element.getAttribute case sensitivity" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("Test", "value");

    // Exact match should work
    const attr1 = elem.getAttribute("Test");
    try std.testing.expect(attr1 != null);
    try std.testing.expectEqualStrings("value", attr1.?);

    // Different case should not match
    const attr2 = elem.getAttribute("test");
    try std.testing.expect(attr2 == null);
}
