const std = @import("std");
const dom = @import("dom");

pub fn main() !void {
    std.debug.print("DOM library initialized.\n", .{});
    std.debug.print("Node size: {d} bytes\n", .{@sizeOf(dom.Node)});
    std.debug.print("AbortSignal size: {d} bytes\n", .{@sizeOf(dom.AbortSignal)});
    std.debug.print("AbortController size: {d} bytes\n", .{@sizeOf(dom.AbortController)});
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
