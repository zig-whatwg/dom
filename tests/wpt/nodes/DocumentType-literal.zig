// META: title=DocumentType literal

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const DocumentType = dom.DocumentType;
const NodeType = dom.NodeType;

test "DocumentType properties" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("", doctype.publicId);
    try std.testing.expectEqualStrings("", doctype.systemId);
}

test "DocumentType with publicId and systemId" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "-//W3C//DTD HTML 4.01//EN", "http://www.w3.org/TR/html4/strict.dtd");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("-//W3C//DTD HTML 4.01//EN", doctype.publicId);
    try std.testing.expectEqualStrings("http://www.w3.org/TR/html4/strict.dtd", doctype.systemId);
}

test "DocumentType node type" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("test", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqual(NodeType.document_type, doctype.prototype.node_type);
    try std.testing.expectEqualStrings("test", doctype.prototype.nodeName());
}
