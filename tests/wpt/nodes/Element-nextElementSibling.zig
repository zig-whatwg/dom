// WPT Test: Element-nextElementSibling (derived from spec requirements)
// Based on WHATWG DOM Standard § 4.3 (NonDocumentTypeChildNode mixin)
// https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-nextelementsibling

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "nextElementSibling is null when no siblings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expectEqual(@as(?*dom.Element, null), child.nextElementSibling());
}

test "nextElementSibling skips text nodes" {
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

    const next = child1.nextElementSibling();
    try std.testing.expect(next != null);
    try std.testing.expectEqualStrings("child2", next.?.tag_name);
}

test "nextElementSibling skips comment nodes" {
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

    const next = child1.nextElementSibling();
    try std.testing.expect(next != null);
    try std.testing.expectEqualStrings("child2", next.?.tag_name);
}

test "nextElementSibling with multiple siblings" {
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

    // Check chain
    const next1 = child1.nextElementSibling();
    try std.testing.expect(next1 != null);
    try std.testing.expectEqualStrings("child2", next1.?.tag_name);

    const next2 = next1.?.nextElementSibling();
    try std.testing.expect(next2 != null);
    try std.testing.expectEqualStrings("child3", next2.?.tag_name);

    const next3 = next2.?.nextElementSibling();
    try std.testing.expectEqual(@as(?*dom.Element, null), next3);
}

test "nextElementSibling returns null at end of list" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    // Text node after last element
    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(@as(?*dom.Element, null), child2.nextElementSibling());
}
