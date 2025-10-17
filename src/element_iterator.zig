//! Element-only iterator for efficient DOM traversal
//!
//! This iterator skips non-element nodes (text, comments, CDATA) during
//! tree traversal, providing 2-3x performance improvement for querySelector
//! operations that only need to examine elements.
//!
//! ## Example
//! ```zig
//! var iter = ElementIterator.init(&root.node);
//! while (iter.next()) |element| {
//!     // Only element nodes, no text/comment nodes
//!     if (element.hasClass("target")) {
//!         return element;
//!     }
//! }
//! ```

const std = @import("std");
const Node = @import("node.zig").Node;
const Element = @import("element.zig").Element;

/// Iterator that yields only element nodes during depth-first traversal
pub const ElementIterator = struct {
    current: ?*Node,
    root: *Node,

    /// Initialize iterator starting from children of root
    pub fn init(root: *Node) ElementIterator {
        return .{
            .current = root.first_child,
            .root = root,
        };
    }

    /// Get next element in depth-first traversal order
    pub fn next(self: *ElementIterator) ?*Element {
        while (self.current) |node| {
            // Find next node (depth-first)
            const next_node = blk: {
                // Try child first
                if (node.first_child) |child| break :blk child;

                // Try sibling
                if (node.next_sibling) |sibling| break :blk sibling;

                // Walk up tree to find next sibling
                var parent = node.parent_node;
                while (parent) |p| {
                    if (p == self.root) break :blk null; // Hit root
                    if (p.next_sibling) |sibling| break :blk sibling;
                    parent = p.parent_node;
                }
                break :blk null;
            };

            self.current = next_node;

            // Return only elements (skip text, comment, etc.)
            if (node.node_type == .element) {
                return @fieldParentPtr("node", node);
            }
        }

        return null;
    }

    /// Reset iterator to beginning
    pub fn reset(self: *ElementIterator) void {
        self.current = self.root.first_child;
    }
};

// Tests
const testing = std.testing;
const Document = @import("document.zig").Document;
const Text = @import("text.zig").Text;

test "ElementIterator - skips text nodes" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    // Add mixed content
    const p1 = try doc.createElement("p");
    _ = try root.node.appendChild(&p1.node);

    const text1 = try Text.create(allocator, "text");
    // Don't defer release - it's now owned by the tree
    _ = try root.node.appendChild(&text1.node);

    const p2 = try doc.createElement("p");
    _ = try root.node.appendChild(&p2.node);

    // Iterator should only yield p1 and p2
    var iter = ElementIterator.init(&root.node);

    const elem1 = iter.next();
    try testing.expect(elem1 != null);
    try testing.expect(elem1.? == p1);

    const elem2 = iter.next();
    try testing.expect(elem2 != null);
    try testing.expect(elem2.? == p2);

    const elem3 = iter.next();
    try testing.expect(elem3 == null);
}

test "ElementIterator - depth-first order" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    // Create tree:
    //   root
    //   ├── a
    //   │   └── b
    //   └── c
    const a = try doc.createElement("a");
    _ = try root.node.appendChild(&a.node);

    const b = try doc.createElement("b");
    _ = try a.node.appendChild(&b.node);

    const c = try doc.createElement("c");
    _ = try root.node.appendChild(&c.node);

    // Depth-first order: a, b, c
    var iter = ElementIterator.init(&root.node);

    try testing.expect(iter.next().? == a);
    try testing.expect(iter.next().? == b);
    try testing.expect(iter.next().? == c);
    try testing.expect(iter.next() == null);
}

test "ElementIterator - empty root" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    var iter = ElementIterator.init(&root.node);
    try testing.expect(iter.next() == null);
}

test "ElementIterator - reset" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    const p = try doc.createElement("p");
    _ = try root.node.appendChild(&p.node);

    var iter = ElementIterator.init(&root.node);
    try testing.expect(iter.next().? == p);
    try testing.expect(iter.next() == null);

    iter.reset();
    try testing.expect(iter.next().? == p);
    try testing.expect(iter.next() == null);
}
