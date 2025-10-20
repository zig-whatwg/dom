// META: title=Element.id

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.id getter and setter" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("item");
    defer elem.prototype.release();

    // No id initially
    const id1 = elem.getAttribute("id");
    try std.testing.expect(id1 == null);

    // Set id
    try elem.setAttribute("id", "test-id");

    // Get id
    const id2 = elem.getAttribute("id");
    try std.testing.expect(id2 != null);
    try std.testing.expectEqualStrings("test-id", id2.?);
}

test "Element with id can be found by getElementById" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem = try doc.createElement("item");
    try elem.setAttribute("id", "my-id");
    _ = try root.prototype.appendChild(&elem.prototype);

    const found = doc.getElementById("my-id");
    try std.testing.expect(found == elem);
}
