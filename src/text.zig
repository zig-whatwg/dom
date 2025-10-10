//! Text Node Implementation
//!
//! This module implements the WHATWG DOM Standard's `Text` interface (§4.11).
//! A Text node represents textual content within the document tree and is one of the
//! most commonly used node types in DOM manipulation.
//!
//! ## WHATWG DOM Standard
//!
//! Text nodes inherit from CharacterData and provide specialized text-specific operations:
//! - **splitText**: Splits the text node at a specified offset, creating a new Text node
//! - **wholeText**: Returns the concatenated data of all contiguous Text nodes
//!
//! ## Key Characteristics
//!
//! - Text nodes are leaves in the DOM tree (cannot have children)
//! - They inherit all CharacterData operations (append, insert, delete, replace)
//! - Multiple adjacent Text nodes can be merged using Node.normalize()
//! - Text nodes are the primary containers for user-visible content
//!
//! ## Relationship to Other Nodes
//!
//! ```
//! CharacterData (abstract)
//!     ├── Text (this interface)
//!     │   └── CDATASection (XML-specific)
//!     ├── Comment
//!     └── ProcessingInstruction
//! ```
//!
//! ## Examples
//!
//! ### Basic Text Creation
//! ```zig
//! const text = try Text.init(allocator, "Hello World");
//! defer text.release();
//! try expect(text.length() == 11);
//! ```
//!
//! ### Splitting Text
//! ```zig
//! const text = try Text.init(allocator, "Hello World");
//! defer text.release();
//!
//! const second = try text.splitText(6); // Split after "Hello "
//! defer second.release();
//!
//! try expectEqualStrings("Hello ", text.getData());
//! try expectEqualStrings("World", second.getData());
//! ```
//!
//! ### Getting Combined Text
//! ```zig
//! // If multiple Text nodes are siblings, wholeText combines them
//! const combined = try text.wholeText(allocator);
//! defer allocator.free(combined);
//! ```
//!
//! ## Specification References
//!
//! - WHATWG DOM Standard §4.11: https://dom.spec.whatwg.org/#interface-text
//! - MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Text
//!
//! ## Memory Management
//!
//! Text nodes use reference counting through their underlying CharacterData:
//! - Call `release()` when done with a Text node
//! - The allocator used for creation must remain valid until release
//! - Strings returned by methods like `wholeText` must be freed by caller

const std = @import("std");
const CharacterData = @import("character_data.zig").CharacterData;
const NodeType = @import("node.zig").NodeType;

/// Text represents textual content in the DOM tree.
///
/// ## WHATWG DOM Standard §4.11
///
/// Text nodes are the primary containers for user-visible content in documents.
/// They inherit from CharacterData and add text-specific operations like splitting
/// and combining contiguous text nodes.
///
/// ## Key Features
///
/// - **Leaf Nodes**: Cannot contain child nodes
/// - **Contiguous Merging**: Multiple adjacent Text nodes can be combined
/// - **Normalization**: Parent nodes can merge adjacent Text nodes via normalize()
/// - **Efficient Splitting**: Can split at any character boundary
///
/// ## Common Use Cases
///
/// 1. **Content Storage**: Holding user-visible text
/// 2. **Text Editing**: Splitting and merging text during editing operations
/// 3. **DOM Manipulation**: Creating and inserting text content
/// 4. **Search/Replace**: Operating on text content efficiently
pub const Text = struct {
    const Self = @This();

    /// Reference to the underlying CharacterData implementation.
    /// All basic text operations delegate to this.
    character_data: *CharacterData,

    /// Creates a new Text node with the specified content.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the Text node
    /// - `data`: Initial text content (copied internally)
    ///
    /// ## Returns
    ///
    /// A pointer to the new Text node, or an error if allocation fails.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// // Create empty text node
    /// const empty = try Text.init(allocator, "");
    /// defer empty.release();
    ///
    /// // Create text with content
    /// const text = try Text.init(allocator, "Hello");
    /// defer text.release();
    /// try expect(text.length() == 5);
    ///
    /// // Create text with Unicode
    /// const unicode = try Text.init(allocator, "Hello 世界");
    /// defer unicode.release();
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.11: Text constructor
    /// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Text/Text
    pub fn init(allocator: std.mem.Allocator, data: []const u8) !*Self {
        const self = try allocator.create(Self);
        self.character_data = try CharacterData.init(allocator, .text_node, data);
        return self;
    }

    /// Releases the Text node and its underlying CharacterData.
    ///
    /// ## Memory Management
    ///
    /// This method:
    /// 1. Releases the underlying CharacterData (which releases the Node)
    /// 2. Frees the Text node structure itself
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello");
    /// defer text.release(); // Automatic cleanup
    ///
    /// // Or manual cleanup
    /// const text2 = try Text.init(allocator, "World");
    /// // ... use text2 ...
    /// text2.release();
    /// ```
    pub fn release(self: *Self) void {
        const allocator = self.character_data.node.allocator;
        self.character_data.release();
        allocator.destroy(self);
    }

    /// Returns the text content of this node.
    ///
    /// ## Returns
    ///
    /// A slice to the internal text data. The slice remains valid until
    /// the text is modified or the node is released.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello");
    /// defer text.release();
    /// try expectEqualStrings("Hello", text.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.data getter
    pub fn getData(self: *const Self) []const u8 {
        return self.character_data.getData();
    }

    /// Sets the text content of this node.
    ///
    /// ## Parameters
    ///
    /// - `data`: New text content (replaces existing content)
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello");
    /// defer text.release();
    /// try text.setData("Goodbye");
    /// try expectEqualStrings("Goodbye", text.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.data setter
    pub fn setData(self: *Self, data: []const u8) !void {
        try self.character_data.setData(data);
    }

    /// Returns the length of the text content in code units (bytes).
    ///
    /// ## Returns
    ///
    /// Number of bytes in the text data.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello");
    /// defer text.release();
    /// try expect(text.length() == 5);
    ///
    /// // Unicode characters may use multiple bytes
    /// const unicode = try Text.init(allocator, "世界"); // 2 chars, 6 bytes
    /// defer unicode.release();
    /// try expect(unicode.length() == 6);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.length
    pub fn length(self: *const Self) usize {
        return self.character_data.length();
    }

    /// Extracts a substring from the text content.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for the returned string
    /// - `offset`: Starting position (0-based)
    /// - `count`: Number of code units to extract
    ///
    /// ## Returns
    ///
    /// A newly allocated string containing the substring.
    /// Caller must free the returned string.
    ///
    /// ## Errors
    ///
    /// - `IndexSizeError`: If offset > length
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello World");
    /// defer text.release();
    ///
    /// const sub = try text.substringData(allocator, 0, 5);
    /// defer allocator.free(sub);
    /// try expectEqualStrings("Hello", sub);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.substringData()
    pub fn substringData(self: *const Self, allocator: std.mem.Allocator, offset: usize, count: usize) ![]const u8 {
        return try self.character_data.substringData(allocator, offset, count);
    }

    /// Appends text to the end of the current content.
    ///
    /// ## Parameters
    ///
    /// - `data`: Text to append
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello");
    /// defer text.release();
    /// try text.appendData(" World");
    /// try expectEqualStrings("Hello World", text.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.appendData()
    pub fn appendData(self: *Self, data: []const u8) !void {
        try self.character_data.appendData(data);
    }

    /// Inserts text at the specified position.
    ///
    /// ## Parameters
    ///
    /// - `offset`: Position to insert at (0-based)
    /// - `data`: Text to insert
    ///
    /// ## Errors
    ///
    /// - `IndexSizeError`: If offset > length
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello World");
    /// defer text.release();
    /// try text.insertData(6, "Beautiful ");
    /// try expectEqualStrings("Hello Beautiful World", text.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.insertData()
    pub fn insertData(self: *Self, offset: usize, data: []const u8) !void {
        try self.character_data.insertData(offset, data);
    }

    /// Deletes a range of text.
    ///
    /// ## Parameters
    ///
    /// - `offset`: Starting position (0-based)
    /// - `count`: Number of code units to delete
    ///
    /// ## Errors
    ///
    /// - `IndexSizeError`: If offset > length
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello World");
    /// defer text.release();
    /// try text.deleteData(5, 6); // Delete " World"
    /// try expectEqualStrings("Hello", text.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.deleteData()
    pub fn deleteData(self: *Self, offset: usize, count: usize) !void {
        try self.character_data.deleteData(offset, count);
    }

    /// Replaces a range of text with new text.
    ///
    /// ## Parameters
    ///
    /// - `offset`: Starting position (0-based)
    /// - `count`: Number of code units to replace
    /// - `data`: Replacement text
    ///
    /// ## Errors
    ///
    /// - `IndexSizeError`: If offset > length
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello World");
    /// defer text.release();
    /// try text.replaceData(6, 5, "Zig"); // Replace "World" with "Zig"
    /// try expectEqualStrings("Hello Zig", text.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.replaceData()
    pub fn replaceData(self: *Self, offset: usize, count: usize, data: []const u8) !void {
        try self.character_data.replaceData(offset, count, data);
    }

    /// Splits this Text node at the specified offset.
    ///
    /// ## WHATWG DOM Standard §4.11
    ///
    /// This method:
    /// 1. Creates a new Text node containing text from offset to end
    /// 2. Removes that text from this node
    /// 3. If this node has a parent, inserts the new node as next sibling
    /// 4. Returns the new Text node
    ///
    /// ## Parameters
    ///
    /// - `offset`: Position to split at (0-based)
    ///
    /// ## Returns
    ///
    /// A new Text node containing the text after the split point.
    /// Caller is responsible for releasing the returned node.
    ///
    /// ## Errors
    ///
    /// - `IndexSizeError`: If offset > length
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello World");
    /// defer text.release();
    ///
    /// const second = try text.splitText(6); // Split after "Hello "
    /// defer second.release();
    ///
    /// try expectEqualStrings("Hello ", text.getData());
    /// try expectEqualStrings("World", second.getData());
    /// ```
    ///
    /// ### Splitting at Boundaries
    /// ```zig
    /// const text = try Text.init(allocator, "ABC");
    /// defer text.release();
    ///
    /// // Split at start
    /// const all = try text.splitText(0);
    /// defer all.release();
    /// try expectEqualStrings("", text.getData());
    /// try expectEqualStrings("ABC", all.getData());
    ///
    /// // Split at end creates empty second node
    /// const text2 = try Text.init(allocator, "ABC");
    /// defer text2.release();
    /// const empty = try text2.splitText(3);
    /// defer empty.release();
    /// try expectEqualStrings("ABC", text2.getData());
    /// try expectEqualStrings("", empty.getData());
    /// ```
    ///
    /// ### Split in Tree
    /// ```zig
    /// const parent = try Element.init(allocator, "div");
    /// defer parent.release();
    ///
    /// const text = try Text.init(allocator, "Hello World");
    /// _ = try parent.appendChild(text.character_data.node);
    ///
    /// const second = try text.splitText(6);
    /// // second is now automatically inserted after text in parent
    /// try expect(parent.childNodes.length() == 2);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.11: Text.splitText()
    /// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Text/splitText
    pub fn splitText(self: *Self, offset: usize) !*Text {
        const data = self.getData();
        if (offset > data.len) {
            return error.IndexSizeError;
        }

        // Create new text node with data from offset to end
        const new_text = try Text.init(self.character_data.node.allocator, data[offset..]);

        // Remove that data from this node
        try self.character_data.deleteData(offset, data.len - offset);

        // If in tree, insert new node as next sibling
        if (self.character_data.node.parent_node) |parent| {
            const next_sibling = self.character_data.node.nextSibling();
            _ = try parent.insertBefore(new_text.character_data.node, next_sibling);
        }

        return new_text;
    }

    /// Returns the concatenated data of all contiguous Text nodes.
    ///
    /// ## WHATWG DOM Standard §4.11
    ///
    /// This method combines the text content of:
    /// 1. All preceding sibling Text nodes
    /// 2. This Text node
    /// 3. All following sibling Text nodes
    ///
    /// This is useful for getting the complete text content even when it has
    /// been split across multiple Text nodes.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for the returned string
    ///
    /// ## Returns
    ///
    /// A newly allocated string containing all contiguous text.
    /// Caller must free the returned string.
    ///
    /// ## Examples
    ///
    /// ### Single Text Node
    /// ```zig
    /// const text = try Text.init(allocator, "Hello");
    /// defer text.release();
    ///
    /// const whole = try text.wholeText(allocator);
    /// defer allocator.free(whole);
    /// try expectEqualStrings("Hello", whole);
    /// ```
    ///
    /// ### Multiple Contiguous Text Nodes
    /// ```zig
    /// const parent = try Element.init(allocator, "div");
    /// defer parent.release();
    ///
    /// const text1 = try Text.init(allocator, "Hello ");
    /// const text2 = try Text.init(allocator, "Beautiful ");
    /// const text3 = try Text.init(allocator, "World");
    ///
    /// _ = try parent.appendChild(text1.character_data.node);
    /// _ = try parent.appendChild(text2.character_data.node);
    /// _ = try parent.appendChild(text3.character_data.node);
    ///
    /// // Get whole text from middle node
    /// const whole = try text2.wholeText(allocator);
    /// defer allocator.free(whole);
    /// try expectEqualStrings("Hello Beautiful World", whole);
    /// ```
    ///
    /// ### Text Nodes Separated by Elements
    /// ```zig
    /// const parent = try Element.init(allocator, "div");
    /// defer parent.release();
    ///
    /// const text1 = try Text.init(allocator, "Hello");
    /// const elem = try Element.init(allocator, "span");
    /// const text2 = try Text.init(allocator, "World");
    ///
    /// _ = try parent.appendChild(text1.character_data.node);
    /// _ = try parent.appendChild(elem.node);
    /// _ = try parent.appendChild(text2.character_data.node);
    ///
    /// // wholeText stops at the element boundary
    /// const whole = try text1.wholeText(allocator);
    /// defer allocator.free(whole);
    /// try expectEqualStrings("Hello", whole); // Only text1
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.11: Text.wholeText
    /// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Text/wholeText
    pub fn wholeText(self: *const Self, allocator: std.mem.Allocator) ![]const u8 {
        var parts = std.ArrayList([]const u8){};
        defer parts.deinit(allocator);

        // Find the first contiguous Text node (walk backwards)
        var current: ?*const @import("node.zig").Node = self.character_data.node;
        while (current) |node| {
            if (node.previousSibling()) |prev| {
                if (prev.node_type == .text_node) {
                    current = prev;
                    continue;
                }
            }
            break;
        }

        // Collect all contiguous Text nodes (walk forwards)
        while (current) |node| {
            if (node.node_type == .text_node) {
                if (node.node_value) |value| {
                    try parts.append(allocator, value);
                }
            } else {
                break;
            }
            current = node.nextSibling();
        }

        return try std.mem.concat(allocator, u8, parts.items);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Text creation" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello World");
    defer text.release();

    try std.testing.expectEqualStrings("Hello World", text.getData());
    try std.testing.expectEqual(@as(usize, 11), text.length());
}

test "Text empty initialization" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "");
    defer text.release();

    try std.testing.expectEqualStrings("", text.getData());
    try std.testing.expectEqual(@as(usize, 0), text.length());
}

test "Text setData" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello");
    defer text.release();

    try text.setData("Goodbye");
    try std.testing.expectEqualStrings("Goodbye", text.getData());
    try std.testing.expectEqual(@as(usize, 7), text.length());
}

test "Text substringData" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello World");
    defer text.release();

    const sub = try text.substringData(allocator, 0, 5);
    defer allocator.free(sub);
    try std.testing.expectEqualStrings("Hello", sub);

    const sub2 = try text.substringData(allocator, 6, 5);
    defer allocator.free(sub2);
    try std.testing.expectEqualStrings("World", sub2);
}

test "Text appendData" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello");
    defer text.release();

    try text.appendData(" World");
    try std.testing.expectEqualStrings("Hello World", text.getData());
}

test "Text insertData" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello World");
    defer text.release();

    try text.insertData(6, "Beautiful ");
    try std.testing.expectEqualStrings("Hello Beautiful World", text.getData());
}

test "Text deleteData" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello World");
    defer text.release();

    try text.deleteData(5, 6);
    try std.testing.expectEqualStrings("Hello", text.getData());
}

test "Text replaceData" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello World");
    defer text.release();

    try text.replaceData(6, 5, "Zig");
    try std.testing.expectEqualStrings("Hello Zig", text.getData());
}

test "Text splitText basic" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello World");
    defer text.release();

    const new_text = try text.splitText(6);
    defer new_text.release();

    try std.testing.expectEqualStrings("Hello ", text.getData());
    try std.testing.expectEqualStrings("World", new_text.getData());
}

test "Text splitText at start" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello");
    defer text.release();

    const new_text = try text.splitText(0);
    defer new_text.release();

    try std.testing.expectEqualStrings("", text.getData());
    try std.testing.expectEqualStrings("Hello", new_text.getData());
}

test "Text splitText at end" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello");
    defer text.release();

    const new_text = try text.splitText(5);
    defer new_text.release();

    try std.testing.expectEqualStrings("Hello", text.getData());
    try std.testing.expectEqualStrings("", new_text.getData());
}

test "Text splitText error on invalid offset" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello");
    defer text.release();

    try std.testing.expectError(error.IndexSizeError, text.splitText(10));
}

test "Text wholeText single node" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello");
    defer text.release();

    const whole = try text.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("Hello", whole);
}

test "Text wholeText empty node" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "");
    defer text.release();

    const whole = try text.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("", whole);
}

test "Text Unicode support" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello 世界");
    defer text.release();

    // "Hello " = 6 bytes, "世界" = 6 bytes (3 bytes per char)
    try std.testing.expectEqual(@as(usize, 12), text.length());

    const data = text.getData();
    try std.testing.expectEqualStrings("Hello 世界", data);
}

test "Text memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const text = try Text.init(allocator, "Hello World");
        try text.setData("Goodbye");
        const sub = try text.substringData(allocator, 0, 4);
        allocator.free(sub);
        text.release();
    }
}

test "Text multiple operations sequence" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Start");
    defer text.release();

    try text.appendData(" Middle");
    try text.appendData(" End");
    try std.testing.expectEqualStrings("Start Middle End", text.getData());

    try text.insertData(6, "Beautiful ");
    try std.testing.expectEqualStrings("Start Beautiful Middle End", text.getData());

    try text.deleteData(6, 10); // Delete "Beautiful "
    try std.testing.expectEqualStrings("Start Middle End", text.getData());

    try text.replaceData(6, 6, "Center");
    try std.testing.expectEqualStrings("Start Center End", text.getData());
}

test "Text splitText multiple times" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "ABCDEFGH");
    defer text.release();

    const part2 = try text.splitText(4); // "ABCD" | "EFGH"
    defer part2.release();

    const part3 = try part2.splitText(2); // "EF" | "GH"
    defer part3.release();

    try std.testing.expectEqualStrings("ABCD", text.getData());
    try std.testing.expectEqualStrings("EF", part2.getData());
    try std.testing.expectEqualStrings("GH", part3.getData());
}

test "Text substringData boundary cases" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Hello");
    defer text.release();

    // Get entire string
    const all = try text.substringData(allocator, 0, 5);
    defer allocator.free(all);
    try std.testing.expectEqualStrings("Hello", all);

    // Get last character
    const last = try text.substringData(allocator, 4, 1);
    defer allocator.free(last);
    try std.testing.expectEqualStrings("o", last);

    // Count beyond end (should clamp)
    const beyond = try text.substringData(allocator, 3, 100);
    defer allocator.free(beyond);
    try std.testing.expectEqualStrings("lo", beyond);
}

test "Text combined with all CharacterData methods" {
    const allocator = std.testing.allocator;

    const text = try Text.init(allocator, "Initial");
    defer text.release();

    // Test all inherited methods work correctly
    try text.appendData(" Text");
    try std.testing.expectEqualStrings("Initial Text", text.getData());

    try text.insertData(8, "More ");
    try std.testing.expectEqualStrings("Initial More Text", text.getData());

    try text.deleteData(8, 5);
    try std.testing.expectEqualStrings("Initial Text", text.getData());

    try text.replaceData(0, 7, "Final");
    try std.testing.expectEqualStrings("Final Text", text.getData());

    const sub = try text.substringData(allocator, 0, 5);
    defer allocator.free(sub);
    try std.testing.expectEqualStrings("Final", sub);

    try std.testing.expectEqual(@as(usize, 10), text.length());
}
