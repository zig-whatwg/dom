# CSS Selector Implementation Roadmap

## Overview

This document outlines the plan to achieve full CSS Selectors Level 4 support in the DOM implementation.

**Current Status:** ~30-40% (Basic Level 1-2 selectors only)  
**Target:** 100% (Full Level 4 support including pseudo-classes)

## Test Suite

A comprehensive test suite has been created in `src/selector_comprehensive.test.zig` with **40+ tests** covering:

- ✅ CSS Selectors Level 1 (basic selectors)
- ❌ CSS Selectors Level 2 (combinators, attribute operators)
- ❌ CSS Selectors Level 3 (structural pseudo-classes, advanced features)
- ❌ CSS Selectors Level 4 (logical combinators, relational selectors)

**Run tests:**
```bash
zig test src/selector_comprehensive.test.zig -I src/
```

## Implementation Phases

### Phase 1: CSS Selectors Level 1 ✅ COMPLETE

**Status:** Working

- [x] Type selector (`div`, `p`, `span`)
- [x] Class selector (`.class-name`)
- [x] ID selector (`#element-id`)
- [x] Universal selector (`*`)
- [x] Multiple simple selectors (`div.class#id`)

### Phase 2: CSS Selectors Level 2 - Combinators ❌ TODO

**Priority:** HIGH - Most impactful for users

#### 2.1 Descendant Combinator (space)
- [ ] Parse `div p` (descendant)
- [ ] Match elements at any nesting level
- [ ] Test: `article section p` matches nested paragraphs

#### 2.2 Child Combinator (>)
- [ ] Parse `div > p` (direct child)
- [ ] Match only immediate children
- [ ] Test: `ul > li` matches only direct list items

#### 2.3 Adjacent Sibling Combinator (+)
- [ ] Parse `h1 + p` (next sibling)
- [ ] Match immediately following sibling
- [ ] Test: `h1 + p` matches first paragraph after heading

#### 2.4 Attribute Selectors (Enhanced)
- [x] `[attr]` - presence
- [x] `[attr="value"]` - exact match
- [ ] `[attr~="value"]` - word match (space-separated)
- [ ] `[attr|="value"]` - language prefix match

### Phase 3: CSS Selectors Level 2 - Pseudo-classes ❌ TODO

**Priority:** MEDIUM

#### 3.1 Link Pseudo-classes
- [ ] `:link` - unvisited links
- [ ] `:visited` - visited links (note: security constraints)

#### 3.2 User Action Pseudo-classes
- [ ] `:hover` - mouse over (requires state tracking)
- [ ] `:active` - being activated
- [ ] `:focus` - has focus

#### 3.3 UI Element States
- [ ] `:enabled` - form controls that are enabled
- [ ] `:disabled` - form controls that are disabled
- [ ] `:checked` - checked checkboxes/radio buttons

#### 3.4 Structural Pseudo-classes
- [ ] `:first-child` - first child of parent
- [ ] `:last-child` - last child of parent

### Phase 4: CSS Selectors Level 3 - Advanced Features ❌ TODO

**Priority:** MEDIUM

#### 4.1 General Sibling Combinator (~)
- [ ] Parse `h1 ~ p` (general sibling)
- [ ] Match all siblings after element
- [ ] Test: `h1 ~ p` matches all paragraphs after h1

#### 4.2 Advanced Attribute Selectors
- [ ] `[attr^="value"]` - starts with
- [ ] `[attr$="value"]` - ends with
- [ ] `[attr*="value"]` - contains substring
- [ ] `[attr i]` - case-insensitive flag

#### 4.3 Structural Pseudo-classes (Extended)
- [ ] `:nth-child(n)` - nth child
- [ ] `:nth-child(odd)` / `:nth-child(even)`
- [ ] `:nth-child(2n+1)` - complex formulas
- [ ] `:nth-last-child(n)` - nth from end
- [ ] `:nth-of-type(n)` - nth of specific type
- [ ] `:nth-last-of-type(n)` - nth of type from end
- [ ] `:first-of-type` - first of type
- [ ] `:last-of-type` - last of type
- [ ] `:only-child` - only child of parent
- [ ] `:only-of-type` - only one of its type

#### 4.4 Content Pseudo-classes
- [ ] `:empty` - has no children

#### 4.5 Negation Pseudo-class
- [ ] `:not(selector)` - negation

### Phase 5: CSS Selectors Level 4 - Logical Combinators ❌ TODO

**Priority:** LOW (nice to have)

#### 5.1 Logical Pseudo-classes
- [ ] `:is(selector, ...)` - matches any selector
- [ ] `:where(selector, ...)` - like :is() but 0 specificity
- [ ] `:not(complex-selector)` - extended negation

#### 5.2 Relational Pseudo-classes  
- [ ] `:has(selector)` - parent selector
- [ ] `:has(> selector)` - direct child check

#### 5.3 Multiple Selectors
- [ ] Selector lists with comma: `h1, h2, h3`

#### 5.4 Additional Features
- [ ] `:any-link` - matches all links
- [ ] Case-insensitive matching improvements

## Architecture Changes Needed

### 1. Enhanced Selector Data Structure

Current structure:
```zig
pub const Selector = struct {
    selector_type: SelectorType,
    value: []const u8,
};
```

Needs to become:
```zig
pub const Selector = struct {
    selector_type: SelectorType,
    value: []const u8,
    combinator: ?Combinator,  // How this connects to next selector
    pseudo_class: ?PseudoClass,
    pseudo_args: ?[]const u8,  // For nth-child(2n+1) etc
};

pub const Combinator = enum {
    none,          // First selector in chain
    descendant,    // space
    child,         // >
    adjacent,      // +
    sibling,       // ~
};

pub const PseudoClass = enum {
    first_child,
    last_child,
    nth_child,
    // ... etc
};
```

### 2. Parser Enhancements

The selector parser needs to:
1. Handle combinator tokens (space, `>`, `+`, `~`)
2. Parse pseudo-class syntax (`:name`, `:name()`)
3. Parse pseudo-class arguments (`2n+1`, `odd`, `even`)
4. Handle selector lists with commas
5. Support complex nesting (`:not(:first-child)`)

### 3. Matcher Algorithm Redesign

Current matcher evaluates one selector at a time.

New matcher must:
1. Evaluate selector chains left-to-right
2. Track context (parent, siblings, position)
3. Handle relative relationships (child, sibling)
4. Cache computed values (child index, sibling count)
5. Support reverse traversal (for `:has()`)

### 4. State Management

Some pseudo-classes require runtime state:
- `:hover`, `:active`, `:focus` - UI interaction state
- `:visited` - browsing history (privacy constrained)
- `:checked` - form control state

Needs state tracking system integrated with Element.

## Performance Considerations

### Optimization Strategies

1. **Selector Compilation**
   - Parse selectors once, cache compiled form
   - Pre-compute selector specificity

2. **Index Structures**
   - Hash maps for ID lookups
   - Class name indexes
   - Tag name indexes

3. **Early Termination**
   - Fail fast on impossible matches
   - Short-circuit combinators

4. **Caching**
   - Cache child/sibling indices
   - Memoize expensive pseudo-class checks

## Testing Strategy

### Test Coverage Goals

- ✅ Unit tests for each selector type
- ✅ Integration tests for complex selectors
- ✅ Edge cases (empty selectors, malformed syntax)
- ⬜ Performance benchmarks
- ⬜ Comparison tests vs browser behavior

### Browser Compatibility Testing

Create test cases that match browser behavior:
- Chrome/Safari (WebKit)
- Firefox (Gecko)
- Edge (Chromium)

## Migration Path

### Backwards Compatibility

All existing selector APIs remain unchanged:
```zig
pub fn querySelector(element: *Node, selector: []const u8) !?*Node
pub fn querySelectorAll(element: *Node, selector: []const u8) !*NodeList
pub fn matches(element: *Node, selector: []const u8) !bool
```

### Progressive Enhancement

1. Existing simple selectors continue to work
2. New features added incrementally
3. Clear error messages for unsupported selectors
4. Feature detection (try selector, catch error)

## Timeline Estimate

**Aggressive:** 2-3 weeks full-time  
**Realistic:** 4-6 weeks part-time  
**Conservative:** 8-12 weeks

### Phase Breakdown

- Phase 1: ✅ Complete (basic selectors)
- Phase 2: 1-2 weeks (combinators + Level 2 pseudo)
- Phase 3: 1-2 weeks (Level 3 structural pseudo)
- Phase 4: 1 week (attribute operators)
- Phase 5: 1-2 weeks (Level 4 logical combinators)
- Testing/Polish: 1 week

## Resources

### Specifications

- [CSS Selectors Level 4](https://www.w3.org/TR/selectors-4/)
- [CSS Selectors Level 3](https://www.w3.org/TR/selectors-3/)
- [Selectors API](https://www.w3.org/TR/selectors-api/)

### Reference Implementations

- WebKit's selector engine (C++)
- Servo's selector crate (Rust)
- Deno DOM (TypeScript)

### Test Suites

- [W3C CSS Test Suite](https://github.com/web-platform-tests/wpt/tree/master/css/selectors)
- [jQuery selector tests](https://github.com/jquery/jquery/tree/main/test/unit/selector.js)

## Success Criteria

The implementation is considered complete when:

- ✅ All 40+ tests in `selector_comprehensive.test.zig` pass
- ✅ No memory leaks in test runs
- ✅ Performance is reasonable (< 1ms for typical selectors)
- ✅ Documentation is complete with examples
- ✅ Demo showcases all selector types
- ✅ README updated with feature matrix

## Contributing

This is a substantial effort! Contributions welcome:

1. Pick a phase from the roadmap
2. Implement the feature with tests
3. Submit PR with benchmarks
4. Update this roadmap

See `src/selector_comprehensive.test.zig` for test structure.

---

**Last Updated:** 2025-10-10  
**Status:** Planning Phase - Tests defined, implementation TODO
