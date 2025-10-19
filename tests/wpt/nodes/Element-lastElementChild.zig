// META: title=Element.lastElementChild
// META: link=https://dom.spec.whatwg.org/#dom-parentnode-lastelementchild

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;
const NodeType = dom.NodeType;

test "lastElementChild: basic functionality" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add first element child
    const child1 = try doc.createElement("child1");
    try child1.setAttribute("data-id", "first_element_child");
    _ = try parent.prototype.appendChild(&child1.prototype);

    // Add text node
    const text1 = try doc.createTextNode(" is ");
    _ = try parent.prototype.appendChild(&text1.prototype);

    // Add last element child
    const child2 = try doc.createElement("child2");
    try child2.setAttribute("data-id", "last_element_child");
    _ = try parent.prototype.appendChild(&child2.prototype);

    // Add text after (not an element)
    const text2 = try doc.createTextNode(" above.");
    _ = try parent.prototype.appendChild(&text2.prototype);

    // Get lastElementChild
    const lec = parent.lastElementChild();
    try std.testing.expect(lec != null);
    try std.testing.expectEqual(NodeType.element, lec.?.prototype.node_type);

    const id_attr = lec.?.getAttribute("data-id");
    try std.testing.expect(id_attr != null);
    try std.testing.expectEqualStrings("last_element_child", id_attr.?);
}

test "lastElementChild: null when no children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    try std.testing.expectEqual(@as(?*Element, null), parent.lastElementChild());
}

test "lastElementChild: null when only text children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text = try doc.createTextNode("only text");
    _ = try parent.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(@as(?*Element, null), parent.lastElementChild());
}

test "lastElementChild: skips non-element nodes at end" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add text before
    const text1 = try doc.createTextNode("before");
    _ = try parent.prototype.appendChild(&text1.prototype);

    // Add element (should be last element)
    const child = try doc.createElement("child");
    try child.setAttribute("data-id", "target");
    _ = try parent.prototype.appendChild(&child.prototype);

    // Add various non-element nodes after
    const text2 = try doc.createTextNode("text after");
    _ = try parent.prototype.appendChild(&text2.prototype);

    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    const text3 = try doc.createTextNode("more text");
    _ = try parent.prototype.appendChild(&text3.prototype);

    const lec = parent.lastElementChild();
    try std.testing.expect(lec != null);

    const id_attr = lec.?.getAttribute("data-id");
    try std.testing.expect(id_attr != null);
    try std.testing.expectEqualStrings("target", id_attr.?);
}

test "lastElementChild: with multiple element children" {
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

    // Should return last element
    const lec = parent.lastElementChild();
    try std.testing.expect(lec != null);
    try std.testing.expectEqualStrings("child3", lec.?.tag_name);

    const id_attr = lec.?.getAttribute("data-id");
    try std.testing.expect(id_attr != null);
    try std.testing.expectEqualStrings("third", id_attr.?);
}

test "lastElementChild: single element is both first and last" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("only-child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(child, parent.firstElementChild());
    try std.testing.expectEqual(child, parent.lastElementChild());
    try std.testing.expectEqual(parent.firstElementChild(), parent.lastElementChild());
}

test "lastElementChild: works on DocumentFragment" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    // Empty fragment
    try std.testing.expectEqual(@as(?*Element, null), frag.lastElementChild());

    // Add elements
    const elem1 = try doc.createElement("elem1");
    _ = try frag.prototype.appendChild(&elem1.prototype);

    const text = try doc.createTextNode("text");
    _ = try frag.prototype.appendChild(&text.prototype);

    const elem2 = try doc.createElement("elem2");
    _ = try frag.prototype.appendChild(&elem2.prototype);

    // elem2 is last element, even with text after
    const comment = try doc.createComment("after");
    _ = try frag.prototype.appendChild(&comment.prototype);

    try std.testing.expectEqual(elem2, frag.lastElementChild());
}

test "lastElementChild: works on Document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Empty document
    try std.testing.expectEqual(@as(?*Element, null), doc.lastElementChild());

    // Add root element
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try std.testing.expectEqual(root, doc.lastElementChild());
}
