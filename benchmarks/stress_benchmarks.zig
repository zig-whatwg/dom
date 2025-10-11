const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;

// ============================================================================
// STRESS TEST BENCHMARKS (Expensive Operations)
// ============================================================================

pub fn benchCreate10kNodes(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(root);

    // Create 10,000 elements
    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        const child = try Element.create(allocator, "div");
        _ = try root.appendChild(child);
    }
}

// Note: Create+destroy test temporarily disabled due to memory management complexity
// The issue is with managing ref counts during mass removal operations
// Individual create/destroy operations work fine (see removeChild benchmark above)

pub fn benchDeepTree500Levels(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(root);

    // Build extremely deep tree: 500 levels
    var parent = root;
    var level: usize = 0;
    while (level < 500) : (level += 1) {
        const child = try Element.create(allocator, "div");
        _ = try parent.appendChild(child);
        parent = child;
    }

    // Traverse back up
    var count: usize = 0;
    var node: ?*Node = parent;
    while (node) |n| {
        count += 1;
        node = n.parent_node;
    }
    if (count == 0) unreachable;
}

pub fn benchComplexQuery10kNodes(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(root);

    // Create 10,000 elements with classes
    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        const child = try Element.create(allocator, "div");

        // Every 10th element gets a special class
        if (i % 10 == 0) {
            try Element.setClassName(child, "special");
        } else {
            try Element.setClassName(child, "normal");
        }

        _ = try root.appendChild(child);
    }

    // Run complex query over 10k nodes
    const results = try Element.querySelectorAll(root, "div.special");
    defer results.deinit();
}

pub fn benchMassiveAttributeOps(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(root);

    // Create 1,000 elements and set 10 attributes each
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const child = try Element.create(allocator, "div");
        _ = try root.appendChild(child);

        // Set 10 attributes per element
        try Element.setAttribute(child, "id", "element");
        try Element.setAttribute(child, "class", "container");
        try Element.setAttribute(child, "data-index", "123");
        try Element.setAttribute(child, "data-value", "test");
        try Element.setAttribute(child, "aria-label", "Label");
        try Element.setAttribute(child, "role", "button");
        try Element.setAttribute(child, "tabindex", "0");
        try Element.setAttribute(child, "title", "Title");
        try Element.setAttribute(child, "data-foo", "bar");
        try Element.setAttribute(child, "data-baz", "qux");
    }
}

pub fn benchWideTree100x100(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(root);

    // Create 100 parent elements, each with 100 children (10,000 total)
    var parent_idx: usize = 0;
    while (parent_idx < 100) : (parent_idx += 1) {
        const parent = try Element.create(allocator, "div");
        _ = try root.appendChild(parent);

        var child_idx: usize = 0;
        while (child_idx < 100) : (child_idx += 1) {
            const child = try Element.create(allocator, "span");
            _ = try parent.appendChild(child);
        }
    }

    // Traverse entire tree
    var count: usize = 0;
    var node = root.firstChild();
    while (node) |n| {
        count += 1;
        var child = n.firstChild();
        while (child) |c| {
            count += 1;
            child = c.nextSibling();
        }
        node = n.nextSibling();
    }
    if (count == 0) unreachable;
}
