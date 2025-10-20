// META: title=Document.createProcessingInstruction in XML documents
// META: link=https://dom.spec.whatwg.org/#dom-document-createprocessinginstruction
// META: link=https://dom.spec.whatwg.org/#dom-processinginstruction-target
// META: link=https://dom.spec.whatwg.org/#dom-characterdata-data
// META: link=https://dom.spec.whatwg.org/#dom-node-ownerdocument

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const ProcessingInstruction = dom.ProcessingInstruction;
const Node = dom.Node;

// Note: WHATWG spec has many INVALID_CHARACTER_ERR cases for target validation.
// We test only the valid cases here for basic functionality.

test "Should get a ProcessingInstruction for target 'xml:fail' and data 'x'" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("xml:fail", "x");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqualStrings("xml:fail", pi.target);
    try std.testing.expectEqualStrings("x", pi.prototype.data);
    try std.testing.expect(pi.prototype.prototype.owner_document == &doc.prototype);
    try std.testing.expect(pi.prototype.prototype.node_type == .processing_instruction);
}

test "Should get a ProcessingInstruction for target 'A·A' and data 'x'" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("A·A", "x");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqualStrings("A·A", pi.target);
    try std.testing.expectEqualStrings("x", pi.prototype.data);
    try std.testing.expect(pi.prototype.prototype.owner_document == &doc.prototype);
    try std.testing.expect(pi.prototype.prototype.node_type == .processing_instruction);
}

test "Should get a ProcessingInstruction for target 'a0' and data 'x'" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("a0", "x");
    defer pi.prototype.prototype.release();

    try std.testing.expectEqualStrings("a0", pi.target);
    try std.testing.expectEqualStrings("x", pi.prototype.data);
    try std.testing.expect(pi.prototype.prototype.owner_document == &doc.prototype);
    try std.testing.expect(pi.prototype.prototype.node_type == .processing_instruction);
}
