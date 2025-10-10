//! CSS Selector Parsing and Matching (§1.3)
//!
//! This module implements CSS selector parsing and element matching as specified
//! by the WHATWG DOM Standard and CSS Selectors Level 4.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§1.3 Selectors**: https://dom.spec.whatwg.org/#selectors
//! - **CSS Selectors 4**: https://drafts.csswg.org/selectors-4/
//!
//! ## MDN Documentation
//!
//! - CSS Selectors: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Selectors
//! - querySelector(): https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector
//! - querySelectorAll(): https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelectorAll
//!
//! ## Supported Selectors
//!
//! This implementation currently supports the following selector types:
//!
//! ### Type Selector
//! Matches elements by tag name (case-insensitive):
//! ```zig
//! const element = try querySelector(root, "div", allocator);
//! ```
//!
//! ### ID Selector
//! Matches elements by ID attribute:
//! ```zig
//! const element = try querySelector(root, "#myid", allocator);
//! ```
//!
//! ### Class Selector
//! Matches elements by class name:
//! ```zig
//! const elements = try querySelectorAll(root, ".myclass", list, allocator);
//! ```
//!
//! ### Attribute Selector
//! Matches elements by attribute presence or value:
//! ```zig
//! // Has attribute
//! const element = try querySelector(root, "[disabled]", allocator);
//!
//! // Attribute equals value
//! const element = try querySelector(root, "[type=\"text\"]", allocator);
//! ```
//!
//! ### Universal Selector
//! Matches all elements:
//! ```zig
//! const all = try querySelectorAll(root, "*", list, allocator);
//! ```
//!
//! ### Combined Selectors
//! Multiple selectors can be combined (logical AND):
//! ```zig
//! // <div class="foo" id="bar">
//! const element = try querySelector(root, "div.foo#bar", allocator);
//! ```
//!
//! ## Usage Example
//!
//! ```zig
//! const std = @import("std");
//! const selector = @import("selector.zig");
//! const Element = @import("element.zig").Element;
//! const NodeList = @import("node_list.zig").NodeList;
//!
//! // Create document structure
//! const root = try Element.create(allocator, "div");
//! defer root.release();
//!
//! const child = try Element.create(allocator, "p");
//! try Element.setAttribute(child, "id", "intro");
//! try Element.setClassName(child, "highlight important");
//! _ = try root.appendChild(child);
//!
//! // Find by ID
//! if (try selector.querySelector(root, "#intro", allocator)) |found| {
//!     // found === child
//! }
//!
//! // Find by class
//! if (try selector.querySelector(root, ".highlight", allocator)) |found| {
//!     // found === child
//! }
//!
//! // Find by combined selector
//! const match = try selector.matches(child, "p.highlight#intro", allocator);
//! // match === true
//!
//! // Find all matching elements
//! var list = NodeList.init(allocator);
//! defer list.deinit();
//! try selector.querySelectorAll(root, ".important", &list, allocator);
//! // list.length() === 1
//! ```
//!
//! ## Performance Considerations
//!
//! - Selector parsing allocates memory for the selector list
//! - Case-insensitive tag matching allocates temporary lowercase strings
//! - querySelector stops at first match (efficient for single elements)
//! - querySelectorAll traverses entire subtree (use specific selectors)
//!
//! ## Error Handling
//!
//! - `error.InvalidSelector`: Malformed selector (e.g., unclosed `[`)
//! - `error.OutOfMemory`: Memory allocation failed
//!
//! ## Limitations
//!
//! Current implementation does not support:
//! - Combinators (descendant, child `>`, sibling `+`, `~`)
//! - Pseudo-classes (`:hover`, `:first-child`, etc.)
//! - Pseudo-elements (`::before`, `::after`)
//! - Attribute operators (`^=`, `$=`, `*=`, `|=`, `~=`)
//! - Multiple selector lists (`,`)
//! - Namespace selectors
//!
//! These features may be added in future versions.

const std = @import("std");
const Node = @import("node.zig").Node;
const Element = @import("element.zig").Element;

/// Selector Type Classification
///
/// Represents the different types of CSS selectors that can be parsed.
/// Each type has different matching semantics.
///
/// See: https://drafts.csswg.org/selectors-4/#selector-syntax
pub const SelectorType = enum {
    /// Type selector: matches element tag name
    /// Example: `div`, `span`, `p`
    tag,

    /// ID selector: matches element with specific id attribute
    /// Example: `#myid`
    id,

    /// Class selector: matches element with specific class
    /// Example: `.myclass`
    class_name,

    /// Attribute selector: matches element with attribute
    /// Example: `[disabled]`, `[type="text"]`
    attribute,

    /// Universal selector: matches all elements
    /// Example: `*`
    universal,
};

/// Selector
///
/// Represents a single parsed CSS selector component.
/// Complex selectors are represented as arrays of Selector structs.
///
/// ## Fields
///
/// - `selector_type`: The type of selector (tag, id, class, etc.)
/// - `value`: The selector value (tag name, id, class name, etc.)
///
/// ## Example
///
/// ```zig
/// // Parse "div.foo#bar" into selectors
/// const selectors = try Selector.parse(allocator, "div.foo#bar");
/// defer allocator.free(selectors);
/// // selectors[0] = { .tag, "div" }
/// // selectors[1] = { .class_name, "foo" }
/// // selectors[2] = { .id, "bar" }
/// ```
pub const Selector = struct {
    selector_type: SelectorType,
    value: []const u8,

    /// Parse CSS Selector String
    ///
    /// Parses a CSS selector string into an array of Selector components.
    /// Memory for the array must be freed by the caller.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the selector array
    /// - `selector`: CSS selector string to parse
    ///
    /// ## Returns
    ///
    /// Array of parsed Selector components. Caller must free with `allocator.free()`.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    /// - `error.InvalidSelector`: Malformed selector syntax
    ///
    /// ## Examples
    ///
    /// ```zig
    /// // Parse tag selector
    /// const selectors = try Selector.parse(allocator, "div");
    /// defer allocator.free(selectors);
    /// // selectors = [{ .tag, "div" }]
    ///
    /// // Parse ID selector
    /// const selectors = try Selector.parse(allocator, "#myid");
    /// defer allocator.free(selectors);
    /// // selectors = [{ .id, "myid" }]
    ///
    /// // Parse class selector
    /// const selectors = try Selector.parse(allocator, ".myclass");
    /// defer allocator.free(selectors);
    /// // selectors = [{ .class_name, "myclass" }]
    ///
    /// // Parse combined selector
    /// const selectors = try Selector.parse(allocator, "div.foo#bar");
    /// defer allocator.free(selectors);
    /// // selectors = [{ .tag, "div" }, { .class_name, "foo" }, { .id, "bar" }]
    ///
    /// // Parse attribute selector
    /// const selectors = try Selector.parse(allocator, "[disabled]");
    /// defer allocator.free(selectors);
    /// // selectors = [{ .attribute, "disabled" }]
    ///
    /// // Parse attribute with value
    /// const selectors = try Selector.parse(allocator, "[type=\"text\"]");
    /// defer allocator.free(selectors);
    /// // selectors = [{ .attribute, "type=\"text\"" }]
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#scope-match-a-selectors-string
    pub fn parse(allocator: std.mem.Allocator, selector: []const u8) ![]Selector {
        var selectors = std.ArrayList(Selector){};
        errdefer selectors.deinit(allocator);

        var i: usize = 0;
        while (i < selector.len) {
            const c = selector[i];

            if (c == '#') {
                // ID selector: #myid
                i += 1;
                const start = i;
                while (i < selector.len and !isDelimiter(selector[i])) : (i += 1) {}
                try selectors.append(allocator, .{
                    .selector_type = .id,
                    .value = selector[start..i],
                });
            } else if (c == '.') {
                // Class selector: .myclass
                i += 1;
                const start = i;
                while (i < selector.len and !isDelimiter(selector[i])) : (i += 1) {}
                try selectors.append(allocator, .{
                    .selector_type = .class_name,
                    .value = selector[start..i],
                });
            } else if (c == '[') {
                // Attribute selector: [name] or [name="value"]
                i += 1;
                const start = i;
                while (i < selector.len and selector[i] != ']') : (i += 1) {}
                if (i >= selector.len) return error.InvalidSelector;
                try selectors.append(allocator, .{
                    .selector_type = .attribute,
                    .value = selector[start..i],
                });
                i += 1;
            } else if (c == '*') {
                // Universal selector: *
                try selectors.append(allocator, .{
                    .selector_type = .universal,
                    .value = "",
                });
                i += 1;
            } else if (std.ascii.isWhitespace(c)) {
                // Skip whitespace
                i += 1;
            } else if (std.ascii.isAlphabetic(c) or c == '-' or c == '_') {
                // Tag selector: div, span, my-element, etc.
                const start = i;
                while (i < selector.len and !isDelimiter(selector[i])) : (i += 1) {}
                try selectors.append(allocator, .{
                    .selector_type = .tag,
                    .value = selector[start..i],
                });
            } else {
                // Unknown character, skip
                i += 1;
            }
        }

        return selectors.toOwnedSlice(allocator);
    }

    /// Check if character is a selector delimiter
    ///
    /// Delimiter characters separate different selector components.
    ///
    /// ## Delimiters
    ///
    /// - `#`: ID selector prefix
    /// - `.`: Class selector prefix
    /// - `[`: Attribute selector start
    /// - ` `: Descendant combinator (not yet supported)
    /// - `>`: Child combinator (not yet supported)
    /// - `+`: Adjacent sibling combinator (not yet supported)
    /// - `~`: General sibling combinator (not yet supported)
    fn isDelimiter(c: u8) bool {
        return c == '#' or c == '.' or c == '[' or c == ' ' or c == '>' or c == '+' or c == '~';
    }
};

/// Match Element Against Selector
///
/// Tests whether a node matches a given CSS selector string.
/// All selector components must match for the function to return true.
///
/// ## Parameters
///
/// - `node`: Node to test (must be an element node)
/// - `selector`: CSS selector string
/// - `allocator`: Memory allocator for temporary allocations
///
/// ## Returns
///
/// `true` if the node matches all selector components, `false` otherwise.
/// Non-element nodes always return `false`.
///
/// ## Errors
///
/// - `error.OutOfMemory`: Memory allocation failed
/// - `error.InvalidSelector`: Malformed selector syntax
///
/// ## Examples
///
/// ```zig
/// // Create element
/// const element = try Element.create(allocator, "div");
/// defer element.release();
/// try Element.setAttribute(element, "id", "main");
/// try Element.setClassName(element, "container active");
///
/// // Test tag selector
/// try std.testing.expect(try matches(element, "div", allocator));
/// try std.testing.expect(!try matches(element, "span", allocator));
///
/// // Test ID selector
/// try std.testing.expect(try matches(element, "#main", allocator));
/// try std.testing.expect(!try matches(element, "#other", allocator));
///
/// // Test class selector
/// try std.testing.expect(try matches(element, ".container", allocator));
/// try std.testing.expect(try matches(element, ".active", allocator));
/// try std.testing.expect(!try matches(element, ".inactive", allocator));
///
/// // Test combined selectors (all must match)
/// try std.testing.expect(try matches(element, "div.container#main", allocator));
/// try std.testing.expect(!try matches(element, "div.container#other", allocator));
/// try std.testing.expect(!try matches(element, "span.container#main", allocator));
/// ```
///
/// ## Case Sensitivity
///
/// - Tag names are case-insensitive (HTML)
/// - IDs are case-sensitive
/// - Class names are case-sensitive
/// - Attribute names are case-sensitive
///
/// See: https://dom.spec.whatwg.org/#scope-match-a-selectors-string
pub fn matches(node: *const Node, selector: []const u8, allocator: std.mem.Allocator) !bool {
    // Only element nodes can match selectors
    if (node.node_type != .element_node) return false;

    const selectors = try Selector.parse(allocator, selector);
    defer allocator.free(selectors);

    // All selector components must match (logical AND)
    for (selectors) |sel| {
        const match = switch (sel.selector_type) {
            .tag => blk: {
                // Tag matching is case-insensitive in HTML
                const data = Element.getData(node);
                const tag_lower = try std.ascii.allocLowerString(allocator, data.tag_name);
                defer allocator.free(tag_lower);
                const sel_lower = try std.ascii.allocLowerString(allocator, sel.value);
                defer allocator.free(sel_lower);
                break :blk std.mem.eql(u8, tag_lower, sel_lower);
            },
            .id => blk: {
                // ID matching is case-sensitive
                if (Element.getAttribute(node, "id")) |id| {
                    break :blk std.mem.eql(u8, id, sel.value);
                }
                break :blk false;
            },
            .class_name => blk: {
                // Class matching is case-sensitive
                const data = Element.getData(node);
                break :blk data.class_list.contains(sel.value);
            },
            .attribute => blk: {
                // Parse attribute selector: [name] or [name="value"]
                var iter = std.mem.splitScalar(u8, sel.value, '=');
                const attr_name = iter.next() orelse break :blk false;

                if (iter.next()) |expected_value| {
                    // Attribute value matching: [name="value"]
                    var clean_value = expected_value;
                    // Remove quotes if present
                    if (clean_value.len > 0 and (clean_value[0] == '"' or clean_value[0] == '\'')) {
                        clean_value = clean_value[1..];
                    }
                    if (clean_value.len > 0 and (clean_value[clean_value.len - 1] == '"' or clean_value[clean_value.len - 1] == '\'')) {
                        clean_value = clean_value[0 .. clean_value.len - 1];
                    }

                    if (Element.getAttribute(node, attr_name)) |attr_value| {
                        break :blk std.mem.eql(u8, attr_value, clean_value);
                    }
                    break :blk false;
                } else {
                    // Attribute presence matching: [name]
                    break :blk Element.hasAttribute(node, attr_name);
                }
            },
            .universal => true,
        };

        // If any component doesn't match, return false
        if (!match) return false;
    }

    return true;
}

/// Query Selector - Find First Matching Element
///
/// Searches the node tree for the first element matching the given selector.
/// Search is performed in depth-first, pre-order traversal.
///
/// ## Parameters
///
/// - `root`: Root node to search from (inclusive)
/// - `selector`: CSS selector string
/// - `allocator`: Memory allocator for temporary allocations
///
/// ## Returns
///
/// First matching element, or `null` if no match found.
///
/// ## Errors
///
/// - `error.OutOfMemory`: Memory allocation failed
/// - `error.InvalidSelector`: Malformed selector syntax
///
/// ## Examples
///
/// ```zig
/// // Create document structure
/// const root = try Element.create(allocator, "div");
/// defer root.release();
///
/// const child1 = try Element.create(allocator, "span");
/// try Element.setAttribute(child1, "id", "first");
/// _ = try root.appendChild(child1);
///
/// const child2 = try Element.create(allocator, "p");
/// try Element.setAttribute(child2, "id", "second");
/// _ = try root.appendChild(child2);
///
/// // Find by ID
/// const found = try querySelector(root, "#second", allocator);
/// // found === child2
///
/// // Find by tag
/// const span = try querySelector(root, "span", allocator);
/// // span === child1
///
/// // No match returns null
/// const none = try querySelector(root, "#nonexistent", allocator);
/// // none === null
/// ```
///
/// ## Performance
///
/// Search stops at first match, making it efficient for finding single elements.
/// For multiple matches, use querySelectorAll().
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector
pub fn querySelector(root: *const Node, selector: []const u8, allocator: std.mem.Allocator) !?*Node {
    // Check if root itself matches
    if (root.node_type == .element_node) {
        if (try matches(root, selector, allocator)) {
            return @constCast(root);
        }
    }

    // Recursively search children (depth-first)
    for (root.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (try querySelector(child, selector, allocator)) |found| {
            return found;
        }
    }

    return null;
}

/// Query Selector All - Find All Matching Elements
///
/// Searches the node tree for all elements matching the given selector.
/// Matching elements are appended to the provided NodeList.
/// Search is performed in depth-first, pre-order traversal.
///
/// ## Parameters
///
/// - `root`: Root node to search from (inclusive)
/// - `selector`: CSS selector string
/// - `list`: NodeList to append matching elements to
/// - `allocator`: Memory allocator for temporary allocations
///
/// ## Errors
///
/// - `error.OutOfMemory`: Memory allocation failed
/// - `error.InvalidSelector`: Malformed selector syntax
///
/// ## Examples
///
/// ```zig
/// // Create document structure with multiple matches
/// const root = try Element.create(allocator, "div");
/// defer root.release();
///
/// const item1 = try Element.create(allocator, "span");
/// try Element.setClassName(item1, "item");
/// _ = try root.appendChild(item1);
///
/// const item2 = try Element.create(allocator, "div");
/// try Element.setClassName(item2, "item");
/// _ = try root.appendChild(item2);
///
/// const other = try Element.create(allocator, "p");
/// _ = try root.appendChild(other);
///
/// // Find all elements with class "item"
/// var list = NodeList.init(allocator);
/// defer list.deinit();
/// try querySelectorAll(root, ".item", &list, allocator);
/// // list.length() === 2
/// // list.item(0) === item1
/// // list.item(1) === item2
///
/// // Find all elements
/// var all_list = NodeList.init(allocator);
/// defer all_list.deinit();
/// try querySelectorAll(root, "*", &all_list, allocator);
/// // all_list.length() === 4 (root + 3 children)
/// ```
///
/// ## Performance
///
/// Traverses entire subtree, so use specific selectors for better performance.
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelectorAll
pub fn querySelectorAll(root: *const Node, selector: []const u8, list: *@import("node_list.zig").NodeList, allocator: std.mem.Allocator) !void {
    // Check if root matches and add to list
    if (root.node_type == .element_node) {
        if (try matches(root, selector, allocator)) {
            try list.append(@constCast(root));
        }
    }

    // Recursively search all children
    for (root.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        try querySelectorAll(child, selector, list, allocator);
    }
}

// ============================================================================
// Tests
// ============================================================================

test "Selector parse tag" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "div");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqual(SelectorType.tag, selectors[0].selector_type);
    try std.testing.expectEqualStrings("div", selectors[0].value);
}

test "Selector parse id" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "#myid");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqual(SelectorType.id, selectors[0].selector_type);
    try std.testing.expectEqualStrings("myid", selectors[0].value);
}

test "Selector parse class" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, ".myclass");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqual(SelectorType.class_name, selectors[0].selector_type);
    try std.testing.expectEqualStrings("myclass", selectors[0].value);
}

test "Selector parse attribute" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "[data-test]");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqual(SelectorType.attribute, selectors[0].selector_type);
    try std.testing.expectEqualStrings("data-test", selectors[0].value);
}

test "Selector parse combined" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "div.myclass#myid");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 3), selectors.len);
    try std.testing.expectEqual(SelectorType.tag, selectors[0].selector_type);
    try std.testing.expectEqual(SelectorType.class_name, selectors[1].selector_type);
    try std.testing.expectEqual(SelectorType.id, selectors[2].selector_type);
}

test "matches tag selector" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try std.testing.expectEqual(true, try matches(element, "div", allocator));
    try std.testing.expectEqual(true, try matches(element, "DIV", allocator));
    try std.testing.expectEqual(false, try matches(element, "span", allocator));
}

test "matches id selector" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try Element.setAttribute(element, "id", "test");

    try std.testing.expectEqual(true, try matches(element, "#test", allocator));
    try std.testing.expectEqual(false, try matches(element, "#other", allocator));
}

test "matches class selector" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try Element.setClassName(element, "foo bar");

    try std.testing.expectEqual(true, try matches(element, ".foo", allocator));
    try std.testing.expectEqual(true, try matches(element, ".bar", allocator));
    try std.testing.expectEqual(false, try matches(element, ".baz", allocator));
}

test "matches combined selector" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try Element.setAttribute(element, "id", "test");
    try Element.setClassName(element, "foo");

    try std.testing.expectEqual(true, try matches(element, "div.foo#test", allocator));
    try std.testing.expectEqual(false, try matches(element, "div.bar#test", allocator));
    try std.testing.expectEqual(false, try matches(element, "span.foo#test", allocator));
}

test "querySelector finds element" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "span");
    _ = try parent.appendChild(child1);

    const child2 = try Element.create(allocator, "p");
    try Element.setAttribute(child2, "id", "target");
    _ = try parent.appendChild(child2);

    const found = try querySelector(parent, "#target", allocator);
    try std.testing.expect(found != null);
    try std.testing.expectEqual(child2, found.?);
}

test "querySelectorAll finds multiple elements" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "span");
    try Element.setClassName(child1, "item");
    _ = try parent.appendChild(child1);

    const child2 = try Element.create(allocator, "span");
    try Element.setClassName(child2, "item");
    _ = try parent.appendChild(child2);

    const child3 = try Element.create(allocator, "p");
    _ = try parent.appendChild(child3);

    var list = @import("node_list.zig").NodeList.init(allocator);
    defer list.deinit();

    try querySelectorAll(parent, ".item", &list, allocator);
    try std.testing.expectEqual(@as(usize, 2), list.length());
}

// ============================================================================
// Enhanced Tests - Edge Cases and Validation
// ============================================================================

test "parse empty selector" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 0), selectors.len);
}

test "parse whitespace only selector" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "   ");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 0), selectors.len);
}

test "parse universal selector" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "*");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqual(SelectorType.universal, selectors[0].selector_type);
}

test "parse multiple classes" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, ".foo.bar.baz");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 3), selectors.len);
    try std.testing.expectEqualStrings("foo", selectors[0].value);
    try std.testing.expectEqualStrings("bar", selectors[1].value);
    try std.testing.expectEqualStrings("baz", selectors[2].value);
}

test "parse attribute with value" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "[type=\"text\"]");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqual(SelectorType.attribute, selectors[0].selector_type);
    try std.testing.expectEqualStrings("type=\"text\"", selectors[0].value);
}

test "parse attribute with single quotes" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "[type='text']");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqualStrings("type='text'", selectors[0].value);
}

test "parse unclosed attribute bracket returns error" {
    const allocator = std.testing.allocator;

    const result = Selector.parse(allocator, "[unclosed");
    try std.testing.expectError(error.InvalidSelector, result);
}

test "parse hyphenated tag name" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "my-element");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqual(SelectorType.tag, selectors[0].selector_type);
    try std.testing.expectEqualStrings("my-element", selectors[0].value);
}

test "parse tag with underscore" {
    const allocator = std.testing.allocator;

    const selectors = try Selector.parse(allocator, "my_element");
    defer allocator.free(selectors);

    try std.testing.expectEqual(@as(usize, 1), selectors.len);
    try std.testing.expectEqualStrings("my_element", selectors[0].value);
}

test "matches non-element node returns false" {
    const allocator = std.testing.allocator;

    const text = try @import("text.zig").Text.init(allocator, "Hello");
    defer text.release();

    try std.testing.expectEqual(false, try matches(text.character_data.node, "div", allocator));
}

test "matches universal selector" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try std.testing.expectEqual(true, try matches(element, "*", allocator));
}

test "matches tag case insensitive" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "DiV");
    defer element.release();

    try std.testing.expectEqual(true, try matches(element, "div", allocator));
    try std.testing.expectEqual(true, try matches(element, "DIV", allocator));
    try std.testing.expectEqual(true, try matches(element, "DiV", allocator));
}

test "matches id case sensitive" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();
    try Element.setAttribute(element, "id", "MyId");

    try std.testing.expectEqual(true, try matches(element, "#MyId", allocator));
    try std.testing.expectEqual(false, try matches(element, "#myid", allocator));
    try std.testing.expectEqual(false, try matches(element, "#MYID", allocator));
}

test "matches class case sensitive" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();
    try Element.setClassName(element, "MyClass");

    try std.testing.expectEqual(true, try matches(element, ".MyClass", allocator));
    try std.testing.expectEqual(false, try matches(element, ".myclass", allocator));
}

test "matches attribute presence" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "input");
    defer element.release();
    try Element.setAttribute(element, "disabled", "");

    try std.testing.expectEqual(true, try matches(element, "[disabled]", allocator));
    try std.testing.expectEqual(false, try matches(element, "[enabled]", allocator));
}

test "matches attribute value with double quotes" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "input");
    defer element.release();
    try Element.setAttribute(element, "type", "text");

    try std.testing.expectEqual(true, try matches(element, "[type=\"text\"]", allocator));
    try std.testing.expectEqual(false, try matches(element, "[type=\"number\"]", allocator));
}

test "matches attribute value with single quotes" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "input");
    defer element.release();
    try Element.setAttribute(element, "type", "text");

    try std.testing.expectEqual(true, try matches(element, "[type='text']", allocator));
}

test "matches attribute value without quotes" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "input");
    defer element.release();
    try Element.setAttribute(element, "type", "text");

    try std.testing.expectEqual(true, try matches(element, "[type=text]", allocator));
}

test "matches multiple classes all must match" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();
    try Element.setClassName(element, "foo bar baz");

    try std.testing.expectEqual(true, try matches(element, ".foo.bar", allocator));
    try std.testing.expectEqual(true, try matches(element, ".foo.bar.baz", allocator));
    try std.testing.expectEqual(false, try matches(element, ".foo.qux", allocator));
}

test "querySelector returns null when no match" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "span");
    _ = try parent.appendChild(child);

    const found = try querySelector(parent, "#nonexistent", allocator);
    try std.testing.expectEqual(@as(?*Node, null), found);
}

test "querySelector matches root element" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();
    try Element.setAttribute(element, "id", "root");

    const found = try querySelector(element, "#root", allocator);
    try std.testing.expect(found != null);
    try std.testing.expectEqual(element, found.?);
}

test "querySelector finds nested element" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const parent = try Element.create(allocator, "div");
    _ = try root.appendChild(parent);

    const child = try Element.create(allocator, "span");
    try Element.setAttribute(child, "id", "nested");
    _ = try parent.appendChild(child);

    const found = try querySelector(root, "#nested", allocator);
    try std.testing.expect(found != null);
    try std.testing.expectEqual(child, found.?);
}

test "querySelector returns first match" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "span");
    try Element.setClassName(child1, "item");
    _ = try parent.appendChild(child1);

    const child2 = try Element.create(allocator, "span");
    try Element.setClassName(child2, "item");
    _ = try parent.appendChild(child2);

    const found = try querySelector(parent, ".item", allocator);
    try std.testing.expect(found != null);
    try std.testing.expectEqual(child1, found.?); // First match
}

test "querySelectorAll empty result" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "span");
    _ = try parent.appendChild(child);

    var list = @import("node_list.zig").NodeList.init(allocator);
    defer list.deinit();

    try querySelectorAll(parent, ".nonexistent", &list, allocator);
    try std.testing.expectEqual(@as(usize, 0), list.length());
}

test "querySelectorAll includes root if matches" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();
    try Element.setClassName(element, "root");

    var list = @import("node_list.zig").NodeList.init(allocator);
    defer list.deinit();

    try querySelectorAll(element, ".root", &list, allocator);
    try std.testing.expectEqual(@as(usize, 1), list.length());
    const found_node: *Node = @ptrCast(@alignCast(list.item(0).?));
    try std.testing.expectEqual(element, found_node);
}

test "querySelectorAll finds all nested elements" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const level1 = try Element.create(allocator, "div");
    try Element.setClassName(level1, "item");
    _ = try root.appendChild(level1);

    const level2 = try Element.create(allocator, "div");
    try Element.setClassName(level2, "item");
    _ = try level1.appendChild(level2);

    const level3 = try Element.create(allocator, "div");
    try Element.setClassName(level3, "item");
    _ = try level2.appendChild(level3);

    var list = @import("node_list.zig").NodeList.init(allocator);
    defer list.deinit();

    try querySelectorAll(root, ".item", &list, allocator);
    try std.testing.expectEqual(@as(usize, 3), list.length());
}

test "querySelectorAll with universal selector" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "span");
    _ = try parent.appendChild(child1);

    const child2 = try Element.create(allocator, "p");
    _ = try parent.appendChild(child2);

    var list = @import("node_list.zig").NodeList.init(allocator);
    defer list.deinit();

    try querySelectorAll(parent, "*", &list, allocator);
    try std.testing.expectEqual(@as(usize, 3), list.length()); // parent + 2 children
}

// Memory leak test
test "selector operations do not leak memory" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const element = try Element.create(allocator, "div");
        defer element.release();

        try Element.setAttribute(element, "id", "test");
        try Element.setClassName(element, "foo bar");

        // Parse selectors
        {
            const selectors = try Selector.parse(allocator, "div.foo#test");
            defer allocator.free(selectors);
        }

        // Test matches
        _ = try matches(element, "div.foo#test", allocator);

        // Test querySelector
        _ = try querySelector(element, ".foo", allocator);

        // Test querySelectorAll
        var list = @import("node_list.zig").NodeList.init(allocator);
        defer list.deinit();
        try querySelectorAll(element, "*", &list, allocator);
    }
}
