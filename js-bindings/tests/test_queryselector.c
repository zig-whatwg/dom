/**
 * Test querySelector Methods
 * 
 * Tests the newly implemented querySelector and querySelectorAll methods.
 */

#include <stdio.h>
#include <string.h>
#include "dom.h"

int main(void) {
    printf("=== querySelector Methods Test ===\n\n");
    
    // Create document
    DOMDocument* doc = dom_document_new();
    
    // Create structure:
    // div#root.container
    //   > p.intro
    //   > div.content
    //     > span#target.highlight
    //     > span.normal
    
    DOMElement* root = dom_document_createelement(doc, "div");
    dom_element_set_id(root, "root");
    dom_element_set_classname(root, "container");
    
    DOMElement* intro = dom_document_createelement(doc, "p");
    dom_element_set_classname(intro, "intro");
    
    DOMElement* content = dom_document_createelement(doc, "div");
    dom_element_set_classname(content, "content");
    
    DOMElement* target = dom_document_createelement(doc, "span");
    dom_element_set_id(target, "target");
    dom_element_set_classname(target, "highlight");
    
    DOMElement* normal = dom_document_createelement(doc, "span");
    dom_element_set_classname(normal, "normal");
    
    // Build tree
    dom_node_appendchild((DOMNode*)root, (DOMNode*)intro);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)content);
    dom_node_appendchild((DOMNode*)content, (DOMNode*)target);
    dom_node_appendchild((DOMNode*)content, (DOMNode*)normal);
    
    // Add root to document (simulate document.body)
    // Note: For now we just use root as our starting point
    
    printf("Created structure:\n");
    printf("  div#root.container\n");
    printf("    > p.intro\n");
    printf("    > div.content\n");
    printf("      > span#target.highlight\n");
    printf("      > span.normal\n\n");
    
    // Test 1: querySelector by ID from element
    printf("Test 1: querySelector by ID from element\n");
    DOMElement* found1 = dom_element_queryselector(root, "#target");
    if (found1 == target) {
        printf("  root.querySelector('#target') = span#target ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected target span, got %p\n\n", (void*)found1);
        return 1;
    }
    
    // Test 2: querySelector by class from element
    printf("Test 2: querySelector by class from element\n");
    DOMElement* found2 = dom_element_queryselector(root, ".highlight");
    if (found2 == target) {
        printf("  root.querySelector('.highlight') = span#target ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected target span, got %p\n\n", (void*)found2);
        return 1;
    }
    
    // Test 3: querySelector by tag from element
    printf("Test 3: querySelector by tag from element\n");
    DOMElement* found3 = dom_element_queryselector(root, "span");
    if (found3 == target || found3 == normal) {
        const char* found_id = dom_element_get_id(found3);
        printf("  root.querySelector('span') = span (id='%s') ✓\n\n", found_id);
    } else {
        printf("  ✗ FAILED: expected a span, got %p\n\n", (void*)found3);
        return 1;
    }
    
    // Test 4: querySelector with descendant combinator
    printf("Test 4: querySelector with descendant combinator\n");
    DOMElement* found4 = dom_element_queryselector(root, "div span");
    if (found4 == target || found4 == normal) {
        printf("  root.querySelector('div span') = span ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected a span inside div, got %p\n\n", (void*)found4);
        return 1;
    }
    
    // Test 5: querySelector not found returns NULL
    printf("Test 5: querySelector not found returns NULL\n");
    DOMElement* found5 = dom_element_queryselector(root, ".nonexistent");
    if (found5 == NULL) {
        printf("  root.querySelector('.nonexistent') = NULL ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected NULL, got %p\n\n", (void*)found5);
        return 1;
    }
    
    // Test 6: querySelector from nested element
    printf("Test 6: querySelector from nested element\n");
    DOMElement* found6 = dom_element_queryselector(content, ".highlight");
    if (found6 == target) {
        printf("  content.querySelector('.highlight') = span#target ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected target span, got %p\n\n", (void*)found6);
        return 1;
    }
    
    // Test 7: querySelector doesn't match self
    printf("Test 7: querySelector searches descendants only\n");
    DOMElement* found7 = dom_element_queryselector(root, "#root");
    if (found7 == NULL) {
        printf("  root.querySelector('#root') = NULL (doesn't match self) ✓\n\n");
    } else {
        printf("  ✗ FAILED: querySelector shouldn't match self, got %p\n\n", (void*)found7);
        return 1;
    }
    
    // Test 8: Complex selector
    printf("Test 8: querySelector with complex selector\n");
    DOMElement* found8 = dom_element_queryselector(root, ".content .highlight");
    if (found8 == target) {
        printf("  root.querySelector('.content .highlight') = span#target ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected target span, got %p\n\n", (void*)found8);
        return 1;
    }
    
    // Cleanup
    dom_element_release(root);
    dom_document_release(doc);
    
    printf("=== ALL QUERYSELECTOR TESTS PASSED ✓ ===\n");
    return 0;
}
