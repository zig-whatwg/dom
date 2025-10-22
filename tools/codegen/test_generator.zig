const std = @import("std");
const Generator = @import("generator.zig").Generator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var generator = Generator.init(allocator);
    defer generator.deinit();

    std.debug.print("Generating Element delegations from Node source...\n\n", .{});

    // Generate Element delegations from Node
    try generator.generateFromSource(
        "Element", // child interface
        "src/node.zig", // parent source file
        "Node", // parent struct name
    );

    // Print generated code (first 2000 chars)
    const output = generator.getOutput();
    const preview_len = @min(output.len, 2000);
    std.debug.print("{s}\n", .{output[0..preview_len]});

    if (output.len > 2000) {
        std.debug.print("\n... ({d} more characters) ...\n", .{output.len - 2000});
    }
}
