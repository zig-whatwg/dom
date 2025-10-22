# V8 Integration Examples

This directory contains examples showing how to integrate the Zig DOM C-ABI with V8 (Google's JavaScript engine).

> **❓ Why do we need js-bindings/* wrappers? Can't V8 call src/* directly?**  
> **→ See [WHY_C_ABI.md](WHY_C_ABI.md)** for a detailed explanation of why the C-ABI layer is essential.

## Prerequisites

### 1. Install V8 Headers and Libraries

There are several ways to get V8:

#### Option A: Using Homebrew (macOS - Easiest)

```bash
# Install v8 via homebrew
brew install v8

# V8 headers will be at: /opt/homebrew/include/v8/
# V8 libraries will be at: /opt/homebrew/lib/
```

#### Option B: Using depot_tools (Build from Source - Most Control)

This is the official way used by Chromium developers:

```bash
# 1. Install depot_tools
cd ~
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$HOME/depot_tools:$PATH"

# 2. Fetch V8 source
mkdir v8_build && cd v8_build
fetch v8
cd v8

# 3. Build V8 as a static library
gn gen out/release --args='is_debug=false v8_monolithic=true v8_use_external_startup_data=false'
ninja -C out/release v8_monolith

# After build:
# - Headers: v8/include/
# - Library: v8/out/release/obj/libv8_monolith.a
```

#### Option C: Pre-built Binaries (Ubuntu/Debian)

```bash
# Install libv8-dev package
sudo apt-get install libv8-dev

# Headers will be at: /usr/include/v8/
# Libraries will be at: /usr/lib/
```

#### Option D: Using jsvu (JavaScript Engine Version Updater)

```bash
# Install jsvu
npm install -g jsvu

# Install v8 (this gives you the binary, not headers)
jsvu --engines=v8

# You'll still need headers from one of the other methods
```

### 2. Build the DOM Library

```bash
cd /path/to/dom
zig build

# This creates: zig-out/lib/libdom.a
```

## Building the Examples

### Basic Wrapper Example

```bash
# Using Homebrew V8 (macOS)
clang++ -std=c++17 v8_basic_wrapper.cpp \
  -I/opt/homebrew/include \
  -L/opt/homebrew/lib \
  -lv8 \
  -L../../zig-out/lib -ldom \
  -lpthread -o v8_basic_wrapper

# Using custom-built V8
clang++ -std=c++17 v8_basic_wrapper.cpp \
  -I$HOME/v8_build/v8/include \
  -L$HOME/v8_build/v8/out/release/obj \
  -lv8_monolith \
  -L../../zig-out/lib -ldom \
  -lpthread -o v8_basic_wrapper

# Run
./v8_basic_wrapper
```

### Document Wrapper Example

```bash
clang++ -std=c++17 v8_document_wrapper.cpp \
  -I/opt/homebrew/include \
  -L/opt/homebrew/lib \
  -lv8 \
  -L../../zig-out/lib -ldom \
  -lpthread -o v8_document_wrapper

./v8_document_wrapper
```

## Examples Overview

### 1. `v8_basic_wrapper.cpp` - Element Wrapper

Shows the fundamental V8 integration patterns:
- Wrapping opaque C pointers in V8 objects
- Property accessors (getters/setters)
- Method callbacks
- Memory management with weak callbacks
- GC integration

**What it demonstrates:**
- `Element.tagName` getter
- `Element.id` getter/setter
- `Element.getAttribute(name)` method
- `Element.setAttribute(name, value)` method

### 2. `v8_document_wrapper.cpp` - Document + Element

Shows a more complete integration:
- Multiple wrapped types (Document, Element, Text)
- Parent-child relationships
- Creating elements from JavaScript
- DOM tree manipulation

**What it demonstrates:**
- `Document.createElement(tagName)`
- `Element.appendChild(child)`
- Tree building from JavaScript
- Multiple object types

### 3. `v8_wrapper_cache.cpp` - Advanced Patterns

Shows production-ready patterns:
- Wrapper caching (one JS object per C object)
- Prototype inheritance
- EventTarget integration
- Error handling

## Architecture Overview

### Layered Design

```
┌─────────────────────────────────────┐
│        JavaScript Code              │
│   (element.id = "foo")              │
├─────────────────────────────────────┤
│        V8 JavaScript Engine         │
│   (Manages JS objects & GC)         │
├─────────────────────────────────────┤
│      V8 Wrapper Layer (C++)         │  ← You write this
│   - WrapElement()                   │
│   - UnwrapElement()                 │
│   - Element_IdGetter()              │
│   - Element_IdSetter()              │
├─────────────────────────────────────┤
│      DOM C-ABI (Zig → C)            │  ← We provide this
│   - dom_element_get_id()            │
│   - dom_element_set_id()            │
│   - Reference counting              │
├─────────────────────────────────────┤
│      Zig DOM Implementation         │
│   - Element struct                  │
│   - Attribute storage               │
│   - Tree algorithms                 │
└─────────────────────────────────────┘
```

### Memory Management Flow

```
JavaScript Side              C++ Wrapper              C Side
─────────────────────────────────────────────────────────

let elem = ...       →   WrapElement()        →   dom_element_addref()
                         - Create JS object         - Increment ref_count
                         - Store C pointer          
                         - Set weak callback        
                         
elem = null          →   (GC runs)            →   ElementWeakCallback()
(GC eligible)            - Detects no refs          - dom_element_release()
                                                     - Decrements ref_count
                                                     - Frees if count == 0
```

### Key Patterns

#### 1. Opaque Pointer Wrapping

```cpp
// Store C pointer in V8 internal field
js_object->SetInternalField(0, External::New(isolate, c_pointer));

// Retrieve later
void* raw = Local<External>::Cast(
    js_object->GetInternalField(0)
)->Value();
DOMElement* elem = static_cast<DOMElement*>(raw);
```

#### 2. Weak Callbacks for GC

```cpp
// When creating wrapper
Persistent<Object>* persistent = new Persistent<Object>(isolate, js_obj);
persistent->SetWeak(c_pointer, WeakCallback, WeakCallbackType::kParameter);

// GC calls this when JS object is collected
void WeakCallback(const WeakCallbackInfo<void>& data) {
    DOMElement* elem = static_cast<DOMElement*>(data.GetParameter());
    dom_element_release(elem);  // Release C-side reference
}
```

#### 3. Property Accessors

```cpp
// Define getter/setter
template->PrototypeTemplate()->SetAccessor(
    String::NewFromUtf8(isolate, "id").ToLocalChecked(),
    Element_IdGetter,    // Called on: element.id
    Element_IdSetter     // Called on: element.id = "foo"
);

// Implement getter
void Element_IdGetter(Local<Name> property,
                      const PropertyCallbackInfo<Value>& info) {
    DOMElement* elem = UnwrapElement(info.Holder());
    const char* id = dom_element_get_id(elem);
    info.GetReturnValue().Set(
        String::NewFromUtf8(info.GetIsolate(), id).ToLocalChecked()
    );
}
```

#### 4. Method Callbacks

```cpp
// Define method
template->PrototypeTemplate()->Set(
    String::NewFromUtf8(isolate, "getAttribute").ToLocalChecked(),
    FunctionTemplate::New(isolate, Element_GetAttribute)
);

// Implement method
void Element_GetAttribute(const FunctionCallbackInfo<Value>& args) {
    DOMElement* elem = UnwrapElement(args.Holder());
    String::Utf8Value name(args.GetIsolate(), args[0]);
    const char* value = dom_element_getattribute(elem, *name);
    args.GetReturnValue().Set(
        String::NewFromUtf8(args.GetIsolate(), value).ToLocalChecked()
    );
}
```

## Common Issues

### 1. V8 Version Compatibility

Different V8 versions have slightly different APIs. The examples target V8 10.0+.

**Symptoms:**
- Compilation errors about missing methods
- Different signatures for callbacks

**Solution:**
- Check your V8 version: `v8 --version` or check headers
- Adjust callback signatures to match your version
- See V8 changelog: https://v8.dev/docs/version-numbers

### 2. Linking Errors

**Error:** `undefined reference to v8::...`

**Solution:**
```bash
# Make sure you link all required V8 libraries
-lv8_monolith          # If you built with v8_monolithic=true
# OR
-lv8 -lv8_libplatform  # If using separate libraries
```

### 3. ICU Data Not Found

**Error:** `Fatal error in v8::InitializeICU()`

**Solution:**
```bash
# Copy ICU data file to your binary location
cp /path/to/v8/out/release/icudtl.dat .

# Or set environment variable
export V8_ICU_DATA_FILE=/path/to/icudtl.dat
```

### 4. Snapshot Blob Not Found

**Error:** `Cannot find snapshot blob`

**Solution:**
```bash
# Copy snapshot files
cp /path/to/v8/out/release/snapshot_blob.bin .

# Or build with v8_use_external_startup_data=false
```

## Next Steps

1. **Start with `v8_basic_wrapper.cpp`** - Learn the fundamentals
2. **Extend to more interfaces** - Add Document, Text, Comment
3. **Add wrapper caching** - See `v8_wrapper_cache.cpp`
4. **Integrate into your runtime** - Node.js addon, Deno extension, etc.

## Resources

- **V8 Embedder's Guide:** https://v8.dev/docs/embed
- **V8 API Reference:** https://v8docs.nodesource.com/
- **Chromium Blink Bindings:** https://chromium.googlesource.com/chromium/src/+/refs/heads/main/third_party/blink/renderer/bindings/
- **DOM C-ABI Reference:** `../dom.h`
- **WHATWG DOM Spec:** https://dom.spec.whatwg.org/

## Contributing

Found an issue or have an improvement? Please submit a PR or open an issue!
