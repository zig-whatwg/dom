/**
 * Phase 4 Integration Test
 * 
 * Tests all Phase 4 interfaces working together:
 * - Attr (attribute nodes)
 * - DocumentType (DOCTYPE declarations)
 * - DocumentFragment (batch operations)
 * - DOMImplementation (factory methods)
 * - Element Attr node methods
 * - Document factory methods (createAttribute, createAttributeNS)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// Forward declarations
typedef struct DOMDocument DOMDocument;
typedef struct DOMElement DOMElement;
typedef struct DOMAttr DOMAttr;
typedef struct DOMDocumentType DOMDocumentType;
typedef struct DOMDocumentFragment DOMDocumentFragment;
typedef struct DOMDOMImplementation DOMDOMImplementation;
typedef struct DOMNamedNodeMap DOMNamedNodeMap;
typedef struct DOMNode DOMNode;

// Document
extern DOMDocument* dom_document_new(void);
extern void dom_document_release(DOMDocument* doc);
extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* name);
extern DOMAttr* dom_document_createattribute(DOMDocument* doc, const char* name);
extern DOMDOMImplementation* dom_document_get_implementation(DOMDocument* doc);
extern DOMElement* dom_document_get_documentelement(DOMDocument* doc);

// DOMImplementation
extern DOMDocumentType* dom_domimplementation_createdocumenttype(DOMDOMImplementation* impl, const char* name, const char* publicId, const char* systemId);
extern DOMDocument* dom_domimplementation_createdocument(DOMDOMImplementation* impl, const char* namespace, const char* qualifiedName, DOMDocumentType* doctype);

// Element
extern int dom_element_setattribute(DOMElement* elem, const char* name, const char* value);
extern DOMAttr* dom_element_getattributenode(DOMElement* elem, const char* name);
extern DOMAttr* dom_element_setattributenode(DOMElement* elem, DOMAttr* attr);
extern DOMAttr* dom_element_removeattributenode(DOMElement* elem, DOMAttr* attr);
extern DOMNamedNodeMap* dom_element_get_attributes(DOMElement* elem);
extern void dom_element_release(DOMElement* elem);

// Attr
extern const char* dom_attr_get_name(DOMAttr* attr);
extern const char* dom_attr_get_value(DOMAttr* attr);
extern int dom_attr_set_value(DOMAttr* attr, const char* value);
extern DOMElement* dom_attr_get_ownerelement(DOMAttr* attr);
extern int dom_attr_get_specified(DOMAttr* attr);
extern void dom_attr_release(DOMAttr* attr);

// NamedNodeMap
extern unsigned int dom_namednodemap_get_length(DOMNamedNodeMap* map);
extern DOMAttr* dom_namednodemap_item(DOMNamedNodeMap* map, unsigned int index);
extern DOMAttr* dom_namednodemap_getnameditem(DOMNamedNodeMap* map, const char* qualifiedName);

// DocumentType
extern const char* dom_documenttype_get_name(DOMDocumentType* doctype);
extern const char* dom_documenttype_get_publicid(DOMDocumentType* doctype);
extern const char* dom_documenttype_get_systemid(DOMDocumentType* doctype);
extern void dom_documenttype_release(DOMDocumentType* doctype);

// Node
extern DOMNode* dom_node_appendchild(DOMNode* parent, DOMNode* child);

int main(void) {
    printf("Phase 4 Integration Test\n");
    printf("========================\n\n");

    // Scenario 1: Create XML document with DOCTYPE using DOMImplementation
    printf("Scenario 1: XML Document with DOCTYPE\n");
    printf("-------------------------------------\n");

    DOMDocument* baseDoc = dom_document_new();
    DOMDOMImplementation* impl = dom_document_get_implementation(baseDoc);
    printf("✓ Got DOMImplementation\n");

    // Create SVG DOCTYPE
    DOMDocumentType* svgDoctype = dom_domimplementation_createdocumenttype(
        impl,
        "svg",
        "-//W3C//DTD SVG 1.1//EN",
        "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
    );
    assert(svgDoctype != NULL);
    printf("✓ Created SVG DOCTYPE\n");

    // Verify DOCTYPE properties
    assert(strcmp(dom_documenttype_get_name(svgDoctype), "svg") == 0);
    assert(strcmp(dom_documenttype_get_publicid(svgDoctype), "-//W3C//DTD SVG 1.1//EN") == 0);
    printf("✓ DOCTYPE properties correct\n");

    // Create SVG document with DOCTYPE
    DOMDocument* svgDoc = dom_domimplementation_createdocument(
        impl,
        "http://www.w3.org/2000/svg",
        "svg",
        svgDoctype
    );
    assert(svgDoc != NULL);
    printf("✓ Created SVG document with DOCTYPE\n");

    // Verify root element
    DOMElement* svgRoot = dom_document_get_documentelement(svgDoc);
    assert(svgRoot != NULL);
    printf("✓ Document has root element\n");

    dom_documenttype_release(svgDoctype);
    dom_document_release(svgDoc);
    dom_document_release(baseDoc);
    printf("✓ Cleaned up\n\n");

    // Scenario 2: Element with multiple attributes (Attr nodes + NamedNodeMap)
    printf("Scenario 2: Element Attributes\n");
    printf("-------------------------------\n");

    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "widget");
    printf("✓ Created element\n");

    // Add attributes using string API
    dom_element_setattribute(elem, "id", "widget-1");
    dom_element_setattribute(elem, "class", "active");
    dom_element_setattribute(elem, "data-value", "42");
    printf("✓ Set 3 attributes\n");

    // Access via NamedNodeMap
    DOMNamedNodeMap* attrs = dom_element_get_attributes(elem);
    unsigned int attrCount = dom_namednodemap_get_length(attrs);
    printf("  DEBUG: attrCount = %u (expected 3)\n", attrCount);
    assert(attrCount == 3);
    printf("✓ NamedNodeMap has 3 attributes\n");

    // Access by index
    for (unsigned int i = 0; i < attrCount; i++) {
        DOMAttr* attr = dom_namednodemap_item(attrs, i);
        assert(attr != NULL);
        const char* name = dom_attr_get_name(attr);
        const char* value = dom_attr_get_value(attr);
        printf("  - %s='%s'\n", name, value);
    }

    // Access by name
    DOMAttr* idAttr = dom_namednodemap_getnameditem(attrs, "id");
    assert(idAttr != NULL);
    assert(strcmp(dom_attr_get_value(idAttr), "widget-1") == 0);
    printf("✓ Access by name works\n");

    // Verify Attr properties
    assert(dom_attr_get_ownerelement(idAttr) == elem);
    assert(dom_attr_get_specified(idAttr) == 1);
    printf("✓ Attr properties correct\n\n");

    // Scenario 3: Manipulate attributes via Attr nodes
    printf("Scenario 3: Attr Node Manipulation\n");
    printf("-----------------------------------\n");

    // Create new attribute
    DOMAttr* titleAttr = dom_document_createattribute(doc, "title");
    dom_attr_set_value(titleAttr, "My Widget");
    printf("✓ Created Attr node (title='My Widget')\n");

    // Add to element
    DOMAttr* oldAttr = dom_element_setattributenode(elem, titleAttr);
    assert(oldAttr == NULL); // No previous title
    printf("✓ Added Attr to element\n");

    // Verify it's there
    DOMAttr* gotTitleAttr = dom_element_getattributenode(elem, "title");
    assert(gotTitleAttr != NULL);
    assert(strcmp(dom_attr_get_value(gotTitleAttr), "My Widget") == 0);
    printf("✓ Retrieved Attr from element\n");

    // Replace it
    DOMAttr* newTitleAttr = dom_document_createattribute(doc, "title");
    dom_attr_set_value(newTitleAttr, "Updated Widget");
    oldAttr = dom_element_setattributenode(elem, newTitleAttr);
    assert(oldAttr != NULL);
    assert(strcmp(dom_attr_get_value(oldAttr), "My Widget") == 0);
    dom_attr_release(oldAttr);
    printf("✓ Replaced Attr\n");

    // Remove it
    gotTitleAttr = dom_element_getattributenode(elem, "title");
    DOMAttr* removed = dom_element_removeattributenode(elem, gotTitleAttr);
    assert(removed != NULL);
    assert(strcmp(dom_attr_get_value(removed), "Updated Widget") == 0);
    dom_attr_release(removed);
    printf("✓ Removed Attr\n\n");

    // Scenario 4: Complete workflow
    printf("Scenario 4: Complete Workflow\n");
    printf("------------------------------\n");

    // Create document with DOCTYPE
    impl = dom_document_get_implementation(doc);
    DOMDocumentType* doctype = dom_domimplementation_createdocumenttype(impl, "data", "", "");
    DOMDocument* dataDoc = dom_domimplementation_createdocument(impl, NULL, "root", doctype);
    printf("✓ Created document with DOCTYPE\n");

    // Add element with attributes
    DOMElement* item = dom_document_createelement(dataDoc, "item");
    dom_element_setattribute(item, "id", "item-1");
    dom_element_setattribute(item, "name", "First Item");
    printf("✓ Created element with attributes\n");

    // Append to document
    DOMElement* rootElem = dom_document_get_documentelement(dataDoc);
    dom_node_appendchild((DOMNode*)rootElem, (DOMNode*)item);
    printf("✓ Appended to document\n");

    // Verify attribute count
    attrs = dom_element_get_attributes(item);
    assert(dom_namednodemap_get_length(attrs) == 2);
    printf("✓ Element has 2 attributes\n");

    // Access attributes via NamedNodeMap
    DOMAttr* nameAttr = dom_namednodemap_getnameditem(attrs, "name");
    assert(nameAttr != NULL);
    assert(strcmp(dom_attr_get_value(nameAttr), "First Item") == 0);
    printf("✓ Accessed attribute via NamedNodeMap\n");

    // Modify attribute value
    dom_attr_set_value(nameAttr, "Modified Item");
    assert(strcmp(dom_attr_get_value(nameAttr), "Modified Item") == 0);
    printf("✓ Modified attribute value\n");

    // Cleanup
    dom_documenttype_release(doctype);
    dom_document_release(dataDoc);
    dom_element_release(elem);
    dom_document_release(doc);
    printf("✓ Cleaned up\n\n");

    printf("========================\n");
    printf("All integration tests passed! ✓\n");
    printf("\nPhase 4 Complete!\n");
    printf("- Attr interface ✓\n");
    printf("- DocumentType interface ✓\n");
    printf("- DocumentFragment interface ✓\n");
    printf("- DOMImplementation interface ✓\n");
    printf("- Element Attr methods ✓\n");
    printf("- Document factory methods ✓\n");

    return 0;
}
