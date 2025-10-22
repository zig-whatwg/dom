// Debug C API vs V8 wrapper
#include <v8.h>
#include <libplatform/libplatform.h>
#include <v8_dom.h>
#include <iostream>
#include <iomanip>
#include <cstring>
#include "dom.h"

void print_hex(const char* label, const char* str) {
    if (!str) {
        std::cout << label << ": (null)" << std::endl;
        return;
    }
    
    size_t len = strlen(str);
    std::cout << label << ": [" << str << "]" << std::endl;
    std::cout << "  strlen: " << len << std::endl;
    std::cout << "  hex: ";
    for (size_t i = 0; i < std::min(len, (size_t)20); i++) {
        std::cout << std::hex << std::setfill('0') << std::setw(2) 
                  << (int)(unsigned char)str[i] << " ";
    }
    std::cout << std::dec << std::endl;
}

int main(int argc, char* argv[]) {
    v8::V8::InitializeICUDefaultLocation(argv[0]);
    v8::V8::InitializeExternalStartupData(argv[0]);
    std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
    v8::V8::InitializePlatform(platform.get());
    v8::V8::Initialize();

    v8::Isolate::CreateParams create_params;
    create_params.array_buffer_allocator =
        v8::ArrayBuffer::Allocator::NewDefaultAllocator();
    v8::Isolate* isolate = v8::Isolate::New(create_params);

    {
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);

        v8::Local<v8::ObjectTemplate> global = v8::ObjectTemplate::New(isolate);
        v8_dom::InstallDOMBindings(isolate, global);

        v8::Local<v8::Context> context = v8::Context::New(isolate, nullptr, global);
        v8::Context::Scope context_scope(context);
        
        std::cout << "=== Creating element via JavaScript ===" << std::endl;
        
        // Create element and set attribute
        v8::TryCatch try_catch(isolate);
        const char* code = R"(
            var elem = document.createElement("test");
            elem.setAttribute("id", "test123");
            elem; // Return element
        )";
        
        v8::Local<v8::String> source = v8::String::NewFromUtf8(isolate, code).ToLocalChecked();
        v8::Local<v8::Script> script;
        if (!v8::Script::Compile(context, source).ToLocal(&script)) {
            v8::String::Utf8Value error(isolate, try_catch.Exception());
            std::cerr << "Compile error: " << *error << std::endl;
            return 1;
        }
        
        v8::Local<v8::Value> result;
        if (!script->Run(context).ToLocal(&result)) {
            v8::String::Utf8Value error(isolate, try_catch.Exception());
            std::cerr << "Runtime error: " << *error << std::endl;
            return 1;
        }
        
        // Now get the element's C pointer directly
        if (result->IsObject()) {
            v8::Local<v8::Object> elem_obj = result.As<v8::Object>();
            
            // Get internal field (the DOMElement pointer)
            if (elem_obj->InternalFieldCount() > 0) {
                DOMElement* elem_ptr = static_cast<DOMElement*>(
                    elem_obj->GetAlignedPointerFromInternalField(0));
                
                std::cout << "\nElement pointer: " << elem_ptr << std::endl;
                
                // Call C API directly
                std::cout << "\n=== Calling C API directly ===" << std::endl;
                const char* value_direct = dom_element_getattribute(elem_ptr, "id");
                print_hex("Direct C API", value_direct);
                
                // Call via JavaScript wrapper
                std::cout << "\n=== Calling via JavaScript wrapper ===" << std::endl;
                const char* js_code = "elem.getAttribute('id')";
                v8::Local<v8::String> js_source = v8::String::NewFromUtf8(isolate, js_code).ToLocalChecked();
                v8::Local<v8::Script> js_script;
                if (!v8::Script::Compile(context, js_source).ToLocal(&js_script)) {
                    v8::String::Utf8Value error(isolate, try_catch.Exception());
                    std::cerr << "Compile error: " << *error << std::endl;
                    return 1;
                }
                
                v8::Local<v8::Value> js_result;
                if (!js_script->Run(context).ToLocal(&js_result)) {
                    v8::String::Utf8Value error(isolate, try_catch.Exception());
                    std::cerr << "Runtime error: " << *error << std::endl;
                    return 1;
                }
                
                if (js_result->IsString()) {
                    v8::String::Utf8Value utf8(isolate, js_result);
                    print_hex("Via JS wrapper", *utf8);
                } else if (js_result->IsNull()) {
                    std::cout << "Via JS wrapper: null" << std::endl;
                } else {
                    std::cout << "Via JS wrapper: (not a string)" << std::endl;
                }
            }
        }
    }

    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;

    return 0;
}
