// META: title=Element.className property

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.className via class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("class", "foo bar");

    const class_attr = elem.getAttribute("class");
    try std.testing.expect(class_attr != null);
    try std.testing.expectEqualStrings("foo bar", class_attr.?);
}

test "Element.className initially empty" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const class_attr = elem.getAttribute("class");
    try std.testing.expect(class_attr == null);
}

test "Element.className modification" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("class", "initial");
    try std.testing.expectEqualStrings("initial", elem.getAttribute("class").?);

    try elem.setAttribute("class", "modified");
    try std.testing.expectEqualStrings("modified", elem.getAttribute("class").?);
}
