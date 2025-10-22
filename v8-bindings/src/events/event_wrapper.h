/**
 * Event Wrapper - V8 bindings for Event
 * 
 * Auto-generated wrapper for DOMEvent.
 * Provides JavaScript interface for Event operations.
 */

#ifndef V8_DOM_EVENT_WRAPPER_H
#define V8_DOM_EVENT_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class EventWrapper {
public:
    /**
     * Wrap a C DOMEvent pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMEvent* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMEvent pointer.
     */
    static DOMEvent* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the Event template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached Event template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 17;
    
private:
    // Readonly properties
    static void TargetGetter(v8::Local<v8::Name> property,
                            const v8::PropertyCallbackInfo<v8::Value>& info);
    static void CurrentTargetGetter(v8::Local<v8::Name> property,
                                   const v8::PropertyCallbackInfo<v8::Value>& info);
    static void SrcElementGetter(v8::Local<v8::Name> property,
                                const v8::PropertyCallbackInfo<v8::Value>& info);
    
    // Read/write properties
    static void CancelBubbleGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info);
    static void CancelBubbleSetter(v8::Local<v8::Name> property,
                                  v8::Local<v8::Value> value,
                                  const v8::PropertyCallbackInfo<void>& info);
    static void ReturnValueGetter(v8::Local<v8::Name> property,
                                 const v8::PropertyCallbackInfo<v8::Value>& info);
    static void ReturnValueSetter(v8::Local<v8::Name> property,
                                 v8::Local<v8::Value> value,
                                 const v8::PropertyCallbackInfo<void>& info);
    
    // Methods
    static void StopPropagation(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void StopImmediatePropagation(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void PreventDefault(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void InitEvent(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void ComposedPath(const v8::FunctionCallbackInfo<v8::Value>& args);
};

} // namespace v8_dom

#endif // V8_DOM_EVENT_WRAPPER_H
