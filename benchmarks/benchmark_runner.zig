//! Benchmark runner executable

const std = @import("std");
const benchmark = @import("benchmark.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("DOM Selector Benchmark Suite\n", .{});
    std.debug.print("=============================\n\n", .{});

    const results = try benchmark.runAllBenchmarks(allocator);
    defer allocator.free(results);

    std.debug.print("\nResults:\n", .{});
    std.debug.print("--------\n", .{});
    for (results) |result| {
        const ns = result.ns_per_op;
        if (ns < 1000) {
            std.debug.print("{s}: {d}ns/op ({d} ops/sec)\n", .{ result.name, ns, result.ops_per_sec });
        } else if (ns < 1_000_000) {
            std.debug.print("{s}: {d}µs/op ({d} ops/sec)\n", .{ result.name, ns / 1000, result.ops_per_sec });
        } else {
            std.debug.print("{s}: {d}ms/op ({d} ops/sec)\n", .{ result.name, ns / 1_000_000, result.ops_per_sec });
        }
    }

    std.debug.print("\nBenchmark complete!\n", .{});
}
