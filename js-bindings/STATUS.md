# JavaScript Bindings - Current Status

**Last Updated**: October 21, 2025  
**Version**: 0.1.0 (Phase 2 Complete)  
**Generator Lines**: 564 lines  
**Generated Bindings**: 34.4 KB (3 interfaces)  
**Documentation**: 50,000+ words  

---

## Quick Status

### ✅ What Works Right Now

```bash
# Generate bindings for any interface
zig build js-bindings-gen -- Node
zig build js-bindings-gen -- Element
zig build js-bindings-gen -- EventTarget

# All generated code compiles
zig test js-bindings/node.zig          # ✅ PASS
zig test js-bindings/element.zig       # ✅ PASS
zig test js-bindings/eventtarget.zig   # ✅ PASS
```

### ⚠️ What's Stubbed

All functions are **stubs** that compile and export but don't execute:
- Getters return empty values (`""`, `0`, `null`)
- Setters return success but don't modify state
- Methods panic if they return non-nullable pointers

**Why**: Phase 2 validated the generator. Phase 3 adds implementation.

---

## Architecture Overview

### Design Principles

1. **Universal C-ABI** - Works with ANY JavaScript engine
2. **Opaque Pointers** - JS never sees internal structs
3. **Manual Ref Counting** - Explicit `addref`/`release`
4. **Borrowed Strings** - Returned strings owned by DOM
5. **Status Codes** - 0 = success, non-zero = error

### Type Mappings

| WebIDL | C ABI | Example |
|--------|-------|---------|
| `DOMString` | `const char*` | `"hello"` |
| `boolean` | `uint8_t` | `0` or `1` |
| `unsigned long` | `uint32_t` | `42` |
| `Node` | `DOMNode*` | opaque pointer |
| `Node?` | `DOMNode*` | `NULL` = null |

### Generated Structure

```zig
// Opaque types
pub const DOMNode = opaque {};

// Attribute getter
export fn dom_node_get_nodename(handle: *DOMNode) [*:0]const u8;

// Attribute setter  
export fn dom_node_set_nodevalue(handle: *DOMNode, value: [*:0]const u8) c_int;

// Method
export fn dom_node_appendchild(handle: *DOMNode, child: *DOMNode) *DOMNode;

// Reference counting
export fn dom_node_addref(handle: *DOMNode) void;
export fn dom_node_release(handle: *DOMNode) void;
```

---

## Current Coverage

### Interfaces Generated (3 of 34)

| Interface | Lines | Attributes | Methods | Status |
|-----------|-------|------------|---------|--------|
| EventTarget | 40 | 0 | 1 (dispatchEvent) | ✅ Compiles |
| Node | 312 | 17 | 18 | ✅ Compiles |
| Element | 419 | 19 | 21 | ✅ Compiles |

### Complex Types Handled

✅ **Skipped Gracefully**:
- Callbacks (`EventListener`)
- Unions (`(TypeA or TypeB)`)
- Dictionaries (`AddEventListenerOptions`)

Example skip comment:
```zig
// SKIPPED: addEventListener() - Contains complex types not supported in C-ABI v1
// Reason: Callback type 'EventListener', Union type '(Options or boolean)'
```

### Remaining Interfaces (31)

Priority interfaces to generate next:
1. Document, Text, Comment, CDATASection
2. CharacterData, DocumentFragment, DocumentType
3. ProcessingInstruction, Attr
4. NamedNodeMap, NodeList, HTMLCollection, DOMTokenList
5. Event, CustomEvent, AbortController, AbortSignal
6. MutationObserver, MutationRecord
7. Range, StaticRange, TreeWalker, NodeIterator
8. ShadowRoot, DocumentType, DOMImplementation

---

## Memory Management

### Reference Counting Pattern

```c
// Creating increases ref count to 1
DOMElement* elem = dom_document_create_element(doc, "div");

// Share? Increase ref count
dom_element_addref(elem);

// Done? Decrease ref count
dom_element_release(elem);  // Freed when count hits 0
```

### String Ownership Rules

**Returned Strings**: BORROWED (don't free)
```c
const char* tag = dom_element_get_tag_name(elem);
printf("%s\n", tag);  // ✅ Use immediately
// Don't free(tag) - it's owned by DOM!
```

**Input Strings**: COPIED (you still own yours)
```c
char* my_str = strdup("value");
dom_element_set_attribute(elem, "id", my_str);
free(my_str);  // ✅ OK - DOM made a copy
```

---

## Error Handling

### Status Codes

```c
int result = dom_element_set_attribute(elem, "id", "foo");
if (result != 0) {
    DOMErrorCode error = (DOMErrorCode)result;
    const char* name = dom_error_code_name(error);
    printf("Error: %s\n", name);
}
```

### Error Code Enum

```c
typedef enum {
    Success = 0,
    InvalidCharacterError = 5,
    NotFoundError = 8,
    HierarchyRequestError = 3,
    SyntaxError = 12,
    // ... 20+ more
} DOMErrorCode;
```

---

## Usage Examples

### Creating Elements

```c
DOMDocument* doc = dom_document_new();
DOMElement* div = dom_document_create_element(doc, "div");

// Set attribute
dom_element_set_attribute(div, "id", "my-div");

// Get attribute  
const char* id = dom_element_get_attribute(div, "id");

// Cleanup
dom_element_release(div);
dom_document_release(doc);
```

### Tree Traversal

```c
uint32_t count = dom_node_get_child_nodes_length(node);
for (uint32_t i = 0; i < count; i++) {
    DOMNode* child = dom_node_get_child_nodes_item(node, i);
    // Use child...
}
```

---

## Building

### Generate Bindings

```bash
# Generate for interface
zig build js-bindings-gen -- InterfaceName

# Output: js-bindings/{lowercase}.zig
```

### Compile as Library

```bash
# Static library
zig build-lib js-bindings/*.zig -O ReleaseFast
# → libjs-bindings.a

# Dynamic library
zig build-lib js-bindings/*.zig -dynamic -O ReleaseFast  
# → libjs-bindings.so / .dylib / .dll
```

### Link with C

```bash
gcc your_app.c libjs-bindings.a -o your_app
```

---

## Roadmap

### Phase 1: Research & Design ✅ COMPLETE

- [x] Browser implementation research
- [x] Architecture design
- [x] Error handling system
- [x] Documentation

**Time**: 3 hours  
**Output**: 35,000 words

### Phase 2: Code Generation ✅ COMPLETE

- [x] Generator implementation
- [x] Type mapping
- [x] Attribute generation
- [x] Method generation
- [x] Complex type handling
- [x] README documentation

**Time**: 5 hours  
**Output**: 564 lines generator + 3 interfaces

### Phase 3: Implementation ⬜ NEXT

- [ ] Replace stubs with Zig DOM calls
- [ ] Type conversions (C ↔ Zig)
- [ ] Error propagation
- [ ] Generate all 34 interfaces
- [ ] C integration test
- [ ] Engine examples

**Estimated**: 8-10 hours  
**Status**: Ready to begin

---

## Known Limitations

### Current (Phase 2)

1. ⚠️ **Stub Implementations** - Functions compile but panic or return defaults
2. ⚠️ **No Callbacks** - Event listeners must be handled at wrapper layer
3. ⚠️ **No Unions** - Methods with union types skipped
4. ⚠️ **No Dictionaries** - Options objects not supported
5. ⚠️ **Limited Coverage** - Only 3 of 34 interfaces generated

### Design Limitations (Won't Fix in V1)

1. ❌ **No Automatic GC** - Manual reference counting only
2. ❌ **No Wrapper Cache** - Engine's responsibility
3. ❌ **No JS Value Types** - Pure C-ABI only

---

## Integration Guide

### For Engine Developers

**Step 1**: Build the library
```bash
zig build-lib js-bindings/*.zig -O ReleaseFast
```

**Step 2**: Create wrapper objects in your engine
```cpp
class NodeWrapper {
    DOMNode* handle_;
public:
    NodeWrapper(DOMNode* h) : handle_(h) {
        dom_node_addref(h);
    }
    ~NodeWrapper() {
        dom_node_release(handle_);
    }
};
```

**Step 3**: Implement wrapper cache
```cpp
std::unordered_map<void*, JSObject*> cache;
```

**Step 4**: Handle events at wrapper layer
```cpp
// Store JS callbacks yourself
// Call dom_eventtarget_dispatchevent for propagation
```

---

## Testing

### Compilation Tests

```bash
$ zig test js-bindings/dom_types.zig
All 2 tests passed. ✅

$ zig test js-bindings/node.zig
All 0 tests passed. ✅

$ zig test js-bindings/element.zig  
All 0 tests passed. ✅
```

### Integration Tests

⬜ TODO (Phase 3): Create C integration test

---

## Performance

### Generator Performance

- EventTarget: ~0.1s
- Node: ~0.2s
- Element: ~0.3s

**Estimated**: 100+ interfaces/minute

### Runtime Performance

- Function calls: Direct C-ABI (zero overhead)
- Type conversions: TBD (Phase 3)
- Memory: Manual ref counting (predictable)

---

## Documentation

### Available Docs

1. **README.md** (this directory) - Complete usage guide
2. **STATUS.md** (this file) - Current status & roadmap
3. **Research** - `summaries/plans/js_bindings_research.md`
4. **Design** - `summaries/plans/js_bindings_design.md`
5. **Session Reports** - `summaries/completion/js_bindings_*.md`

### Quick Links

- [Browser Research](../summaries/plans/js_bindings_research.md)
- [Architecture Design](../summaries/plans/js_bindings_design.md)
- [Session 1 Report](../summaries/completion/js_bindings_session1.md)
- [Session 2 Report](../summaries/completion/js_bindings_session2.md)
- [Final Summary](../summaries/completion/js_bindings_final_summary.md)

---

## FAQ

### Q: Can I use this in production?

**A**: Not yet. Phase 2 is complete (generator works), but implementations are stubs. Wait for Phase 3.

### Q: Which JS engines are supported?

**A**: ALL engines that can call C functions: V8, SpiderMonkey, JSC, QuickJS, Hermes, XS, Bun, Deno, Node.js, etc.

### Q: Why no callbacks in V1?

**A**: Callbacks require bidirectional calling (JS → Zig). C-ABI makes this complex. V2 will add function pointers.

### Q: How do I add implementation?

**A**: Edit `tools/codegen/js_bindings_generator.zig` to call actual Zig DOM functions instead of returning stubs.

### Q: Can I manually edit generated files?

**A**: NO. Edit the generator, then regenerate. Manual edits will be overwritten.

### Q: How do I generate more interfaces?

**A**: `zig build js-bindings-gen -- InterfaceName` - works for any interface in dom.idl

### Q: Why are some methods skipped?

**A**: Complex types (callbacks, unions, dictionaries) aren't supported in C-ABI v1. They're skipped with comments explaining why.

---

## Contact & Contributing

### Questions?

See main project README or design documents in `summaries/plans/`

### Want to Contribute?

Phase 3 needs:
1. Implementation logic (replacing stubs)
2. Type conversion helpers
3. Integration tests
4. Engine-specific examples
5. Performance benchmarks

---

## Version History

### v0.1.0 (Current) - October 21, 2025

**Phase 2 Complete**: Working generator produces compilable bindings

- ✅ Generator: 564 lines
- ✅ Generated: 3 interfaces (34.4 KB)
- ✅ Documentation: 50,000+ words
- ✅ Tests: 100% compilation success

### v0.0.1 - October 21, 2025

**Phase 1 Complete**: Research & design

- ✅ Browser research
- ✅ Architecture design
- ✅ Error handling
- ✅ Documentation

---

**Next Milestone**: Phase 3 - Add implementation logic

**Status**: 🟢 Ready for Phase 3

**Last Updated**: October 21, 2025
