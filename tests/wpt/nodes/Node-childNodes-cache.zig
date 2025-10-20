// META: title=Node.childNodes caching bug
// META: link=https://bugzilla.mozilla.org/show_bug.cgi?id=1919031
// META: link=https://dom.spec.whatwg.org/#dom-node-childnodes

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "childNodes updates correctly after node removal" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create target element with 4 children
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

    // Get child_nodes (NodeList)
    var child_nodes = target.prototype.childNodes();

    // Verify second child (index 1)
    try std.testing.expectEqual(@as(usize, 4), child_nodes.length());
    const second_node = child_nodes.item(1);
    try std.testing.expect(second_node != null);
    const second_elem: *Element = @fieldParentPtr("prototype", second_node.?);
    try std.testing.expectEqualStrings("second", second_elem.tag_name);

    // Remove second child
    try second_elem.remove();

    // Test: Out of bounds elements return null (not undefined in Zig)
    try std.testing.expectEqual(@as(?*dom.Node, null), child_nodes.item(4));
    try std.testing.expectEqual(@as(?*dom.Node, null), child_nodes.item(3));

    // Test: Length is now 3
    try std.testing.expectEqual(@as(usize, 3), child_nodes.length());

    // Test: Remaining children are in correct order
    const child0 = child_nodes.item(0).?;
    const elem0: *Element = @fieldParentPtr("prototype", child0);
    try std.testing.expectEqualStrings("first", elem0.tag_name);

    const child1 = child_nodes.item(1).?;
    const elem1: *Element = @fieldParentPtr("prototype", child1);
    try std.testing.expectEqualStrings("third", elem1.tag_name);

    const child2 = child_nodes.item(2).?;
    const elem2: *Element = @fieldParentPtr("prototype", child2);
    try std.testing.expectEqualStrings("last", elem2.tag_name);

    // Release second since it's no longer in the tree
    second.prototype.release();
}
