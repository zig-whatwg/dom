/**
 * Test Suite: ChildNode Mixin
 * 
 * Tests the ChildNode mixin methods:
 * - before() - Insert nodes before a child
 * - after() - Insert nodes after a child
 * - replaceWith() - Replace a child with other nodes
 * - remove() - Remove a child from its parent
 * 
 * Spec: https://dom.spec.whatwg.org/#interface-childnode
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

void test_childnode_remove_basic() {
    TEST_START("Test 1: ChildNode.remove() - Basic removal");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    DOMElement* child3 = dom_document_createelement(doc, "child3");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child3);
    
    ASSERT(count_children((DOMNode*)parent) == 3, "Parent has 3 children initially");
    
    // Remove middle child
    dom_childnode_remove((DOMNode*)child2);
    
    ASSERT(count_children((DOMNode*)parent) == 2, "Parent has 2 children after removal");
    ASSERT(dom_node_get_firstchild((DOMNode*)parent) == (DOMNode*)child1, "First child is child1");
    ASSERT(dom_node_get_nextsibling((DOMNode*)child1) == (DOMNode*)child3, "Second child is child3");
    ASSERT(dom_node_get_parentnode((DOMNode*)child2) == NULL, "Removed child has no parent");
    
    dom_document_release(doc);
}

void test_childnode_remove_no_parent() {
    TEST_START("Test 2: ChildNode.remove() - No parent (no-op)");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* orphan = dom_document_createelement(doc, "orphan");
    
    // Remove node with no parent - should be a no-op
    dom_childnode_remove((DOMNode*)orphan);
    
    ASSERT(dom_node_get_parentnode((DOMNode*)orphan) == NULL, "Orphan still has no parent");
    
    dom_document_release(doc);
}

void test_childnode_before_single() {
    TEST_START("Test 3: ChildNode.before() - Insert single node");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    DOMElement* new_node = dom_document_createelement(doc, "new");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    
    // Insert new_node before child2
    DOMNode* nodes[1] = { (DOMNode*)new_node };
    int32_t result = dom_childnode_before((DOMNode*)child2, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "before() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 3, "Parent has 3 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)child1, "First child is child1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new_node, "Second child is new_node");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)child2, "Third child is child2");
    
    dom_document_release(doc);
}

void test_childnode_before_multiple() {
    TEST_START("Test 4: ChildNode.before() - Insert multiple nodes");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child = dom_document_createelement(doc, "child");
    DOMElement* new1 = dom_document_createelement(doc, "new1");
    DOMElement* new2 = dom_document_createelement(doc, "new2");
    DOMElement* new3 = dom_document_createelement(doc, "new3");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child);
    
    // Insert multiple nodes before child
    DOMNode* nodes[3] = { (DOMNode*)new1, (DOMNode*)new2, (DOMNode*)new3 };
    int32_t result = dom_childnode_before((DOMNode*)child, nodes, 3);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "before() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 4, "Parent has 4 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)new1, "First child is new1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new2, "Second child is new2");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)new3, "Third child is new3");
    ASSERT(get_nth_child((DOMNode*)parent, 3) == (DOMNode*)child, "Fourth child is original child");
    
    dom_document_release(doc);
}

void test_childnode_after_single() {
    TEST_START("Test 5: ChildNode.after() - Insert single node");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    DOMElement* new_node = dom_document_createelement(doc, "new");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    
    // Insert new_node after child1
    DOMNode* nodes[1] = { (DOMNode*)new_node };
    int32_t result = dom_childnode_after((DOMNode*)child1, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "after() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 3, "Parent has 3 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)child1, "First child is child1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new_node, "Second child is new_node");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)child2, "Third child is child2");
    
    dom_document_release(doc);
}

void test_childnode_after_multiple() {
    TEST_START("Test 6: ChildNode.after() - Insert multiple nodes");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child = dom_document_createelement(doc, "child");
    DOMElement* new1 = dom_document_createelement(doc, "new1");
    DOMElement* new2 = dom_document_createelement(doc, "new2");
    DOMElement* new3 = dom_document_createelement(doc, "new3");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child);
    
    // Insert multiple nodes after child
    DOMNode* nodes[3] = { (DOMNode*)new1, (DOMNode*)new2, (DOMNode*)new3 };
    int32_t result = dom_childnode_after((DOMNode*)child, nodes, 3);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "after() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 4, "Parent has 4 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)child, "First child is original child");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new1, "Second child is new1");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)new2, "Third child is new2");
    ASSERT(get_nth_child((DOMNode*)parent, 3) == (DOMNode*)new3, "Fourth child is new3");
    
    dom_document_release(doc);
}

void test_childnode_replacewith_single() {
    TEST_START("Test 7: ChildNode.replaceWith() - Replace with single node");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "child1");
    DOMElement* child2 = dom_document_createelement(doc, "child2");
    DOMElement* child3 = dom_document_createelement(doc, "child3");
    DOMElement* replacement = dom_document_createelement(doc, "replacement");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child3);
    
    // Replace child2 with replacement
    DOMNode* nodes[1] = { (DOMNode*)replacement };
    int32_t result = dom_childnode_replacewith((DOMNode*)child2, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "replaceWith() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 3, "Parent still has 3 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)child1, "First child is child1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)replacement, "Second child is replacement");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)child3, "Third child is child3");
    ASSERT(dom_node_get_parentnode((DOMNode*)child2) == NULL, "Old child has no parent");
    
    dom_document_release(doc);
}

void test_childnode_replacewith_multiple() {
    TEST_START("Test 8: ChildNode.replaceWith() - Replace with multiple nodes");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child = dom_document_createelement(doc, "child");
    DOMElement* new1 = dom_document_createelement(doc, "new1");
    DOMElement* new2 = dom_document_createelement(doc, "new2");
    DOMElement* new3 = dom_document_createelement(doc, "new3");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child);
    
    // Replace child with multiple nodes
    DOMNode* nodes[3] = { (DOMNode*)new1, (DOMNode*)new2, (DOMNode*)new3 };
    int32_t result = dom_childnode_replacewith((DOMNode*)child, nodes, 3);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "replaceWith() succeeds");
    ASSERT(count_children((DOMNode*)parent) == 3, "Parent has 3 children after replacement");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)new1, "First child is new1");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new2, "Second child is new2");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)new3, "Third child is new3");
    ASSERT(dom_node_get_parentnode((DOMNode*)child) == NULL, "Old child has no parent");
    
    dom_document_release(doc);
}

void test_childnode_before_no_parent() {
    TEST_START("Test 9: ChildNode.before() - No-op when no parent");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* orphan = dom_document_createelement(doc, "orphan");
    DOMElement* new_node = dom_document_createelement(doc, "new");
    
    // Try to insert before node with no parent - should be a no-op
    DOMNode* nodes[1] = { (DOMNode*)new_node };
    int32_t result = dom_childnode_before((DOMNode*)orphan, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "before() succeeds (no-op)");
    ASSERT(dom_node_get_parentnode((DOMNode*)orphan) == NULL, "Orphan still has no parent");
    ASSERT(dom_node_get_parentnode((DOMNode*)new_node) == NULL, "New node has no parent");
    
    dom_document_release(doc);
}

void test_childnode_after_no_parent() {
    TEST_START("Test 10: ChildNode.after() - No-op when no parent");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* orphan = dom_document_createelement(doc, "orphan");
    DOMElement* new_node = dom_document_createelement(doc, "new");
    
    // Try to insert after node with no parent - should be a no-op
    DOMNode* nodes[1] = { (DOMNode*)new_node };
    int32_t result = dom_childnode_after((DOMNode*)orphan, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "after() succeeds (no-op)");
    ASSERT(dom_node_get_parentnode((DOMNode*)orphan) == NULL, "Orphan still has no parent");
    ASSERT(dom_node_get_parentnode((DOMNode*)new_node) == NULL, "New node has no parent");
    
    dom_document_release(doc);
}

void test_childnode_replacewith_no_parent() {
    TEST_START("Test 11: ChildNode.replaceWith() - No-op when no parent");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* orphan = dom_document_createelement(doc, "orphan");
    DOMElement* new_node = dom_document_createelement(doc, "new");
    
    // Try to replace node with no parent - should be a no-op
    DOMNode* nodes[1] = { (DOMNode*)new_node };
    int32_t result = dom_childnode_replacewith((DOMNode*)orphan, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "replaceWith() succeeds (no-op)");
    ASSERT(dom_node_get_parentnode((DOMNode*)orphan) == NULL, "Orphan still has no parent");
    ASSERT(dom_node_get_parentnode((DOMNode*)new_node) == NULL, "New node has no parent");
    
    dom_document_release(doc);
}

void test_childnode_with_text_nodes() {
    TEST_START("Test 12: ChildNode with Text nodes");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMText* text1 = dom_document_createtextnode(doc, "Hello");
    DOMElement* elem = dom_document_createelement(doc, "elem");
    DOMText* text2 = dom_document_createtextnode(doc, "World");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)text1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)elem);
    
    // Insert text2 after elem
    DOMNode* nodes[1] = { (DOMNode*)text2 };
    int32_t result = dom_childnode_after((DOMNode*)elem, nodes, 1);
    
    ASSERT(result == DOM_ERROR_SUCCESS, "after() works with text nodes");
    ASSERT(count_children((DOMNode*)parent) == 3, "Parent has 3 children");
    ASSERT(get_nth_child((DOMNode*)parent, 2) == (DOMNode*)text2, "Text node inserted");
    
    dom_document_release(doc);
}

int main() {
    printf("========================================\n");
    printf("DOM ChildNode Mixin Test Suite\n");
    printf("========================================\n");
    
    test_childnode_remove_basic();
    test_childnode_remove_no_parent();
    test_childnode_before_single();
    test_childnode_before_multiple();
    test_childnode_after_single();
    test_childnode_after_multiple();
    test_childnode_replacewith_single();
    test_childnode_replacewith_multiple();
    test_childnode_before_no_parent();
    test_childnode_after_no_parent();
    test_childnode_replacewith_no_parent();
    test_childnode_with_text_nodes();
    
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
