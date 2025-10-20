// META: title=Document.doctype property

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.doctype is null initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expect(doc.doctype() == null);
}

test "Document.doctype after appendChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    _ = try doc.prototype.appendChild(&doctype.prototype);

    const retrieved = doc.doctype();
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqual(&doctype.prototype, &retrieved.?.prototype);
}

test "Document.doctype first in document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    _ = try doc.prototype.insertBefore(&doctype.prototype, null);

    const retrieved = doc.doctype();
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqualStrings("html", retrieved.?.name);
}
