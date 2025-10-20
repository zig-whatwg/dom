// META: title=Element.classList

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.classList basic functionality" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("class", "foo bar");

    const list = elem.classList();
    try std.testing.expectEqual(@as(usize, 2), list.length());
    try std.testing.expect(list.contains("foo"));
    try std.testing.expect(list.contains("bar"));
}

test "Element.classList.add" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const list = elem.classList();
    try list.add(&[_][]const u8{"test"});
    try std.testing.expectEqual(@as(usize, 1), list.length());
    try std.testing.expect(list.contains("test"));
}

test "Element.classList.remove" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("class", "foo bar baz");

    const list = elem.classList();
    try list.remove(&[_][]const u8{"bar"});
    try std.testing.expectEqual(@as(usize, 2), list.length());
    try std.testing.expect(list.contains("foo"));
    try std.testing.expect(!list.contains("bar"));
    try std.testing.expect(list.contains("baz"));
}
