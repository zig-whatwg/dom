//! NamedNodeMap C-ABI Bindings
//!
//! C-ABI bindings for the NamedNodeMap interface per WHATWG DOM specification.
//! NamedNodeMap provides a collection view of an element's attributes as Attr nodes.
//!
//! ## C API Overview
//!
//! ```c
//! // Get NamedNodeMap
//! DOMNamedNodeMap* dom_element_get_attributes(DOMElement* elem);
//!
//! // Query
//! uint32_t dom_namednodemap_get_length(DOMNamedNodeMap* map);
//! DOMAttr* dom_namednodemap_item(DOMNamedNodeMap* map, uint32_t index);
//! DOMAttr* dom_namednodemap_getnameditem(DOMNamedNodeMap* map, const char* name);
//! DOMAttr* dom_namednodemap_getnameditemns(DOMNamedNodeMap* map, const char* ns, const char* localName);
//!
//! // Modification
//! DOMAttr* dom_namednodemap_setnameditem(DOMNamedNodeMap* map, DOMAttr* attr);
//! DOMAttr* dom_namednodemap_setnameditemns(DOMNamedNodeMap* map, DOMAttr* attr);
//! DOMAttr* dom_namednodemap_removenameditem(DOMNamedNodeMap* map, const char* name);
//! DOMAttr* dom_namednodemap_removenameditemns(DOMNamedNodeMap* map, const char* ns, const char* localName);
//!
//! // Release
//! void dom_namednodemap_release(DOMNamedNodeMap* map);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window, LegacyUnenumerableNamedProperties]
//! interface NamedNodeMap {
//!   readonly attribute unsigned long length;
//!   getter Attr? item(unsigned long index);
//!   getter Attr? getNamedItem(DOMString qualifiedName);
//!   Attr? getNamedItemNS(DOMString? namespace, DOMString localName);
//!   [CEReactions] Attr? setNamedItem(Attr attr);
//!   [CEReactions] Attr? setNamedItemNS(Attr attr);
//!   [CEReactions] Attr removeNamedItem(DOMString qualifiedName);
//!   [CEReactions] Attr removeNamedItemNS(DOMString? namespace, DOMString localName);
//! };
//! ```
//!
//! ## WHATWG Specification
//!
//! - NamedNodeMap interface: https://dom.spec.whatwg.org/#interface-namednodemap
//! - Element.attributes: https://dom.spec.whatwg.org/#dom-element-attributes
//!
//! ## MDN Documentation
//!
//! - NamedNodeMap: https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap
//! - NamedNodeMap.length: https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/length
//! - NamedNodeMap.item(): https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/item

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const NamedNodeMap = dom.NamedNodeMap;
const Attr = dom.Attr;
const DOMNamedNodeMap = types.DOMNamedNodeMap;
const DOMAttr = types.DOMAttr;
const zigErrorToDOMError = types.zigErrorToDOMError;
const cStringToZigString = types.cStringToZigString;
const cStringToZigStringOptional = types.cStringToZigStringOptional;

// ============================================================================
// Properties
// ============================================================================

/// Get the length of a NamedNodeMap.
///
/// Returns the number of attributes in the map.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long length;
/// ```
///
/// ## Parameters
/// - `map`: NamedNodeMap handle (actually Element* from dom_element_get_attributes)
///
/// ## Returns
/// Number of attributes in the map
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-namednodemap-length
/// - https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/length
pub export fn dom_namednodemap_get_length(map: *DOMNamedNodeMap) u32 {
    // map is actually Element* - construct NamedNodeMap wrapper
    const element: *dom.Element = @ptrCast(@alignCast(map));
    var named_node_map = element.getAttributes();
    return named_node_map.length();
}

// ============================================================================
// Query Methods
// ============================================================================

/// Get an attribute at a specific index.
///
/// Returns the Attr node at the specified index, or null if out of bounds.
///
/// ## WebIDL
/// ```webidl
/// getter Attr? item(unsigned long index);
/// ```
///
/// ## Parameters
/// - `map`: NamedNodeMap handle
/// - `index`: Zero-based index
///
/// ## Returns
/// Attr node at index or null if out of bounds
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-namednodemap-item
/// - https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/item
pub export fn dom_namednodemap_item(map: *DOMNamedNodeMap, index: u32) ?*DOMAttr {
    const element: *dom.Element = @ptrCast(@alignCast(map));
    var named_node_map = element.getAttributes();
    const attr_opt = (&named_node_map).item(index) catch {
        return null;
    };
    if (attr_opt) |attr| {
        return @ptrCast(@alignCast(attr));
    }
    return null;
}

/// Get an attribute by name.
///
/// Returns the Attr node with the specified qualified name, or null if not found.
///
/// ## WebIDL
/// ```webidl
/// getter Attr? getNamedItem(DOMString qualifiedName);
/// ```
///
/// ## Parameters
/// - `map`: NamedNodeMap handle
/// - `name`: Qualified attribute name
///
/// ## Returns
/// Attr node with matching name or null if not found
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-namednodemap-getnameditem
/// - https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/getNamedItem
pub export fn dom_namednodemap_getnameditem(map: *DOMNamedNodeMap, name: [*:0]const u8) ?*DOMAttr {
    const element: *dom.Element = @ptrCast(@alignCast(map));
    var named_node_map = element.getAttributes();
    const name_slice = cStringToZigString(name);
    const attr_opt = (&named_node_map).getNamedItem(name_slice) catch {
        return null;
    };
    if (attr_opt) |attr| {
        return @ptrCast(@alignCast(attr));
    }
    return null;
}

/// Get an attribute by namespace and local name.
///
/// Returns the Attr node with the specified namespace and local name, or null if not found.
///
/// ## WebIDL
/// ```webidl
/// Attr? getNamedItemNS(DOMString? namespace, DOMString localName);
/// ```
///
/// ## Parameters
/// - `map`: NamedNodeMap handle
/// - `namespace`: Namespace URI (NULL for no namespace)
/// - `localName`: Local attribute name
///
/// ## Returns
/// Attr node with matching namespace and local name, or null if not found
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-namednodemap-getnameditemns
/// - https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/getNamedItemNS
pub export fn dom_namednodemap_getnameditemns(
    map: *DOMNamedNodeMap,
    namespace: ?[*:0]const u8,
    local_name: [*:0]const u8,
) ?*DOMAttr {
    const element: *dom.Element = @ptrCast(@alignCast(map));
    var named_node_map = element.getAttributes();
    const namespace_slice = cStringToZigStringOptional(namespace);
    const local_name_slice = cStringToZigString(local_name);

    const attr_opt = (&named_node_map).getNamedItemNS(namespace_slice, local_name_slice) catch {
        return null;
    };
    if (attr_opt) |attr| {
        return @ptrCast(@alignCast(attr));
    }
    return null;
}

// ============================================================================
// Modification Methods
// ============================================================================

/// Set an attribute node.
///
/// Adds or replaces an attribute. Returns the replaced attribute or null.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] Attr? setNamedItem(Attr attr);
/// ```
///
/// ## Parameters
/// - `map`: NamedNodeMap handle
/// - `attr`: Attr node to add/replace
///
/// ## Returns
/// Previously existing attribute with same name, or null
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-namednodemap-setnameditem
/// - https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/setNamedItem
pub export fn dom_namednodemap_setnameditem(map: *DOMNamedNodeMap, attr: *DOMAttr) ?*DOMAttr {
    const element: *dom.Element = @ptrCast(@alignCast(map));
    var named_node_map = element.getAttributes();
    const attr_node: *Attr = @ptrCast(@alignCast(attr));

    const old_attr_opt = (&named_node_map).setNamedItem(attr_node) catch {
        return null;
    };
    if (old_attr_opt) |old_attr| {
        return @ptrCast(@alignCast(old_attr));
    }
    return null;
}

/// Set a namespaced attribute node.
///
/// Adds or replaces a namespaced attribute. Returns the replaced attribute or null.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] Attr? setNamedItemNS(Attr attr);
/// ```
///
/// ## Parameters
/// - `map`: NamedNodeMap handle
/// - `attr`: Attr node to add/replace
///
/// ## Returns
/// Previously existing attribute with same namespace and local name, or null
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-namednodemap-setnameditemns
/// - https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/setNamedItemNS
pub export fn dom_namednodemap_setnameditemns(map: *DOMNamedNodeMap, attr: *DOMAttr) ?*DOMAttr {
    const element: *dom.Element = @ptrCast(@alignCast(map));
    var named_node_map = element.getAttributes();
    const attr_node: *Attr = @ptrCast(@alignCast(attr));

    const old_attr_opt = (&named_node_map).setNamedItemNS(attr_node) catch {
        return null;
    };
    if (old_attr_opt) |old_attr| {
        return @ptrCast(@alignCast(old_attr));
    }
    return null;
}

/// Remove an attribute by name.
///
/// Removes the attribute with the specified name.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] Attr removeNamedItem(DOMString qualifiedName);
/// ```
///
/// ## Parameters
/// - `map`: NamedNodeMap handle
/// - `name`: Qualified attribute name
///
/// ## Returns
/// Removed attribute node, or null on error
///
/// ## Note
/// Returns null on error (e.g., NotFoundError). Check error handling separately if needed.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-namednodemap-removenameditem
/// - https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/removeNamedItem
pub export fn dom_namednodemap_removenameditem(map: *DOMNamedNodeMap, name: [*:0]const u8) ?*DOMAttr {
    const element: *dom.Element = @ptrCast(@alignCast(map));
    var named_node_map = element.getAttributes();
    const name_slice = cStringToZigString(name);

    const removed_attr = (&named_node_map).removeNamedItem(name_slice) catch {
        return null;
    };
    return @ptrCast(@alignCast(removed_attr));
}

/// Remove an attribute by namespace and local name.
///
/// Removes the attribute with the specified namespace and local name.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] Attr removeNamedItemNS(DOMString? namespace, DOMString localName);
/// ```
///
/// ## Parameters
/// - `map`: NamedNodeMap handle
/// - `namespace`: Namespace URI (NULL for no namespace)
/// - `localName`: Local attribute name
///
/// ## Returns
/// Removed attribute node, or null on error
///
/// ## Note
/// Returns null on error (e.g., NotFoundError). Check error handling separately if needed.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-namednodemap-removenameditemns
/// - https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/removeNamedItemNS
pub export fn dom_namednodemap_removenameditemns(
    map: *DOMNamedNodeMap,
    namespace: ?[*:0]const u8,
    local_name: [*:0]const u8,
) ?*DOMAttr {
    const element: *dom.Element = @ptrCast(@alignCast(map));
    var named_node_map = element.getAttributes();
    const namespace_slice = cStringToZigStringOptional(namespace);
    const local_name_slice = cStringToZigString(local_name);

    const removed_attr = (&named_node_map).removeNamedItemNS(namespace_slice, local_name_slice) catch {
        return null;
    };
    return @ptrCast(@alignCast(removed_attr));
}

// ============================================================================
// Memory Management
// ============================================================================

/// Release a NamedNodeMap.
///
/// NamedNodeMap is a value type in Zig but heap-allocated for C interop.
/// Call this when done with a NamedNodeMap returned from the API.
///
/// ## Parameters
/// - `map`: NamedNodeMap handle to release
///
/// ## Note
/// NamedNodeMap doesn't own the Attr nodes or the Element. Releasing the map
/// does NOT affect the element's attributes.
pub export fn dom_namednodemap_release(map: *DOMNamedNodeMap) void {
    _ = map;
    // No-op: NamedNodeMap is represented by Element pointer in C-ABI ([SameObject])
    // Element lifetime is managed separately
}
