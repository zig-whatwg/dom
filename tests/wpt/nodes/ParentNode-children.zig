// META: title=ParentNode.children
// META: spec=https://dom.spec.whatwg.org/#dom-parentnode-children

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "ParentNode.children should be a live collection" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const child3 = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child3.prototype);

    const child4 = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child4.prototype);

    const children = parent.children();
    try std.testing.expectEqual(@as(usize, 4), children.length());

    const child5 = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child5.prototype);
    try std.testing.expectEqual(@as(usize, 5), children.length());

    const removed = try parent.prototype.removeChild(&child5.prototype);
    removed.release();
    try std.testing.expectEqual(@as(usize, 4), children.length());
}
