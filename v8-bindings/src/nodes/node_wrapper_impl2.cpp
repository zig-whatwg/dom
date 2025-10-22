// NodeWrapper implementation - Part 2: Read/Write Property and Methods

// ============================================================================
// Property Implementations - Read/Write
// ============================================================================

void NodeWrapper::NodeValueGetter(v8::Local<v8::Name> property,
                                  const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMNode* node = Unwrap(info.Holder());
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
    DOMNode* node = Unwrap(info.Holder());
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
        // Error occurred - check for DOM exception
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
}

// ============================================================================
// Method Implementations - Tree Querying
// ============================================================================

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
