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
    defer text.prototype.release(); // Clean up since insertBefore will fail
    const result = node.insertBefore(&text.prototype, null);
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
    defer text_node.prototype.release(); // Must release orphaned nodes
    try testLeafNode(&text_node.prototype, doc);
}

test "Calling insertBefore on a leaf node Comment must throw HIERARCHY_REQUEST_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("Foo");
    defer comment.prototype.release(); // Must release orphaned nodes
    try testLeafNode(&comment.prototype, doc);
}

test "Calling insertBefore with an inclusive ancestor must throw HIERARCHY_REQUEST_ERR" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const body = try doc.createElement("body");
    defer body.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("div");
    _ = try body.prototype.appendChild(&child.prototype);

    // Step 2: Cannot insert ancestor into descendant
    const result = body.prototype.insertBefore(&body.prototype, &child.prototype);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "insertBefore with null reference node appends at end" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.prototype.insertBefore(&child1.prototype, null);
    _ = try parent.prototype.insertBefore(&child2.prototype, null);

    // Both should be appended
    try std.testing.expect(parent.prototype.first_child == &child1.prototype);
    try std.testing.expect(parent.prototype.last_child == &child2.prototype);
}

test "insertBefore inserts before reference node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    const child3 = try doc.createElement("a");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Insert child2 before child3
    _ = try parent.prototype.insertBefore(&child2.prototype, &child3.prototype);

    // Order should be: child1, child2, child3
    try std.testing.expect(parent.prototype.first_child == &child1.prototype);
    try std.testing.expect(child1.prototype.next_sibling == &child2.prototype);
    try std.testing.expect(child2.prototype.next_sibling == &child3.prototype);
    try std.testing.expect(parent.prototype.last_child == &child3.prototype);
}

test "insertBefore moves node from old parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release(); // Must release orphaned nodes
    const parent2 = try doc.createElement("span");
    defer parent2.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("p");

    _ = try parent1.prototype.appendChild(&child.prototype);
    try std.testing.expect(child.prototype.parent_node == &parent1.prototype);

    // Insert into parent2
    _ = try parent2.prototype.insertBefore(&child.prototype, null);

    // Should be removed from parent1 and added to parent2
    try std.testing.expect(child.prototype.parent_node == &parent2.prototype);
    try std.testing.expect(parent1.prototype.first_child == null);
    try std.testing.expect(parent2.prototype.first_child == &child.prototype);
}
