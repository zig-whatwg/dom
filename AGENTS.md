# Agent Guidelines for WHATWG DOM Implementation in Zig

This document provides comprehensive guidelines for AI agents contributing to the WHATWG DOM implementation. These guidelines ensure code quality, maintainability, and adherence to project standards.

## ⚠️ CRITICAL: DocumentContext Requirement

**ALL node creation MUST use DocumentContext, NOT raw allocators.**

```zig
// ✅ CORRECT - Use DocumentContext
const ctx = try DocumentContext.init(allocator);
defer ctx.deinit();
const node = try Node.init(ctx, .element_node, "div");

// ❌ WRONG - Will not compile
const node = try Node.init(allocator, .element_node, "div");
```

**For tests:**
```zig
test "my test" {
    const allocator = std.testing.allocator;
    
    const ctx = try DocumentContext.init(allocator);
    defer ctx.deinit();
    
    const elem = try Element.create(ctx, "div");
    defer elem.release();
}
```

**For users (Document API):**
```zig
const doc = try Document.init(allocator);
defer doc.release();

const elem = try doc.createElement("div");  // Uses doc.context internally
defer elem.release();
```

## Table of Contents

- [WHATWG Specification Compliance](#whatwg-specification-compliance)
- [Zig Programming Standards](#zig-programming-standards)
- [Memory Safety Requirements](#memory-safety-requirements)
- [Performance Best Practices](#performance-best-practices)
- [Testing Standards](#testing-standards)
- [CHANGELOG.md Requirements](#changelogmd-requirements)
- [Documentation Standards](#documentation-standards)
- [API Stability](#api-stability)
- [Workflow](#workflow)

---

## WHATWG Specification Compliance

**CRITICAL: All implementations MUST reference both the WHATWG DOM spec AND WebIDL definitions.**

### Dual Specification Approach

This project implements the WHATWG DOM standard, which consists of TWO authoritative sources:

1. **WHATWG DOM Standard** (prose specification)
   - URL: https://dom.spec.whatwg.org/
   - Local copy: `/Users/bcardarella/projects/specs/whatwg/dom.md`
   - Describes algorithms, behavior, and semantics

2. **WebIDL Definitions** (interface contracts)
   - URL: https://webidl.spec.whatwg.org/
   - Official DOM WebIDL: `/Users/bcardarella/projects/webref/ed/idl/dom.idl`
   - Defines exact method signatures, return types, and attributes

**BOTH MUST BE CONSULTED when implementing any feature.**

### Implementation Workflow

```zig
// Step 1: Check WebIDL for EXACT signature
// From dom.idl:
// interface Element : Node {
//     undefined removeAttribute(DOMString qualifiedName);
// };

// Step 2: Read WHATWG prose for algorithm
// From dom.spec.whatwg.org §4.9:
// "To remove an attribute by name given a qualifiedName..."

// Step 3: Implement with correct signature + behavior
/// Removes an attribute from the element.
///
/// Implements WHATWG DOM Element.removeAttribute() per §4.9.
/// WebIDL: `undefined removeAttribute(DOMString qualifiedName)`
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-element-removeattribute
/// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:123
pub fn removeAttribute(self: *Element, qualified_name: []const u8) void {
    // Implementation following spec algorithm...
}
```

### WebIDL Type Mapping to Zig

**Always check WebIDL for return types and parameter types!**

| WebIDL Type | Zig Type | Notes |
|-------------|----------|-------|
| `undefined` | `void` | No return value |
| `DOMString` | `[]const u8` | UTF-8 encoded string slice |
| `DOMString?` | `?[]const u8` | Nullable string |
| `boolean` | `bool` | true/false |
| `unsigned long` | `u32` | 32-bit unsigned |
| `Node` | `*Node` | Pointer to Node |
| `Node?` | `?*Node` | Nullable Node pointer |
| `NodeList` | `NodeList` | Live collection struct |
| `Element` | `*Element` | Pointer to Element |
| `[SameObject]` | cached | Return same instance |

### Common WebIDL Patterns

#### Void Returns (undefined)
```zig
// WebIDL: undefined removeAttribute(DOMString name);
pub fn removeAttribute(self: *Element, name: []const u8) void {
    // NOT: pub fn removeAttribute(...) bool
}
```

#### Nullable Returns
```zig
// WebIDL: Node? getFirstChild();
pub fn getFirstChild(self: *Node) ?*Node {
    return self.first_child;
}
```

#### [SameObject] Attribute
```zig
// WebIDL: [SameObject] readonly attribute NodeList childNodes;
// Must return THE SAME NodeList instance every time
pub fn childNodes(self: *Node) *NodeList {
    // Cache in rare data or return view of same underlying data
}
```

### Verification Checklist

Before marking any feature complete:

- [ ] WebIDL signature matches exactly (return type, parameter types)
- [ ] WHATWG prose algorithm implemented correctly
- [ ] Documentation includes BOTH spec references
- [ ] Return type follows WebIDL (`undefined` → `void`, not `bool`)
- [ ] Nullable types match WebIDL (`Node?` → `?*Node`)
- [ ] Collection types use correct interface (NodeList, HTMLCollection)
- [ ] Tests verify spec-compliant behavior

### Example: Complete Implementation

```zig
/// Returns the parent element of this node.
///
/// Implements WHATWG DOM Node.parentElement property per §4.4.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? parentElement;
/// ```
///
/// ## Algorithm (from spec)
/// Return the parent element of this node, or null if:
/// - This node has no parent
/// - The parent is not an Element node
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-node-parentelement
/// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:89
///
/// ## Returns
/// Parent element or null
pub fn parentElement(self: *const Node) ?*Element {
    if (self.parent_node) |parent| {
        if (parent.node_type == .element) {
            return @fieldParentPtr("node", parent);
        }
    }
    return null;
}
```

### Where to Find WebIDL

**Primary Source** (Most Authoritative):
```
/Users/bcardarella/projects/webref/ed/idl/dom.idl
```

**Online Sources**:
- Main WHATWG DOM spec (embedded): https://dom.spec.whatwg.org/
- WebIDL spec: https://webidl.spec.whatwg.org/

**How to Search**:
```bash
# Find interface definition
grep -A 20 "interface Element" /Users/bcardarella/projects/webref/ed/idl/dom.idl

# Find specific method
grep "removeAttribute" /Users/bcardarella/projects/webref/ed/idl/dom.idl
```

---

## Zig Programming Standards

### Idiomatic Zig Code

Write modern, idiomatic Zig following language conventions:

#### Naming Conventions

```zig
// Types: PascalCase
pub const Element = struct { ... };
pub const NodeType = enum { ... };

// Functions and variables: snake_case
pub fn appendChild(parent: *Node, child: *Node) !void { ... }
const my_variable: i32 = 42;

// Constants: SCREAMING_SNAKE_CASE
pub const MAX_TREE_DEPTH: usize = 1000;
pub const DEFAULT_CAPACITY: usize = 16;

// Private members: prefix with underscore when needed for clarity
const _internal_state: State = .init;
```

#### Error Handling

```zig
// Define domain-specific error sets
pub const DOMError = error{
    InvalidCharacterError,
    HierarchyRequestError,
    NotFoundError,
    IndexSizeError,
    InvalidStateError,
};

pub const SecurityError = error{
    CircularReferenceDetected,
    MaxTreeDepthExceeded,
    TooManyNodes,
    TooManyChildren,
};

// Combine error sets when needed
pub fn someOperation() (DOMError || SecurityError || Allocator.Error)!void {
    // Implementation
}

// Use error unions, not sentinel values
pub fn findNode(id: []const u8) !*Node {
    return node orelse error.NotFoundError;
}

// Provide context in error handling
try validateTagName(tag_name) catch |err| switch (err) {
    error.InvalidCharacterError => return error.InvalidCharacterError,
    error.ReservedName => return error.InvalidCharacterError,
    else => return err,
};
```

#### Memory Management

**IMPORTANT: This project uses DocumentContext for memory management, NOT raw allocators.**

```zig
// Node creation REQUIRES DocumentContext
// CORRECT:
const ctx = try DocumentContext.init(allocator);
defer ctx.deinit();

const node = try Node.init(ctx, .element_node, "div");
defer node.release();

// WRONG - This will not compile:
// const node = try Node.init(allocator, .element_node, "div");

// All strings are automatically interned via context
const text_node = try Node.init(ctx, .text_node, "#text");
const interned = try ctx.internString("Hello World");
text_node.node_value = interned.slice();
// NO manual free() needed - strings managed by intern pool

// Reference-counted objects (Node-based)
pub const Node = struct {
    ref_count: usize = 1,
    context: *DocumentContext,  // NOT allocator!
    
    pub fn acquire(self: *Node) void {
        self.ref_count += 1;
    }
    
    pub fn release(self: *Node) void {
        self.ref_count -= 1;
        if (self.ref_count == 0) {
            self.deinit();
        }
    }
    
    fn deinit(self: *Node) void {
        // Clean up via context, not manual free
        // Strings from intern pool need no cleanup
        self.context.allocator.destroy(self);
    }
};

// Document-based workflow (RECOMMENDED for users)
const doc = try Document.init(allocator);
defer doc.release();

const elem = try doc.createElement("div");
defer elem.release();
// Document owns the DocumentContext

// Simple objects with deinit (Range, etc.)
pub const Range = struct {
    allocator: Allocator,
    
    pub fn init(allocator: Allocator) !*Range {
        const range = try allocator.create(Range);
        range.* = .{ .allocator = allocator };
        return range;
    }
    
    pub fn deinit(self: *Range) void {
        self.allocator.destroy(self);
    }
};

// Always document ownership
/// Returns owned string. Caller must free using allocator.
pub fn toString(self: *Node, allocator: Allocator) ![]u8 {
    return allocator.dupe(u8, self.text);
}
```

#### Type Safety

```zig
// Use enums for fixed sets of values
pub const NodeType = enum {
    element,
    text,
    comment,
    document,
    document_fragment,
    processing_instruction,
    document_type,
};

// Use tagged unions for variants
pub const NodeValue = union(enum) {
    element: *Element,
    text: *Text,
    comment: *Comment,
    
    pub fn asElement(self: NodeValue) ?*Element {
        return switch (self) {
            .element => |e| e,
            else => null,
        };
    }
};

// Avoid @intCast/@floatCast when possible
// Use explicit bounds checking instead
fn validateIndex(index: usize, max: usize) !void {
    if (index >= max) return error.IndexSizeError;
}
```

#### Comptime Programming

```zig
// Use comptime for zero-cost abstractions
fn ArrayList(comptime T: type) type {
    return struct {
        items: []T,
        allocator: Allocator,
        
        pub fn init(allocator: Allocator) @This() {
            return .{
                .items = &[_]T{},
                .allocator = allocator,
            };
        }
    };
}

// Use comptime assertions
pub fn setNodeValue(comptime T: type, node: *Node, value: T) void {
    comptime {
        if (@sizeOf(T) > 64) {
            @compileError("Node value too large");
        }
    }
    // Implementation
}
```

---

## Memory Safety Requirements

### Zero Memory Leaks

**Requirement:** ALL code must be leak-free. This is verified by tests.

```zig
test "Element creation - no leaks" {
    const allocator = std.testing.allocator; // Tracks allocations
    
    const ctx = try DocumentContext.init(allocator);
    defer ctx.deinit();
    
    const elem = try Element.create(ctx, "div");
    defer elem.release(); // REQUIRED cleanup
    
    // Test passes only if all allocations are freed
}
```

### Safe Patterns

```zig
// GOOD: Automatic cleanup with defer
pub fn processTree(allocator: Allocator) !void {
    const ctx = try DocumentContext.init(allocator);
    defer ctx.deinit();
    
    const node = try Node.init(ctx, .element_node, "div");
    defer node.release(); // Guaranteed cleanup
    
    // Use node...
    // Release happens even if error occurs
}

// GOOD: Explicit ownership transfer
pub fn adoptNode(doc: *Document, node: *Node) void {
    node.acquire(); // Increment before transfer
    doc.node.appendChild(node) catch {
        node.release(); // Release on error
        return;
    };
    // Document now owns reference
}

// BAD: Missing cleanup
pub fn processTree(allocator: Allocator) !void {
    const ctx = try DocumentContext.init(allocator);
    defer ctx.deinit();
    
    const node = try Node.init(ctx, .element_node, "div");
    // Missing: defer node.release();
    // This will leak memory!
}

// BAD: Use after free
pub fn dangerousCode(node: *Node) void {
    node.release();
    const name = node.tag_name; // Use after free!
}
```

### Reference Counting Rules

```zig
// Rule 1: Creator owns initial reference
const ctx = try DocumentContext.init(allocator);
defer ctx.deinit();
const node = try Node.init(ctx, .element_node, "div");
// ref_count = 1, caller must release()

// Rule 2: Acquire before sharing
pub fn shareNode(node: *Node, other: *Container) void {
    node.acquire(); // ref_count = 2
    other.node = node;
    // Both owners must release()
}

// Rule 3: Release when done
pub fn cleanup(node: *Node) void {
    node.release(); // ref_count -= 1
    // Only destroyed when ref_count reaches 0
}

// Rule 4: Never release more than you own
pub fn buggyCode(node: *Node) void {
    node.release();
    node.release(); // BUG: Double release!
}
```

### Bounds Checking

```zig
// Always validate array access
pub fn getChild(parent: *Node, index: usize) !*Node {
    if (index >= parent.children.items.len) {
        return error.IndexSizeError;
    }
    return parent.children.items[index];
}

// Use Zig's built-in safety features
pub fn accessArray(array: []u8, index: usize) u8 {
    return array[index]; // Runtime bounds check in Debug/ReleaseSafe
}

// For security-critical code, always validate
pub fn secureAccess(array: []u8, index: usize) !u8 {
    if (index >= array.len) return error.IndexSizeError;
    return array[index]; // Explicit check even in ReleaseFast
}
```

---

## Performance Best Practices

### DOM-Specific Optimizations

This is a DOM implementation. Performance is CRITICAL.

#### Fast Paths

```zig
// GOOD: Fast path for common case (ASCII)
pub fn validateName(name: []const u8) !bool {
    // Fast path: pure ASCII (most common)
    var is_ascii = true;
    for (name) |byte| {
        if (byte >= 0x80) {
            is_ascii = false;
            break;
        }
    }
    
    if (is_ascii) {
        return validateAsciiName(name); // Fast validation
    }
    
    // Slow path: Unicode validation
    return validateUnicodeName(name);
}

// BAD: Always using slow path
pub fn validateName(name: []const u8) !bool {
    // Always decodes UTF-8, even for ASCII
    return validateUnicodeName(name);
}
```

#### Bloom Filters for Query Selectors

```zig
// Use bloom filters for fast element matching
pub const BloomFilter = struct {
    bits: u64 = 0,
    
    pub fn add(self: *BloomFilter, class_name: []const u8) void {
        const hash = std.hash.Wyhash.hash(0, class_name);
        self.bits |= @as(u64, 1) << @truncate(@as(u6, @intCast(hash)));
    }
    
    pub fn mayContain(self: BloomFilter, class_name: []const u8) bool {
        const hash = std.hash.Wyhash.hash(0, class_name);
        const mask = @as(u64, 1) << @truncate(@as(u6, @intCast(hash)));
        return (self.bits & mask) != 0;
    }
};

// Use in querySelector for fast rejection
pub fn querySelector(root: *Node, selector: []const u8) !?*Node {
    // Build bloom filter from selector classes
    var filter = BloomFilter{};
    // ... extract classes and add to filter
    
    // Fast rejection: if bloom filter says no, definitely no match
    if (!filter.mayContain(current_class)) {
        continue; // Skip expensive full match
    }
    
    // Full match only if bloom filter says maybe
}
```

#### Minimize Allocations

```zig
// GOOD: Reuse buffers
pub fn processNodes(allocator: Allocator, nodes: []*Node) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    
    for (nodes) |node| {
        buffer.clearRetainingCapacity(); // Reuse allocation
        try buffer.appendSlice(node.text);
        // Process buffer...
    }
}

// BAD: Allocate per iteration
pub fn processNodes(allocator: Allocator, nodes: []*Node) !void {
    for (nodes) |node| {
        var buffer = std.ArrayList(u8).init(allocator); // New allocation
        defer buffer.deinit();
        try buffer.appendSlice(node.text);
    }
}
```

#### Cache-Friendly Data Structures

```zig
// GOOD: Array of structs (cache-friendly)
pub const NodeList = struct {
    nodes: []Node, // Contiguous memory
};

// LESS GOOD: Array of pointers (cache misses)
pub const NodeList = struct {
    nodes: []*Node, // Scattered memory
};

// Use pointers only when necessary for polymorphism
```

#### Early Exit Conditions

```zig
// GOOD: Check cheapest conditions first
pub fn matches(element: *Element, selector: Selector) bool {
    // Check tag first (cheap)
    if (selector.tag) |tag| {
        if (!std.mem.eql(u8, element.tag_name, tag)) {
            return false; // Early exit
        }
    }
    
    // Check classes (more expensive)
    if (selector.classes.items.len > 0) {
        for (selector.classes.items) |class| {
            if (!element.hasClass(class)) return false;
        }
    }
    
    // Check attributes (most expensive)
    if (selector.attributes.items.len > 0) {
        // ...
    }
    
    return true;
}
```

### Benchmarking

```zig
// Always benchmark performance-critical code
test "benchmark - querySelector performance" {
    const allocator = std.testing.allocator;
    const iterations = 10000;
    
    var timer = try std.time.Timer.start();
    
    for (0..iterations) |_| {
        const result = try querySelector(root, ".my-class");
        _ = result;
    }
    
    const elapsed = timer.read();
    const ns_per_op = elapsed / iterations;
    
    std.debug.print("querySelector: {} ns/op\n", .{ns_per_op});
    
    // Assert performance requirement
    try std.testing.expect(ns_per_op < 100_000); // Must be < 100μs
}
```

---

## Testing Standards

### Test Requirements

**CRITICAL:** All code must have comprehensive tests.

#### Test Coverage Requirements

```zig
// 1. HAPPY PATH - Normal usage
test "Element.appendChild - adds child successfully" {
    const allocator = std.testing.allocator;
    
    const ctx = try DocumentContext.init(allocator);
    defer ctx.deinit();
    
    const parent = try Element.create(ctx, "div");
    defer parent.release();
    
    const child = try Element.create(ctx, "span");
    defer child.release();
    
    _ = try parent.appendChild(child.node);
    
    try std.testing.expectEqual(@as(usize, 1), parent.node.child_nodes.length());
    try std.testing.expect(child.node.parent_node == parent.node);
}

// 2. EDGE CASES - Boundary conditions
test "Element.appendChild - handles empty parent" {
    // Test with zero children
}

test "Element.appendChild - maintains order with multiple children" {
    // Test with many children
}

// 3. ERROR CASES - Invalid inputs
test "Element.appendChild - rejects DocumentType child" {
    const allocator = std.testing.allocator;
    
    const ctx = try DocumentContext.init(allocator);
    defer ctx.deinit();
    
    const elem = try Element.create(ctx, "div");
    defer elem.release();
    
    const doctype = try DocumentType.init(ctx, "html", "", "");
    defer doctype.deinit();
    
    try std.testing.expectError(
        error.HierarchyRequestError,
        elem.appendChild(doctype.node)
    );
}

// 4. MEMORY SAFETY - No leaks
test "Element.appendChild - no memory leaks on error" {
    const allocator = std.testing.allocator; // Tracks allocations
    
    const ctx = try DocumentContext.init(allocator);
    defer ctx.deinit();
    
    // All allocations must be freed
    const parent = try Element.create(ctx, "div");
    defer parent.release();
    
    // Even on error paths
    _ = parent.appendChild(invalid_node) catch |err| {
        try std.testing.expectEqual(error.HierarchyRequestError, err);
    };
    
    // Test passes only if no leaks
}

// 5. SPEC COMPLIANCE - Matches WHATWG behavior
test "Element.appendChild - follows spec §4.2.4 algorithm" {
    // Test each step of the spec algorithm
    // Reference: https://dom.spec.whatwg.org/#concept-node-append
}
```

#### Test Organization

```zig
// Group related tests in same file
// File: src/element_test.zig

test "Element.createElement - creates element with tag name" { }
test "Element.createElement - normalizes tag name" { }
test "Element.createElement - rejects invalid names" { }

test "Element.setAttribute - sets attribute" { }
test "Element.setAttribute - updates existing attribute" { }
test "Element.setAttribute - validates attribute name" { }

test "Element.getAttribute - returns attribute value" { }
test "Element.getAttribute - returns null for missing attribute" { }
```

#### Memory Leak Testing

```zig
// ALWAYS use std.testing.allocator
test "operation - no leaks" {
    const allocator = std.testing.allocator; // NOT general_purpose_allocator!
    
    const obj = try SomeType.init(allocator);
    defer obj.deinit();
    
    // Test fails if allocations != frees
}

// For complex scenarios, track explicitly
test "complex operation - tracked allocations" {
    const allocator = std.testing.allocator;
    
    const start_allocs = allocator.total_allocated_bytes;
    
    {
        const obj = try SomeType.init(allocator);
        defer obj.deinit();
        // Use obj...
    }
    
    const end_allocs = allocator.total_allocated_bytes;
    try std.testing.expectEqual(start_allocs, end_allocs);
}
```

### DO NOT Modify Existing Tests During Refactoring

**CRITICAL RULE:** When refactoring, existing tests are the contract.

```zig
// CORRECT REFACTORING:
// 1. Run existing tests: zig build test
// 2. All tests pass ✅
// 3. Refactor implementation
// 4. Run tests again: zig build test
// 5. All tests still pass ✅
// 6. Done!

// INCORRECT REFACTORING:
// 1. Change implementation
// 2. Tests fail
// 3. Modify tests to pass ❌ WRONG!
// 4. This breaks the contract!
```

**Exception:** Only modify tests when:
- Fixing a bug in the test itself (not the implementation)
- Test was testing internal implementation details (refactor to test behavior)
- Adding NEW tests for additional coverage

### Test-Driven Development for New Features

```zig
// 1. Write test FIRST
test "Element.closest - finds ancestor matching selector" {
    const allocator = std.testing.allocator;
    
    // Setup DOM tree
    const grandparent = try Element.create(allocator, "div");
    defer grandparent.release();
    try grandparent.setAttribute("class", "container");
    
    const parent = try Element.create(allocator, "div");
    defer parent.release();
    
    const child = try Element.create(allocator, "span");
    defer child.release();
    
    _ = try grandparent.appendChild(parent.node);
    _ = try parent.appendChild(child.node);
    
    // Test
    const result = try child.closest(".container");
    try std.testing.expect(result == grandparent);
}

// 2. Run test - it FAILS (method doesn't exist yet)

// 3. Implement MINIMUM code to pass test
pub fn closest(self: *Element, selector: []const u8) !?*Element {
    var current = self.parent_node;
    while (current) |node| {
        if (node.node_type == .element) {
            const elem = node.asElement();
            if (try matchesSelector(elem, selector)) {
                return elem;
            }
        }
        current = node.parent_node;
    }
    return null;
}

// 4. Run test - it PASSES ✅

// 5. Add more tests for edge cases
test "Element.closest - returns null if no match" { }
test "Element.closest - matches self" { }
test "Element.closest - stops at document" { }
```

---

## CHANGELOG.md Requirements

### Keep a Changelog Compliance

This project follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) specification.

#### Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features go here

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes and improvements

## [0.1.1] - 2025-10-12

### Added
- Feature descriptions...

[Unreleased]: https://github.com/user/repo/compare/0.1.1...HEAD
[0.1.1]: https://github.com/user/repo/compare/0.1.0...0.1.1
```

#### Category Guidelines

```markdown
### Added
- New `unicode_name_validation.zig` module for Unicode support
- `error.ReservedName` error type for "xml" prefix validation
- Support for Greek, Cyrillic, CJK, Arabic element names
- 56 comprehensive Unicode tests

### Changed
- Element name validation now accepts Unicode per XML 1.1 §2.3
- `validateTagName()` now uses Unicode validation instead of ASCII-only
- README updated with Unicode support section and examples

### Deprecated
- `oldFunction()` will be removed in 0.3.0, use `newFunction()` instead

### Removed
- Removed deprecated `legacyAPI()` function
- Dropped support for case normalization in internal processing

### Fixed
- Fixed memory leak in Element.closest() when selector invalid
- Unicode validation now properly rejects emoji characters
- Control characters (U+0000-U+001F) properly rejected in names

### Security
- Fixed ReDoS vulnerability in selector parsing (CVE-YYYY-XXXX)
- Added cycle detection to prevent infinite loops in tree operations
- Implemented resource quotas (100,000 nodes per document)
```

#### Writing Guidelines

**Keep entries concise (1-2 sentences max) but descriptive.**

```markdown
## GOOD Examples:

### Added
- Unicode support for element/attribute names per XML 1.1 §2.3 with fast-path for ASCII
- CSS selector bytecode compiler with 2-3x performance improvement
- :nth-child(), :not(), :is(), :where(), :has() pseudo-class support

### Fixed
- Memory leak in Element.closest() when parent chain contains null
- ReDoS vulnerability in CSS selector parser with complexity limits

### Changed
- querySelector now uses bytecode compilation instead of AST interpretation
- Element name validation accepts Unicode instead of ASCII-only

## BAD Examples:

### Added
- Added stuff ❌ (Too vague)
- Unicode ❌ (Not descriptive)
- Full Unicode support for element and attribute names according to XML 1.1 §2.3
  - Support for Latin Extended, Greek, Cyrillic, CJK, Arabic, Hebrew, Thai
  - Fast-path optimization for pure ASCII names (zero performance impact)
  - 56 comprehensive Unicode tests covering all supported scripts
  - Architecture notes and implementation details ❌ (Too verbose - save for docs)

### Fixed
- Bug fix ❌ (Which bug?)
- Fixed critical ReDoS vulnerability in CSS selector parser
  - Added complexity limits: 10KB max length, 10 nesting levels
  - Prevents exponential backtracking on malicious selectors
  - Resolves potential DoS attack vector ❌ (Too detailed - keep it simple)
```

**Guidelines:**
- 1-2 sentences maximum per entry
- State what changed and why/impact
- Avoid implementation details, sub-bullets, and architecture notes
- Save detailed explanations for documentation
- Performance numbers OK if brief (e.g., "2x faster")

#### When to Update CHANGELOG

**ALWAYS add to [Unreleased] section immediately after:**
1. Merging a PR
2. Committing a feature
3. Fixing a bug
4. Making ANY user-visible change

**DO NOT:**
- Wait until release to update CHANGELOG
- Combine multiple changes into one entry
- Skip documenting breaking changes
- Assume version number (let maintainer decide)

#### Update Process

```bash
# 1. Make code changes
# 2. Add concise CHANGELOG entry (1-2 sentences)
# 3. Commit CHANGELOG with your changes
# 4. Done

# Example entry:
### Added
- Unicode support for element names per XML 1.1 §2.3
```

#### Semantic Versioning Impact

Document whether change requires version bump:

```markdown
### Added (Minor version bump - 0.1.0 → 0.2.0)
- New public API function `Element.closest()`

### Changed (Major version bump - 0.1.0 → 1.0.0)
- **BREAKING:** `createElement()` now returns `!*Element` instead of `?*Element`
- Migration: Change `if (elem)` to `try createElement()`

### Fixed (Patch version bump - 0.1.0 → 0.1.1)
- Memory leak in appendChild when child already has parent

### Security (Patch version bump, but consider Minor for visibility)
- Fixed ReDoS in selector parser (CVE-2025-XXXX)
```

---

## Documentation Standards

### Inline Documentation

**All public APIs MUST be documented with WebIDL + WHATWG references.**

```zig
/// Creates a new element with the specified tag name.
///
/// Implements WHATWG DOM Document.createElement() per §4.10.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] Element createElement(DOMString localName);
/// ```
///
/// ## Algorithm
/// The tag name is validated according to XML 1.1 §2.3 naming rules.
/// Unicode characters are supported, but reserved names (starting with "xml")
/// and emoji are rejected.
///
/// ## Memory Management
/// Returns a new Element with ref_count = 1. Caller MUST call `element.release()`
/// when done to prevent memory leaks.
///
/// ## Parameters
/// - `allocator`: Memory allocator for element creation
/// - `local_name`: Valid XML name for the element (UTF-8 encoded)
///
/// ## Returns
/// - `*Element`: New element node with specified tag name
///
/// ## Errors
/// - `error.OutOfMemory`: Failed to allocate memory
/// - `error.InvalidCharacterError`: Invalid character in local_name
/// - `error.ReservedName`: local_name starts with "xml" (case-insensitive)
/// - `error.InvalidStateError`: local_name is empty
///
/// ## Example
/// ```zig
/// const elem = try doc.createElement("div");
/// defer elem.node.release();
///
/// try elem.setAttribute("id", "my-div");
/// ```
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-createelement
/// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:456
pub fn createElement(
    self: *Document,
    local_name: []const u8,
) (Allocator.Error || DOMError)!*Element {
    // Implementation following spec algorithm
}
```

### README.md Updates

**Update README.md whenever:**
1. Adding new public API
2. Changing existing API (especially breaking changes)
3. Adding new features
4. Updating version numbers or test counts
5. Changing performance characteristics

```markdown
## GOOD README Updates:

After adding Unicode support:
1. Update feature list:
   - ✅ **Unicode Support** - Full XML 1.1 compliant Unicode names

2. Add usage section:
   ## Unicode Support
   
   Full XML 1.1 §2.3 compliant Unicode support...
   
   ### Examples
   ```zig
   const café = try doc.createElement("café");
   ```

3. Update test count badges:
   [![Tests](https://img.shields.io/badge/tests-786%20passing-brightgreen.svg)]()

4. Update roadmap:
   - [x] Full Unicode support for element and attribute names
```

### Documentation Files

Keep these up-to-date:

```markdown
README.md
  - Features list
  - Usage examples
  - API overview
  - Test counts
  - Performance metrics
  - Roadmap

CHANGELOG.md
  - All changes in [Unreleased]
  - Update immediately after changes

CONTRIBUTING.md
  - Keep guidelines current
  - Update for new workflows

API_REFERENCE.md (if present)
  - Update for API changes
  - Add new functions
```

### Code Comments

```zig
// GOOD: Explain WHY, not WHAT
// Fast path: Skip UTF-8 decoding for pure ASCII (most common case)
// This provides 0% overhead for English element names.
if (is_pure_ascii) {
    return validateAsciiName(name);
}

// GOOD: Document non-obvious behavior
// Note: We don't normalize case because XML is case-sensitive
// per XML 1.1 §2.3, unlike HTML5.
const name = tag_name; // No normalization

// GOOD: Mark TODO/FIXME with context
// TODO(unicode): Add NFC normalization support (WHATWG DOM §4.9.1)
// Currently we accept any valid UTF-8, but spec requires NFC.

// BAD: Obvious comments
// Increment counter by 1
counter += 1;

// BAD: Outdated comments
// Returns null if not found (WRONG: now returns error)
pub fn find() !*Node { }
```

---

## API Stability

### Never Break Public API

**CRITICAL:** Public API stability is paramount.

#### What is Public API?

```zig
// PUBLIC API - Cannot change without major version bump
pub const Element = struct { ... };
pub fn appendChild() !void { }
pub const NodeType = enum { ... };

// INTERNAL - Can change freely
const internal_helper = struct { ... };
fn privateFunction() void { }
```

#### Safe Changes (Patch/Minor version)

```zig
// ✅ Adding new public functions (Minor)
pub fn newFeature() !void { }

// ✅ Adding new fields to structs (Minor, if struct not constructed by users)
pub const Element = struct {
    tag_name: []const u8,
    new_field: []const u8 = "", // Added with default
};

// ✅ Adding new error types to error set (Minor)
pub const DOMError = error{
    ExistingError,
    NewError, // Added
};

// ✅ Fixing bugs (Patch)
pub fn buggyFunction() !void {
    // Fixed implementation, same signature
}

// ✅ Performance improvements (Patch)
pub fn slowFunction() !void {
    // Same behavior, faster implementation
}

// ✅ Internal refactoring (Patch)
// As long as public behavior unchanged
```

#### Breaking Changes (Major version ONLY)

```zig
// ❌ BREAKING: Changing function signature
// Before:
pub fn createElement(name: []const u8) !*Element { }
// After:
pub fn createElement(allocator: Allocator, name: []const u8) !*Element { }
// Migration required!

// ❌ BREAKING: Changing return type
// Before:
pub fn findNode() ?*Node { }
// After:
pub fn findNode() !*Node { }
// Error handling changes!

// ❌ BREAKING: Removing public functions
// Before:
pub fn deprecatedFunction() void { }
// After:
// [removed] - Code using this breaks!

// ❌ BREAKING: Changing struct fields (if publicly constructed)
// Before:
pub const Config = struct { max_depth: usize };
// After:
pub const Config = struct { max_depth: u32 }; // Type changed!

// ❌ BREAKING: Renaming public APIs
// Before:
pub fn oldName() void { }
// After:
pub fn newName() void { } // Breaking even if behavior same!
```

#### Deprecation Process

```zig
// Step 1: Mark as deprecated (Minor version)
/// @deprecated Use newFunction() instead. Will be removed in 2.0.0.
pub fn oldFunction() void {
    @compileLog("Warning: oldFunction is deprecated, use newFunction");
    return newFunction();
}

// Step 2: Add CHANGELOG entry
### Deprecated
- `oldFunction()` deprecated, use `newFunction()` instead (will be removed in 2.0.0)

// Step 3: Update docs
// Step 4: Wait at least one minor version
// Step 5: Remove in next major version

### Removed
- Removed `oldFunction()` (deprecated since 1.5.0)
  - Migration: Replace `oldFunction()` with `newFunction()`
```

#### Internal Refactoring

```zig
// ✅ SAFE: Refactor internals
// Before:
pub fn appendChild(parent: *Node, child: *Node) !void {
    // Old implementation
}

// After:
pub fn appendChild(parent: *Node, child: *Node) !void {
    // Refactored implementation (same behavior)
}

// Tests MUST still pass!
// Public API unchanged!
```

### API Design Guidelines

```zig
// GOOD: Consistent naming
pub fn appendChild(child: *Node) !void { }
pub fn insertBefore(new_child: *Node, ref_child: ?*Node) !void { }
pub fn removeChild(child: *Node) !*Node { }

// GOOD: Error handling
pub fn operation() !ReturnType { } // Can fail
pub fn query() ?ReturnType { }     // May not find
pub fn getter() ReturnType { }     // Always succeeds

// GOOD: Memory ownership clear
/// Caller owns returned string. Must free with allocator.
pub fn toString(allocator: Allocator) ![]u8 { }

/// Borrows reference. Do not free.
pub fn getTagName() []const u8 { }

// GOOD: Allocator explicit
pub fn init(allocator: Allocator) !*Self { }

// BAD: Hidden allocator
pub fn init() !*Self { } // Where does memory come from?
```

---

## Workflow

### Step-by-Step Process

```bash
# 1. READ the requirements

# 2. CHECK WebIDL specification FIRST
# Look up exact interface definition:
grep -A 10 "interface NodeOrElement" /Users/bcardarella/projects/webref/ed/idl/dom.idl
# Note return types (undefined = void), parameter types, nullable markers

# 3. READ WHATWG DOM prose specification
# Understand algorithm and behavior from:
# https://dom.spec.whatwg.org/ OR /Users/bcardarella/projects/specs/whatwg/dom.md

# 4. CHECK existing tests
zig build test

# 5. WRITE tests first (if new feature)
vim src/feature_test.zig
# Test both WebIDL signature AND WHATWG behavior

# 6. IMPLEMENT feature
vim src/feature.zig
# Follow WebIDL signature EXACTLY
# Implement WHATWG algorithm
# Include BOTH spec references in docs

# 7. RUN tests
zig build test --summary all

# 8. ENSURE no memory leaks
zig build test 2>&1 | grep -i leak

# 9. FORMAT code
zig fmt src/

# 10. UPDATE CHANGELOG.md
vim CHANGELOG.md
# Add entry under [Unreleased]
# Include spec reference if applicable

# 11. UPDATE README.md (if needed)
vim README.md
# Update features, examples, test counts

# 12. UPDATE documentation
vim src/feature.zig
# Add/update doc comments with WebIDL + WHATWG refs

# 13. VERIFY everything
zig build test --summary all
zig build -Doptimize=ReleaseFast

# 14. COMMIT
git add .
git commit -m "feat: add feature per WebIDL spec (fixes #123)"

# 15. DONE ✅
```

### Pre-Commit Checklist

- [ ] **WebIDL signature verified** (checked /Users/bcardarella/projects/webref/ed/idl/dom.idl)
- [ ] **WHATWG algorithm implemented** (checked dom.spec.whatwg.org or local dom.md)
- [ ] **Documentation includes BOTH spec references** (WebIDL + WHATWG prose)
- [ ] All tests pass
- [ ] No memory leaks
- [ ] Code formatted (`zig fmt`)
- [ ] CHANGELOG.md updated
- [ ] README.md updated (if needed)
- [ ] Documentation comments added/updated
- [ ] No breaking API changes (or documented if necessary)
- [ ] Existing tests unchanged (unless fixing test bugs)
- [ ] New tests added for new features

### Performance Verification

```bash
# Always verify performance hasn't regressed
zig build bench -Doptimize=ReleaseFast

# Compare with previous benchmarks
# Ensure < 10% regression for existing operations
```

---

## Documentation Organization

**All analysis documents, plans, and summaries MUST go in the `summaries/` directory.**

This keeps the root directory clean and organized.

#### Document Types and Locations

```
summaries/
├── plans/                    # Planning documents
│   ├── dom_memory_plan.md
│   └── feature_plan.md
├── analysis/                 # Performance and technical analysis
│   ├── DEEP_PERFORMANCE_ANALYSIS.md
│   ├── BENCHMARK_COMPARISON.md
│   └── BENCHMARK_METHODOLOGY.md
├── completion/              # Phase completion reports
│   ├── PHASE1_COMPLETION.md
│   ├── PHASE2_COMPLETION.md
│   └── MEMORY_REFACTORING.md
└── notes/                   # Session notes and progress tracking
    └── session_notes.md
```

#### When Creating Documents

**Planning Phase:**
```bash
# Create planning document
vim summaries/plans/feature_name_plan.md
```

**Analysis Phase:**
```bash
# Create analysis document
vim summaries/analysis/performance_analysis.md
```

**Completion Phase:**
```bash
# Create completion report
vim summaries/completion/feature_completion.md
```

**Session Notes:**
```bash
# Create or update session notes
vim summaries/notes/session_$(date +%Y%m%d).md
```

#### Root Directory Documents

Only these documents belong in the root:

- `README.md` - Main project documentation
- `CHANGELOG.md` - User-facing change history
- `CONTRIBUTING.md` - Contributor guidelines
- `LICENSE` - Project license
- `AGENTS.md` - This file (agent guidelines)

**Everything else goes in `summaries/`!**

#### Why This Matters

- ✅ Clean root directory (easy to navigate)
- ✅ Organized documentation (easy to find)
- ✅ Clear separation (code vs docs vs planning)
- ✅ Better git history (smaller diffs in root)
- ✅ Professional appearance (production-ready project)

---

## Summary

### Golden Rules

1. **WebIDL First:** ALWAYS check WebIDL before implementing (return types, signatures)
2. **Dual Spec Compliance:** Reference BOTH WebIDL AND WHATWG prose in all implementations
3. **Memory Safety:** Zero leaks, always use defer, test with std.testing.allocator
4. **Performance:** DOM operations are hot paths, optimize aggressively
5. **Testing:** Write tests first, never modify existing tests during refactoring
6. **CHANGELOG:** Update immediately after every change
7. **Documentation:** Update README and inline docs continuously
8. **API Stability:** Never break public API without major version bump
9. **Idiomatic Zig:** Follow language conventions, use modern patterns

### Questions?

When in doubt:
1. **Check WebIDL first** (`/Users/bcardarella/projects/webref/ed/idl/dom.idl`)
2. **Read WHATWG DOM specification** (prose algorithm)
3. Check existing code for patterns
4. Look at existing tests
5. Follow these guidelines
6. Ask maintainer if still unclear

---

**Remember:** Quality over speed. Take time to do it right. The codebase is production-ready and must stay that way.

**Zero tolerance for:**
- Memory leaks
- Breaking changes without major version
- Untested code
- Missing documentation
- Undocumented CHANGELOG entries
- **Implementations without WebIDL verification**
- **Missing spec references (WebIDL + WHATWG prose)**

**Thank you for maintaining the high quality standards of this project!** 🎉
