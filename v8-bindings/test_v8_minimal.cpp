// Minimal V8 test - NO DOM, just V8 initialization
#include <v8.h>
#include <libplatform/libplatform.h>
#include <iostream>

int main(int argc, char* argv[]) {
    std::cout << "Step 1: Initializing V8..." << std::endl;
    
    v8::V8::InitializeICUDefaultLocation(argv[0]);
    v8::V8::InitializeExternalStartupData(argv[0]);
    
    std::cout << "Step 2: Creating platform..." << std::endl;
    std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
    v8::V8::InitializePlatform(platform.get());
    
    std::cout << "Step 3: Initializing V8 engine..." << std::endl;
    v8::V8::Initialize();
    
    std::cout << "Step 4: Creating isolate..." << std::endl;
    v8::Isolate::CreateParams create_params;
    create_params.array_buffer_allocator =
        v8::ArrayBuffer::Allocator::NewDefaultAllocator();
    v8::Isolate* isolate = v8::Isolate::New(create_params);
    
    {
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);
        
        std::cout << "Step 5: Creating context..." << std::endl;
        v8::Local<v8::Context> context = v8::Context::New(isolate);
        v8::Context::Scope context_scope(context);
        
        std::cout << "Step 6: Running simple JavaScript..." << std::endl;
        const char* code = "1 + 2";
        v8::Local<v8::String> source = 
            v8::String::NewFromUtf8(isolate, code).ToLocalChecked();
        v8::Local<v8::Script> script = 
            v8::Script::Compile(context, source).ToLocalChecked();
        v8::Local<v8::Value> result = script->Run(context).ToLocalChecked();
        
        v8::String::Utf8Value utf8(isolate, result);
        std::cout << "Result: " << *utf8 << std::endl;
    }
    
    std::cout << "Step 7: Cleaning up..." << std::endl;
    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;
    
    std::cout << "✅ V8 minimal test PASSED!" << std::endl;
    return 0;
}
