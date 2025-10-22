#!/usr/bin/env python3
"""
V8 DOM Wrapper Generator

This script generates V8 wrapper code for all DOM interfaces based on the C-ABI.
It reads the dom.h header and generates corresponding wrapper classes.

Usage:
    python3 generate_wrappers.py

Output:
    src/nodes/*.{h,cpp}
    src/collections/*.{h,cpp}
    src/events/*.{h,cpp}
    etc.
"""

import os
import re
from typing import List, Dict, Tuple

# Template indices for each wrapper type
TEMPLATE_INDICES = {
    'EventTarget': 0,
    'Node': 1,
    'Element': 2,
    'Document': 3,
    'DocumentFragment': 4,
    'CharacterData': 5,
    'Text': 6,
    'Comment': 7,
    'CDATASection': 8,
    'ProcessingInstruction': 9,
    'DocumentType': 10,
    'Attr': 11,
    'DOMImplementation': 12,
    'NodeList': 13,
    'HTMLCollection': 14,
    'NamedNodeMap': 15,
    'DOMTokenList': 16,
    'Event': 17,
    'CustomEvent': 18,
    'AbstractRange': 19,
    'Range': 20,
    'StaticRange': 21,
    'NodeIterator': 22,
    'TreeWalker': 23,
    'MutationObserver': 24,
    'MutationRecord': 25,
    'ShadowRoot': 26,
    'AbortController': 27,
    'AbortSignal': 28,
}

# Inheritance relationships
INHERITANCE = {
    'Node': 'EventTarget',
    'Element': 'Node',
    'Document': 'Node',
    'DocumentFragment': 'Node',
    'CharacterData': 'Node',
    'Text': 'CharacterData',
    'Comment': 'CharacterData',
    'CDATASection': 'Text',
    'ProcessingInstruction': 'CharacterData',
    'DocumentType': 'Node',
    'Attr': 'Node',
    'ShadowRoot': 'DocumentFragment',
}

def generate_header(interface_name: str, parent_class: str = None) -> str:
    """Generate wrapper header file."""
    guard = f"V8_DOM_{interface_name.upper()}_WRAPPER_H"
    dom_type = f"DOM{interface_name}"
    wrapper_class = f"{interface_name}Wrapper"
    parent_wrapper = f"{parent_class}Wrapper" if parent_class else "BaseWrapper"
    template_index = TEMPLATE_INDICES.get(interface_name, 99)
    
    parent_include = f'#include "{parent_class.lower()}_wrapper.h"' if parent_class else '#include "../core/base_wrapper.h"'
    
    return f'''/**
 * {interface_name} Wrapper - V8 bindings for {interface_name}
 * 
 * Auto-generated wrapper for DOM{interface_name}.
 * Provides JavaScript interface for {interface_name} operations.
 */

#ifndef {guard}
#define {guard}

#include <v8.h>
{parent_include}
#include "../../js-bindings/dom.h"

namespace v8_dom {{

class {wrapper_class}{f" : public {parent_wrapper}" if parent_class else ""} {{
public:
    /**
     * Wrap a C {dom_type} pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      {dom_type}* obj);
    
    /**
     * Unwrap a V8 object to get the C {dom_type} pointer.
     */
    static {dom_type}* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the {interface_name} template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached {interface_name} template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = {template_index};
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
}};

}} // namespace v8_dom

#endif // {guard}
'''

def generate_implementation(interface_name: str, parent_class: str = None) -> str:
    """Generate wrapper implementation file."""
    dom_type = f"DOM{interface_name}"
    wrapper_class = f"{interface_name}Wrapper"
    lower_name = interface_name.lower()
    parent_wrapper = f"{parent_class}Wrapper" if parent_class else ""
    
    inherit_line = f"    // Inherit from {parent_class}\n    tmpl->Inherit({parent_wrapper}::GetTemplate(isolate));\n" if parent_class else ""
    
    return f'''#include "{lower_name}_wrapper.h"
#include "../core/wrapper_cache.h"
#include "../core/template_cache.h"
#include "../core/utilities.h"

namespace v8_dom {{

v8::Local<v8::Object> {wrapper_class}::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              {dom_type}* obj) {{
    if (!obj) {{
        return v8::Local<v8::Object>();
    }}
    
    // Check wrapper cache first
    WrapperCache* cache = WrapperCache::ForIsolate(isolate);
    if (cache->Has(obj)) {{
        return cache->Get(isolate, obj);
    }}
    
    // Create new wrapper
    v8::EscapableHandleScope handle_scope(isolate);
    v8::Local<v8::FunctionTemplate> tmpl = GetTemplate(isolate);
    v8::Local<v8::Function> constructor = tmpl->GetFunction(context).ToLocalChecked();
    v8::Local<v8::Object> wrapper = constructor->NewInstance(context).ToLocalChecked();
    
    // Store C pointer in internal field
    wrapper->SetInternalField(0, v8::External::New(isolate, obj));
    
    // Increment C-side reference count
    dom_{lower_name}_addref(obj);
    
    // Cache with release callback
    cache->Set(isolate, obj, wrapper, [](void* ptr) {{
        dom_{lower_name}_release(static_cast<{dom_type}*>(ptr));
    }});
    
    return handle_scope.Escape(wrapper);
}}

{dom_type}* {wrapper_class}::Unwrap(v8::Local<v8::Object> obj) {{
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {{
        return nullptr;
    }}
    
    v8::Local<v8::Value> ptr = obj->GetInternalField(0);
    if (!ptr->IsExternal()) {{
        return nullptr;
    }}
    
    return static_cast<{dom_type}*>(v8::Local<v8::External>::Cast(ptr)->Value());
}}

void {wrapper_class}::InstallTemplate(v8::Isolate* isolate) {{
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "{interface_name}"));
    tmpl->InstanceTemplate()->SetInternalFieldCount(1);
    
{inherit_line}
    // Get prototype template for adding properties/methods
    v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
    
    // TODO: Add properties and methods here
    // Example:
    // proto->SetAccessor(v8::String::NewFromUtf8Literal(isolate, "propertyName"),
    //                   PropertyNameGetter, PropertyNameSetter);
    // proto->Set(v8::String::NewFromUtf8Literal(isolate, "methodName"),
    //           v8::FunctionTemplate::New(isolate, MethodName));
    
    // Cache the template
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    cache->Set(kTemplateIndex, tmpl);
}}

v8::Local<v8::FunctionTemplate> {wrapper_class}::GetTemplate(v8::Isolate* isolate) {{
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    
    if (!cache->Has(kTemplateIndex)) {{
        InstallTemplate(isolate);
    }}
    
    return cache->Get(kTemplateIndex);
}}

}} // namespace v8_dom
'''

def main():
    """Generate all wrapper files."""
    print("V8 DOM Wrapper Generator")
    print("=" * 60)
    
    # Create output directories
    os.makedirs("src/nodes", exist_ok=True)
    os.makedirs("src/collections", exist_ok=True)
    os.makedirs("src/events", exist_ok=True)
    os.makedirs("src/ranges", exist_ok=True)
    os.makedirs("src/traversal", exist_ok=True)
    os.makedirs("src/observers", exist_ok=True)
    os.makedirs("src/shadow", exist_ok=True)
    os.makedirs("src/abort", exist_ok=True)
    
    # Node wrappers
    node_types = [
        ('EventTarget', None, 'nodes'),
        ('Node', 'EventTarget', 'nodes'),
        ('Element', 'Node', 'nodes'),
        ('Document', 'Node', 'nodes'),
        ('DocumentFragment', 'Node', 'nodes'),
        ('CharacterData', 'Node', 'nodes'),
        ('Text', 'CharacterData', 'nodes'),
        ('Comment', 'CharacterData', 'nodes'),
        ('CDATASection', 'Text', 'nodes'),
        ('ProcessingInstruction', 'CharacterData', 'nodes'),
        ('DocumentType', 'Node', 'nodes'),
        ('Attr', 'Node', 'nodes'),
        ('DOMImplementation', None, 'nodes'),
    ]
    
    # Collection wrappers
    collection_types = [
        ('NodeList', None, 'collections'),
        ('HTMLCollection', None, 'collections'),
        ('NamedNodeMap', None, 'collections'),
        ('DOMTokenList', None, 'collections'),
    ]
    
    # Event wrappers
    event_types = [
        ('Event', None, 'events'),
        ('CustomEvent', 'Event', 'events'),
    ]
    
    # Range wrappers
    range_types = [
        ('AbstractRange', None, 'ranges'),
        ('Range', 'AbstractRange', 'ranges'),
        ('StaticRange', 'AbstractRange', 'ranges'),
    ]
    
    # Traversal wrappers
    traversal_types = [
        ('NodeIterator', None, 'traversal'),
        ('TreeWalker', None, 'traversal'),
    ]
    
    # Observer wrappers
    observer_types = [
        ('MutationObserver', None, 'observers'),
        ('MutationRecord', None, 'observers'),
    ]
    
    # Shadow DOM wrappers
    shadow_types = [
        ('ShadowRoot', 'DocumentFragment', 'shadow'),
    ]
    
    # Abort API wrappers
    abort_types = [
        ('AbortController', None, 'abort'),
        ('AbortSignal', None, 'abort'),
    ]
    
    all_types = (node_types + collection_types + event_types + 
                 range_types + traversal_types + observer_types + 
                 shadow_types + abort_types)
    
    generated_count = 0
    
    for interface_name, parent_class, directory in all_types:
        lower_name = interface_name.lower()
        header_path = f"src/{directory}/{lower_name}_wrapper.h"
        impl_path = f"src/{directory}/{lower_name}_wrapper.cpp"
        
        # Generate header
        with open(header_path, 'w') as f:
            f.write(generate_header(interface_name, parent_class))
        print(f"✓ Generated {header_path}")
        
        # Generate implementation
        with open(impl_path, 'w') as f:
            f.write(generate_implementation(interface_name, parent_class))
        print(f"✓ Generated {impl_path}")
        
        generated_count += 2
    
    print("=" * 60)
    print(f"Generated {generated_count} files successfully!")
    print("\nNext steps:")
    print("1. Review generated files")
    print("2. Add property/method implementations to each wrapper")
    print("3. Implement core infrastructure (TemplateCache, Utilities)")
    print("4. Create build system")
    print("5. Write tests")

if __name__ == "__main__":
    main()
