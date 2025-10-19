// WPT Test: Element-tagName
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Element-tagName.html
// Translated from JavaScript to Zig
//
// Note: Generic DOM library does not normalize tag names based on namespace.
// HTML-specific behavior (case normalization) should be implemented by HTML library extensions.

const std = @import("std");
const dom = @import("dom");

test "Element.tagName returns the tag name" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    try std.testing.expectEqualStrings("div", elem1.tag_name);
    try std.testing.expectEqualStrings("div", elem1.prototype.nodeName());

    const elem2 = try doc.createElement("SPAN");
    defer elem2.prototype.release();

    try std.testing.expectEqualStrings("SPAN", elem2.tag_name);
    try std.testing.expectEqualStrings("SPAN", elem2.prototype.nodeName());
}

test "Element.tagName for mixed case" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("mixedCase");
    defer elem.prototype.release();

    // Generic DOM preserves case as-is
    try std.testing.expectEqualStrings("mixedCase", elem.tag_name);
}

test "Element.tagName with qualified names" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("foo:bar");
    defer elem.prototype.release();

    // Generic DOM preserves qualified names as-is
    try std.testing.expectEqualStrings("foo:bar", elem.tag_name);
}
