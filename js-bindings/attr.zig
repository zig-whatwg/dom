//! Attr C-ABI Bindings
//!
//! C-ABI bindings for the Attr interface per WHATWG DOM specification.
//! Attr represents attributes as nodes, providing an object-oriented view
//! of element attributes.
//!
//! ## C API Overview
//!
//! ```c
//! // Create Attr
//! DOMAttr* dom_document_createattribute(DOMDocument* doc, const char* localName);
//! DOMAttr* dom_document_createattributens(DOMDocument* doc, const char* ns, const char* qualifiedName);
//!
//! // Properties (readonly except value)
//! const char* dom_attr_get_namespaceuri(DOMAttr* attr);  // nullable
//! const char* dom_attr_get_prefix(DOMAttr* attr);        // nullable
//! const char* dom_attr_get_localname(DOMAttr* attr);
//! const char* dom_attr_get_name(DOMAttr* attr);
//! const char* dom_attr_get_value(DOMAttr* attr);
//! int dom_attr_set_value(DOMAttr* attr, const char* value);
//! DOMElement* dom_attr_get_ownerelement(DOMAttr* attr); // nullable
//! uint8_t dom_attr_get_specified(DOMAttr* attr);        // always 1 (legacy)
//!
//! // Reference counting
//! void dom_attr_addref(DOMAttr* attr);
//! void dom_attr_release(DOMAttr* attr);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface Attr : Node {
//!   readonly attribute DOMString? namespaceURI;
//!   readonly attribute DOMString? prefix;
//!   readonly attribute DOMString localName;
//!   readonly attribute DOMString name;
//!   [CEReactions] attribute DOMString value;
//!
//!   readonly attribute Element? ownerElement;
//!
//!   readonly attribute boolean specified; // useless; always returns true
//! };
//! ```
//!
//! ## WHATWG Specification
//!
//! - Attr interface: https://dom.spec.whatwg.org/#interface-attr
//! - Document.createAttribute: https://dom.spec.whatwg.org/#dom-document-createattribute
//!
//! ## MDN Documentation
//!
//! - Attr: https://developer.mozilla.org/en-US/docs/Web/API/Attr
//! - Attr.name: https://developer.mozilla.org/en-US/docs/Web/API/Attr/name
//! - Attr.value: https://developer.mozilla.org/en-US/docs/Web/API/Attr/value

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const Attr = dom.Attr;
const Element = dom.Element;
const DOMAttr = types.DOMAttr;
const DOMElement = types.DOMElement;
const zigStringToCString = types.zigStringToCString;
const zigStringToCStringOptional = types.zigStringToCStringOptional;
const cStringToZigString = types.cStringToZigString;
const zigErrorToDOMError = types.zigErrorToDOMError;

// ============================================================================
// Properties (Readonly)
// ============================================================================

/// Get the namespace URI of an attribute.
///
/// Returns the namespace URI for namespaced attributes, or null for
/// non-namespaced attributes.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString? namespaceURI;
/// ```
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Returns
/// Namespace URI (borrowed, do NOT free), or NULL for non-namespaced attributes
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattributens(doc, "http://www.w3.org/XML/1998/namespace", "xml:lang");
/// const char* ns = dom_attr_get_namespaceuri(attr);
/// if (ns != NULL) {
///     printf("Namespace: %s\n", ns);
/// }
/// dom_attr_release(attr);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-attr-namespaceuri
/// - https://developer.mozilla.org/en-US/docs/Web/API/Attr/namespaceURI
pub export fn dom_attr_get_namespaceuri(attr: *DOMAttr) ?[*:0]const u8 {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    return zigStringToCStringOptional(attr_node.namespace_uri);
}

/// Get the namespace prefix of an attribute.
///
/// Returns the namespace prefix for namespaced attributes (e.g., "xml" in "xml:lang"),
/// or null for non-namespaced attributes or default namespace.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString? prefix;
/// ```
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Returns
/// Namespace prefix (borrowed, do NOT free), or NULL
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattributens(doc, "http://www.w3.org/XML/1998/namespace", "xml:lang");
/// const char* prefix = dom_attr_get_prefix(attr);
/// if (prefix != NULL) {
///     printf("Prefix: %s\n", prefix);  // "xml"
/// }
/// dom_attr_release(attr);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-attr-prefix
/// - https://developer.mozilla.org/en-US/docs/Web/API/Attr/prefix
pub export fn dom_attr_get_prefix(attr: *DOMAttr) ?[*:0]const u8 {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    return zigStringToCStringOptional(attr_node.prefix);
}

/// Get the local name of an attribute.
///
/// Returns the local name without any namespace prefix.
/// For example, "lang" in "xml:lang".
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString localName;
/// ```
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Returns
/// Local name (borrowed, do NOT free)
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattributens(doc, "http://www.w3.org/XML/1998/namespace", "xml:lang");
/// const char* local = dom_attr_get_localname(attr);
/// printf("Local name: %s\n", local);  // "lang"
/// dom_attr_release(attr);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-attr-localname
/// - https://developer.mozilla.org/en-US/docs/Web/API/Attr/localName
pub export fn dom_attr_get_localname(attr: *DOMAttr) [*:0]const u8 {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    return zigStringToCString(attr_node.local_name);
}

/// Get the qualified name of an attribute.
///
/// Returns the qualified name including prefix if present.
/// For example, "xml:lang" or "id".
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString name;
/// ```
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Returns
/// Qualified name (borrowed, do NOT free)
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattribute(doc, "class");
/// const char* name = dom_attr_get_name(attr);
/// printf("Name: %s\n", name);  // "class"
/// dom_attr_release(attr);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-attr-name
/// - https://developer.mozilla.org/en-US/docs/Web/API/Attr/name
pub export fn dom_attr_get_name(attr: *DOMAttr) [*:0]const u8 {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    const name_str = attr_node.name();
    return zigStringToCString(name_str);
}

/// Get the value of an attribute.
///
/// Returns the attribute's value as a string.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] attribute DOMString value;
/// ```
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Returns
/// Attribute value (borrowed, do NOT free)
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattribute(doc, "id");
/// dom_attr_set_value(attr, "main-content");
/// const char* value = dom_attr_get_value(attr);
/// printf("Value: %s\n", value);  // "main-content"
/// dom_attr_release(attr);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-attr-value
/// - https://developer.mozilla.org/en-US/docs/Web/API/Attr/value
pub export fn dom_attr_get_value(attr: *DOMAttr) [*:0]const u8 {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    const value_str = attr_node.value();
    return zigStringToCString(value_str);
}

/// Set the value of an attribute.
///
/// Updates the attribute's value. If the attribute is attached to an element,
/// this triggers attribute change notifications.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] attribute DOMString value;
/// ```
///
/// ## Parameters
/// - `attr`: Attr handle
/// - `value`: New attribute value
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattribute(doc, "class");
/// int result = dom_attr_set_value(attr, "btn btn-primary");
/// if (result != 0) {
///     printf("Error setting value\n");
/// }
/// dom_attr_release(attr);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-attr-value
/// - https://developer.mozilla.org/en-US/docs/Web/API/Attr/value
pub export fn dom_attr_set_value(attr: *DOMAttr, value: [*:0]const u8) c_int {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    const value_slice = cStringToZigString(value);

    attr_node.setValue(value_slice) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0; // Success
}

/// Get the owner element of an attribute.
///
/// Returns the Element node that this attribute is attached to, or null
/// if the attribute is not currently attached to any element.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? ownerElement;
/// ```
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Returns
/// Owner element or NULL if not attached
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattribute(doc, "id");
///
/// // Before attaching
/// DOMElement* owner = dom_attr_get_ownerelement(attr);
/// assert(owner == NULL);
///
/// // After attaching
/// dom_element_setattributenode(elem, attr);
/// owner = dom_attr_get_ownerelement(attr);
/// assert(owner == elem);
///
/// dom_attr_release(attr);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-attr-ownerelement
/// - https://developer.mozilla.org/en-US/docs/Web/API/Attr/ownerElement
pub export fn dom_attr_get_ownerelement(attr: *DOMAttr) ?*DOMElement {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    if (attr_node.owner_element) |owner| {
        return @ptrCast(@alignCast(owner));
    }
    return null;
}

/// Get the specified property (always returns true).
///
/// This property is useless and always returns true. It exists only for
/// legacy compatibility.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean specified; // useless; always returns true
/// ```
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Returns
/// Always 1 (true)
///
/// ## Note
/// Per WHATWG spec, this property is "useless" and always returns true.
/// It exists only for historical compatibility with older DOM specifications.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-attr-specified
/// - https://developer.mozilla.org/en-US/docs/Web/API/Attr/specified
pub export fn dom_attr_get_specified(attr: *DOMAttr) u8 {
    _ = attr;
    return 1; // Always true per spec
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of an Attr node.
///
/// Call this when sharing an Attr node reference.
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattribute(doc, "id");
///
/// // Share with another owner
/// dom_attr_addref(attr);
/// other_owner = attr;
///
/// // Both owners must release
/// dom_attr_release(attr);
/// dom_attr_release(attr);
/// ```
pub export fn dom_attr_addref(attr: *DOMAttr) void {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    attr_node.acquire();
}

/// Decrement the reference count of an Attr node.
///
/// Call this when done with an Attr node. When ref count reaches 0,
/// the node is freed.
///
/// ## Parameters
/// - `attr`: Attr handle
///
/// ## Example
/// ```c
/// DOMAttr* attr = dom_document_createattribute(doc, "class");
/// // ... use attr ...
/// dom_attr_release(attr);  // Frees if ref_count reaches 0
/// ```
pub export fn dom_attr_release(attr: *DOMAttr) void {
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    attr_node.release();
}
