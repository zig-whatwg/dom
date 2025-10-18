// META: title=Document.createTextNode
// META: link=https://dom.spec.whatwg.org/#dom-document-createtextnode
// META: link=https://dom.spec.whatwg.org/#dom-node-ownerdocument
// META: link=https://dom.spec.whatwg.org/#dom-characterdata-data

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;
const Node = dom.Node;

test "createTextNode with simple string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello");

    try std.testing.expect(std.mem.eql(u8, text.data, "hello"));
    try std.testing.expectEqual(text.node.node_type, .text);
    try std.testing.expect(text.node.getOwnerDocument() == doc);
}

test "createTextNode with special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("a -- b");
    try std.testing.expect(std.mem.eql(u8, text.data, "a -- b"));
}

test "createTextNode with hyphen variations" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("a-");
    try std.testing.expect(std.mem.eql(u8, text1.data, "a-"));

    const text2 = try doc.createTextNode("-b");
    try std.testing.expect(std.mem.eql(u8, text2.data, "-b"));
}

test "createTextNode with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    try std.testing.expect(std.mem.eql(u8, text.data, ""));
    try std.testing.expectEqual(@as(usize, 0), text.data.len);
}

test "createTextNode node has no children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");

    try std.testing.expect(!text.node.hasChildNodes());
    try std.testing.expect(text.node.first_child == null);
    try std.testing.expect(text.node.last_child == null);
}

test "createTextNode sets correct nodeName" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    const name = text.node.nodeName();

    try std.testing.expect(std.mem.eql(u8, name, "#text"));
}

test "createTextNode is not connected initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    try std.testing.expect(!text.node.isConnected());
}

test "createTextNode preserves owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    try std.testing.expect(text.node.getOwnerDocument() == doc);
}
