// META: title=DocumentFragment children access

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "DocumentFragment.firstChild and lastChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    try std.testing.expect(frag.prototype.first_child == null);
    try std.testing.expect(frag.prototype.last_child == null);

    const elem1 = try doc.createElement("first");
    _ = try frag.prototype.appendChild(&elem1.prototype);

    try std.testing.expectEqual(&elem1.prototype, frag.prototype.first_child.?);
    try std.testing.expectEqual(&elem1.prototype, frag.prototype.last_child.?);

    const elem2 = try doc.createElement("last");
    _ = try frag.prototype.appendChild(&elem2.prototype);

    try std.testing.expectEqual(&elem1.prototype, frag.prototype.first_child.?);
    try std.testing.expectEqual(&elem2.prototype, frag.prototype.last_child.?);
}

test "DocumentFragment.childNodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    const children1 = frag.prototype.childNodes();
    try std.testing.expectEqual(@as(usize, 0), children1.length());

    const elem = try doc.createElement("child");
    _ = try frag.prototype.appendChild(&elem.prototype);

    const children2 = frag.prototype.childNodes();
    try std.testing.expectEqual(@as(usize, 1), children2.length());
}
