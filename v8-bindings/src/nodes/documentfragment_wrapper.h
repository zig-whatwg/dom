/**
 * DocumentFragment Wrapper - V8 bindings for DocumentFragment
 * 
 * Auto-generated wrapper for DOMDocumentFragment.
 * Provides JavaScript interface for DocumentFragment operations.
 */

#ifndef V8_DOM_DOCUMENTFRAGMENT_WRAPPER_H
#define V8_DOM_DOCUMENTFRAGMENT_WRAPPER_H

#include <v8.h>
#include "node_wrapper.h"
#include "dom.h"

namespace v8_dom {

class DocumentFragmentWrapper : public NodeWrapper {
public:
    /**
     * Wrap a C DOMDocumentFragment pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMDocumentFragment* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMDocumentFragment pointer.
     */
    static DOMDocumentFragment* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the DocumentFragment template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached DocumentFragment template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 4;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_DOCUMENTFRAGMENT_WRAPPER_H
