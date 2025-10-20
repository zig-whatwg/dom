# Testing Requirements Skill

## 🚨 CRITICAL RULES - READ FIRST

### Rule #1: NEVER Write Tests in src/ Files

**❌ ABSOLUTELY FORBIDDEN: Tests in `src/` directory**

```zig
// ❌ WRONG - src/element.zig
pub const Element = struct {
    // ... implementation ...
};

test "element test" {  // ❌ FORBIDDEN!
    // This test belongs in tests/unit/element_test.zig
}
```

```zig
// ✅ CORRECT - tests/unit/element_test.zig
const std = @import("std");
const Element = @import("dom").Element;

test "element test" {  // ✅ CORRECT LOCATION
    // Test code here
}
```

**WHY THIS RULE EXISTS:**
1. **Compilation speed** - Tests in src/ are compiled even for production builds
2. **Code clarity** - Source files should contain only implementation
3. **Zig best practices** - Separate test files are the standard
4. **Maintainability** - Easy to find and run tests separately

**WHERE TO PUT TESTS:**
- ✅ `tests/unit/` - Unit tests (one file per src/ file)
- ✅ `tests/wpt/` - Web Platform Tests (converted from upstream)
- ❌ NEVER in `src/` - Source files are for implementation ONLY

### Rule #2: Generic DOM Library - No HTML Names

**THIS IS A GENERIC DOM LIBRARY** - Tests MUST use generic element/attribute names.

✅ **ALWAYS use generic names**:
- Elements: `element`, `container`, `item`, `node`, `component`, `widget`, `panel`, `view`, `content`, `wrapper`, `parent`, `child`, `root`
- Attributes: `attr1`, `attr2`, `data-id`, `data-name`, `key`, `value`, `flag`

❌ **NEVER use HTML-specific names**:
- NO HTML elements: `div`, `span`, `p`, `a`, `button`, `input`, `form`, `table`, `ul`, `li`, `header`, `footer`, `section`, `article`, `nav`, `main`, `aside`, `h1`, `body`, `html`
- NO HTML attributes: `id`, `class`, `href`, `src`, `type`, `name`, `action`, `method`, `placeholder`

---

## Test Organization

### Unit Tests (`tests/unit/`)

**One test file per source file:**
- `src/element.zig` → `tests/unit/element_test.zig`
- `src/document.zig` → `tests/unit/document_test.zig`
- `src/string_utils.zig` → `tests/unit/string_utils_test.zig`

**File structure:**
```zig
// tests/unit/element_test.zig
const std = @import("std");
const Element = @import("dom").Element;

test "Element.create - creates element with tag name" {
    const allocator = std.testing.allocator;
    const elem = try Element.create(allocator, "item");
    defer elem.node.release();
    
    try std.testing.expectEqualStrings("item", elem.tag_name);
}

test "Element.setAttribute - sets attribute value" {
    // More tests...
}
```

### WPT Tests (`tests/wpt/`)

**Converted from Web Platform Tests:**
- Organized by interface: `tests/wpt/nodes/Element-*.zig`
- Replace ALL HTML names with generic names during conversion
- Preserve test structure and assertions exactly

### Integration Tests (`tests/`)

**Cross-module tests** can be in `tests/` root if needed.

---

## Before Writing ANY Test

**🛑 STOP - Check this first:**

```bash
# Is there already a test file?
ls tests/unit/my_module_test.zig

# If YES → Add tests there
# If NO → Create new file in tests/unit/
```

**❌ NEVER add `test "..."` blocks to src/ files!**

## When to use this skill

Load this skill when:
- Writing new tests
- Ensuring test coverage
- Verifying memory safety (no leaks)
- Implementing TDD workflows
- Testing spec compliance

## What this skill provides

Testing standards and patterns for DOM implementation:
- Test coverage requirements (happy path, edge cases, errors, memory safety, spec compliance)
- Memory leak testing with `std.testing.allocator`
- Test organization patterns
- TDD workflow
- Refactoring rules (never modify existing tests)

## Test Coverage Requirements

### 1. Happy Path - Normal Usage

```zig
test "Element.appendChild - adds child successfully" {
    const allocator = std.testing.allocator;
    
    // ✅ CORRECT: Generic element names
    const parent = try Element.create(allocator, "parent");
    defer parent.node.release();
    
    const child = try Element.create(allocator, "child");
    defer child.node.release();
    
    _ = try parent.node.appendChild(&child.node);
    
    try std.testing.expectEqual(@as(usize, 1), parent.node.getChildNodes().length());
    try std.testing.expect(child.node.parent_node == &parent.node);
}
```

**❌ WRONG**: Using HTML element names like `"div"`, `"span"`, `"button"`

### 2. Edge Cases - Boundary Conditions

```zig
test "Element.appendChild - handles empty parent" {
    // Test with zero children
}

test "Element.appendChild - maintains order with multiple children" {
    // ✅ CORRECT: Generic names for multiple elements
    const container = try Element.create(allocator, "container");
    const item1 = try Element.create(allocator, "item1");
    const item2 = try Element.create(allocator, "item2");
}

test "NodeList.item - returns null for out of bounds index" {
    // Test boundary conditions
}
```

### 3. Error Cases - Invalid Inputs

```zig
test "Element.appendChild - rejects DocumentType child" {
    const allocator = std.testing.allocator;
    
    // ✅ CORRECT: Generic element name
    const elem = try Element.create(allocator, "element");
    defer elem.node.release();
    
    const doctype = try DocumentType.init(allocator, "root", "", "");
    defer doctype.node.release();
    
    try std.testing.expectError(
        error.HierarchyRequestError,
        elem.node.appendChild(&doctype.node)
    );
}
```

### 4. Memory Safety - No Leaks

```zig
test "Element.appendChild - no memory leaks on error" {
    const allocator = std.testing.allocator; // Tracks allocations
    
    const parent = try Element.create(allocator, "div");
    defer parent.node.release();
    
    // Even on error paths, no leaks
    _ = parent.node.appendChild(invalid_node) catch |err| {
        try std.testing.expectEqual(error.HierarchyRequestError, err);
    };
    
    // Test passes only if all allocations are freed
}
```

### 5. Spec Compliance - Matches WHATWG Behavior

```zig
test "Element.appendChild - follows spec §4.2.4 algorithm" {
    // Test each step of the spec algorithm
    // Reference: https://dom.spec.whatwg.org/#concept-node-append
    
    // Step 1: Validate node type
    // Step 2: Check for circular reference
    // Step 3: Remove from old parent
    // Step 4: Insert into new parent
    // Step 5: Update tree pointers
}
```

## Memory Leak Testing

**CRITICAL: Always use `std.testing.allocator`**

```zig
// ✅ CORRECT
test "operation - no leaks" {
    const allocator = std.testing.allocator; // Tracks allocations!
    
    const obj = try SomeType.init(allocator);
    defer obj.deinit();
    
    // Test fails if allocations != frees
}

// ❌ WRONG
test "operation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator(); // Doesn't track leaks in tests!
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

## Test Organization

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

## DO NOT Modify Existing Tests During Refactoring

**CRITICAL RULE: When refactoring, existing tests are the contract.**

```zig
// ✅ CORRECT REFACTORING:
// 1. Run existing tests: zig build test
// 2. All tests pass ✅
// 3. Refactor implementation
// 4. Run tests again: zig build test
// 5. All tests still pass ✅
// 6. Done!

// ❌ INCORRECT REFACTORING:
// 1. Change implementation
// 2. Tests fail
// 3. Modify tests to pass ❌ WRONG!
// 4. This breaks the contract!
```

**Exception:** Only modify tests when:
- Fixing a bug in the test itself (not the implementation)
- Test was testing internal implementation details (refactor to test behavior)
- Adding NEW tests for additional coverage

## Test-Driven Development Workflow

```zig
// 1. Write test FIRST
test "Element.closest - finds ancestor matching selector" {
    const allocator = std.testing.allocator;
    
    // Setup DOM tree
    const grandparent = try Element.create(allocator, "div");
    defer grandparent.node.release();
    try grandparent.setAttribute("class", "container");
    
    const parent = try Element.create(allocator, "div");
    defer parent.node.release();
    
    const child = try Element.create(allocator, "span");
    defer child.node.release();
    
    _ = try grandparent.node.appendChild(&parent.node);
    _ = try parent.node.appendChild(&child.node);
    
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

## Common Test Patterns

### Setup/Teardown with defer

```zig
test "complex test with multiple objects" {
    const allocator = std.testing.allocator;
    
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const elem1 = try doc.createElement("div");
    defer elem1.node.release();
    
    const elem2 = try doc.createElement("span");
    defer elem2.node.release();
    
    // Test code...
    // Cleanup happens automatically in reverse order
}
```

### Error Testing

```zig
test "operation - returns correct error" {
    const allocator = std.testing.allocator;
    
    const doc = try Document.init(allocator);
    defer doc.release();
    
    // Test specific error
    try std.testing.expectError(
        error.InvalidCharacterError,
        doc.createElement("123invalid")
    );
    
    // Test error set
    const result = doc.createElement("bad<name");
    try std.testing.expectError(error, result);
}
```

### Null/Optional Testing

```zig
test "method - returns null when not found" {
    const allocator = std.testing.allocator;
    
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const result = doc.getElementById("nonexistent");
    try std.testing.expect(result == null);
}

test "method - returns value when found" {
    const allocator = std.testing.allocator;
    
    const doc = try Document.init(allocator);
    defer doc.release();
    
    // Setup with elem that has id
    const elem = try doc.createElement("div");
    defer elem.node.release();
    try elem.setAttribute("id", "found");
    
    const result = doc.getElementById("found");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("found", result.?.id());
}
```

### Comparing Pointers

```zig
test "appendChild - sets parent correctly" {
    const allocator = std.testing.allocator;
    
    const parent = try Element.create(allocator, "div");
    defer parent.node.release();
    
    const child = try Element.create(allocator, "span");
    defer child.node.release();
    
    _ = try parent.node.appendChild(&child.node);
    
    // Compare pointers
    try std.testing.expect(child.node.parent_node == &parent.node);
    try std.testing.expect(parent.node.first_child == &child.node);
}
```

## Running Tests

```bash
# Run all tests
zig build test

# Run with summary
zig build test --summary all

# Check for memory leaks
zig build test 2>&1 | grep -i leak

# Run specific test file
zig test src/element_test.zig

# Run with optimization
zig build test -Doptimize=ReleaseSafe
```

## Integration with Other Skills

This skill coordinates with:
- **whatwg_compliance** - Test spec-compliant behavior
- **zig_standards** - Use idiomatic Zig test patterns
- **documentation_standards** - Document test purpose and coverage

Load all relevant skills for complete testing guidance.
