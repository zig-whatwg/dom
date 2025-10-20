// META: title=Text.splitText()
// META: link=https://dom.spec.whatwg.org/#dom-text-splittextoffset

// NOTE: WHATWG DOM uses UTF-16 code units for string offsets (DOMString is UTF-16).
// Our implementation now correctly converts UTF-16 offsets to UTF-8 byte offsets internally.
// See string_utils.zig for conversion utilities.

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;

test "Split text after end of data" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("camembert");
    defer text.prototype.release();

    try std.testing.expectError(error.IndexSizeError, text.splitText(10));
}

test "Split empty text" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.prototype.release();

    const new_text = try text.splitText(0);
    defer new_text.prototype.release();

    try std.testing.expectEqualStrings("", text.data);
    try std.testing.expectEqualStrings("", new_text.data);
}

test "Split text at beginning" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("comté");
    defer text.prototype.release();

    const new_text = try text.splitText(0);
    defer new_text.prototype.release();

    try std.testing.expectEqualStrings("", text.data);
    try std.testing.expectEqualStrings("comté", new_text.data);
}

test "Split text at end" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // "comté" is 6 bytes in UTF-8 (é = 2 bytes), but 5 UTF-16 code units
    // Our implementation now correctly handles UTF-16 offsets
    const text = try doc.createTextNode("comté");
    defer text.prototype.release();

    const new_text = try text.splitText(5);
    defer new_text.prototype.release();

    try std.testing.expectEqualStrings("comté", text.data);
    try std.testing.expectEqualStrings("", new_text.data);
}

test "Split root" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("comté");
    defer text.prototype.release();

    const new_text = try text.splitText(3);
    defer new_text.prototype.release();

    try std.testing.expectEqualStrings("com", text.data);
    try std.testing.expectEqualStrings("té", new_text.data);
    try std.testing.expect(new_text.prototype.parent_node == null);
}

test "Split child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const text = try doc.createTextNode("bleu");
    _ = try parent.prototype.appendChild(&text.prototype);

    const new_text = try text.splitText(2);

    try std.testing.expectEqualStrings("bl", text.data);
    try std.testing.expectEqualStrings("eu", new_text.data);
    try std.testing.expect(text.prototype.next_sibling == &new_text.prototype);
    try std.testing.expect(new_text.prototype.parent_node == &parent.prototype);
}
