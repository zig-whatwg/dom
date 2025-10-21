/**
 * Test Suite: ParentNode Mixin
 * 
 * Tests the ParentNode mixin methods:
 * - prepend() - Insert nodes at the beginning
 * - append() - Insert nodes at the end
 * - replaceChildren() - Replace all children
 * 
 * Spec: https://dom.spec.whatwg.org/#interface-parentnode
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

// Helper function to count children
int count_children(DOMNode* parent) {
    int count = 0;
    DOMNode* child = dom_node_get_firstchild(parent);
    while (child != NULL) {
        count++;
        child = dom_node_get_nextsibling(child);
    }
    return count;
}

// Helper function to get nth child
DOMNode* get_nth_child(DOMNode* parent, int n) {
    DOMNode* child = dom_node_get_firstchild(parent);
    for (int i = 0; i < n && child != NULL; i++) {
        child = dom_node_get_nextsibling(child);
    }
    return child;
}

void test_parentnode_append_single() {
    TEST_START("Test 1: ParentNode.append() - Single node");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    
    // Append child2
    DOMNode* nodes[1] = { (DOMNode*)child2 };
    int32_t result = dom_parentnode_append((DOMNode*)parent, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "append() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 2, "Parent has 2 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)child1, "First child is child1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)child2, "Second child is child2");
    
    dom_document_release(doc);
}

void test_parentnode_append_multiple() {
    TEST_START("Test 2: ParentNode.append() - Multiple nodes");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* new1 = dom_document_createelement(doc, "new1");
    DOMElement* new2 = dom_document_createelement(doc, "new2");
    DOMElement* new3 = dom_document_createelement(doc, "new3");
    
    // Append multiple nodes
    DOMNode* nodes[3] = { (DOMNode*)new1, (DOMNode*)new2, (DOMNode*)new3 };
    int32_t result = dom_parentnode_append((DOMNode*)parent, nodes, 3);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "append() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 3, "Parent has 3 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)new1, "First child is new1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new2, "Second child is new2");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)new3, "Third child is new3");
    
    dom_document_release(doc);
}

void test_parentnode_prepend_single() {
    TEST_START("Test 3: ParentNode.prepend() - Single node");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    
    // Prepend child2
    DOMNode* nodes[1] = { (DOMNode*)child2 };
    int32_t result = dom_parentnode_prepend((DOMNode*)parent, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "prepend() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 2, "Parent has 2 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)child2, "First child is child2");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)child1, "Second child is child1");
    
    dom_document_release(doc);
}

void test_parentnode_prepend_multiple() {
    TEST_START("Test 4: ParentNode.prepend() - Multiple nodes");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* existing = dom_document_createelement(doc, "existing");
    DOMElement* new1 = dom_document_createelement(doc, "new1");
    DOMElement* new2 = dom_document_createelement(doc, "new2");
    DOMElement* new3 = dom_document_createelement(doc, "new3");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)existing);
    
    // Prepend multiple nodes
    DOMNode* nodes[3] = { (DOMNode*)new1, (DOMNode*)new2, (DOMNode*)new3 };
    int32_t result = dom_parentnode_prepend((DOMNode*)parent, nodes, 3);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "prepend() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 4, "Parent has 4 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)new1, "First child is new1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new2, "Second child is new2");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)new3, "Third child is new3");
    ASSERT(get_nth_child((DOMNode*)parent, 3) == (DOMNode*)existing, "Fourth child is existing");
    
    dom_document_release(doc);
}

void test_parentnode_replacechildren_empty() {
    TEST_START("Test 5: ParentNode.replaceChildren() - Empty (remove all)");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    
    ASSERT(count_children((DOMNode*)parent) == 2, "Parent has 2 children initially");
    
    // Replace with empty array (remove all)
    int32_t result = dom_parentnode_replacechildren((DOMNode*)parent, NULL, 0);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "replaceChildren() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 0, "Parent has no children");
    
    dom_document_release(doc);
}

void test_parentnode_replacechildren_single() {
    TEST_START("Test 6: ParentNode.replaceChildren() - Single node");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    DOMElement* new_child = dom_document_createelement(doc, "new");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    
    // Replace all with single node
    DOMNode* nodes[1] = { (DOMNode*)new_child };
    int32_t result = dom_parentnode_replacechildren((DOMNode*)parent, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "replaceChildren() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 1, "Parent has 1 child");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)new_child, "Only child is new_child");
    
    dom_document_release(doc);
}

void test_parentnode_replacechildren_multiple() {
    TEST_START("Test 7: ParentNode.replaceChildren() - Multiple nodes");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* old1 = dom_document_createelement(doc, "old1");
    DOMElement* old2 = dom_document_createelement(doc, "old2");
    DOMElement* new1 = dom_document_createelement(doc, "new1");
    DOMElement* new2 = dom_document_createelement(doc, "new2");
    DOMElement* new3 = dom_document_createelement(doc, "new3");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)old1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)old2);
    
    // Replace all with multiple nodes
    DOMNode* nodes[3] = { (DOMNode*)new1, (DOMNode*)new2, (DOMNode*)new3 };
    int32_t result = dom_parentnode_replacechildren((DOMNode*)parent, nodes, 3);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "replaceChildren() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 3, "Parent has 3 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)new1, "First child is new1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new2, "Second child is new2");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)new3, "Third child is new3");
    
    dom_document_release(doc);
}

void test_parentnode_document() {
    TEST_START("Test 8: ParentNode on Document node");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* root = dom_document_createelement(doc, "root");
    
    // Test append single element on Document (valid)
    DOMNode* nodes[1] = { (DOMNode*)root };
    int32_t result = dom_parentnode_append((DOMNode*)doc, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "append() single element on Document succeeds");
    ASSERT(count_children((DOMNode*)doc) == 1, "Document has 1 child");
    ASSERT(get_nth_child((DOMNode*)doc, 0) == (DOMNode*)root, "Child is root element");
    
    dom_document_release(doc);
}

void test_parentnode_append_to_empty() {
    TEST_START("Test 9: ParentNode.append() - To empty parent");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child = dom_document_createelement(doc, "child");
    
    ASSERT(count_children((DOMNode*)parent) == 0, "Parent initially empty");
    
    // Append to empty parent
    DOMNode* nodes[1] = { (DOMNode*)child };
    int32_t result = dom_parentnode_append((DOMNode*)parent, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "append() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 1, "Parent has 1 child");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)child, "Child is appended");
    
    dom_document_release(doc);
}

void test_parentnode_prepend_to_empty() {
    TEST_START("Test 10: ParentNode.prepend() - To empty parent");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child = dom_document_createelement(doc, "child");
    
    ASSERT(count_children((DOMNode*)parent) == 0, "Parent initially empty");
    
    // Prepend to empty parent
    DOMNode* nodes[1] = { (DOMNode*)child };
    int32_t result = dom_parentnode_prepend((DOMNode*)parent, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "prepend() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 1, "Parent has 1 child");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)child, "Child is prepended");
    
    dom_document_release(doc);
}

void test_parentnode_with_text_nodes() {
    TEST_START("Test 11: ParentNode with Text nodes");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMText* text1 = dom_document_createtextnode(doc, "Hello");
    DOMText* text2 = dom_document_createtextnode(doc, "World");
    
    // Append text nodes
    DOMNode* nodes[2] = { (DOMNode*)text1, (DOMNode*)text2 };
    int32_t result = dom_parentnode_append((DOMNode*)parent, nodes, 2);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "append() works with text nodes");
    ASSERT(count_children((DOMNode*)parent) == 2, "Parent has 2 text children");
    
    dom_document_release(doc);
}

void test_parentnode_error_on_text_node() {
    TEST_START("Test 12: ParentNode error on Text node");
    
    DOMDocument* doc = dom_document_new();
    DOMText* text = dom_document_createtextnode(doc, "text");
    DOMElement* elem = dom_document_createelement(doc, "elem");
    
    // Try to append to text node - should fail
    DOMNode* nodes[1] = { (DOMNode*)elem };
    int32_t result = dom_parentnode_append((DOMNode*)text, nodes, 1);
    
    ASSERT(result == DOM_ERROR_HIERARCHY_REQUEST, "append() fails on Text node");
    
    dom_document_release(doc);
}

int main() {
    printf("========================================\n");
    printf("DOM ParentNode Mixin Test Suite\n");
    printf("========================================\n");
    
    test_parentnode_append_single();
    test_parentnode_append_multiple();
    test_parentnode_prepend_single();
    test_parentnode_prepend_multiple();
    test_parentnode_replacechildren_empty();
    test_parentnode_replacechildren_single();
    test_parentnode_replacechildren_multiple();
    test_parentnode_document();
    test_parentnode_append_to_empty();
    test_parentnode_prepend_to_empty();
    test_parentnode_with_text_nodes();
    test_parentnode_error_on_text_node();
    
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
