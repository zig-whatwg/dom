# JavaScript Bindings Guide

This document describes how to create JavaScript bindings for this Zig DOM implementation, including design decisions and mappings between Zig and JavaScript DOM APIs.

## Table of Contents

- [Overview](#overview)
- [Property vs Function Design](#property-vs-function-design)
- [Type Mappings](#type-mappings)
- [Memory Management](#memory-management)
- [Error Handling](#error-handling)
- [API Mappings](#api-mappings)

---

## Overview

This library implements the WHATWG DOM specification in Zig, designed to be consumed by JavaScript engines (V8, SpiderMonkey, JavaScriptCore, etc.) through bindings.

**Key Design Principle**: The Zig API is optimized for systems programming, not JavaScript ergonomics. Bindings should handle the impedance mismatch.

---

## Property vs Function Design

### Why Functions Instead of Properties?

**In JavaScript DOM:**
```javascript
node.baseURI        // Property access
node.nodeName       // Property access
node.parentNode     // Property access
```

**In this Zig implementation:**
```zig
node.baseURI()      // Function call
node.nodeName()     // Function call
node.parent_node    // Direct field access (stored)
```

### Rationale

#### 1. **Computed vs Stored Values**

The DOM spec distinguishes between:
- **Stored values**: Actual fields in the node struct (`parent_node`, `first_child`, `next_sibling`)
- **Computed values**: Calculated on-demand (`baseURI`, `nodeName`, `textContent`)

**In Zig:**
```zig
// Stored: Direct field access (cheap)
const parent = node.parent_node;  // Simple pointer dereference

// Computed: Function call (may be expensive)
const uri = node.baseURI();       // Might walk up tree, check attributes
const text = try node.textContent(allocator);  // Traverses entire subtree
```

#### 2. **Memory Efficiency**

Storing computed values as fields would bloat the Node struct:

```zig
// BAD: Storing everything as fields
pub const Node = struct {
    // Stored fields (necessary)
    parent_node: ?*Node,           // 8 bytes
    first_child: ?*Node,           // 8 bytes
    
    // Computed fields (wasteful!)
    node_name: []const u8,         // +16 bytes (but can be computed)
    base_uri: []const u8,          // +16 bytes (but can be computed)
    text_content: []const u8,      // +16 bytes (but can be computed)
    
    // Node would be >200 bytes instead of 96!
};
```

**Current approach (efficient):**
```zig
pub const Node = struct {
    // Only stored fields
    parent_node: ?*Node,           // 8 bytes
    first_child: ?*Node,           // 8 bytes
    // ... other necessary fields
    
    // Computed on demand via vtable
    pub fn nodeName(self: *const Node) []const u8 {
        return self.vtable.node_name(self);  // Polymorphic
    }
};
// Node is exactly 96 bytes
```

#### 3. **Polymorphic Behavior**

Some properties return different values based on node type:

```zig
// Element.nodeName() returns tag name
// Text.nodeName() returns "#text"
// Comment.nodeName() returns "#comment"
pub fn nodeName(self: *const Node) []const u8 {
    return self.vtable.node_name(self);  // Dispatches to correct implementation
}
```

This requires a function call for vtable dispatch.

#### 4. **Thread Safety**

Computed properties can be read-only and thread-safe without locks:

```zig
pub fn nodeName(self: *const Node) []const u8 {
    // Safe to call from multiple threads
    // No mutation, just computation
}
```

Stored fields would need synchronization if mutable.

#### 5. **Zig Idioms**

In Zig, there's no syntactic sugar for properties. The language makes explicit what's a field access vs a function call:

```zig
node.parent_node     // Field access (always cheap)
node.nodeName()      // Function call (might be expensive)
```

This explicitness is intentional - it makes performance characteristics visible.

---

### JavaScript Binding Strategy

**The bindings layer should hide this implementation detail** and present a JavaScript-idiomatic API.

#### Recommended Approach: Property Descriptors

Use JavaScript property descriptors to make functions look like properties:

```javascript
// In your bindings code (e.g., using Node-API, WASM, or FFI)
Object.defineProperty(Node.prototype, 'baseURI', {
  get: function() {
    // Call Zig function
    return zig_node_baseURI(this._zigPtr);
  },
  enumerable: true,
  configurable: false
});

Object.defineProperty(Node.prototype, 'nodeName', {
  get: function() {
    // Call Zig function with vtable dispatch
    return zig_node_nodeName(this._zigPtr);
  },
  enumerable: true,
  configurable: false
});

// Direct field access for stored properties
Object.defineProperty(Node.prototype, 'parentNode', {
  get: function() {
    // Direct field access (pointer dereference)
    const ptr = zig_node_get_parent_node(this._zigPtr);
    return ptr ? wrapNode(ptr) : null;
  },
  enumerable: true,
  configurable: false
});
```

#### Example: Complete Property Mapping

```javascript
class Node {
  constructor(zigPtr) {
    this._zigPtr = zigPtr;
  }
  
  // Computed properties (backed by Zig functions)
  get baseURI() {
    return zigBindings.node_baseURI(this._zigPtr);
  }
  
  get nodeName() {
    return zigBindings.node_nodeName(this._zigPtr);
  }
  
  get textContent() {
    return zigBindings.node_textContent(this._zigPtr);
  }
  
  set textContent(value) {
    zigBindings.node_setTextContent(this._zigPtr, value);
  }
  
  // Stored properties (backed by Zig fields)
  get parentNode() {
    const ptr = zigBindings.node_get_parent_node(this._zigPtr);
    return ptr ? new Node(ptr) : null;
  }
  
  get firstChild() {
    const ptr = zigBindings.node_get_first_child(this._zigPtr);
    return ptr ? new Node(ptr) : null;
  }
  
  // Methods (call Zig functions directly)
  appendChild(child) {
    return zigBindings.node_appendChild(this._zigPtr, child._zigPtr);
  }
  
  contains(other) {
    return zigBindings.node_contains(this._zigPtr, other._zigPtr);
  }
}
```

---

### Quick Reference: Property Categories

#### Category 1: Stored Fields (Direct Access)
These are actual struct fields, accessed directly:

```zig
node.parent_node        // ?*Node
node.first_child        // ?*Node
node.last_child         // ?*Node
node.previous_sibling   // ?*Node
node.next_sibling       // ?*Node
node.owner_document     // ?*Node
node.node_type          // NodeType enum
```

**JavaScript binding**: Simple pointer/value retrieval

#### Category 2: Computed Properties (Functions)
These require computation, so they're functions:

```zig
node.nodeName()         // Vtable dispatch
node.nodeValue()        // Vtable dispatch
node.baseURI()          // Might walk tree
node.textContent()      // Walks entire subtree
node.localName()        // Returns tag name
```

**JavaScript binding**: Wrap in property getter

#### Category 3: Methods (Always Functions)
These are operations that modify state or take parameters:

```zig
node.appendChild(child)
node.removeChild(child)
node.contains(other)
node.cloneNode(deep)
```

**JavaScript binding**: Expose as methods

---

## Type Mappings

### WebIDL → Zig → JavaScript

| WebIDL Type | Zig Type | JavaScript Type | Notes |
|-------------|----------|-----------------|-------|
| `undefined` | `void` | `undefined` | No return value |
| `DOMString` | `[]const u8` | `string` | UTF-8 in Zig, UTF-16 in JS |
| `DOMString?` | `?[]const u8` | `string \| null` | Nullable |
| `boolean` | `bool` | `boolean` | Direct mapping |
| `unsigned short` | `u16` | `number` | Document position flags |
| `unsigned long` | `u32` | `number` | Indices, counts |
| `Node` | `*Node` | `Node` | Wrapped in JS object |
| `Node?` | `?*Node` | `Node \| null` | Nullable pointer |
| `NodeList` | `NodeList` | `NodeList` | Live collection |
| `Element` | `*Element` | `Element` | Subclass of Node |

### String Conversion

**Zig → JavaScript:**
```javascript
// Zig returns []const u8 (UTF-8 bytes)
function zigStringToJS(ptr, len) {
  const bytes = new Uint8Array(zigMemory.buffer, ptr, len);
  return new TextDecoder('utf-8').decode(bytes);
}
```

**JavaScript → Zig:**
```javascript
// JS string (UTF-16) to Zig []const u8 (UTF-8)
function jsStringToZig(str) {
  const encoded = new TextEncoder().encode(str);
  const ptr = zigBindings.allocate(encoded.length);
  new Uint8Array(zigMemory.buffer, ptr, encoded.length).set(encoded);
  return { ptr, len: encoded.length };
}
```

---

## Memory Management

### Reference Counting

All DOM nodes use reference counting:

```zig
// Zig side
const node = try Node.init(...);  // ref_count = 1
node.acquire();                   // ref_count = 2
node.release();                   // ref_count = 1
node.release();                   // ref_count = 0, deallocated
```

### JavaScript Bindings Strategy

**Use FinalizationRegistry for automatic cleanup:**

```javascript
const registry = new FinalizationRegistry((zigPtr) => {
  // Called when JS object is garbage collected
  zigBindings.node_release(zigPtr);
});

class Node {
  constructor(zigPtr, shouldAcquire = false) {
    this._zigPtr = zigPtr;
    
    if (shouldAcquire) {
      zigBindings.node_acquire(zigPtr);
    }
    
    // Register for cleanup
    registry.register(this, zigPtr, this);
  }
  
  // Manual cleanup (optional, for immediate release)
  dispose() {
    if (this._zigPtr) {
      registry.unregister(this);
      zigBindings.node_release(this._zigPtr);
      this._zigPtr = null;
    }
  }
}
```

### Ownership Rules

1. **Factory methods return ref_count=1**: Caller owns the reference
   ```zig
   const elem = try doc.createElement("div");  // ref_count = 1
   defer elem.node.release();  // Caller must release
   ```

2. **appendChild transfers ownership**: Parent acquires, caller releases
   ```zig
   const child = try doc.createElement("span");  // ref_count = 1
   _ = try parent.appendChild(&child.node);      // ref_count = 2 (parent + caller)
   child.node.release();                         // ref_count = 1 (parent owns)
   ```

3. **Getters don't acquire**: Borrowed references
   ```zig
   const parent = node.parent_node;  // Borrowed, don't release
   ```

### JavaScript Binding Example

```javascript
class Document {
  createElement(tagName) {
    // Factory method returns owned reference (ref_count=1)
    const zigPtr = zigBindings.doc_createElement(this._zigPtr, tagName);
    return new Element(zigPtr, false);  // Don't acquire (we already own it)
  }
}

class Node {
  appendChild(child) {
    // appendChild acquires the child (ref_count++)
    zigBindings.node_appendChild(this._zigPtr, child._zigPtr);
    
    // JavaScript side keeps its reference too
    // When JS object is GC'd, ref_count-- happens automatically
    return child;
  }
  
  get parentNode() {
    // Getter returns borrowed reference
    const ptr = zigBindings.node_get_parent_node(this._zigPtr);
    if (!ptr) return null;
    
    // Acquire because we're creating a new JS wrapper
    zigBindings.node_acquire(ptr);
    return new Node(ptr, false);  // We already acquired
  }
}
```

---

## Error Handling

### Zig Error Unions

```zig
pub fn appendChild(self: *Node, child: *Node) !*Node {
    // May return error.HierarchyRequestError, error.OutOfMemory, etc.
}
```

### JavaScript Binding Strategy

Convert Zig errors to JavaScript exceptions:

```javascript
function node_appendChild(parentPtr, childPtr) {
  // Call Zig function
  const result = zigBindings.node_appendChild(parentPtr, childPtr);
  
  // Check for error (Zig error unions encode error in result)
  if (result.is_error) {
    const errorName = zigBindings.getErrorName(result.error_code);
    
    // Map to DOM exception types
    switch (errorName) {
      case 'HierarchyRequestError':
        throw new DOMException('Invalid node hierarchy', 'HierarchyRequestError');
      case 'NotFoundError':
        throw new DOMException('Node not found', 'NotFoundError');
      case 'OutOfMemory':
        throw new Error('Out of memory');
      default:
        throw new Error(`DOM error: ${errorName}`);
    }
  }
  
  return result.value;
}
```

---

## API Mappings

### Complete Node Interface Example

**Zig Implementation:**
```zig
pub const Node = struct {
    // Stored fields
    parent_node: ?*Node,
    first_child: ?*Node,
    
    // Computed properties (functions)
    pub fn nodeName(self: *const Node) []const u8 {
        return self.vtable.node_name(self);
    }
    
    pub fn baseURI(self: *const Node) []const u8 {
        return "";  // Computed
    }
    
    pub fn textContent(self: *const Node, allocator: Allocator) !?[]u8 {
        // Walks tree, allocates string
    }
    
    // Methods
    pub fn appendChild(self: *Node, child: *Node) !*Node {
        // Tree mutation
    }
    
    pub fn contains(self: *const Node, other: ?*const Node) bool {
        // Traversal
    }
};
```

**JavaScript Bindings:**
```javascript
class Node {
  // Stored properties → simple getters
  get parentNode() {
    const ptr = zig.node_get_parent_node(this._ptr);
    return ptr ? wrapNode(ptr) : null;
  }
  
  get firstChild() {
    const ptr = zig.node_get_first_child(this._ptr);
    return ptr ? wrapNode(ptr) : null;
  }
  
  // Computed properties → function-backed getters
  get nodeName() {
    return zig.node_nodeName(this._ptr);
  }
  
  get baseURI() {
    return zig.node_baseURI(this._ptr);
  }
  
  get textContent() {
    return zig.node_textContent(this._ptr);
  }
  
  set textContent(value) {
    zig.node_setTextContent(this._ptr, value);
  }
  
  // Methods → direct calls
  appendChild(child) {
    zig.node_appendChild(this._ptr, child._ptr);
    return child;
  }
  
  contains(other) {
    return zig.node_contains(this._ptr, other ? other._ptr : null);
  }
}
```

---

## Performance Considerations

### Property Access Costs

| Access Pattern | Cost | Notes |
|----------------|------|-------|
| `node.parent_node` | ~1ns | Direct field access |
| `node.nodeName()` | ~5ns | Vtable dispatch |
| `node.baseURI()` | ~10ns | Simple computation |
| `node.textContent()` | ~1µs | Tree traversal + allocation |

### Optimization Tips

1. **Cache computed properties in JavaScript** if accessed frequently:
   ```javascript
   class Node {
     get nodeName() {
       if (!this._cachedNodeName) {
         this._cachedNodeName = zig.node_nodeName(this._ptr);
       }
       return this._cachedNodeName;
     }
   }
   ```

2. **Batch operations** to minimize FFI overhead:
   ```javascript
   // BAD: Multiple FFI calls
   for (let child of parent.childNodes) {
     console.log(child.nodeName);  // FFI call per iteration
   }
   
   // GOOD: Batch query
   const names = zig.node_getChildNodeNames(parent._ptr);  // Single FFI call
   for (let name of names) {
     console.log(name);
   }
   ```

3. **Use stored fields directly** when possible:
   ```javascript
   // GOOD: Direct field access (no vtable)
   let current = node;
   while (current) {
     current = zig.node_get_next_sibling(current._ptr);
   }
   ```

---

## Example: Complete Bindings Module

```javascript
// node-bindings.js

const zig = require('./zig-dom.node');  // Or WASM, or FFI
const registry = new FinalizationRegistry((ptr) => zig.node_release(ptr));

class Node {
  constructor(ptr, acquire = false) {
    this._ptr = ptr;
    if (acquire) zig.node_acquire(ptr);
    registry.register(this, ptr, this);
  }
  
  // === Stored Properties (Fast Field Access) ===
  
  get parentNode() {
    const ptr = zig.node_get_parent_node(this._ptr);
    return ptr ? wrapNode(ptr) : null;
  }
  
  get firstChild() {
    const ptr = zig.node_get_first_child(this._ptr);
    return ptr ? wrapNode(ptr) : null;
  }
  
  get nextSibling() {
    const ptr = zig.node_get_next_sibling(this._ptr);
    return ptr ? wrapNode(ptr) : null;
  }
  
  // === Computed Properties (Function-Backed) ===
  
  get nodeName() {
    return zigStringToJS(zig.node_nodeName(this._ptr));
  }
  
  get baseURI() {
    return zigStringToJS(zig.node_baseURI(this._ptr));
  }
  
  get textContent() {
    const result = zig.node_textContent(this._ptr);
    return result ? zigStringToJS(result) : null;
  }
  
  set textContent(value) {
    const str = jsStringToZig(value);
    zig.node_setTextContent(this._ptr, str.ptr, str.len);
    zig.free(str.ptr);
  }
  
  // === Methods ===
  
  appendChild(child) {
    const result = zig.node_appendChild(this._ptr, child._ptr);
    if (result.is_error) {
      throw zigErrorToJS(result.error);
    }
    return child;
  }
  
  contains(other) {
    return zig.node_contains(this._ptr, other ? other._ptr : 0);
  }
  
  cloneNode(deep = false) {
    const ptr = zig.node_cloneNode(this._ptr, deep);
    return wrapNode(ptr);
  }
}

// Helper: Wrap Zig pointer in appropriate JS class
function wrapNode(ptr) {
  const type = zig.node_get_type(ptr);
  switch (type) {
    case 1: return new Element(ptr, true);
    case 3: return new Text(ptr, true);
    case 9: return new Document(ptr, true);
    default: return new Node(ptr, true);
  }
}

// Helper: Convert Zig error to JS exception
function zigErrorToJS(errorCode) {
  const name = zig.getErrorName(errorCode);
  return new DOMException(`DOM Error: ${name}`, name);
}

// Helper: Convert Zig string to JS
function zigStringToJS(result) {
  if (!result.ptr) return '';
  const bytes = new Uint8Array(zig.memory.buffer, result.ptr, result.len);
  return new TextDecoder('utf-8').decode(bytes);
}

// Helper: Convert JS string to Zig
function jsStringToZig(str) {
  const encoded = new TextEncoder().encode(str);
  const ptr = zig.allocate(encoded.length);
  new Uint8Array(zig.memory.buffer, ptr, encoded.length).set(encoded);
  return { ptr, len: encoded.length };
}

module.exports = { Node, Element, Document, Text };
```

---

## Summary

**Key Takeaways:**

1. **Properties are functions in Zig** for good reasons (performance, memory, polymorphism)
2. **JavaScript bindings should hide this** using property descriptors
3. **The API is still 100% spec-compliant** - the difference is only in how you access it
4. **Performance characteristics are visible** in Zig, hidden in JavaScript
5. **This is standard practice** - Rust, C++, and other DOM implementations do the same

**For JavaScript engine implementers:**
- Use this guide to create ergonomic JavaScript bindings
- Follow the property/method mapping tables
- Handle memory management with FinalizationRegistry
- Convert errors to DOMException types

**For Zig library users:**
- Understand that `node.nodeName()` is a function call
- Use stored fields (`node.parent_node`) for performance
- Accept that this is the idiomatic Zig way
