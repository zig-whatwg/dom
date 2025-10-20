// META: title=Node.hasChildNodes basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.hasChildNodes returns false initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.hasChildNodes());
}

test "Element.hasChildNodes returns true after appendChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(parent.prototype.hasChildNodes());
}

test "Element.hasChildNodes returns false after removeChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const removed = try parent.prototype.removeChild(&child.prototype);
    removed.release();

    try std.testing.expect(!parent.prototype.hasChildNodes());
}

test "Document.hasChildNodes with documentElement" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expect(!doc.prototype.hasChildNodes());

    const elem = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(doc.prototype.hasChildNodes());
}
