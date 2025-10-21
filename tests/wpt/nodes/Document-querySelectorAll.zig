// META: title=Document.querySelectorAll
// META: link=https://dom.spec.whatwg.org/#dom-parentnode-queryselectorall

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.querySelectorAll returns all matching elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const elem3 = try doc.createElement("item");
    _ = try root.prototype.appendChild(&elem3.prototype);

    const result = try doc.querySelectorAll("item");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
}

test "Document.querySelectorAll returns empty slice when no matches" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const result = try doc.querySelectorAll("nonexistent");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 0), result.len);
}

test "Document.querySelectorAll searches entire document tree" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const level1 = try doc.createElement("level");
    _ = try doc.prototype.appendChild(&level1.prototype);

    const level2a = try doc.createElement("level");
    _ = try level1.prototype.appendChild(&level2a.prototype);

    const level2b = try doc.createElement("level");
    _ = try level1.prototype.appendChild(&level2b.prototype);

    const result = try doc.querySelectorAll("level");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
}

test "Document.querySelectorAll with class selector" {
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

    const result = try doc.querySelectorAll(".highlight");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 2), result.len);
}

test "Document.querySelectorAll in document order" {
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

    const result = try doc.querySelectorAll("item");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expectEqualStrings("1", result[0].getAttribute("order").?);
    try std.testing.expectEqualStrings("2", result[1].getAttribute("order").?);
    try std.testing.expectEqualStrings("3", result[2].getAttribute("order").?);
}

test "Document.querySelectorAll with selector list" {
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

    const result = try doc.querySelectorAll("foo, baz");
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 2), result.len);
}

test "Document.querySelectorAll with empty selector errors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const result = doc.querySelectorAll("");
    try std.testing.expectError(error.InvalidSelector, result);
}
