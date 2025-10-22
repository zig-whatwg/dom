//! JavaScript Bindings for Element
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
pub const DOMElement = dom_types.DOMElement;
pub const DOMAttr = dom_types.DOMAttr;
pub const DOMDOMTokenList = dom_types.DOMDOMTokenList;
pub const DOMNamedNodeMap = dom_types.DOMNamedNodeMap;
pub const DOMShadowRoot = dom_types.DOMShadowRoot;
pub const DOMCustomElementRegistry = dom_types.DOMCustomElementRegistry;

// Forward declarations for types not yet in dom_types
pub const DOMHTMLCollection = opaque {};
pub const DOMShadowRootInit = opaque {};

// Import actual DOM implementation
const dom = @import("dom");
const Element = dom.Element;
const Node = dom.Node;
const Attr = dom.Attr;
const DOMTokenList = dom.DOMTokenList;

// Import TokenListWrapper from domtokenlist module
const domtokenlist_mod = @import("domtokenlist.zig");
const TokenListWrapper = domtokenlist_mod.TokenListWrapper;

/// Get namespaceURI attribute
///
/// WebIDL: `readonly attribute DOMString? namespaceURI;`
pub export fn dom_element_get_namespaceuri(handle: *DOMElement) ?[*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return zigStringToCStringOptional(element.namespace_uri);
}

/// Get prefix attribute
///
/// WebIDL: `readonly attribute DOMString? prefix;`
pub export fn dom_element_get_prefix(handle: *DOMElement) ?[*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return zigStringToCStringOptional(element.prefix);
}

/// Get localName attribute
///
/// WebIDL: `readonly attribute DOMString localName;`
pub export fn dom_element_get_localname(handle: *DOMElement) [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return zigStringToCString(element.local_name);
}

/// Get tagName attribute
///
/// WebIDL: `readonly attribute DOMString tagName;`
pub export fn dom_element_get_tagname(handle: *DOMElement) [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return zigStringToCString(element.tag_name);
}

/// Get id attribute
///
/// WebIDL: `attribute DOMString id;`
pub export fn dom_element_get_id(handle: *DOMElement) [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const value = element.getAttribute("id") orelse return "";
    return zigStringToCString(value);
}

/// Set id attribute
///
/// WebIDL: `attribute DOMString id;`
pub export fn dom_element_set_id(handle: *DOMElement, value: [*:0]const u8) c_int {
    const element: *Element = @ptrCast(@alignCast(handle));
    const zig_value = cStringToZigString(value);
    element.setAttribute("id", zig_value) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };
    return 0; // Success
}

/// Get className attribute
///
/// WebIDL: `attribute DOMString className;`
pub export fn dom_element_get_classname(handle: *DOMElement) [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const value = element.getAttribute("class") orelse return "";
    return zigStringToCString(value);
}

/// Set className attribute
///
/// WebIDL: `attribute DOMString className;`
pub export fn dom_element_set_classname(handle: *DOMElement, value: [*:0]const u8) c_int {
    const element: *Element = @ptrCast(@alignCast(handle));
    const zig_value = cStringToZigString(value);
    element.setAttribute("class", zig_value) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };
    return 0; // Success
}

/// Get classList attribute
///
/// Returns a live DOMTokenList representing the element's class tokens.
/// The returned list must be released by the caller using dom_domtokenlist_release().
///
/// WebIDL: `[SameObject, PutForwards=value] readonly attribute DOMTokenList classList;`
///
/// ## Spec References
/// - classList: https://dom.spec.whatwg.org/#dom-element-classlist
/// - DOMTokenList: https://developer.mozilla.org/en-US/docs/Web/API/Element/classList
pub export fn dom_element_get_classlist(handle: *DOMElement) *DOMDOMTokenList {
    const allocator = std.heap.page_allocator;
    const elem: *Element = @ptrCast(@alignCast(handle));

    // Get DOMTokenList value from Element
    const token_list = elem.classList();

    // Heap-allocate wrapper for C-ABI (includes token cache)
    const wrapper = allocator.create(TokenListWrapper) catch {
        @panic("Failed to allocate TokenListWrapper");
    };
    wrapper.* = .{
        .token_list = token_list,
        .next_buffer_index = 0,
    };

    return @ptrCast(wrapper);
}

/// Get slot attribute
///
/// WebIDL: `attribute DOMString slot;`
/// Get slot attribute.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] attribute DOMString slot;
/// ```
///
/// ## Returns
/// The slot attribute value, or empty string if not set (do NOT free)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-element-slot
/// - WebIDL: dom.idl:371
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/slot
///
/// ## Note
/// The slot attribute specifies which <slot> element in a shadow tree this element should be assigned to.
pub export fn dom_element_get_slot(handle: *DOMElement) [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const slot_value = element.getAttribute("slot") orelse return "";
    return zigStringToCString(slot_value);
}

/// Set slot attribute.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] attribute DOMString slot;
/// ```
///
/// ## Parameters
/// - `handle`: Element handle
/// - `value`: Slot name to assign
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-element-slot
/// - WebIDL: dom.idl:371
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/slot
///
/// ## Example
/// ```c
/// // Assign element to slot named "header"
/// dom_element_set_slot(elem, "header");
/// ```
pub export fn dom_element_set_slot(handle: *DOMElement, value: [*:0]const u8) c_int {
    const element: *Element = @ptrCast(@alignCast(handle));
    const slot_name = cStringToZigString(value);
    element.setAttribute("slot", slot_name) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };
    return 0; // Success
}

/// Get the assigned slot element (Slottable mixin).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute HTMLSlotElement? assignedSlot;
/// ```
///
/// ## Returns
/// The slot element this element is assigned to, or NULL if not assigned
/// (borrowed reference - do NOT release)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-slottable-assignedslot
/// - WebIDL: dom.idl:155 (Slottable mixin)
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/assignedSlot
///
/// ## Note
/// The assignedSlot is the <slot> element in a shadow tree that this element
/// is distributed to. Only meaningful for elements in light DOM that are
/// children of a shadow host.
///
/// ## Example
/// ```c
/// // Check if element is assigned to a slot
/// DOMElement* slot = dom_element_get_assignedslot(elem);
/// if (slot) {
///     printf("Element is in slot: %s\n", dom_element_get_tagname(slot));
/// }
/// ```
pub export fn dom_element_get_assignedslot(handle: *DOMElement) ?*DOMElement {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const slot = element.assignedSlot();
    return if (slot) |s| @ptrCast(s) else null;
}

/// Get attributes as NamedNodeMap.
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute NamedNodeMap attributes;
/// ```
///
/// ## Returns
/// NamedNodeMap providing access to element's attributes
/// (borrowed reference - do NOT release)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-element-attributes
/// - WebIDL: dom.idl:378
///
/// ## Note
/// NamedNodeMap is a thin wrapper around Element. In C-ABI, we return the Element
/// pointer directly - NamedNodeMap functions will construct the wrapper internally.
/// This maintains [SameObject] semantics (always returns same underlying Element).
///
/// ## Example
/// ```c
/// DOMNamedNodeMap* attrs = dom_element_get_attributes(elem);
/// uint32_t count = dom_namednodemap_get_length(attrs);
/// for (uint32_t i = 0; i < count; i++) {
///     DOMAttr* attr = dom_namednodemap_item(attrs, i);
///     printf("%s='%s'\n", dom_attr_get_name(attr), dom_attr_get_value(attr));
/// }
/// // Do NOT call dom_namednodemap_release(attrs)!
/// ```
pub export fn dom_element_get_attributes(handle: *DOMElement) *DOMNamedNodeMap {
    // Return Element pointer as NamedNodeMap handle
    // NamedNodeMap functions will interpret this correctly
    return @ptrCast(handle);
}

/// Get shadowRoot attribute
///
/// WebIDL: `readonly attribute ShadowRoot? shadowRoot;`
pub export fn dom_element_get_shadowroot(handle: *DOMElement) ?*DOMShadowRoot {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const shadow = element.shadowRoot() orelse return null;
    return @ptrCast(shadow);
}

/// Get customElementRegistry attribute
///
/// WebIDL: `readonly attribute CustomElementRegistry? customElementRegistry;`
pub export fn dom_element_get_customelementregistry(handle: *DOMElement) ?*DOMCustomElementRegistry {
    _ = handle;
    // TODO: Implement getter
    return null;
}

/// hasAttributes method
///
/// WebIDL: `boolean hasAttributes();`
pub export fn dom_element_hasattributes(handle: *DOMElement) u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return if (element.hasAttributes()) 1 else 0;
}

/// getAttributeNames method
///
/// WebIDL: `DOMString getAttributeNames();`
/// Get sequence of all attribute names.
///
/// ## WebIDL
/// ```webidl
/// sequence<DOMString> getAttributeNames();
/// ```
///
/// ## Algorithm
/// Returns an array of all attribute names on this element.
///
/// ## Parameters
/// - `handle`: Element handle
/// - `count`: Pointer to store the number of attribute names
///
/// ## Returns
/// Array of attribute name strings (caller must free with dom_element_free_attributenames)
/// Returns NULL if no attributes or on error.
///
/// ## Memory Management
/// The returned array is allocated and owned by the caller.
/// You MUST call dom_element_free_attributenames() when done to avoid memory leaks.
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-element-getattributenames
/// - WebIDL: dom.idl:375
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttributeNames
///
/// ## Example
/// ```c
/// uint32_t count = 0;
/// const char** names = dom_element_getattributenames(elem, &count);
/// if (names) {
///     for (uint32_t i = 0; i < count; i++) {
///         printf("Attribute: %s\n", names[i]);
///     }
///     dom_element_free_attributenames(names, count);
/// }
/// ```
pub export fn dom_element_getattributenames(handle: *DOMElement, count: *u32) ?[*]const [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const allocator = std.heap.c_allocator;

    // Get attribute names from element
    const names = element.getAttributeNames(allocator) catch return null;
    defer allocator.free(names);

    // If no attributes, return NULL
    if (names.len == 0) {
        count.* = 0;
        return null;
    }

    // Allocate array for C (array of string pointers)
    const c_array = allocator.alloc([*:0]const u8, names.len) catch return null;

    // Copy name pointers to array (names are borrowed from attributes)
    for (names, 0..) |name, i| {
        c_array[i] = zigStringToCString(name);
    }

    count.* = @intCast(names.len);
    return c_array.ptr;
}

/// Free getAttributeNames array.
///
/// ## Parameters
/// - `names`: Array returned from dom_element_getattributenames()
/// - `count`: Number of elements in the array
///
/// ## Example
/// ```c
/// uint32_t count = 0;
/// const char** names = dom_element_getattributenames(elem, &count);
/// // ... use names ...
/// dom_element_free_attributenames(names, count);
/// ```
pub export fn dom_element_free_attributenames(names: [*]const [*:0]const u8, count: u32) void {
    const allocator = std.heap.c_allocator;
    if (count > 0) {
        const slice = names[0..count];
        allocator.free(slice);
    }
}

/// getAttribute method
///
/// WebIDL: `DOMString getAttribute(DOMString qualifiedName);`
pub export fn dom_element_getattribute(handle: *DOMElement, qualifiedName: [*:0]const u8) ?[*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(qualifiedName);
    const value = element.getAttribute(name);
    return zigStringToCStringOptional(value);
}

/// getAttributeNS method
///
/// WebIDL: `DOMString getAttributeNS(DOMString namespace, DOMString localName);`
pub export fn dom_element_getattributens(handle: *DOMElement, namespace: ?[*:0]const u8, localName: [*:0]const u8) ?[*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const name = cStringToZigString(localName);
    const value = element.getAttributeNS(ns, name);
    return zigStringToCStringOptional(value);
}

/// setAttribute method
///
/// WebIDL: `undefined setAttribute(DOMString qualifiedName, DOMString value);`
pub export fn dom_element_setattribute(handle: *DOMElement, qualifiedName: [*:0]const u8, value: [*:0]const u8) c_int {
    const element: *Element = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(qualifiedName);
    const val = cStringToZigString(value);
    element.setAttribute(name, val) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };
    return 0; // Success
}

/// setAttributeNS method
///
/// WebIDL: `undefined setAttributeNS(DOMString namespace, DOMString qualifiedName, DOMString value);`
pub export fn dom_element_setattributens(handle: *DOMElement, namespace: ?[*:0]const u8, qualifiedName: [*:0]const u8, value: [*:0]const u8) c_int {
    const element: *Element = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const name = cStringToZigString(qualifiedName);
    const val = cStringToZigString(value);
    element.setAttributeNS(ns, name, val) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };
    return 0; // Success
}

/// removeAttribute method
///
/// WebIDL: `undefined removeAttribute(DOMString qualifiedName);`
pub export fn dom_element_removeattribute(handle: *DOMElement, qualifiedName: [*:0]const u8) c_int {
    const element: *Element = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(qualifiedName);
    element.removeAttribute(name);
    return 0; // Success
}

/// removeAttributeNS method
///
/// WebIDL: `undefined removeAttributeNS(DOMString namespace, DOMString localName);`
pub export fn dom_element_removeattributens(handle: *DOMElement, namespace: ?[*:0]const u8, localName: [*:0]const u8) c_int {
    const element: *Element = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const name = cStringToZigString(localName);
    element.removeAttributeNS(ns, name);
    return 0; // Success
}

/// toggleAttribute method
///
/// WebIDL: `boolean toggleAttribute(DOMString qualifiedName, boolean force);`
pub export fn dom_element_toggleattribute(handle: *DOMElement, qualifiedName: [*:0]const u8, force: u8) u8 {
    const element: *Element = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(qualifiedName);
    const force_bool = if (force != 0) true else null;
    const result = element.toggleAttribute(name, force_bool) catch {
        return 0; // Return false on error
    };
    return if (result) 1 else 0;
}

/// hasAttribute method
///
/// WebIDL: `boolean hasAttribute(DOMString qualifiedName);`
pub export fn dom_element_hasattribute(handle: *DOMElement, qualifiedName: [*:0]const u8) u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(qualifiedName);
    return if (element.hasAttribute(name)) 1 else 0;
}

/// hasAttributeNS method
///
/// WebIDL: `boolean hasAttributeNS(DOMString namespace, DOMString localName);`
pub export fn dom_element_hasattributens(handle: *DOMElement, namespace: ?[*:0]const u8, localName: [*:0]const u8) u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const name = cStringToZigString(localName);
    return if (element.hasAttributeNS(ns, name)) 1 else 0;
}

/// Returns the Attr node for the given attribute name.
///
/// ## WebIDL
/// ```webidl
/// Attr? getAttributeNode(DOMString qualifiedName);
/// ```
///
/// ## Algorithm (from DOM spec)
/// 1. Return the attribute in this's attribute list whose qualified name is qualifiedName
/// 2. If no such attribute exists, return null
///
/// ## Parameters
/// - `handle`: Element handle
/// - `qualifiedName`: Attribute name to lookup
///
/// ## Returns
/// Attr node if found, NULL otherwise (borrowed reference - do NOT release)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-element-getattributenode
/// - WebIDL: dom.idl:386
///
/// ## Example
/// ```c
/// DOMElement* elem = dom_document_createelement(doc, "item");
/// dom_element_setattribute(elem, "id", "foo");
///
/// // Get Attr node
/// DOMAttr* attr = dom_element_getattributenode(elem, "id");
/// if (attr) {
///     const char* name = dom_attr_get_name(attr);
///     const char* value = dom_attr_get_value(attr);
///     printf("%s='%s'\n", name, value); // id='foo'
///     // Do NOT call dom_attr_release(attr) - borrowed reference!
/// }
/// ```
pub export fn dom_element_getattributenode(handle: *DOMElement, qualifiedName: [*:0]const u8) ?*DOMAttr {
    const element: *Element = @ptrCast(@alignCast(handle));
    const name = cStringToZigString(qualifiedName);
    const attr_opt = element.getAttributeNode(name) catch return null;
    if (attr_opt) |attr| {
        return @ptrCast(attr);
    }
    return null;
}

/// Returns the Attr node for the given namespaced attribute.
///
/// ## WebIDL
/// ```webidl
/// Attr? getAttributeNodeNS(DOMString? namespace, DOMString localName);
/// ```
///
/// ## Algorithm (from DOM spec)
/// 1. Return the attribute in this's attribute list whose namespace is namespace and local name is localName
/// 2. If no such attribute exists, return null
///
/// ## Parameters
/// - `handle`: Element handle
/// - `namespace`: Namespace URI (NULL for no namespace)
/// - `localName`: Local name without prefix
///
/// ## Returns
/// Attr node if found, NULL otherwise (borrowed reference - do NOT release)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-element-getattributenodens
/// - WebIDL: dom.idl:387
///
/// ## Example
/// ```c
/// DOMElement* elem = dom_document_createelement(doc, "item");
/// dom_element_setattributens(elem, "http://www.w3.org/XML/1998/namespace", "xml:lang", "en");
///
/// // Get namespaced Attr node
/// DOMAttr* attr = dom_element_getattributenodens(elem, "http://www.w3.org/XML/1998/namespace", "lang");
/// if (attr) {
///     const char* localName = dom_attr_get_localname(attr);
///     const char* value = dom_attr_get_value(attr);
///     printf("%s='%s'\n", localName, value); // lang='en'
/// }
/// ```
pub export fn dom_element_getattributenodens(handle: *DOMElement, namespace: ?[*:0]const u8, localName: [*:0]const u8) ?*DOMAttr {
    const element: *Element = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const name = cStringToZigString(localName);
    const attr_opt = element.getAttributeNodeNS(ns, name) catch return null;
    if (attr_opt) |attr| {
        return @ptrCast(attr);
    }
    return null;
}

/// Sets an Attr node on the element, replacing any existing attribute with the same name.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] Attr? setAttributeNode(Attr attr);
/// ```
///
/// ## Algorithm (from DOM spec)
/// 1. If attr's element is neither null nor this, throw InUseAttributeError
/// 2. Let oldAttr be the result of getting an attribute given attr's namespace, attr's local name, and this
/// 3. If oldAttr is attr, return attr
/// 4. If oldAttr is not null, replace oldAttr with attr
/// 5. Otherwise, append attr to this
/// 6. Return oldAttr
///
/// ## Parameters
/// - `handle`: Element handle
/// - `attr`: Attr node to set (takes ownership if not already owned by this element)
///
/// ## Returns
/// The replaced Attr node if one existed, NULL otherwise
/// Caller receives ownership of returned Attr and MUST call dom_attr_release()
///
/// ## Errors
/// Returns NULL on error (InUseAttributeError if attr is owned by another element)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-element-setattributenode
/// - WebIDL: dom.idl:388
///
/// ## Example
/// ```c
/// // Create new attribute
/// DOMAttr* attr = dom_document_createattribute(doc, "class");
/// dom_attr_setvalue(attr, "highlight");
///
/// // Set on element (returns NULL if no previous attribute)
/// DOMAttr* oldAttr = dom_element_setattributenode(elem, attr);
/// if (oldAttr) {
///     // Had previous class attribute
///     const char* oldValue = dom_attr_get_value(oldAttr);
///     printf("Replaced old class: %s\n", oldValue);
///     dom_attr_release(oldAttr); // Caller must release
/// }
///
/// // attr is now owned by elem, don't release it
/// ```
pub export fn dom_element_setattributenode(handle: *DOMElement, attr: *DOMAttr) ?*DOMAttr {
    const element: *Element = @ptrCast(@alignCast(handle));
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    const old_attr_opt = element.setAttributeNode(attr_node) catch return null;
    if (old_attr_opt) |old| {
        return @ptrCast(old);
    }
    return null;
}

/// Sets a namespaced Attr node on the element.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] Attr? setAttributeNodeNS(Attr attr);
/// ```
///
/// ## Algorithm (from DOM spec)
/// Same as setAttributeNode() but uses namespace-aware matching.
///
/// ## Parameters
/// - `handle`: Element handle
/// - `attr`: Namespaced Attr node to set
///
/// ## Returns
/// The replaced Attr node if one existed, NULL otherwise
/// Caller receives ownership of returned Attr and MUST call dom_attr_release()
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-element-setattributenodens
/// - WebIDL: dom.idl:389
///
/// ## Example
/// ```c
/// // Create namespaced attribute
/// DOMAttr* attr = dom_document_createattributens(
///     doc,
///     "http://www.w3.org/XML/1998/namespace",
///     "xml:lang"
/// );
/// dom_attr_setvalue(attr, "en");
///
/// // Set on element
/// DOMAttr* oldAttr = dom_element_setattributenodens(elem, attr);
/// if (oldAttr) {
///     dom_attr_release(oldAttr);
/// }
/// ```
pub export fn dom_element_setattributenodens(handle: *DOMElement, attr: *DOMAttr) ?*DOMAttr {
    const element: *Element = @ptrCast(@alignCast(handle));
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    const old_attr_opt = element.setAttributeNodeNS(attr_node) catch return null;
    if (old_attr_opt) |old| {
        return @ptrCast(old);
    }
    return null;
}

/// Removes an Attr node from the element.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] Attr removeAttributeNode(Attr attr);
/// ```
///
/// ## Algorithm (from DOM spec)
/// 1. If attr is not in this's attribute list, throw NotFoundError
/// 2. Remove attr from this's attribute list
/// 3. Return attr
///
/// ## Parameters
/// - `handle`: Element handle
/// - `attr`: Attr node to remove (must be owned by this element)
///
/// ## Returns
/// The removed Attr node (same as input)
/// Caller receives ownership and MUST call dom_attr_release()
///
/// ## Errors
/// Returns NULL on error (NotFoundError if attr is not an attribute of this element)
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-element-removeattributenode
/// - WebIDL: dom.idl:390
///
/// ## Example
/// ```c
/// // Get attribute node
/// DOMAttr* attr = dom_element_getattributenode(elem, "class");
/// if (attr) {
///     // Remove it
///     DOMAttr* removed = dom_element_removeattributenode(elem, attr);
///     if (removed) {
///         assert(removed == attr); // Same pointer
///         const char* value = dom_attr_get_value(removed);
///         printf("Removed class: %s\n", value);
///         dom_attr_release(removed); // Caller must release
///     }
/// }
/// ```
pub export fn dom_element_removeattributenode(handle: *DOMElement, attr: *DOMAttr) ?*DOMAttr {
    const element: *Element = @ptrCast(@alignCast(handle));
    const attr_node: *Attr = @ptrCast(@alignCast(attr));
    const removed = element.removeAttributeNode(attr_node) catch return null;
    return @ptrCast(removed);
}

// SKIPPED: attachShadow() - Contains complex types not supported in C-ABI v1
// WebIDL: ShadowRoot attachShadow(ShadowRootInit init);
// Reason: Dictionary type 'ShadowRootInit'

/// closest method
///
/// WebIDL: `Element? closest(DOMString selectors);`
pub export fn dom_element_closest(handle: *DOMElement, selectors: [*:0]const u8) ?*DOMElement {
    const element: *Element = @ptrCast(@alignCast(handle));
    const selector_string = cStringToZigString(selectors);

    // closest() requires an allocator for selector parsing
    const allocator = std.heap.page_allocator;

    const result = element.closest(allocator, selector_string) catch {
        return null; // On error, return null
    };

    return if (result) |elem| @ptrCast(elem) else null;
}

/// matches method
///
/// WebIDL: `boolean matches(DOMString selectors);`
pub export fn dom_element_matches(handle: *DOMElement, selectors: [*:0]const u8) u8 {
    const element: *Element = @ptrCast(@alignCast(handle));
    const selector_string = cStringToZigString(selectors);

    // matches() requires an allocator for selector parsing
    // Use page_allocator (should be optimized to use arena in future)
    const allocator = std.heap.page_allocator;

    const result = element.matches(allocator, selector_string) catch {
        return 0; // On error, return false
    };

    return if (result) 1 else 0;
}

/// webkitMatchesSelector method (alias for matches)
///
/// WebIDL: `boolean webkitMatchesSelector(DOMString selectors);`
pub export fn dom_element_webkitmatchesselector(handle: *DOMElement, selectors: [*:0]const u8) u8 {
    // webkitMatchesSelector is just an alias for matches
    return dom_element_matches(handle, selectors);
}

/// querySelector method
///
/// WebIDL: `Element? querySelector(DOMString selectors);`
pub export fn dom_element_queryselector(handle: *DOMElement, selectors: [*:0]const u8) ?*DOMElement {
    const element: *Element = @ptrCast(@alignCast(handle));
    const selector_string = cStringToZigString(selectors);
    const allocator = std.heap.page_allocator;

    const result = element.querySelector(allocator, selector_string) catch {
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
pub export fn dom_element_queryselectorall_first(handle: *DOMElement, selectors: [*:0]const u8) ?*DOMElement {
    // For now, just return the first match (same as querySelector)
    // Full implementation needs NodeList binding
    return dom_element_queryselector(handle, selectors);
}

/// getElementsByTagName method
///
/// WebIDL: `HTMLCollection getElementsByTagName(DOMString qualifiedName);`
pub export fn dom_element_getelementsbytagname(handle: *DOMElement, qualifiedName: [*:0]const u8) *DOMHTMLCollection {
    _ = handle;
    _ = qualifiedName;
    // TODO: Implement method
    @panic("TODO: Non-nullable pointer return");
}

/// getElementsByTagNameNS method
///
/// WebIDL: `HTMLCollection getElementsByTagNameNS(DOMString namespace, DOMString localName);`
pub export fn dom_element_getelementsbytagnamens(handle: *DOMElement, namespace: ?[*:0]const u8, localName: [*:0]const u8) *DOMHTMLCollection {
    _ = handle;
    _ = namespace;
    _ = localName;
    // TODO: Implement method
    @panic("TODO: Non-nullable pointer return");
}

/// getElementsByClassName method
///
/// WebIDL: `HTMLCollection getElementsByClassName(DOMString classNames);`
pub export fn dom_element_getelementsbyclassname(handle: *DOMElement, classNames: [*:0]const u8) *DOMHTMLCollection {
    _ = handle;
    _ = classNames;
    // TODO: Implement method
    @panic("TODO: Non-nullable pointer return");
}

/// Insert an element at a position relative to this element.
///
/// ## WebIDL
/// ```webidl
/// Element? insertAdjacentElement(DOMString where, Element element);
/// ```
///
/// ## Parameters
/// - `handle`: Element to insert relative to
/// - `where`: Position ("beforebegin", "afterbegin", "beforeend", "afterend")
/// - `element`: Element to insert
///
/// ## Returns
/// The inserted element, or NULL if insertion failed
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-element-insertadjacentelement
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentElement
///
/// ## Positions
/// - "beforebegin": Before target element (requires parent)
/// - "afterbegin": As first child of target
/// - "beforeend": As last child of target
/// - "afterend": After target element (requires parent)
pub export fn dom_element_insertadjacentelement(handle: *DOMElement, where: [*:0]const u8, element: *DOMElement) ?*DOMElement {
    const target_elem: *Element = @ptrCast(@alignCast(handle));
    const insert_elem: *Element = @ptrCast(@alignCast(element));
    const where_str = cStringToZigString(where);

    const result = target_elem.insertAdjacentElement(where_str, insert_elem) catch {
        return null;
    };

    return if (result) |elem| @ptrCast(elem) else null;
}

/// Insert text at a position relative to this element.
///
/// ## WebIDL
/// ```webidl
/// undefined insertAdjacentText(DOMString where, DOMString data);
/// ```
///
/// ## Parameters
/// - `handle`: Element to insert relative to
/// - `where`: Position ("beforebegin", "afterbegin", "beforeend", "afterend")
/// - `data`: Text content to insert
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-element-insertadjacenttext
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentText
///
/// ## Positions
/// - "beforebegin": Before target element (requires parent)
/// - "afterbegin": As first child of target
/// - "beforeend": As last child of target
/// - "afterend": After target element (requires parent)
///
/// ## Note
/// This creates a Text node internally. For positions that require a parent
/// (beforebegin, afterend), if parent is null, this is a no-op (returns success).
pub export fn dom_element_insertadjacenttext(handle: *DOMElement, where: [*:0]const u8, data: [*:0]const u8) c_int {
    const target_elem: *Element = @ptrCast(@alignCast(handle));
    const where_str = cStringToZigString(where);
    const data_str = cStringToZigString(data);

    target_elem.insertAdjacentText(where_str, data_str) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0; // Success
}
// ============================================================================
// ParentNode Mixin - Element Traversal
// ============================================================================

/// Returns a live HTMLCollection of element children.
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute HTMLCollection children;
/// ```
///
/// ## Spec References
/// - ParentNode: https://dom.spec.whatwg.org/#dom-parentnode-children
/// - WebIDL: dom.idl:119
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/children
///
/// ## Returns
/// Live HTMLCollection containing only element children (excludes text, comments, etc.)
///
/// ## Example (C)
/// ```c
/// DOMElement* parent = dom_document_createelement(doc, "parent");
/// DOMHTMLCollection* children = dom_element_get_children(parent);
/// unsigned long count = dom_htmlcollection_get_length(children);
/// printf("Element has %lu element children\n", count);
/// ```
pub export fn dom_element_get_children(handle: *DOMElement) *DOMHTMLCollection {
    const element: *Element = @ptrCast(@alignCast(handle));
    _ = element.children(); // Initialize the collection
    // HTMLCollection is a value type, need to return pointer to parent element
    // which owns the collection (following [SameObject] semantics)
    return @ptrCast(handle);
}

/// Returns the first child element, or NULL if none.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? firstElementChild;
/// ```
///
/// ## Spec References
/// - ParentNode: https://dom.spec.whatwg.org/#dom-parentnode-firstelementchild
/// - WebIDL: dom.idl:120
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/firstElementChild
///
/// ## Returns
/// First element child or NULL (skips text nodes, comments, etc.)
///
/// ## Example (C)
/// ```c
/// DOMElement* first = dom_element_get_firstelementchild(parent);
/// if (first != NULL) {
///     const char* tag = dom_element_get_tagname(first);
///     printf("First child element: %s\n", tag);
/// }
/// ```
pub export fn dom_element_get_firstelementchild(handle: *DOMElement) ?*DOMElement {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const first = element.firstElementChild() orelse return null;
    return @ptrCast(first);
}

/// Returns the last child element, or NULL if none.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? lastElementChild;
/// ```
///
/// ## Spec References
/// - ParentNode: https://dom.spec.whatwg.org/#dom-parentnode-lastelementchild
/// - WebIDL: dom.idl:121
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/lastElementChild
///
/// ## Returns
/// Last element child or NULL
pub export fn dom_element_get_lastelementchild(handle: *DOMElement) ?*DOMElement {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const last = element.lastElementChild() orelse return null;
    return @ptrCast(last);
}

/// Returns the number of element children.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long childElementCount;
/// ```
///
/// ## Spec References
/// - ParentNode: https://dom.spec.whatwg.org/#dom-parentnode-childelementcount
/// - WebIDL: dom.idl:122
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/childElementCount
///
/// ## Returns
/// Count of element children (excludes text nodes, comments, etc.)
///
/// ## Example (C)
/// ```c
/// unsigned long count = dom_element_get_childelementcount(parent);
/// printf("Element has %lu child elements\n", count);
/// ```
pub export fn dom_element_get_childelementcount(handle: *DOMElement) u32 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return element.childElementCount();
}

// ============================================================================
// ChildNode Mixin - Element Sibling Traversal
// ============================================================================

/// Returns the next sibling element, or NULL if none.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? nextElementSibling;
/// ```
///
/// ## Spec References
/// - NonDocumentTypeChildNode: https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-nextelementsibling
/// - WebIDL: dom.idl:127
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/nextElementSibling
///
/// ## Returns
/// Next element sibling or NULL (skips text nodes, comments, etc.)
///
/// ## Example (C)
/// ```c
/// DOMElement* next = dom_element_get_nextelementsibling(elem);
/// while (next != NULL) {
///     // Process next element sibling
///     next = dom_element_get_nextelementsibling(next);
/// }
/// ```
pub export fn dom_element_get_nextelementsibling(handle: *DOMElement) ?*DOMElement {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const next = element.nextElementSibling() orelse return null;
    return @ptrCast(next);
}

/// Returns the previous sibling element, or NULL if none.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? previousElementSibling;
/// ```
///
/// ## Spec References
/// - NonDocumentTypeChildNode: https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-previouselementsibling
/// - WebIDL: dom.idl:126
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/previousElementSibling
///
/// ## Returns
/// Previous element sibling or NULL
pub export fn dom_element_get_previouselementsibling(handle: *DOMElement) ?*DOMElement {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const prev = element.previousElementSibling() orelse return null;
    return @ptrCast(prev);
}

// ============================================================================
// Shadow DOM
// ============================================================================

/// Attach a shadow root to the element.
///
/// Creates a new shadow root attached to this element for Shadow DOM encapsulation.
/// Returns error if element already has a shadow root.
///
/// ## WebIDL
/// ```webidl
/// ShadowRoot attachShadow(ShadowRootInit init);
/// ```
///
/// ## Parameters
/// - `handle`: Element handle
/// - `mode`: 0 for open (shadowRoot accessible), 1 for closed (hidden)
/// - `delegates_focus`: Whether to delegate focus to first focusable element
///
/// ## Returns
/// ShadowRoot handle or NULL on error
///
/// ## Example
/// ```c
/// // Open mode - shadowRoot is accessible
/// DOMShadowRoot* shadow = dom_element_attachshadow(elem, 0, false);
/// if (shadow != NULL) {
///     DOMElement* content = dom_document_createelement(doc, "content");
///     dom_node_appendchild((DOMNode*)shadow, (DOMNode*)content);
/// }
///
/// // Closed mode - shadowRoot hidden
/// DOMShadowRoot* closed = dom_element_attachshadow(elem2, 1, false);
/// ```
///
/// ## Spec References
/// - Element.attachShadow(): https://dom.spec.whatwg.org/#dom-element-attachshadow
/// - WebIDL: dom.idl:381
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Element/attachShadow
///
/// ## Note
/// - Can only attach one shadow root per element
/// - Returns NULL if already has shadow root
/// - Mode 0 = open, 1 = closed
/// - ShadowRoot inherits from DocumentFragment (use dom_node_* functions)
pub export fn dom_element_attachshadow(handle: *DOMElement, mode: c_int, delegates_focus: bool) ?*DOMShadowRoot {
    const element: *Element = @ptrCast(@alignCast(handle));

    // ShadowRootInit is inferred from the struct literal
    const shadow = element.attachShadow(.{
        .mode = if (mode == 0) .open else .closed,
        .delegates_focus = delegates_focus,
        .slot_assignment = .named,
        .clonable = false,
        .serializable = false,
    }) catch return null;

    return @ptrCast(shadow);
}

// ============================================================================
// Node API Delegation (Convenience Methods)
// ============================================================================
// These methods delegate to the Node interface for convenience, avoiding the
// need to cast Element to Node in C code. They mirror the JavaScript behavior
// where Element inherits from Node.

/// Append a child node to this element
///
/// WebIDL: `Node appendChild(Node node);` (inherited from Node)
pub export fn dom_element_appendchild(handle: *DOMElement, child: *dom_types.DOMNode) ?*dom_types.DOMNode {
    const element: *Element = @ptrCast(@alignCast(handle));
    const child_node: *Node = @ptrCast(@alignCast(child));
    const result = element.appendChild(child_node) catch return null;
    return @ptrCast(result);
}

/// Insert a node before a reference child
///
/// WebIDL: `Node insertBefore(Node node, Node? child);` (inherited from Node)
pub export fn dom_element_insertbefore(handle: *DOMElement, node: *dom_types.DOMNode, child: ?*dom_types.DOMNode) ?*dom_types.DOMNode {
    const element: *Element = @ptrCast(@alignCast(handle));
    const new_node: *Node = @ptrCast(@alignCast(node));
    const child_node: ?*Node = if (child) |c| @as(*Node, @ptrCast(@alignCast(c))) else null;
    const result = element.insertBefore(new_node, child_node) catch return null;
    return @ptrCast(result);
}

/// Remove a child node from this element
///
/// WebIDL: `Node removeChild(Node child);` (inherited from Node)
pub export fn dom_element_removechild(handle: *DOMElement, child: *dom_types.DOMNode) ?*dom_types.DOMNode {
    const element: *Element = @ptrCast(@alignCast(handle));
    const child_node: *Node = @ptrCast(@alignCast(child));
    const result = element.removeChild(child_node) catch return null;
    return @ptrCast(result);
}

/// Replace a child node with a new node
///
/// WebIDL: `Node replaceChild(Node node, Node child);` (inherited from Node)
pub export fn dom_element_replacechild(handle: *DOMElement, node: *dom_types.DOMNode, child: *dom_types.DOMNode) ?*dom_types.DOMNode {
    const element: *Element = @ptrCast(@alignCast(handle));
    const new_node: *Node = @ptrCast(@alignCast(node));
    const old_child: *Node = @ptrCast(@alignCast(child));
    const result = element.replaceChild(new_node, old_child) catch return null;
    return @ptrCast(result);
}

/// Check if this element has any child nodes
///
/// WebIDL: `boolean hasChildNodes();` (inherited from Node)
pub export fn dom_element_haschildnodes(handle: *DOMElement) u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return if (element.hasChildNodes()) 1 else 0;
}

/// Get the first child node
///
/// WebIDL: `readonly attribute Node? firstChild;` (inherited from Node)
pub export fn dom_element_get_firstchild(handle: *DOMElement) ?*dom_types.DOMNode {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const child = element.firstChild() orelse return null;
    return @ptrCast(child);
}

/// Get the last child node
///
/// WebIDL: `readonly attribute Node? lastChild;` (inherited from Node)
pub export fn dom_element_get_lastchild(handle: *DOMElement) ?*dom_types.DOMNode {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const child = element.lastChild() orelse return null;
    return @ptrCast(child);
}

/// Get the parent node
///
/// WebIDL: `readonly attribute Node? parentNode;` (inherited from Node)
pub export fn dom_element_get_parentnode(handle: *DOMElement) ?*dom_types.DOMNode {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const parent = element.parentNode() orelse return null;
    return @ptrCast(parent);
}

/// Get the next sibling node
///
/// WebIDL: `readonly attribute Node? nextSibling;` (inherited from Node)
pub export fn dom_element_get_nextsibling(handle: *DOMElement) ?*dom_types.DOMNode {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const sibling = element.nextSibling() orelse return null;
    return @ptrCast(sibling);
}

/// Get the previous sibling node
///
/// WebIDL: `readonly attribute Node? previousSibling;` (inherited from Node)
pub export fn dom_element_get_previoussibling(handle: *DOMElement) ?*dom_types.DOMNode {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const sibling = element.previousSibling() orelse return null;
    return @ptrCast(sibling);
}

/// Get the node name (returns tag name for elements)
///
/// WebIDL: `readonly attribute DOMString nodeName;` (inherited from Node)
pub export fn dom_element_get_nodename(handle: *DOMElement) [*:0]const u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return zigStringToCString(element.nodeName());
}

/// Get the text content of this element and its descendants
///
/// WebIDL: `attribute DOMString? textContent;` (inherited from Node)
pub export fn dom_element_get_textcontent(handle: *DOMElement) ?[*:0]const u8 {
    const allocator = std.heap.page_allocator;
    const element: *const Element = @ptrCast(@alignCast(handle));
    const content = element.textContent(allocator) catch return null;
    return zigStringToCStringOptional(content);
}

/// Set the text content of this element (removes all children)
///
/// WebIDL: `attribute DOMString? textContent;` (inherited from Node)
pub export fn dom_element_set_textcontent(handle: *DOMElement, value: ?[*:0]const u8) c_int {
    const element: *Element = @ptrCast(@alignCast(handle));
    const zig_value = cStringToZigStringOptional(value);
    element.setTextContent(zig_value) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };
    return 0; // Success
}

/// Clone this element node
///
/// WebIDL: `Node cloneNode(optional boolean deep = false);` (inherited from Node)
pub export fn dom_element_clonenode(handle: *DOMElement, deep: u8) ?*dom_types.DOMNode {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const cloned = element.cloneNode(deep != 0) catch return null;
    return @ptrCast(cloned);
}

/// Check if this element contains another node
///
/// WebIDL: `boolean contains(Node? other);` (inherited from Node)
pub export fn dom_element_contains(handle: *DOMElement, other: ?*dom_types.DOMNode) u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    const other_node: ?*const Node = if (other) |o| @as(*const Node, @ptrCast(@alignCast(o))) else null;
    return if (element.contains(other_node)) 1 else 0;
}

/// Check if this element is connected to a document
///
/// WebIDL: `readonly attribute boolean isConnected;` (inherited from Node)
pub export fn dom_element_get_isconnected(handle: *DOMElement) u8 {
    const element: *const Element = @ptrCast(@alignCast(handle));
    return if (element.isConnected()) 1 else 0;
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increase reference count
pub export fn dom_element_addref(handle: *DOMElement) void {
    const element: *Element = @ptrCast(@alignCast(handle));
    element.prototype.acquire();
}

/// Decrease reference count
pub export fn dom_element_release(handle: *DOMElement) void {
    const element: *Element = @ptrCast(@alignCast(handle));
    element.prototype.release();
}
