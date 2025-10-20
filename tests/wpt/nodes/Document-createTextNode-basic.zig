// META: title=Document.createTextNode basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.createTextNode creates text node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("test", text.data);
}

test "Document.createTextNode with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("", text.data);
}

test "Document.createTextNode with special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test <>&\"'");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("test <>&\"'", text.data);
}

test "Document.createTextNode sets owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release();

    try std.testing.expectEqual(&doc.prototype, text.prototype.owner_document.?);
}
