/**
 * Wrapper Cache - Maintains JS wrapper ↔ C pointer mappings
 * 
 * This ensures identity preservation: the same C object always maps to the
 * same JavaScript wrapper object. Critical for === comparisons and WeakMaps.
 * 
 * Architecture:
 * - One cache per V8 isolate (stored in isolate data)
 * - Hash map from C pointer → Persistent<Object>
 * - Weak callbacks clean up when JS object is GC'd
 * - Thread-safe within isolate (V8 guarantees single-threaded access)
 */

#ifndef V8_DOM_WRAPPER_CACHE_H
#define V8_DOM_WRAPPER_CACHE_H

#include <v8.h>
#include <unordered_map>
#include <memory>

namespace v8_dom {

/**
 * WrapperCache manages the mapping between C DOM objects and V8 JavaScript wrappers.
 * 
 * Each V8 isolate has its own WrapperCache stored in isolate-local storage.
 * This ensures proper cleanup when the isolate is destroyed.
 */
class WrapperCache {
public:
    WrapperCache() = default;
    ~WrapperCache();
    
    // Non-copyable, non-movable
    WrapperCache(const WrapperCache&) = delete;
    WrapperCache& operator=(const WrapperCache&) = delete;
    
    /**
     * Get the WrapperCache for a given isolate.
     * Creates one if it doesn't exist.
     */
    static WrapperCache* ForIsolate(v8::Isolate* isolate);
    
    /**
     * Check if a C pointer has a cached wrapper.
     */
    bool Has(void* c_ptr) const;
    
    /**
     * Get the cached wrapper for a C pointer.
     * Returns empty handle if not found.
     */
    v8::Local<v8::Object> Get(v8::Isolate* isolate, void* c_ptr);
    
    /**
     * Cache a wrapper for a C pointer.
     * Sets up a weak callback to clean up when GC runs.
     * 
     * @param isolate V8 isolate
     * @param c_ptr C pointer to wrap
     * @param wrapper JS wrapper object
     * @param release_callback Function to release C object (dom_*_release)
     */
    void Set(v8::Isolate* isolate, 
             void* c_ptr, 
             v8::Local<v8::Object> wrapper,
             void (*release_callback)(void*));
    
    /**
     * Remove a cached wrapper.
     * Called automatically by weak callback when GC runs.
     */
    void Remove(void* c_ptr);
    
    /**
     * Get the number of cached wrappers.
     */
    size_t Size() const { return cache_.size(); }
    
private:
    /**
     * Entry in the wrapper cache.
     * Holds a weak persistent reference to the JS object.
     */
    struct CacheEntry {
        v8::Global<v8::Object> wrapper;  // Weak reference to JS object
        void (*release_callback)(void*);  // Function to release C object
        void* c_ptr;  // C pointer (for weak callback)
        
        CacheEntry(v8::Isolate* isolate,
                   v8::Local<v8::Object> obj,
                   void (*release)(void*),
                   void* ptr);
        ~CacheEntry();
    };
    
    /**
     * Weak callback invoked when JS wrapper is GC'd.
     * Releases the C-side reference and removes from cache.
     */
    static void WeakCallback(const v8::WeakCallbackInfo<CacheEntry>& data);
    
    // Hash map from C pointer → cache entry
    std::unordered_map<void*, std::unique_ptr<CacheEntry>> cache_;
    
    // Isolate data slot for storing WrapperCache
    static const int kIsolateSlot = 0;
};

} // namespace v8_dom

#endif // V8_DOM_WRAPPER_CACHE_H
