// META: title=Element.getElementsByClassName

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const HTMLCollection = dom.HTMLCollection;

test "getElementsByClassName should work on disconnected subtrees" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("a");
    defer a.prototype.release();

    const b = try doc.createElement("b");
    try b.setAttribute("class", "foo");
    _ = try a.prototype.appendChild(&b.prototype);

    const list = a.getElementsByClassName("foo");

    try std.testing.expectEqual(@as(usize, 1), list.length());
    try std.testing.expect(list.item(0) == b);
}

test "Interface should be correct" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const list = doc.getElementsByClassName("foo");

    // Should be HTMLCollection (we only have HTMLCollection)
    try std.testing.expect(@TypeOf(list) == HTMLCollection);
}

test "getElementsByClassName() should be a live collection" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    defer root.prototype.release();

    const a = try doc.createElement("a");
    _ = try root.prototype.appendChild(&a.prototype);

    const b = try doc.createElement("b");
    try b.setAttribute("class", "foo");
    _ = try a.prototype.appendChild(&b.prototype);

    const list = a.getElementsByClassName("foo");

    try std.testing.expectEqual(@as(usize, 1), list.length());

    // Add another element with class "foo"
    const c = try doc.createElement("c");
    try c.setAttribute("class", "foo");
    _ = try a.prototype.appendChild(&c.prototype);

    // List should update live
    try std.testing.expectEqual(@as(usize, 2), list.length());

    // Remove one
    const removed_c = try a.prototype.removeChild(&c.prototype);
    removed_c.release();
    try std.testing.expectEqual(@as(usize, 1), list.length());
}
