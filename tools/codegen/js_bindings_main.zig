//! Main entry point for JS bindings generator

const std = @import("std");
const webidl = @import("webidl-parser");
const js_gen = @import("js_bindings_generator.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Read dom.idl
    const idl_path = "skills/whatwg_compliance/dom.idl";
    const idl_content = try std.fs.cwd().readFileAlloc(allocator, idl_path, 1024 * 1024);
    defer allocator.free(idl_content);

    // Get interface name from args
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: js-bindings-gen InterfaceName\n", .{});
        return error.MissingArgument;
    }

    const interface_name = args[1];

    // Generate bindings
    const bindings = try js_gen.generateBindings(allocator, interface_name, idl_content);
    defer allocator.free(bindings);

    // Write to output file - create lowercase filename
    var lower_buf: [256]u8 = undefined;
    var lower_len: usize = 0;
    for (interface_name) |c| {
        lower_buf[lower_len] = std.ascii.toLower(c);
        lower_len += 1;
    }
    const lower_name = lower_buf[0..lower_len];

    const out_path = try std.fmt.allocPrint(allocator, "js-bindings/{s}.zig", .{lower_name});
    defer allocator.free(out_path);

    try std.fs.cwd().writeFile(.{
        .sub_path = out_path,
        .data = bindings,
    });

    std.debug.print("Generated: {s}\n", .{out_path});
}
