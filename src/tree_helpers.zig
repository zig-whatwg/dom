//! Tree Helper Utilities (§4.2)
//!
//! This module provides utility functions for DOM tree traversal, text content extraction,
//! and tree relationship checking. These helpers implement fundamental tree algorithms used
//! throughout the DOM implementation for operations like ancestor checking, text collection,
//! and connected state management.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.2 Trees**: https://dom.spec.whatwg.org/#trees
//! - **§4.2.1 Tree Terminology**: https://dom.spec.whatwg.org/#concept-tree
//! - **§5.3 Text Content**: https://dom.spec.whatwg.org/#concept-child-text-content
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node
//!
//! ## MDN Documentation
//!
//! - Node.textContent: https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent
//! - Node.contains(): https://developer.mozilla.org/en-US/docs/Web/API/Node/contains
//! - Document tree structure: https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model/Introduction
//! - Tree traversal: https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker
//!
//! ## Core Features
//!
//! ### Ancestor/Descendant Checking
//! Efficiently check tree relationships between nodes:
//! ```zig
//! const grandparent = try Element.create(allocator, "div");
//! defer grandparent.node.release();
//!
//! const parent = try Element.create(allocator, "div");
//! _ = try grandparent.node.appendChild(&parent.node);
//!
//! const child = try Element.create(allocator, "span");
//! _ = try parent.node.appendChild(&child.node);
//!
//! // Check descendant relationship
//! try std.testing.expect(isInclusiveDescendant(&child.node, &grandparent.node)); // true
//! try std.testing.expect(isInclusiveDescendant(&parent.node, &grandparent.node)); // true
//! try std.testing.expect(!isInclusiveDescendant(&grandparent.node, &child.node)); // false
//! ```
//!
//! ### Text Content Extraction
//! Collect all text from a subtree in document order:
//! ```zig
//! const div = try Element.create(allocator, "div");
//! defer div.node.release();
//!
//! const text1 = try Text.create(allocator, "Hello ");
//! _ = try div.node.appendChild(&text1.node);
//!
//! const span = try Element.create(allocator, "span");
//! _ = try div.node.appendChild(&span.node);
//!
//! const text2 = try Text.create(allocator, "World");
//! _ = try span.node.appendChild(&text2.node);
//!
//! const content = try getDescendantTextContent(&div.node, allocator);
//! defer allocator.free(content);
//! // content = "Hello World"
//! ```
//!
//! ### Connected State Management
//! Track whether nodes are connected to a document:
//! ```zig
//! const element = try Element.create(allocator, "div");
//! defer element.node.release();
//! // element.node.is_connected = false (not in document)
//!
//! const doc = try Document.init(allocator);
//! defer doc.release();
//! _ = try doc.node.appendChild(&element.node);
//! // element.node.is_connected = true (now connected)
//! ```
//!
//! ## Helper Functions
//!
//! This module provides the following utilities:
//!
//! **Tree Relationships:**
//! - `isInclusiveDescendant(other, node)` - Check if other is descendant of node (or same node)
//! - `isInclusiveAncestor(other, node)` - Check if other is ancestor of node (or same node)
//!
//! **Text Content:**
//! - `getDescendantTextContent(node, allocator)` - Collect all text from subtree
//! - `collectTextContent(node, list, allocator)` - Internal recursive text collector
//!
//! **Connected State:**
//! - `propagateConnectedState(node, is_connected)` - Update connected state recursively
//!
//! ## Memory Management
//!
//! Most helpers are pure (no allocation), except text content functions:
//! ```zig
//! // Pure helpers (no memory management)
//! const is_desc = isInclusiveDescendant(node1, node2);
//! // No cleanup needed
//!
//! // Text content (allocates string)
//! const text = try getDescendantTextContent(node, allocator);
//! defer allocator.free(text); // Caller must free
//! ```
//!
//! ## Usage Examples
//!
//! ### Safe Ancestor Check Before Insertion
//! ```zig
//! fn safeInsert(parent: *Node, child: *Node) !void {
//!     // Prevent circular references
//!     if (isInclusiveDescendant(parent, child)) {
//!         return error.HierarchyRequestError;
//!     }
//!
//!     _ = try parent.appendChild(child);
//! }
//! ```
//!
//! ### Extracting All Text Content
//! ```zig
//! fn extractAllText(root: *Node, allocator: Allocator) ![]u8 {
//!     return try getDescendantTextContent(root, allocator);
//! }
//!
//! // Usage
//! const doc = try Document.init(allocator);
//! defer doc.release();
//! // ... build DOM tree ...
//! const all_text = try extractAllText(&doc.node, allocator);
//! defer allocator.free(all_text);
//! ```
//!
//! ### Building Search Index
//! ```zig
//! fn indexContent(element: *Element, allocator: Allocator) !std.StringHashMap(void) {
//!     var index = std.StringHashMap(void).init(allocator);
//!     errdefer index.deinit();
//!
//!     const text = try getDescendantTextContent(&element.node, allocator);
//!     defer allocator.free(text);
//!
//!     // Tokenize and index
//!     var iter = std.mem.tokenizeAny(u8, text, " \t\n");
//!     while (iter.next()) |word| {
//!         try index.put(word, {});
//!     }
//!
//!     return index;
//! }
//! ```
//!
//! ## Common Patterns
//!
//! ### Find Common Ancestor
//! ```zig
//! fn findCommonAncestor(node1: *Node, node2: *Node) ?*Node {
//!     var current = node1;
//!     while (current.parent_node) |parent| {
//!         if (isInclusiveDescendant(node2, parent)) {
//!             return parent;
//!         }
//!         current = parent;
//!     }
//!     return null;
//! }
//! ```
//!
//! ### Count Descendants
//! ```zig
//! fn countDescendants(node: *const Node) usize {
//!     var count: usize = 0;
//!     var current = node.first_child;
//!     while (current) |child| : (current = child.next_sibling) {
//!         count += 1;
//!         count += countDescendants(child); // Recurse
//!     }
//!     return count;
//! }
//! ```
//!
//! ### Filter Text Nodes
//! ```zig
//! fn collectTextNodes(node: *Node, list: *std.ArrayList(*Node)) !void {
//!     var current = node.first_child;
//!     while (current) |child| : (current = child.next_sibling) {
//!         if (child.node_type == .text) {
//!             try list.append(child);
//!         }
//!         try collectTextNodes(child, list); // Recurse
//!     }
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Ancestor Check** - O(depth), cache results if checking multiple times
//! 2. **Text Collection** - O(n) where n = node count, minimize calls
//! 3. **Iterator Pattern** - For single pass, use direct traversal instead of helpers
//! 4. **Early Exit** - Ancestor checks exit early on match
//! 5. **Reuse Buffers** - For repeated text collection, reuse ArrayList
//! 6. **Connected State** - Batch updates instead of per-node propagation
//!
//! ## Implementation Notes
//!
//! - isInclusiveDescendant walks up parent chain (O(depth))
//! - getDescendantTextContent uses pre-order traversal
//! - Text content collection is recursive (stack depth = tree depth)
//! - Connected state propagation is depth-first
//! - All helpers are tree-structure agnostic (work with any Node subtype)
//! - Text collection allocates string (caller must free)
//! - Pure functions (no side effects except memory allocation)

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
