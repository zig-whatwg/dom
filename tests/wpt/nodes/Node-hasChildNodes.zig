// META: title=Node.hasChildNodes

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element without children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.hasChildNodes());
}

test "Element with children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(parent.prototype.hasChildNodes());
}

test "DocumentFragment without children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expect(!frag.prototype.hasChildNodes());
}

test "Text node has no children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release();

    try std.testing.expect(!text.prototype.hasChildNodes());
}
