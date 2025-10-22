# V8 13.5 API Changes

This document describes the API changes between V8 10.x-12.x and V8 13.5, and how to update wrapper code.

## Summary of Changes

V8 13.5 introduced several breaking API changes that affect DOM wrapper implementation:

1. **C++20 required** - V8 13.5 requires C++20 or later (previously C++17)
2. **SetAccessor → SetNativeDataProperty** - Method renamed on ObjectTemplate
3. **GetInternalField return type** - Now returns `Local<Data>` instead of `Local<Value>`
4. **args.Holder() → args.This()** - For `FunctionCallbackInfo` only

---

## Detailed Changes

### 1. C++ Standard Version

**Old (V8 ≤12.x):**
```bash
CXXFLAGS := -std=c++17
```

**New (V8 13.5):**
```bash
CXXFLAGS := -std=c++20
```

**Reason:** V8 13.5 uses C++20 features internally.

---

### 2. Property Accessor Registration

**Old API (V8 ≤12.x):**
```cpp
v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();

// Readonly property
proto->SetAccessor(
    v8::String::NewFromUtf8Literal(isolate, "propertyName"),
    PropertyGetter
);

// Read/write property
proto->SetAccessor(
    v8::String::NewFromUtf8Literal(isolate, "propertyName"),
    PropertyGetter,
    PropertySetter
);
```

**New API (V8 13.5):**
```cpp
v8::Local<v8::ObjectTemplate> proto = tmpl->PrototypeTemplate();

// Readonly property
proto->SetNativeDataProperty(
    v8::String::NewFromUtf8Literal(isolate, "propertyName"),
    PropertyGetter
);

// Read/write property
proto->SetNativeDataProperty(
    v8::String::NewFromUtf8Literal(isolate, "propertyName"),
    PropertyGetter,
    PropertySetter
);
```

**Migration:**
- Replace `SetAccessor` with `SetNativeDataProperty`
- Signature is the same, just method name changed
- PropertyCallbackInfo signature unchanged

---

### 3. GetInternalField Return Type

**Old API (V8 ≤12.x):**
```cpp
DOMElement* Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    v8::Local<v8::Value> ptr = obj->GetInternalField(0);
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMElement*>(v8::Local<v8::External>::Cast(ptr)->Value());
}
```

**New API (V8 13.5):**
```cpp
DOMElement* Unwrap(v8::Local<v8::Object> obj) {
    if (obj.IsEmpty() || obj->InternalFieldCount() < 1) {
        return nullptr;
    }
    
    // CHANGED: GetInternalField now returns Local<Data>, must cast to Local<Value>
    v8::Local<v8::Value> ptr = obj->GetInternalField(0).As<v8::Value>();
    if (!ptr->IsExternal()) {
        return nullptr;
    }
    
    return static_cast<DOMElement*>(v8::Local<v8::External>::Cast(ptr)->Value());
}
```

**Migration:**
- Add `.As<v8::Value>()` after `GetInternalField(index)`
- Everything else stays the same

**Reason:** V8 13.5 made internal fields more type-safe by returning the base `Data` type.

---

### 4. FunctionCallbackInfo: args.Holder() → args.This()

**Old API (V8 ≤12.x):**
```cpp
void ElementWrapper::GetAttribute(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMElement* elem = Unwrap(args.Holder());  // OLD: Holder()
    if (!elem) {
        // ...
    }
}
```

**New API (V8 13.5):**
```cpp
void ElementWrapper::GetAttribute(const v8::FunctionCallbackInfo<v8::Value>& args) {
    v8::Isolate* isolate = args.GetIsolate();
    DOMElement* elem = Unwrap(args.This());  // NEW: This()
    if (!elem) {
        // ...
    }
}
```

**IMPORTANT:** This change **ONLY** applies to `FunctionCallbackInfo` (methods).

**PropertyCallbackInfo** (property getters/setters) **STILL** uses `info.Holder()`:
```cpp
void ElementWrapper::IdGetter(v8::Local<v8::Name> property,
                              const v8::PropertyCallbackInfo<v8::Value>& info) {
    v8::Isolate* isolate = info.GetIsolate();
    DOMElement* elem = Unwrap(info.Holder());  // PropertyCallbackInfo STILL uses Holder()
    // ...
}
```

**Migration:**
- In methods (`FunctionCallbackInfo`): Change `args.Holder()` to `args.This()`
- In property getters/setters (`PropertyCallbackInfo`): Keep `info.Holder()`

---

## Migration Checklist

For each wrapper file (e.g., `element_wrapper.cpp`):

- [ ] **Update C++ standard** in Makefile: `-std=c++20`
- [ ] **Update V8 include path** to point to `libexec/include`
- [ ] **Replace `SetAccessor`** with `SetNativeDataProperty` in `InstallTemplate()`
- [ ] **Add `.As<v8::Value>()`** to `GetInternalField()` calls in `Unwrap()`
- [ ] **Replace `args.Holder()`** with `args.This()` in all method implementations
- [ ] **Keep `info.Holder()`** in property getter/setter implementations

---

## Automated Migration Script

Use this script to update a wrapper file:

```bash
#!/bin/bash
FILE="$1"

# 1. Fix GetInternalField cast
sed -i '' 's/v8::Local<v8::Value> ptr = obj->GetInternalField(\([0-9]*\));/v8::Local<v8::Value> ptr = obj->GetInternalField(\1).As<v8::Value>();/' "$FILE"

# 2. Change SetAccessor to SetNativeDataProperty
sed -i '' 's/proto->SetAccessor(/proto->SetNativeDataProperty(/g' "$FILE"

# 3. Change args.Holder() to args.This() (only in FunctionCallbackInfo)
sed -i '' 's/Unwrap(args\.Holder())/Unwrap(args.This())/g' "$FILE"

echo "Updated $FILE for V8 13.5"
```

**Usage:**
```bash
./update_for_v8_13.sh src/nodes/document_wrapper.cpp
./update_for_v8_13.sh src/nodes/node_wrapper.cpp
# ... etc
```

---

## V8 13.5 Include Path

Homebrew installs V8 13.5 headers in a non-standard location:

```makefile
# Makefile
V8_INCLUDE := /opt/homebrew/Cellar/v8/13.5.212.10/libexec/include
```

Or use a symlink:
```bash
ls -la /opt/homebrew/Cellar/v8/13.5.212.10/libexec/include/v8.h
```

---

## Testing After Migration

After updating a wrapper:

```bash
# Compile individual wrapper
cd v8-bindings
clang++ -std=c++20 -Wall -Wextra -O2 -fPIC \
    -I../js-bindings \
    -I/opt/homebrew/Cellar/v8/13.5.212.10/libexec/include \
    -c src/nodes/element_wrapper.cpp \
    -o test.o

# Should compile with only warnings (from V8 headers), no errors
```

---

## Reference: ElementWrapper (Updated)

See `src/nodes/element_wrapper.cpp` for a complete, working example of V8 13.5 API usage.

Key points demonstrated:
- `.As<v8::Value>()` on `GetInternalField()` 
- `SetNativeDataProperty()` for all properties
- `args.This()` for all methods
- `info.Holder()` for all property accessors

---

## Additional Resources

- **V8 13.5 Release Notes:** https://v8.dev/blog/v8-release-13.5
- **V8 Embedder's Guide:** https://v8.dev/docs/embed
- **API Changes:** Check V8 headers in `/opt/homebrew/Cellar/v8/13.5.212.10/libexec/include/`

---

## Summary Table

| API | V8 ≤12.x | V8 13.5 | Applies To |
|-----|----------|---------|------------|
| **C++ Standard** | `-std=c++17` | `-std=c++20` | Makefile |
| **Property Registration** | `SetAccessor()` | `SetNativeDataProperty()` | InstallTemplate() |
| **GetInternalField** | Returns `Local<Value>` | Returns `Local<Data>`, cast with `.As<Value>()` | Unwrap() |
| **Method Receiver** | `args.Holder()` | `args.This()` | FunctionCallbackInfo (methods) |
| **Property Receiver** | `info.Holder()` | `info.Holder()` (unchanged) | PropertyCallbackInfo (getters/setters) |

---

**Last Updated:** October 21, 2025  
**V8 Version:** 13.5.212.10 (Homebrew)  
**Status:** ✅ ElementWrapper fully tested and working
