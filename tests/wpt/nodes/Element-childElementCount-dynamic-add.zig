// META: title=Dynamic Adding of Elements

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.childElementCount after appendChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    try std.testing.expectEqual(@as(usize, 1), parent.childElementCount());

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    try std.testing.expectEqual(@as(usize, 2), parent.childElementCount());
}
