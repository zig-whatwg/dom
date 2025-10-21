// META: title=Element.querySelectorAll
// META: link=https://dom.spec.whatwg.org/#dom-parentnode-queryselectorall

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "Element.querySelectorAll returns all matching descendants" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const item1 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&item1.prototype);

    const item2 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&item2.prototype);

    const item3 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&item3.prototype);

    const result = try root.querySelectorAll(allocator, "item");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expect(result[0] == item1);
    try std.testing.expect(result[1] == item2);
    try std.testing.expect(result[2] == item3);
}

test "Element.querySelectorAll returns empty slice when no matches" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const result = try root.querySelectorAll(allocator, "nonexistent");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "Element.querySelectorAll with ID selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const target = try doc.createElement("target");
    try target.setAttribute("id", "unique");
    _ = try root.prototype.appendChild(&target.prototype);

    const result = try root.querySelectorAll(allocator, "#unique");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 1), result.len);
    try std.testing.expect(result[0] == target);
}

test "Element.querySelectorAll with class selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("elem");
    try elem1.setAttribute("class", "highlight");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("elem");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const elem3 = try doc.createElement("elem");
    try elem3.setAttribute("class", "highlight");
    _ = try root.prototype.appendChild(&elem3.prototype);

    const result = try root.querySelectorAll(allocator, ".highlight");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 2), result.len);
    try std.testing.expect(result[0] == elem1);
    try std.testing.expect(result[1] == elem3);
}

test "Element.querySelectorAll with attribute selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("elem");
    try elem1.setAttribute("data-flag", "true");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("elem");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const elem3 = try doc.createElement("elem");
    try elem3.setAttribute("data-flag", "true");
    _ = try root.prototype.appendChild(&elem3.prototype);

    const result = try root.querySelectorAll(allocator, "[data-flag]");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 2), result.len);
}

test "Element.querySelectorAll does not match context element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const child = try doc.createElement("root");
    _ = try root.prototype.appendChild(&child.prototype);

    const result = try root.querySelectorAll(allocator, "root");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 1), result.len);
    try std.testing.expect(result[0] == child);
}

test "Element.querySelectorAll with nested matches" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const level1 = try doc.createElement("level");
    _ = try root.prototype.appendChild(&level1.prototype);

    const level2 = try doc.createElement("level");
    _ = try level1.prototype.appendChild(&level2.prototype);

    const level3 = try doc.createElement("level");
    _ = try level2.prototype.appendChild(&level3.prototype);

    const result = try root.querySelectorAll(allocator, "level");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expect(result[0] == level1);
    try std.testing.expect(result[1] == level2);
    try std.testing.expect(result[2] == level3);
}

test "Element.querySelectorAll with descendant combinator" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const parent1 = try doc.createElement("parent");
    _ = try root.prototype.appendChild(&parent1.prototype);

    const child1 = try doc.createElement("child");
    _ = try parent1.prototype.appendChild(&child1.prototype);

    const parent2 = try doc.createElement("parent");
    _ = try root.prototype.appendChild(&parent2.prototype);

    const child2 = try doc.createElement("child");
    _ = try parent2.prototype.appendChild(&child2.prototype);

    const result = try root.querySelectorAll(allocator, "parent child");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 2), result.len);
    try std.testing.expect(result[0] == child1);
    try std.testing.expect(result[1] == child2);
}

test "Element.querySelectorAll with child combinator" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const parent = try doc.createElement("parent");
    _ = try root.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const grandchild = try doc.createElement("child");
    _ = try child.prototype.appendChild(&grandchild.prototype);

    // Should match only direct children
    const result = try root.querySelectorAll(allocator, "root > parent");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 1), result.len);
    try std.testing.expect(result[0] == parent);
}

test "Element.querySelectorAll in document order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const item1 = try doc.createElement("item");
    try item1.setAttribute("order", "1");
    _ = try root.prototype.appendChild(&item1.prototype);

    const container = try doc.createElement("container");
    _ = try root.prototype.appendChild(&container.prototype);

    const item2 = try doc.createElement("item");
    try item2.setAttribute("order", "2");
    _ = try container.prototype.appendChild(&item2.prototype);

    const item3 = try doc.createElement("item");
    try item3.setAttribute("order", "3");
    _ = try root.prototype.appendChild(&item3.prototype);

    const result = try root.querySelectorAll(allocator, "item");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expectEqualStrings("1", result[0].getAttribute("order").?);
    try std.testing.expectEqualStrings("2", result[1].getAttribute("order").?);
    try std.testing.expectEqualStrings("3", result[2].getAttribute("order").?);
}

test "Element.querySelectorAll with :not() pseudo-class" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("elem");
    try elem1.setAttribute("class", "include");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("elem");
    try elem2.setAttribute("class", "exclude");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const elem3 = try doc.createElement("elem");
    try elem3.setAttribute("class", "include");
    _ = try root.prototype.appendChild(&elem3.prototype);

    const result = try root.querySelectorAll(allocator, "elem:not(.exclude)");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 2), result.len);
    try std.testing.expect(result[0] == elem1);
    try std.testing.expect(result[1] == elem3);
}

test "Element.querySelectorAll with selector list" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const foo = try doc.createElement("foo");
    _ = try root.prototype.appendChild(&foo.prototype);

    const bar = try doc.createElement("bar");
    _ = try root.prototype.appendChild(&bar.prototype);

    const baz = try doc.createElement("baz");
    _ = try root.prototype.appendChild(&baz.prototype);

    const result = try root.querySelectorAll(allocator, "foo, baz");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 2), result.len);
    try std.testing.expect(result[0] == foo);
    try std.testing.expect(result[1] == baz);
}

test "Element.querySelectorAll with universal selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("foo");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("bar");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const elem3 = try doc.createElement("baz");
    _ = try root.prototype.appendChild(&elem3.prototype);

    const result = try root.querySelectorAll(allocator, "*");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
}

test "Element.querySelectorAll with empty selector errors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try std.testing.expectError(error.InvalidSelector, root.querySelectorAll(allocator, ""));
}

test "Element.querySelectorAll with invalid selector errors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try std.testing.expectError(error.UnexpectedToken, root.querySelectorAll(allocator, "###"));
}

test "Element.querySelectorAll result is static snapshot" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const item1 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&item1.prototype);

    const result = try root.querySelectorAll(allocator, "item");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 1), result.len);

    // Add more items after query
    const item2 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&item2.prototype);

    // Result should still be 1 (static snapshot)
    try std.testing.expectEqual(@as(usize, 1), result.len);
}
