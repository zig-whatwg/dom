# Deep Memory Leak Analysis

## Executive Summary

**Root Cause Identified**: Orphaned nodes (created but never inserted into tree) hold document reference counts, preventing document destruction.

## The Problem

### Test Pattern
```zig
const doc = try Document.init(allocator);
defer doc.release();

const text_node = try doc.createTextNode("Foo");  // Orphaned - never inserted
// Test ends, doc.release() called
```

### What Happens

1. **Document.init()**
   - `external_ref_count = 1`
   - `node_ref_count = 0`

2. **doc.createTextNode("Foo")**
   - Creates text node in arena
   - **Calls `acquireNodeRef()`** → `node_ref_count = 1`
   - Node is NOT inserted into tree (orphaned)

3. **Test ends: doc.release()**
   - `external_ref_count = 0`
   - `node_ref_count = 1` (orphaned node)
   - Since `node_ref_count > 0`, calls `clearInternalReferences()`

4. **clearInternalReferences()**
   - Releases `doc.node.first_child` and tree siblings
   - **BUT orphaned nodes are NOT in tree!**
   - `node_ref_count` remains 1
   - Document NOT destroyed (waiting for node_refs to reach 0)

5. **Test ends**
   - **LEAK**: Document structure, string pools, hash maps, arena
   - **LEAK**: Orphaned nodes in arena (never released)

## Why Arena Doesn't Save Us

Even though nodes are arena-allocated:
1. Arena itself is NOT freed (because Document isn't destroyed)
2. Arena's internal buffers remain allocated
3. Testing allocator sees arena buffers as leaks

## Failed Fix Attempt

Previous fix: Only call `acquireNodeRef()` on insertion (not creation).

**Why it failed:**
- WPT tests don't manually release orphaned nodes (browser GC pattern)
- Unit tests DO manually release orphaned nodes (`defer elem.node.release()`)
- Fix worked for WPT, broke unit tests

### Unit Test Pattern
```zig
const elem = try doc.createElement("div");
defer elem.node.release();  // Manual cleanup expected
```

When orphaned nodes don't hold refs:
- `elem.node.release()` decrements elem's ref_count
- Does NOT call `releaseNodeRef()` (because node wasn't inserted)
- Document never knows elem exists
- When `doc.release()` called: `node_ref_count = 0` → destroys immediately
- Arena deinit frees elem
- But unit test's `defer elem.node.release()` STILL runs afterward
- **Use-after-free!**

## The Core Conflict

Two incompatible memory management patterns:

**Pattern A: Browser GC (WPT tests)**
- Create nodes, don't manually release
- Document destroys all nodes on cleanup
- Orphaned nodes cleaned up automatically

**Pattern B: RAII (Unit tests)**
- Create nodes with `defer node.release()`
- Explicit cleanup expected
- Orphaned nodes manually released before document

**Cannot satisfy both without dual-mode memory management.**

## Potential Solutions

### Solution 1: Two-Phase Document Destruction ✅ RECOMMENDED

**Concept**: Force cleanup of orphaned nodes when external refs reach 0.

```zig
pub fn release(self: *Document) void {
    const old = self.external_ref_count.fetchSub(1, .monotonic);
    
    if (old == 1) {
        // External refs reached 0 - document is "closed"
        self.is_destroying = true;
        
        // Phase 1: Release tree nodes cleanly
        self.clearInternalReferences();
        
        // Phase 2: Force cleanup even if orphaned nodes exist
        // Orphaned nodes will be freed by arena.deinit()
        self.deinitInternal();
    }
}
```

**Pros:**
- Matches browser behavior (document destruction frees all nodes)
- WPT tests pass without changes
- Simple conceptual model

**Cons:**
- Unit tests with `defer node.release()` on orphaned nodes will use-after-free
- Need to update ALL unit tests

**Fix Strategy:**
1. Implement forced cleanup in `Document.release()`
2. Audit all unit tests for `defer node.release()` on orphaned nodes
3. Remove manual releases for orphaned nodes
4. Document that orphaned nodes are owned by document, not caller

### Solution 2: Track All Created Nodes ❌ COMPLEX

**Concept**: Maintain a list of ALL nodes (not just tree nodes).

```zig
pub const Document = struct {
    all_nodes: std.ArrayList(*Node),  // Track EVERYTHING
    // ...
};
```

**Pros:**
- Can clean up all nodes, even orphaned

**Cons:**
- Significant memory overhead
- Performance cost (O(n) for every node creation)
- Doubles memory usage (arena + list)
- Complex bookkeeping

### Solution 3: Weak References for Orphaned Nodes ❌ TOO COMPLEX

**Concept**: Orphaned nodes use weak refs, tree nodes use strong refs.

**Cons:**
- Requires complete refactor of ref counting system
- Hard to reason about
- Error-prone

### Solution 4: Accept Testing Allocator Limitation ❌ STATUS QUO

**Concept**: Document current behavior, acknowledge "leaks" are false positives.

**Cons:**
- Cognitive dissonance (tests report leaks)
- Hard to spot REAL leaks among false positives
- Not satisfying

### Solution 5: Custom Test Allocator Wrapper ⚠️ WORKAROUND

**Concept**: Wrap testing allocator to understand arena semantics.

```zig
const ArenaAwareTestAllocator = struct {
    parent: std.mem.Allocator,
    arena_buffers: std.ArrayList([]u8),
    
    // Track which allocations are arena buffers
    // Don't report arena-managed allocations as leaks
};
```

**Pros:**
- Could eliminate false positives

**Cons:**
- Complex to implement correctly
- Would need to track arena's internal state
- Fragile (depends on arena implementation details)

## Recommended Fix: Solution 1

**Two-Phase Document Destruction**

### Implementation Plan

#### Phase 1: Update Document.release() ✅

```zig
pub fn release(self: *Document) void {
    const old = self.external_ref_count.fetchSub(1, .monotonic);
    
    if (old == 1) {
        self.is_destroying = true;
        
        // Release tree nodes
        var current = self.node.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            child.parent_node = null;
            child.setHasParent(false);
            child.release();
            current = next;
        }
        
        self.node.first_child = null;
        self.node.last_child = null;
        
        // FORCE cleanup regardless of node_ref_count
        // Orphaned nodes freed by arena.deinit()
        self.deinitInternal();
    }
}
```

#### Phase 2: Update releaseNodeRef() ✅

```zig
pub fn releaseNodeRef(self: *Document) void {
    // Just decrement, don't trigger destruction
    // Document destruction is controlled by external_ref_count only
    _ = self.node_ref_count.fetchSub(1, .monotonic);
}
```

#### Phase 3: Remove clearInternalReferences() ✅

No longer needed - destruction is immediate when `external_ref_count` reaches 0.

#### Phase 4: Update Unit Tests ✅

Remove `defer node.release()` for orphaned nodes:

```zig
// BEFORE (causes use-after-free with fix)
const elem = try doc.createElement("div");
defer elem.node.release();  // ❌ Remove this

// AFTER
const elem = try doc.createElement("div");
// No defer - document owns orphaned nodes
```

#### Phase 5: Update WPT Tests ✅

Remove the one `defer text.node.release()` in testLeaf:

```zig
fn testLeaf(...) {
    const text = try doc.createTextNode("fail");
    // Remove: defer text.node.release();
    const result = node.appendChild(&text.node);
    try std.testing.expectError(error.HierarchyRequestError, result);
}
```

### Expected Results

- ✅ WPT tests: 75/75 passing, 0 leaks
- ✅ Unit tests: All passing, 0 leaks
- ✅ Clear ownership model: Document owns all nodes it creates
- ✅ Matches browser GC behavior

## Testing Plan

1. **Apply fixes incrementally**
   - Update Document.release()
   - Update releaseNodeRef()
   - Test WPT (should fix leaks)
   - Test unit tests (will show failures)

2. **Fix unit test failures**
   - Audit for `defer node.release()` on orphaned nodes
   - Remove manual releases
   - Verify all tests pass

3. **Verification**
   - Run full test suite: 0 leaks expected
   - Run with valgrind/ASAN: 0 leaks expected
   - Performance regression test: No degradation expected

## Risk Analysis

### Low Risk
- Changes are localized to Document lifecycle
- Clear before/after behavior

### Medium Risk
- Unit tests might have unexpected patterns
- Need thorough audit

### Mitigation
- Test incrementally
- Git commits for each phase
- Can revert if issues found

## Conclusion

The leaks are REAL but fixable. The root cause is clear: orphaned nodes holding refs prevent document destruction. Solution 1 (Two-Phase Destruction) is the cleanest fix that aligns with browser GC semantics.

**Recommended Action**: Implement Solution 1 with incremental testing.
