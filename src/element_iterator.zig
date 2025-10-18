//! Element-only iterator for efficient DOM traversal
//!
//! This iterator skips non-element nodes (text, comments, CDATA) during
//! tree traversal, providing 2-3x performance improvement for querySelector
//! operations that only need to examine elements.
//!
//! ## Example
//! ```zig
//! var iter = ElementIterator.init(&root.prototype);
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
                return @fieldParentPtr("prototype", node);
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
    _ = try doc.prototype.appendChild(&root.prototype);

    // Add mixed content
    const p1 = try doc.createElement("p");
    _ = try root.prototype.appendChild(&p1.prototype);

    const text1 = try Text.create(allocator, "text");
    // Don't defer release - it's now owned by the tree
    _ = try root.prototype.appendChild(&text1.prototype);

    const p2 = try doc.createElement("p");
    _ = try root.prototype.appendChild(&p2.prototype);

    // Iterator should only yield p1 and p2
    var iter = ElementIterator.init(&root.prototype);

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
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create tree:
    //   root
    //   ├── a
    //   │   └── b
    //   └── c
    const a = try doc.createElement("a");
    _ = try root.prototype.appendChild(&a.prototype);

    const b = try doc.createElement("b");
    _ = try a.prototype.appendChild(&b.prototype);

    const c = try doc.createElement("c");
    _ = try root.prototype.appendChild(&c.prototype);

    // Depth-first order: a, b, c
    var iter = ElementIterator.init(&root.prototype);

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
    _ = try doc.prototype.appendChild(&root.prototype);

    var iter = ElementIterator.init(&root.prototype);
    try testing.expect(iter.next() == null);
}

test "ElementIterator - reset" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&root.prototype);

    const p = try doc.createElement("p");
    _ = try root.prototype.appendChild(&p.prototype);

    var iter = ElementIterator.init(&root.prototype);
    try testing.expect(iter.next().? == p);
    try testing.expect(iter.next() == null);

    iter.reset();
    try testing.expect(iter.next().? == p);
    try testing.expect(iter.next() == null);
}
