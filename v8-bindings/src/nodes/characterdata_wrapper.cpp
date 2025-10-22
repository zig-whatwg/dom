#include "characterdata_wrapper.h"
#include "../wrapper_cache.h"
#include "../core/template_cache.h"
#include "../core/utilities.h"

namespace v8_dom {

v8::Local<v8::Object> CharacterDataWrapper::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              DOMCharacterData* obj) {
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
    
    // Increment C-side reference count (CharacterData inherits from Node)
    dom_node_addref((DOMNode*)obj);
    
    // Cache with release callback
    cache->Set(isolate, obj, wrapper, [](void* ptr) {
        dom_node_release((DOMNode*)static_cast<DOMCharacterData*>(ptr));
    });
    
    return handle_scope.Escape(wrapper);
}

DOMCharacterData* CharacterDataWrapper::Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    v8::Local<v8::Data> data = obj->GetInternalField(0);
    v8::Local<v8::Value> ptr = data.As<v8::Value>();
    if (ptr.IsEmpty()) return nullptr;
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMCharacterData*>(v8::Local<v8::External>::Cast(ptr)->Value());
}

void CharacterDataWrapper::InstallTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "CharacterData"));
    tmpl->InstanceTemplate()->SetInternalFieldCount(1);
    
    // Inherit from Node
    tmpl->Inherit(NodeWrapper::GetTemplate(isolate));

    // Get prototype template for adding properties/methods
    v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
    
    // Readonly properties (NonDocumentTypeChildNode mixin)
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "previousElementSibling"),
                                 PreviousElementSiblingGetter);
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "nextElementSibling"),
                                 NextElementSiblingGetter);
    
    // Cache the template
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    cache->Set(kTemplateIndex, tmpl);
}

v8::Local<v8::FunctionTemplate> CharacterDataWrapper::GetTemplate(v8::Isolate* isolate) {
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    
    if (!cache->Has(kTemplateIndex)) {
        InstallTemplate(isolate);
    }
    
    return cache->Get(kTemplateIndex);
}

// ===== Property Getters (NonDocumentTypeChildNode mixin) =====

void CharacterDataWrapper::PreviousElementSiblingGetter(v8::Local<v8::Name> property,
                                                        const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMCharacterData* cdata = Unwrap(info.This());
    
    if (!cdata) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid CharacterData object")));
        return;
    }
    
    DOMElement* prevSibling = dom_characterdata_get_previouselementsibling(cdata);
    if (!prevSibling) {
        info.GetReturnValue().SetNull();
        return;
    }
    
    // TODO: Use ElementWrapper::Wrap when available
    info.GetReturnValue().SetNull();
}

void CharacterDataWrapper::NextElementSiblingGetter(v8::Local<v8::Name> property,
                                                    const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMCharacterData* cdata = Unwrap(info.This());
    
    if (!cdata) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid CharacterData object")));
        return;
    }
    
    DOMElement* nextSibling = dom_characterdata_get_nextelementsibling(cdata);
    if (!nextSibling) {
        info.GetReturnValue().SetNull();
        return;
    }
    
    // TODO: Use ElementWrapper::Wrap when available
    info.GetReturnValue().SetNull();
}

} // namespace v8_dom
