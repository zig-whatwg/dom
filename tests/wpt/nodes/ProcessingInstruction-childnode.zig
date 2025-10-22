// META: title=ProcessingInstruction ChildNode and NonDocumentTypeChildNode
// META: link=https://dom.spec.whatwg.org/#interface-childnode
// META: link=https://dom.spec.whatwg.org/#interface-nondocumenttypechildnode

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;

// ================================================================
// ChildNode.remove() tests
// ================================================================

test "ProcessingInstruction should support remove()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();

    // Just verify the method exists and can be called
    try pi.remove();
}

test "remove() should work if ProcessingInstruction doesn't have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();

    try std.testing.expect(pi.prototype.prototype.parent_node == null);
    try pi.remove();
    try std.testing.expect(pi.prototype.prototype.parent_node == null);
}

test "remove() should work if ProcessingInstruction does have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();

    try std.testing.expect(pi.prototype.prototype.parent_node == null);
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);
    try std.testing.expect(pi.prototype.prototype.parent_node == &parent.prototype);
    try pi.remove();
    try std.testing.expect(pi.prototype.prototype.parent_node == null);
    try std.testing.expect(parent.prototype.first_child == null);
}

test "remove() should work if ProcessingInstruction does have a parent and siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();

    try std.testing.expect(pi.prototype.prototype.parent_node == null);
    const before = try doc.createComment("before");
    _ = try parent.prototype.appendChild(&before.prototype);
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);
    const after = try doc.createComment("after");
    _ = try parent.prototype.appendChild(&after.prototype);

    try std.testing.expect(pi.prototype.prototype.parent_node == &parent.prototype);
    try pi.remove();
    try std.testing.expect(pi.prototype.prototype.parent_node == null);
    // Check that 2 children remain
    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling != null);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling.?.next_sibling == null);
    try std.testing.expect(parent.prototype.first_child == &before.prototype);
    try std.testing.expect(parent.prototype.last_child == &after.prototype);
}

// ================================================================
// ChildNode.before() tests
// ================================================================

test "ProcessingInstruction should support before() with node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const text = try doc.createTextNode("before");
    const nodes = [_]Text.NodeOrString{
        .{ .node = &text.prototype },
    };
    try pi.before(&nodes);

    try std.testing.expect(parent.prototype.first_child == &text.prototype);
    try std.testing.expect(text.prototype.next_sibling == &pi.prototype.prototype);
}

test "ProcessingInstruction before() with string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const nodes = [_]Text.NodeOrString{
        .{ .string = "before text" },
    };
    try pi.before(&nodes);

    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling == &pi.prototype.prototype);
}

// ================================================================
// ChildNode.after() tests
// ================================================================

test "ProcessingInstruction should support after() with node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const text = try doc.createTextNode("after");
    const nodes = [_]Text.NodeOrString{
        .{ .node = &text.prototype },
    };
    try pi.after(&nodes);

    try std.testing.expect(parent.prototype.first_child == &pi.prototype.prototype);
    try std.testing.expect(pi.prototype.prototype.next_sibling == &text.prototype);
    try std.testing.expect(parent.prototype.last_child == &text.prototype);
}

test "ProcessingInstruction after() with string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const nodes = [_]Text.NodeOrString{
        .{ .string = "after text" },
    };
    try pi.after(&nodes);

    try std.testing.expect(parent.prototype.first_child == &pi.prototype.prototype);
    try std.testing.expect(pi.prototype.prototype.next_sibling != null);
    try std.testing.expect(parent.prototype.last_child != &pi.prototype.prototype);
}

// ================================================================
// ChildNode.replaceWith() tests
// ================================================================

test "ProcessingInstruction should support replaceWith() with node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const text = try doc.createTextNode("replacement");
    const nodes = [_]Text.NodeOrString{
        .{ .node = &text.prototype },
    };
    try pi.replaceWith(&nodes);

    try std.testing.expect(parent.prototype.first_child == &text.prototype);
    try std.testing.expect(parent.prototype.last_child == &text.prototype);
    try std.testing.expect(pi.prototype.prototype.parent_node == null);
}

test "ProcessingInstruction replaceWith() with string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const nodes = [_]Text.NodeOrString{
        .{ .string = "replacement text" },
    };
    try pi.replaceWith(&nodes);

    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expect(pi.prototype.prototype.parent_node == null);
}

test "ProcessingInstruction replaceWith() with multiple nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    defer pi.prototype.prototype.release();
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const text1 = try doc.createTextNode("first");
    const text2 = try doc.createTextNode("second");
    const nodes = [_]Text.NodeOrString{
        .{ .node = &text1.prototype },
        .{ .node = &text2.prototype },
    };
    try pi.replaceWith(&nodes);

    try std.testing.expect(parent.prototype.first_child == &text1.prototype);
    try std.testing.expect(text1.prototype.next_sibling == &text2.prototype);
    try std.testing.expect(parent.prototype.last_child == &text2.prototype);
    try std.testing.expect(pi.prototype.prototype.parent_node == null);
}

// ================================================================
// NonDocumentTypeChildNode.previousElementSibling tests
// ================================================================

test "ProcessingInstruction previousElementSibling returns null when no siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    try std.testing.expect(pi.previousElementSibling() == null);
}

test "ProcessingInstruction previousElementSibling skips non-element nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const elem = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&elem.prototype);

    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const prev = pi.previousElementSibling();
    try std.testing.expect(prev != null);
    try std.testing.expect(prev.? == elem);
}

test "ProcessingInstruction previousElementSibling returns immediate element sibling" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const elem = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&elem.prototype);

    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const prev = pi.previousElementSibling();
    try std.testing.expect(prev != null);
    try std.testing.expect(prev.? == elem);
}

// ================================================================
// NonDocumentTypeChildNode.nextElementSibling tests
// ================================================================

test "ProcessingInstruction nextElementSibling returns null when no siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    try std.testing.expect(pi.nextElementSibling() == null);
}

test "ProcessingInstruction nextElementSibling skips non-element nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    const elem = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&elem.prototype);

    const next = pi.nextElementSibling();
    try std.testing.expect(next != null);
    try std.testing.expect(next.? == elem);
}

test "ProcessingInstruction nextElementSibling returns immediate element sibling" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const pi = try doc.createProcessingInstruction("target", "data");
    _ = try parent.prototype.appendChild(&pi.prototype.prototype);

    const elem = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&elem.prototype);

    const next = pi.nextElementSibling();
    try std.testing.expect(next != null);
    try std.testing.expect(next.? == elem);
}
