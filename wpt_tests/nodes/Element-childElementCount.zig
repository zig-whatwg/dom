// WPT Test: Element-childElementCount
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Element-childElementCount.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

test "childElementCount counts only element children" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Initially 0
    try std.testing.expectEqual(@as(u32, 0), parent.childElementCount());

    // Add text node (should not be counted)
    const text1 = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text1.prototype);
    try std.testing.expectEqual(@as(u32, 0), parent.childElementCount());

    // Add first element
    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);
    try std.testing.expectEqual(@as(u32, 1), parent.childElementCount());

    // Add comment (should not be counted)
    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);
    try std.testing.expectEqual(@as(u32, 1), parent.childElementCount());

    // Add second element
    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);
    try std.testing.expectEqual(@as(u32, 2), parent.childElementCount());

    // Add more text (should not be counted)
    const text2 = try doc.createTextNode("more text");
    _ = try parent.prototype.appendChild(&text2.prototype);
    try std.testing.expectEqual(@as(u32, 2), parent.childElementCount());

    // Add third element
    const child3 = try doc.createElement("child3");
    _ = try parent.prototype.appendChild(&child3.prototype);
    try std.testing.expectEqual(@as(u32, 3), parent.childElementCount());

    // Remove an element
    _ = try parent.prototype.removeChild(&child2.prototype);
    child2.prototype.release(); // Explicit release after removal
    try std.testing.expectEqual(@as(u32, 2), parent.childElementCount());
}
