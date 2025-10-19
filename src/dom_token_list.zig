//! DOMTokenList Interface (WHATWG DOM)
//!
//! This module implements the DOMTokenList interface as specified by the WHATWG DOM Standard.
//! DOMTokenList represents a set of space-separated tokens (most commonly used for Element.classList).
//! It provides methods for manipulating the token list while keeping it synchronized with the
//! underlying attribute.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **DOMTokenList**: https://dom.spec.whatwg.org/#domtokenlist
//! - **Element.classList**: https://dom.spec.whatwg.org/#dom-element-classlist
//!
//! ## MDN Documentation
//!
//! - DOMTokenList: https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList
//! - Element.classList: https://developer.mozilla.org/en-US/docs/Web/API/Element/classList
//! - DOMTokenList.add(): https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/add
//! - DOMTokenList.remove(): https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/remove
//! - DOMTokenList.toggle(): https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/toggle
//! - DOMTokenList.contains(): https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/contains
//! - DOMTokenList.replace(): https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/replace
//!
//! ## Core Features
//!
//! ### Token Manipulation
//! ```zig
//! const elem = try doc.createElement("div");
//! const classList = elem.classList();
//!
//! // Add tokens
//! try classList.add(&[_][]const u8{"btn", "btn-primary"});
//! // class="btn btn-primary"
//!
//! // Check for token
//! if (classList.contains("btn")) {
//!     std.debug.print("Has btn class\n", .{});
//! }
//!
//! // Remove tokens
//! try classList.remove(&[_][]const u8{"btn-primary"});
//! // class="btn"
//!
//! // Toggle token
//! _ = try classList.toggle("active", null);
//! // class="btn active"
//! ```
//!
//! ### Live Collection
//! DOMTokenList is a **live view** of the underlying attribute:
//! ```zig
//! const classList = elem.classList();
//! try classList.add(&[_][]const u8{"foo"});
//!
//! // Changes are immediately reflected in the attribute
//! const class_attr = elem.getAttribute("class");
//! // class_attr = "foo"
//!
//! // Modifying the attribute updates the token list
//! try elem.setAttribute("class", "bar baz");
//! try std.testing.expect(classList.contains("bar"));
//! try std.testing.expect(classList.contains("baz"));
//! ```
//!
//! ## Architecture
//!
//! DOMTokenList is implemented as a thin wrapper around an Element:
//! - Stores a pointer to the associated Element
//! - Stores the attribute name (typically "class")
//! - All operations read/write the attribute directly (live behavior)
//! - No internal storage - always reflects current attribute value
//!
//! ## Spec Compliance
//!
//! This implementation follows WHATWG DOM §4.9 exactly:
//! - ✅ Tokens are separated by ASCII whitespace
//! - ✅ Duplicate tokens are not added
//! - ✅ Empty string tokens cause SyntaxError
//! - ✅ Tokens containing whitespace cause InvalidCharacterError
//! - ✅ Order is preserved (insertion order)
//! - ✅ Case-sensitive token matching
//! - ✅ Live collection (no caching)

const std = @import("std");
const Allocator = std.mem.Allocator;
const Element = @import("element.zig").Element;

/// DOMTokenList - A set of space-separated tokens.
///
/// Implements WHATWG DOM DOMTokenList per DOM spec.
///
/// ## WebIDL
/// ```webidl
/// interface DOMTokenList {
///   readonly attribute unsigned long length;
///   getter DOMString? item(unsigned long index);
///   boolean contains(DOMString token);
///   [CEReactions] undefined add(DOMString... tokens);
///   [CEReactions] undefined remove(DOMString... tokens);
///   [CEReactions] boolean toggle(DOMString token, optional boolean force);
///   [CEReactions] boolean replace(DOMString token, DOMString newToken);
///   boolean supports(DOMString token);
///   [CEReactions] stringifier attribute DOMString value;
///   iterable<DOMString>;
/// };
/// ```
///
/// ## Spec References
/// - Interface: https://dom.spec.whatwg.org/#domtokenlist
/// - WebIDL: dom.idl:121-132
pub const DOMTokenList = struct {
    /// Associated element (weak pointer - element owns the token list reference)
    element: *Element,

    /// Attribute name (typically "class")
    attribute_name: []const u8,

    /// Iterator state for next() method
    /// Tracks current position when iterating through tokens
    iterator_index: usize = 0,

    /// Returns the number of tokens.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute unsigned long length;
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// Return the number of tokens in the associated attribute's value.
    ///
    /// ## Returns
    /// Number of tokens (0 if attribute not set or empty)
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-length
    /// - WebIDL: dom.idl:122
    pub fn length(self: DOMTokenList) usize {
        const attr_value = self.element.getAttribute(self.attribute_name) orelse return 0;
        if (attr_value.len == 0) return 0;

        var count: usize = 0;
        var iter = std.mem.tokenizeAny(u8, attr_value, " \t\r\n\x0C");
        while (iter.next()) |_| {
            count += 1;
        }
        return count;
    }

    /// Returns the token at the given index.
    ///
    /// ## WebIDL
    /// ```webidl
    /// getter DOMString? item(unsigned long index);
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// Return the index-th token in the associated attribute's value, or null if index ≥ length.
    ///
    /// ## Parameters
    /// - `index`: Zero-based index
    ///
    /// ## Returns
    /// Borrowed string (slice into attribute value), or null if index out of bounds
    ///
    /// ## Note
    /// The returned slice is only valid as long as the element's class attribute remains unchanged.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-item
    /// - WebIDL: dom.idl:123
    pub fn item(self: DOMTokenList, index: usize) ?[]const u8 {
        const attr_value = self.element.getAttribute(self.attribute_name) orelse return null;

        var iter = std.mem.tokenizeAny(u8, attr_value, " \t\r\n\x0C");
        var i: usize = 0;
        while (iter.next()) |token| {
            if (i == index) {
                return token;
            }
            i += 1;
        }
        return null;
    }

    /// Checks if a token exists in the list.
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean contains(DOMString token);
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// Return true if the associated attribute's value contains token, false otherwise.
    ///
    /// ## Parameters
    /// - `token`: Token to search for
    ///
    /// ## Returns
    /// true if token exists, false otherwise
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-contains
    /// - WebIDL: dom.idl:124
    pub fn contains(self: DOMTokenList, token: []const u8) bool {
        const attr_value = self.element.getAttribute(self.attribute_name) orelse return false;

        var iter = std.mem.tokenizeAny(u8, attr_value, " \t\r\n\x0C");
        while (iter.next()) |existing_token| {
            if (std.mem.eql(u8, existing_token, token)) {
                return true;
            }
        }
        return false;
    }

    /// Adds tokens to the list.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] undefined add(DOMString... tokens);
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// For each token in tokens:
    /// 1. If token is empty, throw SyntaxError
    /// 2. If token contains ASCII whitespace, throw InvalidCharacterError
    /// 3. If token not already in list, append it
    /// 4. Update the associated attribute
    ///
    /// ## Parameters
    /// - `tokens`: Tokens to add
    ///
    /// ## Errors
    /// - `SyntaxError`: Empty token
    /// - `InvalidCharacterError`: Token contains whitespace
    /// - `OutOfMemory`: Failed to allocate new attribute value
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-add
    /// - WebIDL: dom.idl:125
    pub fn add(self: DOMTokenList, tokens: []const []const u8) !void {
        // Step 1: Validate all tokens first
        for (tokens) |token| {
            if (token.len == 0) {
                return error.SyntaxError;
            }
            for (token) |c| {
                if (c == ' ' or c == '\t' or c == '\r' or c == '\n' or c == 0x0C) {
                    return error.InvalidCharacterError;
                }
            }
        }

        // Step 2: Get current value
        const current = self.element.getAttribute(self.attribute_name) orelse "";
        const allocator = self.element.prototype.allocator;

        // Step 3: Build new token list
        var new_tokens = std.ArrayList([]const u8){};
        defer new_tokens.deinit(allocator);

        // Add existing tokens
        if (current.len > 0) {
            var iter = std.mem.tokenizeAny(u8, current, " \t\r\n\x0C");
            while (iter.next()) |existing_token| {
                try new_tokens.append(allocator, existing_token);
            }
        }

        // Add new tokens (if not already present)
        for (tokens) |token| {
            var found = false;
            for (new_tokens.items) |existing| {
                if (std.mem.eql(u8, existing, token)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                try new_tokens.append(allocator, token);
            }
        }

        // Step 4: Join and set attribute
        const new_value = try std.mem.join(allocator, " ", new_tokens.items);
        defer allocator.free(new_value);

        // Intern the new value via the document's string pool
        if (self.element.prototype.owner_document) |owner| {
            if (owner.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner);
                const interned = try doc.string_pool.intern(new_value);
                try self.element.setAttribute(self.attribute_name, interned);
                return;
            }
        }

        // Fallback: If no owner document, duplicate the string
        // (this shouldn't happen in normal use, but provides safety)
        const duped = try allocator.dupe(u8, new_value);
        try self.element.setAttribute(self.attribute_name, duped);
    }

    /// Removes tokens from the list.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] undefined remove(DOMString... tokens);
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// For each token in tokens:
    /// 1. If token is empty, throw SyntaxError
    /// 2. If token contains ASCII whitespace, throw InvalidCharacterError
    /// 3. Remove token from list (if present)
    /// 4. Update the associated attribute
    ///
    /// ## Parameters
    /// - `tokens`: Tokens to remove
    ///
    /// ## Errors
    /// - `SyntaxError`: Empty token
    /// - `InvalidCharacterError`: Token contains whitespace
    /// - `OutOfMemory`: Failed to allocate new attribute value
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-remove
    /// - WebIDL: dom.idl:126
    pub fn remove(self: DOMTokenList, tokens: []const []const u8) !void {
        // Step 1: Validate all tokens first
        for (tokens) |token| {
            if (token.len == 0) {
                return error.SyntaxError;
            }
            for (token) |c| {
                if (c == ' ' or c == '\t' or c == '\r' or c == '\n' or c == 0x0C) {
                    return error.InvalidCharacterError;
                }
            }
        }

        // Step 2: Get current value
        const current = self.element.getAttribute(self.attribute_name) orelse return; // Nothing to remove
        const allocator = self.element.prototype.allocator;

        // Step 3: Build new token list (excluding tokens to remove)
        var new_tokens = std.ArrayList([]const u8){};
        defer new_tokens.deinit(allocator);

        var iter = std.mem.tokenizeAny(u8, current, " \t\r\n\x0C");
        while (iter.next()) |existing_token| {
            var should_keep = true;
            for (tokens) |token_to_remove| {
                if (std.mem.eql(u8, existing_token, token_to_remove)) {
                    should_keep = false;
                    break;
                }
            }
            if (should_keep) {
                try new_tokens.append(allocator, existing_token);
            }
        }

        // Step 4: Join and set attribute (or remove if empty)
        if (new_tokens.items.len == 0) {
            self.element.removeAttribute(self.attribute_name);
        } else {
            const new_value = try std.mem.join(allocator, " ", new_tokens.items);
            defer allocator.free(new_value);

            // Intern the new value via the document's string pool
            if (self.element.prototype.owner_document) |owner| {
                if (owner.node_type == .document) {
                    const Document = @import("document.zig").Document;
                    const doc: *Document = @fieldParentPtr("prototype", owner);
                    const interned = try doc.string_pool.intern(new_value);
                    try self.element.setAttribute(self.attribute_name, interned);
                    return;
                }
            }

            // Fallback: If no owner document, duplicate the string
            const duped = try allocator.dupe(u8, new_value);
            try self.element.setAttribute(self.attribute_name, duped);
        }
    }

    /// Toggles a token in the list.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] boolean toggle(DOMString token, optional boolean force);
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// 1. If token is empty, throw SyntaxError
    /// 2. If token contains ASCII whitespace, throw InvalidCharacterError
    /// 3. If force is not given:
    ///    - If token exists, remove it and return false
    ///    - Otherwise, add it and return true
    /// 4. If force is true, add token (if not present) and return true
    /// 5. If force is false, remove token (if present) and return false
    ///
    /// ## Parameters
    /// - `token`: Token to toggle
    /// - `force`: Optional force flag (null = toggle, true = add, false = remove)
    ///
    /// ## Returns
    /// true if token is now present, false otherwise
    ///
    /// ## Errors
    /// - `SyntaxError`: Empty token
    /// - `InvalidCharacterError`: Token contains whitespace
    /// - `OutOfMemory`: Failed to allocate new attribute value
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-toggle
    /// - WebIDL: dom.idl:127
    pub fn toggle(self: DOMTokenList, token: []const u8, force: ?bool) !bool {
        // Step 1: Validate token
        if (token.len == 0) {
            return error.SyntaxError;
        }
        for (token) |c| {
            if (c == ' ' or c == '\t' or c == '\r' or c == '\n' or c == 0x0C) {
                return error.InvalidCharacterError;
            }
        }

        // Step 2: Check if token exists
        const token_exists = self.contains(token);

        // Step 3: Apply logic based on force parameter
        if (force) |f| {
            if (f) {
                // Force true: add if not present
                if (!token_exists) {
                    try self.add(&[_][]const u8{token});
                }
                return true;
            } else {
                // Force false: remove if present
                if (token_exists) {
                    try self.remove(&[_][]const u8{token});
                }
                return false;
            }
        } else {
            // No force: toggle
            if (token_exists) {
                try self.remove(&[_][]const u8{token});
                return false;
            } else {
                try self.add(&[_][]const u8{token});
                return true;
            }
        }
    }

    /// Replaces a token with a new token.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] boolean replace(DOMString token, DOMString newToken);
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// 1. If either token is empty, throw SyntaxError
    /// 2. If either token contains ASCII whitespace, throw InvalidCharacterError
    /// 3. If token not in list, return false
    /// 4. Replace first occurrence of token with newToken
    /// 5. Remove any subsequent occurrences of token
    /// 6. Update the associated attribute
    /// 7. Return true
    ///
    /// ## Parameters
    /// - `token`: Token to replace
    /// - `new_token`: Replacement token
    ///
    /// ## Returns
    /// true if token was replaced, false if token not found
    ///
    /// ## Errors
    /// - `SyntaxError`: Empty token
    /// - `InvalidCharacterError`: Token contains whitespace
    /// - `OutOfMemory`: Failed to allocate new attribute value
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-replace
    /// - WebIDL: dom.idl:128
    pub fn replace(self: DOMTokenList, token: []const u8, new_token: []const u8) !bool {
        // Step 1: Validate tokens
        if (token.len == 0 or new_token.len == 0) {
            return error.SyntaxError;
        }
        for (token) |c| {
            if (c == ' ' or c == '\t' or c == '\r' or c == '\n' or c == 0x0C) {
                return error.InvalidCharacterError;
            }
        }
        for (new_token) |c| {
            if (c == ' ' or c == '\t' or c == '\r' or c == '\n' or c == 0x0C) {
                return error.InvalidCharacterError;
            }
        }

        // Step 2: Check if token exists
        if (!self.contains(token)) {
            return false;
        }

        // Step 3: Build new token list with replacement
        const current = self.element.getAttribute(self.attribute_name).?; // We know it exists
        const allocator = self.element.prototype.allocator;

        var new_tokens = std.ArrayList([]const u8){};
        defer new_tokens.deinit(allocator);

        var replaced = false;
        var iter = std.mem.tokenizeAny(u8, current, " \t\r\n\x0C");
        while (iter.next()) |existing_token| {
            if (std.mem.eql(u8, existing_token, token)) {
                if (!replaced) {
                    // Replace first occurrence
                    // Check if new_token already exists
                    var new_token_exists = false;
                    for (new_tokens.items) |t| {
                        if (std.mem.eql(u8, t, new_token)) {
                            new_token_exists = true;
                            break;
                        }
                    }
                    if (!new_token_exists) {
                        try new_tokens.append(allocator, new_token);
                    }
                    replaced = true;
                }
                // Skip subsequent occurrences
            } else {
                try new_tokens.append(allocator, existing_token);
            }
        }

        // Step 4: Join and set attribute
        const new_value = try std.mem.join(allocator, " ", new_tokens.items);
        defer allocator.free(new_value);

        // Intern the new value via the document's string pool
        if (self.element.prototype.owner_document) |owner| {
            if (owner.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner);
                const interned = try doc.string_pool.intern(new_value);
                try self.element.setAttribute(self.attribute_name, interned);
                return true;
            }
        }

        // Fallback: If no owner document, duplicate the string
        const duped = try allocator.dupe(u8, new_value);
        try self.element.setAttribute(self.attribute_name, duped);
        return true;
    }

    /// Checks if a token is supported (always returns true for class attribute).
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean supports(DOMString token);
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// For classList, this always returns true (all tokens are supported).
    /// This method is primarily for other token list attributes like rel.
    ///
    /// ## Parameters
    /// - `token`: Token to check
    ///
    /// ## Returns
    /// true (all class tokens are supported)
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-supports
    /// - WebIDL: dom.idl:129
    pub fn supports(self: *const DOMTokenList, token: []const u8) bool {
        _ = self;
        _ = token;
        // For classList, all tokens are supported
        return true;
    }

    /// Returns the complete token list as a string.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] stringifier attribute DOMString value;
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// Return the associated attribute's value, or empty string if not set.
    ///
    /// ## Returns
    /// Attribute value (space-separated tokens), or empty string
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-value
    /// - WebIDL: dom.idl:130
    pub fn value(self: *const DOMTokenList) []const u8 {
        return self.element.getAttribute(self.attribute_name) orelse "";
    }

    /// Sets the complete token list from a string.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] stringifier attribute DOMString value;
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// Set the associated attribute to the given value.
    ///
    /// ## Parameters
    /// - `new_value`: New attribute value (space-separated tokens)
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate new attribute value
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domtokenlist-value
    /// - WebIDL: dom.idl:130
    pub fn setValue(self: DOMTokenList, new_value: []const u8) !void {
        if (new_value.len == 0) {
            self.element.removeAttribute(self.attribute_name);
        } else {
            try self.element.setAttribute(self.attribute_name, new_value);
        }
    }

    /// Returns the next token in the iteration, or null if done.
    ///
    /// This implements the iterable<DOMString> WebIDL behavior.
    /// Each call to next() returns the next token in order until all tokens are consumed.
    ///
    /// ## WebIDL
    /// ```webidl
    /// iterable<DOMString>;
    /// ```
    ///
    /// ## Usage
    /// ```zig
    /// const classList = elem.classList();
    /// var iter = classList;
    /// while (iter.next()) |token| {
    ///     std.debug.print("Token: {s}\n", .{token});
    /// }
    /// ```
    ///
    /// ## Returns
    /// Next token string, or null if iteration is complete
    ///
    /// ## Note
    /// The iterator must be mutable (var, not const) since it tracks state.
    /// The returned slice is valid as long as the element's class attribute remains unchanged.
    ///
    /// ## Spec References
    /// - WebIDL iterable: https://webidl.spec.whatwg.org/#idl-iterable
    /// - DOMTokenList: https://dom.spec.whatwg.org/#domtokenlist
    pub fn next(self: *DOMTokenList) ?[]const u8 {
        const attr_value = self.element.getAttribute(self.attribute_name) orelse return null;
        if (attr_value.len == 0) return null;

        var iter = std.mem.tokenizeAny(u8, attr_value, " \t\r\n\x0C");
        var current_index: usize = 0;

        // Skip to the current iterator position
        while (current_index < self.iterator_index) : (current_index += 1) {
            _ = iter.next() orelse return null;
        }

        // Get the next token
        if (iter.next()) |token| {
            self.iterator_index += 1;
            return token;
        }

        return null;
    }
};
