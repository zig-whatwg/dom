//! HTML Parser for WPT Test Files
//!
//! Extracts JavaScript content and HTML structure from WPT HTML test files.

const std = @import("std");
const mem = std.mem;
const fs = std.fs;

pub const ParsedHtml = struct {
    source_path: []const u8,
    html_structure: []const u8,
    scripts: std.ArrayList([]const u8),
    dependencies: std.ArrayList([]const u8),
    allocator: mem.Allocator,

    pub fn deinit(self: ParsedHtml) void {
        self.allocator.free(self.source_path);
        self.allocator.free(self.html_structure);
        for (self.scripts.items) |script| {
            self.allocator.free(script);
        }
        var scripts = self.scripts;
        scripts.deinit(self.allocator);
        for (self.dependencies.items) |dep| {
            self.allocator.free(dep);
        }
        var dependencies = self.dependencies;
        dependencies.deinit(self.allocator);
    }
};

pub fn parseHtmlFile(allocator: mem.Allocator, file_path: []const u8) !ParsedHtml {
    const content = try fs.cwd().readFileAlloc(allocator, file_path, 10 * 1024 * 1024);
    defer allocator.free(content);

    var parsed = ParsedHtml{
        .source_path = try allocator.dupe(u8, file_path),
        .html_structure = try extractHtmlStructure(allocator, content),
        .scripts = .{},
        .dependencies = .{},
        .allocator = allocator,
    };

    try extractScripts(allocator, content, &parsed.scripts, &parsed.dependencies);

    return parsed;
}

fn extractHtmlStructure(allocator: mem.Allocator, content: []const u8) ![]const u8 {
    // Find body content between <body> and </body>
    const body_start_tag = "<body";
    const body_end_tag = "</body>";

    const body_start_idx = mem.indexOf(u8, content, body_start_tag) orelse {
        // No body tag, return empty
        return try allocator.dupe(u8, "");
    };

    // Find the end of the opening <body> tag (could be <body> or <body class="...">)
    const after_body_tag = mem.indexOfPos(u8, content, body_start_idx, ">") orelse {
        return try allocator.dupe(u8, "");
    };
    const body_content_start = after_body_tag + 1;

    const body_content_end = mem.indexOf(u8, content[body_content_start..], body_end_tag) orelse {
        // No closing body tag, take until end
        return try allocator.dupe(u8, content[body_content_start..]);
    };

    const body_content = content[body_content_start .. body_content_start + body_content_end];

    // Remove script tags from body content
    var cleaned: std.ArrayList(u8) = .{};
    defer cleaned.deinit(allocator);

    var pos: usize = 0;
    while (pos < body_content.len) {
        if (mem.startsWith(u8, body_content[pos..], "<script")) {
            // Skip until </script>
            if (mem.indexOfPos(u8, body_content, pos, "</script>")) |end_idx| {
                pos = end_idx + "</script>".len;
                continue;
            } else {
                // Unclosed script tag, skip to end
                break;
            }
        }
        try cleaned.append(allocator, body_content[pos]);
        pos += 1;
    }

    return try cleaned.toOwnedSlice(allocator);
}

fn extractScripts(
    allocator: mem.Allocator,
    content: []const u8,
    scripts: *std.ArrayList([]const u8),
    dependencies: *std.ArrayList([]const u8),
) !void {
    var pos: usize = 0;

    while (pos < content.len) {
        const script_start = mem.indexOfPos(u8, content, pos, "<script") orelse break;
        const script_tag_end = mem.indexOfPos(u8, content, script_start, ">") orelse break;
        const script_tag = content[script_start .. script_tag_end + 1];

        // Check if it's an external script (<script src="...">)
        if (mem.indexOf(u8, script_tag, "src=")) |src_idx_rel| {
            const src_idx = script_start + src_idx_rel + 4; // Skip "src="
            const quote_char = content[src_idx];
            if (quote_char == '"' or quote_char == '\'') {
                const src_value_start = src_idx + 1;
                const src_value_end = mem.indexOfScalarPos(u8, content, src_value_start, quote_char) orelse {
                    pos = script_tag_end + 1;
                    continue;
                };
                const src_value = content[src_value_start..src_value_end];
                try dependencies.append(allocator, try allocator.dupe(u8, src_value));
            }
            pos = script_tag_end + 1;
            continue;
        }

        // It's an inline script, extract content
        const script_content_start = script_tag_end + 1;
        const script_end = mem.indexOfPos(u8, content, script_content_start, "</script>") orelse {
            pos = script_tag_end + 1;
            continue;
        };

        const script_content = content[script_content_start..script_end];

        // Trim whitespace and skip empty scripts
        const trimmed = mem.trim(u8, script_content, &std.ascii.whitespace);
        if (trimmed.len > 0) {
            try scripts.append(allocator, try allocator.dupe(u8, trimmed));
        }

        pos = script_end + "</script>".len;
    }
}
