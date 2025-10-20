// META: title=Node assorted property tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const NodeType = dom.NodeType;

test "Element node properties" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const child = try doc.createElement("child");
    _ = try root.prototype.appendChild(&child.prototype);

    // Node properties
    try std.testing.expectEqual(NodeType.element, child.prototype.node_type);
    try std.testing.expect(child.prototype.owner_document == &doc.prototype);
    try std.testing.expect(child.prototype.parent_node == &root.prototype);
    try std.testing.expect(child.prototype.parentElement() == root);
    try std.testing.expect(child.prototype.previous_sibling == null);
    try std.testing.expect(child.prototype.next_sibling == null);

    // Element properties
    try std.testing.expectEqualStrings("child", child.local_name);
}

test "Text node properties" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const text = try doc.createTextNode("Hello");
    _ = try root.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(NodeType.text, text.prototype.node_type);
    try std.testing.expect(text.prototype.owner_document == &doc.prototype);
    try std.testing.expect(text.prototype.parent_node == &root.prototype);
    try std.testing.expectEqualStrings("Hello", text.data);
}

test "Comment node properties" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const comment = try doc.createComment("test comment");
    _ = try root.prototype.appendChild(&comment.prototype);

    try std.testing.expectEqual(NodeType.comment, comment.prototype.node_type);
    try std.testing.expect(comment.prototype.owner_document == &doc.prototype);
    try std.testing.expect(comment.prototype.parent_node == &root.prototype);
    try std.testing.expectEqualStrings("test comment", comment.data);
}

test "Detached element properties" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("detached");
    defer element.prototype.release();

    try std.testing.expectEqual(NodeType.element, element.prototype.node_type);
    try std.testing.expect(element.prototype.owner_document == &doc.prototype);
    try std.testing.expect(element.prototype.parent_node == null);
    try std.testing.expect(element.prototype.parentElement() == null);
    try std.testing.expect(element.prototype.previous_sibling == null);
    try std.testing.expect(element.prototype.next_sibling == null);
}

test "Sibling navigation" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const first = try doc.createElement("first");
    _ = try root.prototype.appendChild(&first.prototype);

    const second = try doc.createElement("second");
    _ = try root.prototype.appendChild(&second.prototype);

    const third = try doc.createElement("third");
    _ = try root.prototype.appendChild(&third.prototype);

    // Test sibling navigation
    try std.testing.expect(first.prototype.previous_sibling == null);
    try std.testing.expect(first.prototype.next_sibling == &second.prototype);

    try std.testing.expect(second.prototype.previous_sibling == &first.prototype);
    try std.testing.expect(second.prototype.next_sibling == &third.prototype);

    try std.testing.expect(third.prototype.previous_sibling == &second.prototype);
    try std.testing.expect(third.prototype.next_sibling == null);
}
