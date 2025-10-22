/**
 * CharacterData Wrapper - V8 bindings for CharacterData
 * 
 * Auto-generated wrapper for DOMCharacterData.
 * Provides JavaScript interface for CharacterData operations.
 */

#ifndef V8_DOM_CHARACTERDATA_WRAPPER_H
#define V8_DOM_CHARACTERDATA_WRAPPER_H

#include <v8.h>
#include "node_wrapper.h"
#include "dom.h"

namespace v8_dom {

class CharacterDataWrapper : public NodeWrapper {
public:
    /**
     * Wrap a C DOMCharacterData pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMCharacterData* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMCharacterData pointer.
     */
    static DOMCharacterData* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the CharacterData template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached CharacterData template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 5;
    
private:
    // Readonly properties (NonDocumentTypeChildNode mixin)
    static void PreviousElementSiblingGetter(v8::Local<v8::Name> property,
                                             const v8::PropertyCallbackInfo<v8::Value>& info);
    static void NextElementSiblingGetter(v8::Local<v8::Name> property,
                                        const v8::PropertyCallbackInfo<v8::Value>& info);
};

} // namespace v8_dom

#endif // V8_DOM_CHARACTERDATA_WRAPPER_H
