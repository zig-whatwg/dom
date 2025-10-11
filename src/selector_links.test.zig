//! Tests for CSS4 Link Pseudo-Classes
//!
//! Tests selector matching for link pseudo-classes including:
//! - :any-link - Matches <a> and <area> with href
//! - :link - Unvisited links
//! - :visited - Visited links
//! - :local-link - Links to same domain (CSS4)
//!
//! Spec: https://drafts.csswg.org/selectors-4/#link

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const selector = @import("selector.zig");

test ":any-link matches <a> with href" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    _ = try doc.node.appendChild(link);

    try testing.expect(try selector.matches(link, ":any-link", testing.allocator));
}

test ":any-link matches <area> with href" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const root = try doc.createElement("div");

    _ = try doc.node.appendChild(root);

    const area = try doc.createElement("area");
    try Element.setAttribute(area, "href", "#top");
    _ = try root.appendChild(area);

    try testing.expect(try selector.matches(area, ":any-link", testing.allocator));
}

test ":any-link does not match <a> without href" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "name", "anchor");
    _ = try doc.node.appendChild(link);

    try testing.expect(!try selector.matches(link, ":any-link", testing.allocator));
}

test ":any-link does not match non-link elements" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "href", "https://example.com");
    _ = try doc.node.appendChild(div);

    try testing.expect(!try selector.matches(div, ":any-link", testing.allocator));
}

test ":link matches unvisited links" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    try Element.setAttribute(link, "data-visited", "false");
    _ = try doc.node.appendChild(link);

    try testing.expect(try selector.matches(link, ":link", testing.allocator));
}

test ":link matches links without visited state (default unvisited)" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    _ = try doc.node.appendChild(link);

    try testing.expect(try selector.matches(link, ":link", testing.allocator));
}

test ":link does not match visited links" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    try Element.setAttribute(link, "data-visited", "true");
    _ = try doc.node.appendChild(link);

    try testing.expect(!try selector.matches(link, ":link", testing.allocator));
}

test ":visited matches visited links" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    try Element.setAttribute(link, "data-visited", "true");
    _ = try doc.node.appendChild(link);

    try testing.expect(try selector.matches(link, ":visited", testing.allocator));
}

test ":visited does not match unvisited links" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    try Element.setAttribute(link, "data-visited", "false");
    _ = try doc.node.appendChild(link);

    try testing.expect(!try selector.matches(link, ":visited", testing.allocator));
}

test ":visited does not match links without visited state (default unvisited)" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    _ = try doc.node.appendChild(link);

    try testing.expect(!try selector.matches(link, ":visited", testing.allocator));
}

test ":local-link matches local links" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "/page.html");
    try Element.setAttribute(link, "data-local-link", "true");
    _ = try doc.node.appendChild(link);

    try testing.expect(try selector.matches(link, ":local-link", testing.allocator));
}

test ":local-link does not match external links" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://external.com");
    try Element.setAttribute(link, "data-local-link", "false");
    _ = try doc.node.appendChild(link);

    try testing.expect(!try selector.matches(link, ":local-link", testing.allocator));
}

test ":local-link does not match links without local state" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "/page.html");
    _ = try doc.node.appendChild(link);

    try testing.expect(!try selector.matches(link, ":local-link", testing.allocator));
}

test "complex selector with link pseudo-classes" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const nav = try doc.createElement("nav");
    _ = try doc.node.appendChild(nav);

    const link1 = try doc.createElement("a");
    try Element.setAttribute(link1, "href", "/home");
    try Element.setAttribute(link1, "data-visited", "true");
    try Element.setAttribute(link1, "class", "internal");

    const link2 = try doc.createElement("a");
    try Element.setAttribute(link2, "href", "/about");
    try Element.setAttribute(link2, "data-visited", "false");
    try Element.setAttribute(link2, "class", "internal");

    _ = try nav.appendChild(link1);
    _ = try nav.appendChild(link2);

    // nav :visited.internal
    try testing.expect(try selector.matches(link1, "nav :visited.internal", testing.allocator));
    try testing.expect(!try selector.matches(link2, "nav :visited.internal", testing.allocator));

    // nav :link.internal
    try testing.expect(!try selector.matches(link1, "nav :link.internal", testing.allocator));
    try testing.expect(try selector.matches(link2, "nav :link.internal", testing.allocator));
}

test ":any-link with negation" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link = try doc.createElement("a");
    try Element.setAttribute(link, "href", "https://example.com");
    _ = try doc.node.appendChild(link);

    const div = try doc.createElement("div");

    _ = try doc.node.appendChild(div);

    try testing.expect(!try selector.matches(link, ":not(:any-link)", testing.allocator));
    try testing.expect(try selector.matches(div, ":not(:any-link)", testing.allocator));
}

test ":link and :visited are mutually exclusive" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link1 = try doc.createElement("a");
    try Element.setAttribute(link1, "href", "https://example.com");
    try Element.setAttribute(link1, "data-visited", "false");
    _ = try doc.node.appendChild(link1);

    const link2 = try doc.createElement("a");
    try Element.setAttribute(link2, "href", "https://example.com");
    try Element.setAttribute(link2, "data-visited", "true");
    _ = try doc.node.appendChild(link2);

    // Unvisited link
    try testing.expect(try selector.matches(link1, ":link", testing.allocator));
    try testing.expect(!try selector.matches(link1, ":visited", testing.allocator));

    // Visited link
    try testing.expect(!try selector.matches(link2, ":link", testing.allocator));
    try testing.expect(try selector.matches(link2, ":visited", testing.allocator));
}

test ":any-link matches both :link and :visited" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const link1 = try doc.createElement("a");
    try Element.setAttribute(link1, "href", "https://example.com");
    try Element.setAttribute(link1, "data-visited", "false");
    _ = try doc.node.appendChild(link1);

    const link2 = try doc.createElement("a");
    try Element.setAttribute(link2, "href", "https://example.com");
    try Element.setAttribute(link2, "data-visited", "true");
    _ = try doc.node.appendChild(link2);

    // :any-link should match both visited and unvisited
    try testing.expect(try selector.matches(link1, ":any-link", testing.allocator));
    try testing.expect(try selector.matches(link2, ":any-link", testing.allocator));
}

test "querySelector with link pseudo-classes" {
    const doc = try Document.init(testing.allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(root);

    const link1 = try doc.createElement("a");
    try Element.setAttribute(link1, "href", "https://example.com");
    try Element.setAttribute(link1, "id", "link1");

    const link2 = try doc.createElement("a");
    try Element.setAttribute(link2, "href", "https://example.com");
    try Element.setAttribute(link2, "id", "link2");
    try Element.setAttribute(link2, "data-visited", "true");

    const span = try doc.createElement("span");

    _ = try root.appendChild(link1);
    _ = try root.appendChild(link2);
    _ = try root.appendChild(span);

    // Find first :any-link
    const found_any = try selector.querySelector(root, ":any-link", testing.allocator);
    try testing.expect(found_any != null);
    try testing.expect(found_any.? == link1);

    // Find first :visited
    const found_visited = try selector.querySelector(root, ":visited", testing.allocator);
    try testing.expect(found_visited != null);
    try testing.expect(found_visited.? == link2);
}
