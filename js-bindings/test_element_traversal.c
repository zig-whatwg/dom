/**
 * Test: Element Traversal (ParentNode and ChildNode mixins)
 * 
 * Tests element traversal methods:
 * - ParentNode: children, firstElementChild, lastElementChild, childElementCount
 * - ChildNode: nextElementSibling, previousElementSibling
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct DOMDocument DOMDocument;
typedef struct DOMElement DOMElement;
typedef struct DOMNode DOMNode;
typedef struct DOMText DOMText;
typedef struct DOMHTMLCollection DOMHTMLCollection;

// Document
extern DOMDocument* dom_document_new(void);
extern void dom_document_release(DOMDocument* doc);
extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* name);
extern DOMText* dom_document_createtextnode(DOMDocument* doc, const char* data);

// Node
extern DOMNode* dom_node_appendchild(DOMNode* parent, DOMNode* child);

// Element
extern void dom_element_release(DOMElement* elem);
extern const char* dom_element_get_tagname(DOMElement* elem);

// ParentNode mixin
extern DOMHTMLCollection* dom_element_get_children(DOMElement* elem);
extern DOMElement* dom_element_get_firstelementchild(DOMElement* elem);
extern DOMElement* dom_element_get_lastelementchild(DOMElement* elem);
extern unsigned long dom_element_get_childelementcount(DOMElement* elem);

// ChildNode mixin
extern DOMElement* dom_element_get_nextelementsibling(DOMElement* elem);
extern DOMElement* dom_element_get_previouselementsibling(DOMElement* elem);

// HTMLCollection
extern unsigned long dom_htmlcollection_get_length(DOMHTMLCollection* collection);

// Text
extern void dom_text_release(DOMText* text);

// Test helpers
static int test_count = 0;
static int test_passed = 0;

#define TEST(name) \
    do { \
        test_count++; \
        printf("\n[TEST %d] %s\n", test_count, name); \
    } while(0)

#define ASSERT(expr, msg) \
    do { \
        if (!(expr)) { \
            printf("  ❌ FAILED: %s\n", msg); \
            printf("     Expression: %s\n", #expr); \
            return 1; \
        } \
        printf("  ✅ %s\n", msg); \
    } while(0)

#define TEST_PASS() \
    do { \
        test_passed++; \
        printf("  ✅ PASSED\n"); \
    } while(0)

int main(void) {
    printf("====================================\n");
    printf("Element Traversal Test\n");
    printf("====================================\n");

    // ========================================================================
    // Test 1: childElementCount with no children
    // ========================================================================
    TEST("childElementCount with no children");
    {
        DOMDocument* doc = dom_document_new();
        DOMElement* parent = dom_document_createelement(doc, "parent");

        unsigned long count = dom_element_get_childelementcount(parent);
        ASSERT(count == 0, "Empty element has 0 child elements");

        dom_element_release(parent);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 2: childElementCount with mixed children
    // ========================================================================
    TEST("childElementCount with mixed children (elements + text)");
    {
        DOMDocument* doc = dom_document_new();
        DOMElement* parent = dom_document_createelement(doc, "parent");

        // Add element child
        DOMElement* child1 = dom_document_createelement(doc, "child1");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);

        // Add text node (should NOT be counted)
        DOMText* text = dom_document_createtextnode(doc, "text");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)text);

        // Add another element child
        DOMElement* child2 = dom_document_createelement(doc, "child2");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);

        unsigned long count = dom_element_get_childelementcount(parent);
        ASSERT(count == 2, "Parent has 2 element children (text excluded)");

        dom_element_release(parent);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 3: firstElementChild and lastElementChild
    // ========================================================================
    TEST("firstElementChild and lastElementChild");
    {
        DOMDocument* doc = dom_document_new();
        DOMElement* parent = dom_document_createelement(doc, "parent");

        // Add text node first (should be skipped)
        DOMText* text1 = dom_document_createtextnode(doc, "start");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)text1);

        // Add first element child
        DOMElement* child1 = dom_document_createelement(doc, "first");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);

        // Add middle text
        DOMText* text2 = dom_document_createtextnode(doc, "middle");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)text2);

        // Add last element child
        DOMElement* child2 = dom_document_createelement(doc, "last");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);

        // Add text node at end (should be skipped)
        DOMText* text3 = dom_document_createtextnode(doc, "end");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)text3);

        // Test firstElementChild
        DOMElement* first = dom_element_get_firstelementchild(parent);
        ASSERT(first != NULL, "firstElementChild found");
        ASSERT(first == child1, "firstElementChild is 'first' element");
        const char* first_tag = dom_element_get_tagname(first);
        ASSERT(strcmp(first_tag, "first") == 0, "First element tag is 'first'");

        // Test lastElementChild
        DOMElement* last = dom_element_get_lastelementchild(parent);
        ASSERT(last != NULL, "lastElementChild found");
        ASSERT(last == child2, "lastElementChild is 'last' element");
        const char* last_tag = dom_element_get_tagname(last);
        ASSERT(strcmp(last_tag, "last") == 0, "Last element tag is 'last'");

        dom_element_release(parent);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 4: firstElementChild/lastElementChild with no elements
    // ========================================================================
    TEST("firstElementChild/lastElementChild with only text nodes");
    {
        DOMDocument* doc = dom_document_new();
        DOMElement* parent = dom_document_createelement(doc, "parent");

        // Add only text nodes
        DOMText* text1 = dom_document_createtextnode(doc, "text1");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)text1);

        DOMText* text2 = dom_document_createtextnode(doc, "text2");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)text2);

        DOMElement* first = dom_element_get_firstelementchild(parent);
        ASSERT(first == NULL, "firstElementChild is NULL (no elements)");

        DOMElement* last = dom_element_get_lastelementchild(parent);
        ASSERT(last == NULL, "lastElementChild is NULL (no elements)");

        dom_element_release(parent);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 5: nextElementSibling
    // ========================================================================
    TEST("nextElementSibling skips text nodes");
    {
        DOMDocument* doc = dom_document_new();
        DOMElement* parent = dom_document_createelement(doc, "parent");

        // Add first element
        DOMElement* elem1 = dom_document_createelement(doc, "elem1");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)elem1);

        // Add text node (should be skipped)
        DOMText* text = dom_document_createtextnode(doc, "text");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)text);

        // Add second element
        DOMElement* elem2 = dom_document_createelement(doc, "elem2");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)elem2);

        // Test nextElementSibling skips text
        DOMElement* next = dom_element_get_nextelementsibling(elem1);
        ASSERT(next != NULL, "nextElementSibling found");
        ASSERT(next == elem2, "nextElementSibling skips text node");
        const char* next_tag = dom_element_get_tagname(next);
        ASSERT(strcmp(next_tag, "elem2") == 0, "Next element tag is 'elem2'");

        // Test last element has no nextElementSibling
        DOMElement* after_last = dom_element_get_nextelementsibling(elem2);
        ASSERT(after_last == NULL, "Last element has no nextElementSibling");

        dom_element_release(parent);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 6: previousElementSibling
    // ========================================================================
    TEST("previousElementSibling skips text nodes");
    {
        DOMDocument* doc = dom_document_new();
        DOMElement* parent = dom_document_createelement(doc, "parent");

        // Add first element
        DOMElement* elem1 = dom_document_createelement(doc, "elem1");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)elem1);

        // Add text node (should be skipped)
        DOMText* text = dom_document_createtextnode(doc, "text");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)text);

        // Add second element
        DOMElement* elem2 = dom_document_createelement(doc, "elem2");
        dom_node_appendchild((DOMNode*)parent, (DOMNode*)elem2);

        // Test previousElementSibling skips text
        DOMElement* prev = dom_element_get_previouselementsibling(elem2);
        ASSERT(prev != NULL, "previousElementSibling found");
        ASSERT(prev == elem1, "previousElementSibling skips text node");
        const char* prev_tag = dom_element_get_tagname(prev);
        ASSERT(strcmp(prev_tag, "elem1") == 0, "Previous element tag is 'elem1'");

        // Test first element has no previousElementSibling
        DOMElement* before_first = dom_element_get_previouselementsibling(elem1);
        ASSERT(before_first == NULL, "First element has no previousElementSibling");

        dom_element_release(parent);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 7: Iterate through element siblings
    // ========================================================================
    TEST("Iterate through all element siblings");
    {
        DOMDocument* doc = dom_document_new();
        DOMElement* parent = dom_document_createelement(doc, "parent");

        // Add 5 elements with text nodes in between
        for (int i = 0; i < 5; i++) {
            char tag[20];
            snprintf(tag, sizeof(tag), "elem%d", i);
            DOMElement* elem = dom_document_createelement(doc, tag);
            dom_node_appendchild((DOMNode*)parent, (DOMNode*)elem);

            if (i < 4) {
                DOMText* text = dom_document_createtextnode(doc, "text");
                dom_node_appendchild((DOMNode*)parent, (DOMNode*)text);
            }
        }

        // Iterate forward through element siblings
        DOMElement* first = dom_element_get_firstelementchild(parent);
        ASSERT(first != NULL, "First element found");

        int forward_count = 0;
        DOMElement* current = first;
        while (current != NULL) {
            forward_count++;
            current = dom_element_get_nextelementsibling(current);
        }
        ASSERT(forward_count == 5, "Iterated through 5 elements forward");

        // Iterate backward through element siblings
        DOMElement* last = dom_element_get_lastelementchild(parent);
        ASSERT(last != NULL, "Last element found");

        int backward_count = 0;
        current = last;
        while (current != NULL) {
            backward_count++;
            current = dom_element_get_previouselementsibling(current);
        }
        ASSERT(backward_count == 5, "Iterated through 5 elements backward");

        dom_element_release(parent);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Summary
    // ========================================================================
    printf("\n====================================\n");
    printf("Summary: %d/%d tests passed\n", test_passed, test_count);
    printf("====================================\n");

    if (test_passed == test_count) {
        printf("\n🎉 All tests passed!\n\n");
        return 0;
    } else {
        printf("\n❌ Some tests failed\n\n");
        return 1;
    }
}
