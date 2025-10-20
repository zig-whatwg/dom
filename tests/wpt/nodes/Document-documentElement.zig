// META: title=Document.documentElement

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.documentElement initially null" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expect(doc.documentElement() == null);
}

test "Document.documentElement after appending element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const docElem = doc.documentElement();
    try std.testing.expect(docElem != null);
    try std.testing.expect(docElem.? == root);
}

test "Document.documentElement ignores comments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("comment");
    _ = try doc.prototype.appendChild(&comment.prototype);

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const docElem = doc.documentElement();
    try std.testing.expect(docElem != null);
    try std.testing.expect(docElem.? == root);
}
