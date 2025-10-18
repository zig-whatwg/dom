// META: title=Node.insertBefore
// META: link=https://dom.spec.whatwg.org/#dom-node-insertbefore

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Node = dom.Node;

fn testLeafNode(node: *Node, doc: *Document) !void {
    // Calling insertBefore on a leaf node must throw HIERARCHY_REQUEST_ERR
    const text = try doc.createTextNode("fail");
    defer text.node.release(); // Clean up since insertBefore will fail
    const result = node.insertBefore(&text.node, null);
    try std.testing.expectError(error.HierarchyRequestError, result);

    // Inserting node into itself
    const result2 = node.insertBefore(node, null);
    try std.testing.expectError(error.HierarchyRequestError, result2);
}

test "Calling insertBefore on a leaf node Text must throw HIERARCHY_REQUEST_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text_node = try doc.createTextNode("Foo");
    defer text_node.node.release(); // Must release orphaned nodes
    try testLeafNode(&text_node.node, doc);
}

test "Calling insertBefore on a leaf node Comment must throw HIERARCHY_REQUEST_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("Foo");
    defer comment.node.release(); // Must release orphaned nodes
    try testLeafNode(&comment.node, doc);
}

test "Calling insertBefore with an inclusive ancestor must throw HIERARCHY_REQUEST_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const body = try doc.createElement("body");
    defer body.node.release(); // Must release orphaned nodes
    const child = try doc.createElement("div");
    _ = try body.node.appendChild(&child.node);

    // Step 2: Cannot insert ancestor into descendant
    const result = body.node.insertBefore(&body.node, &child.node);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "insertBefore with null reference node appends at end" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release(); // Must release orphaned nodes
    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.node.insertBefore(&child1.node, null);
    _ = try parent.node.insertBefore(&child2.node, null);

    // Both should be appended
    try std.testing.expect(parent.node.first_child == &child1.node);
    try std.testing.expect(parent.node.last_child == &child2.node);
}

test "insertBefore inserts before reference node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release(); // Must release orphaned nodes
    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    const child3 = try doc.createElement("a");

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child3.node);

    // Insert child2 before child3
    _ = try parent.node.insertBefore(&child2.node, &child3.node);

    // Order should be: child1, child2, child3
    try std.testing.expect(parent.node.first_child == &child1.node);
    try std.testing.expect(child1.node.next_sibling == &child2.node);
    try std.testing.expect(child2.node.next_sibling == &child3.node);
    try std.testing.expect(parent.node.last_child == &child3.node);
}

test "insertBefore moves node from old parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.node.release(); // Must release orphaned nodes
    const parent2 = try doc.createElement("span");
    defer parent2.node.release(); // Must release orphaned nodes
    const child = try doc.createElement("p");

    _ = try parent1.node.appendChild(&child.node);
    try std.testing.expect(child.node.parent_node == &parent1.node);

    // Insert into parent2
    _ = try parent2.node.insertBefore(&child.node, null);

    // Should be removed from parent1 and added to parent2
    try std.testing.expect(child.node.parent_node == &parent2.node);
    try std.testing.expect(parent1.node.first_child == null);
    try std.testing.expect(parent2.node.first_child == &child.node);
}
