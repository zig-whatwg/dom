const std = @import("std");
const dom = @import("dom");

// Import all commonly used types
const Node = dom.Node;
const NodeType = dom.NodeType;
const NodeVTable = dom.NodeVTable;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;
const ShadowRoot = dom.ShadowRoot;

test "DocumentFragment - creation and cleanup" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.prototype.release();

    try std.testing.expect(fragment.prototype.node_type == .document_fragment);
    try std.testing.expectEqualStrings("#document-fragment", fragment.prototype.nodeName());
    try std.testing.expect(fragment.prototype.nodeValue() == null);
}

test "DocumentFragment - can hold children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.prototype.release();

    const elem1 = try doc.createElement("div");
    const elem2 = try doc.createElement("span");

    _ = try fragment.prototype.appendChild(&elem1.prototype);
    _ = try fragment.prototype.appendChild(&elem2.prototype);

    try std.testing.expect(fragment.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), fragment.prototype.childNodes().length());
}

test "DocumentFragment - clone shallow" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    const elem = try doc.createElement("div");
    _ = try fragment.prototype.appendChild(&elem.prototype);

    // Shallow clone
    const clone = try fragment.prototype.cloneNode(false);
    defer clone.release();

    try std.testing.expect(clone.node_type == .document_fragment);
    try std.testing.expect(!clone.hasChildNodes());
}

test "DocumentFragment - clone deep" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    const elem = try doc.createElement("div");
    _ = try fragment.prototype.appendChild(&elem.prototype);

    // Deep clone
    const clone = try fragment.prototype.cloneNode(true);
    defer clone.release();

    try std.testing.expect(clone.node_type == .document_fragment);
    try std.testing.expect(clone.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 1), clone.childNodes().length());
}

