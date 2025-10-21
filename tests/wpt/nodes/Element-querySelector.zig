// META: title=Element.querySelector
// META: link=https://dom.spec.whatwg.org/#dom-parentnode-queryselector

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "Element.querySelector returns first matching descendant" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const item1 = try doc.createElement("item");
    try item1.setAttribute("id", "first");
    _ = try root.prototype.appendChild(&item1.prototype);

    const item2 = try doc.createElement("item");
    try item2.setAttribute("id", "second");
    _ = try root.prototype.appendChild(&item2.prototype);

    const result = try root.querySelector(allocator, "item");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("first", result.?.getAttribute("id").?);
}

test "Element.querySelector with ID selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const target = try doc.createElement("target");
    try target.setAttribute("id", "target-id");
    _ = try root.prototype.appendChild(&target.prototype);

    const result = try root.querySelector(allocator, "#target-id");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == target);
}

test "Element.querySelector with class selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem = try doc.createElement("elem");
    try elem.setAttribute("class", "highlight");
    _ = try root.prototype.appendChild(&elem.prototype);

    const result = try root.querySelector(allocator, ".highlight");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem);
}

test "Element.querySelector with attribute selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem = try doc.createElement("elem");
    try elem.setAttribute("data-value", "test");
    _ = try root.prototype.appendChild(&elem.prototype);

    const result = try root.querySelector(allocator, "[data-value='test']");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem);
}

test "Element.querySelector with descendant combinator" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const parent = try doc.createElement("parent");
    _ = try root.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try root.querySelector(allocator, "parent child");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == child);
}

test "Element.querySelector with child combinator" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const parent = try doc.createElement("parent");
    _ = try root.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try root.querySelector(allocator, "parent > child");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == child);
}

test "Element.querySelector returns null when no match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const result = try root.querySelector(allocator, "nonexistent");
    try std.testing.expect(result == null);
}

test "Element.querySelector does not match context element itself" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const result = try root.querySelector(allocator, "root");
    try std.testing.expect(result == null);
}

test "Element.querySelector with complex selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("item");
    try elem1.setAttribute("class", "foo");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("item");
    try elem2.setAttribute("class", "bar");
    try elem2.setAttribute("id", "target");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const result = try root.querySelector(allocator, "item.bar#target");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem2);
}

test "Element.querySelector returns first match in document order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("match");
    try elem1.setAttribute("data-order", "1");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("match");
    try elem2.setAttribute("data-order", "2");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const elem3 = try doc.createElement("match");
    try elem3.setAttribute("data-order", "3");
    _ = try root.prototype.appendChild(&elem3.prototype);

    const result = try root.querySelector(allocator, "match");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("1", result.?.getAttribute("data-order").?);
}

test "Element.querySelector with nested elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const level1 = try doc.createElement("level1");
    _ = try root.prototype.appendChild(&level1.prototype);

    const level2 = try doc.createElement("level2");
    _ = try level1.prototype.appendChild(&level2.prototype);

    const target = try doc.createElement("target");
    try target.setAttribute("id", "deep");
    _ = try level2.prototype.appendChild(&target.prototype);

    const result = try root.querySelector(allocator, "#deep");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == target);
}

test "Element.querySelector with multiple classes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem = try doc.createElement("elem");
    try elem.setAttribute("class", "foo bar baz");
    _ = try root.prototype.appendChild(&elem.prototype);

    const result = try root.querySelector(allocator, ".foo.bar");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem);
}

test "Element.querySelector with :not() pseudo-class" {
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

    const result = try root.querySelector(allocator, "elem:not(.exclude)");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem1);
}

test "Element.querySelector with :first-child pseudo-class" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("elem");
    try elem1.setAttribute("data-pos", "first");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("elem");
    try elem2.setAttribute("data-pos", "second");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const result = try root.querySelector(allocator, "elem:first-child");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("first", result.?.getAttribute("data-pos").?);
}

test "Element.querySelector with selector list returns first match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("foo");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("bar");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const result = try root.querySelector(allocator, "nonexistent, bar");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem2);
}

test "Element.querySelector with empty selector errors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try std.testing.expectError(error.InvalidSelector, root.querySelector(allocator, ""));
}

test "Element.querySelector with invalid selector errors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try std.testing.expectError(error.UnexpectedToken, root.querySelector(allocator, "###"));
}
