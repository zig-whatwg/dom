// META: title=Element.tagName case preservation

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.tagName preserves case" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("MyElement");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("MyElement", elem.tag_name);
}

test "Element.tagName with lowercase" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("item", elem.tag_name);
}

test "Element.tagName with uppercase" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("ITEM");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("ITEM", elem.tag_name);
}
