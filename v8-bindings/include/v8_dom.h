/**
 * V8 DOM Bindings - Public API
 * 
 * This is the main header for integrating V8 DOM bindings into your browser or JavaScript runtime.
 * 
 * Usage:
 *   #include <v8_dom.h>
 *   
 *   // In your browser initialization:
 *   v8::Local<v8::ObjectTemplate> global = v8::ObjectTemplate::New(isolate);
 *   v8_dom::InstallDOMBindings(isolate, global);
 *   v8::Local<v8::Context> context = v8::Context::New(isolate, nullptr, global);
 *   
 *   // Now JavaScript has access to DOM APIs!
 * 
 * Build:
 *   clang++ your_code.cpp \
 *     -I/path/to/v8-bindings/include \
 *     -L/path/to/v8-bindings/lib -lv8dom \
 *     -L/path/to/dom/zig-out/lib -ldom \
 *     -L/path/to/v8/lib -lv8 \
 *     -lpthread \
 *     -o your_browser
 */

#ifndef V8_DOM_H
#define V8_DOM_H

#include <v8.h>

/**
 * V8 DOM Bindings namespace.
 * 
 * All wrapper classes and utility functions are in this namespace.
 */
namespace v8_dom {

/**
 * Install all DOM bindings into a global object template.
 * 
 * This function:
 * 1. Initializes wrapper and template caches for the isolate
 * 2. Installs all DOM interface templates (Node, Element, Document, etc.)
 * 3. Creates a global 'document' object
 * 4. Exposes DOMImplementation for creating new documents
 * 
 * Call this BEFORE creating your V8 context.
 * 
 * @param isolate The V8 isolate to install bindings into
 * @param global The global object template to add DOM properties to
 * 
 * Example:
 *   v8::Isolate* isolate = v8::Isolate::New(create_params);
 *   v8::Local<v8::ObjectTemplate> global = v8::ObjectTemplate::New(isolate);
 *   v8_dom::InstallDOMBindings(isolate, global);
 *   v8::Local<v8::Context> context = v8::Context::New(isolate, nullptr, global);
 *   
 *   // JavaScript can now use:
 *   // - document.createElement()
 *   // - element.querySelector()
 *   // - etc.
 */
void InstallDOMBindings(v8::Isolate* isolate,
                       v8::Local<v8::ObjectTemplate> global);

/**
 * Cleanup DOM bindings for an isolate.
 * 
 * This is called automatically when the isolate is disposed.
 * You normally don't need to call this manually.
 * 
 * @param isolate The V8 isolate to cleanup
 */
void Cleanup(v8::Isolate* isolate);

/**
 * Get the library version.
 * 
 * @return Version string (e.g., "1.0.0")
 */
const char* GetVersion();

/**
 * Check if DOM bindings are installed for an isolate.
 * 
 * @param isolate The V8 isolate to check
 * @return true if bindings are installed, false otherwise
 */
bool IsInstalled(v8::Isolate* isolate);

} // namespace v8_dom

/**
 * Integration Notes:
 * 
 * 1. Thread Safety:
 *    - Each V8 isolate has its own wrapper cache
 *    - Safe to use multiple isolates (one per thread)
 *    - Not safe to share isolates across threads
 * 
 * 2. Memory Management:
 *    - Wrappers use weak callbacks for GC integration
 *    - C-side objects are reference counted
 *    - Cleanup is automatic when JS objects are collected
 * 
 * 3. Identity Preservation:
 *    - Same C object always wraps to same JS object
 *    - Uses wrapper cache for O(1) lookup
 *    - Prevents duplicate wrappers
 * 
 * 4. Error Handling:
 *    - C-ABI errors are converted to V8 exceptions
 *    - Throws DOMException with proper error codes
 *    - JavaScript try/catch works as expected
 * 
 * 5. Extending for HTML:
 *    - Create HTMLElementWrapper extending ElementWrapper
 *    - Add innerHTML, outerHTML, and other HTML properties
 *    - Install your templates after calling InstallDOMBindings()
 *    - Do NOT modify the v8-bindings library itself
 * 
 * Example HTML Extension:
 * 
 *   #include <v8_dom.h>
 *   
 *   namespace my_browser {
 *   
 *   class HTMLElementWrapper {
 *   public:
 *       static void InstallTemplate(v8::Isolate* isolate) {
 *           // Get base Element template from v8_dom
 *           auto tmpl = v8_dom::GetElementTemplate(isolate);
 *           auto proto = tmpl->PrototypeTemplate();
 *           
 *           // Add HTML-specific properties
 *           proto->SetAccessor(
 *               v8::String::NewFromUtf8Literal(isolate, "innerHTML"),
 *               GetInnerHTML, SetInnerHTML
 *           );
 *           
 *           proto->SetAccessor(
 *               v8::String::NewFromUtf8Literal(isolate, "outerHTML"),
 *               GetOuterHTML, SetOuterHTML
 *           );
 *       }
 *   };
 *   
 *   void InstallHTMLBindings(v8::Isolate* isolate, v8::Local<v8::ObjectTemplate> global) {
 *       // Install base DOM first
 *       v8_dom::InstallDOMBindings(isolate, global);
 *       
 *       // Then add HTML extensions
 *       HTMLElementWrapper::InstallTemplate(isolate);
 *   }
 *   
 *   }
 */

#endif // V8_DOM_H
