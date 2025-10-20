// META: title=Node.firstChild with different node types

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.firstChild with element child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
}

test "Element.firstChild with text child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(&text.prototype, parent.prototype.first_child.?);
}

test "Element.firstChild with comment child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    try std.testing.expectEqual(&comment.prototype, parent.prototype.first_child.?);
}

test "Element.firstChild with mixed children returns first" {
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

    try std.testing.expectEqual(&text.prototype, parent.prototype.first_child.?);
}
