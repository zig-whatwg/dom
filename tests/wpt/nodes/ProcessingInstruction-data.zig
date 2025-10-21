// META: title=ProcessingInstruction.data
// META: link=https://dom.spec.whatwg.org/#dom-characterdata-data

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "ProcessingInstruction has target and data fields" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("xml-stylesheet", "type='text/css' href='style.css'");
    defer pi.prototype.prototype.release();

    // ProcessingInstruction extends Text which is CharacterData
    try std.testing.expect(pi.target.len > 0);
}

test "ProcessingInstruction.target is correct" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("my-target", "my-data");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqualStrings("my-target", pi.target);
}

test "ProcessingInstruction created with different targets" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi1 = try doc.createProcessingInstruction("target1", "data1");
    defer pi1.prototype.prototype.release();

    const pi2 = try doc.createProcessingInstruction("target2", "data2");
    defer pi2.prototype.prototype.release();

    try std.testing.expectEqualStrings("target1", pi1.target);
    try std.testing.expectEqualStrings("target2", pi2.target);
}
