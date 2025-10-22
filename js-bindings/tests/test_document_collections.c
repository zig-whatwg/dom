/**
 * Test Suite: Document Collections and Metadata
 * 
 * Tests:
 * - getElementsByTagName() - Get elements by tag name
 * - getElementsByTagNameNS() - Get elements by namespace and tag name
 * - getElementsByClassName() - Get elements by class name(s)
 * - Document metadata properties (compatMode, characterSet, contentType, etc.)
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

void test_getelementsbytagname_basic() {
    TEST_START("Test 1: getElementsByTagName() - Basic usage");
    
    DOMDocument* doc = dom_document_new();
    
    // Create root element (Document can only have 1 element child)
    DOMElement* root = dom_document_createelement(doc, "root");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    // Create elements with different tag names
    DOMElement* elem1 = dom_document_createelement(doc, "item");
    DOMElement* elem2 = dom_document_createelement(doc, "item");
    DOMElement* elem3 = dom_document_createelement(doc, "other");
    
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem1);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem2);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem3);
    
    // Get all "item" elements
    DOMHTMLCollection* items = dom_document_getelementsbytagname(doc, "item");
    
    ASSERT(items != NULL, "getElementsByTagName returns collection");
    ASSERT(dom_htmlcollection_get_length(items) == 2, "Collection has 2 items");
    
    DOMElement* first = dom_htmlcollection_item(items, 0);
    DOMElement* second = dom_htmlcollection_item(items, 1);
    
    ASSERT(first == elem1, "First item is elem1");
    ASSERT(second == elem2, "Second item is elem2");
    
    dom_htmlcollection_release(items);
    dom_document_release(doc);
}

void test_getelementsbytagname_wildcard() {
    TEST_START("Test 2: getElementsByTagName() - Case sensitive");
    
    DOMDocument* doc = dom_document_new();
    
    // Create root element
    DOMElement* root = dom_document_createelement(doc, "root");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    DOMElement* elem1 = dom_document_createelement(doc, "container");
    DOMElement* elem2 = dom_document_createelement(doc, "CONTAINER");
    DOMElement* elem3 = dom_document_createelement(doc, "item");
    
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem1);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem2);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem3);
    
    // Tag names are case-sensitive (generic DOM, not HTML)
    DOMHTMLCollection* lower = dom_document_getelementsbytagname(doc, "container");
    
    ASSERT(lower != NULL, "getElementsByTagName returns collection");
    ASSERT(dom_htmlcollection_get_length(lower) == 1, "Only lowercase 'container' matches");
    
    dom_htmlcollection_release(lower);
    dom_document_release(doc);
}

void test_getelementsbytagname_empty() {
    TEST_START("Test 3: getElementsByTagName() - No matches");
    
    DOMDocument* doc = dom_document_new();
    
    // Create root element
    DOMElement* root = dom_document_createelement(doc, "root");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    DOMElement* elem = dom_document_createelement(doc, "item");
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem);
    
    // Search for non-existent tag
    DOMHTMLCollection* none = dom_document_getelementsbytagname(doc, "nonexistent");
    
    ASSERT(none != NULL, "getElementsByTagName returns collection even with no matches");
    ASSERT(dom_htmlcollection_get_length(none) == 0, "Collection is empty");
    
    dom_htmlcollection_release(none);
    dom_document_release(doc);
}

void test_getelementsbytagname_nested() {
    TEST_START("Test 4: getElementsByTagName() - Nested elements");
    
    DOMDocument* doc = dom_document_new();
    
    DOMElement* parent = dom_document_createelement(doc, "parent");
    DOMElement* child1 = dom_document_createelement(doc, "item");
    DOMElement* child2 = dom_document_createelement(doc, "item");
    
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)parent);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child1);
    dom_node_appendchild((DOMNode*)parent, (DOMNode*)child2);
    
    // Get all "item" elements (should find nested ones)
    DOMHTMLCollection* items = dom_document_getelementsbytagname(doc, "item");
    
    ASSERT(dom_htmlcollection_get_length(items) == 2, "Collection finds nested items");
    
    dom_htmlcollection_release(items);
    dom_document_release(doc);
}

void test_getelementsbyclassname_basic() {
    TEST_START("Test 5: getElementsByClassName() - Basic usage");
    
    DOMDocument* doc = dom_document_new();
    
    // Create root element
    DOMElement* root = dom_document_createelement(doc, "root");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    DOMElement* elem1 = dom_document_createelement(doc, "elem1");
    DOMElement* elem2 = dom_document_createelement(doc, "elem2");
    DOMElement* elem3 = dom_document_createelement(doc, "elem3");
    
    dom_element_setattribute(elem1, "class", "foo");
    dom_element_setattribute(elem2, "class", "foo");
    dom_element_setattribute(elem3, "class", "bar");
    
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem1);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem2);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem3);
    
    // Get elements with class "foo"
    DOMHTMLCollection* foos = dom_document_getelementsbyclassname(doc, "foo");
    
    ASSERT(foos != NULL, "getElementsByClassName returns collection");
    ASSERT(dom_htmlcollection_get_length(foos) == 2, "Collection has 2 elements with class 'foo'");
    
    dom_htmlcollection_release(foos);
    dom_document_release(doc);
}

void test_getelementsbyclassname_multiple() {
    TEST_START("Test 6: getElementsByClassName() - Elements with multiple classes");
    
    DOMDocument* doc = dom_document_new();
    
    // Create root element
    DOMElement* root = dom_document_createelement(doc, "root");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    DOMElement* elem1 = dom_document_createelement(doc, "elem1");
    DOMElement* elem2 = dom_document_createelement(doc, "elem2");
    DOMElement* elem3 = dom_document_createelement(doc, "elem3");
    
    dom_element_setattribute(elem1, "class", "foo bar baz");
    dom_element_setattribute(elem2, "class", "foo");
    dom_element_setattribute(elem3, "class", "other");
    
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem1);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem2);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem3);
    
    // Get elements by single class (elem1 and elem2 have "foo")
    DOMHTMLCollection* foos = dom_document_getelementsbyclassname(doc, "foo");
    
    ASSERT(foos != NULL, "getElementsByClassName returns collection");
    ASSERT(dom_htmlcollection_get_length(foos) == 2, "Two elements have class 'foo'");
    ASSERT(dom_htmlcollection_item(foos, 0) == elem1, "First item is elem1");
    
    dom_htmlcollection_release(foos);
    dom_document_release(doc);
}

void test_getelementsbyclassname_empty() {
    TEST_START("Test 7: getElementsByClassName() - No matches");
    
    DOMDocument* doc = dom_document_new();
    
    // Create root element
    DOMElement* root = dom_document_createelement(doc, "root");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    DOMElement* elem = dom_document_createelement(doc, "elem");
    dom_element_setattribute(elem, "class", "foo");
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem);
    
    // Search for non-existent class
    DOMHTMLCollection* none = dom_document_getelementsbyclassname(doc, "nonexistent");
    
    ASSERT(none != NULL, "getElementsByClassName returns collection");
    ASSERT(dom_htmlcollection_get_length(none) == 0, "Collection is empty");
    
    dom_htmlcollection_release(none);
    dom_document_release(doc);
}

void test_getelementsbytagnamens_basic() {
    TEST_START("Test 8: getElementsByTagNameNS() - With namespace");
    
    DOMDocument* doc = dom_document_new();
    
    const char* svg_ns = "http://www.w3.org/2000/svg";
    
    // Create root element
    DOMElement* root = dom_document_createelementns(doc, svg_ns, "svg");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    DOMElement* elem1 = dom_document_createelementns(doc, svg_ns, "circle");
    DOMElement* elem2 = dom_document_createelementns(doc, svg_ns, "circle");
    DOMElement* elem3 = dom_document_createelementns(doc, svg_ns, "rect");
    
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem1);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem2);
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem3);
    
    // Get all SVG circles
    DOMHTMLCollection* circles = dom_document_getelementsbytagnamens(doc, svg_ns, "circle");
    
    ASSERT(circles != NULL, "getElementsByTagNameNS returns collection");
    ASSERT(dom_htmlcollection_get_length(circles) == 2, "Collection has 2 circles");
    
    dom_htmlcollection_release(circles);
    dom_document_release(doc);
}

void test_document_metadata_properties() {
    TEST_START("Test 9: Document metadata properties");
    
    DOMDocument* doc = dom_document_new();
    
    // Test compatMode
    const char* compat_mode = dom_document_get_compatmode(doc);
    ASSERT(strcmp(compat_mode, "CSS1Compat") == 0, "compatMode is 'CSS1Compat'");
    
    // Test characterSet
    const char* charset = dom_document_get_characterset(doc);
    ASSERT(strcmp(charset, "UTF-8") == 0, "characterSet is 'UTF-8'");
    
    // Test charset (legacy alias)
    const char* charset_legacy = dom_document_get_charset(doc);
    ASSERT(strcmp(charset_legacy, "UTF-8") == 0, "charset is 'UTF-8'");
    
    // Test inputEncoding (legacy alias)
    const char* input_encoding = dom_document_get_inputencoding(doc);
    ASSERT(strcmp(input_encoding, "UTF-8") == 0, "inputEncoding is 'UTF-8'");
    
    // Test contentType
    const char* content_type = dom_document_get_contenttype(doc);
    ASSERT(strcmp(content_type, "application/xml") == 0, "contentType is 'application/xml'");
    
    dom_document_release(doc);
}

void test_htmlcollection_live_updates() {
    TEST_START("Test 10: HTMLCollection - Live updates");
    
    DOMDocument* doc = dom_document_new();
    
    // Create root element
    DOMElement* root = dom_document_createelement(doc, "root");
    dom_node_appendchild((DOMNode*)doc, (DOMNode*)root);
    
    DOMElement* elem1 = dom_document_createelement(doc, "item");
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem1);
    
    // Get collection
    DOMHTMLCollection* items = dom_document_getelementsbytagname(doc, "item");
    ASSERT(dom_htmlcollection_get_length(items) == 1, "Initially 1 item");
    
    // Add another element
    DOMElement* elem2 = dom_document_createelement(doc, "item");
    dom_node_appendchild((DOMNode*)root, (DOMNode*)elem2);
    
    // Collection should update
    ASSERT(dom_htmlcollection_get_length(items) == 2, "Collection live updates to 2 items");
    
    // Remove an element
    dom_node_removechild((DOMNode*)root, (DOMNode*)elem1);
    
    ASSERT(dom_htmlcollection_get_length(items) == 1, "Collection live updates to 1 item after removal");
    
    dom_htmlcollection_release(items);
    dom_document_release(doc);
}

int main() {
    printf("========================================\n");
    printf("DOM Document Collections & Metadata\n");
    printf("========================================\n");
    
    test_getelementsbytagname_basic();
    test_getelementsbytagname_wildcard();
    test_getelementsbytagname_empty();
    test_getelementsbytagname_nested();
    test_getelementsbyclassname_basic();
    test_getelementsbyclassname_multiple();
    test_getelementsbyclassname_empty();
    test_getelementsbytagnamens_basic();
    test_document_metadata_properties();
    test_htmlcollection_live_updates();
    
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
