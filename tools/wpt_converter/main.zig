//! WPT to V8 Test Converter
//!
//! Converts Web Platform Tests from HTML format to standalone JavaScript files
//! that can be executed in V8 with the DOM library.
//!
//! Usage:
//!   zig build wpt-convert
//!
//! This will:
//! 1. Scan /Users/bcardarella/projects/wpt/dom/ for .html test files
//! 2. Apply filtering rules to exclude rendering/layout tests
//! 3. Extract JavaScript from HTML files
//! 4. Convert HTML structure to document.body.innerHTML
//! 5. Convert absolute paths to relative paths
//! 6. Copy dependency files (testharness.js, common.js, etc.)
//! 7. Write to tests/wpt-v8/ with mirrored directory structure

const std = @import("std");
const fs = std.fs;
const mem = std.mem;

const HtmlParser = @import("html_parser.zig");
const PathConverter = @import("path_converter.zig");
const Filter = @import("filter.zig");
const FileWriter = @import("file_writer.zig");

const WPT_SOURCE_DIR = "/Users/bcardarella/projects/wpt/dom";
const OUTPUT_DIR = "tests/wpt-v8";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("WPT to V8 Test Converter\n", .{});
    std.debug.print("========================\n\n", .{});

    // Create output directory
    try ensureOutputDir();

    // Scan for HTML test files
    std.debug.print("Scanning {s} for HTML test files...\n", .{WPT_SOURCE_DIR});
    var test_files: std.ArrayList([]const u8) = .{};
    defer {
        for (test_files.items) |path| {
            allocator.free(path);
        }
        test_files.deinit(allocator);
    }

    try scanForTests(allocator, &test_files);
    std.debug.print("Found {} HTML test files\n\n", .{test_files.items.len});

    // Filter tests
    std.debug.print("Applying filtering rules...\n", .{});
    var filtered_tests: std.ArrayList([]const u8) = .{};
    defer filtered_tests.deinit(allocator);

    for (test_files.items) |path| {
        if (try Filter.shouldIncludeTest(allocator, path)) {
            try filtered_tests.append(allocator, path);
        }
    }
    std.debug.print("After filtering: {} tests to convert\n\n", .{filtered_tests.items.len});

    // Convert each test
    var converted: usize = 0;
    var failed: usize = 0;

    for (filtered_tests.items) |path| {
        std.debug.print("Converting: {s}...", .{path});

        if (convertTest(allocator, path)) {
            std.debug.print(" ✓\n", .{});
            converted += 1;
        } else |err| {
            std.debug.print(" ✗ ({s})\n", .{@errorName(err)});
            failed += 1;
        }
    }

    // Summary
    std.debug.print("\n========================\n", .{});
    std.debug.print("Conversion complete!\n", .{});
    std.debug.print("  Converted: {}\n", .{converted});
    std.debug.print("  Failed: {}\n", .{failed});
    std.debug.print("  Output: {s}/\n", .{OUTPUT_DIR});
}

fn ensureOutputDir() !void {
    const cwd = fs.cwd();
    cwd.makePath(OUTPUT_DIR) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };
}

fn scanForTests(allocator: mem.Allocator, test_files: *std.ArrayList([]const u8)) !void {
    var dir = try fs.openDirAbsolute(WPT_SOURCE_DIR, .{ .iterate = true });
    defer dir.close();

    try scanDirRecursive(allocator, dir, "", test_files);
}

fn scanDirRecursive(
    allocator: mem.Allocator,
    dir: fs.Dir,
    rel_path: []const u8,
    test_files: *std.ArrayList([]const u8),
) !void {
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        const full_path = if (rel_path.len > 0)
            try std.fmt.allocPrint(allocator, "{s}/{s}", .{ rel_path, entry.name })
        else
            try allocator.dupe(u8, entry.name);
        defer allocator.free(full_path);

        switch (entry.kind) {
            .directory => {
                // Skip certain directories
                if (mem.eql(u8, entry.name, "resources") or
                    mem.eql(u8, entry.name, "support") or
                    mem.eql(u8, entry.name, "crashtests"))
                {
                    continue;
                }

                var sub_dir = try dir.openDir(entry.name, .{ .iterate = true });
                defer sub_dir.close();
                try scanDirRecursive(allocator, sub_dir, full_path, test_files);
            },
            .file => {
                if (mem.endsWith(u8, entry.name, ".html")) {
                    // Duplicate for storage (full_path will be freed by defer)
                    const owned_path = try allocator.dupe(u8, full_path);
                    try test_files.append(allocator, owned_path);
                }
            },
            else => {},
        }
    }
}

fn convertTest(allocator: mem.Allocator, rel_path: []const u8) !void {
    const full_source_path = try std.fmt.allocPrint(
        allocator,
        "{s}/{s}",
        .{ WPT_SOURCE_DIR, rel_path },
    );
    defer allocator.free(full_source_path);

    // Parse HTML file
    const parsed = try HtmlParser.parseHtmlFile(allocator, full_source_path);
    defer parsed.deinit();

    // Convert paths
    const depth = countPathDepth(rel_path);
    var converted_scripts: std.ArrayList([]const u8) = .{};
    defer {
        for (converted_scripts.items) |script| {
            allocator.free(script);
        }
        converted_scripts.deinit(allocator);
    }

    for (parsed.scripts.items) |script| {
        const converted = try PathConverter.convertPaths(allocator, script, depth);
        try converted_scripts.append(allocator, converted);
    }

    // Generate output JavaScript
    const output_js = try generateOutputJs(allocator, parsed, converted_scripts.items);
    defer allocator.free(output_js);

    // Write output file
    const output_path = try getOutputPath(allocator, rel_path);
    defer allocator.free(output_path);

    try FileWriter.writeTestFile(output_path, output_js);
}

fn countPathDepth(path: []const u8) usize {
    var depth: usize = 0;
    for (path) |c| {
        if (c == '/') depth += 1;
    }
    return depth;
}

fn getOutputPath(allocator: mem.Allocator, rel_path: []const u8) ![]const u8 {
    // Change .html to .test.js
    const without_ext = if (mem.endsWith(u8, rel_path, ".html"))
        rel_path[0 .. rel_path.len - 5]
    else
        rel_path;

    return try std.fmt.allocPrint(
        allocator,
        "{s}/{s}.test.js",
        .{ OUTPUT_DIR, without_ext },
    );
}

fn generateOutputJs(
    allocator: mem.Allocator,
    parsed: HtmlParser.ParsedHtml,
    scripts: []const []const u8,
) ![]const u8 {
    var output: std.ArrayList(u8) = .{};
    errdefer output.deinit(allocator);
    const writer = output.writer(allocator);

    // Header comment
    try writer.writeAll("// Converted from WPT HTML test\n");
    try writer.writeAll("// Original: ");
    try writer.writeAll(parsed.source_path);
    try writer.writeAll("\n\n");

    // Convert HTML structure if present
    if (parsed.html_structure.len > 0) {
        try writer.writeAll("// Setup HTML structure\n");
        try writer.writeAll("document.body.innerHTML = ");
        try writeEscapedString(writer, parsed.html_structure);
        try writer.writeAll(";\n\n");
    }

    // Add scripts
    for (scripts) |script| {
        try writer.writeAll(script);
        try writer.writeAll("\n\n");
    }

    return output.toOwnedSlice(allocator);
}

fn writeEscapedString(writer: anytype, str: []const u8) !void {
    try writer.writeByte('`');
    for (str) |c| {
        switch (c) {
            '`' => try writer.writeAll("\\`"),
            '\\' => try writer.writeAll("\\\\"),
            '$' => try writer.writeAll("\\$"),
            else => try writer.writeByte(c),
        }
    }
    try writer.writeByte('`');
}
