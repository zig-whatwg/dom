#include "text_wrapper.h"
#include "../wrapper_cache.h"
#include "../core/template_cache.h"
#include "../core/utilities.h"

namespace v8_dom {

v8::Local<v8::Object> TextWrapper::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              DOMText* obj) {
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
    
    // Increment C-side reference count (Text inherits from Node)
    dom_node_addref((DOMNode*)obj);
    
    // Cache with release callback
    cache->Set(isolate, obj, wrapper, [](void* ptr) {
        dom_node_release((DOMNode*)static_cast<DOMText*>(ptr));
    });
    
    return handle_scope.Escape(wrapper);
}

DOMText* TextWrapper::Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    v8::Local<v8::Data> data = obj->GetInternalField(0);
    v8::Local<v8::Value> ptr = data.As<v8::Value>();
    if (ptr.IsEmpty()) return nullptr;
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMText*>(v8::Local<v8::External>::Cast(ptr)->Value());
}

void TextWrapper::InstallTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "Text"));
    tmpl->InstanceTemplate()->SetInternalFieldCount(1);
    
    // Inherit from CharacterData
    tmpl->Inherit(CharacterDataWrapper::GetTemplate(isolate));

    // Get prototype template for adding properties/methods
    v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
    
    // Readonly property
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "wholeText"),
                                 WholeTextGetter);
    
    // Methods
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "splitText"),
               v8::FunctionTemplate::New(isolate, SplitText));
    
    // Cache the template
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    cache->Set(kTemplateIndex, tmpl);
}

v8::Local<v8::FunctionTemplate> TextWrapper::GetTemplate(v8::Isolate* isolate) {
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    
    if (!cache->Has(kTemplateIndex)) {
        InstallTemplate(isolate);
    }
    
    return cache->Get(kTemplateIndex);
}

// ===== Property Getter =====

void TextWrapper::WholeTextGetter(v8::Local<v8::Name> property,
                                 const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMText* text = Unwrap(info.This());
    
    if (!text) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Text object")));
        return;
    }
    
    const char* wholeText = dom_text_get_wholetext(text);
    if (wholeText) {
        info.GetReturnValue().Set(v8::String::NewFromUtf8(isolate, wholeText).ToLocalChecked());
        dom_text_free_wholetext(wholeText);
    } else {
        info.GetReturnValue().SetEmptyString();
    }
}

// ===== Methods =====

void TextWrapper::SplitText(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    
    DOMText* text = Unwrap(args.This());
    if (!text) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Text object")));
        return;
    }
    
    if (args.Length() < 1 || !args[0]->IsNumber()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Offset argument required")));
        return;
    }
    
    uint32_t offset = args[0]->Uint32Value(context).FromJust();
    DOMText* newText = dom_text_splittext(text, offset);
    
    if (!newText) {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8Literal(isolate, "Failed to split text")));
        return;
    }
    
    // Wrap and return the new Text node
    v8::Local<v8::Object> wrapper = Wrap(isolate, context, newText);
    args.GetReturnValue().Set(wrapper);
}

} // namespace v8_dom
