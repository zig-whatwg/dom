// META: title=Document.URL

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.URL defaults to about:blank" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Document.ownerDocument points to itself in our implementation
    try std.testing.expectEqual(&doc.prototype, doc.prototype.owner_document.?);

    // Document has no parent
    try std.testing.expect(doc.prototype.parent_node == null);
}
