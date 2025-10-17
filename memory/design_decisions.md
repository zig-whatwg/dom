# Design Decisions

Track architectural decisions and their rationale here.

## Two Memory Management Patterns

**Decision**: Support two node creation patterns - direct creation and Document factory.

**Pattern 1: Direct Creation**
```zig
const elem = try Element.create(allocator, "div");
defer elem.node.release();
```
- Simple, straightforward
- No string interning
- Good for tests and simple cases

**Pattern 2: Document Factory (RECOMMENDED)**
```zig
const doc = try Document.init(allocator);
defer doc.release();
const elem = try doc.createElement("div");
defer elem.node.release();
```
- Automatic string interning via `doc.string_pool`
- Better performance for repeated strings
- Recommended for production use

**Rationale**:
- Flexibility for different use cases
- Document owns string pool for interning
- Direct creation simpler for tests
- Factory pattern better for real-world usage

**Date**: 2025-10-16 (Updated 2025-10-17)

---

## Reference Counting for Nodes

**Decision**: Use reference counting (acquire/release) for Node-based objects.

**Rationale**:
- Nodes can be shared between multiple parents (rare but possible)
- DOM allows moving nodes between documents
- Simplifies memory management vs. arena allocation
- Matches browser implementation patterns

**Date**: Early project phase

---

## String Interning via Document

**Decision**: Intern strings through Document's string pool when using factory pattern.

**Implementation**:
- Document has `string_pool: StringPool` field
- Factory methods (createElement, etc.) use interned strings
- Direct creation does NOT intern strings
- String pool cleaned up when Document is released

**Rationale**:
- Tag names repeat frequently ("div", "span", "p")
- Attribute names repeat frequently ("class", "id")  
- Pointer comparison instead of string comparison (faster)
- Significant memory savings on large DOMs
- Document owns lifecycle of interned strings

**Date**: Memory optimization phase (Updated 2025-10-17)

---

*Add new design decisions as they occur. Include date, rationale, and alternatives considered.*
