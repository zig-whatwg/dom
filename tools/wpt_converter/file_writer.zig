//! File Writer - Write converted test files to output directory

const std = @import("std");
const fs = std.fs;
const mem = std.mem;

pub fn writeTestFile(path: []const u8, content: []const u8) !void {
    // Ensure parent directory exists
    if (mem.lastIndexOf(u8, path, "/")) |last_slash| {
        const dir_path = path[0..last_slash];
        fs.cwd().makePath(dir_path) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };
    }

    // Write file
    const file = try fs.cwd().createFile(path, .{});
    defer file.close();

    try file.writeAll(content);
}

pub fn copyDependencyFile(source_path: []const u8, dest_path: []const u8) !void {
    // Ensure parent directory exists
    if (mem.lastIndexOf(u8, dest_path, "/")) |last_slash| {
        const dir_path = dest_path[0..last_slash];
        fs.cwd().makePath(dir_path) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };
    }

    // Copy file
    try fs.cwd().copyFile(source_path, fs.cwd(), dest_path, .{});
}
