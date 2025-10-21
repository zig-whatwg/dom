// META: title=Text.textContent
// META: link=https://dom.spec.whatwg.org/#dom-node-textcontent

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Text.textContent returns text data" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello world");
    defer text.prototype.release();

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("hello world", content.?);
}

test "Text.textContent set updates data" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("original");
    defer text.prototype.release();

    try text.prototype.setTextContent("updated");

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("updated", content.?);
}

test "Text.textContent set to empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("original");
    defer text.prototype.release();

    try text.prototype.setTextContent("");

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("", content.?);
}

test "Text.textContent set to null clears data" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("original");
    defer text.prototype.release();

    try text.prototype.setTextContent(null);

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);
    try std.testing.expect(content == null or content.?.len == 0);
}
