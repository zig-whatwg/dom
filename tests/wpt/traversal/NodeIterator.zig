// META: title=NodeIterator tests
// META: link=https://dom.spec.whatwg.org/#interface-nodeiterator

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Node = dom.Node;
const NodeType = dom.NodeType;
const NodeIterator = dom.NodeIterator;
const NodeFilter = dom.NodeFilter;
const FilterResult = dom.FilterResult;

fn createSampleDOM(doc: *Document) !*Element {
    const root = try doc.createElement("root");
    const elem1 = try doc.createElement("elem1");
    const text1 = try doc.createTextNode("text1");
    const elem2 = try doc.createElement("elem2");
    const comment1 = try doc.createComment("comment1");

    _ = try root.prototype.appendChild(&elem1.prototype);
    _ = try root.prototype.appendChild(&text1.prototype);
    _ = try root.prototype.appendChild(&elem2.prototype);
    _ = try root.prototype.appendChild(&comment1.prototype);

    return root;
}

test "detach() should be a no-op" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ALL, null);

    iter.detach();
    iter.detach();

    try std.testing.expectEqual(&root.prototype, iter.reference_node);
}

test "createNodeIterator() parameter defaults" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, 0xFFFFFFFF, null);

    try std.testing.expectEqual(&root.prototype, iter.root);
    try std.testing.expectEqual(@as(u32, 0xFFFFFFFF), iter.what_to_show);
    try std.testing.expectEqual(@as(?NodeFilter, null), iter.node_filter);
    try std.testing.expectEqual(&root.prototype, iter.reference_node);
    try std.testing.expectEqual(true, iter.pointer_before_reference_node);
}

test "createNodeIterator() with zero whatToShow" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, 0, null);

    try std.testing.expectEqual(&root.prototype, iter.root);
    try std.testing.expectEqual(@as(u32, 0), iter.what_to_show);
    try std.testing.expectEqual(&root.prototype, iter.reference_node);
}

test "createNodeIterator() with specific whatToShow" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, 42, null);

    try std.testing.expectEqual(&root.prototype, iter.root);
    try std.testing.expectEqual(&root.prototype, iter.reference_node);
    try std.testing.expectEqual(@as(u32, 42), iter.what_to_show);
    try std.testing.expectEqual(@as(?NodeFilter, null), iter.node_filter);
}

test "nextNode() returns nodes in document order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ALL, null);

    const node1 = iter.nextNode();
    try std.testing.expect(node1 != null);
    try std.testing.expectEqual(NodeType.element, node1.?.node_type);
    const elem1: *Element = @fieldParentPtr("prototype", node1.?);
    try std.testing.expectEqualStrings("root", elem1.tag_name);
    try std.testing.expectEqual(&root.prototype, iter.reference_node);
    try std.testing.expectEqual(false, iter.pointer_before_reference_node);

    const node2 = iter.nextNode();
    try std.testing.expect(node2 != null);
    try std.testing.expectEqual(NodeType.element, node2.?.node_type);
    const elem2: *Element = @fieldParentPtr("prototype", node2.?);
    try std.testing.expectEqualStrings("elem1", elem2.tag_name);
    try std.testing.expectEqual(node2.?, iter.reference_node);
    try std.testing.expectEqual(false, iter.pointer_before_reference_node);

    const node3 = iter.nextNode();
    try std.testing.expect(node3 != null);
    try std.testing.expectEqual(NodeType.text, node3.?.node_type);

    const node4 = iter.nextNode();
    try std.testing.expect(node4 != null);
    try std.testing.expectEqual(NodeType.element, node4.?.node_type);

    const node5 = iter.nextNode();
    try std.testing.expect(node5 != null);
    try std.testing.expectEqual(NodeType.comment, node5.?.node_type);

    const node6 = iter.nextNode();
    try std.testing.expect(node6 == null);
}

test "previousNode() returns nodes in reverse document order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ALL, null);

    while (iter.nextNode()) |_| {}

    const node1 = iter.previousNode();
    try std.testing.expect(node1 != null);
    try std.testing.expectEqual(NodeType.comment, node1.?.node_type);
    try std.testing.expectEqual(node1.?, iter.reference_node);
    try std.testing.expectEqual(true, iter.pointer_before_reference_node);

    const node2 = iter.previousNode();
    try std.testing.expect(node2 != null);
    try std.testing.expectEqual(NodeType.element, node2.?.node_type);

    const node3 = iter.previousNode();
    try std.testing.expect(node3 != null);
    try std.testing.expectEqual(NodeType.text, node3.?.node_type);

    const node4 = iter.previousNode();
    try std.testing.expect(node4 != null);
    try std.testing.expectEqual(NodeType.element, node4.?.node_type);

    const node5 = iter.previousNode();
    try std.testing.expect(node5 != null);
    try std.testing.expectEqual(NodeType.element, node5.?.node_type);
    const elem5: *Element = @fieldParentPtr("prototype", node5.?);
    try std.testing.expectEqualStrings("root", elem5.tag_name);

    const node6 = iter.previousNode();
    try std.testing.expect(node6 == null);
}

test "nextNode() with SHOW_ELEMENT filter" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ELEMENT, null);

    const node1 = iter.nextNode();
    try std.testing.expect(node1 != null);
    try std.testing.expectEqual(NodeType.element, node1.?.node_type);
    const elem1: *Element = @fieldParentPtr("prototype", node1.?);
    try std.testing.expectEqualStrings("root", elem1.tag_name);

    const node2 = iter.nextNode();
    try std.testing.expect(node2 != null);
    try std.testing.expectEqual(NodeType.element, node2.?.node_type);
    const elem2: *Element = @fieldParentPtr("prototype", node2.?);
    try std.testing.expectEqualStrings("elem1", elem2.tag_name);

    const node3 = iter.nextNode();
    try std.testing.expect(node3 != null);
    try std.testing.expectEqual(NodeType.element, node3.?.node_type);
    const elem3: *Element = @fieldParentPtr("prototype", node3.?);
    try std.testing.expectEqualStrings("elem2", elem3.tag_name);

    const node4 = iter.nextNode();
    try std.testing.expect(node4 == null);
}

test "nextNode() with SHOW_TEXT filter" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_TEXT, null);

    const node1 = iter.nextNode();
    try std.testing.expect(node1 != null);
    try std.testing.expectEqual(NodeType.text, node1.?.node_type);

    const node2 = iter.nextNode();
    try std.testing.expect(node2 == null);
}

test "nextNode() with SHOW_COMMENT filter" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_COMMENT, null);

    const node1 = iter.nextNode();
    try std.testing.expect(node1 != null);
    try std.testing.expectEqual(NodeType.comment, node1.?.node_type);

    const node2 = iter.nextNode();
    try std.testing.expect(node2 == null);
}

test "nextNode() with combined filters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT, null);

    const node1 = iter.nextNode();
    try std.testing.expect(node1 != null);
    try std.testing.expectEqual(NodeType.element, node1.?.node_type);

    const node2 = iter.nextNode();
    try std.testing.expect(node2 != null);
    try std.testing.expectEqual(NodeType.element, node2.?.node_type);

    const node3 = iter.nextNode();
    try std.testing.expect(node3 != null);
    try std.testing.expectEqual(NodeType.text, node3.?.node_type);

    const node4 = iter.nextNode();
    try std.testing.expect(node4 != null);
    try std.testing.expectEqual(NodeType.element, node4.?.node_type);

    const node5 = iter.nextNode();
    try std.testing.expect(node5 == null);
}

test "nextNode() does not traverse outside root" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const outer = try doc.createElement("outer");
    const inner = try doc.createElement("inner");
    const child = try doc.createElement("child");

    _ = try outer.prototype.appendChild(&inner.prototype);
    _ = try inner.prototype.appendChild(&child.prototype);
    _ = try doc.prototype.appendChild(&outer.prototype);

    const iter = try doc.createNodeIterator(&inner.prototype, NodeFilter.SHOW_ELEMENT, null);

    const node1 = iter.nextNode();
    try std.testing.expect(node1 != null);
    try std.testing.expectEqual(&inner.prototype, node1.?);

    const node2 = iter.nextNode();
    try std.testing.expect(node2 != null);
    try std.testing.expectEqual(&child.prototype, node2.?);

    const node3 = iter.nextNode();
    try std.testing.expect(node3 == null);
}

test "previousNode() does not traverse outside root" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const outer = try doc.createElement("outer");
    const inner = try doc.createElement("inner");
    const child = try doc.createElement("child");

    _ = try outer.prototype.appendChild(&inner.prototype);
    _ = try inner.prototype.appendChild(&child.prototype);
    _ = try doc.prototype.appendChild(&outer.prototype);

    const iter = try doc.createNodeIterator(&inner.prototype, NodeFilter.SHOW_ELEMENT, null);

    while (iter.nextNode()) |_| {}

    const node1 = iter.previousNode();
    try std.testing.expect(node1 != null);
    try std.testing.expectEqual(&child.prototype, node1.?);

    const node2 = iter.previousNode();
    try std.testing.expect(node2 != null);
    try std.testing.expectEqual(&inner.prototype, node2.?);

    const node3 = iter.previousNode();
    try std.testing.expect(node3 == null);
}

test "nested tree traversal with nextNode()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const level1a = try doc.createElement("level1a");
    const level1b = try doc.createElement("level1b");
    const level2a = try doc.createElement("level2a");
    const level2b = try doc.createElement("level2b");

    _ = try root.prototype.appendChild(&level1a.prototype);
    _ = try level1a.prototype.appendChild(&level2a.prototype);
    _ = try level1a.prototype.appendChild(&level2b.prototype);
    _ = try root.prototype.appendChild(&level1b.prototype);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ELEMENT, null);

    const nodes = [_]*Node{
        &root.prototype,
        &level1a.prototype,
        &level2a.prototype,
        &level2b.prototype,
        &level1b.prototype,
    };

    for (nodes) |expected| {
        const node = iter.nextNode();
        try std.testing.expect(node != null);
        try std.testing.expectEqual(expected, node.?);
    }

    try std.testing.expect(iter.nextNode() == null);
}

test "referenceNode and pointerBeforeReferenceNode tracking" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const child = try doc.createElement("child");
    _ = try root.prototype.appendChild(&child.prototype);
    _ = try doc.prototype.appendChild(&root.prototype);

    const iter = try doc.createNodeIterator(&root.prototype, NodeFilter.SHOW_ELEMENT, null);

    try std.testing.expectEqual(&root.prototype, iter.reference_node);
    try std.testing.expectEqual(true, iter.pointer_before_reference_node);

    _ = iter.nextNode();
    try std.testing.expectEqual(&root.prototype, iter.reference_node);
    try std.testing.expectEqual(false, iter.pointer_before_reference_node);

    _ = iter.nextNode();
    try std.testing.expectEqual(&child.prototype, iter.reference_node);
    try std.testing.expectEqual(false, iter.pointer_before_reference_node);

    _ = iter.previousNode();
    try std.testing.expectEqual(&child.prototype, iter.reference_node);
    try std.testing.expectEqual(true, iter.pointer_before_reference_node);

    _ = iter.previousNode();
    try std.testing.expectEqual(&root.prototype, iter.reference_node);
    try std.testing.expectEqual(true, iter.pointer_before_reference_node);
}
