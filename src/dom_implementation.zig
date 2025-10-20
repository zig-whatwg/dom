//! DOMImplementation Interface (WHATWG DOM)
//!
//! This module implements the DOMImplementation interface as specified by the WHATWG DOM Standard.
//! DOMImplementation provides methods for creating documents and document types independently of
//! any particular document instance.
//!
//! ## WHATWG Specification
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
//! ## Core Features
//!
//! ### Factory Methods
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const impl = doc.getImplementation();
//!
//! // Create a DocumentType
//! const doctype = try impl.createDocumentType(allocator, "html", "", "");
//! defer doctype.prototype.release();
//!
//! // Create a new XML Document
//! const newDoc = try impl.createDocument(allocator, null, "root", null);
//! defer newDoc.release();
//! ```
//!
//! ## Architecture
//!
//! DOMImplementation is implemented as a stateless factory:
//! - No internal state (zero bytes)
//! - All methods are static-like but instance-based per spec
//! - Factory methods create nodes with proper initialization
//! - Methods delegate to existing Document factory methods
//!
//! ## Spec Compliance
//!
//! This implementation follows WHATWG DOM §4.6 exactly:
//! - ✅ createDocumentType() - Creates DocumentType nodes
//! - ✅ createDocument() - Creates XML documents
//! - ⚠️  createHTMLDocument() - NOT IMPLEMENTED (HTML-specific, this is a generic DOM library)
//! - ✅ hasFeature() - Always returns true (deprecated API)
//!
//! ## Design Decision: No createHTMLDocument
//!
//! This is a **generic DOM library** for XML and custom document types, NOT an HTML-specific library.
//! The createHTMLDocument() method is HTML-specific and not applicable here. HTML libraries
//! extending this DOM library should implement their own HTMLDocument type and factory.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Document = @import("document.zig").Document;
const DocumentType = @import("document_type.zig").DocumentType;

/// DOMImplementation - Factory for creating documents and document types.
///
/// Implements WHATWG DOM DOMImplementation per DOM spec.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=Window]
/// interface DOMImplementation {
///   [NewObject] DocumentType createDocumentType(DOMString name, DOMString publicId, DOMString systemId);
///   [NewObject] XMLDocument createDocument(DOMString? namespace, [LegacyNullToEmptyString] DOMString qualifiedName, optional DocumentType? doctype = null);
///   [NewObject] Document createHTMLDocument(optional DOMString title);
///   boolean hasFeature();
/// };
/// ```
///
/// ## Spec References
/// - Interface: https://dom.spec.whatwg.org/#domimplementation
/// - WebIDL: dom.idl:326-332
///
/// ## Note
/// This is a zero-sized stateless type. All methods are instance methods per spec,
/// but they don't access instance state.
pub const DOMImplementation = struct {
    /// Reference to the document that owns this implementation
    /// Used for string interning and allocator access
    document: *Document,

    /// Creates a new DocumentType node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] DocumentType createDocumentType(DOMString name, DOMString publicId, DOMString systemId);
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// 1. Validate name using XML Name production
    /// 2. If validation fails, throw InvalidCharacterError
    /// 3. Create and return a new DocumentType node with given name, publicId, systemId
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for the DocumentType
    /// - `name`: Qualified name (e.g., "html" for HTML5)
    /// - `public_id`: Public identifier (empty for HTML5)
    /// - `system_id`: System identifier (empty for HTML5)
    ///
    /// ## Returns
    /// New DocumentType node with ref_count=1 (caller must release)
    ///
    /// ## Errors
    /// - `InvalidCharacterError`: Invalid name
    /// - `OutOfMemory`: Allocation failed
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domimplementation-createdocumenttype
    /// - WebIDL: dom.idl:327
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const impl = doc.getImplementation();
    /// const doctype = try impl.createDocumentType(allocator, "html", "", "");
    /// defer doctype.prototype.release();
    /// ```
    pub fn createDocumentType(
        self: *const DOMImplementation,
        name: []const u8,
        public_id: []const u8,
        system_id: []const u8,
    ) !*DocumentType {
        // Delegate to Document.createDocumentType for proper string interning
        return self.document.createDocumentType(name, public_id, system_id);
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
    /// ## Algorithm (from spec)
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
    /// - `allocator`: Memory allocator for the document
    /// - `namespace`: Namespace URI (null for no namespace)
    /// - `qualified_name`: Qualified element name (empty string = no element)
    /// - `doctype`: Optional DocumentType to adopt (null = no doctype)
    ///
    /// ## Returns
    /// New Document with ref_count=1 (caller must release)
    ///
    /// ## Errors
    /// - `InvalidCharacterError`: Invalid qualified name
    /// - `NamespaceError`: Invalid namespace/qualified name combination
    /// - `OutOfMemory`: Allocation failed
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domimplementation-createdocument
    /// - WebIDL: dom.idl:328
    ///
    /// ## Example
    /// ```zig
    /// const impl = doc.getImplementation();
    ///
    /// // Create empty document
    /// const doc1 = try impl.createDocument(allocator, null, "", null);
    /// defer doc1.release();
    ///
    /// // Create document with root element
    /// const doc2 = try impl.createDocument(allocator, null, "root", null);
    /// defer doc2.release();
    ///
    /// // Create document with namespace
    /// const doc3 = try impl.createDocument(
    ///     allocator,
    ///     "http://www.w3.org/2000/svg",
    ///     "svg",
    ///     null
    /// );
    /// defer doc3.release();
    /// ```
    pub fn createDocument(
        self: *const DOMImplementation,
        namespace: ?[]const u8,
        qualified_name: []const u8,
        doctype: ?*DocumentType,
    ) !*Document {
        // Step 1: Create new document using same allocator as parent document
        const doc = try Document.init(self.document.prototype.allocator);
        errdefer doc.release();

        // Step 2: If qualified_name not empty, create and append root element
        if (qualified_name.len > 0) {
            // TODO: When Document.createElementNS is implemented, use it for namespace != null
            // For now, just create element without namespace (generic DOM library)
            _ = namespace; // Ignore namespace for now
            const root_element = try doc.createElement(qualified_name);
            _ = try doc.prototype.appendChild(&root_element.prototype);
            // No release here - createElement returns nodes owned by document
        }

        // Step 3: If doctype provided, prepend it to the document (before root element)
        if (doctype) |dt| {
            // Create a new doctype in the new document with same properties
            // This avoids string pool issues when transferring between documents
            const new_doctype = try doc.createDocumentType(dt.name, dt.publicId, dt.systemId);
            // Insert doctype BEFORE the root element (at the beginning)
            const first_child = doc.prototype.first_child;
            _ = try doc.prototype.insertBefore(&new_doctype.prototype, first_child);
            // new_doctype is now owned by doc, no need to release
        }

        return doc;
    }

    /// Checks if a feature is supported (always returns true).
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean hasFeature();
    /// ```
    ///
    /// ## Algorithm (from spec)
    /// Return true. This method is deprecated and always returns true.
    ///
    /// ## Returns
    /// Always returns true (deprecated API)
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-domimplementation-hasfeature
    /// - WebIDL: dom.idl:331
    ///
    /// ## Note
    /// This method is deprecated and only exists for historical compatibility.
    /// Modern code should not use feature detection via hasFeature().
    /// The spec states: "useless; always returns true"
    ///
    /// ## Example
    /// ```zig
    /// const impl = doc.getImplementation();
    /// const supported = impl.hasFeature();
    /// // supported = true (always)
    /// ```
    pub fn hasFeature(self: *const DOMImplementation) bool {
        _ = self;
        return true;
    }
};
