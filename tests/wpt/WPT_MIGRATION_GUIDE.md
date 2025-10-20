# WPT Test Migration Guide

**Purpose**: Systematic guide for converting WPT DOM tests from JavaScript/HTML to Zig

**Current Progress**: 33/158 nodes/ root tests (20.9%)

---

## Overview

The Web Platform Tests (WPT) for DOM provide comprehensive test coverage for the WHATWG DOM Standard. This guide explains how to systematically migrate these tests to Zig.

### WPT Structure

```
/Users/bcardarella/projects/wpt/dom/
├── nodes/           339 tests (core DOM - our focus)
├── events/          175 tests (event system)
├── ranges/           45 tests (Range API)
├── traversal/        28 tests (TreeWalker, NodeIterator)
├── abort/            10 tests (AbortController/Signal)
├── collections/      10 tests (HTMLCollection)
├── lists/             5 tests (NodeList)
└── (root)            11 tests (IDL harness)
```

---

## Migration Batches

### Batch 1: Already Implemented Features (30 tests)

These features are implemented but lack WPT test coverage:

**CharacterData (2 remaining)**:
- ✅ CharacterData-insertData (converted)
- ✅ CharacterData-replaceData (converted)

**Element - ParentNode Mixin (7 tests)**:
- Element-children
- Element-firstElementChild
- Element-lastElementChild
- Element-nextElementSibling
- Element-previousElementSibling
- Element-childElementCount-dynamic-add
- Element-childElementCount-dynamic-remove

**Element - ChildNode Mixin (2 tests)**:
- Element-remove
- CharacterData-remove

**Element - Query Methods (4 tests)**:
- Element-getElementsByTagName
- Element-getElementsByClassName
- Element-closest
- Element-matches

**Document - Query Methods (3 tests)**:
- Document-getElementsByTagName
- Document-getElementsByClassName
- Document-getElementsByTagNameNS

**Element - Attributes (2 tests)**:
- Element-removeAttribute
- Element-getAttributeNames

**DocumentFragment (1 test)**:
- DocumentFragment-getElementById

**ParentNode Mixin (4 tests)**:
- Element-childElementCount-nochild
- Element-childElementCount-dynamic-add
- Element-childElementCount-dynamic-remove
- Element-siblingElement-null

### Batch 2: Simple Tests (4 tests)

Require minimal implementation:
- Comment-constructor
- Document-constructor
- Node-isEqualNode
- Text-constructor

### Batch 3: Requires Implementation (93 tests)

Major features needing implementation:
- ChildNode mixin (after, before, replaceWith)
- ParentNode mixin (prepend, append, replaceChildren)
- Namespaces (createElementNS, setAttributeNS, etc.)
- DOMImplementation
- Attr & NamedNodeMap
- DocumentType
- ProcessingInstruction
- CDATASection
- Many edge cases

---

## Migration Process

### Step 1: Identify Test File

```bash
ls /Users/bcardarella/projects/wpt/dom/nodes/*.html | grep <feature>
```

### Step 2: Read Original Test

```bash
cat /Users/bcardarella/projects/wpt/dom/nodes/<test-name>.html
```

Understand:
- What interface is being tested
- What methods/properties are exercised
- What assertions are made
- Edge cases covered

### Step 3: Check Implementation

Verify the feature is implemented:
```bash
grep "pub fn <method>" src/*.zig
```

If not implemented, skip to Batch 3.

### Step 4: Create Zig Test File

Template:
```zig
// WPT Test: <test-name>.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/<test-name>.html
//
// Tests <interface>.<feature> behavior as specified in WHATWG DOM Standard § X.Y
// https://dom.spec.whatwg.org/#<spec-section>

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;  // Add needed types

test "<description>" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Test implementation
    // Use defer for orphaned nodes
}
```

### Step 5: Convert Tests

**Common patterns**:

JavaScript → Zig translations:
```javascript
// JavaScript
document.createTextNode("test")
node.data
node.insertData(0, "X")
assert_equals(node.data, "Xtest")
assert_throws_dom("IndexSizeError", ...)
```

```zig
// Zig
const node = try doc.createTextNode("test");
defer node.prototype.release();
node.data
try node.insertData(0, "X");
try std.testing.expectEqualStrings("Xtest", node.data);
try std.testing.expectError(error.IndexOutOfBounds, ...);
```

**Error mapping**:
- `IndexSizeError` → `error.IndexOutOfBounds` (implementation uses this)
- `HierarchyRequestError` → `error.HierarchyRequestError`
- `InvalidCharacterError` → `error.InvalidCharacterError`
- `NotFoundError` → `error.NotFoundError`

**Memory management**:
```zig
// Orphaned nodes need defer release
const orphan = try doc.createElement("div");
defer orphan.prototype.release();

// Tree-inserted nodes are managed by parent
const parent = try doc.createElement("div");
defer parent.prototype.release();
const child = try doc.createElement("span");
_ = try parent.prototype.appendChild(&child.prototype);
// NO defer for child - parent will clean up
```

**Common gotchas**:
1. Use `.prototype` not `.node` for most node types
2. Document uses `.prototype` for Node methods
3. UTF-8 byte offsets vs UTF-16 code units (skip non-ASCII tests)
4. Some tests use `null` which isn't directly translateable

### Step 6: Add to Test Runner

Edit `tests/wpt/wpt_tests.zig`:
```zig
// Add to appropriate section
test {
    _ = @import("nodes/<test-name>.zig");
}
```

### Step 7: Run Tests

```bash
zig build test-wpt
```

Fix any:
- Compilation errors
- Test failures
- Memory leaks

### Step 8: Update Progress

Update test count in:
- `README.md` - Badge and metrics
- `tests/wpt/COVERAGE.md` - Progress tracking
- `tests/wpt/STATUS.md` - Latest updates

---

## Common Test Patterns

### Pattern 1: Error Handling

```zig
test "Feature throws on invalid input" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();
    
    // Test error
    try std.testing.expectError(error.IndexOutOfBounds, 
        node.someMethod(invalid_arg));
}
```

### Pattern 2: State Changes

```zig
test "Feature changes state correctly" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();
    
    // Check initial state
    try std.testing.expectEqualStrings("test", node.data);
    
    // Perform operation
    try node.someMethod(args);
    
    // Check final state
    try std.testing.expectEqualStrings("expected", node.data);
}
```

### Pattern 3: Tree Relationships

```zig
test "Feature maintains tree relationships" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();
    
    const child = try doc.createElement("span");
    // NO defer - will be managed by parent
    
    _ = try parent.prototype.appendChild(&child.prototype);
    
    try std.testing.expectEqual(&child.prototype, 
        parent.prototype.first_child);
}
```

### Pattern 4: Collections/Iteration

```zig
test "Feature returns correct collection" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();
    
    // Build tree
    const child1 = try doc.createElement("span");
    _ = try elem.prototype.appendChild(&child1.prototype);
    
    // Test collection
    const children = elem.children();
    try std.testing.expectEqual(@as(usize, 1), children.length());
}
```

---

## Test Exclusions

### Skip Non-ASCII Tests

UTF-8 byte offsets vs UTF-16 code units cause issues:
```zig
// Note: Skipping non-ASCII tests due to UTF-8 byte offset vs UTF-16 code unit differences
// The implementation uses byte offsets while the spec uses UTF-16 code units.
// This is a known limitation documented in COVERAGE.md.
```

### Skip Namespace Tests

If test uses `*NS` methods and namespaces aren't implemented:
```zig
// Note: Namespace tests skipped - namespaces not yet implemented
// See COVERAGE.md Phase 4 for namespace implementation roadmap
```

### Skip Unimplemented Features

If feature isn't implemented:
```zig
// Note: This test requires <feature> which is not yet implemented
// Tracked in COVERAGE.md Phase <N>
```

---

## Quick Reference

### File Locations

- **WPT Source**: `/Users/bcardarella/projects/wpt/dom/nodes/`
- **Test Destination**: `/Users/bcardarella/projects/dom/tests/wpt/nodes/`
- **Test Runner**: `/Users/bcardarella/projects/dom/tests/wpt/wpt_tests.zig`
- **Implementation**: `/Users/bcardarella/projects/dom/src/`

### Commands

```bash
# View WPT test
cat /Users/bcardarella/projects/wpt/dom/nodes/<test>.html

# Check if feature exists
grep "pub fn <method>" src/*.zig

# Run WPT tests
zig build test-wpt

# Run all tests
zig build test

# Count progress
find tests/wpt/nodes -name "*.zig" | wc -l
```

### Coverage Calculation

```python
implemented = <count>
print(f"nodes/ root: {(implemented/158*100):.1f}%")
print(f"all nodes/: {(implemented/339*100):.1f}%")
print(f"full DOM: {(implemented/623*100):.1f}%")
```

---

## Example: Complete Migration

Let's migrate `CharacterData-insertData.html` step-by-step:

### 1. Read Original

```bash
cat /Users/bcardarella/projects/wpt/dom/nodes/CharacterData-insertData.html
```

Key observations:
- Tests Text and Comment nodes
- Covers: out of bounds, empty string, start/middle/end insertion
- Has non-ASCII tests (skip these)

### 2. Check Implementation

```bash
grep "pub fn insertData" src/text.zig src/comment.zig
```

✅ Found - both implement `insertData()`

### 3. Create Test File

Create `tests/wpt/nodes/CharacterData-insertData.zig` with header:
```zig
// WPT Test: CharacterData-insertData.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/CharacterData-insertData.html
//
// Tests CharacterData.insertData() behavior as specified in WHATWG DOM Standard § 4.10
// https://dom.spec.whatwg.org/#dom-characterdata-insertdata

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;
const Comment = dom.Comment;
```

### 4. Convert Tests

For each JavaScript test:
```javascript
test(function() {
  var node = create()
  node.insertData(0, "X")
  assert_equals(node.data, "Xtest")
}, "Text.insertData() at the start")
```

Convert to Zig:
```zig
test "Text.insertData() at the start" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const node = try doc.createTextNode("test");
    defer node.prototype.release();
    
    try node.insertData(0, "X");
    try std.testing.expectEqualStrings("Xtest", node.data);
}
```

### 5. Add to Runner

Edit `tests/wpt/wpt_tests.zig`:
```zig
// CharacterData tests
test {
    _ = @import("nodes/CharacterData-appendData.zig");
    _ = @import("nodes/CharacterData-data.zig");
    _ = @import("nodes/CharacterData-deleteData.zig");
    _ = @import("nodes/CharacterData-insertData.zig");  // NEW
    _ = @import("nodes/CharacterData-substringData.zig");
}
```

### 6. Test

```bash
zig build test-wpt
```

✅ All tests pass, no leaks

### 7. Update Metrics

- Count: 31 → 32 tests
- Coverage: 19.6% → 20.3%
- Update README.md and COVERAGE.md

---

## Progress Tracking

Current status: **33/158 tests (20.9%)**

**Recent additions**:
- ✅ CharacterData-insertData (10 tests)
- ✅ CharacterData-replaceData (14 tests)

**Next priorities** (Batch 1 - already implemented):
- Element-children
- Element-firstElementChild
- Element-lastElementChild
- Element-nextElementSibling
- Element-previousElementSibling
- Element-getElementsByTagName
- Element-getElementsByClassName
- Element-removeAttribute

**Estimated effort**: 5-10 tests per hour for Batch 1 tests

---

## Tips & Best Practices

1. **Start with Batch 1** - Quick wins, validates existing code
2. **One test file at a time** - Don't batch convert, test incrementally
3. **Read the spec** - Understand WHATWG behavior, not just WPT tests
4. **Match test names** - Use exact WPT test names for traceability
5. **Document skips** - Always explain why tests are skipped
6. **Test memory** - `defer` for orphaned nodes, no `defer` for tree nodes
7. **Update coverage** - Keep metrics current
8. **Commit frequently** - One test file per commit is fine

---

**Last Updated**: 2025-10-18  
**Maintainer**: dom project
