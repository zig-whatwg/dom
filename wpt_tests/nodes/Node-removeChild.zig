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
    _ = try doc.prototype.appendChild(&body.node);

    const s = try doc.createElement("a");
    defer s.prototype.release(); // Must release orphaned nodes

    // s is detached, attempting to remove it should fail
    const result = body.prototype.removeChild(&s.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "Passing a non-detached element from wrong parent should throw NOT_FOUND_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Original test structure: doc -> html -> (body, s)
    // Where s is a sibling of body, not a child
    const html = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&html.node);

    const body = try doc.createElement("body");
    _ = try html.prototype.appendChild(&body.node);

    // Create s and append to html (making s sibling of body, not child)
    const s = try doc.createElement("b");
    _ = try html.prototype.appendChild(&s.node);

    // s is attached to html, not body - should throw NOT_FOUND_ERR
    const result = body.prototype.removeChild(&s.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "Calling removeChild on element with no children should throw NOT_FOUND_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const body = try doc.createElement("body");
    _ = try doc.prototype.appendChild(&body.node);

    const s = try doc.createElement("test");
    _ = try body.prototype.appendChild(&s.node);

    // s has no children, can't remove doc from it
    const result = s.prototype.removeChild(&doc.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "removeChild successfully removes child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.node);
    try std.testing.expect(parent.prototype.first_child == &child.node);

    const removed = try parent.prototype.removeChild(&child.node);
    try std.testing.expect(removed == &child.node);
    try std.testing.expect(parent.prototype.first_child == null);

    // Clean up
    removed.release();
}

test "removeChild returns the removed node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.node);

    const removed = try parent.prototype.removeChild(&child.node);
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
    defer parent.prototype.release(); // Must release orphaned nodes
    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    const child3 = try doc.createElement("a");

    _ = try parent.prototype.appendChild(&child1.node);
    _ = try parent.prototype.appendChild(&child2.node);
    _ = try parent.prototype.appendChild(&child3.node);

    // Remove middle child
    const removed = try parent.prototype.removeChild(&child2.node);

    // child1 should link to child3
    try std.testing.expect(child1.prototype.next_sibling == &child3.node);
    try std.testing.expect(child3.prototype.previous_sibling == &child1.node);

    removed.release();
}
