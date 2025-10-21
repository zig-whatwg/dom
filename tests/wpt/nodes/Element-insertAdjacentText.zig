// META: title=Element.insertAdjacentText
// META: link=https://dom.spec.whatwg.org/#dom-element-insertadjacenttext

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Element.insertAdjacentText beforebegin" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const target = try doc.createElement("target");
    _ = try parent.prototype.appendChild(&target.prototype);

    try target.insertAdjacentText("beforebegin", "text");

    try std.testing.expect(parent.prototype.first_child != &target.prototype);
    const textNode = parent.prototype.first_child.?;
    try std.testing.expectEqual(dom.NodeType.text, textNode.node_type);
}

test "Element.insertAdjacentText afterbegin" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try doc.createElement("target");
    _ = try doc.prototype.appendChild(&target.prototype);

    try target.insertAdjacentText("afterbegin", "text");

    const textNode = target.prototype.first_child.?;
    try std.testing.expectEqual(dom.NodeType.text, textNode.node_type);
}

test "Element.insertAdjacentText beforeend" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try doc.createElement("target");
    _ = try doc.prototype.appendChild(&target.prototype);

    try target.insertAdjacentText("beforeend", "text");

    const textNode = target.prototype.last_child.?;
    try std.testing.expectEqual(dom.NodeType.text, textNode.node_type);
}

test "Element.insertAdjacentText afterend" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const target = try doc.createElement("target");
    _ = try parent.prototype.appendChild(&target.prototype);

    try target.insertAdjacentText("afterend", "text");

    try std.testing.expect(parent.prototype.last_child != &target.prototype);
    const textNode = parent.prototype.last_child.?;
    try std.testing.expectEqual(dom.NodeType.text, textNode.node_type);
}

test "Element.insertAdjacentText with invalid position errors" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try doc.createElement("target");
    _ = try doc.prototype.appendChild(&target.prototype);

    try std.testing.expectError(error.SyntaxError, target.insertAdjacentText("invalid", "text"));
}
