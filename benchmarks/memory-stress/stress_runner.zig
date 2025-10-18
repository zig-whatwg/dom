//! Memory stress test runner
//!
//! Command-line interface for running DOM memory stress tests.

const std = @import("std");
const stress_test = @import("stress_test.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .enable_memory_limit = true }){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command-line arguments
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip program name
    _ = args.skip();

    var duration_seconds: u64 = 1200; // Default: 20 minutes
    var seed: u64 = @intCast(std.time.milliTimestamp());
    var sample_interval_ms: u64 = 10000; // Default: 10 seconds
    var output_dir: []const u8 = "benchmark_results/memory_stress";

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--duration")) {
            const value = args.next() orelse {
                std.debug.print("Error: --duration requires a value\n", .{});
                return error.InvalidArgument;
            };
            duration_seconds = try std.fmt.parseInt(u64, value, 10);
        } else if (std.mem.eql(u8, arg, "--seed")) {
            const value = args.next() orelse {
                std.debug.print("Error: --seed requires a value\n", .{});
                return error.InvalidArgument;
            };
            seed = try std.fmt.parseInt(u64, value, 10);
        } else if (std.mem.eql(u8, arg, "--interval")) {
            const value = args.next() orelse {
                std.debug.print("Error: --interval requires a value\n", .{});
                return error.InvalidArgument;
            };
            const interval_seconds = try std.fmt.parseInt(u64, value, 10);
            sample_interval_ms = interval_seconds * 1000;
        } else if (std.mem.eql(u8, arg, "--output")) {
            output_dir = args.next() orelse {
                std.debug.print("Error: --output requires a value\n", .{});
                return error.InvalidArgument;
            };
        } else if (std.mem.eql(u8, arg, "--help")) {
            printHelp();
            return;
        } else {
            std.debug.print("Unknown argument: {s}\n", .{arg});
            printHelp();
            return error.InvalidArgument;
        }
    }

    std.debug.print("==============================================\n", .{});
    std.debug.print("  DOM Memory Stress Test\n", .{});
    std.debug.print("==============================================\n", .{});
    std.debug.print("Duration: {d} seconds\n", .{duration_seconds});
    std.debug.print("Sample interval: {d} seconds\n", .{sample_interval_ms / 1000});
    std.debug.print("Seed: {d}\n", .{seed});
    std.debug.print("Output: {s}\n", .{output_dir});
    std.debug.print("==============================================\n\n", .{});

    // Create configuration
    const config = stress_test.StressTestConfig{
        .duration_seconds = duration_seconds,
        .sample_interval_ms = sample_interval_ms,
        .nodes_per_cycle = 10000, // Create 10k nodes per cycle
        .operations_per_node = 100, // 100 manipulations per cycle
        .seed = seed,
    };

    // Run stress test
    var test_runner = try stress_test.StressTest.init(allocator, &gpa, config);
    defer test_runner.deinit();

    try test_runner.run();

    // Get results
    const results = try test_runner.getResults(allocator);
    defer allocator.free(results.samples);

    // Save results to JSON
    try saveResults(allocator, output_dir, seed, results);

    std.debug.print("\n==============================================\n", .{});
    std.debug.print("  Test Complete!\n", .{});
    std.debug.print("==============================================\n", .{});
}

fn printHelp() void {
    std.debug.print(
        \\Memory Stress Test for DOM
        \\
        \\Usage:
        \\  zig build memory-stress -Doptimize=ReleaseFast -- [options]
        \\
        \\Options:
        \\  --duration N    Test duration in seconds (default: 1200 = 20 minutes)
        \\  --seed N        Random seed for reproducibility (default: timestamp)
        \\  --interval N    Sample interval in seconds (default: 10)
        \\  --output PATH   Output directory (default: benchmark_results/memory_stress)
        \\  --help          Show this help message
        \\
        \\Examples:
        \\  # Quick test (30 seconds)
        \\  zig build memory-stress -Doptimize=ReleaseFast -- --duration 30
        \\
        \\  # Full test (20 minutes)
        \\  zig build memory-stress -Doptimize=ReleaseFast
        \\
        \\  # Reproducible test
        \\  zig build memory-stress -Doptimize=ReleaseFast -- --duration 60 --seed 12345
        \\
    , .{});
}

fn saveResults(
    allocator: std.mem.Allocator,
    output_dir: []const u8,
    _: u64,
    results: stress_test.StressTestResult,
) !void {
    // Create output directory
    std.fs.cwd().makeDir(output_dir) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    // Generate filename with timestamp
    const timestamp = std.time.milliTimestamp();
    const filename = try std.fmt.allocPrint(
        allocator,
        "{s}/memory_samples_{d}.json",
        .{ output_dir, timestamp },
    );
    defer allocator.free(filename);

    // Build JSON string in memory
    var json: std.ArrayList(u8) = .empty;
    defer json.deinit(allocator);
    const writer = json.writer(allocator);

    try writer.writeAll("{\n");

    // Config
    try writer.writeAll("  \"config\": {\n");
    try writer.print("    \"duration_seconds\": {d},\n", .{results.config.duration_seconds});
    try writer.print("    \"sample_interval_ms\": {d},\n", .{results.config.sample_interval_ms});
    try writer.print("    \"nodes_per_cycle\": {d},\n", .{results.config.nodes_per_cycle});
    try writer.print("    \"operations_per_node\": {d},\n", .{results.config.operations_per_node});
    try writer.print("    \"seed\": {d}\n", .{results.config.seed});
    try writer.writeAll("  },\n");

    // Samples
    try writer.writeAll("  \"samples\": [\n");
    for (results.samples, 0..) |sample, i| {
        try writer.writeAll("    {\n");
        try writer.print("      \"timestamp_ms\": {d},\n", .{sample.timestamp_ms});
        try writer.print("      \"bytes_used\": {d},\n", .{sample.bytes_used});
        try writer.print("      \"peak_bytes\": {d},\n", .{sample.peak_bytes});
        try writer.print("      \"operations_completed\": {d}\n", .{sample.operations_completed});
        if (i < results.samples.len - 1) {
            try writer.writeAll("    },\n");
        } else {
            try writer.writeAll("    }\n");
        }
    }
    try writer.writeAll("  ],\n");

    // Final state
    try writer.writeAll("  \"final_state\": {\n");
    try writer.print("    \"cycles_completed\": {d},\n", .{results.cycles_completed});
    try writer.writeAll("    \"operation_breakdown\": {\n");
    try writer.print("      \"nodes_created\": {d},\n", .{results.operation_breakdown.nodes_created});
    try writer.print("      \"nodes_deleted\": {d},\n", .{results.operation_breakdown.nodes_deleted});
    try writer.print("      \"reads\": {d},\n", .{results.operation_breakdown.reads});
    try writer.print("      \"updates\": {d}\n", .{results.operation_breakdown.updates});
    try writer.writeAll("    }\n");
    try writer.writeAll("  }\n");

    try writer.writeAll("}\n");

    // Write to file
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    try file.writeAll(json.items);

    std.debug.print("\nResults saved to: {s}\n", .{filename});

    // Save "latest" symlink info
    const latest_filename = try std.fmt.allocPrint(
        allocator,
        "{s}/memory_samples_latest.json",
        .{output_dir},
    );
    defer allocator.free(latest_filename);

    // Copy to latest (overwrite)
    std.fs.cwd().deleteFile(latest_filename) catch {};
    try std.fs.cwd().copyFile(filename, std.fs.cwd(), latest_filename, .{});
    std.debug.print("Latest results: {s}\n", .{latest_filename});
}
