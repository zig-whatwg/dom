//! Comment Node Implementation
//!
//! This module implements the WHATWG DOM Standard's `Comment` interface (§4.14).
//! Comment nodes represent comments in HTML and XML documents. They are not displayed
//! to users but are preserved in the DOM tree and can be accessed programmatically.
//!
//! ## WHATWG DOM Standard
//!
//! Comment nodes inherit from CharacterData and contain text that is not rendered
//! in the browser. They are commonly used for:
//! - Developer documentation within markup
//! - Conditional compilation (e.g., IE conditional comments)
//! - Temporarily hiding content
//! - Storing metadata
//!
//! ## Key Characteristics
//!
//! - Comment nodes are leaves in the DOM tree (cannot have children)
//! - They inherit all CharacterData operations (append, insert, delete, replace)
//! - Node name is always "#comment"
//! - Content is not visible to users but is part of the document structure
//! - Can contain any text except the sequence "-->"
//!
//! ## Relationship to Other Nodes
//!
//! ```
//! CharacterData (abstract)
//!     ├── Text
//!     ├── Comment (this interface)
//!     └── ProcessingInstruction
//! ```
//!
//! ## HTML Syntax
//!
//! In HTML, comments are written as:
//! ```html
//! <!-- This is a comment -->
//! <!-- Multi-line
//!      comments are
//!      also supported -->
//! ```
//!
//! ## Examples
//!
//! ### Basic Comment Creation
//! ```zig
//! const comment = try Comment.init(allocator, "This is a comment");
//! defer comment.release();
//! try expect(comment.length() == 17);
//! ```
//!
//! ### Manipulating Comment Content
//! ```zig
//! const comment = try Comment.init(allocator, "TODO: Implement feature");
//! defer comment.release();
//!
//! try comment.setData("DONE: Feature implemented");
//! try expectEqualStrings("DONE: Feature implemented", comment.getData());
//! ```
//!
//! ### Using Comments for Metadata
//! ```zig
//! const comment = try Comment.init(allocator, "Generated: 2024-01-15");
//! defer comment.release();
//!
//! // Comments are preserved in the tree
//! _ = try parent.appendChild(comment.character_data.node);
//! ```
//!
//! ## Specification References
//!
//! - WHATWG DOM Standard §4.14: https://dom.spec.whatwg.org/#interface-comment
//! - MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Comment
//! - HTML Standard (Comments): https://html.spec.whatwg.org/multipage/syntax.html#comments
//!
//! ## Memory Management
//!
//! Comment nodes use reference counting through their underlying CharacterData:
//! - Call `release()` when done with a Comment node
//! - The allocator used for creation must remain valid until release
//! - Strings returned by methods must be freed by caller when applicable

const std = @import("std");
const CharacterData = @import("character_data.zig").CharacterData;
const NodeType = @import("node.zig").NodeType;

/// Comment represents a comment in an HTML or XML document.
///
/// ## WHATWG DOM Standard §4.14
///
/// Comment nodes contain text that is not rendered to users. They are preserved
/// in the DOM tree and can be accessed and manipulated programmatically.
///
/// ## Key Features
///
/// - **Non-Rendered**: Content is invisible to users
/// - **Preserved**: Comments remain in the DOM tree
/// - **Manipulable**: Can be modified like other CharacterData nodes
/// - **Metadata**: Often used for storing developer notes or metadata
///
/// ## Common Use Cases
///
/// 1. **Documentation**: Explaining complex markup
/// 2. **Debugging**: Temporarily hiding content
/// 3. **Metadata**: Storing generation timestamps, versions, etc.
/// 4. **Server-Side Includes**: Markers for server processing
/// 5. **Conditional Comments**: IE-specific content (legacy)
///
/// ## Node Name
///
/// All Comment nodes have the node name "#comment", as specified by the
/// WHATWG DOM Standard.
pub const Comment = struct {
    const Self = @This();

    /// Reference to the underlying CharacterData implementation.
    /// All comment operations delegate to this.
    character_data: *CharacterData,

    /// Creates a new Comment node with the specified content.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the Comment node
    /// - `data`: Initial comment content (copied internally)
    ///
    /// ## Returns
    ///
    /// A pointer to the new Comment node, or an error if allocation fails.
    ///
    /// ## Node Properties
    ///
    /// The created Comment node will have:
    /// - `node_type`: `.comment_node`
    /// - `node_name`: "#comment"
    /// - `node_value`: The provided data
    ///
    /// ## Examples
    ///
    /// ```zig
    /// // Create empty comment
    /// const empty = try Comment.init(allocator, "");
    /// defer empty.release();
    ///
    /// // Create comment with content
    /// const comment = try Comment.init(allocator, "TODO: Fix this");
    /// defer comment.release();
    /// try expect(comment.length() == 14);
    ///
    /// // Multi-line comments
    /// const multiline = try Comment.init(allocator,
    ///     \\Author: John Doe
    ///     \\Date: 2024-01-15
    ///     \\Description: Important comment
    /// );
    /// defer multiline.release();
    /// ```
    ///
    /// ### Metadata Comments
    /// ```zig
    /// const metadata = try Comment.init(allocator, "Version: 1.0.0");
    /// defer metadata.release();
    ///
    /// // Add to document
    /// _ = try document.appendChild(metadata.character_data.node);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.14: Comment constructor
    /// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Comment/Comment
    pub fn init(allocator: std.mem.Allocator, data: []const u8) !*Self {
        const self = try allocator.create(Self);
        self.character_data = try CharacterData.init(allocator, .comment_node, data);

        // Set node name to "#comment" per spec
        allocator.free(self.character_data.node.node_name);
        self.character_data.node.node_name = try allocator.dupe(u8, "#comment");

        return self;
    }

    /// Releases the Comment node and its underlying CharacterData.
    ///
    /// ## Memory Management
    ///
    /// This method:
    /// 1. Releases the underlying CharacterData (which releases the Node)
    /// 2. Frees the Comment node structure itself
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const comment = try Comment.init(allocator, "Temporary");
    /// defer comment.release(); // Automatic cleanup
    ///
    /// // Or manual cleanup
    /// const comment2 = try Comment.init(allocator, "Another");
    /// // ... use comment2 ...
    /// comment2.release();
    /// ```
    pub fn release(self: *Self) void {
        const allocator = self.character_data.node.allocator;
        self.character_data.release();
        allocator.destroy(self);
    }

    /// Returns the comment content.
    ///
    /// ## Returns
    ///
    /// A slice to the internal comment data. The slice remains valid until
    /// the content is modified or the node is released.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const comment = try Comment.init(allocator, "Test comment");
    /// defer comment.release();
    /// try expectEqualStrings("Test comment", comment.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.data getter
    pub fn getData(self: *const Self) []const u8 {
        return self.character_data.getData();
    }

    /// Sets the comment content.
    ///
    /// ## Parameters
    ///
    /// - `data`: New comment content (replaces existing content)
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const comment = try Comment.init(allocator, "Old comment");
    /// defer comment.release();
    /// try comment.setData("New comment");
    /// try expectEqualStrings("New comment", comment.getData());
    /// ```
    ///
    /// ### Updating Metadata
    /// ```zig
    /// const version = try Comment.init(allocator, "Version: 1.0.0");
    /// defer version.release();
    /// try version.setData("Version: 2.0.0");
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.data setter
    pub fn setData(self: *Self, data: []const u8) !void {
        try self.character_data.setData(data);
    }

    /// Returns the length of the comment content in code units (bytes).
    ///
    /// ## Returns
    ///
    /// Number of bytes in the comment data.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const comment = try Comment.init(allocator, "Hello");
    /// defer comment.release();
    /// try expect(comment.length() == 5);
    ///
    /// // Unicode characters may use multiple bytes
    /// const unicode = try Comment.init(allocator, "世界");
    /// defer unicode.release();
    /// try expect(unicode.length() == 6); // 3 bytes per character
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.length
    pub fn length(self: *const Self) usize {
        return self.character_data.length();
    }

    /// Extracts a substring from the comment content.
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
    /// const comment = try Comment.init(allocator, "Hello World");
    /// defer comment.release();
    ///
    /// const sub = try comment.substringData(allocator, 0, 5);
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

    /// Appends text to the end of the comment.
    ///
    /// ## Parameters
    ///
    /// - `data`: Text to append
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const comment = try Comment.init(allocator, "TODO");
    /// defer comment.release();
    /// try comment.appendData(": Implement feature");
    /// try expectEqualStrings("TODO: Implement feature", comment.getData());
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
    /// const comment = try Comment.init(allocator, "Fix bug");
    /// defer comment.release();
    /// try comment.insertData(4, "critical ");
    /// try expectEqualStrings("Fix critical bug", comment.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.insertData()
    pub fn insertData(self: *Self, offset: usize, data: []const u8) !void {
        try self.character_data.insertData(offset, data);
    }

    /// Deletes a range of text from the comment.
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
    /// const comment = try Comment.init(allocator, "TODO: Done");
    /// defer comment.release();
    /// try comment.deleteData(0, 6); // Delete "TODO: "
    /// try expectEqualStrings("Done", comment.getData());
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
    /// const comment = try Comment.init(allocator, "Version: 1.0");
    /// defer comment.release();
    /// try comment.replaceData(9, 3, "2.0");
    /// try expectEqualStrings("Version: 2.0", comment.getData());
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.10: CharacterData.replaceData()
    pub fn replaceData(self: *Self, offset: usize, count: usize, data: []const u8) !void {
        try self.character_data.replaceData(offset, count, data);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Comment creation" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "This is a comment");
    defer comment.release();

    try std.testing.expectEqualStrings("This is a comment", comment.getData());
    try std.testing.expectEqual(@as(usize, 17), comment.length());
}

test "Comment empty initialization" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "");
    defer comment.release();

    try std.testing.expectEqualStrings("", comment.getData());
    try std.testing.expectEqual(@as(usize, 0), comment.length());
}

test "Comment node name is #comment" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Test");
    defer comment.release();

    try std.testing.expectEqualStrings("#comment", comment.character_data.node.node_name);
}

test "Comment setData" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Initial");
    defer comment.release();

    try comment.setData("Modified");
    try std.testing.expectEqualStrings("Modified", comment.getData());
}

test "Comment data manipulation" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Initial");
    defer comment.release();

    try comment.setData("Modified");
    try std.testing.expectEqualStrings("Modified", comment.getData());

    try comment.appendData(" comment");
    try std.testing.expectEqualStrings("Modified comment", comment.getData());
}

test "Comment substringData" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Hello World");
    defer comment.release();

    const sub = try comment.substringData(allocator, 0, 5);
    defer allocator.free(sub);
    try std.testing.expectEqualStrings("Hello", sub);
}

test "Comment appendData" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "TODO");
    defer comment.release();

    try comment.appendData(": Implement feature");
    try std.testing.expectEqualStrings("TODO: Implement feature", comment.getData());
}

test "Comment insertData" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Fix bug");
    defer comment.release();

    try comment.insertData(4, "critical ");
    try std.testing.expectEqualStrings("Fix critical bug", comment.getData());
}

test "Comment deleteData" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "TODO: Done");
    defer comment.release();

    try comment.deleteData(0, 6);
    try std.testing.expectEqualStrings("Done", comment.getData());
}

test "Comment replaceData" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Version: 1.0");
    defer comment.release();

    try comment.replaceData(9, 3, "2.0");
    try std.testing.expectEqualStrings("Version: 2.0", comment.getData());
}

test "Comment multiline content" {
    const allocator = std.testing.allocator;

    const multiline =
        \\Author: John Doe
        \\Date: 2024-01-15
        \\Description: Test comment
    ;

    const comment = try Comment.init(allocator, multiline);
    defer comment.release();

    try std.testing.expectEqualStrings(multiline, comment.getData());
    try std.testing.expectEqual(@as(usize, multiline.len), comment.length());
}

test "Comment Unicode support" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Comment: 世界");
    defer comment.release();

    // "Comment: " = 9 bytes, "世界" = 6 bytes
    try std.testing.expectEqual(@as(usize, 15), comment.length());
    try std.testing.expectEqualStrings("Comment: 世界", comment.getData());
}

test "Comment substringData boundary cases" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Hello");
    defer comment.release();

    // Get entire string
    const all = try comment.substringData(allocator, 0, 5);
    defer allocator.free(all);
    try std.testing.expectEqualStrings("Hello", all);

    // Get last character
    const last = try comment.substringData(allocator, 4, 1);
    defer allocator.free(last);
    try std.testing.expectEqualStrings("o", last);
}

test "Comment insertData at boundaries" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Test");
    defer comment.release();

    // Insert at start
    try comment.insertData(0, "Start ");
    try std.testing.expectEqualStrings("Start Test", comment.getData());

    // Insert at end
    try comment.insertData(10, " End");
    try std.testing.expectEqualStrings("Start Test End", comment.getData());
}

test "Comment deleteData to end" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Hello World");
    defer comment.release();

    try comment.deleteData(5, 100); // Delete from position 5 to end
    try std.testing.expectEqualStrings("Hello", comment.getData());
}

test "Comment deleteData zero count" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Hello");
    defer comment.release();

    try comment.deleteData(2, 0);
    try std.testing.expectEqualStrings("Hello", comment.getData()); // Unchanged
}

test "Comment replaceData various lengths" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "AAA BBB CCC");
    defer comment.release();

    // Replace with longer string
    try comment.replaceData(4, 3, "LONGER");
    try std.testing.expectEqualStrings("AAA LONGER CCC", comment.getData());

    // Replace with shorter string
    try comment.replaceData(4, 6, "OK");
    try std.testing.expectEqualStrings("AAA OK CCC", comment.getData());
}

test "Comment memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const comment = try Comment.init(allocator, "Test comment");
        try comment.setData("Modified");
        const sub = try comment.substringData(allocator, 0, 4);
        allocator.free(sub);
        comment.release();
    }
}

test "Comment combined operations" {
    const allocator = std.testing.allocator;

    const comment = try Comment.init(allocator, "Start");
    defer comment.release();

    try comment.appendData(" Middle");
    try std.testing.expectEqualStrings("Start Middle", comment.getData());

    try comment.insertData(6, "Beautiful ");
    try std.testing.expectEqualStrings("Start Beautiful Middle", comment.getData());

    try comment.deleteData(6, 10); // Delete "Beautiful "
    try std.testing.expectEqualStrings("Start Middle", comment.getData());

    try comment.replaceData(6, 6, "End");
    try std.testing.expectEqualStrings("Start End", comment.getData());
}

test "Comment metadata use case" {
    const allocator = std.testing.allocator;

    // Simulating version metadata in comments
    const version = try Comment.init(allocator, "Version: 1.0.0");
    defer version.release();

    try std.testing.expectEqualStrings("Version: 1.0.0", version.getData());

    // Update version
    try version.replaceData(9, 5, "2.0.0");
    try std.testing.expectEqualStrings("Version: 2.0.0", version.getData());
}

test "Comment todos and notes" {
    const allocator = std.testing.allocator;

    const todo = try Comment.init(allocator, "TODO: Implement feature X");
    defer todo.release();

    // Mark as done
    try todo.replaceData(0, 4, "DONE");
    try std.testing.expectEqualStrings("DONE: Implement feature X", todo.getData());
}
