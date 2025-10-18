// META: title=Element.prototype.hasAttribute
// META: link=https://dom.spec.whatwg.org/#dom-element-hasattribute

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "hasAttribute returns false for non-existent attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("p");
    defer el.node.release(); // Must release orphaned nodes
    try std.testing.expect(!el.hasAttribute("nonexistent"));
}

test "hasAttribute returns true for existing attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("p");
    defer el.node.release(); // Must release orphaned nodes
    try el.setAttribute("x", "first");

    try std.testing.expect(el.hasAttribute("x"));
}

test "hasAttribute after setAttribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("span");
    defer el.node.release(); // Must release orphaned nodes
    try el.setAttribute("data-e2", "2");
    try el.setAttribute("data-F2", "3");
    try el.setAttribute("id", "t");

    try std.testing.expect(el.hasAttribute("data-e2"));
    try std.testing.expect(el.hasAttribute("data-F2"));
    try std.testing.expect(el.hasAttribute("id"));
}

test "hasAttribute returns false after removeAttribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("p");
    defer el.node.release(); // Must release orphaned nodes
    try el.setAttribute("test", "value");
    try std.testing.expect(el.hasAttribute("test"));

    el.removeAttribute("test");
    try std.testing.expect(!el.hasAttribute("test"));
}
