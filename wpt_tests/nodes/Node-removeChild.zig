// META: title=Node.removeChild
// META: link=https://dom.spec.whatwg.org/#dom-node-removechild

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;

test "Passing a detached element to removeChild should throw NOT_FOUND_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const body = try doc.createElement("body");
    _ = try doc.node.appendChild(&body.node);

    const s = try doc.createElement("a");

    // s is detached, attempting to remove it should fail
    const result = body.node.removeChild(&s.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "Passing a non-detached element from wrong parent should throw NOT_FOUND_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    const body = try doc.createElement("body");
    _ = try doc.node.appendChild(&body.node);

    const s = try doc.createElement("b");
    _ = try root.node.appendChild(&s.node);

    // s is attached to root, not body
    const result = body.node.removeChild(&s.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "Calling removeChild on element with no children should throw NOT_FOUND_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const body = try doc.createElement("body");
    _ = try doc.node.appendChild(&body.node);

    const s = try doc.createElement("test");
    _ = try body.node.appendChild(&s.node);

    // s has no children, can't remove doc from it
    const result = s.node.removeChild(&doc.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "removeChild successfully removes child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);
    try std.testing.expect(parent.node.first_child == &child.node);

    const removed = try parent.node.removeChild(&child.node);
    try std.testing.expect(removed == &child.node);
    try std.testing.expect(parent.node.first_child == null);

    // Clean up
    removed.release();
}

test "removeChild returns the removed node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);

    const removed = try parent.node.removeChild(&child.node);
    try std.testing.expect(removed == &child.node);

    // The removed node should still be valid
    try std.testing.expectEqual(removed.node_type, .element);

    removed.release();
}

test "removeChild updates sibling links" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    const child3 = try doc.createElement("a");

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child2.node);
    _ = try parent.node.appendChild(&child3.node);

    // Remove middle child
    const removed = try parent.node.removeChild(&child2.node);

    // child1 should link to child3
    try std.testing.expect(child1.node.next_sibling == &child3.node);
    try std.testing.expect(child3.node.previous_sibling == &child1.node);

    removed.release();
}
