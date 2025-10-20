// META: title=Document.createProcessingInstruction basic tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.createProcessingInstruction creates PI node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqualStrings("target", pi.target);
    try std.testing.expectEqualStrings("data", pi.prototype.data);
}

test "Document.createProcessingInstruction with empty data" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("target", "");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqualStrings("target", pi.target);
    try std.testing.expectEqualStrings("", pi.prototype.data);
}

test "Document.createProcessingInstruction node type" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("xml-stylesheet", "href='style.css'");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqual(dom.NodeType.processing_instruction, pi.prototype.prototype.node_type);
}

test "Document.createProcessingInstruction sets owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqual(&doc.prototype, pi.prototype.prototype.owner_document.?);
}
