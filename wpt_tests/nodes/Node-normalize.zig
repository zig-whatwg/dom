// WPT Test: Node-normalize
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Node-normalize.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

test "normalize merges adjacent text nodes" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    const t1 = try doc.createTextNode("1");
    const t2 = try doc.createTextNode("2");
    const t3 = try doc.createTextNode("3");
    const t4 = try doc.createTextNode("4");

    _ = try df.prototype.appendChild(&t1.prototype);
    _ = try df.prototype.appendChild(&t2.prototype);

    try std.testing.expectEqual(@as(usize, 2), df.prototype.childNodes().length());
    const text_content1 = try df.prototype.textContent(allocator);
    defer if (text_content1) |tc| allocator.free(tc);
    try std.testing.expectEqualStrings("12", text_content1.?);

    const el = try doc.createElement("x");
    _ = try df.prototype.appendChild(&el.prototype);
    _ = try el.prototype.appendChild(&t3.prototype);
    _ = try el.prototype.appendChild(&t4.prototype);

    // Document.normalize() shouldn't affect the DocumentFragment
    try doc.prototype.normalize();
    try std.testing.expectEqual(@as(usize, 2), el.prototype.childNodes().length());
    const text_content2 = try el.prototype.textContent(allocator);
    defer if (text_content2) |tc| allocator.free(tc);
    try std.testing.expectEqualStrings("34", text_content2.?);
    try std.testing.expectEqual(@as(usize, 3), df.prototype.childNodes().length());
    try std.testing.expectEqualStrings("1", t1.data);

    // DocumentFragment.normalize() should merge adjacent text nodes
    try df.prototype.normalize();
    try std.testing.expectEqual(@as(usize, 2), df.prototype.childNodes().length());
    try std.testing.expect(df.prototype.first_child == &t1.prototype);
    try std.testing.expectEqualStrings("12", t1.data);
    // Note: t2 was merged into t1 and removed from tree
    try std.testing.expect(el.prototype.first_child == &t3.prototype);
    try std.testing.expectEqualStrings("34", t3.data);
    // Note: t4 was merged into t3 and removed from tree
}

test "Empty text nodes separated by a non-empty text node" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("container");
    defer div.prototype.release();

    const t1 = try doc.createTextNode("");
    const t2 = try doc.createTextNode("a");
    const t3 = try doc.createTextNode("");

    _ = try div.prototype.appendChild(&t1.prototype);
    _ = try div.prototype.appendChild(&t2.prototype);
    _ = try div.prototype.appendChild(&t3.prototype);

    // Before normalize: 3 children
    try std.testing.expectEqual(@as(usize, 3), div.prototype.childNodes().length());

    try div.prototype.normalize();

    // After normalize: only the non-empty text node remains
    try std.testing.expectEqual(@as(usize, 1), div.prototype.childNodes().length());
    try std.testing.expect(div.prototype.first_child == &t2.prototype);
}

test "Empty text nodes" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("container");
    defer div.prototype.release();

    const t1 = try doc.createTextNode("");
    const t2 = try doc.createTextNode("");

    _ = try div.prototype.appendChild(&t1.prototype);
    _ = try div.prototype.appendChild(&t2.prototype);

    // Before normalize: 2 children
    try std.testing.expectEqual(@as(usize, 2), div.prototype.childNodes().length());

    try div.prototype.normalize();

    // After normalize: all empty text nodes removed
    try std.testing.expectEqual(@as(usize, 0), div.prototype.childNodes().length());
}

test "Non-text nodes are not affected by normalize" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("container");
    defer div.prototype.release();

    const t1 = try doc.createTextNode("a");
    const t2 = try doc.createComment("");
    const t3 = try doc.createTextNode("b");
    const t4 = try doc.createElement("el");
    const t5 = try doc.createTextNode("c");

    _ = try div.prototype.appendChild(&t1.prototype);
    _ = try div.prototype.appendChild(&t2.prototype);
    _ = try div.prototype.appendChild(&t3.prototype);
    _ = try div.prototype.appendChild(&t4.prototype);
    _ = try div.prototype.appendChild(&t5.prototype);

    // Before normalize: 5 children
    try std.testing.expectEqual(@as(usize, 5), div.prototype.childNodes().length());

    try div.prototype.normalize();

    // After normalize: structure unchanged (comment/element prevent merging)
    try std.testing.expectEqual(@as(usize, 5), div.prototype.childNodes().length());
    try std.testing.expect(div.prototype.childNodes().item(0) == &t1.prototype);
    try std.testing.expect(div.prototype.childNodes().item(1) == &t2.prototype);
    try std.testing.expect(div.prototype.childNodes().item(2) == &t3.prototype);
    try std.testing.expect(div.prototype.childNodes().item(3) == &t4.prototype);
    try std.testing.expect(div.prototype.childNodes().item(4) == &t5.prototype);
}
