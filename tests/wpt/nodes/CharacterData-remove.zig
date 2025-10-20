// META: title=CharacterData.remove
// META: link=https://dom.spec.whatwg.org/#dom-childnode-remove

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

// Tests for Text.remove()

test "Text should support remove()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    // Just verify the method exists and can be called
    try text.remove();
}

test "remove() should work if Text doesn't have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    try std.testing.expect(text.prototype.parent_node == null);
    try text.remove();
    try std.testing.expect(text.prototype.parent_node == null);
}

test "remove() should work if Text does have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const text = try doc.createTextNode("text");
    defer text.prototype.release(); // Must release after remove since no longer owned by parent

    try std.testing.expect(text.prototype.parent_node == null);
    _ = try parent.prototype.appendChild(&text.prototype);
    try std.testing.expect(text.prototype.parent_node == &parent.prototype);
    try text.remove();
    try std.testing.expect(text.prototype.parent_node == null);
    try std.testing.expect(parent.prototype.first_child == null);
}

test "remove() should work if Text does have a parent and siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const text = try doc.createTextNode("text");
    defer text.prototype.release(); // Must release after remove since no longer owned by parent

    try std.testing.expect(text.prototype.parent_node == null);
    const before = try doc.createComment("before");
    _ = try parent.prototype.appendChild(&before.prototype);
    _ = try parent.prototype.appendChild(&text.prototype);
    const after = try doc.createComment("after");
    _ = try parent.prototype.appendChild(&after.prototype);

    try std.testing.expect(text.prototype.parent_node == &parent.prototype);
    try text.remove();
    try std.testing.expect(text.prototype.parent_node == null);
    // Check that 2 children remain
    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling != null);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling.?.next_sibling == null);
    try std.testing.expect(parent.prototype.first_child == &before.prototype);
    try std.testing.expect(parent.prototype.last_child == &after.prototype);
}

// Tests for Comment.remove()

test "Comment should support remove()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("comment");
    defer comment.prototype.release();

    try comment.remove();
}

test "remove() should work if Comment doesn't have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("comment");
    defer comment.prototype.release();

    try std.testing.expect(comment.prototype.parent_node == null);
    try comment.remove();
    try std.testing.expect(comment.prototype.parent_node == null);
}

test "remove() should work if Comment does have a parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const comment = try doc.createComment("comment");
    defer comment.prototype.release(); // Must release after remove since no longer owned by parent

    try std.testing.expect(comment.prototype.parent_node == null);
    _ = try parent.prototype.appendChild(&comment.prototype);
    try std.testing.expect(comment.prototype.parent_node == &parent.prototype);
    try comment.remove();
    try std.testing.expect(comment.prototype.parent_node == null);
    try std.testing.expect(parent.prototype.first_child == null);
}

test "remove() should work if Comment does have a parent and siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();
    const comment = try doc.createComment("comment");
    defer comment.prototype.release(); // Must release after remove since no longer owned by parent

    try std.testing.expect(comment.prototype.parent_node == null);
    const before = try doc.createComment("before");
    _ = try parent.prototype.appendChild(&before.prototype);
    _ = try parent.prototype.appendChild(&comment.prototype);
    const after = try doc.createComment("after");
    _ = try parent.prototype.appendChild(&after.prototype);

    try std.testing.expect(comment.prototype.parent_node == &parent.prototype);
    try comment.remove();
    try std.testing.expect(comment.prototype.parent_node == null);
    // Check that 2 children remain
    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling != null);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling.?.next_sibling == null);
    try std.testing.expect(parent.prototype.first_child == &before.prototype);
    try std.testing.expect(parent.prototype.last_child == &after.prototype);
}
