const std = @import("std");
const dom = @import("dom");
const DocumentType = dom.DocumentType;
const Document = dom.Document;

test "DocumentType - create and access properties" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("", doctype.publicId);
    try std.testing.expectEqualStrings("", doctype.systemId);
}

test "DocumentType - XML with public and system IDs" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(
        allocator,
        "svg",
        "-//W3C//DTD SVG 1.1//EN",
        "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd",
    );
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("svg", doctype.name);
    try std.testing.expectEqualStrings("-//W3C//DTD SVG 1.1//EN", doctype.publicId);
    try std.testing.expectEqualStrings("http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd", doctype.systemId);
}

test "DocumentType - nodeName returns name" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    const node_name = doctype.prototype.nodeName();
    try std.testing.expectEqualStrings("html", node_name);
}

test "DocumentType - nodeValue is null" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    try std.testing.expect(doctype.prototype.nodeValue() == null);
}

test "DocumentType - cloneNode creates copy" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "public", "system");
    defer doctype.prototype.release();

    const cloned_node = try doctype.prototype.cloneNode(false);
    defer cloned_node.release();

    const cloned: *DocumentType = @fieldParentPtr("prototype", cloned_node);

    try std.testing.expectEqualStrings("html", cloned.name);
    try std.testing.expectEqualStrings("public", cloned.publicId);
    try std.testing.expectEqualStrings("system", cloned.systemId);
}

test "DocumentType - node_type is correct" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    try std.testing.expect(doctype.prototype.node_type == .document_type);
}

test "DocumentType - remove from document" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try DocumentType.create(allocator, "html", "", "");
    _ = try doc.prototype.appendChild(&doctype.prototype);

    try std.testing.expect(doc.prototype.first_child == &doctype.prototype);

    try doctype.remove();

    try std.testing.expect(doc.prototype.first_child == null);
}

test "DocumentType - before inserts node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try DocumentType.create(allocator, "html", "", "");
    _ = try doc.prototype.appendChild(&doctype.prototype);

    const comment = try doc.createComment("before");
    try doctype.before(&[_]DocumentType.NodeOrString{.{ .node = &comment.prototype }});

    try std.testing.expect(doc.prototype.first_child == &comment.prototype);
    try std.testing.expect(comment.prototype.next_sibling == &doctype.prototype);
}

test "DocumentType - after inserts node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try DocumentType.create(allocator, "html", "", "");
    _ = try doc.prototype.appendChild(&doctype.prototype);

    const comment = try doc.createComment("after");
    try doctype.after(&[_]DocumentType.NodeOrString{.{ .node = &comment.prototype }});

    try std.testing.expect(doc.prototype.first_child == &doctype.prototype);
    try std.testing.expect(doctype.prototype.next_sibling == &comment.prototype);
}

test "DocumentType - replaceWith single node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try DocumentType.create(allocator, "html", "", "");
    _ = try doc.prototype.appendChild(&doctype.prototype);

    const new_doctype = try DocumentType.create(allocator, "xml", "", "");
    try doctype.replaceWith(&[_]DocumentType.NodeOrString{.{ .node = &new_doctype.prototype }});

    try std.testing.expect(doc.prototype.first_child == &new_doctype.prototype);
    try std.testing.expect(doctype.prototype.parent_node == null);
}

test "DocumentType - replaceWith string creates text node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try DocumentType.create(allocator, "html", "", "");
    _ = try doc.prototype.appendChild(&doctype.prototype);

    try doctype.replaceWith(&[_]DocumentType.NodeOrString{.{ .string = "text" }});

    try std.testing.expect(doc.prototype.first_child != null);
    try std.testing.expect(doc.prototype.first_child.?.node_type == .text);
}
