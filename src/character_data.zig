const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// CharacterData is an abstract interface for nodes that contain character data.
///
/// ## Overview
///
/// CharacterData represents a Node object that contains characters. This is an
/// abstract interface and is not instantiated directly. It serves as a base for
/// Text, Comment, and ProcessingInstruction nodes.
///
/// CharacterData provides methods for manipulating the character data within the node,
/// including appending, inserting, deleting, and replacing portions of the data.
///
/// ## Key Concepts
///
/// ### Data Storage
/// The character data is stored in the node's nodeValue and can be accessed and
/// modified through the data attribute or the various manipulation methods.
///
/// ### Length Tracking
/// The length attribute returns the number of code units in the data string,
/// which corresponds to the UTF-8 byte count in Zig.
///
/// ### Index-Based Operations
/// All operations that take an offset parameter use zero-based indexing into
/// the character data string. Operations that would exceed the string boundaries
/// either truncate to the end or throw an IndexSizeError.
///
/// ## Usage Example
///
/// CharacterData is not used directly, but through its subclasses:
///
/// ```zig
/// // Through Text node
/// const text = try Text.init(allocator, "Hello World");
/// defer text.release();
///
/// // Manipulate the data
/// try text.character_data.insertData(5, ",");
/// try text.character_data.deleteData(6, 6);
/// try text.character_data.appendData("!");
///
/// std.debug.print("Data: {s}\n", .{text.character_data.getData()});
/// // Output: Data: Hello!
/// ```
///
/// ## Specification Compliance
///
/// This implementation follows the WHATWG DOM Standard (§4.10 Interface CharacterData):
/// - Data attribute (get/set)
/// - Length attribute
/// - substringData() method
/// - appendData() method
/// - insertData() method
/// - deleteData() method
/// - replaceData() method
///
/// ## Implementation Notes
///
/// ### Memory Management
/// All data modifications allocate new strings and free old ones. The CharacterData
/// takes ownership of the Node and manages its lifecycle.
///
/// ### Error Handling
/// Methods throw IndexSizeError when offset exceeds the data length, matching
/// the DOM specification behavior.
///
/// ## Reference
///
/// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#interface-characterdata
/// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData
pub const CharacterData = struct {
    const Self = @This();

    /// The underlying Node object.
    /// CharacterData wraps a Node and provides character-specific operations.
    node: *Node,

    /// Creates a new CharacterData instance wrapping a Node.
    ///
    /// This is typically not called directly, but through subclass constructors
    /// like Text.init() or Comment.init().
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the CharacterData and Node
    /// - `node_type`: The type of node (text_node, comment_node, etc.)
    /// - `data`: Initial character data for the node
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created CharacterData instance.
    ///
    /// ## Memory Management
    ///
    /// The caller is responsible for calling release() when done.
    /// The data string is duplicated and owned by the Node.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    /// defer char_data.release();
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#interface-characterdata
    pub fn init(allocator: std.mem.Allocator, node_type: NodeType, data: []const u8) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        self.node = try Node.init(allocator, node_type, "#text");
        errdefer self.node.release();

        self.node.node_value = try allocator.dupe(u8, data);
        return self;
    }

    /// Releases all resources associated with this CharacterData.
    ///
    /// Frees the Node and the CharacterData struct itself.
    /// After calling this, the CharacterData pointer is invalid.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    /// char_data.release(); // Clean up
    /// ```
    pub fn release(self: *Self) void {
        const allocator = self.node.allocator;
        self.node.release();
        allocator.destroy(self);
    }

    /// Returns the character data of the node.
    ///
    /// Corresponds to the DOM `data` attribute getter.
    ///
    /// ## Returns
    ///
    /// A string slice containing the character data. Returns empty string
    /// if no data is set.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    /// defer char_data.release();
    ///
    /// const data = char_data.getData();
    /// std.debug.print("Data: {s}\n", .{data}); // Output: Data: Hello
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-characterdata-data
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/data
    pub fn getData(self: *const Self) []const u8 {
        return self.node.node_value orelse "";
    }

    /// Sets the character data of the node.
    ///
    /// Corresponds to the DOM `data` attribute setter.
    /// Replaces all existing data with the new string.
    ///
    /// ## Parameters
    ///
    /// - `data`: New character data to set
    ///
    /// ## Memory Management
    ///
    /// Frees the old data string and allocates a new one.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    /// defer char_data.release();
    ///
    /// try char_data.setData("World");
    /// try std.testing.expectEqualStrings("World", char_data.getData());
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-characterdata-data
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/data
    pub fn setData(self: *Self, data: []const u8) !void {
        if (self.node.node_value) |old_data| {
            self.node.allocator.free(old_data);
        }
        self.node.node_value = try self.node.allocator.dupe(u8, data);
    }

    /// Returns the number of code units in the data.
    ///
    /// Corresponds to the DOM `length` attribute.
    ///
    /// ## Returns
    ///
    /// The number of bytes (UTF-8 code units) in the character data.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    /// defer char_data.release();
    ///
    /// try std.testing.expectEqual(@as(usize, 5), char_data.length());
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-characterdata-length
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/length
    pub fn length(self: *const Self) usize {
        return self.getData().len;
    }

    /// Extracts a substring of the data.
    ///
    /// Returns a new string containing the specified portion of the data,
    /// starting at the given offset and extending for count code units.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for the returned string
    /// - `offset`: Starting position (zero-based)
    /// - `count`: Number of code units to extract
    ///
    /// ## Returns
    ///
    /// A newly allocated string containing the substring. The caller must
    /// free this string.
    ///
    /// ## Errors
    ///
    /// Returns `error.IndexSizeError` if offset is greater than the length.
    ///
    /// ## Behavior
    ///
    /// If offset + count exceeds the length, the substring extends to the
    /// end of the data (does not throw an error).
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
    /// defer char_data.release();
    ///
    /// const sub = try char_data.substringData(allocator, 0, 5);
    /// defer allocator.free(sub);
    ///
    /// try std.testing.expectEqualStrings("Hello", sub);
    /// ```
    ///
    /// ### Beyond Length
    /// ```zig
    /// const sub = try char_data.substringData(allocator, 6, 100);
    /// defer allocator.free(sub);
    ///
    /// try std.testing.expectEqualStrings("World", sub); // Truncates at end
    /// ```
    ///
    /// ### Error Case
    /// ```zig
    /// const result = char_data.substringData(allocator, 100, 5);
    /// try std.testing.expectError(error.IndexSizeError, result);
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-characterdata-substringdata
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/substringData
    pub fn substringData(self: *const Self, allocator: std.mem.Allocator, offset: usize, count: usize) ![]const u8 {
        const data = self.getData();
        if (offset > data.len) {
            return error.IndexSizeError;
        }
        const end = @min(offset + count, data.len);
        return try allocator.dupe(u8, data[offset..end]);
    }

    /// Appends data to the end of the existing data.
    ///
    /// Corresponds to the DOM `appendData()` method.
    ///
    /// ## Parameters
    ///
    /// - `data`: String to append
    ///
    /// ## Memory Management
    ///
    /// Allocates a new string containing the concatenated data and frees
    /// the old data string.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    /// defer char_data.release();
    ///
    /// try char_data.appendData(" World");
    /// try std.testing.expectEqualStrings("Hello World", char_data.getData());
    /// ```
    ///
    /// ### Empty String
    /// ```zig
    /// try char_data.appendData("");
    /// // Data unchanged
    /// ```
    ///
    /// ### Multiple Appends
    /// ```zig
    /// try char_data.appendData("!");
    /// try char_data.appendData("!");
    /// try std.testing.expectEqualStrings("Hello World!!", char_data.getData());
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-characterdata-appenddata
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/appendData
    pub fn appendData(self: *Self, data: []const u8) !void {
        const current = self.getData();
        const new_data = try std.fmt.allocPrint(self.node.allocator, "{s}{s}", .{ current, data });
        if (self.node.node_value) |old_data| {
            self.node.allocator.free(old_data);
        }
        self.node.node_value = new_data;
    }

    /// Inserts data at the specified offset.
    ///
    /// Inserts the given data string before the code unit at the specified offset.
    ///
    /// ## Parameters
    ///
    /// - `offset`: Position at which to insert (zero-based)
    /// - `data`: String to insert
    ///
    /// ## Errors
    ///
    /// Returns `error.IndexSizeError` if offset is greater than the length.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "HelloWorld");
    /// defer char_data.release();
    ///
    /// try char_data.insertData(5, " ");
    /// try std.testing.expectEqualStrings("Hello World", char_data.getData());
    /// ```
    ///
    /// ### Insert at Start
    /// ```zig
    /// try char_data.insertData(0, ">> ");
    /// try std.testing.expectEqualStrings(">> Hello World", char_data.getData());
    /// ```
    ///
    /// ### Insert at End
    /// ```zig
    /// const len = char_data.length();
    /// try char_data.insertData(len, " <<");
    /// try std.testing.expectEqualStrings(">> Hello World <<", char_data.getData());
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-characterdata-insertdata
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/insertData
    pub fn insertData(self: *Self, offset: usize, data: []const u8) !void {
        const current = self.getData();
        if (offset > current.len) {
            return error.IndexSizeError;
        }
        const new_data = try std.fmt.allocPrint(
            self.node.allocator,
            "{s}{s}{s}",
            .{ current[0..offset], data, current[offset..] },
        );
        if (self.node.node_value) |old_data| {
            self.node.allocator.free(old_data);
        }
        self.node.node_value = new_data;
    }

    /// Deletes data starting at the specified offset.
    ///
    /// Removes count code units starting at offset from the data.
    ///
    /// ## Parameters
    ///
    /// - `offset`: Starting position of deletion (zero-based)
    /// - `count`: Number of code units to delete
    ///
    /// ## Errors
    ///
    /// Returns `error.IndexSizeError` if offset is greater than the length.
    ///
    /// ## Behavior
    ///
    /// If offset + count exceeds the length, deletes to the end of the data.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
    /// defer char_data.release();
    ///
    /// try char_data.deleteData(5, 6);
    /// try std.testing.expectEqualStrings("Hello", char_data.getData());
    /// ```
    ///
    /// ### Delete to End
    /// ```zig
    /// try char_data.deleteData(5, 1000);
    /// try std.testing.expectEqualStrings("Hello", char_data.getData());
    /// ```
    ///
    /// ### Delete All
    /// ```zig
    /// try char_data.deleteData(0, char_data.length());
    /// try std.testing.expectEqualStrings("", char_data.getData());
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-characterdata-deletedata
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/deleteData
    pub fn deleteData(self: *Self, offset: usize, count: usize) !void {
        const current = self.getData();
        if (offset > current.len) {
            return error.IndexSizeError;
        }
        const end = @min(offset + count, current.len);
        const new_data = try std.fmt.allocPrint(
            self.node.allocator,
            "{s}{s}",
            .{ current[0..offset], current[end..] },
        );
        if (self.node.node_value) |old_data| {
            self.node.allocator.free(old_data);
        }
        self.node.node_value = new_data;
    }

    /// Replaces a portion of the data with new data.
    ///
    /// Removes count code units starting at offset and inserts the
    /// given data at that position.
    ///
    /// ## Parameters
    ///
    /// - `offset`: Starting position of replacement (zero-based)
    /// - `count`: Number of code units to replace
    /// - `data`: Replacement data
    ///
    /// ## Errors
    ///
    /// Returns `error.IndexSizeError` if offset is greater than the length.
    ///
    /// ## Behavior
    ///
    /// If offset + count exceeds the length, replaces to the end of the data.
    /// The replacement data can be any length (shorter, equal, or longer).
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
    /// defer char_data.release();
    ///
    /// try char_data.replaceData(6, 5, "Zig");
    /// try std.testing.expectEqualStrings("Hello Zig", char_data.getData());
    /// ```
    ///
    /// ### Replace with Longer String
    /// ```zig
    /// try char_data.replaceData(6, 3, "JavaScript");
    /// try std.testing.expectEqualStrings("Hello JavaScript", char_data.getData());
    /// ```
    ///
    /// ### Replace with Shorter String
    /// ```zig
    /// try char_data.replaceData(6, 10, "JS");
    /// try std.testing.expectEqualStrings("Hello JS", char_data.getData());
    /// ```
    ///
    /// ### Replace with Empty String (Same as Delete)
    /// ```zig
    /// try char_data.replaceData(5, 3, "");
    /// try std.testing.expectEqualStrings("Hello", char_data.getData());
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-characterdata-replacedata
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/replaceData
    pub fn replaceData(self: *Self, offset: usize, count: usize, data: []const u8) !void {
        const current = self.getData();
        if (offset > current.len) {
            return error.IndexSizeError;
        }
        const end = @min(offset + count, current.len);
        const new_data = try std.fmt.allocPrint(
            self.node.allocator,
            "{s}{s}{s}",
            .{ current[0..offset], data, current[end..] },
        );
        if (self.node.node_value) |old_data| {
            self.node.allocator.free(old_data);
        }
        self.node.node_value = new_data;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "CharacterData creation and getData" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try std.testing.expectEqualStrings("Hello", char_data.getData());
    try std.testing.expectEqual(@as(usize, 5), char_data.length());
}

test "CharacterData setData" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try char_data.setData("World");
    try std.testing.expectEqualStrings("World", char_data.getData());
}

test "CharacterData substringData" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
    defer char_data.release();

    const substring = try char_data.substringData(allocator, 0, 5);
    defer allocator.free(substring);

    try std.testing.expectEqualStrings("Hello", substring);
}

test "CharacterData appendData" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try char_data.appendData(" World");
    try std.testing.expectEqualStrings("Hello World", char_data.getData());
}

test "CharacterData insertData" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "HelloWorld");
    defer char_data.release();

    try char_data.insertData(5, " ");
    try std.testing.expectEqualStrings("Hello World", char_data.getData());
}

test "CharacterData deleteData" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
    defer char_data.release();

    try char_data.deleteData(5, 6);
    try std.testing.expectEqualStrings("Hello", char_data.getData());
}

test "CharacterData replaceData" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
    defer char_data.release();

    try char_data.replaceData(6, 5, "Zig");
    try std.testing.expectEqualStrings("Hello Zig", char_data.getData());
}

// New comprehensive tests

test "CharacterData empty string initialization" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "");
    defer char_data.release();

    try std.testing.expectEqualStrings("", char_data.getData());
    try std.testing.expectEqual(@as(usize, 0), char_data.length());
}

test "CharacterData substringData edge cases" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    // Substring from middle to beyond end
    const sub1 = try char_data.substringData(allocator, 2, 100);
    defer allocator.free(sub1);
    try std.testing.expectEqualStrings("llo", sub1);

    // Substring with zero count
    const sub2 = try char_data.substringData(allocator, 0, 0);
    defer allocator.free(sub2);
    try std.testing.expectEqualStrings("", sub2);

    // Substring at exact end
    const sub3 = try char_data.substringData(allocator, 5, 0);
    defer allocator.free(sub3);
    try std.testing.expectEqualStrings("", sub3);

    // Substring beyond length should error
    try std.testing.expectError(error.IndexSizeError, char_data.substringData(allocator, 6, 1));
}

test "CharacterData appendData multiple times" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "A");
    defer char_data.release();

    try char_data.appendData("B");
    try char_data.appendData("C");
    try char_data.appendData("D");

    try std.testing.expectEqualStrings("ABCD", char_data.getData());
}

test "CharacterData appendData empty string" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try char_data.appendData("");
    try std.testing.expectEqualStrings("Hello", char_data.getData());
}

test "CharacterData insertData at boundaries" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Middle");
    defer char_data.release();

    // Insert at start
    try char_data.insertData(0, "Start ");
    try std.testing.expectEqualStrings("Start Middle", char_data.getData());

    // Insert at end
    try char_data.insertData(12, " End");
    try std.testing.expectEqualStrings("Start Middle End", char_data.getData());
}

test "CharacterData insertData error on invalid offset" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try std.testing.expectError(error.IndexSizeError, char_data.insertData(100, "X"));
}

test "CharacterData deleteData to end" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
    defer char_data.release();

    try char_data.deleteData(5, 100);
    try std.testing.expectEqualStrings("Hello", char_data.getData());
}

test "CharacterData deleteData all" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
    defer char_data.release();

    try char_data.deleteData(0, char_data.length());
    try std.testing.expectEqualStrings("", char_data.getData());
}

test "CharacterData deleteData zero count" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try char_data.deleteData(2, 0);
    try std.testing.expectEqualStrings("Hello", char_data.getData());
}

test "CharacterData deleteData error on invalid offset" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try std.testing.expectError(error.IndexSizeError, char_data.deleteData(100, 1));
}

test "CharacterData replaceData various lengths" {
    const allocator = std.testing.allocator;

    // Replace with longer string
    {
        const char_data = try CharacterData.init(allocator, .text_node, "Hello XX");
        defer char_data.release();

        try char_data.replaceData(6, 2, "World");
        try std.testing.expectEqualStrings("Hello World", char_data.getData());
    }

    // Replace with shorter string
    {
        const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
        defer char_data.release();

        try char_data.replaceData(6, 5, "Zig");
        try std.testing.expectEqualStrings("Hello Zig", char_data.getData());
    }

    // Replace with empty string (like delete)
    {
        const char_data = try CharacterData.init(allocator, .text_node, "Hello World");
        defer char_data.release();

        try char_data.replaceData(5, 6, "");
        try std.testing.expectEqualStrings("Hello", char_data.getData());
    }
}

test "CharacterData replaceData error on invalid offset" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try std.testing.expectError(error.IndexSizeError, char_data.replaceData(100, 1, "X"));
}

test "CharacterData combined operations" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "Hello");
    defer char_data.release();

    try char_data.appendData(" World");
    try char_data.insertData(5, ",");
    try char_data.replaceData(7, 5, "Zig");
    try char_data.deleteData(5, 1);

    try std.testing.expectEqualStrings("Hello Zig", char_data.getData());
}

test "CharacterData memory leak test" {
    const allocator = std.testing.allocator;

    // Create and destroy many CharacterData instances
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const char_data = try CharacterData.init(allocator, .text_node, "Test data");
        try char_data.setData("Modified");
        try char_data.appendData(" more");
        char_data.release();
    }
}

test "CharacterData setData multiple times" {
    const allocator = std.testing.allocator;

    const char_data = try CharacterData.init(allocator, .text_node, "First");
    defer char_data.release();

    try char_data.setData("Second");
    try std.testing.expectEqualStrings("Second", char_data.getData());

    try char_data.setData("Third");
    try std.testing.expectEqualStrings("Third", char_data.getData());

    try char_data.setData("");
    try std.testing.expectEqualStrings("", char_data.getData());
}
