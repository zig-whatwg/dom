// WPT Test: Node-parentNode
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Node-parentNode.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

test "Document parentNode is null" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    try std.testing.expect(doc.prototype.parent_node == null);
}

test "Root element parentNode is document" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try std.testing.expect(root.prototype.parent_node == &doc.prototype);
}

test "Element parentNode before and after insertion" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    // Note: el will be owned by body after appendChild, so no defer needed

    // Before insertion, parentNode is null
    try std.testing.expect(el.prototype.parent_node == null);

    const body = try doc.createElement("body");
    _ = try doc.prototype.appendChild(&body.prototype);
    // body is now owned by doc

    _ = try body.prototype.appendChild(&el.prototype);
    // el is now owned by body, which is owned by doc
    // When doc.release() is called, it will release body, which releases el

    // After insertion, parentNode is body
    try std.testing.expect(el.prototype.parent_node == &body.prototype);
}

test "Element parentNode after removal" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");
    defer child.prototype.release();

    _ = try parent.prototype.appendChild(&child.prototype);
    try std.testing.expect(child.prototype.parent_node == &parent.prototype);

    _ = try parent.prototype.removeChild(&child.prototype);
    try std.testing.expect(child.prototype.parent_node == null);
}
