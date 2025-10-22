/**
 * HTMLCollection Wrapper - V8 bindings for HTMLCollection
 * 
 * Auto-generated wrapper for DOMHTMLCollection.
 * Provides JavaScript interface for HTMLCollection operations.
 */

#ifndef V8_DOM_HTMLCOLLECTION_WRAPPER_H
#define V8_DOM_HTMLCOLLECTION_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class HTMLCollectionWrapper {
public:
    /**
     * Wrap a C DOMHTMLCollection pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMHTMLCollection* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMHTMLCollection pointer.
     */
    static DOMHTMLCollection* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the HTMLCollection template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached HTMLCollection template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 14;
    
private:
    // Readonly properties
    static void LengthGetter(v8::Local<v8::Name> property,
                            const v8::PropertyCallbackInfo<v8::Value>& info);
    
    // Methods
    static void Item(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void NamedItem(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Indexed property handler
    static v8::Intercepted IndexedPropertyGetter(uint32_t index,
                                                 const v8::PropertyCallbackInfo<v8::Value>& info);
};

} // namespace v8_dom

#endif // V8_DOM_HTMLCOLLECTION_WRAPPER_H
