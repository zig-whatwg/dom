//! Tests for compound selector parsing
//! These tests verify that multiple selector components (tag, class, id, pseudo)
//! can be combined in a single simple selector like: div.class#id:hover

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;

// ============================================================================
// Basic Compound Selector Tests
// ============================================================================

test "compound selector: tag + class" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create: <div class="target"></div>
    const div_target = try doc.createElement("div");
    try Element.setAttribute(div_target, "class", "target");
    _ = try container.appendChild(div_target);

    // Create: <span class="target"></span>
    const span_target = try doc.createElement("span");
    try Element.setAttribute(span_target, "class", "target");
    _ = try container.appendChild(span_target);

    // Should match: div with class="target" only (not the span)
    const result = try Element.querySelector(container, "div.target");
    try testing.expect(result != null);
    try testing.expect(result.? == div_target);
}

test "compound selector: tag + id" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create: <div id="main"></div>
    const div_main = try doc.createElement("div");
    try Element.setAttribute(div_main, "id", "main");
    _ = try container.appendChild(div_main);

    // Create: <span id="main"></span>
    const span_main = try doc.createElement("span");
    try Element.setAttribute(span_main, "id", "main");
    _ = try container.appendChild(span_main);

    // Should match: div with id="main" only (not the span)
    const result = try Element.querySelector(container, "div#main");
    try testing.expect(result != null);
    try testing.expect(result.? == div_main);
}

test "compound selector: class + id" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create: <div class="foo" id="bar"></div>
    const div = try doc.createElement("div");
    try Element.setAttribute(div, "class", "foo");
    try Element.setAttribute(div, "id", "bar");
    _ = try container.appendChild(div);

    // Create: <div class="foo" id="other"></div>
    const div_other = try doc.createElement("div");
    try Element.setAttribute(div_other, "class", "foo");
    try Element.setAttribute(div_other, "id", "other");
    _ = try container.appendChild(div_other);

    // Should match: element with class="foo" AND id="bar"
    const result = try Element.querySelector(container, ".foo#bar");
    try testing.expect(result != null);
    try testing.expect(result.? == div);
}

test "compound selector: tag + class + id" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create: <div class="widget" id="main"></div>
    const target = try doc.createElement("div");
    try Element.setAttribute(target, "class", "widget");
    try Element.setAttribute(target, "id", "main");
    _ = try container.appendChild(target);

    // Create: <span class="widget" id="main"></span>
    const span = try doc.createElement("span");
    try Element.setAttribute(span, "class", "widget");
    try Element.setAttribute(span, "id", "main");
    _ = try container.appendChild(span);

    // Should match: div with class="widget" AND id="main"
    const result = try Element.querySelector(container, "div.widget#main");
    try testing.expect(result != null);
    try testing.expect(result.? == target);
}

test "compound selector: multiple classes" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create: <div class="foo bar"></div>
    const div_both = try doc.createElement("div");
    try Element.setAttribute(div_both, "class", "foo bar");
    _ = try container.appendChild(div_both);

    // Create: <div class="foo"></div>
    const div_foo = try doc.createElement("div");
    try Element.setAttribute(div_foo, "class", "foo");
    _ = try container.appendChild(div_foo);

    // Should match: element with BOTH classes
    const result = try Element.querySelector(container, ".foo.bar");
    try testing.expect(result != null);
    try testing.expect(result.? == div_both);
}

test "compound selector: tag + attribute" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create: <input type="text">
    const input_text = try doc.createElement("input");
    try Element.setAttribute(input_text, "type", "text");
    _ = try container.appendChild(input_text);

    // Create: <div type="text">
    const div = try doc.createElement("div");
    try Element.setAttribute(div, "type", "text");
    _ = try container.appendChild(div);

    // Should match: input with type="text" (not the div)
    const result = try Element.querySelector(container, "input[type='text']");
    try testing.expect(result != null);
    try testing.expect(result.? == input_text);
}

test "compound selector: tag + class + id + attribute" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create: <input type="text" class="field" id="username">
    const target = try doc.createElement("input");
    try Element.setAttribute(target, "type", "text");
    try Element.setAttribute(target, "class", "field");
    try Element.setAttribute(target, "id", "username");
    _ = try container.appendChild(target);

    // Create: <input type="text" class="field" id="password">
    const input2 = try doc.createElement("input");
    try Element.setAttribute(input2, "type", "text");
    try Element.setAttribute(input2, "class", "field");
    try Element.setAttribute(input2, "id", "password");
    _ = try container.appendChild(input2);

    // Should match: all conditions must match
    const result = try Element.querySelector(container, "input.field#username[type='text']");
    try testing.expect(result != null);
    try testing.expect(result.? == target);
}

test "compound selector: no match when any component fails" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create: <div class="widget" id="main"></div>
    const div = try doc.createElement("div");
    try Element.setAttribute(div, "class", "widget");
    try Element.setAttribute(div, "id", "main");
    _ = try container.appendChild(div);

    // Should NOT match: wrong tag
    const result1 = try Element.querySelector(container, "span.widget#main");
    try testing.expect(result1 == null);

    // Should NOT match: wrong class
    const result2 = try Element.querySelector(container, "div.other#main");
    try testing.expect(result2 == null);

    // Should NOT match: wrong id
    const result3 = try Element.querySelector(container, "div.widget#other");
    try testing.expect(result3 == null);
}
