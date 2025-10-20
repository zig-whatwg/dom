// META: title=Element attribute count

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.attributeCount with no attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expectEqual(@as(usize, 0), elem.attributeCount());
}

test "Element.attributeCount after setAttribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("attr1", "value1");
    try std.testing.expectEqual(@as(usize, 1), elem.attributeCount());

    try elem.setAttribute("attr2", "value2");
    try std.testing.expectEqual(@as(usize, 2), elem.attributeCount());

    try elem.setAttribute("attr3", "value3");
    try std.testing.expectEqual(@as(usize, 3), elem.attributeCount());
}

test "Element.attributeCount after removeAttribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("attr1", "value1");
    try elem.setAttribute("attr2", "value2");
    try std.testing.expectEqual(@as(usize, 2), elem.attributeCount());

    elem.removeAttribute("attr1");
    try std.testing.expectEqual(@as(usize, 1), elem.attributeCount());

    elem.removeAttribute("attr2");
    try std.testing.expectEqual(@as(usize, 0), elem.attributeCount());
}
