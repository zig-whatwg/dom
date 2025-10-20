const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "HTMLCollection.item() with negative indices returns null" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo1 = try doc.createElement("widget");
    try foo1.setId("-2");
    _ = try root.prototype.appendChild(&foo1.prototype);

    const foo2 = try doc.createElement("widget");
    try foo2.setId("-1");
    _ = try root.prototype.appendChild(&foo2.prototype);

    const collection = doc.getElementsByTagName("widget");

    try std.testing.expectEqual(@as(usize, 2), collection.length());
}

test "HTMLCollection.item() with small nonnegative integers" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo1 = try doc.createElement("widget");
    try foo1.setId("-2");
    _ = try root.prototype.appendChild(&foo1.prototype);

    const foo2 = try doc.createElement("widget");
    try foo2.setId("-1");
    _ = try root.prototype.appendChild(&foo2.prototype);

    const foo3 = try doc.createElement("widget");
    try foo3.setId("0");
    _ = try root.prototype.appendChild(&foo3.prototype);

    const foo4 = try doc.createElement("widget");
    try foo4.setId("1");
    _ = try root.prototype.appendChild(&foo4.prototype);

    const collection = doc.getElementsByTagName("widget");

    const item0 = collection.item(0).?;
    try std.testing.expectEqualStrings("-2", item0.getId().?);

    const item1 = collection.item(1).?;
    try std.testing.expectEqualStrings("-1", item1.getId().?);
}

test "HTMLCollection.namedItem() with string indices" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo1 = try doc.createElement("widget");
    try foo1.setId("0");
    _ = try root.prototype.appendChild(&foo1.prototype);

    const foo2 = try doc.createElement("widget");
    try foo2.setId("1");
    _ = try root.prototype.appendChild(&foo2.prototype);

    const collection = doc.getElementsByTagName("widget");

    const named0 = collection.namedItem("0").?;
    try std.testing.expectEqualStrings("0", named0.getId().?);

    const named1 = collection.namedItem("1").?;
    try std.testing.expectEqualStrings("1", named1.getId().?);
}

test "HTMLCollection.item() returns null for large indices" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo1 = try doc.createElement("widget");
    try foo1.setId("2147483645");
    _ = try root.prototype.appendChild(&foo1.prototype);

    const collection = doc.getElementsByTagName("widget");

    try std.testing.expectEqual(@as(?*Element, null), collection.item(2147483645));
}

test "HTMLCollection.namedItem() with large numeric strings" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo1 = try doc.createElement("widget");
    try foo1.setId("2147483645");
    _ = try root.prototype.appendChild(&foo1.prototype);

    const collection = doc.getElementsByTagName("widget");

    const named = collection.namedItem("2147483645").?;
    try std.testing.expectEqualStrings("2147483645", named.getId().?);
}

test "HTMLCollection.item() with wraparound at 2^32" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo1 = try doc.createElement("widget");
    try foo1.setId("-2");
    _ = try root.prototype.appendChild(&foo1.prototype);

    const foo2 = try doc.createElement("widget");
    try foo2.setId("-1");
    _ = try root.prototype.appendChild(&foo2.prototype);

    const collection = doc.getElementsByTagName("widget");

    try std.testing.expectEqual(@as(usize, 2), collection.length());
}

test "HTMLCollection.length property" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo1 = try doc.createElement("widget");
    _ = try root.prototype.appendChild(&foo1.prototype);

    const foo2 = try doc.createElement("widget");
    _ = try root.prototype.appendChild(&foo2.prototype);

    const elements = doc.getElementsByTagName("widget");
    try std.testing.expectEqual(@as(usize, 2), elements.length());
}

test "HTMLCollection item() returns elements in order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo1 = try doc.createElement("widget");
    try foo1.setId("first");
    _ = try root.prototype.appendChild(&foo1.prototype);

    const foo2 = try doc.createElement("widget");
    try foo2.setId("second");
    _ = try root.prototype.appendChild(&foo2.prototype);

    const elements = doc.getElementsByTagName("widget");

    const item0 = elements.item(0).?;
    try std.testing.expectEqualStrings("first", item0.getId().?);

    const item1 = elements.item(1).?;
    try std.testing.expectEqualStrings("second", item1.getId().?);
}
