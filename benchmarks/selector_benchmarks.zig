const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

// ============================================================================
// CSS SELECTOR BENCHMARKS
// ============================================================================

pub fn benchSimpleSelector(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "div");
    // Don't defer - owned by doc now
    _ = try doc.node.appendChild(root);

    const target = try Element.create(allocator, "div");
    // Don't defer - owned by root now
    try Element.setClassName(target, "item");
    _ = try root.appendChild(target);

    _ = try Element.querySelector(root, ".item");
}

pub fn benchComplexSelector(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const article = try Element.create(allocator, "article");
    try Element.setClassName(article, "post");
    _ = try doc.node.appendChild(article);

    const p = try Element.create(allocator, "p");
    try Element.setClassName(p, "content");
    _ = try article.appendChild(p);

    _ = try Element.querySelector(article, "article.post > p.content");
}

pub fn benchQuerySelectorAll(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(root);

    // Create 10 items
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const div = try Element.create(allocator, "div");
        try Element.setClassName(div, "item");
        _ = try root.appendChild(div);
    }

    const results = try Element.querySelectorAll(root, ".item");
    defer results.deinit();
}
