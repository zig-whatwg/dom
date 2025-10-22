#!/bin/bash

# Update element_wrapper.cpp for V8 13.5 API

FILE="src/nodes/element_wrapper.cpp"

# 1. Fix GetInternalField cast
sed -i '' 's/v8::Local<v8::Value> ptr = obj->GetInternalField(0);/v8::Local<v8::Value> ptr = obj->GetInternalField(0).As<v8::Value>();/' "$FILE"

# 2. Change SetAccessor to SetNativeDataProperty
sed -i '' 's/proto->SetAccessor(/proto->SetNativeDataProperty(/g' "$FILE"

# 3. Change args.Holder() to args.This() in FunctionCallbackInfo
sed -i '' 's/DOMElement\* elem = Unwrap(args\.Holder());/DOMElement* elem = Unwrap(args.This());/g' "$FILE"

echo "Updated $FILE for V8 13.5 API"
