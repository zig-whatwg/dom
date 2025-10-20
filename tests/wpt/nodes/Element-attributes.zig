// META: title=Element.attributes

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.attributes returns NamedNodeMap" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    const attrs = elem.getAttributes();
    try std.testing.expectEqual(@as(usize, 0), attrs.length());
}

test "Element.attributes is live" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    const attrs = elem.getAttributes();
    try std.testing.expectEqual(@as(usize, 0), attrs.length());

    try elem.setAttribute("test", "value");
    try std.testing.expectEqual(@as(usize, 1), attrs.length());

    try elem.setAttribute("another", "val");
    try std.testing.expectEqual(@as(usize, 2), attrs.length());

    elem.removeAttribute("test");
    try std.testing.expectEqual(@as(usize, 1), attrs.length());
}

test "Element.attributes contains correct values" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    try elem.setAttribute("id", "test-id");
    try elem.setAttribute("class", "foo bar");

    var attrs = elem.getAttributes();
    try std.testing.expectEqual(@as(usize, 2), attrs.length());

    const id_attr = try attrs.getNamedItem("id");
    defer id_attr.?.node.release();
    try std.testing.expectEqualStrings("test-id", id_attr.?.value());
}
