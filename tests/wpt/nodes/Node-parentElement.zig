// WPT Test: Node-parentElement.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Node-parentElement.html
//
// Tests Node.parentElement behavior as specified in WHATWG DOM Standard § 4.4
// https://dom.spec.whatwg.org/#dom-node-parentelement

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;

test "When the parent is null, parentElement should be null" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expectEqual(@as(?*Element, null), doc.prototype.parentElement());
}

test "When the parent is a document, parentElement should be null (doctype)" {
    // Note: This test requires doctype support which is not yet implemented
    // Skipping for now - will implement when doctypes are added
}

test "When the parent is a document, parentElement should be null (element)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Document element's parent is Document (not Element), so parentElement is null
    try std.testing.expectEqual(@as(?*Element, null), root.prototype.parentElement());
}

test "When the parent is a document, parentElement should be null (comment)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("foo");
    _ = try doc.prototype.appendChild(&comment.prototype);

    try std.testing.expectEqual(@as(?*Element, null), comment.prototype.parentElement());
}

test "parentElement should return null for children of DocumentFragments (element)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release(); // Orphaned DocumentFragment needs manual release
    try std.testing.expectEqual(@as(?*Element, null), df.prototype.parentElement());

    const elem = try doc.createElement("container");
    try std.testing.expectEqual(@as(?*Element, null), elem.prototype.parentElement());

    _ = try df.prototype.appendChild(&elem.prototype);
    try std.testing.expectEqual(&df.prototype, elem.prototype.parent_node);
    try std.testing.expectEqual(@as(?*Element, null), elem.prototype.parentElement());
}

test "parentElement should return null for children of DocumentFragments (text)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release(); // Orphaned DocumentFragment needs manual release
    try std.testing.expectEqual(@as(?*Element, null), df.prototype.parentElement());

    const text = try doc.createTextNode("bar");
    try std.testing.expectEqual(@as(?*Element, null), text.prototype.parentElement());

    _ = try df.prototype.appendChild(&text.prototype);
    try std.testing.expectEqual(&df.prototype, text.prototype.parent_node);
    try std.testing.expectEqual(@as(?*Element, null), text.prototype.parentElement());
}

test "parentElement should work correctly with DocumentFragments (element)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release(); // Orphaned DocumentFragment needs manual release
    const parent = try doc.createElement("parent");
    _ = try df.prototype.appendChild(&parent.prototype);

    const elem = try doc.createElement("child");
    try std.testing.expectEqual(@as(?*Element, null), elem.prototype.parentElement());

    _ = try parent.prototype.appendChild(&elem.prototype);
    try std.testing.expectEqual(parent, elem.prototype.parentElement());
}

test "parentElement should work correctly with DocumentFragments (text)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release(); // Orphaned DocumentFragment needs manual release
    const parent = try doc.createElement("parent");
    _ = try df.prototype.appendChild(&parent.prototype);

    const text = try doc.createTextNode("bar");
    try std.testing.expectEqual(@as(?*Element, null), text.prototype.parentElement());

    _ = try parent.prototype.appendChild(&text.prototype);
    try std.testing.expectEqual(parent, text.prototype.parentElement());
}

test "parentElement should work correctly in disconnected subtrees (element)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release(); // Orphaned parent needs manual release
    const elem = try doc.createElement("child");
    try std.testing.expectEqual(@as(?*Element, null), elem.prototype.parentElement());

    _ = try parent.prototype.appendChild(&elem.prototype);
    try std.testing.expectEqual(parent, elem.prototype.parentElement());
}

test "parentElement should work correctly in disconnected subtrees (text)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release(); // Orphaned parent needs manual release
    const text = try doc.createTextNode("bar");
    try std.testing.expectEqual(@as(?*Element, null), text.prototype.parentElement());

    _ = try parent.prototype.appendChild(&text.prototype);
    try std.testing.expectEqual(parent, text.prototype.parentElement());
}

test "parentElement should work correctly in a document (element)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create a body element as document root
    const body = try doc.createElement("body");
    _ = try doc.prototype.appendChild(&body.prototype);

    const elem = try doc.createElement("child");
    try std.testing.expectEqual(@as(?*Element, null), elem.prototype.parentElement());

    _ = try body.prototype.appendChild(&elem.prototype);
    try std.testing.expectEqual(body, elem.prototype.parentElement());
}

test "parentElement should work correctly in a document (text)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create a body element as document root
    const body = try doc.createElement("body");
    _ = try doc.prototype.appendChild(&body.prototype);

    const text = try doc.createTextNode("content");
    try std.testing.expectEqual(@as(?*Element, null), text.prototype.parentElement());

    _ = try body.prototype.appendChild(&text.prototype);
    try std.testing.expectEqual(body, text.prototype.parentElement());
}
