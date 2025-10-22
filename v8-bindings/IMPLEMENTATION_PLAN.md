# V8 DOM Bindings - Implementation Plan

This document outlines the complete implementation of V8 wrappers for all DOM interfaces.

## Current Status

✅ **Infrastructure Complete:**
- WrapperCache (wrapper_cache.h/cpp)
- README.md with architecture

🚧 **In Progress:**
- Core wrappers (Node, Element, Document)
- Build system
- Public API header

## Complete Interface List

### Tier 1: Core Infrastructure (PRIORITY)
1. ✅ WrapperCache - Cache management
2. ⬜ BaseWrapper - Template base class
3. ⬜ TemplateCache - Template caching per isolate
4. ⬜ Utilities - String conversion, error handling

### Tier 2: Foundation Nodes (PRIORITY)
5. ⬜ EventTarget - Base for event dispatch
6. ⬜ Node - Base for all nodes
7. ⬜ Element - Generic elements
8. ⬜ Document - Document root
9. ⬜ DocumentFragment - Lightweight document

### Tier 3: Text Nodes
10. ⬜ CharacterData - Base for text nodes
11. ⬜ Text - Text content
12. ⬜ Comment - Comments
13. ⬜ CDATASection - CDATA sections
14. ⬜ ProcessingInstruction - <?xml ?> nodes

### Tier 4: Special Nodes
15. ⬜ DocumentType - <!DOCTYPE>
16. ⬜ Attr - Attributes
17. ⬜ DOMImplementation - Document creation

### Tier 5: Collections
18. ⬜ NodeList - List of nodes (live/static)
19. ⬜ HTMLCollection - Live element collection
20. ⬜ NamedNodeMap - Attribute map
21. ⬜ DOMTokenList - Class list, etc.

### Tier 6: Events
22. ⬜ Event - Base event
23. ⬜ CustomEvent - Custom events with data
24. ⬜ EventInit - Event initialization options

### Tier 7: Ranges & Selection
25. ⬜ AbstractRange - Base for ranges
26. ⬜ Range - Mutable range
27. ⬜ StaticRange - Immutable range

### Tier 8: Traversal
28. ⬜ NodeIterator - Sequential traversal
29. ⬜ TreeWalker - Tree traversal
30. ⬜ NodeFilter - Filter interface

### Tier 9: Mutation Observation
31. ⬜ MutationObserver - Observe DOM changes
32. ⬜ MutationRecord - Mutation records

### Tier 10: Shadow DOM
33. ⬜ ShadowRoot - Shadow tree root
34. ⬜ ShadowRootInit - Shadow init options

### Tier 11: Abort API
35. ⬜ AbortController - Abort controller
36. ⬜ AbortSignal - Abort signal

## File Structure

```
v8-bindings/
├── include/
│   └── v8_dom.h                      # Public API header
├── src/
│   ├── core/
│   │   ├── wrapper_cache.h           ✅ DONE
│   │   ├── wrapper_cache.cpp         ✅ DONE
│   │   ├── base_wrapper.h            ⬜ TODO
│   │   ├── base_wrapper.cpp          ⬜ TODO
│   │   ├── template_cache.h          ⬜ TODO
│   │   ├── template_cache.cpp        ⬜ TODO
│   │   └── utilities.h               ⬜ TODO
│   ├── nodes/
│   │   ├── event_target_wrapper.h    ⬜ TODO
│   │   ├── event_target_wrapper.cpp  ⬜ TODO
│   │   ├── node_wrapper.h            ⬜ TODO
│   │   ├── node_wrapper.cpp          ⬜ TODO
│   │   ├── element_wrapper.h         ⬜ TODO
│   │   ├── element_wrapper.cpp       ⬜ TODO
│   │   ├── document_wrapper.h        ⬜ TODO
│   │   ├── document_wrapper.cpp      ⬜ TODO
│   │   ├── document_fragment_wrapper.h
│   │   ├── document_fragment_wrapper.cpp
│   │   ├── character_data_wrapper.h
│   │   ├── character_data_wrapper.cpp
│   │   ├── text_wrapper.h
│   │   ├── text_wrapper.cpp
│   │   ├── comment_wrapper.h
│   │   ├── comment_wrapper.cpp
│   │   ├── cdata_section_wrapper.h
│   │   ├── cdata_section_wrapper.cpp
│   │   ├── processing_instruction_wrapper.h
│   │   ├── processing_instruction_wrapper.cpp
│   │   ├── document_type_wrapper.h
│   │   ├── document_type_wrapper.cpp
│   │   ├── attr_wrapper.h
│   │   ├── attr_wrapper.cpp
│   │   ├── dom_implementation_wrapper.h
│   │   └── dom_implementation_wrapper.cpp
│   ├── collections/
│   │   ├── node_list_wrapper.h
│   │   ├── node_list_wrapper.cpp
│   │   ├── html_collection_wrapper.h
│   │   ├── html_collection_wrapper.cpp
│   │   ├── named_node_map_wrapper.h
│   │   ├── named_node_map_wrapper.cpp
│   │   ├── dom_token_list_wrapper.h
│   │   └── dom_token_list_wrapper.cpp
│   ├── events/
│   │   ├── event_wrapper.h
│   │   ├── event_wrapper.cpp
│   │   ├── custom_event_wrapper.h
│   │   └── custom_event_wrapper.cpp
│   ├── ranges/
│   │   ├── abstract_range_wrapper.h
│   │   ├── abstract_range_wrapper.cpp
│   │   ├── range_wrapper.h
│   │   ├── range_wrapper.cpp
│   │   ├── static_range_wrapper.h
│   │   └── static_range_wrapper.cpp
│   ├── traversal/
│   │   ├── node_iterator_wrapper.h
│   │   ├── node_iterator_wrapper.cpp
│   │   ├── tree_walker_wrapper.h
│   │   └── tree_walker_wrapper.cpp
│   ├── observers/
│   │   ├── mutation_observer_wrapper.h
│   │   ├── mutation_observer_wrapper.cpp
│   │   ├── mutation_record_wrapper.h
│   │   └── mutation_record_wrapper.cpp
│   ├── shadow/
│   │   ├── shadow_root_wrapper.h
│   │   └── shadow_root_wrapper.cpp
│   ├── abort/
│   │   ├── abort_controller_wrapper.h
│   │   ├── abort_controller_wrapper.cpp
│   │   ├── abort_signal_wrapper.h
│   │   └── abort_signal_wrapper.cpp
│   └── v8_dom.cpp                    # Main entry point
├── tests/
│   ├── test_wrapper_cache.cpp
│   ├── test_node.cpp
│   ├── test_element.cpp
│   ├── test_document.cpp
│   └── ...
├── examples/
│   ├── basic_usage.cpp
│   ├── custom_extension.cpp
│   └── performance_test.cpp
├── Makefile
├── CMakeLists.txt                    # Alternative build system
├── README.md                         ✅ DONE
└── IMPLEMENTATION_PLAN.md            ✅ THIS FILE
```

## Implementation Pattern

Each wrapper follows this pattern:

### 1. Header File (example: element_wrapper.h)

```cpp
#ifndef V8_DOM_ELEMENT_WRAPPER_H
#define V8_DOM_ELEMENT_WRAPPER_H

#include "node_wrapper.h"
#include "../core/base_wrapper.h"
#include "../../js-bindings/dom.h"

namespace v8_dom {

class ElementWrapper : public NodeWrapper {
public:
    // Factory method - creates or retrieves cached wrapper
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMElement* element);
    
    // Unwrap JS object to get C pointer
    static DOMElement* Unwrap(v8::Local<v8::Object> obj);
    
    // Install template (called once per isolate)
    static void InstallTemplate(v8::Isolate* isolate);
    
    // Get cached template
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);

private:
    // Property getters/setters
    static void TagNameGetter(v8::Local<v8::Name> property,
                             const v8::PropertyCallbackInfo<v8::Value>& info);
    static void IdGetter(v8::Local<v8::Name> property,
                        const v8::PropertyCallbackInfo<v8::Value>& info);
    static void IdSetter(v8::Local<v8::Name> property,
                        v8::Local<v8::Value> value,
                        const v8::PropertyCallbackInfo<void>& info);
    
    // Methods
    static void GetAttribute(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void SetAttribute(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void QuerySelector(const v8::FunctionCallbackInfo<v8::Value>& args);
    // ... more methods
    
    // Template cache key
    static constexpr int kTemplateIndex = /* unique index */;
};

} // namespace v8_dom

#endif // V8_DOM_ELEMENT_WRAPPER_H
```

### 2. Implementation File (example: element_wrapper.cpp)

```cpp
#include "element_wrapper.h"
#include "../core/utilities.h"
#include "../core/wrapper_cache.h"

namespace v8_dom {

v8::Local<v8::Object> ElementWrapper::Wrap(v8::Isolate* isolate,
                                           v8::Local<v8::Context> context,
                                           DOMElement* element) {
    // Check cache first
    WrapperCache* cache = WrapperCache::ForIsolate(isolate);
    if (cache->Has(element)) {
        return cache->Get(isolate, element);
    }
    
    // Create new wrapper
    v8::EscapableHandleScope handle_scope(isolate);
    v8::Local<v8::FunctionTemplate> tmpl = GetTemplate(isolate);
    v8::Local<v8::Function> constructor = tmpl->GetFunction(context).ToLocalChecked();
    v8::Local<v8::Object> wrapper = constructor->NewInstance(context).ToLocalChecked();
    
    // Store C pointer in internal field
    wrapper->SetInternalField(0, v8::External::New(isolate, element));
    
    // Add reference count
    dom_element_addref(element);
    
    // Cache with release callback
    cache->Set(isolate, element, wrapper, [](void* ptr) {
        dom_element_release(static_cast<DOMElement*>(ptr));
    });
    
    return handle_scope.Escape(wrapper);
}

DOMElement* ElementWrapper::Unwrap(v8::Local<v8::Object> obj) {
    if (obj->InternalFieldCount() < 1) return nullptr;
    v8::Local<v8::Value> ptr = obj->GetInternalField(0);
    if (!ptr->IsExternal()) return nullptr;
    return static_cast<DOMElement*>(v8::Local<v8::External>::Cast(ptr)->Value());
}

void ElementWrapper::InstallTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "Element"));
    tmpl->InstanceTemplate()->SetInternalFieldCount(1);
    
    // Inherit from Node
    tmpl->Inherit(NodeWrapper::GetTemplate(isolate));
    
    // Add properties
    v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
    proto->SetAccessor(v8::String::NewFromUtf8Literal(isolate, "tagName"),
                      TagNameGetter);
    proto->SetAccessor(v8::String::NewFromUtf8Literal(isolate, "id"),
                      IdGetter, IdSetter);
    
    // Add methods
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "getAttribute"),
              v8::FunctionTemplate::New(isolate, GetAttribute));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "setAttribute"),
              v8::FunctionTemplate::New(isolate, SetAttribute));
    
    // Cache template
    TemplateCache::Set(isolate, kTemplateIndex, tmpl);
}

v8::Local<v8::FunctionTemplate> ElementWrapper::GetTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = TemplateCache::Get(isolate, kTemplateIndex);
    if (tmpl.IsEmpty()) {
        InstallTemplate(isolate);
        tmpl = TemplateCache::Get(isolate, kTemplateIndex);
    }
    return tmpl;
}

void ElementWrapper::TagNameGetter(v8::Local<v8::Name> property,
                                   const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMElement* elem = Unwrap(info.Holder());
    if (!elem) return; // Throw error
    
    const char* tag = dom_element_get_tagname(elem);
    info.GetReturnValue().Set(
        v8::String::NewFromUtf8(isolate, tag).ToLocalChecked()
    );
}

// ... implement all other methods similarly

} // namespace v8_dom
```

## Build System

### Makefile

```makefile
CXX := clang++
CXXFLAGS := -std=c++17 -Wall -Wextra -O2
INCLUDES := -I../js-bindings -I/opt/homebrew/include
LDFLAGS := -L/opt/homebrew/lib
LIBS := -lv8

SRC_DIR := src
OBJ_DIR := obj
LIB_DIR := lib

# All source files
SRCS := $(wildcard $(SRC_DIR)/**/*.cpp) $(wildcard $(SRC_DIR)/*.cpp)
OBJS := $(SRCS:$(SRC_DIR)/%.cpp=$(OBJ_DIR)/%.o)

TARGET := $(LIB_DIR)/libv8dom.a

all: $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p $(LIB_DIR)
	ar rcs $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -rf $(OBJ_DIR) $(LIB_DIR)

.PHONY: all clean
```

## Estimated Lines of Code

- **Core infrastructure**: ~1,000 lines
- **Node wrappers** (10 types): ~3,000 lines
- **Collection wrappers** (4 types): ~1,000 lines
- **Event wrappers** (2 types): ~500 lines
- **Range wrappers** (3 types): ~800 lines
- **Traversal wrappers** (2 types): ~600 lines
- **Observer wrappers** (2 types): ~600 lines
- **Shadow DOM wrappers** (1 type): ~300 lines
- **Abort wrappers** (2 types): ~400 lines
- **Main entry point**: ~500 lines
- **Public API header**: ~300 lines
- **Tests**: ~2,000 lines
- **Examples**: ~500 lines

**Total: ~11,500 lines**

## Implementation Priority

### Phase 1: Minimum Viable (Week 1)
- ✅ WrapperCache
- ⬜ BaseWrapper, TemplateCache, Utilities
- ⬜ EventTarget, Node, Element
- ⬜ Document, Text
- ⬜ Basic build system
- ⬜ Simple test

### Phase 2: Core Complete (Week 2)
- ⬜ All node types
- ⬜ Collections (NodeList, HTMLCollection)
- ⬜ Events (Event, CustomEvent)
- ⬜ Complete build system
- ⬜ Comprehensive tests

### Phase 3: Advanced (Week 3)
- ⬜ Ranges
- ⬜ Traversal
- ⬜ Observers
- ⬜ Shadow DOM
- ⬜ Abort API
- ⬜ Documentation
- ⬜ Examples

## Next Steps

1. Complete core infrastructure (BaseWrapper, TemplateCache, Utilities)
2. Implement Tier 2 (EventTarget, Node, Element, Document)
3. Test basic functionality
4. Implement remaining tiers
5. Write comprehensive tests
6. Create examples
7. Performance benchmarks
8. Documentation

## Notes for HTML Library Extension

Your HTML library should extend the wrappers like this:

```cpp
#include <v8_dom.h>

namespace v8_html {

class HTMLElementWrapper : public v8_dom::ElementWrapper {
public:
    static void InstallTemplate(v8::Isolate* isolate) {
        // Get base Element template
        v8::Local<v8::FunctionTemplate> tmpl = v8_dom::ElementWrapper::GetTemplate(isolate);
        
        // Add HTML-specific properties
        v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
        proto->SetAccessor(
            v8::String::NewFromUtf8Literal(isolate, "innerHTML"),
            GetInnerHTML,
            SetInnerHTML
        );
        
        // Don't call base InstallTemplate() - already cached!
    }
};

}
```

This allows the HTML library to add properties without modifying this library.
