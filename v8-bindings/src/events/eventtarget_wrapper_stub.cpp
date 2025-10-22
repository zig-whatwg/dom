// Stub implementation for EventTargetWrapper
// TODO: Implement full EventTargetWrapper

#include "../nodes/eventtarget_wrapper.h"

namespace v8_dom {

v8::Local<v8::FunctionTemplate> EventTargetWrapper::GetTemplate(v8::Isolate* isolate) {
    return v8::FunctionTemplate::New(isolate);
}

v8::Local<v8::Object> EventTargetWrapper::Wrap(v8::Isolate* isolate,
                                                 v8::Local<v8::Context> context,
                                                 DOMEventTarget* target) {
    return v8::Object::New(isolate);
}

} // namespace v8_dom
