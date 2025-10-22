/**
 * Node Wrapper - V8 bindings for Node
 * 
 * Auto-generated wrapper for DOMNode.
 * Provides JavaScript interface for Node operations.
 */

#ifndef V8_DOM_NODE_WRAPPER_H
#define V8_DOM_NODE_WRAPPER_H

#include <v8.h>
#include "eventtarget_wrapper.h"
#include "dom.h"

namespace v8_dom {

class NodeWrapper : public EventTargetWrapper {
public:
    /**
     * Wrap a C DOMNode pointer in a V8 object.
     * Uses wrapper cache for identity preservation.
     */
    static v8::Local<v8::Object> Wrap(v8::Isolate* isolate,
                                      v8::Local<v8::Context> context,
                                      DOMNode* obj);
    
    /**
     * Unwrap a V8 object to get the C DOMNode pointer.
     */
    static DOMNode* Unwrap(v8::Local<v8::Object> obj);
    
    /**
     * Install the Node template (called once per isolate).
     */
    static void InstallTemplate(v8::Isolate* isolate);
    
    /**
     * Get the cached Node template.
     */
    static v8::Local<v8::FunctionTemplate> GetTemplate(v8::Isolate* isolate);
    
    /**
     * Template cache index.
     */
    static constexpr int kTemplateIndex = 1;
    
private:
    // Readonly properties
    static void NodeTypeGetter(v8::Local<v8::Name> property,
                               const v8::PropertyCallbackInfo<v8::Value>& info);
    static void NodeNameGetter(v8::Local<v8::Name> property,
                               const v8::PropertyCallbackInfo<v8::Value>& info);
    static void ParentNodeGetter(v8::Local<v8::Name> property,
                                 const v8::PropertyCallbackInfo<v8::Value>& info);
    static void ParentElementGetter(v8::Local<v8::Name> property,
                                    const v8::PropertyCallbackInfo<v8::Value>& info);
    static void FirstChildGetter(v8::Local<v8::Name> property,
                                 const v8::PropertyCallbackInfo<v8::Value>& info);
    static void LastChildGetter(v8::Local<v8::Name> property,
                                const v8::PropertyCallbackInfo<v8::Value>& info);
    static void PreviousSiblingGetter(v8::Local<v8::Name> property,
                                      const v8::PropertyCallbackInfo<v8::Value>& info);
    static void NextSiblingGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info);
    static void OwnerDocumentGetter(v8::Local<v8::Name> property,
                                    const v8::PropertyCallbackInfo<v8::Value>& info);
    static void IsConnectedGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info);
    
    // Read/write properties
    static void NodeValueGetter(v8::Local<v8::Name> property,
                                const v8::PropertyCallbackInfo<v8::Value>& info);
    static void NodeValueSetter(v8::Local<v8::Name> property,
                                v8::Local<v8::Value> value,
                                const v8::PropertyCallbackInfo<void>& info);
    static void TextContentGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info);
    static void TextContentSetter(v8::Local<v8::Name> property,
                                  v8::Local<v8::Value> value,
                                  const v8::PropertyCallbackInfo<void>& info);
    
    // Methods - Tree manipulation
    static void AppendChild(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void InsertBefore(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void RemoveChild(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void ReplaceChild(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void CloneNode(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Methods - Tree querying
    static void GetRootNode(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void HasChildNodes(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void Contains(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void IsSameNode(const v8::FunctionCallbackInfo<v8::Value>& args);
    static void IsEqualNode(const v8::FunctionCallbackInfo<v8::Value>& args);
    
    // Methods - Other
    static void Normalize(const v8::FunctionCallbackInfo<v8::Value>& args);
};

} // namespace v8_dom

#endif // V8_DOM_NODE_WRAPPER_H
