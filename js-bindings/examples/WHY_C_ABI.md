# Why js-bindings/* (C-ABI) Instead of Direct src/* Access?

## TL;DR

**You cannot call Zig functions directly from C++/V8.** Zig's native ABI is unstable and incompatible with C's ABI. The `js-bindings/` layer provides a stable C-ABI bridge.

## The Problem

### Zig's Native ABI (src/*.zig)

```zig
// src/element.zig - Native Zig API
pub const Element = struct {
    prototype: Node,           // First field (64+ bytes)
    tag_name: []const u8,      // Zig slice (16 bytes: ptr + len)
    namespace_uri: ?[]const u8, // Optional slice (16 bytes)
    attributes: StringHashMap,  // Zig HashMap struct (40+ bytes)
    // ... more fields
    
    pub fn getAttribute(self: *const Element, name: []const u8) ?[]const u8 {
        return self.attributes.get(name);
    }
};
```

**Problems:**
1. **Zig slices** (`[]const u8`) = `{ptr, len}` struct (16 bytes)
   - C++ doesn't understand this layout
   - V8 can't pass Zig slices

2. **Error unions** (`!*Element`) = discriminated union
   - C++ doesn't know how to unpack `error.OutOfMemory!*Element`
   - V8 can't handle Zig error types

3. **Optionals** (`?[]const u8`) = tagged union `{bool, value}`
   - C++ sees garbage if it reads this as a pointer
   - Memory layout is Zig-specific

4. **Struct layout** is undefined
   - Zig can reorder fields for optimization
   - Size/alignment can change between Zig versions
   - No stable memory layout guarantee

5. **Calling convention** is undefined
   - How are arguments passed? (registers? stack?)
   - How are return values handled?
   - Zig doesn't guarantee C calling convention

### What V8 Expects (C/C++ ABI)

```cpp
// V8 expects this:
typedef struct DOMElement DOMElement;  // Opaque pointer
const char* dom_element_get_tagname(DOMElement* elem);  // C function

// NOT this:
struct Element { /* ??? */ };  // Unknown layout
std::optional<std::string_view> getAttribute(...);  // Wrong types
```

## The Solution: C-ABI Bridge Layer

### js-bindings/*.zig - Stable C-ABI

```zig
// js-bindings/element.zig - C-ABI wrapper
const Element = @import("../src/element.zig").Element;

/// Opaque pointer (C-compatible)
pub const DOMElement = opaque {};

/// C-ABI function (stable calling convention)
pub export fn dom_element_get_tagname(handle: *DOMElement) [*:0]const u8 {
    // 1. Cast opaque pointer back to real Element
    const element: *const Element = @ptrCast(@alignCast(handle));
    
    // 2. Call native Zig API (returns Zig slice)
    const tag: []const u8 = element.tag_name;
    
    // 3. Convert Zig slice → C string (null-terminated pointer)
    return zigStringToCString(tag);  // Returns [*:0]const u8
}
```

**What `export` does:**
- ✅ Uses C calling convention (cdecl/stdcall)
- ✅ Generates C-compatible symbol name
- ✅ Guarantees stable ABI
- ✅ No name mangling

**What the wrapper provides:**
- ✅ Opaque pointers (just `void*`, no struct layout exposure)
- ✅ C types only (`const char*`, `int32_t`, `uint8_t`)
- ✅ Null-terminated strings (C convention)
- ✅ Error codes instead of error unions (`0` = success, `>0` = error)
- ✅ No optionals (use `NULL` instead)

## Visual Comparison

### Without C-ABI (DOESN'T WORK)

```
┌─────────────────────────┐
│   V8 (C++)              │
│                         │
│   DOMElement* elem = ...│
│   elem->tag_name ???    │  ← Can't access Zig struct!
│   elem->getAttribute??? │  ← Can't call Zig function!
└─────────────────────────┘
          ↓ ??? (Incompatible ABI)
┌─────────────────────────┐
│   src/element.zig       │
│                         │
│   pub const Element =   │
│     struct {            │
│       tag_name: []u8,   │  ← Zig slice (unknown to C++)
│       attrs: HashMap,   │  ← Zig type (unknown to C++)
│     };                  │
└─────────────────────────┘
```

### With C-ABI (WORKS)

```
┌─────────────────────────────────────┐
│   V8 (C++)                          │
│                                     │
│   DOMElement* elem = ...            │
│   const char* tag =                 │
│     dom_element_get_tagname(elem);  │  ← C function call
└─────────────────────────────────────┘
          ↓ (C ABI)
┌─────────────────────────────────────┐
│   js-bindings/element.zig           │
│                                     │
│   pub export fn                     │
│   dom_element_get_tagname(          │
│     handle: *DOMElement             │  ← Opaque pointer (C)
│   ) [*:0]const u8 {                 │  ← C string (C)
│     const elem: *Element =          │
│       @ptrCast(handle);             │
│     return toCString(               │
│       elem.tag_name                 │  ← Access Zig internals
│     );                              │
│   }                                 │
└─────────────────────────────────────┘
          ↓ (Zig ABI)
┌─────────────────────────────────────┐
│   src/element.zig                   │
│                                     │
│   pub const Element = struct {      │
│     tag_name: []const u8,           │  ← Zig slice
│     attrs: StringHashMap,           │  ← Zig HashMap
│   };                                │
└─────────────────────────────────────┘
```

## Real Example

### Native Zig API (src/element.zig)

```zig
pub fn getAttribute(self: *const Element, name: []const u8) ?[]const u8 {
    return self.attributes.get(name);
}
```

**Type signature in Zig terms:**
```zig
fn(*const Element, []const u8) ?[]const u8
//   ^^^^^^^^^^^  ^^^^^^^^^^  ^^^^^^^^^^
//   Zig pointer  Zig slice   Optional Zig slice
```

**What V8 sees if you try to call this directly:**
```cpp
// C++ has NO IDEA what this means:
??? getAttribute(???, ???) → ???
```

### C-ABI Wrapper (js-bindings/element.zig)

```zig
pub export fn dom_element_getattribute(
    handle: *DOMElement,           // Opaque pointer (C)
    qualified_name: [*:0]const u8  // C string (null-terminated)
) ?[*:0]const u8 {                 // Nullable C string
    const element: *const Element = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(qualified_name);  // C → Zig
    const value = element.getAttribute(name);          // Call native API
    return if (value) |v| zigStringToCString(v) else null;  // Zig → C
}
```

**Type signature in C terms:**
```c
const char* dom_element_getattribute(
    DOMElement* handle,      // void* (opaque)
    const char* name         // null-terminated string
);
// Returns: NULL or null-terminated string
```

**What V8 sees:**
```cpp
extern "C" const char* dom_element_getattribute(void*, const char*);
// ✅ Perfect! This is exactly what C++ expects
```

## Type Conversion Table

| Zig Type (src/*.zig) | C Type (js-bindings/*.zig) | V8/C++ Type |
|-----------------------|----------------------------|-------------|
| `[]const u8` | `[*:0]const u8` | `const char*` |
| `?[]const u8` | `?[*:0]const u8` | `const char*` (or `NULL`) |
| `!*Element` | `*DOMElement` | `DOMElement*` |
| Error union | `c_int` (0=ok, >0=err) | `int` |
| `?*Element` | `?*DOMElement` | `DOMElement*` (or `NULL`) |
| `bool` | `u8` (0/1) | `uint8_t` |
| `u32` | `u32` | `uint32_t` |
| `ArrayList(T)` | `[*]T + count` | `T* array, size_t count` |

## Why Not Extern "C" in Zig?

You might think: "Can't I just mark Zig functions as `extern "C"`?"

**No, because:**

1. **Types are still Zig types**
   ```zig
   pub extern fn getAttribute(elem: *Element, name: []const u8) ?[]const u8;
   //                                              ^^^^^^^^^^    ^^^^^^^^^^
   //                                              Still Zig slice!
   ```

2. **`extern` is for importing, not exporting**
   - `extern fn` = "this function is defined elsewhere (in C)"
   - `export fn` = "export this function to C"

3. **You'd still need type conversion**

## Couldn't We Auto-Generate the Bindings?

**Yes! And we do.**

The `tools/codegen/` directory contains code generators that:
1. Parse WebIDL specifications
2. Generate `js-bindings/*.zig` C-ABI wrappers
3. Keep everything in sync

But the generated code still needs to exist because:
- V8 needs stable C symbols to link against
- Type conversion must happen somewhere
- Error handling must be translated

## Performance Cost?

**Minimal!** The C-ABI wrapper is just type conversion:

```zig
pub export fn dom_element_get_id(handle: *DOMElement) [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const id = element.getAttribute("id") orelse return "";
    return zigStringToCString(id);
}
```

**Cost breakdown:**
- `@ptrCast`: **0 cycles** (compile-time, no runtime cost)
- `element.getAttribute()`: **Native Zig call** (same as direct)
- `zigStringToCString()`: **0-1 cycles** (usually just returns pointer)

**Total overhead: ~0-1 CPU cycles** (basically free!)

## Alternative Architectures Considered

### ❌ Alternative 1: Expose Zig Structs Directly

```cpp
struct Element {  // Try to replicate Zig layout
    Node prototype;
    const char* tag_name;  // ??? Wrong! This is a Zig slice
    // ...
};
```

**Problems:**
- Struct layout is unstable (Zig can change it)
- Can't replicate Zig slice/optional/error union layouts
- Breaks on every Zig update

### ❌ Alternative 2: C Shim Library

```c
// shim.c
const char* dom_element_get_tagname(void* elem) {
    // Call Zig from C somehow???
    // Still need a stable ABI from Zig!
}
```

**Problems:**
- Just moves the problem to C
- Still need Zig → C bridge (back to C-ABI)
- Extra complexity for no benefit

### ✅ Alternative 3: Use js-bindings/ (Current)

```zig
// js-bindings/element.zig
pub export fn dom_element_get_tagname(handle: *DOMElement) [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return zigStringToCString(element.tag_name);
}
```

**Benefits:**
- ✅ Stable C ABI
- ✅ Minimal overhead
- ✅ Type safe (Zig checks everything)
- ✅ Future proof (insulated from Zig ABI changes)
- ✅ Works with ANY language (C, C++, Rust, Python, etc.)

## Real-World Examples

Every browser does this:

### Chromium/Blink
```
V8 (C++) → Blink Bindings (C++) → Blink Core (C++)
                                   ^^^^^^^^^^^
                                   C-ABI boundary within C++
```

### Firefox/Gecko
```
SpiderMonkey (C++) → Gecko Bindings (C++) → Gecko Core (C++)
                                             ^^^^^^^^^^^
                                             XPCOM C-ABI
```

### Our Library
```
V8 (C++) → js-bindings (Zig export) → src (Native Zig)
                        ^^^^^^^^^^^^^
                        C-ABI boundary
```

## Conclusion

**You MUST use the C-ABI layer** because:

1. ✅ **Zig ABI is unstable** - not safe for FFI
2. ✅ **Type incompatibility** - Zig types ≠ C types
3. ✅ **Calling convention** - Zig doesn't guarantee C conventions
4. ✅ **Industry standard** - Every browser uses a C-ABI boundary
5. ✅ **Zero overhead** - Just pointer casts and type conversions
6. ✅ **Future proof** - Insulated from Zig ABI changes
7. ✅ **Language agnostic** - Works with any FFI-capable language

The `js-bindings/` layer is **not redundant** - it's **essential** for stable, safe, and performant FFI!

## Further Reading

- Zig's `export` keyword: https://ziglang.org/documentation/master/#export
- FFI Best Practices: https://www.chiark.greenend.org.uk/~sgtatham/coroutines.html
- C ABI Specification: https://refspecs.linuxfoundation.org/elf/x86_64-abi-0.99.pdf
- Browser Bindings Architecture: (Blink IDL/CodeGen)
