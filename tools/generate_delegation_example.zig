//! WebIDL to Zig Delegation Code Generator - Example

const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll(
        \\================================================================================
        \\WebIDL to Zig Delegation Code Generator
        \\================================================================================
        \\
        \\This tool would solve the code duplication problem by GENERATING delegation
        \\methods automatically from dom.idl.
        \\
        \\GENERATED OUTPUT EXAMPLE for Element:
        \\
    );
}
