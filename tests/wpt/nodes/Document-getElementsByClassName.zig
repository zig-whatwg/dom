// META: title=Document.getElementsByClassName

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const HTMLCollection = dom.HTMLCollection;

test "getElementsByClassName() should be a live collection" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const a = try doc.createElement("a");
    try a.setAttribute("class", "foo");
    _ = try root.prototype.appendChild(&a.prototype);

    const list = doc.getElementsByClassName("foo");

    try std.testing.expectEqual(@as(usize, 1), list.length());

    const b = try doc.createElement("b");
    try b.setAttribute("class", "foo");
    _ = try root.prototype.appendChild(&b.prototype);

    try std.testing.expectEqual(@as(usize, 2), list.length());

    const removed_b = try root.prototype.removeChild(&b.prototype);
    removed_b.release();
    try std.testing.expectEqual(@as(usize, 1), list.length());
}
