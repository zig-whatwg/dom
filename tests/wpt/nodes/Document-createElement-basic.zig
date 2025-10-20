// META: title=Document.createElement basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.createElement creates element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("test", elem.tag_name);
}

test "Document.createElement preserves case" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("TestElement");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("TestElement", elem.tag_name);
}

test "Document.createElement with single character" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Single character tag names are valid
    const elem = try doc.createElement("x");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("x", elem.tag_name);
}

test "Document.createElement sets owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    defer elem.prototype.release();

    try std.testing.expectEqual(&doc.prototype, elem.prototype.owner_document.?);
}
