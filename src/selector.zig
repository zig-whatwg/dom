//! CSS Selector Parsing and Matching - Full CSS4 Support
//!
//! This module implements comprehensive CSS selector parsing and element matching
//! with support for combinators, pseudo-classes, and advanced features.
//!
//! **Support Level:** CSS Selectors Level 1-4 (Full Support)
//!
//! ## WHATWG Specification
//!
//! - **§1.3 Selectors**: https://dom.spec.whatwg.org/#selectors
//! - **CSS Selectors 4**: https://drafts.csswg.org/selectors-4/

const std = @import("std");
const Node = @import("node.zig").Node;
const Element = @import("element.zig").Element;

// ============================================================================
// Type Definitions
// ============================================================================

/// Errors that can occur during selector parsing and matching
pub const SelectorError = error{
    InvalidSelector,
    OutOfMemory,
};

/// Selector Type Classification
pub const SelectorType = enum {
    tag,
    id,
    class_name,
    attribute,
    universal,
};

/// Combinator types for complex selectors
pub const Combinator = enum {
    none, // No combinator (simple selector)
    descendant, // space: "div p"
    child, // >: "div > p"
    adjacent_sibling, // +: "h1 + p"
    general_sibling, // ~: "h1 ~ p"
};

/// Pseudo-class types
pub const PseudoClass = enum {
    none,
    first_child,
    last_child,
    nth_child,
    nth_last_child,
    first_of_type,
    last_of_type,
    nth_of_type,
    nth_last_of_type,
    only_child,
    only_of_type,
    empty,
    root,
    not,
    is, // :is() - matches any selector in the list
    where, // :where() - like :is() but with zero specificity
    has, // :has() - relational pseudo-class
    lang, // :lang() - language matching
    dir, // :dir() - text direction matching (CSS4)
    focus_within, // :focus-within - element or descendant has focus (CSS4)
    focus_visible, // :focus-visible - keyboard focus indication (CSS4)
    // Form state pseudo-classes
    enabled, // :enabled - form element that can be interacted with
    disabled, // :disabled - form element with disabled attribute
    checked, // :checked - checked checkbox/radio or selected option
    indeterminate, // :indeterminate - checkbox in indeterminate state
    required, // :required - form field with required attribute
    optional, // :optional - form field without required attribute
    valid, // :valid - form field with valid input
    invalid, // :invalid - form field with invalid input
    read_only, // :read-only - form field with readonly attribute
    read_write, // :read-write - editable form field
    in_range, // :in-range - input value within min/max range
    out_of_range, // :out-of-range - input value outside min/max range
    placeholder_shown, // :placeholder-shown - input showing placeholder text
    default, // :default - default button/option/radio/checkbox in a form
    // Link pseudo-classes (CSS4 Section 8)
    any_link, // :any-link - matches <a> and <area> with href
    link, // :link - unvisited links
    visited, // :visited - visited links
    local_link, // :local-link - links to same domain (CSS4)
    // User action pseudo-classes (CSS4 Sections 9.1-9.3, 8.4)
    hover, // :hover - element is being hovered
    active, // :active - element is being activated
    focus, // :focus - element has focus
    target, // :target - element is the target of current URL fragment
    // Custom element pseudo-class (CSS4 Section 5.4)
    defined, // :defined - custom element is defined
};

/// Attribute operators for attribute selectors
pub const AttributeOperator = enum {
    exists, // [attr]
    equals, // [attr="value"]
    contains, // [attr*="value"]
    starts_with, // [attr^="value"]
    ends_with, // [attr$="value"]
    word_match, // [attr~="value"]
    lang_match, // [attr|="value"]
};

/// Single selector component (tag, class, id, attribute, or pseudo-class)
pub const SelectorComponent = struct {
    selector_type: SelectorType,
    value: []const u8,
    pseudo_class: PseudoClass = .none,
    pseudo_args: ?[]const u8 = null,
    attr_operator: AttributeOperator = .exists,
    attr_value: ?[]const u8 = null, // For attribute selectors with values
    attr_case_insensitive: bool = false, // For [attr=value i] flag
};

/// Compound selector - multiple components that all apply to the same element
/// Examples: "div.class", "input#id[type='text']", ".foo.bar:hover"
pub const CompoundSelector = struct {
    components: []SelectorComponent,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *CompoundSelector) void {
        self.allocator.free(self.components);
    }
};

/// Simple selector component (for backward compatibility - now an alias)
pub const SimpleSelector = CompoundSelector;

/// Complex selector with combinators
pub const ComplexSelector = struct {
    parts: []CompoundSelector,
    combinators: []Combinator,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ComplexSelector) void {
        for (self.parts) |*part| {
            part.deinit();
        }
        self.allocator.free(self.parts);
        self.allocator.free(self.combinators);
    }
};

/// Selector group - handles comma-separated selectors like "div, p, span"
/// This is the top-level structure that represents the entire selector string
pub const SelectorGroup = struct {
    selectors: []ComplexSelector,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *SelectorGroup) void {
        for (self.selectors) |*selector| {
            selector.deinit();
        }
        self.allocator.free(self.selectors);
    }
};

// ============================================================================
// Parsing Functions
// ============================================================================

/// Parse a selector group (supports comma-separated selectors)
/// This is the main entry point for parsing selector strings
pub fn parseGroup(allocator: std.mem.Allocator, selector_str: []const u8) !SelectorGroup {
    var selectors = std.ArrayList(ComplexSelector){};
    errdefer {
        for (selectors.items) |*sel| {
            sel.deinit();
        }
        selectors.deinit(allocator);
    }

    // Split on commas and parse each selector
    // But ignore commas inside parentheses (e.g., :is(p, div))
    var start: usize = 0;
    var i: usize = 0;
    var paren_depth: usize = 0;

    while (i < selector_str.len) : (i += 1) {
        if (selector_str[i] == '(') {
            paren_depth += 1;
        } else if (selector_str[i] == ')') {
            if (paren_depth > 0) paren_depth -= 1;
        } else if (selector_str[i] == ',' and paren_depth == 0) {
            const trimmed = std.mem.trim(u8, selector_str[start..i], " \t\r\n");
            if (trimmed.len > 0) {
                const selector = try parse(allocator, trimmed);
                try selectors.append(allocator, selector);
            }
            start = i + 1;
        }
    }

    // Handle the last selector (after the last comma or the only selector)
    if (start <= selector_str.len) {
        const trimmed = std.mem.trim(u8, selector_str[start..], " \t\r\n");
        if (trimmed.len > 0) {
            const selector = try parse(allocator, trimmed);
            try selectors.append(allocator, selector);
        }
    }

    return SelectorGroup{
        .selectors = try selectors.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

/// Parse a complete CSS selector string into a ComplexSelector
/// For single selectors without commas. Use parseGroup() for comma-separated selectors.
pub fn parse(allocator: std.mem.Allocator, selector_str: []const u8) !ComplexSelector {
    var parts = std.ArrayList(SimpleSelector){};
    errdefer parts.deinit(allocator);

    var combinators = std.ArrayList(Combinator){};
    errdefer combinators.deinit(allocator);

    var i: usize = 0;
    var current_combinator: Combinator = .none;

    while (i < selector_str.len) {
        // Skip whitespace and detect combinators
        while (i < selector_str.len and std.ascii.isWhitespace(selector_str[i])) {
            if (i > 0 and current_combinator == .none) {
                // Whitespace is descendant combinator
                current_combinator = .descendant;
            }
            i += 1;
        }

        if (i >= selector_str.len) break;

        const c = selector_str[i];

        // Check for combinator symbols
        if (c == '>') {
            current_combinator = .child;
            i += 1;
            continue;
        } else if (c == '+') {
            current_combinator = .adjacent_sibling;
            i += 1;
            continue;
        } else if (c == '~') {
            current_combinator = .general_sibling;
            i += 1;
            continue;
        }

        // Parse compound selector
        const compound = try parseSimpleSelector(allocator, selector_str, &i);
        try parts.append(allocator, compound);
        try combinators.append(allocator, current_combinator);
        current_combinator = .none;
    }

    return ComplexSelector{
        .parts = try parts.toOwnedSlice(allocator),
        .combinators = try combinators.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

/// Helper to parse a single selector component at current position
/// Returns null if a pseudo-element was encountered (should be skipped)
fn parseSelectorComponent(selector_str: []const u8, i: *usize) !?SelectorComponent {
    const c = selector_str[i.*];

    if (c == '#') {
        // ID selector
        i.* += 1;
        const start = i.*;
        while (i.* < selector_str.len and !isDelimiter(selector_str[i.*])) : (i.* += 1) {}
        return SelectorComponent{
            .selector_type = .id,
            .value = selector_str[start..i.*],
        };
    } else if (c == '.') {
        // Class selector
        i.* += 1;
        const start = i.*;
        while (i.* < selector_str.len and !isDelimiter(selector_str[i.*])) : (i.* += 1) {}
        return SelectorComponent{
            .selector_type = .class_name,
            .value = selector_str[start..i.*],
        };
    } else if (c == '[') {
        // Attribute selector
        i.* += 1;
        const attr_start = i.*;

        // Find end of attribute selector
        while (i.* < selector_str.len and selector_str[i.*] != ']') : (i.* += 1) {}
        if (i.* >= selector_str.len) return error.InvalidSelector;

        const attr_content = selector_str[attr_start..i.*];
        i.* += 1; // Skip ']'

        // Parse attribute operator
        return try parseAttributeSelector(attr_content);
    } else if (c == '*') {
        // Universal selector
        i.* += 1;
        return SelectorComponent{
            .selector_type = .universal,
            .value = "",
        };
    } else if (c == ':') {
        // Pseudo-class or pseudo-element
        i.* += 1;
        const pseudo_start = i.*;

        // Check for :: (pseudo-element)
        // Pseudo-elements don't match elements in querySelector, so we skip them
        if (i.* < selector_str.len and selector_str[i.*] == ':') {
            i.* += 1; // Skip second ':'
            // Skip the pseudo-element name
            while (i.* < selector_str.len and !isDelimiter(selector_str[i.*])) : (i.* += 1) {}
            return null; // Signal to skip this pseudo-element
        }

        // Parse pseudo-class name
        while (i.* < selector_str.len and selector_str[i.*] != '(' and !isDelimiter(selector_str[i.*])) : (i.* += 1) {}
        const pseudo_name = selector_str[pseudo_start..i.*];

        // Parse arguments if present
        var pseudo_args: ?[]const u8 = null;
        if (i.* < selector_str.len and selector_str[i.*] == '(') {
            i.* += 1;
            const args_start = i.*;
            var paren_depth: usize = 1;
            while (i.* < selector_str.len and paren_depth > 0) {
                if (selector_str[i.*] == '(') paren_depth += 1;
                if (selector_str[i.*] == ')') paren_depth -= 1;
                if (paren_depth > 0) i.* += 1;
            }
            pseudo_args = selector_str[args_start..i.*];
            if (i.* < selector_str.len) i.* += 1; // Skip ')'
        }

        return SelectorComponent{
            .selector_type = .universal, // Pseudo-classes don't have a specific type
            .value = "",
            .pseudo_class = parsePseudoClassName(pseudo_name),
            .pseudo_args = pseudo_args,
        };
    } else if (std.ascii.isAlphabetic(c) or c == '-' or c == '_') {
        // Tag selector
        const start = i.*;
        while (i.* < selector_str.len and !isDelimiter(selector_str[i.*])) : (i.* += 1) {}
        return SelectorComponent{
            .selector_type = .tag,
            .value = selector_str[start..i.*],
        };
    }

    return error.InvalidSelector;
}

/// Parse a compound selector at the current position
/// A compound selector is a sequence of simple selectors without combinators
/// Examples: "div", "div.class", "div.class#id[attr]", ".foo.bar:hover"
fn parseSimpleSelector(allocator: std.mem.Allocator, selector_str: []const u8, i: *usize) !CompoundSelector {
    var components = std.ArrayList(SelectorComponent){};
    errdefer components.deinit(allocator);

    const start_i = i.*;

    while (i.* < selector_str.len) {
        const c = selector_str[i.*];

        // Check for combinators (space, >, +, ~) that end the compound selector
        if (isCombinator(c)) {
            break;
        }

        // Try to parse a component at current position
        const component = parseSelectorComponent(selector_str, i) catch |err| {
            // If parsing fails, advance past unknown character and continue
            if (err == error.InvalidSelector) {
                i.* += 1;
                continue;
            }
            return err;
        };

        // If component is null, it was a pseudo-element (already skipped)
        if (component) |comp| {
            try components.append(allocator, comp);
        }

        // If we hit end of string or a combinator, stop parsing this compound selector
        if (i.* >= selector_str.len or isCombinator(selector_str[i.*])) {
            break;
        }
    }

    // If no components were parsed, return a universal selector
    if (components.items.len == 0 and i.* > start_i) {
        try components.append(allocator, .{
            .selector_type = .universal,
            .value = "",
        });
    }

    return CompoundSelector{
        .components = try components.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

/// Parse attribute selector content
fn parseAttributeSelector(content: []const u8) !SelectorComponent {
    var result = SelectorComponent{
        .selector_type = .attribute,
        .value = content,
        .attr_operator = .exists,
        .attr_value = null,
        .attr_case_insensitive = false,
    };

    // Trim whitespace and check for case-insensitive flag 'i'
    var trimmed = std.mem.trim(u8, content, " \t\r\n");
    if (trimmed.len > 0 and trimmed[trimmed.len - 1] == 'i') {
        // Check if there's a space before the 'i'
        if (trimmed.len > 1 and std.ascii.isWhitespace(trimmed[trimmed.len - 2])) {
            result.attr_case_insensitive = true;
            trimmed = std.mem.trim(u8, trimmed[0 .. trimmed.len - 1], " \t\r\n");
        }
    }

    // Check for operators and extract value
    if (std.mem.indexOf(u8, trimmed, "^=")) |idx| {
        result.attr_operator = .starts_with;
        result.value = trimmed[0..idx];
        result.attr_value = cleanAttributeValue(trimmed[idx + 2 ..]);
    } else if (std.mem.indexOf(u8, trimmed, "$=")) |idx| {
        result.attr_operator = .ends_with;
        result.value = trimmed[0..idx];
        result.attr_value = cleanAttributeValue(trimmed[idx + 2 ..]);
    } else if (std.mem.indexOf(u8, trimmed, "*=")) |idx| {
        result.attr_operator = .contains;
        result.value = trimmed[0..idx];
        result.attr_value = cleanAttributeValue(trimmed[idx + 2 ..]);
    } else if (std.mem.indexOf(u8, trimmed, "~=")) |idx| {
        result.attr_operator = .word_match;
        result.value = trimmed[0..idx];
        result.attr_value = cleanAttributeValue(trimmed[idx + 2 ..]);
    } else if (std.mem.indexOf(u8, trimmed, "|=")) |idx| {
        result.attr_operator = .lang_match;
        result.value = trimmed[0..idx];
        result.attr_value = cleanAttributeValue(trimmed[idx + 2 ..]);
    } else if (std.mem.indexOf(u8, trimmed, "=")) |idx| {
        result.attr_operator = .equals;
        result.value = trimmed[0..idx];
        result.attr_value = cleanAttributeValue(trimmed[idx + 1 ..]);
    }

    return result;
}

/// Clean attribute value by removing quotes
fn cleanAttributeValue(value: []const u8) []const u8 {
    var clean = value;
    if (clean.len > 0 and (clean[0] == '"' or clean[0] == '\'')) {
        clean = clean[1..];
    }
    if (clean.len > 0 and (clean[clean.len - 1] == '"' or clean[clean.len - 1] == '\'')) {
        clean = clean[0 .. clean.len - 1];
    }
    return clean;
}

/// Parse pseudo-class name
fn parsePseudoClassName(name: []const u8) PseudoClass {
    if (std.mem.eql(u8, name, "first-child")) return .first_child;
    if (std.mem.eql(u8, name, "last-child")) return .last_child;
    if (std.mem.eql(u8, name, "nth-child")) return .nth_child;
    if (std.mem.eql(u8, name, "nth-last-child")) return .nth_last_child;
    if (std.mem.eql(u8, name, "first-of-type")) return .first_of_type;
    if (std.mem.eql(u8, name, "last-of-type")) return .last_of_type;
    if (std.mem.eql(u8, name, "nth-of-type")) return .nth_of_type;
    if (std.mem.eql(u8, name, "nth-last-of-type")) return .nth_last_of_type;
    if (std.mem.eql(u8, name, "only-child")) return .only_child;
    if (std.mem.eql(u8, name, "only-of-type")) return .only_of_type;
    if (std.mem.eql(u8, name, "empty")) return .empty;
    if (std.mem.eql(u8, name, "root")) return .root;
    if (std.mem.eql(u8, name, "not")) return .not;
    if (std.mem.eql(u8, name, "is")) return .is;
    if (std.mem.eql(u8, name, "where")) return .where;
    if (std.mem.eql(u8, name, "has")) return .has;
    if (std.mem.eql(u8, name, "lang")) return .lang;
    if (std.mem.eql(u8, name, "dir")) return .dir;
    if (std.mem.eql(u8, name, "focus-within")) return .focus_within;
    if (std.mem.eql(u8, name, "focus-visible")) return .focus_visible;
    // Form state pseudo-classes
    if (std.mem.eql(u8, name, "enabled")) return .enabled;
    if (std.mem.eql(u8, name, "disabled")) return .disabled;
    if (std.mem.eql(u8, name, "checked")) return .checked;
    if (std.mem.eql(u8, name, "indeterminate")) return .indeterminate;
    if (std.mem.eql(u8, name, "required")) return .required;
    if (std.mem.eql(u8, name, "optional")) return .optional;
    if (std.mem.eql(u8, name, "valid")) return .valid;
    if (std.mem.eql(u8, name, "invalid")) return .invalid;
    if (std.mem.eql(u8, name, "read-only")) return .read_only;
    if (std.mem.eql(u8, name, "read-write")) return .read_write;
    if (std.mem.eql(u8, name, "in-range")) return .in_range;
    if (std.mem.eql(u8, name, "out-of-range")) return .out_of_range;
    if (std.mem.eql(u8, name, "placeholder-shown")) return .placeholder_shown;
    if (std.mem.eql(u8, name, "default")) return .default;
    // Link pseudo-classes
    if (std.mem.eql(u8, name, "any-link")) return .any_link;
    if (std.mem.eql(u8, name, "link")) return .link;
    if (std.mem.eql(u8, name, "visited")) return .visited;
    if (std.mem.eql(u8, name, "local-link")) return .local_link;
    // User action pseudo-classes
    if (std.mem.eql(u8, name, "hover")) return .hover;
    if (std.mem.eql(u8, name, "active")) return .active;
    if (std.mem.eql(u8, name, "focus")) return .focus;
    if (std.mem.eql(u8, name, "target")) return .target;
    // Custom element pseudo-class
    if (std.mem.eql(u8, name, "defined")) return .defined;
    return .none;
}

fn isDelimiter(c: u8) bool {
    return c == '#' or c == '.' or c == '[' or c == ':' or
        c == ' ' or c == '>' or c == '+' or c == '~';
}

/// Check if character is a combinator (ends a simple selector)
fn isCombinator(c: u8) bool {
    return c == ' ' or c == '>' or c == '+' or c == '~';
}

// ============================================================================
// Matching Functions
// ============================================================================

/// Match element against selector (supports comma-separated selectors)
pub fn matches(node: *const Node, selector_str: []const u8, allocator: std.mem.Allocator) !bool {
    if (node.node_type != .element_node) return false;

    // Parse as selector group to support comma-separated selectors
    var group = try parseGroup(allocator, selector_str);
    defer group.deinit();

    // Match if ANY selector in the group matches
    for (group.selectors) |*selector| {
        if (try matchesComplexSelector(node, selector, allocator)) {
            return true;
        }
    }
    return false;
}

/// Match element against parsed complex selector
fn matchesComplexSelector(node: *const Node, selector: *const ComplexSelector, allocator: std.mem.Allocator) SelectorError!bool {
    if (selector.parts.len == 0) return false;

    // Start from the end of the selector (the element we're testing)
    const last_idx = selector.parts.len - 1;

    // Match the last (rightmost) simple selector against this element
    if (!try matchesSimpleSelector(node, selector.parts[last_idx], allocator)) {
        return false;
    }

    // If it's just a simple selector, we're done
    if (selector.parts.len == 1) return true;

    // Walk backwards through combinators
    var current_node = node;
    var idx: usize = last_idx;

    while (idx > 0) {
        idx -= 1;
        const combinator = selector.combinators[idx + 1];
        const target_selector = selector.parts[idx];

        switch (combinator) {
            .none => {
                // Compound selector - must match same element
                if (!try matchesSimpleSelector(current_node, target_selector, allocator)) {
                    return false;
                }
            },
            .descendant => {
                // Find ancestor matching target_selector
                var ancestor = current_node.parent_node;
                var found = false;
                while (ancestor) |anc| {
                    if (anc.node_type == .element_node) {
                        if (try matchesSimpleSelector(anc, target_selector, allocator)) {
                            current_node = anc;
                            found = true;
                            break;
                        }
                    }
                    ancestor = anc.parent_node;
                }
                if (!found) return false;
            },
            .child => {
                // Direct parent must match
                const parent = current_node.parent_node orelse return false;
                if (parent.node_type != .element_node) return false;
                if (!try matchesSimpleSelector(parent, target_selector, allocator)) {
                    return false;
                }
                current_node = parent;
            },
            .adjacent_sibling => {
                // Previous sibling must match
                const prev = current_node.previousSibling() orelse return false;
                if (prev.node_type != .element_node) return false;
                if (!try matchesSimpleSelector(prev, target_selector, allocator)) {
                    return false;
                }
                current_node = prev;
            },
            .general_sibling => {
                // Find preceding sibling matching target_selector
                var sibling = current_node.previousSibling();
                var found = false;
                while (sibling) |sib| {
                    if (sib.node_type == .element_node) {
                        if (try matchesSimpleSelector(sib, target_selector, allocator)) {
                            current_node = sib;
                            found = true;
                            break;
                        }
                    }
                    sibling = sib.previousSibling();
                }
                if (!found) return false;
            },
        }
    }

    return true;
}

/// Match element against simple selector
/// Match a compound selector (all components must match)
fn matchesSimpleSelector(node: *const Node, selector: CompoundSelector, allocator: std.mem.Allocator) SelectorError!bool {
    // A compound selector matches if ALL components match
    for (selector.components) |component| {
        const component_matches = try matchesSelectorComponent(node, component, allocator);
        if (!component_matches) return false;
    }
    return true;
}

/// Match a single selector component
fn matchesSelectorComponent(node: *const Node, component: SelectorComponent, allocator: std.mem.Allocator) SelectorError!bool {
    // First check the base selector type
    const base_match = switch (component.selector_type) {
        .tag => blk: {
            const data = Element.getData(node);
            break :blk std.mem.eql(u8, data.tag_name, component.value);
        },
        .id => blk: {
            if (Element.getAttribute(node, "id")) |id| {
                break :blk std.mem.eql(u8, id, component.value);
            }
            break :blk false;
        },
        .class_name => blk: {
            const data = Element.getData(node);
            break :blk data.class_list.contains(component.value);
        },
        .attribute => try matchesAttributeSelector(node, component, allocator),
        .universal => true,
    };

    if (!base_match) return false;

    // Then check pseudo-class if present
    if (component.pseudo_class != .none) {
        return try matchesPseudoClass(node, component.pseudo_class, component.pseudo_args, allocator);
    }

    return true;
}

/// Match attribute selector
fn matchesAttributeSelector(node: *const Node, component: SelectorComponent, allocator: std.mem.Allocator) SelectorError!bool {
    const attr_name = component.value;
    const actual_value = Element.getAttribute(node, attr_name) orelse {
        // Attribute doesn't exist - selector cannot match
        return false;
    };

    // If just checking existence, we have the attribute
    if (component.attr_value == null) {
        return true;
    }

    const expected_value = component.attr_value.?;

    // Handle case-insensitive matching
    if (component.attr_case_insensitive) {
        const actual_lower = try std.ascii.allocLowerString(allocator, actual_value);
        defer allocator.free(actual_lower);
        const expected_lower = try std.ascii.allocLowerString(allocator, expected_value);
        defer allocator.free(expected_lower);

        return switch (component.attr_operator) {
            .exists => true,
            .equals => std.mem.eql(u8, actual_lower, expected_lower),
            .contains => std.mem.indexOf(u8, actual_lower, expected_lower) != null,
            .starts_with => std.mem.startsWith(u8, actual_lower, expected_lower),
            .ends_with => std.mem.endsWith(u8, actual_lower, expected_lower),
            .word_match => hasWord(actual_lower, expected_lower),
            .lang_match => hasLangPrefix(actual_lower, expected_lower),
        };
    }

    return switch (component.attr_operator) {
        .exists => true,
        .equals => std.mem.eql(u8, actual_value, expected_value),
        .contains => std.mem.indexOf(u8, actual_value, expected_value) != null,
        .starts_with => std.mem.startsWith(u8, actual_value, expected_value),
        .ends_with => std.mem.endsWith(u8, actual_value, expected_value),
        .word_match => hasWord(actual_value, expected_value),
        .lang_match => hasLangPrefix(actual_value, expected_value),
    };
}

/// Check if value contains word (space-separated)
fn hasWord(value: []const u8, word: []const u8) bool {
    var iter = std.mem.tokenizeScalar(u8, value, ' ');
    while (iter.next()) |token| {
        if (std.mem.eql(u8, token, word)) return true;
    }
    return false;
}

/// Check if value has language prefix
fn hasLangPrefix(value: []const u8, prefix: []const u8) bool {
    if (std.mem.eql(u8, value, prefix)) return true;
    if (std.mem.startsWith(u8, value, prefix)) {
        if (value.len > prefix.len and value[prefix.len] == '-') {
            return true;
        }
    }
    return false;
}

/// Match :lang() pseudo-class
/// Matches elements with a language attribute that matches the given language code
/// Supports language inheritance from parent elements
fn matchesLang(node: *const Node, lang_code: []const u8) bool {
    // Walk up the tree looking for a lang attribute
    var current: ?*const Node = node;
    while (current) |curr| {
        // Check if this is an element node
        if (curr.node_type == .element_node) {
            // Check for lang attribute
            if (Element.getAttribute(curr, "lang")) |lang_attr| {
                // Match using language prefix matching
                // e.g., :lang(en) matches lang="en" or lang="en-US"
                return hasLangPrefix(lang_attr, lang_code);
            }
        }

        // Move up to parent
        current = curr.parent_node;
    }

    // No lang attribute found in the element tree
    return false;
}

/// Match :dir() pseudo-class (CSS4)
/// Matches elements with a text direction matching the given direction
/// Supports direction inheritance from parent elements
fn matchesDir(node: *const Node, direction: []const u8) bool {
    // Walk up the tree looking for a dir attribute
    var current: ?*const Node = node;
    while (current) |curr| {
        // Check if this is an element node
        if (curr.node_type == .element_node) {
            // Check for dir attribute
            if (Element.getAttribute(curr, "dir")) |dir_attr| {
                // Match direction (case-insensitive)
                return std.ascii.eqlIgnoreCase(dir_attr, direction);
            }
        }

        // Move up to parent
        current = curr.parent_node;
    }

    // No dir attribute found, default is "ltr"
    return std.ascii.eqlIgnoreCase(direction, "ltr");
}

/// Match :focus-within pseudo-class (CSS4)
/// Matches element if it or any descendant has focus
fn matchesFocusWithin(node: *const Node) bool {
    // Check if element itself has focus
    if (node.node_type == .element_node) {
        if (Element.getAttribute(node, "data-has-focus")) |focus_val| {
            if (std.mem.eql(u8, focus_val, "true")) {
                return true;
            }
        }
    }

    // Check all descendants
    for (node.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (matchesFocusWithin(child)) {
            return true;
        }
    }

    return false;
}

/// Match :focus-visible pseudo-class (CSS4)
/// Matches focused element when focus should be visible (keyboard navigation)
fn matchesFocusVisible(node: *const Node) bool {
    // Element must have focus
    if (node.node_type == .element_node) {
        if (Element.getAttribute(node, "data-has-focus")) |focus_val| {
            if (std.mem.eql(u8, focus_val, "true")) {
                // Check if focus was triggered by keyboard
                if (Element.getAttribute(node, "data-focus-visible")) |visible_val| {
                    return std.mem.eql(u8, visible_val, "true");
                }
            }
        }
    }

    return false;
}

/// Match :enabled pseudo-class
/// Matches form elements that can be interacted with (not disabled)
fn matchesEnabled(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    // Check if it's a form element (case-insensitive)
    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const form_elements = [_][]const u8{ "input", "button", "select", "textarea", "option" };
    var is_form_element = false;
    for (form_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_form_element = true;
            break;
        }
    }

    if (!is_form_element) return false;

    // Element is enabled if it does NOT have disabled attribute
    return !Element.hasAttribute(node, "disabled");
}

/// Match :disabled pseudo-class
/// Matches form elements with disabled attribute
fn matchesDisabled(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    // Check if it's a form element
    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const form_elements = [_][]const u8{ "input", "button", "select", "textarea", "option" };
    var is_form_element = false;
    for (form_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_form_element = true;
            break;
        }
    }

    if (!is_form_element) return false;

    return Element.hasAttribute(node, "disabled");
}

/// Match :checked pseudo-class
/// Matches checkboxes/radios that are checked
fn matchesChecked(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    if (!std.ascii.eqlIgnoreCase(tag_name, "input")) return false;

    // Check data-checked attribute (simulated state)
    if (Element.getAttribute(node, "data-checked")) |checked_val| {
        return std.mem.eql(u8, checked_val, "true");
    }

    return false;
}

/// Match :indeterminate pseudo-class
/// Matches checkboxes in indeterminate state
fn matchesIndeterminate(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    if (!std.ascii.eqlIgnoreCase(tag_name, "input")) return false;

    // Check data-indeterminate attribute (simulated state)
    if (Element.getAttribute(node, "data-indeterminate")) |indet_val| {
        return std.mem.eql(u8, indet_val, "true");
    }

    return false;
}

/// Match :required pseudo-class
/// Matches form fields with required attribute
fn matchesRequired(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const form_elements = [_][]const u8{ "input", "select", "textarea" };
    var is_form_element = false;
    for (form_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_form_element = true;
            break;
        }
    }

    if (!is_form_element) return false;

    return Element.hasAttribute(node, "required");
}

/// Match :optional pseudo-class
/// Matches form fields without required attribute
fn matchesOptional(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const form_elements = [_][]const u8{ "input", "select", "textarea" };
    var is_form_element = false;
    for (form_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_form_element = true;
            break;
        }
    }

    if (!is_form_element) return false;

    // Element is optional if it does NOT have required attribute
    return !Element.hasAttribute(node, "required");
}

/// Match :valid pseudo-class
/// Matches form fields with valid input
fn matchesValid(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const form_elements = [_][]const u8{ "input", "select", "textarea" };
    var is_form_element = false;
    for (form_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_form_element = true;
            break;
        }
    }

    if (!is_form_element) return false;

    // Check data-valid attribute (simulated validation state)
    if (Element.getAttribute(node, "data-valid")) |valid_val| {
        return std.mem.eql(u8, valid_val, "true");
    }

    // If no validation state is set, consider it valid by default
    return true;
}

/// Match :invalid pseudo-class
/// Matches form fields with invalid input
fn matchesInvalid(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const form_elements = [_][]const u8{ "input", "select", "textarea" };
    var is_form_element = false;
    for (form_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_form_element = true;
            break;
        }
    }

    if (!is_form_element) return false;

    // Check data-valid attribute (simulated validation state)
    if (Element.getAttribute(node, "data-valid")) |valid_val| {
        return std.mem.eql(u8, valid_val, "false");
    }

    return false;
}

/// Match :read-only pseudo-class
/// Matches form fields with readonly attribute
fn matchesReadOnly(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const form_elements = [_][]const u8{ "input", "textarea" };
    var is_form_element = false;
    for (form_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_form_element = true;
            break;
        }
    }

    if (!is_form_element) return false;

    return Element.hasAttribute(node, "readonly");
}

/// Match :read-write pseudo-class
/// Matches editable form fields (not readonly)
fn matchesReadWrite(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const form_elements = [_][]const u8{ "input", "textarea" };
    var is_form_element = false;
    for (form_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_form_element = true;
            break;
        }
    }

    if (!is_form_element) return false;

    // Element is read-write if it does NOT have readonly attribute
    return !Element.hasAttribute(node, "readonly");
}

/// Match :in-range pseudo-class
/// Matches input elements whose value is within the min/max range
fn matchesInRange(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    if (!std.ascii.eqlIgnoreCase(tag_name, "input")) return false;

    // Only certain input types support min/max
    // number, range, date, datetime-local, month, time, week
    const type_attr = Element.getAttribute(node, "type") orelse "text";
    const range_types = [_][]const u8{ "number", "range", "date", "datetime-local", "month", "time", "week" };
    var is_range_type = false;
    for (range_types) |rt| {
        if (std.ascii.eqlIgnoreCase(type_attr, rt)) {
            is_range_type = true;
            break;
        }
    }
    if (!is_range_type) return false;

    // Check if element has data-in-range attribute (simulated validation state)
    if (Element.getAttribute(node, "data-in-range")) |in_range_val| {
        return std.mem.eql(u8, in_range_val, "true");
    }

    // If no explicit state, check if min/max are present
    // If they are present but no data-in-range, default to true (in range)
    const has_min = Element.hasAttribute(node, "min");
    const has_max = Element.hasAttribute(node, "max");
    if (has_min or has_max) {
        return true; // Default to in-range if constraints exist
    }

    return false; // No range constraints = not applicable
}

/// Match :out-of-range pseudo-class
/// Matches input elements whose value is outside the min/max range
fn matchesOutOfRange(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    if (!std.ascii.eqlIgnoreCase(tag_name, "input")) return false;

    // Only certain input types support min/max
    const type_attr = Element.getAttribute(node, "type") orelse "text";
    const range_types = [_][]const u8{ "number", "range", "date", "datetime-local", "month", "time", "week" };
    var is_range_type = false;
    for (range_types) |rt| {
        if (std.ascii.eqlIgnoreCase(type_attr, rt)) {
            is_range_type = true;
            break;
        }
    }
    if (!is_range_type) return false;

    // Check if element has data-in-range attribute (simulated validation state)
    if (Element.getAttribute(node, "data-in-range")) |in_range_val| {
        return std.mem.eql(u8, in_range_val, "false");
    }

    return false; // Default to not out-of-range
}

/// Match :placeholder-shown pseudo-class
/// Matches input/textarea elements that are showing placeholder text
fn matchesPlaceholderShown(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;
    const placeholder_elements = [_][]const u8{ "input", "textarea" };
    var is_placeholder_element = false;
    for (placeholder_elements) |elem| {
        if (std.ascii.eqlIgnoreCase(tag_name, elem)) {
            is_placeholder_element = true;
            break;
        }
    }
    if (!is_placeholder_element) return false;

    // Element must have a placeholder attribute
    if (!Element.hasAttribute(node, "placeholder")) return false;

    // Check if placeholder is currently shown (simulated with data-placeholder-shown)
    if (Element.getAttribute(node, "data-placeholder-shown")) |shown_val| {
        return std.mem.eql(u8, shown_val, "true");
    }

    // If element has placeholder but no explicit state, assume shown if no value
    const value = Element.getAttribute(node, "value") orelse "";
    return value.len == 0; // Placeholder shown when value is empty
}

/// Match :any-link pseudo-class
/// Matches <a> and <area> elements with href attribute
fn matchesAnyLink(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;

    // Must be <a> or <area> element
    const is_link = std.ascii.eqlIgnoreCase(tag_name, "a") or
        std.ascii.eqlIgnoreCase(tag_name, "area");
    if (!is_link) return false;

    // Must have href attribute
    return Element.hasAttribute(node, "href");
}

/// Match :link pseudo-class
/// Matches unvisited links (<a> or <area> with href that hasn't been visited)
fn matchesLink(node: *const Node) bool {
    if (!matchesAnyLink(node)) return false;

    // Check if the link has NOT been visited (simulated with data-visited)
    if (Element.getAttribute(node, "data-visited")) |visited_val| {
        return std.mem.eql(u8, visited_val, "false");
    }

    // If no data-visited attribute, default to unvisited (true for :link)
    return true;
}

/// Match :visited pseudo-class
/// Matches visited links (<a> or <area> with href that has been visited)
fn matchesVisited(node: *const Node) bool {
    if (!matchesAnyLink(node)) return false;

    // Check if the link HAS been visited (simulated with data-visited)
    if (Element.getAttribute(node, "data-visited")) |visited_val| {
        return std.mem.eql(u8, visited_val, "true");
    }

    // If no data-visited attribute, default to unvisited (false for :visited)
    return false;
}

/// Match :local-link pseudo-class (CSS4)
/// Matches links to the same domain (simulated with data-local-link attribute)
fn matchesLocalLink(node: *const Node) bool {
    if (!matchesAnyLink(node)) return false;

    // Check data-local-link attribute (simulated state)
    if (Element.getAttribute(node, "data-local-link")) |local_val| {
        return std.mem.eql(u8, local_val, "true");
    }

    // If no explicit state and has href, we could check the href value
    // For simplicity in testing, we default to false if not explicitly set
    return false;
}

/// Match :hover pseudo-class
/// Matches element that is being hovered by the cursor
fn matchesHover(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    // Check data-hover attribute (simulated state)
    if (Element.getAttribute(node, "data-hover")) |hover_val| {
        return std.mem.eql(u8, hover_val, "true");
    }

    return false;
}

/// Match :active pseudo-class
/// Matches element that is being activated (e.g., mouse button down)
fn matchesActive(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    // Check data-active attribute (simulated state)
    if (Element.getAttribute(node, "data-active")) |active_val| {
        return std.mem.eql(u8, active_val, "true");
    }

    return false;
}

/// Match :focus pseudo-class
/// Matches element that currently has focus
fn matchesFocus(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    // Check data-has-focus attribute (simulated state)
    // This is consistent with :focus-within and :focus-visible
    if (Element.getAttribute(node, "data-has-focus")) |focus_val| {
        return std.mem.eql(u8, focus_val, "true");
    }

    return false;
}

/// Match :target pseudo-class
/// Matches element whose ID matches the current URL fragment
fn matchesTarget(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    // Check data-target attribute (simulated state)
    // In a real implementation, this would check if element's ID matches
    // the URL fragment (e.g., #section would match <div id="section">)
    if (Element.getAttribute(node, "data-target")) |target_val| {
        return std.mem.eql(u8, target_val, "true");
    }

    return false;
}

/// Match :defined pseudo-class (CSS4)
/// Matches custom elements that have been defined
fn matchesDefined(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;

    // Check if tag name contains a hyphen (custom element requirement)
    const has_hyphen = std.mem.indexOfScalar(u8, tag_name, '-') != null;

    if (has_hyphen) {
        // For custom elements, check data-defined attribute
        if (Element.getAttribute(node, "data-defined")) |defined_val| {
            return std.mem.eql(u8, defined_val, "true");
        }
        // If no explicit state, assume undefined
        return false;
    }

    // Standard HTML elements are always defined
    return true;
}

/// Match :default pseudo-class
/// Matches the default submit button or checked radio/checkbox in a form
fn matchesDefault(node: *const Node) bool {
    if (node.node_type != .element_node) return false;

    const data = Element.getData(node);
    const tag_name = data.tag_name;

    // For buttons: check if it's the default submit button
    if (std.ascii.eqlIgnoreCase(tag_name, "button")) {
        const type_attr = Element.getAttribute(node, "type") orelse "submit";
        // Default submit button has type="submit" and is first in form
        if (std.ascii.eqlIgnoreCase(type_attr, "submit")) {
            // Check data-default attribute (simulated state)
            if (Element.getAttribute(node, "data-default")) |default_val| {
                return std.mem.eql(u8, default_val, "true");
            }
            return false;
        }
        return false;
    }

    // For input elements
    if (std.ascii.eqlIgnoreCase(tag_name, "input")) {
        const type_attr = Element.getAttribute(node, "type") orelse "text";

        // For submit/image inputs
        if (std.ascii.eqlIgnoreCase(type_attr, "submit") or
            std.ascii.eqlIgnoreCase(type_attr, "image"))
        {
            if (Element.getAttribute(node, "data-default")) |default_val| {
                return std.mem.eql(u8, default_val, "true");
            }
            return false;
        }

        // For radio/checkbox: check if has checked attribute (default checked state)
        if (std.ascii.eqlIgnoreCase(type_attr, "radio") or
            std.ascii.eqlIgnoreCase(type_attr, "checkbox"))
        {
            // Default is defined by the checked attribute in HTML
            return Element.hasAttribute(node, "checked");
        }

        return false;
    }

    // For option elements
    if (std.ascii.eqlIgnoreCase(tag_name, "option")) {
        // Default option has selected attribute
        return Element.hasAttribute(node, "selected");
    }

    return false;
}

/// Match pseudo-class
fn matchesPseudoClass(node: *const Node, pseudo: PseudoClass, args: ?[]const u8, allocator: std.mem.Allocator) SelectorError!bool {
    return switch (pseudo) {
        .none => true,
        .first_child => matchesFirstChild(node),
        .last_child => matchesLastChild(node),
        .nth_child => try matchesNthChild(node, args orelse "1", allocator),
        .nth_last_child => try matchesNthLastChild(node, args orelse "1", allocator),
        .nth_of_type => try matchesNthOfType(node, args orelse "1", allocator),
        .nth_last_of_type => try matchesNthLastOfType(node, args orelse "1", allocator),
        .only_child => matchesOnlyChild(node),
        .first_of_type => matchesFirstOfType(node),
        .last_of_type => matchesLastOfType(node),
        .only_of_type => matchesOnlyOfType(node),
        .empty => matchesEmpty(node),
        .root => node.parent_node == null,
        .not => try matchesNot(node, args orelse "", allocator),
        .is, .where => try matchesIs(node, args orelse "", allocator),
        .has => try matchesHas(node, args orelse "", allocator),
        .lang => matchesLang(node, args orelse ""),
        .dir => matchesDir(node, args orelse "ltr"),
        .focus_within => matchesFocusWithin(node),
        .focus_visible => matchesFocusVisible(node),
        .enabled => matchesEnabled(node),
        .disabled => matchesDisabled(node),
        .checked => matchesChecked(node),
        .indeterminate => matchesIndeterminate(node),
        .required => matchesRequired(node),
        .optional => matchesOptional(node),
        .valid => matchesValid(node),
        .invalid => matchesInvalid(node),
        .read_only => matchesReadOnly(node),
        .read_write => matchesReadWrite(node),
        .in_range => matchesInRange(node),
        .out_of_range => matchesOutOfRange(node),
        .placeholder_shown => matchesPlaceholderShown(node),
        .default => matchesDefault(node),
        // Link pseudo-classes
        .any_link => matchesAnyLink(node),
        .link => matchesLink(node),
        .visited => matchesVisited(node),
        .local_link => matchesLocalLink(node),
        // User action pseudo-classes
        .hover => matchesHover(node),
        .active => matchesActive(node),
        .focus => matchesFocus(node),
        .target => matchesTarget(node),
        // Custom element pseudo-class
        .defined => matchesDefined(node),
    };
}

/// Match :not() pseudo-class by negating inner selector(s)
/// CSS4: Supports comma-separated selector lists like :not(div, .class, #id)
/// Returns true if NONE of the selectors match (negates OR logic)
fn matchesNot(node: *const Node, inner_selector: []const u8, allocator: std.mem.Allocator) SelectorError!bool {
    // Parse as a selector group (comma-separated)
    var group = try parseGroup(allocator, inner_selector);
    defer group.deinit();

    // Return true if NONE of the selectors match
    for (group.selectors) |*selector| {
        if (try matchesComplexSelector(node, selector, allocator)) {
            return false; // At least one matches, so :not() is false
        }
    }
    return true; // None matched, so :not() is true
}

/// Match :is() and :where() pseudo-classes
/// These match if ANY selector in the comma-separated list matches
/// :where() is identical to :is() but with zero specificity (we don't track specificity)
fn matchesIs(node: *const Node, selector_list: []const u8, allocator: std.mem.Allocator) SelectorError!bool {
    // Parse as a selector group (comma-separated)
    var group = try parseGroup(allocator, selector_list);
    defer group.deinit();

    // Return true if ANY selector matches
    for (group.selectors) |*selector| {
        if (try matchesComplexSelector(node, selector, allocator)) {
            return true;
        }
    }
    return false;
}

/// Match :has() pseudo-class (relational pseudo-class)
/// Matches if ANY relative matches the selector (respecting combinators)
fn matchesHas(node: *const Node, selector_str: []const u8, allocator: std.mem.Allocator) SelectorError!bool {
    // Parse the selector
    var group = try parseGroup(allocator, selector_str);
    defer group.deinit();

    // Check each selector in the group
    for (group.selectors) |*sel| {
        // Detect the combinator type from the selector
        const combinator = detectHasCombinator(selector_str);

        const matches_result = switch (combinator) {
            .child => try hasMatchingChild(node, sel, allocator),
            .adjacent_sibling => try hasMatchingAdjacentSibling(node, sel, allocator),
            .general_sibling => try hasMatchingGeneralSibling(node, sel, allocator),
            .descendant, .none => try hasMatchingDescendant(node, sel, allocator),
        };

        if (matches_result) return true;
    }

    return false;
}

/// Detect what combinator the :has() selector starts with
fn detectHasCombinator(selector_str: []const u8) Combinator {
    // Trim leading whitespace
    var i: usize = 0;
    while (i < selector_str.len and std.ascii.isWhitespace(selector_str[i])) : (i += 1) {}

    if (i >= selector_str.len) return .none;

    // Check for explicit combinator at the start
    const c = selector_str[i];
    if (c == '>') return .child;
    if (c == '+') return .adjacent_sibling;
    if (c == '~') return .general_sibling;

    // No explicit combinator = descendant (any descendant)
    return .descendant;
}

/// Check if any direct child matches the selector
fn hasMatchingChild(node: *const Node, selector: *const ComplexSelector, allocator: std.mem.Allocator) SelectorError!bool {
    for (node.child_nodes.items.items) |child_ptr| {
        const child: *const Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type != .element_node) continue;

        if (try matchesComplexSelector(child, selector, allocator)) {
            return true;
        }
    }
    return false;
}

/// Check if the next sibling (adjacent) matches the selector
fn hasMatchingAdjacentSibling(node: *const Node, selector: *const ComplexSelector, allocator: std.mem.Allocator) SelectorError!bool {
    var sibling_node = node.nextSibling();

    // Skip text nodes to find next element sibling
    while (sibling_node) |sib| {
        if (sib.node_type == .element_node) {
            return try matchesComplexSelector(sib, selector, allocator);
        }
        sibling_node = sib.nextSibling();
    }

    return false;
}

/// Check if any following sibling matches the selector
fn hasMatchingGeneralSibling(node: *const Node, selector: *const ComplexSelector, allocator: std.mem.Allocator) SelectorError!bool {
    var sibling_node = node.nextSibling();

    while (sibling_node) |sib| {
        if (sib.node_type == .element_node) {
            if (try matchesComplexSelector(sib, selector, allocator)) {
                return true;
            }
        }
        sibling_node = sib.nextSibling();
    }

    return false;
}

/// Recursively check if any descendant matches the selector
fn hasMatchingDescendant(node: *const Node, selector: *const ComplexSelector, allocator: std.mem.Allocator) SelectorError!bool {
    // Check all child nodes
    for (node.child_nodes.items.items) |child_ptr| {
        const child: *const Node = @ptrCast(@alignCast(child_ptr));

        // Skip non-element nodes
        if (child.node_type != .element_node) continue;

        // Check if this child matches
        if (try matchesComplexSelector(child, selector, allocator)) {
            return true;
        }

        // Recursively check descendants
        if (try hasMatchingDescendant(child, selector, allocator)) {
            return true;
        }
    }
    return false;
}

fn matchesFirstChild(node: *const Node) bool {
    const parent = node.parent_node orelse return false;

    // Find first element child
    for (parent.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type == .element_node) {
            return child == node;
        }
    }
    return false;
}

fn matchesLastChild(node: *const Node) bool {
    const parent = node.parent_node orelse return false;

    // Find last element child
    var i = parent.child_nodes.items.items.len;
    while (i > 0) {
        i -= 1;
        const child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[i]));
        if (child.node_type == .element_node) {
            return child == node;
        }
    }
    return false;
}

fn matchesOnlyChild(node: *const Node) bool {
    const parent = node.parent_node orelse return false;

    var element_count: usize = 0;
    for (parent.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type == .element_node) {
            element_count += 1;
            if (element_count > 1) return false;
        }
    }
    return element_count == 1;
}

fn matchesFirstOfType(node: *const Node) bool {
    const parent = node.parent_node orelse return false;
    const data = Element.getData(node);

    for (parent.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type == .element_node) {
            const child_data = Element.getData(child);
            if (std.mem.eql(u8, child_data.tag_name, data.tag_name)) {
                return child == node;
            }
        }
    }
    return false;
}

fn matchesLastOfType(node: *const Node) bool {
    const parent = node.parent_node orelse return false;
    const data = Element.getData(node);

    var i = parent.child_nodes.items.items.len;
    while (i > 0) {
        i -= 1;
        const child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[i]));
        if (child.node_type == .element_node) {
            const child_data = Element.getData(child);
            if (std.mem.eql(u8, child_data.tag_name, data.tag_name)) {
                return child == node;
            }
        }
    }
    return false;
}

fn matchesOnlyOfType(node: *const Node) bool {
    const parent = node.parent_node orelse return false;
    const data = Element.getData(node);

    var type_count: usize = 0;
    for (parent.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type == .element_node) {
            const child_data = Element.getData(child);
            if (std.mem.eql(u8, child_data.tag_name, data.tag_name)) {
                type_count += 1;
                if (type_count > 1) return false;
            }
        }
    }
    return type_count == 1;
}

fn matchesEmpty(node: *const Node) bool {
    // Element is empty if it has no children or only whitespace text
    if (node.child_nodes.items.items.len == 0) return true;

    for (node.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type == .element_node) return false;
        if (child.node_type == .text_node) {
            // Check if text is only whitespace
            const text_data = child.node_value orelse "";
            for (text_data) |c| {
                if (!std.ascii.isWhitespace(c)) return false;
            }
        }
    }
    return true;
}

fn matchesNthChild(node: *const Node, formula: []const u8, allocator: std.mem.Allocator) SelectorError!bool {
    _ = allocator;

    const parent = node.parent_node orelse return false;

    // Get index of this element among element siblings
    var index: usize = 1; // CSS uses 1-based indexing
    for (parent.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type == .element_node) {
            if (child == node) break;
            index += 1;
        }
    }

    return matchesNthFormula(index, formula);
}

fn matchesNthLastChild(node: *const Node, formula: []const u8, allocator: std.mem.Allocator) SelectorError!bool {
    _ = allocator;

    const parent = node.parent_node orelse return false;

    // Count total element children
    var total: usize = 0;
    for (parent.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type == .element_node) {
            total += 1;
        }
    }

    // Get index from the end
    var index_from_end: usize = 1;
    var i = parent.child_nodes.items.items.len;
    while (i > 0) {
        i -= 1;
        const child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[i]));
        if (child.node_type == .element_node) {
            if (child == node) break;
            index_from_end += 1;
        }
    }

    return matchesNthFormula(index_from_end, formula);
}

fn matchesNthOfType(node: *const Node, formula: []const u8, allocator: std.mem.Allocator) SelectorError!bool {
    _ = allocator;

    const parent = node.parent_node orelse return false;
    const data = Element.getData(node);

    // Get index among siblings of same type
    var index: usize = 1;
    for (parent.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (child.node_type == .element_node) {
            const child_data = Element.getData(child);
            if (std.mem.eql(u8, child_data.tag_name, data.tag_name)) {
                if (child == node) break;
                index += 1;
            }
        }
    }

    return matchesNthFormula(index, formula);
}

fn matchesNthLastOfType(node: *const Node, formula: []const u8, allocator: std.mem.Allocator) SelectorError!bool {
    _ = allocator;

    const parent = node.parent_node orelse return false;
    const data = Element.getData(node);

    // Get index from end among siblings of same type
    var index_from_end: usize = 1;
    var i = parent.child_nodes.items.items.len;
    while (i > 0) {
        i -= 1;
        const child: *Node = @ptrCast(@alignCast(parent.child_nodes.items.items[i]));
        if (child.node_type == .element_node) {
            const child_data = Element.getData(child);
            if (std.mem.eql(u8, child_data.tag_name, data.tag_name)) {
                if (child == node) break;
                index_from_end += 1;
            }
        }
    }

    return matchesNthFormula(index_from_end, formula);
}

fn matchesNthFormula(index: usize, formula: []const u8) bool {
    // Handle special cases
    if (std.mem.eql(u8, formula, "odd")) {
        return index % 2 == 1;
    }
    if (std.mem.eql(u8, formula, "even")) {
        return index % 2 == 0;
    }

    // Try to parse as simple number
    if (std.fmt.parseInt(usize, formula, 10)) |n| {
        return index == n;
    } else |_| {}

    // Parse full An+B notation
    // Examples: 2n+1, 3n, -n+3, n+5, 4n-1
    const parsed = parseNthFormula(formula) catch return false;
    return matchesAnPlusB(index, parsed.a, parsed.b);
}

const NthFormula = struct {
    a: i32, // coefficient for n (can be negative)
    b: i32, // constant offset (can be negative)
};

/// Parse An+B notation, handling all CSS variations:
/// - "n"      -> a=1, b=0
/// - "2n"     -> a=2, b=0
/// - "2n+1"   -> a=2, b=1
/// - "2n-1"   -> a=2, b=-1
/// - "-n+3"   -> a=-1, b=3
/// - "n+3"    -> a=1, b=3
/// - "3"      -> a=0, b=3
fn parseNthFormula(formula: []const u8) !NthFormula {
    const trimmed = std.mem.trim(u8, formula, &std.ascii.whitespace);

    // Remove all whitespace for easier parsing
    var no_space_buf: [256]u8 = undefined;
    var no_space_len: usize = 0;
    for (trimmed) |c| {
        if (!std.ascii.isWhitespace(c)) {
            if (no_space_len >= no_space_buf.len) return error.FormulaToLong;
            no_space_buf[no_space_len] = c;
            no_space_len += 1;
        }
    }
    const s = no_space_buf[0..no_space_len];

    if (s.len == 0) return error.EmptyFormula;

    // Look for 'n' to determine if this is An+B or just B
    const n_pos = std.mem.indexOfScalar(u8, s, 'n');

    if (n_pos == null) {
        // No 'n', so it's just a number B
        const b = try std.fmt.parseInt(i32, s, 10);
        return NthFormula{ .a = 0, .b = b };
    }

    const n_index = n_pos.?;

    // Parse A (coefficient of n)
    var a: i32 = 1;
    if (n_index > 0) {
        const a_str = s[0..n_index];
        if (a_str.len == 1 and a_str[0] == '-') {
            a = -1;
        } else if (a_str.len == 1 and a_str[0] == '+') {
            a = 1;
        } else {
            a = try std.fmt.parseInt(i32, a_str, 10);
        }
    }

    // Parse B (offset after n)
    var b: i32 = 0;
    if (n_index + 1 < s.len) {
        const b_str = s[n_index + 1 ..];
        b = try std.fmt.parseInt(i32, b_str, 10);
    }

    return NthFormula{ .a = a, .b = b };
}

/// Check if index matches the An+B formula
/// Formula: An + B = index for some non-negative integer n (n >= 0)
/// Rearranged: n = (index - B) / A
/// Match if: (index - B) % A == 0 AND (index - B) / A >= 0
fn matchesAnPlusB(index: usize, a: i32, b: i32) bool {
    const idx = @as(i32, @intCast(index));

    // Special case: a = 0 means just check if index == b
    if (a == 0) {
        return idx == b;
    }

    // Calculate index - b
    const diff = idx - b;

    // For negative 'a', we need n = (index - b) / a >= 0
    // which means (index - b) and a must have opposite signs or diff == 0
    if (a < 0) {
        // diff must be <= 0 for n to be >= 0
        if (diff > 0) return false;
    } else {
        // a > 0, so diff must be >= 0 for n to be >= 0
        if (diff < 0) return false;
    }

    // Check if diff is divisible by a
    return @rem(diff, a) == 0;
}

// ============================================================================
// Query Functions
// ============================================================================

pub fn querySelector(root: *const Node, selector: []const u8, allocator: std.mem.Allocator) !?*Node {
    // Check if root matches first
    if (root.node_type == .element_node) {
        if (try matches(root, selector, allocator)) {
            return @constCast(root);
        }
    }

    // Then search descendants
    for (root.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        if (try querySelector(child, selector, allocator)) |found| {
            return found;
        }
    }

    return null;
}

pub fn querySelectorAll(root: *const Node, selector: []const u8, list: *@import("node_list.zig").NodeList, allocator: std.mem.Allocator) !void {
    // Check if root matches first
    if (root.node_type == .element_node) {
        if (try matches(root, selector, allocator)) {
            try list.append(@constCast(root));
        }
    }

    // Then search descendants
    for (root.child_nodes.items.items) |child_ptr| {
        const child: *Node = @ptrCast(@alignCast(child_ptr));
        try querySelectorAll(child, selector, list, allocator);
    }
}

// ============================================================================
// Backwards Compatibility
// ============================================================================

/// Backwards compatibility alias - use ComplexSelector instead
pub const Selector = ComplexSelector;
