const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "DOMTokenList has length property" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    defer elem.prototype.release();
    try elem.setAttribute("class", "foo   Foo foo   ");

    const classList = elem.classList();
    _ = classList.length();
}

test "DOMTokenList iteration via next()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    defer elem.prototype.release();
    try elem.setAttribute("class", "foo   Foo foo   ");

    var classList = elem.classList();
    var collected = std.ArrayList([]const u8){};
    defer collected.deinit(allocator);

    while (classList.next()) |token| {
        try collected.append(allocator, token);
    }

    try std.testing.expectEqual(@as(usize, 2), collected.items.len);
    try std.testing.expectEqualStrings("foo", collected.items[0]);
    try std.testing.expectEqualStrings("Foo", collected.items[1]);
}

test "DOMTokenList iteration returns unique tokens only" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    defer elem.prototype.release();
    try elem.setAttribute("class", "foo   Foo foo   ");

    var classList = elem.classList();
    try std.testing.expectEqual(@as(usize, 2), classList.length());

    const first = classList.item(0).?;
    const second = classList.item(1).?;

    try std.testing.expectEqualStrings("foo", first);
    try std.testing.expectEqualStrings("Foo", second);
}
