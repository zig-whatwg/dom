// META: title=Node.cloneNode deep cloning
// META: link=https://dom.spec.whatwg.org/#dom-node-clonenode

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Node.cloneNode with deep=true clones children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const clone = try parent.prototype.cloneNode(true);
    defer clone.release();

    try std.testing.expectEqual(@as(usize, 2), clone.childNodes().length());
}

test "Node.cloneNode with deep=false does not clone children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const clone = try parent.prototype.cloneNode(false);
    defer clone.release();

    try std.testing.expectEqual(@as(usize, 0), clone.childNodes().length());
}

test "Node.cloneNode deep clones nested structure" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    defer root.prototype.release();

    const level1 = try doc.createElement("level1");
    _ = try root.prototype.appendChild(&level1.prototype);

    const level2 = try doc.createElement("level2");
    _ = try level1.prototype.appendChild(&level2.prototype);

    const clone = try root.prototype.cloneNode(true);
    defer clone.release();

    try std.testing.expectEqual(@as(usize, 1), clone.childNodes().length());
    const clonedLevel1 = clone.first_child.?;
    try std.testing.expectEqual(@as(usize, 1), clonedLevel1.childNodes().length());
}

test "Node.cloneNode clones attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttribute("id", "test");
    try elem.setAttribute("class", "foo");

    const clone = try elem.prototype.cloneNode(false);
    defer clone.release();

    const clonedElem: *dom.Element = @fieldParentPtr("prototype", clone);
    try std.testing.expectEqualStrings("test", clonedElem.getAttribute("id").?);
    try std.testing.expectEqualStrings("foo", clonedElem.getAttribute("class").?);
}

test "Node.cloneNode clones text content" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello world");
    defer text.prototype.release();

    const clone = try text.prototype.cloneNode(false);
    defer clone.release();

    const clonedText: *dom.Text = @fieldParentPtr("prototype", clone);
    try std.testing.expectEqualStrings("hello world", clonedText.data);
}
