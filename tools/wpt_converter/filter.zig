//! Filter WPT tests to exclude rendering/layout tests

const std = @import("std");
const mem = std.mem;
const fs = std.fs;

/// Directories to exclude entirely
const EXCLUDED_DIRS = [_][]const u8{
    "parts", // Declarative DOM parts (rendering)
    "observable", // Experimental Observable API
    "crashtests", // Crash tests
    "tentative", // May be experimental/unstable
};

/// Directories to include
const INCLUDED_DIRS = [_][]const u8{
    "nodes",
    "traversal",
    "abort",
    "collections",
    "lists",
    "ranges",
    "events",
};

/// Layout/rendering properties to detect
const LAYOUT_PROPERTIES = [_][]const u8{
    "offsetWidth",
    "offsetHeight",
    "offsetTop",
    "offsetLeft",
    "clientWidth",
    "clientHeight",
    "clientTop",
    "clientLeft",
    "scrollWidth",
    "scrollHeight",
    "scrollTop",
    "scrollLeft",
    "getBoundingClientRect",
    "getClientRects",
    "getComputedStyle",
};

/// Rendering/layout keywords in filenames
const LAYOUT_KEYWORDS = [_][]const u8{
    "rendering",
    "layout",
    "paint",
    "display",
    "visual",
};

pub fn shouldIncludeTest(allocator: mem.Allocator, rel_path: []const u8) !bool {
    // Check if path contains excluded directories
    for (EXCLUDED_DIRS) |excluded| {
        if (containsPathSegment(rel_path, excluded)) {
            return false;
        }
    }

    // Check if path is in an included directory or is a root-level test
    const is_root_level = mem.indexOf(u8, rel_path, "/") == null;
    var in_included_dir = is_root_level;

    if (!is_root_level) {
        for (INCLUDED_DIRS) |included| {
            if (startsWithPathSegment(rel_path, included)) {
                in_included_dir = true;
                break;
            }
        }
    }

    if (!in_included_dir) {
        return false; // Not in any included directory and not root-level
    }

    // Check filename for layout keywords
    const filename = getFilename(rel_path);
    for (LAYOUT_KEYWORDS) |keyword| {
        if (mem.indexOf(u8, filename, keyword) != null) {
            return false;
        }
    }

    // Read file and check content
    const full_path = try std.fmt.allocPrint(
        allocator,
        "/Users/bcardarella/projects/wpt/dom/{s}",
        .{rel_path},
    );
    defer allocator.free(full_path);

    const content = fs.cwd().readFileAlloc(allocator, full_path, 10 * 1024 * 1024) catch |err| {
        std.debug.print("Warning: Could not read {s}: {s}\n", .{ full_path, @errorName(err) });
        return false;
    };
    defer allocator.free(content);

    // Check for CSS/stylesheet references
    if (mem.indexOf(u8, content, "stylesheet") != null or
        mem.indexOf(u8, content, ".css") != null or
        mem.indexOf(u8, content, "style=") != null)
    {
        return false;
    }

    // Check for layout/rendering properties
    for (LAYOUT_PROPERTIES) |prop| {
        if (mem.indexOf(u8, content, prop) != null) {
            return false;
        }
    }

    return true;
}

fn containsPathSegment(path: []const u8, segment: []const u8) bool {
    var iter = mem.splitScalar(u8, path, '/');
    while (iter.next()) |part| {
        if (mem.eql(u8, part, segment)) {
            return true;
        }
    }
    return false;
}

fn startsWithPathSegment(path: []const u8, segment: []const u8) bool {
    if (path.len < segment.len) return false;
    if (!mem.startsWith(u8, path, segment)) return false;
    if (path.len == segment.len) return true;
    return path[segment.len] == '/';
}

fn getFilename(path: []const u8) []const u8 {
    if (mem.lastIndexOf(u8, path, "/")) |idx| {
        return path[idx + 1 ..];
    }
    return path;
}
