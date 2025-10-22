// Detailed test with explicit checks
#include <v8.h>
#include <libplatform/libplatform.h>
#include <iostream>
#include "src/wrapper_cache.h"
#include "src/core/template_cache.h"
#include "src/nodes/document_wrapper.h"
#include "src/nodes/node_wrapper.h"
#include "dom.h"

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
        
        std::cout << "Creating DOMDocument..." << std::endl;
        DOMDocument* doc = dom_document_new();
        std::cout << "  C pointer: " << (void*)doc << std::endl;
        
        std::cout << "\nWrapping Document..." << std::endl;
        v8::Local<v8::Object> js_doc = v8_dom::DocumentWrapper::Wrap(isolate, context, doc);
        std::cout << "  JS object empty: " << (js_doc.IsEmpty() ? "YES" : "NO") << std::endl;
        std::cout << "  Internal fields: " << js_doc->InternalFieldCount() << std::endl;
        
        std::cout << "\nUnwrapping Document..." << std::endl;
        DOMDocument* unwrapped_doc = v8_dom::DocumentWrapper::Unwrap(js_doc);
        std::cout << "  Unwrapped pointer: " << (void*)unwrapped_doc << std::endl;
        std::cout << "  Pointers match: " << (doc == unwrapped_doc ? "YES" : "NO") << std::endl;
        
        std::cout << "\nUnwrapping as Node..." << std::endl;
        DOMNode* unwrapped_node = v8_dom::NodeWrapper::Unwrap(js_doc);
        std::cout << "  Unwrapped as node: " << (void*)unwrapped_node << std::endl;
        std::cout << "  Node is null: " << (unwrapped_node == nullptr ? "YES" : "NO") << std::endl;
        
        if (unwrapped_node) {
            std::cout << "\nCalling dom_node_get_nodetype..." << std::endl;
            uint16_t nodeType = dom_node_get_nodetype(unwrapped_node);
            std::cout << "  NodeType: " << nodeType << std::endl;
        }
        
        dom_document_release(doc);
    }

    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;

    return 0;
}
