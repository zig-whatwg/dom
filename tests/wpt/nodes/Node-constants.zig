// META: title=Node constants
// META: link=https://dom.spec.whatwg.org/#interface-node

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Node = dom.Node;
const NodeType = dom.NodeType;

test "Node.NodeType constants have correct values" {
    try std.testing.expectEqual(@as(u8, 1), NodeType.element.value());
    try std.testing.expectEqual(@as(u8, 2), NodeType.attribute.value());
    try std.testing.expectEqual(@as(u8, 3), NodeType.text.value());
    try std.testing.expectEqual(@as(u8, 4), NodeType.cdata_section.value());
    try std.testing.expectEqual(@as(u8, 7), NodeType.processing_instruction.value());
    try std.testing.expectEqual(@as(u8, 8), NodeType.comment.value());
    try std.testing.expectEqual(@as(u8, 9), NodeType.document.value());
    try std.testing.expectEqual(@as(u8, 10), NodeType.document_type.value());
    try std.testing.expectEqual(@as(u8, 11), NodeType.document_fragment.value());
}

test "Node document position constants have correct values" {
    try std.testing.expectEqual(@as(u16, 0x01), Node.DOCUMENT_POSITION_DISCONNECTED);
    try std.testing.expectEqual(@as(u16, 0x02), Node.DOCUMENT_POSITION_PRECEDING);
    try std.testing.expectEqual(@as(u16, 0x04), Node.DOCUMENT_POSITION_FOLLOWING);
    try std.testing.expectEqual(@as(u16, 0x08), Node.DOCUMENT_POSITION_CONTAINS);
    try std.testing.expectEqual(@as(u16, 0x10), Node.DOCUMENT_POSITION_CONTAINED_BY);
    try std.testing.expectEqual(@as(u16, 0x20), Node.DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC);
}

test "Element node has correct nodeType" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try std.testing.expectEqual(NodeType.element, elem.prototype.node_type);
    try std.testing.expectEqual(@as(u8, 1), elem.prototype.node_type.value());
}

test "Text node has correct nodeType" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();
    try std.testing.expectEqual(NodeType.text, text.prototype.node_type);
    try std.testing.expectEqual(@as(u8, 3), text.prototype.node_type.value());
}

test "Document node has correct nodeType" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expectEqual(NodeType.document, doc.prototype.node_type);
    try std.testing.expectEqual(@as(u8, 9), doc.prototype.node_type.value());
}

test "Comment node has correct nodeType" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("comment");
    defer comment.prototype.release();
    try std.testing.expectEqual(NodeType.comment, comment.prototype.node_type);
    try std.testing.expectEqual(@as(u8, 8), comment.prototype.node_type.value());
}

test "DocumentFragment node has correct nodeType" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    try std.testing.expectEqual(NodeType.document_fragment, fragment.prototype.node_type);
    try std.testing.expectEqual(@as(u8, 11), fragment.prototype.node_type.value());
}

test "DocumentType node has correct nodeType" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    defer doctype.prototype.release();
    try std.testing.expectEqual(NodeType.document_type, doctype.prototype.node_type);
    try std.testing.expectEqual(@as(u8, 10), doctype.prototype.node_type.value());
}

test "ProcessingInstruction node has correct nodeType" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("xml", "version=\"1.0\"");
    defer pi.prototype.prototype.release();
    try std.testing.expectEqual(NodeType.processing_instruction, pi.prototype.prototype.node_type);
    try std.testing.expectEqual(@as(u8, 7), pi.prototype.prototype.node_type.value());
}
