// META: title=Document.doctype
// META: link=https://dom.spec.whatwg.org/#dom-document-doctype

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const DocumentType = dom.DocumentType;

test "Window document with doctype" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create a DocumentType node using document's factory method
    const doctype = try doc.createDocumentType("html", "", "");

    // Add a comment before doctype (to match WPT's HTML structure)
    const comment = try doc.createComment(" comment ");
    _ = try doc.prototype.appendChild(&comment.prototype);

    // Add doctype
    _ = try doc.prototype.appendChild(&doctype.prototype);

    // Doctype should be a DocumentType
    try std.testing.expect(doc.doctype() != null);
    try std.testing.expect(doc.doctype().?.prototype.node_type == .document_type);

    // doc.doctype() should return the doctype node we added
    try std.testing.expect(doc.doctype().? == doctype);

    // Verify doctype is the second child (after comment)
    const children = doc.prototype.childNodes();
    try std.testing.expectEqual(@as(usize, 2), children.length());
    try std.testing.expect(children.item(1) == &doctype.prototype);
}

test "new Document() has no doctype" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create and append an element
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Document should have no doctype
    try std.testing.expect(doc.doctype() == null);
}
