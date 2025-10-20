// META: title=Node.nextSibling with different node types

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.nextSibling to element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    try std.testing.expectEqual(&child2.prototype, child1.prototype.next_sibling.?);
}

test "Element.nextSibling to text" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const elem = try doc.createElement("element");
    _ = try parent.prototype.appendChild(&elem.prototype);

    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(&text.prototype, elem.prototype.next_sibling.?);
}

test "Element.nextSibling null when last child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(child.prototype.next_sibling == null);
}
