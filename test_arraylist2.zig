const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var list = std.ArrayList([]const u8){};
    
    try list.append(allocator, "hello");
    try list.append(allocator, "world");
    
    std.debug.print("Length: {}\n", .{list.items.len});
    
    list.deinit(allocator);
}
