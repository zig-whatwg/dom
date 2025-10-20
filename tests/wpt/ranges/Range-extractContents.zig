// META: title=Range.extractContents() tests
// META: link=https://dom.spec.whatwg.org/#dom-range-extractcontents

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;
const Element = dom.Element;
const Text = dom.Text;
const Range = dom.Range;

test "extractContents() returns DocumentFragment" {
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

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expectEqual(dom.NodeType.document_fragment, fragment.prototype.node_type);
}

test "extractContents() removes content from tree" {
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

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expectEqualStrings(" World", text.data);
}

test "extractContents() fragment contains extracted nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Extract me");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 0);
    try range.setEnd(&text.prototype, 7);

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expectEqual(@as(usize, 1), fragment.prototype.childNodes().length());

    const extracted_text: *Text = @fieldParentPtr("prototype", fragment.prototype.first_child.?);
    try std.testing.expectEqualStrings("Extract", extracted_text.data);
}

test "extractContents() with collapsed range returns empty fragment" {
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

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expectEqual(@as(usize, 0), fragment.prototype.childNodes().length());
    try std.testing.expectEqualStrings("Test", text.data);
}

test "extractContents() collapses range to start" {
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

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expect(range.collapsed());
    try std.testing.expectEqual(@as(u32, 1), range.start_offset);
}

test "extractContents() extracts element nodes" {
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

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expectEqual(@as(usize, 1), fragment.prototype.childNodes().length());
    try std.testing.expectEqual(@as(usize, 2), container.prototype.childNodes().length());
}
