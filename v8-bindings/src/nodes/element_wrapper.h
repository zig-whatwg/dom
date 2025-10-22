/**
 * Element Wrapper - V8 bindings for Element
 * 
 * Auto-generated wrapper for DOMElement.
 * Provides JavaScript interface for Element operations.
 */

#ifndef V8_DOM_ELEMENT_WRAPPER_H
#define V8_DOM_ELEMENT_WRAPPER_H

#include <v8.h>
#include "node_wrapper.h"
#include "dom.h"

namespace v8_dom {

class ElementWrapper : public NodeWrapper {
public:
    /**
     * Wrap a C DOMElement pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMElement* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMElement pointer.
     */
    static DOMElement* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the Element template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached Element template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 2;
    
private:
    // Property interceptor to prevent shadowing
    static v8::Intercepted NamedPropertySetter(v8::Local<v8::Name> property,
                                               v8::Local<v8::Value> value,
                                               const v8::PropertyCallbackInfo<void>& info);
    
    // Readonly properties
    static void TagNameGetter(v8::Local<v8::Name> property,
                             const v8::PropertyCallbackInfo<v8::Value>& info);
    static void NamespaceURIGetter(v8::Local<v8::Name> property,
                                   const v8::PropertyCallbackInfo<v8::Value>& info);
    static void PrefixGetter(v8::Local<v8::Name> property,
                            const v8::PropertyCallbackInfo<v8::Value>& info);
    static void LocalNameGetter(v8::Local<v8::Name> property,
                               const v8::PropertyCallbackInfo<v8::Value>& info);
    static void ClassListGetter(v8::Local<v8::Name> property,
                               const v8::PropertyCallbackInfo<v8::Value>& info);
    static void ShadowRootGetter(v8::Local<v8::Name> property,
                                const v8::PropertyCallbackInfo<v8::Value>& info);
    static void AssignedSlotGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info);
    
    // Read/write properties
    static void IdGetter(v8::Local<v8::Name> property,
                        const v8::PropertyCallbackInfo<v8::Value>& info);
    static void IdSetter(v8::Local<v8::Name> property,
                        v8::Local<v8::Value> value,
                        const v8::PropertyCallbackInfo<void>& info);
    static void ClassNameGetter(v8::Local<v8::Name> property,
                               const v8::PropertyCallbackInfo<v8::Value>& info);
    static void ClassNameSetter(v8::Local<v8::Name> property,
                               v8::Local<v8::Value> value,
                               const v8::PropertyCallbackInfo<void>& info);
    static void SlotGetter(v8::Local<v8::Name> property,
                          const v8::PropertyCallbackInfo<v8::Value>& info);
    static void SlotSetter(v8::Local<v8::Name> property,
                          v8::Local<v8::Value> value,
                          const v8::PropertyCallbackInfo<void>& info);
    
    // Methods - Attributes
    static void GetAttribute(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void GetAttributeNS(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void SetAttribute(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void SetAttributeNS(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void RemoveAttribute(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void RemoveAttributeNS(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void ToggleAttribute(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void HasAttribute(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void HasAttributeNS(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void HasAttributes(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void GetAttributeNames(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Methods - Querying
    static void Matches(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void Closest(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void QuerySelector(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void QuerySelectorAll(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void WebkitMatchesSelector(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Methods - Shadow DOM
    static void AttachShadow(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Methods - Adjacent insertion
    static void InsertAdjacentElement(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void InsertAdjacentText(const v8::FunctionCallbackInfo<v8::Value>& args);
};

} // namespace v8_dom

#endif // V8_DOM_ELEMENT_WRAPPER_H
