// Test wrapper string handling
#include <v8.h>
#include <libplatform/libplatform.h>
#include <iostream>
#include <iomanip>
#include <cstring>
#include "src/wrapper_cache.h"
#include "src/core/template_cache.h"
#include "src/nodes/document_wrapper.h"
#include "src/nodes/element_wrapper.h"
#include "dom.h"

void print_hex(const char* label, const char* str) {
    if (!str) {
        std::cout << label << ": (null)" << std::endl;
        return;
    }
    
    size_t len = strlen(str);
    std::cout << label << ": [" << str << "]" << std::endl;
    std::cout << "  C strlen: " << len << " bytes" << std::endl;
    std::cout << "  Hex: ";
    for (size_t i = 0; i < len && i < 20; i++) {
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

        v8_dom::WrapperCache::ForIsolate(isolate);
        v8_dom::TemplateCache::ForIsolate(isolate);

        v8::Local<v8::Context> context = v8::Context::New(isolate);
        v8::Context::Scope context_scope(context);
        
        // Create document and element directly
        std::cout << "Creating document and element via C API..." << std::endl;
        DOMDocument* doc = dom_document_new();
        DOMElement* elem = dom_document_createelement(doc, "test");
        
        // Set attribute via C API
        std::cout << "\nSetting attribute via C API..." << std::endl;
        dom_element_setattribute(elem, "id", "test123");
        
        // Get attribute via C API
        std::cout << "\nGetting attribute via C API..." << std::endl;
        const char* value_c = dom_element_getattribute(elem, "id");
        print_hex("C API result", value_c);
        
        // Now wrap the element
        std::cout << "\nWrapping element..." << std::endl;
        v8::Local<v8::Object> js_elem = v8_dom::ElementWrapper::Wrap(isolate, context, elem);
        
        // Try to get attribute via JavaScript
        std::cout << "\nGetting attribute via JavaScript..." << std::endl;
        v8::Local<v8::String> get_attr_code = v8::String::NewFromUtf8Literal(isolate, 
            "arguments[0].getAttribute('id')");
        v8::Local<v8::Script> script = v8::Script::Compile(context, get_attr_code).ToLocalChecked();
        
        v8::Local<v8::Value> argv[1] = { js_elem };
        v8::Local<v8::Function> func = script->Run(context).ToLocalChecked().As<v8::Function>();
        v8::Local<v8::Value> result = func->Call(context, context->Global(), 1, argv).ToLocalChecked();
        
        if (result->IsString()) {
            v8::String::Utf8Value utf8(isolate, result);
            print_hex("JS result", *utf8);
        }
        
        dom_element_release(elem);
        dom_document_release(doc);
    }

    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;

    return 0;
}
