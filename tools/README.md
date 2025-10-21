# DOM Tools

This directory contains tools for generating and maintaining the Zig DOM implementation.

## Overview

```
tools/
├── ARCHITECTURE.md              # Tool architecture and design
├── webidl-parser/              # ⭐ Standalone WebIDL parser library
│   ├── README.md               #    (Designed for extraction)
│   ├── root.zig                #    Public API
│   ├── ast.zig                 #    AST types
│   ├── parser.zig              #    Parser implementation
│   └── build.zig               #    Standalone build
│
└── codegen/                    # ⭐ Zig code generator
    ├── README.md               #    (Uses webidl-parser)
    ├── STATUS.md               #    Implementation status
    ├── main.zig                #    CLI tool
    └── generator.zig           #    Code generation logic
```

## Quick Start

### Option 1: Using the tools (once complete)

```bash
# Generate delegation for Element interface
zig run tools/codegen/main.zig -- Element

# Generate for all interfaces  
zig run tools/codegen/main.zig -- all
```

### Option 2: Using the WebIDL parser library

```zig
const webidl = @import("tools/webidl-parser/root.zig");

var parser = webidl.Parser.init(allocator, source);
var doc = try parser.parse();
defer doc.deinit();

if (doc.getInterface("Element")) |interface| {
    std.debug.print("Interface: {s}\n", .{interface.name});
    std.debug.print("Parent: {s}\n", .{interface.parent orelse "none"});
}
```

## The Two Tools

### 1. 📦 WebIDL Parser (`webidl-parser/`)

**A standalone, reusable WebIDL parsing library.**

- ✅ Zero dependencies (only `std`)
- ✅ Parses WebIDL → AST
- ✅ **Designed to be extracted** into its own package
- ✅ Generic, not DOM-specific

**Status**: 95% complete, needs minor API fixes

[Full documentation →](webidl-parser/README.md)

### 2. 🔧 Code Generator (`codegen/`)

**Generates Zig delegation methods from WebIDL.**

- ✅ DOM-specific tool
- ✅ Uses WebIDL parser as a library
- ✅ Generates inline delegation methods
- ✅ Solves the inheritance duplication problem

**Status**: 80% complete, needs parser to finish

[Full documentation →](codegen/README.md)  
[Implementation status →](codegen/STATUS.md)

## Why Two Separate Tools?

**Clean separation of concerns:**

| Concern | Tool | Can be used by |
|---------|------|----------------|
| **Parse WebIDL** | webidl-parser | Any project needing WebIDL parsing |
| **Generate Zig code** | codegen | This DOM library |

This means:
- ✅ Parser can be extracted to its own package
- ✅ Parser can be reused by other projects
- ✅ Code generator stays DOM-specific
- ✅ Clean dependency graph: codegen → webidl-parser

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                WebIDL → Zig Pipeline                │
└─────────────────────────────────────────────────────┘

Input: dom.idl
   ↓
┌──────────────────────┐
│  WebIDL Parser       │  ← Standalone library
│  (webidl-parser/)    │     (can be extracted)
└──────────────────────┘
   ↓ AST
┌──────────────────────┐
│  Code Generator      │  ← DOM-specific
│  (codegen/)          │     (uses parser)
└──────────────────────┘
   ↓
Output: Generated Zig delegation methods
```

## Current Status

### ✅ Completed
- WebIDL parser architecture
- AST type definitions  
- Code generator templates
- CLI tool structure
- Complete documentation

### ⚠️ In Progress (~20% remaining)
- Fix ArrayList API for Zig 0.15.1
- Test parser on real dom.idl
- Complete type mappings
- Build integration

### 📋 Next Steps
1. Fix parser API compatibility (2-3 hours)
2. Test end-to-end (1-2 hours)
3. Integrate into build.zig (2-3 hours)
4. Generate for all interfaces (1 day)

**Estimated completion: 3-4 days**

## The Problem We're Solving

**Zig lacks class inheritance**, so we use composition:

```zig
// Without delegation (ugly!)
elem.prototype.appendChild(child);
elem.prototype.prototype.addEventListener(...);

// With generated delegation (clean!)
elem.appendChild(child);
elem.addEventListener(...);
```

**For deep hierarchies (HTMLButtonElement → Element → Node → EventTarget):**
- Manual delegation = 75+ duplicated methods ❌
- Generated delegation = Zero duplication, automated ✅

## Research: Industry Validation

We researched how Chrome, Firefox, and WebKit handle this:

**Finding**: **All 3 browsers use WebIDL code generation!** ✅

The difference:
- **Browsers**: C++ has inheritance (free), generate bindings (JS ↔ C++)
- **Zig DOM**: No inheritance (limitation), generate delegation (simulate it)

Same principle, different target. **This is the RIGHT approach.**

See: Browser research findings in `codegen/STATUS.md`

## Future: Extraction Plan

### Extracting WebIDL Parser

When ready, extract `webidl-parser/` to its own repo:

```bash
# 1. Create new repo
git init webidl-parser
cd webidl-parser

# 2. Copy files
cp -r ../dom/tools/webidl-parser/* .

# 3. Test standalone build
zig build
zig build test

# 4. Publish
git tag v0.1.0
git push origin v0.1.0
```

### Using as Package

In DOM library:

```zig
// build.zig.zon
.dependencies = .{
    .webidl = .{
        .url = "https://github.com/you/webidl-parser/archive/v0.1.0.tar.gz",
        .hash = "...",
    },
},

// build.zig
const webidl = b.dependency("webidl", .{});
codegen_exe.root_module.addImport("webidl-parser", webidl.module("webidl-parser"));
```

## Contributing

### Working on WebIDL Parser
- Keep it generic and dependency-free
- No DOM-specific logic
- Think: "Could another project use this?"

### Working on Code Generator
- DOM-specific logic is fine here
- Can depend on parser
- Focus on generating correct Zig code

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed tool architecture
- **[webidl-parser/README.md](webidl-parser/README.md)** - Parser library docs
- **[codegen/README.md](codegen/README.md)** - Code generator docs
- **[codegen/STATUS.md](codegen/STATUS.md)** - Implementation status & next steps

## See Also

- `../AGENTS.md` - Agent guidelines (mentions browser research skill)
- `../skills/browser_research/SKILL.md` - Browser implementation research process
- `../ROADMAP.md` - Project roadmap

---

**Summary**: Two tools, cleanly separated. Parser is standalone and reusable. Generator is DOM-specific and uses the parser. Both work together to automate delegation generation from WebIDL specs.
