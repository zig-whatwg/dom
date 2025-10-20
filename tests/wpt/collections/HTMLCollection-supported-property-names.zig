const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "HTMLCollection.namedItem() with id attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const span1 = try doc.createElement("element");
    _ = try root.prototype.appendChild(&span1.prototype);

    const span2 = try doc.createElement("element");
    try span2.setId("some-id");
    _ = try root.prototype.appendChild(&span2.prototype);

    const span3 = try doc.createElement("element");
    try span3.setId("some-id");
    _ = try root.prototype.appendChild(&span3.prototype);

    const elements = doc.getElementsByTagName("element");

    const named = elements.namedItem("some-id").?;
    try std.testing.expectEqualStrings("some-id", named.getId().?);
}

test "HTMLCollection.namedItem() with name attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const span1 = try doc.createElement("element");
    try span1.setAttribute("name", "some-name");
    _ = try root.prototype.appendChild(&span1.prototype);

    const span2 = try doc.createElement("element");
    try span2.setAttribute("name", "some-name");
    _ = try root.prototype.appendChild(&span2.prototype);

    const elements = doc.getElementsByTagName("element");

    const named = elements.namedItem("some-name").?;
    try std.testing.expectEqualStrings("some-name", named.getAttribute("name").?);
}

test "HTMLCollection.namedItem() with both id and name attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const span = try doc.createElement("element");
    try span.setId("another-id");
    try span.setAttribute("name", "another-name");
    _ = try root.prototype.appendChild(&span.prototype);

    const elements = doc.getElementsByTagName("element");

    const namedById = elements.namedItem("another-id").?;
    try std.testing.expectEqualStrings("another-id", namedById.getId().?);

    const namedByName = elements.namedItem("another-name").?;
    try std.testing.expectEqualStrings("another-name", namedByName.getAttribute("name").?);
}

test "HTMLCollection.namedItem() returns null for non-existent name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const span = try doc.createElement("element");
    try span.setId("some-id");
    _ = try root.prototype.appendChild(&span.prototype);

    const elements = doc.getElementsByTagName("element");

    const named = elements.namedItem("non-existent");
    try std.testing.expectEqual(@as(?*Element, null), named);
}

test "HTMLCollection.namedItem() no duplicates in results" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const span1 = try doc.createElement("element");
    try span1.setId("duplicate-id");
    _ = try root.prototype.appendChild(&span1.prototype);

    const span2 = try doc.createElement("element");
    try span2.setId("duplicate-id");
    _ = try root.prototype.appendChild(&span2.prototype);

    const elements = doc.getElementsByTagName("element");

    const named = elements.namedItem("duplicate-id").?;
    try std.testing.expectEqualStrings("duplicate-id", named.getId().?);
}

test "HTMLCollection.namedItem() prefers id over name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const span1 = try doc.createElement("element");
    try span1.setId("test");
    _ = try root.prototype.appendChild(&span1.prototype);

    const span2 = try doc.createElement("element");
    try span2.setAttribute("name", "test");
    _ = try root.prototype.appendChild(&span2.prototype);

    const elements = doc.getElementsByTagName("element");

    const named = elements.namedItem("test").?;
    try std.testing.expectEqualStrings("test", named.getId().?);
    try std.testing.expectEqual(@as(?[]const u8, null), named.getAttribute("name"));
}
