# Agent Guidelines for WHATWG DOM Implementation in Zig

## ⚠️ CRITICAL: Ask Clarifying Questions When Unclear

**ALWAYS ask clarifying questions when requirements are ambiguous or unclear.**

### Question-Asking Protocol

When you receive a request that is:
- Ambiguous or has multiple interpretations
- Missing key details needed for implementation
- Unclear about expected behavior or scope
- Could be understood in different ways

**YOU MUST**:
1. ✅ **Ask ONE clarifying question at a time**
2. ✅ **Wait for the answer before proceeding**
3. ✅ **Continue asking questions until you have complete understanding**
4. ✅ **Never make assumptions when you can ask**

### Examples of When to Ask

❓ **Ambiguous request**: "Make tag names case-insensitive"
- **Ask**: "Do you want tag names normalized to lowercase (so 'DIV' becomes 'div'), or should they preserve casing but match case-insensitively (so 'DIV' and 'div' are treated as the same)?"

❓ **Missing details**: "Add support for custom elements"
- **Ask**: "Should custom elements follow the Web Components spec with hyphenated names, or any arbitrary element name?"

❓ **Unclear scope**: "Optimize querySelector performance"
- **Ask**: "Which selector types should be prioritized? Simple class/ID selectors, complex descendant selectors, or attribute selectors?"

❓ **Multiple interpretations**: "Add case-insensitive attributes"
- **Ask**: "Should 'data-id' and 'DATA-ID' be treated as the same attribute (with normalization), or as separate attributes that both happen to work?"

### What NOT to Do

❌ **Don't make assumptions and implement something that might be wrong**
❌ **Don't ask multiple questions in one message** (ask one, wait for answer, then ask next)
❌ **Don't proceed with unclear requirements** hoping you guessed correctly
❌ **Don't over-explain options** in the question (keep questions concise)

### Good Question Pattern

```
"I want to make sure I understand correctly: [restate what you think they mean].

Is that correct, or did you mean [alternative interpretation]?"
```

**Remember**: It's better to ask and get it right than to implement the wrong thing quickly.

---

## ⚠️ CRITICAL: Generic DOM Library - NO HTML Specifics

**THIS IS A GENERIC DOM LIBRARY** implementing WHATWG DOM for **ANY document type** (XML, custom formats), **NOT HTML**.

### Absolute Prohibitions

❌ **NEVER** add HTML-specific features:
- NO HTML element interfaces (HTMLDivElement, HTMLButtonElement, etc.)
- NO HTML semantics (button behavior, form submission, etc.)
- NO HTML-specific attributes (href, src, action handling)
- NO HTML parsing (namespace normalization, case folding)
- NO HTML-only APIs (document.forms, document.images, etc.)

❌ **NEVER** use HTML element names in code/tests/docs:
- NO: `div`, `span`, `p`, `a`, `button`, `input`, `form`, `table`, `ul`, `li`, `header`, `footer`, `section`, `article`, `nav`, `main`, `aside`, `h1`, `body`, `html`

✅ **ONLY use generic element names**:
- YES: `element`, `container`, `item`, `node`, `component`, `widget`, `panel`, `view`, `content`, `wrapper`, `parent`, `child`, `root`, `level1`, `level2`

✅ **ONLY use generic attribute names**:
- YES: `attr1`, `attr2`, `data-id`, `data-name`, `key`, `value`, `flag`

### Test Location Rules

- **Unit tests**: Co-located with implementation in `src/` files
- **WPT tests**: Converted from Web Platform Tests, placed in `wpt_tests/` directory ONLY
- **WPT conversion**: Replace ALL HTML-specific names with generic names during conversion

---

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

## ⚠️ CRITICAL: Interface Mixins - DO NOT Put on Base Classes

**WHATWG uses interface mixins to add methods to SPECIFIC types.**

### ❌ WRONG: Adding to Node Base Class

```zig
pub const Node = struct {
    pub fn children(self: *Node) ElementCollection { } // ❌ WRONG!
    pub fn firstElementChild(self: *const Node) ?*Element { } // ❌ WRONG!
};
```

**Problem**: Text and Comment nodes inherit these but can't have children!

### ✅ CORRECT: Adding to Specific Types Only

```zig
// Element includes ParentNode mixin
pub const Element = struct {
    pub fn children(self: *Element) ElementCollection { } // ✅
    pub fn firstElementChild(self: *const Element) ?*Element { } // ✅
};

// Document includes ParentNode mixin
pub const Document = struct {
    pub fn children(self: *Document) ElementCollection { } // ✅
    pub fn firstElementChild(self: *const Document) ?*Element { } // ✅
};

// Text does NOT include ParentNode - no children() method
pub const Text = struct {
    // NO children() - Text can't have children!
};
```

**How to verify**:
1. Check `dom.idl` for mixin definition
2. Check which types `includes` the mixin
3. Implement ONLY on those specific types
4. DO NOT put on base class (Node) for inheritance

**Yes, you will duplicate code**. This is correct for type safety!

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

### 6. **benchmark_parity** - Benchmark Synchronization

**Automatically loaded when:**
- Adding new benchmarks
- Modifying existing benchmarks
- Adding performance-critical features
- Running benchmark pipeline

**Provides:**
- Zig ↔ JavaScript benchmark parity rules
- Benchmark structure patterns
- DOM setup conventions for fair comparison
- Naming conventions
- Verification checklist
- Troubleshooting guide

**Critical Rule:** When Zig benchmarks change, JavaScript benchmarks MUST be updated to match.

**Location:** `skills/benchmark_parity/`

### 7. **communication_protocol** - Clarifying Questions ⭐

**ALWAYS ACTIVE** - Applies to every interaction and task.

**Core Principle:**
When requirements are ambiguous, unclear, or could be interpreted multiple ways, **ALWAYS ask clarifying questions** before proceeding.

**Provides:**
- Question-asking protocol (one question at a time)
- When to ask vs. when to proceed
- Question patterns and examples
- Anti-patterns to avoid (assuming, option overload, paralysis)
- Decision tree for "should I ask?"

**Critical Rule:** Ask ONE clarifying question at a time. Wait for answer. Repeat until understanding is complete.

**Location:** `skills/communication_protocol/`

---

## Golden Rules

These apply to ALL work on this project:

### 0. **Ask When Unclear** ⭐ NEW
When requirements are ambiguous or unclear, **ASK CLARIFYING QUESTIONS** before proceeding. One question at a time. Wait for answer. Never assume.

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
├── communication_protocol/  # ⭐ Ask clarifying questions when unclear
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

1. **ASK A CLARIFYING QUESTION** ⭐ - Don't assume, just ask (one question at a time)
2. **Load `whatwg_compliance` skill** - Check complete WebIDL + prose spec
3. **Load relevant skills** - Get specialized guidance
4. Check existing code for patterns
5. Look at existing tests
6. Follow the Golden Rules

---

**Quality over speed.** Take time to do it right. The codebase is production-ready and must stay that way.

**Skills provide the details.** This file coordinates. Load skills for deep expertise.

**Thank you for maintaining the high quality standards of this project!** 🎉
