// META: title=Node.isSameNode basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Node.isSameNode with same node reference" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.isSameNode(&elem.prototype));
}

test "Node.isSameNode with different nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("elem1");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("elem2");
    defer elem2.prototype.release();

    try std.testing.expect(!elem1.prototype.isSameNode(&elem2.prototype));
}

test "Node.isSameNode with null" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.isSameNode(null));
}
