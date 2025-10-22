/**
 * NamedNodeMap Wrapper - V8 bindings for NamedNodeMap
 * 
 * Auto-generated wrapper for DOMNamedNodeMap.
 * Provides JavaScript interface for NamedNodeMap operations.
 */

#ifndef V8_DOM_NAMEDNODEMAP_WRAPPER_H
#define V8_DOM_NAMEDNODEMAP_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class NamedNodeMapWrapper {
public:
    /**
     * Wrap a C DOMNamedNodeMap pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMNamedNodeMap* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMNamedNodeMap pointer.
     */
    static DOMNamedNodeMap* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the NamedNodeMap template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached NamedNodeMap template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 15;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_NAMEDNODEMAP_WRAPPER_H
