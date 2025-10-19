// WPT Test: Node-childNodes
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Node-childNodes.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

test "Node.childNodes on an Element" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createElement("p");
    defer node.prototype.release();

    // Initially empty
    try std.testing.expectEqual(@as(u32, 0), node.prototype.childNodes().length());

    // Add first child
    const child = try doc.createElement("p");
    _ = try node.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(@as(u32, 1), node.prototype.childNodes().length());

    const list = node.prototype.childNodes();
    try std.testing.expect(list.item(0) == &child.prototype);

    // Add second child
    const child2 = try doc.createComment("comment");
    _ = try node.prototype.appendChild(&child2.prototype);

    try std.testing.expectEqual(@as(u32, 2), node.prototype.childNodes().length());
    try std.testing.expect(list.item(0) == &child.prototype);
    try std.testing.expect(list.item(1) == &child2.prototype);

    // Out of bounds returns null
    try std.testing.expect(list.item(2) == null);
}

test "Node.childNodes on a DocumentFragment" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createDocumentFragment();
    defer node.prototype.release();

    // Initially empty
    try std.testing.expectEqual(@as(u32, 0), node.prototype.childNodes().length());

    // Add first child
    const child = try doc.createElement("p");
    _ = try node.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(@as(u32, 1), node.prototype.childNodes().length());

    const list = node.prototype.childNodes();
    try std.testing.expect(list.item(0) == &child.prototype);

    // Add second child
    const child2 = try doc.createComment("comment");
    _ = try node.prototype.appendChild(&child2.prototype);

    try std.testing.expectEqual(@as(u32, 2), node.prototype.childNodes().length());
    try std.testing.expect(list.item(0) == &child.prototype);
    try std.testing.expect(list.item(1) == &child2.prototype);

    // Out of bounds returns null
    try std.testing.expect(list.item(2) == null);
}

test "Node.childNodes on a Document" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    // Initially empty (or just doctype in HTML)
    const initial_count = doc.prototype.childNodes().length();

    // Add first child
    const child = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(initial_count + 1, doc.prototype.childNodes().length());

    _ = doc.prototype.childNodes(); // NodeList is live

    // Add second child (comment)
    const child2 = try doc.createComment("comment");
    _ = try doc.prototype.appendChild(&child2.prototype);

    try std.testing.expectEqual(initial_count + 2, doc.prototype.childNodes().length());
}

test "Node.childNodes should be a live collection" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createElement("ul");
    defer node.prototype.release();

    // Add initial children
    const li1 = try doc.createElement("li");
    _ = try node.prototype.appendChild(&li1.prototype);

    const li2 = try doc.createElement("li");
    _ = try node.prototype.appendChild(&li2.prototype);

    const li3 = try doc.createElement("li");
    _ = try node.prototype.appendChild(&li3.prototype);

    const li4 = try doc.createElement("li");
    _ = try node.prototype.appendChild(&li4.prototype);

    // Get the NodeList
    const children = node.prototype.childNodes();
    try std.testing.expectEqual(@as(u32, 4), children.length());

    // Add a new child
    const li5 = try doc.createElement("li");
    _ = try node.prototype.appendChild(&li5.prototype);

    // NodeList should reflect the change (it's live)
    try std.testing.expectEqual(@as(u32, 5), children.length());

    // Remove a child
    _ = try node.prototype.removeChild(&li5.prototype);

    // After removal, li5 is detached and needs explicit release
    li5.prototype.release();

    // NodeList should reflect the change
    try std.testing.expectEqual(@as(u32, 4), children.length());
}

test "Node.childNodes with mixed node types" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const node = try doc.createElement("div");
    defer node.prototype.release();

    const kid1 = try doc.createElement("p");
    const kid2 = try doc.createTextNode("hey");
    const kid3 = try doc.createElement("span");

    _ = try node.prototype.appendChild(&kid1.prototype);
    _ = try node.prototype.appendChild(&kid2.prototype);
    _ = try node.prototype.appendChild(&kid3.prototype);

    const list = node.prototype.childNodes();
    try std.testing.expectEqual(@as(u32, 3), list.length());

    try std.testing.expect(list.item(0) == &kid1.prototype);
    try std.testing.expect(list.item(1) == &kid2.prototype);
    try std.testing.expect(list.item(2) == &kid3.prototype);
}
