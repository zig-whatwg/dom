// META: title=Dynamic Removal of Elements

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.childElementCount after removeChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    try std.testing.expectEqual(@as(usize, 2), parent.childElementCount());

    const removed = try parent.prototype.removeChild(parent.prototype.last_child.?);
    removed.release();

    try std.testing.expectEqual(@as(usize, 1), parent.childElementCount());
}
