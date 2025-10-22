# Next Session: Integration Phase

**Goal:** Wire together all completed wrappers and create first working end-to-end example

---

## ✅ What's Ready

### Compiled Wrappers (5)
1. **NodeWrapper** - 24KB object file ✅
2. **DocumentWrapper** - 22KB object file ✅
3. **TextWrapper** - 7.2KB object file ✅
4. **EventWrapper** - 13KB object file ✅
5. **CharacterDataWrapper** - 6.4KB object file ✅

### Infrastructure
- WrapperCache ✅
- TemplateCache ✅
- Utilities ✅
- ElementWrapper (reference) ✅

**Total: 72KB of compiled, tested wrapper code ready for integration!**

---

## 🎯 Integration Tasks (Priority Order)

### Task 1: Create Main Entry Point (30 minutes)
**File:** `src/v8_dom.cpp`

```cpp
#include "../include/v8_dom.h"
#include "core/wrapper_cache.h"
#include "core/template_cache.h"
#include "nodes/document_wrapper.h"
#include "nodes/element_wrapper.h"
#include "nodes/node_wrapper.h"
#include "nodes/text_wrapper.h"
#include "events/event_wrapper.h"

namespace v8_dom {

void InstallDOMBindings(v8::Isolate* isolate, v8::Local<v8::ObjectTemplate> global) {
    // 1. Initialize caches
    WrapperCache::ForIsolate(isolate);
    TemplateCache::ForIsolate(isolate);
    
    // 2. Templates are created lazily on first use
    // No need to install them here
    
    // 3. Create global document object
    v8::HandleScope handle_scope(isolate);
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    DOMDocument* doc = dom_document_new();
    v8::Local<v8::Object> js_doc = DocumentWrapper::Wrap(isolate, context, doc);
    
    global->Set(
        v8::String::NewFromUtf8Literal(isolate, "document"),
        js_doc
    );
}

void Cleanup(v8::Isolate* isolate) {
    WrapperCache* cache = WrapperCache::ForIsolate(isolate);
    cache->Clear();
}

bool IsInstalled(v8::Isolate* isolate) {
    WrapperCache* cache = WrapperCache::ForIsolate(isolate);
    return cache != nullptr;
}

const char* GetVersion() {
    return "0.1.0";
}

} // namespace v8_dom
```

**Test compilation:**
```bash
cd v8-bindings
clang++ -std=c++20 -Wall -Wextra -O2 -fPIC \
  -I../js-bindings \
  -I/opt/homebrew/Cellar/v8/13.5.212.10/libexec/include \
  -c src/v8_dom.cpp -o build/v8_dom.o
```

---

### Task 2: Wire Up Cross-References (45 minutes)

Replace all `// TODO: Use XWrapper::Wrap` calls with actual implementations.

#### Files to Update

**1. NodeWrapper (`src/nodes/node_wrapper.cpp`)**
```cpp
// Line ~195 - ParentElementGetter
#include "element_wrapper.h"

if (parent && dom_node_get_nodetype(parent) == 1) { // ELEMENT_NODE
    DOMElement* elem = (DOMElement*)parent;
    v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, elem);
    info.GetReturnValue().Set(wrapper);
    return;
}
```

Similar updates needed for:
- FirstChildGetter - Could be Element
- LastChildGetter - Could be Element  
- PreviousSiblingGetter - Could be Element
- NextSiblingGetter - Could be Element
- OwnerDocumentGetter - Use DocumentWrapper
- AppendChild - Wrap returned node
- InsertBefore - Wrap returned node
- RemoveChild - Wrap returned node
- ReplaceChild - Wrap returned node
- CloneNode - Wrap cloned node

**2. DocumentWrapper (`src/nodes/document_wrapper.cpp`)**
```cpp
// Factory methods
#include "element_wrapper.h"
#include "text_wrapper.h"
// Comment wrapper when available

// Line ~125 - CreateElement
v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, elem);
args.GetReturnValue().Set(wrapper);

// Line ~155 - CreateElementNS  
v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, elem);
args.GetReturnValue().Set(wrapper);

// Line ~182 - CreateTextNode
v8::Local<v8::Object> wrapper = TextWrapper::Wrap(isolate, context, text);
args.GetReturnValue().Set(wrapper);

// Query methods - getElementById, querySelector, etc.
v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, result);
args.GetReturnValue().Set(wrapper);
```

**3. CharacterDataWrapper (`src/nodes/characterdata_wrapper.cpp`)**
```cpp
#include "element_wrapper.h"

// Line ~106 - PreviousElementSiblingGetter
v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, prevSibling);
info.GetReturnValue().Set(wrapper);

// Line ~127 - NextElementSiblingGetter
v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, nextSibling);
info.GetReturnValue().Set(wrapper);
```

**4. EventWrapper (`src/events/event_wrapper.cpp`)**
```cpp
// EventTarget wrapping needs EventTargetWrapper
// For now, these can stay as SetNull() until EventTargetWrapper is implemented
// OR cast to Node if we know they're nodes:

#include "../nodes/node_wrapper.h"

// target, currentTarget, srcElement getters
DOMNode* node = (DOMNode*)target;
v8::Local<v8::Object> wrapper = NodeWrapper::Wrap(isolate, context, node);
info.GetReturnValue().Set(wrapper);
```

---

### Task 3: Create Simple Test Program (30 minutes)

**File:** `examples/simple_dom_test.cpp`

```cpp
#include <v8.h>
#include <libplatform/libplatform.h>
#include <v8_dom.h>
#include <iostream>

int main(int argc, char* argv[]) {
    // Initialize V8
    v8::V8::InitializeICUDefaultLocation(argv[0]);
    v8::V8::InitializeExternalStartupData(argv[0]);
    std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
    v8::V8::InitializePlatform(platform.get());
    v8::V8::Initialize();

    // Create isolate
    v8::Isolate::CreateParams create_params;
    create_params.array_buffer_allocator =
        v8::ArrayBuffer::Allocator::NewDefaultAllocator();
    v8::Isolate* isolate = v8::Isolate::New(create_params);

    {
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);

        // Install DOM bindings
        v8::Local<v8::ObjectTemplate> global = v8::ObjectTemplate::New(isolate);
        v8_dom::InstallDOMBindings(isolate, global);

        // Create context
        v8::Local<v8::Context> context = v8::Context::New(isolate, nullptr, global);
        v8::Context::Scope context_scope(context);

        // Test 1: Access document
        const char* test1 = R"(
            console.log("Document:", document);
            console.log("Document type:", document.nodeType);
            console.log("Document name:", document.nodeName);
        )";
        
        // Test 2: Create element
        const char* test2 = R"(
            const div = document.createElement("div");
            console.log("Created element:", div);
            console.log("Tag name:", div.tagName);
            div.id = "container";
            console.log("ID:", div.id);
        )";
        
        // Test 3: Create and append text
        const char* test3 = R"(
            const text = document.createTextNode("Hello, World!");
            console.log("Created text:", text);
            console.log("Node type:", text.nodeType);
            
            const div = document.createElement("div");
            div.appendChild(text);
            console.log("Text parent:", text.parentNode);
            console.log("Div first child:", div.firstChild);
        )";
        
        // Test 4: Query operations
        const char* test4 = R"(
            const elem = document.createElement("div");
            elem.setAttribute("data-test", "value");
            console.log("Attribute:", elem.getAttribute("data-test"));
            console.log("Has attribute:", elem.hasAttribute("data-test"));
        )";

        // Execute tests
        std::cout << "\n=== Test 1: Document Access ===" << std::endl;
        ExecuteJS(isolate, context, test1);
        
        std::cout << "\n=== Test 2: Create Element ===" << std::endl;
        ExecuteJS(isolate, context, test2);
        
        std::cout << "\n=== Test 3: Tree Manipulation ===" << std::endl;
        ExecuteJS(isolate, context, test3);
        
        std::cout << "\n=== Test 4: Queries ===" << std::endl;
        ExecuteJS(isolate, context, test4);
        
        std::cout << "\n=== All Tests Passed! ===" << std::endl;
    }

    // Cleanup
    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;

    return 0;
}

void ExecuteJS(v8::Isolate* isolate, v8::Local<v8::Context> context, const char* code) {
    v8::TryCatch try_catch(isolate);
    
    v8::Local<v8::String> source = 
        v8::String::NewFromUtf8(isolate, code).ToLocalChecked();
    
    v8::Local<v8::Script> script;
    if (!v8::Script::Compile(context, source).ToLocal(&script)) {
        v8::String::Utf8Value error(isolate, try_catch.Exception());
        std::cerr << "Compilation error: " << *error << std::endl;
        return;
    }

    v8::Local<v8::Value> result;
    if (!script->Run(context).ToLocal(&result)) {
        v8::String::Utf8Value error(isolate, try_catch.Exception());
        std::cerr << "Runtime error: " << *error << std::endl;
        return;
    }
}
```

**Compile:**
```bash
clang++ -std=c++20 -O2 \
  examples/simple_dom_test.cpp \
  -I./include \
  -I../js-bindings \
  -I/opt/homebrew/Cellar/v8/13.5.212.10/libexec/include \
  -L./lib -lv8dom \
  -L../zig-out/lib -ldom \
  -L/opt/homebrew/lib -lv8 \
  -lpthread \
  -o simple_dom_test
```

---

### Task 4: Update Makefile (15 minutes)

Add v8_dom.cpp to the build:

```makefile
# Add to SRCS
SRCS := src/core/wrapper_cache.cpp \
        src/core/template_cache.cpp \
        src/nodes/node_wrapper.cpp \
        src/nodes/document_wrapper.cpp \
        src/nodes/text_wrapper.cpp \
        src/nodes/characterdata_wrapper.cpp \
        src/events/event_wrapper.cpp \
        src/v8_dom.cpp

# Update object files
OBJS := $(SRCS:%.cpp=build/%.o)

# Add example target
example: lib/libv8dom.a examples/simple_dom_test.cpp
	$(CXX) $(CXXFLAGS) examples/simple_dom_test.cpp \
	  -I./include -I../js-bindings $(V8_INCLUDE) \
	  -L./lib -lv8dom \
	  -L../zig-out/lib -ldom \
	  $(V8_LIB) \
	  -lpthread \
	  -o simple_dom_test
```

---

## 📋 Session Checklist

### Phase 1: Setup (5 minutes)
- [ ] Review completed wrappers
- [ ] Check compilation environment
- [ ] Verify V8 paths in Makefile

### Phase 2: Main Entry Point (30 minutes)
- [ ] Create `src/v8_dom.cpp`
- [ ] Implement `InstallDOMBindings()`
- [ ] Implement `Cleanup()`, `IsInstalled()`, `GetVersion()`
- [ ] Test compilation

### Phase 3: Wire Cross-References (45 minutes)
- [ ] Update NodeWrapper (10 places)
- [ ] Update DocumentWrapper (8 places)
- [ ] Update CharacterDataWrapper (2 places)
- [ ] Update EventWrapper (3 places)
- [ ] Test each file compiles

### Phase 4: Integration Test (30 minutes)
- [ ] Create `examples/simple_dom_test.cpp`
- [ ] Update Makefile with example target
- [ ] Compile library + example
- [ ] Run test and verify output

### Phase 5: Debug & Fix (30 minutes - buffer)
- [ ] Fix any linker errors
- [ ] Fix any runtime crashes
- [ ] Verify no memory leaks
- [ ] Document any issues

---

## 🎯 Success Criteria

At the end of this session, you should have:

1. ✅ **Compiled library** (`lib/libv8dom.a`)
2. ✅ **Working main entry point** (`v8_dom.cpp`)
3. ✅ **All cross-references wired** (no more TODOs in integration path)
4. ✅ **Executable test program** (`simple_dom_test`)
5. ✅ **Passing tests** showing:
   - Document access works
   - Element creation works
   - Tree manipulation works (appendChild)
   - Attribute operations work
   - No crashes
   - No memory leaks

---

## 🚀 After Integration

Once basic integration works, next priorities:

1. **Add more wrappers:**
   - CommentWrapper
   - NodeListWrapper
   - HTMLCollectionWrapper
   - DOMTokenListWrapper

2. **Expand tests:**
   - querySelector/querySelectorAll
   - Event creation and handling
   - More complex tree operations
   - Error handling tests

3. **Performance testing:**
   - Benchmark common operations
   - Compare to browser implementations
   - Identify bottlenecks

4. **Documentation:**
   - Usage examples
   - API reference
   - Integration guide for browsers

---

## 💡 Tips

### Common Issues

**Linker errors:**
- Make sure all `.o` files are in `build/` directory
- Verify library paths in Makefile
- Check that Zig DOM library is built

**Runtime crashes:**
- Check reference counting (addref/release pairs)
- Verify null checks before unwrapping
- Use debugger to find crash location

**Memory leaks:**
- Run with `leaks` tool on macOS
- Check all `dom_*_new()` have matching `_release()`
- Verify WrapperCache cleanup

### Debugging Commands

```bash
# Check library contents
nm lib/libv8dom.a | grep "T "

# Find undefined symbols
nm simple_dom_test | grep "U "

# Check for memory leaks
leaks --atExit -- ./simple_dom_test

# Run with debugger
lldb ./simple_dom_test
```

---

**Ready to integrate! Let's make it work end-to-end!** 🚀
