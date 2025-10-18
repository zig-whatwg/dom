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
    const result = elem.node.compareDocumentPosition(&elem.node);
    try std.testing.expectEqual(@as(u16, 0), result);
}

test "compareDocumentPosition: other is ancestor (CONTAINS + PRECEDING)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");
    const grandchild = try doc.createElement("p");

    _ = try parent.node.appendChild(&child.node);
    _ = try child.node.appendChild(&grandchild.node);

    // parent compared to grandchild: parent contains and precedes grandchild
    const result = grandchild.node.compareDocumentPosition(&parent.node);
    const expected = Node.DOCUMENT_POSITION_CONTAINS | Node.DOCUMENT_POSITION_PRECEDING;
    try std.testing.expectEqual(expected, result);
}

test "compareDocumentPosition: other is descendant (CONTAINED_BY + FOLLOWING)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");
    const grandchild = try doc.createElement("p");

    _ = try parent.node.appendChild(&child.node);
    _ = try child.node.appendChild(&grandchild.node);

    // parent compared to grandchild: parent contains and grandchild follows
    const result = parent.node.compareDocumentPosition(&grandchild.node);
    const expected = Node.DOCUMENT_POSITION_CONTAINED_BY | Node.DOCUMENT_POSITION_FOLLOWING;
    try std.testing.expectEqual(expected, result);
}

test "compareDocumentPosition: preceding sibling" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const sibling1 = try doc.createElement("span");
    const sibling2 = try doc.createElement("p");

    _ = try parent.node.appendChild(&sibling1.node);
    _ = try parent.node.appendChild(&sibling2.node);

    // sibling2 compared to sibling1: sibling1 precedes
    const result = sibling2.node.compareDocumentPosition(&sibling1.node);
    try std.testing.expectEqual(Node.DOCUMENT_POSITION_PRECEDING, result);
}

test "compareDocumentPosition: following sibling" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const sibling1 = try doc.createElement("span");
    const sibling2 = try doc.createElement("p");

    _ = try parent.node.appendChild(&sibling1.node);
    _ = try parent.node.appendChild(&sibling2.node);

    // sibling1 compared to sibling2: sibling2 follows
    const result = sibling1.node.compareDocumentPosition(&sibling2.node);
    try std.testing.expectEqual(Node.DOCUMENT_POSITION_FOLLOWING, result);
}

test "compareDocumentPosition: disconnected nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    const elem2 = try doc.createElement("span");

    // Disconnected nodes should return DISCONNECTED + IMPLEMENTATION_SPECIFIC + (PRECEDING or FOLLOWING)
    const result = elem1.node.compareDocumentPosition(&elem2.node);
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
    const child = try doc.createElement("span");

    _ = try parent.node.appendChild(&child.node);

    // Parent contains child
    const parent_to_child = parent.node.compareDocumentPosition(&child.node);
    const expected_parent = Node.DOCUMENT_POSITION_CONTAINED_BY | Node.DOCUMENT_POSITION_FOLLOWING;
    try std.testing.expectEqual(expected_parent, parent_to_child);

    // Child is contained by parent
    const child_to_parent = child.node.compareDocumentPosition(&parent.node);
    const expected_child = Node.DOCUMENT_POSITION_CONTAINS | Node.DOCUMENT_POSITION_PRECEDING;
    try std.testing.expectEqual(expected_child, child_to_parent);
}
