/**
 * MutationRecord Wrapper - V8 bindings for MutationRecord
 * 
 * Auto-generated wrapper for DOMMutationRecord.
 * Provides JavaScript interface for MutationRecord operations.
 */

#ifndef V8_DOM_MUTATIONRECORD_WRAPPER_H
#define V8_DOM_MUTATIONRECORD_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class MutationRecordWrapper {
public:
    /**
     * Wrap a C DOMMutationRecord pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMMutationRecord* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMMutationRecord pointer.
     */
    static DOMMutationRecord* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the MutationRecord template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached MutationRecord template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 25;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_MUTATIONRECORD_WRAPPER_H
