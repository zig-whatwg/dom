/**
 * EventTarget Wrapper - V8 bindings for EventTarget
 * 
 * Auto-generated wrapper for DOMEventTarget.
 * Provides JavaScript interface for EventTarget operations.
 */

#ifndef V8_DOM_EVENTTARGET_WRAPPER_H
#define V8_DOM_EVENTTARGET_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class EventTargetWrapper {
public:
    /**
     * Wrap a C DOMEventTarget pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMEventTarget* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMEventTarget pointer.
     */
    static DOMEventTarget* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the EventTarget template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached EventTarget template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 0;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_EVENTTARGET_WRAPPER_H
