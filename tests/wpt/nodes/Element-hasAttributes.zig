// WPT Test: Element-hasAttributes
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Element-hasAttributes.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

test "hasAttributes() must return false when the element does not have attribute" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const button_element = try doc.createElement("button");
    defer button_element.prototype.release();

    try std.testing.expectEqual(false, button_element.hasAttributes());

    const empty_div = try doc.createElement("div");
    defer empty_div.prototype.release();

    try std.testing.expectEqual(false, empty_div.hasAttributes());
}

test "hasAttributes() must return true when the element has attribute" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    // Element with id attribute
    const div_with_id = try doc.createElement("div");
    defer div_with_id.prototype.release();

    try div_with_id.setAttribute("id", "foo");
    try std.testing.expectEqual(true, div_with_id.hasAttributes());

    // Element with class attribute
    const div_with_class = try doc.createElement("div");
    defer div_with_class.prototype.release();

    try div_with_class.setAttribute("class", "foo");
    try std.testing.expectEqual(true, div_with_class.hasAttributes());

    // Element with custom attribute
    const p_with_custom = try doc.createElement("p");
    defer p_with_custom.prototype.release();

    try p_with_custom.setAttribute("data-foo", "");
    try std.testing.expectEqual(true, p_with_custom.hasAttributes());

    const div_with_custom = try doc.createElement("div");
    defer div_with_custom.prototype.release();

    try div_with_custom.setAttribute("data-custom", "foo");
    try std.testing.expectEqual(true, div_with_custom.hasAttributes());
}
