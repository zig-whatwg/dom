// META: title=Text.wholeText simple tests

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Text.wholeText with single text node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("single");
    defer text.prototype.release();

    const whole = try text.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("single", whole);
}

test "Text.wholeText with adjacent text nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text1 = try doc.createTextNode("Hello");
    _ = try parent.prototype.appendChild(&text1.prototype);

    const text2 = try doc.createTextNode(" ");
    _ = try parent.prototype.appendChild(&text2.prototype);

    const text3 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text3.prototype);

    const whole = try text2.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("Hello World", whole);
}

test "Text.wholeText with element interrupting" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const text1 = try doc.createTextNode("Before");
    _ = try parent.prototype.appendChild(&text1.prototype);

    const elem = try doc.createElement("element");
    _ = try parent.prototype.appendChild(&elem.prototype);

    const text2 = try doc.createTextNode("After");
    _ = try parent.prototype.appendChild(&text2.prototype);

    const whole1 = try text1.wholeText(allocator);
    defer allocator.free(whole1);
    try std.testing.expectEqualStrings("Before", whole1);

    const whole2 = try text2.wholeText(allocator);
    defer allocator.free(whole2);
    try std.testing.expectEqualStrings("After", whole2);
}
