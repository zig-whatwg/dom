// META: title=Node.isConnected basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Node.isConnected on orphaned element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.isConnected());
}

test "Node.isConnected after appendChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(parent.prototype.isConnected());
    try std.testing.expect(child.prototype.isConnected());
}

test "Node.isConnected after removeChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(child.prototype.isConnected());

    const removed = try parent.prototype.removeChild(&child.prototype);
    defer removed.release();

    try std.testing.expect(!removed.isConnected());
}
