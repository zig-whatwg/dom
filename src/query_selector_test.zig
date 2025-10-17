//! Query Selector Tests
//!
//! Comprehensive tests for querySelector and querySelectorAll implementation.

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const DocumentFragment = @import("document_fragment.zig").DocumentFragment;

test "querySelector - simple type selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(&div.node);

    const result = try div.querySelector(allocator, "div");
    try testing.expect(result == null); // div is not a descendant of itself
}

test "querySelector - finds child element" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child = try doc.createElement("p");
    _ = try parent.node.appendChild(&child.node);

    const result = try parent.querySelector(allocator, "p");
    try testing.expect(result != null);
    try testing.expect(result.? == child);
}

test "querySelector - class selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("span");
    try child2.setAttribute("class", "highlight");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, ".highlight");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - ID selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("div");
    try child2.setAttribute("id", "main");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, "#main");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - compound selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    try child1.setAttribute("class", "text");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("p");
    try child2.setAttribute("class", "text highlight");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, "p.highlight");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - child combinator" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    const parent = try doc.createElement("div");
    try parent.setAttribute("class", "parent");
    _ = try root.node.appendChild(&parent.node);

    const child = try doc.createElement("p");
    _ = try parent.node.appendChild(&child.node);

    const result = try root.querySelector(allocator, "div.parent > p");
    try testing.expect(result != null);
    try testing.expect(result.? == child);
}

test "querySelector - returns null when no match" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child = try doc.createElement("p");
    _ = try parent.node.appendChild(&child.node);

    const result = try parent.querySelector(allocator, "span");
    try testing.expect(result == null);
}

test "querySelectorAll - finds multiple elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child2.node);

    const child3 = try doc.createElement("span");
    _ = try parent.node.appendChild(&child3.node);

    const results = try parent.querySelectorAll(allocator, "p");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == child1);
    try testing.expect(results[1] == child2);
}

test "querySelectorAll - returns empty array when no match" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child = try doc.createElement("p");
    _ = try parent.node.appendChild(&child.node);

    const results = try parent.querySelectorAll(allocator, "span");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 0), results.len);
}

test "querySelectorAll - with class selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    try child1.setAttribute("class", "text");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("div");
    try child2.setAttribute("class", "text");
    _ = try parent.node.appendChild(&child2.node);

    const child3 = try doc.createElement("span");
    _ = try parent.node.appendChild(&child3.node);

    const results = try parent.querySelectorAll(allocator, ".text");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == child1);
    try testing.expect(results[1] == child2);
}

test "querySelectorAll - finds nested elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    const child1 = try doc.createElement("p");
    _ = try root.node.appendChild(&child1.node);

    const grandchild1 = try doc.createElement("span");
    _ = try child1.node.appendChild(&grandchild1.node);

    const child2 = try doc.createElement("div");
    _ = try root.node.appendChild(&child2.node);

    const grandchild2 = try doc.createElement("span");
    _ = try child2.node.appendChild(&grandchild2.node);

    const results = try root.querySelectorAll(allocator, "span");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == grandchild1);
    try testing.expect(results[1] == grandchild2);
}

test "Document.querySelector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.node.appendChild(&html.node);

    const body = try doc.createElement("body");
    _ = try html.node.appendChild(&body.node);

    const button = try doc.createElement("button");
    try button.setAttribute("class", "btn");
    _ = try body.node.appendChild(&button.node);

    const result = try doc.querySelector(".btn");
    try testing.expect(result != null);
    try testing.expect(result.? == button);
}

test "Document.querySelectorAll" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.node.appendChild(&html.node);

    const body = try doc.createElement("body");
    _ = try html.node.appendChild(&body.node);

    const btn1 = try doc.createElement("button");
    _ = try body.node.appendChild(&btn1.node);

    const btn2 = try doc.createElement("button");
    _ = try body.node.appendChild(&btn2.node);

    const results = try doc.querySelectorAll("button");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == btn1);
    try testing.expect(results[1] == btn2);
}

test "DocumentFragment.querySelector" {
    const allocator = testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.node.release();

    const child1 = try Element.create(allocator, "p");
    _ = try fragment.node.appendChild(&child1.node);

    const child2 = try Element.create(allocator, "div");
    try child2.setAttribute("class", "target");
    _ = try fragment.node.appendChild(&child2.node);

    const result = try fragment.querySelector(allocator, ".target");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "DocumentFragment.querySelectorAll" {
    const allocator = testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.node.release();

    const child1 = try Element.create(allocator, "p");
    _ = try fragment.node.appendChild(&child1.node);

    const child2 = try Element.create(allocator, "p");
    _ = try fragment.node.appendChild(&child2.node);

    const results = try fragment.querySelectorAll(allocator, "p");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == child1);
    try testing.expect(results[1] == child2);
}

test "querySelector - attribute selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("input");
    try child1.setAttribute("type", "text");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("input");
    try child2.setAttribute("type", "submit");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, "input[type='submit']");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - :first-child pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("li");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("li");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, "li:first-child");
    try testing.expect(result != null);
    try testing.expect(result.? == child1);
}

test "querySelectorAll - universal selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("span");
    _ = try parent.node.appendChild(&child2.node);

    const child3 = try doc.createElement("div");
    _ = try parent.node.appendChild(&child3.node);

    const results = try parent.querySelectorAll(allocator, "*");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 3), results.len);
}

// ============================================================================
// Element.matches() Tests
// ============================================================================

test "Element.matches - type selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    try testing.expect(try elem.matches(allocator, "div"));
    try testing.expect(!try elem.matches(allocator, "span"));
}

test "Element.matches - class selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();
    try elem.setAttribute("class", "container active");

    try testing.expect(try elem.matches(allocator, ".container"));
    try testing.expect(try elem.matches(allocator, ".active"));
    try testing.expect(!try elem.matches(allocator, ".hidden"));
}

test "Element.matches - ID selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();
    try elem.setAttribute("id", "main");

    try testing.expect(try elem.matches(allocator, "#main"));
    try testing.expect(!try elem.matches(allocator, "#other"));
}

test "Element.matches - compound selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "button");
    defer elem.node.release();
    try elem.setAttribute("class", "btn primary");
    try elem.setAttribute("type", "submit");

    try testing.expect(try elem.matches(allocator, "button.btn"));
    try testing.expect(try elem.matches(allocator, "button.primary"));
    try testing.expect(try elem.matches(allocator, "button.btn.primary"));
    try testing.expect(!try elem.matches(allocator, "button.secondary"));
}

test "Element.matches - attribute selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "input");
    defer elem.node.release();
    try elem.setAttribute("type", "text");
    try elem.setAttribute("required", "");

    try testing.expect(try elem.matches(allocator, "input[type='text']"));
    try testing.expect(try elem.matches(allocator, "input[required]"));
    try testing.expect(!try elem.matches(allocator, "input[type='submit']"));
}

test "Element.matches - universal selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    try testing.expect(try elem.matches(allocator, "*"));
}

// ============================================================================
// Element.closest() Tests
// ============================================================================

test "Element.closest - matches self" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();
    try elem.setAttribute("class", "container");

    const result = try elem.closest(allocator, ".container");
    try testing.expect(result != null);
    try testing.expect(result.? == elem);
}

test "Element.closest - finds parent" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "form");
    defer parent.node.release();
    try parent.setAttribute("class", "login-form");

    const child = try Element.create(allocator, "button");
    _ = try parent.node.appendChild(&child.node);

    const result = try child.closest(allocator, "form");
    try testing.expect(result != null);
    try testing.expect(result.? == parent);
}

test "Element.closest - finds ancestor" {
    const allocator = testing.allocator;

    const grandparent = try Element.create(allocator, "article");
    defer grandparent.node.release();
    try grandparent.setAttribute("class", "post");

    const parent = try Element.create(allocator, "div");
    _ = try grandparent.node.appendChild(&parent.node);

    const child = try Element.create(allocator, "span");
    _ = try parent.node.appendChild(&child.node);

    const result = try child.closest(allocator, "article.post");
    try testing.expect(result != null);
    try testing.expect(result.? == grandparent);
}

test "Element.closest - returns null when no match" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.node.release();

    const child = try Element.create(allocator, "span");
    _ = try parent.node.appendChild(&child.node);

    const result = try child.closest(allocator, "form");
    try testing.expect(result == null);
}

test "Element.closest - stops at document" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(&div.node);

    // Should not find Document (not an Element)
    const result = try div.closest(allocator, "*");
    try testing.expect(result != null);
    try testing.expect(result.? == div); // Matches self
}

test "Element.closest - with complex selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const form = try doc.createElement("form");
    try form.setAttribute("class", "login");
    try form.setAttribute("method", "POST");
    _ = try doc.node.appendChild(&form.node);

    const fieldset = try doc.createElement("fieldset");
    _ = try form.node.appendChild(&fieldset.node);

    const input = try doc.createElement("input");
    _ = try fieldset.node.appendChild(&input.node);

    const result = try input.closest(allocator, "form.login[method='POST']");
    try testing.expect(result != null);
    try testing.expect(result.? == form);
}

test "Element.matches and Element.closest - event delegation pattern" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const list = try doc.createElement("ul");
    try list.setAttribute("class", "menu");
    _ = try doc.node.appendChild(&list.node);

    const item = try doc.createElement("li");
    _ = try list.node.appendChild(&item.node);

    const link = try doc.createElement("a");
    try link.setAttribute("class", "menu-link");
    _ = try item.node.appendChild(&link.node);

    // Simulate click on link - check if it matches ".menu a"
    // This should match because link is an "a" element with ancestor ".menu"
    const in_menu = try link.matches(allocator, ".menu a");
    try testing.expect(in_menu); // Matches! (link is "a" with ancestor ".menu")

    // Find the containing menu
    const menu = try link.closest(allocator, ".menu");
    try testing.expect(menu != null);
    try testing.expect(menu.? == list);

    // Check if link itself is a menu link
    const is_menu_link = try link.matches(allocator, ".menu-link");
    try testing.expect(is_menu_link);
}
