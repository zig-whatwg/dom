# CSS Selector Implementation Plan

## Current Status (Session Start)

### ✅ Passing Tests (5/38)
1. `test "CSS Level 1: Type selector"` - Element type matching (`p`, `div`)
2. `test "CSS Level 1: Class selector"` - Class matching (`.container`)
3. `test "CSS Level 1: ID selector"` - ID matching (`#main`)
4. `test "CSS Level 2: Attribute presence selector [attr]"` - Attribute exists (`[disabled]`)
5. `test "CSS Level 2: Attribute equals selector [attr=value]"` - Attribute value (`[type="text"]`)

### ❌ Failing Tests (33/38)
All combinators, pseudo-classes, and advanced attribute selectors fail as expected.

### Test Suite
- **File**: `src/selector_comprehensive.test.zig`
- **Total Tests**: 38
- **Command**: `zig test src/selector_comprehensive.test.zig -I src/`
- **Memory Leaks**: 3 tests (needs investigation but not blocking)

## Implementation Phases

### Phase 1: Architecture Redesign ⏰ Estimated: 2-3 hours

**Goal**: Restructure selector parsing to support complex selectors

**Current Limitation**: 
```zig
pub const Selector = struct {
    selector_type: SelectorType,
    value: []const u8,
};
```

**New Structure Needed**:
```zig
pub const Combinator = enum {
    none,           // No combinator (single selector)
    descendant,     // space: div p
    child,          // >: div > p  
    adjacent_sibling, // +: h1 + p
    general_sibling,  // ~: h1 ~ p
};

pub const PseudoClass = enum {
    none,
    first_child,
    last_child,
    nth_child,
    nth_last_child,
    first_of_type,
    last_of_type,
    only_child,
    not,
    // ... more
};

pub const AttributeOperator = enum {
    exists,      // [attr]
    equals,      // [attr="value"]
    contains,    // [attr*="value"]
    starts_with, // [attr^="value"]
    ends_with,   // [attr$="value"]
    word_match,  // [attr~="value"]
    lang_match,  // [attr|="value"]
};

pub const SimpleSelector = struct {
    selector_type: SelectorType,
    value: []const u8,
    pseudo_class: PseudoClass = .none,
    pseudo_args: ?[]const u8 = null,
    attr_operator: AttributeOperator = .exists,
};

pub const Selector = struct {
    parts: []SimpleSelector,
    combinators: []Combinator,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *Selector) void {
        // Free allocated memory
    }
};
```

**Files to Modify**:
- `src/selector.zig` - Main implementation
- Any code calling `Selector.parse()` (likely minimal)

**Tasks**:
1. [ ] Define new enums (Combinator, PseudoClass, AttributeOperator)
2. [ ] Define SimpleSelector and new Selector struct
3. [ ] Update SelectorType enum if needed
4. [ ] Add memory management (init/deinit)
5. [ ] Update existing tests to use new structure
6. [ ] Ensure 5 passing tests still pass

### Phase 2: Combinator Support ⏰ Estimated: 4-6 hours

**Priority Order** (by usage frequency):
1. Descendant (space) - `div p`
2. Child (>) - `div > p`
3. Adjacent sibling (+) - `h1 + p`
4. General sibling (~) - `h1 ~ p`

**Implementation for Each**:

#### 2.1 Descendant Combinator (space)
- **Test**: `test "CSS Level 2: Descendant combinator (space)"`
- **Expected**: Match elements at ANY level below
- **Algorithm**:
  ```zig
  // For selector "div p":
  // 1. Find all <p> elements
  // 2. For each <p>, walk up ancestors
  // 3. If any ancestor is <div>, it's a match
  ```

#### 2.2 Child Combinator (>)
- **Test**: `test "CSS Level 2: Child combinator (>)"`
- **Expected**: Match DIRECT children only
- **Algorithm**:
  ```zig
  // For selector "div > p":
  // 1. Find all <p> elements
  // 2. For each <p>, check if parent is <div>
  // 3. If yes, it's a match
  ```

#### 2.3 Adjacent Sibling (+)
- **Test**: `test "CSS Level 2: Adjacent sibling combinator (+)"`
- **Expected**: Match immediately following sibling
- **Algorithm**:
  ```zig
  // For selector "h1 + p":
  // 1. Find all <h1> elements
  // 2. For each <h1>, get next sibling
  // 3. If next sibling is <p>, it's a match
  ```

#### 2.4 General Sibling (~)
- **Test**: `test "CSS Level 3: General sibling combinator (~)"`
- **Expected**: Match any following sibling
- **Algorithm**:
  ```zig
  // For selector "h1 ~ p":
  // 1. Find all <h1> elements
  // 2. For each <h1>, get all following siblings
  // 3. If any following sibling is <p>, it's a match
  ```

**Tasks**:
- [ ] Update parser to detect combinators (split on space, >, +, ~)
- [ ] Implement `matchesDescendant()`
- [ ] Implement `matchesChild()`
- [ ] Implement `matchesAdjacentSibling()`
- [ ] Implement `matchesGeneralSibling()`
- [ ] Update `matches()` to handle combinators
- [ ] All 4 combinator tests pass

### Phase 3: Structural Pseudo-Classes ⏰ Estimated: 6-8 hours

**Priority Order**:
1. `:first-child`
2. `:last-child`
3. `:nth-child(n)`
4. `:nth-last-child(n)`
5. `:only-child`
6. `:first-of-type`
7. `:last-of-type`
8. `:nth-of-type(n)`
9. `:nth-last-of-type(n)`
10. `:only-of-type`

**Implementation Strategy**:

Each pseudo-class needs:
1. Parser support (detect `:` and extract pseudo-class name/args)
2. Matcher function
3. Integration into main matching logic

**Example: `:first-child`**
```zig
fn matchesFirstChild(element: *Element) bool {
    const parent = element.node.parent_node orelse return false;
    const first_child = parent.first_child orelse return false;
    return first_child == element.node;
}
```

**Example: `:nth-child(n)`**
```zig
fn matchesNthChild(element: *Element, formula: []const u8) !bool {
    // Parse formula: "2n+1", "even", "odd", "3", etc.
    const index = getChildIndex(element);
    return matchesNthFormula(index, formula);
}
```

**Tasks**:
- [ ] Implement `:first-child`
- [ ] Implement `:last-child`
- [ ] Implement `:only-child`
- [ ] Implement nth formula parser
- [ ] Implement `:nth-child(n)`
- [ ] Implement `:nth-last-child(n)`
- [ ] Implement type-specific variants
- [ ] 10 pseudo-class tests pass

### Phase 4: Advanced Attribute Selectors ⏰ Estimated: 2-3 hours

**Operators to Implement**:
1. `[attr~="value"]` - Word match (already has test, currently failing)
2. `[attr^="value"]` - Starts with
3. `[attr$="value"]` - Ends with
4. `[attr*="value"]` - Contains
5. `[attr|="value"]` - Language prefix match

**Implementation**:
```zig
fn matchesAttributeOperator(
    element: *Element,
    attr_name: []const u8,
    attr_value: []const u8,
    operator: AttributeOperator
) bool {
    const actual = Element.getAttribute(element, attr_name) orelse return false;
    
    return switch (operator) {
        .exists => true,
        .equals => std.mem.eql(u8, actual, attr_value),
        .contains => std.mem.indexOf(u8, actual, attr_value) != null,
        .starts_with => std.mem.startsWith(u8, actual, attr_value),
        .ends_with => std.mem.endsWith(u8, actual, attr_value),
        .word_match => hasWord(actual, attr_value),
        .lang_match => hasLangPrefix(actual, attr_value),
    };
}
```

**Tasks**:
- [ ] Update parser to detect `~=`, `^=`, `$=`, `*=`, `|=`
- [ ] Implement each operator in matcher
- [ ] All 5 attribute operator tests pass

### Phase 5: Advanced Features ⏰ Estimated: 4-6 hours

**Features**:
1. `:not()` pseudo-class
2. Multiple selectors (comma-separated) - `h1, h2, h3`
3. `:empty` pseudo-class
4. Other Level 3/4 pseudo-classes from tests

**Implementation Complexity**:
- `:not()` requires recursive parsing and matching
- Multiple selectors require OR logic across selector groups
- Some pseudo-classes need element state (`:hover`, `:focus`) - may defer

**Tasks**:
- [ ] Implement `:not()` with recursive parsing
- [ ] Implement multiple selector support
- [ ] Implement remaining pseudo-classes
- [ ] All remaining tests pass (38/38)

## Testing Strategy

### Continuous Testing
After each phase:
```bash
zig test src/selector_comprehensive.test.zig -I src/
```

### Memory Leak Testing
```bash
zig test src/selector_comprehensive.test.zig -I src/ 2>&1 | grep "leaked"
```

### Integration Testing
Run full test suite:
```bash
zig build test
```

### Performance Testing
After implementation, test with large DOMs:
```bash
zig build run-query-demo
```

## Success Criteria

- [ ] All 38 comprehensive tests pass
- [ ] No memory leaks in selector tests
- [ ] All existing tests still pass (529+ tests)
- [ ] Performance: querySelector on 100-element DOM < 1ms
- [ ] Code is well-documented
- [ ] Examples updated to show new capabilities

## Risk Mitigation

**Risk 1**: Parser becomes too complex
- **Mitigation**: Break into smaller parser functions per feature
- **Fallback**: Use regex for initial prototyping, optimize later

**Risk 2**: Performance degrades with complex selectors
- **Mitigation**: Profile early, optimize hot paths
- **Fallback**: Add selector complexity limits

**Risk 3**: Memory management becomes error-prone
- **Mitigation**: Comprehensive testing with GPA
- **Fallback**: Simplify allocator usage, document ownership

## Next Steps

1. **Immediate**: Start Phase 1 (Architecture Redesign)
2. **Today's Goal**: Complete Phase 1 + Phase 2.1 (descendant combinator)
3. **Session Goal**: Get combinators working (Phase 2 complete)

## Questions to Answer

- How should we handle case sensitivity in selectors?
- Should we support CSS4 `:is()` and `:where()`?
- What's the max selector complexity we should support?
- Should we cache parsed selectors for performance?
