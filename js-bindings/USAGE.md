# JavaScript Bindings Usage Guide

Quick reference for using the DOM JavaScript bindings C library.

## Building the Library

```bash
# Build static library
zig build lib-js-bindings

# Output: zig-out/lib/libdom.a (2.3 MB)
```

## Compiling C Programs

```bash
# Basic compilation
gcc -o myapp myapp.c zig-out/lib/libdom.a -lpthread

# With optimization
gcc -O2 -o myapp myapp.c zig-out/lib/libdom.a -lpthread

# C++ compilation
g++ -o myapp myapp.cpp zig-out/lib/libdom.a -lpthread
```

## Quick Start Example

```c
#include <stdio.h>

// Forward declarations
typedef struct DOMDocument DOMDocument;
typedef struct DOMElement DOMElement;

extern DOMDocument* dom_document_new(void);
extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* name);
extern int dom_element_setattribute(DOMElement* elem, const char* name, const char* value);
extern const char* dom_element_getattribute(DOMElement* elem, const char* name);
extern void dom_element_release(DOMElement* elem);
extern void dom_document_release(DOMDocument* doc);

int main(void) {
    // Create document
    DOMDocument* doc = dom_document_new();
    
    // Create element
    DOMElement* div = dom_document_createelement(doc, "div");
    
    // Set attributes
    dom_element_setattribute(div, "id", "container");
    dom_element_setattribute(div, "class", "main");
    
    // Get attribute
    const char* id = dom_element_getattribute(div, "id");
    printf("Element id: %s\n", id);
    
    // Cleanup
    dom_element_release(div);
    dom_document_release(doc);
    
    return 0;
}
```

Compile and run:
```bash
gcc -o example example.c zig-out/lib/libdom.a -lpthread
./example
# Output: Element id: container
```

## API Reference

### Document Functions

```c
// Create new document
DOMDocument* dom_document_new(void);

// Factory methods
DOMElement* dom_document_createelement(DOMDocument* doc, const char* localName);
DOMElement* dom_document_createelementns(DOMDocument* doc, const char* namespace, const char* qualifiedName);
DOMText* dom_document_createtextnode(DOMDocument* doc, const char* data);
DOMComment* dom_document_createcomment(DOMDocument* doc, const char* data);

// Reference counting
void dom_document_addref(DOMDocument* doc);
void dom_document_release(DOMDocument* doc);
```

### Element Functions

```c
// Properties
const char* dom_element_get_tagname(DOMElement* elem);
const char* dom_element_get_id(DOMElement* elem);
int dom_element_set_id(DOMElement* elem, const char* id);
const char* dom_element_get_classname(DOMElement* elem);
int dom_element_set_classname(DOMElement* elem, const char* className);

// Attributes
const char* dom_element_getattribute(DOMElement* elem, const char* qualifiedName);
int dom_element_setattribute(DOMElement* elem, const char* qualifiedName, const char* value);
int dom_element_removeattribute(DOMElement* elem, const char* qualifiedName);
unsigned char dom_element_hasattribute(DOMElement* elem, const char* qualifiedName);
unsigned char dom_element_toggleattribute(DOMElement* elem, const char* qualifiedName, unsigned char force);

// Namespaced attributes
const char* dom_element_getattributens(DOMElement* elem, const char* namespace, const char* localName);
int dom_element_setattributens(DOMElement* elem, const char* namespace, const char* qualifiedName, const char* value);
int dom_element_removeattributens(DOMElement* elem, const char* namespace, const char* localName);
unsigned char dom_element_hasattributens(DOMElement* elem, const char* namespace, const char* localName);

// Reference counting
void dom_element_addref(DOMElement* elem);
void dom_element_release(DOMElement* elem);
```

### Node Functions

```c
// Properties
unsigned short dom_node_get_nodetype(DOMNode* node);
const char* dom_node_get_nodename(DOMNode* node);
const char* dom_node_get_nodevalue(DOMNode* node);
int dom_node_set_nodevalue(DOMNode* node, const char* value);
DOMNode* dom_node_get_parentnode(DOMNode* node);
DOMElement* dom_node_get_parentelement(DOMNode* node);
DOMNode* dom_node_get_firstchild(DOMNode* node);
DOMNode* dom_node_get_lastchild(DOMNode* node);
DOMNode* dom_node_get_previoussibling(DOMNode* node);
DOMNode* dom_node_get_nextsibling(DOMNode* node);
DOMDocument* dom_node_get_ownerdocument(DOMNode* node);

// Tree queries
unsigned char dom_node_haschildnodes(DOMNode* node);
unsigned char dom_node_contains(DOMNode* node, DOMNode* other);

// Tree manipulation
DOMNode* dom_node_appendchild(DOMNode* parent, DOMNode* child);
DOMNode* dom_node_insertbefore(DOMNode* parent, DOMNode* node, DOMNode* child);
DOMNode* dom_node_removechild(DOMNode* parent, DOMNode* child);
DOMNode* dom_node_replacechild(DOMNode* parent, DOMNode* node, DOMNode* child);

// Cloning
DOMNode* dom_node_clonenode(DOMNode* node, unsigned char deep);

// Comparison
unsigned char dom_node_issamenode(DOMNode* node, DOMNode* other);
unsigned char dom_node_isequalnode(DOMNode* node, DOMNode* other);

// Normalization
int dom_node_normalize(DOMNode* node);

// Reference counting
void dom_node_addref(DOMNode* node);
void dom_node_release(DOMNode* node);
```

### Error Handling

```c
// Error codes (c_int)
// 0 = Success
// Non-zero = Error code

// Get error information
const char* dom_error_code_name(int code);
const char* dom_error_code_message(int code);

// Example usage
int result = dom_element_setattribute(elem, "id", "test");
if (result != 0) {
    const char* name = dom_error_code_name(result);
    const char* msg = dom_error_code_message(result);
    fprintf(stderr, "Error %s: %s\n", name, msg);
}
```

Common error codes:
- `0` - Success
- `3` - HierarchyRequestError
- `4` - WrongDocumentError
- `5` - InvalidCharacterError
- `8` - NotFoundError

## Memory Management

### Reference Counting

All DOM objects use manual reference counting:

```c
// Objects start with ref_count = 1
DOMDocument* doc = dom_document_new();  // ref_count = 1

// Share ownership - increment ref count
dom_document_addref(doc);  // ref_count = 2

// Release ownership - decrement ref count
dom_document_release(doc);  // ref_count = 1
dom_document_release(doc);  // ref_count = 0, freed
```

### Parent Ownership

When a child is added to a parent, the parent owns the child:

```c
DOMElement* div = dom_document_createelement(doc, "div");
DOMElement* span = dom_document_createelement(doc, "span");

// Cast to DOMNode* for tree operations
DOMNode* div_node = (DOMNode*)div;
DOMNode* span_node = (DOMNode*)span;

// Parent takes ownership of child
dom_node_appendchild(div_node, span_node);

// Only release parent - it releases children automatically
dom_element_release(div);  // This also releases span
```

### String Ownership

**Returned strings are borrowed** - do NOT free them:

```c
const char* tag_name = dom_element_get_tagname(elem);
printf("Tag: %s\n", tag_name);
// DO NOT call free(tag_name) - the element owns the string
```

**Passed strings are copied** - you still own your strings:

```c
char* my_string = strdup("hello");
dom_element_setattribute(elem, "data-msg", my_string);
free(my_string);  // OK - DOM made a copy
```

## Common Patterns

### Building a Document Tree

```c
// Create document
DOMDocument* doc = dom_document_new();

// Create structure: div#container > span.text + p.content
DOMElement* div = dom_document_createelement(doc, "div");
DOMElement* span = dom_document_createelement(doc, "span");
DOMElement* p = dom_document_createelement(doc, "p");

// Set attributes
dom_element_set_id(div, "container");
dom_element_set_classname(span, "text");
dom_element_set_classname(p, "content");

// Build tree
DOMNode* div_node = (DOMNode*)div;
dom_node_appendchild(div_node, (DOMNode*)span);
dom_node_appendchild(div_node, (DOMNode*)p);

// Add text content
DOMText* text = dom_document_createtextnode(doc, "Hello, World!");
dom_node_appendchild((DOMNode*)span, (DOMNode*)text);

// Cleanup (releases all children too)
dom_element_release(div);
dom_document_release(doc);
```

### Traversing a Tree

```c
void print_tree(DOMNode* node, int depth) {
    // Print node name with indentation
    for (int i = 0; i < depth; i++) printf("  ");
    const char* name = dom_node_get_nodename(node);
    unsigned short type = dom_node_get_nodetype(node);
    printf("<%s> (type=%d)\n", name, type);
    
    // Traverse children
    if (dom_node_haschildnodes(node)) {
        DOMNode* child = dom_node_get_firstchild(node);
        while (child != NULL) {
            print_tree(child, depth + 1);
            child = dom_node_get_nextsibling(child);
        }
    }
}

// Usage
DOMElement* root = dom_document_createelement(doc, "root");
// ... build tree ...
print_tree((DOMNode*)root, 0);
```

### Error Handling

```c
int result = dom_element_setattribute(elem, "id", "test");
if (result != 0) {
    fprintf(stderr, "Error: %s\n", dom_error_code_message(result));
    return 1;
}
```

### Type Casting

Elements and other node types can be cast to DOMNode*:

```c
DOMElement* elem = dom_document_createelement(doc, "div");
DOMNode* node = (DOMNode*)elem;  // Safe cast

// Use node operations
dom_node_appendchild(parent_node, node);

// Can still use element operations on original pointer
dom_element_setattribute(elem, "id", "test");
```

## Node Types

```c
// nodeType values (unsigned short)
#define ELEMENT_NODE 1
#define ATTRIBUTE_NODE 2
#define TEXT_NODE 3
#define CDATA_SECTION_NODE 4
#define PROCESSING_INSTRUCTION_NODE 7
#define COMMENT_NODE 8
#define DOCUMENT_NODE 9
#define DOCUMENT_TYPE_NODE 10
#define DOCUMENT_FRAGMENT_NODE 11

// Usage
unsigned short type = dom_node_get_nodetype(node);
if (type == ELEMENT_NODE) {
    DOMElement* elem = (DOMElement*)node;
    // Use element-specific functions
}
```

## Complete Example

See `test.c` for a complete example with 9 test cases covering:
- Document creation
- Element creation and attributes
- Tree building and navigation
- Node properties
- Error handling
- Memory management

```bash
cd js-bindings
gcc -o test test.c ../zig-out/lib/libdom.a -lpthread
./test
```

## Tips and Best Practices

### 1. Always Check Return Values

```c
int result = dom_element_setattribute(elem, "id", "test");
if (result != 0) {
    // Handle error
}
```

### 2. Match addref/release Calls

```c
// Every addref must have a matching release
dom_document_addref(doc);
// ... use doc ...
dom_document_release(doc);
```

### 3. Use Parent Ownership

```c
// Let parent manage children - don't manually release children
dom_node_appendchild(parent, child);
dom_element_release(parent);  // This releases child too
```

### 4. Don't Free Returned Strings

```c
const char* str = dom_element_getattribute(elem, "id");
// str is borrowed - just use it, don't free it
printf("ID: %s\n", str);
```

### 5. Check for NULL

```c
const char* attr = dom_element_getattribute(elem, "missing");
if (attr == NULL) {
    printf("Attribute not found\n");
}
```

### 6. Cast Safely

```c
// All node types can be cast to DOMNode*
DOMElement* elem = ...;
DOMText* text = ...;
DOMComment* comment = ...;

DOMNode* node1 = (DOMNode*)elem;
DOMNode* node2 = (DOMNode*)text;
DOMNode* node3 = (DOMNode*)comment;
```

## Troubleshooting

### Linker Errors

If you get "undefined reference" errors:

```bash
# Make sure to link pthread
gcc -o test test.c zig-out/lib/libdom.a -lpthread

# On Linux, you may also need:
gcc -o test test.c zig-out/lib/libdom.a -lpthread -lm -ldl
```

### Memory Leaks

Use valgrind to detect leaks:

```bash
valgrind --leak-check=full ./test
```

### Segmentation Faults

Common causes:
1. Using released pointer (use-after-free)
2. Not checking for NULL
3. Double-free (releasing twice)

Debug with gdb:
```bash
gcc -g -o test test.c zig-out/lib/libdom.a -lpthread
gdb ./test
```

## Performance Tips

### 1. Batch Attribute Changes

```c
// Good - batch changes
dom_element_setattribute(elem, "id", "test");
dom_element_setattribute(elem, "class", "main");
dom_element_setattribute(elem, "data-foo", "bar");
```

### 2. Cache Element Lookups

```c
// Good - cache the element
DOMElement* elem = dom_document_createelement(doc, "div");
// Use elem multiple times without re-creating
```

### 3. Build Trees Bottom-Up

```c
// Good - build children first, then add to parent
DOMElement* child1 = dom_document_createelement(doc, "span");
DOMElement* child2 = dom_document_createelement(doc, "p");
dom_node_appendchild(parent, (DOMNode*)child1);
dom_node_appendchild(parent, (DOMNode*)child2);
```

## Further Reading

- **API Reference**: See `API_REFERENCE.md` for complete function documentation
- **Implementation Status**: See `NODE_STATUS.md` for feature completeness
- **Test Example**: See `test.c` for comprehensive usage examples
- **WHATWG DOM Spec**: https://dom.spec.whatwg.org/

## Support

For issues or questions:
- Check the test program: `js-bindings/test.c`
- Read the API reference: `js-bindings/API_REFERENCE.md`
- View implementation status: `js-bindings/NODE_STATUS.md`
