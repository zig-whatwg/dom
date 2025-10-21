const std = @import("std");
const dom = @import("dom");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const doc = try dom.Document.init(allocator);
    defer doc.release();
    
    const elem = try doc.createElement("div");
    
    // Set empty class
    try elem.setAttribute("class", "");
    
    var classList = elem.classList();
    
    // Add active
    std.debug.print("1. Adding 'active'...\n", .{});
    try classList.add(&[_][]const u8{"active"});
    std.debug.print("   Length: {}\n", .{classList.length()});
    
    // Add 3 more
    std.debug.print("2. Adding 'btn', 'btn-primary', 'disabled'...\n", .{});
    try classList.add(&[_][]const u8{"btn", "btn-primary", "disabled"});
    std.debug.print("   Length: {}\n", .{classList.length()});
    
    // Add active again (duplicate)
    std.debug.print("3. Adding 'active' again...\n", .{});
    try classList.add(&[_][]const u8{"active"});
    std.debug.print("   Length: {}\n", .{classList.length()});
    
    std.debug.print("Done!\n", .{});
}
