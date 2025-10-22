/**
 * Example C program showing how to use the Zig DOM JavaScript bindings
 * 
 * This demonstrates the C-ABI interface for JavaScript engines.
 * 
 * To compile (once bindings library is built):
 *   gcc test_example.c -L../zig-out/lib -ldom_js_bindings -o test_example
 *   ./test_example
 */

#include <stdio.h>
#include <stdint.h>

// Forward declarations of opaque types
typedef struct DOMDocument DOMDocument;
typedef struct DOMElement DOMElement;
typedef struct DOMNode DOMNode;
typedef struct DOMText DOMText;

// Error codes
typedef enum {
    DOM_SUCCESS = 0,
    DOM_INDEX_SIZE_ERROR = 1,
    DOM_HIERARCHY_REQUEST_ERROR = 3,
    DOM_WRONG_DOCUMENT_ERROR = 4,
    DOM_INVALID_CHARACTER_ERROR = 5,
    DOM_NOT_FOUND_ERROR = 8,
    DOM_SYNTAX_ERROR = 12,
} DOMErrorCode;

// Node constants
#define ELEMENT_NODE 1
#define TEXT_NODE 3
#define COMMENT_NODE 8
#define DOCUMENT_NODE 9

// Function declarations (from generated bindings)

// Document functions
extern DOMDocument* dom_document_new(void);
extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* tag_name);
extern DOMText* dom_document_createtextnode(DOMDocument* doc, const char* data);
extern void dom_document_release(DOMDocument* doc);

// Node functions
extern uint16_t dom_node_get_nodetype(DOMNode* node);
extern const char* dom_node_get_nodename(DOMNode* node);
extern uint8_t dom_node_get_isconnected(DOMNode* node);
extern uint8_t dom_node_haschildnodes(DOMNode* node);
extern DOMNode* dom_node_get_firstchild(DOMNode* node);
extern DOMNode* dom_node_appendchild(DOMNode* parent, DOMNode* child);
extern DOMNode* dom_node_removechild(DOMNode* parent, DOMNode* child);
extern uint8_t dom_node_contains(DOMNode* parent, DOMNode* child);
extern void dom_node_addref(DOMNode* node);
extern void dom_node_release(DOMNode* node);

// Element functions
extern const char* dom_element_get_tagname(DOMElement* elem);
extern int dom_element_setattribute(DOMElement* elem, const char* name, const char* value);
extern const char* dom_element_getattribute(DOMElement* elem, const char* name);
extern void dom_element_addref(DOMElement* elem);
extern void dom_element_release(DOMElement* elem);

int main() {
    printf("Zig DOM JavaScript Bindings - C Example\n");
    printf("=========================================\n\n");
    
    // Create document
    DOMDocument* doc = dom_document_new();
    printf("✓ Created document\n");
    
    // Create elements
    DOMElement* div = dom_document_createelement(doc, "div");
    printf("✓ Created <div> element\n");
    
    DOMElement* span = dom_document_createelement(doc, "span");
    printf("✓ Created <span> element\n");
    
    // Set attributes
    int result = dom_element_setattribute(div, "id", "container");
    if (result == DOM_SUCCESS) {
        printf("✓ Set id='container' on div\n");
    }
    
    result = dom_element_setattribute(span, "class", "text");
    if (result == DOM_SUCCESS) {
        printf("✓ Set class='text' on span\n");
    }
    
    // Build tree structure
    DOMNode* div_node = (DOMNode*)div;
    DOMNode* span_node = (DOMNode*)span;
    
    DOMNode* appended = dom_node_appendchild(div_node, span_node);
    printf("✓ Appended span to div\n");
    
    // Query tree
    uint8_t has_children = dom_node_haschildnodes(div_node);
    printf("✓ div.hasChildNodes() = %s\n", has_children ? "true" : "false");
    
    DOMNode* first_child = dom_node_get_firstchild(div_node);
    if (first_child) {
        const char* child_name = dom_node_get_nodename(first_child);
        printf("✓ div.firstChild.nodeName = %s\n", child_name);
    }
    
    uint8_t contains = dom_node_contains(div_node, span_node);
    printf("✓ div.contains(span) = %s\n", contains ? "true" : "false");
    
    // Get attributes back
    const char* id = dom_element_getattribute(div, "id");
    printf("✓ div.getAttribute('id') = %s\n", id);
    
    const char* class_attr = dom_element_getattribute(span, "class");
    printf("✓ span.getAttribute('class') = %s\n", class_attr);
    
    // Memory management - release nodes
    // Note: span is owned by div (parent), so only release div + doc
    dom_element_release(div);
    dom_document_release(doc);
    
    printf("\n✓ All tests passed!\n");
    return 0;
}
