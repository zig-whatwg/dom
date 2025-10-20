// META: title=Element.localName basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.localName returns the local name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    defer elem.prototype.release();

    const local = elem.localName();
    try std.testing.expectEqualStrings("test", local);
}

test "Element.localName preserves case" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("TestElement");
    defer elem.prototype.release();

    const local = elem.localName();
    try std.testing.expectEqualStrings("TestElement", local);
}

test "Element.localName same as tagName for non-namespaced elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const local = elem.localName();
    try std.testing.expectEqualStrings(elem.tag_name, local);
}
