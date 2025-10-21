//! WebIDL to Zig Code Generator - Main CLI
//!
//! Usage:
//!   zig run tools/codegen/main.zig -- [interface_name]
//!
//! Examples:
//!   zig run tools/codegen/main.zig -- Element
//!   zig run tools/codegen/main.zig -- all

const std = @import("std");

// Import standalone WebIDL parser library
const webidl = @import("webidl-parser");

// Import code generator
const generator = @import("generator.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try printUsage();
        return;
    }

    const interface_name = args[1];

    // Read dom.idl
    const idl_path = "skills/whatwg_compliance/dom.idl";
    const idl_source = try std.fs.cwd().readFileAlloc(allocator, idl_path, 10 * 1024 * 1024);
    defer allocator.free(idl_source);

    // Parse WebIDL using standalone parser
    std.debug.print("Parsing {s}...\n", .{idl_path});
    var p = webidl.Parser.init(allocator, idl_source);
    var doc = try p.parse();
    defer doc.deinit();

    std.debug.print("Found {} interfaces\n", .{doc.interfaces.count()});

    if (std.mem.eql(u8, interface_name, "all")) {
        // Generate for all interfaces
        try generateAll(&doc, allocator);
    } else {
        // Generate for specific interface
        try generateInterface(interface_name, &doc, allocator);
    }
}

fn generateInterface(name: []const u8, doc: *webidl.Document, allocator: std.mem.Allocator) !void {
    const interface = doc.getInterface(name) orelse {
        std.debug.print("Interface '{s}' not found\n", .{name});
        return error.InterfaceNotFound;
    };

    std.debug.print("\nGenerating delegation for {s}...\n", .{name});

    // Get ancestors
    const ancestors = try interface.getAncestors(doc.interfaces, allocator);
    defer allocator.free(ancestors);

    if (ancestors.len == 0) {
        std.debug.print("  No ancestors - no delegation needed\n", .{});
        return;
    }

    std.debug.print("  Inheritance chain: {s}", .{name});
    for (ancestors) |ancestor| {
        std.debug.print(" : {s}", .{ancestor});
    }
    std.debug.print("\n", .{});

    // Count methods to generate
    var method_count: usize = 0;
    for (ancestors) |ancestor_name| {
        if (doc.getInterface(ancestor_name)) |ancestor| {
            method_count += ancestor.methods.len + ancestor.attributes.len;
        }
    }

    std.debug.print("  Generating {d} delegation methods...\n", .{method_count});

    // Generate code
    var gen = generator.Generator.init(allocator);
    defer gen.deinit();

    // Load overrides from overrides.json
    try gen.loadOverrides();

    try gen.generate(interface, doc);

    const output = gen.getOutput();

    // Output generated code
    std.debug.print("{s}\n", .{output});

    std.debug.print("\n✓ Generated successfully!\n", .{});
}

fn generateAll(doc: *webidl.Document, allocator: std.mem.Allocator) !void {
    std.debug.print("\nGenerating delegation for all interfaces...\n\n", .{});

    var iter = doc.interfaces.iterator();
    while (iter.next()) |entry| {
        const interface = entry.value_ptr.*;

        // Skip interfaces without parents
        if (interface.parent == null) continue;

        try generateInterface(interface.name, doc, allocator);
        std.debug.print("\n", .{});
    }
}

fn printUsage() !void {
    std.debug.print(
        \\Usage: zig run tools/codegen/main.zig -- [interface_name | all]
        \\
        \\Examples:
        \\  zig run tools/codegen/main.zig -- Element
        \\  zig run tools/codegen/main.zig -- Document
        \\  zig run tools/codegen/main.zig -- all
        \\
        \\This generates Zig delegation methods for the specified interface
        \\from the WebIDL definitions in skills/whatwg_compliance/dom.idl.
        \\
    , .{});
}
