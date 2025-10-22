#include "event_wrapper.h"
#include "../wrapper_cache.h"
#include "../core/template_cache.h"
#include "../core/utilities.h"

namespace v8_dom {

v8::Local<v8::Object> EventWrapper::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              DOMEvent* obj) {
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
    dom_event_addref(obj);
    
    // Cache with release callback
    cache->Set(isolate, obj, wrapper, [](void* ptr) {
        dom_event_release(static_cast<DOMEvent*>(ptr));
    });
    
    return handle_scope.Escape(wrapper);
}

DOMEvent* EventWrapper::Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    v8::Local<v8::Value> ptr = obj->GetInternalField(0).As<v8::Value>();
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMEvent*>(v8::Local<v8::External>::Cast(ptr)->Value());
}

void EventWrapper::InstallTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "Event"));
    tmpl->InstanceTemplate()->SetInternalFieldCount(1);
    

    // Get prototype template for adding properties/methods
    v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
    
    // Readonly properties
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "target"),
                                 TargetGetter);
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "currentTarget"),
                                 CurrentTargetGetter);
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "srcElement"),
                                 SrcElementGetter);
    
    // Read/write properties
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "cancelBubble"),
                                 CancelBubbleGetter, CancelBubbleSetter);
    proto->SetNativeDataProperty(v8::String::NewFromUtf8Literal(isolate, "returnValue"),
                                 ReturnValueGetter, ReturnValueSetter);
    
    // Methods
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "stopPropagation"),
               v8::FunctionTemplate::New(isolate, StopPropagation));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "stopImmediatePropagation"),
               v8::FunctionTemplate::New(isolate, StopImmediatePropagation));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "preventDefault"),
               v8::FunctionTemplate::New(isolate, PreventDefault));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "initEvent"),
               v8::FunctionTemplate::New(isolate, InitEvent));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "composedPath"),
               v8::FunctionTemplate::New(isolate, ComposedPath));
    
    // Cache the template
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    cache->Set(kTemplateIndex, tmpl);
}

v8::Local<v8::FunctionTemplate> EventWrapper::GetTemplate(v8::Isolate* isolate) {
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    
    if (!cache->Has(kTemplateIndex)) {
        InstallTemplate(isolate);
    }
    
    return cache->Get(kTemplateIndex);
}

// ===== Readonly Property Getters =====

void EventWrapper::TargetGetter(v8::Local<v8::Name> property,
                               const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMEvent* event = Unwrap(info.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    DOMEventTarget* target = dom_event_get_target(event);
    if (!target) {
        info.GetReturnValue().SetNull();
        return;
    }
    
    // TODO: Use EventTargetWrapper::Wrap when available
    info.GetReturnValue().SetNull();
}

void EventWrapper::CurrentTargetGetter(v8::Local<v8::Name> property,
                                      const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMEvent* event = Unwrap(info.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    DOMEventTarget* currentTarget = dom_event_get_currenttarget(event);
    if (!currentTarget) {
        info.GetReturnValue().SetNull();
        return;
    }
    
    // TODO: Use EventTargetWrapper::Wrap when available
    info.GetReturnValue().SetNull();
}

void EventWrapper::SrcElementGetter(v8::Local<v8::Name> property,
                                   const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMEvent* event = Unwrap(info.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    DOMEventTarget* srcElement = dom_event_get_srcelement(event);
    if (!srcElement) {
        info.GetReturnValue().SetNull();
        return;
    }
    
    // TODO: Use EventTargetWrapper::Wrap when available
    info.GetReturnValue().SetNull();
}

// ===== Read/Write Property Getters/Setters =====

void EventWrapper::CancelBubbleGetter(v8::Local<v8::Name> property,
                                     const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMEvent* event = Unwrap(info.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    uint8_t cancelBubble = dom_event_get_cancelbubble(event);
    info.GetReturnValue().Set(v8::Boolean::New(isolate, cancelBubble != 0));
}

void EventWrapper::CancelBubbleSetter(v8::Local<v8::Name> property,
                                     v8::Local<v8::Value> value,
                                     const v8::PropertyCallbackInfo<void>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMEvent* event = Unwrap(info.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    bool boolValue = value->BooleanValue(isolate);
    dom_event_set_cancelbubble(event, boolValue ? 1 : 0);
}

void EventWrapper::ReturnValueGetter(v8::Local<v8::Name> property,
                                    const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMEvent* event = Unwrap(info.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    uint8_t returnValue = dom_event_get_returnvalue(event);
    info.GetReturnValue().Set(v8::Boolean::New(isolate, returnValue != 0));
}

void EventWrapper::ReturnValueSetter(v8::Local<v8::Name> property,
                                    v8::Local<v8::Value> value,
                                    const v8::PropertyCallbackInfo<void>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMEvent* event = Unwrap(info.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    bool boolValue = value->BooleanValue(isolate);
    dom_event_set_returnvalue(event, boolValue ? 1 : 0);
}

// ===== Methods =====

void EventWrapper::StopPropagation(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMEvent* event = Unwrap(args.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    dom_event_stoppropagation(event);
}

void EventWrapper::StopImmediatePropagation(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMEvent* event = Unwrap(args.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    dom_event_stopimmediatepropagation(event);
}

void EventWrapper::PreventDefault(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMEvent* event = Unwrap(args.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    dom_event_preventdefault(event);
}

void EventWrapper::InitEvent(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMEvent* event = Unwrap(args.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    if (args.Length() < 1 || !args[0]->IsString()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Event type required")));
        return;
    }
    
    v8::String::Utf8Value type(isolate, args[0]);
    
    uint8_t bubbles = 0;
    if (args.Length() >= 2 && args[1]->IsBoolean()) {
        bubbles = args[1]->BooleanValue(isolate) ? 1 : 0;
    }
    
    uint8_t cancelable = 0;
    if (args.Length() >= 3 && args[2]->IsBoolean()) {
        cancelable = args[2]->BooleanValue(isolate) ? 1 : 0;
    }
    
    dom_event_initevent(event, *type, bubbles, cancelable);
}

void EventWrapper::ComposedPath(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMEvent* event = Unwrap(args.This());
    
    if (!event) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Event object")));
        return;
    }
    
    uint32_t count = 0;
    DOMEventTarget** path = dom_event_composedpath(event, &count);
    
    if (!path) {
        args.GetReturnValue().Set(v8::Array::New(isolate, 0));
        return;
    }
    
    v8::Local<v8::Array> result = v8::Array::New(isolate, count);
    
    for (uint32_t i = 0; i < count; i++) {
        // TODO: Use EventTargetWrapper::Wrap when available
        result->Set(context, i, v8::Null(isolate)).Check();
    }
    
    dom_event_free_composedpath(path, count);
    args.GetReturnValue().Set(result);
}

} // namespace v8_dom
