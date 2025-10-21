# Tools Architecture

This directory contains two separate but related tools:

## 1. WebIDL Parser (`webidl-parser/`)

**Purpose**: Standalone, reusable WebIDL parsing library

**Designed for extraction**: This is intentionally isolated with zero dependencies beyond `std`, ready to be extracted into its own package.

```
tools/webidl-parser/
├── README.md          # Complete library documentation
├── root.zig           # Public API exports
├── ast.zig            # AST data structures
├── parser.zig         # WebIDL parser implementation
├── build.zig          # Standalone build (for when extracted)
└── .gitignore         # Ignore build artifacts
```

**Key Design Principles:**
- ✅ Zero dependencies (only `std`)
- ✅ Allocator-agnostic
- ✅ Pure Zig, no C dependencies
- ✅ Focused scope (DOM subset of WebIDL)
- ✅ Clean API surface
- ✅ Can be extracted to separate repo anytime

**API:**
```zig
const webidl = @import("webidl-parser");

var parser = webidl.Parser.init(allocator, source);
var doc = try parser.parse();
defer doc.deinit();

// Access parsed interfaces
if (doc.getInterface("Element")) |interface| {
    // Use AST...
}
```

## 2. Code Generator (`codegen/`)

**Purpose**: Generate Zig delegation methods from WebIDL AST

**Dependencies**: Uses the WebIDL parser as a library

```
tools/codegen/
├── README.md          # Code generator documentation
├── main.zig           # CLI entry point
├── generator.zig      # Zig code generation logic
└── STATUS.md          # Implementation status
```

**Key Design Principles:**
- ✅ Separate from parser (imports it)
- ✅ DOM-specific (not generic)
- ✅ Generates inline delegation methods
- ✅ Outputs Zig code

**Usage:**
```bash
zig run tools/codegen/main.zig -- Element
```

## Dependency Graph

```
┌───────────────────────────────────────────────┐
│                                               │
│  Code Generator (tools/codegen/)              │
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  main.zig                              │  │
│  │  generator.zig                         │  │
│  └────────────────────────────────────────┘  │
│                  │                            │
│                  │ imports                    │
│                  ▼                            │
│  ┌────────────────────────────────────────┐  │
│  │  WebIDL Parser (webidl-parser/)        │  │
│  │                                        │  │
│  │  - root.zig (exports)                  │  │
│  │  - parser.zig                          │  │
│  │  - ast.zig                             │  │
│  └────────────────────────────────────────┘  │
│                                               │
└───────────────────────────────────────────────┘
```

## Why This Separation?

### 1. **Reusability**
The WebIDL parser can be used by other projects that need to parse WebIDL but don't need Zig code generation.

### 2. **Clean Boundaries**
- Parser: WebIDL text → AST (generic)
- Generator: AST → Zig delegation code (specific)

### 3. **Easy Extraction**
To extract WebIDL parser to its own repo:
1. Copy `tools/webidl-parser/` to new repo
2. Publish to GitHub
3. Update DOM library to use package:

```zig
// build.zig.zon
.dependencies = .{
    .webidl = .{
        .url = "https://github.com/you/webidl-parser/archive/v0.1.0.tar.gz",
        .hash = "...",
    },
},
```

### 4. **Maintainability**
Each tool has a single, well-defined responsibility:
- Parser: Parse WebIDL correctly
- Generator: Generate correct Zig code

## Current Status

### WebIDL Parser
- ✅ AST types complete
- ✅ Parser structure complete
- ⚠️ Needs minor fixes for Zig 0.15.1 APIs
- ⚠️ Needs testing on real dom.idl

### Code Generator
- ✅ Generator template complete
- ✅ CLI tool complete
- ⚠️ Needs parser fixes to complete
- ⚠️ Needs build integration

**Total remaining work: ~3-4 days**

## Future: Package Manager Integration

Once the WebIDL parser is extracted:

```zig
// In DOM library's build.zig
const webidl_parser = b.dependency("webidl", .{
    .target = target,
    .optimize = optimize,
});

// Use in code generator
const codegen_exe = b.addExecutable(.{
    .name = "codegen",
    .root_source_file = b.path("tools/codegen/main.zig"),
    // ...
});
codegen_exe.root_module.addImport("webidl-parser", webidl_parser.module("webidl-parser"));
```

## Contributing

When working on these tools:

1. **WebIDL Parser**: Keep it generic and dependency-free
2. **Code Generator**: DOM-specific logic only

Make sure changes to the parser don't break the clean separation!

## See Also

- `webidl-parser/README.md` - Parser library documentation
- `codegen/README.md` - Code generator documentation
- `codegen/STATUS.md` - Implementation status
