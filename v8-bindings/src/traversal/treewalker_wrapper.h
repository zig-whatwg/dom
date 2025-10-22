/**
 * TreeWalker Wrapper - V8 bindings for TreeWalker
 * 
 * Auto-generated wrapper for DOMTreeWalker.
 * Provides JavaScript interface for TreeWalker operations.
 */

#ifndef V8_DOM_TREEWALKER_WRAPPER_H
#define V8_DOM_TREEWALKER_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class TreeWalkerWrapper {
public:
    /**
     * Wrap a C DOMTreeWalker pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMTreeWalker* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMTreeWalker pointer.
     */
    static DOMTreeWalker* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the TreeWalker template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached TreeWalker template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 23;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_TREEWALKER_WRAPPER_H
