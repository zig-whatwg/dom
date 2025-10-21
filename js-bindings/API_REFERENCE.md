# JavaScript Bindings - C API Reference

**Version**: 0.1.0 (Phase 3)  
**Date**: October 21, 2025  
**Status**: 56 functions implemented across 3 interfaces

---

## Table of Contents

1. [Overview](#overview)
2. [Memory Management](#memory-management)
3. [Error Handling](#error-handling)
4. [Document API](#document-api)
5. [Node API](#node-api)
6. [Element API](#element-api)
7. [Type Reference](#type-reference)
8. [Examples](#examples)

---

## Overview

This C API provides JavaScript engine integration for the Zig WHATWG DOM implementation. The API follows these principles:

- **Universal C-ABI** - Works with any JavaScript engine (V8, SpiderMonkey, JSC, QuickJS, etc.)
- **Opaque pointers** - JS engines never see internal structures
- **Manual reference counting** - Explicit `addref`/`release`
- **Borrowed strings** - Returned strings are owned by DOM, don't free
- **Status codes** - Functions return `0` for success, error codes on failure

---

## Memory Management

### Reference Counting

All DOM objects use manual reference counting:

```c
// Creating increases ref count to 1
DOMDocument* doc = dom_document_new();  // ref_count = 1

// Sharing requires addref
dom_document_addref(doc);  // ref_count = 2
other_owner = doc;

// Release when done
dom_document_release(doc);  // ref_count = 1
dom_document_release(doc);  // ref_count = 0 → freed
```

### Parent-Child Ownership

When nodes are added to tree, parent owns children:

```c
DOMElement* div = dom_document_createelement(doc, "div");   // ref_count = 1
DOMElement* span = dom_document_createelement(doc, "span"); // ref_count = 1

// Append child - div now owns span
dom_node_appendchild((DOMNode*)div, (DOMNode*)span);

// Only release div - span is freed automatically
dom_element_release(div);  // Frees both div and span
```

### String Ownership

**Returned strings are BORROWED** - don't free them:

```c
const char* tag = dom_element_get_tagname(elem);
printf("Tag: %s\n", tag);  // ✅ OK
// DON'T free(tag) - it's owned by DOM!
```

**Input strings are COPIED** - you still own yours:

```c
char* my_string = strdup("value");
dom_element_setattribute(elem, "id", my_string);
free(my_string);  // ✅ OK - DOM made a copy
```

---

## Error Handling

Functions that can fail return `c_int` status codes:

```c
int result = dom_element_setattribute(elem, "id", "foo");
if (result != 0) {
    DOMErrorCode error = (DOMErrorCode)result;
    const char* name = dom_error_code_name(error);
    printf("Error: %s\n", name);
}
```

### Error Codes

```c
typedef enum {
    DOM_SUCCESS = 0,
    DOM_INDEX_SIZE_ERROR = 1,
    DOM_HIERARCHY_REQUEST_ERROR = 3,
    DOM_WRONG_DOCUMENT_ERROR = 4,
    DOM_INVALID_CHARACTER_ERROR = 5,
    DOM_NOT_FOUND_ERROR = 8,
    DOM_SYNTAX_ERROR = 12,
    // ... 20+ more error codes
} DOMErrorCode;

// Get error details
const char* dom_error_code_name(DOMErrorCode code);
const char* dom_error_code_message(DOMErrorCode code);
```

---

## Document API

### Creation

```c
// Create new document (uses page allocator internally)
DOMDocument* dom_document_new(void);
```

### Factory Methods

```c
// Create element
DOMElement* dom_document_createelement(
    DOMDocument* doc,
    const char* localName
);

// Create namespaced element  
DOMElement* dom_document_createelementns(
    DOMDocument* doc,
    const char* namespace,      // nullable
    const char* qualifiedName
);

// Create text node
DOMText* dom_document_createtextnode(
    DOMDocument* doc,
    const char* data
);

// Create comment node
DOMComment* dom_document_createcomment(
    DOMDocument* doc,
    const char* data
);
```

### Reference Counting

```c
void dom_document_addref(DOMDocument* doc);
void dom_document_release(DOMDocument* doc);
```

### Example

```c
DOMDocument* doc = dom_document_new();
DOMElement* div = dom_document_createelement(doc, "div");
DOMText* text = dom_document_createtextnode(doc, "Hello");

// Build tree
dom_node_appendchild((DOMNode*)div, (DOMNode*)text);

// Cleanup
dom_element_release(div);  // Also frees text
dom_document_release(doc);
```

---

## Node API

**Implementation**: 29/32 functions (90% complete)

### Constants

```c
#define ELEMENT_NODE 1
#define TEXT_NODE 3
#define COMMENT_NODE 8
#define DOCUMENT_NODE 9
#define DOCUMENT_FRAGMENT_NODE 11
```

### Properties (Read-Only)

```c
// Node type
uint16_t dom_node_get_nodetype(DOMNode* node);

// Node name (e.g., "div", "#text", "#document")
const char* dom_node_get_nodename(DOMNode* node);

// Connection status
uint8_t dom_node_get_isconnected(DOMNode* node);  // Returns 0 or 1

// Owner document
DOMDocument* dom_node_get_ownerdocument(DOMNode* node);  // nullable
```

### Tree Navigation

```c
// Parent
DOMNode* dom_node_get_parentnode(DOMNode* node);      // nullable
DOMElement* dom_node_get_parentelement(DOMNode* node); // nullable, Element-only

// Children
DOMNode* dom_node_get_firstchild(DOMNode* node);   // nullable
DOMNode* dom_node_get_lastchild(DOMNode* node);    // nullable

// Siblings
DOMNode* dom_node_get_previoussibling(DOMNode* node);  // nullable
DOMNode* dom_node_get_nextsibling(DOMNode* node);      // nullable
```

### Node Value

```c
// Get node value (null for Elements, data for Text/Comment)
const char* dom_node_get_nodevalue(DOMNode* node);  // nullable

// Set node value
int dom_node_set_nodevalue(DOMNode* node, const char* value);
```

### Tree Manipulation

```c
// Check if node has children
uint8_t dom_node_haschildnodes(DOMNode* node);

// Append child
DOMNode* dom_node_appendchild(DOMNode* parent, DOMNode* child);

// Insert before reference child
DOMNode* dom_node_insertbefore(
    DOMNode* parent,
    DOMNode* newChild,
    DOMNode* refChild  // nullable - null means append
);

// Remove child
DOMNode* dom_node_removechild(DOMNode* parent, DOMNode* child);

// Replace child
DOMNode* dom_node_replacechild(
    DOMNode* parent,
    DOMNode* newChild,
    DOMNode* oldChild
);
```

### Node Comparison

```c
// Pointer equality
uint8_t dom_node_issamenode(DOMNode* node, DOMNode* other);

// Deep equality (structure + content)
uint8_t dom_node_isequalnode(DOMNode* node, DOMNode* other);

// Document position (returns bitmask)
uint16_t dom_node_comparedocumentposition(DOMNode* node, DOMNode* other);

// Containment check
uint8_t dom_node_contains(DOMNode* node, DOMNode* other);
```

### Cloning & Normalization

```c
// Clone node (deep if subtree != 0)
DOMNode* dom_node_clonenode(DOMNode* node, uint8_t subtree);

// Normalize adjacent text nodes
int dom_node_normalize(DOMNode* node);
```

### Namespaces

```c
// Lookup prefix for namespace
const char* dom_node_lookupprefix(
    DOMNode* node,
    const char* namespace  // nullable
);

// Lookup namespace for prefix
const char* dom_node_lookupnamespaceuri(
    DOMNode* node,
    const char* prefix  // nullable
);

// Check if namespace is default
uint8_t dom_node_isdefaultnamespace(
    DOMNode* node,
    const char* namespace  // nullable
);
```

### Reference Counting

```c
void dom_node_addref(DOMNode* node);
void dom_node_release(DOMNode* node);
```

### Deferred Functions

⏸️ **Not yet implemented**:
- `dom_node_get_childnodes()` - Needs NodeList binding
- `dom_node_get_textcontent()` / `dom_node_set_textcontent()` - Needs memory strategy

---

## Element API

**Implementation**: 20/40 functions (50% complete)

### Properties

```c
// Element identification
const char* dom_element_get_namespaceuri(DOMElement* elem);  // nullable
const char* dom_element_get_prefix(DOMElement* elem);        // nullable
const char* dom_element_get_localname(DOMElement* elem);
const char* dom_element_get_tagname(DOMElement* elem);

// Convenience properties (wraps getAttribute/setAttribute)
const char* dom_element_get_id(DOMElement* elem);
int dom_element_set_id(DOMElement* elem, const char* value);

const char* dom_element_get_classname(DOMElement* elem);
int dom_element_set_classname(DOMElement* elem, const char* value);
```

### Attribute Methods

```c
// Check for attributes
uint8_t dom_element_hasattributes(DOMElement* elem);
uint8_t dom_element_hasattribute(DOMElement* elem, const char* name);
uint8_t dom_element_hasattributens(
    DOMElement* elem,
    const char* namespace,  // nullable
    const char* localName
);

// Get attributes
const char* dom_element_getattribute(
    DOMElement* elem,
    const char* qualifiedName
);  // Returns NULL if not found

const char* dom_element_getattributens(
    DOMElement* elem,
    const char* namespace,  // nullable
    const char* localName
);  // Returns NULL if not found

// Set attributes
int dom_element_setattribute(
    DOMElement* elem,
    const char* qualifiedName,
    const char* value
);

int dom_element_setattributens(
    DOMElement* elem,
    const char* namespace,  // nullable
    const char* qualifiedName,
    const char* value
);

// Remove attributes
int dom_element_removeattribute(
    DOMElement* elem,
    const char* qualifiedName
);

int dom_element_removeattributens(
    DOMElement* elem,
    const char* namespace,  // nullable
    const char* localName
);

// Toggle attribute (returns new state: 0 or 1)
uint8_t dom_element_toggleattribute(
    DOMElement* elem,
    const char* qualifiedName,
    uint8_t force  // 0 = toggle, 1 = force on
);
```

### Reference Counting

```c
void dom_element_addref(DOMElement* elem);
void dom_element_release(DOMElement* elem);
```

### Deferred Functions

⏸️ **Not yet implemented**:
- Attr node methods (getAttributeNode, setAttributeNode, etc.)
- Query methods (matches, closest, querySelector, querySelectorAll)
- Element iteration (getElementsByTagName, getElementsByClassName)
- DOM manipulation (insertAdjacentElement, insertAdjacentHTML, insertAdjacentText)
- Collections (classList, attributes) - need DOMTokenList/NamedNodeMap bindings

---

## Type Reference

### Opaque Types

All DOM objects are opaque pointers:

```c
typedef struct DOMDocument DOMDocument;
typedef struct DOMNode DOMNode;
typedef struct DOMElement DOMElement;
typedef struct DOMText DOMText;
typedef struct DOMComment DOMComment;
typedef struct DOMNodeList DOMNodeList;
typedef struct DOMHTMLCollection DOMHTMLCollection;
// ... more types
```

### Casting

Element inherits from Node, can cast safely:

```c
DOMElement* elem = dom_document_createelement(doc, "div");
DOMNode* node = (DOMNode*)elem;  // Safe upcast

// Use Node API on Element
dom_node_appendchild(parent_node, (DOMNode*)elem);
```

---

## Examples

### Example 1: Simple DOM Tree

```c
#include "dom_bindings.h"

int main() {
    // Create document
    DOMDocument* doc = dom_document_new();
    
    // Create elements
    DOMElement* html = dom_document_createelement(doc, "html");
    DOMElement* body = dom_document_createelement(doc, "body");
    DOMElement* h1 = dom_document_createelement(doc, "h1");
    
    // Build tree
    dom_node_appendchild((DOMNode*)html, (DOMNode*)body);
    dom_node_appendchild((DOMNode*)body, (DOMNode*)h1);
    
    // Add text content
    DOMText* text = dom_document_createtextnode(doc, "Hello, World!");
    dom_node_appendchild((DOMNode*)h1, (DOMNode*)text);
    
    // Set attributes
    dom_element_setattribute(h1, "id", "title");
    dom_element_setattribute(h1, "class", "header");
    
    // Query attributes
    const char* id = dom_element_getattribute(h1, "id");
    printf("H1 id: %s\n", id);  // "title"
    
    // Check tree structure
    uint8_t has_children = dom_node_haschildnodes((DOMNode*)body);
    printf("Body has children: %d\n", has_children);  // 1
    
    // Cleanup (html owns entire tree)
    dom_element_release(html);
    dom_document_release(doc);
    
    return 0;
}
```

### Example 2: Tree Manipulation

```c
DOMDocument* doc = dom_document_new();

// Create list
DOMElement* ul = dom_document_createelement(doc, "ul");
DOMElement* li1 = dom_document_createelement(doc, "li");
DOMElement* li2 = dom_document_createelement(doc, "li");
DOMElement* li3 = dom_document_createelement(doc, "li");

// Add items
dom_node_appendchild((DOMNode*)ul, (DOMNode*)li1);
dom_node_appendchild((DOMNode*)ul, (DOMNode*)li2);
dom_node_appendchild((DOMNode*)ul, (DOMNode*)li3);

// Insert at specific position
DOMElement* li_new = dom_document_createelement(doc, "li");
dom_node_insertbefore((DOMNode*)ul, (DOMNode*)li_new, (DOMNode*)li2);
// Order: li1, li_new, li2, li3

// Remove item
dom_node_removechild((DOMNode*)ul, (DOMNode*)li3);

// Replace item
DOMElement* li_replacement = dom_document_createelement(doc, "li");
dom_node_replacechild((DOMNode*)ul, (DOMNode*)li_replacement, (DOMNode*)li1);

// Cleanup
dom_element_release(ul);
dom_document_release(doc);
```

### Example 3: Namespaced Elements (SVG)

```c
DOMDocument* doc = dom_document_new();

// Create SVG element
DOMElement* svg = dom_document_createelementns(
    doc,
    "http://www.w3.org/2000/svg",
    "svg"
);

// Create SVG circle
DOMElement* circle = dom_document_createelementns(
    doc,
    "http://www.w3.org/2000/svg",
    "circle"
);

// Set SVG attributes
dom_element_setattributens(circle, NULL, "cx", "50");
dom_element_setattributens(circle, NULL, "cy", "50");
dom_element_setattributens(circle, NULL, "r", "40");

// Build tree
dom_node_appendchild((DOMNode*)svg, (DOMNode*)circle);

// Check namespace
const char* ns = dom_element_get_namespaceuri(circle);
printf("Namespace: %s\n", ns);  // "http://www.w3.org/2000/svg"

// Cleanup
dom_element_release(svg);
dom_document_release(doc);
```

### Example 4: Error Handling

```c
DOMDocument* doc = dom_document_new();
DOMElement* elem = dom_document_createelement(doc, "div");

// Attempt invalid attribute name
int result = dom_element_setattribute(elem, "invalid name", "value");
if (result != 0) {
    DOMErrorCode error = (DOMErrorCode)result;
    const char* name = dom_error_code_name(error);
    const char* msg = dom_error_code_message(error);
    
    printf("Error %d: %s\n", error, name);
    printf("Message: %s\n", msg);
    // Error 5: InvalidCharacterError
    // Message: String contains invalid characters
}

// Cleanup
dom_element_release(elem);
dom_document_release(doc);
```

---

## Compilation

### Building the Library

```bash
# Generate bindings (already done)
zig build js-bindings-gen -- Document
zig build js-bindings-gen -- Node
zig build js-bindings-gen -- Element

# Build static library (TODO: fix build.zig for Zig 0.15)
zig build-lib js-bindings/*.zig -static -O ReleaseFast
# → libdom_js_bindings.a
```

### Compiling Your Application

```bash
# Static linking
gcc your_app.c libdom_js_bindings.a -o your_app

# Dynamic linking
gcc your_app.c -L. -ldom_js_bindings -o your_app
```

---

## Performance Characteristics

### Zero-Copy Operations ✅

- All string getters: O(1), zero-copy (cast `.ptr`)
- All pointer getters: O(1), zero-copy (`@ptrCast`)
- No allocations in any getter

### Reference Counting ✅

- Thread-safe via atomic operations
- O(1) acquire/release
- Predictable memory management
- No GC pauses

### Attribute Operations

- `getAttribute`: O(n) where n = number of attributes
- `setAttribute`: O(n) for search + O(1) for update
- `hasAttribute`: O(n) where n = number of attributes
- `removeAttribute`: O(n) for search + O(1) for removal

Future: Bloom filter optimization for class/id lookups

---

## Current Limitations

### V1 Limitations

1. ⏸️ **No childNodes** - Needs NodeList binding (live collection)
2. ⏸️ **No textContent** - Needs memory management strategy
3. ⏸️ **No event listeners** - Callback support deferred to V2
4. ⏸️ **Limited query methods** - matches/closest need allocator handling
5. 🟡 **Error handling** - Non-nullable returns can't report errors cleanly

### Design Limitations (Won't Fix in V1)

1. ❌ **No automatic GC** - Manual reference counting only
2. ❌ **No wrapper cache** - Engine's responsibility
3. ❌ **No bidirectional callbacks** - Pure C→Zig only

---

## Version History

### v0.1.0 (Current) - October 21, 2025

**Phase 3 In Progress**: Core functionality implemented

- ✅ Infrastructure: StringPool null-termination
- ✅ Node: 29/32 functions (90%)
- ✅ Element: 20/40 functions (50%)
- ✅ Document: 7/35 functions (20% - factory methods)
- **Total**: 56 functions across 3 interfaces

---

## Support & Contributions

### Questions?

See full documentation in `js-bindings/README.md` and design documents in `summaries/plans/`

### Want to Contribute?

Priority areas:
1. Complete remaining Element methods
2. Implement NodeList/HTMLCollection bindings
3. Add textContent with memory management
4. Create engine-specific examples (V8, QuickJS, Bun)
5. Performance benchmarks

---

**Last Updated**: October 21, 2025  
**Maintainer**: Zig DOM Project  
**License**: Same as parent project
