const std = @import("std");
const SourceParser = @import("source_parser.zig").SourceParser;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var parser = SourceParser.init(allocator);

    std.debug.print("Parsing src/node.zig for Node struct...\n", .{});
    var methods = try parser.parseFile("src/node.zig", "Node");
    defer {
        for (methods.items) |*method| {
            method.deinit(allocator);
        }
        methods.deinit(allocator);
    }

    std.debug.print("\nFound {d} public methods:\n\n", .{methods.items.len});

    for (methods.items) |method| {
        std.debug.print("  {s} {s}(", .{
            if (method.is_inline) "inline" else "      ",
            method.name,
        });

        for (method.parameters.items, 0..) |param, i| {
            if (i > 0) std.debug.print(", ", .{});
            std.debug.print("{s}: {s}", .{ param.name, param.type });
        }

        std.debug.print(") {s}\n", .{method.return_type});
    }
}
