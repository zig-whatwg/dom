const std = @import("std");
const dom = @import("dom");

const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Node = dom.Node;
const NodeIterator = dom.NodeIterator;
const NodeFilter = dom.NodeFilter;
const FilterResult = dom.FilterResult;

test "NodeIterator basic forward iteration" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Build tree: root -> [elem1, text1, elem2]
    const root = try doc.createElement("root");
    const elem1 = try doc.createElement("child1");
    const text1 = try doc.createTextNode("text");
    const elem2 = try doc.createElement("child2");
    _ = try root.prototype.appendChild(&elem1.prototype);
    _ = try root.prototype.appendChild(&text1.prototype);
    _ = try root.prototype.appendChild(&elem2.prototype);

    // Append root to document so it gets cleaned up
    _ = try doc.prototype.appendChild(&root.prototype);

    const iterator = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ALL, null);
    // No need to deinit - arena allocated, freed with document

    // Should return root, then children in order
    try std.testing.expectEqual(&root.prototype, iterator.nextNode().?);
    try std.testing.expectEqual(&elem1.prototype, iterator.nextNode().?);
    try std.testing.expectEqual(&text1.prototype, iterator.nextNode().?);
    try std.testing.expectEqual(&elem2.prototype, iterator.nextNode().?);
    try std.testing.expect(iterator.nextNode() == null);
}

test "NodeIterator backward iteration" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try root.prototype.appendChild(&child1.prototype);
    _ = try root.prototype.appendChild(&child2.prototype);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iterator = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ALL, null);
    // No need to deinit - arena allocated, freed with document

    // Move to end
    while (iterator.nextNode()) |_| {}

    // Go backward
    try std.testing.expectEqual(&child2.prototype, iterator.previousNode().?);
    try std.testing.expectEqual(&child1.prototype, iterator.previousNode().?);
    try std.testing.expectEqual(&root.prototype, iterator.previousNode().?);
    try std.testing.expect(iterator.previousNode() == null);
}

test "NodeIterator filter by node type" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const elem1 = try doc.createElement("child1");
    const text1 = try doc.createTextNode("text");
    const elem2 = try doc.createElement("child2");
    _ = try root.prototype.appendChild(&elem1.prototype);
    _ = try root.prototype.appendChild(&text1.prototype);
    _ = try root.prototype.appendChild(&elem2.prototype);
    _ = try doc.prototype.appendChild(&root.prototype);

    // Only show elements
    const iterator = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ELEMENT, null);
    // No need to deinit - arena allocated, freed with document

    // Should skip text node
    try std.testing.expectEqual(&root.prototype, iterator.nextNode().?);
    try std.testing.expectEqual(&elem1.prototype, iterator.nextNode().?);
    try std.testing.expectEqual(&elem2.prototype, iterator.nextNode().?);
    try std.testing.expect(iterator.nextNode() == null);
}

test "NodeIterator detach does nothing" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const iterator = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ALL, null);
    // No need to deinit - arena allocated, freed with document

    iterator.detach(); // Should be no-op
    try std.testing.expectEqual(&root.prototype, iterator.nextNode().?);
}
