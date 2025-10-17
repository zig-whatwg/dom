//! Benchmark suite for DOM selector performance

const std = @import("std");
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
const Parser = @import("selector/parser.zig").Parser;
const Matcher = @import("selector/matcher.zig").Matcher;

/// Single benchmark result
pub const BenchmarkResult = struct {
    name: []const u8,
    operations: usize,
    total_ns: u64,
    ns_per_op: u64,
    ops_per_sec: u64,
};

/// Run a benchmark function multiple times and collect statistics
pub fn benchmarkFn(
    allocator: std.mem.Allocator,
    comptime name: []const u8,
    iterations: usize,
    func: *const fn (std.mem.Allocator) anyerror!void,
) !BenchmarkResult {
    // Warmup
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try func(allocator);
    }
    
    // Actual benchmark
    const start = std.time.nanoTimestamp();
    i = 0;
    while (i < iterations) : (i += 1) {
        try func(allocator);
    }
    const end = std.time.nanoTimestamp();
    
    const total_ns: u64 = @intCast(end - start);
    const ns_per_op = total_ns / iterations;
    const ops_per_sec = if (ns_per_op > 0) 
        (1_000_000_000 / ns_per_op) 
    else 
        0;
    
    return BenchmarkResult{
        .name = name,
        .operations = iterations,
        .total_ns = total_ns,
        .ns_per_op = ns_per_op,
        .ops_per_sec = ops_per_sec,
    };
}

/// Run all benchmarks and return results
pub fn runAllBenchmarks(allocator: std.mem.Allocator) ![]BenchmarkResult {
    var results: std.ArrayList(BenchmarkResult) = .empty;
    errdefer results.deinit(allocator);
    
    std.debug.print("Running tokenizer benchmarks...\n", .{});
    try results.append(allocator, try benchmarkFn(allocator, "Tokenizer: Simple ID (#main)", 10000, tokenizeSimpleId));
    try results.append(allocator, try benchmarkFn(allocator, "Tokenizer: Simple Class (.button)", 10000, tokenizeSimpleClass));
    try results.append(allocator, try benchmarkFn(allocator, "Tokenizer: Complex", 10000, tokenizeComplex));
    
    std.debug.print("Running parser benchmarks...\n", .{});
    try results.append(allocator, try benchmarkFn(allocator, "Parser: Simple ID (#main)", 10000, parseSimpleId));
    try results.append(allocator, try benchmarkFn(allocator, "Parser: Simple Class (.button)", 10000, parseSimpleClass));
    try results.append(allocator, try benchmarkFn(allocator, "Parser: Complex", 10000, parseComplex));
    
    std.debug.print("Running matcher benchmarks...\n", .{});
    try results.append(allocator, try benchmarkFn(allocator, "Matcher: Simple ID", 10000, matchSimpleId));
    try results.append(allocator, try benchmarkFn(allocator, "Matcher: Simple Class", 10000, matchSimpleClass));
    
    std.debug.print("Running querySelector benchmarks...\n", .{});
    try results.append(allocator, try benchmarkFn(allocator, "querySelector: Small DOM (100)", 1000, querySmallDom));
    try results.append(allocator, try benchmarkFn(allocator, "querySelector: Medium DOM (1000)", 1000, queryMediumDom));
    try results.append(allocator, try benchmarkFn(allocator, "querySelector: Large DOM (10000)", 100, queryLargeDom));
    try results.append(allocator, try benchmarkFn(allocator, "querySelector: Class selector", 1000, queryClass));
    
    std.debug.print("Running SPA benchmarks...\n", .{});
    try results.append(allocator, try benchmarkFn(allocator, "SPA: Repeated queries (1000x)", 1000, spaRepeated));
    
    return results.toOwnedSlice(allocator);
}

// Benchmark functions

fn tokenizeSimpleId(allocator: std.mem.Allocator) !void {
    var tokenizer = Tokenizer.init(allocator, "#main");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);
}

fn tokenizeSimpleClass(allocator: std.mem.Allocator) !void {
    var tokenizer = Tokenizer.init(allocator, ".button");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);
}

fn tokenizeComplex(allocator: std.mem.Allocator) !void {
    var tokenizer = Tokenizer.init(allocator, "div.active > a[href]:not(.disabled)");
    const tokens = try tokenizer.tokenize();
    defer allocator.free(tokens);
}

fn parseSimpleId(allocator: std.mem.Allocator) !void {
    var tokenizer = Tokenizer.init(allocator, "#main");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();
    var list = try parser.parse();
    defer list.deinit();
}

fn parseSimpleClass(allocator: std.mem.Allocator) !void {
    var tokenizer = Tokenizer.init(allocator, ".button");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();
    var list = try parser.parse();
    defer list.deinit();
}

fn parseComplex(allocator: std.mem.Allocator) !void {
    var tokenizer = Tokenizer.init(allocator, "div.active > a[href]:not(.disabled)");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();
    var list = try parser.parse();
    defer list.deinit();
}

fn matchSimpleId(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    const div = try doc.createElement("div");
    try div.setAttribute("id", "target");
    _ = try root.node.appendChild(&div.node);
    
    var tokenizer = Tokenizer.init(allocator, "#target");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();
    var list = try parser.parse();
    defer list.deinit();
    
    const matcher = Matcher.init(allocator);
    _ = try matcher.matches(div, &list);
}

fn matchSimpleClass(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    const button = try doc.createElement("button");
    try button.setAttribute("class", "btn");
    _ = try root.node.appendChild(&button.node);
    
    var tokenizer = Tokenizer.init(allocator, ".btn");
    var parser = try Parser.init(allocator, &tokenizer);
    defer parser.deinit();
    var list = try parser.parse();
    defer list.deinit();
    
    const matcher = Matcher.init(allocator);
    _ = try matcher.matches(button, &list);
}

fn querySmallDom(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const div = try doc.createElement("div");
        if (i == 50) try div.setAttribute("id", "target");
        _ = try root.node.appendChild(&div.node);
    }
    
    const result = try doc.querySelector("#target");
    _ = result;
}

fn queryMediumDom(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const div = try doc.createElement("div");
        if (i == 500) try div.setAttribute("id", "target");
        _ = try root.node.appendChild(&div.node);
    }
    
    const result = try doc.querySelector("#target");
    _ = result;
}

fn queryLargeDom(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        const div = try doc.createElement("div");
        if (i == 5000) try div.setAttribute("id", "target");
        _ = try root.node.appendChild(&div.node);
    }
    
    const result = try doc.querySelector("#target");
    _ = result;
}

fn queryClass(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const div = try doc.createElement("div");
        if (i % 100 == 0) try div.setAttribute("class", "target");
        _ = try root.node.appendChild(&div.node);
    }
    
    const result = try doc.querySelector(".target");
    _ = result;
}

fn spaRepeated(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);
    
    var i: usize = 0;
    while (i < 500) : (i += 1) {
        const div = try doc.createElement("div");
        try div.setAttribute("class", "component");
        _ = try root.node.appendChild(&div.node);
    }
    
    const result = try doc.querySelector(".component");
    _ = result;
}
