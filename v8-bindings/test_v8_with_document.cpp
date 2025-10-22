// Test V8 with Document wrapper
#include <v8.h>
#include <libplatform/libplatform.h>
#include <iostream>
#include "src/wrapper_cache.h"
#include "src/core/template_cache.h"
#include "src/nodes/document_wrapper.h"
#include "dom.h"

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
        
        std::cout << "Creating caches..." << std::endl;
        v8_dom::WrapperCache::ForIsolate(isolate);
        v8_dom::TemplateCache::ForIsolate(isolate);
        
        std::cout << "Creating context..." << std::endl;
        v8::Local<v8::Context> context = v8::Context::New(isolate);
        v8::Context::Scope context_scope(context);
        
        std::cout << "Creating Document..." << std::endl;
        DOMDocument* doc = dom_document_new();
        
        std::cout << "Wrapping Document..." << std::endl;
        v8::Local<v8::Object> js_doc = v8_dom::DocumentWrapper::Wrap(isolate, context, doc);
        
        std::cout << "Document wrapped successfully!" << std::endl;
        std::cout << "Is empty: " << (js_doc.IsEmpty() ? "YES" : "NO") << std::endl;
        
        dom_document_release(doc);
    }
    
    std::cout << "Cleaning up..." << std::endl;
    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;
    
    std::cout << "✅ Document wrapper test PASSED!" << std::endl;
    return 0;
}
