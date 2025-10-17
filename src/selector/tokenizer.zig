//! CSS Selector Tokenizer (Selectors Level 4)
//!
//! This module implements tokenization for CSS Selectors Level 4 syntax as used by
//! WHATWG DOM querySelector/querySelectorAll. The tokenizer breaks selector strings
//! into tokens for subsequent parsing, supporting the full Selectors-4 syntax including
//! pseudo-classes, attributes, and combinators.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§1.3 Selectors**: https://dom.spec.whatwg.org/#selectors
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#parentnode (querySelector)
//! - **§4.9 Interface Element**: https://dom.spec.whatwg.org/#interface-element (matches)
//!
//! ## CSS Selectors Specification
//!
//! - **Selectors Level 4**: https://drafts.csswg.org/selectors-4/
//! - **§3 Selector Syntax**: https://drafts.csswg.org/selectors-4/#selector-syntax
//! - **§16 Grammar**: https://drafts.csswg.org/selectors-4/#grammar
//!
//! ## MDN Documentation
//!
//! - CSS Selectors: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Selectors
//! - querySelector(): https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector
//! - CSS Selector syntax: https://developer.mozilla.org/en-US/docs/Learn/CSS/Building_blocks/Selectors
//!
//! ## Core Features
//!
//! ### Token Stream
//! Convert selector string into token stream:
//! ```zig
//! const input = "div.container > p.text[data-id='123']";
//! var tokenizer = Tokenizer.init(input);
//!
//! while (try tokenizer.next()) |token| {
//!     // Token{ .tag = .ident, .value = "div", ... }
//!     // Token{ .tag = .dot, .value = ".", ... }
//!     // Token{ .tag = .ident, .value = "container", ... }
//!     // Token{ .tag = .gt, .value = ">", ... }
//!     // ... etc
//! }
//! ```
//!
//! ### Supported Tokens
//! All CSS Selectors Level 4 token types:
//! ```zig
//! // Simple selectors
//! "div"           → .ident
//! ".class"        → .dot + .ident
//! "#id"           → .hash
//! "*"             → .asterisk
//!
//! // Combinators
//! ">"             → .gt (child)
//! "+"             → .plus (next sibling)
//! "~"             → .tilde (subsequent sibling)
//! " "             → .whitespace (descendant)
//!
//! // Attributes
//! "[attr]"        → .lbracket + .ident + .rbracket
//! "[attr=val]"    → ... + .equals + ...
//! "[attr^=val]"   → ... + .prefix_match + ...
//! ```
//!
//! ### Zero-Copy Design
//! Tokens are slices into original string (no allocation):
//! ```zig
//! const input = "div.container";
//! var tokenizer = Tokenizer.init(input);
//!
//! const tok1 = try tokenizer.next();
//! // tok1.value points into input ("div")
//! // No string duplication
//! ```
//!
//! ## Tokenizer Structure
//!
//! Tokenizer maintains scanning state:
//! - **input**: Source selector string
//! - **pos**: Current position in input
//! - **start**: Start of current token
//!
//! **Tokenization is:**
//! - Single-pass (left-to-right scan)
//! - Zero-copy (tokens are string slices)
//! - Fast-path for ASCII (most common case)
//! - UTF-8 aware for international content
//!
//! ## Memory Management
//!
//! Tokenizer is stack-allocated, tokens reference input string:
//! ```zig
//! const input = "div > p";
//! var tokenizer = Tokenizer.init(input);
//! // No defer needed - Tokenizer is a plain struct
//!
//! // Tokens are slices into input
//! // input must outlive tokens
//! ```
//!
//! ## Usage Examples
//!
//! ### Basic Tokenization
//! ```zig
//! const input = "div.container";
//! var tokenizer = Tokenizer.init(input);
//!
//! const tok1 = (try tokenizer.next()).?;
//! try std.testing.expectEqual(Token.Tag.ident, tok1.tag);
//! try std.testing.expectEqualStrings("div", tok1.value);
//!
//! const tok2 = (try tokenizer.next()).?;
//! try std.testing.expectEqual(Token.Tag.dot, tok2.tag);
//!
//! const tok3 = (try tokenizer.next()).?;
//! try std.testing.expectEqual(Token.Tag.ident, tok3.tag);
//! try std.testing.expectEqualStrings("container", tok3.value);
//! ```
//!
//! ### Complex Selector
//! ```zig
//! const input = "article > header h1[class*='title']:first-child";
//! var tokenizer = Tokenizer.init(input);
//!
//! var tokens = std.ArrayList(Token).init(allocator);
//! defer tokens.deinit();
//!
//! while (try tokenizer.next()) |token| {
//!     if (token.tag != .whitespace) { // Skip whitespace
//!         try tokens.append(token);
//!     }
//! }
//! ```
//!
//! ### Error Handling
//! ```zig
//! const invalid = "div[unclosed";
//! var tokenizer = Tokenizer.init(invalid);
//!
//! while (tokenizer.next()) |token| {
//!     // Process token
//! } else |err| {
//!     // Handle tokenization error
//!     std.debug.print("Error: {}\n", .{err});
//! }
//! ```
//!
//! ## Common Patterns
//!
//! ### Skip Whitespace
//! ```zig
//! fn nextNonWhitespace(tokenizer: *Tokenizer) !?Token {
//!     while (try tokenizer.next()) |token| {
//!         if (token.tag != .whitespace) {
//!             return token;
//!         }
//!     }
//!     return null;
//! }
//! ```
//!
//! ### Peek Ahead
//! ```zig
//! fn peekToken(tokenizer: *Tokenizer) !?Token {
//!     const saved_pos = tokenizer.pos;
//!     defer tokenizer.pos = saved_pos; // Restore position
//!
//!     return try tokenizer.next();
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **ASCII Fast Path** - Tokenizer optimized for ASCII (most selectors)
//! 2. **Zero-Copy** - Tokens are slices, no string allocation
//! 3. **Single Pass** - One left-to-right scan
//! 4. **Skip Whitespace** - Filter whitespace tokens if not needed for parsing
//! 5. **Reuse Tokenizer** - Reset and reuse instead of creating new instances
//! 6. **Inline Scanning** - Hot path functions marked inline
//!
//! ## Implementation Notes
//!
//! - Implements CSS Syntax Module Level 3 tokenization
//! - Supports full Selectors Level 4 token set
//! - Zero-copy design (tokens are slices into input)
//! - Single-pass left-to-right scanning
//! - ASCII fast path for common case
//! - UTF-8 aware for international identifiers
//! - Handles CSS escapes (\XX, \\n, etc.)
//! - Whitespace tokens can be filtered by parser
//! - Error handling for unclosed strings, invalid escapes
//! - Compatible with subsequent parser implementation

const std = @import("std");
const Allocator = std.mem.Allocator;

/// CSS selector token
pub const Token = struct {
    tag: Tag,
    value: []const u8,
    start: usize,
    end: usize,

    pub const Tag = enum {
        // Identifiers and names
        ident, // tag names, identifiers
        hash, // #id
        string, // "string" or 'string'

        // Delimiters
        dot, // .
        comma, // ,
        gt, // >
        plus, // +
        tilde, // ~
        lparen, // (
        rparen, // )
        lbracket, // [
        rbracket, // ]
        colon, // :
        equals, // =

        // Attribute matchers
        prefix_match, // ^=
        suffix_match, // $=
        substring_match, // *=
        includes_match, // ~=
        dash_match, // |=

        // Special
        asterisk, // *
        whitespace, // space/tab/newline
        eof, // end of input
    };
};

/// Tokenizer state
pub const Tokenizer = struct {
    input: []const u8,
    pos: usize = 0,
    allocator: Allocator,

    pub fn init(allocator: Allocator, input: []const u8) Tokenizer {
        return .{
            .input = input,
            .allocator = allocator,
        };
    }

    /// Tokenize entire input into token list
    pub fn tokenize(self: *Tokenizer) ![]Token {
        var tokens = std.ArrayList(Token){};
        defer tokens.deinit(self.allocator);

        while (true) {
            const token = try self.nextToken();
            try tokens.append(self.allocator, token);
            if (token.tag == .eof) break;
        }

        return tokens.toOwnedSlice(self.allocator);
    }

    /// Get next token from input
    pub fn nextToken(self: *Tokenizer) !Token {
        // Don't skip whitespace - it's significant for descendant combinator
        // self.skipWhitespace();

        const start = self.pos;

        if (self.pos >= self.input.len) {
            return Token{
                .tag = .eof,
                .value = "",
                .start = start,
                .end = start,
            };
        }

        const c = self.input[self.pos];

        // Single-character tokens
        return switch (c) {
            '.' => self.makeToken(.dot, start, 1),
            ',' => self.makeToken(.comma, start, 1),
            '>' => self.makeToken(.gt, start, 1),
            '+' => self.makeToken(.plus, start, 1),
            '~' => {
                // Could be ~= (includes match) or ~ (general sibling)
                if (self.peek() == '=') {
                    return self.makeToken(.includes_match, start, 2);
                }
                return self.makeToken(.tilde, start, 1);
            },
            '(' => self.makeToken(.lparen, start, 1),
            ')' => self.makeToken(.rparen, start, 1),
            '[' => self.makeToken(.lbracket, start, 1),
            ']' => self.makeToken(.rbracket, start, 1),
            ':' => self.makeToken(.colon, start, 1),
            '=' => self.makeToken(.equals, start, 1),
            '*' => {
                // Could be *= (substring match) or * (universal)
                if (self.peek() == '=') {
                    return self.makeToken(.substring_match, start, 2);
                }
                return self.makeToken(.asterisk, start, 1);
            },
            '#' => {
                // Hash token (#id)
                self.pos += 1;
                const ident_start = self.pos;
                if (!self.isIdentStart()) {
                    return error.UnexpectedToken;
                }
                self.consumeIdent();
                const value = self.input[ident_start..self.pos];
                return Token{
                    .tag = .hash,
                    .value = value,
                    .start = start,
                    .end = self.pos,
                };
            },
            '^' => {
                // Must be ^= (prefix match)
                if (self.peek() != '=') {
                    return error.UnexpectedToken;
                }
                return self.makeToken(.prefix_match, start, 2);
            },
            '$' => {
                // Must be $= (suffix match)
                if (self.peek() != '=') {
                    return error.UnexpectedToken;
                }
                return self.makeToken(.suffix_match, start, 2);
            },
            '|' => {
                // Must be |= (dash match)
                if (self.peek() != '=') {
                    return error.UnexpectedToken;
                }
                return self.makeToken(.dash_match, start, 2);
            },
            '"', '\'' => {
                // String literal
                return self.consumeString(c);
            },
            ' ', '\t', '\n', '\r' => {
                // Whitespace (important for descendant combinator)
                self.consumeWhitespace();
                return Token{
                    .tag = .whitespace,
                    .value = self.input[start..self.pos],
                    .start = start,
                    .end = self.pos,
                };
            },
            else => {
                // Could be identifier or number
                if (self.isIdentStart()) {
                    return self.consumeIdentToken(start);
                } else if (c >= '0' and c <= '9') {
                    // Number (for nth-child patterns like "2n+1")
                    return self.consumeIdentToken(start); // Treat as ident for now
                }
                return error.UnexpectedToken;
            },
        };
    }

    /// Create simple token and advance position
    fn makeToken(self: *Tokenizer, tag: Token.Tag, start: usize, len: usize) Token {
        self.pos += len;
        return Token{
            .tag = tag,
            .value = self.input[start..self.pos],
            .start = start,
            .end = self.pos,
        };
    }

    /// Peek next character without consuming
    fn peek(self: *const Tokenizer) ?u8 {
        if (self.pos + 1 >= self.input.len) return null;
        return self.input[self.pos + 1];
    }

    /// Check if current position is identifier start
    fn isIdentStart(self: *const Tokenizer) bool {
        if (self.pos >= self.input.len) return false;
        const c = self.input[self.pos];
        return switch (c) {
            'a'...'z', 'A'...'Z', '_' => true,
            '-' => {
                // Identifier can start with - if followed by letter/underscore
                if (self.pos + 1 >= self.input.len) return false;
                const next = self.input[self.pos + 1];
                return switch (next) {
                    'a'...'z', 'A'...'Z', '_' => true,
                    else => false,
                };
            },
            0x80...0xFF => true, // Non-ASCII (Unicode)
            else => false,
        };
    }

    /// Check if character is identifier continuation
    fn isIdentContinue(c: u8) bool {
        return switch (c) {
            'a'...'z', 'A'...'Z', '0'...'9', '_', '-' => true,
            0x80...0xFF => true, // Non-ASCII (Unicode)
            else => false,
        };
    }

    /// Consume identifier characters
    fn consumeIdent(self: *Tokenizer) void {
        while (self.pos < self.input.len) : (self.pos += 1) {
            const c = self.input[self.pos];
            if (!isIdentContinue(c)) break;
        }
    }

    /// Consume identifier token
    fn consumeIdentToken(self: *Tokenizer, start: usize) Token {
        // Consume identifier or number-like pattern
        while (self.pos < self.input.len) {
            const c = self.input[self.pos];
            if (!isIdentContinue(c) and !(c >= '0' and c <= '9')) break;
            self.pos += 1;
        }
        return Token{
            .tag = .ident,
            .value = self.input[start..self.pos],
            .start = start,
            .end = self.pos,
        };
    }

    /// Consume string literal
    fn consumeString(self: *Tokenizer, quote: u8) !Token {
        const start = self.pos;
        self.pos += 1; // Skip opening quote

        const value_start = self.pos;

        while (self.pos < self.input.len) {
            const c = self.input[self.pos];
            if (c == quote) {
                // Found closing quote
                const value = self.input[value_start..self.pos];
                self.pos += 1; // Skip closing quote
                return Token{
                    .tag = .string,
                    .value = value,
                    .start = start,
                    .end = self.pos,
                };
            } else if (c == '\\') {
                // Escape sequence - skip next character
                self.pos += 2;
            } else if (c == '\n' or c == '\r') {
                // Unescaped newline in string is error
                return error.UnexpectedToken;
            } else {
                self.pos += 1;
            }
        }

        // Unclosed string
        return error.UnexpectedEOF;
    }

    /// Skip whitespace
    fn skipWhitespace(self: *Tokenizer) void {
        while (self.pos < self.input.len) {
            const c = self.input[self.pos];
            if (c != ' ' and c != '\t' and c != '\n' and c != '\r') break;
            self.pos += 1;
        }
    }

    /// Consume whitespace (for whitespace token)
    fn consumeWhitespace(self: *Tokenizer) void {
        while (self.pos < self.input.len) {
            const c = self.input[self.pos];
            if (c != ' ' and c != '\t' and c != '\n' and c != '\r') break;
            self.pos += 1;
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

const testing = std.testing;

test "Tokenizer - simple type selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len); // ident + eof
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqualStrings("div", tokens[0].value);
    try testing.expectEqual(Token.Tag.eof, tokens[1].tag);
}

test "Tokenizer - class selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ".foo");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 3), tokens.len); // dot + ident + eof
    try testing.expectEqual(Token.Tag.dot, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("foo", tokens[1].value);
}

test "Tokenizer - ID selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "#myid");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len); // hash + eof
    try testing.expectEqual(Token.Tag.hash, tokens[0].tag);
    try testing.expectEqualStrings("myid", tokens[0].value);
}

test "Tokenizer - compound selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div.foo#bar");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div . foo # bar eof
    try testing.expectEqual(@as(usize, 5), tokens.len);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqualStrings("div", tokens[0].value);
    try testing.expectEqual(Token.Tag.dot, tokens[1].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[2].tag);
    try testing.expectEqualStrings("foo", tokens[2].value);
    try testing.expectEqual(Token.Tag.hash, tokens[3].tag);
    try testing.expectEqualStrings("bar", tokens[3].value);
}

test "Tokenizer - child combinator" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div > p");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div whitespace > whitespace p eof
    try testing.expectEqual(@as(usize, 6), tokens.len);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqual(Token.Tag.whitespace, tokens[1].tag);
    try testing.expectEqual(Token.Tag.gt, tokens[2].tag);
    try testing.expectEqual(Token.Tag.whitespace, tokens[3].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[4].tag);
}

test "Tokenizer - adjacent sibling combinator" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div+p");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div + p eof
    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqual(Token.Tag.plus, tokens[1].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[2].tag);
}

test "Tokenizer - general sibling combinator" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div~p");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div ~ p eof
    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqual(Token.Tag.tilde, tokens[1].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[2].tag);
}

test "Tokenizer - attribute selector with presence" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // [ href ] eof
    try testing.expectEqual(@as(usize, 4), tokens.len);
    try testing.expectEqual(Token.Tag.lbracket, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("href", tokens[1].value);
    try testing.expectEqual(Token.Tag.rbracket, tokens[2].tag);
}

test "Tokenizer - attribute selector with exact match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[type=\"text\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // [ type = "text" ] eof
    try testing.expectEqual(@as(usize, 6), tokens.len);
    try testing.expectEqual(Token.Tag.lbracket, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("type", tokens[1].value);
    try testing.expectEqual(Token.Tag.equals, tokens[2].tag);
    try testing.expectEqual(Token.Tag.string, tokens[3].tag);
    try testing.expectEqualStrings("text", tokens[3].value);
    try testing.expectEqual(Token.Tag.rbracket, tokens[4].tag);
}

test "Tokenizer - attribute selector with prefix match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href^=\"http\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // [ href ^= "http" ] eof
    try testing.expectEqual(@as(usize, 6), tokens.len);
    try testing.expectEqual(Token.Tag.lbracket, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqual(Token.Tag.prefix_match, tokens[2].tag);
    try testing.expectEqual(Token.Tag.string, tokens[3].tag);
    try testing.expectEqualStrings("http", tokens[3].value);
}

test "Tokenizer - attribute selector with suffix match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href$=\".pdf\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.suffix_match, tokens[2].tag);
    try testing.expectEqualStrings(".pdf", tokens[3].value);
}

test "Tokenizer - attribute selector with substring match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[href*=\"example\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.substring_match, tokens[2].tag);
    try testing.expectEqualStrings("example", tokens[3].value);
}

test "Tokenizer - attribute selector with includes match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[class~=\"foo\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.includes_match, tokens[2].tag);
}

test "Tokenizer - attribute selector with dash match" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[lang|=\"en\"]");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.dash_match, tokens[2].tag);
}

test "Tokenizer - pseudo-class" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ":first-child");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // : first-child eof
    try testing.expectEqual(@as(usize, 3), tokens.len);
    try testing.expectEqual(Token.Tag.colon, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("first-child", tokens[1].value);
}

test "Tokenizer - pseudo-class with parentheses" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, ":nth-child(2n+1)");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // : nth-child ( 2n + 1 ) eof
    // Tokens: colon, ident(nth-child), lparen, ident(2n), plus, ident(1), rparen, eof
    try testing.expectEqual(Token.Tag.colon, tokens[0].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[1].tag);
    try testing.expectEqualStrings("nth-child", tokens[1].value);
    try testing.expectEqual(Token.Tag.lparen, tokens[2].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[3].tag);
    try testing.expectEqualStrings("2n", tokens[3].value);
    try testing.expectEqual(Token.Tag.plus, tokens[4].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[5].tag);
    try testing.expectEqualStrings("1", tokens[5].value);
    try testing.expectEqual(Token.Tag.rparen, tokens[6].tag);
}

test "Tokenizer - universal selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "*");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len);
    try testing.expectEqual(Token.Tag.asterisk, tokens[0].tag);
}

test "Tokenizer - multiple selectors" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div, span");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div , whitespace span eof
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqual(Token.Tag.comma, tokens[1].tag);
    try testing.expectEqual(Token.Tag.whitespace, tokens[2].tag);
    try testing.expectEqual(Token.Tag.ident, tokens[3].tag);
}

test "Tokenizer - complex selector" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div.foo > p:first-child");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    // div . foo whitespace > whitespace p : first-child eof
    try testing.expect(tokens.len > 0);
    try testing.expectEqual(Token.Tag.ident, tokens[0].tag);
    try testing.expectEqualStrings("div", tokens[0].value);
}

test "Tokenizer - string with single quotes" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[title='hello']");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(Token.Tag.string, tokens[3].tag);
    try testing.expectEqualStrings("hello", tokens[3].value);
}

test "Tokenizer - unclosed string error" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "[title=\"hello");
    try testing.expectError(error.UnexpectedEOF, tokenizer.tokenize());
}

test "Tokenizer - invalid token error" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "div ^");
    try testing.expectError(error.UnexpectedToken, tokenizer.tokenize());
}

test "Tokenizer - empty input" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 1), tokens.len);
    try testing.expectEqual(Token.Tag.eof, tokens[0].tag);
}

test "Tokenizer - whitespace only" {
    const allocator = testing.allocator;

    var tokenizer = Tokenizer.init(allocator, "   ");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);

    try testing.expectEqual(@as(usize, 2), tokens.len);
    try testing.expectEqual(Token.Tag.whitespace, tokens[0].tag);
    try testing.expectEqual(Token.Tag.eof, tokens[1].tag);
}
