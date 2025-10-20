// META: title=Element.id property

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.getId returns null initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expect(elem.getId() == null);
}

test "Element.setId sets the id" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setId("test-id");

    const id = elem.getId();
    try std.testing.expect(id != null);
    try std.testing.expectEqualStrings("test-id", id.?);
}

test "Element.setId via setAttribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("id", "via-attr");

    const id = elem.getId();
    try std.testing.expect(id != null);
    try std.testing.expectEqualStrings("via-attr", id.?);
}

test "Element.getId reflects attribute changes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("id", "first");
    try std.testing.expectEqualStrings("first", elem.getId().?);

    try elem.setAttribute("id", "second");
    try std.testing.expectEqualStrings("second", elem.getId().?);

    elem.removeAttribute("id");
    try std.testing.expect(elem.getId() == null);
}
