// WPT Test: Element-previousElementSibling (derived from spec requirements)
// Based on WHATWG DOM Standard § 4.3 (NonDocumentTypeChildNode mixin)
// https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-previouselementsibling

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "previousElementSibling is null when no siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(@as(?*dom.Element, null), child.previousElementSibling());
}

test "previousElementSibling skips text nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    // Add text node between elements
    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const prev = child2.previousElementSibling();
    try std.testing.expect(prev != null);
    try std.testing.expectEqualStrings("child1", prev.?.tag_name);
}

test "previousElementSibling skips comment nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    // Add comment node between elements
    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const prev = child2.previousElementSibling();
    try std.testing.expect(prev != null);
    try std.testing.expectEqualStrings("child1", prev.?.tag_name);
}

test "previousElementSibling with multiple siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const child3 = try doc.createElement("child3");
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Check chain backwards
    const prev1 = child3.previousElementSibling();
    try std.testing.expect(prev1 != null);
    try std.testing.expectEqualStrings("child2", prev1.?.tag_name);

    const prev2 = prev1.?.previousElementSibling();
    try std.testing.expect(prev2 != null);
    try std.testing.expectEqualStrings("child1", prev2.?.tag_name);

    const prev3 = prev2.?.previousElementSibling();
    try std.testing.expectEqual(@as(?*dom.Element, null), prev3);
}

test "previousElementSibling returns null at start of list" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Text node before first element
    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    try std.testing.expectEqual(@as(?*dom.Element, null), child1.previousElementSibling());
}
