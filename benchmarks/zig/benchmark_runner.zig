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
    std.debug.print("========\n", .{});

    // Define category detection
    const Category = struct {
        fn getCategory(name: []const u8) ?[]const u8 {
            if (std.mem.startsWith(u8, name, "Tokenizer:") or
                std.mem.startsWith(u8, name, "Parser:") or
                std.mem.startsWith(u8, name, "Matcher:"))
                return "Internal Components";
            if (std.mem.startsWith(u8, name, "Pure query: getElementById") or
                std.mem.startsWith(u8, name, "Pure query: querySelector #id"))
                return "Pure Query: ID Lookups";
            if (std.mem.startsWith(u8, name, "Pure query: getElementsByTagName") or
                std.mem.startsWith(u8, name, "Pure query: querySelector tag"))
                return "Pure Query: Tag Lookups";
            if (std.mem.startsWith(u8, name, "Pure query: getElementsByClassName") or
                std.mem.startsWith(u8, name, "Pure query: querySelector .class"))
                return "Pure Query: Class Lookups";
            if (std.mem.startsWith(u8, name, "Complex:"))
                return "Complex Selectors";
            if (std.mem.startsWith(u8, name, "DOM construction:"))
                return "DOM Construction";
            if (std.mem.startsWith(u8, name, "querySelector:") or
                std.mem.startsWith(u8, name, "getElementById:"))
                return "Full Benchmarks (Construction + Query)";
            if (std.mem.startsWith(u8, name, "SPA:"))
                return "SPA Patterns";
            return null;
        }
    };

    var last_category: ?[]const u8 = null;
    for (results) |result| {
        const category = Category.getCategory(result.name);

        // Print category header if entering a new category
        if (category) |cat| {
            if (last_category == null or !std.mem.eql(u8, last_category.?, cat)) {
                std.debug.print("\n{s}\n", .{cat});
                std.debug.print("{s}\n", .{"--------------------------------------------------"});
                last_category = cat;
            }
        }

        const ns = result.ns_per_op;
        const bytes = result.bytes_per_op;

        // Format time
        const time_str = if (ns < 1000)
            "ns"
        else if (ns < 1_000_000)
            "µs"
        else
            "ms";
        const time_val = if (ns < 1000)
            ns
        else if (ns < 1_000_000)
            ns / 1000
        else
            ns / 1_000_000;

        // Format memory
        const mem_str = if (bytes < 1024)
            "B"
        else if (bytes < 1024 * 1024)
            "KB"
        else
            "MB";
        const mem_val = if (bytes < 1024)
            bytes
        else if (bytes < 1024 * 1024)
            bytes / 1024
        else
            bytes / (1024 * 1024);

        std.debug.print("{s}: {d}{s}/op | {d}{s}/op | {d} ops/sec\n", .{ result.name, time_val, time_str, mem_val, mem_str, result.ops_per_sec });
    }

    std.debug.print("\nBenchmark complete!\n", .{});
}
