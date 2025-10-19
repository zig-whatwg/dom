// META: title=Element.firstElementChild
// META: link=https://dom.spec.whatwg.org/#dom-parentnode-firstelementchild

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;
const NodeType = dom.NodeType;

test "firstElementChild: basic functionality" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add text node (not an element)
    const text1 = try doc.createTextNode("The result of this test is ");
    _ = try parent.prototype.appendChild(&text1.prototype);

    // Add first element child
    const child1 = try doc.createElement("child");
    try child1.setAttribute("data-id", "first_element_child");
    _ = try parent.prototype.appendChild(&child1.prototype);

    // Get firstElementChild
    const fec = parent.firstElementChild();
    try std.testing.expect(fec != null);
    try std.testing.expectEqual(NodeType.element, fec.?.prototype.node_type);

    const id_attr = fec.?.getAttribute("data-id");
    try std.testing.expect(id_attr != null);
    try std.testing.expectEqualStrings("first_element_child", id_attr.?);
}

test "firstElementChild: null when no children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    try std.testing.expectEqual(@as(?*Element, null), parent.firstElementChild());
}

test "firstElementChild: null when only text children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text = try doc.createTextNode("only text");
    _ = try parent.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(@as(?*Element, null), parent.firstElementChild());
}

test "firstElementChild: skips non-element nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add various non-element nodes
    const text1 = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text1.prototype);

    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    const text2 = try doc.createTextNode("more text");
    _ = try parent.prototype.appendChild(&text2.prototype);

    // Add first element
    const child = try doc.createElement("child");
    try child.setAttribute("data-id", "target");
    _ = try parent.prototype.appendChild(&child.prototype);

    // Add more stuff after
    const text3 = try doc.createTextNode("after");
    _ = try parent.prototype.appendChild(&text3.prototype);

    const fec = parent.firstElementChild();
    try std.testing.expect(fec != null);

    const id_attr = fec.?.getAttribute("data-id");
    try std.testing.expect(id_attr != null);
    try std.testing.expectEqualStrings("target", id_attr.?);
}

test "firstElementChild: with multiple element children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add multiple elements
    const child1 = try doc.createElement("child1");
    try child1.setAttribute("data-id", "first");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    try child2.setAttribute("data-id", "second");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const child3 = try doc.createElement("child3");
    try child3.setAttribute("data-id", "third");
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Should return first element
    const fec = parent.firstElementChild();
    try std.testing.expect(fec != null);
    try std.testing.expectEqualStrings("child1", fec.?.tag_name);

    const id_attr = fec.?.getAttribute("data-id");
    try std.testing.expect(id_attr != null);
    try std.testing.expectEqualStrings("first", id_attr.?);
}

test "firstElementChild: works on DocumentFragment" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    // Empty fragment
    try std.testing.expectEqual(@as(?*Element, null), frag.firstElementChild());

    // Add text node
    const text = try doc.createTextNode("text");
    _ = try frag.prototype.appendChild(&text.prototype);
    try std.testing.expectEqual(@as(?*Element, null), frag.firstElementChild());

    // Add element
    const elem = try doc.createElement("elem");
    _ = try frag.prototype.appendChild(&elem.prototype);
    try std.testing.expectEqual(elem, frag.firstElementChild());
}

test "firstElementChild: works on Document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Empty document
    try std.testing.expectEqual(@as(?*Element, null), doc.firstElementChild());

    // Add root element
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try std.testing.expectEqual(root, doc.firstElementChild());
}
