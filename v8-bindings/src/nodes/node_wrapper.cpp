#include "node_wrapper.h"
#include "../wrapper_cache.h"
#include "../core/template_cache.h"
#include "../core/utilities.h"
#include "element_wrapper.h"
#include "document_wrapper.h"

namespace v8_dom {

v8::Local<v8::Object> NodeWrapper::Wrap(v8::Isolate* isolate,
                                              v8::Local<v8::Context> context,
                                              DOMNode* obj) {
    if (!obj) {
        return v8::Local<v8::Object>();
    }
    
    // Check wrapper cache first
    WrapperCache* cache = WrapperCache::ForIsolate(isolate);
    if (cache->Has(obj)) {
        return cache->Get(isolate, obj);
    }
    
    // Create new wrapper
    v8::EscapableHandleScope handle_scope(isolate);
    v8::Local<v8::FunctionTemplate> tmpl = GetTemplate(isolate);
    v8::Local<v8::Function> constructor = tmpl->GetFunction(context).ToLocalChecked();
    v8::Local<v8::Object> wrapper = constructor->NewInstance(context).ToLocalChecked();
    
    // Store C pointer in internal field
    wrapper->SetInternalField(0, v8::External::New(isolate, obj));
    
    // Increment C-side reference count
    dom_node_addref(obj);
    
    // Cache with release callback
    cache->Set(isolate, obj, wrapper, [](void* ptr) {
        dom_node_release(static_cast<DOMNode*>(ptr));
    });
    
    return handle_scope.Escape(wrapper);
}


DOMNode* NodeWrapper::Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    v8::Local<v8::Data> data = obj->GetInternalField(0);
    v8::Local<v8::Value> ptr = data.As<v8::Value>();
    if (ptr.IsEmpty()) return nullptr;
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMNode*>(v8::Local<v8::External>::Cast(ptr)->Value());

}

void NodeWrapper::InstallTemplate(v8::Isolate* isolate) {
    v8::Local<v8::FunctionTemplate> tmpl = v8::FunctionTemplate::New(isolate);
    tmpl->SetClassName(v8::String::NewFromUtf8Literal(isolate, "Node"));
    tmpl->InstanceTemplate()->SetInternalFieldCount(1);
    
    // Inherit from EventTarget
    tmpl->Inherit(EventTargetWrapper::GetTemplate(isolate));

    // Get prototype template for adding properties/methods
    v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();
    
    // Readonly properties
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "nodeType"),
        NodeTypeGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "nodeName"),
        NodeNameGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "parentNode"),
        ParentNodeGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "parentElement"),
        ParentElementGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "firstChild"),
        FirstChildGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "lastChild"),
        LastChildGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "previousSibling"),
        PreviousSiblingGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "nextSibling"),
        NextSiblingGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "ownerDocument"),
        OwnerDocumentGetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "isConnected"),
        IsConnectedGetter);
    
    // Read/write properties
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "nodeValue"),
        NodeValueGetter,
        NodeValueSetter);
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "textContent"),
        TextContentGetter,
        TextContentSetter);
    
    // Methods - Tree manipulation
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "appendChild"),
              v8::FunctionTemplate::New(isolate, AppendChild));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "insertBefore"),
              v8::FunctionTemplate::New(isolate, InsertBefore));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "removeChild"),
              v8::FunctionTemplate::New(isolate, RemoveChild));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "replaceChild"),
              v8::FunctionTemplate::New(isolate, ReplaceChild));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "cloneNode"),
              v8::FunctionTemplate::New(isolate, CloneNode));
    
    // Methods - Tree querying
    // TODO: Enable when dom_node_getrootnode is implemented in C API
    // proto->Set(v8::String::NewFromUtf8Literal(isolate, "getRootNode"),
    //           v8::FunctionTemplate::New(isolate, GetRootNode));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "hasChildNodes"),
              v8::FunctionTemplate::New(isolate, HasChildNodes));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "contains"),
              v8::FunctionTemplate::New(isolate, Contains));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "isSameNode"),
              v8::FunctionTemplate::New(isolate, IsSameNode));
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "isEqualNode"),
              v8::FunctionTemplate::New(isolate, IsEqualNode));
    
    // Methods - Other
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "normalize"),
              v8::FunctionTemplate::New(isolate, Normalize));
    
    // Cache the template
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    cache->Set(kTemplateIndex, tmpl);
}


v8::Local<v8::FunctionTemplate> NodeWrapper::GetTemplate(v8::Isolate* isolate) {
    TemplateCache* cache = TemplateCache::ForIsolate(isolate);
    
    if (!cache->Has(kTemplateIndex)) {
        InstallTemplate(isolate);
    }
    
    return cache->Get(kTemplateIndex);
}

// ============================================================================
// Property Implementations - Readonly
// ============================================================================

void NodeWrapper::NodeTypeGetter(v8::Local<v8::Name> property,
                                 const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    uint16_t nodeType = dom_node_get_nodetype(node);
    info.GetReturnValue().Set(v8::Integer::New(isolate, nodeType));

}

void NodeWrapper::NodeNameGetter(v8::Local<v8::Name> property,
                                 const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    const char* nodeName = dom_node_get_nodename(node);
    info.GetReturnValue().Set(CStringToV8String(isolate, nodeName));

}

void NodeWrapper::ParentNodeGetter(v8::Local<v8::Name> property,
                                   const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    DOMNode* parentNode = dom_node_get_parentnode(node);
    if (parentNode) {
        info.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, parentNode));
    } else {
        info.GetReturnValue().SetNull();
    }

}

void NodeWrapper::ParentElementGetter(v8::Local<v8::Name> property,
                                      const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    DOMElement* parentElement = dom_node_get_parentelement(node);
    if (parentElement) {
        info.GetReturnValue().Set(ElementWrapper::Wrap(isolate, context, parentElement));
    } else {
        info.GetReturnValue().SetNull();
    }

}

void NodeWrapper::FirstChildGetter(v8::Local<v8::Name> property,
                                   const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    DOMNode* firstChild = dom_node_get_firstchild(node);
    if (firstChild) {
        info.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, firstChild));
    } else {
        info.GetReturnValue().SetNull();
    }

}

void NodeWrapper::LastChildGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    DOMNode* lastChild = dom_node_get_lastchild(node);
    if (lastChild) {
        info.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, lastChild));
    } else {
        info.GetReturnValue().SetNull();
    }

}

void NodeWrapper::PreviousSiblingGetter(v8::Local<v8::Name> property,
                                        const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    DOMNode* previousSibling = dom_node_get_previoussibling(node);
    if (previousSibling) {
        info.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, previousSibling));
    } else {
        info.GetReturnValue().SetNull();
    }

}

void NodeWrapper::NextSiblingGetter(v8::Local<v8::Name> property,
                                    const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    DOMNode* nextSibling = dom_node_get_nextsibling(node);
    if (nextSibling) {
        info.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, nextSibling));
    } else {
        info.GetReturnValue().SetNull();
    }

}

void NodeWrapper::OwnerDocumentGetter(v8::Local<v8::Name> property,
                                      const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    DOMDocument* ownerDocument = dom_node_get_ownerdocument(node);
    if (ownerDocument) {
        info.GetReturnValue().Set(DocumentWrapper::Wrap(isolate, context, ownerDocument));
    } else {
        info.GetReturnValue().SetNull();
    }
}

void NodeWrapper::IsConnectedGetter(v8::Local<v8::Name> property,
                                    const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    uint8_t isConnected = dom_node_get_isconnected(node);
    info.GetReturnValue().Set(v8::Boolean::New(isolate, isConnected != 0));
}

// ============================================================================
// Property Implementations - Read/Write
// ============================================================================

void NodeWrapper::NodeValueGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    const char* nodeValue = dom_node_get_nodevalue(node);
    if (nodeValue && nodeValue[0] != '\0') {
        info.GetReturnValue().Set(CStringToV8String(isolate, nodeValue));
    } else {
        info.GetReturnValue().SetNull();
    }

}

void NodeWrapper::NodeValueSetter(v8::Local<v8::Name> property,
                                  v8::Local<v8::Value> value,
                                  const v8::PropertyCallbackInfo<void>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (value->IsNull() || value->IsUndefined()) {
        int32_t err = dom_node_set_nodevalue(node, nullptr);
        if (err != 0) {
            ThrowDOMException(isolate, err);
        }
    } else {
        CStringFromV8 nodeValue(isolate, value);
        int32_t err = dom_node_set_nodevalue(node, nodeValue.get());
        if (err != 0) {
            ThrowDOMException(isolate, err);
        }
    }
}

void NodeWrapper::TextContentGetter(v8::Local<v8::Name> property,
                                    const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    const char* textContent = dom_node_get_textcontent(node);
    if (textContent && textContent[0] != '\0') {
        info.GetReturnValue().Set(CStringToV8String(isolate, textContent));
    } else {
        info.GetReturnValue().SetEmptyString();
    }
}

void NodeWrapper::TextContentSetter(v8::Local<v8::Name> property,
                                    v8::Local<v8::Value> value,
                                    const v8::PropertyCallbackInfo<void>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.This().As<v8::Object>());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (value->IsNull() || value->IsUndefined()) {
        int32_t err = dom_node_set_textcontent(node, nullptr);
        if (err != 0) {
            ThrowDOMException(isolate, err);
        }
    } else {
        CStringFromV8 textContent(isolate, value);
        int32_t err = dom_node_set_textcontent(node, textContent.get());
        if (err != 0) {
            ThrowDOMException(isolate, err);
        }
    }
}

// ============================================================================
// Method Implementations - Tree Manipulation
// ============================================================================

void NodeWrapper::AppendChild(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (args.Length() < 1 || !args[0]->IsObject()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "appendChild requires a Node argument")));
        return;
    }
    
    DOMNode* child = NodeWrapper::Unwrap(args[0].As<v8::Object>());
    if (!child) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Argument must be a Node")));
        return;
    }
    
    DOMNode* result = dom_node_appendchild(node, child);
    if (result) {
        args.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, result));
    } else {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8Literal(isolate, "Failed to append child")));
    }

}

void NodeWrapper::InsertBefore(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (args.Length() < 2 || !args[0]->IsObject()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "insertBefore requires 2 arguments")));
        return;
    }
    
    DOMNode* newNode = NodeWrapper::Unwrap(args[0].As<v8::Object>());
    if (!newNode) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "First argument must be a Node")));
        return;
    }
    
    DOMNode* refNode = nullptr;
    if (!args[1]->IsNull() && !args[1]->IsUndefined()) {
        if (!args[1]->IsObject()) {
            isolate->ThrowException(v8::Exception::TypeError(
                v8::String::NewFromUtf8Literal(isolate, "Second argument must be a Node or null")));
            return;
        }
        refNode = NodeWrapper::Unwrap(args[1].As<v8::Object>());
    }
    
    DOMNode* result = dom_node_insertbefore(node, newNode, refNode);
    if (result) {
        args.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, result));
    } else {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8Literal(isolate, "Failed to insert before")));
    }

}

void NodeWrapper::RemoveChild(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (args.Length() < 1 || !args[0]->IsObject()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "removeChild requires a Node argument")));
        return;
    }
    
    DOMNode* child = NodeWrapper::Unwrap(args[0].As<v8::Object>());
    if (!child) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Argument must be a Node")));
        return;
    }
    
    DOMNode* result = dom_node_removechild(node, child);
    if (result) {
        args.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, result));
    } else {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8Literal(isolate, "Failed to remove child")));
    }

}

void NodeWrapper::ReplaceChild(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (args.Length() < 2 || !args[0]->IsObject() || !args[1]->IsObject()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "replaceChild requires 2 Node arguments")));
        return;
    }
    
    DOMNode* newNode = NodeWrapper::Unwrap(args[0].As<v8::Object>());
    DOMNode* oldNode = NodeWrapper::Unwrap(args[1].As<v8::Object>());
    
    if (!newNode || !oldNode) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Arguments must be Nodes")));
        return;
    }
    
    DOMNode* result = dom_node_replacechild(node, newNode, oldNode);
    if (result) {
        args.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, result));
    } else {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8Literal(isolate, "Failed to replace child")));
    }

}

void NodeWrapper::CloneNode(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    // deep defaults to false
    uint8_t deep = 0;
    if (args.Length() > 0) {
        deep = args[0]->BooleanValue(isolate) ? 1 : 0;
    }
    
    DOMNode* clone = dom_node_clonenode(node, deep);
    if (clone) {
        args.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, clone));
    } else {
        isolate->ThrowException(v8::Exception::Error(
            v8::String::NewFromUtf8Literal(isolate, "Failed to clone node")));
    }


// ============================================================================
// Method Implementations - Tree Querying
// ============================================================================
#if 0 // TODO: Enable when dom_node_getrootnode is implemented
}

void NodeWrapper::GetRootNode(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    v8::Local<v8::Context> context = isolate->GetCurrentContext();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    // composed defaults to false
    uint8_t composed = 0;
    if (args.Length() > 0 && args[0]->IsObject()) {
        v8::Local<v8::Object> options = args[0].As<v8::Object>();
        v8::Local<v8::Value> composedVal = options->Get(context,
            v8::String::NewFromUtf8Literal(isolate, "composed")).ToLocalChecked();
        composed = composedVal->BooleanValue(isolate) ? 1 : 0;
    }
    
    DOMNode* rootNode = dom_node_getrootnode(node, composed);
    if (rootNode) {
        args.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, rootNode));
    } else {
        args.GetReturnValue().Set(NodeWrapper::Wrap(isolate, context, node));
    }

#endif

}

void NodeWrapper::HasChildNodes(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    uint8_t result = dom_node_haschildnodes(node);
    args.GetReturnValue().Set(v8::Boolean::New(isolate, result != 0));

}

void NodeWrapper::Contains(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (args.Length() < 1) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    if (args[0]->IsNull() || args[0]->IsUndefined()) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    if (!args[0]->IsObject()) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Argument must be a Node")));
        return;
    }
    
    DOMNode* other = NodeWrapper::Unwrap(args[0].As<v8::Object>());
    if (!other) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    uint8_t result = dom_node_contains(node, other);
    args.GetReturnValue().Set(v8::Boolean::New(isolate, result != 0));

}

void NodeWrapper::IsSameNode(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (args.Length() < 1 || args[0]->IsNull() || args[0]->IsUndefined()) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    if (!args[0]->IsObject()) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    DOMNode* other = NodeWrapper::Unwrap(args[0].As<v8::Object>());
    if (!other) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    uint8_t result = dom_node_issamenode(node, other);
    args.GetReturnValue().Set(v8::Boolean::New(isolate, result != 0));

}

void NodeWrapper::IsEqualNode(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    if (args.Length() < 1 || args[0]->IsNull() || args[0]->IsUndefined()) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    if (!args[0]->IsObject()) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    DOMNode* other = NodeWrapper::Unwrap(args[0].As<v8::Object>());
    if (!other) {
        args.GetReturnValue().Set(v8::Boolean::New(isolate, false));
        return;
    }
    
    uint8_t result = dom_node_isequalnode(node, other);
    args.GetReturnValue().Set(v8::Boolean::New(isolate, result != 0));

}

// ============================================================================
// Method Implementations - Other
// ============================================================================

void NodeWrapper::Normalize(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMNode* node = Unwrap(args.This());
    if (!node) {
        isolate->ThrowException(v8::Exception::TypeError(
            v8::String::NewFromUtf8Literal(isolate, "Invalid Node")));
        return;
    }
    
    int32_t err = dom_node_normalize(node);
    if (err != 0) {
        ThrowDOMException(isolate, err);
    }

}

} // namespace v8_dom
