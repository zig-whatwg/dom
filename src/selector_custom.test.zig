//! Tests for CSS4 :defined Pseudo-Class
//!
//! Tests selector matching for the :defined pseudo-class:
//! - :defined - Matches custom elements that have been defined
//!
//! Spec: https://drafts.csswg.org/selectors-4/#defined-pseudo

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const selector = @import("selector.zig");

test ":defined matches standard HTML elements" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const div = try doc.createElement("div");

    _ = try doc.node.appendChild(div);

    const span = try doc.createElement("span");

    _ = try doc.node.appendChild(span);

    const button = try doc.createElement("button");

    // Standard HTML elements are always defined
    _ = try doc.node.appendChild(button);

    // Standard HTML elements are always defined
    try testing.expect(try selector.matches(div, ":defined", testing.allocator));
    try testing.expect(try selector.matches(span, ":defined", testing.allocator));
    try testing.expect(try selector.matches(button, ":defined", testing.allocator));
}

test ":defined matches defined custom elements" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const custom = try doc.createElement("my-component");
    try Element.setAttribute(custom, "data-defined", "true");
    _ = try doc.node.appendChild(custom);

    try testing.expect(try selector.matches(custom, ":defined", testing.allocator));
}

test ":defined does not match undefined custom elements" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const custom = try doc.createElement("my-component");
    try Element.setAttribute(custom, "data-defined", "false");
    _ = try doc.node.appendChild(custom);

    try testing.expect(!try selector.matches(custom, ":defined", testing.allocator));
}

test ":defined defaults to false for custom elements without data-defined" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const custom = try doc.createElement("my-component");

    // Custom element without data-defined is considered undefined
    _ = try doc.node.appendChild(custom);

    // Custom element without data-defined is considered undefined
    try testing.expect(!try selector.matches(custom, ":defined", testing.allocator));
}

test "custom element detection requires hyphen" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    // Has hyphen - custom element
    const custom1 = try doc.createElement("my-element");

    // No hyphen - treated as standard element
    _ = try doc.node.appendChild(custom1);

    // No hyphen - treated as standard element
    const custom2 = try doc.createElement("myelement");

    // my-element without data-defined is undefined
    _ = try doc.node.appendChild(custom2);

    // my-element without data-defined is undefined
    try testing.expect(!try selector.matches(custom1, ":defined", testing.allocator));

    // myelement without hyphen is always defined (standard element)
    try testing.expect(try selector.matches(custom2, ":defined", testing.allocator));
}

test ":not(:defined) matches undefined custom elements" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const undefined_custom = try doc.createElement("undefined-element");

    _ = try doc.node.appendChild(undefined_custom);

    const defined_custom = try doc.createElement("defined-element");
    try Element.setAttribute(defined_custom, "data-defined", "true");
    _ = try doc.node.appendChild(defined_custom);

    try testing.expect(try selector.matches(undefined_custom, ":not(:defined)", testing.allocator));
    try testing.expect(!try selector.matches(defined_custom, ":not(:defined)", testing.allocator));
}

test ":not(:defined) does not match standard elements" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const div = try doc.createElement("div");

    // Standard elements are always defined, so :not(:defined) doesn't match
    _ = try doc.node.appendChild(div);

    // Standard elements are always defined, so :not(:defined) doesn't match
    try testing.expect(!try selector.matches(div, ":not(:defined)", testing.allocator));
}

test ":defined with class selector" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const custom = try doc.createElement("my-widget");
    try Element.setAttribute(custom, "class", "active");
    try Element.setAttribute(custom, "data-defined", "true");
    _ = try doc.node.appendChild(custom);

    try testing.expect(try selector.matches(custom, "my-widget.active:defined", testing.allocator));
}

test ":defined with attribute selector" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const custom = try doc.createElement("custom-input");
    try Element.setAttribute(custom, "type", "text");
    try Element.setAttribute(custom, "data-defined", "true");
    _ = try doc.node.appendChild(custom);

    try testing.expect(try selector.matches(custom, "custom-input[type]:defined", testing.allocator));
}

test "querySelector finds first :defined custom element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(root);

    const undefined_elem = try doc.createElement("my-element");
    try Element.setAttribute(undefined_elem, "id", "elem1");

    const defined_elem = try doc.createElement("my-element");
    try Element.setAttribute(defined_elem, "id", "elem2");
    try Element.setAttribute(defined_elem, "data-defined", "true");

    _ = try root.appendChild(undefined_elem);
    _ = try root.appendChild(defined_elem);

    const found = try selector.querySelector(root, "my-element:defined", testing.allocator);
    try testing.expect(found != null);
    try testing.expect(found.? == defined_elem);
}

test ":defined with descendant combinator" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    const custom = try doc.createElement("custom-card");
    try Element.setAttribute(custom, "data-defined", "true");
    _ = try container.appendChild(custom);

    try testing.expect(try selector.matches(custom, "div custom-card:defined", testing.allocator));
}

test ":defined with :is()" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const custom1 = try doc.createElement("my-button");
    try Element.setAttribute(custom1, "data-defined", "true");
    _ = try doc.node.appendChild(custom1);

    const custom2 = try doc.createElement("my-input");
    try Element.setAttribute(custom2, "data-defined", "true");
    _ = try doc.node.appendChild(custom2);

    try testing.expect(try selector.matches(custom1, ":is(my-button, my-input):defined", testing.allocator));
    try testing.expect(try selector.matches(custom2, ":is(my-button, my-input):defined", testing.allocator));
}

test "mixing standard and custom elements with :defined" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(root);

    const standard = try doc.createElement("span");

    const defined_custom = try doc.createElement("custom-elem");
    try Element.setAttribute(defined_custom, "data-defined", "true");

    const undefined_custom = try doc.createElement("other-elem");

    _ = try root.appendChild(standard);
    _ = try root.appendChild(defined_custom);
    _ = try root.appendChild(undefined_custom);

    // All three different behaviors
    try testing.expect(try selector.matches(standard, ":defined", testing.allocator)); // Standard always defined
    try testing.expect(try selector.matches(defined_custom, ":defined", testing.allocator)); // Explicitly defined
    try testing.expect(!try selector.matches(undefined_custom, ":defined", testing.allocator)); // Undefined custom
}

test "case sensitivity in custom element names" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    // Custom element names are case-insensitive in HTML
    const custom = try doc.createElement("My-Component");
    try Element.setAttribute(custom, "data-defined", "true");
    _ = try doc.node.appendChild(custom);

    try testing.expect(try selector.matches(custom, ":defined", testing.allocator));
}

test ":defined state transition" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const custom = try doc.createElement("lazy-component");

    // Initially undefined
    _ = try doc.node.appendChild(custom);

    // Initially undefined
    try testing.expect(!try selector.matches(custom, ":defined", testing.allocator));

    // Becomes defined
    try Element.setAttribute(custom, "data-defined", "true");
    try testing.expect(try selector.matches(custom, ":defined", testing.allocator));

    // Cannot become undefined again (in real implementations)
    // But for testing we can set it back
    try Element.setAttribute(custom, "data-defined", "false");
    try testing.expect(!try selector.matches(custom, ":defined", testing.allocator));
}

test "complex selector with multiple :defined checks" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const parent = try doc.createElement("custom-container");
    try Element.setAttribute(parent, "data-defined", "true");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("custom-item");
    try Element.setAttribute(child, "data-defined", "true");
    _ = try parent.appendChild(child);

    try testing.expect(try selector.matches(child, "custom-container:defined custom-item:defined", testing.allocator));
}
