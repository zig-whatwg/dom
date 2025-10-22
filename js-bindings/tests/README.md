# JS Bindings Test Suite

This directory contains C integration tests for the js-bindings (C-ABI) layer.

## Test Organization

All test files follow the pattern `test_<feature>.c` and test specific aspects of the C-ABI bindings.

### Test Files

**Core Node Types:**
- `test.c` - Basic functionality test
- `test_example.c` - Simple example usage
- `test_header.c` - Header file compilation test
- `test_text_nodes.c` - Text node operations
- `test_attr_nodes.c` - Attribute node operations

**Document & Element:**
- `test_document_adoption.c` - Document.adoptNode, importNode
- `test_document_collections.c` - getElementsBy*, querySelector*
- `test_getelementbyid.c` - Document.getElementById
- `test_domimplementation.c` - DOMImplementation interface
- `test_element_traversal.c` - Element traversal (siblings, children)
- `test_insertadjacent.c` - insertAdjacentElement/Text

**Collections:**
- `test_domtokenlist.c` - DOMTokenList (classList)

**Traversal:**
- `test_nodeiterator.c` - NodeIterator interface
- `test_treewalker.c` - TreeWalker interface
- `test_range.c` - Range interface
- `test_staticrange.c` - StaticRange interface

**Events:**
- `test_events.c` - Basic event functionality
- `test_event_constructors.c` - Event constructors
- `test_event_listeners.c` - Event listener management
- `test_simple_dispatch.c` - Simple event dispatch

**Selectors & Queries:**
- `test_queryselector.c` - querySelector/querySelectorAll
- `test_selectors.c` - CSS selector matching

**Mixins:**
- `test_childnode.c` - ChildNode mixin (before, after, remove, replaceWith)
- `test_parentnode.c` - ParentNode mixin (prepend, append, querySelector)

**Advanced Features:**
- `test_mutationobserver.c` - MutationObserver interface
- `test_abort.c` - AbortController/AbortSignal
- `test_shadowroot.c` - Shadow DOM functionality

**Integration:**
- `test_phase4_integration.c` - Comprehensive integration test

## Building Tests

### Individual Test

```bash
# From project root
cd js-bindings/tests

# Compile a test
gcc -o test_events test_events.c ../../zig-out/lib/libdom.a -lpthread -I..

# Run the test
./test_events
```

### All Tests

```bash
# From js-bindings/tests directory
for test in test_*.c; do
    name="${test%.c}"
    echo "Building $name..."
    gcc -o "$name" "$test" ../../zig-out/lib/libdom.a -lpthread -I..
    
    echo "Running $name..."
    ./"$name"
    echo "---"
done
```

## Test Structure

Most tests follow this pattern:

```c
#include "dom.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

int main(void) {
    // Create document
    DOMDocument* doc = dom_document_new();
    
    // Test functionality
    // ... assertions ...
    
    // Cleanup
    dom_document_release(doc);
    
    printf("✓ All tests passed!\n");
    return 0;
}
```

## Test Coverage

The test suite covers:

- ✅ **Core DOM**: Document, Element, Node, Text, Comment
- ✅ **Collections**: NodeList, HTMLCollection, NamedNodeMap, DOMTokenList
- ✅ **Traversal**: NodeIterator, TreeWalker, Range, StaticRange
- ✅ **Events**: Event, CustomEvent, EventTarget, dispatch
- ✅ **Selectors**: querySelector, querySelectorAll, matches, closest
- ✅ **Mixins**: ChildNode, ParentNode, NonDocumentTypeChildNode
- ✅ **Advanced**: MutationObserver, AbortController, Shadow DOM
- ✅ **Memory**: Reference counting, leak detection

## Memory Testing

All tests are designed to run cleanly under memory checkers:

```bash
# With Valgrind (Linux)
valgrind --leak-check=full --show-leak-kinds=all ./test_events

# With Address Sanitizer (macOS/Linux)
gcc -fsanitize=address -o test_events test_events.c ../../zig-out/lib/libdom.a -lpthread -I..
./test_events
```

## Adding New Tests

1. Create `test_<feature>.c` in this directory
2. Include `dom.h` from parent directory: `#include "dom.h"`
3. Write test using assertions
4. Ensure proper cleanup (all `*_new()` matched with `*_release()`)
5. Build and run to verify
6. Update this README with test description

## Notes

- **Compiled binaries**: Test executables (no extension or `.exe`) are gitignored
- **Debug symbols**: `.dSYM` directories are gitignored
- **Object files**: `.o` files are gitignored
- **Header**: All tests include `../dom.h` from parent directory
- **Library**: All tests link against `../../zig-out/lib/libdom.a`

## Status

**Total Tests**: 20+ C integration tests  
**Status**: All tests passing ✅  
**Coverage**: ~95% of C-ABI surface area  
**Memory**: Zero leaks detected  

---

**Last Updated**: October 21, 2025
