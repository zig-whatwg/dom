//! Source Code Analyzer
//!
//! Analyzes existing Zig source files to detect:
//! 1. Methods that would be generated (check WebIDL)
//! 2. Methods already implemented in source
//! 3. Whether implementation is delegation or custom logic
//! 4. Automatically update overrides.json

const std = @import("std");
const Allocator = std.mem.Allocator;
const webidl = @import("webidl-parser");

/// Result of analyzing a method implementation
pub const MethodAnalysis = enum {
    not_found, // Method doesn't exist in source
    simple_delegate, // Method just delegates (can be removed/replaced)
    custom_impl, // Method has custom logic (add to overrides)
};

/// Analysis result for a single method
pub const MethodInfo = struct {
    name: []const u8,
    analysis: MethodAnalysis,
    line_start: ?usize = null,
    line_end: ?usize = null,
    reason: ?[]const u8 = null, // Why it's a custom implementation
};

/// Analyzer for source files
pub const Analyzer = struct {
    allocator: Allocator,

    pub fn init(allocator: Allocator) Analyzer {
        return .{ .allocator = allocator };
    }

    /// Analyze a source file for an interface
    pub fn analyzeInterface(
        _: *Analyzer,
        interface: webidl.Interface,
        source_path: []const u8,
    ) !std.ArrayList(MethodInfo) {
        _ = interface;
        _ = source_path;
        const results = std.ArrayList(MethodInfo){};

        // TODO: Get all methods that would be generated (from ancestors)
        // TODO: For each ancestor method, check if it exists in source

        return results;
    }

    /// Check if a method exists in source and analyze its implementation
    fn analyzeMethod(
        self: *Analyzer,
        source: []const u8,
        method_name: []const u8,
    ) !MethodInfo {

        // Find method declaration
        const search_str = try std.fmt.allocPrint(self.allocator, "pub fn {s}(", .{method_name});
        defer self.allocator.free(search_str);

        if (std.mem.indexOf(u8, source, search_str)) |start_pos| {
            // Method exists - now determine if it's delegation or custom

            // Find the method body (between { and })
            const body_start = std.mem.indexOfPos(u8, source, start_pos, "{") orelse return .{
                .name = method_name,
                .analysis = .not_found,
            };

            const body_end = self.findMatchingBrace(source, body_start) orelse return .{
                .name = method_name,
                .analysis = .not_found,
            };

            const method_body = source[body_start..body_end];

            // Analyze body to determine if it's delegation or custom
            const is_delegate = self.isSimpleDelegation(method_body);

            return .{
                .name = method_name,
                .analysis = if (is_delegate) .simple_delegate else .custom_impl,
                .line_start = self.getLineNumber(source, start_pos),
                .line_end = self.getLineNumber(source, body_end),
            };
        }

        return .{
            .name = method_name,
            .analysis = .not_found,
        };
    }

    /// Check if method body is simple delegation
    fn isSimpleDelegation(_: *Analyzer, body: []const u8) bool {

        // Simple heuristics for delegation:
        // 1. Contains "return" and "self.prototype."
        // 2. OR contains "Mixin" (old pattern)
        // 3. Very short (< 5 lines of actual code)

        const has_prototype_call = std.mem.indexOf(u8, body, "self.prototype.") != null;
        const has_mixin_call = std.mem.indexOf(u8, body, "Mixin") != null;

        // Count non-empty, non-comment lines
        var line_count: usize = 0;
        var lines = std.mem.split(u8, body, "\n");
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);
            if (trimmed.len > 0 and !std.mem.startsWith(u8, trimmed, "//")) {
                line_count += 1;
            }
        }

        // Simple delegation typically:
        // - Calls prototype or mixin
        // - Has very few lines (< 5)
        if (has_prototype_call or has_mixin_call) {
            if (line_count <= 5) {
                return true;
            }
        }

        return false;
    }

    /// Find matching closing brace
    fn findMatchingBrace(_: *Analyzer, source: []const u8, start: usize) ?usize {
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

    /// Get line number for a byte position
    fn getLineNumber(_: *Analyzer, source: []const u8, pos: usize) usize {
        var line: usize = 1;
        var i: usize = 0;

        while (i < pos and i < source.len) : (i += 1) {
            if (source[i] == '\n') {
                line += 1;
            }
        }

        return line;
    }
};

/// Override registry entry
pub const Override = struct {
    reason: []const u8,
    file: []const u8,
    date: []const u8,
};

/// Load overrides from JSON file
pub fn loadOverrides(allocator: Allocator, path: []const u8) !std.StringHashMap(std.StringHashMap(Override)) {
    _ = path;

    // TODO: Implement JSON parsing
    // For now, return empty map
    const overrides = std.StringHashMap(std.StringHashMap(Override)).init(allocator);
    return overrides;
}

/// Save overrides to JSON file
pub fn saveOverrides(
    allocator: Allocator,
    overrides: std.StringHashMap(std.StringHashMap(Override)),
    path: []const u8,
) !void {
    _ = allocator;
    _ = overrides;
    _ = path;

    // TODO: Implement JSON serialization
}
