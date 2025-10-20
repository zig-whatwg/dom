// META: title=DocumentType.remove
// META: link=https://dom.spec.whatwg.org/#dom-childnode-remove

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const DocumentType = dom.DocumentType;

test "DocumentType.remove() - basic functionality" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    _ = try doc.prototype.appendChild(&doctype.prototype);

    try std.testing.expect(doctype.prototype.parent_node != null);

    // Call remove()
    try doctype.remove();

    // Should no longer have parent
    try std.testing.expect(doctype.prototype.parent_node == null);
    try std.testing.expectEqual(@as(usize, 0), doc.prototype.childNodes().length());

    // Release removed doctype
    doctype.prototype.release();
}

test "DocumentType.remove() - not in tree" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    defer doctype.prototype.release();

    // Should not throw even if not in tree
    try doctype.remove();

    try std.testing.expect(doctype.prototype.parent_node == null);
}
