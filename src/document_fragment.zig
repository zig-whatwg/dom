//! DocumentFragment implementation - lightweight document container.
//!
//! This module implements the WHATWG DOM DocumentFragment interface:
//! - Lightweight container for DOM nodes
//! - No special behavior (simpler than Document)
//! - Used for efficient batch DOM operations
//!
//! Spec: WHATWG DOM §4.11 (https://dom.spec.whatwg.org/#interface-documentfragment)

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;

/// DocumentFragment node - lightweight document container.
///
/// DocumentFragments are used to hold a temporary collection of nodes
/// that can be inserted into a document as a batch. This is more efficient
/// than inserting nodes one by one.
///
/// ## Key Properties
/// - Has no parent (always orphaned)
/// - Can contain any node type except Document
/// - When inserted, its children are moved (not the fragment itself)
pub const DocumentFragment = struct {
    /// Base Node (MUST be first field for @fieldParentPtr)
    node: Node,

    /// Vtable for DocumentFragment nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
    };

    /// Creates a new DocumentFragment node.
    ///
    /// ## Memory Management
    /// Returns DocumentFragment with ref_count=1. Caller MUST call `fragment.node.release()`.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    ///
    /// ## Returns
    /// New document fragment with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const fragment = try DocumentFragment.create(allocator);
    /// defer fragment.node.release();
    /// ```
    pub fn create(allocator: Allocator) !*DocumentFragment {
        const fragment = try allocator.create(DocumentFragment);
        errdefer allocator.destroy(fragment);

        // Initialize base Node
        fragment.node = .{
            .vtable = &vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .document_fragment,
            .flags = 0,
            .node_id = 0,
            .generation = 0,
            .allocator = allocator,
            .parent_node = null,
            .previous_sibling = null,
            .first_child = null,
            .last_child = null,
            .next_sibling = null,
            .owner_document = null,
            .rare_data = null,
        };

        return fragment;
    }

    // === Private vtable implementations ===

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const fragment: *DocumentFragment = @fieldParentPtr("node", node);

        // Release document reference if owned by a document
        if (fragment.node.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("node", owner_doc);
                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        fragment.node.deinitRareData();

        // Free all children
        var current = fragment.node.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            child.parent_node = null;
            child.setHasParent(false);
            child.release();
            current = next;
        }

        fragment.node.allocator.destroy(fragment);
    }

    /// Vtable implementation: node name (always "#document-fragment")
    fn nodeNameImpl(_: *const Node) []const u8 {
        return "#document-fragment";
    }

    /// Vtable implementation: node value (always null for document fragments)
    fn nodeValueImpl(_: *const Node) ?[]const u8 {
        return null;
    }

    /// Vtable implementation: set node value (no-op for document fragments)
    fn setNodeValueImpl(_: *Node, _: []const u8) !void {
        // Document fragments have no value
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        const fragment: *const DocumentFragment = @fieldParentPtr("node", node);
        _ = fragment;

        // Create new fragment
        const new_fragment = try DocumentFragment.create(node.allocator);

        // If deep clone, clone all children
        if (deep) {
            var current = node.first_child;
            while (current) |child| {
                const cloned_child = try child.cloneNode(deep);
                errdefer cloned_child.release();

                _ = try new_fragment.node.appendChild(cloned_child);

                current = child.next_sibling;
            }
        }

        return &new_fragment.node;
    }
};

// === Tests ===

test "DocumentFragment - creation and cleanup" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.node.release();

    try std.testing.expect(fragment.node.node_type == .document_fragment);
    try std.testing.expectEqualStrings("#document-fragment", fragment.node.nodeName());
    try std.testing.expect(fragment.node.nodeValue() == null);
}

test "DocumentFragment - can hold children" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.node.release();

    const elem1 = try doc.createElement("div");
    const elem2 = try doc.createElement("span");

    _ = try fragment.node.appendChild(&elem1.node);
    _ = try fragment.node.appendChild(&elem2.node);

    try std.testing.expect(fragment.node.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), fragment.node.childNodes().length());
}

test "DocumentFragment - clone shallow" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    const elem = try doc.createElement("div");
    _ = try fragment.node.appendChild(&elem.node);

    // Shallow clone
    const clone = try fragment.node.cloneNode(false);
    defer clone.release();

    try std.testing.expect(clone.node_type == .document_fragment);
    try std.testing.expect(!clone.hasChildNodes());
}

test "DocumentFragment - clone deep" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    const elem = try doc.createElement("div");
    _ = try fragment.node.appendChild(&elem.node);

    // Deep clone
    const clone = try fragment.node.cloneNode(true);
    defer clone.release();

    try std.testing.expect(clone.node_type == .document_fragment);
    try std.testing.expect(clone.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 1), clone.childNodes().length());
}
