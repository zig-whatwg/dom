// META: title=Element.insertAdjacentElement
// META: link=https://dom.spec.whatwg.org/#dom-element-insertadjacentelement

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.insertAdjacentElement beforebegin" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const target = try doc.createElement("target");
    _ = try parent.prototype.appendChild(&target.prototype);

    const newElem = try doc.createElement("new");

    const result = try target.insertAdjacentElement("beforebegin", newElem);
    try std.testing.expect(result == newElem);
    try std.testing.expect(newElem.prototype.parent_node == &parent.prototype);
    try std.testing.expect(parent.prototype.first_child == &newElem.prototype);
}

test "Element.insertAdjacentElement afterbegin" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try doc.createElement("target");
    _ = try doc.prototype.appendChild(&target.prototype);

    const existing = try doc.createElement("existing");
    _ = try target.prototype.appendChild(&existing.prototype);

    const newElem = try doc.createElement("new");

    const result = try target.insertAdjacentElement("afterbegin", newElem);
    try std.testing.expect(result == newElem);
    try std.testing.expect(newElem.prototype.parent_node == &target.prototype);
    try std.testing.expect(target.prototype.first_child == &newElem.prototype);
}

test "Element.insertAdjacentElement beforeend" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try doc.createElement("target");
    _ = try doc.prototype.appendChild(&target.prototype);

    const existing = try doc.createElement("existing");
    _ = try target.prototype.appendChild(&existing.prototype);

    const newElem = try doc.createElement("new");

    const result = try target.insertAdjacentElement("beforeend", newElem);
    try std.testing.expect(result == newElem);
    try std.testing.expect(newElem.prototype.parent_node == &target.prototype);
    try std.testing.expect(target.prototype.last_child == &newElem.prototype);
}

test "Element.insertAdjacentElement afterend" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const target = try doc.createElement("target");
    _ = try parent.prototype.appendChild(&target.prototype);

    const newElem = try doc.createElement("new");

    const result = try target.insertAdjacentElement("afterend", newElem);
    try std.testing.expect(result == newElem);
    try std.testing.expect(newElem.prototype.parent_node == &parent.prototype);
    try std.testing.expect(parent.prototype.last_child == &newElem.prototype);
}

test "Element.insertAdjacentElement with invalid position errors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try doc.createElement("target");
    _ = try doc.prototype.appendChild(&target.prototype);

    const newElem = try doc.createElement("new");
    defer newElem.prototype.release();

    try std.testing.expectError(error.SyntaxError, target.insertAdjacentElement("invalid", newElem));
}
