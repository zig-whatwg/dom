const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "HTMLCollection has length method" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const p1 = try doc.createElement("paragraph");
    try p1.setId("1");
    _ = try root.prototype.appendChild(&p1.prototype);

    const paragraphs = doc.getElementsByTagName("paragraph");
    _ = paragraphs.length();
}

test "HTMLCollection length property" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const p1 = try doc.createElement("paragraph");
    try p1.setId("1");
    _ = try root.prototype.appendChild(&p1.prototype);

    const p2 = try doc.createElement("paragraph");
    try p2.setId("2");
    _ = try root.prototype.appendChild(&p2.prototype);

    const paragraphs = doc.getElementsByTagName("paragraph");
    try std.testing.expectEqual(@as(usize, 2), paragraphs.length());
}

test "HTMLCollection is iterable via item()" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const p1 = try doc.createElement("paragraph");
    try p1.setId("1");
    _ = try root.prototype.appendChild(&p1.prototype);

    const p2 = try doc.createElement("paragraph");
    try p2.setId("2");
    _ = try root.prototype.appendChild(&p2.prototype);

    const p3 = try doc.createElement("paragraph");
    try p3.setId("3");
    _ = try root.prototype.appendChild(&p3.prototype);

    const p4 = try doc.createElement("paragraph");
    try p4.setId("4");
    _ = try root.prototype.appendChild(&p4.prototype);

    const p5 = try doc.createElement("paragraph");
    try p5.setId("5");
    _ = try root.prototype.appendChild(&p5.prototype);

    const paragraphs = doc.getElementsByTagName("paragraph");
    const ids = "12345";

    var idx: usize = 0;
    while (idx < paragraphs.length()) : (idx += 1) {
        const element = paragraphs.item(idx).?;
        const elem_id = element.getId().?;
        const expected = ids[idx .. idx + 1];
        try std.testing.expectEqualStrings(expected, elem_id);
    }
}

test "HTMLCollection item() returns null for out of bounds" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const p1 = try doc.createElement("paragraph");
    _ = try root.prototype.appendChild(&p1.prototype);

    const paragraphs = doc.getElementsByTagName("paragraph");
    try std.testing.expectEqual(@as(?*Element, null), paragraphs.item(100));
}
