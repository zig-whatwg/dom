/**
 * NodeList Wrapper - V8 bindings for NodeList
 * 
 * Auto-generated wrapper for DOMNodeList.
 * Provides JavaScript interface for NodeList operations.
 */

#ifndef V8_DOM_NODELIST_WRAPPER_H
#define V8_DOM_NODELIST_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class NodeListWrapper {
public:
    /**
     * Wrap a C DOMNodeList pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMNodeList* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMNodeList pointer.
     */
    static DOMNodeList* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the NodeList template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached NodeList template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 13;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_NODELIST_WRAPPER_H
