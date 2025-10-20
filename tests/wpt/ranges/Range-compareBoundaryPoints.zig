// META: title=Range.compareBoundaryPoints() tests
// META: link=https://dom.spec.whatwg.org/#dom-range-compareboundarypoints

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Range = dom.Range;
const HowToCompare = dom.HowToCompare;

test "compareBoundaryPoints START_TO_START with same range" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&elem.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&elem.prototype, 0);
    try range.setEnd(&elem.prototype, 0);

    const result = try range.compareBoundaryPoints(.start_to_start, range);
    try std.testing.expectEqual(@as(i16, 0), result);
}

test "compareBoundaryPoints START_TO_END with different positions" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range1 = try doc.createRange();
    defer range1.deinit();

    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setStart(&text.prototype, 0);
    try range1.setEnd(&text.prototype, 5);

    try range2.setStart(&text.prototype, 6);
    try range2.setEnd(&text.prototype, 11);

    const result = try range1.compareBoundaryPoints(.start_to_end, range2);
    try std.testing.expect(result < 0);
}

test "compareBoundaryPoints END_TO_END with same position" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Test");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range1 = try doc.createRange();
    defer range1.deinit();

    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setStart(&text.prototype, 0);
    try range1.setEnd(&text.prototype, 4);

    try range2.setStart(&text.prototype, 2);
    try range2.setEnd(&text.prototype, 4);

    const result = try range1.compareBoundaryPoints(.end_to_end, range2);
    try std.testing.expectEqual(@as(i16, 0), result);
}

test "compareBoundaryPoints END_TO_START" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("ABCDEF");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range1 = try doc.createRange();
    defer range1.deinit();

    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setStart(&text.prototype, 0);
    try range1.setEnd(&text.prototype, 3);

    try range2.setStart(&text.prototype, 4);
    try range2.setEnd(&text.prototype, 6);

    const result = try range1.compareBoundaryPoints(.end_to_start, range2);
    try std.testing.expect(result < 0);
}

test "compareBoundaryPoints returns negative when first point before second" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Testing");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range1 = try doc.createRange();
    defer range1.deinit();

    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setStart(&text.prototype, 1);
    try range1.setEnd(&text.prototype, 3);

    try range2.setStart(&text.prototype, 4);
    try range2.setEnd(&text.prototype, 6);

    const result = try range1.compareBoundaryPoints(.start_to_start, range2);
    try std.testing.expect(result < 0);
}

test "compareBoundaryPoints returns positive when first point after second" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Testing");
    const container = try doc.createElement("container");
    _ = try container.prototype.appendChild(&text.prototype);
    _ = try doc.prototype.appendChild(&container.prototype);

    const range1 = try doc.createRange();
    defer range1.deinit();

    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setStart(&text.prototype, 4);
    try range1.setEnd(&text.prototype, 6);

    try range2.setStart(&text.prototype, 1);
    try range2.setEnd(&text.prototype, 3);

    const result = try range1.compareBoundaryPoints(.start_to_start, range2);
    try std.testing.expect(result > 0);
}
