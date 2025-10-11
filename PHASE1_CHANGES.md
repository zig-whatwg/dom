# Phase 1: Architecture Redesign - Changes

## Goal
Redesign selector parsing to support combinators, pseudo-classes, and advanced attribute operators.

## New Enums and Structs

### 1. Combinator Enum
```zig
pub const Combinator = enum {
    none,             // No combinator (single selector)
    descendant,       // space: "div p"
    child,            // >: "div > p"
    adjacent_sibling, // +: "h1 + p"
    general_sibling,  // ~: "h1 ~ p"
};
```

### 2. PseudoClass Enum
```zig
pub const PseudoClass = enum {
    none,
    first_child,
    last_child,
    nth_child,
    nth_last_child,
    first_of_type,
    last_of_type,
    nth_of_type,
    nth_last_of_type,
    only_child,
    only_of_type,
    empty,
    root,
    not,
    // More to come...
};
```

### 3. AttributeOperator Enum
```zig
pub const AttributeOperator = enum {
    exists,       // [attr]
    equals,       // [attr="value"]
    contains,     // [attr*="value"]
    starts_with,  // [attr^="value"]
    ends_with,    // [attr$="value"]
    word_match,   // [attr~="value"]
    lang_match,   // [attr|="value"]
};
```

### 4. SimpleSelector Struct
```zig
pub const SimpleSelector = struct {
    selector_type: SelectorType,
    value: []const u8,
    pseudo_class: PseudoClass = .none,
    pseudo_args: ?[]const u8 = null,
    attr_operator: AttributeOperator = .exists,
};
```

### 5. New Selector Struct (Complex)
```zig
pub const ComplexSelector = struct {
    parts: []SimpleSelector,
    combinators: []Combinator,
    allocator: std.mem.Allocator,
    
    pub fn deinit(self: *ComplexSelector) void {
        self.allocator.free(self.parts);
        self.allocator.free(self.combinators);
    }
};
```

## Strategy

**Keep backward compatibility during transition:**
1. Keep existing `Selector` struct and `parse()` function
2. Add new parsing functions alongside old ones
3. Update tests incrementally
4. Once all working, replace old with new

**Alternative: Big bang replacement:**
1. Replace Selector struct entirely
2. Update all callers at once
3. Run all tests to verify

**Decision: Go with Big Bang** - Cleaner, fewer intermediate states

## Implementation Steps

1. ✅ Document plan
2. Add new enums above Selector struct
3. Create SimpleSelector struct
4. Rename old Selector to LegacySelector temporarily
5. Create new ComplexSelector struct  
6. Implement new parse() for ComplexSelector
7. Update matches() to handle ComplexSelector
8. Update querySelector/querySelectorAll
9. Run tests - ensure 5 passing tests still pass
10. Remove LegacySelector code

## Files to Modify
- `src/selector.zig` - Main changes

## Testing Strategy
After each change, run:
```bash
zig test src/selector.zig -I src/
```

Ensure these tests still pass:
- test "Selector parse tag"
- test "Selector parse id"
- test "Selector parse class"
- test "matches tag selector"
- test "matches id selector"
- test "matches class selector"
- And all other existing tests
