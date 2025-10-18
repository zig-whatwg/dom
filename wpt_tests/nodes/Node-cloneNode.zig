// META: title=Node.cloneNode
// META: link=https://dom.spec.whatwg.org/#dom-node-clonenode

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Node = dom.Node;

test "cloneNode() shallow copy of element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("div");
    const copy = try element.node.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&element.node != copy);

    // Should have same nodeType and nodeName
    try std.testing.expectEqual(element.node.node_type, copy.node_type);
    try std.testing.expect(std.mem.eql(u8, element.node.nodeName(), copy.nodeName()));
}

test "cloneNode() shallow copy does not clone children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");
    _ = try parent.node.appendChild(&child.node);

    const copy = try parent.node.cloneNode(false);
    defer copy.release();

    // Original has children
    try std.testing.expect(parent.node.hasChildNodes());

    // Copy should not have children
    try std.testing.expect(!copy.hasChildNodes());
}

test "cloneNode() deep copy clones children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");
    const grandchild = try doc.createElement("p");

    _ = try child.node.appendChild(&grandchild.node);
    _ = try parent.node.appendChild(&child.node);

    const copy = try parent.node.cloneNode(true);
    defer copy.release();

    // Original has children
    try std.testing.expect(parent.node.hasChildNodes());

    // Copy should also have children
    try std.testing.expect(copy.hasChildNodes());

    // Copy should have same number of children (but different objects)
    try std.testing.expect(copy.first_child != null);
    try std.testing.expect(copy.first_child.? != parent.node.first_child.?);
}

test "cloneNode() copies attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("div");
    try element.setAttribute("id", "test");
    try element.setAttribute("class", "foo bar");

    const copy_node = try element.node.cloneNode(false);
    defer copy_node.release();

    // Get the Element from the cloned Node
    const copy: *Element = @fieldParentPtr("node", copy_node);

    // Attributes should be copied
    try std.testing.expect(copy.getAttribute("id") != null);
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("id").?, "test"));
    try std.testing.expect(copy.getAttribute("class") != null);
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("class").?, "foo bar"));
}

test "cloneNode() text node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello, world!");
    const copy = try text.node.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&text.node != copy);

    // Should have same node type
    try std.testing.expectEqual(text.node.node_type, copy.node_type);

    // Should have same text content
    const copy_text: *Text = @fieldParentPtr("node", copy);
    try std.testing.expect(std.mem.eql(u8, text.data, copy_text.data));
}

test "cloneNode() comment node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    const copy = try comment.node.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&comment.node != copy);

    // Should have same node type
    try std.testing.expectEqual(comment.node.node_type, copy.node_type);

    // Should have same comment data
    const copy_comment: *Comment = @fieldParentPtr("node", copy);
    try std.testing.expect(std.mem.eql(u8, comment.data, copy_comment.data));
}

test "cloneNode() preserves owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("div");
    const copy = try element.node.cloneNode(false);
    defer copy.release();

    // Both should have same owner document
    try std.testing.expect(element.node.getOwnerDocument() == copy.getOwnerDocument());
    try std.testing.expect(copy.getOwnerDocument() == doc);
}
