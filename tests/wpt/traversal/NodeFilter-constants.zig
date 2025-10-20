// META: title=NodeFilter constants
// META: link=https://dom.spec.whatwg.org/#interface-nodefilter

const std = @import("std");
const dom = @import("dom");
const NodeFilter = dom.NodeFilter;
const FilterResult = dom.FilterResult;

test "NodeFilter acceptNode constants" {
    try std.testing.expectEqual(@as(u32, 1), @intFromEnum(FilterResult.accept));
    try std.testing.expectEqual(@as(u32, 2), @intFromEnum(FilterResult.reject));
    try std.testing.expectEqual(@as(u32, 3), @intFromEnum(FilterResult.skip));
}

test "NodeFilter SHOW_ALL constant" {
    try std.testing.expectEqual(@as(u32, 0xFFFFFFFF), NodeFilter.SHOW_ALL);
}

test "NodeFilter SHOW_ELEMENT constant" {
    try std.testing.expectEqual(@as(u32, 0x1), NodeFilter.SHOW_ELEMENT);
}

test "NodeFilter SHOW_ATTRIBUTE constant" {
    try std.testing.expectEqual(@as(u32, 0x2), NodeFilter.SHOW_ATTRIBUTE);
}

test "NodeFilter SHOW_TEXT constant" {
    try std.testing.expectEqual(@as(u32, 0x4), NodeFilter.SHOW_TEXT);
}

test "NodeFilter SHOW_CDATA_SECTION constant" {
    try std.testing.expectEqual(@as(u32, 0x8), NodeFilter.SHOW_CDATA_SECTION);
}

test "NodeFilter SHOW_ENTITY_REFERENCE constant" {
    try std.testing.expectEqual(@as(u32, 0x10), NodeFilter.SHOW_ENTITY_REFERENCE);
}

test "NodeFilter SHOW_ENTITY constant" {
    try std.testing.expectEqual(@as(u32, 0x20), NodeFilter.SHOW_ENTITY);
}

test "NodeFilter SHOW_PROCESSING_INSTRUCTION constant" {
    try std.testing.expectEqual(@as(u32, 0x40), NodeFilter.SHOW_PROCESSING_INSTRUCTION);
}

test "NodeFilter SHOW_COMMENT constant" {
    try std.testing.expectEqual(@as(u32, 0x80), NodeFilter.SHOW_COMMENT);
}

test "NodeFilter SHOW_DOCUMENT constant" {
    try std.testing.expectEqual(@as(u32, 0x100), NodeFilter.SHOW_DOCUMENT);
}

test "NodeFilter SHOW_DOCUMENT_TYPE constant" {
    try std.testing.expectEqual(@as(u32, 0x200), NodeFilter.SHOW_DOCUMENT_TYPE);
}

test "NodeFilter SHOW_DOCUMENT_FRAGMENT constant" {
    try std.testing.expectEqual(@as(u32, 0x400), NodeFilter.SHOW_DOCUMENT_FRAGMENT);
}

test "NodeFilter SHOW_NOTATION constant" {
    try std.testing.expectEqual(@as(u32, 0x800), NodeFilter.SHOW_NOTATION);
}
