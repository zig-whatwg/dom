const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var list = std.ArrayList([]const u8){};
    
    // Try append with allocator
    try list.append(allocator, "hello");
    
    std.debug.print("Works!\n", .{});
    
    list.deinit(allocator);
}
