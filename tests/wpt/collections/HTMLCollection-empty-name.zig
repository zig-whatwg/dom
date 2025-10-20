const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "Empty string as name for Document.getElementsByTagName" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const div1 = try doc.createElement("item");
    try div1.setAttribute("class", "active");
    try div1.setId("");
    _ = try container.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("item");
    try div2.setAttribute("class", "active");
    try div2.setAttribute("name", "");
    _ = try container.prototype.appendChild(&div2.prototype);

    const collection = doc.getElementsByTagName("item");

    const named = collection.namedItem("");
    try std.testing.expectEqual(@as(?*Element, null), named);
}

test "Empty string as name for Element.getElementsByTagName" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const div1 = try doc.createElement("item");
    try div1.setAttribute("class", "active");
    try div1.setId("");
    _ = try container.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("item");
    try div2.setAttribute("class", "active");
    try div2.setAttribute("name", "");
    _ = try container.prototype.appendChild(&div2.prototype);

    const collection = container.getElementsByTagName("item");

    const named = collection.namedItem("");
    try std.testing.expectEqual(@as(?*Element, null), named);
}

test "Empty string as name for Document.getElementsByClassName" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const div1 = try doc.createElement("item");
    try div1.setAttribute("class", "active");
    try div1.setId("");
    _ = try container.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("item");
    try div2.setAttribute("class", "active");
    try div2.setAttribute("name", "");
    _ = try container.prototype.appendChild(&div2.prototype);

    const collection = doc.getElementsByClassName("active");

    const named = collection.namedItem("");
    try std.testing.expectEqual(@as(?*Element, null), named);
}

test "Empty string as name for Element.getElementsByClassName" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const div1 = try doc.createElement("item");
    try div1.setAttribute("class", "active");
    try div1.setId("");
    _ = try container.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("item");
    try div2.setAttribute("class", "active");
    try div2.setAttribute("name", "");
    _ = try container.prototype.appendChild(&div2.prototype);

    const collection = container.getElementsByClassName("active");

    const named = collection.namedItem("");
    try std.testing.expectEqual(@as(?*Element, null), named);
}

test "Empty string as name for Element.children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const div1 = try doc.createElement("item");
    try div1.setAttribute("class", "active");
    try div1.setId("");
    _ = try container.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("item");
    try div2.setAttribute("class", "active");
    try div2.setAttribute("name", "");
    _ = try container.prototype.appendChild(&div2.prototype);

    const collection = container.children();

    const named = collection.namedItem("");
    try std.testing.expectEqual(@as(?*Element, null), named);
}

test "Empty id attribute does not match empty string lookup" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    try elem.setId("");
    _ = try doc.prototype.appendChild(&elem.prototype);

    const collection = doc.getElementsByTagName("item");
    const named = collection.namedItem("");
    try std.testing.expectEqual(@as(?*Element, null), named);
}

test "Empty name attribute does not match empty string lookup" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    try elem.setAttribute("name", "");
    _ = try doc.prototype.appendChild(&elem.prototype);

    const collection = doc.getElementsByTagName("item");
    const named = collection.namedItem("");
    try std.testing.expectEqual(@as(?*Element, null), named);
}
