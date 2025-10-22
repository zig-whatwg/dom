/**
 * Template Cache - Caches V8 FunctionTemplates per isolate
 * 
 * V8 templates are expensive to create, so we cache them per isolate.
 * Each wrapper type has a unique index for template lookup.
 */

#ifndef V8_DOM_TEMPLATE_CACHE_H
#define V8_DOM_TEMPLATE_CACHE_H

#include <v8.h>
#include <vector>

namespace v8_dom {

class TemplateCache {
public:
    /**
     * Get the TemplateCache for a given isolate.
     * Creates one if it doesn't exist.
     */
    static TemplateCache* ForIsolate(v8::Isolate* isolate);
    
    /**
     * Get a cached template by index.
     * Returns empty handle if not found.
     */
    v8::Local<v8::FunctionTemplate> Get(int index);
    
    /**
     * Cache a template at the given index.
     */
    void Set(int index, v8::Local<v8::FunctionTemplate> tmpl);
    
    /**
     * Check if a template is cached at the given index.
     */
    bool Has(int index) const;
    
private:
    TemplateCache(v8::Isolate* isolate);
    ~TemplateCache();
    
    // Non-copyable, non-movable
    TemplateCache(const TemplateCache&) = delete;
    TemplateCache& operator=(const TemplateCache&) = delete;
    
    v8::Isolate* isolate_;
    std::vector<v8::Global<v8::FunctionTemplate>> templates_;
    
    // Isolate data slot (different from WrapperCache)
    static const int kIsolateSlot = 1;
};

} // namespace v8_dom

#endif // V8_DOM_TEMPLATE_CACHE_H
