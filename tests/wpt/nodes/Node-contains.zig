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
    defer elem.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(!elem.prototype.contains(null));

    // Test with document node
    try std.testing.expect(!doc.prototype.contains(null));
}

test "Node.contains() with parent-child relationships" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create a simple tree: parent -> child -> grandchild
    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("span");
    const grandchild = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try child.prototype.appendChild(&grandchild.prototype);

    // Parent contains child
    try std.testing.expect(parent.prototype.contains(&child.prototype));

    // Parent contains grandchild
    try std.testing.expect(parent.prototype.contains(&grandchild.prototype));

    // Child contains grandchild
    try std.testing.expect(child.prototype.contains(&grandchild.prototype));

    // A node contains itself
    try std.testing.expect(parent.prototype.contains(&parent.prototype));
    try std.testing.expect(child.prototype.contains(&child.prototype));
    try std.testing.expect(grandchild.prototype.contains(&grandchild.prototype));

    // Child does not contain parent
    try std.testing.expect(!child.prototype.contains(&parent.prototype));

    // Grandchild does not contain parent or child
    try std.testing.expect(!grandchild.prototype.contains(&parent.prototype));
    try std.testing.expect(!grandchild.prototype.contains(&child.prototype));
}

test "Node.contains() with detached nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release(); // Must release orphaned nodes
    const elem2 = try doc.createElement("span");
    defer elem2.prototype.release(); // Must release orphaned nodes

    // Detached nodes don't contain each other
    try std.testing.expect(!elem1.prototype.contains(&elem2.prototype));
    try std.testing.expect(!elem2.prototype.contains(&elem1.prototype));

    // But they contain themselves
    try std.testing.expect(elem1.prototype.contains(&elem1.prototype));
    try std.testing.expect(elem2.prototype.contains(&elem2.prototype));
}

test "Node.contains() with sibling nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const sibling1 = try doc.createElement("span");
    const sibling2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&sibling1.prototype);
    _ = try parent.prototype.appendChild(&sibling2.prototype);

    // Siblings don't contain each other
    try std.testing.expect(!sibling1.prototype.contains(&sibling2.prototype));
    try std.testing.expect(!sibling2.prototype.contains(&sibling1.prototype));

    // But parent contains both
    try std.testing.expect(parent.prototype.contains(&sibling1.prototype));
    try std.testing.expect(parent.prototype.contains(&sibling2.prototype));
}
