/**
 * ShadowRoot Wrapper - V8 bindings for ShadowRoot
 * 
 * Auto-generated wrapper for DOMShadowRoot.
 * Provides JavaScript interface for ShadowRoot operations.
 */

#ifndef V8_DOM_SHADOWROOT_WRAPPER_H
#define V8_DOM_SHADOWROOT_WRAPPER_H

#include <v8.h>
#include "../nodes/documentfragment_wrapper.h"
#include "dom.h"

namespace v8_dom {

class ShadowRootWrapper : public DocumentFragmentWrapper {
public:
    /**
     * Wrap a C DOMShadowRoot pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMShadowRoot* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMShadowRoot pointer.
     */
    static DOMShadowRoot* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the ShadowRoot template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached ShadowRoot template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 26;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_SHADOWROOT_WRAPPER_H
