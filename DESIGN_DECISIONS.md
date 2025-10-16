# Design Decisions

This document explains key architectural and API design decisions made in this WHATWG DOM implementation.

## Table of Contents

- [Why Properties Are Functions](#why-properties-are-functions)
- [Memory Management Strategy](#memory-management-strategy)
- [Node Size Target (96 bytes)](#node-size-target-96-bytes)
- [Vtable-Based Polymorphism](#vtable-based-polymorphism)
- [String Interning](#string-interning)

---

## Why Properties Are Functions

**Question**: Why is `baseURI`, `nodeName`, etc. implemented as functions instead of struct fields?

**Answer**: Performance, memory efficiency, and Zig idioms.

### The Issue

In JavaScript DOM, you access properties like this:
```javascript
node.baseURI        // Looks like a property
node.nodeName       // Looks like a property
```

In this Zig implementation, they're functions:
```zig
node.baseURI()      // Function call
node.nodeName()     // Function call
```

### Rationale

#### 1. Computed vs Stored Values

DOM properties fall into two categories:

**Stored (Direct Field Access)**:
```zig
node.parent_node       // Simple pointer dereference (~1ns)
node.first_child       // Direct field access
node.next_sibling      // Just reading a pointer
```

**Computed (Requires Calculation)**:
```zig
node.nodeName()        // Vtable dispatch to get correct name (~5ns)
node.baseURI()         // Might walk up tree, check attributes (~10ns-1µs)
node.textContent()     // Traverses entire subtree (~1µs-1ms)
```

If we made computed properties into fields, we'd need to:
- Update them every time the tree changes (expensive)
- Store them even when never accessed (memory waste)
- Keep them synchronized (complexity)

#### 2. Memory Efficiency

Storing computed values would bloat Node:

```zig
// BAD: Everything as fields
pub const Node = struct {
    parent_node: ?*Node,           // 8 bytes (necessary)
    first_child: ?*Node,           // 8 bytes (necessary)
    
    node_name: []const u8,         // +16 bytes (can be computed!)
    node_value: ?[]const u8,       // +16 bytes (can be computed!)
    base_uri: []const u8,          // +16 bytes (can be computed!)
    text_content: []const u8,      // +16 bytes (can be computed!)
    
    // Node would be ~200 bytes instead of 96!
};
```

**Current approach (efficient)**:
```zig
// GOOD: Only stored fields, compute the rest
pub const Node = struct {
    parent_node: ?*Node,           // 8 bytes
    first_child: ?*Node,           // 8 bytes
    // ... other necessary fields
    
    // Computed on demand (no storage cost)
    pub fn nodeName(self: *const Node) []const u8 {
        return self.vtable.node_name(self);  // Vtable dispatch
    }
    
    pub fn baseURI(self: *const Node) []const u8 {
        // Walk up tree, check for xml:base, return document URL
        // Only computed when accessed
    }
};
// Node is exactly 96 bytes
```

**Savings**: 104 bytes per node × millions of nodes = hundreds of MB saved!

#### 3. Polymorphic Behavior

Some properties return different values based on node type:

```zig
// Element node
elem.nodeName()  // Returns "div", "span", etc.

// Text node
text.nodeName()  // Returns "#text"

// Comment node
comment.nodeName()  // Returns "#comment"
```

This requires **runtime dispatch** via vtable:

```zig
pub fn nodeName(self: *const Node) []const u8 {
    return self.vtable.node_name(self);  // Calls correct implementation
}
```

This can't be a simple field - it needs to be a function.

#### 4. Zig Language Idioms

Zig makes performance characteristics explicit:

```zig
node.parent_node     // Field access → always O(1), very cheap
node.nodeName()      // Function call → might be O(n), check the docs
```

This explicitness is **intentional design** in Zig. The language doesn't hide costs.

Compare to other languages:
- **C++**: Can use operator overloading to hide function calls (bad for perf)
- **Python**: Properties look like fields but call functions (hidden cost)
- **Zig**: Function calls look like function calls (explicit cost)

#### 5. JavaScript Binding Layer

**Important**: The bindings layer should hide this implementation detail!

In JavaScript, use property descriptors:

```javascript
Object.defineProperty(Node.prototype, 'nodeName', {
  get: function() {
    return zig_node_nodeName(this._zigPtr);  // Calls Zig function
  }
});

// Now JavaScript users see:
node.nodeName  // Looks like a property!
```

### Comparison: Stored vs Computed

| Property | Type | Zig Access | JS Access | Cost |
|----------|------|------------|-----------|------|
| `parent_node` | Stored | `node.parent_node` | `node.parentNode` | ~1ns |
| `first_child` | Stored | `node.first_child` | `node.firstChild` | ~1ns |
| `nodeName` | Computed | `node.nodeName()` | `node.nodeName` | ~5ns |
| `baseURI` | Computed | `node.baseURI()` | `node.baseURI` | ~10ns-1µs |
| `textContent` | Computed | `node.textContent()` | `node.textContent` | ~1µs-1ms |

### Industry Standard

This approach is **standard practice** in systems languages:

- **Rust** (servo): `node.node_name()` is a function
- **C++** (Blink, WebKit): `node->nodeName()` is a function
- **Swift** (WebKit): `node.nodeName` is a computed property

Only at the **JavaScript bindings layer** do they appear as properties.

### Conclusion

**Zig API**: Explicit, efficient, idiomatic
```zig
node.nodeName()      // Function call (explicit)
node.parent_node     // Field access (explicit)
```

**JavaScript API**: Ergonomic, familiar
```javascript
node.nodeName        // Property (actually calls Zig function)
node.parentNode      // Property (actually reads Zig field)
```

**Best of both worlds**: Zig optimizes, JavaScript provides ergonomics.

See [JS_BINDINGS.md](JS_BINDINGS.md) for complete implementation guide.

---

## Memory Management Strategy

### Reference Counting

**Decision**: Use reference counting with weak parent pointers.

**Why**:
- Deterministic cleanup (no GC pauses)
- Works with any allocator
- Thread-safe (atomic operations)
- Prevents cycles (weak parent pointers)

**Alternative considered**: Garbage collection
- **Rejected**: Would tie us to a specific GC, limit use cases

### Dual Reference Counting (Document Only)

Documents use two reference counts:
- External refs (from application code)
- Internal node refs (from owned nodes)

**Why**: Document must outlive its nodes, but nodes shouldn't keep document alive forever.

---

## Node Size Target (96 bytes)

**Decision**: Keep Node struct at ≤96 bytes.

**Why**:
- Fits in 2 cache lines (typical cache line = 64 bytes)
- Allows millions of nodes in memory efficiently
- Room for future additions without breaking the budget

**How**:
- Pack `ref_count` + `has_parent` into single u32
- Use weak pointers (no cycles)
- Defer rarely-used data to `NodeRareData`
- Compute properties on demand (don't store)

---

## Vtable-Based Polymorphism

**Decision**: Use vtable pointers for polymorphic behavior.

**Why**:
- Allows different node types (Element, Text, Comment, etc.)
- Small overhead (8 bytes per node)
- Fast dispatch (single indirect call)
- Extensible (users can add custom node types)

**Alternative considered**: Tagged unions
- **Rejected**: Would limit extensibility, increase code duplication

---

## String Interning

**Decision**: Intern strings per-document (tag names, attribute names).

**Why**:
- Tag names repeated frequently ("div", "span", etc.)
- Reduces memory usage (pointer instead of full string)
- Faster comparisons (pointer equality instead of string comparison)

**Trade-off**: Adds complexity, but worth it for memory savings.

---

## Summary

All design decisions prioritize:
1. **Performance** - Explicit costs, cache-friendly, minimal allocations
2. **Memory efficiency** - 96-byte nodes, string interning, computed properties
3. **Correctness** - 100% spec compliance, zero memory leaks
4. **Extensibility** - Vtables allow custom node types
5. **Ergonomics** - At the bindings layer, not in the core library

The Zig API is optimized for **systems programming**.  
JavaScript bindings provide **developer ergonomics**.

This separation of concerns allows the best of both worlds.
