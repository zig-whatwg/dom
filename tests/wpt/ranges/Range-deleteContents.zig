// META: title=Range.deleteContents() tests
// META: link=https://dom.spec.whatwg.org/#dom-range-deletecontents

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Range = dom.Range;

test "deleteContents() removes text content" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 0);
    try range.setEnd(&text.prototype, 5);

    try range.deleteContents();

    try std.testing.expectEqualStrings(" World", text.data);
}

test "deleteContents() with collapsed range does nothing" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Test");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 2);
    try range.setEnd(&text.prototype, 2);

    try std.testing.expect(range.collapsed());

    try range.deleteContents();

    try std.testing.expectEqualStrings("Test", text.data);
}

test "deleteContents() removes element nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    const child3 = try doc.createElement("child3");

    _ = try container.prototype.appendChild(&child1.prototype);
    _ = try container.prototype.appendChild(&child2.prototype);
    _ = try container.prototype.appendChild(&child3.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&container.prototype, 1);
    try range.setEnd(&container.prototype, 2);

    try range.deleteContents();

    try std.testing.expectEqual(@as(usize, 2), container.prototype.childNodes().length());
    try std.testing.expectEqual(&child1.prototype, container.prototype.first_child.?);
    try std.testing.expectEqual(&child3.prototype, container.prototype.last_child.?);
}

test "deleteContents() removes partial text content" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("ABCDEFGH");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 2);
    try range.setEnd(&text.prototype, 6);

    try range.deleteContents();

    try std.testing.expectEqualStrings("ABGH", text.data);
}

test "deleteContents() collapses range to start" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Content");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 1);
    try range.setEnd(&text.prototype, 5);

    try std.testing.expect(!range.collapsed());

    try range.deleteContents();

    try std.testing.expect(range.collapsed());
    try std.testing.expectEqual(@as(u32, 1), range.start_offset);
    try std.testing.expectEqual(@as(u32, 1), range.end_offset);
}
