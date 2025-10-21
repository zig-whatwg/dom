// META: title=Text.nodeName
// META: link=https://dom.spec.whatwg.org/#dom-node-nodename

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Text.nodeName returns #text" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("#text", text.prototype.nodeName());
}

test "Text.nodeName is constant" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("first");
    defer text1.prototype.release();

    const text2 = try doc.createTextNode("second");
    defer text2.prototype.release();

    try std.testing.expectEqualStrings("#text", text1.prototype.nodeName());
    try std.testing.expectEqualStrings("#text", text2.prototype.nodeName());
}
