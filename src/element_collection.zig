//! ElementCollection - Generic Live Collection of Elements
//!
//! This module implements a generic live collection of Element nodes for any document type.
//! Unlike HTMLCollection (which is HTML-specific), ElementCollection works with XML, custom
//! formats, and any generic DOM structure.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§5.2 Interface HTMLCollection**: https://dom.spec.whatwg.org/#interface-htmlcollection
//!   (We implement the same interface but for generic documents)
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#interface-parentnode (children)
//! - **§5 Collections**: https://dom.spec.whatwg.org/#collections
//!
//! ## Core Features
//!
//! ### Live Collection
//! ElementCollection is a "live" collection - it automatically reflects DOM changes:
//! ```zig
//! const parent = try Element.create(allocator, "container");
//! defer parent.node.release();
//!
//! const children = parent.children();
//! try std.testing.expectEqual(@as(usize, 0), children.length());
//!
//! // Add element child - collection updates automatically
//! const child = try Element.create(allocator, "item");
//! _ = try parent.node.appendChild(&child.node);
//! try std.testing.expectEqual(@as(usize, 1), children.length()); // Now 1!
//!
//! // Add text node - collection does NOT update (text nodes excluded)
//! const text = try Text.create(allocator, "hello");
//! _ = try parent.node.appendChild(&text.node);
//! try std.testing.expectEqual(@as(usize, 1), children.length()); // Still 1!
//! ```
//!
//! ### Elements Only
//! Unlike NodeList (which includes all node types), ElementCollection only includes Element nodes:
//! ```zig
//! const parent = try Element.create(allocator, "parent");
//! defer parent.node.release();
//!
//! // Add mixed children
//! const elem1 = try Element.create(allocator, "child1");
//! _ = try parent.node.appendChild(&elem1.node);
//!
//! const text = try Text.create(allocator, "text content");
//! _ = try parent.node.appendChild(&text.node);
//!
//! const elem2 = try Element.create(allocator, "child2");
//! _ = try parent.node.appendChild(&elem2.node);
//!
//! // childNodes has 3 nodes, children has 2 elements
//! const all_nodes = parent.node.childNodes();
//! const only_elements = parent.children();
//! try std.testing.expectEqual(@as(usize, 3), all_nodes.length());
//! try std.testing.expectEqual(@as(usize, 2), only_elements.length());
//! ```
//!
//! ### Indexed Access
//! Access elements by index using item():
//! ```zig
//! const parent = try Element.create(allocator, "list");
//! defer parent.node.release();
//!
//! // Add element children
//! for (0..3) |_| {
//!     const item = try Element.create(allocator, "item");
//!     _ = try parent.node.appendChild(&item.node);
//! }
//!
//! const children = parent.children();
//! const first = children.item(0); // First element child
//! const second = children.item(1); // Second element child
//! const none = children.item(99); // null (out of bounds)
//! ```
//!
//! ## ElementCollection Structure
//!
//! ElementCollection is a lightweight view - it doesn't store elements, just references the parent:
//! - **parent**: Pointer to parent node whose element children are viewed
//!
//! Size: 8 bytes (just one pointer)
//!
//! **Key Properties:**
//! - **Live**: Reflects DOM changes automatically
//! - **Non-owning**: Doesn't own elements, just provides access
//! - **Elements only**: Skips non-Element nodes (Text, Comment, etc.)
//! - **O(n) operations**: length() and item() traverse linked list, filtering by node type
//! - **No storage**: Doesn't allocate memory for element list
//! - **Zero-copy**: Just a view into existing tree structure
//! - **Generic**: Works with any document type (XML, custom), not HTML-specific
//!
//! ## Memory Management
//!
//! ElementCollection is a stack-allocated value type (not heap-allocated):
//! ```zig
//! const parent = try Element.create(allocator, "container");
//! defer parent.node.release();
//!
//! const children = parent.children();
//! // No defer needed - ElementCollection is a plain struct value
//!
//! // ElementCollection doesn't own elements - parent owns them
//! ```
//!
//! **Important:**
//! - ElementCollection does NOT own the elements it references
//! - Elements are owned by their parent via tree structure
//! - Parent.release() frees all children automatically
//! - ElementCollection is just a view (like a slice, but live and filtered)
//!
//! ## Usage Examples
//!
//! ### Traversing Element Children
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! const container = try Element.create(allocator, "container");
//! defer container.node.release();
//!
//! // Add mixed children
//! for (0..3) |i| {
//!     const elem = try Element.create(allocator, "item");
//!     _ = try container.node.appendChild(&elem.node);
//!
//!     // Add text between elements
//!     if (i < 2) {
//!         const text = try Text.create(allocator, " ");
//!         _ = try container.node.appendChild(&text.node);
//!     }
//! }
//!
//! // Iterate via ElementCollection (elements only)
//! const children = container.children();
//! for (0..children.length()) |i| {
//!     const child = children.item(i).?;
//!     std.debug.print("Element {}: {s}\n", .{i, child.tag_name});
//! }
//! ```
//!
//! ### Live Collection Behavior
//! ```zig
//! const parent = try Element.create(allocator, "list");
//! defer parent.node.release();
//!
//! const collection = parent.children();
//!
//! // Initially empty
//! try std.testing.expectEqual(@as(usize, 0), collection.length());
//!
//! // Add element - collection updates
//! const item1 = try Element.create(allocator, "item1");
//! _ = try parent.node.appendChild(&item1.node);
//! try std.testing.expectEqual(@as(usize, 1), collection.length());
//!
//! // Add text - collection does NOT update (text not an element)
//! const text = try Text.create(allocator, "text");
//! _ = try parent.node.appendChild(&text.node);
//! try std.testing.expectEqual(@as(usize, 1), collection.length());
//!
//! // Add another element - collection updates
//! const item2 = try Element.create(allocator, "item2");
//! _ = try parent.node.appendChild(&item2.node);
//! try std.testing.expectEqual(@as(usize, 2), collection.length());
//!
//! // Remove element - collection updates
//! _ = try parent.node.removeChild(&item1.node);
//! try std.testing.expectEqual(@as(usize, 1), collection.length());
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Cache Length** - length() is O(n), cache in loop: `const len = collection.length()`
//! 2. **Forward Iteration** - Use for loop with cached length
//! 3. **Avoid Repeated Access** - item() is O(n), store reference if used multiple times
//! 4. **Direct Traversal** - For single pass, manually traverse with node_type checks
//! 5. **Snapshot if Modifying** - Convert to array before modifying DOM during iteration
//!
//! ## Implementation Notes
//!
//! - ElementCollection is a plain struct (8 bytes, just parent pointer)
//! - No heap allocation (stack-allocated value type)
//! - length() traverses linked list and counts Element nodes only (O(n))
//! - item() traverses from first_child, skipping non-Element nodes (O(n) per call)
//! - Live collection - automatically reflects DOM mutations
//! - Non-owning - elements owned by tree structure, not by ElementCollection
//! - Generic design - works with any document type, not HTML-specific

const std = @import("std");
const Node = @import("node.zig").Node;
const Element = @import("element.zig").Element;
const NodeType = @import("node.zig").NodeType;

/// ElementCollection - live collection of Element nodes.
///
/// This is a "live" collection that automatically reflects changes to the DOM tree.
/// For ParentNode.children, the collection is backed by the node's linked list of children,
/// but only includes Element nodes (skips Text, Comment, etc.).
///
/// ## Memory Management
/// ElementCollection does NOT own the elements - it merely provides a view into the tree.
/// Elements are owned by their parent via the tree structure.
pub const ElementCollection = struct {
    /// Parent node whose element children this collection represents
    parent: *Node,

    /// Creates a new ElementCollection viewing the element children of a parent node.
    ///
    /// ## Parameters
    /// - `parent`: Parent node whose element children to view
    ///
    /// ## Returns
    /// ElementCollection viewing parent's element children
    pub fn init(parent: *Node) ElementCollection {
        return .{
            .parent = parent,
        };
    }

    /// Returns the number of elements in the collection.
    ///
    /// Implements WHATWG DOM HTMLCollection.length property (generic version).
    /// This traverses the child linked list and counts Element nodes only (O(n)).
    ///
    /// ## WHATWG Specification
    /// **WebIDL**: `readonly attribute unsigned long length;`
    /// **Spec**: https://dom.spec.whatwg.org/#dom-htmlcollection-length
    ///
    /// ## Returns
    /// Number of elements in the collection
    pub fn length(self: *const ElementCollection) usize {
        var count: usize = 0;
        var current = self.parent.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                count += 1;
            }
            current = node.next_sibling;
        }
        return count;
    }

    /// Returns the element at the specified index.
    ///
    /// Implements WHATWG DOM HTMLCollection.item() method (generic version).
    /// This traverses the child linked list, skipping non-Element nodes (O(n)).
    ///
    /// ## WHATWG Specification
    /// **WebIDL**: `getter Element? item(unsigned long index);`
    /// **Spec**: https://dom.spec.whatwg.org/#dom-htmlcollection-item
    ///
    /// ## Parameters
    /// - `index`: Zero-based index of element to retrieve
    ///
    /// ## Returns
    /// Element at index or null if index >= length
    ///
    /// ## Example
    /// ```zig
    /// const child = collection.item(0); // First element child
    /// if (child) |elem| {
    ///     std.debug.print("First element: {s}\n", .{elem.tag_name});
    /// }
    /// ```
    pub fn item(self: *const ElementCollection, index: usize) ?*Element {
        var count: usize = 0;
        var current = self.parent.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                if (count == index) {
                    // Convert Node to Element
                    return @fieldParentPtr("node", node);
                }
                count += 1;
            }
            current = node.next_sibling;
        }
        return null;
    }
};

// ============================================================================
// TESTS
// ============================================================================

const testing = std.testing;

test "ElementCollection - empty collection" {
    const allocator = testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.node.release();

    const collection = ElementCollection.init(&parent.node);
    try testing.expectEqual(@as(usize, 0), collection.length());
    try testing.expectEqual(@as(?*Element, null), collection.item(0));
}

test "ElementCollection - single element" {
    const allocator = testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.node.release();

    const child = try doc.createElement("child");
    _ = try parent.node.appendChild(&child.node);

    const collection = ElementCollection.init(&parent.node);
    try testing.expectEqual(@as(usize, 1), collection.length());

    const first = collection.item(0);
    try testing.expect(first != null);
    try testing.expectEqualStrings("child", first.?.tag_name);
}

test "ElementCollection - multiple elements" {
    const allocator = testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.node.release();

    // Add 3 element children
    const child1 = try doc.createElement("child1");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("child2");
    _ = try parent.node.appendChild(&child2.node);

    const child3 = try doc.createElement("child3");
    _ = try parent.node.appendChild(&child3.node);

    const collection = ElementCollection.init(&parent.node);
    try testing.expectEqual(@as(usize, 3), collection.length());

    try testing.expectEqualStrings("child1", collection.item(0).?.tag_name);
    try testing.expectEqualStrings("child2", collection.item(1).?.tag_name);
    try testing.expectEqualStrings("child3", collection.item(2).?.tag_name);
    try testing.expectEqual(@as(?*Element, null), collection.item(3));
}

test "ElementCollection - filters out non-element nodes" {
    const allocator = testing.allocator;
    const Document = @import("document.zig").Document;
    const Comment = @import("comment.zig").Comment;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.node.release();

    // Add mixed children: element, text, element, comment, element
    const elem1 = try doc.createElement("elem1");
    _ = try parent.node.appendChild(&elem1.node);

    const text = try doc.createTextNode("text content");
    _ = try parent.node.appendChild(&text.node);

    const elem2 = try doc.createElement("elem2");
    _ = try parent.node.appendChild(&elem2.node);

    const comment = try Comment.create(allocator, "comment content");
    _ = try parent.node.appendChild(&comment.node);

    const elem3 = try doc.createElement("elem3");
    _ = try parent.node.appendChild(&elem3.node);

    // childNodes has 5 nodes, children has 3 elements
    const all_nodes = parent.node.childNodes();
    const only_elements = ElementCollection.init(&parent.node);

    try testing.expectEqual(@as(usize, 5), all_nodes.length());
    try testing.expectEqual(@as(usize, 3), only_elements.length());

    try testing.expectEqualStrings("elem1", only_elements.item(0).?.tag_name);
    try testing.expectEqualStrings("elem2", only_elements.item(1).?.tag_name);
    try testing.expectEqualStrings("elem3", only_elements.item(2).?.tag_name);
}

test "ElementCollection - live collection" {
    const allocator = testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.node.release();

    const collection = ElementCollection.init(&parent.node);

    // Initially empty
    try testing.expectEqual(@as(usize, 0), collection.length());

    // Add element - collection updates
    const child1 = try doc.createElement("child1");
    _ = try parent.node.appendChild(&child1.node);
    try testing.expectEqual(@as(usize, 1), collection.length());

    // Add text - collection does NOT update (text not an element)
    const text = try doc.createTextNode("text");
    _ = try parent.node.appendChild(&text.node);
    try testing.expectEqual(@as(usize, 1), collection.length());

    // Add another element - collection updates
    const child2 = try doc.createElement("child2");
    _ = try parent.node.appendChild(&child2.node);
    try testing.expectEqual(@as(usize, 2), collection.length());

    // Remove element - collection updates
    _ = try parent.node.removeChild(&child1.node);
    child1.node.release(); // Manual release for removed node
    try testing.expectEqual(@as(usize, 1), collection.length());
    try testing.expectEqualStrings("child2", collection.item(0).?.tag_name);
}

test "ElementCollection - out of bounds access" {
    const allocator = testing.allocator;
    const Document = @import("document.zig").Document;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.node.release();

    const child = try doc.createElement("child");
    _ = try parent.node.appendChild(&child.node);

    const collection = ElementCollection.init(&parent.node);

    try testing.expect(collection.item(0) != null);
    try testing.expectEqual(@as(?*Element, null), collection.item(1));
    try testing.expectEqual(@as(?*Element, null), collection.item(100));
}
