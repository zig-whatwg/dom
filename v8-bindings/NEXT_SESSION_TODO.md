# Next Session TODO

## ✅ Completed This Session
1. ✅ Identified V8 13.5 API changes
2. ✅ Updated Element wrapper for V8 13.5 (~800 lines, WORKING)
3. ✅ Updated ALL 28 remaining wrapper skeletons for V8 13.5 API
4. ✅ Created complete documentation and migration tools
5. ✅ Verified compilation (Element wrapper compiles successfully)

## 🎯 Next Steps: Implement Core Wrappers

### Priority 1: NodeWrapper (~400-500 lines) - IN PROGRESS
**File:** `src/nodes/node_wrapper.cpp`
**Status:** Header updated with all methods, implementation TODO

**Properties to implement:**
- ✅ Declarations added to header
- ⬜ nodeType (readonly, uint16)
- ⬜ nodeName (readonly, string)
- ⬜ nodeValue (read/write, string)
- ⬜ parentNode (readonly, Node)
- ⬜ parentElement (readonly, Element)
- ⬜ firstChild, lastChild (readonly, Node)
- ⬜ previousSibling, nextSibling (readonly, Node)
- ⬜ ownerDocument (readonly, Document)

**Methods to implement:**
- ⬜ appendChild(node)
- ⬜ insertBefore(node, child)
- ⬜ removeChild(child)
- ⬜ replaceChild(node, child)
- ⬜ cloneNode(deep)
- ⬜ getRootNode(options)
- ⬜ hasChildNodes()
- ⬜ contains(other)
- ⬜ isSameNode(other)
- ⬜ isEqualNode(other)
- ⬜ normalize()

**Pattern to follow:** See `element_wrapper.cpp` lines 160-800

### Priority 2: DocumentWrapper (~300 lines)
**File:** `src/nodes/document_wrapper.cpp`

**Key methods:**
- createElement(tagName)
- createTextNode(data)
- createComment(data)
- querySelector(selectors)
- querySelectorAll(selectors)
- getElementById(id)
- getElementsByTagName(tag)
- getElementsByClassName(classes)

### Priority 3: TextWrapper (~200 lines)
**File:** `src/nodes/text_wrapper.cpp`

**Properties:**
- data (read/write, string)
- length (readonly, number)
- wholeText (readonly, string)

**Methods:**
- splitText(offset)
- appendData(data)
- insertData(offset, data)
- deleteData(offset, count)
- replaceData(offset, count, data)

### Priority 4: EventTargetWrapper (~200 lines)
**File:** `src/nodes/eventtarget_wrapper.cpp`

**Methods:**
- addEventListener(type, listener, options)
- removeEventListener(type, listener, options)
- dispatchEvent(event)

### Priority 5: EventWrapper (~200 lines)
**File:** `src/events/event_wrapper.cpp`

**Properties:**
- type, target, currentTarget
- eventPhase, bubbles, cancelable
- defaultPrevented, isTrusted

**Methods:**
- stopPropagation()
- stopImmediatePropagation()
- preventDefault()

## 📋 Implementation Checklist

For each wrapper:
- [ ] Add property/method declarations to `.h` file
- [ ] Implement InstallTemplate() - register properties/methods
- [ ] Implement all property getters/setters
- [ ] Implement all methods
- [ ] Test compilation
- [ ] Verify with simple test

## 🔧 Quick Commands

### Continue NodeWrapper Implementation
```bash
cd v8-bindings

# Edit node_wrapper.cpp and add implementations following element_wrapper.cpp pattern

# Test compilation
clang++ -std=c++20 -Wall -Wextra -O2 -fPIC \
    -I../js-bindings \
    -I/opt/homebrew/Cellar/v8/13.5.212.10/libexec/include \
    -c src/nodes/node_wrapper.cpp \
    -o test_node.o
```

### Implementation Pattern (from Element wrapper)
```cpp
// 1. In InstallTemplate() - Register property
proto->SetNativeDataProperty(
    v8::String::NewFromUtf8Literal(isolate, "propertyName"),
    PropertyGetter,
    PropertySetter  // optional, omit for readonly
);

// 2. Implement getter
void NodeWrapper::PropertyGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.Holder());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    // Call C API
    const char* value = dom_node_get_property(node);
    info.GetReturnValue().Set(CStringToV8String(isolate, value));
}

// 3. Implement method
void NodeWrapper::MethodName(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMNode* node = Unwrap(args.This());  // V8 13.5: use This() not Holder()
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    // Validate arguments
    if (args.Length() < 1) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "method requires 1 argument")));
        return;
    }
    
    // Convert arguments and call C API
    // ... implementation
}
```

## 📚 Reference Files
- `src/nodes/element_wrapper.cpp` - Complete working example
- `V8_13_5_API_CHANGES.md` - API reference
- `../js-bindings/dom.h` - C API reference

## ⏱️ Time Estimate
- NodeWrapper: 3-4 hours
- DocumentWrapper: 2-3 hours
- TextWrapper: 1-2 hours
- EventTarget/Event: 2-3 hours
- **Total: 8-12 hours** (1-2 days)

## 🎯 Goal
After implementing these 5 core wrappers, we'll have a minimum viable V8 DOM bindings library that can:
- Create documents and elements
- Manipulate the DOM tree
- Query elements
- Handle text nodes
- Fire events

This is enough for basic browser integration!
