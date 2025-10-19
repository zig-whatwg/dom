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
    defer text.prototype.release(); // Must release orphaned nodes

    try std.testing.expect(std.mem.eql(u8, text.data, "hello"));
    try std.testing.expectEqual(text.prototype.node_type, .text);
    try std.testing.expect(text.prototype.getOwnerDocument() == doc);
}

test "createTextNode with special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("a -- b");
    defer text.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, text.data, "a -- b"));
}

test "createTextNode with hyphen variations" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("a-");
    defer text1.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, text1.data, "a-"));

    const text2 = try doc.createTextNode("-b");
    defer text2.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, text2.data, "-b"));
}

test "createTextNode with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(std.mem.eql(u8, text.data, ""));
    try std.testing.expectEqual(@as(usize, 0), text.data.len);
}

test "createTextNode node has no children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release(); // Must release orphaned nodes

    try std.testing.expect(!text.prototype.hasChildNodes());
    try std.testing.expect(text.prototype.first_child == null);
    try std.testing.expect(text.prototype.last_child == null);
}

test "createTextNode sets correct nodeName" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release(); // Must release orphaned nodes
    const name = text.prototype.nodeName();

    try std.testing.expect(std.mem.eql(u8, name, "#text"));
}

test "createTextNode is not connected initially" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(!text.prototype.isConnected());
}

test "createTextNode preserves owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("test");
    defer text.prototype.release(); // Must release orphaned nodes
    try std.testing.expect(text.prototype.getOwnerDocument() == doc);
}
