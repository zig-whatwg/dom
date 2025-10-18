# WPT Test Status

## Overview

Web Platform Tests converted from `/Users/bcardarella/projects/wpt/dom/nodes/`.

**Status**: Second batch imported
**Test Results**: TBD (43 total tests)

## Running Tests

```bash
zig build test-wpt
```

## Test Files Converted

### Node Tests (35 tests)
- [x] Node-appendChild.zig (3 tests - 1 passing, 2 failing due to adoption not implemented)
- [x] Node-baseURI.zig (3 tests - memory leaks to fix)
- [x] Node-cloneNode.zig (8 tests - some failures, memory leaks)
- [x] Node-compareDocumentPosition.zig (8 tests - NEW)
- [x] Node-contains.zig (5 tests - 1 failure, memory leaks)
- [x] Node-insertBefore.zig (6 tests - memory leaks)
- [x] Node-isConnected.zig (1 test - passing)
- [x] Node-removeChild.zig (6 tests - NEW)
- [x] Node-replaceChild.zig (9 tests - NEW)

### Element Tests (9 tests)
- [x] Element-hasAttribute.zig (4 tests - passing)
- [x] Element-setAttribute.zig (5 tests - passing)

### Document Tests (19 tests)
- [x] Document-createElement.zig (11 tests - NEW)
- [x] Document-createTextNode.zig (8 tests - NEW)

## Known Issues

1. **Memory Leaks**: Many tests leak because Document nodes are not being released properly
2. **Document Adoption**: Tests expect `appendChild` to automatically adopt nodes from other documents
3. **Node.contains(null)**: Returns true instead of false

## Notes

- Test structure and assertions are preserved exactly from WPT
- No changes to source code - all failures indicate spec compliance gaps
- File names are identical to WPT (with .zig extension)
