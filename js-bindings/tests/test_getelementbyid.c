#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "dom.h"

int main() {
    printf("Testing Document.getElementById()...\n");

    // Create document
    DOMDocument* doc = dom_document_new();
    
    // Create element with ID
    DOMElement* elem1 = dom_document_createelement(doc, "element");
    dom_element_setattribute(elem1, "id", "test-id");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)elem1);
    
    // Test: getElementById finds the element
    DOMElement* found = dom_document_getelementbyid(doc, "test-id");
    assert(found != NULL);
    assert(found == elem1);
    printf("✓ getElementById found element with ID 'test-id'\n");
    
    // Test: getElementById returns NULL for non-existent ID
    DOMElement* not_found = dom_document_getelementbyid(doc, "non-existent");
    assert(not_found == NULL);
    printf("✓ getElementById returns NULL for non-existent ID\n");
    
    // Test: Cache works (same result on second lookup)
    DOMElement* found2 = dom_document_getelementbyid(doc, "test-id");
    assert(found2 == elem1);
    printf("✓ getElementById cache works\n");
    
    // Create second element with different ID
    DOMElement* elem2 = dom_document_createelement(doc, "element");
    dom_element_setattribute(elem2, "id", "another-id");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)elem2);
    
    // Test: getElementById finds second element
    DOMElement* found3 = dom_document_getelementbyid(doc, "another-id");
    assert(found3 != NULL);
    assert(found3 == elem2);
    printf("✓ getElementById finds second element\n");
    
    // Cleanup
    dom_document_release(doc);
    
    printf("\nAll tests passed! ✓\n");
    return 0;
}
