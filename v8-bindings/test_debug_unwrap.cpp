// Debug test to see what's happening with unwrapping
#include <v8.h>
#include <libplatform/libplatform.h>
#include <v8_dom.h>
#include <iostream>

int main(int argc, char* argv[]) {
    // Initialize V8
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
        
        std::cout << "Getting document..." << std::endl;
        v8::Local<v8::String> doc_key = v8::String::NewFromUtf8Literal(isolate, "document");
        v8::Local<v8::Value> doc_val = context->Global()->Get(context, doc_key).ToLocalChecked();
        
        if (doc_val->IsObject()) {
            std::cout << "✓ document is an object" << std::endl;
            v8::Local<v8::Object> doc_obj = doc_val.As<v8::Object>();
            
            std::cout << "Internal field count: " << doc_obj->InternalFieldCount() << std::endl;
            
            if (doc_obj->InternalFieldCount() > 0) {
                v8::Local<v8::Data> field0_data = doc_obj->GetInternalField(0);
                // Try to cast to Value
                v8::Local<v8::Value> field0;
                if (field0_data.As<v8::Value>().IsEmpty()) {
                    std::cout << "✗ Cannot cast field 0 to Value" << std::endl;
                } else {
                    field0 = field0_data.As<v8::Value>();
                    std::cout << "✓ Field 0 casts to Value" << std::endl;
                    std::cout << "Field 0 is External: " << (field0->IsExternal() ? "YES" : "NO") << std::endl;
                    
                    if (field0->IsExternal()) {
                        void* ptr = v8::Local<v8::External>::Cast(field0)->Value();
                        std::cout << "Pointer value: " << ptr << std::endl;
                        std::cout << "Pointer is null: " << (ptr == nullptr ? "YES" : "NO") << std::endl;
                    }
                }
            }
        } else {
            std::cout << "✗ document is not an object" << std::endl;
        }
    }

    isolate->Dispose();
    v8::V8::Dispose();
    v8::V8::DisposePlatform();
    delete create_params.array_buffer_allocator;

    return 0;
}
