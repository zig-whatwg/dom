#include "../include/v8_dom.h"
#include "wrapper_cache.h"
#include "core/template_cache.h"
#include "nodes/document_wrapper.h"

namespace v8_dom {

// Global document instance (one per isolate)
static DOMDocument* g_document = nullptr;

// Accessor for 'document' property
static void DocumentGetter(v8::Local<v8::Name> property,
                           const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    // Create document on first access
    if (!g_document) {
        g_document = dom_document_new();
    }
    
    v8::Local<v8::Object> wrapper = DocumentWrapper::Wrap(isolate, context, g_document);
    info.GetReturnValue().Set(wrapper);
}

void InstallDOMBindings(v8::Isolate* isolate, v8::Local<v8::ObjectTemplate> global) {
    // 1. Initialize caches
    WrapperCache::ForIsolate(isolate);
    TemplateCache::ForIsolate(isolate);
    
    // 2. Install 'document' as a lazy accessor using SetNativeDataProperty
    global->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "document"),
        DocumentGetter,
        nullptr,  // No setter
        v8::Local<v8::Value>(),  // No data
        v8::PropertyAttribute::None
    );
}

void Cleanup(v8::Isolate* isolate) {
    // Clean up global document
    if (g_document) {
        dom_document_release(g_document);
        g_document = nullptr;
    }
    (void)isolate;
}

bool IsInstalled(v8::Isolate* isolate) {
    WrapperCache* cache = WrapperCache::ForIsolate(isolate);
    return cache != nullptr;
}

const char* GetVersion() {
    return "0.1.0";
}

} // namespace v8_dom
