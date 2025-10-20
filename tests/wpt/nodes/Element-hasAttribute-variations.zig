// META: title=Element.hasAttribute variations

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.hasAttribute returns false initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(!elem.hasAttribute("test"));
}

test "Element.hasAttribute returns true after setAttribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "value");
    try std.testing.expect(elem.hasAttribute("test"));
}

test "Element.hasAttribute returns false after removeAttribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "value");
    elem.removeAttribute("test");
    try std.testing.expect(!elem.hasAttribute("test"));
}

test "Element.hasAttribute case sensitivity" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("Test", "value");
    try std.testing.expect(elem.hasAttribute("Test"));
    try std.testing.expect(!elem.hasAttribute("test"));
}

test "Element.hasAttribute with empty value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "");
    try std.testing.expect(elem.hasAttribute("test"));
}
