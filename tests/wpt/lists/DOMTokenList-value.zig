const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "classList.value returns empty string for undefined class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectEqualStrings("", classList.value());
}

test "classList.value returns literal value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   a  a b ");

    const classList = elem.classList();
    try std.testing.expectEqualStrings("   a  a b ", classList.value());
}

test "classList.setValue sets literal value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   a  a b ");

    const classList = elem.classList();
    try classList.setValue(" foo bar foo ");

    try std.testing.expectEqualStrings(" foo bar foo ", classList.value());
    // DOMTokenList is an ordered set, so "foo" appears only once → length = 2
    try std.testing.expectEqual(@as(usize, 2), classList.length());
}

test "classList.setValue updates class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.setValue("foo bar");

    const attr = elem.getAttribute("class").?;
    try std.testing.expectEqualStrings("foo bar", attr);
}

test "classList.length reflects token count not literal characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try classList.setValue(" foo bar foo ");

    // DOMTokenList is an ordered set, so "foo" appears only once → length = 2
    try std.testing.expectEqual(@as(usize, 2), classList.length());
}

test "classList.setValue with empty string removes class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "foo bar");

    const classList = elem.classList();
    try classList.setValue("");

    try std.testing.expectEqual(@as(?[]const u8, null), elem.getAttribute("class"));
    try std.testing.expectEqualStrings("", classList.value());
}
