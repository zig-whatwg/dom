// META: title=Node.compareDocumentPosition() tests
// META: link=https://dom.spec.whatwg.org/#dom-node-comparedocumentposition
// META: author=Aryeh Gregor, ayg@aryeh.name

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;

test "compareDocumentPosition with same node returns 0" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release(); // Must release orphaned nodes
    const result = elem.prototype.compareDocumentPosition(&elem.prototype);
    try std.testing.expectEqual(@as(u16, 0), result);
}

test "compareDocumentPosition: other is ancestor (CONTAINS + PRECEDING)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("span");
    const grandchild = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try child.prototype.appendChild(&grandchild.prototype);

    // parent compared to grandchild: parent contains and precedes grandchild
    const result = grandchild.prototype.compareDocumentPosition(&parent.prototype);
    const expected = Node.DOCUMENT_POSITION_CONTAINS | Node.DOCUMENT_POSITION_PRECEDING;
    try std.testing.expectEqual(expected, result);
}

test "compareDocumentPosition: other is descendant (CONTAINED_BY + FOLLOWING)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("span");
    const grandchild = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try child.prototype.appendChild(&grandchild.prototype);

    // parent compared to grandchild: parent contains and grandchild follows
    const result = parent.prototype.compareDocumentPosition(&grandchild.prototype);
    const expected = Node.DOCUMENT_POSITION_CONTAINED_BY | Node.DOCUMENT_POSITION_FOLLOWING;
    try std.testing.expectEqual(expected, result);
}

test "compareDocumentPosition: preceding sibling" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const sibling1 = try doc.createElement("span");
    const sibling2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&sibling1.prototype);
    _ = try parent.prototype.appendChild(&sibling2.prototype);

    // sibling2 compared to sibling1: sibling1 precedes
    const result = sibling2.prototype.compareDocumentPosition(&sibling1.prototype);
    try std.testing.expectEqual(Node.DOCUMENT_POSITION_PRECEDING, result);
}

test "compareDocumentPosition: following sibling" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const sibling1 = try doc.createElement("span");
    const sibling2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&sibling1.prototype);
    _ = try parent.prototype.appendChild(&sibling2.prototype);

    // sibling1 compared to sibling2: sibling2 follows
    const result = sibling1.prototype.compareDocumentPosition(&sibling2.prototype);
    try std.testing.expectEqual(Node.DOCUMENT_POSITION_FOLLOWING, result);
}

test "compareDocumentPosition: disconnected nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release(); // Must release orphaned nodes
    const elem2 = try doc.createElement("span");
    defer elem2.prototype.release(); // Must release orphaned nodes

    // Disconnected nodes should return DISCONNECTED + IMPLEMENTATION_SPECIFIC + (PRECEDING or FOLLOWING)
    const result = elem1.prototype.compareDocumentPosition(&elem2.prototype);
    const base_flags = Node.DOCUMENT_POSITION_DISCONNECTED | Node.DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC;

    // Should have base flags plus either PRECEDING or FOLLOWING
    const has_base_flags = (result & base_flags) == base_flags;
    const has_direction = (result & Node.DOCUMENT_POSITION_PRECEDING) != 0 or
        (result & Node.DOCUMENT_POSITION_FOLLOWING) != 0;

    try std.testing.expect(has_base_flags);
    try std.testing.expect(has_direction);
}

test "compareDocumentPosition: parent and child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    // Parent contains child
    const parent_to_child = parent.prototype.compareDocumentPosition(&child.prototype);
    const expected_parent = Node.DOCUMENT_POSITION_CONTAINED_BY | Node.DOCUMENT_POSITION_FOLLOWING;
    try std.testing.expectEqual(expected_parent, parent_to_child);

    // Child is contained by parent
    const child_to_parent = child.prototype.compareDocumentPosition(&parent.prototype);
    const expected_child = Node.DOCUMENT_POSITION_CONTAINS | Node.DOCUMENT_POSITION_PRECEDING;
    try std.testing.expectEqual(expected_child, child_to_parent);
}
