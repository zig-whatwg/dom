//! CSS Selector Parser (Selectors Level 4)
//!
//! This module implements parsing for CSS Selectors Level 4 syntax as used by
//! WHATWG DOM querySelector/querySelectorAll. The parser converts token streams
//! from the tokenizer into Abstract Syntax Trees (AST) for efficient evaluation.
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
//! - Selector Specificity: https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity
//! - Selector Types: https://developer.mozilla.org/en-US/docs/Learn/CSS/Building_blocks/Selectors
//!
//! ## Core Features
//!
//! ### Parse Token Stream to AST
//! Convert tokenizer output into structured selector AST:
//! ```zig
//! const allocator = std.heap.page_allocator;
//! var tokenizer = Tokenizer.init(allocator, "div.container > p.text");
//! var parser = try Parser.init(allocator, &tokenizer);
//! defer parser.deinit();
//!
//! const selector_list = try parser.parse();
//! // Returns: SelectorList with complex selector chains
//! ```
//!
//! ### Selector AST Structure
//! The AST represents the parsed selector hierarchy:
//! ```
//! SelectorList (top-level, comma-separated)
//!   └─ ComplexSelector (combinator chains)
//!        └─ CompoundSelector (element + classes + attributes)
//!             └─ SimpleSelector (type, class, id, attribute, pseudo)
//! ```
//!
//! ### Supported Selector Types
//! All CSS Selectors Level 4 selector types:
//! ```zig
//! // Type selector
//! "div"                  → SimpleSelector.Type{ .tag_name = "div" }
//!
//! // Class selector
//! ".container"           → SimpleSelector.Class{ .class_name = "container" }
//!
//! // ID selector
//! "#main"                → SimpleSelector.Id{ .id = "main" }
//!
//! // Attribute selector
//! "[href]"               → SimpleSelector.Attribute{ .name = "href", .matcher = .Presence }
//! "[href='#']"           → SimpleSelector.Attribute{ .matcher = .Exact{ .value = "#" } }
//! "[href^='http']"       → SimpleSelector.Attribute{ .matcher = .Prefix{ .value = "http" } }
//!
//! // Pseudo-class
//! ":first-child"         → SimpleSelector.PseudoClass{ .kind = .FirstChild }
//! ":nth-child(2n+1)"     → SimpleSelector.PseudoClass{ .kind = .NthChild{ .a = 2, .b = 1 } }
//!
//! // Universal selector
//! "*"                    → SimpleSelector.Universal
//! ```
//!
//! ### Combinator Support
//! All CSS combinators for expressing relationships:
//! ```zig
//! "div p"        → Descendant combinator (space)
//! "div > p"      → Child combinator (>)
//! "div + p"      → NextSibling combinator (+)
//! "div ~ p"      → SubsequentSibling combinator (~)
//! ```
//!
//! ## Selector AST Types
//!
//! ### SelectorList (Comma-Separated)
//! Top-level structure for multiple selectors:
//! ```zig
//! const SelectorList = struct {
//!     selectors: []ComplexSelector,  // Array of complex selectors
//!     allocator: Allocator,
//!
//!     pub fn deinit(self: *SelectorList) void;
//! };
//!
//! // Example: "div, span, p"
//! // → SelectorList with 3 ComplexSelectors
//! ```
//!
//! ### ComplexSelector (Combinator Chain)
//! A sequence of compound selectors with combinators:
//! ```zig
//! const ComplexSelector = struct {
//!     compound: CompoundSelector,           // First compound selector
//!     combinators: []CombinatorPair,        // Rest of chain with combinators
//!     allocator: Allocator,
//!
//!     pub fn deinit(self: *ComplexSelector) void;
//! };
//!
//! const CombinatorPair = struct {
//!     combinator: Combinator,
//!     compound: CompoundSelector,
//! };
//!
//! // Example: "div > p.text"
//! // → ComplexSelector {
//! //     compound: CompoundSelector for "div",
//! //     combinators: [{ .combinator = .Child, .compound = CompoundSelector for "p.text" }]
//! //   }
//! ```
//!
//! ### CompoundSelector (Element + Qualifiers)
//! A single element with its classes, attributes, and pseudo-classes:
//! ```zig
//! const CompoundSelector = struct {
//!     simple_selectors: []SimpleSelector,   // Type, class, id, attribute, pseudo
//!     allocator: Allocator,
//!
//!     pub fn deinit(self: *CompoundSelector) void;
//! };
//!
//! // Example: "div.container#main[role='navigation']"
//! // → CompoundSelector with 4 SimpleSelectors:
//! //   - Type{ .tag_name = "div" }
//! //   - Class{ .class_name = "container" }
//! //   - Id{ .id = "main" }
//! //   - Attribute{ .name = "role", .matcher = .Exact{ .value = "navigation" } }
//! ```
//!
//! ### SimpleSelector (Atomic Selector)
//! Individual selector component:
//! ```zig
//! const SimpleSelector = union(enum) {
//!     Universal,                            // *
//!     Type: struct { tag_name: []const u8 },
//!     Class: struct { class_name: []const u8 },
//!     Id: struct { id: []const u8 },
//!     Attribute: AttributeSelector,
//!     PseudoClass: PseudoClassSelector,
//!     PseudoElement: PseudoElementSelector,
//! };
//! ```
//!
//! ### Attribute Selector
//! Attribute matching with various operators:
//! ```zig
//! const AttributeSelector = struct {
//!     name: []const u8,
//!     matcher: AttributeMatcher,
//!     case_sensitive: bool = true,  // Default case-sensitive
//! };
//!
//! const AttributeMatcher = union(enum) {
//!     Presence,                      // [attr]
//!     Exact: struct { value: []const u8 },       // [attr="value"]
//!     Prefix: struct { value: []const u8 },      // [attr^="value"]
//!     Suffix: struct { value: []const u8 },      // [attr$="value"]
//!     Substring: struct { value: []const u8 },   // [attr*="value"]
//!     Includes: struct { value: []const u8 },    // [attr~="value"] (whitespace-separated)
//!     DashMatch: struct { value: []const u8 },   // [attr|="value"] (hyphen-separated)
//! };
//! ```
//!
//! ### Pseudo-Class Selector
//! Pseudo-classes with optional arguments:
//! ```zig
//! const PseudoClassSelector = struct {
//!     kind: PseudoClassKind,
//! };
//!
//! const PseudoClassKind = union(enum) {
//!     // Structural pseudo-classes
//!     FirstChild,                    // :first-child
//!     LastChild,                     // :last-child
//!     OnlyChild,                     // :only-child
//!     FirstOfType,                   // :first-of-type
//!     LastOfType,                    // :last-of-type
//!     OnlyOfType,                    // :only-of-type
//!     Empty,                         // :empty
//!     Root,                          // :root
//!
//!     // Nth pseudo-classes
//!     NthChild: NthPattern,          // :nth-child(an+b)
//!     NthLastChild: NthPattern,      // :nth-last-child(an+b)
//!     NthOfType: NthPattern,         // :nth-of-type(an+b)
//!     NthLastOfType: NthPattern,     // :nth-last-of-type(an+b)
//!
//!     // Link pseudo-classes
//!     AnyLink,                       // :any-link
//!     Link,                          // :link
//!     Visited,                       // :visited
//!
//!     // User action pseudo-classes
//!     Hover,                         // :hover
//!     Active,                        // :active
//!     Focus,                         // :focus
//!     FocusVisible,                  // :focus-visible
//!     FocusWithin,                   // :focus-within
//!
//!     // Input pseudo-classes
//!     Enabled,                       // :enabled
//!     Disabled,                      // :disabled
//!     ReadOnly,                      // :read-only
//!     ReadWrite,                     // :read-write
//!     Checked,                       // :checked
//!
//!     // Negation and matching
//!     Not: *SelectorList,            // :not(selector)
//!     Is: *SelectorList,             // :is(selector)
//!     Where: *SelectorList,          // :where(selector)
//!     Has: *SelectorList,            // :has(selector)
//! };
//!
//! const NthPattern = struct {
//!     a: i32,  // Coefficient (e.g., 2 in "2n+1")
//!     b: i32,  // Constant (e.g., 1 in "2n+1")
//! };
//! ```
//!
//! ## Memory Management
//!
//! Parser allocates AST nodes using provided allocator:
//! ```zig
//! const allocator = std.heap.page_allocator;
//! var parser = try Parser.init(allocator, &tokenizer);
//! defer parser.deinit();  // Frees all AST nodes
//!
//! const selector_list = try parser.parse();
//! // selector_list owned by parser, freed by parser.deinit()
//! ```
//!
//! **Lifetime rules:**
//! - Parser owns all AST nodes
//! - AST nodes reference tokens (which reference input string)
//! - Input string must outlive parser
//! - Call `parser.deinit()` to free all AST memory
//!
//! ## Usage Examples
//!
//! ### Simple Selector
//! ```zig
//! const allocator = std.testing.allocator;
//! var tokenizer = Tokenizer.init(allocator, "div");
//! var parser = try Parser.init(allocator, &tokenizer);
//! defer parser.deinit();
//!
//! const selector_list = try parser.parse();
//! try testing.expectEqual(@as(usize, 1), selector_list.selectors.len);
//!
//! const complex = selector_list.selectors[0];
//! try testing.expectEqual(@as(usize, 1), complex.compound.simple_selectors.len);
//!
//! const simple = complex.compound.simple_selectors[0];
//! try testing.expect(simple == .Type);
//! try testing.expectEqualStrings("div", simple.Type.tag_name);
//! ```
//!
//! ### Compound Selector
//! ```zig
//! var tokenizer = Tokenizer.init(allocator, "div.container#main");
//! var parser = try Parser.init(allocator, &tokenizer);
//! defer parser.deinit();
//!
//! const selector_list = try parser.parse();
//! const compound = selector_list.selectors[0].compound;
//!
//! // Should have 3 simple selectors: type, class, id
//! try testing.expectEqual(@as(usize, 3), compound.simple_selectors.len);
//! ```
//!
//! ### Complex Selector with Combinator
//! ```zig
//! var tokenizer = Tokenizer.init(allocator, "div > p");
//! var parser = try Parser.init(allocator, &tokenizer);
//! defer parser.deinit();
//!
//! const selector_list = try parser.parse();
//! const complex = selector_list.selectors[0];
//!
//! // Should have 1 combinator pair
//! try testing.expectEqual(@as(usize, 1), complex.combinators.len);
//! try testing.expectEqual(Combinator.Child, complex.combinators[0].combinator);
//! ```
//!
//! ### Multiple Selectors
//! ```zig
//! var tokenizer = Tokenizer.init(allocator, "div, span, p");
//! var parser = try Parser.init(allocator, &tokenizer);
//! defer parser.deinit();
//!
//! const selector_list = try parser.parse();
//! try testing.expectEqual(@as(usize, 3), selector_list.selectors.len);
//! ```
//!
//! ### Attribute Selector
//! ```zig
//! var tokenizer = Tokenizer.init(allocator, "[href^='https']");
//! var parser = try Parser.init(allocator, &tokenizer);
//! defer parser.deinit();
//!
//! const selector_list = try parser.parse();
//! const simple = selector_list.selectors[0].compound.simple_selectors[0];
//!
//! try testing.expect(simple == .Attribute);
//! try testing.expectEqualStrings("href", simple.Attribute.name);
//! try testing.expect(simple.Attribute.matcher == .Prefix);
//! try testing.expectEqualStrings("https", simple.Attribute.matcher.Prefix.value);
//! ```
//!
//! ## Parser Architecture
//!
//! ### Recursive Descent Parser
//! Implements grammar rules as recursive functions:
//! ```
//! selector_list      := complex_selector (',' complex_selector)*
//! complex_selector   := compound_selector (combinator compound_selector)*
//! compound_selector  := simple_selector+
//! simple_selector    := type | class | id | attribute | pseudo
//! ```
//!
//! ### Parse Functions
//! Each grammar rule has a corresponding parse function:
//! - `parseSelectorList()` → Top-level entry point
//! - `parseComplexSelector()` → Parse combinator chains
//! - `parseCompoundSelector()` → Parse element + qualifiers
//! - `parseSimpleSelector()` → Parse atomic selectors
//! - `parseAttribute()` → Parse attribute selectors
//! - `parsePseudoClass()` → Parse pseudo-class selectors
//!
//! ## Performance Considerations
//!
//! 1. **AST Allocation** - All nodes allocated upfront, freed together
//! 2. **String Slices** - AST nodes reference tokenizer strings (zero-copy)
//! 3. **Single Pass** - Parser makes one pass through tokens
//! 4. **Error Recovery** - Parser fails fast on invalid syntax
//! 5. **Minimal Copying** - Strings not duplicated (lifetime tied to input)
//!
//! ## Error Handling
//!
//! Parser returns errors for invalid syntax:
//! ```zig
//! const ParserError = error{
//!     UnexpectedToken,       // Unexpected token in this context
//!     UnexpectedEOF,         // Unexpected end of input
//!     InvalidSelector,       // Malformed selector syntax
//!     OutOfMemory,           // Allocation failure
//! };
//! ```
//!
//! ## Implementation Notes
//!
//! - Implements CSS Selectors Level 4 grammar
//! - Recursive descent parser (LL parser)
//! - Single-pass token consumption
//! - AST nodes allocated from parser's allocator
//! - String slices reference original input (zero-copy)
//! - Whitespace tokens used to detect descendant combinator
//! - Parser owns all AST memory (freed by deinit)
//! - Compatible with matcher implementation
//! - Supports full selector syntax (type, class, id, attribute, pseudo, combinators)

const std = @import("std");
const Allocator = std.mem.Allocator;
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Token = @import("tokenizer.zig").Token;
const ArrayList = std.ArrayList;

// ============================================================================
// AST Node Types
// ============================================================================

/// Top-level selector list (comma-separated selectors)
pub const SelectorList = struct {
    selectors: []ComplexSelector,
    allocator: Allocator,

    pub fn deinit(self: *SelectorList) void {
        for (self.selectors) |*selector| {
            selector.deinit();
        }
        self.allocator.free(self.selectors);
    }
};

/// Complex selector (combinator chain)
pub const ComplexSelector = struct {
    compound: CompoundSelector,
    combinators: []CombinatorPair,
    allocator: Allocator,

    pub fn deinit(self: *ComplexSelector) void {
        self.compound.deinit();
        for (self.combinators) |*pair| {
            pair.compound.deinit();
        }
        self.allocator.free(self.combinators);
    }
};

/// Combinator with associated compound selector
pub const CombinatorPair = struct {
    combinator: Combinator,
    compound: CompoundSelector,
};

/// Combinator types
pub const Combinator = enum {
    Descendant, // space (whitespace)
    Child, // >
    NextSibling, // +
    SubsequentSibling, // ~
};

/// Compound selector (multiple simple selectors for same element)
pub const CompoundSelector = struct {
    simple_selectors: []SimpleSelector,
    allocator: Allocator,

    pub fn deinit(self: *CompoundSelector) void {
        for (self.simple_selectors) |*selector| {
            selector.deinit(self.allocator);
        }
        self.allocator.free(self.simple_selectors);
    }
};

/// Simple selector (atomic selector)
pub const SimpleSelector = union(enum) {
    Universal,
    Type: struct { tag_name: []const u8 },
    Class: struct { class_name: []const u8 },
    Id: struct { id: []const u8 },
    Attribute: AttributeSelector,
    PseudoClass: PseudoClassSelector,
    PseudoElement: PseudoElementSelector,

    pub fn deinit(self: *SimpleSelector, allocator: Allocator) void {
        switch (self.*) {
            .PseudoClass => |*pseudo| pseudo.deinit(allocator),
            .PseudoElement => |*pseudo| pseudo.deinit(allocator),
            else => {},
        }
    }
};

/// Attribute selector
pub const AttributeSelector = struct {
    name: []const u8,
    matcher: AttributeMatcher,
    case_sensitive: bool = true,
};

/// Attribute matching operators
pub const AttributeMatcher = union(enum) {
    Presence, // [attr]
    Exact: struct { value: []const u8 }, // [attr="value"]
    Prefix: struct { value: []const u8 }, // [attr^="value"]
    Suffix: struct { value: []const u8 }, // [attr$="value"]
    Substring: struct { value: []const u8 }, // [attr*="value"]
    Includes: struct { value: []const u8 }, // [attr~="value"]
    DashMatch: struct { value: []const u8 }, // [attr|="value"]
};

/// Pseudo-class selector
pub const PseudoClassSelector = struct {
    kind: PseudoClassKind,

    pub fn deinit(self: *PseudoClassSelector, allocator: Allocator) void {
        switch (self.kind) {
            .Not, .Is, .Where, .Has => |selector_list_ptr| {
                selector_list_ptr.deinit();
                allocator.destroy(selector_list_ptr);
            },
            else => {},
        }
    }
};

/// Pseudo-class types
pub const PseudoClassKind = union(enum) {
    // Structural pseudo-classes
    FirstChild,
    LastChild,
    OnlyChild,
    FirstOfType,
    LastOfType,
    OnlyOfType,
    Empty,
    Root,

    // Nth pseudo-classes
    NthChild: NthPattern,
    NthLastChild: NthPattern,
    NthOfType: NthPattern,
    NthLastOfType: NthPattern,

    // Link pseudo-classes
    AnyLink,
    Link,
    Visited,

    // User action pseudo-classes
    Hover,
    Active,
    Focus,
    FocusVisible,
    FocusWithin,

    // Input pseudo-classes
    Enabled,
    Disabled,
    ReadOnly,
    ReadWrite,
    Checked,

    // Negation and matching
    Not: *SelectorList,
    Is: *SelectorList,
    Where: *SelectorList,
    Has: *SelectorList,
};

/// Nth pattern (an+b)
pub const NthPattern = struct {
    a: i32, // Coefficient
    b: i32, // Constant
};

/// Pseudo-element selector
pub const PseudoElementSelector = struct {
    name: []const u8,

    pub fn deinit(_: *PseudoElementSelector, _: Allocator) void {
        // No dynamic allocation, nothing to free
    }
};

// ============================================================================
// Parser Errors
// ============================================================================

pub const ParserError = error{
    UnexpectedToken,
    UnexpectedEOF,
    InvalidSelector,
    OutOfMemory,
};

// ============================================================================
// Parser
// ============================================================================

pub const Parser = struct {
    allocator: Allocator,
    tokenizer: *Tokenizer,
    current_token: ?Token = null,
    peeked_token: ?Token = null,

    pub fn init(allocator: Allocator, tokenizer: *Tokenizer) !Parser {
        var parser = Parser{
            .allocator = allocator,
            .tokenizer = tokenizer,
        };
        // Prime the parser with first token
        try parser.advance();
        return parser;
    }

    pub fn deinit(self: *Parser) void {
        _ = self;
        // Parser doesn't own AST nodes after parse() returns
        // Caller responsible for calling SelectorList.deinit()
    }

    /// Parse complete selector list
    pub fn parse(self: *Parser) ParserError!SelectorList {
        return try self.parseSelectorList();
    }

    // ========================================================================
    // Grammar Rules
    // ========================================================================

    /// Parse selector list (comma-separated complex selectors)
    fn parseSelectorList(self: *Parser) ParserError!SelectorList {
        var selectors = ArrayList(ComplexSelector){};
        errdefer {
            for (selectors.items) |*selector| {
                selector.deinit();
            }
            selectors.deinit(self.allocator);
        }

        // Parse first complex selector
        try selectors.append(self.allocator, try self.parseComplexSelector());

        // Parse additional selectors (comma-separated)
        while (self.current_token) |token| {
            if (token.tag == .comma) {
                try self.advance();
                self.skipWhitespace();
                try selectors.append(self.allocator, try self.parseComplexSelector());
            } else {
                break;
            }
        }

        return SelectorList{
            .selectors = try selectors.toOwnedSlice(self.allocator),
            .allocator = self.allocator,
        };
    }

    /// Parse complex selector (combinator chain)
    fn parseComplexSelector(self: *Parser) ParserError!ComplexSelector {
        var combinators = ArrayList(CombinatorPair){};
        errdefer {
            for (combinators.items) |*pair| {
                pair.compound.deinit();
            }
            combinators.deinit(self.allocator);
        }

        // Parse first compound selector
        const first_compound = try self.parseCompoundSelector();

        // Parse combinator chain
        while (true) {
            // Check for combinator
            const combinator = try self.parseCombinator();
            if (combinator == null) break;

            self.skipWhitespace();

            // Parse next compound selector
            const next_compound = try self.parseCompoundSelector();

            try combinators.append(self.allocator, CombinatorPair{
                .combinator = combinator.?,
                .compound = next_compound,
            });
        }

        return ComplexSelector{
            .compound = first_compound,
            .combinators = try combinators.toOwnedSlice(self.allocator),
            .allocator = self.allocator,
        };
    }

    /// Parse combinator (>, +, ~, or whitespace)
    fn parseCombinator(self: *Parser) ParserError!?Combinator {
        const token = self.current_token orelse return null;

        return switch (token.tag) {
            .gt => blk: {
                try self.advance();
                break :blk Combinator.Child;
            },
            .plus => blk: {
                try self.advance();
                break :blk Combinator.NextSibling;
            },
            .tilde => blk: {
                try self.advance();
                break :blk Combinator.SubsequentSibling;
            },
            .whitespace => blk: {
                try self.advance();
                // Peek ahead - if next token is combinator, this whitespace is just spacing
                if (self.current_token) |next_token| {
                    if (next_token.tag == .gt or next_token.tag == .plus or next_token.tag == .tilde) {
                        return try self.parseCombinator();
                    }
                }
                // Whitespace followed by compound selector = descendant combinator
                if (self.isCompoundStart()) {
                    break :blk Combinator.Descendant;
                }
                // Whitespace at end of selector
                return null;
            },
            else => null,
        };
    }

    /// Parse compound selector (one or more simple selectors)
    fn parseCompoundSelector(self: *Parser) ParserError!CompoundSelector {
        var simple_selectors = ArrayList(SimpleSelector){};
        errdefer {
            for (simple_selectors.items) |*selector| {
                selector.deinit(self.allocator);
            }
            simple_selectors.deinit(self.allocator);
        }

        // Parse first simple selector
        try simple_selectors.append(self.allocator, try self.parseSimpleSelector());

        // Parse additional simple selectors (no whitespace between)
        while (self.isSimpleSelectorStart()) {
            try simple_selectors.append(self.allocator, try self.parseSimpleSelector());
        }

        if (simple_selectors.items.len == 0) {
            return error.InvalidSelector;
        }

        return CompoundSelector{
            .simple_selectors = try simple_selectors.toOwnedSlice(self.allocator),
            .allocator = self.allocator,
        };
    }

    /// Parse simple selector
    fn parseSimpleSelector(self: *Parser) ParserError!SimpleSelector {
        const token = self.current_token orelse return error.UnexpectedEOF;

        return switch (token.tag) {
            .asterisk => blk: {
                try self.advance();
                break :blk SimpleSelector.Universal;
            },
            .ident => blk: {
                const tag_name = token.value;
                try self.advance();
                break :blk SimpleSelector{ .Type = .{ .tag_name = tag_name } };
            },
            .dot => blk: {
                try self.advance();
                const class_token = self.current_token orelse return error.UnexpectedEOF;
                if (class_token.tag != .ident) return error.InvalidSelector;
                const class_name = class_token.value;
                try self.advance();
                break :blk SimpleSelector{ .Class = .{ .class_name = class_name } };
            },
            .hash => blk: {
                const id = token.value;
                try self.advance();
                break :blk SimpleSelector{ .Id = .{ .id = id } };
            },
            .lbracket => blk: {
                break :blk SimpleSelector{ .Attribute = try self.parseAttribute() };
            },
            .colon => blk: {
                try self.advance();
                // Check for pseudo-element (::)
                if (self.current_token) |next_token| {
                    if (next_token.tag == .colon) {
                        try self.advance();
                        return try self.parsePseudoElement();
                    }
                }
                break :blk SimpleSelector{ .PseudoClass = try self.parsePseudoClass() };
            },
            else => error.InvalidSelector,
        };
    }

    /// Parse attribute selector
    fn parseAttribute(self: *Parser) ParserError!AttributeSelector {
        // Consume '['
        try self.expectToken(.lbracket);
        try self.advance();

        // Parse attribute name
        const name_token = self.current_token orelse return error.UnexpectedEOF;
        if (name_token.tag != .ident) return error.InvalidSelector;
        const name = name_token.value;
        try self.advance();

        // Check for matcher operator
        const token = self.current_token orelse return error.UnexpectedEOF;

        var matcher: AttributeMatcher = undefined;

        switch (token.tag) {
            .rbracket => {
                // [attr] - presence only
                matcher = AttributeMatcher.Presence;
            },
            .equals => {
                try self.advance();
                const value = try self.parseAttributeValue();
                matcher = AttributeMatcher{ .Exact = .{ .value = value } };
            },
            .prefix_match => {
                try self.advance();
                const value = try self.parseAttributeValue();
                matcher = AttributeMatcher{ .Prefix = .{ .value = value } };
            },
            .suffix_match => {
                try self.advance();
                const value = try self.parseAttributeValue();
                matcher = AttributeMatcher{ .Suffix = .{ .value = value } };
            },
            .substring_match => {
                try self.advance();
                const value = try self.parseAttributeValue();
                matcher = AttributeMatcher{ .Substring = .{ .value = value } };
            },
            .includes_match => {
                try self.advance();
                const value = try self.parseAttributeValue();
                matcher = AttributeMatcher{ .Includes = .{ .value = value } };
            },
            .dash_match => {
                try self.advance();
                const value = try self.parseAttributeValue();
                matcher = AttributeMatcher{ .DashMatch = .{ .value = value } };
            },
            else => return error.InvalidSelector,
        }

        // Consume ']'
        try self.expectToken(.rbracket);
        try self.advance();

        return AttributeSelector{
            .name = name,
            .matcher = matcher,
        };
    }

    /// Parse attribute value (string or identifier)
    fn parseAttributeValue(self: *Parser) ParserError![]const u8 {
        const token = self.current_token orelse return error.UnexpectedEOF;
        const value = switch (token.tag) {
            .string, .ident => token.value,
            else => return error.InvalidSelector,
        };
        try self.advance();
        return value;
    }

    /// Parse pseudo-class selector
    fn parsePseudoClass(self: *Parser) ParserError!PseudoClassSelector {
        const name_token = self.current_token orelse return error.UnexpectedEOF;
        if (name_token.tag != .ident) return error.InvalidSelector;
        const name = name_token.value;
        try self.advance();

        // Check for function pseudo-class (with parentheses)
        if (self.current_token) |token| {
            if (token.tag == .lparen) {
                return try self.parseFunctionalPseudoClass(name);
            }
        }

        // Simple pseudo-class (no arguments)
        const kind = try self.parsePseudoClassName(name);
        return PseudoClassSelector{ .kind = kind };
    }

    /// Parse pseudo-class name without arguments
    fn parsePseudoClassName(_: *Parser, name: []const u8) ParserError!PseudoClassKind {
        if (std.mem.eql(u8, name, "first-child")) return .FirstChild;
        if (std.mem.eql(u8, name, "last-child")) return .LastChild;
        if (std.mem.eql(u8, name, "only-child")) return .OnlyChild;
        if (std.mem.eql(u8, name, "first-of-type")) return .FirstOfType;
        if (std.mem.eql(u8, name, "last-of-type")) return .LastOfType;
        if (std.mem.eql(u8, name, "only-of-type")) return .OnlyOfType;
        if (std.mem.eql(u8, name, "empty")) return .Empty;
        if (std.mem.eql(u8, name, "root")) return .Root;
        if (std.mem.eql(u8, name, "any-link")) return .AnyLink;
        if (std.mem.eql(u8, name, "link")) return .Link;
        if (std.mem.eql(u8, name, "visited")) return .Visited;
        if (std.mem.eql(u8, name, "hover")) return .Hover;
        if (std.mem.eql(u8, name, "active")) return .Active;
        if (std.mem.eql(u8, name, "focus")) return .Focus;
        if (std.mem.eql(u8, name, "focus-visible")) return .FocusVisible;
        if (std.mem.eql(u8, name, "focus-within")) return .FocusWithin;
        if (std.mem.eql(u8, name, "enabled")) return .Enabled;
        if (std.mem.eql(u8, name, "disabled")) return .Disabled;
        if (std.mem.eql(u8, name, "read-only")) return .ReadOnly;
        if (std.mem.eql(u8, name, "read-write")) return .ReadWrite;
        if (std.mem.eql(u8, name, "checked")) return .Checked;

        return error.InvalidSelector;
    }

    /// Parse functional pseudo-class (with arguments)
    fn parseFunctionalPseudoClass(self: *Parser, name: []const u8) ParserError!PseudoClassSelector {
        // Consume '('
        try self.expectToken(.lparen);
        try self.advance();
        self.skipWhitespace();

        var kind: PseudoClassKind = undefined;

        // Check pseudo-class type
        if (std.mem.eql(u8, name, "nth-child")) {
            const pattern = try self.parseNthPattern();
            kind = PseudoClassKind{ .NthChild = pattern };
        } else if (std.mem.eql(u8, name, "nth-last-child")) {
            const pattern = try self.parseNthPattern();
            kind = PseudoClassKind{ .NthLastChild = pattern };
        } else if (std.mem.eql(u8, name, "nth-of-type")) {
            const pattern = try self.parseNthPattern();
            kind = PseudoClassKind{ .NthOfType = pattern };
        } else if (std.mem.eql(u8, name, "nth-last-of-type")) {
            const pattern = try self.parseNthPattern();
            kind = PseudoClassKind{ .NthLastOfType = pattern };
        } else if (std.mem.eql(u8, name, "not")) {
            const selector_list = try self.allocator.create(SelectorList);
            selector_list.* = try self.parseSelectorList();
            kind = PseudoClassKind{ .Not = selector_list };
        } else if (std.mem.eql(u8, name, "is")) {
            const selector_list = try self.allocator.create(SelectorList);
            selector_list.* = try self.parseSelectorList();
            kind = PseudoClassKind{ .Is = selector_list };
        } else if (std.mem.eql(u8, name, "where")) {
            const selector_list = try self.allocator.create(SelectorList);
            selector_list.* = try self.parseSelectorList();
            kind = PseudoClassKind{ .Where = selector_list };
        } else if (std.mem.eql(u8, name, "has")) {
            const selector_list = try self.allocator.create(SelectorList);
            selector_list.* = try self.parseSelectorList();
            kind = PseudoClassKind{ .Has = selector_list };
        } else {
            return error.InvalidSelector;
        }

        self.skipWhitespace();

        // Consume ')'
        try self.expectToken(.rparen);
        try self.advance();

        return PseudoClassSelector{ .kind = kind };
    }

    /// Parse nth pattern (an+b)
    fn parseNthPattern(self: *Parser) ParserError!NthPattern {
        // Handle special keywords
        const token = self.current_token orelse return error.UnexpectedEOF;
        if (token.tag == .ident) {
            if (std.mem.eql(u8, token.value, "odd")) {
                try self.advance();
                return NthPattern{ .a = 2, .b = 1 };
            }
            if (std.mem.eql(u8, token.value, "even")) {
                try self.advance();
                return NthPattern{ .a = 2, .b = 0 };
            }
        }

        // Parse an+b pattern
        // Simplified parser - handles common cases
        // Full implementation would need more complex parsing

        var a: i32 = 0;
        var b: i32 = 0;

        // Try to parse coefficient (a)
        if (token.tag == .ident) {
            // Could be "n", "2n", "-n", etc.
            const value = token.value;
            if (std.mem.endsWith(u8, value, "n")) {
                const coeff_str = value[0 .. value.len - 1];
                if (coeff_str.len == 0) {
                    a = 1;
                } else if (std.mem.eql(u8, coeff_str, "-")) {
                    a = -1;
                } else if (std.mem.eql(u8, coeff_str, "+")) {
                    a = 1;
                } else {
                    a = std.fmt.parseInt(i32, coeff_str, 10) catch return error.InvalidSelector;
                }
                try self.advance();
                self.skipWhitespace();

                // Check for +b or -b
                if (self.current_token) |next_token| {
                    if (next_token.tag == .plus) {
                        try self.advance();
                        self.skipWhitespace();
                        const b_token = self.current_token orelse return error.UnexpectedEOF;
                        b = std.fmt.parseInt(i32, b_token.value, 10) catch return error.InvalidSelector;
                        try self.advance();
                    } else if (next_token.tag == .ident and next_token.value[0] == '-') {
                        b = std.fmt.parseInt(i32, next_token.value, 10) catch return error.InvalidSelector;
                        try self.advance();
                    }
                }
            } else {
                // Just a number (b only)
                b = std.fmt.parseInt(i32, value, 10) catch return error.InvalidSelector;
                try self.advance();
            }
        } else {
            return error.InvalidSelector;
        }

        return NthPattern{ .a = a, .b = b };
    }

    /// Parse pseudo-element selector
    fn parsePseudoElement(self: *Parser) ParserError!SimpleSelector {
        const name_token = self.current_token orelse return error.UnexpectedEOF;
        if (name_token.tag != .ident) return error.InvalidSelector;
        const name = name_token.value;
        try self.advance();

        return SimpleSelector{ .PseudoElement = .{ .name = name } };
    }

    // ========================================================================
    // Utilities
    // ========================================================================

    /// Check if current position is start of compound selector
    fn isCompoundStart(self: *const Parser) bool {
        const token = self.current_token orelse return false;
        return switch (token.tag) {
            .ident, .dot, .hash, .lbracket, .colon, .asterisk => true,
            else => false,
        };
    }

    /// Check if current position is start of simple selector
    fn isSimpleSelectorStart(self: *const Parser) bool {
        const token = self.current_token orelse return false;
        return switch (token.tag) {
            .dot, .hash, .lbracket, .colon => true,
            else => false,
        };
    }

    /// Advance to next token
    fn advance(self: *Parser) ParserError!void {
        self.current_token = self.tokenizer.nextToken() catch |err| {
            return switch (err) {
                error.UnexpectedToken => error.UnexpectedToken,
                error.UnexpectedEOF => error.UnexpectedEOF,
            };
        };
    }

    /// Skip whitespace tokens
    fn skipWhitespace(self: *Parser) void {
        while (self.current_token) |token| {
            if (token.tag != .whitespace) break;
            self.advance() catch break;
        }
    }

    /// Expect specific token type
    fn expectToken(self: *const Parser, expected: Token.Tag) ParserError!void {
        const token = self.current_token orelse return error.UnexpectedEOF;
        if (token.tag != expected) return error.UnexpectedToken;
    }
};

// ============================================================================
// Tests
// ============================================================================

const testing = std.testing;












