// META: title=Element.localName

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.localName without namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("item", elem.local_name);
}

test "Element.localName with namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS("http://example.com", "custom:element");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("element", elem.local_name);
}

test "Element.localName matches tagName without namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings(elem.local_name, elem.tag_name);
}
