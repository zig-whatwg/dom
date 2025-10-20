// META: title=Document.getElementsByTagName
// META: link=https://dom.spec.whatwg.org/#dom-document-getelementsbytagname

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const HTMLCollection = dom.HTMLCollection;

test "Document.getElementsByTagName - Interfaces" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const list = doc.getElementsByTagName("item");

    try std.testing.expect(@TypeOf(list) == HTMLCollection);
}

test "Document.getElementsByTagName - Live collection" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const list = doc.getElementsByTagName("item");

    try std.testing.expectEqual(@as(usize, 0), list.length());

    const item1 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&item1.prototype);

    try std.testing.expectEqual(@as(usize, 1), list.length());

    const item2 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&item2.prototype);

    try std.testing.expectEqual(@as(usize, 2), list.length());
}
