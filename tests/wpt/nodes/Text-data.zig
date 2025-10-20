// META: title=Text.data

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Text.data initial value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("hello", text.data);
}

test "Text.data empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("", text.data);
}

test "Text.data can be modified" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("initial");
    defer text.prototype.release();

    try text.prototype.setNodeValue("modified");
    try std.testing.expectEqualStrings("modified", text.data);
}

test "Text.data with special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello\n\t<>&");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("Hello\n\t<>&", text.data);
}
