/**
 * Test Suite: Element insertAdjacent Methods
 * 
 * Tests the Element manipulation methods:
 * - insertAdjacentElement() - Insert element at position
 * - insertAdjacentText() - Insert text at position
 * 
 * Spec: https://dom.spec.whatwg.org/#interface-element (§4.10 legacy)
 */

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "dom.h"

// Forward declarations for CharacterData (Text nodes)
typedef struct DOMCharacterData DOMCharacterData;
extern const char* dom_characterdata_get_data(DOMCharacterData* cdata);

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

// Helper to count children
int count_children(DOMNode* parent) {
    int count = 0;
    DOMNode* child = dom_node_get_firstchild(parent);
    while (child != NULL) {
        count++;
        child = dom_node_get_nextsibling(child);
    }
    return count;
}

// Helper to get nth child
DOMNode* get_nth_child(DOMNode* parent, int n) {
    DOMNode* child = dom_node_get_firstchild(parent);
    for (int i = 0; i < n && child != NULL; i++) {
        child = dom_node_get_nextsibling(child);
    }
    return child;
}

void test_insertadjacentelement_beforebegin() {
    TEST_START("Test 1: insertAdjacentElement('beforebegin')");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* target = dom_document_createelement(doc, "target");
    DOMElement* new_elem = dom_document_createelement(doc, "new");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)target);
    
    // Insert before target
    DOMElement* result = dom_element_insertadjacentelement(target, "beforebegin", new_elem);
    
    ASSERT(result == new_elem, "Returns inserted element");
    ASSERT(count_children((DOMNode*)parent) == 2, "Parent has 2 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)new_elem, "First child is new_elem");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)target, "Second child is target");
    
    dom_document_release(doc);
}

void test_insertadjacentelement_afterbegin() {
    TEST_START("Test 2: insertAdjacentElement('afterbegin')");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* target = dom_document_createelement(doc, "target");
    DOMElement* existing = dom_document_createelement(doc, "existing");
    DOMElement* new_elem = dom_document_createelement(doc, "new");
    
    dom_node_appendchild((DOMNode*)target, (DOMNode*)existing);
    
    // Insert as first child
    DOMElement* result = dom_element_insertadjacentelement(target, "afterbegin", new_elem);
    
    ASSERT(result == new_elem, "Returns inserted element");
    ASSERT(count_children((DOMNode*)target) == 2, "Target has 2 children");
    ASSERT(get_nth_child((DOMNode*)target, 0) == (DOMNode*)new_elem, "First child is new_elem");
    ASSERT(get_nth_child((DOMNode*)target, 1) == (DOMNode*)existing, "Second child is existing");
    
    dom_document_release(doc);
}

void test_insertadjacentelement_beforeend() {
    TEST_START("Test 3: insertAdjacentElement('beforeend')");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* target = dom_document_createelement(doc, "target");
    DOMElement* existing = dom_document_createelement(doc, "existing");
    DOMElement* new_elem = dom_document_createelement(doc, "new");
    
    dom_node_appendchild((DOMNode*)target, (DOMNode*)existing);
    
    // Insert as last child
    DOMElement* result = dom_element_insertadjacentelement(target, "beforeend", new_elem);
    
    ASSERT(result == new_elem, "Returns inserted element");
    ASSERT(count_children((DOMNode*)target) == 2, "Target has 2 children");
    ASSERT(get_nth_child((DOMNode*)target, 0) == (DOMNode*)existing, "First child is existing");
    ASSERT(get_nth_child((DOMNode*)target, 1) == (DOMNode*)new_elem, "Second child is new_elem");
    
    dom_document_release(doc);
}

void test_insertadjacentelement_afterend() {
    TEST_START("Test 4: insertAdjacentElement('afterend')");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* target = dom_document_createelement(doc, "target");
    DOMElement* new_elem = dom_document_createelement(doc, "new");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)target);
    
    // Insert after target
    DOMElement* result = dom_element_insertadjacentelement(target, "afterend", new_elem);
    
    ASSERT(result == new_elem, "Returns inserted element");
    ASSERT(count_children((DOMNode*)parent) == 2, "Parent has 2 children");
    ASSERT(get_nth_child((DOMNode*)parent, 0) == (DOMNode*)target, "First child is target");
    ASSERT(get_nth_child((DOMNode*)parent, 1) == (DOMNode*)new_elem, "Second child is new_elem");
    
    dom_document_release(doc);
}

void test_insertadjacentelement_no_parent() {
    TEST_START("Test 5: insertAdjacentElement with no parent");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* orphan = dom_document_createelement(doc, "orphan");
    DOMElement* new_elem = dom_document_createelement(doc, "new");
    
    // Try beforebegin without parent
    DOMElement* result1 = dom_element_insertadjacentelement(orphan, "beforebegin", new_elem);
    ASSERT(result1 == NULL, "beforebegin without parent returns NULL");
    
    // Try afterend without parent
    DOMElement* new_elem2 = dom_document_createelement(doc, "new2");
    DOMElement* result2 = dom_element_insertadjacentelement(orphan, "afterend", new_elem2);
    ASSERT(result2 == NULL, "afterend without parent returns NULL");
    
    dom_document_release(doc);
}

void test_insertadjacentelement_invalid_position() {
    TEST_START("Test 6: insertAdjacentElement with invalid position");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* target = dom_document_createelement(doc, "target");
    DOMElement* new_elem = dom_document_createelement(doc, "new");
    
    // Invalid position should return NULL
    DOMElement* result = dom_element_insertadjacentelement(target, "invalid", new_elem);
    
    ASSERT(result == NULL, "Invalid position returns NULL");
    
    dom_document_release(doc);
}

void test_insertadjacenttext_beforebegin() {
    TEST_START("Test 7: insertAdjacentText('beforebegin')");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* target = dom_document_createelement(doc, "target");
    
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)target);
    
    // Insert text before target
    int32_t result = dom_element_insertadjacenttext(target, "beforebegin", "Hello");
    
    ASSERT(result == DOM_ERROR_SUCCESS, "insertAdjacentText succeeds");
    ASSERT(count_children((DOMNode*)parent) == 2, "Parent has 2 children");
    
    // Check first child is text node
    DOMNode* text_node = get_nth_child((DOMNode*)parent, 0);
    ASSERT(dom_node_get_nodetype(text_node) == DOM_TEXT_NODE, "First child is text node");
    
    const char* text_content = dom_characterdata_get_data((DOMCharacterData*)text_node);
    ASSERT(strcmp(text_content, "Hello") == 0, "Text content is 'Hello'");
    
    dom_document_release(doc);
}


int main() {
    printf("========================================\n");
    printf("DOM insertAdjacent Methods (Subset)\n");
    printf("========================================\n");
    
    test_insertadjacentelement_beforebegin();
    test_insertadjacentelement_afterbegin();
    test_insertadjacentelement_beforeend();
    test_insertadjacentelement_afterend();
    test_insertadjacentelement_no_parent();
    test_insertadjacentelement_invalid_position();
    test_insertadjacenttext_beforebegin();
    
    printf("\n========================================\n");
    printf("Passed: %d, Failed: %d\n", tests_passed, tests_failed);
    printf("========================================\n");
    
    return tests_failed == 0 ? 0 : 1;
}
