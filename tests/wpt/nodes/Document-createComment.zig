// META: title=Document.createComment
// META: link=https://dom.spec.whatwg.org/#dom-document-createcomment
// META: link=https://dom.spec.whatwg.org/#dom-node-ownerdocument
// META: link=https://dom.spec.whatwg.org/#dom-characterdata-data
// META: link=https://dom.spec.whatwg.org/#dom-node-nodevalue
// META: link=https://dom.spec.whatwg.org/#dom-node-textcontent
// META: link=https://dom.spec.whatwg.org/#dom-node-nodetype
// META: link=https://dom.spec.whatwg.org/#dom-node-haschildnodes
// META: link=https://dom.spec.whatwg.org/#dom-node-childnodes

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Comment = dom.Comment;
const Node = dom.Node;
const NodeType = dom.NodeType;

fn testCreateComment(doc: *Document, value: []const u8, desc: []const u8) !void {
    const allocator = std.testing.allocator;

    const comment = try doc.createComment(value);
    defer comment.prototype.release();

    // Check type
    try std.testing.expect(comment.prototype.node_type == .comment);

    // Check owner document
    try std.testing.expect(comment.prototype.getOwnerDocument() == doc);

    // Check data
    try std.testing.expectEqualStrings(value, comment.data);

    // Check nodeValue
    const node_value = comment.prototype.nodeValue();
    try std.testing.expect(node_value != null);
    try std.testing.expectEqualStrings(value, node_value.?);

    // Check textContent
    const text_content = try comment.prototype.textContent(allocator);
    defer if (text_content) |tc| allocator.free(tc);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings(value, text_content.?);

    // Check nodeType
    try std.testing.expectEqual(@as(u8, 8), comment.prototype.node_type.value());

    // Check nodeName
    try std.testing.expectEqualStrings("#comment", comment.prototype.nodeName());

    // Check hasChildNodes
    try std.testing.expectEqual(false, comment.prototype.hasChildNodes());

    // Check childNodes
    const child_nodes = comment.prototype.childNodes();
    try std.testing.expectEqual(@as(usize, 0), child_nodes.length());

    // Check firstChild
    try std.testing.expectEqual(@as(?*Node, null), comment.prototype.first_child);

    // Check lastChild
    try std.testing.expectEqual(@as(?*Node, null), comment.prototype.last_child);

    _ = desc; // Used for test description
}

test "createComment(\"\u{000b}\")" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try testCreateComment(doc, "\u{000b}", "vertical tab character");
}

test "createComment(\"a -- b\")" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try testCreateComment(doc, "a -- b", "double dash in comment");
}

test "createComment(\"a-\")" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try testCreateComment(doc, "a-", "trailing dash");
}

test "createComment(\"-b\")" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try testCreateComment(doc, "-b", "leading dash");
}

test "createComment(\"null\")" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // In JavaScript, null becomes string "null"
    try testCreateComment(doc, "null", "null as string");
}

test "createComment(\"undefined\")" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // In JavaScript, undefined becomes string "undefined"
    try testCreateComment(doc, "undefined", "undefined as string");
}

test "createComment with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try testCreateComment(doc, "", "empty string");
}

test "createComment with simple text" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try testCreateComment(doc, "Hello, World!", "simple text");
}
