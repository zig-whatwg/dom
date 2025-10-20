// WPT Test: ChildNode-remove.js
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/ChildNode-remove.js
//
// Tests ChildNode.remove() behavior as specified in WHATWG DOM Standard § 4.5
// https://dom.spec.whatwg.org/#dom-childnode-remove

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;

// Element.remove() tests

test "Element should support remove()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createElement("test");
    defer node.prototype.release();

    // remove() method exists and can be called
    try node.remove();
}

test "Element.remove() should work if Element doesn't have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createElement("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);
}

test "Element.remove() should work if Element does have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const node = try doc.createElement("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    _ = try parent.prototype.appendChild(&node.prototype);
    try std.testing.expectEqual(&parent.prototype, node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);
    try std.testing.expectEqual(@as(?*dom.Node, null), parent.prototype.first_child);
}

test "Element.remove() should work if Element does have a parent and siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const node = try doc.createElement("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    const before = try doc.createComment("before");
    _ = try parent.prototype.appendChild(&before.prototype);

    _ = try parent.prototype.appendChild(&node.prototype);

    const after = try doc.createComment("after");
    _ = try parent.prototype.appendChild(&after.prototype);

    try std.testing.expectEqual(&parent.prototype, node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    // Parent should have two children left: before and after
    try std.testing.expectEqual(&before.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&after.prototype, parent.prototype.last_child.?);
    try std.testing.expectEqual(&after.prototype, parent.prototype.first_child.?.next_sibling.?);
}

// Text.remove() tests

test "Text should support remove()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    // remove() method exists and can be called
    try node.remove();
}

test "Text.remove() should work if Text doesn't have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);
}

test "Text.remove() should work if Text does have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    _ = try parent.prototype.appendChild(&node.prototype);
    try std.testing.expectEqual(&parent.prototype, node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);
    try std.testing.expectEqual(@as(?*dom.Node, null), parent.prototype.first_child);
}

test "Text.remove() should work if Text does have a parent and siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    const before = try doc.createComment("before");
    _ = try parent.prototype.appendChild(&before.prototype);

    _ = try parent.prototype.appendChild(&node.prototype);

    const after = try doc.createComment("after");
    _ = try parent.prototype.appendChild(&after.prototype);

    try std.testing.expectEqual(&parent.prototype, node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    // Parent should have two children left: before and after
    try std.testing.expectEqual(&before.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&after.prototype, parent.prototype.last_child.?);
}

// Comment.remove() tests

test "Comment should support remove()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    // remove() method exists and can be called
    try node.remove();
}

test "Comment.remove() should work if Comment doesn't have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);
}

test "Comment.remove() should work if Comment does have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    _ = try parent.prototype.appendChild(&node.prototype);
    try std.testing.expectEqual(&parent.prototype, node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);
    try std.testing.expectEqual(@as(?*dom.Node, null), parent.prototype.first_child);
}

test "Comment.remove() should work if Comment does have a parent and siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const node = try doc.createComment("test");
    defer node.prototype.release();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    const before = try doc.createComment("before");
    _ = try parent.prototype.appendChild(&before.prototype);

    _ = try parent.prototype.appendChild(&node.prototype);

    const after = try doc.createComment("after");
    _ = try parent.prototype.appendChild(&after.prototype);

    try std.testing.expectEqual(&parent.prototype, node.prototype.parent_node);

    try node.remove();

    try std.testing.expectEqual(@as(?*dom.Node, null), node.prototype.parent_node);

    // Parent should have two children left: before and after
    try std.testing.expectEqual(&before.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&after.prototype, parent.prototype.last_child.?);
}
