// META: title=Node.contains() tests
// META: link=https://dom.spec.whatwg.org/#dom-node-contains
// META: author=Aryeh Gregor, ayg@aryeh.name

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;

test "Node.contains(null) returns false" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.node.release(); // Must release orphaned nodes
    try std.testing.expect(!elem.node.contains(null));

    // Test with document node
    try std.testing.expect(!doc.node.contains(null));
}

test "Node.contains() with parent-child relationships" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create a simple tree: parent -> child -> grandchild
    const parent = try doc.createElement("div");
    defer parent.node.release(); // Must release orphaned nodes
    const child = try doc.createElement("span");
    const grandchild = try doc.createElement("p");

    _ = try parent.node.appendChild(&child.node);
    _ = try child.node.appendChild(&grandchild.node);

    // Parent contains child
    try std.testing.expect(parent.node.contains(&child.node));

    // Parent contains grandchild
    try std.testing.expect(parent.node.contains(&grandchild.node));

    // Child contains grandchild
    try std.testing.expect(child.node.contains(&grandchild.node));

    // A node contains itself
    try std.testing.expect(parent.node.contains(&parent.node));
    try std.testing.expect(child.node.contains(&child.node));
    try std.testing.expect(grandchild.node.contains(&grandchild.node));

    // Child does not contain parent
    try std.testing.expect(!child.node.contains(&parent.node));

    // Grandchild does not contain parent or child
    try std.testing.expect(!grandchild.node.contains(&parent.node));
    try std.testing.expect(!grandchild.node.contains(&child.node));
}

test "Node.contains() with detached nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.node.release(); // Must release orphaned nodes
    const elem2 = try doc.createElement("span");
    defer elem2.node.release(); // Must release orphaned nodes

    // Detached nodes don't contain each other
    try std.testing.expect(!elem1.node.contains(&elem2.node));
    try std.testing.expect(!elem2.node.contains(&elem1.node));

    // But they contain themselves
    try std.testing.expect(elem1.node.contains(&elem1.node));
    try std.testing.expect(elem2.node.contains(&elem2.node));
}

test "Node.contains() with sibling nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release(); // Must release orphaned nodes
    const sibling1 = try doc.createElement("span");
    const sibling2 = try doc.createElement("p");

    _ = try parent.node.appendChild(&sibling1.node);
    _ = try parent.node.appendChild(&sibling2.node);

    // Siblings don't contain each other
    try std.testing.expect(!sibling1.node.contains(&sibling2.node));
    try std.testing.expect(!sibling2.node.contains(&sibling1.node));

    // But parent contains both
    try std.testing.expect(parent.node.contains(&sibling1.node));
    try std.testing.expect(parent.node.contains(&sibling2.node));
}
