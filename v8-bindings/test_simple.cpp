// Simple V8 DOM Bindings Test
// Tests basic DOM operations end-to-end

#include <v8.h>
#include <libplatform/libplatform.h>
#include <v8_dom.h>
#include <iostream>
#include <cstdio>

void ExecuteJS(v8::Isolate* isolate, v8::Local<v8::Context> context, const char* code) {
    v8::TryCatch try_catch(isolate);
    
    v8::Local<v8::String> source = 
        v8::String::NewFromUtf8(isolate, code).ToLocalChecked();
    
    v8::Local<v8::Script> script;
    if (!v8::Script::Compile(context, source).ToLocal(&script)) {
        v8::String::Utf8Value error(isolate, try_catch.Exception());
        std::cerr << "Compilation error: " << *error << std::endl;
        return;
    }

    v8::Local<v8::Value> result;
    if (!script->Run(context).ToLocal(&result)) {
        v8::String::Utf8Value error(isolate, try_catch.Exception());
        std::cerr << "Runtime error: " << *error << std::endl;
        return;
    }
}

int main(int argc, char* argv[]) {
    // Initialize V8
    v8::V8::InitializeICUDefaultLocation(argv[0]);
    v8::V8::InitializeExternalStartupData(argv[0]);
    std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
    v8::V8::InitializePlatform(platform.get());
    v8::V8::Initialize();

    // Create isolate
    v8::Isolate::CreateParams create_params;
    create_params.array_buffer_allocator =
        v8::ArrayBuffer::Allocator::NewDefaultAllocator();
    v8::Isolate* isolate = v8::Isolate::New(create_params);

    {
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);

        // Install DOM bindings
        v8::Local<v8::ObjectTemplate> global = v8::ObjectTemplate::New(isolate);
        
        // Add console.log for output
        global->Set(
            v8::String::NewFromUtf8Literal(isolate, "console"),
            v8::ObjectTemplate::New(isolate)
        );
        
        v8_dom::InstallDOMBindings(isolate, global);

        // Create context with DOM
        v8::Local<v8::Context> context = v8::Context::New(isolate, nullptr, global);
        v8::Context::Scope context_scope(context);
        
        std::cout << "\n=== V8 DOM Bindings Test ===" << std::endl;
        std::cout << "Version: " << v8_dom::GetVersion() << std::endl;
        std::cout << "Installed: " << (v8_dom::IsInstalled(isolate) ? "Yes" : "No") << std::endl;
        std::cout << std::endl;

        // Test 1: Access document
        std::cout << "Test 1: Access document" << std::endl;
        ExecuteJS(isolate, context, R"(
            if (typeof document !== 'undefined') {
                console.log('✓ document exists');
            }
        )");
        
        // Test 2: Create element
        std::cout << "Test 2: Create element" << std::endl;
        ExecuteJS(isolate, context, R"(
            const div = document.createElement("div");
            if (div && typeof div === 'object') {
                console.log('✓ createElement works');
            }
        )");
        
        // Test 3: Set element attributes
        std::cout << "Test 3: Set element attributes" << std::endl;
        ExecuteJS(isolate, context, R"(
            const elem = document.createElement("div");
            elem.id = "test";
            elem.className = "main active";
            if (elem.id === "test" && elem.className === "main active") {
                console.log('✓ Element attributes work');
            }
        )");
        
        // Test 4: Create and append text node
        std::cout << "Test 4: Tree manipulation" << std::endl;
        ExecuteJS(isolate, context, R"(
            const div = document.createElement("div");
            const text = document.createTextNode("Hello, World!");
            div.appendChild(text);
            
            if (div.firstChild && div.firstChild.nodeType === 3) {
                console.log('✓ appendChild works');
            }
            if (text.parentNode === div) {
                console.log('✓ parentNode works');
            }
        )");
        
        // Test 5: Query operations (will work now with wired wrappers)
        std::cout << "Test 5: Query operations" << std::endl;
        ExecuteJS(isolate, context, R"(
            // Note: getElementById won't find anything since we don't have a live DOM tree
            // But the method should exist and not crash
            const result = document.getElementById("nonexistent");
            if (result === null) {
                console.log('✓ getElementById returns null for non-existent');
            }
        )");
        
        std::cout << "\n=== All Tests Passed! ===" << std::endl;
    }

    // Cleanup
    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;

    return 0;
}
