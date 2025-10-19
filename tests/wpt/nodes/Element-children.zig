// META: title=Element.children
// META: link=https://dom.spec.whatwg.org/#dom-parentnode-children

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const HTMLCollection = dom.HTMLCollection;

test "children returns HTMLCollection" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const children = parent.children();

    // Should be an HTMLCollection (though we can't test instanceof directly)
    // Test that it has the expected interface
    try std.testing.expectEqual(@as(usize, 0), children.length());
}

test "children is a live collection" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("list");
    defer parent.prototype.release();

    // Add some initial children
    const item1 = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&item1.prototype);

    const item2 = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&item2.prototype);

    const item3 = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&item3.prototype);

    const item4 = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&item4.prototype);

    const children = parent.children();
    try std.testing.expectEqual(@as(usize, 4), children.length());

    // Add a new child - collection should update
    const item5 = try doc.createElement("item");
    _ = try parent.prototype.appendChild(&item5.prototype);
    try std.testing.expectEqual(@as(usize, 5), children.length());

    // Remove a child - collection should update
    _ = try parent.prototype.removeChild(&item5.prototype);
    item5.prototype.release(); // Must release orphaned node
    try std.testing.expectEqual(@as(usize, 4), children.length());
}

test "children only includes element nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    // Add text node
    const text1 = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text1.prototype);

    const children = parent.children();
    try std.testing.expectEqual(@as(usize, 0), children.length());

    // Add element
    const elem1 = try doc.createElement("elem1");
    _ = try parent.prototype.appendChild(&elem1.prototype);
    try std.testing.expectEqual(@as(usize, 1), children.length());

    // Add comment
    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);
    try std.testing.expectEqual(@as(usize, 1), children.length());

    // Add another element
    const elem2 = try doc.createElement("elem2");
    _ = try parent.prototype.appendChild(&elem2.prototype);
    try std.testing.expectEqual(@as(usize, 2), children.length());

    // Add more text
    const text2 = try doc.createTextNode("more text");
    _ = try parent.prototype.appendChild(&text2.prototype);
    try std.testing.expectEqual(@as(usize, 2), children.length());
}

test "children can be accessed by index" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const elem1 = try doc.createElement("first");
    _ = try parent.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("second");
    _ = try parent.prototype.appendChild(&elem2.prototype);

    const elem3 = try doc.createElement("third");
    _ = try parent.prototype.appendChild(&elem3.prototype);

    const children = parent.children();

    const first = children.item(0);
    try std.testing.expect(first != null);
    try std.testing.expectEqualStrings("first", first.?.tag_name);

    const second = children.item(1);
    try std.testing.expect(second != null);
    try std.testing.expectEqualStrings("second", second.?.tag_name);

    const third = children.item(2);
    try std.testing.expect(third != null);
    try std.testing.expectEqualStrings("third", third.?.tag_name);

    // Out of bounds
    try std.testing.expectEqual(@as(?*Element, null), children.item(3));
    try std.testing.expectEqual(@as(?*Element, null), children.item(100));
}

test "children works on DocumentFragment" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const frag = try doc.createDocumentFragment();
    defer frag.prototype.release();

    const children = frag.children();
    try std.testing.expectEqual(@as(usize, 0), children.length());

    // Add elements
    const elem1 = try doc.createElement("elem1");
    _ = try frag.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("elem2");
    _ = try frag.prototype.appendChild(&elem2.prototype);

    try std.testing.expectEqual(@as(usize, 2), children.length());
}

test "children works on Document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const children = doc.children();
    try std.testing.expectEqual(@as(usize, 0), children.length());

    // Add root element
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try std.testing.expectEqual(@as(usize, 1), children.length());
    try std.testing.expectEqual(root, children.item(0));
}

test "empty parent has empty children collection" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("empty");
    defer parent.prototype.release();

    const children = parent.children();
    try std.testing.expectEqual(@as(usize, 0), children.length());
    try std.testing.expectEqual(@as(?*Element, null), children.item(0));
}
