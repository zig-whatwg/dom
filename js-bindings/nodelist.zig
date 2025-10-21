//! NodeList C-ABI Bindings
//!
//! C-ABI bindings for the NodeList interface per WHATWG DOM specification.
//! NodeList is a live collection of nodes (typically representing a node's children).
//!
//! ## C API Overview
//!
//! ```c
//! // Get NodeList
//! DOMNodeList* dom_node_get_childnodes(DOMNode* node);
//!
//! // Access items
//! uint32_t dom_nodelist_get_length(DOMNodeList* list);
//! DOMNode* dom_nodelist_item(DOMNodeList* list, uint32_t index);
//!
//! // Note: NodeList is value type in Zig, heap-allocated for C
//! void dom_nodelist_release(DOMNodeList* list);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface NodeList {
//!   getter Node? item(unsigned long index);
//!   readonly attribute unsigned long length;
//!   iterable<Node>;
//! };
//! ```
//!
//! ## WHATWG Specification
//!
//! - NodeList interface: https://dom.spec.whatwg.org/#interface-nodelist
//! - Node.childNodes: https://dom.spec.whatwg.org/#dom-node-childnodes
//!
//! ## MDN Documentation
//!
//! - NodeList: https://developer.mozilla.org/en-US/docs/Web/API/NodeList
//! - NodeList.length: https://developer.mozilla.org/en-US/docs/Web/API/NodeList/length
//! - NodeList.item(): https://developer.mozilla.org/en-US/docs/Web/API/NodeList/item

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const Node = dom.Node;
const NodeList = dom.NodeList;
const DOMNode = types.DOMNode;
const DOMNodeList = types.DOMNodeList;

// ============================================================================
// Properties
// ============================================================================

/// Get the length of a NodeList.
///
/// Returns the number of nodes in the list. This is a live count that
/// reflects the current state of the DOM.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long length;
/// ```
///
/// ## Parameters
/// - `list`: NodeList handle
///
/// ## Returns
/// Number of nodes in the list
///
/// ## Example
/// ```c
/// DOMNodeList* children = dom_node_get_childnodes(parent);
/// uint32_t count = dom_nodelist_get_length(children);
/// printf("Parent has %u children\n", count);
/// dom_nodelist_release(children);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodelist-length
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeList/length
pub export fn dom_nodelist_get_length(list: *DOMNodeList) u32 {
    const node_list: *NodeList = @ptrCast(@alignCast(list));
    return @intCast(node_list.length());
}

// ============================================================================
// Methods
// ============================================================================

/// Get a node at a specific index in the list.
///
/// Returns the node at the specified index, or null if the index is out of bounds.
/// This is a live view - the returned node reflects the current DOM state.
///
/// ## WebIDL
/// ```webidl
/// getter Node? item(unsigned long index);
/// ```
///
/// ## Parameters
/// - `list`: NodeList handle
/// - `index`: Zero-based index
///
/// ## Returns
/// Node at index or null if out of bounds
///
/// ## Example
/// ```c
/// DOMNodeList* children = dom_node_get_childnodes(parent);
/// uint32_t count = dom_nodelist_get_length(children);
///
/// for (uint32_t i = 0; i < count; i++) {
///     DOMNode* child = dom_nodelist_item(children, i);
///     if (child != NULL) {
///         const char* name = dom_node_get_nodename(child);
///         printf("Child %u: %s\n", i, name);
///     }
/// }
///
/// dom_nodelist_release(children);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodelist-item
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeList/item
pub export fn dom_nodelist_item(list: *DOMNodeList, index: u32) ?*DOMNode {
    const node_list: *NodeList = @ptrCast(@alignCast(list));
    const node = node_list.item(@intCast(index));
    if (node) |n| {
        return @ptrCast(@alignCast(n));
    }
    return null;
}

// ============================================================================
// Memory Management
// ============================================================================

/// Release a NodeList.
///
/// NodeList is a value type in Zig but heap-allocated for C interop.
/// Call this when done with a NodeList returned from the API.
///
/// ## Parameters
/// - `list`: NodeList handle to release
///
/// ## Example
/// ```c
/// DOMNodeList* children = dom_node_get_childnodes(parent);
/// // ... use children ...
/// dom_nodelist_release(children);
/// ```
///
/// ## Note
/// NodeList doesn't own the nodes it references. Releasing the NodeList
/// does NOT release the nodes themselves - they are owned by their parent.
pub export fn dom_nodelist_release(list: *DOMNodeList) void {
    const allocator = std.heap.page_allocator;
    const node_list: *NodeList = @ptrCast(@alignCast(list));
    allocator.destroy(node_list);
}
