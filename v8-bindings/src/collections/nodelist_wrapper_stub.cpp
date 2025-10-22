// Stub implementation for NodeListWrapper
// TODO: Implement full NodeListWrapper

#include "../collections/nodelist_wrapper.h"

namespace v8_dom {

v8::Local<v8::Object> NodeListWrapper::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              DOMNodeList* list) {
    // Return empty array for now
    return v8::Array::New(isolate, 0);
}

} // namespace v8_dom
