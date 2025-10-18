//! Text Interface (§4.7)
//!
//! This module implements the Text interface as specified by the WHATWG DOM Standard.
//! Text nodes represent the actual text content of elements and are the most common
//! type of node in a DOM tree after elements. They store mutable character data and
//! provide methods for text manipulation.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.7 Interface Text**: https://dom.spec.whatwg.org/#interface-text
//! - **§4.8 Interface CharacterData**: https://dom.spec.whatwg.org/#interface-characterdata
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node (base)
//!
//! ## MDN Documentation
//!
//! - Text: https://developer.mozilla.org/en-US/docs/Web/API/Text
//! - Text.data: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/data
//! - Text.length: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/length
//! - Text.substringData(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/substringData
//! - Text.splitText(): https://developer.mozilla.org/en-US/docs/Web/API/Text/splitText
//!
//! ## Core Features
//!
//! ### Text Content Storage
//! Text nodes store mutable string content that can be modified:
//! ```zig
//! const text = try Text.create(allocator, "Hello, World!");
//! defer text.node.release();
//!
//! // Access via node.nodeValue
//! const content = text.node.nodeValue(); // "Hello, World!"
//!
//! // Or via data field
//! const data = text.data; // "Hello, World!"
//! ```
//!
//! ### Character Data Manipulation
//! Text provides methods for substring operations, insertion, deletion:
//! ```zig
//! const text = try Text.create(allocator, "Hello World");
//! defer text.node.release();
//!
//! // Get substring
//! const sub = try text.substringData(0, 5); // "Hello"
//! defer allocator.free(sub);
//!
//! // Append text
//! try text.appendData(" Zig!");
//! // text.data = "Hello World Zig!"
//! ```
//!
//! ### Text Splitting
//! Split text nodes at a specific offset for editing operations:
//! ```zig
//! const parent = try Element.create(allocator, "p");
//! defer parent.node.release();
//!
//! const text = try Text.create(allocator, "Hello World");
//! _ = try parent.node.appendChild(&text.node);
//!
//! // Split at offset 6 (after "Hello ")
//! const second_half = try text.splitText(6);
//! // text.data = "Hello "
//! // second_half.data = "World"
//! // Both are children of parent
//! ```
//!
//! ## Text Node Structure
//!
//! Text nodes extend Node with character data storage:
//! - **node**: Base Node struct (MUST be first field for @fieldParentPtr)
//! - **data**: Owned string ([]u8) containing text content
//! - **vtable**: Node vtable for polymorphic behavior
//!
//! Size beyond Node: 16 bytes (for data slice)
//!
//! ## Memory Management
//!
//! Text nodes use reference counting through Node interface:
//! ```zig
//! const text = try Text.create(allocator, "Example");
//! defer text.node.release(); // Decrements ref_count, frees if 0
//!
//! // When sharing ownership:
//! text.node.acquire(); // Increment ref_count
//! other_structure.text_node = &text.node;
//! // Both owners must call release()
//! ```
//!
//! When a text node is released (ref_count reaches 0):
//! 1. Text data string is freed (allocator.free(data))
//! 2. Node base is freed
//! 3. Children are released recursively (though text nodes rarely have children)
//!
//! ## Usage Examples
//!
//! ### Creating Text Nodes
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! // Direct creation (simple, for tests)
//! const text1 = try Text.create(allocator, "Hello");
//! defer text1.node.release();
//!
//! // Via Document factory (RECOMMENDED - with string interning)
//! const doc = try Document.init(allocator);
//! defer doc.release();
//! const text2 = try doc.createTextNode("World");
//! defer text2.node.release();
//! ```
//!
//! ### Building Text Content
//! ```zig
//! const paragraph = try Element.create(allocator, "p");
//! defer paragraph.node.release();
//!
//! // Add text content
//! const text = try Text.create(allocator, "This is a ");
//! _ = try paragraph.node.appendChild(&text.node);
//!
//! const emphasis = try Element.create(allocator, "em");
//! _ = try paragraph.node.appendChild(&emphasis.node);
//!
//! const emphText = try Text.create(allocator, "very");
//! _ = try emphasis.node.appendChild(&emphText.node);
//!
//! const moreText = try Text.create(allocator, " important message.");
//! _ = try paragraph.node.appendChild(&moreText.node);
//!
//! // Result: <p>This is a <em>very</em> important message.</p>
//! ```
//!
//! ### Manipulating Text Data
//! ```zig
//! const text = try Text.create(allocator, "Initial");
//! defer text.node.release();
//!
//! // Append text
//! try text.appendData(" content");
//! // text.data = "Initial content"
//!
//! // Insert text
//! try text.insertData(8, "new ");
//! // text.data = "Initial new content"
//!
//! // Delete text
//! try text.deleteData(8, 4);
//! // text.data = "Initial content"
//!
//! // Replace text
//! try text.replaceData(0, 7, "Final");
//! // text.data = "Final content"
//! ```
//!
//! ## Common Patterns
//!
//! ### Whitespace Normalization
//! ```zig
//! fn normalizeWhitespace(text: *Text) !void {
//!     const allocator = text.node.allocator;
//!     var normalized = std.ArrayList(u8).init(allocator);
//!     defer normalized.deinit();
//!
//!     var in_whitespace = false;
//!     for (text.data) |char| {
//!         if (std.ascii.isWhitespace(char)) {
//!             if (!in_whitespace) {
//!                 try normalized.append(' ');
//!                 in_whitespace = true;
//!             }
//!         } else {
//!             try normalized.append(char);
//!             in_whitespace = false;
//!         }
//!     }
//!
//!     // Replace with normalized text
//!     allocator.free(text.data);
//!     text.data = try normalized.toOwnedSlice();
//! }
//! ```
//!
//! ### Text Extraction
//! ```zig
//! fn getTextContent(node: *Node, allocator: Allocator) ![]u8 {
//!     var buffer = std.ArrayList(u8).init(allocator);
//!     defer buffer.deinit();
//!
//!     // Traverse tree and collect all text nodes
//!     var current = node.first_child;
//!     while (current) |child| : (current = child.next_sibling) {
//!         if (child.node_type == .text) {
//!             const text = @fieldParentPtr(Text, "node", child);
//!             try buffer.appendSlice(text.data);
//!         } else {
//!             const child_text = try getTextContent(child, allocator);
//!             defer allocator.free(child_text);
//!             try buffer.appendSlice(child_text);
//!         }
//!     }
//!
//!     return buffer.toOwnedSlice();
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Batch Modifications** - Use appendData/replaceData instead of multiple small changes
//! 2. **Avoid Frequent Splits** - splitText() allocates new nodes, use sparingly
//! 3. **String Interning** - Use Document.createTextNode() for repeated strings
//! 4. **Buffer Building** - For complex text assembly, use ArrayList then create once
//! 5. **Whitespace** - Remove unnecessary whitespace text nodes during parsing
//! 6. **Normalize Adjacent** - Merge adjacent text nodes for better tree structure
//! 7. **Read-Only Access** - Use text.data directly instead of substringData(0, length)
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // data (read-write) - CharacterData interface
//! Object.defineProperty(Text.prototype, 'data', {
//!   get: function() { return zig.text_get_data(this._ptr); },
//!   set: function(value) { zig.text_set_data(this._ptr, value); }
//! });
//!
//! // length (readonly) - CharacterData interface
//! Object.defineProperty(Text.prototype, 'length', {
//!   get: function() { return zig.text_get_length(this._ptr); }
//! });
//!
//! // wholeText (readonly)
//! Object.defineProperty(Text.prototype, 'wholeText', {
//!   get: function() { return zig.text_get_whole_text(this._ptr); }
//! });
//!
//! // Text inherits all Node properties (nodeType, nodeName, nodeValue, etc.)
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // CharacterData methods
//! Text.prototype.substringData = function(offset, count) {
//!   return zig.text_substringData(this._ptr, offset, count);
//! };
//!
//! Text.prototype.appendData = function(data) {
//!   zig.text_appendData(this._ptr, data);
//! };
//!
//! Text.prototype.insertData = function(offset, data) {
//!   zig.text_insertData(this._ptr, offset, data);
//! };
//!
//! Text.prototype.deleteData = function(offset, count) {
//!   zig.text_deleteData(this._ptr, offset, count);
//! };
//!
//! Text.prototype.replaceData = function(offset, count, data) {
//!   zig.text_replaceData(this._ptr, offset, count, data);
//! };
//!
//! // Text-specific methods
//! Text.prototype.splitText = function(offset) {
//!   return zig.text_splitText(this._ptr, offset);
//! };
//!
//! // Text inherits all Node methods (appendChild, etc.)
//! // Text inherits all EventTarget methods (addEventListener, etc.)
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - Text extends Node via struct embedding (node is first field)
//! - Text.data is owned by the Text node (allocated, must be freed)
//! - Node.nodeValue() returns text.data for text nodes
//! - Text nodes rarely have children (but spec allows it)
//! - nodeName is always "#text" for text nodes
//! - Text nodes cannot have attributes
//! - splitText() creates sibling, not child node
//! - CharacterData methods (appendData, etc.) are on Text struct directly

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

    /// Returns the concatenated text of all contiguous Text nodes.
    ///
    /// Implements WHATWG DOM Text.wholeText property per §4.7.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute DOMString wholeText;
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.7)
    /// Return the concatenation of the data of all contiguous Text nodes
    /// (those before, this, and those after this node).
    ///
    /// Contiguous means adjacent Text node siblings with no non-Text nodes in between.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for the result string
    ///
    /// ## Returns
    /// Owned string containing concatenated text. Caller must free.
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate result string
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-text-wholetext
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:434
    ///
    /// ## Example
    /// ```zig
    /// const whole = try text_node.wholeText(allocator);
    /// defer allocator.free(whole);
    /// std.debug.print("Whole text: {s}\n", .{whole});
    /// ```
    pub fn wholeText(self: *const Text, allocator: Allocator) ![]u8 {
        var parts = std.ArrayListUnmanaged([]const u8){};
        defer parts.deinit(allocator);

        // Walk left to find first contiguous text node
        var first_text = &self.node;
        while (first_text.previous_sibling) |prev| {
            if (prev.node_type != .text) break;
            first_text = prev;
        }

        // Collect all contiguous text node data (from first to last)
        var current: ?*const Node = first_text;
        while (current) |node| {
            if (node.node_type != .text) break;

            const text_node: *const Text = @fieldParentPtr("node", node);
            try parts.append(allocator, text_node.data);

            current = node.next_sibling;
        }

        // Concatenate all parts
        return std.mem.concat(allocator, u8, parts.items);
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

                // Only release node ref if this node was ever inserted into the document tree.
                // Orphaned nodes (created but never inserted) don't hold node refs.
                if (text.node.flags & Node.FLAG_EVER_INSERTED != 0) {
                    doc.releaseNodeRef();
                }
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

        // Preserve owner document (WHATWG DOM §4.5.1 Clone algorithm)
        cloned.node.owner_document = text.node.owner_document;

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

test "Text - wholeText with single text node" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.node.release();

    const whole = try text.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("Hello World", whole);
}

test "Text - wholeText with contiguous text nodes" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const text1 = try doc.createTextNode("Hello ");
    const text2 = try doc.createTextNode("beautiful ");
    const text3 = try doc.createTextNode("world!");

    _ = try parent.node.appendChild(&text1.node);
    _ = try parent.node.appendChild(&text2.node);
    _ = try parent.node.appendChild(&text3.node);

    // wholeText from middle node should concatenate all three
    const whole = try text2.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("Hello beautiful world!", whole);
}

test "Text - wholeText with non-text siblings" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const text1 = try doc.createTextNode("Hello");
    const elem = try doc.createElement("span");
    const text2 = try doc.createTextNode("World");

    _ = try parent.node.appendChild(&text1.node);
    _ = try parent.node.appendChild(&elem.node);
    _ = try parent.node.appendChild(&text2.node);

    // wholeText from text1 should only include text1 (element breaks contiguity)
    const whole1 = try text1.wholeText(allocator);
    defer allocator.free(whole1);
    try std.testing.expectEqualStrings("Hello", whole1);

    // wholeText from text2 should only include text2
    const whole2 = try text2.wholeText(allocator);
    defer allocator.free(whole2);
    try std.testing.expectEqualStrings("World", whole2);
}

test "Text - wholeText with empty text nodes" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const text1 = try doc.createTextNode("");
    const text2 = try doc.createTextNode("Content");
    const text3 = try doc.createTextNode("");

    _ = try parent.node.appendChild(&text1.node);
    _ = try parent.node.appendChild(&text2.node);
    _ = try parent.node.appendChild(&text3.node);

    // wholeText should include empty strings too
    const whole = try text2.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("Content", whole);
}
