//! JavaScript Bindings for Document
//!
//! This file provides C-ABI compatible bindings.

const std = @import("std");
const dom_types = @import("dom_types.zig");
const DOMErrorCode = dom_types.DOMErrorCode;
const zigErrorToDOMError = dom_types.zigErrorToDOMError;
const zigStringToCString = dom_types.zigStringToCString;
const zigStringToCStringOptional = dom_types.zigStringToCStringOptional;
const cStringToZigString = dom_types.cStringToZigString;
const cStringToZigStringOptional = dom_types.cStringToZigStringOptional;

// Import opaque types from dom_types
pub const DOMDocument = dom_types.DOMDocument;
pub const DOMElement = dom_types.DOMElement;
pub const DOMText = dom_types.DOMText;
pub const DOMComment = dom_types.DOMComment;
pub const DOMCDATASection = dom_types.DOMCDATASection;
pub const DOMProcessingInstruction = dom_types.DOMProcessingInstruction;
pub const DOMNode = dom_types.DOMNode;
pub const DOMAttr = dom_types.DOMAttr;
pub const DOMDocumentFragment = dom_types.DOMDocumentFragment;
pub const DOMDocumentType = dom_types.DOMDocumentType;
pub const DOMDOMImplementation = dom_types.DOMDOMImplementation;
pub const DOMRange = dom_types.DOMRange;

// Forward declarations for types not yet in dom_types
pub const DOMHTMLCollection = opaque {};
pub const DOMNodeIterator = opaque {};
pub const DOMEvent = opaque {};
pub const DOMTreeWalker = opaque {};
pub const DOMNodeFilter = opaque {};

// Import actual DOM implementation
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;
const Text = dom.Text;
const Comment = dom.Comment;
const HTMLCollection = dom.HTMLCollection;
const Range = dom.Range;

/// Get implementation attribute
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute DOMImplementation implementation;
/// ```
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-document-implementation
/// - WebIDL: dom.idl:289
///
/// ## Note
/// [SameObject] means this always returns the same DOMImplementation pointer for a given Document.
/// The implementation is embedded in the Document and shares its lifetime.
///
/// ## Parameters
/// - `handle`: Document handle
///
/// ## Returns
/// DOMImplementation handle (never NULL)
///
/// ## Example
/// ```c
/// DOMDocument* doc = dom_document_new();
/// DOMDOMImplementation* impl = dom_document_get_implementation(doc);
/// // impl is always the same pointer for this doc ([SameObject])
/// DOMDOMImplementation* impl2 = dom_document_get_implementation(doc);
/// // impl == impl2
/// ```
pub export fn dom_document_get_implementation(handle: *DOMDocument) *dom_types.DOMDOMImplementation {
    const doc: *Document = @ptrCast(@alignCast(handle));
    return @ptrCast(doc.getImplementation());
}

/// Get URL attribute.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute USVString URL;
/// ```
///
/// ## Returns
/// Document URL (empty string for generic DOM without browsing context)
///
/// ## Spec References
/// - https://dom.spec.whatwg.org/#dom-document-url
/// - https://developer.mozilla.org/en-US/docs/Web/API/Document/URL
///
/// ## Note
/// This is a generic DOM library without browser context. Returns empty string
/// by default. Applications can provide custom URL via document subclassing.
pub export fn dom_document_get_url(handle: *DOMDocument) [*:0]const u8 {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const url = doc.getURL();
    return zigStringToCString(url);
}

/// Get documentURI attribute (alias for URL).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute USVString documentURI;
/// ```
///
/// ## Returns
/// Document URI (same as URL, empty string for generic DOM)
///
/// ## Spec References
/// - https://dom.spec.whatwg.org/#dom-document-documenturi
/// - https://developer.mozilla.org/en-US/docs/Web/API/Document/documentURI
///
/// ## Note
/// This property is functionally equivalent to URL. It exists for
/// historical reasons and compatibility.
pub export fn dom_document_get_documenturi(handle: *DOMDocument) [*:0]const u8 {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const uri = doc.getDocumentURI();
    return zigStringToCString(uri);
}

/// Get compatMode attribute.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString compatMode;
/// ```
///
/// ## Returns
/// "CSS1Compat" for standards mode (this implementation always returns standards mode)
///
/// ## Spec References
/// - https://dom.spec.whatwg.org/#dom-document-compatmode
/// - https://developer.mozilla.org/en-US/docs/Web/API/Document/compatMode
///
/// ## Note
/// This generic DOM library always returns "CSS1Compat" (standards mode).
/// Quirks mode is HTML-specific.
pub export fn dom_document_get_compatmode(handle: *DOMDocument) [*:0]const u8 {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const mode = doc.getCompatMode();
    return zigStringToCString(mode);
}

/// Get characterSet attribute.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString characterSet;
/// ```
///
/// ## Returns
/// "UTF-8" (this implementation always uses UTF-8)
///
/// ## Spec References
/// - https://dom.spec.whatwg.org/#dom-document-characterset
/// - https://developer.mozilla.org/en-US/docs/Web/API/Document/characterSet
pub export fn dom_document_get_characterset(handle: *DOMDocument) [*:0]const u8 {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const charset = doc.getCharacterSet();
    return zigStringToCString(charset);
}

/// Get charset attribute (legacy alias of characterSet).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString charset;
/// ```
///
/// ## Returns
/// "UTF-8" (same as characterSet)
///
/// ## Note
/// This is a legacy alias. Use characterSet instead.
pub export fn dom_document_get_charset(handle: *DOMDocument) [*:0]const u8 {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const charset = doc.getCharset();
    return zigStringToCString(charset);
}

/// Get inputEncoding attribute (legacy alias of characterSet).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString inputEncoding;
/// ```
///
/// ## Returns
/// "UTF-8" (same as characterSet)
///
/// ## Note
/// This is a legacy alias. Use characterSet instead.
pub export fn dom_document_get_inputencoding(handle: *DOMDocument) [*:0]const u8 {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const encoding = doc.getInputEncoding();
    return zigStringToCString(encoding);
}

/// Get contentType attribute.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString contentType;
/// ```
///
/// ## Returns
/// "application/xml" (this generic DOM implementation)
///
/// ## Spec References
/// - https://dom.spec.whatwg.org/#dom-document-contenttype
/// - https://developer.mozilla.org/en-US/docs/Web/API/Document/contentType
///
/// ## Note
/// This generic DOM library returns "application/xml".
/// HTML documents would return "text/html".
pub export fn dom_document_get_contenttype(handle: *DOMDocument) [*:0]const u8 {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const content_type = doc.getContentType();
    return zigStringToCString(content_type);
}

/// Get doctype attribute.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DocumentType? doctype;
/// ```
///
/// ## Returns
/// DocumentType node or NULL if none exists
///
/// ## Spec References
/// - https://dom.spec.whatwg.org/#dom-document-doctype
/// - https://developer.mozilla.org/en-US/docs/Web/API/Document/doctype
///
/// ## Example (C)
/// ```c
/// DOMDocumentType* doctype = dom_document_get_doctype(doc);
/// if (doctype) {
///     const char* name = dom_documenttype_get_name(doctype);
///     printf("DOCTYPE: %s\n", name);
/// }
/// ```
pub export fn dom_document_get_doctype(handle: *DOMDocument) ?*DOMDocumentType {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const dt = doc.doctype() orelse return null;
    return @ptrCast(dt);
}

/// Get documentElement attribute
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? documentElement;
/// ```
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-document-documentelement
/// - WebIDL: dom.idl:291
///
/// ## Returns
/// The document's root element (first Element child), or NULL if none exists.
///
/// ## Example
/// ```c
/// DOMDocument* doc = dom_document_new();
/// DOMElement* root = dom_document_get_documentelement(doc);
/// // root is NULL (empty document)
///
/// DOMElement* elem = dom_document_createelement(doc, "root");
/// dom_node_appendchild((DOMNode*)doc, (DOMNode*)elem);
/// root = dom_document_get_documentelement(doc);
/// // root == elem
/// ```
pub export fn dom_document_get_documentelement(handle: *DOMDocument) ?*DOMElement {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const elem_opt = doc.documentElement();
    if (elem_opt) |elem| {
        return @ptrCast(elem);
    }
    return null;
}

/// Get elements by tag name.
///
/// ## WebIDL
/// ```webidl
/// HTMLCollection getElementsByTagName(DOMString qualifiedName);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `qualifiedName`: Tag name to search for (case-insensitive for HTML, case-sensitive for XML)
///
/// ## Returns
/// Live HTMLCollection of matching elements (caller must release)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-getelementsbytagname
/// - WebIDL: dom.idl:292
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByTagName
///
/// ## Note
/// The returned collection is live - it automatically updates when DOM changes.
/// Special value "*" matches all elements.
///
/// ## Example
/// ```c
/// DOMHTMLCollection* divs = dom_document_getelementsbytagname(doc, "div");
/// uint32_t count = dom_htmlcollection_get_length(divs);
/// for (uint32_t i = 0; i < count; i++) {
///     DOMElement* elem = dom_htmlcollection_item(divs, i);
///     // Process element
/// }
/// dom_htmlcollection_release(divs);
/// ```
pub export fn dom_document_getelementsbytagname(handle: *DOMDocument, qualifiedName: [*:0]const u8) *DOMHTMLCollection {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const tag_name = cStringToZigString(qualifiedName);

    // getElementsByTagName returns a value type, need to allocate
    const collection = doc.getElementsByTagName(tag_name);
    const collection_ptr = std.heap.c_allocator.create(HTMLCollection) catch {
        @panic("Failed to allocate HTMLCollection");
    };
    collection_ptr.* = collection;

    return @ptrCast(collection_ptr);
}

/// Get elements by namespace and local name.
///
/// ## WebIDL
/// ```webidl
/// HTMLCollection getElementsByTagNameNS(DOMString? namespace, DOMString localName);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `namespace`: Namespace URI (NULL for no namespace, "*" for any namespace)
/// - `localName`: Local name to search for ("*" matches all local names)
///
/// ## Returns
/// Live HTMLCollection of matching elements (caller must release)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-getelementsbytagnamens
/// - WebIDL: dom.idl:293
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByTagNameNS
///
/// ## Note
/// The returned collection is live - it automatically updates when DOM changes.
/// Use "*" for namespace to match any namespace.
///
/// ## Example
/// ```c
/// // Find SVG circles
/// DOMHTMLCollection* circles = dom_document_getelementsbytagnamens(
///     doc, "http://www.w3.org/2000/svg", "circle");
/// dom_htmlcollection_release(circles);
/// ```
pub export fn dom_document_getelementsbytagnamens(handle: *DOMDocument, namespace: ?[*:0]const u8, localName: [*:0]const u8) *DOMHTMLCollection {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const local_name = cStringToZigString(localName);

    // getElementsByTagNameNS returns a value type, need to allocate
    const collection = doc.getElementsByTagNameNS(ns, local_name);
    const collection_ptr = std.heap.c_allocator.create(HTMLCollection) catch {
        @panic("Failed to allocate HTMLCollection");
    };
    collection_ptr.* = collection;

    return @ptrCast(collection_ptr);
}

/// Get elements by class name(s).
///
/// ## WebIDL
/// ```webidl
/// HTMLCollection getElementsByClassName(DOMString classNames);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `classNames`: Space-separated list of class names
///
/// ## Returns
/// Live HTMLCollection of matching elements (caller must release)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-getelementsbyclassname
/// - WebIDL: dom.idl:294
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByClassName
///
/// ## Note
/// The returned collection is live - it automatically updates when DOM changes.
/// Elements must have ALL specified classes to match.
///
/// ## Example
/// ```c
/// // Find elements with both "button" and "primary" classes
/// DOMHTMLCollection* buttons = dom_document_getelementsbyclassname(doc, "button primary");
/// uint32_t count = dom_htmlcollection_get_length(buttons);
/// dom_htmlcollection_release(buttons);
/// ```
pub export fn dom_document_getelementsbyclassname(handle: *DOMDocument, classNames: [*:0]const u8) *DOMHTMLCollection {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const class_names = cStringToZigString(classNames);

    // getElementsByClassName returns a value type, need to allocate
    const collection = doc.getElementsByClassName(class_names);
    const collection_ptr = std.heap.c_allocator.create(HTMLCollection) catch {
        @panic("Failed to allocate HTMLCollection");
    };
    collection_ptr.* = collection;

    return @ptrCast(collection_ptr);
}

/// Get element by ID.
///
/// ## WebIDL
/// ```webidl
/// Element? getElementById(DOMString elementId);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `elementId`: ID value to search for
///
/// ## Returns
/// Element with matching ID, or NULL if not found
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-getelementbyid
/// - WebIDL: dom.idl:295
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementById
///
/// ## Performance
/// - Uses optimized ID map with caching (~2-84ns typical)
/// - Faster than querySelector for ID lookups
///
/// ## Note
/// Only searches connected elements (attached to document tree).
/// Returns first match if multiple elements share same ID (invalid but handled).
///
/// ## Example
/// ```c
/// DOMElement* elem = dom_document_getelementbyid(doc, "my-element");
/// if (elem) {
///     // Process element
/// }
/// ```
pub export fn dom_document_getelementbyid(handle: *DOMDocument, elementId: [*:0]const u8) ?*DOMElement {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const id = cStringToZigString(elementId);
    const elem_opt = doc.getElementById(id);
    if (elem_opt) |elem| {
        return @ptrCast(elem);
    }
    return null;
}

// SKIPPED: createElement() - Contains complex types not supported in C-ABI v1
// WebIDL: Element createElement(DOMString localName, (DOMString or ElementCreationOptions) options);
// Reason: Union type '(DOMString or ElementCreationOptions)'
// MANUALLY ADDED: Simple version without options parameter

/// createElement method (simplified - no options)
///
/// WebIDL: `Element createElement(DOMString localName);`
pub export fn dom_document_createelement(handle: *DOMDocument, localName: [*:0]const u8) *DOMElement {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(localName);
    const elem = doc.createElement(name) catch {
        @panic("createElement failed - cannot return error via C-ABI");
    };
    return @ptrCast(elem);
}

// SKIPPED: createElementNS() - Contains complex types not supported in C-ABI v1
// WebIDL: Element createElementNS(DOMString namespace, DOMString qualifiedName, (DOMString or ElementCreationOptions) options);
// Reason: Union type '(DOMString or ElementCreationOptions)'
// MANUALLY ADDED: Simple version without options parameter

/// createElementNS method (simplified - no options)
///
/// WebIDL: `Element createElementNS(DOMString? namespace, DOMString qualifiedName);`
pub export fn dom_document_createelementns(handle: *DOMDocument, namespace: ?[*:0]const u8, qualifiedName: [*:0]const u8) *DOMElement {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const name = cStringToZigString(qualifiedName);
    const elem = doc.createElementNS(ns, name) catch {
        @panic("createElementNS failed - cannot return error via C-ABI");
    };
    return @ptrCast(elem);
}

/// createDocumentFragment method
///
/// WebIDL: `DocumentFragment createDocumentFragment();`
export fn dom_document_createdocumentfragment(handle: *DOMDocument) *DOMDocumentFragment {
    _ = handle;
    // TODO: Implement method
    @panic("TODO: Non-nullable pointer return");
}

/// createTextNode method
///
/// WebIDL: `Text createTextNode(DOMString data);`
pub export fn dom_document_createtextnode(handle: *DOMDocument, data: [*:0]const u8) *DOMText {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const text_data = cStringToZigString(data);
    const text_node = doc.createTextNode(text_data) catch {
        @panic("createTextNode failed - cannot return error via C-ABI");
    };
    return @ptrCast(text_node);
}

/// Creates a new CDATASection node.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] CDATASection createCDATASection(DOMString data);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `data`: Text content for the CDATA section
///
/// ## Returns
/// New CDATASection node with ref_count=1 (caller must release)
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-document-createcdatasection
/// - WebIDL: dom.idl:303
pub export fn dom_document_createcdatasection(handle: *DOMDocument, data: [*:0]const u8) *DOMCDATASection {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const cdata_data = cStringToZigString(data);
    const cdata_node = doc.createCDATASection(cdata_data) catch {
        @panic("createCDATASection failed - cannot return error via C-ABI");
    };
    return @ptrCast(cdata_node);
}

/// createComment method
///
/// WebIDL: `Comment createComment(DOMString data);`
pub export fn dom_document_createcomment(handle: *DOMDocument, data: [*:0]const u8) *DOMComment {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const comment_data = cStringToZigString(data);
    const comment_node = doc.createComment(comment_data) catch {
        @panic("createComment failed - cannot return error via C-ABI");
    };
    return @ptrCast(comment_node);
}

/// Creates a new ProcessingInstruction node.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] ProcessingInstruction createProcessingInstruction(DOMString target, DOMString data);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `target`: Target application name (e.g., "xml-stylesheet")
/// - `data`: Processing instruction data
///
/// ## Returns
/// New ProcessingInstruction node with ref_count=1 (caller must release)
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-document-createprocessinginstruction
/// - WebIDL: dom.idl:304
pub export fn dom_document_createprocessinginstruction(handle: *DOMDocument, target: [*:0]const u8, data: [*:0]const u8) *DOMProcessingInstruction {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const target_str = cStringToZigString(target);
    const data_str = cStringToZigString(data);
    const pi_node = doc.createProcessingInstruction(target_str, data_str) catch {
        @panic("createProcessingInstruction failed - cannot return error via C-ABI");
    };
    return @ptrCast(pi_node);
}

/// Import a node from another document.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, NewObject] Node importNode(Node node, optional boolean deep = false);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `node`: Node to import
/// - `deep`: If non-zero, deep clone; if zero, shallow clone
///
/// ## Returns
/// New node in this document's context (caller must release)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-importnode
/// - WebIDL: dom.idl:300
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Document/importNode
///
/// ## Note
/// The original node is not altered. The returned node is a copy owned by this document.
/// For C-ABI, we simplify the union type `(boolean or ImportNodeOptions)` to just boolean.
pub export fn dom_document_importnode(handle: *DOMDocument, node: *DOMNode, deep: u8) *DOMNode {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const source_node: *Node = @ptrCast(@alignCast(node));
    const deep_bool = (deep != 0);

    const result = doc.importNode(source_node, deep_bool) catch {
        @panic("importNode failed - cannot return error via C-ABI");
    };

    return @ptrCast(result);
}

/// Adopt a node from another document.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] Node adoptNode(Node node);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `node`: Node to adopt
///
/// ## Returns
/// The adopted node (same pointer, but now owned by this document)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-adoptnode
/// - WebIDL: dom.idl:299
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Document/adoptNode
///
/// ## Note
/// Unlike importNode, adoptNode transfers ownership rather than cloning.
/// The node is removed from its original document and adopted by this document.
pub export fn dom_document_adoptnode(handle: *DOMDocument, node: *DOMNode) *DOMNode {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const adopt_node: *Node = @ptrCast(@alignCast(node));

    const result = doc.adoptNode(adopt_node) catch {
        @panic("adoptNode failed - cannot return error via C-ABI");
    };

    return @ptrCast(result);
}

/// Creates a new Attr node.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] Attr createAttribute(DOMString localName);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `localName`: Attribute name
///
/// ## Returns
/// New Attr node with ref_count=1 (caller must release)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-createattribute
/// - WebIDL: dom.idl:304
pub export fn dom_document_createattribute(handle: *DOMDocument, localName: [*:0]const u8) *DOMAttr {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(localName);
    const attr = doc.createAttribute(name) catch {
        @panic("createAttribute failed - cannot return error via C-ABI");
    };
    return @ptrCast(attr);
}

/// Creates a new namespaced Attr node.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] Attr createAttributeNS(DOMString? namespace, DOMString qualifiedName);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `namespace`: Namespace URI (NULL for no namespace)
/// - `qualifiedName`: Qualified name (e.g., "xml:lang")
///
/// ## Returns
/// New Attr node with ref_count=1 (caller must release)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-createattributens
/// - WebIDL: dom.idl:305
pub export fn dom_document_createattributens(handle: *DOMDocument, namespace: ?[*:0]const u8, qualifiedName: [*:0]const u8) *DOMAttr {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const name = cStringToZigString(qualifiedName);
    const attr = doc.createAttributeNS(ns, name) catch {
        @panic("createAttributeNS failed - cannot return error via C-ABI");
    };
    return @ptrCast(attr);
}

/// createEvent method
///
/// WebIDL: `Event createEvent(DOMString interface);`
export fn dom_document_createevent(handle: *DOMDocument, interface: [*:0]const u8) *DOMEvent {
    _ = handle;
    _ = interface;
    // TODO: Implement method
    @panic("TODO: Non-nullable pointer return");
}

/// Create a new Range.
///
/// Creates a collapsed range positioned at the start of the document.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] Range createRange();
/// ```
///
/// ## Returns
/// New Range object (must be released by caller with dom_range_release)
///
/// ## Example
/// ```c
/// DOMDocument* doc = dom_document_new();
/// DOMRange* range = dom_document_createrange(doc);
///
/// // Use range...
///
/// dom_range_release(range);
/// dom_document_release(doc);
/// ```
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-document-createrange
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Document/createRange
/// - WebIDL: dom.idl:309
pub export fn dom_document_createrange(handle: *DOMDocument) *DOMRange {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const range = doc.createRange() catch {
        @panic("createRange failed - cannot return error via C-ABI");
    };
    return @ptrCast(range);
}

/// createNodeIterator method
///
/// WebIDL: `NodeIterator createNodeIterator(Node root, unsigned long whatToShow, NodeFilter filter);`
export fn dom_document_createnodeiterator(handle: *DOMDocument, root: *DOMNode, whatToShow: u32, filter: ?*DOMNodeFilter) *DOMNodeIterator {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const root_node: *dom.Node = @ptrCast(@alignCast(root));

    // Note: filter parameter ignored for now (NodeFilter C-ABI not yet implemented)
    _ = filter;

    const iterator = doc.createNodeIterator(root_node, whatToShow, null) catch {
        @panic("NodeIterator creation failed");
    };

    return @ptrCast(iterator);
}

/// createTreeWalker method
///
/// WebIDL: `TreeWalker createTreeWalker(Node root, unsigned long whatToShow, NodeFilter filter);`
export fn dom_document_createtreewalker(handle: *DOMDocument, root: *DOMNode, whatToShow: u32, filter: ?*DOMNodeFilter) *DOMTreeWalker {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const root_node: *dom.Node = @ptrCast(@alignCast(root));

    // Note: filter parameter ignored for now (NodeFilter C-ABI not yet implemented)
    _ = filter;

    const walker = doc.createTreeWalker(root_node, whatToShow, null) catch {
        @panic("TreeWalker creation failed");
    };

    return @ptrCast(walker);
}
/// querySelector method
///
/// WebIDL: `Element? querySelector(DOMString selectors);`
pub export fn dom_document_queryselector(handle: *DOMDocument, selectors: [*:0]const u8) ?*DOMElement {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const selector_string = cStringToZigString(selectors);

    const result = doc.querySelector(selector_string) catch {
        return null; // On error, return null
    };

    return if (result) |elem| @ptrCast(elem) else null;
}

/// Query all matching elements with CSS selector.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] NodeList querySelectorAll(DOMString selectors);
/// ```
///
/// ## Parameters
/// - `handle`: Document handle
/// - `selectors`: CSS selector string
///
/// ## Returns
/// Static NodeList of matching elements (caller must free with dom_nodelist_static_release)
/// Returns NULL on error or empty result
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-queryselectorall
/// - WebIDL: dom.idl:171
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelectorAll
///
/// ## Note
/// Returns a static snapshot (not live) of matching elements at query time.
/// Use dom_nodelist_static_get_length() and dom_nodelist_static_item() to access results.
///
/// ## Example
/// ```c
/// DOMNodeList* results = dom_document_queryselectorall(doc, ".button");
/// if (results) {
///     uint32_t count = dom_nodelist_static_get_length(results);
///     for (uint32_t i = 0; i < count; i++) {
///         DOMNode* node = dom_nodelist_static_item(results, i);
///         DOMElement* elem = (DOMElement*)node;
///         // Process element
///     }
///     dom_nodelist_static_release(results);
/// }
/// ```
pub export fn dom_document_queryselectorall(handle: *DOMDocument, selectors: [*:0]const u8) ?*dom_types.DOMNodeList {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const selector_string = cStringToZigString(selectors);

    const results = doc.querySelectorAll(selector_string) catch {
        return null;
    };

    if (results.len == 0) {
        return null;
    }

    // For C-ABI, create a static snapshot wrapper
    const allocator = std.heap.c_allocator;

    // Duplicate the slice so it persists
    const heap_results = allocator.dupe(*Element, results) catch {
        return null;
    };

    // Create wrapper
    const wrapper = allocator.create(StaticNodeList) catch {
        allocator.free(heap_results);
        return null;
    };

    wrapper.* = StaticNodeList{
        .elements = heap_results.ptr,
        .count = heap_results.len,
    };

    return @ptrCast(wrapper);
}

// ============================================================================
// Static NodeList structure (for querySelectorAll results)
// ============================================================================

/// Static NodeList wrapper for querySelectorAll results
const StaticNodeList = struct {
    elements: [*]*Element,
    count: usize,

    pub fn length(self: *const StaticNodeList) u32 {
        return @intCast(self.count);
    }

    pub fn item(self: *const StaticNodeList, index: u32) ?*Node {
        if (index >= self.count) {
            return null;
        }
        return &self.elements[index].prototype;
    }
};

/// Get length of static NodeList from querySelectorAll.
///
/// ## Parameters
/// - `list`: NodeList handle from querySelectorAll
///
/// ## Returns
/// Number of elements in the static snapshot
pub export fn dom_nodelist_static_get_length(list: *dom_types.DOMNodeList) u32 {
    const static_list: *StaticNodeList = @ptrCast(@alignCast(list));
    return static_list.length();
}

/// Get element at index from static NodeList.
///
/// ## Parameters
/// - `list`: NodeList handle from querySelectorAll
/// - `index`: Zero-based index
///
/// ## Returns
/// Node at index, or NULL if out of bounds
pub export fn dom_nodelist_static_item(list: *dom_types.DOMNodeList, index: u32) ?*DOMNode {
    const static_list: *StaticNodeList = @ptrCast(@alignCast(list));
    const node_opt = static_list.item(index);
    if (node_opt) |n| {
        return @ptrCast(n);
    }
    return null;
}

/// Release static NodeList from querySelectorAll.
///
/// ## Parameters
/// - `list`: NodeList handle to release
///
/// ## Note
/// This frees the static snapshot array and wrapper, not the elements themselves.
pub export fn dom_nodelist_static_release(list: *dom_types.DOMNodeList) void {
    const allocator = std.heap.c_allocator;
    const static_list: *StaticNodeList = @ptrCast(@alignCast(list));
    const slice = static_list.elements[0..static_list.count];
    allocator.free(slice);
    allocator.destroy(static_list);
}

// ============================================================================
// Node API Delegation (Convenience Methods)
// ============================================================================
// These methods delegate to the Node interface for convenience, avoiding the
// need to cast Document to Node in C code.

/// Append a child node to this document
///
/// WebIDL: `Node appendChild(Node node);` (inherited from Node)
pub export fn dom_document_appendchild(handle: *DOMDocument, child: *DOMNode) ?*DOMNode {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const child_node: *Node = @ptrCast(@alignCast(child));
    const result = doc.appendChild(child_node) catch return null;
    return @ptrCast(result);
}

/// Insert a node before a reference child
///
/// WebIDL: `Node insertBefore(Node node, Node? child);` (inherited from Node)
pub export fn dom_document_insertbefore(handle: *DOMDocument, node: *DOMNode, child: ?*DOMNode) ?*DOMNode {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const new_node: *Node = @ptrCast(@alignCast(node));
    const child_node: ?*Node = if (child) |c| @as(*Node, @ptrCast(@alignCast(c))) else null;
    const result = doc.insertBefore(new_node, child_node) catch return null;
    return @ptrCast(result);
}

/// Remove a child node from this document
///
/// WebIDL: `Node removeChild(Node child);` (inherited from Node)
pub export fn dom_document_removechild(handle: *DOMDocument, child: *DOMNode) ?*DOMNode {
    const doc: *Document = @ptrCast(@alignCast(handle));
    const child_node: *Node = @ptrCast(@alignCast(child));
    const result = doc.removeChild(child_node) catch return null;
    return @ptrCast(result);
}

/// Check if this document has any child nodes
///
/// WebIDL: `boolean hasChildNodes();` (inherited from Node)
pub export fn dom_document_haschildnodes(handle: *DOMDocument) u8 {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    return if (doc.hasChildNodes()) 1 else 0;
}

/// Get the first child node
///
/// WebIDL: `readonly attribute Node? firstChild;` (inherited from Node)
pub export fn dom_document_get_firstchild(handle: *DOMDocument) ?*DOMNode {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const child = doc.firstChild() orelse return null;
    return @ptrCast(child);
}

/// Get the last child node
///
/// WebIDL: `readonly attribute Node? lastChild;` (inherited from Node)
pub export fn dom_document_get_lastchild(handle: *DOMDocument) ?*DOMNode {
    const doc: *const Document = @ptrCast(@alignCast(handle));
    const child = doc.lastChild() orelse return null;
    return @ptrCast(child);
}

// ============================================================================
// Document Lifecycle
// ============================================================================

/// Create a new Document (not in WebIDL - C-ABI specific)
///
/// Creates a new DOM Document. The caller must call dom_document_release() when done.
///
/// Note: Requires an allocator. For now, uses a global page allocator.
/// Future: Add dom_document_new_with_allocator() variant.
pub export fn dom_document_new() *DOMDocument {
    const allocator = std.heap.page_allocator;
    const doc = Document.init(allocator) catch {
        @panic("Document.init failed - out of memory");
    };
    return @ptrCast(doc);
}

/// Increase reference count
pub export fn dom_document_addref(handle: *DOMDocument) void {
    const doc: *Document = @ptrCast(@alignCast(handle));
    doc.acquire();
}

/// Decrease reference count
pub export fn dom_document_release(handle: *DOMDocument) void {
    const doc: *Document = @ptrCast(@alignCast(handle));
    doc.release();
}
