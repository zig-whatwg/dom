// META: title=Text() constructor

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const NodeType = dom.NodeType;

test "new Text(): no arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("", text.data);
    try std.testing.expect(text.prototype.owner_document == &doc.prototype);
}

test "new Text(): with data argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test data");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("test data", text.data);
    try std.testing.expect(text.prototype.owner_document == &doc.prototype);
}

test "new Text(): special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("&amp;");
    defer text1.prototype.release();
    try std.testing.expectEqualStrings("&amp;", text1.data);

    const text2 = try doc.createTextNode("-->");
    defer text2.prototype.release();
    try std.testing.expectEqualStrings("-->", text2.data);

    const text3 = try doc.createTextNode("<!--");
    defer text3.prototype.release();
    try std.testing.expectEqualStrings("<!--", text3.data);
}

test "new Text(): node type" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release();

    try std.testing.expectEqual(NodeType.text, text.prototype.node_type);
    try std.testing.expectEqualStrings("#text", text.prototype.nodeName());
}
