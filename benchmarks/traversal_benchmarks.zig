const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;

// ============================================================================
// TREE TRAVERSAL BENCHMARKS
// ============================================================================

pub fn benchTreeTraversal(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "ul");
    _ = try doc.node.appendChild(root);

    // Build simple tree: 10 list items
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const li = try Element.create(allocator, "li");
        _ = try root.appendChild(li);

        // Each li has 3 child divs
        var j: usize = 0;
        while (j < 3) : (j += 1) {
            const div = try Element.create(allocator, "div");
            _ = try li.appendChild(div);
        }
    }

    // Traverse all children
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

pub fn benchDeepTreeTraversal(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(root);

    // Build deep tree: 50 levels
    var parent = root;
    var level: usize = 0;
    while (level < 50) : (level += 1) {
        const child = try Element.create(allocator, "div");
        _ = try parent.appendChild(child);
        parent = child;
    }

    // Traverse up
    var count: usize = 0;
    var node: ?*Node = parent;
    while (node) |n| {
        count += 1;
        node = n.parent_node;
    }
    if (count == 0) unreachable;
}
