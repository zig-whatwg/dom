//! DOM tree helper functions for tree manipulation and queries
//!
//! This module provides utility functions for:
//! - Tree traversal (ancestor/descendant checks)
//! - Text content collection
//! - Connected state propagation
//!
//! Spec: https://dom.spec.whatwg.org/

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;

/// Returns true if other is an inclusive descendant of node.
///
/// Inclusive descendant means other equals node, or other is a descendant of node.
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-tree-inclusive-descendant
pub fn isInclusiveDescendant(other: *const Node, node: *const Node) bool {
    // Check if same node
    if (other == node) return true;

    // Walk up from other looking for node
    var current = other.parent_node;
    while (current) |p| {
        if (p == node) return true;
        current = p.parent_node;
    }

    return false;
}

/// Returns descendant text content by concatenating all Text node data.
///
/// This performs a tree-order traversal collecting text from all Text nodes.
/// Used for Node.textContent getter on Element and DocumentFragment nodes.
///
/// ## Memory
/// Returns owned string - caller must free with allocator.
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-child-text-content
pub fn getDescendantTextContent(
    node: *const Node,
    allocator: Allocator,
) ![]u8 {
    var list: std.ArrayList(u8) = .empty;
    errdefer list.deinit(allocator);

    try collectTextContent(node, &list, allocator);

    return try list.toOwnedSlice(allocator);
}

/// Recursively collects text content from node and all descendants.
fn collectTextContent(node: *const Node, list: *std.ArrayList(u8), allocator: Allocator) !void {
    const TextNode = @import("text.zig").Text;

    var current = node.first_child;
    while (current) |child| {
        // Save next sibling before any operations
        const next = child.next_sibling;

        // If text node, append its data
        if (child.node_type == .text) {
            const text: *const TextNode = @fieldParentPtr("node", child);
            try list.appendSlice(allocator, text.data);
        }

        // Recurse into all children (not just text nodes)
        try collectTextContent(child, list, allocator);

        current = next;
    }
}

/// Sets connected state for node and all its descendants recursively.
///
/// Called when inserting/removing nodes to propagate connected state changes.
/// Must traverse entire subtree.
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#connected
pub fn setDescendantsConnected(node: *Node, connected: bool) void {
    var current = node.first_child;
    while (current) |child| {
        // Save next sibling BEFORE any operations that might modify it
        const next = child.next_sibling;

        child.setConnected(connected);

        // Recurse into children
        setDescendantsConnected(child, connected);

        // Use saved next pointer
        current = next;
    }
}

/// Removes all children from parent node.
///
/// Used by textContent setter and normalize() operations.
/// Releases all children (decrements ref counts).
pub fn removeAllChildren(parent: *Node) void {
    var current = parent.first_child;
    while (current) |child| {
        const next = child.next_sibling;

        // Clear child's parent pointers
        child.parent_node = null;
        child.previous_sibling = null;
        child.next_sibling = null;
        child.setHasParent(false);

        // Update connected state
        if (child.isConnected()) {
            child.setConnected(false);
            setDescendantsConnected(child, false);
        }

        // Release parent's ownership
        child.release();

        current = next;
    }

    // Clear parent's child pointers
    parent.first_child = null;
    parent.last_child = null;
}

/// Returns true if node has any element children.
///
/// Helper for checking if DocumentFragment has element children during validation.
pub fn hasElementChild(node: *const Node) bool {
    var current = node.first_child;
    while (current) |child| {
        if (child.node_type == .element) return true;
        current = child.next_sibling;
    }
    return false;
}

/// Counts element children of a node.
///
/// Helper for DocumentFragment validation during insertion.
pub fn countElementChildren(node: *const Node) usize {
    var count: usize = 0;
    var current = node.first_child;
    while (current) |child| {
        if (child.node_type == .element) count += 1;
        current = child.next_sibling;
    }
    return count;
}

/// Returns the first descendant of a node in tree order.
///
/// Used by normalize() to start tree traversal.
/// Simply returns the first child (if any).
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-tree-order
pub fn getFirstDescendant(node: *const Node) ?*Node {
    return node.first_child;
}

/// Returns the next node in tree order within a boundary.
///
/// Used by normalize() for depth-first tree traversal.
/// Returns null when reaching the boundary node or end of tree.
///
/// ## Algorithm
/// 1. If node has children, return first child (go deeper)
/// 2. If node has next sibling, return it (go right)
/// 3. Walk up ancestors looking for next sibling (go up and right)
/// 4. Stop at boundary node
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-tree-order
pub fn getNextNodeInTree(node: *const Node, boundary: *const Node) ?*Node {
    // If node has children, return first child (depth-first)
    if (node.first_child) |child| {
        return child;
    }

    // If node is the boundary, we're done
    if (node == boundary) {
        return null;
    }

    // Otherwise, walk up to find next sibling
    var current = node;
    while (true) {
        // Try next sibling
        if (current.next_sibling) |sibling| {
            return sibling;
        }

        // Move to parent
        const parent = current.parent_node orelse return null;

        // Stop at boundary
        if (parent == boundary) {
            return null;
        }

        current = parent;
    }
}

// ============================================================================
// TESTS
// ============================================================================

const Element = @import("element.zig").Element;
const Text = @import("text.zig").Text;
const Document = @import("document.zig").Document;

test "tree_helpers - isInclusiveDescendant with same node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.node.release();

    // Node is its own inclusive descendant
    try std.testing.expect(isInclusiveDescendant(&elem.node, &elem.node));
}

test "tree_helpers - isInclusiveDescendant with ancestor" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child = try doc.createElement("item");
    defer child.node.release();

    // Manually set up parent-child relationship
    child.node.parent_node = &parent.node;

    // Child is inclusive descendant of parent
    try std.testing.expect(isInclusiveDescendant(&child.node, &parent.node));

    // Parent is NOT descendant of child
    try std.testing.expect(!isInclusiveDescendant(&parent.node, &child.node));

    // Clean up
    child.node.parent_node = null;
}

test "tree_helpers - getDescendantTextContent empty" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.node.release();

    // No children - empty string
    const content = try getDescendantTextContent(&elem.node, allocator);
    defer allocator.free(content);

    try std.testing.expectEqualStrings("", content);
}

test "tree_helpers - getDescendantTextContent with text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.node.release();

    const text = try doc.createTextNode("Hello");
    defer text.node.release();

    // Manually add text as child
    elem.node.first_child = &text.node;
    elem.node.last_child = &text.node;
    text.node.parent_node = &elem.node;

    const content = try getDescendantTextContent(&elem.node, allocator);
    defer allocator.free(content);

    try std.testing.expectEqualStrings("Hello", content);

    // Clean up
    elem.node.first_child = null;
    elem.node.last_child = null;
    text.node.parent_node = null;
}

test "tree_helpers - getDescendantTextContent nested" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("element");
    defer div.node.release();

    const span = try doc.createElement("item");
    defer span.node.release();

    const text1 = try doc.createTextNode("Hello");
    defer text1.node.release();

    const text2 = try doc.createTextNode(" World");
    defer text2.node.release();

    // Structure: <div><span>Hello</span> World</div>
    div.node.first_child = &span.node;
    div.node.last_child = &text2.node;

    span.node.parent_node = &div.node;
    span.node.next_sibling = &text2.node;
    span.node.first_child = &text1.node;
    span.node.last_child = &text1.node;

    text1.node.parent_node = &span.node;

    text2.node.parent_node = &div.node;
    text2.node.previous_sibling = &span.node;

    const content = try getDescendantTextContent(&div.node, allocator);
    defer allocator.free(content);

    try std.testing.expectEqualStrings("Hello World", content);

    // Clean up
    div.node.first_child = null;
    div.node.last_child = null;
    span.node.parent_node = null;
    span.node.next_sibling = null;
    span.node.first_child = null;
    span.node.last_child = null;
    text1.node.parent_node = null;
    text2.node.parent_node = null;
    text2.node.previous_sibling = null;
}

test "tree_helpers - setDescendantsConnected" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child = try doc.createElement("item");
    defer child.node.release();

    // Manually connect
    parent.node.first_child = &child.node;
    child.node.parent_node = &parent.node;

    // Initially not connected
    try std.testing.expect(!child.node.isConnected());

    // Set connected
    child.node.setConnected(true);
    setDescendantsConnected(&parent.node, true);

    try std.testing.expect(child.node.isConnected());

    // Set disconnected
    setDescendantsConnected(&parent.node, false);
    try std.testing.expect(!child.node.isConnected());

    // Clean up
    parent.node.first_child = null;
    child.node.parent_node = null;
}

test "tree_helpers - removeAllChildren" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const child1 = try doc.createElement("item");
    defer child1.node.release();

    const child2 = try doc.createElement("text-block");
    defer child2.node.release();

    // Manually add children
    parent.node.first_child = &child1.node;
    parent.node.last_child = &child2.node;

    child1.node.parent_node = &parent.node;
    child1.node.next_sibling = &child2.node;
    child1.node.setHasParent(true);

    child2.node.parent_node = &parent.node;
    child2.node.previous_sibling = &child1.node;
    child2.node.setHasParent(true);

    // Remove all
    removeAllChildren(&parent.node);

    try std.testing.expect(parent.node.first_child == null);
    try std.testing.expect(parent.node.last_child == null);
    try std.testing.expect(child1.node.parent_node == null);
    try std.testing.expect(child2.node.parent_node == null);
    try std.testing.expect(!child1.node.hasParent());
    try std.testing.expect(!child2.node.hasParent());
}

test "tree_helpers - hasElementChild" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    const text = try doc.createTextNode("text");
    defer text.node.release();

    const elem = try doc.createElement("item");
    defer elem.node.release();

    // Parent with only text child
    parent.node.first_child = &text.node;
    text.node.parent_node = &parent.node;

    try std.testing.expect(!hasElementChild(&parent.node));

    // Add element child
    parent.node.last_child = &elem.node;
    text.node.next_sibling = &elem.node;
    elem.node.parent_node = &parent.node;
    elem.node.previous_sibling = &text.node;

    try std.testing.expect(hasElementChild(&parent.node));

    // Clean up
    parent.node.first_child = null;
    parent.node.last_child = null;
    text.node.parent_node = null;
    text.node.next_sibling = null;
    elem.node.parent_node = null;
    elem.node.previous_sibling = null;
}

test "tree_helpers - countElementChildren" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.node.release();

    try std.testing.expectEqual(@as(usize, 0), countElementChildren(&parent.node));

    const elem1 = try doc.createElement("item");
    defer elem1.node.release();

    const text = try doc.createTextNode("text");
    defer text.node.release();

    const elem2 = try doc.createElement("text-block");
    defer elem2.node.release();

    // Structure: elem1, text, elem2
    parent.node.first_child = &elem1.node;
    parent.node.last_child = &elem2.node;

    elem1.node.parent_node = &parent.node;
    elem1.node.next_sibling = &text.node;

    text.node.parent_node = &parent.node;
    text.node.previous_sibling = &elem1.node;
    text.node.next_sibling = &elem2.node;

    elem2.node.parent_node = &parent.node;
    elem2.node.previous_sibling = &text.node;

    try std.testing.expectEqual(@as(usize, 2), countElementChildren(&parent.node));

    // Clean up
    parent.node.first_child = null;
    parent.node.last_child = null;
    elem1.node.parent_node = null;
    elem1.node.next_sibling = null;
    text.node.parent_node = null;
    text.node.previous_sibling = null;
    text.node.next_sibling = null;
    elem2.node.parent_node = null;
    elem2.node.previous_sibling = null;
}
