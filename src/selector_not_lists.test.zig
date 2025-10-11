const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const selector = @import("selector.zig");
const Node = @import("node.zig").Node;

// Helper to set element attributes
inline fn setAttr(node: *Node, name: []const u8, value: []const u8) !void {
    try Element.setAttribute(node, name, value);
}

// Test 1: Single selector (baseline - should still work)
test ":not() with single selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    const p = try doc.createElement("p");
    _ = try doc.node.appendChild(p);

    // :not(div) matches p but not div
    try testing.expect(try selector.matches(p, ":not(div)", allocator));
    try testing.expect(!try selector.matches(div, ":not(div)", allocator));

    // :not(p) matches div but not p
    try testing.expect(try selector.matches(div, ":not(p)", allocator));
    try testing.expect(!try selector.matches(p, ":not(p)", allocator));
}

// Test 2: Two selectors in :not()
test ":not() with two selectors" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    const p = try doc.createElement("p");
    _ = try doc.node.appendChild(p);

    const span = try doc.createElement("span");
    _ = try doc.node.appendChild(span);

    // :not(div, p) should match span, but not div or p
    try testing.expect(try selector.matches(span, ":not(div, p)", allocator));
    try testing.expect(!try selector.matches(div, ":not(div, p)", allocator));
    try testing.expect(!try selector.matches(p, ":not(div, p)", allocator));
}

// Test 3: Multiple selectors in :not()
test ":not() with multiple selectors" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    const p = try doc.createElement("p");
    _ = try doc.node.appendChild(p);

    const span = try doc.createElement("span");
    _ = try doc.node.appendChild(span);

    const article = try doc.createElement("article");
    _ = try doc.node.appendChild(article);

    // :not(div, p, span) should match article only
    try testing.expect(try selector.matches(article, ":not(div, p, span)", allocator));
    try testing.expect(!try selector.matches(div, ":not(div, p, span)", allocator));
    try testing.expect(!try selector.matches(p, ":not(div, p, span)", allocator));
    try testing.expect(!try selector.matches(span, ":not(div, p, span)", allocator));
}

// Test 4: :not() with class selectors
test ":not() with multiple class selectors" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const active = try doc.createElement("div");
    try setAttr(active, "class", "active");
    _ = try doc.node.appendChild(active);

    const disabled = try doc.createElement("div");
    try setAttr(disabled, "class", "disabled");
    _ = try doc.node.appendChild(disabled);

    const normal = try doc.createElement("div");
    try setAttr(normal, "class", "normal");
    _ = try doc.node.appendChild(normal);

    // :not(.active, .disabled) should match only normal
    try testing.expect(try selector.matches(normal, ":not(.active, .disabled)", allocator));
    try testing.expect(!try selector.matches(active, ":not(.active, .disabled)", allocator));
    try testing.expect(!try selector.matches(disabled, ":not(.active, .disabled)", allocator));
}

// Test 5: :not() with ID selectors
test ":not() with multiple ID selectors" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const header = try doc.createElement("div");
    try setAttr(header, "id", "header");
    _ = try doc.node.appendChild(header);

    const footer = try doc.createElement("div");
    try setAttr(footer, "id", "footer");
    _ = try doc.node.appendChild(footer);

    const content = try doc.createElement("div");
    try setAttr(content, "id", "content");
    _ = try doc.node.appendChild(content);

    // :not(#header, #footer) should match only content
    try testing.expect(try selector.matches(content, ":not(#header, #footer)", allocator));
    try testing.expect(!try selector.matches(header, ":not(#header, #footer)", allocator));
    try testing.expect(!try selector.matches(footer, ":not(#header, #footer)", allocator));
}

// Test 6: :not() with mixed selectors (tag + class + id)
test ":not() with mixed selector types" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    const active_p = try doc.createElement("p");
    try setAttr(active_p, "class", "active");
    _ = try doc.node.appendChild(active_p);

    const header = try doc.createElement("section");
    try setAttr(header, "id", "header");
    _ = try doc.node.appendChild(header);

    const span = try doc.createElement("span");
    _ = try doc.node.appendChild(span);

    // :not(div, .active, #header) should match only span
    try testing.expect(try selector.matches(span, ":not(div, .active, #header)", allocator));
    try testing.expect(!try selector.matches(div, ":not(div, .active, #header)", allocator));
    try testing.expect(!try selector.matches(active_p, ":not(div, .active, #header)", allocator));
    try testing.expect(!try selector.matches(header, ":not(div, .active, #header)", allocator));
}

// Test 7: :not() with compound selectors
test ":not() with compound selectors in list" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div_active = try doc.createElement("div");
    try setAttr(div_active, "class", "active");
    _ = try doc.node.appendChild(div_active);

    const p_special = try doc.createElement("p");
    try setAttr(p_special, "id", "special");
    _ = try doc.node.appendChild(p_special);

    const span = try doc.createElement("span");
    _ = try doc.node.appendChild(span);

    // :not(div.active, p#special) should match only span
    try testing.expect(try selector.matches(span, ":not(div.active, p#special)", allocator));
    try testing.expect(!try selector.matches(div_active, ":not(div.active, p#special)", allocator));
    try testing.expect(!try selector.matches(p_special, ":not(div.active, p#special)", allocator));
}

// Test 8: :not() with whitespace handling
test ":not() with whitespace in selector list" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    const p = try doc.createElement("p");
    _ = try doc.node.appendChild(p);

    const span = try doc.createElement("span");
    _ = try doc.node.appendChild(span);

    // Whitespace around commas should be handled
    try testing.expect(try selector.matches(span, ":not( div , p )", allocator));
    try testing.expect(!try selector.matches(div, ":not( div , p )", allocator));
    try testing.expect(!try selector.matches(p, ":not( div , p )", allocator));
}

// Test 9: :not() nested in compound selector
test ":not() selector list in compound selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div_active = try doc.createElement("div");
    try setAttr(div_active, "class", "active");
    _ = try doc.node.appendChild(div_active);

    const div_disabled = try doc.createElement("div");
    try setAttr(div_disabled, "class", "disabled");
    _ = try doc.node.appendChild(div_disabled);

    const div_normal = try doc.createElement("div");
    try setAttr(div_normal, "class", "normal");
    _ = try doc.node.appendChild(div_normal);

    const p_active = try doc.createElement("p");
    try setAttr(p_active, "class", "active");
    _ = try doc.node.appendChild(p_active);

    // div:not(.active, .disabled) should match only div.normal
    try testing.expect(try selector.matches(div_normal, "div:not(.active, .disabled)", allocator));
    try testing.expect(!try selector.matches(div_active, "div:not(.active, .disabled)", allocator));
    try testing.expect(!try selector.matches(div_disabled, "div:not(.active, .disabled)", allocator));
    try testing.expect(!try selector.matches(p_active, "div:not(.active, .disabled)", allocator));
}

// Test 10: Empty :not() list (edge case)
test ":not() with empty selector list" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // :not() with no selectors should match everything (vacuous truth)
    try testing.expect(try selector.matches(div, ":not()", allocator));
}

// Test 11: :not() with attribute selectors
test ":not() with attribute selectors in list" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const with_title = try doc.createElement("div");
    try setAttr(with_title, "title", "test");
    _ = try doc.node.appendChild(with_title);

    const with_disabled = try doc.createElement("div");
    try setAttr(with_disabled, "disabled", "");
    _ = try doc.node.appendChild(with_disabled);

    const normal = try doc.createElement("div");
    _ = try doc.node.appendChild(normal);

    // :not([title], [disabled]) should match only normal
    try testing.expect(try selector.matches(normal, ":not([title], [disabled])", allocator));
    try testing.expect(!try selector.matches(with_title, ":not([title], [disabled])", allocator));
    try testing.expect(!try selector.matches(with_disabled, ":not([title], [disabled])", allocator));
}

// Test 12: :not() with pseudo-class selectors
test ":not() with pseudo-classes in list" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(parent);

    // Create 3 children
    const child1 = try doc.createElement("span");
    _ = try parent.appendChild(child1);

    const child2 = try doc.createElement("span");
    _ = try parent.appendChild(child2);

    const child3 = try doc.createElement("span");
    _ = try parent.appendChild(child3);

    // :not(:first-child, :last-child) should match only the middle child
    try testing.expect(try selector.matches(child2, ":not(:first-child, :last-child)", allocator));
    try testing.expect(!try selector.matches(child1, ":not(:first-child, :last-child)", allocator));
    try testing.expect(!try selector.matches(child3, ":not(:first-child, :last-child)", allocator));
}

// Test 13: Complex real-world example
test ":not() complex real-world selector list" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const nav_link = try doc.createElement("a");
    try setAttr(nav_link, "class", "nav-link");
    _ = try doc.node.appendChild(nav_link);

    const button_primary = try doc.createElement("button");
    try setAttr(button_primary, "class", "btn-primary");
    _ = try doc.node.appendChild(button_primary);

    const input_text = try doc.createElement("input");
    try setAttr(input_text, "type", "text");
    _ = try doc.node.appendChild(input_text);

    const div_content = try doc.createElement("div");
    try setAttr(div_content, "id", "content");
    _ = try doc.node.appendChild(div_content);

    // :not(a.nav-link, button.btn-primary, input[type="text"], #content)
    // Should NOT match any of the above elements
    const selector_str = ":not(a.nav-link, button.btn-primary, input[type=\"text\"], #content)";

    try testing.expect(!try selector.matches(nav_link, selector_str, allocator));
    try testing.expect(!try selector.matches(button_primary, selector_str, allocator));
    try testing.expect(!try selector.matches(input_text, selector_str, allocator));
    try testing.expect(!try selector.matches(div_content, selector_str, allocator));

    // But should match a normal span
    const span = try doc.createElement("span");
    _ = try doc.node.appendChild(span);
    try testing.expect(try selector.matches(span, selector_str, allocator));
}
