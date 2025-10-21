//! WebIDL Parser for Zig
//!
//! A standalone WebIDL parsing library with zero dependencies.
//!
//! ## Usage
//!
//! ```zig
//! const webidl = @import("webidl-parser");
//!
//! var parser = webidl.Parser.init(allocator, source);
//! var doc = try parser.parse();
//! defer doc.deinit();
//!
//! if (doc.getInterface("Element")) |interface| {
//!     // Use the interface AST
//! }
//! ```

const std = @import("std");

// Export public API
pub const Document = @import("ast.zig").Document;
pub const Interface = @import("ast.zig").Interface;
pub const Method = @import("ast.zig").Method;
pub const Attribute = @import("ast.zig").Attribute;
pub const Parameter = @import("ast.zig").Parameter;
pub const Type = @import("ast.zig").Type;

pub const Parser = @import("parser.zig").Parser;

// Version
pub const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

test "webidl-parser" {
    // Run all tests
    std.testing.refAllDecls(@This());
}
