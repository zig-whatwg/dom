// META: title=Element.setAttribute and Element.getAttribute
// META: link=https://dom.spec.whatwg.org/#dom-element-setattribute
// META: link=https://dom.spec.whatwg.org/#dom-element-getattribute

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "setAttribute sets attribute value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.node.release(); // Must release orphaned nodes
    try el.setAttribute("id", "test");

    const value = el.getAttribute("id");
    try std.testing.expect(value != null);
    try std.testing.expect(std.mem.eql(u8, value.?, "test"));
}

test "getAttribute returns null for non-existent attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.node.release(); // Must release orphaned nodes
    const value = el.getAttribute("nonexistent");
    try std.testing.expect(value == null);
}

test "setAttribute overwrites existing attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.node.release(); // Must release orphaned nodes
    try el.setAttribute("class", "foo");
    try el.setAttribute("class", "bar");

    const value = el.getAttribute("class");
    try std.testing.expect(value != null);
    try std.testing.expect(std.mem.eql(u8, value.?, "bar"));
}

test "setAttribute with multiple attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.node.release(); // Must release orphaned nodes
    try el.setAttribute("id", "myid");
    try el.setAttribute("class", "myclass");
    try el.setAttribute("data-value", "123");

    const id = el.getAttribute("id");
    const class = el.getAttribute("class");
    const data = el.getAttribute("data-value");

    try std.testing.expect(id != null);
    try std.testing.expect(std.mem.eql(u8, id.?, "myid"));
    try std.testing.expect(class != null);
    try std.testing.expect(std.mem.eql(u8, class.?, "myclass"));
    try std.testing.expect(data != null);
    try std.testing.expect(std.mem.eql(u8, data.?, "123"));
}

test "setAttribute with empty string value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.node.release(); // Must release orphaned nodes
    try el.setAttribute("disabled", "");

    const value = el.getAttribute("disabled");
    try std.testing.expect(value != null);
    try std.testing.expect(std.mem.eql(u8, value.?, ""));
}
