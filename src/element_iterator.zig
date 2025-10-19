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




