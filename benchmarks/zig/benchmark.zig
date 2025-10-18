//! Benchmark suite for DOM selector performance

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Tokenizer = dom.selector.Tokenizer;
const Parser = dom.selector.Parser;
const Matcher = dom.selector.Matcher;

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

/// Run a benchmark with setup phase (setup runs once, func runs multiple times)
/// This is useful for benchmarks where you want to build the DOM once and then
/// measure just the query operations.
pub fn benchmarkWithSetup(
    allocator: std.mem.Allocator,
    comptime name: []const u8,
    iterations: usize,
    setup: *const fn (std.mem.Allocator) anyerror!*Document,
    func: *const fn (*Document) anyerror!void,
) !BenchmarkResult {
    // Setup: build DOM once
    const doc = try setup(allocator);
    defer doc.release();

    // Warmup
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        try func(doc);
    }

    // Actual benchmark: only measure the func execution
    const start = std.time.nanoTimestamp();
    i = 0;
    while (i < iterations) : (i += 1) {
        try func(doc);
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
    try results.append(allocator, try benchmarkFn(allocator, "SPA: Cold vs Hot cache (100x)", 100, spaColdVsHot));

    std.debug.print("Running getElementById benchmarks...\n", .{});
    try results.append(allocator, try benchmarkFn(allocator, "getElementById: Small DOM (100)", 1000, getElementByIdSmall));
    try results.append(allocator, try benchmarkFn(allocator, "getElementById: Medium DOM (1000)", 1000, getElementByIdMedium));
    try results.append(allocator, try benchmarkFn(allocator, "getElementById: Large DOM (10000)", 100, getElementByIdLarge));

    std.debug.print("Running query-only benchmarks (DOM pre-built)...\n", .{});
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementById (100 elem)", 100000, setupSmallDom, benchGetElementById));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementById (1000 elem)", 100000, setupMediumDom, benchGetElementById));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementById (10000 elem)", 100000, setupLargeDom, benchGetElementById));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector #id (100 elem)", 100000, setupSmallDom, benchQuerySelectorId));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector #id (1000 elem)", 100000, setupMediumDom, benchQuerySelectorId));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector #id (10000 elem)", 100000, setupLargeDom, benchQuerySelectorId));

    std.debug.print("Running tag query benchmarks (Phase 3)...\n", .{});
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementsByTagName (100 elem)", 100000, setupTagSmall, benchGetElementsByTagName));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementsByTagName (1000 elem)", 100000, setupTagMedium, benchGetElementsByTagName));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementsByTagName (10000 elem)", 100000, setupTagLarge, benchGetElementsByTagName));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector tag (100 elem)", 100000, setupTagSmall, benchQuerySelectorTag));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector tag (1000 elem)", 100000, setupTagMedium, benchQuerySelectorTag));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector tag (10000 elem)", 100000, setupTagLarge, benchQuerySelectorTag));

    // Phase 4: Class query benchmarks
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementsByClassName (100 elem)", 100000, setupClassSmall, benchGetElementsByClassName));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementsByClassName (1000 elem)", 100000, setupClassMedium, benchGetElementsByClassName));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: getElementsByClassName (10000 elem)", 100000, setupClassLarge, benchGetElementsByClassName));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector .class (100 elem)", 100000, setupClassSmall, benchQuerySelectorClass));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector .class (1000 elem)", 100000, setupClassMedium, benchQuerySelectorClass));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Pure query: querySelector .class (10000 elem)", 100000, setupClassLarge, benchQuerySelectorClass));

    std.debug.print("Running DOM construction benchmarks (Phase 1.2)...\n", .{});
    try results.append(allocator, try benchmarkFn(allocator, "DOM construction: Small (100 elem)", 1000, constructSmallDom));
    try results.append(allocator, try benchmarkFn(allocator, "DOM construction: Medium (1000 elem)", 1000, constructMediumDom));
    try results.append(allocator, try benchmarkFn(allocator, "DOM construction: Large (10000 elem)", 100, constructLargeDom));

    std.debug.print("Running complex selector benchmarks...\n", .{});
    try results.append(allocator, try benchmarkWithSetup(allocator, "Complex: Child combinator (div > p)", 100000, setupChildCombinator, benchChildCombinator));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Complex: Descendant combinator (article p)", 100000, setupDescendantCombinator, benchDescendantCombinator));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Complex: Adjacent sibling (h1 + p)", 100000, setupAdjacentSibling, benchAdjacentSibling));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Complex: Type + class (div.active)", 100000, setupTypeClass, benchTypeClass));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Complex: Attribute selector (div[data-id])", 100000, setupAttributeSelector, benchAttributeSelector));
    try results.append(allocator, try benchmarkWithSetup(allocator, "Complex: Multi-component (article#main > header h1.title)", 100000, setupComplexMultiComponent, benchComplexMultiComponent));

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

    // Build DOM with various components
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const div = try doc.createElement("div");
        try div.setAttribute("class", "component");
        _ = try root.node.appendChild(&div.node);

        const button = try doc.createElement("button");
        try button.setAttribute("class", "btn primary");
        _ = try div.node.appendChild(&button.node);
    }

    // Simulate SPA: repeated queries for different selectors
    // First query parses and caches, subsequent queries use cache
    i = 0;
    while (i < 10) : (i += 1) {
        _ = try doc.querySelector(".component");
        _ = try doc.querySelector(".btn");
        _ = try doc.querySelector(".primary");
        _ = try doc.querySelector("button");
        _ = try doc.querySelector("div");
    }
}

fn spaColdVsHot(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Build simple DOM
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const div = try doc.createElement("div");
        try div.setAttribute("class", "item");
        if (i == 500) try div.setAttribute("id", "target");
        _ = try root.node.appendChild(&div.node);
    }

    // Run same query 100 times (1st is cold, rest are hot from cache)
    i = 0;
    while (i < 100) : (i += 1) {
        _ = try doc.querySelector(".item");
    }
}

fn getElementByIdSmall(allocator: std.mem.Allocator) !void {
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

    // Direct O(1) lookup!
    const result = doc.getElementById("target");
    _ = result;
}

fn getElementByIdMedium(allocator: std.mem.Allocator) !void {
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

    const result = doc.getElementById("target");
    _ = result;
}

fn getElementByIdLarge(allocator: std.mem.Allocator) !void {
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

    const result = doc.getElementById("target");
    _ = result;
}

// Setup functions for query-only benchmarks

fn setupSmallDom(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const div = try doc.createElement("div");
        if (i == 50) try div.setAttribute("id", "target");
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

fn setupMediumDom(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const div = try doc.createElement("div");
        if (i == 500) try div.setAttribute("id", "target");
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

fn setupLargeDom(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        const div = try doc.createElement("div");
        if (i == 5000) try div.setAttribute("id", "target");
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

// Query benchmark functions (measure only query time)

fn benchGetElementById(doc: *Document) !void {
    const result = doc.getElementById("target");
    _ = result;
}

fn benchQuerySelectorId(doc: *Document) !void {
    const result = try doc.querySelector("#target");
    _ = result;
}

// Setup functions for tag query benchmarks (Phase 3)

fn setupTagSmall(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Create mix of elements - 50 divs, 50 buttons
    var i: usize = 0;
    while (i < 50) : (i += 1) {
        const div = try doc.createElement("div");
        _ = try root.node.appendChild(&div.node);
    }

    i = 0;
    while (i < 50) : (i += 1) {
        const button = try doc.createElement("button");
        _ = try root.node.appendChild(&button.node);
    }

    return doc;
}

fn setupTagMedium(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Create mix of elements - 500 divs, 500 buttons
    var i: usize = 0;
    while (i < 500) : (i += 1) {
        const div = try doc.createElement("div");
        _ = try root.node.appendChild(&div.node);
    }

    i = 0;
    while (i < 500) : (i += 1) {
        const button = try doc.createElement("button");
        _ = try root.node.appendChild(&button.node);
    }

    return doc;
}

fn setupTagLarge(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Create mix of elements - 5000 divs, 5000 buttons
    var i: usize = 0;
    while (i < 5000) : (i += 1) {
        const div = try doc.createElement("div");
        _ = try root.node.appendChild(&div.node);
    }

    i = 0;
    while (i < 5000) : (i += 1) {
        const button = try doc.createElement("button");
        _ = try root.node.appendChild(&button.node);
    }

    return doc;
}

// Tag query benchmark functions (Phase 3)

fn benchGetElementsByTagName(doc: *Document) !void {
    const result = doc.getElementsByTagName("button");
    _ = result;
}

fn benchQuerySelectorTag(doc: *Document) !void {
    const result = try doc.querySelector("button");
    _ = result;
}

// Setup functions for class query benchmarks (Phase 4)

fn setupClassSmall(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Create mix of elements - 50 with "btn", 50 with "container"
    var i: usize = 0;
    while (i < 50) : (i += 1) {
        const button = try doc.createElement("button");
        try button.setAttribute("class", "btn primary");
        _ = try root.node.appendChild(&button.node);
    }

    i = 0;
    while (i < 50) : (i += 1) {
        const div = try doc.createElement("div");
        try div.setAttribute("class", "container");
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

fn setupClassMedium(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Create mix of elements - 500 with "btn", 500 with "container"
    var i: usize = 0;
    while (i < 500) : (i += 1) {
        const button = try doc.createElement("button");
        try button.setAttribute("class", "btn primary");
        _ = try root.node.appendChild(&button.node);
    }

    i = 0;
    while (i < 500) : (i += 1) {
        const div = try doc.createElement("div");
        try div.setAttribute("class", "container");
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

fn setupClassLarge(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    // Create mix of elements - 5000 with "btn", 5000 with "container"
    var i: usize = 0;
    while (i < 5000) : (i += 1) {
        const button = try doc.createElement("button");
        try button.setAttribute("class", "btn primary");
        _ = try root.node.appendChild(&button.node);
    }

    i = 0;
    while (i < 5000) : (i += 1) {
        const div = try doc.createElement("div");
        try div.setAttribute("class", "container");
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

// Class query benchmark functions (Phase 4)

fn benchGetElementsByClassName(doc: *Document) !void {
    const result = doc.getElementsByClassName("btn");
    _ = result;
}

fn benchQuerySelectorClass(doc: *Document) !void {
    const result = try doc.querySelector(".btn");
    _ = result;
}

// DOM Construction benchmarks (Phase 1.2)

fn constructSmallDom(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const div = try doc.createElement("div");
        _ = try root.node.appendChild(&div.node);
    }
}

fn constructMediumDom(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const div = try doc.createElement("div");
        _ = try root.node.appendChild(&div.node);
    }
}

fn constructLargeDom(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 10000) : (i += 1) {
        const div = try doc.createElement("div");
        _ = try root.node.appendChild(&div.node);
    }
}

// ===================================================================
// Complex Selector Benchmarks
// ===================================================================

fn setupChildCombinator(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    // Build: div > (div > p) * 1000
    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const div = try doc.createElement("div");
        const p = try doc.createElement("p");
        _ = try div.node.appendChild(&p.node);
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

fn setupDescendantCombinator(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    // Build: article > div > div > p * 1000
    const root = try doc.createElement("article");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const outer = try doc.createElement("div");
        const inner = try doc.createElement("div");
        const p = try doc.createElement("p");
        _ = try inner.node.appendChild(&p.node);
        _ = try outer.node.appendChild(&inner.node);
        _ = try root.node.appendChild(&outer.node);
    }

    return doc;
}

fn setupAdjacentSibling(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    // Build: (h1, p) * 500 pairs
    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 500) : (i += 1) {
        const h1 = try doc.createElement("h1");
        const p = try doc.createElement("p");
        _ = try root.node.appendChild(&h1.node);
        _ = try root.node.appendChild(&p.node);
    }

    return doc;
}

fn setupTypeClass(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    // Build: 1000 divs, 10% with class "active"
    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const div = try doc.createElement("div");
        if (i % 10 == 0) try div.setAttribute("class", "active");
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

fn setupAttributeSelector(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    // Build: 1000 divs with data-id
    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    var buf: [16]u8 = undefined;
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const div = try doc.createElement("div");
        const id_str = try std.fmt.bufPrint(&buf, "{d}", .{i});
        try div.setAttribute("data-id", id_str);
        _ = try root.node.appendChild(&div.node);
    }

    return doc;
}

fn setupComplexMultiComponent(allocator: std.mem.Allocator) !*Document {
    const doc = try Document.init(allocator);
    errdefer doc.release();

    // Build: article#main > header > (div > h1.title) * 100
    const article = try doc.createElement("article");
    try article.setAttribute("id", "main");
    _ = try doc.node.appendChild(&article.node);

    const header = try doc.createElement("header");
    _ = try article.node.appendChild(&header.node);

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const div = try doc.createElement("div");
        const h1 = try doc.createElement("h1");
        try h1.setAttribute("class", "title");
        _ = try div.node.appendChild(&h1.node);
        _ = try header.node.appendChild(&div.node);
    }

    return doc;
}

fn benchChildCombinator(doc: *Document) !void {
    const result = try doc.querySelector("div > p");
    _ = result;
}

fn benchDescendantCombinator(doc: *Document) !void {
    const result = try doc.querySelector("article p");
    _ = result;
}

fn benchAdjacentSibling(doc: *Document) !void {
    const result = try doc.querySelector("h1 + p");
    _ = result;
}

fn benchTypeClass(doc: *Document) !void {
    const result = try doc.querySelector("div.active");
    _ = result;
}

fn benchAttributeSelector(doc: *Document) !void {
    const result = try doc.querySelector("div[data-id=\"500\"]");
    _ = result;
}

fn benchComplexMultiComponent(doc: *Document) !void {
    const result = try doc.querySelector("article#main > header h1.title");
    _ = result;
}
