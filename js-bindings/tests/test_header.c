/**
 * Test that dom.h compiles correctly with C
 */

#include "dom.h"
#include <stdio.h>

int main(void) {
    printf("Testing dom.h with C compiler\n");
    
    // Test that we can use the types
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "div");
    
    // Test that constants are defined
    int element_type = DOM_ELEMENT_NODE;
    int success = DOM_ERROR_SUCCESS;
    
    printf("  DOM_ELEMENT_NODE = %d\n", element_type);
    printf("  DOM_ERROR_SUCCESS = %d\n", success);
    
    // Cleanup
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("✓ Header test passed\n");
    return 0;
}
