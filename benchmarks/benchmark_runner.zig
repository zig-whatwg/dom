const std = @import("std");

/// Benchmark Result
pub const BenchmarkResult = struct {
    name: []const u8,
    iterations: usize,
    total_ns: u64,
    avg_ns: u64,
    ops_per_sec: f64,

    pub fn print(self: *const BenchmarkResult) void {
        const avg_us = @as(f64, @floatFromInt(self.avg_ns)) / 1000.0;
        std.debug.print("  {s:<50} ", .{self.name});
        std.debug.print("{d:>8.2} μs/op  ", .{avg_us});
        std.debug.print("{d:>12.0} ops/sec\n", .{self.ops_per_sec});
    }
};

/// Run a benchmark
pub fn runBenchmark(
    allocator: std.mem.Allocator,
    name: []const u8,
    iterations: usize,
    comptime benchFn: fn (std.mem.Allocator) anyerror!void,
) !BenchmarkResult {
    // Warmup
    var i: usize = 0;
    while (i < @min(iterations / 10, 100)) : (i += 1) {
        try benchFn(allocator);
    }

    // Actual benchmark
    const start = std.time.nanoTimestamp();
    i = 0;
    while (i < iterations) : (i += 1) {
        try benchFn(allocator);
    }
    const end = std.time.nanoTimestamp();
    const total_ns = @as(u64, @intCast(end - start));
    const avg_ns = total_ns / iterations;
    const ops_per_sec = 1_000_000_000.0 / @as(f64, @floatFromInt(avg_ns));

    return BenchmarkResult{
        .name = name,
        .iterations = iterations,
        .total_ns = total_ns,
        .avg_ns = avg_ns,
        .ops_per_sec = ops_per_sec,
    };
}
