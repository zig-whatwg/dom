// META: title=Document.querySelector
// META: link=https://dom.spec.whatwg.org/#dom-parentnode-queryselector

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Document.querySelector returns first matching element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("item");
    try elem1.setAttribute("id", "first");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("item");
    try elem2.setAttribute("id", "second");
    _ = try root.prototype.appendChild(&elem2.prototype);

    const result = try doc.querySelector("item");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("first", result.?.getAttribute("id").?);
}

test "Document.querySelector with ID selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem = try doc.createElement("elem");
    try elem.setAttribute("id", "target");
    _ = try root.prototype.appendChild(&elem.prototype);

    const result = try doc.querySelector("#target");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem);
}

test "Document.querySelector with class selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem = try doc.createElement("elem");
    try elem.setAttribute("class", "highlight");
    _ = try root.prototype.appendChild(&elem.prototype);

    const result = try doc.querySelector(".highlight");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem);
}

test "Document.querySelector returns null when no match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const result = try doc.querySelector("nonexistent");
    try std.testing.expect(result == null);
}

test "Document.querySelector searches entire document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const nested = try doc.createElement("nested");
    _ = try root.prototype.appendChild(&nested.prototype);

    const target = try doc.createElement("target");
    try target.setAttribute("id", "deep");
    _ = try nested.prototype.appendChild(&target.prototype);

    const result = try doc.querySelector("#deep");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == target);
}

test "Document.querySelector with complex selector" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem = try doc.createElement("item");
    try elem.setAttribute("class", "foo bar");
    try elem.setAttribute("id", "target");
    _ = try root.prototype.appendChild(&elem.prototype);

    const result = try doc.querySelector("item.foo.bar#target");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == elem);
}

test "Document.querySelector with descendant combinator" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const result = try doc.querySelector("parent child");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == child);
}

test "Document.querySelector with empty selector errors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const result = doc.querySelector("");
    try std.testing.expectError(error.InvalidSelector, result);
}
