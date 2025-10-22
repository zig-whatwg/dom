#include "htmlcollection_wrapper.h"
#include "../wrapper_cache.h"
#include "../core/template_cache.h"
#include "../core/utilities.h"
#include "../nodes/element_wrapper.h"

namespace v8_dom {

v8::Local<v8::Object> HTMLCollectionWrapper::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              DOMHTMLCollection* obj) {
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
    
    // NOTE: HTMLCollection doesn't have addref - it's managed by the document
    // We just need to release it when the wrapper is GC'd
    
    // Cache with release callback
    cache->Set(isolate, obj, wrapper, [](void* ptr) {
        dom_htmlcollection_release(static_cast<DOMHTMLCollection*>(ptr));
    });
    
    return handle_scope.Escape(wrapper);
}

DOMHTMLCollection* HTMLCollectionWrapper::Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    v8::Local<v8::Value> ptr = obj->GetInternalField(0).As<v8::Value>();
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMHTMLCollection*>(v8::Local<v8::External>::Cast(ptr)->Value());
}

void HTMLCollectionWrapper::InstallTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "HTMLCollection"));
    
    v8::Local<v8::ObjectTemplate> instance = tmpl->InstanceTemplate();
    instance->SetInternalFieldCount(1);
    
    // Enable indexed property access (collection[0], collection[1], etc.)
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
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "namedItem"),
              v8::FunctionTemplate::New(isolate, NamedItem));
    
    // Cache the template
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    cache->Set(kTemplateIndex, tmpl);
}

v8::Local<v8::FunctionTemplate> HTMLCollectionWrapper::GetTemplate(v8::Isolate* isolate) {
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    
    if (!cache->Has(kTemplateIndex)) {
        InstallTemplate(isolate);
    }
    
    return cache->Get(kTemplateIndex);
}

// ===== Property Getters =====

void HTMLCollectionWrapper::LengthGetter(v8::Local<v8::Name> property,
                                        const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMHTMLCollection* collection = Unwrap(info.This().As<v8::Object>());
    
    if (!collection) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid HTMLCollection object")));
        return;
    }
    
    uint32_t length = dom_htmlcollection_get_length(collection);
    info.GetReturnValue().Set(v8::Integer::NewFromUnsigned(isolate, length));
}

// ===== Methods =====

void HTMLCollectionWrapper::Item(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    DOMHTMLCollection* collection = Unwrap(args.This().As<v8::Object>());
    if (!collection) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid HTMLCollection object")));
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
    
    // Call C-ABI to get element at index
    DOMElement* elem = dom_htmlcollection_item(collection, index);
    
    if (!elem) {
        args.GetReturnValue().SetNull();
        return;
    }
    
    // Wrap and return the element
    v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, elem);
    args.GetReturnValue().Set(wrapper);
}

void HTMLCollectionWrapper::NamedItem(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    DOMHTMLCollection* collection = Unwrap(args.This().As<v8::Object>());
    if (!collection) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid HTMLCollection object")));
        return;
    }
    
    if (args.Length() < 1 || !args[0]->IsString()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Name string required")));
        return;
    }
    
    v8::String::Utf8Value name(isolate, args[0]);
    
    // Call C-ABI to get element by name
    DOMElement* elem = dom_htmlcollection_nameditem(collection, *name);
    
    if (!elem) {
        args.GetReturnValue().SetNull();
        return;
    }
    
    // Wrap and return the element
    v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, elem);
    args.GetReturnValue().Set(wrapper);
}

// ===== Indexed Property Handler =====

v8::Intercepted HTMLCollectionWrapper::IndexedPropertyGetter(uint32_t index,
                                                             const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    DOMHTMLCollection* collection = Unwrap(info.This().As<v8::Object>());
    if (!collection) {
        return v8::Intercepted::kNo;  // Property does not exist
    }
    
    // Call C-ABI to get element at index
    DOMElement* elem = dom_htmlcollection_item(collection, index);
    
    if (!elem) {
        return v8::Intercepted::kNo;  // Index out of bounds
    }
    
    // Wrap and return the element
    v8::Local<v8::Object> wrapper = ElementWrapper::Wrap(isolate, context, elem);
    info.GetReturnValue().Set(wrapper);
    return v8::Intercepted::kYes;  // Property intercepted successfully
}

} // namespace v8_dom
