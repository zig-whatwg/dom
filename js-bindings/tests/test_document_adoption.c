/**
 * Test Suite: Document Node Adoption and Import
 * 
 * Tests Document.adoptNode() and Document.importNode() methods:
 * - adoptNode() - Transfer node ownership between documents
 * - importNode() - Copy node from one document to another
 * 
 * Spec: https://dom.spec.whatwg.org/#interface-document
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

void test_importnode_shallow() {
    TEST_START("Test 1: importNode() - Shallow clone");
    
    DOMDocument* doc1 = dom_document_new();
    DOMDocument* doc2 = dom_document_new();
    
    // Create element in doc1 with a child
    DOMElement* elem = dom_document_createelement(doc1, "parent");
    DOMElement* child = dom_document_createelement(doc1, "child");
    dom_node_appendchild((DOMNode*)elem, (DOMNode*)child);
    
    // Import shallow (no children)
    DOMNode* imported = dom_document_importnode(doc2, (DOMNode*)elem, 0);
    
    ASSERT(imported != NULL, "importNode returns a node");
    ASSERT(imported != (DOMNode*)elem, "Imported node is a different pointer");
    ASSERT(dom_node_get_firstchild(imported) == NULL, "Shallow import has no children");
    ASSERT(dom_node_get_ownerdocument(imported) == (DOMNode*)(DOMNode*)doc2, "Imported node owned by doc2");
    ASSERT(dom_node_get_ownerdocument((DOMNode*)elem) == (DOMNode*)doc1, "Original node still owned by doc1");
    
    dom_document_release(doc1);
    dom_document_release(doc2);
}

void test_importnode_deep() {
    TEST_START("Test 2: importNode() - Deep clone");
    
    DOMDocument* doc1 = dom_document_new();
    DOMDocument* doc2 = dom_document_new();
    
    // Create element tree in doc1
    DOMElement* parent = dom_document_createelement(doc1, "parent");
    DOMElement* child1 = dom_document_createelement(doc1, "child1");
    DOMElement* child2 = dom_document_createelement(doc1, "child2");
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    
    // Import deep (with children)
    DOMNode* imported = dom_document_importnode(doc2, (DOMNode*)parent, 1);
    
    ASSERT(imported != NULL, "importNode returns a node");
    ASSERT(imported != (DOMNode*)parent, "Imported node is a different pointer");
    
    // Check children were cloned
    DOMNode* imported_child1 = dom_node_get_firstchild(imported);
    ASSERT(imported_child1 != NULL, "Deep import has first child");
    ASSERT(imported_child1 != (DOMNode*)child1, "Child is a clone (different pointer)");
    
    DOMNode* imported_child2 = dom_node_get_nextsibling(imported_child1);
    ASSERT(imported_child2 != NULL, "Deep import has second child");
    
    // Verify ownership
    ASSERT(dom_node_get_ownerdocument(imported) == (DOMNode*)(DOMNode*)doc2, "Imported parent owned by doc2");
    ASSERT(dom_node_get_ownerdocument(imported_child1) == (DOMNode*)(DOMNode*)doc2, "Imported child1 owned by doc2");
    ASSERT(dom_node_get_ownerdocument(imported_child2) == (DOMNode*)(DOMNode*)doc2, "Imported child2 owned by doc2");
    
    // Original unchanged
    ASSERT(dom_node_get_ownerdocument((DOMNode*)parent) == (DOMNode*)doc1, "Original parent still owned by doc1");
    
    dom_document_release(doc1);
    dom_document_release(doc2);
}

void test_importnode_text() {
    TEST_START("Test 3: importNode() - Text node");
    
    DOMDocument* doc1 = dom_document_new();
    DOMDocument* doc2 = dom_document_new();
    
    DOMText* text = dom_document_createtextnode(doc1, "Hello World");
    
    // Import text node
    DOMNode* imported = dom_document_importnode(doc2, (DOMNode*)text, 0);
    
    ASSERT(imported != NULL, "importNode returns a node");
    ASSERT(dom_node_get_nodetype(imported) == DOM_TEXT_NODE, "Imported node is text");
    ASSERT(dom_node_get_ownerdocument(imported) == (DOMNode*)(DOMNode*)doc2, "Imported text owned by doc2");
    
    dom_document_release(doc1);
    dom_document_release(doc2);
}

void test_adoptnode_basic() {
    TEST_START("Test 4: adoptNode() - Basic adoption");
    
    DOMDocument* doc1 = dom_document_new();
    DOMDocument* doc2 = dom_document_new();
    
    DOMElement* elem = dom_document_createelement(doc1, "element");
    
    ASSERT(dom_node_get_ownerdocument((DOMNode*)elem) == (DOMNode*)doc1, "Element initially owned by doc1");
    
    // Adopt element into doc2
    DOMNode* adopted = dom_document_adoptnode(doc2, (DOMNode*)elem);
    
    ASSERT(adopted == (DOMNode*)elem, "adoptNode returns same pointer");
    ASSERT(dom_node_get_ownerdocument(adopted) == (DOMNode*)(DOMNode*)doc2, "Element now owned by doc2");
    
    dom_document_release(doc1);
    dom_document_release(doc2);
}

void test_adoptnode_with_children() {
    TEST_START("Test 5: adoptNode() - With children");
    
    DOMDocument* doc1 = dom_document_new();
    DOMDocument* doc2 = dom_document_new();
    
    // Create element tree
    DOMElement* parent = dom_document_createelement(doc1, "parent");
    DOMElement* child1 = dom_document_createelement(doc1, "child1");
    DOMElement* child2 = dom_document_createelement(doc1, "child2");
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    
    // Adopt parent (children should move too)
    DOMNode* adopted = dom_document_adoptnode(doc2, (DOMNode*)parent);
    
    ASSERT(adopted == (DOMNode*)parent, "adoptNode returns same pointer");
    ASSERT(dom_node_get_ownerdocument(adopted) == (DOMNode*)(DOMNode*)doc2, "Parent now owned by doc2");
    
    // Check children were adopted too
    DOMNode* adopted_child1 = dom_node_get_firstchild(adopted);
    DOMNode* adopted_child2 = dom_node_get_nextsibling(adopted_child1);
    
    ASSERT(adopted_child1 == (DOMNode*)child1, "Child1 is same pointer");
    ASSERT(adopted_child2 == (DOMNode*)child2, "Child2 is same pointer");
    ASSERT(dom_node_get_ownerdocument(adopted_child1) == (DOMNode*)(DOMNode*)doc2, "Child1 now owned by doc2");
    ASSERT(dom_node_get_ownerdocument(adopted_child2) == (DOMNode*)(DOMNode*)doc2, "Child2 now owned by doc2");
    
    dom_document_release(doc1);
    dom_document_release(doc2);
}

void test_adoptnode_removes_from_parent() {
    TEST_START("Test 6: adoptNode() - Removes from parent");
    
    DOMDocument* doc1 = dom_document_new();
    DOMDocument* doc2 = dom_document_new();
    
    DOMElement* parent = dom_document_createelement(doc1, "parent");
    DOMElement* child = dom_document_createelement(doc1, "child");
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child);
    
    ASSERT(dom_node_get_parentnode((DOMNode*)child) == (DOMNode*)parent, "Child has parent initially");
    
    // Adopt child (should remove from parent)
    DOMNode* adopted = dom_document_adoptnode(doc2, (DOMNode*)child);
    
    ASSERT(adopted == (DOMNode*)child, "adoptNode returns same pointer");
    ASSERT(dom_node_get_parentnode(adopted) == NULL, "Adopted node has no parent");
    ASSERT(dom_node_get_firstchild((DOMNode*)parent) == NULL, "Parent has no children");
    
    dom_document_release(doc1);
    dom_document_release(doc2);
}

void test_import_vs_adopt() {
    TEST_START("Test 7: importNode() vs adoptNode() - Different behavior");
    
    DOMDocument* doc1 = dom_document_new();
    DOMDocument* doc2 = dom_document_new();
    
    DOMElement* elem1 = dom_document_createelement(doc1, "elem1");
    DOMElement* elem2 = dom_document_createelement(doc1, "elem2");
    
    // Import creates a copy
    DOMNode* imported = dom_document_importnode(doc2, (DOMNode*)elem1, 0);
    ASSERT(imported != (DOMNode*)elem1, "Import creates new node");
    ASSERT(dom_node_get_ownerdocument((DOMNode*)elem1) == (DOMNode*)doc1, "Original still in doc1");
    ASSERT(dom_node_get_ownerdocument(imported) == (DOMNode*)(DOMNode*)doc2, "Copy is in doc2");
    
    // Adopt transfers ownership
    DOMNode* adopted = dom_document_adoptnode(doc2, (DOMNode*)elem2);
    ASSERT(adopted == (DOMNode*)elem2, "Adopt returns same node");
    ASSERT(dom_node_get_ownerdocument(adopted) == (DOMNode*)(DOMNode*)doc2, "Node moved to doc2");
    
    dom_document_release(doc1);
    dom_document_release(doc2);
}

void test_importnode_same_document() {
    TEST_START("Test 8: importNode() - Same document");
    
    DOMDocument* doc = dom_document_new();
    
    DOMElement* elem = dom_document_createelement(doc, "element");
    
    // Import from same document (should still create a copy)
    DOMNode* imported = dom_document_importnode(doc, (DOMNode*)elem, 0);
    
    ASSERT(imported != NULL, "importNode succeeds");
    ASSERT(imported != (DOMNode*)elem, "Import creates copy even for same document");
    ASSERT(dom_node_get_ownerdocument(imported) == (DOMNode*)(DOMNode*)doc, "Copy owned by same document");
    
    dom_document_release(doc);
}

void test_adoptnode_same_document() {
    TEST_START("Test 9: adoptNode() - Same document (no-op)");
    
    DOMDocument* doc = dom_document_new();
    
    DOMElement* elem = dom_document_createelement(doc, "element");
    
    // Adopt from same document (should be no-op)
    DOMNode* adopted = dom_document_adoptnode(doc, (DOMNode*)elem);
    
    ASSERT(adopted == (DOMNode*)elem, "adoptNode returns same pointer");
    ASSERT(dom_node_get_ownerdocument(adopted) == (DOMNode*)(DOMNode*)doc, "Still owned by same document");
    
    dom_document_release(doc);
}

void test_import_with_attributes() {
    TEST_START("Test 10: importNode() - With attributes");
    
    DOMDocument* doc1 = dom_document_new();
    DOMDocument* doc2 = dom_document_new();
    
    DOMElement* elem = dom_document_createelement(doc1, "element");
    dom_element_setattribute(elem, "id", "test");
    dom_element_setattribute(elem, "class", "foo bar");
    
    // Import with attributes
    DOMNode* imported = dom_document_importnode(doc2, (DOMNode*)elem, 0);
    DOMElement* imported_elem = (DOMElement*)imported;
    
    ASSERT(imported != NULL, "importNode succeeds");
    
    const char* id = dom_element_getattribute(imported_elem, "id");
    const char* class_attr = dom_element_getattribute(imported_elem, "class");
    
    ASSERT(strcmp(id, "test") == 0, "Attribute 'id' copied");
    ASSERT(strcmp(class_attr, "foo bar") == 0, "Attribute 'class' copied");
    
    dom_document_release(doc1);
    dom_document_release(doc2);
}

int main() {
    printf("========================================\n");
    printf("DOM Document Adoption/Import Test Suite\n");
    printf("========================================\n");
    
    test_importnode_shallow();
    test_importnode_deep();
    test_importnode_text();
    test_adoptnode_basic();
    test_adoptnode_with_children();
    test_adoptnode_removes_from_parent();
    test_import_vs_adopt();
    test_importnode_same_document();
    test_adoptnode_same_document();
    test_import_with_attributes();
    
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
