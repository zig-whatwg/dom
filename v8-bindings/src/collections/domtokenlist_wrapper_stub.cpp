// Stub implementation for DOMTokenListWrapper
// TODO: Implement full DOMTokenListWrapper

#include "../collections/domtokenlist_wrapper.h"

namespace v8_dom {

v8::Local<v8::Object> DOMTokenListWrapper::Wrap(v8::Isolate* isolate,
                                                  v8::Local<v8::Context> context,
                                                  DOMDOMTokenList* list) {
    // Return empty array for now
    return v8::Array::New(isolate, 0);
}

} // namespace v8_dom
