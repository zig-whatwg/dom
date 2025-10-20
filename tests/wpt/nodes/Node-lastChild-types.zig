// META: title=Node.lastChild with different node types

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.lastChild with element child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

test "Element.lastChild with mixed children returns last" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    const elem = try doc.createElement("element");
    _ = try parent.prototype.appendChild(&elem.prototype);

    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    try std.testing.expectEqual(&comment.prototype, parent.prototype.last_child.?);
}

test "Element.lastChild null when no children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.last_child == null);
}
