//! html_collection Tests
//!
//! Tests for html_collection functionality.

const std = @import("std");
const dom = @import("dom");

const testing = std.testing;
const HTMLCollection = dom.HTMLCollection;
const Document = dom.Document;
const Element = dom.Element;
const Comment = dom.Comment;
test "HTMLCollection - children: empty collection" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const collection = HTMLCollection.initChildren(&parent.prototype);
    try testing.expectEqual(@as(usize, 0), collection.length());
    try testing.expectEqual(@as(?*Element, null), collection.item(0));
}

test "HTMLCollection - children: single element" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const collection = HTMLCollection.initChildren(&parent.prototype);
    try testing.expectEqual(@as(usize, 1), collection.length());

    const first = collection.item(0);
    try testing.expect(first != null);
    try testing.expectEqualStrings("child", first.?.tag_name);
}

test "HTMLCollection - children: multiple elements" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const child3 = try doc.createElement("child3");
    _ = try parent.prototype.appendChild(&child3.prototype);

    const collection = HTMLCollection.initChildren(&parent.prototype);
    try testing.expectEqual(@as(usize, 3), collection.length());

    try testing.expectEqualStrings("child1", collection.item(0).?.tag_name);
    try testing.expectEqualStrings("child2", collection.item(1).?.tag_name);
    try testing.expectEqualStrings("child3", collection.item(2).?.tag_name);
    try testing.expectEqual(@as(?*Element, null), collection.item(3));
}

test "HTMLCollection - children: filters out non-element nodes" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const elem1 = try doc.createElement("elem1");
    _ = try parent.prototype.appendChild(&elem1.prototype);

    const text = try doc.createTextNode("text content");
    _ = try parent.prototype.appendChild(&text.prototype);

    const elem2 = try doc.createElement("elem2");
    _ = try parent.prototype.appendChild(&elem2.prototype);

    const comment = try Comment.create(allocator, "comment content");
    _ = try parent.prototype.appendChild(&comment.prototype);

    const elem3 = try doc.createElement("elem3");
    _ = try parent.prototype.appendChild(&elem3.prototype);

    const all_nodes = parent.prototype.childNodes();
    const only_elements = HTMLCollection.initChildren(&parent.prototype);

    try testing.expectEqual(@as(usize, 5), all_nodes.length());
    try testing.expectEqual(@as(usize, 3), only_elements.length());

    try testing.expectEqualStrings("elem1", only_elements.item(0).?.tag_name);
    try testing.expectEqualStrings("elem2", only_elements.item(1).?.tag_name);
    try testing.expectEqualStrings("elem3", only_elements.item(2).?.tag_name);
}

test "HTMLCollection - children: live collection" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const collection = HTMLCollection.initChildren(&parent.prototype);

    // Initially empty
    try testing.expectEqual(@as(usize, 0), collection.length());

    // Add element - collection updates
    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);
    try testing.expectEqual(@as(usize, 1), collection.length());

    // Add text - collection does NOT update (text not an element)
    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);
    try testing.expectEqual(@as(usize, 1), collection.length());

    // Add another element - collection updates
    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);
    try testing.expectEqual(@as(usize, 2), collection.length());

    // Remove element - collection updates
    _ = try parent.prototype.removeChild(&child1.prototype);
    child1.prototype.release();
    try testing.expectEqual(@as(usize, 1), collection.length());
    try testing.expectEqualStrings("child2", collection.item(0).?.tag_name);
}

test "HTMLCollection - document_tagged: empty collection" {
    const collection = HTMLCollection.initDocumentTagged(null);
    try testing.expectEqual(@as(usize, 0), collection.length());
    try testing.expectEqual(@as(?*Element, null), collection.item(0));
}

test "HTMLCollection - document_tagged: backed by ArrayList" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("widget");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("widget");
    _ = try root.prototype.appendChild(&elem2.prototype);

    // Get collection backed by Document's tag_map
    const collection = doc.getElementsByTagName("widget");
    try testing.expectEqual(@as(usize, 2), collection.length());
    try testing.expectEqualStrings("widget", collection.item(0).?.tag_name);
    try testing.expectEqualStrings("widget", collection.item(1).?.tag_name);
}

test "HTMLCollection - element_scoped: getElementsByTagName" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    defer container.prototype.release();

    const widget1 = try doc.createElement("widget");
    _ = try container.prototype.appendChild(&widget1.prototype);

    const other = try doc.createElement("other");
    _ = try container.prototype.appendChild(&other.prototype);

    const widget2 = try doc.createElement("widget");
    _ = try container.prototype.appendChild(&widget2.prototype);

    const collection = HTMLCollection.initElementByTagName(container, "widget");
    try testing.expectEqual(@as(usize, 2), collection.length());
    try testing.expectEqualStrings("widget", collection.item(0).?.tag_name);
    try testing.expectEqualStrings("widget", collection.item(1).?.tag_name);
    try testing.expectEqual(@as(?*Element, null), collection.item(2));
}

test "HTMLCollection - element_scoped: getElementsByClassName" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    defer container.prototype.release();

    const item1 = try doc.createElement("item");
    try item1.setAttribute("class", "active");
    _ = try container.prototype.appendChild(&item1.prototype);

    const item2 = try doc.createElement("item");
    try item2.setAttribute("class", "inactive");
    _ = try container.prototype.appendChild(&item2.prototype);

    const item3 = try doc.createElement("item");
    try item3.setAttribute("class", "active primary");
    _ = try container.prototype.appendChild(&item3.prototype);

    const collection = HTMLCollection.initElementByClassName(container, "active");
    try testing.expectEqual(@as(usize, 2), collection.length());
    try testing.expect(std.mem.eql(u8, collection.item(0).?.tag_name, "item"));
    try testing.expect(std.mem.eql(u8, collection.item(1).?.tag_name, "item"));
}

test "HTMLCollection - element_scoped: nested descendants" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    defer root.prototype.release();

    const level1 = try doc.createElement("level1");
    _ = try root.prototype.appendChild(&level1.prototype);

    const widget1 = try doc.createElement("widget");
    _ = try level1.prototype.appendChild(&widget1.prototype);

    const level2 = try doc.createElement("level2");
    _ = try level1.prototype.appendChild(&level2.prototype);

    const widget2 = try doc.createElement("widget");
    _ = try level2.prototype.appendChild(&widget2.prototype);

    const collection = HTMLCollection.initElementByTagName(root, "widget");
    try testing.expectEqual(@as(usize, 2), collection.length());
}

test "HTMLCollection - namedItem: finds by id" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    try child1.setAttribute("id", "first");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    try child2.setAttribute("id", "second");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const collection = HTMLCollection.initChildren(&parent.prototype);
    const found = collection.namedItem("second");
    try testing.expect(found != null);
    try testing.expectEqualStrings("child2", found.?.tag_name);
}

test "HTMLCollection - namedItem: finds by name attribute" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    try child1.setAttribute("name", "username");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const collection = HTMLCollection.initChildren(&parent.prototype);
    const found = collection.namedItem("username");
    try testing.expect(found != null);
    try testing.expectEqualStrings("child1", found.?.tag_name);
}

test "HTMLCollection - namedItem: not found" {
    const allocator = testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const collection = HTMLCollection.initChildren(&parent.prototype);
    try testing.expectEqual(@as(?*Element, null), collection.namedItem("nonexistent"));
}
