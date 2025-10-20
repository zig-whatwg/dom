// META: title=Node.previousSibling with different node types

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.previousSibling to element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    try std.testing.expectEqual(&child1.prototype, child2.prototype.previous_sibling.?);
}

test "Element.previousSibling to text" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    const elem = try doc.createElement("element");
    _ = try parent.prototype.appendChild(&elem.prototype);

    try std.testing.expectEqual(&text.prototype, elem.prototype.previous_sibling.?);
}

test "Element.previousSibling null when first child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(child.prototype.previous_sibling == null);
}
