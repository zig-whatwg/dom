// META: title=Node.replaceChild
// META: link=https://dom.spec.whatwg.org/#dom-node-replacechild

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Node = dom.Node;

test "If child's parent is not the context node, NotFoundError should be thrown" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("div");
    defer a.prototype.release(); // Must release orphaned nodes
    const b = try doc.createElement("div");
    defer b.prototype.release(); // Must release orphaned nodes
    const c = try doc.createElement("div");
    defer c.prototype.release(); // Must release orphaned nodes

    // c is not a child of a
    const result = a.prototype.replaceChild(&b.node, &c.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "If child's parent is not the context node (child in different parent)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("div");
    defer a.prototype.release(); // Must release orphaned nodes
    const b = try doc.createElement("div");
    const c = try doc.createElement("div");
    defer c.prototype.release(); // Must release orphaned nodes
    const d = try doc.createElement("div");
    defer d.prototype.release(); // Must release orphaned nodes

    _ = try d.prototype.appendChild(&b.node);

    // b is in d, not a
    const result = a.prototype.replaceChild(&b.node, &c.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "If context node cannot contain children, HierarchyRequestError should be thrown" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text_node = try doc.createTextNode("text");
    defer text_node.prototype.release();
    const a = try doc.createElement("div");
    defer a.prototype.release(); // Must release orphaned nodes
    const b = try doc.createElement("div");
    defer b.prototype.release(); // Must release orphaned nodes

    // Text nodes can't have children
    const result = text_node.prototype.replaceChild(&a.node, &b.node);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "If node is an inclusive ancestor of context node, HierarchyRequestError should be thrown" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("div");
    defer a.prototype.release(); // Must release orphaned nodes
    const b = try doc.createElement("div");

    _ = try a.prototype.appendChild(&b.node);

    // Can't replace b with a (would create cycle)
    const result = a.prototype.replaceChild(&a.node, &b.node);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "If node is ancestor of context node, HierarchyRequestError should be thrown" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("div");
    const b = try doc.createElement("div");
    const c = try doc.createElement("div");
    defer c.prototype.release(); // Must release orphaned nodes

    _ = try c.prototype.appendChild(&a.node);
    _ = try a.prototype.appendChild(&b.node);

    // Can't replace b with c (c is ancestor of a)
    const result = a.prototype.replaceChild(&c.node, &b.node);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "replaceChild successfully replaces child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const old_child = try doc.createElement("span");
    const new_child = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&old_child.node);
    try std.testing.expect(parent.prototype.first_child == &old_child.node);

    const replaced = try parent.prototype.replaceChild(&new_child.node, &old_child.node);

    // new_child should now be the child
    try std.testing.expect(parent.prototype.first_child == &new_child.node);

    // Should return old child
    try std.testing.expect(replaced == &old_child.node);

    replaced.release();
}

test "replaceChild maintains sibling relationships" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child1 = try doc.createElement("a");
    const child2 = try doc.createElement("b");
    const child3 = try doc.createElement("c");
    const new_child = try doc.createElement("new");

    _ = try parent.prototype.appendChild(&child1.node);
    _ = try parent.prototype.appendChild(&child2.node);
    _ = try parent.prototype.appendChild(&child3.node);

    // Replace child2 with new_child
    const replaced = try parent.prototype.replaceChild(&new_child.node, &child2.node);

    // Check sibling links
    try std.testing.expect(child1.prototype.next_sibling == &new_child.node);
    try std.testing.expect(new_child.prototype.previous_sibling == &child1.node);
    try std.testing.expect(new_child.prototype.next_sibling == &child3.node);
    try std.testing.expect(child3.prototype.previous_sibling == &new_child.node);

    replaced.release();
}

test "replaceChild removes node from old parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release(); // Must release orphaned nodes
    const parent2 = try doc.createElement("span");
    defer parent2.prototype.release(); // Must release orphaned nodes
    const old_child = try doc.createElement("old");
    const new_child = try doc.createElement("new");

    _ = try parent1.prototype.appendChild(&new_child.node);
    _ = try parent2.prototype.appendChild(&old_child.node);

    // Replace old_child with new_child (should move new_child from parent1)
    const replaced = try parent2.prototype.replaceChild(&new_child.node, &old_child.node);

    // new_child should be in parent2
    try std.testing.expect(new_child.prototype.parent_node == &parent2.node);

    // parent1 should be empty
    try std.testing.expect(parent1.prototype.first_child == null);

    replaced.release();
}
