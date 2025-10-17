# Agent Guidelines for WHATWG DOM Implementation in Zig

This project uses **Agent Skills** for specialized knowledge areas. Skills are automatically loaded when relevant to your task.

## ⚠️ CRITICAL: Memory Management Patterns

**This library supports TWO node creation patterns:**

### Pattern 1: Direct Creation (Element.create)

```zig
// Direct creation with allocator (no string interning)
const elem = try Element.create(allocator, "div");
defer elem.node.release();

// Caller responsible for string lifetimes
// No automatic string interning
```

### Pattern 2: Document Factory Methods (Recommended)

```zig
// Document-based creation (automatic string interning)
const doc = try Document.init(allocator);
defer doc.release();

const elem = try doc.createElement("div");
// elem.tag_name automatically interned in doc.string_pool
// elem.node.owner_document = &doc.node
```

**For tests:**
```zig
test "my test" {
    const allocator = std.testing.allocator;
    
    // Option 1: Direct creation
    const elem = try Element.create(allocator, "div");
    defer elem.node.release();
    
    // Option 2: Via Document (for string interning)
    const doc = try Document.init(allocator);
    defer doc.release();
    const elem2 = try doc.createElement("span");
}
```

**For applications (Document API preferred):**
```zig
const doc = try Document.init(allocator);
defer doc.release();

// Automatic string interning via doc.string_pool
const elem = try doc.createElement("div");
const text = try doc.createTextNode("Hello");
_ = try elem.node.appendChild(&text.node);
```

---

## Available Skills

Claude automatically loads skills when relevant to your task. You don't need to manually select them.

### 1. **whatwg_compliance** - Specification Compliance

**Automatically loaded when:**
- Implementing DOM interfaces or methods
- Verifying WebIDL signatures
- Understanding WHATWG algorithms
- Checking spec compliance

**Provides:**
- Complete WHATWG DOM specification (prose)
- Full WebIDL interface definitions (`dom.idl`)
- WebIDL to Zig type mappings
- Extended attributes guide ([CEReactions], [SameObject], etc.)
- Implementation workflow and verification checklists

**Location:** `skills/whatwg_compliance/`

### 2. **zig_standards** - Zig Programming Patterns

**Automatically loaded when:**
- Writing or refactoring Zig code
- Implementing DOM algorithms
- Managing memory with Document and allocators
- Handling errors

**Provides:**
- Naming conventions and code style
- Error handling patterns (DOM errors → Zig error unions)
- Memory management patterns (Document factory or direct creation)
- Reference counting rules
- Type safety best practices
- Comptime programming patterns

**Location:** `skills/zig_standards/`

### 3. **testing_requirements** - Test Standards

**Automatically loaded when:**
- Writing tests
- Ensuring test coverage
- Verifying memory safety (no leaks)
- Implementing TDD workflows

**Provides:**
- Test coverage requirements (happy path, edge cases, errors, memory, spec)
- Memory leak testing with `std.testing.allocator`
- Test organization patterns
- TDD workflow
- Refactoring rules (never modify existing tests)

**Location:** `skills/testing_requirements/`

### 4. **performance_optimization** - DOM Performance

**Automatically loaded when:**
- Implementing query selectors
- Optimizing tree traversal
- Working on hot paths
- Benchmarking operations

**Provides:**
- Fast paths for common cases (ASCII, simple selectors)
- Bloom filters for query optimization
- Allocation minimization patterns
- Cache-friendly data structures
- Early exit conditions
- Benchmarking patterns

**Location:** `skills/performance_optimization/`

### 5. **documentation_standards** - Documentation Format

**Automatically loaded when:**
- Writing inline documentation
- Updating README.md or CHANGELOG.md
- Documenting design decisions
- Creating completion reports

**Provides:**
- Comprehensive module-level documentation format (`//!`)
- Function and type documentation patterns (`///`)
- WHATWG + MDN specification reference format
- Complete usage examples and common patterns
- Security annotation standards
- README.md update workflow
- CHANGELOG.md format (Keep a Changelog 1.1.0)

**Reference Standard:** `/Users/bcardarella/projects/dom/src/` (peer DOM library)

**Location:** `skills/documentation_standards/`

---

## Golden Rules

These apply to ALL work on this project:

### 1. **Complete Spec Understanding** 
Read FULL specifications from `skills/whatwg_compliance/`, not grep fragments. WebIDL AND prose MUST both be consulted.

### 2. **Memory Safety**
Zero leaks, proper cleanup with defer, test with `std.testing.allocator`.

### 3. **Performance Critical**
This is a DOM implementation. Optimize aggressively. Use fast paths, bloom filters, minimize allocations.

### 4. **Test First**
Write tests before implementation. Never modify existing tests during refactoring (they are the contract).

### 5. **Dual Compliance**
WebIDL signature + WHATWG algorithm required for every feature. Both spec references (WHATWG + MDN) in documentation following the standard format.

---

## Critical Project Context

### Memory Management
- **Two patterns**: Direct creation (`Element.create`) or Document factory methods (`doc.createElement`)
- **String interning**: Only via `Document.string_pool` (automatic in factory methods)
- **Reference counting**: All nodes use `.acquire()`/`.release()` on `.node` field
- **Document**: Dual reference counting (external + node refs)

### Code Quality
- Production-ready codebase
- Zero tolerance for memory leaks
- Zero tolerance for breaking changes without major version
- Zero tolerance for untested code
- Zero tolerance for missing or incomplete documentation
- **Documentation standard**: Follow format from `/Users/bcardarella/projects/dom/src/`

### Workflow
1. **Check WebIDL** in `skills/whatwg_compliance/dom.idl` for EXACT signature
2. **Read WHATWG algorithm** from spec for complete behavior
3. **Write tests first** (TDD)
4. **Implement** with both spec references
5. **Verify** no leaks, all tests pass
6. **Document** with WebIDL + prose references
7. **Update** CHANGELOG.md immediately

---

## Memory Tool Usage

Use Claude's memory tool to persist knowledge across sessions:

**Store in memory:**
- Completed WHATWG features with implementation dates
- Design decisions and architectural rationale  
- Performance benchmark baselines
- Complex spec interpretation notes
- Known gotchas and edge cases

**Memory directory structure:**
```
memory/
├── completed_features.json
├── design_decisions.md
├── performance_baselines.json
└── spec_interpretations.md
```

---

## Quick Reference

### Most Common Types
```zig
undefined → void                 // CRITICAL: Not bool!
DOMString → []const u8
DOMString? → ?[]const u8
unsigned long → u32
Node → *Node
Node? → ?*Node
[NewObject] Element → !*Element
[SameObject] NodeList → *NodeList
```

### Most Common Errors
```zig
pub const DOMError = error{
    InvalidCharacterError,      // Invalid name/character
    HierarchyRequestError,      // Invalid parent/child relationship
    NotFoundError,              // Element/attribute not found
    InvalidStateError,          // Operation not allowed in current state
};
```

### Memory Management
```zig
// Pattern 1: Direct creation
const elem = try Element.create(allocator, "div");
defer elem.node.release();  // Decrements ref_count

// Pattern 2: Document factory (recommended)
const doc = try Document.init(allocator);
defer doc.release();
const elem2 = try doc.createElement("span");
// Strings auto-interned in doc.string_pool

// Sharing requires acquire
elem.node.acquire();  // Increment ref_count before sharing
```

---

## File Organization

```
skills/
├── whatwg_compliance/       # Complete specs, WebIDL, type mappings
├── zig_standards/           # Zig idioms, memory patterns, errors
├── testing_requirements/    # Test patterns, coverage, TDD
├── performance_optimization/# Fast paths, bloom filters, benchmarks
└── documentation_standards/ # Doc format, CHANGELOG, README

memory/                      # Persistent knowledge (memory tool)
├── completed_features.json
├── design_decisions.md
└── performance_baselines.json

summaries/                   # Analysis docs, plans, reports
├── plans/
├── analysis/
├── completion/
└── notes/

src/                         # Source code
└── ... (Zig files)

Root:
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── AGENTS.md (this file)
└── ... (build files)
```

---

## Zero Tolerance For

- Memory leaks (test with `std.testing.allocator`)
- Breaking changes without major version bump
- Untested code
- Missing documentation
- Undocumented CHANGELOG entries
- **Implementations without WebIDL verification**
- **Missing spec references (WebIDL + WHATWG prose)**
- **Using grep instead of reading complete specs**

---

## When in Doubt

1. **Load `whatwg_compliance` skill** - Check complete WebIDL + prose spec
2. **Load relevant skills** - Get specialized guidance
3. Check existing code for patterns
4. Look at existing tests
5. Follow the Golden Rules
6. Ask maintainer if still unclear

---

**Quality over speed.** Take time to do it right. The codebase is production-ready and must stay that way.

**Skills provide the details.** This file coordinates. Load skills for deep expertise.

**Thank you for maintaining the high quality standards of this project!** 🎉
