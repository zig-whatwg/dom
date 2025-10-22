// META: title=DOMImplementation.createDocument
// META: link=https://dom.spec.whatwg.org/#dom-domimplementation-createdocument

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "DOMImplementation.createDocument creates document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const newDoc = try impl.createDocument(null, "", null);
    defer newDoc.release();

    try std.testing.expect(newDoc.prototype.node_type == .document);
}

test "DOMImplementation.createDocument with namespace and qualified name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const newDoc = try impl.createDocument(
        "http://example.com/ns",
        "root",
        null,
    );
    defer newDoc.release();

    const docElem = newDoc.documentElement();
    try std.testing.expect(docElem != null);
    try std.testing.expectEqualStrings("root", docElem.?.tag_name);
}

test "DOMImplementation.createDocument with doctype" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const doctype = try impl.createDocumentType("html", "", "");
    defer doctype.prototype.release();

    const newDoc = try impl.createDocument(null, "", doctype);
    defer newDoc.release();

    const dt = newDoc.doctype();
    try std.testing.expect(dt != null);
    try std.testing.expectEqualStrings("html", dt.?.name);
}
