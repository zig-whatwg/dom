//! DOMImplementation JavaScript Bindings
//!
//! C-ABI bindings for the WHATWG DOMImplementation interface.
//!
//! ## WHATWG Specification
//!
//! DOMImplementation provides factory methods for creating documents and document types
//! independently of any particular document instance.
//!
//! Relevant specification sections:
//! - **DOMImplementation**: https://dom.spec.whatwg.org/#domimplementation
//! - **Document.implementation**: https://dom.spec.whatwg.org/#dom-document-implementation
//!
//! ## MDN Documentation
//!
//! - DOMImplementation: https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation
//! - DOMImplementation.createDocumentType(): https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocumentType
//! - DOMImplementation.createDocument(): https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocument
//! - DOMImplementation.hasFeature(): https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/hasFeature
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface DOMImplementation {
//!   [NewObject] DocumentType createDocumentType(DOMString name, DOMString publicId, DOMString systemId);
//!   [NewObject] XMLDocument createDocument(DOMString? namespace, [LegacyNullToEmptyString] DOMString qualifiedName, optional DocumentType? doctype = null);
//!   boolean hasFeature(); // useless; always returns true
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#domimplementation (WebIDL: dom.idl:326-332)
//!
//! ## Exported Functions (5 total)
//!
//! ### Factory Methods
//! - `dom_domimplementation_createdocumenttype()` - Create DocumentType node
//! - `dom_domimplementation_createdocument()` - Create XML document
//!
//! ### Feature Detection (Deprecated)
//! - `dom_domimplementation_hasfeature()` - Always returns true (deprecated)
//!
//! ### Memory Management
//! - `dom_domimplementation_addref()` - Increment reference count
//! - `dom_domimplementation_release()` - Decrement reference count
//!
//! ## Memory Management
//!
//! DOMImplementation uses reference counting but is special:
//! - Obtained from `Document.implementation` ([SameObject] - always same pointer)
//! - Initial ref count is managed by the Document
//! - Call `addref()` if you need to keep it beyond Document lifetime
//! - Call `release()` when done (but Document typically owns the final reference)
//!
//! ## JavaScript Integration
//!
//! ### Access Pattern
//! ```javascript
//! // Get implementation from document ([SameObject])
//! const impl = document.implementation;
//!
//! // Create DocumentType
//! const doctype = impl.createDocumentType('html', '', '');
//! console.log(doctype.name); // 'html'
//! doctype.release();
//!
//! // Create XML document with root element
//! const xmlDoc = impl.createDocument(null, 'root', null);
//! console.log(xmlDoc.documentElement.nodeName); // 'ROOT'
//! xmlDoc.release();
//!
//! // Create document with namespace
//! const svgDoc = impl.createDocument('http://www.w3.org/2000/svg', 'svg', null);
//! console.log(svgDoc.documentElement.namespaceURI); // 'http://www.w3.org/2000/svg'
//! svgDoc.release();
//!
//! // Create document with DOCTYPE
//! const doctype2 = impl.createDocumentType('svg', '-//W3C//DTD SVG 1.1//EN', 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd');
//! const svgWithDoctype = impl.createDocument('http://www.w3.org/2000/svg', 'svg', doctype2);
//! console.log(svgWithDoctype.doctype === doctype2); // true
//! doctype2.release();
//! svgWithDoctype.release();
//!
//! // hasFeature() - deprecated, always returns true
//! console.log(impl.hasFeature()); // true (always)
//! ```
//!
//! ## Usage Example (C)
//!
//! ```c
//! #include <stdio.h>
//!
//! typedef struct DOMDocument DOMDocument;
//! typedef struct DOMDOMImplementation DOMDOMImplementation;
//! typedef struct DOMDocumentType DOMDocumentType;
//!
//! extern DOMDocument* dom_document_new(void);
//! extern DOMDOMImplementation* dom_document_get_implementation(DOMDocument* doc);
//! extern DOMDocumentType* dom_domimplementation_createdocumenttype(
//!     DOMDOMImplementation* impl,
//!     const char* name,
//!     const char* public_id,
//!     const char* system_id
//! );
//! extern DOMDocument* dom_domimplementation_createdocument(
//!     DOMDOMImplementation* impl,
//!     const char* namespace,
//!     const char* qualified_name,
//!     DOMDocumentType* doctype
//! );
//! extern int dom_domimplementation_hasfeature(DOMDOMImplementation* impl);
//! extern void dom_documenttype_release(DOMDocumentType* doctype);
//! extern void dom_document_release(DOMDocument* doc);
//!
//! int main(void) {
//!     // Create base document
//!     DOMDocument* doc = dom_document_new();
//!
//!     // Get implementation ([SameObject])
//!     DOMDOMImplementation* impl = dom_document_get_implementation(doc);
//!
//!     // Create HTML5 DOCTYPE
//!     DOMDocumentType* htmlDoctype = dom_domimplementation_createdocumenttype(impl, "html", "", "");
//!     printf("Created DOCTYPE: html\n");
//!     dom_documenttype_release(htmlDoctype);
//!
//!     // Create XML document with root element
//!     DOMDocument* xmlDoc = dom_domimplementation_createdocument(impl, NULL, "root", NULL);
//!     printf("Created XML document with root element\n");
//!     dom_document_release(xmlDoc);
//!
//!     // Create SVG document with namespace
//!     DOMDocument* svgDoc = dom_domimplementation_createdocument(
//!         impl,
//!         "http://www.w3.org/2000/svg",
//!         "svg",
//!         NULL
//!     );
//!     printf("Created SVG document\n");
//!     dom_document_release(svgDoc);
//!
//!     // Create document with DOCTYPE
//!     DOMDocumentType* svgDoctype = dom_domimplementation_createdocumenttype(
//!         impl,
//!         "svg",
//!         "-//W3C//DTD SVG 1.1//EN",
//!         "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
//!     );
//!     DOMDocument* svgWithDoctype = dom_domimplementation_createdocument(
//!         impl,
//!         "http://www.w3.org/2000/svg",
//!         "svg",
//!         svgDoctype
//!     );
//!     printf("Created SVG document with DOCTYPE\n");
//!     dom_documenttype_release(svgDoctype);
//!     dom_document_release(svgWithDoctype);
//!
//!     // hasFeature() - deprecated, always returns true
//!     int hasFeature = dom_domimplementation_hasfeature(impl);
//!     printf("hasFeature: %d (always true)\n", hasFeature);
//!
//!     // Clean up
//!     dom_document_release(doc);
//!     return 0;
//! }
//! ```
//!
//! ## Design Decision: No createHTMLDocument
//!
//! This is a **generic DOM library** for XML and custom document types, NOT an HTML-specific library.
//! The `createHTMLDocument()` method is HTML-specific and not implemented here. HTML libraries
//! extending this DOM library should implement their own HTMLDocument type and factory.
//!
//! Per WebIDL: `[NewObject] Document createHTMLDocument(optional DOMString title);`
//! - NOT IMPLEMENTED in this generic DOM library
//! - HTML-specific behavior (creates <html>, <head>, <title>, <body>)
//! - HTML libraries should add this separately
//!
//! ## Implementation Notes
//!
//! ### [NewObject] Attribute
//! - Per WebIDL: All factory methods return [NewObject] - fresh references
//! - Caller receives ownership and MUST call release() when done
//! - JavaScript wrapper should create new wrapper objects for each call
//!
//! ### [LegacyNullToEmptyString] Attribute
//! - In createDocument(), null qualifiedName becomes empty string
//! - C bindings: NULL pointer → empty document (no root element)
//! - JavaScript: `impl.createDocument(null, null, null)` → qualifiedName=""
//!
//! ### [SameObject] Attribute
//! - Document.implementation always returns same DOMImplementation pointer
//! - No need to addref/release if only using during Document lifetime
//! - Safe to compare pointers: `impl1 === impl2` in JavaScript
//!
//! ### Namespace Handling (TODO)
//! - Currently namespace parameter is accepted but ignored
//! - Full namespace support requires Document.createElementNS() (not yet implemented)
//! - Future enhancement: Store namespace on Element and respect during creation
//!
//! ## Error Handling
//!
//! Factory methods return NULL on error (memory allocation failure).
//! No other errors are possible for these methods (unlike setAttribute, etc).
//!
//! ```c
//! DOMDocumentType* doctype = dom_domimplementation_createdocumenttype(impl, "html", "", "");
//! if (!doctype) {
//!     fprintf(stderr, "Failed to create DocumentType (out of memory)\n");
//!     return -1;
//! }
//! ```
//!
//! ## Spec Compliance
//!
//! ✅ createDocumentType() - Per DOM spec §4.6.1
//! ✅ createDocument() - Per DOM spec §4.6.2
//! ⚠️  createHTMLDocument() - NOT IMPLEMENTED (HTML-specific)
//! ✅ hasFeature() - Per DOM spec §4.6.4 (deprecated, always true)
//!
//! See also:
//! - `documenttype.zig` for DocumentType bindings
//! - `document.zig` for Document bindings and getImplementation()
//! - `../src/dom_implementation.zig` for implementation details

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");
const DOMImplementation = dom.DOMImplementation;
const DocumentType = dom.DocumentType;
const Document = dom.Document;

// ============================================================================
// Type Conversions
// ============================================================================

/// Convert opaque C handle to Zig DOMImplementation pointer
fn handleToImpl(handle: *types.DOMDOMImplementation) *DOMImplementation {
    return @ptrCast(@alignCast(handle));
}

/// Convert Zig DOMImplementation pointer to opaque C handle
fn implToHandle(impl: *DOMImplementation) *types.DOMDOMImplementation {
    return @ptrCast(@alignCast(impl));
}

/// Convert opaque C DocumentType handle to Zig DocumentType pointer
fn handleToDocumentType(handle: *types.DOMDocumentType) *DocumentType {
    return @ptrCast(@alignCast(handle));
}

/// Convert Zig DocumentType pointer to opaque C handle
fn documentTypeToHandle(doctype: *DocumentType) *types.DOMDocumentType {
    return @ptrCast(@alignCast(doctype));
}

/// Convert opaque C Document handle to Zig Document pointer
fn handleToDocument(handle: *types.DOMDocument) *Document {
    return @ptrCast(@alignCast(handle));
}

/// Convert Zig Document pointer to opaque C handle
fn documentToHandle(doc: *Document) *types.DOMDocument {
    return @ptrCast(@alignCast(doc));
}

// ============================================================================
// Factory Methods
// ============================================================================

/// Creates a new DocumentType node.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] DocumentType createDocumentType(DOMString name, DOMString publicId, DOMString systemId);
/// ```
///
/// ## Algorithm (from DOM spec §4.6.1)
/// 1. Validate name using XML Name production
/// 2. If validation fails, throw InvalidCharacterError
/// 3. Create and return a new DocumentType node with given name, publicId, systemId
///
/// ## Parameters
/// - `impl`: DOMImplementation handle (from document.implementation)
/// - `name`: Qualified name (e.g., "html" for HTML5)
/// - `public_id`: Public identifier (empty "" for HTML5)
/// - `system_id`: System identifier (empty "" for HTML5)
///
/// ## Returns
/// New DocumentType handle with ref_count=1, or NULL on error
///
/// ## Errors
/// Returns NULL if:
/// - Invalid name (validation error)
/// - Out of memory
///
/// ## Memory Management
/// Caller receives ownership and MUST call dom_documenttype_release() when done.
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-domimplementation-createdocumenttype
/// - WebIDL: dom.idl:327
///
/// ## Example
/// ```c
/// DOMDOMImplementation* impl = dom_document_get_implementation(doc);
///
/// // HTML5 DOCTYPE
/// DOMDocumentType* htmlDoctype = dom_domimplementation_createdocumenttype(impl, "html", "", "");
///
/// // SVG 1.1 DOCTYPE
/// DOMDocumentType* svgDoctype = dom_domimplementation_createdocumenttype(
///     impl,
///     "svg",
///     "-//W3C//DTD SVG 1.1//EN",
///     "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
/// );
///
/// dom_documenttype_release(htmlDoctype);
/// dom_documenttype_release(svgDoctype);
/// ```
pub export fn dom_domimplementation_createdocumenttype(
    impl: *types.DOMDOMImplementation,
    name: [*:0]const u8,
    public_id: [*:0]const u8,
    system_id: [*:0]const u8,
) ?*types.DOMDocumentType {
    const zig_impl = handleToImpl(impl);
    const zig_name = types.cStringToZigString(name);
    const zig_public_id = types.cStringToZigString(public_id);
    const zig_system_id = types.cStringToZigString(system_id);

    const doctype = zig_impl.createDocumentType(zig_name, zig_public_id, zig_system_id) catch return null;
    return documentTypeToHandle(doctype);
}

/// Creates a new XML Document.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] XMLDocument createDocument(
///   DOMString? namespace,
///   [LegacyNullToEmptyString] DOMString qualifiedName,
///   optional DocumentType? doctype = null
/// );
/// ```
///
/// ## Algorithm (from DOM spec §4.6.2)
/// 1. Let document be a new document
/// 2. Set document's type to "xml"
/// 3. Set document's content type to "application/xml"
/// 4. If namespace is not null and qualifiedName is not empty:
///    a. Create element with namespace and qualifiedName
///    b. Append element to document
/// 5. If doctype is not null:
///    a. Append doctype to document
/// 6. Return document
///
/// ## Parameters
/// - `impl`: DOMImplementation handle
/// - `namespace`: Namespace URI (NULL or empty for no namespace)
/// - `qualified_name`: Qualified element name (empty "" = no root element)
/// - `doctype`: Optional DocumentType to adopt (NULL = no doctype)
///
/// ## Returns
/// New Document handle with ref_count=1, or NULL on error
///
/// ## Errors
/// Returns NULL if:
/// - Invalid qualified name
/// - Invalid namespace/qualified name combination
/// - Out of memory
///
/// ## Memory Management
/// Caller receives ownership and MUST call dom_document_release() when done.
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-domimplementation-createdocument
/// - WebIDL: dom.idl:328
///
/// ## Example
/// ```c
/// DOMDOMImplementation* impl = dom_document_get_implementation(doc);
///
/// // Empty document (no root element)
/// DOMDocument* emptyDoc = dom_domimplementation_createdocument(impl, NULL, "", NULL);
///
/// // Document with root element
/// DOMDocument* xmlDoc = dom_domimplementation_createdocument(impl, NULL, "root", NULL);
///
/// // Document with namespace
/// DOMDocument* svgDoc = dom_domimplementation_createdocument(
///     impl,
///     "http://www.w3.org/2000/svg",
///     "svg",
///     NULL
/// );
///
/// // Document with DOCTYPE
/// DOMDocumentType* doctype = dom_domimplementation_createdocumenttype(impl, "svg", "-//W3C//DTD SVG 1.1//EN", "...");
/// DOMDocument* svgWithDoctype = dom_domimplementation_createdocument(
///     impl,
///     "http://www.w3.org/2000/svg",
///     "svg",
///     doctype
/// );
///
/// dom_document_release(emptyDoc);
/// dom_document_release(xmlDoc);
/// dom_document_release(svgDoc);
/// dom_documenttype_release(doctype);
/// dom_document_release(svgWithDoctype);
/// ```
pub export fn dom_domimplementation_createdocument(
    impl: *types.DOMDOMImplementation,
    namespace: ?[*:0]const u8,
    qualified_name: [*:0]const u8,
    doctype: ?*types.DOMDocumentType,
) ?*types.DOMDocument {
    const zig_impl = handleToImpl(impl);
    const zig_namespace = if (namespace) |ns| types.cStringToZigString(ns) else null;
    const zig_qualified_name = types.cStringToZigString(qualified_name);
    const zig_doctype = if (doctype) |dt| handleToDocumentType(dt) else null;

    const doc = zig_impl.createDocument(zig_namespace, zig_qualified_name, zig_doctype) catch return null;
    return documentToHandle(doc);
}

// ============================================================================
// Feature Detection (Deprecated)
// ============================================================================

/// Checks if a feature is supported (always returns true).
///
/// ## WebIDL
/// ```webidl
/// boolean hasFeature(); // useless; always returns true
/// ```
///
/// ## Algorithm (from DOM spec §4.6.4)
/// Return true. This method is deprecated and always returns true.
///
/// ## Parameters
/// - `impl`: DOMImplementation handle
///
/// ## Returns
/// Always returns 1 (true)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-domimplementation-hasfeature
/// - WebIDL: dom.idl:331
///
/// ## Note
/// This method is deprecated and only exists for historical compatibility.
/// The spec states: "useless; always returns true"
/// Modern code should not use feature detection via hasFeature().
///
/// ## Example
/// ```c
/// DOMDOMImplementation* impl = dom_document_get_implementation(doc);
/// int hasFeature = dom_domimplementation_hasfeature(impl);
/// // hasFeature = 1 (always true)
/// ```
pub export fn dom_domimplementation_hasfeature(impl: *types.DOMDOMImplementation) c_int {
    const zig_impl = handleToImpl(impl);
    return if (zig_impl.hasFeature()) 1 else 0;
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increment reference count on DOMImplementation.
///
/// ## Parameters
/// - `impl`: DOMImplementation handle
///
/// ## Memory Management
/// DOMImplementation is typically owned by the Document and managed via [SameObject].
/// Only call addref() if you need to keep the implementation beyond Document lifetime.
///
/// ## Example
/// ```c
/// DOMDOMImplementation* impl = dom_document_get_implementation(doc);
/// dom_domimplementation_addref(impl); // Only if keeping beyond doc lifetime
/// // ... use impl ...
/// dom_domimplementation_release(impl);
/// ```
pub export fn dom_domimplementation_addref(impl: *types.DOMDOMImplementation) void {
    const zig_impl = handleToImpl(impl);
    // DOMImplementation is embedded in Document, so increment Document ref count
    zig_impl.document.prototype.acquire();
}

/// Decrement reference count on DOMImplementation.
///
/// ## Parameters
/// - `impl`: DOMImplementation handle
///
/// ## Memory Management
/// Frees the DOMImplementation (and its owning Document) when reference count reaches zero.
/// Typically you don't need to call this if you only use impl during Document lifetime.
///
/// ## Example
/// ```c
/// DOMDOMImplementation* impl = dom_document_get_implementation(doc);
/// // ... use impl ...
/// // No need to release if doc is still alive
/// dom_document_release(doc); // This releases impl too
/// ```
pub export fn dom_domimplementation_release(impl: *types.DOMDOMImplementation) void {
    const zig_impl = handleToImpl(impl);
    // DOMImplementation is embedded in Document, so decrement Document ref count
    zig_impl.document.prototype.release();
}
