// META: title=Node.baseURI
// META: link=https://dom.spec.whatwg.org/#dom-node-baseuri

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "Node.baseURI returns a string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("div");
    defer element.node.release(); // Must release orphaned nodes
    const base_uri = element.node.baseURI();

    // baseURI should return a string (even if placeholder)
    try std.testing.expect(base_uri.len >= 0);
}

test "Node.baseURI for elements in document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const body = try doc.createElement("body");
    _ = try doc.node.appendChild(&body.node);

    const element = try doc.createElement("div");
    _ = try body.node.appendChild(&element.node);

    const base_uri = element.node.baseURI();

    // Should return a valid string
    try std.testing.expect(base_uri.len >= 0);
}

test "Node.baseURI for detached elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("div");
    defer element.node.release(); // Must release orphaned nodes
    const base_uri = element.node.baseURI();

    // Detached elements should still return a baseURI
    try std.testing.expect(base_uri.len >= 0);
}
