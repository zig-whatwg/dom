//! WebIDL to Zig Code Generator - Main CLI
//!
//! Usage:
//!   zig run tools/codegen/main.zig -- [interface_name]
//!   zig run tools/codegen/main.zig -- [interface_name] --from-source [parent_source] [parent_struct]
//!
//! Examples:
//!   # WebIDL-based generation (old approach)
//!   zig run tools/codegen/main.zig -- Element
//!   zig run tools/codegen/main.zig -- all
//!
//!   # Source-based generation (RECOMMENDED)
//!   zig run tools/codegen/main.zig -- Element --from-source src/node.zig Node
//!   zig run tools/codegen/main.zig -- Document --from-source src/node.zig Node

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

    // Check for --from-source flag (RECOMMENDED approach)
    if (args.len >= 5 and std.mem.eql(u8, args[2], "--from-source")) {
        const parent_source = args[3];
        const parent_struct = args[4];
        try generateFromSource(interface_name, parent_source, parent_struct, allocator);
        return;
    }

    // WebIDL-based generation (old approach)
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

    try gen.generate(interface, doc);

    const output = gen.getOutput();

    // Output generated code
    std.debug.print("{s}\n", .{output});

    std.debug.print("\n✓ Generated successfully!\n", .{});
}

/// Generate delegation code from Zig source file (RECOMMENDED)
fn generateFromSource(
    interface_name: []const u8,
    parent_source: []const u8,
    parent_struct: []const u8,
    allocator: std.mem.Allocator,
) !void {
    std.debug.print("\n🔧 Source-Based Code Generation\n", .{});
    std.debug.print("Interface: {s}\n", .{interface_name});
    std.debug.print("Parent: {s} from {s}\n\n", .{ parent_struct, parent_source });

    // Generate code
    var gen = generator.Generator.init(allocator);
    defer gen.deinit();

    try gen.generateFromSource(interface_name, parent_source, parent_struct);

    const output = gen.getOutput();

    // Output generated code
    std.debug.print("{s}\n", .{output});

    std.debug.print("\n✓ Generated successfully!\n", .{});

    // Create lowercase version of interface name for tip
    const lower_name = try allocator.alloc(u8, interface_name.len);
    defer allocator.free(lower_name);
    _ = std.ascii.lowerString(lower_name, interface_name);

    std.debug.print("\n💡 Tip: Copy the generated code to src/{s}.zig\n", .{lower_name});
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
        \\Usage: 
        \\  zig run tools/codegen/main.zig -- [interface_name] [options]
        \\  zig build codegen -- [interface_name] [options]
        \\
        \\Source-Based Generation (RECOMMENDED):
        \\  --from-source [parent_source] [parent_struct]
        \\
        \\Examples:
        \\  # Source-based generation (RECOMMENDED)
        \\  zig build codegen -- Element --from-source src/node.zig Node
        \\  zig build codegen -- Document --from-source src/node.zig Node
        \\  zig build codegen -- Text --from-source src/character_data.zig CharacterData
        \\
        \\  # WebIDL-based generation (old approach)
        \\  zig build codegen -- Element
        \\  zig build codegen -- Document
        \\  zig build codegen -- all
        \\
        \\This generates Zig delegation methods for the specified interface
        \\from the WebIDL definitions in skills/whatwg_compliance/dom.idl.
        \\
    , .{});
}
