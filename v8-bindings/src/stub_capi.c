// Stub C API functions for unimplemented features
// These allow linking but throw errors if called

#include "dom.h"
#include <stdio.h>
#include <stdlib.h>

// Stub for dom_node_getrootnode
DOMNode* dom_node_getrootnode(DOMNode* node, uint8_t composed) {
    fprintf(stderr, "ERROR: dom_node_getrootnode not implemented\n");
    return NULL;
}

// Stub for dom_element_queryselectorall  
DOMNodeList* dom_element_queryselectorall(DOMElement* elem, const char* selectors) {
    fprintf(stderr, "ERROR: dom_element_queryselectorall not implemented\n");
    return NULL;
}
