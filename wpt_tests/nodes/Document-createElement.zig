// META: title=Document.createElement
// META: link=https://dom.spec.whatwg.org/#dom-document-createelement
// META: link=https://dom.spec.whatwg.org/#dom-element-localname
// META: link=https://dom.spec.whatwg.org/#dom-element-tagname

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "createElement with simple tag name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("foo");
    defer elem.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, elem.tag_name, "foo"));
}

test "createElement with tag containing numbers" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("f1oo");
    defer elem1.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, elem1.tag_name, "f1oo"));

    const elem2 = try doc.createElement("foo1");
    defer elem2.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, elem2.tag_name, "foo1"));
}

test "createElement with colon in name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("f:oo");
    defer elem1.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, elem1.tag_name, "f:oo"));

    const elem2 = try doc.createElement("foo:");
    defer elem2.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, elem2.tag_name, "foo:"));

    const elem3 = try doc.createElement(":foo");
    defer elem3.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, elem3.tag_name, ":foo"));
}

test "createElement with standard HTML elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, div.tag_name, "div"));

    const span = try doc.createElement("span");
    defer span.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, span.tag_name, "span"));

    const p = try doc.createElement("p");
    defer p.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, p.tag_name, "p"));
}

test "createElement returns Element node type" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    defer elem.prototype.release(); // Must release orphaned nodes
    try std.testing.expectEqual(elem.prototype.node_type, .element);
}

test "createElement sets owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(elem.prototype.getOwnerDocument() == doc);
}

test "createElement element has no children initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(!elem.prototype.hasChildNodes());
    try std.testing.expect(elem.prototype.first_child == null);
    try std.testing.expect(elem.prototype.last_child == null);
}

test "createElement element has no attributes initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(!elem.hasAttributes());
    try std.testing.expectEqual(@as(usize, 0), elem.attributeCount());
}

test "createElement element is not connected initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(!elem.prototype.isConnected());
}

test "createElement preserves case in tag name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("FOO");
    defer elem1.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, elem1.tag_name, "FOO"));

    const elem2 = try doc.createElement("FoO");
    defer elem2.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, elem2.tag_name, "FoO"));
}
