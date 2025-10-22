/**
 * Range Wrapper - V8 bindings for Range
 * 
 * Auto-generated wrapper for DOMRange.
 * Provides JavaScript interface for Range operations.
 */

#ifndef V8_DOM_RANGE_WRAPPER_H
#define V8_DOM_RANGE_WRAPPER_H

#include <v8.h>
#include "abstractrange_wrapper.h"
#include "dom.h"

namespace v8_dom {

class RangeWrapper : public AbstractRangeWrapper {
public:
    /**
     * Wrap a C DOMRange pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMRange* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMRange pointer.
     */
    static DOMRange* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the Range template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached Range template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 20;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_RANGE_WRAPPER_H
