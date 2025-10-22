// Test string encoding
#include <v8.h>
#include <libplatform/libplatform.h>
#include <v8_dom.h>
#include <iostream>
#include <iomanip>

void ExecuteJS(v8::Isolate* isolate, v8::Local<v8::Context> context, const char* code) {
    v8::TryCatch try_catch(isolate);
    
    v8::Local<v8::String> source = 
        v8::String::NewFromUtf8(isolate, code).ToLocalChecked();
    
    v8::Local<v8::Script> script;
    if (!v8::Script::Compile(context, source).ToLocal(&script)) {
        v8::String::Utf8Value error(isolate, try_catch.Exception());
        std::cerr << "❌ Compilation error: " << *error << std::endl;
        return;
    }

    v8::Local<v8::Value> result;
    if (!script->Run(context).ToLocal(&result)) {
        v8::String::Utf8Value error(isolate, try_catch.Exception());
        std::cerr << "❌ Runtime error: " << *error << std::endl;
        return;
    }
    
    // Print result as UTF-8 string
    v8::String::Utf8Value utf8(isolate, result);
    std::cout << "Result: [" << *utf8 << "]" << std::endl;
    std::cout << "Length: " << utf8.length() << " bytes" << std::endl;
    
    // Print hex dump
    std::cout << "Hex: ";
    for (int i = 0; i < utf8.length(); i++) {
        std::cout << std::hex << std::setfill('0') << std::setw(2) 
                  << (int)(unsigned char)(*utf8)[i] << " ";
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
        
        std::cout << "Test: setAttribute/getAttribute" << std::endl;
        ExecuteJS(isolate, context, R"(
            var elem = document.createElement("test");
            elem.setAttribute("id", "test123");
            elem.getAttribute("id")
        )");
        
        std::cout << "\nTest: Direct string" << std::endl;
        ExecuteJS(isolate, context, "'test123'");
    }

    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;

    return 0;
}
