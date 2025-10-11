//! Tests for CSS4 pseudo-classes
//!
//! This file tests three CSS4 pseudo-classes:
//! - :dir() - Text direction matching
//! - :focus-within - Focus state propagation to ancestors
//! - :focus-visible - Keyboard focus indication

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const Node = @import("node.zig").Node;
const selector = @import("selector.zig");

// ============================================================================
// :dir() Tests - Text Direction Matching
// ============================================================================

test ":dir() basic ltr matching" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "dir", "ltr");
    _ = try doc.node.appendChild(div);

    // Should match with :dir(ltr)
    try testing.expect(try selector.matches(div, ":dir(ltr)", allocator));

    // Should not match different direction
    try testing.expect(!try selector.matches(div, ":dir(rtl)", allocator));
}

test ":dir() basic rtl matching" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "dir", "rtl");
    _ = try doc.node.appendChild(div);

    // Should match with :dir(rtl)
    try testing.expect(try selector.matches(div, ":dir(rtl)", allocator));

    // Should not match different direction
    try testing.expect(!try selector.matches(div, ":dir(ltr)", allocator));
}

test ":dir() case insensitive" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "dir", "RTL");
    _ = try doc.node.appendChild(div);

    // Should match case-insensitively
    try testing.expect(try selector.matches(div, ":dir(rtl)", allocator));
    try testing.expect(try selector.matches(div, ":dir(RTL)", allocator));
    try testing.expect(try selector.matches(div, ":dir(Rtl)", allocator));
}

test ":dir() inheritance from parent" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    try Element.setAttribute(parent, "dir", "rtl");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("p");
    _ = try parent.appendChild(child);

    // Child should inherit parent's direction
    try testing.expect(try selector.matches(child, ":dir(rtl)", allocator));
}

test ":dir() child overrides parent" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    try Element.setAttribute(parent, "dir", "rtl");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("p");
    try Element.setAttribute(child, "dir", "ltr");
    _ = try parent.appendChild(child);

    // Child should use its own direction, not parent's
    try testing.expect(try selector.matches(child, ":dir(ltr)", allocator));
    try testing.expect(!try selector.matches(child, ":dir(rtl)", allocator));
}

test ":dir() default is ltr" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // Element with no dir attribute should default to ltr
    try testing.expect(try selector.matches(div, ":dir(ltr)", allocator));
    try testing.expect(!try selector.matches(div, ":dir(rtl)", allocator));
}

test ":dir() with querySelector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    const rtl1 = try doc.createElement("p");
    try Element.setAttribute(rtl1, "dir", "rtl");
    _ = try container.appendChild(rtl1);

    const ltr1 = try doc.createElement("p");
    try Element.setAttribute(ltr1, "dir", "ltr");
    _ = try container.appendChild(ltr1);

    const rtl2 = try doc.createElement("span");
    try Element.setAttribute(rtl2, "dir", "rtl");
    _ = try container.appendChild(rtl2);

    // Query for first rtl element
    const result = try Element.querySelector(container, ":dir(rtl)");
    try testing.expect(result == rtl1);
}

test ":dir() combined with other selectors" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    try Element.setAttribute(container, "dir", "rtl");
    _ = try doc.node.appendChild(container);

    const p1 = try doc.createElement("p");
    try Element.setAttribute(p1, "class", "special");
    _ = try container.appendChild(p1);

    const p2 = try doc.createElement("p");
    _ = try container.appendChild(p2);

    // Combined: rtl paragraph with class
    try testing.expect(try selector.matches(p1, "p.special:dir(rtl)", allocator));

    // Should match just rtl
    try testing.expect(try selector.matches(p2, "p:dir(rtl)", allocator));
}

// ============================================================================
// :focus-within Tests - Focus State Propagation
// ============================================================================

test ":focus-within element with focus matches" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "data-has-focus", "true");
    _ = try doc.node.appendChild(div);

    // Element with focus should match :focus-within
    try testing.expect(try selector.matches(div, ":focus-within", allocator));
}

test ":focus-within parent of focused element matches" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("input");
    try Element.setAttribute(child, "data-has-focus", "true");
    _ = try parent.appendChild(child);

    // Parent should match because child has focus
    try testing.expect(try selector.matches(parent, ":focus-within", allocator));
}

test ":focus-within deep nesting" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const grandparent = try doc.createElement("div");
    _ = try doc.node.appendChild(grandparent);

    const parent = try doc.createElement("div");
    _ = try grandparent.appendChild(parent);

    const child = try doc.createElement("input");
    try Element.setAttribute(child, "data-has-focus", "true");
    _ = try parent.appendChild(child);

    // Grandparent should match
    try testing.expect(try selector.matches(grandparent, ":focus-within", allocator));

    // Parent should match
    try testing.expect(try selector.matches(parent, ":focus-within", allocator));

    // Child should match
    try testing.expect(try selector.matches(child, ":focus-within", allocator));
}

test ":focus-within no focus doesn't match" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    const child = try doc.createElement("input");
    _ = try div.appendChild(child);

    // No element has focus, should not match
    try testing.expect(!try selector.matches(div, ":focus-within", allocator));
    try testing.expect(!try selector.matches(child, ":focus-within", allocator));
}

test ":focus-within with querySelector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    const div1 = try doc.createElement("div");
    _ = try container.appendChild(div1);

    const input1 = try doc.createElement("input");
    try Element.setAttribute(input1, "data-has-focus", "true");
    _ = try div1.appendChild(input1);

    const div2 = try doc.createElement("div");
    _ = try container.appendChild(div2);

    // Query for first element with focus-within
    const result = try Element.querySelector(container, ":focus-within");
    try testing.expect(result == container); // Container is first with focus-within
}

test ":focus-within combined selectors" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const form = try doc.createElement("form");
    try Element.setAttribute(form, "class", "active");
    _ = try doc.node.appendChild(form);

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "data-has-focus", "true");
    _ = try form.appendChild(input);

    // Combined: form with class and focus-within
    try testing.expect(try selector.matches(form, "form.active:focus-within", allocator));
}

// ============================================================================
// :focus-visible Tests - Keyboard Focus Indication
// ============================================================================

test ":focus-visible keyboard focus matches" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "data-has-focus", "true");
    try Element.setAttribute(input, "data-focus-visible", "true");
    _ = try doc.node.appendChild(input);

    // Element focused via keyboard should match
    try testing.expect(try selector.matches(input, ":focus-visible", allocator));
}

test ":focus-visible mouse focus doesn't match" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "data-has-focus", "true");
    // Note: data-focus-visible not set (mouse focus)
    _ = try doc.node.appendChild(button);

    // Element focused via mouse should not match
    try testing.expect(!try selector.matches(button, ":focus-visible", allocator));
}

test ":focus-visible no focus doesn't match" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    _ = try doc.node.appendChild(input);

    // Element without focus should not match
    try testing.expect(!try selector.matches(input, ":focus-visible", allocator));
}

test ":focus-visible with querySelector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    const button1 = try doc.createElement("button");
    try Element.setAttribute(button1, "data-has-focus", "true");
    // Mouse focus - no visible
    _ = try container.appendChild(button1);

    const input1 = try doc.createElement("input");
    try Element.setAttribute(input1, "data-has-focus", "true");
    try Element.setAttribute(input1, "data-focus-visible", "true");
    _ = try container.appendChild(input1);

    // Query for first focus-visible element
    const result = try Element.querySelector(container, ":focus-visible");
    try testing.expect(result == input1);
}

test ":focus-visible combined selectors" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    try Element.setAttribute(input, "class", "form-control");
    try Element.setAttribute(input, "data-has-focus", "true");
    try Element.setAttribute(input, "data-focus-visible", "true");
    _ = try doc.node.appendChild(input);

    // Combined: input with class and focus-visible
    try testing.expect(try selector.matches(input, "input.form-control:focus-visible", allocator));
}

// ============================================================================
// Combined Tests - Multiple CSS4 Pseudo-classes
// ============================================================================

test "CSS4 pseudo-classes combined" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const form = try doc.createElement("form");
    try Element.setAttribute(form, "dir", "rtl");
    _ = try doc.node.appendChild(form);

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "data-has-focus", "true");
    try Element.setAttribute(input, "data-focus-visible", "true");
    _ = try form.appendChild(input);

    // Form matches :dir(rtl) and :focus-within
    try testing.expect(try selector.matches(form, ":dir(rtl):focus-within", allocator));

    // Input matches all three
    try testing.expect(try selector.matches(input, ":dir(rtl):focus-within:focus-visible", allocator));
}

test "CSS4 inside :not()" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div1 = try doc.createElement("div");
    try Element.setAttribute(div1, "dir", "ltr");
    _ = try doc.node.appendChild(div1);

    const div2 = try doc.createElement("div");
    try Element.setAttribute(div2, "dir", "rtl");
    _ = try doc.node.appendChild(div2);

    // :not(:dir(rtl)) should match ltr
    try testing.expect(try selector.matches(div1, ":not(:dir(rtl))", allocator));

    // :not(:dir(rtl)) should not match rtl
    try testing.expect(!try selector.matches(div2, ":not(:dir(rtl))", allocator));
}

test "CSS4 memory safety - multiple queries" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    try Element.setAttribute(container, "dir", "rtl");
    _ = try doc.node.appendChild(container);

    // Create many child elements
    var i: usize = 0;
    while (i < 50) : (i += 1) {
        const div = try doc.createElement("div");
        if (i % 2 == 0) {
            try Element.setAttribute(div, "data-has-focus", "true");
        }
        _ = try container.appendChild(div);
    }

    // Query multiple times
    var j: usize = 0;
    while (j < 5) : (j += 1) {
        const dir_results = try Element.querySelectorAll(container, ":dir(rtl)");
        defer {
            dir_results.deinit();
            allocator.destroy(dir_results);
        }
        try testing.expect(dir_results.length() > 0);

        const focus_results = try Element.querySelectorAll(container, ":focus-within");
        defer {
            focus_results.deinit();
            allocator.destroy(focus_results);
        }
        try testing.expect(focus_results.length() > 0);
    }
}
