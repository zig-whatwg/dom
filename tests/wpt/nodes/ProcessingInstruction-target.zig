// META: title=ProcessingInstruction.target

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const NodeType = dom.NodeType;

test "ProcessingInstruction.target basic" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("xml-stylesheet", "href='style.css'");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqualStrings("xml-stylesheet", pi.target);
}

test "ProcessingInstruction.target is readonly" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("target1", "data1");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqualStrings("target1", pi.target);
    // target is read-only in spec, cannot change
}

test "ProcessingInstruction node type" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("test", "data");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqual(NodeType.processing_instruction, pi.prototype.prototype.node_type);
}
