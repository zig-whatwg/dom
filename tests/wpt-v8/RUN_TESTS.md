# Running WPT V8 Tests

## Current Status

The V8 bindings are built and can load JavaScript files. However, the full WPT testharness.js framework requires DOM APIs that are not yet fully implemented in the v8-bindings:

- `document.getElementsByTagName()` - Not exposed in v8-bindings yet
- Full EventTarget implementation on Window
- Various other browser APIs

## How to Run Tests

### Using the Custom Test Runner

A custom C++ test runner has been created at `v8-bindings/wpt_test_runner`. This runner:

1. Initializes V8 with DOM bindings
2. Creates a document with basic setup
3. Provides stub window/self/addEventListener functions
4. Loads and executes JavaScript test files

Build the runner:

```bash
cd v8-bindings
clang++ -std=c++20 wpt_test_runner.cpp \
  -I./include -I../js-bindings -I/opt/homebrew/Cellar/v8/13.5.212.10/libexec/include \
  -DV8_COMPRESS_POINTERS -DV8_31BIT_SMIS_ON_64BIT_ARCH -DV8_ENABLE_SANDBOX \
  -L./lib -lv8dom \
  -L../zig-out/lib -ldom \
  -L/opt/homebrew/lib -lv8 -lv8_libplatform \
  -lpthread -Wl,-undefined,dynamic_lookup \
  -o wpt_test_runner
```

Run a test:

```bash
./v8-bindings/wpt_test_runner \
  tests/wpt-v8/runner_bootstrap.js \
  tests/wpt-v8/resources/testharness.js \
  tests/wpt-v8/attributes-are-nodes.test.js
```

## Missing v8-bindings Features

To fully support WPT tests, the v8-bindings need:

1. **Document methods**:
   - `getElementsByTagName(name)` 
   - `getElementsByClassName(className)`
   - `querySelector(selector)`
   - `querySelectorAll(selector)`

2. **Element methods**:
   - `querySelector(selector)`
   - `querySelectorAll(selector)`
   - `getElementsByClassName(className)`
   - `getElementsByTagName(name)`

3. **Node properties**:
   - `nodeType` getter
   - `nodeName` getter  
   - `textContent` getter/setter

4. **EventTarget** (on Document and Element):
   - `addEventListener(event, callback, options)`
   - `removeEventListener(event, callback, options)`
   - `dispatchEvent(event)`

5. **Attr** interface exposure

## Next Steps

To make tests runnable, choose one of:

### Option 1: Extend v8-bindings (Recommended)

Add the missing wrappers to v8-bindings for Document and Element query methods. These are already implemented in the Zig DOM C-ABI at `js-bindings/`, they just need V8 wrappers.

See `v8-bindings/src/nodes/document_wrapper.cpp` and `v8-bindings/src/nodes/element_wrapper.cpp`.

### Option 2: Create Minimal Test Harness

Create a simpler test framework (not WPT testharness.js) that works with the current v8-bindings API. This would be a custom `minitest.js` that provides:

```javascript
function test(fn, name) {
  try {
    fn();
    console.log('✓ PASS:', name);
  } catch (e) {
    console.log('✗ FAIL:', name, e.message);
  }
}

function assert_true(condition, message) {
  if (!condition) throw new Error(message || 'assert_true failed');
}

function assert_equals(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(`${message || 'assert_equals failed'}: expected ${expected}, got ${actual}`);
  }
}

// ... more assertions
```

### Option 3: Use Direct C++ Tests

Continue using the existing C++ test files in `v8-bindings/` which test the bindings directly without requiring full WPT infrastructure.

## Current Test Runner Features

The wpt_test_runner provides:

- ✅ V8 initialization with DOM bindings
- ✅ Global `document` object
- ✅ `console.log()` / `console.error()`
- ✅ `print()` function (d8 compatibility)
- ✅ `load(filename)` function to load JS files
- ✅ `quit(code)` function to exit
- ✅ `self` and `window` pointing to global
- ✅ Stub `addEventListener`/`removeEventListener`/`dispatchEvent`
- ✅ Stub `setTimeout`/`setInterval` (synchronous execution)
- ✅ `document.body` element

Missing:
- ❌ Full WPT testharness.js support (needs more DOM APIs)
- ❌ Async test support
- ❌ Test result aggregation
