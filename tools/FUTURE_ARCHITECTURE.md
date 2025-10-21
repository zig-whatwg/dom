# Future Architecture: Multiple Code Generators

## Vision: Complete WebIDL → Multiple Targets

```
                    ┌─────────────────────────────────────┐
                    │      WebIDL Parser (Shared)        │
                    │    tools/webidl-parser/            │
                    │  (Standalone, reusable library)     │
                    └─────────────────────────────────────┘
                                    │
                                    │ AST
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
        ┌───────────────────────┐       ┌──────────────────────┐
        │  Zig Delegation Gen   │       │  JS Bindings Gen     │
        │  tools/codegen/       │       │  tools/js-bindings/  │
        │                       │       │                      │
        │  WebIDL → Zig methods │       │  WebIDL → JS↔Zig    │
        └───────────────────────┘       └──────────────────────┘
                    │                               │
                    ▼                               ▼
        ┌───────────────────────┐       ┌──────────────────────┐
        │   Zig Implementation  │◄──────│   JavaScript API     │
        │   (uses delegation)   │  FFI  │   (wraps Zig)       │
        └───────────────────────┘       └──────────────────────┘
```

## Directory Structure (Future)

```
tools/
├── README.md                     # Overview
├── ARCHITECTURE.md               # Current architecture
├── FUTURE_ARCHITECTURE.md        # This file (vision)
│
├── webidl-parser/               # 📦 Shared parser (extraction-ready)
│   ├── root.zig                 #    Used by ALL generators
│   ├── ast.zig                  #    
│   └── parser.zig               #    
│
├── codegen/                     # 🔧 Zig delegation generator
│   ├── main.zig                 #    (Priority: Phase 1 - NOW)
│   └── generator.zig            #    
│
└── js-bindings/                 # 🌐 JS bindings generator (FUTURE)
    ├── main.zig                 #    (Priority: Phase 3 - LATER)
    ├── zig-generator.zig        #    Generates export fn in Zig
    ├── js-generator.zig         #    Generates JS wrapper classes
    └── README.md                #    
```

## Phase 1: Zig Delegation (NOW) ✅

**Goal**: Enable Zig development without `.prototype` chains

```bash
zig build codegen -- Element
```

**Generates**: Delegation methods in Zig

```zig
pub inline fn appendChild(self: *Element, node: anytype) !*Node {
    return try self.prototype.appendChild(node);
}
```

**Status**: 80% complete, ~3-4 days remaining

## Phase 2: Stabilize Zig API (NEXT)

**Goal**: Complete and test core DOM implementation

- Complete all DOM interfaces
- Comprehensive test coverage
- API stability
- Performance optimization

**Status**: Ongoing, several months

## Phase 3: JS Bindings Generator (LATER)

**Goal**: Expose Zig DOM to JavaScript

### What It Would Generate

#### 3a. Zig Export Functions

```bash
zig build js-bindings -- Element
```

Generates `bindings/zig/element.zig`:

```zig
// GENERATED: JS export functions for Element
pub export fn element_getAttribute(
    ptr: *anyopaque,
    name_ptr: [*]const u8,
    name_len: usize,
    out_len: *usize,
) ?[*]const u8 {
    const elem: *Element = @ptrCast(@alignCast(ptr));
    const name = name_ptr[0..name_len];
    
    const result = elem.getAttribute(name) orelse return null;
    out_len.* = result.len;
    return result.ptr;
}

pub export fn element_setAttribute(
    ptr: *anyopaque,
    name_ptr: [*]const u8,
    name_len: usize,
    value_ptr: [*]const u8,
    value_len: usize,
) bool {
    const elem: *Element = @ptrCast(@alignCast(ptr));
    const name = name_ptr[0..name_len];
    const value = value_ptr[0..value_len];
    
    elem.setAttribute(name, value) catch return false;
    return true;
}
```

#### 3b. JavaScript Wrapper Classes

Generates `bindings/js/Element.js`:

```javascript
// GENERATED: JavaScript wrapper for Element
import { Node } from './Node.js';
import { wasm } from './runtime.js';

export class Element extends Node {
    getAttribute(name) {
        const encoder = new TextEncoder();
        const decoder = new TextDecoder();
        
        const nameBytes = encoder.encode(name);
        const namePtr = wasm.allocString(nameBytes);
        
        const outLen = new Uint32Array(1);
        const resultPtr = wasm.element_getAttribute(
            this._ptr,
            namePtr,
            nameBytes.length,
            outLen
        );
        
        wasm.freeString(namePtr);
        
        if (resultPtr === 0) return null;
        
        const resultBytes = new Uint8Array(
            wasm.memory.buffer,
            resultPtr,
            outLen[0]
        );
        return decoder.decode(resultBytes);
    }
    
    setAttribute(name, value) {
        const encoder = new TextEncoder();
        const nameBytes = encoder.encode(name);
        const valueBytes = encoder.encode(value);
        
        const namePtr = wasm.allocString(nameBytes);
        const valuePtr = wasm.allocString(valueBytes);
        
        const success = wasm.element_setAttribute(
            this._ptr,
            namePtr,
            nameBytes.length,
            valuePtr,
            valueBytes.length
        );
        
        wasm.freeString(namePtr);
        wasm.freeString(valuePtr);
        
        if (!success) {
            throw new Error('setAttribute failed');
        }
    }
}
```

### Challenges to Solve

**Memory Management**:
- JS strings → Zig strings (allocation/deallocation)
- Reference counting across boundary
- GC coordination

**Type Conversions**:
- WebIDL types → Zig types → JS types
- Null handling
- Error handling (try/catch ↔ error unions)

**Performance**:
- Minimize boundary crossings
- Batch operations
- Zero-copy where possible

## Usage Example (Future)

```javascript
// In browser or Node.js with WASM
import { Document } from '@zig-dom/bindings';

// Load WASM
await zigDOM.init();

// Use the API
const doc = new Document();
const elem = doc.createElement('div');
elem.setAttribute('id', 'foo');
elem.setAttribute('class', 'bar');

console.log(elem.getAttribute('id')); // 'foo'

doc.body.appendChild(elem);
```

## Implementation Plan (Phase 3)

### Step 1: Prototype (1-2 weeks)
- Manual bindings for 2-3 interfaces
- Prove WASM/FFI works
- Establish patterns

### Step 2: Generator (2-3 weeks)
- Build `js-bindings` generator
- Reuse WebIDL parser
- Generate Zig exports + JS wrappers

### Step 3: Runtime (1-2 weeks)
- Memory management
- String handling
- Error propagation

### Step 4: Full Coverage (2-3 weeks)
- Generate for all interfaces
- Test suite
- Documentation

**Total: 6-10 weeks** (after Zig API is stable)

## Why Wait Until Phase 3?

### Reasons to Wait:

1. **Zig API needs to stabilize** - Don't generate bindings for changing API
2. **Core DOM incomplete** - Need solid foundation first
3. **Different complexity** - FFI/WASM is separate problem domain
4. **Can test without it** - Zig tests don't need JS bindings
5. **Learn from usage** - Zig API design will inform binding design

### When to Start:

✅ Zig API is stable and feature-complete  
✅ Test coverage is comprehensive  
✅ Performance is acceptable  
✅ Memory management is solid  

**Estimated timeline: 6-12 months from now**

## Alternative: Manual Bindings (Interim)

Before generator is built, can create manual bindings for demo:

```zig
// bindings/js/manual.zig
pub export fn demo_createElement(name_ptr: [*]const u8, name_len: usize) *anyopaque {
    const allocator = // ... get allocator
    const doc = // ... get document
    const name = name_ptr[0..name_len];
    
    const elem = doc.createElement(name) catch return null;
    return @ptrCast(elem);
}
```

This validates the approach without building a full generator.

## Benefits of This Architecture

✅ **Single WebIDL parser** - Shared by all generators  
✅ **Phased approach** - Build what's needed when it's needed  
✅ **Independent tools** - Each generator is separate  
✅ **Extraction-ready** - Parser can be published separately  
✅ **Industry-proven** - Mirrors browser architecture  

## Summary

**Should we build JS bindings generator?**

**Answer**: **Yes, but Phase 3 (after Zig API is stable)**

**Current priority order:**
1. ✅ **Phase 1**: Delegation generator (NOW) - 3-4 days
2. ⏳ **Phase 2**: Complete Zig DOM (NEXT) - Several months
3. 📅 **Phase 3**: JS bindings generator (LATER) - 6-10 weeks

**The architecture supports both** - WebIDL parser is shared, generators are independent.

Build delegation generator now, plan for JS bindings later! 🎯
