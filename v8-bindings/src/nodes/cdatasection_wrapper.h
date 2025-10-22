/**
 * CDATASection Wrapper - V8 bindings for CDATASection
 * 
 * Auto-generated wrapper for DOMCDATASection.
 * Provides JavaScript interface for CDATASection operations.
 */

#ifndef V8_DOM_CDATASECTION_WRAPPER_H
#define V8_DOM_CDATASECTION_WRAPPER_H

#include <v8.h>
#include "text_wrapper.h"
#include "dom.h"

namespace v8_dom {

class CDATASectionWrapper : public TextWrapper {
public:
    /**
     * Wrap a C DOMCDATASection pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMCDATASection* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMCDATASection pointer.
     */
    static DOMCDATASection* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the CDATASection template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached CDATASection template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 8;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_CDATASECTION_WRAPPER_H
