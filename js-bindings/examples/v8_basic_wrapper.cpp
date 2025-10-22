/**
 * V8 Basic Integration Example
 * 
 * This example shows how to wrap a single DOM class (Element) for V8.
 * It demonstrates the fundamental patterns needed for V8 integration:
 * - Wrapping opaque C pointers in V8 objects
 * - Exposing C functions as JavaScript methods
 * - Memory management with V8's GC
 * 
 * Prerequisites:
 *   1. Install V8:
 *      - Download from https://v8.dev/docs/embed
 *      - Or build from source: https://v8.dev/docs/build
 *   
 *   2. Build the DOM library:
 *      cd /path/to/dom
 *      zig build
 *      # Creates zig-out/lib/libdom.a
 * 
 * Build:
 *   clang++ -std=c++17 v8_basic_wrapper.cpp \
 *     -I/path/to/v8/include \
 *     -L/path/to/v8/lib \
 *     -lv8_monolith \
 *     -L../../zig-out/lib -ldom \
 *     -lpthread -o v8_basic_wrapper
 * 
 * Run:
 *   ./v8_basic_wrapper
 * 
 * Expected output:
 *   Creating DOM structure in C...
 *   Wrapping Element for JavaScript...
 *   
 *   Executing JavaScript code...
 *   JavaScript executing...
 *   element.tagName = div
 *   element.id = container
 *   element.getAttribute("data-test") = hello
 *   After modification:
 *   element.id = modified-container
 *   element.getAttribute("data-test") = world
 *   
 *   Verifying changes in C...
 *   C: element.id = modified-container
 *   C: element.getAttribute('data-test') = world
 *   GC: Released Element (C-side)
 *   
 *   Success! V8 integration working correctly.
 * 
 * Based on Chromium's Blink bindings architecture.
 */

#include <v8.h>
#include <libplatform/libplatform.h>
#include <iostream>
#include "../dom.h"

using namespace v8;

// Global slot index for storing the C pointer in V8 internal fields
static const int kElementPointerIndex = 0;

/**
 * WeakCallback for Element objects.
 * Called by V8 GC when JavaScript wrapper is collected.
 * This is where we release the C-side DOM reference.
 */
void ElementWeakCallback(const WeakCallbackInfo<void>& data) {
    // Get the C pointer from callback data
    DOMElement* elem = static_cast<DOMElement*>(data.GetParameter());
    
    // Release the C-side reference (decrements ref_count)
    dom_element_release(elem);
    
    std::cout << "GC: Released Element (C-side)" << std::endl;
}

/**
 * Extract the C DOMElement pointer from a V8 object.
 * 
 * This is a critical helper used by all wrapped methods.
 * It safely extracts the opaque pointer we stored in the internal field.
 */
DOMElement* UnwrapElement(Local<Object> obj) {
    if (obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    // Get the pointer from internal field 0
    Local<Value> ptr_val = obj->GetInternalField(kElementPointerIndex);
    if (ptr_val.IsEmpty() || !ptr_val->IsExternal()) {
        return nullptr;
    }
    
    // Cast back to DOMElement*
    return static_cast<DOMElement*>(Local<External>::Cast(ptr_val)->Value());
}

/**
 * Element.tagName getter
 * 
 * JavaScript: element.tagName
 * C API: dom_element_get_tagname(elem)
 */
void Element_TagNameGetter(Local<Name> property,
                            const PropertyCallbackInfo<Value>& info) {
    Isolate* isolate = info.GetIsolate();
    
    // Unwrap the C pointer
    DOMElement* elem = UnwrapElement(info.Holder());
    if (!elem) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "Invalid Element").ToLocalChecked()));
        return;
    }
    
    // Call C API
    const char* tag_name = dom_element_get_tagname(elem);
    
    // Convert C string to V8 string (borrowed, so no free needed)
    Local<String> result = String::NewFromUtf8(isolate, tag_name).ToLocalChecked();
    info.GetReturnValue().Set(result);
}

/**
 * Element.id getter
 * 
 * JavaScript: element.id
 * C API: dom_element_get_id(elem)
 */
void Element_IdGetter(Local<Name> property,
                      const PropertyCallbackInfo<Value>& info) {
    Isolate* isolate = info.GetIsolate();
    
    DOMElement* elem = UnwrapElement(info.Holder());
    if (!elem) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "Invalid Element").ToLocalChecked()));
        return;
    }
    
    const char* id = dom_element_get_id(elem);
    Local<String> result = String::NewFromUtf8(isolate, id).ToLocalChecked();
    info.GetReturnValue().Set(result);
}

/**
 * Element.id setter
 * 
 * JavaScript: element.id = "myId"
 * C API: dom_element_set_id(elem, "myId")
 */
void Element_IdSetter(Local<Name> property,
                      Local<Value> value,
                      const PropertyCallbackInfo<void>& info) {
    Isolate* isolate = info.GetIsolate();
    
    DOMElement* elem = UnwrapElement(info.Holder());
    if (!elem) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "Invalid Element").ToLocalChecked()));
        return;
    }
    
    // Convert V8 string to C string
    String::Utf8Value id_utf8(isolate, value);
    const char* id = *id_utf8;
    
    // Call C API (returns error code)
    int32_t err = dom_element_set_id(elem, id);
    if (err != 0) {
        const char* err_msg = dom_error_code_message(err);
        isolate->ThrowException(Exception::Error(
            String::NewFromUtf8(isolate, err_msg).ToLocalChecked()));
    }
}

/**
 * Element.getAttribute(name)
 * 
 * JavaScript: element.getAttribute("href")
 * C API: dom_element_getattribute(elem, "href")
 */
void Element_GetAttribute(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate();
    
    // Validate arguments
    if (args.Length() < 1) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "getAttribute requires 1 argument").ToLocalChecked()));
        return;
    }
    
    DOMElement* elem = UnwrapElement(args.Holder());
    if (!elem) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "Invalid Element").ToLocalChecked()));
        return;
    }
    
    // Get attribute name
    String::Utf8Value name_utf8(isolate, args[0]);
    const char* name = *name_utf8;
    
    // Call C API
    const char* value = dom_element_getattribute(elem, name);
    
    // Return null if attribute doesn't exist
    if (!value) {
        args.GetReturnValue().SetNull();
        return;
    }
    
    // Return attribute value
    Local<String> result = String::NewFromUtf8(isolate, value).ToLocalChecked();
    args.GetReturnValue().Set(result);
}

/**
 * Element.setAttribute(name, value)
 * 
 * JavaScript: element.setAttribute("href", "https://example.com")
 * C API: dom_element_setattribute(elem, "href", "https://example.com")
 */
void Element_SetAttribute(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate();
    
    if (args.Length() < 2) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "setAttribute requires 2 arguments").ToLocalChecked()));
        return;
    }
    
    DOMElement* elem = UnwrapElement(args.Holder());
    if (!elem) {
        isolate->ThrowException(Exception::TypeError(
            String::NewFromUtf8(isolate, "Invalid Element").ToLocalChecked()));
        return;
    }
    
    String::Utf8Value name_utf8(isolate, args[0]);
    String::Utf8Value value_utf8(isolate, args[1]);
    
    // Call C API
    int32_t err = dom_element_setattribute(elem, *name_utf8, *value_utf8);
    if (err != 0) {
        const char* err_msg = dom_error_code_message(err);
        isolate->ThrowException(Exception::Error(
            String::NewFromUtf8(isolate, err_msg).ToLocalChecked()));
    }
}

/**
 * Create the Element prototype template.
 * 
 * This sets up the JavaScript interface for Element objects:
 * - Properties (tagName, id, className)
 * - Methods (getAttribute, setAttribute, querySelector, etc.)
 * 
 * This is called once at initialization to create the prototype.
 */
Local<FunctionTemplate> CreateElementTemplate(Isolate* isolate) {
    Local<FunctionTemplate> tmpl = FunctionTemplate::New(isolate);
    tmpl->SetClassName(String::NewFromUtf8(isolate, "Element").ToLocalChecked());
    
    // Set internal field count (we need 1 slot for the C pointer)
    tmpl->InstanceTemplate()->SetInternalFieldCount(1);
    
    // Add properties
    Local<ObjectTemplate> proto = tmpl->PrototypeTemplate();
    
    proto->SetAccessor(
        String::NewFromUtf8(isolate, "tagName").ToLocalChecked(),
        Element_TagNameGetter
    );
    
    proto->SetAccessor(
        String::NewFromUtf8(isolate, "id").ToLocalChecked(),
        Element_IdGetter,
        Element_IdSetter
    );
    
    // Add methods
    proto->Set(
        String::NewFromUtf8(isolate, "getAttribute").ToLocalChecked(),
        FunctionTemplate::New(isolate, Element_GetAttribute)
    );
    
    proto->Set(
        String::NewFromUtf8(isolate, "setAttribute").ToLocalChecked(),
        FunctionTemplate::New(isolate, Element_SetAttribute)
    );
    
    return tmpl;
}

/**
 * Wrap a C DOMElement* in a V8 JavaScript object.
 * 
 * This is the bridge function that:
 * 1. Creates a new V8 object using the Element template
 * 2. Stores the C pointer in an internal field
 * 3. Sets up a weak callback for GC integration
 * 4. Increments the C-side reference count
 * 
 * This is called whenever you need to expose a C element to JavaScript.
 */
Local<Object> WrapElement(Isolate* isolate,
                          Local<Context> context,
                          Local<FunctionTemplate> element_template,
                          DOMElement* elem) {
    EscapableHandleScope handle_scope(isolate);
    
    // Create new V8 object from template
    Local<Function> constructor = element_template->GetFunction(context).ToLocalChecked();
    Local<Object> js_elem = constructor->NewInstance(context).ToLocalChecked();
    
    // Store the C pointer in internal field
    js_elem->SetInternalField(kElementPointerIndex, External::New(isolate, elem));
    
    // Increment C-side reference count
    // (The V8 wrapper holds a strong reference to the C object)
    dom_element_addref(elem);
    
    // Set up weak callback for GC
    // When V8 GC collects this object, ElementWeakCallback will be called
    Persistent<Object>* persistent = new Persistent<Object>(isolate, js_elem);
    persistent->SetWeak(elem, ElementWeakCallback, WeakCallbackType::kParameter);
    
    return handle_scope.Escape(js_elem);
}

/**
 * Main function - demonstrates the wrapper in action
 */
int main(int argc, char* argv[]) {
    // Initialize V8
    V8::InitializeICUDefaultLocation(argv[0]);
    V8::InitializeExternalStartupData(argv[0]);
    std::unique_ptr<Platform> platform = platform::NewDefaultPlatform();
    V8::InitializePlatform(platform.get());
    V8::Initialize();
    
    // Create V8 isolate
    Isolate::CreateParams create_params;
    create_params.array_buffer_allocator = ArrayBuffer::Allocator::NewDefaultAllocator();
    Isolate* isolate = Isolate::New(create_params);
    
    {
        Isolate::Scope isolate_scope(isolate);
        HandleScope handle_scope(isolate);
        
        // Create context
        Local<Context> context = Context::New(isolate);
        Context::Scope context_scope(context);
        
        // Create Element template (done once at startup)
        Local<FunctionTemplate> element_template = CreateElementTemplate(isolate);
        
        // === C-side: Create DOM structure ===
        std::cout << "Creating DOM structure in C..." << std::endl;
        DOMDocument* doc = dom_document_new();
        DOMElement* div = dom_document_createelement(doc, "div");
        dom_element_set_id(div, "container");
        dom_element_setattribute(div, "data-test", "hello");
        
        // === Wrap for JavaScript ===
        std::cout << "Wrapping Element for JavaScript..." << std::endl;
        Local<Object> js_div = WrapElement(isolate, context, element_template, div);
        
        // Store in global scope as "element"
        context->Global()->Set(
            context,
            String::NewFromUtf8(isolate, "element").ToLocalChecked(),
            js_div
        ).Check();
        
        // === Execute JavaScript code ===
        std::cout << "\nExecuting JavaScript code..." << std::endl;
        const char* js_code = R"(
            console.log('JavaScript executing...');
            console.log('element.tagName =', element.tagName);
            console.log('element.id =', element.id);
            console.log('element.getAttribute("data-test") =', element.getAttribute("data-test"));
            
            // Modify from JavaScript
            element.id = "modified-container";
            element.setAttribute("data-test", "world");
            
            console.log('After modification:');
            console.log('element.id =', element.id);
            console.log('element.getAttribute("data-test") =', element.getAttribute("data-test"));
        )";
        
        // Add console.log support
        Local<ObjectTemplate> console_template = ObjectTemplate::New(isolate);
        console_template->Set(
            String::NewFromUtf8(isolate, "log").ToLocalChecked(),
            FunctionTemplate::New(isolate, [](const FunctionCallbackInfo<Value>& args) {
                for (int i = 0; i < args.Length(); i++) {
                    String::Utf8Value str(args.GetIsolate(), args[i]);
                    std::cout << *str;
                    if (i < args.Length() - 1) std::cout << " ";
                }
                std::cout << std::endl;
            })
        );
        context->Global()->Set(
            context,
            String::NewFromUtf8(isolate, "console").ToLocalChecked(),
            console_template->NewInstance(context).ToLocalChecked()
        ).Check();
        
        // Compile and run
        Local<String> source = String::NewFromUtf8(isolate, js_code).ToLocalChecked();
        Local<Script> script = Script::Compile(context, source).ToLocalChecked();
        script->Run(context).ToLocalChecked();
        
        // === Verify changes in C ===
        std::cout << "\nVerifying changes in C..." << std::endl;
        std::cout << "C: element.id = " << dom_element_get_id(div) << std::endl;
        std::cout << "C: element.getAttribute('data-test') = " 
                  << dom_element_getattribute(div, "data-test") << std::endl;
        
        // Clean up C-side
        dom_element_release(div);
        dom_document_release(doc);
    }
    
    // Shutdown V8
    isolate->Dispose();
    V8::Dispose();
    V8::DisposePlatform();
    delete create_params.array_buffer_allocator;
    
    std::cout << "\nSuccess! V8 integration working correctly." << std::endl;
    return 0;
}
