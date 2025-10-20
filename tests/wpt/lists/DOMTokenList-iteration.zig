const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "classList basic iteration" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   a  a b ");

    const list = elem.classList();
    try std.testing.expectEqual(@as(usize, 2), list.length());
    try std.testing.expectEqualStrings("a", list.item(0).?);
    try std.testing.expectEqualStrings("b", list.item(1).?);
}

test "classList.item() returns tokens in order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   a  a b ");

    const list = elem.classList();

    try std.testing.expectEqualStrings("a", list.item(0).?);
    try std.testing.expectEqualStrings("b", list.item(1).?);
    try std.testing.expectEqual(@as(?[]const u8, null), list.item(2));
}

test "classList.item() with out of bounds index" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   a  a b ");

    const list = elem.classList();

    try std.testing.expectEqual(@as(?[]const u8, null), list.item(100));
    try std.testing.expectEqual(@as(?[]const u8, null), list.item(2));
}

test "classList.length property" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   a  a b ");

    const list = elem.classList();
    try std.testing.expectEqual(@as(usize, 2), list.length());
}

test "classList with empty class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "");

    const list = elem.classList();
    try std.testing.expectEqual(@as(usize, 0), list.length());
    try std.testing.expectEqual(@as(?[]const u8, null), list.item(0));
}

test "classList with only whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   \t  \n  ");

    const list = elem.classList();
    try std.testing.expectEqual(@as(usize, 0), list.length());
}

test "classList removes duplicate tokens" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "a a a b b c a");

    const list = elem.classList();
    // Per WHATWG spec, DOMTokenList is an ordered set (unique tokens only)
    // "a a a b b c a" → [a, b, c] (3 unique tokens)
    try std.testing.expectEqual(@as(usize, 3), list.length());
}
