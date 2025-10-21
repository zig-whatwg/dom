//! DocumentType C-ABI Bindings
//!
//! C-ABI bindings for the DocumentType interface per WHATWG DOM specification.
//! DocumentType represents the document's DTD (Document Type Declaration).
//!
//! ## C API Overview
//!
//! ```c
//! // Properties (readonly)
//! const char* dom_documenttype_get_name(DOMDocumentType* doctype);
//! const char* dom_documenttype_get_publicid(DOMDocumentType* doctype);
//! const char* dom_documenttype_get_systemid(DOMDocumentType* doctype);
//!
//! // Reference counting
//! void dom_documenttype_addref(DOMDocumentType* doctype);
//! void dom_documenttype_release(DOMDocumentType* doctype);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface DocumentType : Node {
//!   readonly attribute DOMString name;
//!   readonly attribute DOMString publicId;
//!   readonly attribute DOMString systemId;
//! };
//! ```
//!
//! ## WHATWG Specification
//!
//! - DocumentType interface: https://dom.spec.whatwg.org/#documenttype
//! - Document.doctype: https://dom.spec.whatwg.org/#dom-document-doctype
//!
//! ## MDN Documentation
//!
//! - DocumentType: https://developer.mozilla.org/en-US/docs/Web/API/DocumentType

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const DocumentType = dom.DocumentType;
const DOMDocumentType = types.DOMDocumentType;
const zigStringToCString = types.zigStringToCString;

// ============================================================================
// Properties (Readonly)
// ============================================================================

/// Get the name of the document type.
///
/// Returns the document type name (e.g., "html", "xml", "svg").
/// This is the name that appears in the <!DOCTYPE> declaration.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString name;
/// ```
///
/// ## Parameters
/// - `doctype`: DocumentType handle
///
/// ## Returns
/// Document type name (borrowed, do NOT free)
///
/// ## Example
/// ```c
/// // HTML5: <!DOCTYPE html>
/// DOMDocumentType* doctype = dom_document_get_doctype(doc);
/// if (doctype != NULL) {
///     const char* name = dom_documenttype_get_name(doctype);
///     printf("DOCTYPE name: %s\n", name);  // "html"
/// }
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-documenttype-name
/// - https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/name
pub export fn dom_documenttype_get_name(doctype: *DOMDocumentType) [*:0]const u8 {
    const doctype_node: *DocumentType = @ptrCast(@alignCast(doctype));
    return zigStringToCString(doctype_node.name);
}

/// Get the public identifier of the document type.
///
/// Returns the public ID from the <!DOCTYPE> declaration, or empty string
/// if not specified. HTML5 typically uses an empty public ID.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString publicId;
/// ```
///
/// ## Parameters
/// - `doctype`: DocumentType handle
///
/// ## Returns
/// Public identifier (borrowed, do NOT free)
///
/// ## Example
/// ```c
/// // XHTML: <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "...">
/// DOMDocumentType* doctype = dom_document_get_doctype(doc);
/// if (doctype != NULL) {
///     const char* publicId = dom_documenttype_get_publicid(doctype);
///     if (publicId[0] != '\0') {
///         printf("Public ID: %s\n", publicId);
///     }
/// }
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-documenttype-publicid
/// - https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/publicId
pub export fn dom_documenttype_get_publicid(doctype: *DOMDocumentType) [*:0]const u8 {
    const doctype_node: *DocumentType = @ptrCast(@alignCast(doctype));
    return zigStringToCString(doctype_node.publicId);
}

/// Get the system identifier of the document type.
///
/// Returns the system ID (typically a URL to the DTD) from the <!DOCTYPE>
/// declaration, or empty string if not specified. HTML5 typically uses an
/// empty system ID.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString systemId;
/// ```
///
/// ## Parameters
/// - `doctype`: DocumentType handle
///
/// ## Returns
/// System identifier (borrowed, do NOT free)
///
/// ## Example
/// ```c
/// // SVG: <!DOCTYPE svg PUBLIC "..." "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
/// DOMDocumentType* doctype = dom_document_get_doctype(doc);
/// if (doctype != NULL) {
///     const char* systemId = dom_documenttype_get_systemid(doctype);
///     if (systemId[0] != '\0') {
///         printf("System ID: %s\n", systemId);
///     }
/// }
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-documenttype-systemid
/// - https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/systemId
pub export fn dom_documenttype_get_systemid(doctype: *DOMDocumentType) [*:0]const u8 {
    const doctype_node: *DocumentType = @ptrCast(@alignCast(doctype));
    return zigStringToCString(doctype_node.systemId);
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of a DocumentType node.
///
/// Call this when sharing a DocumentType node reference.
///
/// ## Parameters
/// - `doctype`: DocumentType handle
pub export fn dom_documenttype_addref(doctype: *DOMDocumentType) void {
    const doctype_node: *DocumentType = @ptrCast(@alignCast(doctype));
    doctype_node.prototype.acquire();
}

/// Decrement the reference count of a DocumentType node.
///
/// Call this when done with a DocumentType node. When ref count reaches 0,
/// the node is freed.
///
/// ## Parameters
/// - `doctype`: DocumentType handle
pub export fn dom_documenttype_release(doctype: *DOMDocumentType) void {
    const doctype_node: *DocumentType = @ptrCast(@alignCast(doctype));
    doctype_node.prototype.release();
}
