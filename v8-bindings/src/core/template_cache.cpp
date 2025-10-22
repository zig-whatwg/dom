#include "template_cache.h"

namespace v8_dom {

const int TemplateCache::kIsolateSlot;

TemplateCache::TemplateCache(v8::Isolate* isolate)
    : isolate_(isolate)
    , templates_(100) {  // Pre-allocate space for 100 templates
}

TemplateCache::~TemplateCache() {
    // Global<> handles clean themselves up
    templates_.clear();
}

TemplateCache* TemplateCache::ForIsolate(v8::Isolate* isolate) {
    // Try to get existing cache from isolate data
    void* data = isolate->GetData(kIsolateSlot);
    if (data) {
        return static_cast<TemplateCache*>(data);
    }
    
    // Create new cache and store in isolate
    TemplateCache* cache = new TemplateCache(isolate);
    isolate->SetData(kIsolateSlot, cache);
    
    return cache;
}

v8::Local<v8::FunctionTemplate> TemplateCache::Get(int index) {
    if (index < 0 || index >= static_cast<int>(templates_.size())) {
        return v8::Local<v8::FunctionTemplate>();
    }
    
    if (templates_[index].IsEmpty()) {
        return v8::Local<v8::FunctionTemplate>();
    }
    
    return templates_[index].Get(isolate_);
}

void TemplateCache::Set(int index, v8::Local<v8::FunctionTemplate> tmpl) {
    // Expand vector if needed
    if (index >= static_cast<int>(templates_.size())) {
        templates_.resize(index + 1);
    }
    
    // Store template as persistent
    templates_[index].Reset(isolate_, tmpl);
}

bool TemplateCache::Has(int index) const {
    if (index < 0 || index >= static_cast<int>(templates_.size())) {
        return false;
    }
    
    return !templates_[index].IsEmpty();
}

} // namespace v8_dom
