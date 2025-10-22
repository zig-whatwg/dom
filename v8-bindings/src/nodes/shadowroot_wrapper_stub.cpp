// Stub implementation for ShadowRootWrapper
// TODO: Implement full ShadowRootWrapper

#include "../shadow/shadowroot_wrapper.h"

namespace v8_dom {

v8::Local<v8::Object> ShadowRootWrapper::Wrap(v8::Isolate* isolate,
                                                v8::Local<v8::Context> context,
                                                DOMShadowRoot* root) {
    return v8::Object::New(isolate);
}

} // namespace v8_dom
