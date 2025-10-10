//! DocumentFragment Interface - WHATWG DOM Standard §4.7
//! ======================================================
//!
//! DocumentFragment is a minimal document object that has no parent. It is used as a
//! lightweight version of Document to store a well-formed or potentially non-well-formed
//! fragment of XML or HTML.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-documentfragment
//! - **Section**: §4.7 Interface DocumentFragment
//!
//! ## MDN Documentation
//! - **DocumentFragment**: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
//! - **new DocumentFragment()**: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/DocumentFragment
//!
//! ## Key Concepts
//!
//! ### Purpose
//! DocumentFragments are useful for building DOM structures off-screen before inserting
//! them into the live document. This is more efficient than manipulating the live DOM
//! repeatedly, as it:
//! - Avoids repeated reflows and repaints
//! - Allows batch operations
//! - Provides a clean API for template rendering
//!
//! ### Characteristics
//! - Has no parent (orphaned node tree root)
//! - When inserted into a document, the fragment itself is not inserted
//! - Only its children are inserted
//! - After insertion, the fragment becomes empty
//!
//! ### Use Cases
//! 1. **Batch DOM Operations**: Build complex structures without triggering reflows
//! 2. **Template Rendering**: Construct elements before adding to document
//! 3. **Performance**: Reduce layout thrashing with off-screen construction
//!
//! ## Architecture
//!
//! ```
//! DocumentFragment (inherits from Node)
//! ├── node_type: .document_fragment_node
//! ├── node_name: "#document-fragment"
//! ├── parent_node: null (always)
//! └── child_nodes: [...children...]
//!
//! When appended to a parent:
//!   Parent.appendChild(fragment)
//!     → Fragment's children move to parent
//!     → Fragment becomes empty
//! ```
//!
//! ## Usage Examples
//!
//! ### Basic Creation and Usage
//! ```zig
//! const fragment = try DocumentFragment.init(allocator);
//! defer fragment.release();
//!
//! // Build structure
//! const div = try Element.create(allocator, "div");
//! _ = try fragment.node.appendChild(div);
//!
//! const text = try Text.init(allocator, "Hello");
//! _ = try div.appendChild(text.character_data.node);
//!
//! // Insert into document (fragment becomes empty)
//! _ = try document_body.appendChild(fragment.node);
//! ```
//!
//! ### Batch DOM Operations (Performance)
//! ```zig
//! // BAD: Multiple reflows
//! for (items) |item| {
//!     const li = try doc.createElement("li");
//!     _ = try ul.appendChild(li);
//!     // Triggers reflow on each append
//! }
//!
//! // GOOD: Single reflow
//! const fragment = try DocumentFragment.init(allocator);
//! defer fragment.release();
//!
//! for (items) |item| {
//!     const li = try doc.createElement("li");
//!     _ = try fragment.node.appendChild(li);
//! }
//! _ = try ul.appendChild(fragment.node); // Single reflow
//! ```
//!
//! ### Template Rendering
//! ```zig
//! fn renderTemplate(allocator: Allocator, data: []const Item) !*Node {
//!     const fragment = try DocumentFragment.init(allocator);
//!     errdefer fragment.release();
//!
//!     for (data) |item| {
//!         const div = try Element.create(allocator, "div");
//!         try Element.setClassName(div, "item");
//!
//!         const title = try Element.create(allocator, "h2");
//!         _ = try div.appendChild(title);
//!
//!         const text = try Text.init(allocator, item.title);
//!         _ = try title.appendChild(text.character_data.node);
//!
//!         _ = try fragment.node.appendChild(div);
//!     }
//!
//!     return fragment.node;
//! }
//! ```
//!
//! ### Building Complex Structures
//! ```zig
//! const fragment = try DocumentFragment.init(allocator);
//! defer fragment.release();
//!
//! // Create header
//! const header = try Element.create(allocator, "header");
//! const h1 = try Element.create(allocator, "h1");
//! _ = try header.appendChild(h1);
//! _ = try fragment.node.appendChild(header);
//!
//! // Create main content
//! const main = try Element.create(allocator, "main");
//! _ = try fragment.node.appendChild(main);
//!
//! // Create footer
//! const footer = try Element.create(allocator, "footer");
//! _ = try fragment.node.appendChild(footer);
//!
//! // Insert entire structure at once
//! _ = try body.appendChild(fragment.node);
//! ```
//!
//! ### Using with querySelector
//! ```zig
//! const fragment = try DocumentFragment.init(allocator);
//! defer fragment.release();
//!
//! // Build structure
//! const div1 = try Element.create(allocator, "div");
//! try Element.setAttribute(div1, "id", "first");
//! _ = try fragment.node.appendChild(div1);
//!
//! const div2 = try Element.create(allocator, "div");
//! try Element.setClassName(div2, "highlight");
//! _ = try fragment.node.appendChild(div2);
//!
//! // Query before inserting
//! if (try Element.querySelector(fragment.node, "#first")) |found| {
//!     // Can query fragment's children
//! }
//! ```
//!
//! ## Memory Management
//!
//! DocumentFragment owns its node and all children. When released:
//! - The fragment's node is released
//! - All children are recursively released
//!
//! After appending to a parent:
//! - Children are transferred to the parent
//! - Fragment becomes empty (but still valid)
//! - Fragment must still be released
//!
//! ## Performance Benefits
//!
//! Using DocumentFragment for batch operations can provide significant performance
//! improvements:
//! - **Reflows**: 1 instead of N
//! - **Repaints**: 1 instead of N
//! - **Layout calculations**: Deferred until insertion
//!
//! Typical performance improvement: 2-10x for large batches (100+ elements)
//!
//! ## Thread Safety
//!
//! DocumentFragment is not thread-safe. All operations should be performed from
//! a single thread.

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// DocumentFragment represents a minimal document object with no parent.
///
/// See: https://dom.spec.whatwg.org/#interface-documentfragment
/// See: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
pub const DocumentFragment = struct {
    const Self = @This();

    /// The underlying node (node_type is .document_fragment_node)
    node: *Node,

    /// Allocator for memory management
    allocator: std.mem.Allocator,

    /// Initialize a new DocumentFragment.
    ///
    /// Creates a document fragment node with node type `document_fragment_node` and
    /// node name "#document-fragment". The fragment has no parent and is initially empty.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-documentfragment-documentfragment
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/DocumentFragment
    ///
    /// ## WHATWG Specification (§4.7)
    /// > The new DocumentFragment() constructor steps are to do nothing.
    /// > (The fragment is initialized to the standard node defaults)
    ///
    /// ## Examples
    ///
    /// ### Basic Initialization
    /// ```zig
    /// const fragment = try DocumentFragment.init(allocator);
    /// defer fragment.release();
    /// ```
    ///
    /// ### With Children
    /// ```zig
    /// const fragment = try DocumentFragment.init(allocator);
    /// defer fragment.release();
    ///
    /// const div = try Element.create(allocator, "div");
    /// _ = try fragment.node.appendChild(div);
    /// ```
    ///
    /// ### Batch Creation
    /// ```zig
    /// const fragment = try DocumentFragment.init(allocator);
    /// defer fragment.release();
    ///
    /// var i: usize = 0;
    /// while (i < 10) : (i += 1) {
    ///     const p = try Element.create(allocator, "p");
    ///     _ = try fragment.node.appendChild(p);
    /// }
    /// ```
    ///
    /// ## Memory Management
    /// The caller is responsible for calling `release()` when done.
    /// Children appended to the fragment are managed by the fragment until
    /// the fragment is appended to another node.
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .node = try Node.init(allocator, .document_fragment_node, "#document-fragment"),
            .allocator = allocator,
        };
        return self;
    }

    /// Release the document fragment and all its resources.
    ///
    /// Releases the fragment's node (which recursively releases all children)
    /// and frees the fragment structure itself.
    ///
    /// ## Examples
    /// ```zig
    /// const fragment = try DocumentFragment.init(allocator);
    /// defer fragment.release();
    /// ```
    ///
    /// ## Note
    /// Even after appending the fragment to a parent (which empties it),
    /// the fragment must still be released.
    pub fn release(self: *Self) void {
        self.node.release();
        self.allocator.destroy(self);
    }

    /// Get the underlying node.
    ///
    /// Provides access to the fragment's node for operations like appendChild,
    /// querySelector, etc.
    ///
    /// ## Examples
    ///
    /// ### Appending to Fragment
    /// ```zig
    /// const fragment = try DocumentFragment.init(allocator);
    /// defer fragment.release();
    ///
    /// const div = try Element.create(allocator, "div");
    /// _ = try fragment.node.appendChild(div);
    /// ```
    ///
    /// ### Querying Fragment
    /// ```zig
    /// if (try Element.querySelector(fragment.node, ".item")) |element| {
    ///     // Found element in fragment
    /// }
    /// ```
    ///
    /// ## Returns
    /// A pointer to the fragment's underlying node.
    pub fn getNode(self: *Self) *Node {
        return self.node;
    }
};

// ============================================================================
// Tests
// ============================================================================

const Element = @import("element.zig").Element;
const Text = @import("text.zig").Text;

test "DocumentFragment creation" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    try std.testing.expectEqual(NodeType.document_fragment_node, fragment.node.node_type);
    try std.testing.expectEqualStrings("#document-fragment", fragment.node.node_name);
    try std.testing.expect(fragment.node.parent_node == null);
}

test "DocumentFragment appendChild" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    const div = try Element.create(allocator, "div");
    _ = try fragment.node.appendChild(div);

    try std.testing.expectEqual(@as(usize, 1), fragment.node.child_nodes.length());
    try std.testing.expectEqual(div, fragment.node.firstChild().?);
}

test "DocumentFragment multiple children" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    const div1 = try Element.create(allocator, "div");
    _ = try fragment.node.appendChild(div1);

    const div2 = try Element.create(allocator, "div");
    _ = try fragment.node.appendChild(div2);

    const div3 = try Element.create(allocator, "div");
    _ = try fragment.node.appendChild(div3);

    try std.testing.expectEqual(@as(usize, 3), fragment.node.child_nodes.length());
}

test "DocumentFragment children accessible" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    // Add children to fragment
    const child1 = try Element.create(allocator, "span");
    _ = try fragment.node.appendChild(child1);

    const child2 = try Element.create(allocator, "span");
    _ = try fragment.node.appendChild(child2);

    try std.testing.expectEqual(@as(usize, 2), fragment.node.child_nodes.length());

    // Can access children
    try std.testing.expectEqual(child1, fragment.node.firstChild().?);
    try std.testing.expectEqual(child2, fragment.node.lastChild().?);
}

test "DocumentFragment batch DOM operations" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    // Build list in fragment
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const li = try Element.create(allocator, "li");
        _ = try fragment.node.appendChild(li);
    }

    try std.testing.expectEqual(@as(usize, 10), fragment.node.child_nodes.length());

    // Fragment holds all children
    try std.testing.expect(fragment.node.firstChild() != null);
    try std.testing.expect(fragment.node.lastChild() != null);
}

test "DocumentFragment with text nodes" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    const div = try Element.create(allocator, "div");
    _ = try fragment.node.appendChild(div);

    const text = try Node.init(allocator, .text_node, "Hello, World!");
    _ = try div.appendChild(text);

    try std.testing.expectEqual(@as(usize, 1), fragment.node.child_nodes.length());

    // Verify structure
    const child_div = fragment.node.firstChild().?;
    try std.testing.expect(child_div.firstChild() != null);
}

test "DocumentFragment querySelector" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    const div1 = try Element.create(allocator, "div");
    try Element.setAttribute(div1, "id", "first");
    _ = try fragment.node.appendChild(div1);

    const div2 = try Element.create(allocator, "div");
    try Element.setClassName(div2, "highlight");
    _ = try fragment.node.appendChild(div2);

    // Query by ID
    const found_id = try Element.querySelector(fragment.node, "#first");
    try std.testing.expect(found_id != null);
    try std.testing.expectEqual(div1, found_id.?);

    // Query by class
    const found_class = try Element.querySelector(fragment.node, ".highlight");
    try std.testing.expect(found_class != null);
    try std.testing.expectEqual(div2, found_class.?);
}

test "DocumentFragment querySelectorAll" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    var i: usize = 0;
    while (i < 5) : (i += 1) {
        const div = try Element.create(allocator, "div");
        try Element.setClassName(div, "item");
        _ = try fragment.node.appendChild(div);
    }

    const list = try Element.querySelectorAll(fragment.node, ".item");
    defer {
        list.deinit();
        allocator.destroy(list);
    }

    try std.testing.expectEqual(@as(usize, 5), list.length());
}

test "DocumentFragment complex structure" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    // Create header
    const header = try Element.create(allocator, "header");
    const h1 = try Element.create(allocator, "h1");
    _ = try header.appendChild(h1);

    const title_text = try Node.init(allocator, .text_node, "Title");
    _ = try h1.appendChild(title_text);

    _ = try fragment.node.appendChild(header);

    // Create main
    const main = try Element.create(allocator, "main");
    const p = try Element.create(allocator, "p");
    _ = try main.appendChild(p);

    const p_text = try Node.init(allocator, .text_node, "Content");
    _ = try p.appendChild(p_text);

    _ = try fragment.node.appendChild(main);

    // Create footer
    const footer = try Element.create(allocator, "footer");
    _ = try fragment.node.appendChild(footer);

    try std.testing.expectEqual(@as(usize, 3), fragment.node.child_nodes.length());
}

test "DocumentFragment maintains children" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    // Add children
    const child1 = try Element.create(allocator, "span");
    _ = try fragment.node.appendChild(child1);

    const child2 = try Element.create(allocator, "span");
    _ = try fragment.node.appendChild(child2);

    // Fragment maintains children until released
    try std.testing.expectEqual(@as(usize, 2), fragment.node.child_nodes.length());
    try std.testing.expect(fragment.node.firstChild() != null);
    try std.testing.expect(fragment.node.lastChild() != null);
}

test "DocumentFragment can hold multiple element types" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    const span = try Element.create(allocator, "span");
    _ = try fragment.node.appendChild(span);

    const div = try Element.create(allocator, "div");
    _ = try fragment.node.appendChild(div);

    const p = try Element.create(allocator, "p");
    _ = try fragment.node.appendChild(p);

    try std.testing.expectEqual(@as(usize, 3), fragment.node.child_nodes.length());
}

test "DocumentFragment can hold elements with IDs" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    const div = try Element.create(allocator, "div");
    try Element.setAttribute(div, "id", "test");
    _ = try fragment.node.appendChild(div);

    // Fragment holds the element
    try std.testing.expectEqual(@as(usize, 1), fragment.node.child_nodes.length());

    // Can access the child directly
    const child = fragment.node.firstChild().?;
    const child_id = Element.getAttribute(child, "id");
    try std.testing.expect(child_id != null);
    try std.testing.expectEqualStrings("test", child_id.?);
}

test "DocumentFragment memory leak test" {
    const allocator = std.testing.allocator;

    // Run 100 iterations to detect memory leaks
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const fragment = try DocumentFragment.init(allocator);
        defer fragment.release();

        const div1 = try Element.create(allocator, "div");
        _ = try fragment.node.appendChild(div1);

        const div2 = try Element.create(allocator, "div");
        _ = try fragment.node.appendChild(div2);

        const text = try Node.init(allocator, .text_node, "test");
        _ = try div1.appendChild(text);
    }
}

test "DocumentFragment with nested structures memory leak test" {
    const allocator = std.testing.allocator;

    // Test complex structures don't leak
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const fragment = try DocumentFragment.init(allocator);
        defer fragment.release();

        const div = try Element.create(allocator, "div");
        _ = try fragment.node.appendChild(div);

        const span = try Element.create(allocator, "span");
        _ = try div.appendChild(span);

        const text = try Node.init(allocator, .text_node, "test");
        _ = try span.appendChild(text);
    }
}

test "DocumentFragment getNode" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.init(allocator);
    defer fragment.release();

    const node = fragment.getNode();
    try std.testing.expectEqual(fragment.node, node);
    try std.testing.expectEqual(NodeType.document_fragment_node, node.node_type);
}
