/**
 * NodeIterator Wrapper - V8 bindings for NodeIterator
 * 
 * Auto-generated wrapper for DOMNodeIterator.
 * Provides JavaScript interface for NodeIterator operations.
 */

#ifndef V8_DOM_NODEITERATOR_WRAPPER_H
#define V8_DOM_NODEITERATOR_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class NodeIteratorWrapper {
public:
    /**
     * Wrap a C DOMNodeIterator pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMNodeIterator* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMNodeIterator pointer.
     */
    static DOMNodeIterator* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the NodeIterator template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached NodeIterator template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 22;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_NODEITERATOR_WRAPPER_H
