/**
 * Utilities - Helper functions for V8 DOM bindings
 * 
 * String conversion, error handling, and common operations.
 */

#ifndef V8_DOM_UTILITIES_H
#define V8_DOM_UTILITIES_H

#include <v8.h>
#include "dom.h"

namespace v8_dom {

/**
 * Convert C string to V8 string.
 * Returns empty string for nullptr.
 */
inline v8::Local<v8::String> CStringToV8String(v8::Isolate* isolate, const char* str) {
    if (!str) {
        return v8::String::Empty(isolate);
    }
    return v8::String::NewFromUtf8(isolate, str).ToLocalChecked();
}

/**
 * Convert V8 string to std::string.
 */
inline std::string V8StringToStdString(v8::Isolate* isolate, v8::Local<v8::Value> value) {
    if (value.IsEmpty() || !value->IsString()) {
        return "";
    }
    v8::String::Utf8Value utf8(isolate, value);
    return std::string(*utf8, utf8.length());
}

/**
 * Throw a DOM exception in V8.
 * 
 * @param isolate V8 isolate
 * @param error_code DOM error code from C-ABI
 */
inline void ThrowDOMException(v8::Isolate* isolate, int32_t error_code) {
    if (error_code == 0) {
        return;  // No error
    }
    
    const char* name = dom_error_code_name(error_code);
    const char* message = dom_error_code_message(error_code);
    
    v8::Local<v8::String> error_name = CStringToV8String(isolate, name);
    v8::Local<v8::String> error_message = CStringToV8String(isolate, message);
    
    // Create DOMException-like error
    v8::Local<v8::Object> error = v8::Exception::Error(error_message)
        ->ToObject(isolate->GetCurrentContext()).ToLocalChecked();
    
    error->Set(isolate->GetCurrentContext(),
              v8::String::NewFromUtf8Literal(isolate, "name"),
              error_name).Check();
    
    error->Set(isolate->GetCurrentContext(),
              v8::String::NewFromUtf8Literal(isolate, "code"),
              v8::Integer::New(isolate, error_code)).Check();
    
    isolate->ThrowException(error);
}

/**
 * Check if a V8 value is null or undefined.
 */
inline bool IsNullOrUndefined(v8::Local<v8::Value> value) {
    return value.IsEmpty() || value->IsNull() || value->IsUndefined();
}

/**
 * Get C string from V8 value (for passing to C-ABI).
 * Returns nullptr for null/undefined.
 * 
 * WARNING: The returned pointer is only valid while the Utf8Value object lives!
 * Store the Utf8Value on the stack if you need the pointer.
 */
class CStringFromV8 {
public:
    explicit CStringFromV8(v8::Isolate* isolate, v8::Local<v8::Value> value)
        : utf8_(isolate, value) {}
    
    const char* get() const {
        return *utf8_;
    }
    
    operator const char*() const {
        return *utf8_;
    }
    
private:
    v8::String::Utf8Value utf8_;
};

} // namespace v8_dom

#endif // V8_DOM_UTILITIES_H
