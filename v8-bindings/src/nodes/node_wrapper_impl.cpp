// NodeWrapper implementation - Part 1: Registration and Properties
// This will be inserted into node_wrapper.cpp

// In InstallTemplate() - replace the TODO section with:

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
    
    // Read/write properties
    proto->SetNativeDataProperty(
        v8::String::NewFromUtf8Literal(isolate, "nodeValue"),
        NodeValueGetter,
        NodeValueSetter);
    
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
    proto->Set(v8::String::NewFromUtf8Literal(isolate, "getRootNode"),
              v8::FunctionTemplate::New(isolate, GetRootNode));
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

// ============================================================================
// Property Implementations - Readonly
// ============================================================================

void NodeWrapper::NodeTypeGetter(v8::Local<v8::Name> property,
                                 const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
