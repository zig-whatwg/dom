// META: title=previousElementSibling and nextElementSibling null test
// META: link=https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-previouselementsibling
// META: link=https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-nextelementsibling

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "previousElementSibling and nextElementSibling return null for only child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add text before (not an element)
    const text1 = try doc.createTextNode("The result of this test is ");
    _ = try parent.prototype.appendChild(&text1.prototype);

    // Add only element child
    const only_child = try doc.createElement("child");
    try only_child.setAttribute("data-id", "first_element_child");
    _ = try parent.prototype.appendChild(&only_child.prototype);

    // Add text after (not an element)
    const text2 = try doc.createTextNode(" unknown.");
    _ = try parent.prototype.appendChild(&text2.prototype);

    // Only element has no element siblings
    try std.testing.expectEqual(@as(?*Element, null), only_child.previousElementSibling());
    try std.testing.expectEqual(@as(?*Element, null), only_child.nextElementSibling());
}

test "previousElementSibling null for first element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const first = try doc.createElement("first");
    _ = try parent.prototype.appendChild(&first.prototype);

    const second = try doc.createElement("second");
    _ = try parent.prototype.appendChild(&second.prototype);

    // First element has no previous element sibling
    try std.testing.expectEqual(@as(?*Element, null), first.previousElementSibling());
    // But has next sibling
    try std.testing.expectEqual(second, first.nextElementSibling());
}

test "nextElementSibling null for last element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const first = try doc.createElement("first");
    _ = try parent.prototype.appendChild(&first.prototype);

    const second = try doc.createElement("second");
    _ = try parent.prototype.appendChild(&second.prototype);

    // Last element has no next element sibling
    try std.testing.expectEqual(@as(?*Element, null), second.nextElementSibling());
    // But has previous sibling
    try std.testing.expectEqual(first, second.previousElementSibling());
}

test "both null for disconnected element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("disconnected");
    defer elem.prototype.release();

    // Disconnected element has no siblings
    try std.testing.expectEqual(@as(?*Element, null), elem.previousElementSibling());
    try std.testing.expectEqual(@as(?*Element, null), elem.nextElementSibling());
}
