# Browser Research & Implementation Design Skill

**When to use**: When implementing any new DOM feature, interface, or method.

**Purpose**: Ensure implementations are based on proven browser patterns, optimized for Zig's strengths, and fully spec-compliant.

---

## Mandatory Process for New Features

When implementing ANY new DOM feature, you MUST follow this process:

### Step 1: Specification Review (REQUIRED)

**Read BOTH sources**:
1. **WHATWG DOM Spec** - Complete prose algorithm
   - Location: `skills/whatwg_compliance/` directory
   - Read the FULL section, not grep fragments
   - Understand the "why" behind the algorithm

2. **WebIDL Interface** - Exact method signature
   - Location: `skills/whatwg_compliance/dom.idl`
   - Check parameter types, return types, extended attributes
   - Map to Zig types using `webidl_mapping.md`

**Never skip this step!** Grep is not a substitute for reading complete specifications.

---

### Step 2: Browser Implementation Research (REQUIRED)

Research how Chrome, Firefox, and WebKit implement the feature:

#### 2.1 Chrome/Blink Research

**Source Locations**:
- Main: `https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/core/dom/`
- Search: Use Chromium Code Search with feature name
- Files to check:
  - `element.h` / `element.cc` - Element-related features
  - `node.h` / `node.cc` - Node-related features
  - `document.h` / `document.cc` - Document-related features
  - Feature-specific files (e.g., `attr.h` for attributes)

**What to look for**:
- Data structure design (class layout, field sizes)
- Memory management patterns (ref counting, ownership)
- Optimization techniques (inline storage, fast paths, caching)
- String handling (AtomicString interning)
- Performance characteristics (complexity comments)

**Example search**:
```
https://source.chromium.org/search?q=setAttributeNS&ss=chromium%2Fchromium%2Fsrc
```

#### 2.2 Firefox/Gecko Research

**Source Locations**:
- Main: `https://searchfox.org/mozilla-central/source/dom/base/`
- Search: Use Searchfox with feature name
- Files to check:
  - `Element.h` / `Element.cpp`
  - `nsINode.h` / `nsINode.cpp`
  - `Document.h` / `Document.cpp`
  - Feature-specific files

**What to look for**:
- Space optimizations (tagged pointers, bit packing)
- Integer namespace IDs (instead of URI strings)
- Inline storage patterns
- Performance comments and telemetry
- Memory overhead calculations

**Example search**:
```
https://searchfox.org/mozilla-central/search?q=setAttributeNS&path=dom/base
```

#### 2.3 WebKit Research

**Source Locations**:
- Main: `https://github.com/WebKit/WebKit/tree/main/Source/WebCore/dom/`
- Search: GitHub search within WebCore/dom
- Files to check:
  - `Element.h` / `Element.cpp`
  - `Node.h` / `Node.cpp`
  - `Document.h` / `Document.cpp`

**What to look for**:
- Similarities to Chrome (shared ancestry)
- Differences in implementation details
- AtomString usage (string interning)
- Cache-friendly patterns

#### 2.4 Cross-Browser Patterns

**Identify universal patterns** (all 3 browsers do this):
- These are proven approaches validated across billions of pages
- Strong signal that this is the "right" way
- Prioritize these patterns in Zig implementation

**Identify unique optimizations** (only 1 browser does this):
- Understand the trade-offs
- Consider if applicable to Zig's use case
- May be browser-specific (e.g., Firefox's XUL legacy)

**Document findings** in `summaries/plans/[feature]_browser_research.md`

---

### Step 3: Design Document (REQUIRED)

Create implementation plan: `summaries/plans/[feature]_design.md`

**Required sections**:

#### 3.1 Executive Summary
- Feature overview
- Key browser findings (3-5 bullet points)
- Recommended approach for Zig
- Expected benefits (performance, memory, simplicity)

#### 3.2 Browser Implementation Analysis

For EACH browser (Chrome, Firefox, WebKit):
- Data structure layout (with sizes in bytes)
- Code snippets (simplified C++ → conceptual)
- Key optimizations
- Performance characteristics (Big-O, cache effects)
- Memory overhead calculations

**Example**:
```markdown
### Chrome/Blink: AttributeStorage

**Data Structure**:
```cpp
class Attribute {
    QualifiedName name_;   // 8 bytes (pointer to interned)
    AtomicString value_;   // 8 bytes
    // Total: 16 bytes per attribute
};
```

**Storage Pattern**: Two-tier (immutable vs mutable)
**Optimization**: Copy-on-write during parsing
**Memory**: 16 bytes/attr + 24 bytes overhead
```

#### 3.3 Cross-Browser Patterns

**Universal Patterns** (table format):
| Pattern | Chrome | Firefox | WebKit | Why? |
|---------|--------|---------|--------|------|
| Array storage | ✅ | ✅ | ✅ | Cache locality |
| String interning | ✅ | ✅ | ✅ | O(1) comparison |

**Unique Optimizations**:
- Firefox only: [describe + trade-offs]
- Chrome only: [describe + trade-offs]

#### 3.4 Zig Implementation Plan

**Design Principles**:
1. Start simple, optimize incrementally
2. Measure before optimizing
3. Leverage Zig's strengths (comptime, tagged unions, explicit allocation)
4. Zero-overhead for common cases

**Proposed Structures** (with Zig code):
```zig
pub const Feature = struct {
    // Field layout with sizes
    field1: Type,  // 8 bytes
    field2: Type,  // 16 bytes
    // Total: 24 bytes
    
    pub fn method(...) !ReturnType {
        // Implementation outline
    }
};
```

**Zig Advantages Used**:
- Comptime for [specific optimization]
- Tagged unions for [specific use case]
- Explicit allocation control for [specific pattern]
- No hidden allocations

#### 3.5 Implementation Phases

Break into phases (1 week each max):
- **Phase 1**: Foundation (core types)
- **Phase 2**: Basic functionality
- **Phase 3**: Optimizations
- **Phase 4**: Edge cases and error handling
- **Phase 5**: Performance tuning

Each phase should:
- Be independently testable
- Have clear success criteria
- Build on previous phases
- Produce working code (not stubs)

#### 3.6 Performance Expectations

**Benchmark predictions**:
- Operation X: [current time] → [expected time] ([N]x speedup)
- Memory: [current bytes] → [expected bytes] ([N]% reduction)
- Allocations: [current count] → [expected count]

**Real-world scenario**:
- Describe typical usage (e.g., "Parse 1000 element HTML page")
- Calculate before/after metrics
- Include allocation counts, cache misses, etc.

#### 3.7 Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Performance regression | Low/Med/High | Low/Med/High/Critical | [How to avoid] |
| Breaking changes | ... | ... | ... |
| Memory increase | ... | ... | ... |

#### 3.8 Validation Criteria

**Correctness**:
- [ ] All existing tests pass (zero regressions)
- [ ] All WPT tests pass (import in Step 4)
- [ ] Zero memory leaks (ASAN/valgrind)
- [ ] Spec algorithm followed exactly

**Performance**:
- [ ] Operation X is ≥[N]x faster
- [ ] Memory overhead ≤[M]%
- [ ] Allocations reduced by ≥[N]%

**Code Quality**:
- [ ] Comprehensive inline documentation
- [ ] CHANGELOG.md updated
- [ ] No breaking API changes (or major version bump)

---

### Step 4: WPT Test Import (REQUIRED)

Import relevant Web Platform Tests:

#### 4.1 Find WPT Tests

**Local WPT Repository**: `/Users/bcardarella/projects/wpt`

**IMPORTANT**: Always use the local WPT checkout, not remote GitHub.

**Search Locations**:
- `/Users/bcardarella/projects/wpt/dom/nodes/` - Node-related tests
- `/Users/bcardarella/projects/wpt/dom/events/` - Event-related tests
- `/Users/bcardarella/projects/wpt/dom/interface-objects/` - Interface tests
- Feature-specific directories in `/Users/bcardarella/projects/wpt/`

**Example**: Find MutationObserver tests:
```bash
find /Users/bcardarella/projects/wpt/dom/nodes -name "MutationObserver*.html"
```

**Example**: Find attribute tests:
```bash
find /Users/bcardarella/projects/wpt/dom/nodes -name "*attribute*" -name "*.html"
```

#### 4.2 Convert WPT Tests to Zig

**Conversion Process**:

1. **Read HTML test file** - Understand what's being tested
2. **Extract test assertions** - Identify checks and expectations
3. **Convert to Zig test** - Translate JavaScript → Zig
4. **Replace HTML elements with generic names** - CRITICAL!

**HTML Element Name Rules** (GENERIC DOM LIBRARY):

❌ **NEVER use HTML element names**:
- NO: `div`, `span`, `p`, `a`, `button`, `input`, `form`, `table`, `ul`, `li`
- NO: `header`, `footer`, `section`, `article`, `nav`, `main`, `h1`, `body`, `html`

✅ **ONLY use generic element names**:
- YES: `element`, `container`, `item`, `node`, `component`, `widget`, `panel`
- YES: `view`, `content`, `wrapper`, `parent`, `child`, `root`, `level1`, `level2`

**Rationale**: This is a **GENERIC DOM library** for ANY document type (XML, custom formats), NOT HTML-specific.

#### 4.3 WPT Test Template

```zig
// tests/wpt/nodes/Element-setAttributeNS.zig

const std = @import("std");
const testing = std.testing;
const Element = @import("../../src/element.zig").Element;
const Document = @import("../../src/document.zig").Document;

// Test: [brief description from WPT]
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/[file].html#L[line]
test "Element.setAttributeNS - [specific test case]" {
    const allocator = testing.allocator;
    
    const doc = try Document.init(allocator);
    defer doc.release();
    
    // Use GENERIC element names (not HTML)
    const elem = try doc.createElement("element");  // NOT "div"!
    defer elem.node.release();
    
    // Test logic (converted from WPT)
    try elem.setAttributeNS(
        "http://example.com/ns",
        "ns:attr",
        "value"
    );
    
    // Assertions (converted from WPT)
    const value = elem.getAttributeNS("http://example.com/ns", "attr");
    try testing.expect(value != null);
    try testing.expectEqualStrings("value", value.?);
}
```

#### 4.4 WPT Test Location

**Place tests in**: `tests/wpt/[category]/[Feature]-[method].zig`

**Examples**:
- `tests/wpt/nodes/Element-setAttributeNS.zig`
- `tests/wpt/events/Event-stopPropagation.zig`
- `tests/wpt/nodes/Node-appendChild.zig`

#### 4.5 Track WPT Coverage

**Update**: `tests/wpt/COVERAGE.md`

```markdown
## setAttributeNS Coverage

**WPT Source**: https://github.com/web-platform-tests/wpt/tree/master/dom/nodes

| WPT Test | Status | Zig Test Location |
|----------|--------|-------------------|
| Element-setAttributeNS-namespace-null.html | ✅ Passing | tests/wpt/nodes/Element-setAttributeNS.zig:L45 |
| Element-setAttributeNS-invalid-name.html | ✅ Passing | tests/wpt/nodes/Element-setAttributeNS.zig:L67 |
| ... | ... | ... |

**Coverage**: 15 / 18 tests (83%)
**Remaining**: [list uncovered test scenarios]
```

---

### Step 5: Implementation (TDD)

**Test-Driven Development** (required):

1. **Write WPT tests first** (from Step 4)
2. **Run tests** (they should fail)
3. **Implement minimum code** to pass one test
4. **Run tests** (verify one more passes)
5. **Refactor** if needed
6. **Repeat** until all tests pass

**Benefits**:
- Tests define contract (from WPT = spec-derived)
- No untested code
- Catch regressions immediately
- Refactoring is safe

---

### Step 6: Documentation (REQUIRED)

**Inline Documentation** (every public item):

```zig
/// Sets a namespaced attribute on the element.
///
/// Implements WHATWG DOM Element.setAttributeNS() per §4.9.1.
/// If an attribute with matching (namespace, localName) exists, updates value.
/// Otherwise, creates new attribute with specified namespace and qualified name.
///
/// ## Parameters
///
/// - `namespace_uri`: Namespace URI (nullable). Null = no namespace.
/// - `qualified_name`: Qualified name (may include prefix). Examples: "attr", "ns:attr"
/// - `value`: Attribute value
///
/// ## Returns
///
/// Nothing on success.
///
/// ## Errors
///
/// - `InvalidCharacterError`: If qualified_name contains invalid XML characters
/// - `NamespaceError`: If qualified_name malformed or namespace inconsistent with prefix
///
/// ## Example
///
/// ```zig
/// const elem = try doc.createElement("svg");
/// try elem.setAttributeNS(
///     "http://www.w3.org/2000/svg",
///     "viewBox",
///     "0 0 100 100"
/// );
/// ```
///
/// ## Spec Compliance
///
/// **WHATWG**: https://dom.spec.whatwg.org/#dom-element-setattributens
///
/// **WebIDL**: dom.idl:456
/// ```webidl
/// [CEReactions]
/// undefined setAttributeNS(DOMString? namespace, DOMString qualifiedName, DOMString value);
/// ```
///
/// **Algorithm** (WHATWG DOM §4.9.1):
/// 1. Let namespace be the given namespace (nullable)
/// 2. Let prefix be null
/// 3. Let localName be qualifiedName
/// 4. If qualifiedName contains ":", split into prefix and localName
/// 5. Validate namespace against prefix (throw NamespaceError if inconsistent)
/// 6. Set attribute with (namespace, prefix, localName, value)
///
/// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttributeNS
pub fn setAttributeNS(
    self: *Element,
    namespace_uri: ?[]const u8,
    qualified_name: []const u8,
    value: []const u8,
) DOMError!void {
    // Implementation...
}
```

**Documentation Standard**: Follow format from `skills/documentation_standards/SKILL.md`

**CHANGELOG.md** (Keep a Changelog 1.1.0 format):

```markdown
## [Unreleased]

### Added

- **Phase [N]: [Feature Name]** 🎉
  - **[Feature] Interface (WHATWG DOM §X.Y)** ✅ NEW
    - `feature.method()` - [Brief description]
    - [Key details about implementation]
  - **Browser Research**: Analyzed Chrome, Firefox, WebKit implementations
    - Universal pattern: [Pattern 1]
    - Universal pattern: [Pattern 2]
    - Optimization: [Specific technique from browser X]
  - **Performance**: [N]x faster than naive approach, [M]% fewer allocations
  - **Test Coverage**: [N] WPT tests imported, all passing ✅
  - **Spec References**:
    - [Feature]: [WHATWG URL]
    - WebIDL: dom.idl:[line]
    - MDN: [MDN URL]
```

---

## Decision Tree: When to Use This Skill

```
┌─────────────────────────────────────┐
│ Am I implementing a new feature?    │
│ (not fixing a bug in existing code) │
└────────────┬────────────────────────┘
             │
             ▼ YES
┌─────────────────────────────────────┐
│ Is this feature in WHATWG DOM spec? │
└────────────┬────────────────────────┘
             │
             ▼ YES
┌─────────────────────────────────────┐
│ ✅ USE THIS SKILL                   │
│                                     │
│ Process:                            │
│ 1. Read WHATWG + WebIDL specs      │
│ 2. Research Chrome/Firefox/WebKit  │
│ 3. Create design document          │
│ 4. Import WPT tests                │
│ 5. Implement (TDD)                 │
│ 6. Document thoroughly             │
└─────────────────────────────────────┘
```

**If NO** (not a new feature):
- Bug fix: Use standard TDD + testing_requirements skill
- Refactoring: Ensure zero behavior changes, existing tests must pass
- Optimization: Benchmark before/after, use performance_optimization skill

**If NO** (not in WHATWG spec):
- Custom extension: Document clearly as non-standard
- Still research browsers if related to similar feature
- Extra care with documentation (mark as extension)

---

## Anti-Patterns to Avoid

### ❌ Grepping Specs
**Wrong**:
```bash
$ rg "setAttributeNS" skills/whatwg_compliance/
```

**Right**: Open the spec file, read the complete section including context, related algorithms, and edge cases.

### ❌ Assuming Browser Implementation
**Wrong**: "I think browsers probably use a hash map for this."

**Right**: Look at actual source code, measure memory layout, read performance comments.

### ❌ Copying Browser Code Directly
**Wrong**: Port C++ code line-by-line to Zig.

**Right**: Understand the pattern, adapt to Zig's idioms and strengths.

### ❌ Skipping WPT Tests
**Wrong**: "I'll write my own tests."

**Right**: Import WPT tests (spec-derived, battle-tested), then add extra tests if needed.

### ❌ Implementing Everything at Once
**Wrong**: Big-bang implementation of entire feature in one PR.

**Right**: Phased implementation, each phase independently testable and deployable.

### ❌ Using HTML Element Names
**Wrong**: `const div = try doc.createElement("div");`

**Right**: `const container = try doc.createElement("container");`

**Rationale**: This is a generic DOM library, not HTML-specific!

---

## Success Criteria

A feature implementation is complete when:

**Research**:
- ✅ All 3 browsers researched (Chrome, Firefox, WebKit)
- ✅ Design document created with analysis + plan
- ✅ Cross-browser patterns identified
- ✅ Zig-specific optimizations planned

**Specification**:
- ✅ WHATWG prose algorithm read completely
- ✅ WebIDL signature verified and mapped to Zig
- ✅ Edge cases and error conditions understood

**Testing**:
- ✅ Relevant WPT tests imported and converted
- ✅ All WPT tests passing
- ✅ Zero memory leaks (ASAN/valgrind)
- ✅ Additional edge case tests added

**Implementation**:
- ✅ Code follows spec algorithm exactly
- ✅ Leverages Zig strengths (comptime, tagged unions, etc.)
- ✅ Performance meets expectations (benchmarked)
- ✅ Memory overhead acceptable (measured)

**Documentation**:
- ✅ Comprehensive inline documentation (follows standard)
- ✅ CHANGELOG.md updated (Keep a Changelog format)
- ✅ Design document in summaries/plans/
- ✅ Completion report in summaries/completion/

---

## Example: Complete Feature Implementation

See `summaries/plans/namespaced_attributes_design.md` for a complete example following this skill.

**That design document demonstrates**:
- 70 pages of thorough browser research
- Cross-browser pattern analysis
- Zig-optimized implementation plan
- 7 phased implementation roadmap
- Performance expectations with calculations
- Risk analysis and validation criteria

**Use this as a template** for future feature implementations!

---

## Skill Interaction

This skill works with:

- **whatwg_compliance**: Provides specs to read, WebIDL to verify
- **testing_requirements**: TDD workflow, test patterns
- **performance_optimization**: Benchmark patterns, optimization techniques
- **documentation_standards**: Inline doc format, CHANGELOG format
- **zig_standards**: Zig idioms, memory patterns, error handling

**This skill adds**: Mandatory browser research + design planning before implementation.

---

## Quick Reference Checklist

Before starting ANY new feature:

```
□ Read WHATWG spec section completely
□ Check WebIDL signature in dom.idl
□ Research Chrome/Blink implementation
□ Research Firefox/Gecko implementation
□ Research WebKit implementation
□ Identify universal patterns (all 3 browsers)
□ Identify unique optimizations (specific browsers)
□ Create design document (summaries/plans/)
□ Plan implementation phases (1 week each max)
□ Calculate performance expectations
□ Find relevant WPT tests
□ Convert WPT tests to Zig (generic element names!)
□ Place tests in tests/wpt/[category]/
□ Update COVERAGE.md
□ Implement using TDD
□ Verify all tests pass (zero leaks)
□ Write comprehensive inline documentation
□ Update CHANGELOG.md
□ Write completion report (summaries/completion/)
```

**If you skip ANY of these, stop and do them first!**

---

## Conclusion

This skill ensures every feature implementation is:
- **Proven**: Based on battle-tested browser patterns
- **Optimized**: Leverages Zig's unique strengths
- **Spec-compliant**: Follows WHATWG exactly, verified by WPT
- **Well-tested**: WPT + additional tests, zero leaks
- **Well-documented**: Comprehensive inline + design docs

**Quality over speed.** Take time to research, design, and test thoroughly.

The result: Production-ready code that performs as well as (or better than) browser implementations.
