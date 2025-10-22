/**
 * Text Wrapper - V8 bindings for Text
 * 
 * Auto-generated wrapper for DOMText.
 * Provides JavaScript interface for Text operations.
 */

#ifndef V8_DOM_TEXT_WRAPPER_H
#define V8_DOM_TEXT_WRAPPER_H

#include <v8.h>
#include "characterdata_wrapper.h"
#include "dom.h"

namespace v8_dom {

class TextWrapper : public CharacterDataWrapper {
public:
    /**
     * Wrap a C DOMText pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMText* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMText pointer.
     */
    static DOMText* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the Text template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached Text template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 6;
    
private:
    // Readonly property
    static void WholeTextGetter(v8::Local<v8::Name> property,
                               const v8::PropertyCallbackInfo<v8::Value>& info);
    
    // Methods
    static void SplitText(const v8::FunctionCallbackInfo<v8::Value>& args);
};

} // namespace v8_dom

#endif // V8_DOM_TEXT_WRAPPER_H
