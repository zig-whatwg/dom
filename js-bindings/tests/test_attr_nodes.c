/**
 * Test Element Attr Node Methods
 * 
 * Tests the 5 Element Attr node manipulation functions:
 * - dom_element_getattributenode()
 * - dom_element_getattributenodens()
 * - dom_element_setattributenode()
 * - dom_element_setattributenodens()
 * - dom_element_removeattributenode()
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// Forward declarations
typedef struct DOMDocument DOMDocument;
typedef struct DOMElement DOMElement;
typedef struct DOMAttr DOMAttr;

// Document
extern DOMDocument* dom_document_new(void);
extern void dom_document_release(DOMDocument* doc);
extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* name);
extern DOMAttr* dom_document_createattribute(DOMDocument* doc, const char* name);
extern DOMAttr* dom_document_createattributens(DOMDocument* doc, const char* namespace, const char* qualified_name);

// Element - String attributes
extern int dom_element_setattribute(DOMElement* elem, const char* name, const char* value);
extern int dom_element_setattributens(DOMElement* elem, const char* namespace, const char* qualified_name, const char* value);
extern const char* dom_element_getattribute(DOMElement* elem, const char* name);
extern void dom_element_release(DOMElement* elem);

// Element - Attr node methods
extern DOMAttr* dom_element_getattributenode(DOMElement* elem, const char* name);
extern DOMAttr* dom_element_getattributenodens(DOMElement* elem, const char* namespace, const char* local_name);
extern DOMAttr* dom_element_setattributenode(DOMElement* elem, DOMAttr* attr);
extern DOMAttr* dom_element_setattributenodens(DOMElement* elem, DOMAttr* attr);
extern DOMAttr* dom_element_removeattributenode(DOMElement* elem, DOMAttr* attr);

// Attr
extern const char* dom_attr_get_name(DOMAttr* attr);
extern const char* dom_attr_get_value(DOMAttr* attr);
extern int dom_attr_set_value(DOMAttr* attr, const char* value);
extern const char* dom_attr_get_localname(DOMAttr* attr);
extern const char* dom_attr_get_namespaceuri(DOMAttr* attr);
extern DOMElement* dom_attr_get_ownerelement(DOMAttr* attr);
extern void dom_attr_release(DOMAttr* attr);

int main(void) {
    printf("Testing Element Attr Node Methods\n");
    printf("==================================\n\n");

    // Create document and element
    DOMDocument* doc = dom_document_new();
    assert(doc != NULL);
    DOMElement* elem = dom_document_createelement(doc, "item");
    assert(elem != NULL);
    printf("✓ Created document and element\n\n");

    // Test 1: getAttributeNode() - non-existent attribute
    printf("Test 1: getAttributeNode() - non-existent\n");
    DOMAttr* attr = dom_element_getattributenode(elem, "id");
    assert(attr == NULL);
    printf("  ✓ Returns NULL for non-existent attribute\n");

    // Test 2: setAttributeNode() - add new attribute
    printf("\nTest 2: setAttributeNode() - add new\n");
    DOMAttr* classAttr = dom_document_createattribute(doc, "class");
    assert(classAttr != NULL);
    dom_attr_set_value(classAttr, "highlight");
    printf("  ✓ Created Attr node (class='highlight')\n");

    DOMAttr* oldAttr = dom_element_setattributenode(elem, classAttr);
    assert(oldAttr == NULL); // No previous attribute
    printf("  ✓ Set attribute (no previous attribute)\n");

    // Verify it's set
    const char* className = dom_element_getattribute(elem, "class");
    assert(className != NULL);
    assert(strcmp(className, "highlight") == 0);
    printf("  ✓ Verified: class='highlight'\n");

    // Test 3: getAttributeNode() - existing attribute
    printf("\nTest 3: getAttributeNode() - existing\n");
    attr = dom_element_getattributenode(elem, "class");
    assert(attr != NULL);
    printf("  ✓ Got Attr node\n");

    const char* attrName = dom_attr_get_name(attr);
    assert(strcmp(attrName, "class") == 0);
    printf("  ✓ name = 'class'\n");

    const char* attrValue = dom_attr_get_value(attr);
    assert(strcmp(attrValue, "highlight") == 0);
    printf("  ✓ value = 'highlight'\n");

    DOMElement* ownerElem = dom_attr_get_ownerelement(attr);
    assert(ownerElem == elem);
    printf("  ✓ ownerElement is correct\n");

    // Test 4: setAttributeNode() - replace existing
    printf("\nTest 4: setAttributeNode() - replace existing\n");
    DOMAttr* newClassAttr = dom_document_createattribute(doc, "class");
    dom_attr_set_value(newClassAttr, "active");
    printf("  ✓ Created new Attr node (class='active')\n");

    oldAttr = dom_element_setattributenode(elem, newClassAttr);
    assert(oldAttr != NULL);
    printf("  ✓ Set attribute (returned old attribute)\n");

    const char* oldValue = dom_attr_get_value(oldAttr);
    assert(strcmp(oldValue, "highlight") == 0);
    printf("  ✓ Old value = 'highlight'\n");

    // Verify new value
    className = dom_element_getattribute(elem, "class");
    assert(strcmp(className, "active") == 0);
    printf("  ✓ New value = 'active'\n");

    // Release old attribute (we own it now)
    dom_attr_release(oldAttr);
    printf("  ✓ Released old attribute\n");

    // Test 5: removeAttributeNode()
    printf("\nTest 5: removeAttributeNode()\n");
    attr = dom_element_getattributenode(elem, "class");
    assert(attr != NULL);
    printf("  ✓ Got class attribute\n");

    DOMAttr* removed = dom_element_removeattributenode(elem, attr);
    assert(removed != NULL);
    assert(removed == attr); // Same pointer
    printf("  ✓ Removed attribute (same pointer)\n");

    const char* removedValue = dom_attr_get_value(removed);
    assert(strcmp(removedValue, "active") == 0);
    printf("  ✓ Removed value = 'active'\n");

    // Verify it's gone
    className = dom_element_getattribute(elem, "class");
    assert(className == NULL);
    printf("  ✓ Verified: attribute removed from element\n");

    // Release removed attribute (we own it now)
    dom_attr_release(removed);
    printf("  ✓ Released removed attribute\n");

    // Test 6: removeAttributeNode() - not found
    printf("\nTest 6: removeAttributeNode() - not found\n");
    DOMAttr* orphanAttr = dom_document_createattribute(doc, "orphan");
    removed = dom_element_removeattributenode(elem, orphanAttr);
    assert(removed == NULL); // Not found (not owned by element)
    printf("  ✓ Returns NULL for attribute not owned by element\n");
    dom_attr_release(orphanAttr);

    // Test 7: Namespaced attributes - setAttributeNodeNS()
    printf("\nTest 7: Namespaced attributes - setAttributeNodeNS()\n");
    const char* xml_ns = "http://www.w3.org/XML/1998/namespace";
    DOMAttr* langAttr = dom_document_createattributens(doc, xml_ns, "xml:lang");
    assert(langAttr != NULL);
    dom_attr_set_value(langAttr, "en");
    printf("  ✓ Created namespaced Attr (xml:lang='en')\n");

    oldAttr = dom_element_setattributenodens(elem, langAttr);
    assert(oldAttr == NULL); // No previous attribute
    printf("  ✓ Set namespaced attribute\n");

    // Test 8: getAttributeNodeNS()
    printf("\nTest 8: getAttributeNodeNS()\n");
    attr = dom_element_getattributenodens(elem, xml_ns, "lang");
    assert(attr != NULL);
    printf("  ✓ Got namespaced Attr node\n");

    const char* localName = dom_attr_get_localname(attr);
    assert(strcmp(localName, "lang") == 0);
    printf("  ✓ localName = 'lang'\n");

    const char* namespaceURI = dom_attr_get_namespaceuri(attr);
    assert(namespaceURI != NULL);
    assert(strcmp(namespaceURI, xml_ns) == 0);
    printf("  ✓ namespaceURI = '%s'\n", xml_ns);

    attrValue = dom_attr_get_value(attr);
    assert(strcmp(attrValue, "en") == 0);
    printf("  ✓ value = 'en'\n");

    // Test 9: Replace namespaced attribute
    printf("\nTest 9: Replace namespaced attribute\n");
    DOMAttr* newLangAttr = dom_document_createattributens(doc, xml_ns, "xml:lang");
    dom_attr_set_value(newLangAttr, "fr");
    printf("  ✓ Created new namespaced Attr (xml:lang='fr')\n");

    oldAttr = dom_element_setattributenodens(elem, newLangAttr);
    assert(oldAttr != NULL);
    printf("  ✓ Replaced namespaced attribute\n");

    oldValue = dom_attr_get_value(oldAttr);
    assert(strcmp(oldValue, "en") == 0);
    printf("  ✓ Old value = 'en'\n");

    dom_attr_release(oldAttr);
    printf("  ✓ Released old attribute\n");

    // Test 10: Remove namespaced attribute
    printf("\nTest 10: Remove namespaced attribute\n");
    attr = dom_element_getattributenodens(elem, xml_ns, "lang");
    assert(attr != NULL);

    removed = dom_element_removeattributenode(elem, attr);
    assert(removed != NULL);
    printf("  ✓ Removed namespaced attribute\n");

    removedValue = dom_attr_get_value(removed);
    assert(strcmp(removedValue, "fr") == 0);
    printf("  ✓ Removed value = 'fr'\n");

    dom_attr_release(removed);
    printf("  ✓ Released removed attribute\n");

    // Test 11: Multiple attributes
    printf("\nTest 11: Multiple attributes\n");
    dom_element_setattribute(elem, "id", "item1");
    dom_element_setattribute(elem, "class", "widget");
    dom_element_setattribute(elem, "data-value", "42");
    printf("  ✓ Set 3 attributes via string API\n");

    DOMAttr* idAttr = dom_element_getattributenode(elem, "id");
    DOMAttr* classAttr2 = dom_element_getattributenode(elem, "class");
    DOMAttr* dataAttr = dom_element_getattributenode(elem, "data-value");
    assert(idAttr != NULL);
    assert(classAttr2 != NULL);
    assert(dataAttr != NULL);
    printf("  ✓ Got all 3 Attr nodes\n");

    // Verify values
    assert(strcmp(dom_attr_get_value(idAttr), "item1") == 0);
    assert(strcmp(dom_attr_get_value(classAttr2), "widget") == 0);
    assert(strcmp(dom_attr_get_value(dataAttr), "42") == 0);
    printf("  ✓ All values correct\n");

    // Verify ownership
    assert(dom_attr_get_ownerelement(idAttr) == elem);
    assert(dom_attr_get_ownerelement(classAttr2) == elem);
    assert(dom_attr_get_ownerelement(dataAttr) == elem);
    printf("  ✓ All attributes owned by element\n");

    // Cleanup
    dom_element_release(elem);
    dom_document_release(doc);

    printf("\n==================================\n");
    printf("All tests passed! ✓\n");

    return 0;
}
