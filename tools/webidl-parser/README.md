# WebIDL Parser for Zig

A standalone WebIDL parser library written in Zig.

## Overview

This is a pure Zig implementation of a WebIDL parser that can parse WHATWG Web IDL files and produce an Abstract Syntax Tree (AST).

**Design Goal**: Zero dependencies, reusable library that can be extracted into its own package.

## Features

- ✅ Parse WebIDL interfaces and inheritance
- ✅ Extract methods, attributes, and their signatures
- ✅ Handle WebIDL types (nullable, sequences, etc.)
- ✅ Parse parameters (optional, variadic)
- ✅ Build inheritance chains
- ✅ Zero dependencies (only `std`)
- ✅ Allocator-agnostic design

## Non-Goals

This parser is focused on the subset of WebIDL needed for DOM implementation:
- ❌ No callback interfaces (not needed for DOM)
- ❌ No dictionaries parsing (can be added later)
- ❌ No enums (not needed for core DOM)
- ❌ No full WebIDL validation (just parsing)

## Usage

```zig
const std = @import("std");
const webidl = @import("webidl-parser");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Read WebIDL source
    const source = try std.fs.cwd().readFileAlloc(allocator, "dom.idl", 10_000_000);
    defer allocator.free(source);
    
    // Parse
    var parser = webidl.Parser.init(allocator, source);
    var doc = try parser.parse();
    defer doc.deinit();
    
    // Use the AST
    if (doc.getInterface("Element")) |interface| {
        std.debug.print("Interface: {s}\n", .{interface.name});
        std.debug.print("Parent: {s}\n", .{interface.parent orelse "none"});
        std.debug.print("Methods: {d}\n", .{interface.methods.len});
        std.debug.print("Attributes: {d}\n", .{interface.attributes.len});
        
        // Get inheritance chain
        const ancestors = try interface.getAncestors(doc.interfaces, allocator);
        defer allocator.free(ancestors);
        
        std.debug.print("Ancestors: ", .{});
        for (ancestors) |ancestor| {
            std.debug.print("{s} ", .{ancestor});
        }
        std.debug.print("\n", .{});
    }
}
```

## API Reference

### Core Types

#### `Document`
Represents a parsed WebIDL document containing multiple interfaces.

```zig
pub const Document = struct {
    interfaces: std.StringHashMap(Interface),
    allocator: Allocator,
    
    pub fn init(allocator: Allocator) Document;
    pub fn deinit(self: *Document) void;
    pub fn getInterface(self: *Document, name: []const u8) ?Interface;
    pub fn addInterface(self: *Document, interface: Interface) !void;
};
```

#### `Interface`
Represents a WebIDL interface with its methods and attributes.

```zig
pub const Interface = struct {
    name: []const u8,
    parent: ?[]const u8,
    methods: []Method,
    attributes: []Attribute,
    
    pub fn getAncestors(
        self: Interface,
        interfaces: std.StringHashMap(Interface),
        allocator: Allocator
    ) ![][]const u8;
    
    pub fn inheritanceDepth(
        self: Interface,
        interfaces: std.StringHashMap(Interface)
    ) usize;
};
```

#### `Method`
Represents a WebIDL operation/method.

```zig
pub const Method = struct {
    name: []const u8,
    return_type: Type,
    parameters: []Parameter,
    is_static: bool = false,
};
```

#### `Attribute`
Represents a WebIDL attribute.

```zig
pub const Attribute = struct {
    name: []const u8,
    type: Type,
    readonly: bool = false,
};
```

#### `Type`
Represents a WebIDL type.

```zig
pub const Type = struct {
    name: []const u8,
    nullable: bool = false,
    is_sequence: bool = false,
    is_promise: bool = false,
    
    pub fn fromString(allocator: Allocator, type_str: []const u8) !Type;
};
```

#### `Parameter`
Represents a method parameter.

```zig
pub const Parameter = struct {
    name: []const u8,
    type: Type,
    optional: bool = false,
    variadic: bool = false,
};
```

### Parser

```zig
pub const Parser = struct {
    pub fn init(allocator: Allocator, source: []const u8) Parser;
    pub fn parse(self: *Parser) !Document;
};
```

## Architecture

```
┌─────────────────────────────────────────────┐
│           WebIDL Parser Library             │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────┐      ┌─────────────┐     │
│  │   Parser    │─────>│     AST     │     │
│  │  (Lexer +   │      │   (Types)   │     │
│  │   Parser)   │      │             │     │
│  └─────────────┘      └─────────────┘     │
│                                             │
│  Input: WebIDL text                        │
│  Output: AST (Document, Interface, etc)    │
│                                             │
└─────────────────────────────────────────────┘
```

## Files

```
tools/webidl-parser/
├── README.md           # This file
├── ast.zig            # AST types (pure data structures)
├── parser.zig         # Parser implementation
└── root.zig           # Library entry point (exports API)
```

## Design Principles

### 1. Zero Dependencies
- Only depends on `std` library
- No external packages required
- Easy to vendor or extract

### 2. Allocator-Agnostic
- Caller provides allocator
- No hidden allocations
- Memory management is explicit

### 3. Pure Zig
- No C dependencies
- No build-time code generation
- Standard Zig idioms

### 4. Focused Scope
- Parses what's needed for DOM
- Doesn't parse entire WebIDL spec
- Can be extended later if needed

### 5. Reusable
- Clean API surface
- Well-documented
- Can be extracted to standalone repo

## Extraction Plan

To extract into standalone library:

1. Copy `tools/webidl-parser/` to new repo
2. Add `build.zig`:
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Library
    const lib = b.addStaticLibrary(.{
        .name = "webidl-parser",
        .root_source_file = b.path("root.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // Tests
    const tests = b.addTest(.{
        .root_source_file = b.path("root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
```

3. Add `build.zig.zon`:
```zig
.{
    .name = "webidl-parser",
    .version = "0.1.0",
    .dependencies = .{},
}
```

4. Publish to GitHub
5. Use in dom library via Zig package manager:
```zig
// build.zig.zon in dom library
.dependencies = .{
    .webidl = .{
        .url = "https://github.com/you/webidl-parser/archive/v0.1.0.tar.gz",
        .hash = "...",
    },
},
```

## Testing

```bash
# Run tests (once implemented)
zig build test

# Test on real WebIDL file
zig run example.zig -- path/to/dom.idl
```

## Future Enhancements

These can be added without breaking existing API:

- [ ] Extended attributes parsing (`[NewObject]`, etc.)
- [ ] Dictionary types
- [ ] Callback interfaces
- [ ] Enum types
- [ ] Union types
- [ ] Better error messages with line/column info
- [ ] Incremental parsing
- [ ] Pretty-printing (AST → WebIDL)

## License

Same as parent project (will be extracted).

## Contributing

This is designed to be extracted into a standalone library. Keep it:
- Dependency-free (only `std`)
- Well-documented
- Focused on WebIDL → AST parsing
- Separate from code generation concerns
