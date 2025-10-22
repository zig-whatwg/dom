/**
 * Test DOMImplementation C-ABI Bindings
 * 
 * Tests the 5 DOMImplementation functions:
 * - dom_document_get_implementation()
 * - dom_domimplementation_createdocumenttype()
 * - dom_domimplementation_createdocument()
 * - dom_domimplementation_hasfeature()
 * - dom_domimplementation_addref() / dom_domimplementation_release()
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// Forward declarations
typedef struct DOMDocument DOMDocument;
typedef struct DOMDOMImplementation DOMDOMImplementation;
typedef struct DOMDocumentType DOMDocumentType;
typedef struct DOMElement DOMElement;

// Document
extern DOMDocument* dom_document_new(void);
extern void dom_document_release(DOMDocument* doc);
extern DOMDOMImplementation* dom_document_get_implementation(DOMDocument* doc);
extern DOMElement* dom_document_get_documentelement(DOMDocument* doc);

// DOMImplementation
extern DOMDocumentType* dom_domimplementation_createdocumenttype(
    DOMDOMImplementation* impl,
    const char* name,
    const char* public_id,
    const char* system_id
);
extern DOMDocument* dom_domimplementation_createdocument(
    DOMDOMImplementation* impl,
    const char* namespace,
    const char* qualified_name,
    DOMDocumentType* doctype
);
extern int dom_domimplementation_hasfeature(DOMDOMImplementation* impl);
extern void dom_domimplementation_addref(DOMDOMImplementation* impl);
extern void dom_domimplementation_release(DOMDOMImplementation* impl);

// DocumentType
extern const char* dom_documenttype_get_name(DOMDocumentType* doctype);
extern const char* dom_documenttype_get_publicid(DOMDocumentType* doctype);
extern const char* dom_documenttype_get_systemid(DOMDocumentType* doctype);
extern void dom_documenttype_release(DOMDocumentType* doctype);

// Element
extern const char* dom_element_get_tagname(DOMElement* elem);

int main(void) {
    printf("Testing DOMImplementation C-ABI Bindings\n");
    printf("=========================================\n\n");

    // Create document
    DOMDocument* doc = dom_document_new();
    assert(doc != NULL);
    printf("✓ Created document\n");

    // Test 1: Get implementation ([SameObject])
    printf("\nTest 1: Get implementation\n");
    DOMDOMImplementation* impl1 = dom_document_get_implementation(doc);
    assert(impl1 != NULL);
    printf("  ✓ Got implementation (first call)\n");

    DOMDOMImplementation* impl2 = dom_document_get_implementation(doc);
    assert(impl2 != NULL);
    assert(impl1 == impl2); // [SameObject]
    printf("  ✓ Same pointer on second call ([SameObject])\n");

    // Test 2: hasFeature() - deprecated, always returns true
    printf("\nTest 2: hasFeature() - deprecated API\n");
    int hasFeature = dom_domimplementation_hasfeature(impl1);
    assert(hasFeature == 1);
    printf("  ✓ hasFeature() returns true (always)\n");

    // Test 3: createDocumentType() - HTML5 DOCTYPE
    printf("\nTest 3: createDocumentType() - HTML5\n");
    DOMDocumentType* htmlDoctype = dom_domimplementation_createdocumenttype(
        impl1,
        "html",
        "",
        ""
    );
    assert(htmlDoctype != NULL);
    printf("  ✓ Created HTML5 DOCTYPE\n");

    const char* name = dom_documenttype_get_name(htmlDoctype);
    assert(strcmp(name, "html") == 0);
    printf("  ✓ name = 'html'\n");

    const char* publicId = dom_documenttype_get_publicid(htmlDoctype);
    assert(strcmp(publicId, "") == 0);
    printf("  ✓ publicId = '' (empty)\n");

    const char* systemId = dom_documenttype_get_systemid(htmlDoctype);
    assert(strcmp(systemId, "") == 0);
    printf("  ✓ systemId = '' (empty)\n");

    dom_documenttype_release(htmlDoctype);

    // Test 4: createDocumentType() - SVG 1.1 DOCTYPE
    printf("\nTest 4: createDocumentType() - SVG 1.1\n");
    DOMDocumentType* svgDoctype = dom_domimplementation_createdocumenttype(
        impl1,
        "svg",
        "-//W3C//DTD SVG 1.1//EN",
        "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
    );
    assert(svgDoctype != NULL);
    printf("  ✓ Created SVG 1.1 DOCTYPE\n");

    name = dom_documenttype_get_name(svgDoctype);
    assert(strcmp(name, "svg") == 0);
    printf("  ✓ name = 'svg'\n");

    publicId = dom_documenttype_get_publicid(svgDoctype);
    assert(strcmp(publicId, "-//W3C//DTD SVG 1.1//EN") == 0);
    printf("  ✓ publicId = '-//W3C//DTD SVG 1.1//EN'\n");

    systemId = dom_documenttype_get_systemid(svgDoctype);
    assert(strcmp(systemId, "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd") == 0);
    printf("  ✓ systemId = 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'\n");

    // Test 5: createDocument() - Empty document (no root element)
    printf("\nTest 5: createDocument() - Empty document\n");
    DOMDocument* emptyDoc = dom_domimplementation_createdocument(impl1, NULL, "", NULL);
    assert(emptyDoc != NULL);
    printf("  ✓ Created empty document\n");

    DOMElement* emptyRoot = dom_document_get_documentelement(emptyDoc);
    assert(emptyRoot == NULL);
    printf("  ✓ documentElement is NULL (no root element)\n");

    dom_document_release(emptyDoc);

    // Test 6: createDocument() - Document with root element
    printf("\nTest 6: createDocument() - With root element\n");
    DOMDocument* xmlDoc = dom_domimplementation_createdocument(impl1, NULL, "root", NULL);
    assert(xmlDoc != NULL);
    printf("  ✓ Created document with root element\n");

    DOMElement* rootElem = dom_document_get_documentelement(xmlDoc);
    assert(rootElem != NULL);
    printf("  ✓ documentElement exists\n");

    const char* tagName = dom_element_get_tagname(rootElem);
    assert(strcmp(tagName, "root") == 0);
    printf("  ✓ root element tagName = 'root'\n");

    dom_document_release(xmlDoc);

    // Test 7: createDocument() - With namespace (TODO: namespace support)
    printf("\nTest 7: createDocument() - With namespace\n");
    DOMDocument* svgDoc = dom_domimplementation_createdocument(
        impl1,
        "http://www.w3.org/2000/svg",
        "svg",
        NULL
    );
    assert(svgDoc != NULL);
    printf("  ✓ Created SVG document\n");

    DOMElement* svgElem = dom_document_get_documentelement(svgDoc);
    assert(svgElem != NULL);
    tagName = dom_element_get_tagname(svgElem);
    assert(strcmp(tagName, "svg") == 0);
    printf("  ✓ root element tagName = 'svg'\n");
    printf("  ⚠  namespace not yet stored (TODO: full namespace support)\n");

    dom_document_release(svgDoc);

    // Test 8: createDocument() - With DOCTYPE
    printf("\nTest 8: createDocument() - With DOCTYPE\n");
    DOMDocument* svgWithDoctype = dom_domimplementation_createdocument(
        impl1,
        "http://www.w3.org/2000/svg",
        "svg",
        svgDoctype
    );
    assert(svgWithDoctype != NULL);
    printf("  ✓ Created document with DOCTYPE\n");

    dom_documenttype_release(svgDoctype);
    dom_document_release(svgWithDoctype);

    // Test 9: addref/release (ownership transfer)
    printf("\nTest 9: Reference counting\n");
    DOMDOMImplementation* implCopy = dom_document_get_implementation(doc);
    dom_domimplementation_addref(implCopy);
    printf("  ✓ Added reference to implementation\n");

    // Release impl reference first, then document
    dom_domimplementation_release(implCopy);
    printf("  ✓ Released implementation reference\n");

    // Release document
    dom_document_release(doc);
    printf("  ✓ Released document\n");

    // Cleanup
    printf("\n=========================================\n");
    printf("All tests passed! ✓\n");

    return 0;
}
