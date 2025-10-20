// META: title=Node.nodeName for DocumentType

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "DocumentType.nodeName returns the name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try dom.DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    const name = doctype.prototype.nodeName();
    try std.testing.expectEqualStrings("html", name);
}

test "DocumentType.nodeName with different names" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype1 = try dom.DocumentType.create(allocator, "custom", "", "");
    defer doctype1.prototype.release();

    const name1 = doctype1.prototype.nodeName();
    try std.testing.expectEqualStrings("custom", name1);

    const doctype2 = try dom.DocumentType.create(allocator, "svg", "", "");
    defer doctype2.prototype.release();

    const name2 = doctype2.prototype.nodeName();
    try std.testing.expectEqualStrings("svg", name2);
}
