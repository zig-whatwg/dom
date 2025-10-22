//! Path Converter - Convert absolute WPT paths to relative paths

const std = @import("std");
const mem = std.mem;

pub fn convertPaths(allocator: mem.Allocator, script: []const u8, depth: usize) ![]const u8 {
    var output: std.ArrayList(u8) = .{};
    errdefer output.deinit(allocator);
    const writer = output.writer(allocator);

    var pos: usize = 0;
    while (pos < script.len) {
        // Look for load/import statements with absolute paths
        if (findPathReference(script, pos)) |ref| {
            // Write everything before the path
            try writer.writeAll(script[pos..ref.start]);

            // Convert and write the path
            const converted_path = try convertAbsolutePath(allocator, ref.path, depth);
            defer allocator.free(converted_path);
            try writer.writeAll(converted_path);

            pos = ref.end;
        } else {
            // No more path references, write the rest
            try writer.writeAll(script[pos..]);
            break;
        }
    }

    return output.toOwnedSlice(allocator);
}

const PathReference = struct {
    start: usize,
    end: usize,
    path: []const u8,
};

fn findPathReference(script: []const u8, start_pos: usize) ?PathReference {
    // Look for common patterns:
    // - "/resources/testharness.js"
    // - src="/resources/..."
    // - load("/...")
    // - import "/..."

    var pos = start_pos;
    while (pos < script.len) {
        if (script[pos] == '/') {
            // Check if this looks like a path (preceded by quote or other path char)
            if (pos == 0) {
                pos += 1;
                continue;
            }

            const prev_char = script[pos - 1];
            if (prev_char == '"' or prev_char == '\'' or prev_char == '(') {
                // Found a potential path, extract it
                const path_start = pos;
                var path_end = pos + 1;

                // Find the end of the path (quote, paren, or whitespace)
                while (path_end < script.len) {
                    const c = script[path_end];
                    if (c == '"' or c == '\'' or c == ')' or c == ' ' or c == '\n' or c == '\r') {
                        break;
                    }
                    path_end += 1;
                }

                const path = script[path_start..path_end];

                // Only convert if it looks like a resource path
                if (mem.startsWith(u8, path, "/resources/") or
                    mem.startsWith(u8, path, "/common/") or
                    mem.startsWith(u8, path, "/dom/"))
                {
                    return PathReference{
                        .start = path_start,
                        .end = path_end,
                        .path = path,
                    };
                }
            }
        }
        pos += 1;
    }

    return null;
}

fn convertAbsolutePath(allocator: mem.Allocator, absolute_path: []const u8, depth: usize) ![]const u8 {
    // Convert /resources/testharness.js to ../../resources/testharness.js
    // depending on depth

    // Remove leading slash
    const path_without_slash = if (mem.startsWith(u8, absolute_path, "/"))
        absolute_path[1..]
    else
        absolute_path;

    // Build relative path with ../ based on depth
    var result: std.ArrayList(u8) = .{};
    errdefer result.deinit(allocator);

    // Add ../ for each level of depth
    var i: usize = 0;
    while (i < depth) : (i += 1) {
        try result.appendSlice(allocator, "../");
    }

    // Add the path
    try result.appendSlice(allocator, path_without_slash);

    return result.toOwnedSlice(allocator);
}

test "convertAbsolutePath" {
    const allocator = std.testing.allocator;

    // Depth 0 (root level)
    {
        const result = try convertAbsolutePath(allocator, "/resources/test.js", 0);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("resources/test.js", result);
    }

    // Depth 1 (one level deep)
    {
        const result = try convertAbsolutePath(allocator, "/resources/test.js", 1);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("../resources/test.js", result);
    }

    // Depth 2 (two levels deep)
    {
        const result = try convertAbsolutePath(allocator, "/resources/test.js", 2);
        defer allocator.free(result);
        try std.testing.expectEqualStrings("../../resources/test.js", result);
    }
}
