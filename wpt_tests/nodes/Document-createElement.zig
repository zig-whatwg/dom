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
    try std.testing.expect(std.mem.eql(u8, elem.tag_name, "foo"));
}

test "createElement with tag containing numbers" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("f1oo");
    try std.testing.expect(std.mem.eql(u8, elem1.tag_name, "f1oo"));

    const elem2 = try doc.createElement("foo1");
    try std.testing.expect(std.mem.eql(u8, elem2.tag_name, "foo1"));
}

test "createElement with colon in name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("f:oo");
    try std.testing.expect(std.mem.eql(u8, elem1.tag_name, "f:oo"));

    const elem2 = try doc.createElement("foo:");
    try std.testing.expect(std.mem.eql(u8, elem2.tag_name, "foo:"));

    const elem3 = try doc.createElement(":foo");
    try std.testing.expect(std.mem.eql(u8, elem3.tag_name, ":foo"));
}

test "createElement with standard HTML elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    try std.testing.expect(std.mem.eql(u8, div.tag_name, "div"));

    const span = try doc.createElement("span");
    try std.testing.expect(std.mem.eql(u8, span.tag_name, "span"));

    const p = try doc.createElement("p");
    try std.testing.expect(std.mem.eql(u8, p.tag_name, "p"));
}

test "createElement returns Element node type" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    try std.testing.expectEqual(elem.node.node_type, .element);
}

test "createElement sets owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    try std.testing.expect(elem.node.getOwnerDocument() == doc);
}

test "createElement element has no children initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    try std.testing.expect(!elem.node.hasChildNodes());
    try std.testing.expect(elem.node.first_child == null);
    try std.testing.expect(elem.node.last_child == null);
}

test "createElement element has no attributes initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    try std.testing.expect(!elem.hasAttributes());
    try std.testing.expectEqual(@as(usize, 0), elem.attributeCount());
}

test "createElement element is not connected initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    try std.testing.expect(!elem.node.isConnected());
}

test "createElement preserves case in tag name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("FOO");
    try std.testing.expect(std.mem.eql(u8, elem1.tag_name, "FOO"));

    const elem2 = try doc.createElement("FoO");
    try std.testing.expect(std.mem.eql(u8, elem2.tag_name, "FoO"));
}
