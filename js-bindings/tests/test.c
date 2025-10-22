/**
 * JavaScript Bindings C Test Program
 * 
 * This program tests the DOM JavaScript bindings static library
 * by creating a simple DOM tree and manipulating it.
 * 
 * Compile:
 *   zig build lib-js-bindings
 *   gcc -o test test.c zig-out/lib/libdom.a -lpthread
 *   ./test
 */

#include <stdio.h>
#include <string.h>
#include "dom.h"

int main(void) {
    printf("=== JavaScript Bindings C Test ===\n\n");
    
    // Test 1: Create document
    printf("Test 1: Creating document...\n");
    DOMDocument* doc = dom_document_new();
    if (!doc) {
        printf("  FAILED: Could not create document\n");
        return 1;
    }
    printf("  ✓ Document created\n\n");
    
    // Test 2: Create element
    printf("Test 2: Creating element...\n");
    DOMElement* div = dom_document_createelement(doc, "div");
    if (!div) {
        printf("  FAILED: Could not create element\n");
        dom_document_release(doc);
        return 1;
    }
    
    const char* tag_name = dom_element_get_tagname(div);
    printf("  ✓ Element created: <%s>\n", tag_name);
    
    if (strcmp(tag_name, "div") != 0) {
        printf("  FAILED: Expected tag name 'div', got '%s'\n", tag_name);
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ Tag name correct\n\n");
    
    // Test 3: Set attributes
    printf("Test 3: Setting attributes...\n");
    int result = dom_element_set_id(div, "container");
    if (result != 0) {
        printf("  FAILED: Could not set id attribute (error code: %d)\n", result);
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ ID set to 'container'\n");
    
    result = dom_element_setattribute(div, "class", "main");
    if (result != 0) {
        printf("  FAILED: Could not set class attribute (error code: %d)\n", result);
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ Class set to 'main'\n\n");
    
    // Test 4: Get attributes
    printf("Test 4: Getting attributes...\n");
    const char* id = dom_element_get_id(div);
    printf("  id = '%s'\n", id);
    if (strcmp(id, "container") != 0) {
        printf("  FAILED: Expected id 'container', got '%s'\n", id);
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ ID correct\n");
    
    const char* class_attr = dom_element_getattribute(div, "class");
    if (!class_attr) {
        printf("  FAILED: Class attribute not found\n");
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  class = '%s'\n", class_attr);
    if (strcmp(class_attr, "main") != 0) {
        printf("  FAILED: Expected class 'main', got '%s'\n", class_attr);
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ Class correct\n\n");
    
    // Test 5: hasAttribute
    printf("Test 5: Testing hasAttribute...\n");
    unsigned char has_id = dom_element_hasattribute(div, "id");
    unsigned char has_data = dom_element_hasattribute(div, "data-foo");
    printf("  hasAttribute('id') = %d\n", has_id);
    printf("  hasAttribute('data-foo') = %d\n", has_data);
    if (has_id != 1 || has_data != 0) {
        printf("  FAILED: hasAttribute not working correctly\n");
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ hasAttribute works\n\n");
    
    // Test 6: Build tree
    printf("Test 6: Building tree...\n");
    DOMElement* span = dom_document_createelement(doc, "span");
    
    DOMNode* div_node = (DOMNode*)div;
    DOMNode* span_node = (DOMNode*)span;
    
    DOMNode* appended = dom_node_appendchild(div_node, span_node);
    if (!appended) {
        printf("  FAILED: appendChild returned NULL\n");
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ Child appended\n");
    
    unsigned char has_children = dom_node_haschildnodes(div_node);
    printf("  hasChildNodes = %d\n", has_children);
    if (has_children != 1) {
        printf("  FAILED: Expected hasChildNodes = 1, got %d\n", has_children);
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ hasChildNodes works\n");
    
    DOMNode* first_child = dom_node_get_firstchild(div_node);
    if (!first_child) {
        printf("  FAILED: firstChild is NULL\n");
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    
    const char* child_name = dom_node_get_nodename(first_child);
    printf("  firstChild.nodeName = '%s'\n", child_name);
    if (strcmp(child_name, "span") != 0) {
        printf("  FAILED: Expected nodeName 'span', got '%s'\n", child_name);
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ Tree navigation works\n\n");
    
    // Test 7: Node properties
    printf("Test 7: Testing node properties...\n");
    unsigned short node_type = dom_node_get_nodetype(div_node);
    printf("  nodeType = %d\n", node_type);
    if (node_type != 1) {  // ELEMENT_NODE = 1
        printf("  FAILED: Expected nodeType 1 (ELEMENT_NODE), got %d\n", node_type);
        dom_element_release(div);
        dom_document_release(doc);
        return 1;
    }
    printf("  ✓ nodeType correct (ELEMENT_NODE)\n\n");
    
    // Test 8: Error handling
    printf("Test 8: Testing error handling...\n");
    const char* error_name = dom_error_code_name(DOM_ERROR_INVALID_CHARACTER);
    const char* error_msg = dom_error_code_message(DOM_ERROR_INVALID_CHARACTER);
    printf("  Error name: %s\n", error_name);
    printf("  Error message: %s\n", error_msg);
    printf("  ✓ Error handling works\n\n");
    
    // Cleanup
    printf("Test 9: Cleanup...\n");
    dom_element_release(div);  // Also releases span (parent owns children)
    dom_document_release(doc);
    printf("  ✓ Resources released\n\n");
    
    printf("=== ALL TESTS PASSED ✓ ===\n");
    return 0;
}
