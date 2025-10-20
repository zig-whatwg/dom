const std = @import("std");
const dom = @import("dom");

const Document = dom.Document;
const Element = dom.Element;
const TreeWalker = dom.TreeWalker;
const NodeFilter = dom.NodeFilter;

test "TreeWalker firstChild navigation" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try root.prototype.appendChild(&child1.prototype);
    _ = try root.prototype.appendChild(&child2.prototype);

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    try std.testing.expectEqual(&root.prototype, walker.current_node);
    try std.testing.expectEqual(&child1.prototype, walker.firstChild().?);
    try std.testing.expectEqual(&child1.prototype, walker.current_node);
}

test "TreeWalker nextSibling navigation" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try root.prototype.appendChild(&child1.prototype);
    _ = try root.prototype.appendChild(&child2.prototype);

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    _ = walker.firstChild();
    try std.testing.expectEqual(&child2.prototype, walker.nextSibling().?);
}

test "TreeWalker parentNode navigation" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const child = try doc.createElement("child");
    _ = try root.prototype.appendChild(&child.prototype);

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    _ = walker.firstChild();
    try std.testing.expectEqual(&root.prototype, walker.parentNode().?);
}

test "TreeWalker nextNode traversal" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try root.prototype.appendChild(&child1.prototype);
    _ = try root.prototype.appendChild(&child2.prototype);

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ALL, null);
    defer walker.deinit();

    try std.testing.expectEqual(&child1.prototype, walker.nextNode().?);
    try std.testing.expectEqual(&child2.prototype, walker.nextNode().?);
    try std.testing.expect(walker.nextNode() == null);
}
