/**
 * AbortSignal Wrapper - V8 bindings for AbortSignal
 * 
 * Auto-generated wrapper for DOMAbortSignal.
 * Provides JavaScript interface for AbortSignal operations.
 */

#ifndef V8_DOM_ABORTSIGNAL_WRAPPER_H
#define V8_DOM_ABORTSIGNAL_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class AbortSignalWrapper {
public:
    /**
     * Wrap a C DOMAbortSignal pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMAbortSignal* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMAbortSignal pointer.
     */
    static DOMAbortSignal* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the AbortSignal template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached AbortSignal template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 28;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_ABORTSIGNAL_WRAPPER_H
