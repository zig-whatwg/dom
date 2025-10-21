/**
 * Test Selector Methods
 * 
 * Tests the newly implemented matches() and closest() methods.
 */

#include <stdio.h>
#include <string.h>
#include "dom.h"

int main(void) {
    printf("=== Selector Methods Test ===\n\n");
    
    // Create document
    DOMDocument* doc = dom_document_new();
    
    // Create structure: div.container > p#paragraph.text > span
    DOMElement* div = dom_document_createelement(doc, "div");
    dom_element_set_classname(div, "container");
    
    DOMElement* p = dom_document_createelement(doc, "p");
    dom_element_set_id(p, "paragraph");
    dom_element_set_classname(p, "text");
    
    DOMElement* span = dom_document_createelement(doc, "span");
    
    // Build tree
    dom_node_appendchild((DOMNode*)div, (DOMNode*)p);
    dom_node_appendchild((DOMNode*)p, (DOMNode*)span);
    
    printf("Created structure: div.container > p#paragraph.text > span\n\n");
    
    // Test 1: matches() with class selector
    printf("Test 1: matches() with class selector\n");
    uint8_t matches1 = dom_element_matches(div, ".container");
    uint8_t matches2 = dom_element_matches(div, ".wrong");
    printf("  div.matches('.container') = %d\n", matches1);
    printf("  div.matches('.wrong') = %d\n", matches2);
    if (matches1 == 1 && matches2 == 0) {
        printf("  ✓ Class selector works\n\n");
    } else {
        printf("  ✗ FAILED\n\n");
        return 1;
    }
    
    // Test 2: matches() with ID selector
    printf("Test 2: matches() with ID selector\n");
    uint8_t matches3 = dom_element_matches(p, "#paragraph");
    uint8_t matches4 = dom_element_matches(p, "#wrong");
    printf("  p.matches('#paragraph') = %d\n", matches3);
    printf("  p.matches('#wrong') = %d\n", matches4);
    if (matches3 == 1 && matches4 == 0) {
        printf("  ✓ ID selector works\n\n");
    } else {
        printf("  ✗ FAILED\n\n");
        return 1;
    }
    
    // Test 3: matches() with tag selector
    printf("Test 3: matches() with tag selector\n");
    uint8_t matches5 = dom_element_matches(span, "span");
    uint8_t matches6 = dom_element_matches(span, "div");
    printf("  span.matches('span') = %d\n", matches5);
    printf("  span.matches('div') = %d\n", matches6);
    if (matches5 == 1 && matches6 == 0) {
        printf("  ✓ Tag selector works\n\n");
    } else {
        printf("  ✗ FAILED\n\n");
        return 1;
    }
    
    // Test 4: matches() with complex selector
    printf("Test 4: matches() with complex selector\n");
    uint8_t matches7 = dom_element_matches(p, "p.text");
    uint8_t matches8 = dom_element_matches(p, "p.wrong");
    printf("  p.matches('p.text') = %d\n", matches7);
    printf("  p.matches('p.wrong') = %d\n", matches8);
    if (matches7 == 1 && matches8 == 0) {
        printf("  ✓ Complex selector works\n\n");
    } else {
        printf("  ✗ FAILED\n\n");
        return 1;
    }
    
    // Test 5: closest() - find parent by class
    printf("Test 5: closest() - find parent by class\n");
    DOMElement* closest1 = dom_element_closest(span, ".container");
    if (closest1 == div) {
        printf("  span.closest('.container') = div ✓\n");
    } else {
        printf("  ✗ FAILED: expected div, got %p\n", (void*)closest1);
        return 1;
    }
    
    DOMElement* closest2 = dom_element_closest(span, ".text");
    if (closest2 == p) {
        printf("  span.closest('.text') = p ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected p, got %p\n", (void*)closest2);
        return 1;
    }
    
    // Test 6: closest() - find self
    printf("Test 6: closest() - find self\n");
    DOMElement* closest3 = dom_element_closest(p, "#paragraph");
    if (closest3 == p) {
        printf("  p.closest('#paragraph') = p (self) ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected p, got %p\n", (void*)closest3);
        return 1;
    }
    
    // Test 7: closest() - not found returns NULL
    printf("Test 7: closest() - not found returns NULL\n");
    DOMElement* closest4 = dom_element_closest(span, ".nonexistent");
    if (closest4 == NULL) {
        printf("  span.closest('.nonexistent') = NULL ✓\n\n");
    } else {
        printf("  ✗ FAILED: expected NULL, got %p\n", (void*)closest4);
        return 1;
    }
    
    // Test 8: webkitMatchesSelector (alias)
    printf("Test 8: webkitMatchesSelector (alias)\n");
    uint8_t webkit_matches = dom_element_webkitmatchesselector(div, ".container");
    if (webkit_matches == 1) {
        printf("  div.webkitMatchesSelector('.container') = 1 ✓\n\n");
    } else {
        printf("  ✗ FAILED\n\n");
        return 1;
    }
    
    // Cleanup
    dom_element_release(div);
    dom_document_release(doc);
    
    printf("=== ALL SELECTOR TESTS PASSED ✓ ===\n");
    return 0;
}
