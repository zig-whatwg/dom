/**
 * DOMTokenList Wrapper - V8 bindings for DOMTokenList
 * 
 * Auto-generated wrapper for DOMDOMTokenList.
 * Provides JavaScript interface for DOMTokenList operations.
 */

#ifndef V8_DOM_DOMTOKENLIST_WRAPPER_H
#define V8_DOM_DOMTOKENLIST_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class DOMTokenListWrapper {
public:
    /**
     * Wrap a C DOMDOMTokenList pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMDOMTokenList* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMDOMTokenList pointer.
     */
    static DOMDOMTokenList* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the DOMTokenList template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached DOMTokenList template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 16;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_DOMTOKENLIST_WRAPPER_H
