/**
 * Test Suite: Shadow DOM (ShadowRoot)
 * 
 * Tests:
 * - Element.attachShadow() - Attach shadow root to element
 * - ShadowRoot properties - mode, delegatesFocus, slotAssignment, host
 * - Shadow tree manipulation - appendChild, querySelector, etc.
 * - Mode enforcement - open vs closed
 * 
 * Spec: https://dom.spec.whatwg.org/#interface-shadowroot
 */

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "dom.h"

int tests_passed = 0;
int tests_failed = 0;

#define ASSERT(condition, message) \
    do { \
        if (condition) { \
            printf("  ✓ %s\n", message); \
            tests_passed++; \
        } else { \
            printf("  ✗ %s\n", message); \
            tests_failed++; \
        } \
    } while (0)

#define TEST_START(name) \
    printf("\n%s\n", name); \
    printf("----------------------------------------\n")

void test_attachshadow_open() {
    TEST_START("Test 1: attachShadow() - Open mode");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* host = dom_document_createelement(doc, "host");
    
    // Attach shadow root in open mode
    DOMShadowRoot* shadow = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, false);
    
    ASSERT(shadow != NULL, "attachShadow returns shadow root");
    ASSERT(dom_shadowroot_get_mode(shadow) == DOM_SHADOWROOT_MODE_OPEN, "Mode is open");
    ASSERT(dom_shadowroot_get_delegatesfocus(shadow) == false, "delegatesFocus is false");
    
    // Verify host relationship
    DOMElement* host_check = dom_shadowroot_get_host(shadow);
    ASSERT(host_check == host, "host property returns correct element");
    
    // Verify shadowRoot getter returns shadow root (open mode)
    DOMShadowRoot* shadow_check = dom_element_get_shadowroot(host);
    ASSERT(shadow_check == shadow, "Element.shadowRoot returns shadow root in open mode");
    
    dom_element_release(host);
    dom_document_release(doc);
}

void test_attachshadow_closed() {
    TEST_START("Test 2: attachShadow() - Closed mode");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* host = dom_document_createelement(doc, "host");
    
    // Attach shadow root in closed mode
    DOMShadowRoot* shadow = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_CLOSED, false);
    
    ASSERT(shadow != NULL, "attachShadow returns shadow root");
    ASSERT(dom_shadowroot_get_mode(shadow) == DOM_SHADOWROOT_MODE_CLOSED, "Mode is closed");
    
    // Verify host relationship still works
    DOMElement* host_check = dom_shadowroot_get_host(shadow);
    ASSERT(host_check == host, "host property returns correct element");
    
    // Verify shadowRoot getter returns NULL (closed mode)
    DOMShadowRoot* shadow_check = dom_element_get_shadowroot(host);
    ASSERT(shadow_check == NULL, "Element.shadowRoot returns NULL in closed mode");
    
    dom_element_release(host);
    dom_document_release(doc);
}

void test_attachshadow_delegates_focus() {
    TEST_START("Test 3: attachShadow() - Delegates focus");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* host = dom_document_createelement(doc, "host");
    
    // Attach shadow root with delegatesFocus = true
    DOMShadowRoot* shadow = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, true);
    
    ASSERT(shadow != NULL, "attachShadow returns shadow root");
    ASSERT(dom_shadowroot_get_delegatesfocus(shadow) == true, "delegatesFocus is true");
    
    dom_element_release(host);
    dom_document_release(doc);
}

void test_attachshadow_once() {
    TEST_START("Test 4: attachShadow() - Can only attach once");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* host = dom_document_createelement(doc, "host");
    
    // First attachment succeeds
    DOMShadowRoot* shadow1 = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, false);
    ASSERT(shadow1 != NULL, "First attachShadow succeeds");
    
    // Second attachment fails
    DOMShadowRoot* shadow2 = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, false);
    ASSERT(shadow2 == NULL, "Second attachShadow returns NULL");
    
    dom_element_release(host);
    dom_document_release(doc);
}

void test_shadow_tree_manipulation() {
    TEST_START("Test 5: Shadow tree - appendChild");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* host = dom_document_createelement(doc, "host");
    DOMShadowRoot* shadow = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, false);
    
    // Add elements to shadow tree
    DOMElement* child1 = dom_document_createelement(doc, "child");
    DOMElement* child2 = dom_document_createelement(doc, "child");
    
    // ShadowRoot extends DocumentFragment which extends Node
    DOMNode* result1 = dom_node_appendchild((DOMNode*)shadow, (DOMNode*)child1);
    DOMNode* result2 = dom_node_appendchild((DOMNode*)shadow, (DOMNode*)child2);
    
    ASSERT(result1 != NULL, "Can append first child to shadow root");
    ASSERT(result2 != NULL, "Can append second child to shadow root");
    
    // Verify structure
    DOMNode* first_child = dom_node_get_firstchild((DOMNode*)shadow);
    DOMNode* last_child = dom_node_get_lastchild((DOMNode*)shadow);
    
    ASSERT(first_child == (DOMNode*)child1, "First child is correct");
    ASSERT(last_child == (DOMNode*)child2, "Last child is correct");
    
    dom_element_release(host);
    dom_document_release(doc);
}

void test_shadow_properties() {
    TEST_START("Test 6: ShadowRoot properties");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* host = dom_document_createelement(doc, "host");
    DOMShadowRoot* shadow = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, false);
    
    // Check default values
    ASSERT(dom_shadowroot_get_slotassignment(shadow) == DOM_SLOTASSIGNMENT_NAMED, 
           "Default slot assignment is named");
    ASSERT(dom_shadowroot_get_clonable(shadow) == false, "Default clonable is false");
    ASSERT(dom_shadowroot_get_serializable(shadow) == false, "Default serializable is false");
    
    dom_element_release(host);
    dom_document_release(doc);
}

void test_shadow_querySelector() {
    TEST_START("Test 7: Shadow tree - structure");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* host = dom_document_createelement(doc, "host");
    DOMShadowRoot* shadow = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, false);
    
    // Add element with class to shadow tree
    DOMElement* child = dom_document_createelement(doc, "child");
    dom_element_setattribute(child, "class", "target");
    dom_node_appendchild((DOMNode*)shadow, (DOMNode*)child);
    
    // Verify child is in shadow tree
    DOMNode* first_child = dom_node_get_firstchild((DOMNode*)shadow);
    ASSERT(first_child == (DOMNode*)child, "Child is in shadow tree");
    
    // Verify parent relationship
    DOMNode* parent = dom_node_get_parentnode((DOMNode*)child);
    ASSERT(parent == (DOMNode*)shadow, "Child's parent is shadow root");
    
    dom_element_release(host);
    dom_document_release(doc);
}

void test_shadow_encapsulation() {
    TEST_START("Test 8: Shadow tree encapsulation");
    
    DOMDocument* doc = dom_document_new();
    
    // Create document element (root)
    DOMElement* root = dom_document_createelement(doc, "root");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    // Create host and add to root
    DOMElement* host = dom_document_createelement(doc, "host");
    dom_node_appendchild((DOMNode*)root, (DOMNode*)host);
    
    // Attach shadow and add content
    DOMShadowRoot* shadow = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, false);
    DOMElement* shadow_child = dom_document_createelement(doc, "shadow-content");
    dom_element_setattribute(shadow_child, "class", "shadow-target");
    dom_node_appendchild((DOMNode*)shadow, (DOMNode*)shadow_child);
    
    // Add regular child to root
    DOMElement* regular_child = dom_document_createelement(doc, "regular-content");
    dom_element_setattribute(regular_child, "class", "regular-target");
    dom_node_appendchild((DOMNode*)root, (DOMNode*)regular_child);
    
    // Query from document - should NOT find shadow content
    DOMElement* found_shadow = dom_document_queryselector(doc, ".shadow-target");
    DOMElement* found_regular = dom_document_queryselector(doc, ".regular-target");
    
    ASSERT(found_shadow == NULL, "Document query does NOT find shadow content");
    ASSERT(found_regular == regular_child, "Document query finds regular content");
    
    dom_document_release(doc);
}

void test_multiple_hosts() {
    TEST_START("Test 9: Multiple elements with shadow roots");
    
    DOMDocument* doc = dom_document_new();
    
    DOMElement* host1 = dom_document_createelement(doc, "host1");
    DOMElement* host2 = dom_document_createelement(doc, "host2");
    
    DOMShadowRoot* shadow1 = dom_element_attachshadow(host1, DOM_SHADOWROOT_MODE_OPEN, false);
    DOMShadowRoot* shadow2 = dom_element_attachshadow(host2, DOM_SHADOWROOT_MODE_CLOSED, true);
    
    ASSERT(shadow1 != shadow2, "Each host has its own shadow root");
    ASSERT(dom_shadowroot_get_host(shadow1) == host1, "shadow1 host is host1");
    ASSERT(dom_shadowroot_get_host(shadow2) == host2, "shadow2 host is host2");
    ASSERT(dom_shadowroot_get_mode(shadow1) == DOM_SHADOWROOT_MODE_OPEN, "shadow1 is open");
    ASSERT(dom_shadowroot_get_mode(shadow2) == DOM_SHADOWROOT_MODE_CLOSED, "shadow2 is closed");
    ASSERT(dom_shadowroot_get_delegatesfocus(shadow1) == false, "shadow1 doesn't delegate focus");
    ASSERT(dom_shadowroot_get_delegatesfocus(shadow2) == true, "shadow2 delegates focus");
    
    dom_element_release(host1);
    dom_element_release(host2);
    dom_document_release(doc);
}

void test_shadow_node_type() {
    TEST_START("Test 10: ShadowRoot node type");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* host = dom_document_createelement(doc, "host");
    DOMShadowRoot* shadow = dom_element_attachshadow(host, DOM_SHADOWROOT_MODE_OPEN, false);
    
    // ShadowRoot extends DocumentFragment but has its own node type (12)
    // This implementation distinguishes ShadowRoot from DocumentFragment
    int node_type = dom_node_get_nodetype((DOMNode*)shadow);
    ASSERT(node_type == 12, "ShadowRoot node type is SHADOW_ROOT (12)");
    
    dom_element_release(host);
    dom_document_release(doc);
}

int main() {
    printf("========================================\n");
    printf("DOM Shadow DOM (ShadowRoot)\n");
    printf("========================================\n");
    
    test_attachshadow_open();
    test_attachshadow_closed();
    test_attachshadow_delegates_focus();
    test_attachshadow_once();
    test_shadow_tree_manipulation();
    test_shadow_properties();
    test_shadow_querySelector();
    test_shadow_encapsulation();
    test_multiple_hosts();
    test_shadow_node_type();
    
    printf("\n========================================\n");
    printf("Test Results\n");
    printf("========================================\n");
    printf("Passed: %d\n", tests_passed);
    printf("Failed: %d\n", tests_failed);
    printf("Total:  %d\n", tests_passed + tests_failed);
    printf("========================================\n");
    
    if (tests_failed == 0) {
        printf("✓ All tests passed!\n");
        return 0;
    } else {
        printf("✗ Some tests failed.\n");
        return 1;
    }
}
