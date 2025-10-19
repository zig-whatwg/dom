// META: title=Node.appendChild
// META: link=https://dom.spec.whatwg.org/#dom-node-appendchild

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Node = dom.Node;

fn testLeaf(node: *Node, desc: []const u8, doc: *Document) !void {
    const allocator = std.testing.allocator;

    // Pre-insert step 1: Appending to a leaf node should fail
    const text = try doc.createTextNode("fail");
    defer text.prototype.release(); // Must release orphaned nodes (not inserted into tree)

    const result = node.appendChild(&text.prototype);
    try std.testing.expectError(error.HierarchyRequestError, result);

    _ = desc; // Note: desc used for test naming in WPT
    _ = allocator;
}

test "Appending to a leaf node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Test text node
    const text_node = try doc.createTextNode("Foo");
    defer text_node.prototype.release();
    try testLeaf(&text_node.prototype, "text node", doc);

    // Test comment
    const comment = try doc.createComment("Foo");
    defer comment.prototype.release();
    try testLeaf(&comment.prototype, "comment", doc);
}

test "Adopting an orphan" {
    const allocator = std.testing.allocator;

    // Create two documents (simulating main document and frame document)
    const doc = try Document.init(allocator);
    defer doc.release();

    const frame_doc = try Document.init(allocator);
    defer frame_doc.release();

    // Create body elements
    const body = try doc.createElement("body");
    _ = try doc.prototype.appendChild(&body.prototype);

    const frame_body = try frame_doc.createElement("body");
    _ = try frame_doc.prototype.appendChild(&frame_body.prototype);

    // Create element in frame document
    const s = try frame_doc.createElement("a");
    try std.testing.expect(s.prototype.getOwnerDocument() == frame_doc);

    // Append to main document body - should adopt
    _ = try body.prototype.appendChild(&s.prototype);
    try std.testing.expect(s.prototype.getOwnerDocument() == doc);
}

test "Adopting a non-orphan" {
    const allocator = std.testing.allocator;

    // Create two documents
    const doc = try Document.init(allocator);
    defer doc.release();

    const frame_doc = try Document.init(allocator);
    defer frame_doc.release();

    // Create body elements
    const body = try doc.createElement("body");
    _ = try doc.prototype.appendChild(&body.prototype);

    const frame_body = try frame_doc.createElement("body");
    _ = try frame_doc.prototype.appendChild(&frame_body.prototype);

    // Create element in frame document
    const s = try frame_doc.createElement("b");
    try std.testing.expect(s.prototype.getOwnerDocument() == frame_doc);

    // Append to frame body first
    _ = try frame_body.prototype.appendChild(&s.prototype);
    try std.testing.expect(s.prototype.getOwnerDocument() == frame_doc);

    // Now append to main document body - should adopt
    _ = try body.prototype.appendChild(&s.prototype);
    try std.testing.expect(s.prototype.getOwnerDocument() == doc);
}
