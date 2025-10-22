/**
 * MutationObserver Wrapper - V8 bindings for MutationObserver
 * 
 * Auto-generated wrapper for DOMMutationObserver.
 * Provides JavaScript interface for MutationObserver operations.
 */

#ifndef V8_DOM_MUTATIONOBSERVER_WRAPPER_H
#define V8_DOM_MUTATIONOBSERVER_WRAPPER_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

class MutationObserverWrapper {
public:
    /**
     * Wrap a C DOMMutationObserver pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMMutationObserver* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMMutationObserver pointer.
     */
    static DOMMutationObserver* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the MutationObserver template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached MutationObserver template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 24;
    
private:
    // Property getters/setters and methods will be added here
    // TODO: Parse dom.h to auto-generate these declarations
};

} // namespace v8_dom

#endif // V8_DOM_MUTATIONOBSERVER_WRAPPER_H
