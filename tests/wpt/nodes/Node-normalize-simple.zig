// META: title=Node.normalize simple tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Node.normalize merges adjacent text nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text1 = try doc.createTextNode("Hello");
    _ = try parent.prototype.appendChild(&text1.prototype);

    const text2 = try doc.createTextNode(" ");
    _ = try parent.prototype.appendChild(&text2.prototype);

    const text3 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text3.prototype);

    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    try std.testing.expectEqual(@as(usize, 1), parent.prototype.childNodes().length());

    const text_node: *dom.Text = @fieldParentPtr("prototype", parent.prototype.first_child.?);
    try std.testing.expectEqualStrings("Hello World", text_node.data);
}

test "Node.normalize removes empty text nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text1 = try doc.createTextNode("");
    _ = try parent.prototype.appendChild(&text1.prototype);

    const elem = try doc.createElement("element");
    _ = try parent.prototype.appendChild(&elem.prototype);

    const text2 = try doc.createTextNode("");
    _ = try parent.prototype.appendChild(&text2.prototype);

    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    try std.testing.expectEqual(@as(usize, 1), parent.prototype.childNodes().length());
    try std.testing.expectEqual(&elem.prototype, parent.prototype.first_child.?);
}

test "Node.normalize with no text nodes does nothing" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const elem1 = try doc.createElement("elem1");
    _ = try parent.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("elem2");
    _ = try parent.prototype.appendChild(&elem2.prototype);

    try std.testing.expectEqual(@as(usize, 2), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    try std.testing.expectEqual(@as(usize, 2), parent.prototype.childNodes().length());
}
