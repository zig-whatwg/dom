/**
 * Document Wrapper - V8 bindings for Document
 * 
 * Auto-generated wrapper for DOMDocument.
 * Provides JavaScript interface for Document operations.
 */

#ifndef V8_DOM_DOCUMENT_WRAPPER_H
#define V8_DOM_DOCUMENT_WRAPPER_H

#include <v8.h>
#include "node_wrapper.h"
#include "dom.h"

namespace v8_dom {

class DocumentWrapper : public NodeWrapper {
public:
    /**
     * Wrap a C DOMDocument pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMDocument* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMDocument pointer.
     */
    static DOMDocument* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the Document template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached Document template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 3;
    
private:
    // Readonly properties
    static void CompatModeGetter(v8::Local<v8::Name> property,
                                 const v8::PropertyCallbackInfo<v8::Value>& info);
    static void CharacterSetGetter(v8::Local<v8::Name> property,
                                   const v8::PropertyCallbackInfo<v8::Value>& info);
    static void ContentTypeGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info);
    static void DocumentURIGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info);
    static void DoctypeGetter(v8::Local<v8::Name> property,
                             const v8::PropertyCallbackInfo<v8::Value>& info);
    
    // Factory methods
    static void CreateElement(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void CreateElementNS(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void CreateTextNode(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void CreateComment(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void CreateAttribute(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void CreateAttributeNS(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Node manipulation
    static void ImportNode(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void AdoptNode(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Query methods
    static void QuerySelector(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void QuerySelectorAll(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void GetElementsByTagName(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void GetElementsByTagNameNS(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void GetElementsByClassName(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void GetElementById(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Range/Iterator factory methods
    static void CreateRange(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void CreateTreeWalker(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void CreateNodeIterator(const v8::FunctionCallbackInfo<v8::Value>& args);
};

} // namespace v8_dom

#endif // V8_DOM_DOCUMENT_WRAPPER_H
