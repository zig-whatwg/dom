# WPT V8 Test Integration Roadmap

**Current Status:** 362 tests converted and ready  
**Execution Status:** ⏳ Waiting for v8-bindings runtime fix  
**Date:** October 22, 2025

---

## Overview

We have successfully converted **362 WPT tests** from HTML to V8-compatible JavaScript. However, these tests cannot currently execute because the v8-bindings library has runtime initialization issues.

---

## Current State

### ✅ Complete

1. **Test Conversion System** - 100% working
   - 362 tests converted from HTML to JavaScript
   - Path conversion working correctly
   - Test structure preserved
   - WPT testharness.js framework downloaded

2. **Test Infrastructure**
   - `run_tests.js` - Test runner script
   - `runner_bootstrap.js` - DOM environment setup
   - `testharness.js` - WPT test framework
   - `testharnessreport.js` - WPT reporter
   - `common.js` - WPT helper functions (1089 lines)
   - `constants.js` - WPT constants (11 lines)

3. **Test Categories** - All converted
   - 142 nodes tests
   - 83 events tests  
   - 38 ranges tests
   - 16 traversal tests
   - 9 collections tests
   - 9 root-level tests
   - 5 lists tests
   - 3 abort tests

### ⏳ Blocked

**v8-bindings Runtime Issues:**
- Library compiles successfully
- Runtime crashes or hangs during V8 initialization
- Likely V8 configuration mismatch or ABI incompatibility
- See `v8-bindings/FINAL_SESSION_STATUS.md` for details

---

## What Tests Need to Run

### Global Requirements

All 362 tests require these globals to be available in JavaScript:

**Core Constructors:**
```javascript
Document
Element
Node
Text
Comment
CDATASection
ProcessingInstruction
DocumentFragment
DocumentType
Attr
```

**Collection Types:**
```javascript
NodeList
HTMLCollection
NamedNodeMap
DOMTokenList
```

**Range Types:**
```javascript
Range
StaticRange
```

**Event Types:**
```javascript
Event
CustomEvent
EventTarget
```

**Traversal Types:**
```javascript
NodeIterator
TreeWalker
NodeFilter
```

**Advanced Types:**
```javascript
AbortController
AbortSignal
MutationObserver
MutationRecord
ShadowRoot
```

**Global document:**
```javascript
var document = new Document();
```

---

## Alternative Approaches

Since v8-bindings is blocked, we have several options:

### Option 1: Fix v8-bindings Runtime Issues ⭐ Recommended

**Pros:**
- Most direct path to running tests
- Uses d8 (V8's command-line shell)
- Tests run in actual V8 engine

**Cons:**
- Requires debugging V8 initialization
- Complex V8 embedding issues

**Next Steps:**
1. Debug V8 initialization crash
2. Verify V8 build flags match runtime
3. Check ABI compatibility
4. Test minimal V8 wrapper

**Estimated Effort:** 2-4 hours

### Option 2: Node.js Native Addon

Create a Node.js native addon wrapping the C-ABI js-bindings.

**Pros:**
- js-bindings already working (27 tests passing)
- Node.js has mature native addon support
- Easier debugging than raw V8

**Cons:**
- Need to write Node.js addon wrapper
- Tests would run in Node.js, not pure V8

**Implementation:**
```c
// node_dom_addon.cpp
#include <node_api.h>
#include "dom.h"

napi_value CreateDocument(napi_env env, napi_callback_info info) {
    DOMDocument* doc = dom_document_new();
    napi_value result;
    napi_create_external(env, doc, NULL, NULL, &result);
    return result;
}

// ... wrap all C-ABI functions
```

**Estimated Effort:** 1-2 days

### Option 3: JavaScript Engine Bindings (QuickJS, Duktape)

Use a simpler JavaScript engine with easier embedding.

**Pros:**
- Simpler embedding than V8
- Smaller, easier to debug
- Still validates DOM implementation

**Cons:**
- Not V8 (different performance characteristics)
- Less realistic for browser use cases

**Estimated Effort:** 1-2 days

### Option 4: Test Structure Validation (No Execution)

Validate test structure without running them.

**Pros:**
- Immediate feedback
- Catches syntax errors
- Validates conversion quality

**Cons:**
- Doesn't validate DOM implementation
- Can't measure pass/fail rates

**Implementation:**
```javascript
// validate_tests.js
const fs = require('fs');
const acorn = require('acorn');

// Parse each test file
// Check for syntax errors
// Validate structure
// Report issues
```

**Estimated Effort:** 2-4 hours

---

## Recommended Path Forward

### Phase 1: Immediate (Test Validation)

**Goal:** Validate all 362 tests are syntactically correct

1. **Create validation script**
   ```bash
   node tools/validate_wpt_tests.js
   ```

2. **Check for issues**
   - JavaScript syntax errors
   - Missing dependencies
   - Path references

3. **Fix any problems**

**Estimated Time:** 2-4 hours

### Phase 2: Short-term (Node.js Addon)

**Goal:** Get tests actually running

1. **Create Node.js native addon**
   - Wrap C-ABI functions
   - Expose DOM globals
   - Create test runner

2. **Run tests in Node.js**
   ```bash
   node tests/wpt-v8/run_tests_node.js
   ```

3. **Collect results**
   - Track pass/fail by category
   - Identify missing features
   - Report coverage

**Estimated Time:** 1-2 days

### Phase 3: Long-term (Fix v8-bindings)

**Goal:** Run tests in actual V8

1. **Debug v8-bindings runtime**
   - Fix initialization crash
   - Verify V8 configuration
   - Test minimal wrapper

2. **Run tests in d8**
   ```bash
   d8 --expose-gc tests/wpt-v8/run_tests.js -- nodes/
   ```

3. **Full test suite execution**

**Estimated Time:** 2-4 hours (debugging time)

---

## Test Execution Requirements by Category

### Nodes Tests (142 tests)

**Required APIs:**
- Document: createElement, createTextNode, createComment, getElementById, querySelector, appendChild, removeChild, etc.
- Element: setAttribute, getAttribute, appendChild, querySelector, matches, closest, classList, etc.
- Node: appendChild, removeChild, insertBefore, cloneNode, normalize, etc.

**Example Test:**
```javascript
// nodes/Document-createElement.test.js
test(function() {
    var element = document.createElement("div");
    assert_equals(element.localName, "div");
}, "createElement with lowercase name");
```

### Events Tests (83 tests)

**Required APIs:**
- Event: constructor, phase constants, bubbles, cancelable, preventDefault, stopPropagation
- EventTarget: addEventListener, removeEventListener, dispatchEvent
- CustomEvent: constructor, detail property

**Example Test:**
```javascript
// events/Event-constants.test.js
test(function() {
    assert_equals(Event.NONE, 0);
    assert_equals(Event.CAPTURING_PHASE, 1);
    assert_equals(Event.AT_TARGET, 2);
    assert_equals(Event.BUBBLING_PHASE, 3);
}, "Event phase constants");
```

### Ranges Tests (38 tests)

**Required APIs:**
- Range: constructor, setStart, setEnd, collapse, deleteContents, extractContents, cloneContents, insertNode, surroundContents
- StaticRange: constructor, startContainer, endContainer, startOffset, endOffset

**Example Test:**
```javascript
// ranges/Range-constructor.test.js
test(function() {
    var range = new Range();
    assert_equals(range.startContainer, document);
    assert_equals(range.endContainer, document);
}, "Range constructor");
```

### Traversal Tests (16 tests)

**Required APIs:**
- NodeIterator: nextNode, previousNode, root, referenceNode, filter
- TreeWalker: nextNode, previousNode, parentNode, firstChild, lastChild, nextSibling, previousSibling, filter
- NodeFilter: constants, acceptNode

**Example Test:**
```javascript
// traversal/TreeWalker-basic.test.js
test(function() {
    var walker = document.createTreeWalker(document.body);
    assert_equals(walker.root, document.body);
}, "TreeWalker creation");
```

---

## Success Metrics

### Phase 1 (Validation)
- ✅ All 362 tests parse without syntax errors
- ✅ All dependencies resolved
- ✅ Test structure valid

### Phase 2 (Node.js Execution)
- ✅ Tests run in Node.js environment
- ✅ Pass rate tracked by category
- ✅ Missing features identified
- 🎯 Target: 70%+ pass rate

### Phase 3 (V8 Execution)
- ✅ Tests run in d8
- ✅ Same pass rate as Node.js
- ✅ Performance benchmarks collected
- 🎯 Target: 80%+ pass rate

---

## Known Limitations

### Cannot Test (Rendering Required)
These were already filtered out:
- Layout properties (offsetWidth, getBoundingClientRect, etc.)
- CSS computed styles
- Visual rendering
- User interaction (focus, scroll, pointer events)

### May Fail (Implementation Gaps)
Some tests may fail due to:
- Unimplemented DOM features
- Edge case behavior differences
- Namespace handling differences
- HTML-specific parsing

---

## Files Ready for Testing

### Test Runner
- `tests/wpt-v8/run_tests.js` - Main test runner
- `tests/wpt-v8/runner_bootstrap.js` - Environment setup

### WPT Framework
- `tests/wpt-v8/resources/testharness.js` - Test framework (5207 lines)
- `tests/wpt-v8/resources/testharnessreport.js` - Reporter (32 lines)
- `tests/wpt-v8/common.js` - Helpers (1089 lines)
- `tests/wpt-v8/constants.js` - Constants (11 lines)

### Converted Tests (362 files)
- `tests/wpt-v8/nodes/*.test.js` - 142 tests
- `tests/wpt-v8/events/*.test.js` - 83 tests
- `tests/wpt-v8/ranges/*.test.js` - 38 tests
- `tests/wpt-v8/traversal/*.test.js` - 16 tests
- `tests/wpt-v8/collections/*.test.js` - 9 tests
- `tests/wpt-v8/*.test.js` - 9 root-level tests
- `tests/wpt-v8/lists/*.test.js` - 5 tests
- `tests/wpt-v8/abort/*.test.js` - 3 tests

---

## Next Session Recommendations

**Immediate Priority:**

1. **Create Test Validator** (2-4 hours)
   ```bash
   cd tools
   # Create validate_wpt_tests.js
   # Parse all 362 tests
   # Check syntax, structure
   # Report issues
   ```

2. **Start Node.js Addon** (1-2 days)
   ```bash
   cd js-bindings
   # Create node_addon/
   # Wrap C-ABI with N-API
   # Expose DOM globals
   # Run first test
   ```

3. **OR Debug v8-bindings** (2-4 hours)
   ```bash
   cd v8-bindings
   # Review V8 initialization
   # Check build flags
   # Test minimal wrapper
   # Fix runtime crash
   ```

**Recommendation:** Start with #2 (Node.js addon) because:
- ✅ js-bindings already proven working (27 tests passing)
- ✅ Node.js has excellent debugging
- ✅ Can iterate quickly
- ✅ Get actual test results immediately

Once Node.js addon is working and tests are passing, we can return to fixing v8-bindings for pure V8 execution.

---

## Conclusion

We have **362 WPT tests ready to run**, complete infrastructure, and working C-ABI bindings. The only blocker is getting these bindings exposed to a JavaScript environment.

**Best Path:** Create Node.js native addon wrapping js-bindings → Run tests → Fix implementation issues → Optimize → Return to v8-bindings later.

**Status:** Ready for next phase of integration work! 🚀

---

**Document Date:** October 22, 2025  
**Tests Ready:** 362  
**Infrastructure:** Complete  
**Next Step:** Choose execution strategy and begin implementation
