//! Text node implementation - represents text content in the DOM tree.
//!
//! This module implements the WHATWG DOM Text interface with:
//! - Mutable text content storage
//! - Character data manipulation methods
//! - Vtable implementation for polymorphic Node behavior
//!
//! Spec: WHATWG DOM §4.7 (https://dom.spec.whatwg.org/#interface-text)

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;

/// Text node representing character data in the DOM.
///
/// Text nodes store mutable string content and provide methods for
/// character data manipulation (substring, append, insert, delete, replace).
///
/// ## Memory Layout
/// - Embeds Node as first field (for vtable polymorphism)
/// - Stores text data as owned string (allocated)
/// - Text content can be modified via nodeValue or data accessors
pub const Text = struct {
    /// Base Node (MUST be first field for @fieldParentPtr to work)
    node: Node,

    /// Text content (owned string, 16 bytes)
    /// Allocated and freed by this Text node
    data: []u8,

    /// Vtable for Text nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
    };

    /// Creates a new Text node with the specified content.
    ///
    /// ## Memory Management
    /// Returns Text with ref_count=1. Caller MUST call `text.node.release()`.
    /// Text content is duplicated and owned by the Text node.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    /// - `content`: Initial text content (will be duplicated)
    ///
    /// ## Returns
    /// New text node with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const text = try Text.create(allocator, "Hello World");
    /// defer text.node.release();
    /// ```
    pub fn create(allocator: Allocator, content: []const u8) !*Text {
        const text = try allocator.create(Text);
        errdefer allocator.destroy(text);

        // Duplicate text content (owned by this node)
        const data = try allocator.dupe(u8, content);
        errdefer allocator.free(data);

        // Initialize base Node
        text.node = .{
            .vtable = &vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .text,
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

        // Initialize Text-specific fields
        text.data = data;

        return text;
    }

    /// Returns the text content length in bytes.
    pub fn length(self: *const Text) usize {
        return self.data.len;
    }

    /// Returns a substring of the text content.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for substring
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes (or null for rest of string)
    ///
    /// ## Returns
    /// Owned string slice. Caller must free with allocator.
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate substring
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn substringData(
        self: *const Text,
        allocator: Allocator,
        offset: usize,
        count: ?usize,
    ) ![]u8 {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = if (count) |c|
            @min(offset + c, self.data.len)
        else
            self.data.len;

        return allocator.dupe(u8, self.data[offset..end]);
    }

    /// Appends text to the end of the current content.
    ///
    /// ## Parameters
    /// - `text_to_append`: Text to append
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    pub fn appendData(self: *Text, text_to_append: []const u8) !void {
        const new_data = try std.mem.concat(
            self.node.allocator,
            u8,
            &[_][]const u8{ self.data, text_to_append },
        );

        self.node.allocator.free(self.data);
        self.data = new_data;
        self.node.generation += 1;
    }

    /// Inserts text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Byte offset where to insert
    /// - `text_to_insert`: Text to insert
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn insertData(self: *Text, offset: usize, text_to_insert: []const u8) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const new_data = try std.mem.concat(
            self.node.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], text_to_insert, self.data[offset..] },
        );

        self.node.allocator.free(self.data);
        self.data = new_data;
        self.node.generation += 1;
    }

    /// Deletes text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes to delete
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn deleteData(self: *Text, offset: usize, count: usize) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = @min(offset + count, self.data.len);

        const new_data = try std.mem.concat(
            self.node.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], self.data[end..] },
        );

        self.node.allocator.free(self.data);
        self.data = new_data;
        self.node.generation += 1;
    }

    /// Replaces text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes to replace
    /// - `replacement`: Replacement text
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn replaceData(
        self: *Text,
        offset: usize,
        count: usize,
        replacement: []const u8,
    ) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = @min(offset + count, self.data.len);

        const new_data = try std.mem.concat(
            self.node.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], replacement, self.data[end..] },
        );

        self.node.allocator.free(self.data);
        self.data = new_data;
        self.node.generation += 1;
    }

    // === Private vtable implementations ===

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const text: *Text = @fieldParentPtr("node", node);

        // Release document reference if owned by a document
        if (text.node.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                // Get Document from its node field (node is first field)
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("node", owner_doc);
                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        text.node.deinitRareData();

        text.node.allocator.free(text.data);
        text.node.allocator.destroy(text);
    }

    /// Vtable implementation: node name (always "#text")
    fn nodeNameImpl(_: *const Node) []const u8 {
        return "#text";
    }

    /// Vtable implementation: node value (returns text content)
    fn nodeValueImpl(node: *const Node) ?[]const u8 {
        const text: *const Text = @fieldParentPtr("node", node);
        return text.data;
    }

    /// Vtable implementation: set node value (updates text content)
    fn setNodeValueImpl(node: *Node, value: []const u8) !void {
        const text: *Text = @fieldParentPtr("node", node);

        // Allocate new content
        const new_data = try node.allocator.dupe(u8, value);

        // Free old and replace
        node.allocator.free(text.data);
        text.data = new_data;
        node.generation += 1;
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        const text: *const Text = @fieldParentPtr("node", node);

        // Text nodes have no children, so deep is ignored
        _ = deep;

        // Create new text with same content
        const cloned = try Text.create(node.allocator, text.data);
        return &cloned.node;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "Text - creation and cleanup" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.node.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.text, text.node.node_type);
    try std.testing.expectEqual(@as(u32, 1), text.node.getRefCount());
    try std.testing.expectEqualStrings("Hello World", text.data);
    try std.testing.expectEqual(@as(usize, 11), text.length());

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("#text", text.node.nodeName());
    try std.testing.expectEqualStrings("Hello World", text.node.nodeValue().?);
}

test "Text - empty content" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "");
    defer text.node.release();

    try std.testing.expectEqual(@as(usize, 0), text.length());
    try std.testing.expectEqualStrings("", text.data);
}

test "Text - set node value" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "original");
    defer text.node.release();

    try std.testing.expectEqualStrings("original", text.data);

    // Change via nodeValue setter
    try text.node.setNodeValue("updated");
    try std.testing.expectEqualStrings("updated", text.data);

    // Verify generation incremented
    try std.testing.expect(text.node.generation > 0);
}

test "Text - substringData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.node.release();

    // Substring with count
    {
        const sub = try text.substringData(allocator, 0, 5);
        defer allocator.free(sub);
        try std.testing.expectEqualStrings("Hello", sub);
    }

    // Substring from middle
    {
        const sub = try text.substringData(allocator, 6, 5);
        defer allocator.free(sub);
        try std.testing.expectEqualStrings("World", sub);
    }

    // Substring to end (no count)
    {
        const sub = try text.substringData(allocator, 6, null);
        defer allocator.free(sub);
        try std.testing.expectEqualStrings("World", sub);
    }

    // Out of bounds
    try std.testing.expectError(error.IndexOutOfBounds, text.substringData(allocator, 100, 1));
}

test "Text - appendData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello");
    defer text.node.release();

    try text.appendData(" World");
    try std.testing.expectEqualStrings("Hello World", text.data);

    try text.appendData("!");
    try std.testing.expectEqualStrings("Hello World!", text.data);
}

test "Text - insertData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.node.release();

    // Insert in middle
    try text.insertData(5, " Beautiful");
    try std.testing.expectEqualStrings("Hello Beautiful World", text.data);

    // Insert at start
    try text.insertData(0, "Oh ");
    try std.testing.expectEqualStrings("Oh Hello Beautiful World", text.data);

    // Insert at end
    try text.insertData(text.data.len, "!");
    try std.testing.expectEqualStrings("Oh Hello Beautiful World!", text.data);

    // Out of bounds
    try std.testing.expectError(error.IndexOutOfBounds, text.insertData(1000, "fail"));
}

test "Text - deleteData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello Beautiful World");
    defer text.node.release();

    // Delete from middle
    try text.deleteData(5, 10); // Remove " Beautiful"
    try std.testing.expectEqualStrings("Hello World", text.data);

    // Delete from start
    try text.deleteData(0, 6); // Remove "Hello "
    try std.testing.expectEqualStrings("World", text.data);

    // Delete to end (count too large)
    try text.deleteData(0, 1000);
    try std.testing.expectEqualStrings("", text.data);

    // Out of bounds
    try std.testing.expectError(error.IndexOutOfBounds, text.deleteData(1000, 1));
}

test "Text - replaceData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.node.release();

    // Replace in middle
    try text.replaceData(6, 5, "Zig");
    try std.testing.expectEqualStrings("Hello Zig", text.data);

    // Replace at start
    try text.replaceData(0, 5, "Hi");
    try std.testing.expectEqualStrings("Hi Zig", text.data);

    // Replace everything
    try text.replaceData(0, text.data.len, "New");
    try std.testing.expectEqualStrings("New", text.data);

    // Out of bounds
    try std.testing.expectError(error.IndexOutOfBounds, text.replaceData(1000, 1, "fail"));
}

test "Text - cloneNode" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.node.release();

    // Clone
    const cloned_node = try text.node.cloneNode(false);
    defer cloned_node.release();

    const cloned: *Text = @fieldParentPtr("node", cloned_node);

    // Verify clone properties
    try std.testing.expectEqualStrings("Hello World", cloned.data);
    try std.testing.expectEqual(@as(u32, 1), cloned.node.getRefCount());

    // Verify independence
    try text.appendData("!");
    try std.testing.expectEqualStrings("Hello World!", text.data);
    try std.testing.expectEqualStrings("Hello World", cloned.data); // Unchanged
}

test "Text - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple creation
    {
        const text = try Text.create(allocator, "test");
        defer text.node.release();
    }

    // Test 2: Modifications
    {
        const text = try Text.create(allocator, "test");
        defer text.node.release();

        try text.appendData(" more");
        try text.insertData(0, "prefix ");
        try text.deleteData(0, 7);
        try text.replaceData(0, 4, "TEST");
        try text.node.setNodeValue("final");
    }

    // Test 3: Clone
    {
        const text = try Text.create(allocator, "original");
        defer text.node.release();

        const cloned = try text.node.cloneNode(false);
        defer cloned.release();
    }

    // Test 4: Multiple acquire/release
    {
        const text = try Text.create(allocator, "test");
        defer text.node.release();

        text.node.acquire();
        defer text.node.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Text - ref counting" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "test");
    defer text.node.release();

    // Initial ref count
    try std.testing.expectEqual(@as(u32, 1), text.node.getRefCount());

    // Acquire
    text.node.acquire();
    try std.testing.expectEqual(@as(u32, 2), text.node.getRefCount());

    // Release
    text.node.release();
    try std.testing.expectEqual(@as(u32, 1), text.node.getRefCount());
}
