#include "wrapper_cache.h"
#include <iostream>

namespace v8_dom {

// Static member initialization
const int WrapperCache::kIsolateSlot;

// CacheEntry implementation

WrapperCache::CacheEntry::CacheEntry(v8::Isolate* isolate,
                                      v8::Local<v8::Object> obj,
                                      void (*release)(void*),
                                      void* ptr)
    : wrapper(isolate, obj)
    , release_callback(release)
    , c_ptr(ptr) {
    // Set up weak callback for GC
    wrapper.SetWeak(this, WeakCallback, v8::WeakCallbackType::kParameter);
}

WrapperCache::CacheEntry::~CacheEntry() {
    // Clean up C-side reference if still alive
    if (release_callback && c_ptr) {
        release_callback(c_ptr);
    }
}

// WrapperCache implementation

WrapperCache::~WrapperCache() {
    // Entries clean themselves up in destructor
    cache_.clear();
}

WrapperCache* WrapperCache::ForIsolate(v8::Isolate* isolate) {
    // Try to get existing cache from isolate data
    void* data = isolate->GetData(kIsolateSlot);
    if (data) {
        return static_cast<WrapperCache*>(data);
    }
    
    // Create new cache and store in isolate
    WrapperCache* cache = new WrapperCache();
    isolate->SetData(kIsolateSlot, cache);
    
    // Note: We rely on the isolate owner to delete this cache
    // Typically done in isolate disposal or via AddMessageListener
    
    return cache;
}

bool WrapperCache::Has(void* c_ptr) const {
    return cache_.find(c_ptr) != cache_.end();
}

v8::Local<v8::Object> WrapperCache::Get(v8::Isolate* isolate, void* c_ptr) {
    auto it = cache_.find(c_ptr);
    if (it == cache_.end()) {
        return v8::Local<v8::Object>();
    }
    return it->second->wrapper.Get(isolate);
}

void WrapperCache::Set(v8::Isolate* isolate, 
                       void* c_ptr, 
                       v8::Local<v8::Object> wrapper,
                       void (*release_callback)(void*)) {
    // Create cache entry (sets up weak callback)
    auto entry = std::make_unique<CacheEntry>(isolate, wrapper, release_callback, c_ptr);
    
    // Store in cache
    cache_[c_ptr] = std::move(entry);
}

void WrapperCache::Remove(void* c_ptr) {
    cache_.erase(c_ptr);
}

void WrapperCache::WeakCallback(const v8::WeakCallbackInfo<CacheEntry>& data) {
    CacheEntry* entry = data.GetParameter();
    void* c_ptr = entry->c_ptr;
    
    // Release C-side reference
    if (entry->release_callback) {
        entry->release_callback(c_ptr);
        entry->release_callback = nullptr;  // Prevent double-free
    }
    
    // Remove from cache (this deletes the entry)
    v8::Isolate* isolate = data.GetIsolate();
    WrapperCache* cache = ForIsolate(isolate);
    cache->Remove(c_ptr);
}

} // namespace v8_dom
