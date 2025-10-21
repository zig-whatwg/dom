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

/// Get URL attribute
///
/// WebIDL: `readonly attribute USVString URL;`
export fn dom_document_get_url(handle: *DOMDocument) [*:0]const u8 {
    _ = handle;
    // TODO: Implement getter
    return "";
}

/// Get documentURI attribute
///
/// WebIDL: `readonly attribute USVString documentURI;`
export fn dom_document_get_documenturi(handle: *DOMDocument) [*:0]const u8 {
    _ = handle;
    // TODO: Implement getter
    return "";
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

/// Get doctype attribute
///
/// WebIDL: `readonly attribute DocumentType? doctype;`
export fn dom_document_get_doctype(handle: *DOMDocument) ?*DOMDocumentType {
    _ = handle;
    // TODO: Implement getter
    return null;
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

/// querySelectorAll method
///
/// Note: This returns the first element only for now (C-ABI limitation).
/// Full implementation requires NodeList binding.
///
/// WebIDL: `NodeList querySelectorAll(DOMString selectors);`
pub export fn dom_document_queryselectorall_first(handle: *DOMDocument, selectors: [*:0]const u8) ?*DOMElement {
    // For now, just return the first match (same as querySelector)
    // Full implementation needs NodeList binding
    return dom_document_queryselector(handle, selectors);
}

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
