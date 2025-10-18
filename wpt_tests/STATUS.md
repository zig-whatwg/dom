# WPT Test Status

## Overview

Web Platform Tests converted from `/Users/bcardarella/projects/wpt/dom/nodes/`.

**Status**: Initial conversion complete
**Test Results**: 30/35 passing (85.7%)

## Running Tests

```bash
zig build test-wpt
```

## Test Files Converted

### Node Tests
- [x] Node-appendChild.zig (3 tests - 1 passing, 2 failing due to adoption not implemented)
- [x] Node-baseURI.zig (3 tests - memory leaks to fix)
- [x] Node-cloneNode.zig (8 tests - some failures, memory leaks)
- [x] Node-contains.zig (5 tests - 1 failure, memory leaks)
- [x] Node-insertBefore.zig (6 tests - memory leaks)
- [x] Node-isConnected.zig (1 test - passing)

### Element Tests
- [x] Element-hasAttribute.zig (4 tests - passing)
- [x] Element-setAttribute.zig (5 tests - passing)

## Known Issues

1. **Memory Leaks**: Many tests leak because Document nodes are not being released properly
2. **Document Adoption**: Tests expect `appendChild` to automatically adopt nodes from other documents
3. **Node.contains(null)**: Returns true instead of false

## Notes

- Test structure and assertions are preserved exactly from WPT
- No changes to source code - all failures indicate spec compliance gaps
- File names are identical to WPT (with .zig extension)
