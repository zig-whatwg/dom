// META: title=Range constructor test
// META: link=https://dom.spec.whatwg.org/#dom-range-range

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Range = dom.Range;

test "Range() constructor creates collapsed range at document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const range = try doc.createRange();
    defer range.deinit();

    try std.testing.expectEqual(&doc.prototype, range.start_container);
    try std.testing.expectEqual(&doc.prototype, range.end_container);
    try std.testing.expectEqual(@as(u32, 0), range.start_offset);
    try std.testing.expectEqual(@as(u32, 0), range.end_offset);
    try std.testing.expect(range.collapsed());
    try std.testing.expectEqual(&doc.prototype, range.commonAncestorContainer());
}
