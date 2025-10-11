const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const selector = @import("selector.zig");

// Test 1: ::before pseudo-element (should be ignored)
test "::before pseudo-element is ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // div::before should match div (pseudo-element is ignored)
    try testing.expect(try selector.matches(div, "div::before", allocator));

    // Just for clarity: div without pseudo-element also matches
    try testing.expect(try selector.matches(div, "div", allocator));
}

// Test 2: ::after pseudo-element (should be ignored)
test "::after pseudo-element is ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const p = try doc.createElement("p");
    _ = try doc.node.appendChild(p);

    // p::after should match p (pseudo-element is ignored)
    try testing.expect(try selector.matches(p, "p::after", allocator));
}

// Test 3: ::first-line pseudo-element
test "::first-line pseudo-element is ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const p = try doc.createElement("p");
    _ = try doc.node.appendChild(p);

    try testing.expect(try selector.matches(p, "p::first-line", allocator));
}

// Test 4: ::first-letter pseudo-element
test "::first-letter pseudo-element is ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const p = try doc.createElement("p");
    _ = try doc.node.appendChild(p);

    try testing.expect(try selector.matches(p, "p::first-letter", allocator));
}

// Test 5: ::selection pseudo-element
test "::selection pseudo-element is ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    try testing.expect(try selector.matches(div, "div::selection", allocator));
}

// Test 6: ::marker pseudo-element (CSS Lists)
test "::marker pseudo-element is ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const li = try doc.createElement("li");
    _ = try doc.node.appendChild(li);

    try testing.expect(try selector.matches(li, "li::marker", allocator));
}

// Test 7: ::placeholder pseudo-element (CSS Forms)
test "::placeholder pseudo-element is ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, "input::placeholder", allocator));
}

// Test 8: ::backdrop pseudo-element (CSS Fullscreen)
test "::backdrop pseudo-element is ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const dialog = try doc.createElement("dialog");
    _ = try doc.node.appendChild(dialog);

    try testing.expect(try selector.matches(dialog, "dialog::backdrop", allocator));
}

// Test 9: Pseudo-element with class selector
test "pseudo-element with class selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "class", "container");
    _ = try doc.node.appendChild(div);

    // .container::before should match div.container (pseudo-element ignored)
    try testing.expect(try selector.matches(div, ".container::before", allocator));

    // div.container::after
    try testing.expect(try selector.matches(div, "div.container::after", allocator));
}

// Test 10: Pseudo-element with ID selector
test "pseudo-element with ID selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "id", "main");
    _ = try doc.node.appendChild(div);

    // #main::before should match div#main (pseudo-element ignored)
    try testing.expect(try selector.matches(div, "#main::before", allocator));

    // div#main::after
    try testing.expect(try selector.matches(div, "div#main::after", allocator));
}

// Test 11: Pseudo-element with pseudo-class
test "pseudo-element with pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("span");
    _ = try parent.appendChild(child);

    // span:first-child::before should match first child
    try testing.expect(try selector.matches(child, "span:first-child::before", allocator));
}

// Test 12: Legacy single-colon syntax :before (treated as unrecognized pseudo-class)
test "legacy :before syntax (single colon)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // Legacy :before with single colon is not recognized as a pseudo-class
    // In our implementation, unrecognized pseudo-classes are treated as .none
    // which returns true (meaning the selector matches the element part, ignoring the unknown pseudo)
    // This is actually correct behavior - it's lenient and matches browser behavior
    try testing.expect(try selector.matches(div, "div:before", allocator));

    // Similarly for :after
    try testing.expect(try selector.matches(div, "div:after", allocator));
}

// Test 13: Multiple pseudo-elements (only first is respected in CSS anyway)
test "selector with multiple pseudo-elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // div::before::after - CSS spec says this is invalid, but we should handle it gracefully
    // by skipping both pseudo-elements
    try testing.expect(try selector.matches(div, "div::before::after", allocator));
}

// Test 14: Pseudo-element in complex selector
test "pseudo-element in complex selector with combinators" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("span");
    _ = try parent.appendChild(child);

    // div > span::before should match span (pseudo-element ignored)
    try testing.expect(try selector.matches(child, "div > span::before", allocator));
}

// Test 15: Pseudo-element doesn't match wrong element
test "pseudo-element doesn't affect element matching" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    const span = try doc.createElement("span");
    _ = try doc.node.appendChild(span);

    // div::before should match div, not span
    try testing.expect(try selector.matches(div, "div::before", allocator));
    try testing.expect(!try selector.matches(span, "div::before", allocator));
}

// Test 16: Vendor-prefixed pseudo-elements
test "vendor-prefixed pseudo-elements are ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    _ = try doc.node.appendChild(input);

    // Webkit-specific pseudo-elements
    try testing.expect(try selector.matches(input, "input::-webkit-input-placeholder", allocator));
    try testing.expect(try selector.matches(input, "input::-moz-placeholder", allocator));
}

// Test 17: CSS custom pseudo-elements (::part, ::slotted in shadow DOM)
test "::part and ::slotted pseudo-elements are ignored" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    try testing.expect(try selector.matches(div, "div::part(something)", allocator));
    try testing.expect(try selector.matches(div, "div::slotted(*)", allocator));
}
