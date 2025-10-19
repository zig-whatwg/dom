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
            if (std.mem.startsWith(u8, name, "Attribute:"))
                return "Attribute Operations (Phase 15)";
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
        const bytes = result.bytes_per_op; // Show baseline memory (after warmup)

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

        // Format memory (check for overflow/invalid values)
        // Values > 1TB are likely unsigned wraparound, show as 0
        const valid_bytes = if (bytes > 1024 * 1024 * 1024 * 1024) 0 else bytes;
        const mem_str = if (valid_bytes < 1024)
            "B"
        else if (valid_bytes < 1024 * 1024)
            "KB"
        else if (valid_bytes < 1024 * 1024 * 1024)
            "MB"
        else
            "GB";
        const mem_val: u64 = if (valid_bytes < 1024)
            valid_bytes
        else if (valid_bytes < 1024 * 1024)
            valid_bytes / 1024
        else if (valid_bytes < 1024 * 1024 * 1024)
            valid_bytes / (1024 * 1024)
        else
            valid_bytes / (1024 * 1024 * 1024);

        std.debug.print("{s}: {d}{s}/op ({d} ops/sec) | {d}{s} total\n", .{ result.name, time_val, time_str, result.ops_per_sec, mem_val, mem_str });
    }

    std.debug.print("\nBenchmark complete!\n", .{});
}
