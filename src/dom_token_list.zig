//! DOMTokenList Implementation
//!
//! This module implements the WHATWG DOM Standard's `DOMTokenList` interface (§7.1).
//! DOMTokenList represents a set of space-separated tokens, such as those found in
//! the `class` attribute of HTML elements.
//!
//! ## WHATWG DOM Standard
//!
//! DOMTokenList is primarily used for managing CSS class names via `Element.classList`,
//! but can also be used for other space-separated token lists like `rel` attributes.
//!
//! ## Key Characteristics
//!
//! - **Token Set**: Maintains a set of unique tokens (no duplicates)
//! - **Space-Separated**: Tokens cannot contain whitespace
//! - **Order Preserving**: Maintains insertion order
//! - **Case-Sensitive**: Token matching is case-sensitive
//! - **Dynamic**: Changes reflect immediately in associated attributes
//!
//! ## Common Use Cases
//!
//! ```javascript
//! // CSS class manipulation
//! element.classList.add('active');
//! element.classList.remove('hidden');
//! element.classList.toggle('expanded');
//! element.classList.replace('old-class', 'new-class');
//!
//! // Relationship attributes
//! link.relList.add('noopener');
//! ```
//!
//! ## Examples
//!
//! ### Basic Class Management
//! ```zig
//! var classList = DOMTokenList.init(allocator);
//! defer classList.deinit();
//!
//! try classList.add("button");
//! try classList.add("primary");
//! try expect(classList.contains("button"));
//! ```
//!
//! ### Toggle Pattern
//! ```zig
//! const isActive = try classList.toggle("active", null);
//! if (isActive) {
//!     // Class was added
//! }
//! ```
//!
//! ### String Conversion
//! ```zig
//! const str = try classList.toString(allocator);
//! defer allocator.free(str);
//! // str = "button primary"
//! ```
//!
//! ## Specification References
//!
//! - WHATWG DOM Standard §7.1: https://dom.spec.whatwg.org/#interface-domtokenlist
//! - MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList
//! - HTML Standard (classList): https://html.spec.whatwg.org/multipage/dom.html#dom-classlist
//!
//! ## Memory Management
//!
//! - Call `deinit()` when done to free all tokens
//! - Tokens are copied and owned by the list
//! - Strings from `toString()` must be freed by caller

const std = @import("std");

/// DOMTokenList represents a set of space-separated tokens.
///
/// ## WHATWG DOM Standard §7.1
///
/// DOMTokenList is most commonly used for managing CSS class names via
/// `Element.classList`, but can represent any space-separated token set.
///
/// ## Key Features
///
/// - **No Duplicates**: Adding the same token twice has no effect
/// - **No Whitespace**: Tokens cannot contain spaces, tabs, newlines, etc.
/// - **Case-Sensitive**: "Active" and "active" are different tokens
/// - **Order Preservation**: Tokens maintain insertion order
/// - **Validation**: Empty tokens and whitespace rejected with errors
///
/// ## Validation Rules
///
/// Per the WHATWG DOM specification:
/// - Tokens must not be empty (throws SyntaxError)
/// - Tokens must not contain ASCII whitespace (throws InvalidCharacterError)
/// - These rules ensure tokens can be reliably serialized/parsed
///
/// ## Common Patterns
///
/// ### Class Toggle
/// ```zig
/// // Add if absent, remove if present
/// _ = try classList.toggle("active", null);
/// ```
///
/// ### Conditional Add
/// ```zig
/// // Force add regardless of current state
/// _ = try classList.toggle("selected", true);
/// ```
///
/// ### Class Replacement
/// ```zig
/// // Replace old-theme with new-theme
/// _ = try classList.replace("old-theme", "new-theme");
/// ```
pub const DOMTokenList = struct {
    const Self = @This();

    /// Internal storage for tokens (owned strings).
    tokens: std.ArrayList([]const u8),

    /// Allocator for token storage.
    allocator: std.mem.Allocator,

    /// Creates a new empty token list.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    /// try expect(list.length() == 0);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList interface
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .tokens = std.ArrayList([]const u8){},
            .allocator = allocator,
        };
    }

    /// Releases the token list and all contained tokens.
    ///
    /// ## Memory Management
    ///
    /// Frees all token strings and the internal storage.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit(); // Automatic cleanup
    /// try list.add("token");
    /// ```
    pub fn deinit(self: *Self) void {
        for (self.tokens.items) |token| {
            self.allocator.free(token);
        }
        self.tokens.deinit(self.allocator);
    }

    /// Returns the number of tokens in the list.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    /// try list.add("one");
    /// try list.add("two");
    /// try expect(list.length() == 2);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.length
    pub fn length(self: *const Self) usize {
        return self.tokens.items.len;
    }

    /// Returns the token at the specified index.
    ///
    /// ## Parameters
    ///
    /// - `index`: 0-based index
    ///
    /// ## Returns
    ///
    /// The token at the index, or null if out of bounds.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    /// try list.add("first");
    /// try list.add("second");
    ///
    /// try expectEqualStrings("first", list.item(0).?);
    /// try expect(list.item(10) == null);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.item()
    pub fn item(self: *const Self, index: usize) ?[]const u8 {
        if (index >= self.tokens.items.len) {
            return null;
        }
        return self.tokens.items[index];
    }

    /// Checks if the token exists in the list.
    ///
    /// ## Parameters
    ///
    /// - `token`: Token to search for (case-sensitive)
    ///
    /// ## Returns
    ///
    /// True if the token is present, false otherwise.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    /// try list.add("active");
    ///
    /// try expect(list.contains("active"));
    /// try expect(!list.contains("Active")); // Case-sensitive
    /// try expect(!list.contains("hidden"));
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.contains()
    pub fn contains(self: *const Self, token: []const u8) bool {
        for (self.tokens.items) |t| {
            if (std.mem.eql(u8, t, token)) {
                return true;
            }
        }
        return false;
    }

    /// Adds a token to the list if not already present.
    ///
    /// ## Parameters
    ///
    /// - `token`: Token to add (must be non-empty, no whitespace)
    ///
    /// ## Errors
    ///
    /// - `SyntaxError`: If token is empty
    /// - `InvalidCharacterError`: If token contains whitespace
    ///
    /// ## Behavior
    ///
    /// If the token already exists, this method does nothing (idempotent).
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.add("button");
    /// try list.add("primary");
    /// try expect(list.length() == 2);
    ///
    /// // Adding duplicate has no effect
    /// try list.add("button");
    /// try expect(list.length() == 2);
    /// ```
    ///
    /// ### Error Cases
    /// ```zig
    /// try expectError(error.SyntaxError, list.add(""));
    /// try expectError(error.InvalidCharacterError, list.add("has space"));
    /// try expectError(error.InvalidCharacterError, list.add("has\ttab"));
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.add()
    pub fn add(self: *Self, token: []const u8) !void {
        if (token.len == 0) {
            return error.SyntaxError;
        }

        for (token) |c| {
            if (std.ascii.isWhitespace(c)) {
                return error.InvalidCharacterError;
            }
        }

        if (self.contains(token)) {
            return;
        }

        const token_copy = try self.allocator.dupe(u8, token);
        try self.tokens.append(self.allocator, token_copy);
    }

    /// Removes a token from the list if present.
    ///
    /// ## Parameters
    ///
    /// - `token`: Token to remove (must be non-empty, no whitespace)
    ///
    /// ## Errors
    ///
    /// - `SyntaxError`: If token is empty
    /// - `InvalidCharacterError`: If token contains whitespace
    ///
    /// ## Behavior
    ///
    /// If the token doesn't exist, this method does nothing (idempotent).
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    /// try list.add("active");
    ///
    /// try list.remove("active");
    /// try expect(!list.contains("active"));
    ///
    /// // Removing non-existent token is safe
    /// try list.remove("nonexistent"); // No error
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.remove()
    pub fn remove(self: *Self, token: []const u8) !void {
        if (token.len == 0) {
            return error.SyntaxError;
        }

        for (token) |c| {
            if (std.ascii.isWhitespace(c)) {
                return error.InvalidCharacterError;
            }
        }

        for (self.tokens.items, 0..) |t, i| {
            if (std.mem.eql(u8, t, token)) {
                self.allocator.free(t);
                _ = self.tokens.orderedRemove(i);
                return;
            }
        }
    }

    /// Toggles a token - removes if present, adds if absent.
    ///
    /// ## Parameters
    ///
    /// - `token`: Token to toggle (must be non-empty, no whitespace)
    /// - `force`: Optional boolean to force add (true) or remove (false)
    ///
    /// ## Returns
    ///
    /// True if token is now present, false if now absent.
    ///
    /// ## Errors
    ///
    /// - `SyntaxError`: If token is empty
    /// - `InvalidCharacterError`: If token contains whitespace
    ///
    /// ## Examples
    ///
    /// ### Basic Toggle
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    ///
    /// const added = try list.toggle("active", null);
    /// try expect(added == true);
    ///
    /// const removed = try list.toggle("active", null);
    /// try expect(removed == false);
    /// ```
    ///
    /// ### Force Add
    /// ```zig
    /// // Always add, regardless of current state
    /// _ = try list.toggle("selected", true);
    /// try expect(list.contains("selected"));
    /// ```
    ///
    /// ### Force Remove
    /// ```zig
    /// // Always remove, regardless of current state
    /// _ = try list.toggle("selected", false);
    /// try expect(!list.contains("selected"));
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.toggle()
    pub fn toggle(self: *Self, token: []const u8, force: ?bool) !bool {
        if (token.len == 0) {
            return error.SyntaxError;
        }

        for (token) |c| {
            if (std.ascii.isWhitespace(c)) {
                return error.InvalidCharacterError;
            }
        }

        const exists = self.contains(token);

        if (force) |f| {
            if (f) {
                try self.add(token);
                return true;
            } else {
                try self.remove(token);
                return false;
            }
        }

        if (exists) {
            try self.remove(token);
            return false;
        } else {
            try self.add(token);
            return true;
        }
    }

    /// Replaces one token with another.
    ///
    /// ## Parameters
    ///
    /// - `old_token`: Token to replace (must exist)
    /// - `new_token`: Replacement token
    ///
    /// ## Returns
    ///
    /// True if replacement occurred, false if old_token wasn't present.
    ///
    /// ## Errors
    ///
    /// - `SyntaxError`: If either token is empty
    /// - `InvalidCharacterError`: If either token contains whitespace
    ///
    /// ## Behavior
    ///
    /// - If old_token doesn't exist, returns false (no change)
    /// - If new_token already exists elsewhere, removes old_token and returns true
    /// - Otherwise, replaces old_token with new_token in place
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    /// try list.add("old-theme");
    ///
    /// const replaced = try list.replace("old-theme", "new-theme");
    /// try expect(replaced == true);
    /// try expect(list.contains("new-theme"));
    /// try expect(!list.contains("old-theme"));
    /// ```
    ///
    /// ### Non-existent Token
    /// ```zig
    /// const result = try list.replace("nonexistent", "something");
    /// try expect(result == false); // No change
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.replace()
    pub fn replace(self: *Self, old_token: []const u8, new_token: []const u8) !bool {
        if (old_token.len == 0 or new_token.len == 0) {
            return error.SyntaxError;
        }

        for (old_token) |c| {
            if (std.ascii.isWhitespace(c)) {
                return error.InvalidCharacterError;
            }
        }

        for (new_token) |c| {
            if (std.ascii.isWhitespace(c)) {
                return error.InvalidCharacterError;
            }
        }

        for (self.tokens.items, 0..) |t, i| {
            if (std.mem.eql(u8, t, old_token)) {
                if (self.contains(new_token) and !std.mem.eql(u8, old_token, new_token)) {
                    self.allocator.free(t);
                    _ = self.tokens.orderedRemove(i);
                    return true;
                }

                self.allocator.free(t);
                self.tokens.items[i] = try self.allocator.dupe(u8, new_token);
                return true;
            }
        }

        return false;
    }

    /// Checks if a token is supported (always returns false).
    ///
    /// ## Note
    ///
    /// This method is primarily used with `<iframe sandbox>` and `<link rel>`.
    /// For general DOMTokenList usage (like classList), it returns false.
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.supports()
    pub fn supports(self: *const Self, token: []const u8) bool {
        _ = self;
        _ = token;
        return false;
    }

    /// Converts the token list to a space-separated string.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for the returned string
    ///
    /// ## Returns
    ///
    /// A space-separated string of all tokens. Caller must free.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    /// try list.add("button");
    /// try list.add("primary");
    ///
    /// const str = try list.toString(allocator);
    /// defer allocator.free(str);
    /// try expectEqualStrings("button primary", str);
    /// ```
    ///
    /// ### Empty List
    /// ```zig
    /// var empty = DOMTokenList.init(allocator);
    /// defer empty.deinit();
    ///
    /// const str = try empty.toString(allocator);
    /// defer allocator.free(str);
    /// try expectEqualStrings("", str);
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList stringifier
    pub fn toString(self: *const Self, allocator: std.mem.Allocator) ![]const u8 {
        if (self.tokens.items.len == 0) {
            return try allocator.dupe(u8, "");
        }
        return try std.mem.join(allocator, " ", self.tokens.items);
    }

    /// Sets the token list from a space-separated string.
    ///
    /// ## Parameters
    ///
    /// - `value`: Space-separated token string
    ///
    /// ## Behavior
    ///
    /// - Clears existing tokens
    /// - Parses value on any ASCII whitespace
    /// - Adds unique tokens in order
    /// - Ignores duplicate tokens
    /// - Multiple spaces treated as single separator
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    ///
    /// try list.setValue("button primary active");
    /// try expect(list.length() == 3);
    /// try expect(list.contains("button"));
    /// try expect(list.contains("primary"));
    /// ```
    ///
    /// ### Multiple Spaces and Duplicates
    /// ```zig
    /// try list.setValue("foo  bar  foo  baz");
    /// try expect(list.length() == 3); // Duplicates removed
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §7.1: DOMTokenList.value setter
    pub fn setValue(self: *Self, value: []const u8) !void {
        for (self.tokens.items) |token| {
            self.allocator.free(token);
        }
        self.tokens.clearRetainingCapacity();

        var iter = std.mem.tokenizeAny(u8, value, &std.ascii.whitespace);
        while (iter.next()) |token| {
            if (!self.contains(token)) {
                const token_copy = try self.allocator.dupe(u8, token);
                try self.tokens.append(self.allocator, token_copy);
            }
        }
    }

    /// Removes all tokens from the list.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var list = DOMTokenList.init(allocator);
    /// defer list.deinit();
    /// try list.add("one");
    /// try list.add("two");
    ///
    /// list.clear();
    /// try expect(list.length() == 0);
    /// ```
    pub fn clear(self: *Self) void {
        for (self.tokens.items) |token| {
            self.allocator.free(token);
        }
        self.tokens.clearRetainingCapacity();
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DOMTokenList basic operations" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try std.testing.expectEqual(@as(usize, 0), list.length());

    try list.add("foo");
    try std.testing.expectEqual(@as(usize, 1), list.length());
    try std.testing.expect(list.contains("foo"));

    try list.add("bar");
    try std.testing.expectEqual(@as(usize, 2), list.length());

    try list.add("foo");
    try std.testing.expectEqual(@as(usize, 2), list.length());

    try list.remove("foo");
    try std.testing.expectEqual(@as(usize, 1), list.length());
    try std.testing.expect(!list.contains("foo"));
}

test "DOMTokenList empty list" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try std.testing.expectEqual(@as(usize, 0), list.length());
    try std.testing.expect(!list.contains("anything"));
    try std.testing.expect(list.item(0) == null);
}

test "DOMTokenList add validation" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    // Empty token
    try std.testing.expectError(error.SyntaxError, list.add(""));

    // Whitespace in token
    try std.testing.expectError(error.InvalidCharacterError, list.add("has space"));
    try std.testing.expectError(error.InvalidCharacterError, list.add("has\ttab"));
    try std.testing.expectError(error.InvalidCharacterError, list.add("has\nnewline"));
}

test "DOMTokenList remove validation" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try std.testing.expectError(error.SyntaxError, list.remove(""));
    try std.testing.expectError(error.InvalidCharacterError, list.remove("has space"));
}

test "DOMTokenList remove non-existent" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("exists");
    try list.remove("nonexistent"); // Should not error
    try std.testing.expectEqual(@as(usize, 1), list.length());
}

test "DOMTokenList toggle" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    const result1 = try list.toggle("foo", null);
    try std.testing.expectEqual(true, result1);
    try std.testing.expect(list.contains("foo"));

    const result2 = try list.toggle("foo", null);
    try std.testing.expectEqual(false, result2);
    try std.testing.expect(!list.contains("foo"));

    const result3 = try list.toggle("bar", true);
    try std.testing.expectEqual(true, result3);
    try std.testing.expect(list.contains("bar"));

    const result4 = try list.toggle("bar", true);
    try std.testing.expectEqual(true, result4);
    try std.testing.expect(list.contains("bar"));
}

test "DOMTokenList toggle force false" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("active");
    const result = try list.toggle("active", false);
    try std.testing.expectEqual(false, result);
    try std.testing.expect(!list.contains("active"));
}

test "DOMTokenList toggle validation" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try std.testing.expectError(error.SyntaxError, list.toggle("", null));
    try std.testing.expectError(error.InvalidCharacterError, list.toggle("has space", null));
}

test "DOMTokenList replace" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("foo");
    try list.add("bar");

    const result1 = try list.replace("foo", "baz");
    try std.testing.expectEqual(true, result1);
    try std.testing.expect(!list.contains("foo"));
    try std.testing.expect(list.contains("baz"));

    const result2 = try list.replace("nonexistent", "qux");
    try std.testing.expectEqual(false, result2);
}

test "DOMTokenList replace validation" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try std.testing.expectError(error.SyntaxError, list.replace("", "new"));
    try std.testing.expectError(error.SyntaxError, list.replace("old", ""));
    try std.testing.expectError(error.InvalidCharacterError, list.replace("has space", "new"));
    try std.testing.expectError(error.InvalidCharacterError, list.replace("old", "has space"));
}

test "DOMTokenList replace with existing token" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("foo");
    try list.add("bar");
    try list.add("baz");

    // Replace foo with bar (bar already exists)
    const result = try list.replace("foo", "bar");
    try std.testing.expectEqual(true, result);
    try std.testing.expect(!list.contains("foo"));
    try std.testing.expectEqual(@as(usize, 2), list.length());
}

test "DOMTokenList toString" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("foo");
    try list.add("bar");
    try list.add("baz");

    const str = try list.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("foo bar baz", str);
}

test "DOMTokenList toString empty" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    const str = try list.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("", str);
}

test "DOMTokenList setValue" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.setValue("foo bar baz");
    try std.testing.expectEqual(@as(usize, 3), list.length());
    try std.testing.expect(list.contains("foo"));
    try std.testing.expect(list.contains("bar"));
    try std.testing.expect(list.contains("baz"));

    try list.setValue("foo  bar  foo  baz");
    try std.testing.expectEqual(@as(usize, 3), list.length());
}

test "DOMTokenList setValue with various whitespace" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.setValue("  foo\t\tbar\n\nbaz  ");
    try std.testing.expectEqual(@as(usize, 3), list.length());
    try std.testing.expect(list.contains("foo"));
    try std.testing.expect(list.contains("bar"));
    try std.testing.expect(list.contains("baz"));
}

test "DOMTokenList item access" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("first");
    try list.add("second");
    try list.add("third");

    try std.testing.expectEqualStrings("first", list.item(0).?);
    try std.testing.expectEqualStrings("second", list.item(1).?);
    try std.testing.expectEqualStrings("third", list.item(2).?);
    try std.testing.expect(list.item(3) == null);
}

test "DOMTokenList case sensitivity" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("Active");
    try std.testing.expect(list.contains("Active"));
    try std.testing.expect(!list.contains("active"));
    try std.testing.expect(!list.contains("ACTIVE"));
}

test "DOMTokenList order preservation" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("first");
    try list.add("second");
    try list.add("third");

    const str = try list.toString(allocator);
    defer allocator.free(str);
    try std.testing.expectEqualStrings("first second third", str);
}

test "DOMTokenList clear" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("one");
    try list.add("two");
    try list.add("three");
    try std.testing.expectEqual(@as(usize, 3), list.length());

    list.clear();
    try std.testing.expectEqual(@as(usize, 0), list.length());
}

test "DOMTokenList memory leak test" {
    const allocator = std.testing.allocator;

    var iteration: usize = 0;
    while (iteration < 100) : (iteration += 1) {
        var list = DOMTokenList.init(allocator);
        defer list.deinit();

        try list.add("button");
        try list.add("primary");
        _ = try list.toggle("active", null);
        _ = try list.replace("primary", "secondary");
        try list.setValue("one two three");

        const str = try list.toString(allocator);
        allocator.free(str);
    }
}

test "DOMTokenList multiple operations sequence" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("button");
    try list.add("primary");
    try list.add("large");

    _ = try list.toggle("active", true);
    try std.testing.expectEqual(@as(usize, 4), list.length());

    _ = try list.replace("primary", "secondary");
    try std.testing.expect(list.contains("secondary"));

    try list.remove("large");
    try std.testing.expectEqual(@as(usize, 3), list.length());

    const str = try list.toString(allocator);
    defer allocator.free(str);
    try std.testing.expectEqualStrings("button secondary active", str);
}

test "DOMTokenList setValue clears previous tokens" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try list.add("old1");
    try list.add("old2");
    try std.testing.expectEqual(@as(usize, 2), list.length());

    try list.setValue("new1 new2 new3");
    try std.testing.expectEqual(@as(usize, 3), list.length());
    try std.testing.expect(!list.contains("old1"));
    try std.testing.expect(!list.contains("old2"));
    try std.testing.expect(list.contains("new1"));
}

test "DOMTokenList supports always returns false" {
    const allocator = std.testing.allocator;

    var list = DOMTokenList.init(allocator);
    defer list.deinit();

    try std.testing.expect(!list.supports("anything"));
    try std.testing.expect(!list.supports(""));
}
