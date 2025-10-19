//! fast_path Tests
//!
//! Tests for fast_path functionality.

const std = @import("std");
const testing = std.testing;
const dom = @import("dom");
const FastPathType = dom.FastPathType;
const detectFastPath = dom.detectFastPath;
const extractIdentifier = dom.extractIdentifier;

test "detectFastPath - simple ID" {
    try testing.expectEqual(FastPathType.simple_id, detectFastPath("#main"));
    try testing.expectEqual(FastPathType.simple_id, detectFastPath("  #main  "));
    try testing.expectEqual(FastPathType.simple_id, detectFastPath("#my-id"));
    try testing.expectEqual(FastPathType.simple_id, detectFastPath("#_private"));
}

test "detectFastPath - simple class" {
    try testing.expectEqual(FastPathType.simple_class, detectFastPath(".button"));
    try testing.expectEqual(FastPathType.simple_class, detectFastPath("  .button  "));
    try testing.expectEqual(FastPathType.simple_class, detectFastPath(".my-class"));
}

test "detectFastPath - simple tag" {
    try testing.expectEqual(FastPathType.simple_tag, detectFastPath("div"));
    try testing.expectEqual(FastPathType.simple_tag, detectFastPath("  div  "));
    try testing.expectEqual(FastPathType.simple_tag, detectFastPath("custom-element"));
}

test "detectFastPath - ID filtered" {
    try testing.expectEqual(FastPathType.id_filtered, detectFastPath("article#main .content"));
    try testing.expectEqual(FastPathType.id_filtered, detectFastPath("#wrapper div"));
}

test "detectFastPath - generic" {
    try testing.expectEqual(FastPathType.generic, detectFastPath("div > p"));
    try testing.expectEqual(FastPathType.generic, detectFastPath("div.active"));
    try testing.expectEqual(FastPathType.generic, detectFastPath("div:hover"));
    try testing.expectEqual(FastPathType.generic, detectFastPath("[href]"));
}

test "extractIdentifier - ID" {
    try testing.expectEqualStrings("main", extractIdentifier("#main"));
    try testing.expectEqualStrings("main", extractIdentifier("  #main  "));
}

test "extractIdentifier - class" {
    try testing.expectEqualStrings("button", extractIdentifier(".button"));
    try testing.expectEqualStrings("button", extractIdentifier("  .button  "));
}

test "extractIdentifier - tag" {
    try testing.expectEqualStrings("div", extractIdentifier("div"));
    try testing.expectEqualStrings("div", extractIdentifier("  div  "));
}
