//! Advanced CSS Selector Tests
//! Tests for :is(), :where(), :has(), and comma-separated selectors

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const Text = @import("text.zig").Text;
const selector = @import("selector.zig");

fn createDocument() !*Document {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    return doc;
}

// ============================================================================
// Comma-Separated Selectors (Selector Groups)
// ============================================================================

test "Selector Groups: Simple comma-separated selectors" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const p1 = try doc.createElement("p");
    _ = try container.appendChild(p1);

    const div = try doc.createElement("div");
    _ = try container.appendChild(div);

    const span = try doc.createElement("span");
    _ = try container.appendChild(span);

    // Test single selector (should still work)
    try testing.expect(try Element.matches(p1, "p"));

    // Test comma-separated selectors
    try testing.expect(try Element.matches(p1, "p, div, span"));
    try testing.expect(try Element.matches(div, "p, div, span"));
    try testing.expect(try Element.matches(span, "p, div, span"));

    // Test with non-matching selector in the list
    try testing.expect(try Element.matches(p1, "article, p, section"));
    try testing.expect(!try Element.matches(p1, "article, section"));
}

test "Selector Groups: Complex selectors with commas" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    try Element.setAttribute(container, "id", "container");
    _ = try doc.node.appendChild(container);

    const p1 = try doc.createElement("p");
    const data_p1 = Element.getData(p1);
    try data_p1.class_list.add("intro");
    _ = try container.appendChild(p1);

    const div = try doc.createElement("div");
    const data_div = Element.getData(div);
    try data_div.class_list.add("content");
    _ = try container.appendChild(div);

    // Test complex comma-separated selectors
    try testing.expect(try Element.matches(p1, "p.intro, div.content"));
    try testing.expect(try Element.matches(div, "p.intro, div.content"));
    try testing.expect(!try Element.matches(container, "p.intro, div.content"));

    // Test with child combinators
    try testing.expect(try Element.matches(p1, "#container > p, #container > div"));
    try testing.expect(try Element.matches(div, "#container > p, #container > div"));
}

test "Selector Groups: With pseudo-classes" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const p1 = try doc.createElement("p");
    _ = try container.appendChild(p1);

    const p2 = try doc.createElement("p");
    _ = try container.appendChild(p2);

    const div = try doc.createElement("div");
    _ = try container.appendChild(div);

    // Test comma-separated selectors with pseudo-classes
    try testing.expect(try Element.matches(p1, "p:first-child, div:last-child"));
    try testing.expect(try Element.matches(div, "p:first-child, div:last-child"));
    try testing.expect(!try Element.matches(p2, "p:first-child, div:last-child"));
}

// ============================================================================
// :is() Pseudo-Class
// ============================================================================

test ":is() Basic functionality" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("article");

    _ = try doc.node.appendChild(container);

    const p = try doc.createElement("p");
    _ = try container.appendChild(p);

    const div = try doc.createElement("div");
    _ = try container.appendChild(div);

    const span = try doc.createElement("span");
    _ = try container.appendChild(span);

    // Test :is() with simple selectors
    try testing.expect(try Element.matches(p, ":is(p, div, span)"));
    try testing.expect(try Element.matches(div, ":is(p, div, span)"));
    try testing.expect(try Element.matches(span, ":is(p, div, span)"));
    try testing.expect(!try Element.matches(container, ":is(p, div, span)"));
}

test ":is() With classes" {
    const doc = try createDocument();
    defer doc.release();

    const p1 = try doc.createElement("p");

    const data_p1 = Element.getData(p1);
    try data_p1.class_list.add("intro");
    _ = try doc.node.appendChild(p1);

    const p2 = try doc.createElement("p");
    const data_p2 = Element.getData(p2);
    try data_p2.class_list.add("content");
    _ = try doc.node.appendChild(p2);

    const div = try doc.createElement("div");
    const data_div = Element.getData(div);
    try data_div.class_list.add("sidebar");
    _ = try doc.node.appendChild(div);

    // Test :is() with class selectors
    try testing.expect(try Element.matches(p1, ":is(.intro, .content)"));
    try testing.expect(try Element.matches(p2, ":is(.intro, .content)"));
    try testing.expect(!try Element.matches(div, ":is(.intro, .content)"));
}

test ":is() With complex selectors" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    try Element.setAttribute(container, "id", "main");
    _ = try doc.node.appendChild(container);

    const p = try doc.createElement("p");
    const data_p = Element.getData(p);
    try data_p.class_list.add("intro");
    _ = try container.appendChild(p);

    // Test :is() with compound selectors
    try testing.expect(try Element.matches(p, ":is(p.intro, div.content)"));
    try testing.expect(!try Element.matches(container, ":is(p.intro, div.content)"));
}

test ":is() Nested with other selectors" {
    const doc = try createDocument();
    defer doc.release();

    const article = try doc.createElement("article");

    _ = try doc.node.appendChild(article);

    const p = try doc.createElement("p");
    _ = try article.appendChild(p);

    const div = try doc.createElement("div");
    _ = try article.appendChild(div);

    // Test :is() in combination with other selectors
    try testing.expect(try Element.matches(p, "article :is(p, span)"));
    try testing.expect(try Element.matches(div, "article :is(div, span)"));
}

// ============================================================================
// :where() Pseudo-Class
// ============================================================================

test ":where() Basic functionality" {
    const doc = try createDocument();
    defer doc.release();

    const p = try doc.createElement("p");

    _ = try doc.node.appendChild(p);

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // :where() should function identically to :is()
    try testing.expect(try Element.matches(p, ":where(p, div, span)"));
    try testing.expect(try Element.matches(div, ":where(p, div, span)"));
}

test ":where() With complex selectors" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const p = try doc.createElement("p");
    const data_p = Element.getData(p);
    try data_p.class_list.add("intro");
    _ = try container.appendChild(p);

    // Test :where() with compound selectors
    try testing.expect(try Element.matches(p, ":where(p.intro, div.content)"));
}

// ============================================================================
// :has() Pseudo-Class (Relational Pseudo-Class)
// ============================================================================

test ":has() Basic descendant matching" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const p = try doc.createElement("p");
    _ = try container.appendChild(p);

    // Container has a p descendant
    try testing.expect(try Element.matches(container, ":has(p)"));
    // p doesn't have any descendants
    try testing.expect(!try Element.matches(p, ":has(p)"));
}

test ":has() With class selectors" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const p = try doc.createElement("p");
    const data_p = Element.getData(p);
    try data_p.class_list.add("intro");
    _ = try container.appendChild(p);

    const div = try doc.createElement("div");
    const data_div = Element.getData(div);
    try data_div.class_list.add("content");
    _ = try container.appendChild(div);

    // Container has both .intro and .content descendants
    try testing.expect(try Element.matches(container, ":has(.intro)"));
    try testing.expect(try Element.matches(container, ":has(.content)"));
    try testing.expect(!try Element.matches(p, ":has(.intro)"));
}

test ":has() With nested descendants" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const article = try doc.createElement("article");
    _ = try container.appendChild(article);

    const p = try doc.createElement("p");
    _ = try article.appendChild(p);

    // Container has nested p descendant
    try testing.expect(try Element.matches(container, ":has(p)"));
    // Article also has p descendant
    try testing.expect(try Element.matches(article, ":has(p)"));
}

test ":has() With multiple selectors" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const p = try doc.createElement("p");
    _ = try container.appendChild(p);

    const span = try doc.createElement("span");
    _ = try container.appendChild(span);

    // Test :has() with comma-separated selectors
    try testing.expect(try Element.matches(container, ":has(p, article)"));
    try testing.expect(try Element.matches(container, ":has(span, article)"));
    try testing.expect(!try Element.matches(container, ":has(article, section)"));
}

test ":has() Empty container" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    // Empty container doesn't have any descendants
    try testing.expect(!try Element.matches(container, ":has(p)"));
    try testing.expect(!try Element.matches(container, ":has(*)"));
}

// ============================================================================
// Combined Advanced Selectors
// ============================================================================

test "Combined: :is() with :not()" {
    const doc = try createDocument();
    defer doc.release();

    const p1 = try doc.createElement("p");

    const data_p1 = Element.getData(p1);
    try data_p1.class_list.add("intro");
    _ = try doc.node.appendChild(p1);

    const p2 = try doc.createElement("p");
    const data_p2 = Element.getData(p2);
    try data_p2.class_list.add("content");
    _ = try doc.node.appendChild(p2);

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // Test :is() combined with :not()
    try testing.expect(try Element.matches(p1, ":is(p, div):not(.content)"));
    try testing.expect(!try Element.matches(p2, ":is(p, div):not(.content)"));
    try testing.expect(try Element.matches(div, ":is(p, div):not(.content)"));
}

test "Combined: :has() with :is()" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const p = try doc.createElement("p");
    _ = try container.appendChild(p);

    const span = try doc.createElement("span");
    _ = try container.appendChild(span);

    // Test :has() with :is() inside
    try testing.expect(try Element.matches(container, ":has(:is(p, article))"));
    try testing.expect(try Element.matches(container, ":has(:is(span, article))"));
}

test "Complex selector groups with pseudo-classes" {
    const doc = try createDocument();
    defer doc.release();

    const container = try doc.createElement("div");

    _ = try doc.node.appendChild(container);

    const p1 = try doc.createElement("p");
    _ = try container.appendChild(p1);

    const p2 = try doc.createElement("p");
    _ = try container.appendChild(p2);

    const div = try doc.createElement("div");
    _ = try container.appendChild(div);

    // Complex query: "first p OR last div"
    try testing.expect(try Element.matches(p1, "p:first-child, div:last-child"));
    try testing.expect(!try Element.matches(p2, "p:first-child, div:last-child"));
    try testing.expect(try Element.matches(div, "p:first-child, div:last-child"));
}

test "Practical example: Navigation menu styling" {
    const doc = try createDocument();
    defer doc.release();

    const nav = try doc.createElement("nav");

    _ = try doc.node.appendChild(nav);

    const link1 = try doc.createElement("a");
    const data_link1 = Element.getData(link1);
    try data_link1.class_list.add("home");
    _ = try nav.appendChild(link1);

    const link2 = try doc.createElement("a");
    const data_link2 = Element.getData(link2);
    try data_link2.class_list.add("about");
    _ = try nav.appendChild(link2);

    const link3 = try doc.createElement("a");
    const data_link3 = Element.getData(link3);
    try data_link3.class_list.add("contact");
    _ = try nav.appendChild(link3);

    // Select multiple navigation links with one selector
    try testing.expect(try Element.matches(link1, "a:is(.home, .about, .contact)"));
    try testing.expect(try Element.matches(link2, "a:is(.home, .about, .contact)"));
    try testing.expect(try Element.matches(link3, "a:is(.home, .about, .contact)"));

    // Select nav that has specific links
    try testing.expect(try Element.matches(nav, "nav:has(.home)"));
    try testing.expect(try Element.matches(nav, "nav:has(:is(.home, .products))"));
}
