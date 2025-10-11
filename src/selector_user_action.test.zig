//! Tests for CSS4 User Action Pseudo-Classes
//!
//! Tests selector matching for user action pseudo-classes including:
//! - :hover - Element is being hovered
//! - :active - Element is being activated
//! - :focus - Element has focus
//! - :target - Element is the target of current URL fragment
//!
//! Spec: https://drafts.csswg.org/selectors-4/#useraction-pseudos

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const selector = @import("selector.zig");

test ":hover matches hovered element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "data-hover", "true");
    _ = try doc.node.appendChild(button);

    try testing.expect(try selector.matches(button, ":hover", testing.allocator));
}

test ":hover does not match non-hovered element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "data-hover", "false");
    _ = try doc.node.appendChild(button);

    try testing.expect(!try selector.matches(button, ":hover", testing.allocator));
}

test ":hover without data attribute defaults to false" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const button = try doc.createElement("button");

    _ = try doc.node.appendChild(button);

    try testing.expect(!try selector.matches(button, ":hover", testing.allocator));
}

test ":active matches activated element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "data-active", "true");
    _ = try doc.node.appendChild(button);

    try testing.expect(try selector.matches(button, ":active", testing.allocator));
}

test ":active does not match non-active element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "data-active", "false");
    _ = try doc.node.appendChild(button);

    try testing.expect(!try selector.matches(button, ":active", testing.allocator));
}

test ":focus matches focused element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "data-has-focus", "true");
    _ = try doc.node.appendChild(input);

    try testing.expect(try selector.matches(input, ":focus", testing.allocator));
}

test ":focus does not match non-focused element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "data-has-focus", "false");
    _ = try doc.node.appendChild(input);

    try testing.expect(!try selector.matches(input, ":focus", testing.allocator));
}

test ":target matches target element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const section = try doc.createElement("section");
    try Element.setAttribute(section, "id", "intro");
    try Element.setAttribute(section, "data-target", "true");
    _ = try doc.node.appendChild(section);

    try testing.expect(try selector.matches(section, ":target", testing.allocator));
}

test ":target does not match non-target element" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const section = try doc.createElement("section");
    try Element.setAttribute(section, "id", "intro");
    try Element.setAttribute(section, "data-target", "false");
    _ = try doc.node.appendChild(section);

    try testing.expect(!try selector.matches(section, ":target", testing.allocator));
}

test "complex selector with :hover" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const nav = try doc.createElement("nav");
    _ = try doc.node.appendChild(nav);

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "#");
    try Element.setAttribute(link, "data-hover", "true");
    _ = try nav.appendChild(link);

    try testing.expect(try selector.matches(link, "nav a:hover", testing.allocator));
}

test "multiple user action states" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "data-hover", "true");
    try Element.setAttribute(button, "data-active", "true");
    try Element.setAttribute(button, "data-has-focus", "true");
    _ = try doc.node.appendChild(button);

    try testing.expect(try selector.matches(button, ":hover", testing.allocator));
    try testing.expect(try selector.matches(button, ":active", testing.allocator));
    try testing.expect(try selector.matches(button, ":focus", testing.allocator));
}

test ":hover with class selector" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "class", "primary");
    try Element.setAttribute(button, "data-hover", "true");
    _ = try doc.node.appendChild(button);

    try testing.expect(try selector.matches(button, "button.primary:hover", testing.allocator));
}

test ":active with :not()" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const active = try doc.createElement("div");
    try Element.setAttribute(active, "data-active", "true");
    _ = try doc.node.appendChild(active);

    const inactive = try doc.createElement("div");
    try Element.setAttribute(inactive, "data-active", "false");
    _ = try doc.node.appendChild(inactive);

    try testing.expect(!try selector.matches(active, ":not(:active)", testing.allocator));
    try testing.expect(try selector.matches(inactive, ":not(:active)", testing.allocator));
}

test ":target with :is()" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const section = try doc.createElement("section");
    try Element.setAttribute(section, "id", "target-section");
    try Element.setAttribute(section, "data-target", "true");
    _ = try doc.node.appendChild(section);

    try testing.expect(try selector.matches(section, ":is(section, div):target", testing.allocator));
}

test "querySelector with :hover" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(root);

    const button1 = try doc.createElement("button");
    try Element.setAttribute(button1, "id", "btn1");

    const button2 = try doc.createElement("button");
    try Element.setAttribute(button2, "id", "btn2");
    try Element.setAttribute(button2, "data-hover", "true");

    _ = try root.appendChild(button1);
    _ = try root.appendChild(button2);

    const found = try selector.querySelector(root, ":hover", testing.allocator);
    try testing.expect(found != null);
    try testing.expect(found.? == button2);
}

test "descendant combinator with :hover and :active" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const form = try doc.createElement("form");
    _ = try doc.node.appendChild(form);

    const button = try doc.createElement("button");
    try Element.setAttribute(button, "data-hover", "true");
    try Element.setAttribute(button, "data-active", "true");
    _ = try form.appendChild(button);

    try testing.expect(try selector.matches(button, "form button:hover", testing.allocator));
    try testing.expect(try selector.matches(button, "form button:active", testing.allocator));
    try testing.expect(try selector.matches(button, "form button:hover:active", testing.allocator));
}

test ":focus vs :focus-visible" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    // Element with focus but not visible focus
    const input1 = try doc.createElement("input");
    try Element.setAttribute(input1, "data-has-focus", "true");
    _ = try doc.node.appendChild(input1);

    // Element with visible focus (keyboard)
    const input2 = try doc.createElement("input");
    try Element.setAttribute(input2, "data-has-focus", "true");
    try Element.setAttribute(input2, "data-focus-visible", "true");
    _ = try doc.node.appendChild(input2);

    // Both have :focus
    try testing.expect(try selector.matches(input1, ":focus", testing.allocator));
    try testing.expect(try selector.matches(input2, ":focus", testing.allocator));

    // Only input2 has :focus-visible
    try testing.expect(!try selector.matches(input1, ":focus-visible", testing.allocator));
    try testing.expect(try selector.matches(input2, ":focus-visible", testing.allocator));
}

test ":target with nested elements" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const article = try doc.createElement("article");
    try Element.setAttribute(article, "id", "main-content");
    try Element.setAttribute(article, "data-target", "true");
    _ = try doc.node.appendChild(article);

    const heading = try doc.createElement("h1");

    _ = try article.appendChild(heading);

    // article is the target
    try testing.expect(try selector.matches(article, "article:target", testing.allocator));

    // heading is inside target but not itself a target
    try testing.expect(!try selector.matches(heading, "h1:target", testing.allocator));
}

test "combined user action pseudo-classes" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "#");
    try Element.setAttribute(link, "data-hover", "true");
    try Element.setAttribute(link, "data-has-focus", "true");
    _ = try doc.node.appendChild(link);

    // Multiple pseudo-classes on same element
    try testing.expect(try selector.matches(link, "a:hover:focus", testing.allocator));
    try testing.expect(try selector.matches(link, "a:focus:hover", testing.allocator)); // Order doesn't matter
}

test ":hover with child combinator" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    try Element.setAttribute(parent, "class", "container");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("span");
    try Element.setAttribute(child, "data-hover", "true");
    _ = try parent.appendChild(child);

    try testing.expect(try selector.matches(child, ".container > span:hover", testing.allocator));
}

test ":active on link" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    try Element.setAttribute(link, "data-active", "true");
    _ = try doc.node.appendChild(link);

    try testing.expect(try selector.matches(link, "a:active", testing.allocator));
}
