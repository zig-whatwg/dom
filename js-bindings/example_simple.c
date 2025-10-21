/**
 * Simple DOM Example
 * 
 * This example shows how easy it is to use the DOM library with dom.h
 * 
 * Compile:
 *   gcc -o example example_simple.c zig-out/lib/libdom.a -lpthread
 */

#include <stdio.h>
#include "dom.h"

int main(void) {
    printf("Creating a simple DOM tree...\n\n");
    
    // Create document
    DOMDocument* doc = dom_document_new();
    printf("✓ Document created\n");
    
    // Create a div element with id and class
    DOMElement* div = dom_document_createelement(doc, "div");
    dom_element_set_id(div, "container");
    dom_element_set_classname(div, "main highlight");
    printf("✓ Created div#container.main.highlight\n");
    
    // Create a paragraph with custom attribute
    DOMElement* p = dom_document_createelement(doc, "p");
    dom_element_setattribute(p, "data-id", "123");
    printf("✓ Created paragraph with data-id='123'\n");
    
    // Create text node
    DOMText* text = dom_document_createtextnode(doc, "Hello, World!");
    printf("✓ Created text node\n");
    
    // Build the tree: div > p > text
    dom_node_appendchild((DOMNode*)div, (DOMNode*)p);
    dom_node_appendchild((DOMNode*)p, (DOMNode*)text);
    printf("✓ Built tree structure\n\n");
    
    // Query the tree
    printf("Tree structure:\n");
    printf("  <%s", dom_element_get_tagname(div));
    printf(" id=\"%s\"", dom_element_get_id(div));
    printf(" class=\"%s\">\n", dom_element_get_classname(div));
    
    DOMNode* child = dom_node_get_firstchild((DOMNode*)div);
    if (child) {
        const char* child_tag = dom_node_get_nodename(child);
        const char* data_id = dom_element_getattribute((DOMElement*)child, "data-id");
        printf("    <%s data-id=\"%s\">\n", child_tag, data_id);
        
        DOMNode* grandchild = dom_node_get_firstchild(child);
        if (grandchild && dom_node_get_nodetype(grandchild) == DOM_TEXT_NODE) {
            const char* value = dom_node_get_nodevalue(grandchild);
            printf("      \"%s\"\n", value);
        }
        
        printf("    </%s>\n", child_tag);
    }
    
    printf("  </%s>\n\n", dom_element_get_tagname(div));
    
    // Cleanup
    dom_element_release(div);
    dom_document_release(doc);
    printf("✓ Cleaned up\n");
    
    return 0;
}
