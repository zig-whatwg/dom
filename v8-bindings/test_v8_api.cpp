#include <v8.h>
#include <iostream>

int main() {
    // Just test if we can access ObjectTemplate methods
    v8::Isolate::CreateParams params;
    v8::Isolate* isolate = v8::Isolate::New(params);
    
    {
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);
        
        v8::Local<v8::ObjectTemplate> tmpl = v8::ObjectTemplate::New(isolate);
        
        // Try to see what methods are available
        std::cout << "V8 API test compiled successfully" << std::endl;
    }
    
    isolate->Dispose();
    return 0;
}
