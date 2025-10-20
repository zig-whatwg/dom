// META: title=Element.setAttribute variations

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.setAttribute creates new attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "value");
    try std.testing.expect(elem.hasAttribute("test"));
}

test "Element.setAttribute updates existing attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "first");
    try std.testing.expectEqualStrings("first", elem.getAttribute("test").?);

    try elem.setAttribute("test", "second");
    try std.testing.expectEqualStrings("second", elem.getAttribute("test").?);
}

test "Element.setAttribute with empty value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "");
    try std.testing.expect(elem.hasAttribute("test"));
    try std.testing.expectEqualStrings("", elem.getAttribute("test").?);
}

test "Element.setAttribute with special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "<>&\"'");
    try std.testing.expectEqualStrings("<>&\"'", elem.getAttribute("test").?);
}

test "Element.setAttribute with valid names" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Valid attribute names work
    try elem.setAttribute("data-test", "value");
    try std.testing.expect(elem.hasAttribute("data-test"));

    try elem.setAttribute("x", "value");
    try std.testing.expect(elem.hasAttribute("x"));
}
