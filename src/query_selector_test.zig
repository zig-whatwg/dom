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
    _ = try doc.prototype.appendChild(&div.prototype);

    const result = try div.querySelector(allocator, "div");
    try testing.expect(result == null); // div is not a descendant of itself
}

test "querySelector - finds child element" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try parent.querySelector(allocator, "p");
    try testing.expect(result != null);
    try testing.expect(result.? == child);
}

test "querySelector - class selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("span");
    try child2.setAttribute("class", "highlight");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const result = try parent.querySelector(allocator, ".highlight");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - ID selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("div");
    try child2.setAttribute("id", "main");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const result = try parent.querySelector(allocator, "#main");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - compound selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("p");
    try child1.setAttribute("class", "text");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("p");
    try child2.setAttribute("class", "text highlight");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const result = try parent.querySelector(allocator, "p.highlight");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - child combinator" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&root.prototype);

    const parent = try doc.createElement("div");
    try parent.setAttribute("class", "parent");
    _ = try root.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try root.querySelector(allocator, "div.parent > p");
    try testing.expect(result != null);
    try testing.expect(result.? == child);
}

test "querySelector - returns null when no match" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try parent.querySelector(allocator, "span");
    try testing.expect(result == null);
}

test "querySelectorAll - finds multiple elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const child3 = try doc.createElement("span");
    _ = try parent.prototype.appendChild(&child3.prototype);

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
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child.prototype);

    const results = try parent.querySelectorAll(allocator, "span");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 0), results.len);
}

test "querySelectorAll - with class selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("p");
    try child1.setAttribute("class", "text");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("div");
    try child2.setAttribute("class", "text");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const child3 = try doc.createElement("span");
    _ = try parent.prototype.appendChild(&child3.prototype);

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
    _ = try doc.prototype.appendChild(&root.prototype);

    const child1 = try doc.createElement("p");
    _ = try root.prototype.appendChild(&child1.prototype);

    const grandchild1 = try doc.createElement("span");
    _ = try child1.prototype.appendChild(&grandchild1.prototype);

    const child2 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&child2.prototype);

    const grandchild2 = try doc.createElement("span");
    _ = try child2.prototype.appendChild(&grandchild2.prototype);

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
    _ = try doc.prototype.appendChild(&html.prototype);

    const body = try doc.createElement("body");
    _ = try html.prototype.appendChild(&body.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("class", "btn");
    _ = try body.prototype.appendChild(&button.prototype);

    const result = try doc.querySelector(".btn");
    try testing.expect(result != null);
    try testing.expect(result.? == button);
}

test "Document.querySelectorAll" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&html.prototype);

    const body = try doc.createElement("body");
    _ = try html.prototype.appendChild(&body.prototype);

    const btn1 = try doc.createElement("button");
    _ = try body.prototype.appendChild(&btn1.prototype);

    const btn2 = try doc.createElement("button");
    _ = try body.prototype.appendChild(&btn2.prototype);

    const results = try doc.querySelectorAll("button");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == btn1);
    try testing.expect(results[1] == btn2);
}

test "DocumentFragment.querySelector" {
    const allocator = testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.prototype.release();

    const child1 = try Element.create(allocator, "p");
    _ = try fragment.prototype.appendChild(&child1.prototype);

    const child2 = try Element.create(allocator, "div");
    try child2.setAttribute("class", "target");
    _ = try fragment.prototype.appendChild(&child2.prototype);

    const result = try fragment.querySelector(allocator, ".target");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "DocumentFragment.querySelectorAll" {
    const allocator = testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.prototype.release();

    const child1 = try Element.create(allocator, "p");
    _ = try fragment.prototype.appendChild(&child1.prototype);

    const child2 = try Element.create(allocator, "p");
    _ = try fragment.prototype.appendChild(&child2.prototype);

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
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("input");
    try child1.setAttribute("type", "text");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("input");
    try child2.setAttribute("type", "submit");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const result = try parent.querySelector(allocator, "input[type='submit']");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - :first-child pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("li");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("li");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const result = try parent.querySelector(allocator, "li:first-child");
    try testing.expect(result != null);
    try testing.expect(result.? == child1);
}

test "querySelectorAll - universal selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("span");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const child3 = try doc.createElement("div");
    _ = try parent.prototype.appendChild(&child3.prototype);

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
    defer elem.prototype.release();

    try testing.expect(try elem.matches(allocator, "div"));
    try testing.expect(!try elem.matches(allocator, "span"));
}

test "Element.matches - class selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();
    try elem.setAttribute("class", "container active");

    try testing.expect(try elem.matches(allocator, ".container"));
    try testing.expect(try elem.matches(allocator, ".active"));
    try testing.expect(!try elem.matches(allocator, ".hidden"));
}

test "Element.matches - ID selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();
    try elem.setAttribute("id", "main");

    try testing.expect(try elem.matches(allocator, "#main"));
    try testing.expect(!try elem.matches(allocator, "#other"));
}

test "Element.matches - compound selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "button");
    defer elem.prototype.release();
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
    defer elem.prototype.release();
    try elem.setAttribute("type", "text");
    try elem.setAttribute("required", "");

    try testing.expect(try elem.matches(allocator, "input[type='text']"));
    try testing.expect(try elem.matches(allocator, "input[required]"));
    try testing.expect(!try elem.matches(allocator, "input[type='submit']"));
}

test "Element.matches - universal selector" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try testing.expect(try elem.matches(allocator, "*"));
}

// ============================================================================
// Element.closest() Tests
// ============================================================================

test "Element.closest - matches self" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();
    try elem.setAttribute("class", "container");

    const result = try elem.closest(allocator, ".container");
    try testing.expect(result != null);
    try testing.expect(result.? == elem);
}

test "Element.closest - finds parent" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "form");
    defer parent.prototype.release();
    try parent.setAttribute("class", "login-form");

    const child = try Element.create(allocator, "button");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try child.closest(allocator, "form");
    try testing.expect(result != null);
    try testing.expect(result.? == parent);
}

test "Element.closest - finds ancestor" {
    const allocator = testing.allocator;

    const grandparent = try Element.create(allocator, "article");
    defer grandparent.prototype.release();
    try grandparent.setAttribute("class", "post");

    const parent = try Element.create(allocator, "div");
    _ = try grandparent.prototype.appendChild(&parent.prototype);

    const child = try Element.create(allocator, "span");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try child.closest(allocator, "article.post");
    try testing.expect(result != null);
    try testing.expect(result.? == grandparent);
}

test "Element.closest - returns null when no match" {
    const allocator = testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.prototype.release();

    const child = try Element.create(allocator, "span");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try child.closest(allocator, "form");
    try testing.expect(result == null);
}

test "Element.closest - stops at document" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&div.prototype);

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
    _ = try doc.prototype.appendChild(&form.prototype);

    const fieldset = try doc.createElement("fieldset");
    _ = try form.prototype.appendChild(&fieldset.prototype);

    const input = try doc.createElement("input");
    _ = try fieldset.prototype.appendChild(&input.prototype);

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
    _ = try doc.prototype.appendChild(&list.prototype);

    const item = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item.prototype);

    const link = try doc.createElement("a");
    try link.setAttribute("class", "menu-link");
    _ = try item.prototype.appendChild(&link.prototype);

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

// ============================================================================
// COMBINATOR TESTS - Additional Coverage
// ============================================================================

test "querySelector - descendant combinator (space)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const article = try doc.createElement("article");
    _ = try doc.prototype.appendChild(&article.prototype);

    const header = try doc.createElement("header");
    _ = try article.prototype.appendChild(&header.prototype);

    const h1 = try doc.createElement("h1");
    _ = try header.prototype.appendChild(&h1.prototype);

    const paragraph = try doc.createElement("p");
    _ = try article.prototype.appendChild(&paragraph.prototype);

    // "article h1" should match h1 (descendant, not direct child)
    const result = try article.querySelector(allocator, "article h1");
    try testing.expect(result != null);
    try testing.expect(result.? == h1);

    // "article p" should match paragraph
    const result2 = try article.querySelector(allocator, "article p");
    try testing.expect(result2 != null);
    try testing.expect(result2.? == paragraph);
}

test "querySelector - next sibling combinator (+)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const h1 = try doc.createElement("h1");
    _ = try container.prototype.appendChild(&h1.prototype);

    const p = try doc.createElement("p");
    _ = try container.prototype.appendChild(&p.prototype);

    const span = try doc.createElement("span");
    _ = try container.prototype.appendChild(&span.prototype);

    // "h1 + p" should match p (immediately follows h1)
    const result = try container.querySelector(allocator, "h1 + p");
    try testing.expect(result != null);
    try testing.expect(result.? == p);

    // "p + span" should match span
    const result2 = try container.querySelector(allocator, "p + span");
    try testing.expect(result2 != null);
    try testing.expect(result2.? == span);

    // "h1 + span" should not match (span doesn't immediately follow h1)
    const result3 = try container.querySelector(allocator, "h1 + span");
    try testing.expect(result3 == null);
}

test "querySelector - subsequent sibling combinator (~)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const h1 = try doc.createElement("h1");
    _ = try container.prototype.appendChild(&h1.prototype);

    const p = try doc.createElement("p");
    _ = try container.prototype.appendChild(&p.prototype);

    const span = try doc.createElement("span");
    _ = try container.prototype.appendChild(&span.prototype);

    const div = try doc.createElement("div");
    _ = try container.prototype.appendChild(&div.prototype);

    // "h1 ~ span" should match span (follows h1, not immediately)
    const result = try container.querySelector(allocator, "h1 ~ span");
    try testing.expect(result != null);
    try testing.expect(result.? == span);

    // "h1 ~ div" should match div
    const result2 = try container.querySelector(allocator, "h1 ~ div");
    try testing.expect(result2 != null);
    try testing.expect(result2.? == div);

    // "p ~ span" should match span
    const result3 = try container.querySelector(allocator, "p ~ span");
    try testing.expect(result3 != null);
    try testing.expect(result3.? == span);
}

// ============================================================================
// PSEUDO-CLASS TESTS - Additional Coverage
// ============================================================================

test "querySelector - :last-child pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const list = try doc.createElement("ul");
    _ = try doc.prototype.appendChild(&list.prototype);

    const item1 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item1.prototype);

    const item2 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item2.prototype);

    const item3 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item3.prototype);

    // "li:last-child" should match item3
    const result = try list.querySelector(allocator, "li:last-child");
    try testing.expect(result != null);
    try testing.expect(result.? == item3);
}

test "querySelector - :only-child pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const container1 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&container1.prototype);

    const only = try doc.createElement("p");
    _ = try container1.prototype.appendChild(&only.prototype);

    const container2 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&container2.prototype);

    const p1 = try doc.createElement("p");
    _ = try container2.prototype.appendChild(&p1.prototype);

    const p2 = try doc.createElement("p");
    _ = try container2.prototype.appendChild(&p2.prototype);

    // "p:only-child" should match only
    const result = try doc.querySelector("p:only-child");
    try testing.expect(result != null);
    try testing.expect(result.? == only);
}

test "querySelector - :nth-child(2n) pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const list = try doc.createElement("ul");
    _ = try doc.prototype.appendChild(&list.prototype);

    const item1 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item1.prototype);

    const item2 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item2.prototype);

    const item3 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item3.prototype);

    const item4 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item4.prototype);

    // "li:nth-child(2n)" should match even children (item2, item4)
    const result = try list.querySelector(allocator, "li:nth-child(2n)");
    try testing.expect(result != null);
    try testing.expect(result.? == item2); // First match

    // "li:nth-child(odd)" should match odd children
    const result2 = try list.querySelector(allocator, "li:nth-child(odd)");
    try testing.expect(result2 != null);
    try testing.expect(result2.? == item1);
}

test "querySelector - :nth-child(3) pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const list = try doc.createElement("ul");
    _ = try doc.prototype.appendChild(&list.prototype);

    const item1 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item1.prototype);

    const item2 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item2.prototype);

    const item3 = try doc.createElement("li");
    _ = try list.prototype.appendChild(&item3.prototype);

    // "li:nth-child(3)" should match third child
    const result = try list.querySelector(allocator, "li:nth-child(3)");
    try testing.expect(result != null);
    try testing.expect(result.? == item3);
}

test "querySelector - :not() pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const p1 = try doc.createElement("p");
    try p1.setAttribute("class", "intro");
    _ = try container.prototype.appendChild(&p1.prototype);

    const p2 = try doc.createElement("p");
    _ = try container.prototype.appendChild(&p2.prototype);

    const p3 = try doc.createElement("p");
    try p3.setAttribute("class", "intro");
    _ = try container.prototype.appendChild(&p3.prototype);

    // "p:not(.intro)" should match p2
    const result = try container.querySelector(allocator, "p:not(.intro)");
    try testing.expect(result != null);
    try testing.expect(result.? == p2);
}

test "querySelector - :empty pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const empty = try doc.createElement("p");
    _ = try container.prototype.appendChild(&empty.prototype);

    const not_empty = try doc.createElement("p");
    const text = try doc.createTextNode("content");
    _ = try not_empty.prototype.appendChild(&text.prototype);
    _ = try container.prototype.appendChild(&not_empty.prototype);

    // "p:empty" should match empty
    const result = try container.querySelector(allocator, "p:empty");
    try testing.expect(result != null);
    try testing.expect(result.? == empty);
}

// ============================================================================
// ATTRIBUTE SELECTOR TESTS - Additional Coverage
// ============================================================================

test "querySelector - attribute prefix selector [attr^=value]" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const link1 = try doc.createElement("a");
    try link1.setAttribute("href", "https://example.com");
    _ = try container.prototype.appendChild(&link1.prototype);

    const link2 = try doc.createElement("a");
    try link2.setAttribute("href", "http://example.com");
    _ = try container.prototype.appendChild(&link2.prototype);

    const link3 = try doc.createElement("a");
    try link3.setAttribute("href", "/local/path");
    _ = try container.prototype.appendChild(&link3.prototype);

    // "a[href^='https']" should match link1
    const result = try container.querySelector(allocator, "a[href^='https']");
    try testing.expect(result != null);
    try testing.expect(result.? == link1);

    // "a[href^='/']" should match link3
    const result2 = try container.querySelector(allocator, "a[href^='/']");
    try testing.expect(result2 != null);
    try testing.expect(result2.? == link3);
}

test "querySelector - attribute suffix selector [attr$=value]" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const img1 = try doc.createElement("img");
    try img1.setAttribute("src", "photo.jpg");
    _ = try container.prototype.appendChild(&img1.prototype);

    const img2 = try doc.createElement("img");
    try img2.setAttribute("src", "icon.png");
    _ = try container.prototype.appendChild(&img2.prototype);

    const img3 = try doc.createElement("img");
    try img3.setAttribute("src", "logo.svg");
    _ = try container.prototype.appendChild(&img3.prototype);

    // "img[src$='.png']" should match img2
    const result = try container.querySelector(allocator, "img[src$='.png']");
    try testing.expect(result != null);
    try testing.expect(result.? == img2);
}

test "querySelector - attribute contains selector [attr*=value]" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const div1 = try doc.createElement("div");
    try div1.setAttribute("class", "btn btn-primary active");
    _ = try container.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("div");
    try div2.setAttribute("class", "button");
    _ = try container.prototype.appendChild(&div2.prototype);

    // "[class*='primary']" should match div1
    const result = try container.querySelector(allocator, "[class*='primary']");
    try testing.expect(result != null);
    try testing.expect(result.? == div1);
}

// ============================================================================
// ADVANCED PSEUDO-CLASS TESTS
// ============================================================================

test "querySelector - :is() pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const h1 = try doc.createElement("h1");
    _ = try container.prototype.appendChild(&h1.prototype);

    const h2 = try doc.createElement("h2");
    _ = try container.prototype.appendChild(&h2.prototype);

    const p = try doc.createElement("p");
    _ = try container.prototype.appendChild(&p.prototype);

    // ":is(h1, h2)" should match h1 (first heading)
    const result = try container.querySelector(allocator, ":is(h1, h2)");
    try testing.expect(result != null);
    try testing.expect(result.? == h1);
}

test "querySelector - :where() pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const p1 = try doc.createElement("p");
    try p1.setAttribute("class", "intro");
    _ = try container.prototype.appendChild(&p1.prototype);

    const div1 = try doc.createElement("div");
    try div1.setAttribute("class", "intro");
    _ = try container.prototype.appendChild(&div1.prototype);

    // ":where(p, div).intro" should match p1
    const result = try container.querySelector(allocator, ":where(p, div).intro");
    try testing.expect(result != null);
    try testing.expect(result.? == p1);
}

test "querySelector - :has() relational pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const section1 = try doc.createElement("section");
    _ = try container.prototype.appendChild(&section1.prototype);

    const h2 = try doc.createElement("h2");
    _ = try section1.prototype.appendChild(&h2.prototype);

    const section2 = try doc.createElement("section");
    _ = try container.prototype.appendChild(&section2.prototype);

    const p = try doc.createElement("p");
    _ = try section2.prototype.appendChild(&p.prototype);

    // "section:has(h2)" should match section1
    const result = try container.querySelector(allocator, "section:has(h2)");
    try testing.expect(result != null);
    try testing.expect(result.? == section1);
}
