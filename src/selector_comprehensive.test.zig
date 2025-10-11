//! Comprehensive CSS Selector Test Suite
//!
//! This test suite defines the complete CSS Selectors Level 4 specification
//! that we aim to support. Tests are organized by CSS Selectors Level:
//!
//! - Level 1: Basic selectors (type, class, id)
//! - Level 2: Attribute selectors, pseudo-classes
//! - Level 3: Advanced combinators, structural pseudo-classes
//! - Level 4: Logical combinations, relational pseudo-classes
//!
//! Each test documents the CSS Selectors spec section it implements.

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const Text = @import("text.zig").Text;

// ============================================================================
// CSS Selectors Level 1
// https://www.w3.org/TR/selectors-1/
// ============================================================================

test "CSS Level 1: Type selector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p = try doc.createElement("p");
    const span = try doc.createElement("span");

    _ = try div.appendChild(p);
    _ = try div.appendChild(span);
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    // Should match p element
    const result = try Element.querySelector(div, "p");
    try testing.expect(result != null);
    try testing.expect(result.? == p);
}

test "CSS Level 1: Class selector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "class", "container");

    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, ".container");
    try testing.expect(result != null);
    try testing.expect(result.? == div);
}

test "CSS Level 1: ID selector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "id", "main");

    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "#main");
    try testing.expect(result != null);
    try testing.expect(result.? == div);
}

test "CSS Level 1: Universal selector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p = try doc.createElement("p");
    _ = try div.appendChild(p);

    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const results = try Element.querySelectorAll(div, "*");
    defer {
        results.deinit();
        allocator.destroy(results);
    }

    // Should match both div and p
    try testing.expectEqual(@as(usize, 1), results.length());
}

// ============================================================================
// CSS Selectors Level 2
// https://www.w3.org/TR/selectors-2/
// ============================================================================

test "CSS Level 2: Descendant combinator (space)" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const section = try doc.createElement("section");
    const p = try doc.createElement("p");

    _ = try div.appendChild(section);
    _ = try section.appendChild(p);

    // div p should match p (descendant at any level)
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "div p");
    try testing.expect(result != null);
    try testing.expect(result.? == p);
}

test "CSS Level 2: Child combinator (>)" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p1 = try doc.createElement("p");
    const section = try doc.createElement("section");
    const p2 = try doc.createElement("p");

    _ = try div.appendChild(p1);
    _ = try div.appendChild(section);
    _ = try section.appendChild(p2);

    // div > p should match only p1 (direct child)
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "div > p");
    try testing.expect(result != null);
    try testing.expect(result.? == p1);

    // Should not match p2 (not a direct child of div)
    const all = try Element.querySelectorAll(div, "div > p");
    defer {
        all.deinit();
        allocator.destroy(all);
    }
    try testing.expectEqual(@as(usize, 1), all.length());
}

test "CSS Level 2: Adjacent sibling combinator (+)" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const h1 = try doc.createElement("h1");
    const p = try doc.createElement("p");
    const span = try doc.createElement("span");

    _ = try div.appendChild(h1);
    _ = try div.appendChild(p);
    _ = try div.appendChild(span);

    // h1 + p should match p (immediately follows h1)
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "h1 + p");
    try testing.expect(result != null);
    try testing.expect(result.? == p);

    // h1 + span should not match (not adjacent)
    const no_match = try Element.querySelector(div, "h1 + span");
    try testing.expect(no_match == null);
}

test "CSS Level 2: Attribute presence selector [attr]" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "disabled", "");

    _ = try doc.node.appendChild(input); // Add to document tree for cleanup

    const result = try Element.querySelector(input, "[disabled]");
    try testing.expect(result != null);
    try testing.expect(result.? == input);
}

test "CSS Level 2: Attribute equals selector [attr=value]" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "text");

    _ = try doc.node.appendChild(input); // Add to document tree for cleanup

    const result = try Element.querySelector(input, "[type=\"text\"]");
    try testing.expect(result != null);
    try testing.expect(result.? == input);

    // Should not match different value
    const no_match = try Element.querySelector(input, "[type=\"checkbox\"]");
    try testing.expect(no_match == null);
}

test "CSS Level 2: Attribute word match selector [attr~=value]" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "class", "foo bar baz");

    // Should match when value is one of the space-separated words
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "[class~=\"bar\"]");
    try testing.expect(result != null);
    try testing.expect(result.? == div);

    // Should not match partial word
    const no_match = try Element.querySelector(div, "[class~=\"ba\"]");
    try testing.expect(no_match == null);
}

test "CSS Level 2: First child pseudo-class :first-child" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const ul = try doc.createElement("ul");
    const li1 = try doc.createElement("li");
    const li2 = try doc.createElement("li");
    const li3 = try doc.createElement("li");

    _ = try ul.appendChild(li1);
    _ = try ul.appendChild(li2);
    _ = try ul.appendChild(li3);

    // li:first-child should match only li1
    _ = try doc.node.appendChild(ul); // Add to document tree for cleanup

    const result = try Element.querySelector(ul, "li:first-child");
    try testing.expect(result != null);
    try testing.expect(result.? == li1);
}

test "CSS Level 2: Link pseudo-classes :link and :visited" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("a");
    try Element.setAttribute(a, "href", "https://example.com");

    // :link matches unvisited links
    _ = try doc.node.appendChild(a); // Add to document tree for cleanup

    const result = try Element.querySelector(a, ":link");
    try testing.expect(result != null);

    // Note: :visited would require browser history, not testable in pure DOM
}

// ============================================================================
// CSS Selectors Level 3
// https://www.w3.org/TR/selectors-3/
// ============================================================================

test "CSS Level 3: General sibling combinator (~)" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const h1 = try doc.createElement("h1");
    const p1 = try doc.createElement("p");
    const p2 = try doc.createElement("p");

    _ = try div.appendChild(h1);
    _ = try div.appendChild(p1);
    _ = try div.appendChild(p2);

    // h1 ~ p should match both p elements (all siblings after h1)
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const results = try Element.querySelectorAll(div, "h1 ~ p");
    defer {
        results.deinit();
        allocator.destroy(results);
    }
    try testing.expectEqual(@as(usize, 2), results.length());
}

test "CSS Level 3: Attribute starts with selector [attr^=value]" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("a");
    try Element.setAttribute(a, "href", "https://example.com");

    _ = try doc.node.appendChild(a); // Add to document tree for cleanup

    const result = try Element.querySelector(a, "[href^=\"https\"]");
    try testing.expect(result != null);
    try testing.expect(result.? == a);

    const no_match = try Element.querySelector(a, "[href^=\"http://\"]");
    try testing.expect(no_match == null);
}

test "CSS Level 3: Attribute ends with selector [attr$=value]" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("a");
    try Element.setAttribute(a, "href", "document.pdf");

    _ = try doc.node.appendChild(a); // Add to document tree for cleanup

    const result = try Element.querySelector(a, "[href$=\".pdf\"]");
    try testing.expect(result != null);
    try testing.expect(result.? == a);

    const no_match = try Element.querySelector(a, "[href$=\".jpg\"]");
    try testing.expect(no_match == null);
}

test "CSS Level 3: Attribute contains selector [attr*=value]" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("a");
    try Element.setAttribute(a, "href", "https://github.com/user/repo");

    _ = try doc.node.appendChild(a); // Add to document tree for cleanup

    const result = try Element.querySelector(a, "[href*=\"github\"]");
    try testing.expect(result != null);
    try testing.expect(result.? == a);

    const no_match = try Element.querySelector(a, "[href*=\"gitlab\"]");
    try testing.expect(no_match == null);
}

test "CSS Level 3: Attribute language prefix selector [attr|=value]" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const p = try doc.createElement("p");
    try Element.setAttribute(p, "lang", "en-US");

    // Should match "en" or "en-*"
    _ = try doc.node.appendChild(p); // Add to document tree for cleanup

    const result = try Element.querySelector(p, "[lang|=\"en\"]");
    try testing.expect(result != null);
    try testing.expect(result.? == p);

    const no_match = try Element.querySelector(p, "[lang|=\"fr\"]");
    try testing.expect(no_match == null);
}

test "CSS Level 3: Last child pseudo-class :last-child" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const ul = try doc.createElement("ul");
    const li1 = try doc.createElement("li");
    const li2 = try doc.createElement("li");
    const li3 = try doc.createElement("li");

    _ = try ul.appendChild(li1);
    _ = try ul.appendChild(li2);
    _ = try ul.appendChild(li3);

    _ = try doc.node.appendChild(ul); // Add to document tree for cleanup

    const result = try Element.querySelector(ul, "li:last-child");
    try testing.expect(result != null);
    try testing.expect(result.? == li3);
}

test "CSS Level 3: Nth child pseudo-class :nth-child(n)" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const ul = try doc.createElement("ul");
    const li1 = try doc.createElement("li");
    const li2 = try doc.createElement("li");
    const li3 = try doc.createElement("li");

    _ = try ul.appendChild(li1);
    _ = try ul.appendChild(li2);
    _ = try ul.appendChild(li3);

    // :nth-child(2) should match second child
    _ = try doc.node.appendChild(ul); // Add to document tree for cleanup

    const result = try Element.querySelector(ul, "li:nth-child(2)");
    try testing.expect(result != null);
    try testing.expect(result.? == li2);

    // :nth-child(odd) should match li1 and li3
    const odds = try Element.querySelectorAll(ul, "li:nth-child(odd)");
    defer {
        odds.deinit();
        allocator.destroy(odds);
    }
    try testing.expectEqual(@as(usize, 2), odds.length());

    // :nth-child(even) should match li2
    const evens = try Element.querySelectorAll(ul, "li:nth-child(even)");
    defer {
        evens.deinit();
        allocator.destroy(evens);
    }
    try testing.expectEqual(@as(usize, 1), evens.length());
}

test "CSS Level 3: Nth last child pseudo-class :nth-last-child(n)" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const ul = try doc.createElement("ul");
    const li1 = try doc.createElement("li");
    const li2 = try doc.createElement("li");
    const li3 = try doc.createElement("li");

    _ = try ul.appendChild(li1);
    _ = try ul.appendChild(li2);
    _ = try ul.appendChild(li3);

    // :nth-last-child(2) should match second from end (li2)
    _ = try doc.node.appendChild(ul); // Add to document tree for cleanup

    const result = try Element.querySelector(ul, "li:nth-last-child(2)");
    try testing.expect(result != null);
    try testing.expect(result.? == li2);
}

test "CSS Level 3: First of type pseudo-class :first-of-type" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const span = try doc.createElement("span");
    const p1 = try doc.createElement("p");
    const p2 = try doc.createElement("p");

    _ = try div.appendChild(span);
    _ = try div.appendChild(p1);
    _ = try div.appendChild(p2);

    // p:first-of-type should match p1
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "p:first-of-type");
    try testing.expect(result != null);
    try testing.expect(result.? == p1);
}

test "CSS Level 3: Last of type pseudo-class :last-of-type" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p1 = try doc.createElement("p");
    const p2 = try doc.createElement("p");
    const span = try doc.createElement("span");

    _ = try div.appendChild(p1);
    _ = try div.appendChild(p2);
    _ = try div.appendChild(span);

    // p:last-of-type should match p2
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "p:last-of-type");
    try testing.expect(result != null);
    try testing.expect(result.? == p2);
}

test "CSS Level 3: Only child pseudo-class :only-child" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p = try doc.createElement("p");
    _ = try div.appendChild(p);

    // p:only-child should match (it's the only child)
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "p:only-child");
    try testing.expect(result != null);
    try testing.expect(result.? == p);

    // Add another child
    const span = try doc.createElement("span");
    _ = try div.appendChild(span);

    // Now p:only-child should not match
    const no_match = try Element.querySelector(div, "p:only-child");
    try testing.expect(no_match == null);
}

test "CSS Level 3: Only of type pseudo-class :only-of-type" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p = try doc.createElement("p");
    const span = try doc.createElement("span");

    _ = try div.appendChild(p);
    _ = try div.appendChild(span);

    // p:only-of-type should match (only p element)
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "p:only-of-type");
    try testing.expect(result != null);
    try testing.expect(result.? == p);
}

test "CSS Level 3: Empty pseudo-class :empty" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div1 = try doc.createElement("div");
    const div2 = try doc.createElement("div");
    const text = try doc.createTextNode("content");
    _ = try div2.appendChild(text.character_data.node);

    const container = try doc.createElement("div");
    _ = try container.appendChild(div1);
    _ = try container.appendChild(div2);

    // div:empty should match only div1
    _ = try doc.node.appendChild(div1); // Add to document tree for cleanup

    const result = try Element.querySelector(container, "div:empty");
    try testing.expect(result != null);
    try testing.expect(result.? == div1);
}

test "CSS Level 3: Not pseudo-class :not()" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p1 = try doc.createElement("p");
    const p2 = try doc.createElement("p");
    try Element.setAttribute(p1, "class", "special");

    _ = try div.appendChild(p1);
    _ = try div.appendChild(p2);

    // p:not(.special) should match only p2
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const result = try Element.querySelector(div, "p:not(.special)");
    try testing.expect(result != null);
    try testing.expect(result.? == p2);
}

test "CSS Level 3: Enabled and disabled pseudo-classes" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input1 = try doc.createElement("input");
    const input2 = try doc.createElement("input");
    try Element.setAttribute(input2, "disabled", "");

    const form = try doc.createElement("form");
    _ = try form.appendChild(input1);
    _ = try form.appendChild(input2);

    // input:enabled should match input1
    _ = try doc.node.appendChild(input1); // Add to document tree for cleanup

    const enabled = try Element.querySelector(form, "input:enabled");
    try testing.expect(enabled != null);
    try testing.expect(enabled.? == input1);

    // input:disabled should match input2
    const disabled = try Element.querySelector(form, "input:disabled");
    try testing.expect(disabled != null);
    try testing.expect(disabled.? == input2);
}

test "CSS Level 3: Checked pseudo-class :checked" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "checkbox");
    try Element.setAttribute(input, "checked", "");

    // input:checked should match
    _ = try doc.node.appendChild(input); // Add to document tree for cleanup

    const result = try Element.querySelector(input, ":checked");
    try testing.expect(result != null);
    try testing.expect(result.? == input);
}

// ============================================================================
// CSS Selectors Level 4
// https://www.w3.org/TR/selectors-4/
// ============================================================================

test "CSS Level 4: Is pseudo-class :is()" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const h1 = try doc.createElement("h1");
    const h2 = try doc.createElement("h2");
    const p = try doc.createElement("p");

    _ = try div.appendChild(h1);
    _ = try div.appendChild(h2);
    _ = try div.appendChild(p);

    // :is(h1, h2) should match h1 and h2 but not p
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const results = try Element.querySelectorAll(div, ":is(h1, h2)");
    defer {
        results.deinit();
        allocator.destroy(results);
    }
    try testing.expectEqual(@as(usize, 2), results.length());
}

test "CSS Level 4: Where pseudo-class :where()" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p1 = try doc.createElement("p");
    const p2 = try doc.createElement("p");
    try Element.setAttribute(p1, "class", "intro");

    _ = try div.appendChild(p1);
    _ = try div.appendChild(p2);

    // :where(.intro) p should match paragraphs (where has 0 specificity)
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const results = try Element.querySelectorAll(div, ":where(.intro)");
    defer {
        results.deinit();
        allocator.destroy(results);
    }
    try testing.expectEqual(@as(usize, 1), results.length());
}

test "CSS Level 4: Has pseudo-class :has()" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div1 = try doc.createElement("div");
    const div2 = try doc.createElement("div");
    const p = try doc.createElement("p");

    _ = try div1.appendChild(p);

    const container = try doc.createElement("div");
    _ = try container.appendChild(div1);
    _ = try container.appendChild(div2);

    // div:has(p) should match only div1
    _ = try doc.node.appendChild(div1); // Add to document tree for cleanup

    const result = try Element.querySelector(container, "div:has(p)");
    try testing.expect(result != null);
    try testing.expect(result.? == div1);

    // div:has(span) should not match anything
    const no_match = try Element.querySelector(container, "div:has(span)");
    try testing.expect(no_match == null);
}

test "CSS Level 4: Multiple selector lists with comma" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const h1 = try doc.createElement("h1");
    const p = try doc.createElement("p");
    const span = try doc.createElement("span");

    _ = try div.appendChild(h1);
    _ = try div.appendChild(p);
    _ = try div.appendChild(span);

    // h1, p should match both h1 and p but not span
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const results = try Element.querySelectorAll(div, "h1, p");
    defer {
        results.deinit();
        allocator.destroy(results);
    }
    try testing.expectEqual(@as(usize, 2), results.length());
}

test "CSS Level 4: Case-insensitive attribute selector [attr=value i]" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const input = try doc.createElement("input");
    try Element.setAttribute(input, "type", "TEXT");

    // Should match case-insensitively with 'i' flag
    _ = try doc.node.appendChild(input); // Add to document tree for cleanup

    const result = try Element.querySelector(input, "[type=\"text\" i]");
    try testing.expect(result != null);
    try testing.expect(result.? == input);
}

test "CSS Level 4: Any-link pseudo-class :any-link" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const a = try doc.createElement("a");
    try Element.setAttribute(a, "href", "https://example.com");

    // :any-link matches all links (visited or unvisited)
    _ = try doc.node.appendChild(a); // Add to document tree for cleanup

    const result = try Element.querySelector(a, ":any-link");
    try testing.expect(result != null);
    try testing.expect(result.? == a);
}

// ============================================================================
// Complex Selector Combinations
// ============================================================================

test "Complex: Multiple combinators" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const article = try doc.createElement("article");
    const header = try doc.createElement("header");
    const h1 = try doc.createElement("h1");
    const div = try doc.createElement("div");
    const p = try doc.createElement("p");

    _ = try article.appendChild(header);
    _ = try header.appendChild(h1);
    _ = try article.appendChild(div);
    _ = try div.appendChild(p);

    // article > div p should match p (child then descendant)
    _ = try doc.node.appendChild(article); // Add to document tree for cleanup

    const result = try Element.querySelector(article, "article > div p");
    try testing.expect(result != null);
    try testing.expect(result.? == p);
}

test "Complex: Chained pseudo-classes" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const p1 = try doc.createElement("p");
    const p2 = try doc.createElement("p");
    try Element.setAttribute(p1, "class", "special");

    _ = try div.appendChild(p1);
    _ = try div.appendChild(p2);

    // p:first-child:not(.special) should not match (p1 has .special)
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const no_match = try Element.querySelector(div, "p:first-child:not(.special)");
    try testing.expect(no_match == null);

    // p:last-child:not(.special) should match p2
    const result = try Element.querySelector(div, "p:last-child:not(.special)");
    try testing.expect(result != null);
    try testing.expect(result.? == p2);
}

test "Complex: Nested :is() and :not()" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    const h1 = try doc.createElement("h1");
    const p = try doc.createElement("p");
    const span = try doc.createElement("span");
    try Element.setAttribute(span, "class", "excluded");

    _ = try div.appendChild(h1);
    _ = try div.appendChild(p);
    _ = try div.appendChild(span);

    // :is(h1, p, span):not(.excluded) should match h1 and p but not span
    _ = try doc.node.appendChild(div); // Add to document tree for cleanup

    const results = try Element.querySelectorAll(div, ":is(h1, p, span):not(.excluded)");
    defer {
        results.deinit();
        allocator.destroy(results);
    }
    try testing.expectEqual(@as(usize, 2), results.length());
}

test "Complex: Attribute and pseudo-class combination" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const form = try doc.createElement("form");
    const input1 = try doc.createElement("input");
    const input2 = try doc.createElement("input");

    try Element.setAttribute(input1, "type", "text");
    try Element.setAttribute(input1, "required", "");
    try Element.setAttribute(input2, "type", "text");

    _ = try form.appendChild(input1);
    _ = try form.appendChild(input2);

    // input[type="text"]:enabled[required] should match input1
    _ = try doc.node.appendChild(form); // Add to document tree for cleanup

    const result = try Element.querySelector(form, "input[type=\"text\"]:enabled[required]");
    try testing.expect(result != null);
    try testing.expect(result.? == input1);
}
