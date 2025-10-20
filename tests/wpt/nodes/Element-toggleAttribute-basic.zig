// META: title=Element.toggleAttribute basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.toggleAttribute adds attribute if not present" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const result = try elem.toggleAttribute("test", null);
    try std.testing.expect(result);
    try std.testing.expect(elem.hasAttribute("test"));
}

test "Element.toggleAttribute removes attribute if present" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "value");
    const result = try elem.toggleAttribute("test", null);
    try std.testing.expect(!result);
    try std.testing.expect(!elem.hasAttribute("test"));
}

test "Element.toggleAttribute with force true" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const result1 = try elem.toggleAttribute("test", true);
    try std.testing.expect(result1);
    try std.testing.expect(elem.hasAttribute("test"));

    // Toggle again with force true - should still be present
    const result2 = try elem.toggleAttribute("test", true);
    try std.testing.expect(result2);
    try std.testing.expect(elem.hasAttribute("test"));
}

test "Element.toggleAttribute with force false" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("test", "value");

    const result = try elem.toggleAttribute("test", false);
    try std.testing.expect(!result);
    try std.testing.expect(!elem.hasAttribute("test"));
}
