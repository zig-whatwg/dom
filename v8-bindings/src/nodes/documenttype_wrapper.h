/**
 * DocumentType Wrapper - V8 bindings for DocumentType
 * 
 * Auto-generated wrapper for DOMDocumentType.
 * Provides JavaScript interface for DocumentType operations.
 */

#ifndef V8_DOM_DOCUMENTTYPE_WRAPPER_H
#define V8_DOM_DOCUMENTTYPE_WRAPPER_H

#include <v8.h>
#include "node_wrapper.h"
#include "dom.h"

namespace v8_dom {

class DocumentTypeWrapper : public NodeWrapper {
public:
    /**
     * Wrap a C DOMDocumentType pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMDocumentType* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMDocumentType pointer.
     */
    static DOMDocumentType* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the DocumentType template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached DocumentType template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 10;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_DOCUMENTTYPE_WRAPPER_H
