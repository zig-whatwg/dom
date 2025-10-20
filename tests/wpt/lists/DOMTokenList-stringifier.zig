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
    const val = classList.value();
    try std.testing.expectEqualStrings("", val);
}

test "classList.value returns literal class attribute value" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   a  a b ");

    const classList = elem.classList();

    const attr = elem.getAttribute("class").?;
    try std.testing.expectEqualStrings("   a  a b ", attr);

    const val = classList.value();
    try std.testing.expectEqualStrings("   a  a b ", val);
}

test "classList.value preserves whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();
    try elem.setAttribute("class", "   a  a b ");

    const classList = elem.classList();
    try std.testing.expectEqualStrings("   a  a b ", classList.value());
}

test "classList.value is empty for no class attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const classList = elem.classList();
    try std.testing.expectEqualStrings("", classList.value());
    try std.testing.expectEqual(@as(usize, 0), classList.length());
}
