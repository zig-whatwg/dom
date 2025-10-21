//! JavaScript Bindings for Node
//!
//! This file provides C-ABI compatible bindings.

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");
const Node = dom.Node;
const NodeList = dom.NodeList;
const Document = dom.Document;
const Element = dom.Element;

// Import helper functions
const zigStringToCString = types.zigStringToCString;
const zigStringToCStringOptional = types.zigStringToCStringOptional;
const cStringToZigString = types.cStringToZigString;
const cStringToZigStringOptional = types.cStringToZigStringOptional;
const zigErrorToDOMError = types.zigErrorToDOMError;

// Import opaque types
pub const DOMNode = types.DOMNode;
pub const DOMDocument = types.DOMDocument;
pub const DOMElement = types.DOMElement;
pub const DOMNodeList = types.DOMNodeList;

/// Get nodeType attribute
///
/// WebIDL: `readonly attribute unsigned short nodeType;`
pub export fn dom_node_get_nodetype(handle: *DOMNode) u16 {
    const node: *Node = @ptrCast(@alignCast(handle));
    return @intFromEnum(node.node_type);
}

/// Get nodeName attribute
///
/// WebIDL: `readonly attribute DOMString nodeName;`
pub export fn dom_node_get_nodename(handle: *DOMNode) [*:0]const u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const name = node.nodeName();
    return zigStringToCString(name);
}

/// Get baseURI attribute
///
/// WebIDL: `readonly attribute USVString baseURI;`
pub export fn dom_node_get_baseuri(handle: *DOMNode) [*:0]const u8 {
    _ = handle;
    // TODO: baseURI not yet implemented in core DOM
    return "";
}

/// Get isConnected attribute
///
/// WebIDL: `readonly attribute boolean isConnected;`
pub export fn dom_node_get_isconnected(handle: *DOMNode) u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    return if (node.isConnected()) 1 else 0;
}

/// Get ownerDocument attribute
///
/// WebIDL: `readonly attribute Document? ownerDocument;`
pub export fn dom_node_get_ownerdocument(handle: *DOMNode) ?*DOMDocument {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const owner_doc = node.owner_document;
    return @ptrCast(owner_doc);
}

/// Get parentNode attribute
///
/// WebIDL: `readonly attribute Node? parentNode;`
pub export fn dom_node_get_parentnode(handle: *DOMNode) ?*DOMNode {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const parent = node.parent_node;
    return @ptrCast(parent);
}

/// Get parentElement attribute
///
/// WebIDL: `readonly attribute Element? parentElement;`
pub export fn dom_node_get_parentelement(handle: *DOMNode) ?*DOMElement {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const parent = node.parent_node orelse return null;
    // Only return if parent is an Element
    if (parent.node_type != .element) return null;
    return @ptrCast(parent);
}

/// Get childNodes attribute
///
/// Returns a live NodeList of the node's children. The returned NodeList
/// is heap-allocated and must be released with dom_nodelist_release().
///
/// WebIDL: `[SameObject] readonly attribute NodeList childNodes;`
/// Spec: https://dom.spec.whatwg.org/#dom-node-childnodes
/// MDN: https://developer.mozilla.org/en-US/docs/Web/API/Node/childNodes
///
/// ## Parameters
/// - `handle`: Node handle
///
/// ## Returns
/// NodeList of children (must be released by caller)
///
/// ## Example
/// ```c
/// DOMNodeList* children = dom_node_get_childnodes(node);
/// uint32_t count = dom_nodelist_get_length(children);
/// printf("Node has %u children\n", count);
/// dom_nodelist_release(children);
/// ```
///
/// ## Note
/// [SameObject] attribute in WebIDL means JS engines should cache the instance.
/// C API returns new instance each time - caller must manage lifetime.
pub export fn dom_node_get_childnodes(handle: *DOMNode) *DOMNodeList {
    const node: *Node = @ptrCast(@alignCast(handle));

    // Get NodeList from Zig (this is a value type)
    const node_list = node.childNodes();

    // Allocate on heap for C (page allocator for long-lived collection)
    const allocator = std.heap.page_allocator;
    const heap_list = allocator.create(NodeList) catch {
        @panic("Failed to allocate NodeList");
    };
    heap_list.* = node_list;

    return @ptrCast(@alignCast(heap_list));
}

/// Get firstChild attribute
///
/// WebIDL: `readonly attribute Node? firstChild;`
pub export fn dom_node_get_firstchild(handle: *DOMNode) ?*DOMNode {
    const node: *const Node = @ptrCast(@alignCast(handle));
    return @ptrCast(node.first_child);
}

/// Get lastChild attribute
///
/// WebIDL: `readonly attribute Node? lastChild;`
pub export fn dom_node_get_lastchild(handle: *DOMNode) ?*DOMNode {
    const node: *const Node = @ptrCast(@alignCast(handle));
    return @ptrCast(node.last_child);
}

/// Get previousSibling attribute
///
/// WebIDL: `readonly attribute Node? previousSibling;`
pub export fn dom_node_get_previoussibling(handle: *DOMNode) ?*DOMNode {
    const node: *const Node = @ptrCast(@alignCast(handle));
    return @ptrCast(node.previous_sibling);
}

/// Get nextSibling attribute
///
/// WebIDL: `readonly attribute Node? nextSibling;`
pub export fn dom_node_get_nextsibling(handle: *DOMNode) ?*DOMNode {
    const node: *const Node = @ptrCast(@alignCast(handle));
    return @ptrCast(node.next_sibling);
}

/// Get nodeValue attribute
///
/// WebIDL: `attribute DOMString? nodeValue;`
pub export fn dom_node_get_nodevalue(handle: *DOMNode) ?[*:0]const u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const value = node.nodeValue();
    return zigStringToCStringOptional(value);
}

/// Set nodeValue attribute
///
/// WebIDL: `attribute DOMString? nodeValue;`
pub export fn dom_node_set_nodevalue(handle: *DOMNode, value: ?[*:0]const u8) c_int {
    const node: *Node = @ptrCast(@alignCast(handle));
    const zig_value = cStringToZigStringOptional(value) orelse "";
    node.setNodeValue(zig_value) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };
    return 0; // Success
}

/// Get textContent attribute
///
/// WebIDL: `attribute DOMString? textContent;`
pub export fn dom_node_get_textcontent(handle: *DOMNode) ?[*:0]const u8 {
    _ = handle;
    // TODO: textContent returns allocated memory (requires allocator)
    // Need to design memory management strategy for dynamically allocated strings
    // Options:
    // 1. Add dom_node_get_textcontent_alloc(allocator) variant
    // 2. Use thread-local string cache
    // 3. Add dom_string_free() cleanup function
    // Deferred until memory management strategy is decided
    return null;
}

/// Set textContent attribute
///
/// WebIDL: `attribute DOMString? textContent;`
pub export fn dom_node_set_textcontent(handle: *DOMNode, value: ?[*:0]const u8) c_int {
    _ = handle;
    _ = value;
    // TODO: Setter implementation pending textContent getter strategy
    return 0; // Success
}

// SKIPPED: getRootNode() - Contains complex types not supported in C-ABI v1
// WebIDL: Node getRootNode(GetRootNodeOptions options);
// Reason: Dictionary type 'GetRootNodeOptions'

/// hasChildNodes method
///
/// WebIDL: `boolean hasChildNodes();`
pub export fn dom_node_haschildnodes(handle: *DOMNode) u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    return if (node.first_child != null) 1 else 0;
}

/// normalize method
///
/// WebIDL: `undefined normalize();`
pub export fn dom_node_normalize(handle: *DOMNode) c_int {
    const node: *Node = @ptrCast(@alignCast(handle));
    node.normalize() catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };
    return 0; // Success
}

/// cloneNode method
///
/// WebIDL: `Node cloneNode(boolean subtree);`
pub export fn dom_node_clonenode(handle: *DOMNode, subtree: u8) *DOMNode {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const deep = (subtree != 0);

    const result = node.cloneNode(deep) catch {
        // On error, can't return error code (non-nullable return)
        // This is a critical issue - we can't return anything valid
        // For now, panic (caller should use try-catch pattern)
        @panic("cloneNode failed - cannot return error via C-ABI");
    };

    return @ptrCast(result);
}

/// isEqualNode method
///
/// WebIDL: `boolean isEqualNode(Node otherNode);`
pub export fn dom_node_isequalnode(handle: *DOMNode, otherNode: ?*DOMNode) u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const other: ?*const Node = if (otherNode) |n| @ptrCast(@alignCast(n)) else null;
    return if (node.isEqualNode(other)) 1 else 0;
}

/// isSameNode method
///
/// WebIDL: `boolean isSameNode(Node otherNode);`
pub export fn dom_node_issamenode(handle: *DOMNode, otherNode: ?*DOMNode) u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const other: ?*const Node = if (otherNode) |n| @ptrCast(@alignCast(n)) else null;
    return if (node.isSameNode(other)) 1 else 0;
}

/// compareDocumentPosition method
///
/// WebIDL: `unsigned short compareDocumentPosition(Node other);`
pub export fn dom_node_comparedocumentposition(handle: *DOMNode, other: *DOMNode) u16 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const other_node: *const Node = @ptrCast(@alignCast(other));
    return node.compareDocumentPosition(other_node);
}

/// contains method
///
/// WebIDL: `boolean contains(Node other);`
pub export fn dom_node_contains(handle: *DOMNode, other: ?*DOMNode) u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const other_node: ?*const Node = if (other) |n| @ptrCast(@alignCast(n)) else null;
    return if (node.contains(other_node)) 1 else 0;
}

/// lookupPrefix method
///
/// WebIDL: `DOMString lookupPrefix(DOMString namespace);`
pub export fn dom_node_lookupprefix(handle: *DOMNode, namespace: ?[*:0]const u8) ?[*:0]const u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    const result = node.lookupPrefix(ns);
    return zigStringToCStringOptional(result);
}

/// lookupNamespaceURI method
///
/// WebIDL: `DOMString lookupNamespaceURI(DOMString prefix);`
pub export fn dom_node_lookupnamespaceuri(handle: *DOMNode, prefix: ?[*:0]const u8) ?[*:0]const u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const pfx = cStringToZigStringOptional(prefix);
    const result = node.lookupNamespaceURI(pfx);
    return zigStringToCStringOptional(result);
}

/// isDefaultNamespace method
///
/// WebIDL: `boolean isDefaultNamespace(DOMString namespace);`
pub export fn dom_node_isdefaultnamespace(handle: *DOMNode, namespace: ?[*:0]const u8) u8 {
    const node: *const Node = @ptrCast(@alignCast(handle));
    const ns = cStringToZigStringOptional(namespace);
    return if (node.isDefaultNamespace(ns)) 1 else 0;
}

/// insertBefore method
///
/// WebIDL: `Node insertBefore(Node node, Node child);`
pub export fn dom_node_insertbefore(handle: *DOMNode, node: *DOMNode, child: ?*DOMNode) *DOMNode {
    const parent: *Node = @ptrCast(@alignCast(handle));
    const new_node: *Node = @ptrCast(@alignCast(node));
    const ref_child: ?*Node = if (child) |c| @ptrCast(@alignCast(c)) else null;

    const result = parent.insertBefore(new_node, ref_child) catch {
        // On error, return the node as-is (can't return error code)
        return node;
    };

    return @ptrCast(result);
}

/// appendChild method
///
/// WebIDL: `Node appendChild(Node node);`
pub export fn dom_node_appendchild(handle: *DOMNode, child: *DOMNode) *DOMNode {
    const parent_node: *Node = @ptrCast(@alignCast(handle));
    const child_node: *Node = @ptrCast(@alignCast(child));

    const result = parent_node.appendChild(child_node) catch {
        // On error, we can't return an error code (method returns Node, not c_int)
        // Best we can do is return the child node as-is
        // TODO: Consider adding dom_node_appendchild_checked that returns c_int
        return child;
    };

    return @ptrCast(result);
}

/// replaceChild method
///
/// WebIDL: `Node replaceChild(Node node, Node child);`
pub export fn dom_node_replacechild(handle: *DOMNode, node: *DOMNode, child: *DOMNode) *DOMNode {
    const parent: *Node = @ptrCast(@alignCast(handle));
    const new_node: *Node = @ptrCast(@alignCast(node));
    const old_child: *Node = @ptrCast(@alignCast(child));

    const result = parent.replaceChild(new_node, old_child) catch {
        // On error, return the old child as-is
        return child;
    };

    return @ptrCast(result);
}

/// removeChild method
///
/// WebIDL: `Node removeChild(Node child);`
pub export fn dom_node_removechild(handle: *DOMNode, child: *DOMNode) *DOMNode {
    const parent: *Node = @ptrCast(@alignCast(handle));
    const child_node: *Node = @ptrCast(@alignCast(child));

    const result = parent.removeChild(child_node) catch {
        // On error, return the child as-is
        return child;
    };

    return @ptrCast(result);
}
/// Increase reference count
pub export fn dom_node_addref(handle: *DOMNode) void {
    const node: *Node = @ptrCast(@alignCast(handle));
    node.acquire();
}

/// Decrease reference count
pub export fn dom_node_release(handle: *DOMNode) void {
    const node: *Node = @ptrCast(@alignCast(handle));
    node.release();
}
