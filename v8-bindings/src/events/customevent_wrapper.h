/**
 * CustomEvent Wrapper - V8 bindings for CustomEvent
 * 
 * Auto-generated wrapper for DOMCustomEvent.
 * Provides JavaScript interface for CustomEvent operations.
 */

#ifndef V8_DOM_CUSTOMEVENT_WRAPPER_H
#define V8_DOM_CUSTOMEVENT_WRAPPER_H

#include <v8.h>
#include "event_wrapper.h"
#include "dom.h"

namespace v8_dom {

class CustomEventWrapper : public EventWrapper {
public:
    /**
     * Wrap a C DOMCustomEvent pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMCustomEvent* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMCustomEvent pointer.
     */
    static DOMCustomEvent* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the CustomEvent template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached CustomEvent template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 18;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_CUSTOMEVENT_WRAPPER_H
