// META: title=Node.parentNode on orphaned nodes

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Node.parentNode is null for orphaned element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.parent_node == null);
}

test "Node.parentNode is set after appendChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(&parent.prototype, child.prototype.parent_node.?);
}

test "Node.parentNode is null after removeChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const removed = try parent.prototype.removeChild(&child.prototype);
    defer removed.release();

    try std.testing.expect(removed.parent_node == null);
}
