const std = @import("std");
const Generator = @import("generator.zig").Generator;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var generator = Generator.init(allocator);
    defer generator.deinit();

    std.debug.print("Generating Element delegations from Node source...\n", .{});

    // Generate Element delegations from Node
    try generator.generateFromSource(
        "Element", // child interface
        "src/node.zig", // parent source file
        "Node", // parent struct name
    );

    // Write to file
    const file = try std.fs.cwd().createFile("/tmp/element_delegations.zig", .{});
    defer file.close();

    const output = generator.getOutput();
    try file.writeAll(output);

    std.debug.print("Wrote {d} bytes to /tmp/element_delegations.zig\n", .{output.len});

    // Count methods
    var count: usize = 0;
    var iter = std.mem.tokenizeScalar(u8, output, '\n');
    while (iter.next()) |line| {
        if (std.mem.startsWith(u8, line, "    pub inline fn") or
            std.mem.startsWith(u8, line, "    pub fn"))
        {
            count += 1;
        }
    }

    std.debug.print("Generated {d} methods\n", .{count});
}
