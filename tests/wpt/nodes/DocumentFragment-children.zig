// META: title=DocumentFragment children

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "DocumentFragment can contain elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    const elem = try doc.createElement("item");
    _ = try frag.prototype.appendChild(&elem.prototype);

    try std.testing.expect(frag.prototype.hasChildNodes());
}

test "DocumentFragment can contain text nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    const text = try doc.createTextNode("hello");
    _ = try frag.prototype.appendChild(&text.prototype);

    try std.testing.expect(frag.prototype.hasChildNodes());
}

test "DocumentFragment can contain multiple children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    const elem1 = try doc.createElement("first");
    const elem2 = try doc.createElement("second");
    const text = try doc.createTextNode("text");

    _ = try frag.prototype.appendChild(&elem1.prototype);
    _ = try frag.prototype.appendChild(&elem2.prototype);
    _ = try frag.prototype.appendChild(&text.prototype);

    try std.testing.expect(frag.prototype.hasChildNodes());
    // Verify we have 3 children by counting
    var count: u32 = 0;
    var child = frag.prototype.first_child;
    while (child) |c| : (child = c.next_sibling) {
        count += 1;
    }
    try std.testing.expectEqual(@as(u32, 3), count);
}
