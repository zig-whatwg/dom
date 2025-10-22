# WPT-V8 Integration Status

## Summary

The V8 bindings are **partially working** but need additional DOM API wrappers to support the full WPT test suite.

## What's Working ✅

1. **V8 Bindings Library** (`v8-bindings/lib/libv8dom.a`)
   - Compiles successfully
   - Includes wrappers for: Node, Document, Element, Text, CharacterData, Event
   - Wrapper caching and GC integration working
   - Basic tree manipulation working

2. **Test Runner** (`v8-bindings/wpt_test_runner`)
   - Custom C++ program that embeds V8 + DOM
   - Provides: `console.log`, `print`, `load`, `quit`, `document`, `self`, `window`
   - Can load and execute JavaScript files
   - Has stubs for: `addEventListener`, `setTimeout`, `setInterval`

3. **Basic DOM Operations**
   - `document.createElement(tagName)` ✅
   - `document.createTextNode(data)` ✅
   - `element.appendChild(child)` ✅
   - `node.parentNode` ✅
   - `element.id` getter/setter ✅
   - `element.className` getter/setter ✅

## What's Missing ❌

The WPT testharness.js requires these DOM APIs that are **NOT yet wrapped** in v8-bindings:

### Critical Missing APIs

1. **Document Query Methods**
   ```javascript
   document.getElementById(id)           // ❌ Not wrapped
   document.getElementsByTagName(name)   // ❌ Not wrapped
   document.getElementsByClassName(name) // ❌ Not wrapped
   document.querySelector(selector)      // ❌ Not wrapped
   document.querySelectorAll(selector)   // ❌ Not wrapped
   ```

2. **Element Query Methods**
   ```javascript
   element.querySelector(selector)       // ❌ Not wrapped
   element.querySelectorAll(selector)    // ❌ Not wrapped
   element.getElementsByTagName(name)    // ❌ Not wrapped
   element.getElementsByClassName(name)  // ❌ Not wrapped
   ```

3. **Node Properties**
   ```javascript
   node.nodeType         // ❌ Not wrapped
   node.nodeName         // ❌ Not wrapped
   node.textContent      // ❌ Not wrapped
   node.firstChild       // ❌ Not wrapped
   node.lastChild        // ❌ Not wrapped
   node.nextSibling      // ❌ Not wrapped
   node.previousSibling  // ❌ Not wrapped
   ```

4. **EventTarget Methods** (for Document/Element)
   ```javascript
   element.addEventListener(event, fn)     // ❌ Not wrapped
   element.removeEventListener(event, fn)  // ❌ Not wrapped
   element.dispatchEvent(event)            // ❌ Not wrapped
   ```

5. **Attr Interface**
   ```javascript
   document.createAttribute(name)  // ❌ Not wrapped
   // Attr constructor not exposed   // ❌ Not exposed
   ```

## The Core Problem

**The Zig DOM C-ABI (`js-bindings/`) HAS these functions implemented**, but the **V8 wrappers (`v8-bindings/src/`) haven't been written yet**.

For example:
- ✅ C-ABI has: `dom_document_get_element_by_id(doc, id)`  
- ❌ V8 wrapper missing: `DocumentWrapper::GetElementById()`

## How to Fix

### Step 1: Add Missing Wrappers to `v8-bindings/src/nodes/document_wrapper.cpp`

```cpp
// In DocumentWrapper::Install()
tmpl->Set(
    isolate,
    "getElementById",
    v8::FunctionTemplate::New(isolate, GetElementById)
);

// Add callback function
void DocumentWrapper::GetElementById(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    // Get 'this' (Document)
    DOMDocument* doc = UnwrapDocument(args.Holder());
    
    // Get argument (id string)
    v8::String::Utf8Value id(isolate, args[0]);
    
    // Call C-ABI
    DOMElement* elem = dom_document_get_element_by_id(doc, *id);
    
    if (!elem) {
        args.GetReturnValue().SetNull();
        return;
    }
    
    // Wrap result
    v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, elem);
    args.GetReturnValue().Set(wrapper);
}
```

### Step 2: Add Similar Wrappers for Other Methods

Follow the same pattern for:
- `document.getElementsByTagName()`
- `document.getElementsByClassName()`
- `document.querySelector()`
- `document.querySelectorAll()`

### Step 3: Add Element Query Methods

In `v8-bindings/src/nodes/element_wrapper.cpp`, add:
- `element.querySelector()`
- `element.querySelectorAll()`
- etc.

### Step 4: Add Node Properties

In `v8-bindings/src/nodes/node_wrapper.cpp`, add getters for:
- `nodeType`
- `nodeName`
- `textContent`
- `firstChild`, `lastChild`, `nextSibling`, `previousSibling`

### Step 5: Rebuild and Test

```bash
cd v8-bindings
make -f Makefile.minimal clean
make -f Makefile.minimal

# Rebuild test runner
clang++ -std=c++20 wpt_test_runner.cpp \
  -I./include -I../js-bindings -I/opt/homebrew/Cellar/v8/13.5.212.10/libexec/include \
  -DV8_COMPRESS_POINTERS -DV8_31BIT_SMIS_ON_64BIT_ARCH -DV8_ENABLE_SANDBOX \
  -L./lib -lv8dom -L../zig-out/lib -ldom \
  -L/opt/homebrew/lib -lv8 -lv8_libplatform \
  -lpthread -Wl,-undefined,dynamic_lookup \
  -o wpt_test_runner

# Test
./wpt_test_runner \
  ../tests/wpt-v8/runner_bootstrap.js \
  ../tests/wpt-v8/resources/testharness.js \
  ../tests/wpt-v8/attributes-are-nodes.test.js
```

## Files to Modify

1. `v8-bindings/src/nodes/document_wrapper.h` - Add method declarations
2. `v8-bindings/src/nodes/document_wrapper.cpp` - Implement wrappers
3. `v8-bindings/src/nodes/element_wrapper.h` - Add method declarations  
4. `v8-bindings/src/nodes/element_wrapper.cpp` - Implement wrappers
5. `v8-bindings/src/nodes/node_wrapper.h` - Add property declarations
6. `v8-bindings/src/nodes/node_wrapper.cpp` - Implement property getters
7. `v8-bindings/Makefile.minimal` - May need to add new source files

## Available C-ABI Functions

Check `js-bindings/*.h` for available functions. All are prefixed with `dom_*`:

```c
// From js-bindings/document.h
DOMElement* dom_document_get_element_by_id(DOMDocument* doc, const char* id);
DOMNodeList* dom_document_get_elements_by_tag_name(DOMDocument* doc, const char* tag);
DOMElement* dom_document_query_selector(DOMDocument* doc, const char* selector);

// From js-bindings/element.h  
DOMElement* dom_element_query_selector(DOMElement* elem, const char* selector);
DOMNodeList* dom_element_get_elements_by_tag_name(DOMElement* elem, const char* tag);

// From js-bindings/node.h
uint16_t dom_node_get_node_type(const DOMNode* node);
char* dom_node_get_node_name(const DOMNode* node);
char* dom_node_get_text_content(const DOMNode* node);
```

## Quick Win: Minimal Test Harness

If you want to run tests **now** without fixing all wrappers, create a minimal test harness:

```javascript
// tests/wpt-v8/minitest.js
function test(fn, name) {
  try {
    fn();
    print('✓ PASS:', name);
  } catch (e) {
    print('✗ FAIL:', name, '-', e.message);
  }
}

function assert_true(condition, message) {
  if (!condition) throw new Error(message || 'Expected true');
}

function assert_equals(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(`${message || ''}: expected ${expected}, got ${actual}`);
  }
}

function assert_throws_dom(error_name, fn, message) {
  try {
    fn();
    throw new Error(message || `Expected ${error_name} to be thrown`);
  } catch (e) {
    if (e.name !== error_name && e.message.indexOf(error_name) === -1) {
      throw new Error(`Expected ${error_name}, got ${e.name || e.message}`);
    }
  }
}
```

Then run tests with:
```bash
./wpt_test_runner \
  tests/wpt-v8/runner_bootstrap.js \
  tests/wpt-v8/minitest.js \
  tests/wpt-v8/attributes-are-nodes.test.js
```

## Conclusion

The infrastructure is **ready** - we just need to add the wrapper functions that bridge JavaScript → V8 → C-ABI → Zig DOM.

Each wrapper follows the same pattern:
1. Unwrap C pointer from V8 object
2. Extract arguments from V8
3. Call C-ABI function
4. Wrap result back to V8 object
5. Return to JavaScript

The C-ABI functions already exist and work. We just need to expose them to JavaScript through V8 wrappers.
