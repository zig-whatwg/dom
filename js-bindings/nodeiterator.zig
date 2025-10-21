//! NodeIterator C-ABI Bindings
//!
//! This module provides C-compatible bindings for the WHATWG DOM NodeIterator interface.
//! NodeIterator provides forward and backward iteration through a filtered DOM tree view.
//!
//! ## WebIDL Interface
//!
//! ```webidl
//! interface NodeIterator {
//!   [SameObject] readonly attribute Node root;
//!   readonly attribute Node referenceNode;
//!   readonly attribute boolean pointerBeforeReferenceNode;
//!   readonly attribute unsigned long whatToShow;
//!   readonly attribute NodeFilter? filter;
//!
//!   Node? nextNode();
//!   Node? previousNode();
//!
//!   undefined detach();
//! };
//! ```
//!
//! ## Spec References
//!
//! - **WHATWG DOM**: https://dom.spec.whatwg.org/#interface-nodeiterator
//! - **MDN NodeIterator**: https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator
//!
//! ## Usage Example (C)
//!
//! ```c
//! // Create node iterator (via Document)
//! DOMNodeIterator* iterator = dom_document_createnodeiterator(
//!     doc,
//!     root_node,
//!     DOM_NODEFILTER_SHOW_ELEMENT,  // Show only elements
//!     NULL                           // No custom filter
//! );
//!
//! // Forward iteration
//! DOMNode* node = dom_nodeiterator_nextnode(iterator);
//! while (node != NULL) {
//!     printf("Found element\n");
//!     node = dom_nodeiterator_nextnode(iterator);
//! }
//!
//! // Backward iteration
//! node = dom_nodeiterator_previousnode(iterator);
//! while (node != NULL) {
//!     printf("Found element\n");
//!     node = dom_nodeiterator_previousnode(iterator);
//! }
//!
//! // Clean up
//! dom_nodeiterator_release(iterator);
//! ```

const std = @import("std");
const root = @import("root.zig");
const dom = @import("dom");
const NodeIterator = dom.NodeIterator;
const Node = dom.Node;
const DOMNode = root.DOMNode;
const DOMNodeIterator = root.DOMNodeIterator;

// ============================================================================
// NodeIterator Properties
// ============================================================================

/// Get the root node of the iterator.
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute Node root;
/// ```
///
/// ## Parameters
/// - `iterator`: NodeIterator handle
///
/// ## Returns
/// Root node (never null)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodeiterator-root
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/root
pub export fn dom_nodeiterator_get_root(iterator: *const DOMNodeIterator) *DOMNode {
    const it: *const NodeIterator = @ptrCast(@alignCast(iterator));
    return @ptrCast(it.root);
}

/// Get the reference node.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node referenceNode;
/// ```
///
/// ## Parameters
/// - `iterator`: NodeIterator handle
///
/// ## Returns
/// Reference node (current position marker)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodeiterator-referencenode
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/referenceNode
pub export fn dom_nodeiterator_get_referencenode(iterator: *const DOMNodeIterator) *DOMNode {
    const it: *const NodeIterator = @ptrCast(@alignCast(iterator));
    return @ptrCast(it.reference_node);
}

/// Get whether pointer is before reference node.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean pointerBeforeReferenceNode;
/// ```
///
/// ## Parameters
/// - `iterator`: NodeIterator handle
///
/// ## Returns
/// 1 if pointer is before reference node, 0 if after
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodeiterator-pointerbeforereferencenode
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/pointerBeforeReferenceNode
pub export fn dom_nodeiterator_get_pointerbeforereferencenode(iterator: *const DOMNodeIterator) u8 {
    const it: *const NodeIterator = @ptrCast(@alignCast(iterator));
    return if (it.pointer_before_reference_node) 1 else 0;
}

/// Get the whatToShow bitmask.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long whatToShow;
/// ```
///
/// ## Parameters
/// - `iterator`: NodeIterator handle
///
/// ## Returns
/// Bitmask of node types to show (NodeFilter.SHOW_* constants)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodeiterator-whattoshow
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/whatToShow
pub export fn dom_nodeiterator_get_whattoshow(iterator: *const DOMNodeIterator) u32 {
    const it: *const NodeIterator = @ptrCast(@alignCast(iterator));
    return it.what_to_show;
}

// ============================================================================
// NodeIterator Navigation Methods
// ============================================================================

/// Navigate to next node in iteration order.
///
/// ## WebIDL
/// ```webidl
/// Node? nextNode();
/// ```
///
/// ## Parameters
/// - `iterator`: NodeIterator handle
///
/// ## Returns
/// Next node, or null if at end
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodeiterator-nextnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/nextNode
pub export fn dom_nodeiterator_nextnode(iterator: *DOMNodeIterator) ?*DOMNode {
    const it: *NodeIterator = @ptrCast(@alignCast(iterator));
    return if (it.nextNode()) |node| @ptrCast(node) else null;
}

/// Navigate to previous node in iteration order.
///
/// ## WebIDL
/// ```webidl
/// Node? previousNode();
/// ```
///
/// ## Parameters
/// - `iterator`: NodeIterator handle
///
/// ## Returns
/// Previous node, or null if at beginning
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodeiterator-previousnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/previousNode
pub export fn dom_nodeiterator_previousnode(iterator: *DOMNodeIterator) ?*DOMNode {
    const it: *NodeIterator = @ptrCast(@alignCast(iterator));
    return if (it.previousNode()) |node| @ptrCast(node) else null;
}

// ============================================================================
// NodeIterator Lifecycle
// ============================================================================

/// Detach the iterator (no-op per spec).
///
/// ## WebIDL
/// ```webidl
/// undefined detach();
/// ```
///
/// ## Parameters
/// - `iterator`: NodeIterator handle
///
/// ## Note
/// This method is a no-op. It exists for historical reasons and spec compatibility.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-nodeiterator-detach
/// - https://developer.mozilla.org/en-US/docs/Web/API/NodeIterator/detach
pub export fn dom_nodeiterator_detach(iterator: *DOMNodeIterator) void {
    const it: *NodeIterator = @ptrCast(@alignCast(iterator));
    it.detach();
}

/// Release a NodeIterator and free its memory.
///
/// ## Parameters
/// - `iterator`: NodeIterator handle
pub export fn dom_nodeiterator_release(iterator: *DOMNodeIterator) void {
    const it: *NodeIterator = @ptrCast(@alignCast(iterator));
    it.deinit();
}
