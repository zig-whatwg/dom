//! Test main for JS bindings generator

const std = @import("std");
const webidl = @import("webidl-parser");
const js_gen = @import("js_bindings_generator.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: test-gen idl-file InterfaceName\n", .{});
        return error.MissingArgument;
    }

    const idl_path = args[1];
    const interface_name = args[2];

    // Read IDL file
    const idl_content = try std.fs.cwd().readFileAlloc(allocator, idl_path, 1024 * 1024);
    defer allocator.free(idl_content);

    // Generate bindings
    const bindings = try js_gen.generateBindings(allocator, interface_name, idl_content);
    defer allocator.free(bindings);

    // Print to stdout
    std.debug.print("{s}", .{bindings});
}
