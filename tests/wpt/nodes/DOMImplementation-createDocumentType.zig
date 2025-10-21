// META: title=DOMImplementation.createDocumentType
// META: link=https://dom.spec.whatwg.org/#dom-domimplementation-createdocumenttype

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "DOMImplementation.createDocumentType creates doctype" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const doctype = try impl.createDocumentType("html", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("", doctype.publicId);
    try std.testing.expectEqualStrings("", doctype.systemId);
}

test "DOMImplementation.createDocumentType with public ID" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const doctype = try impl.createDocumentType(
        "html",
        "-//W3C//DTD HTML 4.01//EN",
        "",
    );
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("-//W3C//DTD HTML 4.01//EN", doctype.publicId);
}

test "DOMImplementation.createDocumentType with system ID" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const doctype = try impl.createDocumentType(
        "html",
        "",
        "http://www.w3.org/TR/html4/strict.dtd",
    );
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("http://www.w3.org/TR/html4/strict.dtd", doctype.systemId);
}

test "DOMImplementation.createDocumentType with both IDs" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const doctype = try impl.createDocumentType(
        "html",
        "-//W3C//DTD HTML 4.01//EN",
        "http://www.w3.org/TR/html4/strict.dtd",
    );
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("-//W3C//DTD HTML 4.01//EN", doctype.publicId);
    try std.testing.expectEqualStrings("http://www.w3.org/TR/html4/strict.dtd", doctype.systemId);
}
