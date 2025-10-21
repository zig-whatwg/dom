//! analyze.zig - Analyze source files and update overrides.json
//!
//! Usage: zig run tools/codegen/analyze.zig -- InterfaceName
//!
//! This tool:
//! 1. Reads WebIDL for the interface
//! 2. Finds what methods WOULD be generated
//! 3. Checks if those methods exist in the source file
//! 4. Determines if they're simple delegation or custom implementation
//! 5. Updates overrides.json automatically

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} InterfaceName\n", .{args[0]});
        std.debug.print("Example: {s} Node\n", .{args[0]});
        return error.MissingArgument;
    }

    const interface_name = args[1];

    std.debug.print("Analyzing {s}...\n", .{interface_name});

    // Convert to lowercase for file path
    const lower_name = try std.ascii.allocLowerString(allocator, interface_name);
    defer allocator.free(lower_name);

    // Special case mappings
    const file_name = if (std.mem.eql(u8, lower_name, "eventtarget"))
        "event_target"
    else
        lower_name;

    const source_path = try std.fmt.allocPrint(allocator, "src/{s}.zig", .{file_name});
    defer allocator.free(source_path);

    // Read source file
    const source = std.fs.cwd().readFileAlloc(allocator, source_path, 10 * 1024 * 1024) catch |err| {
        std.debug.print("Error reading {s}: {}\n", .{ source_path, err });
        return err;
    };
    defer allocator.free(source);

    std.debug.print("✓ Loaded {s} ({} bytes)\n", .{ source_path, source.len });

    // Analyze methods that would be generated from ancestors
    // For now, hardcode EventTarget methods as example
    if (std.mem.eql(u8, interface_name, "Node")) {
        try analyzeNodeMethods(allocator, source);
    } else {
        std.debug.print("TODO: Implement analysis for {s}\n", .{interface_name});
    }
}

fn analyzeNodeMethods(allocator: std.mem.Allocator, source: []const u8) !void {
    const methods = [_][]const u8{
        "addEventListener",
        "removeEventListener",
        "dispatchEvent",
    };

    std.debug.print("\nAnalyzing EventTarget methods in Node:\n", .{});
    std.debug.print("=" ** 60 ++ "\n", .{});

    for (methods) |method_name| {
        const analysis = try analyzeMethod(allocator, source, method_name);

        std.debug.print("\n{s}():\n", .{method_name});
        std.debug.print("  Status: {s}\n", .{@tagName(analysis.status)});

        if (analysis.line_start) |line| {
            std.debug.print("  Location: lines {d}-{d}\n", .{ line, analysis.line_end.? });
        }

        switch (analysis.status) {
            .not_found => {
                std.debug.print("  Action: ✅ Will be generated\n", .{});
            },
            .simple_delegation => {
                std.debug.print("  Action: 🗑️  Remove (old delegation pattern)\n", .{});
                std.debug.print("  Pattern: {s}\n", .{analysis.pattern.?});
            },
            .custom_implementation => {
                std.debug.print("  Action: 📝 Add to overrides.json\n", .{});
                std.debug.print("  Reason: Custom implementation ({d} lines)\n", .{analysis.body_lines.?});
            },
        }
    }

    std.debug.print("\n" ++ "=" ** 60 ++ "\n", .{});
}

const AnalysisStatus = enum {
    not_found,
    simple_delegation,
    custom_implementation,
};

const AnalysisResult = struct {
    status: AnalysisStatus,
    line_start: ?usize = null,
    line_end: ?usize = null,
    body_lines: ?usize = null,
    pattern: ?[]const u8 = null, // What delegation pattern it uses
};

fn analyzeMethod(allocator: std.mem.Allocator, source: []const u8, method_name: []const u8) !AnalysisResult {
    // Search for method declaration
    const search_str = try std.fmt.allocPrint(allocator, "pub fn {s}(", .{method_name});
    defer allocator.free(search_str);

    const method_pos = std.mem.indexOf(u8, source, search_str) orelse {
        return AnalysisResult{ .status = .not_found };
    };

    // Found the method - now analyze it
    const line_start = getLineNumber(source, method_pos);

    // Find method body
    const body_start = std.mem.indexOfPos(u8, source, method_pos, "{") orelse {
        return AnalysisResult{ .status = .not_found };
    };

    const body_end = findMatchingBrace(source, body_start) orelse {
        return AnalysisResult{ .status = .not_found };
    };

    const line_end = getLineNumber(source, body_end);
    const method_body = source[body_start + 1 .. body_end];

    // Count non-empty lines
    var body_lines: usize = 0;
    var lines = std.mem.splitSequence(u8, method_body, "\n");
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
        if (trimmed.len > 0 and !std.mem.startsWith(u8, trimmed, "//")) {
            body_lines += 1;
        }
    }

    // Check for delegation patterns
    if (std.mem.indexOf(u8, method_body, "EventTargetMixin") != null) {
        return AnalysisResult{
            .status = .simple_delegation,
            .line_start = line_start,
            .line_end = line_end,
            .body_lines = body_lines,
            .pattern = "EventTargetMixin (old pattern)",
        };
    }

    if (std.mem.indexOf(u8, method_body, "self.prototype.") != null and body_lines <= 3) {
        return AnalysisResult{
            .status = .simple_delegation,
            .line_start = line_start,
            .line_end = line_end,
            .body_lines = body_lines,
            .pattern = "self.prototype (simple delegation)",
        };
    }

    // If it's more complex, it's a custom implementation
    return AnalysisResult{
        .status = .custom_implementation,
        .line_start = line_start,
        .line_end = line_end,
        .body_lines = body_lines,
    };
}

fn getLineNumber(source: []const u8, pos: usize) usize {
    var line: usize = 1;
    var i: usize = 0;

    while (i < pos and i < source.len) : (i += 1) {
        if (source[i] == '\n') {
            line += 1;
        }
    }

    return line;
}

fn findMatchingBrace(source: []const u8, start: usize) ?usize {
    var depth: i32 = 0;
    var i = start;

    while (i < source.len) : (i += 1) {
        if (source[i] == '{') {
            depth += 1;
        } else if (source[i] == '}') {
            depth -= 1;
            if (depth == 0) {
                return i;
            }
        }
    }

    return null;
}
