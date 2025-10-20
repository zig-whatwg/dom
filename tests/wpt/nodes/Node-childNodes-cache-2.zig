// META: title=Node.childNodes caching bug with replaceChild
// META: link=https://dom.spec.whatwg.org/#dom-node-childnodes

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "childNodes caching with replaceChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try doc.createElement("target");
    defer target.prototype.release();

    const first = try doc.createElement("first");
    _ = try target.prototype.appendChild(&first.prototype);

    const second = try doc.createElement("second");
    _ = try target.prototype.appendChild(&second.prototype);

    const third = try doc.createElement("third");
    _ = try target.prototype.appendChild(&third.prototype);

    const last = try doc.createElement("last");
    _ = try target.prototype.appendChild(&last.prototype);

    // Initial state: [first, second, third, last]
    const nodes1 = target.prototype.childNodes();
    try std.testing.expectEqual(@as(usize, 4), nodes1.length());
    try std.testing.expect(nodes1.item(0) == &first.prototype);
    try std.testing.expect(nodes1.item(1) == &second.prototype);
    try std.testing.expect(nodes1.item(2) == &third.prototype);
    try std.testing.expect(nodes1.item(3) == &last.prototype);

    // Replace second with third
    _ = try target.prototype.replaceChild(&third.prototype, &second.prototype);
    second.prototype.release(); // Released after removal

    // New state: [first, third, last]
    const nodes2 = target.prototype.childNodes();
    try std.testing.expectEqual(@as(usize, 3), nodes2.length());
    try std.testing.expect(nodes2.item(0) == &first.prototype);
    try std.testing.expect(nodes2.item(1) == &third.prototype);
    try std.testing.expect(nodes2.item(2) == &last.prototype);
}
