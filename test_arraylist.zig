const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();
    
    try list.append("hello");
    try list.append("world");
    
    std.debug.print("Length: {}\n", .{list.items.len});
}
