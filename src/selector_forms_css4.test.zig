const std = @import("std");
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const Node = @import("node.zig").Node;
const selector = @import("selector.zig");
const testing = std.testing;

// ============================================================================
// CSS4 Form Validation Pseudo-class Tests
// ============================================================================
// Tests for additional CSS4 form validation pseudo-classes:
//   :in-range, :out-of-range
//   :placeholder-shown
//   :default
//
// Session 8 - Adding CSS4 form validation selector support
// ============================================================================

// ----------------------------------------------------------------------------
// :in-range and :out-of-range Tests
// ----------------------------------------------------------------------------

test "selector :in-range matches number input within range" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "number");
    try Element.setAttribute(input, "min", "0");
    try Element.setAttribute(input, "max", "100");
    try Element.setAttribute(input, "data-in-range", "true");

    try testing.expect(try selector.matches(input, "input:in-range", allocator));
    try testing.expect(!try selector.matches(input, "input:out-of-range", allocator));
}

test "selector :out-of-range matches number input outside range" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "number");
    try Element.setAttribute(input, "min", "0");
    try Element.setAttribute(input, "max", "100");
    try Element.setAttribute(input, "data-in-range", "false");

    try testing.expect(!try selector.matches(input, "input:in-range", allocator));
    try testing.expect(try selector.matches(input, "input:out-of-range", allocator));
}

test "selector :in-range supports range input type" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "range");
    try Element.setAttribute(input, "min", "0");
    try Element.setAttribute(input, "max", "100");
    try Element.setAttribute(input, "data-in-range", "true");

    try testing.expect(try selector.matches(input, ":in-range", allocator));
}

test "selector :in-range supports date input type" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "date");
    try Element.setAttribute(input, "min", "2024-01-01");
    try Element.setAttribute(input, "max", "2024-12-31");
    try Element.setAttribute(input, "data-in-range", "true");

    try testing.expect(try selector.matches(input, ":in-range", allocator));
}

test "selector :in-range does not match text inputs" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "text");
    try Element.setAttribute(input, "data-in-range", "true");

    try testing.expect(!try selector.matches(input, ":in-range", allocator));
}

test "selector :in-range does not match non-input elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.release();
    try Element.setAttribute(div, "data-in-range", "true");

    try testing.expect(!try selector.matches(div, ":in-range", allocator));
}

test "selector :in-range defaults to true when constraints exist" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "number");
    try Element.setAttribute(input, "min", "0");
    try Element.setAttribute(input, "max", "100");
    // No data-in-range attribute - should default to true

    try testing.expect(try selector.matches(input, ":in-range", allocator));
}

test "selector :in-range returns false when no constraints" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "number");
    // No min/max attributes

    try testing.expect(!try selector.matches(input, ":in-range", allocator));
}

test "selector :in-range case-insensitive type matching" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("INPUT");
    defer input.release();
    try Element.setAttribute(input, "type", "number");
    try Element.setAttribute(input, "min", "0");
    try Element.setAttribute(input, "data-in-range", "true");

    try testing.expect(try selector.matches(input, ":in-range", allocator));
}

// ----------------------------------------------------------------------------
// :placeholder-shown Tests
// ----------------------------------------------------------------------------

test "selector :placeholder-shown matches input with visible placeholder" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "placeholder", "Enter text...");
    try Element.setAttribute(input, "data-placeholder-shown", "true");

    try testing.expect(try selector.matches(input, ":placeholder-shown", allocator));
}

test "selector :placeholder-shown does not match input with value" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "placeholder", "Enter text...");
    try Element.setAttribute(input, "data-placeholder-shown", "false");

    try testing.expect(!try selector.matches(input, ":placeholder-shown", allocator));
}

test "selector :placeholder-shown defaults based on value" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Input with placeholder but no value - placeholder shown
    const input1 = try doc.createElement("input");
    defer input1.release();
    try Element.setAttribute(input1, "placeholder", "Enter text...");
    try testing.expect(try selector.matches(input1, ":placeholder-shown", allocator));

    // Input with placeholder and value - placeholder not shown
    const input2 = try doc.createElement("input");
    defer input2.release();
    try Element.setAttribute(input2, "placeholder", "Enter text...");
    try Element.setAttribute(input2, "value", "some text");
    try testing.expect(!try selector.matches(input2, ":placeholder-shown", allocator));
}

test "selector :placeholder-shown requires placeholder attribute" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "data-placeholder-shown", "true");
    // No placeholder attribute

    try testing.expect(!try selector.matches(input, ":placeholder-shown", allocator));
}

test "selector :placeholder-shown supports textarea" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const textarea = try doc.createElement("textarea");
    defer textarea.release();
    try Element.setAttribute(textarea, "placeholder", "Enter description...");
    try Element.setAttribute(textarea, "data-placeholder-shown", "true");

    try testing.expect(try selector.matches(textarea, "textarea:placeholder-shown", allocator));
}

test "selector :placeholder-shown does not match non-input elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.release();
    try Element.setAttribute(div, "placeholder", "text");
    try Element.setAttribute(div, "data-placeholder-shown", "true");

    try testing.expect(!try selector.matches(div, ":placeholder-shown", allocator));
}

test "selector :placeholder-shown case-insensitive matching" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("INPUT");
    defer input.release();
    try Element.setAttribute(input, "placeholder", "Enter text...");
    try Element.setAttribute(input, "data-placeholder-shown", "true");

    try testing.expect(try selector.matches(input, ":placeholder-shown", allocator));
}

// ----------------------------------------------------------------------------
// :default Tests
// ----------------------------------------------------------------------------

test "selector :default matches default submit button" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    defer button.release();
    try Element.setAttribute(button, "type", "submit");
    try Element.setAttribute(button, "data-default", "true");

    try testing.expect(try selector.matches(button, "button:default", allocator));
}

test "selector :default does not match non-default button" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    defer button.release();
    try Element.setAttribute(button, "type", "submit");
    try Element.setAttribute(button, "data-default", "false");

    try testing.expect(!try selector.matches(button, "button:default", allocator));
}

test "selector :default matches submit input" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "submit");
    try Element.setAttribute(input, "data-default", "true");

    try testing.expect(try selector.matches(input, ":default", allocator));
}

test "selector :default matches image input" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "image");
    try Element.setAttribute(input, "data-default", "true");

    try testing.expect(try selector.matches(input, ":default", allocator));
}

test "selector :default matches checked radio with checked attribute" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const radio = try doc.createElement("input");
    defer radio.release();
    try Element.setAttribute(radio, "type", "radio");
    try Element.setAttribute(radio, "checked", "");

    try testing.expect(try selector.matches(radio, ":default", allocator));
}

test "selector :default matches checked checkbox with checked attribute" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const checkbox = try doc.createElement("input");
    defer checkbox.release();
    try Element.setAttribute(checkbox, "type", "checkbox");
    try Element.setAttribute(checkbox, "checked", "checked");

    try testing.expect(try selector.matches(checkbox, ":default", allocator));
}

test "selector :default does not match unchecked radio" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const radio = try doc.createElement("input");
    defer radio.release();
    try Element.setAttribute(radio, "type", "radio");
    // No checked attribute

    try testing.expect(!try selector.matches(radio, ":default", allocator));
}

test "selector :default matches selected option" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const option = try doc.createElement("option");
    defer option.release();
    try Element.setAttribute(option, "selected", "");

    try testing.expect(try selector.matches(option, "option:default", allocator));
}

test "selector :default does not match unselected option" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const option = try doc.createElement("option");
    defer option.release();
    // No selected attribute

    try testing.expect(!try selector.matches(option, ":default", allocator));
}

test "selector :default does not match button with type=button" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    defer button.release();
    try Element.setAttribute(button, "type", "button");
    try Element.setAttribute(button, "data-default", "true");

    try testing.expect(!try selector.matches(button, ":default", allocator));
}

test "selector :default does not match non-form elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.release();
    try Element.setAttribute(div, "data-default", "true");

    try testing.expect(!try selector.matches(div, ":default", allocator));
}

test "selector :default case-insensitive type matching" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const button = try doc.createElement("BUTTON");
    defer button.release();
    try Element.setAttribute(button, "type", "submit");
    try Element.setAttribute(button, "data-default", "true");

    try testing.expect(try selector.matches(button, ":default", allocator));
}

// ----------------------------------------------------------------------------
// Combined Selector Tests
// ----------------------------------------------------------------------------

test "selector combines :in-range with other selectors" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "number");
    try Element.setAttribute(input, "class", "price");
    try Element.setAttribute(input, "min", "0");
    try Element.setAttribute(input, "data-in-range", "true");

    try testing.expect(try selector.matches(input, "input.price:in-range", allocator));
    try testing.expect(try selector.matches(input, ".price:in-range", allocator));
    try testing.expect(try selector.matches(input, "[type=number]:in-range", allocator));
}

test "selector combines :placeholder-shown with other selectors" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "email");
    try Element.setAttribute(input, "id", "user-email");
    try Element.setAttribute(input, "placeholder", "Enter email...");
    try Element.setAttribute(input, "data-placeholder-shown", "true");

    try testing.expect(try selector.matches(input, "input#user-email:placeholder-shown", allocator));
    try testing.expect(try selector.matches(input, "#user-email:placeholder-shown", allocator));
    try testing.expect(try selector.matches(input, "[type=email]:placeholder-shown", allocator));
}

test "selector combines :default with other selectors" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    defer button.release();
    try Element.setAttribute(button, "type", "submit");
    try Element.setAttribute(button, "class", "primary");
    try Element.setAttribute(button, "data-default", "true");

    try testing.expect(try selector.matches(button, "button.primary:default", allocator));
    try testing.expect(try selector.matches(button, ".primary:default", allocator));
    try testing.expect(try selector.matches(button, "[type=submit]:default", allocator));
}

test "selector :not() with new form selectors" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Input NOT in range
    const input = try doc.createElement("input");
    defer input.release();
    try Element.setAttribute(input, "type", "number");
    try Element.setAttribute(input, "min", "0");
    try Element.setAttribute(input, "data-in-range", "false");

    try testing.expect(try selector.matches(input, "input:not(:in-range)", allocator));

    // Input NOT showing placeholder
    const input2 = try doc.createElement("input");
    defer input2.release();
    try Element.setAttribute(input2, "placeholder", "text");
    try Element.setAttribute(input2, "value", "content");

    try testing.expect(try selector.matches(input2, "input:not(:placeholder-shown)", allocator));
}
