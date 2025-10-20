// META: title=Element.className

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.className via class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    // Set class
    try elem.setAttribute("class", "foo bar");

    const class_val = elem.getAttribute("class");
    try std.testing.expect(class_val != null);
    try std.testing.expectEqualStrings("foo bar", class_val.?);
}

test "Element.className empty" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    const class_val = elem.getAttribute("class");
    try std.testing.expect(class_val == null);
}

test "Element.className multiple classes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    try elem.setAttribute("class", "one two three");

    const found = elem.getAttribute("class");
    try std.testing.expectEqualStrings("one two three", found.?);
}
