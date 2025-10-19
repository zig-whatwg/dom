//! Main Entry Point
//!
//! Simple executable entry point for the DOM library. Primarily used for library
//! verification and size reporting. The actual library API is exposed through root.zig.
//!
//! ## Usage
//!
//! Run the executable to verify library initialization and view struct sizes:
//! ```bash
//! zig build run
//! # Output:
//! # DOM library initialized.
//! # Node size: 96 bytes
//! # AbortSignal size: 48 bytes
//! # AbortController size: 24 bytes
//! ```
//!
//! ## Library API
//!
//! For library usage, import via root.zig:
//! ```zig
//! const dom = @import("dom");
//!
//! const doc = try dom.Document.init(allocator);
//! const elem = try doc.createElement("div");
//! ```

const std = @import("std");
const dom = @import("dom");

pub fn main() !void {
    std.debug.print("DOM library initialized.\n", .{});
    std.debug.print("Node size: {d} bytes\n", .{@sizeOf(dom.Node)});
    std.debug.print("AbortSignal size: {d} bytes\n", .{@sizeOf(dom.AbortSignal)});
    std.debug.print("AbortController size: {d} bytes\n", .{@sizeOf(dom.AbortController)});
}


