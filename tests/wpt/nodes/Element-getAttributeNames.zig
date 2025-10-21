// META: title=Element.getAttributeNames
// META: link=https://dom.spec.whatwg.org/#dom-element-getattributenames

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.getAttributeNames returns empty array when no attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    const names = try elem.getAttributeNames(allocator);
    defer allocator.free(names);

    try std.testing.expectEqual(@as(usize, 0), names.len);
}

test "Element.getAttributeNames returns single attribute name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttribute("id", "test");

    const names = try elem.getAttributeNames(allocator);
    defer {
        for (names) |name| allocator.free(name);
        allocator.free(names);
    }

    try std.testing.expectEqual(@as(usize, 1), names.len);
    try std.testing.expectEqualStrings("id", names[0]);
}

test "Element.getAttributeNames returns multiple attribute names" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttribute("id", "test");
    try elem.setAttribute("class", "foo");
    try elem.setAttribute("data-value", "bar");

    const names = try elem.getAttributeNames(allocator);
    defer {
        for (names) |name| allocator.free(name);
        allocator.free(names);
    }

    try std.testing.expectEqual(@as(usize, 3), names.len);
}

test "Element.getAttributeNames after attribute removal" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("elem");
    defer elem.prototype.release();

    try elem.setAttribute("id", "test");
    try elem.setAttribute("class", "foo");

    {
        const names = try elem.getAttributeNames(allocator);
        defer {
            for (names) |name| allocator.free(name);
            allocator.free(names);
        }
        try std.testing.expectEqual(@as(usize, 2), names.len);
    }

    elem.removeAttribute("id");

    {
        const names = try elem.getAttributeNames(allocator);
        defer {
            for (names) |name| allocator.free(name);
            allocator.free(names);
        }
        try std.testing.expectEqual(@as(usize, 1), names.len);
        try std.testing.expectEqualStrings("class", names[0]);
    }
}
