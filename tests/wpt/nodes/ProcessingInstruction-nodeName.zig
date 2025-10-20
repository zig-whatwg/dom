// META: title=ProcessingInstruction.nodeName

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "ProcessingInstruction.nodeName returns target" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("xml-stylesheet", "href='style.css'");
    defer pi.prototype.prototype.release();

    const node_name = pi.prototype.prototype.nodeName();
    try std.testing.expectEqualStrings("xml-stylesheet", node_name);
}

test "ProcessingInstruction.nodeName with different target" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("custom-pi", "data");
    defer pi.prototype.prototype.release();

    const node_name = pi.prototype.prototype.nodeName();
    try std.testing.expectEqualStrings("custom-pi", node_name);
}
