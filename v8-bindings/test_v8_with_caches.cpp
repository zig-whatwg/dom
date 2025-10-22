// Test V8 with just our cache classes
#include <v8.h>
#include <libplatform/libplatform.h>
#include <iostream>
#include "src/wrapper_cache.h"
#include "src/core/template_cache.h"

int main(int argc, char* argv[]) {
    std::cout << "Initializing V8..." << std::endl;
    v8::V8::InitializeICUDefaultLocation(argv[0]);
    v8::V8::InitializeExternalStartupData(argv[0]);
    std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
    v8::V8::InitializePlatform(platform.get());
    v8::V8::Initialize();
    
    std::cout << "Creating isolate..." << std::endl;
    v8::Isolate::CreateParams create_params;
    create_params.array_buffer_allocator =
        v8::ArrayBuffer::Allocator::NewDefaultAllocator();
    v8::Isolate* isolate = v8::Isolate::New(create_params);
    
    {
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);
        
        std::cout << "Creating WrapperCache..." << std::endl;
        v8_dom::WrapperCache* wrapper_cache = v8_dom::WrapperCache::ForIsolate(isolate);
        std::cout << "WrapperCache created: " << (wrapper_cache ? "YES" : "NO") << std::endl;
        
        std::cout << "Creating TemplateCache..." << std::endl;
        v8_dom::TemplateCache* template_cache = v8_dom::TemplateCache::ForIsolate(isolate);
        std::cout << "TemplateCache created: " << (template_cache ? "YES" : "NO") << std::endl;
        
        std::cout << "Creating context..." << std::endl;
        v8::Local<v8::Context> context = v8::Context::New(isolate);
        v8::Context::Scope context_scope(context);
        
        std::cout << "Running JavaScript..." << std::endl;
        const char* code = "2 + 3";
        v8::Local<v8::String> source = 
            v8::String::NewFromUtf8(isolate, code).ToLocalChecked();
        v8::Local<v8::Script> script = 
            v8::Script::Compile(context, source).ToLocalChecked();
        v8::Local<v8::Value> result = script->Run(context).ToLocalChecked();
        
        v8::String::Utf8Value utf8(isolate, result);
        std::cout << "Result: " << *utf8 << std::endl;
    }
    
    std::cout << "Cleaning up..." << std::endl;
    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;
    
    std::cout << "✅ Cache test PASSED!" << std::endl;
    return 0;
}
