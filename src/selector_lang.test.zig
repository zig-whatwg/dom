//! Tests for :lang() pseudo-class support
//!
//! The :lang() pseudo-class matches elements based on their language,
//! as determined by the lang attribute. Language matching uses prefix
//! matching, so :lang(en) matches both lang="en" and lang="en-US".

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const Node = @import("node.zig").Node;
const selector = @import("selector.zig");

test ":lang() basic matching - exact match" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "lang", "en");
    _ = try doc.node.appendChild(div);

    // Should match with :lang(en)
    try testing.expect(try selector.matches(div, ":lang(en)", allocator));

    // Should not match different language
    try testing.expect(!try selector.matches(div, ":lang(fr)", allocator));
}

test ":lang() prefix matching - en matches en-US" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "lang", "en-US");
    _ = try doc.node.appendChild(div);

    // :lang(en) should match lang="en-US" (prefix match)
    try testing.expect(try selector.matches(div, ":lang(en)", allocator));

    // :lang(en-US) should also match exactly
    try testing.expect(try selector.matches(div, ":lang(en-US)", allocator));

    // :lang(fr) should not match
    try testing.expect(!try selector.matches(div, ":lang(fr)", allocator));
}

test ":lang() prefix matching - en-US does not match en-GB" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "lang", "en-US");
    _ = try doc.node.appendChild(div);

    // :lang(en-GB) should NOT match lang="en-US"
    try testing.expect(!try selector.matches(div, ":lang(en-GB)", allocator));
}

test ":lang() inheritance - child inherits from parent" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    try Element.setAttribute(parent, "lang", "fr");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("span");
    _ = try parent.appendChild(child);

    // Child should inherit lang from parent
    try testing.expect(try selector.matches(child, ":lang(fr)", allocator));
    try testing.expect(!try selector.matches(child, ":lang(en)", allocator));
}

test ":lang() inheritance - grandchild inherits" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const grandparent = try doc.createElement("html");
    try Element.setAttribute(grandparent, "lang", "de");
    _ = try doc.node.appendChild(grandparent);

    const parent = try doc.createElement("body");
    _ = try grandparent.appendChild(parent);

    const child = try doc.createElement("div");
    _ = try parent.appendChild(child);

    // Grandchild should inherit lang from grandparent
    try testing.expect(try selector.matches(child, ":lang(de)", allocator));
}

test ":lang() inheritance - child overrides parent" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    try Element.setAttribute(parent, "lang", "en");
    _ = try doc.node.appendChild(parent);

    const child = try doc.createElement("span");
    try Element.setAttribute(child, "lang", "fr");
    _ = try parent.appendChild(child);

    // Child should use its own lang, not parent's
    try testing.expect(try selector.matches(child, ":lang(fr)", allocator));
    try testing.expect(!try selector.matches(child, ":lang(en)", allocator));

    // Parent should still match en
    try testing.expect(try selector.matches(parent, ":lang(en)", allocator));
}

test ":lang() no lang attribute" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // Should not match any language without lang attribute
    try testing.expect(!try selector.matches(div, ":lang(en)", allocator));
    try testing.expect(!try selector.matches(div, ":lang(fr)", allocator));
}

test ":lang() with querySelector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create elements with different languages
    const en_elem = try doc.createElement("p");
    try Element.setAttribute(en_elem, "lang", "en");
    _ = try container.appendChild(en_elem);

    const fr_elem = try doc.createElement("p");
    try Element.setAttribute(fr_elem, "lang", "fr");
    _ = try container.appendChild(fr_elem);

    const de_elem = try doc.createElement("p");
    try Element.setAttribute(de_elem, "lang", "de");
    _ = try container.appendChild(de_elem);

    // Query for English elements
    const en_result = try Element.querySelector(container, "p:lang(en)");
    try testing.expect(en_result != null);
    try testing.expect(en_result.? == en_elem);

    // Query for French elements
    const fr_result = try Element.querySelector(container, "p:lang(fr)");
    try testing.expect(fr_result != null);
    try testing.expect(fr_result.? == fr_elem);
}

test ":lang() with querySelectorAll" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(container);

    // Create elements with English
    const en1 = try doc.createElement("p");
    try Element.setAttribute(en1, "lang", "en");
    _ = try container.appendChild(en1);

    const en2 = try doc.createElement("span");
    try Element.setAttribute(en2, "lang", "en-US");
    _ = try container.appendChild(en2);

    const fr = try doc.createElement("div");
    try Element.setAttribute(fr, "lang", "fr");
    _ = try container.appendChild(fr);

    // Query for all English elements (should match en and en-US)
    const results = try Element.querySelectorAll(container, ":lang(en)");
    defer {
        results.deinit();
        allocator.destroy(results);
    }

    try testing.expectEqual(@as(usize, 2), results.length());
    const item0: *Node = @ptrCast(@alignCast(results.item(0).?));
    const item1: *Node = @ptrCast(@alignCast(results.item(1).?));
    try testing.expect(item0 == en1);
    try testing.expect(item1 == en2);
}

test ":lang() combined with other pseudo-classes" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    try Element.setAttribute(container, "lang", "en");
    _ = try doc.node.appendChild(container);

    const child1 = try doc.createElement("p");
    _ = try container.appendChild(child1);

    const child2 = try doc.createElement("p");
    _ = try container.appendChild(child2);

    // :lang(en):first-child
    try testing.expect(try selector.matches(child1, ":lang(en):first-child", allocator));
    try testing.expect(!try selector.matches(child2, ":lang(en):first-child", allocator));

    // :lang(en):last-child
    try testing.expect(try selector.matches(child2, ":lang(en):last-child", allocator));
    try testing.expect(!try selector.matches(child1, ":lang(en):last-child", allocator));
}

test ":lang() combined with class selector" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "lang", "es");
    try Element.setAttribute(div, "class", "content");
    _ = try doc.node.appendChild(div);

    // div.content:lang(es)
    try testing.expect(try selector.matches(div, "div.content:lang(es)", allocator));
    try testing.expect(!try selector.matches(div, "div.content:lang(en)", allocator));
}

test ":lang() inside :not()" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const en_elem = try doc.createElement("div");
    try Element.setAttribute(en_elem, "lang", "en");
    _ = try doc.node.appendChild(en_elem);

    const fr_elem = try doc.createElement("div");
    try Element.setAttribute(fr_elem, "lang", "fr");
    _ = try doc.node.appendChild(fr_elem);

    // :not(:lang(en)) should match French element
    try testing.expect(!try selector.matches(en_elem, ":not(:lang(en))", allocator));
    try testing.expect(try selector.matches(fr_elem, ":not(:lang(en))", allocator));
}

test ":lang() multiple language regions" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try Element.setAttribute(div, "lang", "zh-Hans-CN");
    _ = try doc.node.appendChild(div);

    // Should match prefix
    try testing.expect(try selector.matches(div, ":lang(zh)", allocator));
    try testing.expect(try selector.matches(div, ":lang(zh-Hans)", allocator));
    try testing.expect(try selector.matches(div, ":lang(zh-Hans-CN)", allocator));
}

test ":lang() with descendant combinator" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    try Element.setAttribute(container, "lang", "it");
    _ = try doc.node.appendChild(container);

    const paragraph = try doc.createElement("p");
    _ = try container.appendChild(paragraph);

    // div:lang(it) p should match paragraph
    const result = try Element.querySelector(container, "div:lang(it) p");
    try testing.expect(result != null);
    try testing.expect(result.? == paragraph);
}

test ":lang() memory safety - no leaks" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create and query many elements
    var i: usize = 0;
    while (i < 50) : (i += 1) {
        const div = try doc.createElement("div");
        try Element.setAttribute(div, "lang", "ja");
        _ = try doc.node.appendChild(div);
    }

    // Query multiple times
    var j: usize = 0;
    while (j < 5) : (j += 1) {
        const results = try Element.querySelectorAll(doc.node, ":lang(ja)");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        try testing.expectEqual(@as(usize, 50), results.length());
    }
}
