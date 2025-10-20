// META: title=Node.contains basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Node.contains with same node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.contains(&elem.prototype));
}

test "Node.contains with direct child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(parent.prototype.contains(&child.prototype));
}

test "Node.contains with descendant" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const grandparent = try doc.createElement("grandparent");
    defer grandparent.prototype.release();

    const parent = try doc.createElement("parent");
    _ = try grandparent.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(grandparent.prototype.contains(&child.prototype));
}

test "Node.contains returns false for unrelated nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("elem1");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("elem2");
    defer elem2.prototype.release();

    try std.testing.expect(!elem1.prototype.contains(&elem2.prototype));
}

test "Node.contains with null returns false" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.contains(null));
}
