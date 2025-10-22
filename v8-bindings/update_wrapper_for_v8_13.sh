#!/bin/bash

# Update any wrapper file for V8 13.5 API
# Usage: ./update_wrapper_for_v8_13.sh src/nodes/node_wrapper.cpp

if [ $# -eq 0 ]; then
    echo "Usage: $0 <wrapper.cpp>"
    echo "Example: $0 src/nodes/node_wrapper.cpp"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found"
    exit 1
fi

echo "Updating $FILE for V8 13.5 API..."

# 1. Fix GetInternalField cast - match any pattern
sed -i '' 's/v8::Local<v8::Value> ptr = obj->GetInternalField(\([0-9]*\));/v8::Local<v8::Value> ptr = obj->GetInternalField(\1).As<v8::Value>();/g' "$FILE"

# 2. Change SetAccessor to SetNativeDataProperty
sed -i '' 's/proto->SetAccessor(/proto->SetNativeDataProperty(/g' "$FILE"

# 3. Change args.Holder() to args.This() - but only in Unwrap() calls
sed -i '' 's/Unwrap(args\.Holder())/Unwrap(args.This())/g' "$FILE"

echo "✅ Updated $FILE"
