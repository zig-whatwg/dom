#include "nodelist_wrapper.h"
#include "../wrapper_cache.h"
#include "../core/template_cache.h"
#include "../core/utilities.h"
#include "../nodes/node_wrapper.h"

namespace v8_dom {

v8::Local<v8::Object> NodeListWrapper::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              DOMNodeList* obj) {
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
    
    // NOTE: Static NodeLists (from querySelectorAll) don't have addref
    // They're snapshots that need to be released when done
    
    // Cache with release callback
    cache->Set(isolate, obj, wrapper, [](void* ptr) {
        dom_nodelist_static_release(static_cast<DOMNodeList*>(ptr));
    });
    
    return handle_scope.Escape(wrapper);
}

DOMNodeList* NodeListWrapper::Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    v8::Local<v8::Value> ptr = obj->GetInternalField(0).As<v8::Value>();
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMNodeList*>(v8::Local<v8::External>::Cast(ptr)->Value());
}

void NodeListWrapper::InstallTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "NodeList"));
    
    v8::Local<v8::ObjectTemplate> instance = tmpl->InstanceTemplate();
    instance->SetInternalFieldCount(1);
    
    // Enable indexed property access (list[0], list[1], etc.)
    // Use explicit constructor with 5 params
    v8::IndexedPropertyHandlerConfiguration handler_config(
        IndexedPropertyGetter,  // getter
        nullptr,                // setter
        nullptr,                // query
        nullptr,                // deleter
        nullptr                 // enumerator
    );
    instance->SetHandler(handler_config);

    // Get prototype template for adding properties/methods
    v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
    
    // Readonly properties
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "length"),
                                 LengthGetter);
    
    // Methods
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "item"),
              v8::FunctionTemplate::New(isolate, Item));
    
    // Cache the template
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    cache->Set(kTemplateIndex, tmpl);
}

v8::Local<v8::FunctionTemplate> NodeListWrapper::GetTemplate(v8::Isolate* isolate) {
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    
    if (!cache->Has(kTemplateIndex)) {
        InstallTemplate(isolate);
    }
    
    return cache->Get(kTemplateIndex);
}

// ===== Property Getters =====

void NodeListWrapper::LengthGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNodeList* list = Unwrap(info.This().As<v8::Object>());
    
    if (!list) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid NodeList object")));
        return;
    }
    
    uint32_t length = dom_nodelist_static_get_length(list);
    info.GetReturnValue().Set(v8::Integer::NewFromUnsigned(isolate, length));
}

// ===== Methods =====

void NodeListWrapper::Item(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    DOMNodeList* list = Unwrap(args.This().As<v8::Object>());
    if (!list) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid NodeList object")));
        return;
    }
    
    if (args.Length() < 1) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Index required")));
        return;
    }
    
    // Get index argument
    v8::Maybe<uint32_t> maybeIndex = args[0]->Uint32Value(context);
    if (maybeIndex.IsNothing()) {
        args.GetReturnValue().SetNull();
        return;
    }
    uint32_t index = maybeIndex.ToChecked();
    
    // Call C-ABI to get node at index
    DOMNode* node = dom_nodelist_static_item(list, index);
    
    if (!node) {
        args.GetReturnValue().SetNull();
        return;
    }
    
    // Wrap and return the node
    v8::Local<v8::Object> wrapper = NodeWrapper::Wrap(isolate, context, node);
    args.GetReturnValue().Set(wrapper);
}

// ===== Indexed Property Handler =====

v8::Intercepted NodeListWrapper::IndexedPropertyGetter(uint32_t index,
                                                       const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    DOMNodeList* list = Unwrap(info.This().As<v8::Object>());
    if (!list) {
        return v8::Intercepted::kNo;  // Property does not exist
    }
    
    // Call C-ABI to get node at index
    DOMNode* node = dom_nodelist_static_item(list, index);
    
    if (!node) {
        return v8::Intercepted::kNo;  // Index out of bounds
    }
    
    // Wrap and return the node
    v8::Local<v8::Object> wrapper = NodeWrapper::Wrap(isolate, context, node);
    info.GetReturnValue().Set(wrapper);
    return v8::Intercepted::kYes;  // Property intercepted successfully
}

} // namespace v8_dom
