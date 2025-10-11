const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const selector = @import("selector.zig");
const Node = @import("node.zig").Node;

// ============================================================================
// :has() with Combinator Tests
// ============================================================================

test ":has() with descendant combinator (space) - default behavior" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // <div class="parent">
    //   <span>
    //     <b class="deep">text</b>
    //   </span>
    // </div>
    const parent = try doc.createElement("div");
    try Element.setAttribute(parent, "class", "parent");
    _ = try container.appendChild(parent);

    const span = try doc.createElement("span");
    _ = try parent.appendChild(span);

    const deep = try doc.createElement("b");
    try Element.setAttribute(deep, "class", "deep");
    _ = try span.appendChild(deep);

    // :has(.deep) should match because .deep is a descendant (even if nested)
    try testing.expect(try selector.matches(parent, "div:has(.deep)", testing.allocator));

    // Explicit descendant combinator (space is implied, but can be explicit)
    try testing.expect(try selector.matches(parent, "div:has( .deep)", testing.allocator));
}

test ":has() with child combinator (>) - direct children only" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // <div id="parent">
    //   <span class="direct-child"></span>
    //   <div>
    //     <span class="nested-child"></span>
    //   </div>
    // </div>
    const parent = try doc.createElement("div");
    try Element.setAttribute(parent, "id", "parent");
    _ = try container.appendChild(parent);

    const directChild = try doc.createElement("span");
    try Element.setAttribute(directChild, "class", "direct-child");
    _ = try parent.appendChild(directChild);

    const wrapper = try doc.createElement("div");
    _ = try parent.appendChild(wrapper);

    const nestedChild = try doc.createElement("span");
    try Element.setAttribute(nestedChild, "class", "nested-child");
    _ = try wrapper.appendChild(nestedChild);

    // :has(> .direct-child) should match - direct child
    try testing.expect(try selector.matches(parent, "div:has(> .direct-child)", testing.allocator));

    // :has(> .nested-child) should NOT match - not a direct child
    try testing.expect(!try selector.matches(parent, "div:has(> .nested-child)", testing.allocator));

    // :has(.nested-child) without > should match - any descendant
    try testing.expect(try selector.matches(parent, "div:has(.nested-child)", testing.allocator));
}

test ":has() with adjacent sibling combinator (+) - next sibling only" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // <div>
    //   <h1 class="title"></h1>
    //   <p class="intro"></p>
    //   <p class="body"></p>
    // </div>
    const h1 = try doc.createElement("h1");
    try Element.setAttribute(h1, "class", "title");
    _ = try container.appendChild(h1);

    const intro = try doc.createElement("p");
    try Element.setAttribute(intro, "class", "intro");
    _ = try container.appendChild(intro);

    const body = try doc.createElement("p");
    try Element.setAttribute(body, "class", "body");
    _ = try container.appendChild(body);

    // h1:has(+ .intro) should match - .intro is adjacent sibling
    try testing.expect(try selector.matches(h1, "h1:has(+ .intro)", testing.allocator));

    // h1:has(+ .body) should NOT match - .body is not adjacent (there's .intro in between)
    try testing.expect(!try selector.matches(h1, "h1:has(+ .body)", testing.allocator));

    // .intro:has(+ .body) should match
    try testing.expect(try selector.matches(intro, "p:has(+ .body)", testing.allocator));
}

test ":has() with general sibling combinator (~) - any following sibling" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // <div>
    //   <h1 class="title"></h1>
    //   <p class="intro"></p>
    //   <div class="spacer"></div>
    //   <p class="conclusion"></p>
    // </div>
    const h1 = try doc.createElement("h1");
    try Element.setAttribute(h1, "class", "title");
    _ = try container.appendChild(h1);

    const intro = try doc.createElement("p");
    try Element.setAttribute(intro, "class", "intro");
    _ = try container.appendChild(intro);

    const spacer = try doc.createElement("div");
    try Element.setAttribute(spacer, "class", "spacer");
    _ = try container.appendChild(spacer);

    const conclusion = try doc.createElement("p");
    try Element.setAttribute(conclusion, "class", "conclusion");
    _ = try container.appendChild(conclusion);

    // h1:has(~ .conclusion) should match - .conclusion is a following sibling
    try testing.expect(try selector.matches(h1, "h1:has(~ .conclusion)", testing.allocator));

    // h1:has(~ .intro) should match - .intro is a following sibling
    try testing.expect(try selector.matches(h1, "h1:has(~ .intro)", testing.allocator));

    // .intro:has(~ .conclusion) should match
    try testing.expect(try selector.matches(intro, "p:has(~ .conclusion)", testing.allocator));

    // .conclusion:has(~ .intro) should NOT match - .intro comes before
    try testing.expect(!try selector.matches(conclusion, "p:has(~ .intro)", testing.allocator));
}

test ":has() complex selectors with combinators" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // <section id="article">
    //   <header>
    //     <h1>Title</h1>
    //   </header>
    //   <div class="content">
    //     <p class="intro"></p>
    //   </div>
    // </section>
    const article = try doc.createElement("section");
    try Element.setAttribute(article, "id", "article");
    _ = try container.appendChild(article);

    const header = try doc.createElement("header");
    _ = try article.appendChild(header);

    const h1 = try doc.createElement("h1");
    _ = try header.appendChild(h1);

    const content = try doc.createElement("div");
    try Element.setAttribute(content, "class", "content");
    _ = try article.appendChild(content);

    const intro = try doc.createElement("p");
    try Element.setAttribute(intro, "class", "intro");
    _ = try content.appendChild(intro);

    // section:has(> header) - has direct child header
    try testing.expect(try selector.matches(article, "section:has(> header)", testing.allocator));

    // section:has(> h1) - does NOT have direct child h1 (it's nested in header)
    try testing.expect(!try selector.matches(article, "section:has(> h1)", testing.allocator));

    // section:has(h1) - has h1 as descendant
    try testing.expect(try selector.matches(article, "section:has(h1)", testing.allocator));

    // header:has(+ .content) - header has adjacent sibling .content
    try testing.expect(try selector.matches(header, "header:has(+ .content)", testing.allocator));
}

test ":has() with multiple conditions using comma-separated selectors" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // <div id="parent">
    //   <span class="child1"></span>
    // </div>
    const parent = try doc.createElement("div");
    try Element.setAttribute(parent, "id", "parent");
    _ = try container.appendChild(parent);

    const child1 = try doc.createElement("span");
    try Element.setAttribute(child1, "class", "child1");
    _ = try parent.appendChild(child1);

    // :has(> .child1, > .child2) - should match if it has EITHER direct child
    try testing.expect(try selector.matches(parent, "div:has(> .child1, > .child2)", testing.allocator));

    // Add child2
    const child2 = try doc.createElement("span");
    try Element.setAttribute(child2, "class", "child2");
    _ = try parent.appendChild(child2);

    // Now it has both
    try testing.expect(try selector.matches(parent, "div:has(> .child1, > .child2)", testing.allocator));
}

test ":has() combinator with tag selectors" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("ul");
    _ = try doc.node.appendChild(container);

    // <ul>
    //   <li><a href="#">Link</a></li>
    //   <li>Text</li>
    // </ul>
    const li1 = try doc.createElement("li");
    _ = try container.appendChild(li1);

    const a = try doc.createElement("a");
    try Element.setAttribute(a, "href", "#");
    _ = try li1.appendChild(a);

    const li2 = try doc.createElement("li");
    _ = try container.appendChild(li2);

    // li:has(> a) - should match li1 only
    try testing.expect(try selector.matches(li1, "li:has(> a)", testing.allocator));
    try testing.expect(!try selector.matches(li2, "li:has(> a)", testing.allocator));

    // ul:has(> li) - should match container
    try testing.expect(try selector.matches(container, "ul:has(> li)", testing.allocator));
}

test ":has() no combinator vs with combinator difference" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // <div class="outer">
    //   <div class="inner">
    //     <span class="target"></span>
    //   </div>
    // </div>
    const outer = try doc.createElement("div");
    try Element.setAttribute(outer, "class", "outer");
    _ = try container.appendChild(outer);

    const inner = try doc.createElement("div");
    try Element.setAttribute(inner, "class", "inner");
    _ = try outer.appendChild(inner);

    const target = try doc.createElement("span");
    try Element.setAttribute(target, "class", "target");
    _ = try inner.appendChild(target);

    // :has(.target) - matches because .target is ANY descendant
    try testing.expect(try selector.matches(outer, "div:has(.target)", testing.allocator));

    // :has(> .target) - does NOT match because .target is not a direct child
    try testing.expect(!try selector.matches(outer, "div:has(> .target)", testing.allocator));

    // But inner DOES match :has(> .target)
    try testing.expect(try selector.matches(inner, "div:has(> .target)", testing.allocator));
}
