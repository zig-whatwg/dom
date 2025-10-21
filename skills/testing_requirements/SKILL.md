# Testing Requirements Skill

## 🚨 CRITICAL RULES - READ FIRST

### Rule #0: WPT Tests Are SACRED - NEVER Delete or Skip

**When converting Web Platform Tests (WPT) to Zig:**

**❌ ABSOLUTELY FORBIDDEN:**
- ❌ NEVER delete WPT test files because they seem "too complicated"
- ❌ NEVER skip/comment out WPT tests because features are "unimplemented"
- ❌ NEVER modify the test to avoid implementing required features
- ❌ NEVER change the WHATWG public API to make tests pass

**✅ REQUIRED ACTIONS:**
- ✅ ALWAYS use the exact WHATWG public API as specified in WebIDL
- ✅ ALWAYS implement missing features if WPT tests require them
- ✅ ALWAYS ask the user for guidance if a feature seems complex
- ✅ ALWAYS preserve the test structure and assertions from upstream WPT

**WHY THIS RULE EXISTS:**
1. **WPT tests validate spec compliance** - They define correctness
2. **Missing tests = incomplete implementation** - We need full coverage
3. **Deleted tests = broken contract** - Future regressions won't be caught
4. **API changes break compatibility** - Users depend on WHATWG APIs

**WHAT TO DO WHEN YOU ENCOUNTER:**

**Scenario 1: Test uses unimplemented feature**
```
❌ WRONG: Delete the test file
❌ WRONG: Comment out the test
❌ WRONG: Skip the feature

✅ CORRECT: 
1. Document which feature is missing
2. Ask user: "This test requires [Feature X]. Should I implement it now?"
3. Wait for guidance
4. Implement the feature if approved
```

**Scenario 2: Feature seems complex**
```
❌ WRONG: Delete tests and say "too complicated"
❌ WRONG: Simplify the test to avoid complexity

✅ CORRECT:
1. Explain the complexity to user
2. Ask: "This requires [complex thing]. How should I proceed?"
3. Wait for guidance
4. Follow user's direction
```

**Scenario 3: API doesn't match your assumption**
```
❌ WRONG: Change the public API to match your test
❌ WRONG: Keep using wrong API because "it works"

✅ CORRECT:
1. Check WebIDL in skills/whatwg_compliance/dom.idl
2. Check existing implementation in src/
3. Use the EXACT API that exists
4. If API is wrong, report it as a bug (don't "fix" it yourself)
```

**RECOVERY PROTOCOL:**

If you deleted or skipped WPT tests:
1. ✅ Restore ALL deleted test files immediately
2. ✅ Uncomment ALL skipped tests
3. ✅ Identify which features are missing
4. ✅ Ask user for implementation guidance
5. ✅ Implement missing features properly

**Example: What I Should Have Done**

```
❌ What I did:
- Found DocumentFragment.getElementById() not implemented
- Deleted the test file
- Moved on

✅ What I should have done:
- Found DocumentFragment.getElementById() not implemented
- Asked user: "DocumentFragment.getElementById() is not implemented. Should I implement it now to make these tests pass?"
- Waited for guidance
- Implemented the feature properly
```

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

### Rule #2: Test ONLY Public APIs

**❌ NEVER test private/internal implementation details**

```zig
// ❌ WRONG - Testing internal functions
const internal_func = @import("../../src/element.zig").internalHelper;

test "internal helper" {  // ❌ FORBIDDEN!
    try std.testing.expect(internal_func(123));
}
```

```zig
// ✅ CORRECT - Test only public API through @import("dom")
const dom = @import("dom");
const Element = dom.Element;

test "Element public API" {  // ✅ CORRECT
    const elem = try Element.create(allocator, "item");
    defer elem.node.release();
    
    // Test only what users can access through @import("dom")
    try std.testing.expectEqualStrings("item", elem.tag_name);
}
```

**WHAT IS PUBLIC API:**
- ✅ Types exported from `src/root.zig` (accessible via `@import("dom")`)
- ✅ `pub const` structs, enums, functions at module level
- ✅ `pub fn` methods on exported types
- ✅ `pub` fields on exported structs

**WHAT IS PRIVATE/INTERNAL:**
- ❌ Functions without `pub` keyword
- ❌ Functions in other modules not exported by `root.zig`
- ❌ Helper functions used internally
- ❌ Implementation details (internal state, algorithms)

**WHY THIS RULE EXISTS:**
1. **Refactoring freedom** - Internal details can change without breaking tests
2. **Test stability** - Tests won't break when implementation changes
3. **Clear contract** - Tests document what users can actually use
4. **Maintainability** - Don't need to update tests when refactoring internals

**HOW TO VERIFY:**
```zig
// Can you import it through @import("dom")?
const dom = @import("dom");
const MyType = dom.MyType;  // ✅ Public - can test
const helper = dom.helper;  // ❌ Error = internal - don't test
```

### Rule #3: Generic DOM Library - No HTML Names

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

**🛑 STOP - Check these first:**

### 1. Can users access this through @import("dom")?

```zig
// Try importing in a test file
const dom = @import("dom");
const MyType = dom.MyType;  // ✅ Compiles = Public API = Test it
const helper = dom.helper;  // ❌ Error = Internal = Don't test
```

**If it's not exported from `src/root.zig`, DON'T TEST IT.**

### 2. Is this implementation detail or public behavior?

```zig
// ❌ WRONG - Testing internal algorithm
test "internal sorting uses quicksort" {
    // This tests HOW it works, not WHAT it does
}

// ✅ CORRECT - Testing public behavior
test "children returns elements in document order" {
    // This tests WHAT users can rely on
}
```

### 3. Is there already a test file?

```bash
# Check if test file exists
ls tests/unit/my_module_test.zig

# If YES → Add tests there
# If NO → Create new file in tests/unit/
```

**❌ NEVER add `test "..."` blocks to src/ files!**

---

## What to Test vs What NOT to Test

### ✅ DO Test: Public API Behavior

Test what users can see and rely on:

```zig
// ✅ CORRECT - Testing public method behavior
test "Element.appendChild - adds child to parent" {
    const allocator = std.testing.allocator;
    const parent = try Element.create(allocator, "parent");
    defer parent.node.release();
    
    const child = try Element.create(allocator, "child");
    defer child.node.release();
    
    _ = try parent.node.appendChild(&child.node);
    
    // Test observable public behavior
    try std.testing.expectEqual(@as(usize, 1), parent.node.childNodes().length());
    try std.testing.expect(child.node.parent_node == &parent.node);
}
```

### ❌ DON'T Test: Internal Implementation

Don't test how it works internally:

```zig
// ❌ WRONG - Testing internal data structures
test "internal bloom filter has correct bits set" {
    const elem = try Element.create(allocator, "item");
    defer elem.node.release();
    
    // Testing internal bloom filter state = FORBIDDEN
    try std.testing.expect(elem.internal_bloom_filter.bits[3] == 0x42);
}

// ❌ WRONG - Testing internal helper functions
test "internal string escaping helper" {
    const escaped = escapeString("test"); // Internal function
    try std.testing.expectEqualStrings("test", escaped);
}

// ❌ WRONG - Testing private fields
test "element internal cache state" {
    const elem = try Element.create(allocator, "item");
    defer elem.node.release();
    
    // Testing internal cache state = FORBIDDEN
    try std.testing.expect(elem.cache_dirty == false);
}
```

### Examples of Public vs Private

**Public API (✅ Test these):**
- `Element.create()` - Factory function
- `Element.setAttribute()` - Public method
- `Element.getAttribute()` - Public method
- `elem.tag_name` - Public field (if `pub`)
- Return values and errors from public methods

**Private/Internal (❌ Don't test these):**
- `validateElementName()` - Internal helper (no `pub`)
- `elem.attribute_map` - Internal data structure
- `elem.updateBloomFilter()` - Internal optimization
- Algorithm choices (hash function, sorting method, etc.)
- Memory layout, cache state, internal flags

### How to Tell if Something is Public

**Method 1: Try to import it**
```zig
const dom = @import("dom");
const thing = dom.Thing;  // Compiles? = Public. Error? = Private.
```

**Method 2: Check src/root.zig**
```zig
// src/root.zig
pub const Element = @import("element.zig").Element;  // ✅ Public
// If it's not here, it's private
```

**Method 3: Check for `pub` keyword**
```zig
pub fn createElement(...) !*Element { }  // ✅ Public
fn internalHelper(...) void { }          // ❌ Private
```

### Why This Matters

**Testing public API:**
- ✅ Tests remain stable during refactoring
- ✅ Tests document what users can rely on
- ✅ Tests won't break when internal implementation changes
- ✅ Encourages good API design

**Testing private internals:**
- ❌ Tests break during refactoring
- ❌ Tests expose implementation details
- ❌ Makes refactoring harder and more expensive
- ❌ Tests don't reflect user experience

---

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
