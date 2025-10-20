// META: title=Node.nodeType values

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const NodeType = dom.NodeType;

test "Element.nodeType is ELEMENT_NODE" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try std.testing.expectEqual(NodeType.element, elem.prototype.node_type);
}

test "Text.nodeType is TEXT_NODE" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    try std.testing.expectEqual(NodeType.text, text.prototype.node_type);
}

test "Comment.nodeType is COMMENT_NODE" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("comment");
    defer comment.prototype.release();

    try std.testing.expectEqual(NodeType.comment, comment.prototype.node_type);
}

test "Document.nodeType is DOCUMENT_NODE" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expectEqual(NodeType.document, doc.prototype.node_type);
}

test "DocumentFragment.nodeType is DOCUMENT_FRAGMENT_NODE" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expectEqual(NodeType.document_fragment, frag.prototype.node_type);
}

test "DocumentType.nodeType is DOCUMENT_TYPE_NODE" {
    const allocator = std.testing.allocator;

    const doctype = try dom.DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqual(NodeType.document_type, doctype.prototype.node_type);
}

test "ProcessingInstruction.nodeType is PROCESSING_INSTRUCTION_NODE" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqual(NodeType.processing_instruction, pi.prototype.prototype.node_type);
}
