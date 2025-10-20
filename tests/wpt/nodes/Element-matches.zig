// META: title=Test for Element.matches

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "Element.matches with type selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const select = try doc.createElement("select");
    _ = try doc.prototype.appendChild(&select.prototype);

    try std.testing.expect(try select.matches(allocator, "select"));
    try std.testing.expect(!try select.matches(allocator, "form"));
}

test "Element.matches with ID selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    try elem.setAttribute("id", "test-id");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, "#test-id"));
    try std.testing.expect(!try elem.matches(allocator, "#other-id"));
}

test "Element.matches with class selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    try elem.setAttribute("class", "foo bar");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, ".foo"));
    try std.testing.expect(try elem.matches(allocator, ".bar"));
    try std.testing.expect(!try elem.matches(allocator, ".baz"));
}

test "Element.matches with multiple classes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    try elem.setAttribute("class", "alpha beta gamma");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, ".alpha.beta"));
    try std.testing.expect(try elem.matches(allocator, ".beta.gamma"));
    try std.testing.expect(try elem.matches(allocator, ".alpha.beta.gamma"));
    try std.testing.expect(!try elem.matches(allocator, ".alpha.delta"));
}

test "Element.matches with attribute selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("input");
    try elem.setAttribute("type", "text");
    try elem.setAttribute("required", "");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, "[type]"));
    try std.testing.expect(try elem.matches(allocator, "[type='text']"));
    try std.testing.expect(try elem.matches(allocator, "[required]"));
    try std.testing.expect(!try elem.matches(allocator, "[disabled]"));
}

test "Element.matches with attribute value selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    try elem.setAttribute("data-value", "foo");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, "[data-value='foo']"));
    try std.testing.expect(!try elem.matches(allocator, "[data-value='bar']"));
}

test "Element.matches with combined selectors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("button");
    try elem.setAttribute("id", "submit-btn");
    try elem.setAttribute("class", "primary active");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, "button#submit-btn"));
    try std.testing.expect(try elem.matches(allocator, "button.primary"));
    try std.testing.expect(try elem.matches(allocator, "button.primary.active"));
    try std.testing.expect(try elem.matches(allocator, "#submit-btn.primary"));
    try std.testing.expect(!try elem.matches(allocator, "container.primary"));
}

test "Element.matches with universal selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("anything");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, "*"));
}

test "Element.matches with descendant combinator" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create parent > child structure
    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    // Descendant combinator: child IS a descendant of parent, so should match
    try std.testing.expect(try child.matches(allocator, "parent child"));

    // Simple selector also works
    try std.testing.expect(try child.matches(allocator, "child"));

    // Wrong parent should not match
    try std.testing.expect(!try child.matches(allocator, "wrongparent child"));
}

test "Element.matches with child combinator" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    // Child combinator: child IS a direct child of parent, so should match
    try std.testing.expect(try child.matches(allocator, "parent > child"));

    // Simple selector also works
    try std.testing.expect(try child.matches(allocator, "child"));

    // Wrong parent should not match
    try std.testing.expect(!try child.matches(allocator, "wrongparent > child"));
}

test "Element.matches with :not() pseudo-class" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    try elem.setAttribute("class", "active");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, "container:not(.disabled)"));
    try std.testing.expect(!try elem.matches(allocator, "container:not(.active)"));
}

test "Element.matches is case-sensitive for classes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    try elem.setAttribute("class", "Foo");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, ".Foo"));
    try std.testing.expect(!try elem.matches(allocator, ".foo"));
}

test "Element.matches with selector list (comma)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("button");
    try elem.setAttribute("class", "primary");
    _ = try doc.prototype.appendChild(&elem.prototype);

    // Should match if ANY selector in list matches
    try std.testing.expect(try elem.matches(allocator, "input, button"));
    try std.testing.expect(try elem.matches(allocator, ".primary, .secondary"));
    try std.testing.expect(try elem.matches(allocator, "select, .primary"));
    try std.testing.expect(!try elem.matches(allocator, "input, select"));
}

test "Element.matches with empty selector fails" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&elem.prototype);

    // Empty selector should error
    try std.testing.expectError(error.InvalidSelector, elem.matches(allocator, ""));
}

test "Element.matches with whitespace-only selector fails" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&elem.prototype);

    // Whitespace-only selector should error
    try std.testing.expectError(error.InvalidSelector, elem.matches(allocator, "   "));
}

test "Element.matches with invalid selector fails" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&elem.prototype);

    // Invalid selector syntax should error (UnexpectedToken is the specific error returned)
    try std.testing.expectError(error.UnexpectedToken, elem.matches(allocator, "###"));
}

test "Element.matches without ID attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(!try elem.matches(allocator, "#some-id"));
}

test "Element.matches without class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(!try elem.matches(allocator, ".some-class"));
}

test "Element.matches with complex attribute selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    try elem.setAttribute("data-value", "test123");
    _ = try doc.prototype.appendChild(&elem.prototype);

    // Exact match
    try std.testing.expect(try elem.matches(allocator, "[data-value='test123']"));

    // Wrong value
    try std.testing.expect(!try elem.matches(allocator, "[data-value='wrong']"));
}

test "Element.matches returns false for non-matching type" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("button");
    _ = try doc.prototype.appendChild(&elem.prototype);

    try std.testing.expect(try elem.matches(allocator, "button"));
    try std.testing.expect(!try elem.matches(allocator, "input"));
    try std.testing.expect(!try elem.matches(allocator, "select"));
    try std.testing.expect(!try elem.matches(allocator, "container"));
}
