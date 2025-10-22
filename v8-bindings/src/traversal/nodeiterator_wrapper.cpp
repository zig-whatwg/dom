#include "nodeiterator_wrapper.h"
#include "../wrapper_cache.h"
#include "../core/template_cache.h"
#include "../core/utilities.h"

namespace v8_dom {

v8::Local<v8::Object> NodeIteratorWrapper::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              DOMNodeIterator* obj) {
    if (!obj) {
        return v8::Local<v8::Object>();
    }
    
    // Check wrapper cache first
    WrapperCache* cache = WrapperCache::ForIsolate(isolate);
    if (cache->Has(obj)) {
        return cache->Get(isolate, obj);
    }
    
    // Create new wrapper
    v8::EscapableHandleScope handle_scope(isolate);
    v8::Local<v8::FunctionTemplate> tmpl = GetTemplate(isolate);
    v8::Local<v8::Function> constructor = tmpl->GetFunction(context).ToLocalChecked();
    v8::Local<v8::Object> wrapper = constructor->NewInstance(context).ToLocalChecked();
    
    // Store C pointer in internal field
    wrapper->SetInternalField(0, v8::External::New(isolate, obj));
    
    // Increment C-side reference count
    dom_nodeiterator_addref(obj);
    
    // Cache with release callback
    cache->Set(isolate, obj, wrapper, [](void* ptr) {
        dom_nodeiterator_release(static_cast<DOMNodeIterator*>(ptr));
    });
    
    return handle_scope.Escape(wrapper);
}

DOMNodeIterator* NodeIteratorWrapper::Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    v8::Local<v8::Value> ptr = obj->GetInternalField(0).As<v8::Value>();
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMNodeIterator*>(v8::Local<v8::External>::Cast(ptr)->Value());
}

void NodeIteratorWrapper::InstallTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "NodeIterator"));
    tmpl->InstanceTemplate()->SetInternalFieldCount(1);
    

    // Get prototype template for adding properties/methods
    v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
    
    // TODO: Add properties and methods here
    // Example:
    // proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "propertyName"),
    //                   PropertyNameGetter, PropertyNameSetter);
    // proto->Set(v8::String::NewFromUtf8Literal(isolate, "methodName"),
    //           v8::FunctionTemplate::New(isolate, MethodName));
    
    // Cache the template
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    cache->Set(kTemplateIndex, tmpl);
}

v8::Local<v8::FunctionTemplate> NodeIteratorWrapper::GetTemplate(v8::Isolate* isolate) {
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    
    if (!cache->Has(kTemplateIndex)) {
        InstallTemplate(isolate);
    }
    
    return cache->Get(kTemplateIndex);
}

} // namespace v8_dom
