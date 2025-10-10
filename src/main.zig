//! Main Entry Point
//!
//! This is the main entry point for the DOM library when built as an executable.
//! The library is primarily designed to be used as a package, but this file
//! provides a simple demonstration entry point.
//!
//! ## Usage as Library
//!
//! To use this as a library in your project, add to build.zig:
//! ```zig
//! const dom = b.dependency("dom", .{});
//! exe.root_module.addImport("dom", dom.module("dom"));
//! ```
//!
//! Then in your code:
//! ```zig
//! const dom = @import("dom");
//! const node = try dom.Node.init(allocator, .element_node);
//! ```

const std = @import("std");

pub fn main() !void {
    std.debug.print("DOM Standard Implementation v0.1.0\n", .{});
    std.debug.print("WHATWG DOM Living Standard\n", .{});
    std.debug.print("Use as a library: const dom = @import(\"dom\");\n", .{});
}

test "basic ArrayList usage" {
    const allocator = std.testing.allocator;
    var list = std.ArrayList(i32){};
    defer list.deinit(allocator);
    try list.append(allocator, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "string comparison" {
    try std.testing.expectEqualStrings("hello", "hello");
    try std.testing.expect(!std.mem.eql(u8, "hello", "world"));
}
