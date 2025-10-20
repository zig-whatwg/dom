// META: title=DocumentFragment.querySelectorAll after modification

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "DocumentFragment children are accessible after modifications" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    const elem1 = try doc.createElement("elem1");
    _ = try frag.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("elem2");
    _ = try frag.prototype.appendChild(&elem2.prototype);

    try std.testing.expectEqual(&elem1.prototype, frag.prototype.first_child.?);
    try std.testing.expectEqual(&elem2.prototype, frag.prototype.last_child.?);

    // Remove first child
    const removed = try frag.prototype.removeChild(&elem1.prototype);
    removed.release();

    try std.testing.expectEqual(&elem2.prototype, frag.prototype.first_child.?);
}
