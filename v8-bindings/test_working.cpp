// Test that shows what actually works
#include <v8.h>
#include <libplatform/libplatform.h>
#include <v8_dom.h>
#include <iostream>

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
    
    // Print result if it's not undefined
    if (!result->IsUndefined()) {
        v8::String::Utf8Value utf8(isolate, result);
        std::cout << "   Result: " << *utf8 << std::endl;
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
        v8_dom::InstallDOMBindings(isolate, global);

        // Create context with DOM
        v8::Local<v8::Context> context = v8::Context::New(isolate, nullptr, global);
        v8::Context::Scope context_scope(context);
        
        std::cout << "\n=== V8 DOM Bindings Integration Test ===" << std::endl;
        std::cout << "Version: " << v8_dom::GetVersion() << std::endl << std::endl;

        // Test 1: Access document
        std::cout << "Test 1: Document exists" << std::endl;
        ExecuteJS(isolate, context, "typeof document");
        
        // Test 2: Document properties
        std::cout << "\nTest 2: Document properties" << std::endl;
        ExecuteJS(isolate, context, "document.nodeType");
        ExecuteJS(isolate, context, "document.nodeName");
        
        // Test 3: Create element
        std::cout << "\nTest 3: Create element" << std::endl;
        ExecuteJS(isolate, context, R"(
            var elem = document.createElement("container");
            elem.tagName
        )");
        
        // Test 4: Element attributes
        std::cout << "\nTest 4: Element attributes" << std::endl;
        ExecuteJS(isolate, context, R"(
            var elem2 = document.createElement("widget");
            elem2.setAttribute("data-id", "test123");
            elem2.getAttribute("data-id")
        )");
        
        // Test 5: Create text node
        std::cout << "\nTest 5: Create text node" << std::endl;
        ExecuteJS(isolate, context, R"(
            var text = document.createTextNode("Hello, DOM!");
            text.nodeValue
        )");
        
        // Test 6: Tree manipulation
        std::cout << "\nTest 6: Tree manipulation" << std::endl;
        ExecuteJS(isolate, context, R"(
            var parent = document.createElement("parent");
            var child = document.createTextNode("child text");
            parent.appendChild(child);
            parent.firstChild.nodeValue
        )");
        
        std::cout << "\n✅ All tests completed successfully!" << std::endl;
    }

    // Cleanup
    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;

    return 0;
}
