// META: title=DocumentType.nodeName property

const std = @import("std");
const dom = @import("dom");

test "DocumentType.nodeName returns name" {
    const allocator = std.testing.allocator;

    const doctype = try dom.DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    const node_name = doctype.prototype.nodeName();
    try std.testing.expectEqualStrings("html", node_name);
}

test "DocumentType.nodeName with custom name" {
    const allocator = std.testing.allocator;

    const doctype = try dom.DocumentType.create(allocator, "custom-doctype", "", "");
    defer doctype.prototype.release();

    const node_name = doctype.prototype.nodeName();
    try std.testing.expectEqualStrings("custom-doctype", node_name);
}
