/**
 * Comment Wrapper - V8 bindings for Comment
 * 
 * Auto-generated wrapper for DOMComment.
 * Provides JavaScript interface for Comment operations.
 */

#ifndef V8_DOM_COMMENT_WRAPPER_H
#define V8_DOM_COMMENT_WRAPPER_H

#include <v8.h>
#include "characterdata_wrapper.h"
#include "dom.h"

namespace v8_dom {

class CommentWrapper : public CharacterDataWrapper {
public:
    /**
     * Wrap a C DOMComment pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMComment* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMComment pointer.
     */
    static DOMComment* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the Comment template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached Comment template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 7;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_COMMENT_WRAPPER_H
