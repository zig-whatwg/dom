/**
 * DOM JavaScript Bindings - C Header File
 * 
 * This header provides declarations for the DOM C-ABI library.
 * 
 * Usage:
 *   #include "dom.h"
 *   
 *   // Compile with:
 *   gcc -o myapp myapp.c -L/path/to/lib -ldom -lpthread
 * 
 * Version: 1.0.0
 * License: MIT
 * Spec: WHATWG DOM Living Standard
 */

#ifndef DOM_H
#define DOM_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdbool.h>

/* ============================================================================
 * Opaque Types
 * ========================================================================= */

typedef struct DOMDocument DOMDocument;
typedef struct DOMElement DOMElement;
typedef struct DOMNode DOMNode;
typedef struct DOMCharacterData DOMCharacterData;
typedef struct DOMText DOMText;
typedef struct DOMComment DOMComment;
typedef struct DOMCDATASection DOMCDATASection;
typedef struct DOMProcessingInstruction DOMProcessingInstruction;
typedef struct DOMDocumentFragment DOMDocumentFragment;
typedef struct DOMDocumentType DOMDocumentType;
typedef struct DOMDOMImplementation DOMDOMImplementation;
typedef struct DOMAttr DOMAttr;
typedef struct DOMDOMTokenList DOMDOMTokenList;
typedef struct DOMNamedNodeMap DOMNamedNodeMap;
typedef struct DOMShadowRoot DOMShadowRoot;
typedef struct DOMEventTarget DOMEventTarget;
typedef struct DOMEvent DOMEvent;
typedef struct DOMCustomEvent DOMCustomEvent;
typedef struct DOMAbstractRange DOMAbstractRange;
typedef struct DOMRange DOMRange;
typedef struct DOMStaticRange DOMStaticRange;
typedef struct DOMTreeWalker DOMTreeWalker;
typedef struct DOMNodeIterator DOMNodeIterator;
typedef struct DOMHTMLCollection DOMHTMLCollection;
typedef struct DOMNodeList DOMNodeList;
typedef struct DOMAbortController DOMAbortController;
typedef struct DOMAbortSignal DOMAbortSignal;

/* ============================================================================
 * Constants
 * ========================================================================= */

/* Node Types */
#define DOM_ELEMENT_NODE                1
#define DOM_ATTRIBUTE_NODE              2
#define DOM_TEXT_NODE                   3
#define DOM_CDATA_SECTION_NODE          4
#define DOM_PROCESSING_INSTRUCTION_NODE 7
#define DOM_COMMENT_NODE                8
#define DOM_DOCUMENT_NODE               9
#define DOM_DOCUMENT_TYPE_NODE          10
#define DOM_DOCUMENT_FRAGMENT_NODE      11

/* Error Codes */
#define DOM_ERROR_SUCCESS                      0
#define DOM_ERROR_INDEX_SIZE                   1
#define DOM_ERROR_HIERARCHY_REQUEST            3
#define DOM_ERROR_WRONG_DOCUMENT               4
#define DOM_ERROR_INVALID_CHARACTER            5
#define DOM_ERROR_NO_MODIFICATION_ALLOWED      7
#define DOM_ERROR_NOT_FOUND                    8
#define DOM_ERROR_NOT_SUPPORTED                9
#define DOM_ERROR_INUSE_ATTRIBUTE              10
#define DOM_ERROR_INVALID_STATE                11
#define DOM_ERROR_SYNTAX                       12
#define DOM_ERROR_INVALID_MODIFICATION         13
#define DOM_ERROR_NAMESPACE                    14
#define DOM_ERROR_INVALID_ACCESS               15

/* Boolean values for C */
#define DOM_TRUE  1
#define DOM_FALSE 0

/* Range Boundary Point Comparison Constants */
#define DOM_RANGE_START_TO_START 0
#define DOM_RANGE_START_TO_END   1
#define DOM_RANGE_END_TO_END     2
#define DOM_RANGE_END_TO_START   3

/* Event Phase Constants */
#define DOM_EVENT_NONE              0
#define DOM_EVENT_CAPTURING_PHASE   1
#define DOM_EVENT_AT_TARGET         2
#define DOM_EVENT_BUBBLING_PHASE    3

/* ============================================================================
 * Error Handling
 * ========================================================================= */

/**
 * Get the name of an error code.
 * 
 * @param code Error code from a DOM function
 * @return Null-terminated string (do NOT free)
 * 
 * Example:
 *   int err = dom_element_setattribute(elem, "id", "test");
 *   if (err != 0) {
 *     printf("Error: %s\n", dom_error_code_name(err));
 *   }
 */
const char* dom_error_code_name(int32_t code);

/**
 * Get a human-readable message for an error code.
 * 
 * @param code Error code from a DOM function
 * @return Null-terminated string (do NOT free)
 */
const char* dom_error_code_message(int32_t code);

/* ============================================================================
 * Document Interface
 * ========================================================================= */

/**
 * Create a new Document.
 * 
 * The document is created with ref_count = 1.
 * Call dom_document_release() when done.
 * 
 * @return New document (never NULL)
 * 
 * Example:
 *   DOMDocument* doc = dom_document_new();
 *   // ... use doc ...
 *   dom_document_release(doc);
 */
DOMDocument* dom_document_new(void);

/**
 * Increment document reference count.
 * 
 * Call this when sharing ownership of the document.
 * Each addref must be matched with a release.
 * 
 * @param doc Document
 */
void dom_document_addref(DOMDocument* doc);

/**
 * Decrement document reference count.
 * 
 * When ref_count reaches 0, the document is freed.
 * 
 * @param doc Document
 */
void dom_document_release(DOMDocument* doc);

/**
 * Get document compat mode.
 * 
 * @param doc Document
 * @return "CSS1Compat" (standards mode) - this implementation always uses standards mode
 */
const char* dom_document_get_compatmode(DOMDocument* doc);

/**
 * Get document character encoding.
 * 
 * @param doc Document
 * @return "UTF-8" - this implementation always uses UTF-8
 */
const char* dom_document_get_characterset(DOMDocument* doc);

/**
 * Get document character set (legacy alias).
 * 
 * @param doc Document
 * @return "UTF-8" - same as characterSet
 */
const char* dom_document_get_charset(DOMDocument* doc);

/**
 * Get document input encoding (legacy alias).
 * 
 * @param doc Document
 * @return "UTF-8" - same as characterSet
 */
const char* dom_document_get_inputencoding(DOMDocument* doc);

/**
 * Get document content type.
 * 
 * @param doc Document
 * @return "application/xml" - generic DOM returns XML content type
 */
const char* dom_document_get_contenttype(DOMDocument* doc);

/**
 * Get document URL.
 * 
 * Returns the document's URL. For a generic DOM without browsing context,
 * this returns an empty string by default.
 * 
 * @param doc Document
 * @return Document URL (empty string for generic DOM)
 * 
 * Example:
 *   const char* url = dom_document_get_url(doc);
 *   printf("Document URL: %s\n", url);
 */
const char* dom_document_get_url(DOMDocument* doc);

/**
 * Get document URI (alias for URL).
 * 
 * This property is functionally equivalent to URL. It exists for
 * historical reasons and compatibility.
 * 
 * @param doc Document
 * @return Document URI (same as URL, empty string for generic DOM)
 * 
 * Example:
 *   const char* uri = dom_document_get_documenturi(doc);
 */
const char* dom_document_get_documenturi(DOMDocument* doc);

/**
 * Get document type declaration.
 * 
 * Returns the DocumentType node (<!DOCTYPE ...>) if present.
 * 
 * @param doc Document
 * @return DocumentType node or NULL if none exists
 * 
 * Example:
 *   DOMDocumentType* doctype = dom_document_get_doctype(doc);
 *   if (doctype) {
 *       const char* name = dom_documenttype_get_name(doctype);
 *       printf("DOCTYPE: %s\n", name);
 *   }
 */
DOMDocumentType* dom_document_get_doctype(DOMDocument* doc);

/**
 * Create an element.
 * 
 * @param doc Document
 * @param localName Tag name (e.g., "div", "span")
 * @return New element (never NULL, panics on error)
 * 
 * Example:
 *   DOMElement* div = dom_document_createelement(doc, "div");
 */
DOMElement* dom_document_createelement(DOMDocument* doc, const char* localName);

/**
 * Create an element with namespace.
 * 
 * @param doc Document
 * @param namespace Namespace URI (can be NULL)
 * @param qualifiedName Qualified name (e.g., "svg:rect")
 * @return New element (never NULL, panics on error)
 */
DOMElement* dom_document_createelementns(DOMDocument* doc, const char* ns, const char* qualifiedName);

/**
 * Create a text node.
 * 
 * @param doc Document
 * @param data Text content
 * @return New text node (never NULL)
 */
DOMText* dom_document_createtextnode(DOMDocument* doc, const char* data);

/**
 * Create a comment node.
 * 
 * @param doc Document
 * @param data Comment content
 * @return New comment node (never NULL)
 */
DOMComment* dom_document_createcomment(DOMDocument* doc, const char* data);

/**
 * Import a node from another document.
 * 
 * Creates a copy of a node from another document that can be inserted into this document.
 * The original node is not altered.
 * 
 * @param doc Target document
 * @param node Node to import
 * @param deep If non-zero, deep clone (with descendants); if zero, shallow clone
 * @return New node owned by this document (never NULL)
 * 
 * Example:
 *   DOMDocument* doc1 = dom_document_new();
 *   DOMDocument* doc2 = dom_document_new();
 *   DOMElement* elem = dom_document_createelement(doc1, "div");
 *   
 *   // Import elem from doc1 into doc2
 *   DOMNode* imported = dom_document_importnode(doc2, (DOMNode*)elem, 0);
 *   // imported is now owned by doc2, elem is unchanged in doc1
 */
DOMNode* dom_document_importnode(DOMDocument* doc, DOMNode* node, uint8_t deep);

/**
 * Adopt a node from another document.
 * 
 * Transfers ownership of a node from its current document to this document.
 * Unlike importNode, adoptNode moves the node rather than copying it.
 * 
 * @param doc Target document
 * @param node Node to adopt
 * @return The same node, now owned by this document (never NULL)
 * 
 * Example:
 *   DOMDocument* doc1 = dom_document_new();
 *   DOMDocument* doc2 = dom_document_new();
 *   DOMElement* elem = dom_document_createelement(doc1, "div");
 *   
 *   // Adopt elem from doc1 into doc2
 *   DOMNode* adopted = dom_document_adoptnode(doc2, (DOMNode*)elem);
 *   // adopted == elem, but now belongs to doc2
 */
DOMNode* dom_document_adoptnode(DOMDocument* doc, DOMNode* node);

/**
 * Find first element matching a CSS selector.
 * 
 * Searches the document tree for an element matching the CSS selector.
 * 
 * @param doc Document
 * @param selectors CSS selector string (e.g., ".class", "#id", "div > p")
 * @return First matching element or NULL if not found
 * 
 * Example:
 *   DOMElement* button = dom_document_queryselector(doc, "button.primary");
 *   if (button) {
 *     printf("Found primary button\n");
 *   }
 */
DOMElement* dom_document_queryselector(DOMDocument* doc, const char* selectors);

/**
 * Find all elements matching a CSS selector.
 * 
 * Returns a static snapshot of all elements matching the selector at query time.
 * The list does NOT update when the DOM changes (unlike getElementsByClassName).
 * 
 * @param doc Document
 * @param selectors CSS selector string
 * @return Static NodeList or NULL if no matches or error
 * 
 * Example:
 *   DOMNodeList* results = dom_document_queryselectorall(doc, ".button");
 *   if (results) {
 *       uint32_t count = dom_nodelist_static_get_length(results);
 *       for (uint32_t i = 0; i < count; i++) {
 *           DOMNode* node = dom_nodelist_static_item(results, i);
 *           // Process node (can cast to DOMElement*)
 *       }
 *       dom_nodelist_static_release(results);
 *   }
 */
DOMNodeList* dom_document_queryselectorall(DOMDocument* doc, const char* selectors);

/**
 * Get all elements with the specified tag name.
 * 
 * Returns a live HTMLCollection of elements with the given tag name.
 * The collection automatically updates as the DOM changes.
 * 
 * @param doc Document
 * @param qualifiedName Tag name to search for (use "*" for all elements)
 * @return Live HTMLCollection (must be released with dom_htmlcollection_release)
 * 
 * Example:
 *   DOMHTMLCollection* divs = dom_document_getelementsbytagname(doc, "div");
 *   uint32_t count = dom_htmlcollection_get_length(divs);
 *   for (uint32_t i = 0; i < count; i++) {
 *       DOMElement* elem = dom_htmlcollection_item(divs, i);
 *       // Process element
 *   }
 *   dom_htmlcollection_release(divs);
 */
DOMHTMLCollection* dom_document_getelementsbytagname(DOMDocument* doc, const char* qualifiedName);

/**
 * Get all elements with the specified namespace and local name.
 * 
 * Returns a live HTMLCollection of elements matching both namespace and local name.
 * Use "*" for either parameter to match any namespace or any local name.
 * 
 * @param doc Document
 * @param namespace Namespace URI (NULL for no namespace, "*" for any)
 * @param localName Local name (use "*" for any local name)
 * @return Live HTMLCollection (must be released with dom_htmlcollection_release)
 * 
 * Example:
 *   // Find all SVG circles
 *   DOMHTMLCollection* circles = dom_document_getelementsbytagnamens(
 *       doc, "http://www.w3.org/2000/svg", "circle");
 *   dom_htmlcollection_release(circles);
 */
DOMHTMLCollection* dom_document_getelementsbytagnamens(DOMDocument* doc, const char* ns, const char* localName);

/**
 * Get elements by class name(s).
 * 
 * Returns a live HTMLCollection of all elements with the specified class name(s).
 * Multiple class names should be space-separated.
 * 
 * @param doc Document
 * @param classNames Space-separated list of class names
 * @return Live HTMLCollection (must be released with dom_htmlcollection_release)
 * 
 * Example:
 *   // Find elements with both "button" and "primary" classes
 *   DOMHTMLCollection* buttons = dom_document_getelementsbyclassname(doc, "button primary");
 *   uint32_t count = dom_htmlcollection_get_length(buttons);
 *   dom_htmlcollection_release(buttons);
 */
DOMHTMLCollection* dom_document_getelementsbyclassname(DOMDocument* doc, const char* classNames);

/**
 * Get element by ID.
 * 
 * Returns the first element with the specified ID attribute value.
 * Uses optimized ID map with caching for fast lookups (~2-84ns).
 * 
 * @param doc Document
 * @param elementId ID value to search for
 * @return Element with matching ID, or NULL if not found
 * 
 * Example:
 *   DOMElement* elem = dom_document_getelementbyid(doc, "my-element");
 *   if (elem) {
 *       // Process element
 *   }
 */
DOMElement* dom_document_getelementbyid(DOMDocument* doc, const char* elementId);

/**
 * Create a new Range.
 * 
 * Creates a collapsed range positioned at the start of the document.
 * 
 * @param doc Document
 * @return New Range (must be released with dom_range_release)
 * 
 * Example:
 *   DOMRange* range = dom_document_createrange(doc);
 *   dom_range_setstart(range, textNode, 0);
 *   dom_range_setend(range, textNode, 5);
 *   dom_range_release(range);
 */
DOMRange* dom_document_createrange(DOMDocument* doc);

/**
 * Create a TreeWalker.
 * 
 * @param doc Document
 * @param root Root node for traversal
 * @param whatToShow Bitmask of node types to show (use DOM_NODEFILTER_SHOW_* constants)
 * @param filter Custom node filter (currently must be NULL)
 * @return TreeWalker
 * 
 * Example:
 *   DOMTreeWalker* walker = dom_document_createtreewalker(
 *       doc, 
 *       rootNode, 
 *       DOM_NODEFILTER_SHOW_ELEMENT,
 *       NULL
 *   );
 *   DOMNode* child = dom_treewalker_firstchild(walker);
 *   dom_treewalker_release(walker);
 */
DOMTreeWalker* dom_document_createtreewalker(DOMDocument* doc, DOMNode* root, uint32_t whatToShow, void* filter);

/**
 * Create a NodeIterator.
 * 
 * @param doc Document
 * @param root Root node for iteration
 * @param whatToShow Bitmask of node types to show (use DOM_NODEFILTER_SHOW_* constants)
 * @param filter Custom node filter (currently must be NULL)
 * @return NodeIterator
 * 
 * Example:
 *   DOMNodeIterator* iterator = dom_document_createnodeiterator(
 *       doc,
 *       rootNode,
 *       DOM_NODEFILTER_SHOW_ELEMENT,
 *       NULL
 *   );
 *   DOMNode* node = dom_nodeiterator_nextnode(iterator);
 *   while (node != NULL) {
 *       // Process node
 *       node = dom_nodeiterator_nextnode(iterator);
 *   }
 *   dom_nodeiterator_release(iterator);
 */
DOMNodeIterator* dom_document_createnodeiterator(DOMDocument* doc, DOMNode* root, uint32_t whatToShow, void* filter);

/* ============================================================================
 * DOMImplementation Interface
 * ========================================================================= */

/**
 * Create a DocumentType node.
 * 
 * Creates a DocumentType node (<!DOCTYPE>) with the specified properties.
 * 
 * @param impl DOMImplementation handle
 * @param qualifiedName Document type name (e.g., "html")
 * @param publicId Public identifier (empty string for none)
 * @param systemId System identifier (empty string for none)
 * @return DocumentType node (must be released), or NULL on error
 * 
 * Example:
 *   DOMDOMImplementation* impl = dom_document_get_implementation(doc);
 *   DOMDocumentType* doctype = dom_domimplementation_createdocumenttype(
 *       impl, "html", "", ""
 *   );
 *   // Use doctype...
 *   dom_documenttype_release(doctype);
 */
DOMDocumentType* dom_domimplementation_createdocumenttype(
    DOMDOMImplementation* impl,
    const char* qualifiedName,
    const char* publicId,
    const char* systemId
);

/**
 * Create a Document.
 * 
 * Creates a new Document with optional namespace, qualified name, and doctype.
 * 
 * @param impl DOMImplementation handle
 * @param namespace_ Namespace URI (NULL for none)
 * @param qualifiedName Qualified element name for document element (NULL for none)
 * @param doctype DocumentType to associate (NULL for none)
 * @return New Document (must be released), or NULL on error
 * 
 * Example:
 *   DOMDOMImplementation* impl = dom_document_get_implementation(doc);
 *   DOMDocument* newDoc = dom_domimplementation_createdocument(
 *       impl, NULL, "root", NULL
 *   );
 *   // Use newDoc...
 *   dom_document_release(newDoc);
 */
DOMDocument* dom_domimplementation_createdocument(
    DOMDOMImplementation* impl,
    const char* namespace_,
    const char* qualifiedName,
    DOMDocumentType* doctype
);

/**
 * Check if feature is supported (legacy, always returns 1).
 * 
 * This is a legacy method from DOM Level 1. Modern code should not use it.
 * Always returns 1 (true) for compatibility.
 * 
 * @param impl DOMImplementation handle
 * @return 1 (always returns true for compatibility)
 */
int32_t dom_domimplementation_hasfeature(DOMDOMImplementation* impl);

/**
 * Increment reference count.
 * 
 * @param impl DOMImplementation handle
 */
void dom_domimplementation_addref(DOMDOMImplementation* impl);

/**
 * Decrement reference count.
 * 
 * @param impl DOMImplementation handle
 */
void dom_domimplementation_release(DOMDOMImplementation* impl);

/* ============================================================================
 * AbstractRange Interface
 * ========================================================================= */

/**
 * Get the start container node (AbstractRange).
 * 
 * AbstractRange is the base interface for Range and StaticRange.
 * All Range and StaticRange pointers can be cast to AbstractRange.
 * 
 * @param range AbstractRange (or Range/StaticRange cast to AbstractRange)
 * @return Start container node (do NOT release)
 */
DOMNode* dom_abstractrange_get_startcontainer(DOMAbstractRange* range);

/**
 * Get the start offset (AbstractRange).
 * 
 * @param range AbstractRange
 * @return Offset within start container
 */
uint32_t dom_abstractrange_get_startoffset(DOMAbstractRange* range);

/**
 * Get the end container node (AbstractRange).
 * 
 * @param range AbstractRange
 * @return End container node (do NOT release)
 */
DOMNode* dom_abstractrange_get_endcontainer(DOMAbstractRange* range);

/**
 * Get the end offset (AbstractRange).
 * 
 * @param range AbstractRange
 * @return Offset within end container
 */
uint32_t dom_abstractrange_get_endoffset(DOMAbstractRange* range);

/**
 * Check if range is collapsed (AbstractRange).
 * 
 * A range is collapsed when start == end.
 * 
 * @param range AbstractRange
 * @return 1 if collapsed, 0 otherwise
 */
uint8_t dom_abstractrange_get_collapsed(DOMAbstractRange* range);

/* ============================================================================
 * Range Interface
 * ========================================================================= */

/**
 * Get the start container node.
 * 
 * @param range Range
 * @return Start container node (do NOT release)
 */
DOMNode* dom_range_get_startcontainer(DOMRange* range);

/**
 * Get the start offset.
 * 
 * @param range Range
 * @return Offset within start container
 */
uint32_t dom_range_get_startoffset(DOMRange* range);

/**
 * Get the end container node.
 * 
 * @param range Range
 * @return End container node (do NOT release)
 */
DOMNode* dom_range_get_endcontainer(DOMRange* range);

/**
 * Get the end offset.
 * 
 * @param range Range
 * @return Offset within end container
 */
uint32_t dom_range_get_endoffset(DOMRange* range);

/**
 * Check if range is collapsed.
 * 
 * @param range Range
 * @return 1 if collapsed, 0 otherwise
 */
uint8_t dom_range_get_collapsed(DOMRange* range);

/**
 * Get the common ancestor container.
 * 
 * @param range Range
 * @return Common ancestor node (do NOT release)
 */
DOMNode* dom_range_get_commonancestorcontainer(DOMRange* range);

/**
 * Set the start boundary.
 * 
 * @param range Range
 * @param node Container node
 * @param offset Offset within node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_setstart(DOMRange* range, DOMNode* node, uint32_t offset);

/**
 * Set the end boundary.
 * 
 * @param range Range
 * @param node Container node
 * @param offset Offset within node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_setend(DOMRange* range, DOMNode* node, uint32_t offset);

/**
 * Set start before a node.
 * 
 * @param range Range
 * @param node Node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_setstartbefore(DOMRange* range, DOMNode* node);

/**
 * Set start after a node.
 * 
 * @param range Range
 * @param node Node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_setstartafter(DOMRange* range, DOMNode* node);

/**
 * Set end before a node.
 * 
 * @param range Range
 * @param node Node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_setendbefore(DOMRange* range, DOMNode* node);

/**
 * Set end after a node.
 * 
 * @param range Range
 * @param node Node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_setendafter(DOMRange* range, DOMNode* node);

/**
 * Collapse the range.
 * 
 * @param range Range
 * @param to_start 1 to collapse to start, 0 to collapse to end
 */
void dom_range_collapse(DOMRange* range, uint8_t to_start);

/**
 * Select node contents.
 * 
 * @param range Range
 * @param node Node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_selectnodecontents(DOMRange* range, DOMNode* node);

/**
 * Select a node (including the node itself).
 * 
 * @param range Range
 * @param node Node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_selectnode(DOMRange* range, DOMNode* node);

/**
 * Compare boundary points.
 * 
 * @param range Range
 * @param how Comparison type (DOM_RANGE_START_TO_START, etc.)
 * @param source_range Range to compare with
 * @return -1, 0, or 1, or error code (>= 8) on failure
 */
int16_t dom_range_compareboundarypoints(DOMRange* range, uint16_t how, DOMRange* source_range);

/**
 * Compare a point with the range.
 * 
 * @param range Range
 * @param node Node
 * @param offset Offset
 * @return -1, 0, or 1, or error code (>= 8) on failure
 */
int16_t dom_range_comparepoint(DOMRange* range, DOMNode* node, uint32_t offset);

/**
 * Check if point is in range.
 * 
 * @param range Range
 * @param node Node
 * @param offset Offset
 * @return 1 if in range, 0 if not, >= 2 on error
 */
uint8_t dom_range_ispointinrange(DOMRange* range, DOMNode* node, uint32_t offset);

/**
 * Check if node intersects range.
 * 
 * @param range Range
 * @param node Node
 * @return 1 if intersects, 0 otherwise
 */
uint8_t dom_range_intersectsnode(DOMRange* range, DOMNode* node);

/**
 * Delete range contents.
 * 
 * @param range Range
 * @return 0 on success, error code on failure
 */
int32_t dom_range_deletecontents(DOMRange* range);

/**
 * Extract contents into DocumentFragment.
 * 
 * @param range Range
 * @return DocumentFragment (must be released), or NULL on error
 */
DOMDocumentFragment* dom_range_extractcontents(DOMRange* range);

/**
 * Clone contents into DocumentFragment.
 * 
 * @param range Range
 * @return DocumentFragment (must be released), or NULL on error
 */
DOMDocumentFragment* dom_range_clonecontents(DOMRange* range);

/**
 * Insert node at range start.
 * 
 * @param range Range
 * @param node Node to insert
 * @return 0 on success, error code on failure
 */
int32_t dom_range_insertnode(DOMRange* range, DOMNode* node);

/**
 * Surround contents with new parent.
 * 
 * @param range Range
 * @param new_parent New parent node
 * @return 0 on success, error code on failure
 */
int32_t dom_range_surroundcontents(DOMRange* range, DOMNode* new_parent);

/**
 * Clone the range.
 * 
 * @param range Range
 * @return Cloned range (must be released), or NULL on error
 */
DOMRange* dom_range_clonerange(DOMRange* range);

/**
 * Detach the range (no-op, legacy method).
 * 
 * @param range Range
 */
void dom_range_detach(DOMRange* range);

/**
 * Convert range to string (stringifier).
 * 
 * Returns the text content of the range. For text nodes and elements,
 * this concatenates all text within the range boundaries.
 * 
 * The returned string is owned by the caller and MUST be freed using
 * dom_range_free_tostring().
 * 
 * @param range Range handle
 * @return Null-terminated string (NULL on error)
 * 
 * Example:
 *   DOMRange* range = dom_document_createrange(doc);
 *   dom_range_setstart(range, textNode, 0);
 *   dom_range_setend(range, textNode, 5);
 *   
 *   const char* text = dom_range_tostring(range);
 *   if (text) {
 *       printf("Range text: %s\n", text);
 *       dom_range_free_tostring(text);
 *   }
 *   
 *   dom_range_release(range);
 */
const char* dom_range_tostring(DOMRange* range);

/**
 * Free string returned by dom_range_tostring().
 * 
 * Frees the string returned by dom_range_tostring().
 * MUST be called to avoid memory leaks.
 * 
 * @param str String returned by dom_range_tostring()
 * 
 * Example:
 *   const char* text = dom_range_tostring(range);
 *   if (text) {
 *       printf("Text: %s\n", text);
 *       dom_range_free_tostring(text);
 *   }
 */
void dom_range_free_tostring(const char* str);

/**
 * Increment range reference count.
 * 
 * @param range Range handle
 */
void dom_range_addref(DOMRange* range);

/**
 * Decrement range reference count.
 * 
 * @param range Range handle
 */
void dom_range_release(DOMRange* range);

/**
 * Release a reference to an element.
 * 
 * @param elem Element
 */
void dom_element_release(DOMElement* elem);

/**
 * Insert an element at a position relative to the target element.
 * 
 * @param target Element to insert relative to
 * @param where Position: "beforebegin", "afterbegin", "beforeend", "afterend"
 * @param element Element to insert
 * @return The inserted element, or NULL if insertion failed
 * 
 * Positions:
 * - "beforebegin": Before target (requires parent)
 * - "afterbegin": As first child of target
 * - "beforeend": As last child of target
 * - "afterend": After target (requires parent)
 */
DOMElement* dom_element_insertadjacentelement(DOMElement* target, const char* where, DOMElement* element);

/**
 * Insert text at a position relative to the target element.
 * 
 * @param target Element to insert relative to
 * @param where Position: "beforebegin", "afterbegin", "beforeend", "afterend"
 * @param data Text content to insert
 * @return 0 on success, error code on failure
 * 
 * Positions:
 * - "beforebegin": Before target (requires parent, no-op if no parent)
 * - "afterbegin": As first child of target
 * - "beforeend": As last child of target
 * - "afterend": After target (requires parent, no-op if no parent)
 */
int32_t dom_element_insertadjacenttext(DOMElement* target, const char* where, const char* data);

/* ============================================================================
 * DOMTokenList Interface (Element.classList)
 * ========================================================================= */

/**
 * Get element tag name.
 * 
 * @param elem Element
 * @return Tag name (do NOT free, valid until element is released)
 */
const char* dom_element_get_tagname(DOMElement* elem);

/**
 * Get element namespace URI.
 * 
 * @param elem Element
 * @return Namespace URI or NULL (do NOT free)
 */
const char* dom_element_get_namespaceuri(DOMElement* elem);

/**
 * Get element namespace prefix.
 * 
 * @param elem Element
 * @return Prefix or NULL (do NOT free)
 */
const char* dom_element_get_prefix(DOMElement* elem);

/**
 * Get element local name.
 * 
 * @param elem Element
 * @return Local name (do NOT free)
 */
const char* dom_element_get_localname(DOMElement* elem);

/**
 * Get element ID attribute.
 * 
 * @param elem Element
 * @return ID value or empty string (do NOT free)
 */
const char* dom_element_get_id(DOMElement* elem);

/**
 * Set element ID attribute.
 * 
 * @param elem Element
 * @param id New ID value
 * @return 0 on success, error code on failure
 */
int32_t dom_element_set_id(DOMElement* elem, const char* id);

/**
 * Get element class attribute.
 * 
 * @param elem Element
 * @return Class value or empty string (do NOT free)
 */
const char* dom_element_get_classname(DOMElement* elem);

/**
 * Set element class attribute.
 * 
 * @param elem Element
 * @param className New class value
 * @return 0 on success, error code on failure
 */
int32_t dom_element_set_classname(DOMElement* elem, const char* className);

/**
 * Get an attribute value.
 * 
 * @param elem Element
 * @param qualifiedName Attribute name
 * @return Attribute value or NULL if not present (do NOT free)
 * 
 * Example:
 *   const char* id = dom_element_getattribute(elem, "id");
 *   if (id != NULL) {
 *     printf("ID: %s\n", id);
 *   }
 */
const char* dom_element_getattribute(DOMElement* elem, const char* qualifiedName);

/**
 * Set an attribute value.
 * 
 * @param elem Element
 * @param qualifiedName Attribute name
 * @param value Attribute value
 * @return 0 on success, error code on failure
 * 
 * Example:
 *   int err = dom_element_setattribute(elem, "id", "container");
 *   if (err != 0) {
 *     fprintf(stderr, "Error: %s\n", dom_error_code_message(err));
 *   }
 */
int32_t dom_element_setattribute(DOMElement* elem, const char* qualifiedName, const char* value);

/**
 * Remove an attribute.
 * 
 * @param elem Element
 * @param qualifiedName Attribute name
 * @return 0 on success, error code on failure
 */
int32_t dom_element_removeattribute(DOMElement* elem, const char* qualifiedName);

/**
 * Check if element has an attribute.
 * 
 * @param elem Element
 * @param qualifiedName Attribute name
 * @return 1 if present, 0 if not present
 */
uint8_t dom_element_hasattribute(DOMElement* elem, const char* qualifiedName);

/**
 * Toggle an attribute.
 * 
 * If force is 0, toggles normally (add if missing, remove if present).
 * If force is 1, adds the attribute.
 * If force is 2, removes the attribute.
 * 
 * @param elem Element
 * @param qualifiedName Attribute name
 * @param force Toggle behavior (0 = toggle, 1 = force add, 2 = force remove)
 * @return 1 if attribute is present after operation, 0 if not
 */
uint8_t dom_element_toggleattribute(DOMElement* elem, const char* qualifiedName, uint8_t force);

/**
 * Get namespaced attribute value.
 * 
 * @param elem Element
 * @param namespace Namespace URI (can be NULL)
 * @param localName Local attribute name
 * @return Attribute value or NULL (do NOT free)
 */
const char* dom_element_getattributens(DOMElement* elem, const char* ns, const char* localName);

/**
 * Set namespaced attribute value.
 * 
 * @param elem Element
 * @param namespace Namespace URI (can be NULL)
 * @param qualifiedName Qualified name (e.g., "xml:lang")
 * @param value Attribute value
 * @return 0 on success, error code on failure
 */
int32_t dom_element_setattributens(DOMElement* elem, const char* ns, const char* qualifiedName, const char* value);

/**
 * Remove namespaced attribute.
 * 
 * @param elem Element
 * @param namespace Namespace URI (can be NULL)
 * @param localName Local attribute name
 * @return 0 on success, error code on failure
 */
int32_t dom_element_removeattributens(DOMElement* elem, const char* ns, const char* localName);

/**
 * Check if element has namespaced attribute.
 * 
 * @param elem Element
 * @param namespace Namespace URI (can be NULL)
 * @param localName Local attribute name
 * @return 1 if present, 0 if not present
 */
uint8_t dom_element_hasattributens(DOMElement* elem, const char* ns, const char* localName);

/**
 * Check if element has any attributes.
 * 
 * @param elem Element
 * @return 1 if has attributes, 0 if not
 */
uint8_t dom_element_hasattributes(DOMElement* elem);

/**
 * Get array of all attribute names.
 * 
 * Returns an array of all qualified attribute names on the element.
 * The returned array is owned by the caller and MUST be freed using
 * dom_element_free_attributenames().
 * 
 * @param elem Element handle
 * @param count Pointer to store the number of attribute names
 * @return Array of null-terminated attribute name strings (NULL if no attributes or error)
 * 
 * Example:
 *   uint32_t count;
 *   const char** names = dom_element_getattributenames(elem, &count);
 *   if (names) {
 *       printf("Element has %u attributes:\n", count);
 *       for (uint32_t i = 0; i < count; i++) {
 *           printf("  - %s\n", names[i]);
 *       }
 *       dom_element_free_attributenames(names, count);
 *   }
 */
const char** dom_element_getattributenames(DOMElement* elem, uint32_t* count);

/**
 * Free attribute names array.
 * 
 * Frees the array returned by dom_element_getattributenames().
 * MUST be called to avoid memory leaks.
 * 
 * @param names Array of attribute names (from dom_element_getattributenames)
 * @param count Number of names in array
 * 
 * Example:
 *   uint32_t count;
 *   const char** names = dom_element_getattributenames(elem, &count);
 *   if (names) {
 *       // ... use names ...
 *       dom_element_free_attributenames(names, count);
 *   }
 */
void dom_element_free_attributenames(const char** names, uint32_t count);

/**
 * Get the slot attribute (Slottable mixin).
 * 
 * Returns the value of the "slot" attribute, which specifies which slot
 * in a shadow tree this element should be assigned to.
 * 
 * @param elem Element handle
 * @return Slot name (empty string if not set, do NOT free)
 * 
 * Example:
 *   const char* slot_name = dom_element_get_slot(elem);
 *   printf("Element slot: %s\n", slot_name);
 */
const char* dom_element_get_slot(DOMElement* elem);

/**
 * Set the slot attribute (Slottable mixin).
 * 
 * Sets the "slot" attribute, which specifies which slot in a shadow tree
 * this element should be assigned to. Setting the slot attribute reassigns
 * the element to the new slot.
 * 
 * @param elem Element handle
 * @param value Slot name (use "" to remove slot attribute)
 * @return 0 on success, error code on failure
 * 
 * Example:
 *   // Assign element to "header" slot
 *   int err = dom_element_set_slot(elem, "header");
 *   if (err != 0) {
 *       fprintf(stderr, "Error: %s\n", dom_error_code_message(err));
 *   }
 *   
 *   // Remove slot assignment
 *   dom_element_set_slot(elem, "");
 */
int32_t dom_element_set_slot(DOMElement* elem, const char* value);

/**
 * Get the assigned slot element (Slottable mixin).
 * 
 * Returns the <slot> element that this element is assigned to in a shadow tree.
 * Returns NULL if the element is not assigned to any slot.
 * 
 * @param elem Element handle
 * @return Slot element or NULL (do NOT release)
 * 
 * Example:
 *   DOMElement* slot = dom_element_get_assignedslot(elem);
 *   if (slot) {
 *       const char* name = dom_element_getattribute(slot, "name");
 *       printf("Assigned to slot: %s\n", name ? name : "(default)");
 *   } else {
 *       printf("Not assigned to any slot\n");
 *   }
 */
DOMElement* dom_element_get_assignedslot(DOMElement* elem);

/**
 * Test if element matches a CSS selector.
 * 
 * Returns true if the element would be selected by the specified selector string.
 * 
 * @param elem Element
 * @param selectors CSS selector string (e.g., ".class", "#id", "div.class")
 * @return 1 if matches, 0 if not
 * 
 * Example:
 *   if (dom_element_matches(elem, ".active")) {
 *     printf("Element has 'active' class\n");
 *   }
 */
uint8_t dom_element_matches(DOMElement* elem, const char* selectors);

/**
 * Find closest ancestor element matching a selector.
 * 
 * Traverses the element and its parents (heading toward document root)
 * until it finds a node that matches the specified CSS selector.
 * 
 * @param elem Element to start from
 * @param selectors CSS selector string
 * @return Matching element or NULL if not found
 * 
 * Example:
 *   DOMElement* container = dom_element_closest(elem, ".container");
 *   if (container) {
 *     printf("Found container ancestor\n");
 *   }
 */
DOMElement* dom_element_closest(DOMElement* elem, const char* selectors);

/**
 * Webkit prefixed version of matches() for compatibility.
 * 
 * @param elem Element
 * @param selectors CSS selector string
 * @return 1 if matches, 0 if not
 */
uint8_t dom_element_webkitmatchesselector(DOMElement* elem, const char* selectors);

/**
 * Find first descendant element matching a CSS selector.
 * 
 * Searches the element's descendants for an element matching the CSS selector.
 * 
 * @param elem Element to search within
 * @param selectors CSS selector string
 * @return First matching descendant or NULL if not found
 * 
 * Example:
 *   DOMElement* input = dom_element_queryselector(form, "input[type='text']");
 *   if (input) {
 *     printf("Found text input\n");
 *   }
 */
DOMElement* dom_element_queryselector(DOMElement* elem, const char* selectors);

/**
 * Find all descendant elements matching a CSS selector.
 * 
 * Returns a static snapshot of all descendant elements matching the selector.
 * The list does NOT update when the DOM changes (not live).
 * 
 * @param elem Element to search within
 * @param selectors CSS selector string
 * @return Static NodeList or NULL if no matches or error
 * 
 * Example:
 *   DOMNodeList* items = dom_element_queryselectorall(list, ".list-item");
 *   if (items) {
 *       uint32_t count = dom_nodelist_static_get_length(items);
 *       for (uint32_t i = 0; i < count; i++) {
 *           DOMNode* node = dom_nodelist_static_item(items, i);
 *           // Process item
 *       }
 *       dom_nodelist_static_release(items);
 *   }
 */
DOMNodeList* dom_element_queryselectorall(DOMElement* elem, const char* selectors);

/**
 * Increment element reference count.
 * 
 * @param elem Element
 */
void dom_element_addref(DOMElement* elem);

/**
 * Decrement element reference count.
 * 
 * When ref_count reaches 0, the element is freed.
 * This also releases all child nodes.
 * 
 * @param elem Element
 */
void dom_element_release(DOMElement* elem);

/* ============================================================================
 * DOMTokenList Interface (Element.classList)
 * ========================================================================= */

/**
 * Get the classList (DOMTokenList) for an element.
 * 
 * Returns a live collection of class tokens on the element.
 * 
 * @param elem Element
 * @return DOMTokenList (must be released by caller)
 * 
 * Example:
 *   DOMDOMTokenList* classList = dom_element_get_classlist(elem);
 *   dom_domtokenlist_add(classList, ...);
 *   dom_domtokenlist_release(classList);
 */
DOMDOMTokenList* dom_element_get_classlist(DOMElement* elem);

/**
 * Get the number of tokens in the list.
 * 
 * @param list DOMTokenList
 * @return Number of unique tokens
 */
uint32_t dom_domtokenlist_get_length(DOMDOMTokenList* list);

/**
 * Get the value attribute (space-separated token string).
 * 
 * @param list DOMTokenList
 * @return Token string (do NOT free)
 */
const char* dom_domtokenlist_get_value(DOMDOMTokenList* list);

/**
 * Set the value attribute (replace all tokens).
 * 
 * @param list DOMTokenList
 * @param value Space-separated token string
 * @return 0 on success, error code on failure
 */
int32_t dom_domtokenlist_set_value(DOMDOMTokenList* list, const char* value);

/**
 * Get a token at a specific index.
 * 
 * @param list DOMTokenList
 * @param index Zero-based index
 * @return Token at index (do NOT free), or NULL if out of bounds
 */
const char* dom_domtokenlist_item(DOMDOMTokenList* list, uint32_t index);

/**
 * Check if a token exists in the list.
 * 
 * @param list DOMTokenList
 * @param token Token to search for
 * @return 1 if exists, 0 otherwise
 */
uint8_t dom_domtokenlist_contains(DOMDOMTokenList* list, const char* token);

/**
 * Check if a token is supported (validation).
 * 
 * For classList, always returns 1 (no validation).
 * 
 * @param list DOMTokenList
 * @param token Token to validate
 * @return 1 if supported, 0 otherwise
 */
uint8_t dom_domtokenlist_supports(DOMDOMTokenList* list, const char* token);

/**
 * Add one or more tokens to the list.
 * 
 * Duplicates are ignored (ordered set behavior).
 * 
 * @param list DOMTokenList
 * @param tokens Array of token strings
 * @param count Number of tokens in array
 * @return 0 on success, error code on failure
 * 
 * Example:
 *   const char* tokens[] = {"btn", "btn-primary", "active"};
 *   dom_domtokenlist_add(classList, tokens, 3);
 */
int32_t dom_domtokenlist_add(DOMDOMTokenList* list, const char** tokens, uint32_t count);

/**
 * Remove one or more tokens from the list.
 * 
 * Non-existent tokens are ignored.
 * 
 * @param list DOMTokenList
 * @param tokens Array of token strings
 * @param count Number of tokens in array
 * @return 0 on success, error code on failure
 * 
 * Example:
 *   const char* tokens[] = {"active", "disabled"};
 *   dom_domtokenlist_remove(classList, tokens, 2);
 */
int32_t dom_domtokenlist_remove(DOMDOMTokenList* list, const char** tokens, uint32_t count);

/**
 * Toggle a token in the list.
 * 
 * If token exists, removes it and returns 0.
 * If token doesn't exist, adds it and returns 1.
 * Optional force parameter: 1 = always add, 0 = always remove, -1 = toggle.
 * 
 * @param list DOMTokenList
 * @param token Token to toggle
 * @param force -1 = toggle, 0 = force remove, 1 = force add
 * @return 1 if token is now present, 0 if now absent
 * 
 * Example:
 *   // Toggle (add if absent, remove if present)
 *   uint8_t is_active = dom_domtokenlist_toggle(classList, "active", -1);
 *   
 *   // Force add
 *   dom_domtokenlist_toggle(classList, "enabled", 1);
 *   
 *   // Force remove
 *   dom_domtokenlist_toggle(classList, "disabled", 0);
 */
uint8_t dom_domtokenlist_toggle(DOMDOMTokenList* list, const char* token, int8_t force);

/**
 * Replace a token with a new token.
 * 
 * @param list DOMTokenList
 * @param token Token to replace
 * @param newToken Replacement token
 * @return 1 if replacement occurred, 0 if token didn't exist
 * 
 * Example:
 *   if (dom_domtokenlist_replace(classList, "btn-primary", "btn-secondary")) {
 *     printf("Replaced primary with secondary\n");
 *   }
 */
uint8_t dom_domtokenlist_replace(DOMDOMTokenList* list, const char* token, const char* newToken);

/**
 * Release a DOMTokenList.
 * 
 * DOMTokenList is a value type but heap-allocated for C interop.
 * Call this when done with a DOMTokenList returned from the API.
 * 
 * @param list DOMTokenList to release
 * 
 * Note: Releasing the list does NOT affect the element's class attribute.
 */
void dom_domtokenlist_release(DOMDOMTokenList* list);

/* ============================================================================
 * Node Interface
 * ========================================================================= */

/**
 * Get node type.
 * 
 * @param node Node
 * @return Node type constant (DOM_ELEMENT_NODE, etc.)
 */
uint16_t dom_node_get_nodetype(DOMNode* node);

/**
 * Get node name.
 * 
 * For elements, this is the tag name.
 * For text nodes, this is "#text".
 * 
 * @param node Node
 * @return Node name (do NOT free)
 */
const char* dom_node_get_nodename(DOMNode* node);

/**
 * Get node value.
 * 
 * For text/comment nodes, returns the text content.
 * For elements, returns NULL.
 * 
 * @param node Node
 * @return Node value or NULL (do NOT free)
 */
const char* dom_node_get_nodevalue(DOMNode* node);

/**
 * Set node value.
 * 
 * @param node Node
 * @param value New value (can be NULL)
 * @return 0 on success, error code on failure
 */
int32_t dom_node_set_nodevalue(DOMNode* node, const char* value);

/**
 * Get parent node.
 * 
 * @param node Node
 * @return Parent node or NULL (do NOT release)
 */
DOMNode* dom_node_get_parentnode(DOMNode* node);

/**
 * Get parent element.
 * 
 * Returns parent only if it's an element node.
 * 
 * @param node Node
 * @return Parent element or NULL (do NOT release)
 */
DOMElement* dom_node_get_parentelement(DOMNode* node);

/**
 * Get first child node.
 * 
 * @param node Node
 * @return First child or NULL (do NOT release)
 */
DOMNode* dom_node_get_firstchild(DOMNode* node);

/**
 * Get last child node.
 * 
 * @param node Node
 * @return Last child or NULL (do NOT release)
 */
DOMNode* dom_node_get_lastchild(DOMNode* node);

/**
 * Get previous sibling node.
 * 
 * @param node Node
 * @return Previous sibling or NULL (do NOT release)
 */
DOMNode* dom_node_get_previoussibling(DOMNode* node);

/**
 * Get next sibling node.
 * 
 * @param node Node
 * @return Next sibling or NULL (do NOT release)
 */
DOMNode* dom_node_get_nextsibling(DOMNode* node);

/**
 * Get owner document.
 * 
 * @param node Node
 * @return Owner document or NULL (do NOT release)
 */
DOMDocument* dom_node_get_ownerdocument(DOMNode* node);

/**
 * Check if node is connected to a document.
 * 
 * Returns true if the node is in a document tree (has a document ancestor).
 * 
 * @param node Node
 * @return 1 if connected, 0 if not
 */
uint8_t dom_node_get_isconnected(DOMNode* node);

/**
 * Get the text content of the node and its descendants.
 * 
 * Returns all text contained in the node's subtree, concatenated together.
 * For text nodes, returns the data. For elements, returns concatenated text
 * of all descendant text nodes.
 * 
 * @param node Node
 * @return Text content (borrowed reference, may be empty string), never NULL
 */
const char* dom_node_get_textcontent(DOMNode* node);

/**
 * Set the text content of the node.
 * 
 * Removes all children and replaces with a single text node containing the value,
 * or removes all children if value is NULL.
 * 
 * @param node Node
 * @param value Text content to set (NULL to remove all children)
 * @return 0 on success, error code on failure
 */
int32_t dom_node_set_textcontent(DOMNode* node, const char* value);

/**
 * Get the root node of the tree.
 * 
 * Returns the root of the tree containing this node.
 * 
 * @param node Node
 * @param composed If non-zero, pierces shadow boundaries; if zero, stops at shadow root
 * @return Root node (never NULL, borrowed reference)
 * 
 * Example:
 *   // Get root without piercing shadow boundaries (default)
 *   DOMNode* root = dom_node_getrootnode(node, 0);
 *   
 *   // Get root, traversing through shadow boundaries
 *   DOMNode* doc = dom_node_getrootnode(shadow_child, 1);
 */
DOMNode* dom_node_getrootnode(DOMNode* node, uint8_t composed);

/**
 * Check if node has child nodes.
 * 
 * @param node Node
 * @return 1 if has children, 0 if not
 */
uint8_t dom_node_haschildnodes(DOMNode* node);

/**
 * Check if this node contains another node.
 * 
 * A node contains itself and all its descendants.
 * 
 * @param node Node
 * @param other Node to check
 * @return 1 if contains, 0 if not
 */
uint8_t dom_node_contains(DOMNode* node, DOMNode* other);

/**
 * Append a child node.
 * 
 * The parent takes ownership of the child.
 * When the parent is released, the child is also released.
 * 
 * @param parent Parent node
 * @param child Child node to append
 * @return The appended child (do NOT release separately)
 * 
 * Example:
 *   DOMElement* div = dom_document_createelement(doc, "div");
 *   DOMElement* span = dom_document_createelement(doc, "span");
 *   dom_node_appendchild((DOMNode*)div, (DOMNode*)span);
 *   // Only release div - it will release span automatically
 *   dom_element_release(div);
 */
DOMNode* dom_node_appendchild(DOMNode* parent, DOMNode* child);

/**
 * Insert a child node before a reference node.
 * 
 * @param parent Parent node
 * @param node Node to insert
 * @param child Reference node (insert before this)
 * @return The inserted node (do NOT release separately)
 */
DOMNode* dom_node_insertbefore(DOMNode* parent, DOMNode* node, DOMNode* child);

/**
 * Remove a child node.
 * 
 * After removal, you must call dom_node_release() on the child.
 * 
 * @param parent Parent node
 * @param child Child node to remove
 * @return The removed child (must be released by caller)
 */
DOMNode* dom_node_removechild(DOMNode* parent, DOMNode* child);

/**
 * Replace a child node.
 * 
 * @param parent Parent node
 * @param node New node
 * @param child Old node to replace
 * @return The replaced child (must be released by caller)
 */
DOMNode* dom_node_replacechild(DOMNode* parent, DOMNode* node, DOMNode* child);

/**
 * Clone a node.
 * 
 * @param node Node to clone
 * @param deep If 1, clone descendants too; if 0, shallow clone
 * @return Cloned node (must be released by caller)
 */
DOMNode* dom_node_clonenode(DOMNode* node, uint8_t deep);

/**
 * Check if two nodes are the same (identity check).
 * 
 * @param node First node
 * @param other Second node
 * @return 1 if same, 0 if not
 */
uint8_t dom_node_issamenode(DOMNode* node, DOMNode* other);

/**
 * Check if two nodes are equal (value check).
 * 
 * @param node First node
 * @param other Second node
 * @return 1 if equal, 0 if not
 */
uint8_t dom_node_isequalnode(DOMNode* node, DOMNode* other);

/**
 * Normalize the node tree.
 * 
 * Merges adjacent text nodes and removes empty text nodes.
 * 
 * @param node Node
 * @return 0 on success, error code on failure
 */
int32_t dom_node_normalize(DOMNode* node);

/**
 * Increment node reference count.
 * 
 * @param node Node
 */
void dom_node_addref(DOMNode* node);

/**
 * Decrement node reference count.
 * 
 * @param node Node
 */
void dom_node_release(DOMNode* node);

// ============================================================================
// MutationObserver
// ============================================================================

typedef struct DOMMutationObserver DOMMutationObserver;
typedef struct DOMMutationRecord DOMMutationRecord;

/**
 * C callback function type for MutationObserver.
 * 
 * Called when mutations are observed.
 * 
 * @param records Array of mutation record pointers
 * @param record_count Number of records in array
 * @param observer The MutationObserver instance
 * @param context User-provided context pointer
 */
typedef void (*DOMMutationCallback)(
    DOMMutationRecord** records,
    uint32_t record_count,
    DOMMutationObserver* observer,
    void* context
);

/**
 * Options for observing mutations.
 * 
 * Corresponds to MutationObserverInit dictionary in WebIDL.
 * Use 255 for undefined boolean values.
 */
typedef struct {
    uint8_t child_list;              /* 0=false, 1=true */
    uint8_t attributes;              /* 0=false, 1=true, 255=undefined */
    uint8_t character_data;          /* 0=false, 1=true, 255=undefined */
    uint8_t subtree;                 /* 0=false, 1=true */
    uint8_t attribute_old_value;     /* 0=false, 1=true, 255=undefined */
    uint8_t character_data_old_value; /* 0=false, 1=true, 255=undefined */
    const char** attribute_filter;   /* null-terminated array of strings, or NULL */
} DOMMutationObserverInit;

/**
 * Create a new MutationObserver.
 * 
 * @param callback C function to call when mutations occur
 * @param context User-provided context pointer (passed to callback)
 * @return MutationObserver handle, or NULL on failure
 */
DOMMutationObserver* dom_mutationobserver_new(DOMMutationCallback callback, void* context);

/**
 * Observe a target node for mutations.
 * 
 * @param observer MutationObserver handle
 * @param target Node to observe
 * @param options Options specifying what to observe
 * @return 0 on success, error code on failure
 */
int32_t dom_mutationobserver_observe(
    DOMMutationObserver* observer,
    DOMNode* target,
    const DOMMutationObserverInit* options
);

/**
 * Stop observing all targets.
 * 
 * @param observer MutationObserver handle
 */
void dom_mutationobserver_disconnect(DOMMutationObserver* observer);

/**
 * Take all pending mutation records.
 * 
 * Returns array of records and clears the observer's record queue.
 * 
 * @param observer MutationObserver handle
 * @param out_count Pointer to store number of records
 * @return Array of record pointers, or NULL if none
 */
DOMMutationRecord** dom_mutationobserver_takerecords(
    DOMMutationObserver* observer,
    uint32_t* out_count
);

/**
 * Release a MutationObserver.
 * 
 * @param observer MutationObserver handle
 */
void dom_mutationobserver_release(DOMMutationObserver* observer);

// MutationRecord accessors

/**
 * Get the mutation type.
 * 
 * @param record MutationRecord handle
 * @return "attributes", "characterData", or "childList"
 */
const char* dom_mutationrecord_get_type(const DOMMutationRecord* record);

/**
 * Get the target node that was mutated.
 * 
 * @param record MutationRecord handle
 * @return Target node
 */
DOMNode* dom_mutationrecord_get_target(const DOMMutationRecord* record);

/**
 * Get the nodes added (for childList mutations).
 * 
 * @param record MutationRecord handle
 * @param out_count Pointer to store number of nodes
 * @return Array of node pointers, or NULL if none
 */
DOMNode** dom_mutationrecord_get_addednodes(const DOMMutationRecord* record, uint32_t* out_count);

/**
 * Get the nodes removed (for childList mutations).
 * 
 * @param record MutationRecord handle
 * @param out_count Pointer to store number of nodes
 * @return Array of node pointers, or NULL if none
 */
DOMNode** dom_mutationrecord_get_removednodes(const DOMMutationRecord* record, uint32_t* out_count);

/**
 * Get the previous sibling (for childList mutations).
 * 
 * @param record MutationRecord handle
 * @return Previous sibling node, or NULL if none
 */
DOMNode* dom_mutationrecord_get_previoussibling(const DOMMutationRecord* record);

/**
 * Get the next sibling (for childList mutations).
 * 
 * @param record MutationRecord handle
 * @return Next sibling node, or NULL if none
 */
DOMNode* dom_mutationrecord_get_nextsibling(const DOMMutationRecord* record);

/**
 * Get the attribute name (for attributes mutations).
 * 
 * @param record MutationRecord handle
 * @return Attribute name, or NULL if not an attribute mutation
 */
const char* dom_mutationrecord_get_attributename(const DOMMutationRecord* record);

/**
 * Get the attribute namespace (for attributes mutations).
 * 
 * @param record MutationRecord handle
 * @return Attribute namespace, or NULL if none
 */
const char* dom_mutationrecord_get_attributenamespace(const DOMMutationRecord* record);

/**
 * Get the old value (for attributes or characterData mutations with oldValue option).
 * 
 * @param record MutationRecord handle
 * @return Old value, or NULL if not captured
 */
const char* dom_mutationrecord_get_oldvalue(const DOMMutationRecord* record);

/**
 * Release a MutationRecord.
 * 
 * @param record MutationRecord handle
 */
void dom_mutationrecord_release(DOMMutationRecord* record);

// ============================================================================
// TreeWalker & NodeFilter Constants
// ============================================================================

typedef struct DOMTreeWalker DOMTreeWalker;

// NodeFilter.SHOW_* constants
#define DOM_NODEFILTER_SHOW_ALL                  0xFFFFFFFF
#define DOM_NODEFILTER_SHOW_ELEMENT              0x1
#define DOM_NODEFILTER_SHOW_ATTRIBUTE            0x2
#define DOM_NODEFILTER_SHOW_TEXT                 0x4
#define DOM_NODEFILTER_SHOW_CDATA_SECTION        0x8
#define DOM_NODEFILTER_SHOW_ENTITY_REFERENCE     0x10
#define DOM_NODEFILTER_SHOW_ENTITY               0x20
#define DOM_NODEFILTER_SHOW_PROCESSING_INSTRUCTION 0x40
#define DOM_NODEFILTER_SHOW_COMMENT              0x80
#define DOM_NODEFILTER_SHOW_DOCUMENT             0x100
#define DOM_NODEFILTER_SHOW_DOCUMENT_TYPE        0x200
#define DOM_NODEFILTER_SHOW_DOCUMENT_FRAGMENT    0x400
#define DOM_NODEFILTER_SHOW_NOTATION             0x800

// TreeWalker properties

/**
 * Get the root node of the tree walker.
 * 
 * @param walker TreeWalker handle
 * @return Root node (never NULL)
 */
DOMNode* dom_treewalker_get_root(const DOMTreeWalker* walker);

/**
 * Get the whatToShow bitmask.
 * 
 * @param walker TreeWalker handle
 * @return Bitmask of node types to show
 */
uint32_t dom_treewalker_get_whattoshow(const DOMTreeWalker* walker);

/**
 * Get the current node.
 * 
 * @param walker TreeWalker handle
 * @return Current node (never NULL)
 */
DOMNode* dom_treewalker_get_currentnode(const DOMTreeWalker* walker);

/**
 * Set the current node.
 * 
 * @param walker TreeWalker handle
 * @param node New current node
 */
void dom_treewalker_set_currentnode(DOMTreeWalker* walker, DOMNode* node);

// TreeWalker navigation methods

/**
 * Navigate to parent node.
 * 
 * @param walker TreeWalker handle
 * @return Parent node, or NULL if none
 */
DOMNode* dom_treewalker_parentnode(DOMTreeWalker* walker);

/**
 * Navigate to first child.
 * 
 * @param walker TreeWalker handle
 * @return First child node, or NULL if none
 */
DOMNode* dom_treewalker_firstchild(DOMTreeWalker* walker);

/**
 * Navigate to last child.
 * 
 * @param walker TreeWalker handle
 * @return Last child node, or NULL if none
 */
DOMNode* dom_treewalker_lastchild(DOMTreeWalker* walker);

/**
 * Navigate to previous sibling.
 * 
 * @param walker TreeWalker handle
 * @return Previous sibling node, or NULL if none
 */
DOMNode* dom_treewalker_previoussibling(DOMTreeWalker* walker);

/**
 * Navigate to next sibling.
 * 
 * @param walker TreeWalker handle
 * @return Next sibling node, or NULL if none
 */
DOMNode* dom_treewalker_nextsibling(DOMTreeWalker* walker);

/**
 * Navigate to previous node in tree order.
 * 
 * @param walker TreeWalker handle
 * @return Previous node, or NULL if none
 */
DOMNode* dom_treewalker_previousnode(DOMTreeWalker* walker);

/**
 * Navigate to next node in tree order.
 * 
 * @param walker TreeWalker handle
 * @return Next node, or NULL if none
 */
DOMNode* dom_treewalker_nextnode(DOMTreeWalker* walker);

/**
 * Release a TreeWalker.
 * 
 * @param walker TreeWalker handle
 */
void dom_treewalker_release(DOMTreeWalker* walker);

// ============================================================================
// NodeIterator
// ============================================================================

/**
 * Get the root node of the iterator.
 * 
 * @param iterator NodeIterator handle
 * @return Root node (never NULL)
 */
DOMNode* dom_nodeiterator_get_root(const DOMNodeIterator* iterator);

/**
 * Get the reference node.
 * 
 * @param iterator NodeIterator handle
 * @return Reference node (current position)
 */
DOMNode* dom_nodeiterator_get_referencenode(const DOMNodeIterator* iterator);

/**
 * Get whether pointer is before reference node.
 * 
 * @param iterator NodeIterator handle
 * @return 1 if before reference node, 0 if after
 */
uint8_t dom_nodeiterator_get_pointerbeforereferencenode(const DOMNodeIterator* iterator);

/**
 * Get the whatToShow bitmask.
 * 
 * @param iterator NodeIterator handle
 * @return Bitmask of node types to show
 */
uint32_t dom_nodeiterator_get_whattoshow(const DOMNodeIterator* iterator);

/**
 * Navigate to next node.
 * 
 * @param iterator NodeIterator handle
 * @return Next node, or NULL if at end
 */
DOMNode* dom_nodeiterator_nextnode(DOMNodeIterator* iterator);

/**
 * Navigate to previous node.
 * 
 * @param iterator NodeIterator handle
 * @return Previous node, or NULL if at beginning
 */
DOMNode* dom_nodeiterator_previousnode(DOMNodeIterator* iterator);

/**
 * Detach the iterator (no-op per spec).
 * 
 * @param iterator NodeIterator handle
 */
void dom_nodeiterator_detach(DOMNodeIterator* iterator);

/**
 * Release a NodeIterator.
 * 
 * @param iterator NodeIterator handle
 */
void dom_nodeiterator_release(DOMNodeIterator* iterator);

// ============================================================================
// ChildNode Mixin
// ============================================================================

/**
 * Insert nodes before this node.
 * 
 * @param child Node to insert before
 * @param nodes Array of nodes to insert
 * @param count Number of nodes in array
 * @return 0 on success, error code on failure
 */
int32_t dom_childnode_before(DOMNode* child, DOMNode** nodes, uint32_t count);

/**
 * Insert nodes after this node.
 * 
 * @param child Node to insert after
 * @param nodes Array of nodes to insert
 * @param count Number of nodes in array
 * @return 0 on success, error code on failure
 */
int32_t dom_childnode_after(DOMNode* child, DOMNode** nodes, uint32_t count);

/**
 * Replace this node with other nodes.
 * 
 * @param child Node to replace
 * @param nodes Array of replacement nodes
 * @param count Number of nodes in array
 * @return 0 on success, error code on failure
 */
int32_t dom_childnode_replacewith(DOMNode* child, DOMNode** nodes, uint32_t count);

/**
 * Remove this node from its parent.
 * 
 * @param child Node to remove
 */
void dom_childnode_remove(DOMNode* child);

// ============================================================================
// ParentNode Mixin
// ============================================================================

/**
 * Prepend nodes at the beginning of this node's children.
 * 
 * @param parent Node to prepend to (must be Element, Document, or DocumentFragment)
 * @param nodes Array of nodes to prepend
 * @param count Number of nodes in array
 * @return 0 on success, error code on failure
 */
int32_t dom_parentnode_prepend(DOMNode* parent, DOMNode** nodes, uint32_t count);

/**
 * Append nodes at the end of this node's children.
 * 
 * @param parent Node to append to (must be Element, Document, or DocumentFragment)
 * @param nodes Array of nodes to append
 * @param count Number of nodes in array
 * @return 0 on success, error code on failure
 */
int32_t dom_parentnode_append(DOMNode* parent, DOMNode** nodes, uint32_t count);

/**
 * Replace all children with new nodes.
 * 
 * @param parent Node whose children to replace (must be Element, Document, or DocumentFragment)
 * @param nodes Array of replacement nodes
 * @param count Number of nodes in array
 * @return 0 on success, error code on failure
 */
int32_t dom_parentnode_replacechildren(DOMNode* parent, DOMNode** nodes, uint32_t count);

// ============================================================================
// HTMLCollection
// ============================================================================

/**
 * Get the length of an HTMLCollection.
 * 
 * Returns the number of elements in the collection. This is a live count that
 * reflects the current state of the DOM (elements only, no text/comment nodes).
 * 
 * @param collection HTMLCollection handle
 * @return Number of elements in the collection
 * 
 * Example:
 *   DOMHTMLCollection* children = dom_element_get_children(parent);
 *   uint32_t count = dom_htmlcollection_get_length(children);
 *   printf("Parent has %u element children\n", count);
 *   dom_htmlcollection_release(children);
 */
uint32_t dom_htmlcollection_get_length(DOMHTMLCollection* collection);

/**
 * Get an element at a specific index in the collection.
 * 
 * Returns the element at the specified index, or NULL if the index is out of bounds.
 * This is a live view - the returned element reflects the current DOM state.
 * 
 * @param collection HTMLCollection handle
 * @param index Zero-based index
 * @return Element at index or NULL if out of bounds
 * 
 * Example:
 *   DOMHTMLCollection* children = dom_element_get_children(parent);
 *   uint32_t count = dom_htmlcollection_get_length(children);
 *   for (uint32_t i = 0; i < count; i++) {
 *       DOMElement* child = dom_htmlcollection_item(children, i);
 *       if (child != NULL) {
 *           const char* tag = dom_element_get_tagname(child);
 *           printf("Child %u: %s\n", i, tag);
 *       }
 *   }
 *   dom_htmlcollection_release(children);
 */
DOMElement* dom_htmlcollection_item(DOMHTMLCollection* collection, uint32_t index);

/**
 * Get an element by its id or name attribute.
 * 
 * Returns the first element in the collection with the specified id or name attribute.
 * This provides named access to collection items.
 * 
 * @param collection HTMLCollection handle
 * @param name Value to match against id or name attributes
 * @return First element with matching id or name, or NULL if not found
 * 
 * Example:
 *   DOMHTMLCollection* children = dom_element_get_children(parent);
 *   DOMElement* item = dom_htmlcollection_nameditem(children, "myElement");
 *   if (item != NULL) {
 *       printf("Found element with id or name 'myElement'\n");
 *   }
 *   dom_htmlcollection_release(children);
 */
DOMElement* dom_htmlcollection_nameditem(DOMHTMLCollection* collection, const char* name);

/**
 * Release an HTMLCollection.
 * 
 * Call this when done with an HTMLCollection returned from the API.
 * Note: Releasing the collection does NOT release the elements themselves.
 * 
 * @param collection HTMLCollection handle to release
 * 
 * Example:
 *   DOMHTMLCollection* children = dom_element_get_children(parent);
 *   // ... use children ...
 *   dom_htmlcollection_release(children);
 */
void dom_htmlcollection_release(DOMHTMLCollection* collection);

// ============================================================================
// Shadow DOM
// ============================================================================

/**
 * Shadow root mode constants.
 * 
 * Mode controls JavaScript access to the shadow root:
 * - DOM_SHADOWROOT_MODE_OPEN (0): Element.shadowRoot returns the shadow root
 * - DOM_SHADOWROOT_MODE_CLOSED (1): Element.shadowRoot returns NULL
 */
#define DOM_SHADOWROOT_MODE_OPEN 0
#define DOM_SHADOWROOT_MODE_CLOSED 1

/**
 * Slot assignment mode constants.
 * 
 * - DOM_SLOTASSIGNMENT_NAMED (0): Automatic slot assignment (default)
 * - DOM_SLOTASSIGNMENT_MANUAL (1): Manual slot assignment via HTMLSlotElement.assign()
 */
#define DOM_SLOTASSIGNMENT_NAMED 0
#define DOM_SLOTASSIGNMENT_MANUAL 1

/**
 * Attach a shadow root to an element.
 * 
 * Creates a new shadow root for Shadow DOM encapsulation. Each element can only
 * have one shadow root - subsequent calls return NULL.
 * 
 * @param element Element to attach shadow root to
 * @param mode Shadow mode (DOM_SHADOWROOT_MODE_OPEN or DOM_SHADOWROOT_MODE_CLOSED)
 * @param delegates_focus Whether to delegate focus to first focusable element
 * @return Shadow root handle or NULL if already has shadow root
 * 
 * Example:
 *   // Open mode - shadowRoot is accessible
 *   DOMShadowRoot* shadow = dom_element_attachshadow(elem, DOM_SHADOWROOT_MODE_OPEN, false);
 *   if (shadow != NULL) {
 *       // Add content to shadow tree
 *       DOMElement* content = dom_document_createelement(doc, "content");
 *       dom_node_appendchild((DOMNode*)shadow, (DOMNode*)content);
 *   }
 * 
 *   // Closed mode - shadowRoot hidden from JavaScript
 *   DOMShadowRoot* closed = dom_element_attachshadow(elem2, DOM_SHADOWROOT_MODE_CLOSED, false);
 */
DOMShadowRoot* dom_element_attachshadow(DOMElement* element, int mode, bool delegates_focus);

/**
 * Get the element's shadow root (if mode is open).
 * 
 * Returns the shadow root if attached and mode is open, NULL otherwise.
 * This enforces the open/closed mode distinction per the Shadow DOM spec.
 * 
 * @param element Element handle
 * @return Shadow root if mode is open, NULL if closed or no shadow root
 * 
 * Example:
 *   // Open mode - shadowRoot is accessible
 *   DOMShadowRoot* shadow = dom_element_attachshadow(elem, DOM_SHADOWROOT_MODE_OPEN, false);
 *   DOMShadowRoot* check = dom_element_get_shadowroot(elem);
 *   // check == shadow
 * 
 *   // Closed mode - shadowRoot is NULL
 *   dom_element_attachshadow(elem2, DOM_SHADOWROOT_MODE_CLOSED, false);
 *   DOMShadowRoot* closed = dom_element_get_shadowroot(elem2);
 *   // closed == NULL
 */
DOMShadowRoot* dom_element_get_shadowroot(DOMElement* element);

/**
 * Get the shadow root mode.
 * 
 * Returns whether the shadow root is open or closed.
 * 
 * @param shadow Shadow root handle
 * @return DOM_SHADOWROOT_MODE_OPEN (0) or DOM_SHADOWROOT_MODE_CLOSED (1)
 * 
 * Example:
 *   int mode = dom_shadowroot_get_mode(shadow);
 *   if (mode == DOM_SHADOWROOT_MODE_OPEN) {
 *       printf("Shadow root is accessible\n");
 *   }
 */
int dom_shadowroot_get_mode(DOMShadowRoot* shadow);

/**
 * Get the delegatesFocus flag.
 * 
 * Returns whether focus is delegated to the first focusable element in the shadow tree.
 * 
 * @param shadow Shadow root handle
 * @return true if focus is delegated, false otherwise
 * 
 * Example:
 *   if (dom_shadowroot_get_delegatesfocus(shadow)) {
 *       printf("Focus is delegated\n");
 *   }
 */
bool dom_shadowroot_get_delegatesfocus(DOMShadowRoot* shadow);

/**
 * Get the slot assignment mode.
 * 
 * Returns the slot assignment mode for this shadow root.
 * 
 * @param shadow Shadow root handle
 * @return DOM_SLOTASSIGNMENT_NAMED (0) or DOM_SLOTASSIGNMENT_MANUAL (1)
 * 
 * Example:
 *   int mode = dom_shadowroot_get_slotassignment(shadow);
 *   if (mode == DOM_SLOTASSIGNMENT_NAMED) {
 *       printf("Automatic slot assignment\n");
 *   }
 */
int dom_shadowroot_get_slotassignment(DOMShadowRoot* shadow);

/**
 * Get the clonable flag.
 * 
 * Returns whether the shadow root can be cloned with cloneNode().
 * 
 * @param shadow Shadow root handle
 * @return true if clonable, false otherwise
 */
bool dom_shadowroot_get_clonable(DOMShadowRoot* shadow);

/**
 * Get the serializable flag.
 * 
 * Returns whether the shadow root is included in innerHTML serialization.
 * 
 * @param shadow Shadow root handle
 * @return true if serializable, false otherwise
 */
bool dom_shadowroot_get_serializable(DOMShadowRoot* shadow);

/**
 * Get the host element.
 * 
 * Returns the element that hosts this shadow root.
 * 
 * @param shadow Shadow root handle
 * @return Host element (never NULL)
 * 
 * Example:
 *   DOMShadowRoot* shadow = dom_element_attachshadow(elem, DOM_SHADOWROOT_MODE_OPEN, false);
 *   DOMElement* host = dom_shadowroot_get_host(shadow);
 *   // host == elem
 */
DOMElement* dom_shadowroot_get_host(DOMShadowRoot* shadow);

// ============================================================================
// AbortController & AbortSignal
// ============================================================================

/**
 * Create a new AbortController.
 * 
 * The controller is created with a signal that can be passed to abortable operations.
 * Call dom_abortcontroller_release() when done to free both controller and signal.
 * 
 * @return AbortController handle (never NULL)
 * 
 * Example:
 *   DOMAbortController* controller = dom_abortcontroller_new();
 *   DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
 *   
 *   // Pass signal to operation
 *   fetch_with_abort(url, signal);
 *   
 *   // User cancels
 *   dom_abortcontroller_abort(controller, NULL);
 *   
 *   dom_abortcontroller_release(controller);
 */
DOMAbortController* dom_abortcontroller_new(void);

/**
 * Get the controller's signal.
 * 
 * The signal is [SameObject] - always returns the same instance for a controller.
 * The signal is owned by the controller - do NOT release it separately.
 * 
 * @param controller AbortController handle
 * @return AbortSignal handle (never NULL)
 * 
 * Example:
 *   DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
 *   
 *   // [SameObject] - always same pointer
 *   DOMAbortSignal* signal2 = dom_abortcontroller_get_signal(controller);
 *   // signal == signal2
 *   
 *   // Pass to multiple operations
 *   fetch_with_abort(url1, signal);
 *   fetch_with_abort(url2, signal);
 */
DOMAbortSignal* dom_abortcontroller_get_signal(DOMAbortController* controller);

/**
 * Abort the controller's signal.
 * 
 * Triggers abort on the signal, causing all operations using it to be cancelled.
 * If already aborted, this is a no-op (idempotent).
 * 
 * @param controller AbortController handle
 * @param reason Abort reason (opaque pointer, can be NULL for default reason)
 * 
 * Example:
 *   // Abort with default reason ("AbortError")
 *   dom_abortcontroller_abort(controller, NULL);
 *   
 *   // Abort with custom reason
 *   MyError* error = create_timeout_error();
 *   dom_abortcontroller_abort(controller, (void*)error);
 */
void dom_abortcontroller_abort(DOMAbortController* controller, void* reason);

/**
 * Release an AbortController.
 * 
 * Frees the controller and its signal. After this call, both handles are invalid.
 * 
 * @param controller AbortController handle
 * 
 * Example:
 *   DOMAbortController* controller = dom_abortcontroller_new();
 *   // ... use controller ...
 *   dom_abortcontroller_release(controller);
 */
void dom_abortcontroller_release(DOMAbortController* controller);

/**
 * Create a pre-aborted signal (static factory).
 * 
 * Returns a signal that's already aborted, useful for immediately-cancelled operations.
 * The returned signal has ref_count = 1 - caller MUST call dom_abortsignal_release().
 * 
 * @param reason Abort reason (opaque pointer, can be NULL for default reason)
 * @return AbortSignal handle (never NULL, already aborted)
 * 
 * Example:
 *   // Return immediately-aborted signal
 *   DOMAbortSignal* signal = dom_abortsignal_abort(NULL);
 *   
 *   if (dom_abortsignal_get_aborted(signal)) {
 *       printf("Signal is aborted\n");
 *   }
 *   
 *   dom_abortsignal_release(signal);
 */
DOMAbortSignal* dom_abortsignal_abort(void* reason);

/**
 * Check if signal has been aborted.
 * 
 * @param signal AbortSignal handle
 * @return 1 if aborted, 0 if not aborted
 * 
 * Example:
 *   void fetch_data(const char* url, DOMAbortSignal* signal) {
 *       // Check before starting
 *       if (dom_abortsignal_get_aborted(signal)) {
 *           printf("Already aborted\n");
 *           return;
 *       }
 *       
 *       // Perform work...
 *       
 *       // Check periodically
 *       if (dom_abortsignal_get_aborted(signal)) {
 *           printf("Aborted during operation\n");
 *           return;
 *       }
 *   }
 */
uint8_t dom_abortsignal_get_aborted(DOMAbortSignal* signal);

/**
 * Throw if signal has been aborted.
 * 
 * In C, "throw" returns an error code. Returns 0 if not aborted,
 * DOM_ERROR_INVALID_STATE if aborted.
 * 
 * @param signal AbortSignal handle
 * @return 0 if not aborted, DOM_ERROR_INVALID_STATE (11) if aborted
 * 
 * Example:
 *   int err = dom_abortsignal_throwifaborted(signal);
 *   if (err != 0) {
 *       printf("Aborted: %s\n", dom_error_code_message(err));
 *       return err;
 *   }
 *   
 *   // Continue operation...
 */
int32_t dom_abortsignal_throwifaborted(DOMAbortSignal* signal);

/**
 * Increment signal reference count.
 * 
 * Call this when sharing the signal with another owner.
 * Each acquire() MUST be balanced with a release().
 * 
 * @param signal AbortSignal handle
 * 
 * Example:
 *   DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
 *   
 *   // Share with another context
 *   dom_abortsignal_acquire(signal);
 *   my_context->signal = signal;
 *   
 *   // Later, both contexts must release
 *   dom_abortsignal_release(my_context->signal);
 *   dom_abortcontroller_release(controller);
 */
void dom_abortsignal_acquire(DOMAbortSignal* signal);

/**
 * Decrement signal reference count.
 * 
 * Automatically frees the signal when ref_count reaches 0.
 * MUST be called by every owner when done with the signal.
 * 
 * @param signal AbortSignal handle
 * 
 * Example:
 *   DOMAbortSignal* signal = dom_abortsignal_abort(NULL);
 *   // ... use signal ...
 *   dom_abortsignal_release(signal);
 */
void dom_abortsignal_release(DOMAbortSignal* signal);

// ============================================================================
// StaticRange
// ============================================================================

/**
 * Create a new StaticRange.
 * 
 * Creates an immutable range from boundary points. Unlike Range, StaticRange
 * does NOT track DOM mutations and allows out-of-bounds offsets.
 * 
 * @param start_container Start boundary node
 * @param start_offset Offset within start container (can be out of bounds)
 * @param end_container End boundary node
 * @param end_offset Offset within end container (can be out of bounds)
 * @return StaticRange handle, or NULL if invalid node type (DocumentType/Attr)
 * 
 * Example:
 *   DOMDocument* doc = dom_document_new();
 *   DOMText* text = dom_document_createtextnode(doc, "Hello, World!");
 *   
 *   // Select "Hello" (characters 0-5)
 *   DOMStaticRange* range = dom_staticrange_new(
 *       (DOMNode*)text, 0,
 *       (DOMNode*)text, 5
 *   );
 *   
 *   if (range) {
 *       printf("Collapsed: %d\n", dom_staticrange_get_collapsed(range));
 *       dom_staticrange_release(range);
 *   }
 *   
 *   dom_document_release(doc);
 */
DOMStaticRange* dom_staticrange_new(
    DOMNode* start_container,
    uint32_t start_offset,
    DOMNode* end_container,
    uint32_t end_offset
);

/**
 * Get the start container node.
 * 
 * @param range StaticRange handle
 * @return Start container node (do NOT release)
 * 
 * Example:
 *   DOMNode* start = dom_staticrange_get_startcontainer(range);
 *   const char* name = dom_node_get_nodename(start);
 */
DOMNode* dom_staticrange_get_startcontainer(DOMStaticRange* range);

/**
 * Get the start offset.
 * 
 * @param range StaticRange handle
 * @return Offset within start container (may be out of bounds)
 * 
 * Example:
 *   uint32_t offset = dom_staticrange_get_startoffset(range);
 *   printf("Start: %u\n", offset);
 */
uint32_t dom_staticrange_get_startoffset(DOMStaticRange* range);

/**
 * Get the end container node.
 * 
 * @param range StaticRange handle
 * @return End container node (do NOT release)
 * 
 * Example:
 *   DOMNode* end = dom_staticrange_get_endcontainer(range);
 *   uint16_t type = dom_node_get_nodetype(end);
 */
DOMNode* dom_staticrange_get_endcontainer(DOMStaticRange* range);

/**
 * Get the end offset.
 * 
 * @param range StaticRange handle
 * @return Offset within end container (may be out of bounds)
 * 
 * Example:
 *   uint32_t offset = dom_staticrange_get_endoffset(range);
 *   printf("End: %u\n", offset);
 */
uint32_t dom_staticrange_get_endoffset(DOMStaticRange* range);

/**
 * Check if range is collapsed.
 * 
 * A range is collapsed if start and end are at the same position.
 * 
 * @param range StaticRange handle
 * @return 1 if collapsed, 0 otherwise
 * 
 * Example:
 *   // Insertion point (collapsed range)
 *   DOMStaticRange* collapsed = dom_staticrange_new(
 *       (DOMNode*)text, 5,
 *       (DOMNode*)text, 5
 *   );
 *   
 *   if (dom_staticrange_get_collapsed(collapsed)) {
 *       printf("Range is an insertion point\n");
 *   }
 */
uint8_t dom_staticrange_get_collapsed(DOMStaticRange* range);

/**
 * Release a StaticRange.
 * 
 * Frees the range and releases node references.
 * 
 * @param range StaticRange handle
 * 
 * Example:
 *   DOMStaticRange* range = dom_staticrange_new(...);
 *   // ... use range ...
 *   dom_staticrange_release(range);
 */
void dom_staticrange_release(DOMStaticRange* range);

/* ============================================================================
 * DocumentFragment Interface (ParentNode mixin)
 * ========================================================================= */

/**
 * Get live collection of element children.
 * 
 * Returns an HTMLCollection of all element children (skips text nodes, etc.).
 * The collection is live and updates when the DOM changes.
 * 
 * @param fragment DocumentFragment handle
 * @return HTMLCollection of element children (must be released)
 * 
 * Example:
 *   DOMHTMLCollection* elements = dom_documentfragment_get_children(fragment);
 *   uint32_t count = dom_htmlcollection_get_length(elements);
 *   for (uint32_t i = 0; i < count; i++) {
 *       DOMElement* elem = dom_htmlcollection_item(elements, i);
 *   }
 *   dom_htmlcollection_release(elements);
 */
DOMHTMLCollection* dom_documentfragment_get_children(DOMDocumentFragment* fragment);

/**
 * Get first element child.
 * 
 * @param fragment DocumentFragment handle
 * @return First element child or NULL
 * 
 * Example:
 *   DOMElement* first = dom_documentfragment_get_firstelementchild(fragment);
 */
DOMElement* dom_documentfragment_get_firstelementchild(DOMDocumentFragment* fragment);

/**
 * Get last element child.
 * 
 * @param fragment DocumentFragment handle
 * @return Last element child or NULL
 * 
 * Example:
 *   DOMElement* last = dom_documentfragment_get_lastelementchild(fragment);
 */
DOMElement* dom_documentfragment_get_lastelementchild(DOMDocumentFragment* fragment);

/**
 * Get count of element children.
 * 
 * Returns number of element children (text nodes, comments, etc. not counted).
 * 
 * @param fragment DocumentFragment handle
 * @return Number of element children
 * 
 * Example:
 *   uint32_t count = dom_documentfragment_get_childelementcount(fragment);
 */
uint32_t dom_documentfragment_get_childelementcount(DOMDocumentFragment* fragment);

/**
 * Find first element matching CSS selector.
 * 
 * @param fragment DocumentFragment handle
 * @param selectors CSS selector string
 * @return First matching element or NULL
 * 
 * Example:
 *   DOMElement* button = dom_documentfragment_queryselector(fragment, ".primary");
 */
DOMElement* dom_documentfragment_queryselector(DOMDocumentFragment* fragment, const char* selectors);

/**
 * Find all elements matching CSS selector.
 * 
 * Returns a static snapshot (not live) of matching elements.
 * 
 * @param fragment DocumentFragment handle
 * @param selectors CSS selector string
 * @return Static NodeList or NULL (must be released with dom_nodelist_static_release)
 * 
 * Example:
 *   DOMNodeList* items = dom_documentfragment_queryselectorall(fragment, ".item");
 *   if (items) {
 *       uint32_t count = dom_nodelist_static_get_length(items);
 *       for (uint32_t i = 0; i < count; i++) {
 *           DOMNode* node = dom_nodelist_static_item(items, i);
 *       }
 *       dom_nodelist_static_release(items);
 *   }
 */
DOMNodeList* dom_documentfragment_queryselectorall(DOMDocumentFragment* fragment, const char* selectors);

/**
 * Increment reference count.
 * 
 * @param fragment DocumentFragment handle
 */
void dom_documentfragment_addref(DOMDocumentFragment* fragment);

/**
 * Decrement reference count.
 * 
 * @param fragment DocumentFragment handle
 */
void dom_documentfragment_release(DOMDocumentFragment* fragment);

/* ============================================================================
 * Text Interface
 * ========================================================================= */

/**
 * Split text node at offset.
 * 
 * Splits this Text node into two nodes at the specified offset,
 * keeping the first part in this node and returning the second part.
 * 
 * @param text Text node to split
 * @param offset Character offset where to split (0-based)
 * @return New Text node containing text after offset, or NULL on error
 * 
 * Example:
 *   DOMText* text = dom_document_createtextnode(doc, "Hello World");
 *   DOMText* second = dom_text_splittext(text, 6);
 *   // text.data = "Hello "
 *   // second.data = "World"
 */
DOMText* dom_text_splittext(DOMText* text, uint32_t offset);

/**
 * Get concatenated text of this and adjacent Text nodes.
 * 
 * Returns the text of this node and all logically adjacent Text nodes
 * (siblings with no intervening element nodes).
 * 
 * @param text Text node
 * @return Concatenated text (caller-owned - MUST free with dom_text_free_wholetext)
 * 
 * Note: The returned string is allocated and owned by the caller.
 * You MUST call dom_text_free_wholetext() when done to avoid memory leaks.
 * 
 * Example:
 *   // parent has: Text("Hello "), Text("World")
 *   const char* whole = dom_text_get_wholetext(firstText);
 *   printf("Whole text: %s\n", whole);  // "Hello World"
 *   dom_text_free_wholetext(whole);  // Must free!
 */
const char* dom_text_get_wholetext(DOMText* text);

/**
 * Free wholeText string allocated by dom_text_get_wholetext.
 * 
 * @param str String returned from dom_text_get_wholetext()
 * 
 * Example:
 *   const char* whole = dom_text_get_wholetext(text);
 *   // ... use whole ...
 *   dom_text_free_wholetext(whole);
 */
void dom_text_free_wholetext(const char* str);

/* ============================================================================
 * CharacterData Interface (NonDocumentTypeChildNode mixin)
 * ========================================================================= */

/**
 * Get previous element sibling (CharacterData).
 * 
 * Returns the previous sibling that is an Element, skipping text nodes,
 * comments, and other non-element siblings.
 * 
 * @param cdata CharacterData handle (Text, Comment, or CDATASection)
 * @return Previous element sibling or NULL
 * 
 * Note: CharacterData includes the NonDocumentTypeChildNode mixin per WHATWG spec.
 * 
 * Example:
 *   // <div><span>A</span>text<span>B</span></div>
 *   DOMText* text = ...;  // "text" node
 *   DOMElement* prev = dom_characterdata_get_previouselementsibling((DOMCharacterData*)text);
 *   // Returns <span>A</span>
 */
DOMElement* dom_characterdata_get_previouselementsibling(DOMCharacterData* cdata);

/**
 * Get next element sibling (CharacterData).
 * 
 * Returns the next sibling that is an Element, skipping text nodes,
 * comments, and other non-element siblings.
 * 
 * @param cdata CharacterData handle (Text, Comment, or CDATASection)
 * @return Next element sibling or NULL
 * 
 * Note: CharacterData includes the NonDocumentTypeChildNode mixin per WHATWG spec.
 * 
 * Example:
 *   // <div><span>A</span>text<span>B</span></div>
 *   DOMText* text = ...;  // "text" node
 *   DOMElement* next = dom_characterdata_get_nextelementsibling((DOMCharacterData*)text);
 *   // Returns <span>B</span>
 */
DOMElement* dom_characterdata_get_nextelementsibling(DOMCharacterData* cdata);

/* ============================================================================
 * Static NodeList (querySelectorAll results)
 * ========================================================================= */

/**
 * Get length of static NodeList from querySelectorAll.
 * 
 * @param list NodeList handle from querySelectorAll
 * @return Number of elements in the snapshot
 * 
 * Example:
 *   DOMNodeList* results = dom_document_queryselectorall(doc, ".item");
 *   uint32_t count = dom_nodelist_static_get_length(results);
 */
uint32_t dom_nodelist_static_get_length(DOMNodeList* list);

/**
 * Get element at index from static NodeList.
 * 
 * @param list NodeList handle from querySelectorAll
 * @param index Zero-based index
 * @return Node at index, or NULL if out of bounds
 * 
 * Example:
 *   DOMNode* node = dom_nodelist_static_item(results, 0);
 *   if (node) {
 *       DOMElement* elem = (DOMElement*)node;  // Safe cast for querySelectorAll results
 *   }
 */
DOMNode* dom_nodelist_static_item(DOMNodeList* list, uint32_t index);

/**
 * Release static NodeList from querySelectorAll.
 * 
 * Frees the snapshot array (but not the elements themselves).
 * 
 * @param list NodeList handle to release
 * 
 * Example:
 *   DOMNodeList* results = dom_document_queryselectorall(doc, ".item");
 *   // ... process results ...
 *   dom_nodelist_static_release(results);
 */
void dom_nodelist_static_release(DOMNodeList* list);

/* ============================================================================
 * Event Interface
 * ========================================================================= */

/**
 * Get event target.
 * 
 * Returns the object to which the event was originally dispatched.
 * 
 * @param event Event handle
 * @return Event target or NULL
 * 
 * Example:
 *   DOMEventTarget* target = dom_event_get_target(event);
 *   if (target) {
 *       DOMNode* node = (DOMNode*)target;  // EventTarget can be cast to Node
 *   }
 */
DOMEventTarget* dom_event_get_target(DOMEvent* event);

/**
 * Get current event target.
 * 
 * Returns the object whose event listener is currently being invoked.
 * Changes during event propagation.
 * 
 * @param event Event handle
 * @return Current target or NULL
 */
DOMEventTarget* dom_event_get_currenttarget(DOMEvent* event);

/**
 * Get source element (legacy alias for target).
 * 
 * @param event Event handle
 * @return Event target or NULL
 */
DOMEventTarget* dom_event_get_srcelement(DOMEvent* event);

/**
 * Stop event propagation.
 * 
 * Prevents the event from propagating to other listeners.
 * 
 * @param event Event handle
 */
void dom_event_stoppropagation(DOMEvent* event);

/**
 * Stop event propagation immediately.
 * 
 * Prevents all other listeners from being invoked, even on current target.
 * 
 * @param event Event handle
 */
void dom_event_stopimmediatepropagation(DOMEvent* event);

/**
 * Prevent default action.
 * 
 * Prevents the browser's default action for this event.
 * Only works if event is cancelable.
 * 
 * @param event Event handle
 */
void dom_event_preventdefault(DOMEvent* event);

/**
 * Initialize event (legacy method).
 * 
 * This is a legacy method from DOM Level 2. Modern code should use
 * Event constructors instead. Can only be called before dispatch.
 * 
 * @param event Event handle
 * @param type Event type string
 * @param bubbles Non-zero if event should bubble
 * @param cancelable Non-zero if event is cancelable
 * 
 * Example:
 *   DOMEvent* event = dom_event_new();
 *   dom_event_initevent(event, "click", 1, 1);
 */
void dom_event_initevent(DOMEvent* event, const char* type, uint8_t bubbles, uint8_t cancelable);

/**
 * Get cancelBubble flag (legacy).
 * 
 * Legacy attribute - use stopPropagation() instead.
 * 
 * @param event Event handle
 * @return 1 if propagation stopped, 0 otherwise
 */
uint8_t dom_event_get_cancelbubble(DOMEvent* event);

/**
 * Set cancelBubble flag (legacy).
 * 
 * Legacy attribute - setting to true calls stopPropagation().
 * 
 * @param event Event handle
 * @param value Non-zero to stop propagation
 */
void dom_event_set_cancelbubble(DOMEvent* event, uint8_t value);

/**
 * Get returnValue flag (legacy).
 * 
 * Legacy attribute - returns opposite of defaultPrevented.
 * 
 * @param event Event handle
 * @return 0 if default prevented, 1 otherwise
 */
uint8_t dom_event_get_returnvalue(DOMEvent* event);

/**
 * Set returnValue flag (legacy).
 * 
 * Legacy attribute - setting to false calls preventDefault().
 * 
 * @param event Event handle
 * @param value 0 to prevent default, non-zero to allow
 */
void dom_event_set_returnvalue(DOMEvent* event, uint8_t value);

/**
 * Get the event's composed path.
 * 
 * Returns the event's path, which is an array of event targets that the event
 * will visit during propagation (capture, target, and bubble phases).
 * 
 * The returned array is owned by the caller and MUST be freed using
 * dom_event_free_composedpath().
 * 
 * @param event Event handle
 * @param count Pointer to store the number of targets in the path
 * @return Array of event target pointers (NULL if no path or error)
 * 
 * Example:
 *   uint32_t count;
 *   DOMEventTarget** path = dom_event_composedpath(event, &count);
 *   if (path) {
 *       printf("Path has %u targets\n", count);
 *       for (uint32_t i = 0; i < count; i++) {
 *           if (path[i]) {
 *               // Process target (can cast to DOMNode*)
 *           }
 *       }
 *       dom_event_free_composedpath(path, count);
 *   }
 */
DOMEventTarget** dom_event_composedpath(DOMEvent* event, uint32_t* count);

/**
 * Free composed path array.
 * 
 * Frees the array returned by dom_event_composedpath().
 * MUST be called to avoid memory leaks.
 * 
 * @param path Array of event targets (from dom_event_composedpath)
 * @param count Number of targets in array
 * 
 * Example:
 *   uint32_t count;
 *   DOMEventTarget** path = dom_event_composedpath(event, &count);
 *   if (path) {
 *       // ... use path ...
 *       dom_event_free_composedpath(path, count);
 *   }
 */
void dom_event_free_composedpath(DOMEventTarget** path, uint32_t count);

/**
 * Increment event reference count.
 * 
 * @param event Event handle
 */
void dom_event_addref(DOMEvent* event);

/**
 * Decrement event reference count.
 * 
 * @param event Event handle
 */
void dom_event_release(DOMEvent* event);

/* ============================================================================
 * CustomEvent Interface
 * ========================================================================= */

/**
 * Get custom event detail.
 * 
 * Returns custom data associated with the event.
 * 
 * @param event CustomEvent handle
 * @return Custom data pointer or NULL
 * 
 * Example:
 *   void* detail = dom_customevent_get_detail(event);
 *   if (detail) {
 *       int* value = (int*)detail;
 *       printf("Custom value: %d\n", *value);
 *   }
 */
void* dom_customevent_get_detail(DOMCustomEvent* event);

/**
 * Initialize custom event (legacy method).
 * 
 * This is a legacy method from DOM Level 3. Modern code should use
 * CustomEvent constructors instead. Can only be called before dispatch.
 * 
 * @param event CustomEvent handle
 * @param type Event type string
 * @param bubbles Non-zero if event should bubble
 * @param cancelable Non-zero if event is cancelable
 * @param detail Custom data pointer
 * 
 * Example:
 *   DOMCustomEvent* event = dom_customevent_new();
 *   void* data = malloc(sizeof(int));
 *   *(int*)data = 42;
 *   dom_customevent_initcustomevent(event, "custom", 1, 1, data);
 */
void dom_customevent_initcustomevent(DOMCustomEvent* event, const char* type, uint8_t bubbles, uint8_t cancelable, void* detail);

/**
 * Increment custom event reference count.
 * 
 * @param event CustomEvent handle
 */
void dom_customevent_addref(DOMCustomEvent* event);

/**
 * Decrement custom event reference count.
 * 
 * @param event CustomEvent handle
 */
void dom_customevent_release(DOMCustomEvent* event);

#ifdef __cplusplus
}
#endif

#endif /* DOM_H */
