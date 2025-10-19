//! tree_helpers Tests
//!
//! Tests for tree_helpers functionality.

const std = @import("std");
const dom = @import("dom");

const testing = std.testing;
const tree_helpers = dom.tree_helpers;
const Node = dom.Node;
const Document = dom.Document;
const Element = dom.Element;
test "tree_helpers - tree_helpers.isInclusiveDescendant with same node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Node is its own inclusive descendant
    try std.testing.expect(tree_helpers.isInclusiveDescendant(&elem.prototype, &elem.prototype));
}

test "tree_helpers - tree_helpers.isInclusiveDescendant with ancestor" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child = try doc.createElement("item");
    defer child.prototype.release();

    // Manually set up parent-child relationship
    child.prototype.parent_node = &parent.prototype;

    // Child is inclusive descendant of parent
    try std.testing.expect(tree_helpers.isInclusiveDescendant(&child.prototype, &parent.prototype));

    // Parent is NOT descendant of child
    try std.testing.expect(!tree_helpers.isInclusiveDescendant(&parent.prototype, &child.prototype));

    // Clean up
    child.prototype.parent_node = null;
}

test "tree_helpers - tree_helpers.getDescendantTextContent empty" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // No children - empty string
    const content = try tree_helpers.getDescendantTextContent(&elem.prototype, allocator);
    defer allocator.free(content);

    try std.testing.expectEqualStrings("", content);
}

test "tree_helpers - tree_helpers.getDescendantTextContent with text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();

    // Manually add text as child
    elem.prototype.first_child = &text.prototype;
    elem.prototype.last_child = &text.prototype;
    text.prototype.parent_node = &elem.prototype;

    const content = try tree_helpers.getDescendantTextContent(&elem.prototype, allocator);
    defer allocator.free(content);

    try std.testing.expectEqualStrings("Hello", content);

    // Clean up
    elem.prototype.first_child = null;
    elem.prototype.last_child = null;
    text.prototype.parent_node = null;
}

test "tree_helpers - tree_helpers.getDescendantTextContent nested" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("element");
    defer div.prototype.release();

    const span = try doc.createElement("item");
    defer span.prototype.release();

    const text1 = try doc.createTextNode("Hello");
    defer text1.prototype.release();

    const text2 = try doc.createTextNode(" World");
    defer text2.prototype.release();

    // Structure: <div><span>Hello</span> World</div>
    div.prototype.first_child = &span.prototype;
    div.prototype.last_child = &text2.prototype;

    span.prototype.parent_node = &div.prototype;
    span.prototype.next_sibling = &text2.prototype;
    span.prototype.first_child = &text1.prototype;
    span.prototype.last_child = &text1.prototype;

    text1.prototype.parent_node = &span.prototype;

    text2.prototype.parent_node = &div.prototype;
    text2.prototype.previous_sibling = &span.prototype;

    const content = try tree_helpers.getDescendantTextContent(&div.prototype, allocator);
    defer allocator.free(content);

    try std.testing.expectEqualStrings("Hello World", content);

    // Clean up
    div.prototype.first_child = null;
    div.prototype.last_child = null;
    span.prototype.parent_node = null;
    span.prototype.next_sibling = null;
    span.prototype.first_child = null;
    span.prototype.last_child = null;
    text1.prototype.parent_node = null;
    text2.prototype.parent_node = null;
    text2.prototype.previous_sibling = null;
}

test "tree_helpers - tree_helpers.setDescendantsConnected" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child = try doc.createElement("item");
    defer child.prototype.release();

    // Manually connect
    parent.prototype.first_child = &child.prototype;
    child.prototype.parent_node = &parent.prototype;

    // Initially not connected
    try std.testing.expect(!child.prototype.isConnected());

    // Set connected
    child.prototype.setConnected(true);
    tree_helpers.setDescendantsConnected(&parent.prototype, true);

    try std.testing.expect(child.prototype.isConnected());

    // Set disconnected
    tree_helpers.setDescendantsConnected(&parent.prototype, false);
    try std.testing.expect(!child.prototype.isConnected());

    // Clean up
    parent.prototype.first_child = null;
    child.prototype.parent_node = null;
}

test "tree_helpers - tree_helpers.removeAllChildren" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    defer child1.prototype.release();

    const child2 = try doc.createElement("text-block");
    defer child2.prototype.release();

    // Manually add children
    parent.prototype.first_child = &child1.prototype;
    parent.prototype.last_child = &child2.prototype;

    child1.prototype.parent_node = &parent.prototype;
    child1.prototype.next_sibling = &child2.prototype;
    child1.prototype.setHasParent(true);

    child2.prototype.parent_node = &parent.prototype;
    child2.prototype.previous_sibling = &child1.prototype;
    child2.prototype.setHasParent(true);

    // Remove all
    tree_helpers.removeAllChildren(&parent.prototype);

    try std.testing.expect(parent.prototype.first_child == null);
    try std.testing.expect(parent.prototype.last_child == null);
    try std.testing.expect(child1.prototype.parent_node == null);
    try std.testing.expect(child2.prototype.parent_node == null);
    try std.testing.expect(!child1.prototype.hasParent());
    try std.testing.expect(!child2.prototype.hasParent());
}

test "tree_helpers - tree_helpers.hasElementChild" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    // Parent with only text child
    parent.prototype.first_child = &text.prototype;
    text.prototype.parent_node = &parent.prototype;

    try std.testing.expect(!tree_helpers.hasElementChild(&parent.prototype));

    // Add element child
    parent.prototype.last_child = &elem.prototype;
    text.prototype.next_sibling = &elem.prototype;
    elem.prototype.parent_node = &parent.prototype;
    elem.prototype.previous_sibling = &text.prototype;

    try std.testing.expect(tree_helpers.hasElementChild(&parent.prototype));

    // Clean up
    parent.prototype.first_child = null;
    parent.prototype.last_child = null;
    text.prototype.parent_node = null;
    text.prototype.next_sibling = null;
    elem.prototype.parent_node = null;
    elem.prototype.previous_sibling = null;
}

test "tree_helpers - tree_helpers.countElementChildren" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    try std.testing.expectEqual(@as(usize, 0), tree_helpers.countElementChildren(&parent.prototype));

    const elem1 = try doc.createElement("item");
    defer elem1.prototype.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    const elem2 = try doc.createElement("text-block");
    defer elem2.prototype.release();

    // Structure: elem1, text, elem2
    parent.prototype.first_child = &elem1.prototype;
    parent.prototype.last_child = &elem2.prototype;

    elem1.prototype.parent_node = &parent.prototype;
    elem1.prototype.next_sibling = &text.prototype;

    text.prototype.parent_node = &parent.prototype;
    text.prototype.previous_sibling = &elem1.prototype;
    text.prototype.next_sibling = &elem2.prototype;

    elem2.prototype.parent_node = &parent.prototype;
    elem2.prototype.previous_sibling = &text.prototype;

    try std.testing.expectEqual(@as(usize, 2), tree_helpers.countElementChildren(&parent.prototype));

    // Clean up
    parent.prototype.first_child = null;
    parent.prototype.last_child = null;
    elem1.prototype.parent_node = null;
    elem1.prototype.next_sibling = null;
    text.prototype.parent_node = null;
    text.prototype.previous_sibling = null;
    text.prototype.next_sibling = null;
    elem2.prototype.parent_node = null;
    elem2.prototype.previous_sibling = null;
}

