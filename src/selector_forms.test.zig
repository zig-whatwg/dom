const std = @import("std");
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const Node = @import("node.zig").Node;
const selector = @import("selector.zig");
const testing = std.testing;

// ============================================================================
// Form State Pseudo-class Tests
// ============================================================================
// Tests for CSS form state pseudo-classes:
//   :enabled, :disabled, :checked, :indeterminate
//   :required, :optional, :valid, :invalid
//   :read-only, :read-write
//
// Session 7 - Adding comprehensive form selector support
// ============================================================================

// ----------------------------------------------------------------------------
// :enabled and :disabled Tests
// ----------------------------------------------------------------------------

test ":enabled matches enabled input elements" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    _ = try doc.node.appendChild(input);

    // Input without disabled attribute should match :enabled
    try testing.expect(try selector.matches(input, ":enabled", allocator));
    try testing.expect(!try selector.matches(input, ":disabled", allocator));
}

test ":disabled matches disabled input elements" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    try Element.setAttribute(input, "disabled", "");
    _ = try doc.node.appendChild(input);

    // Input with disabled attribute should match :disabled
    try testing.expect(try selector.matches(input, ":disabled", allocator));
    try testing.expect(!try selector.matches(input, ":enabled", allocator));
}

test ":enabled/:disabled match various form elements" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Test button
    const button = try doc.createElement("button");
    try Element.setAttribute(button, "disabled", "");
    _ = try doc.node.appendChild(button);
    try testing.expect(try selector.matches(button, ":disabled", allocator));

    // Test select
    const select_elem = try doc.createElement("select");
    _ = try doc.node.appendChild(select_elem);
    try testing.expect(try selector.matches(select_elem, ":enabled", allocator));

    // Test textarea
    const textarea = try doc.createElement("textarea");
    try Element.setAttribute(textarea, "disabled", "");
    _ = try doc.node.appendChild(textarea);
    try testing.expect(try selector.matches(textarea, ":disabled", allocator));
}

test ":enabled/:disabled only match form elements" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "disabled", "");
    _ = try doc.node.appendChild(div);

    // div is not a form element, should not match
    try testing.expect(!try selector.matches(div, ":disabled", allocator));
    try testing.expect(!try selector.matches(div, ":enabled", allocator));
}

// ----------------------------------------------------------------------------
// :checked and :indeterminate Tests
// ----------------------------------------------------------------------------

test ":checked matches checked checkboxes" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const checkbox = try doc.createElement("input");
    try Element.setAttribute(checkbox, "type", "checkbox");
    try Element.setAttribute(checkbox, "data-checked", "true");
    _ = try doc.node.appendChild(checkbox);

    try testing.expect(try selector.matches(checkbox, ":checked", allocator));
}

test ":checked matches checked radios" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const radio = try doc.createElement("input");
    try Element.setAttribute(radio, "type", "radio");
    try Element.setAttribute(radio, "data-checked", "true");
    _ = try doc.node.appendChild(radio);

    try testing.expect(try selector.matches(radio, ":checked", allocator));
}

test ":checked does not match unchecked inputs" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const checkbox = try doc.createElement("input");
    try Element.setAttribute(checkbox, "type", "checkbox");
    try Element.setAttribute(checkbox, "data-checked", "false");
    _ = try doc.node.appendChild(checkbox);

    try testing.expect(!try selector.matches(checkbox, ":checked", allocator));
}

test ":indeterminate matches indeterminate checkboxes" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const checkbox = try doc.createElement("input");
    try Element.setAttribute(checkbox, "type", "checkbox");
    try Element.setAttribute(checkbox, "data-indeterminate", "true");
    _ = try doc.node.appendChild(checkbox);

    try testing.expect(try selector.matches(checkbox, ":indeterminate", allocator));
}

test ":checked/:indeterminate only match input elements" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "data-checked", "true");
    _ = try doc.node.appendChild(div);

    try testing.expect(!try selector.matches(div, ":checked", allocator));
}

// ----------------------------------------------------------------------------
// :required and :optional Tests
// ----------------------------------------------------------------------------

test ":required matches required input elements" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    try Element.setAttribute(input, "required", "");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":required", allocator));
    try testing.expect(!try selector.matches(input, ":optional", allocator));
}

test ":optional matches non-required elements" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":optional", allocator));
    try testing.expect(!try selector.matches(input, ":required", allocator));
}

test ":required/:optional match various form fields" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Test select
    const select_elem = try doc.createElement("select");
    try Element.setAttribute(select_elem, "required", "");
    _ = try doc.node.appendChild(select_elem);
    try testing.expect(try selector.matches(select_elem, ":required", allocator));

    // Test textarea
    const textarea = try doc.createElement("textarea");
    _ = try doc.node.appendChild(textarea);
    try testing.expect(try selector.matches(textarea, ":optional", allocator));
}

test ":required/:optional only match input/select/textarea" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "required", "");
    _ = try doc.node.appendChild(button);

    // button is not input/select/textarea, should not match
    try testing.expect(!try selector.matches(button, ":required", allocator));
    try testing.expect(!try selector.matches(button, ":optional", allocator));
}

// ----------------------------------------------------------------------------
// :valid and :invalid Tests
// ----------------------------------------------------------------------------

test ":valid matches valid form fields" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "email");
    try Element.setAttribute(input, "data-valid", "true");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":valid", allocator));
    try testing.expect(!try selector.matches(input, ":invalid", allocator));
}

test ":invalid matches invalid form fields" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "email");
    try Element.setAttribute(input, "data-valid", "false");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":invalid", allocator));
    try testing.expect(!try selector.matches(input, ":valid", allocator));
}

test ":valid default state for fields without validation" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    _ = try doc.node.appendChild(input);

    // Fields without data-valid attribute are considered valid by default
    try testing.expect(try selector.matches(input, ":valid", allocator));
    try testing.expect(!try selector.matches(input, ":invalid", allocator));
}

test ":valid/:invalid only match form fields" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "data-valid", "false");
    _ = try doc.node.appendChild(div);

    try testing.expect(!try selector.matches(div, ":invalid", allocator));
    try testing.expect(!try selector.matches(div, ":valid", allocator));
}

// ----------------------------------------------------------------------------
// :read-only and :read-write Tests
// ----------------------------------------------------------------------------

test ":read-only matches readonly inputs" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    try Element.setAttribute(input, "readonly", "");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":read-only", allocator));
    try testing.expect(!try selector.matches(input, ":read-write", allocator));
}

test ":read-write matches editable inputs" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":read-write", allocator));
    try testing.expect(!try selector.matches(input, ":read-only", allocator));
}

test ":read-only/:read-write match textarea" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const textarea = try doc.createElement("textarea");
    try Element.setAttribute(textarea, "readonly", "");
    _ = try doc.node.appendChild(textarea);

    try testing.expect(try selector.matches(textarea, ":read-only", allocator));
}

test ":read-only/:read-write only match input/textarea" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const select_elem = try doc.createElement("select");
    try Element.setAttribute(select_elem, "readonly", "");
    _ = try doc.node.appendChild(select_elem);

    // select is not input/textarea, should not match
    try testing.expect(!try selector.matches(select_elem, ":read-only", allocator));
    try testing.expect(!try selector.matches(select_elem, ":read-write", allocator));
}

// ----------------------------------------------------------------------------
// Integration Tests - Complex Combinations
// ----------------------------------------------------------------------------

test "form pseudo-class combinations :required:valid" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "email");
    try Element.setAttribute(input, "required", "");
    try Element.setAttribute(input, "data-valid", "true");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":required:valid", allocator));
}

test "form pseudo-class combinations :enabled:checked" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const checkbox = try doc.createElement("input");
    try Element.setAttribute(checkbox, "type", "checkbox");
    try Element.setAttribute(checkbox, "data-checked", "true");
    _ = try doc.node.appendChild(checkbox);

    try testing.expect(try selector.matches(checkbox, ":enabled:checked", allocator));
}

test "form pseudo-class with :not() - :not(:disabled)" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":not(:disabled)", allocator));
}

test "form pseudo-class with :not() - :not(:required)" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":not(:required)", allocator));
}

test "multiple form states combined" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "email");
    try Element.setAttribute(input, "required", "");
    try Element.setAttribute(input, "data-valid", "true");
    _ = try doc.node.appendChild(input);

    // Should match multiple combined states
    try testing.expect(try selector.matches(input, ":required:valid:enabled", allocator));
}
