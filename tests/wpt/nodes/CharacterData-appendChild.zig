// META: title=Node.appendChild applied to CharacterData
// META: link=https://dom.spec.whatwg.org/#dom-node-appendchild
// META: link=https://dom.spec.whatwg.org/#introduction-to-the-dom

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Text.appendChild(Text)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createTextNode("test");
    defer node1.prototype.release();
    const node2 = try doc.createTextNode("test");
    defer node2.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.appendChild(&node2.prototype));
}

test "Text.appendChild(Comment)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createTextNode("test");
    defer node1.prototype.release();
    const node2 = try doc.createComment("test");
    defer node2.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.appendChild(&node2.prototype));
}

test "Text.appendChild(ProcessingInstruction)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createTextNode("test");
    defer node1.prototype.release();
    const node2 = try doc.createProcessingInstruction("target", "test");
    defer node2.prototype.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.appendChild(&node2.prototype.prototype));
}

test "Comment.appendChild(Text)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createComment("test");
    defer node1.prototype.release();
    const node2 = try doc.createTextNode("test");
    defer node2.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.appendChild(&node2.prototype));
}

test "Comment.appendChild(Comment)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createComment("test");
    defer node1.prototype.release();
    const node2 = try doc.createComment("test");
    defer node2.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.appendChild(&node2.prototype));
}

test "Comment.appendChild(ProcessingInstruction)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createComment("test");
    defer node1.prototype.release();
    const node2 = try doc.createProcessingInstruction("target", "test");
    defer node2.prototype.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.appendChild(&node2.prototype.prototype));
}

test "ProcessingInstruction.appendChild(Text)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createProcessingInstruction("target", "test");
    defer node1.prototype.prototype.release();
    const node2 = try doc.createTextNode("test");
    defer node2.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.prototype.appendChild(&node2.prototype));
}

test "ProcessingInstruction.appendChild(Comment)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createProcessingInstruction("target", "test");
    defer node1.prototype.prototype.release();
    const node2 = try doc.createComment("test");
    defer node2.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.prototype.appendChild(&node2.prototype));
}

test "ProcessingInstruction.appendChild(ProcessingInstruction)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node1 = try doc.createProcessingInstruction("target", "test");
    defer node1.prototype.prototype.release();
    const node2 = try doc.createProcessingInstruction("target", "test");
    defer node2.prototype.prototype.release();

    try std.testing.expectError(error.HierarchyRequestError, node1.prototype.prototype.appendChild(&node2.prototype.prototype));
}
