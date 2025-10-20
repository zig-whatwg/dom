// META: title=Element.removeAttribute variations

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.removeAttribute removes existing attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "value");
    try std.testing.expect(elem.hasAttribute("test"));

    elem.removeAttribute("test");
    try std.testing.expect(!elem.hasAttribute("test"));
}

test "Element.removeAttribute on missing attribute does nothing" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Should not error
    elem.removeAttribute("missing");
    try std.testing.expect(!elem.hasAttribute("missing"));
}

test "Element.removeAttribute case sensitivity" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("Test", "value");

    // Remove with different case should not remove
    elem.removeAttribute("test");
    try std.testing.expect(elem.hasAttribute("Test"));

    // Remove with exact case should work
    elem.removeAttribute("Test");
    try std.testing.expect(!elem.hasAttribute("Test"));
}
