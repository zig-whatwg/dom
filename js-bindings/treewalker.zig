//! TreeWalker C-ABI Bindings
//!
//! This module provides C-compatible bindings for the WHATWG DOM TreeWalker interface.
//! TreeWalker provides flexible navigation through a filtered view of the DOM tree.
//!
//! ## WebIDL Interface
//!
//! ```webidl
//! interface TreeWalker {
//!   [SameObject] readonly attribute Node root;
//!   readonly attribute unsigned long whatToShow;
//!   readonly attribute NodeFilter? filter;
//!   attribute Node currentNode;
//!
//!   Node? parentNode();
//!   Node? firstChild();
//!   Node? lastChild();
//!   Node? previousSibling();
//!   Node? nextSibling();
//!   Node? previousNode();
//!   Node? nextNode();
//! };
//! ```
//!
//! ## Spec References
//!
//! - **WHATWG DOM**: https://dom.spec.whatwg.org/#interface-treewalker
//! - **MDN TreeWalker**: https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker
//!
//! ## Usage Example (C)
//!
//! ```c
//! // Create tree walker (via Document)
//! DOMTreeWalker* walker = dom_document_createtreewalker(
//!     doc,
//!     root_node,
//!     DOM_NODEFILTER_SHOW_ELEMENT,  // Show only elements
//!     NULL                           // No custom filter
//! );
//!
//! // Get root
//! DOMNode* root = dom_treewalker_get_root(walker);
//!
//! // Navigate to first child
//! DOMNode* child = dom_treewalker_firstchild(walker);
//! if (child) {
//!     printf("First child found\n");
//! }
//!
//! // Navigate to next sibling
//! DOMNode* sibling = dom_treewalker_nextsibling(walker);
//!
//! // Clean up
//! dom_treewalker_release(walker);
//! ```

const std = @import("std");
const root = @import("root.zig");
const dom = @import("dom");
const TreeWalker = dom.TreeWalker;
const Node = dom.Node;
const DOMNode = root.DOMNode;
const DOMTreeWalker = root.DOMTreeWalker;

// ============================================================================
// TreeWalker Properties
// ============================================================================

/// Get the root node of the tree walker.
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute Node root;
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Root node (never null)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-root
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/root
pub export fn dom_treewalker_get_root(walker: *const DOMTreeWalker) *DOMNode {
    const tw: *const TreeWalker = @ptrCast(@alignCast(walker));
    return @ptrCast(tw.root);
}

/// Get the whatToShow bitmask.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long whatToShow;
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Bitmask of node types to show (NodeFilter.SHOW_* constants)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-whattoshow
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/whatToShow
pub export fn dom_treewalker_get_whattoshow(walker: *const DOMTreeWalker) u32 {
    const tw: *const TreeWalker = @ptrCast(@alignCast(walker));
    return tw.what_to_show;
}

/// Get the current node.
///
/// ## WebIDL
/// ```webidl
/// attribute Node currentNode;
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Current node (never null)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-currentnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/currentNode
pub export fn dom_treewalker_get_currentnode(walker: *const DOMTreeWalker) *DOMNode {
    const tw: *const TreeWalker = @ptrCast(@alignCast(walker));
    return @ptrCast(tw.current_node);
}

/// Set the current node.
///
/// ## WebIDL
/// ```webidl
/// attribute Node currentNode;
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
/// - `node`: New current node
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-currentnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/currentNode
pub export fn dom_treewalker_set_currentnode(walker: *DOMTreeWalker, node: *DOMNode) void {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    const n: *Node = @ptrCast(@alignCast(node));
    tw.current_node = n;
}

// ============================================================================
// TreeWalker Navigation Methods
// ============================================================================

/// Navigate to parent node.
///
/// ## WebIDL
/// ```webidl
/// Node? parentNode();
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Parent node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-parentnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/parentNode
pub export fn dom_treewalker_parentnode(walker: *DOMTreeWalker) ?*DOMNode {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    return if (tw.parentNode()) |node| @ptrCast(node) else null;
}

/// Navigate to first child.
///
/// ## WebIDL
/// ```webidl
/// Node? firstChild();
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// First child node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-firstchild
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/firstChild
pub export fn dom_treewalker_firstchild(walker: *DOMTreeWalker) ?*DOMNode {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    return if (tw.firstChild()) |node| @ptrCast(node) else null;
}

/// Navigate to last child.
///
/// ## WebIDL
/// ```webidl
/// Node? lastChild();
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Last child node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-lastchild
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/lastChild
pub export fn dom_treewalker_lastchild(walker: *DOMTreeWalker) ?*DOMNode {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    return if (tw.lastChild()) |node| @ptrCast(node) else null;
}

/// Navigate to previous sibling.
///
/// ## WebIDL
/// ```webidl
/// Node? previousSibling();
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Previous sibling node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-previoussibling
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/previousSibling
pub export fn dom_treewalker_previoussibling(walker: *DOMTreeWalker) ?*DOMNode {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    return if (tw.previousSibling()) |node| @ptrCast(node) else null;
}

/// Navigate to next sibling.
///
/// ## WebIDL
/// ```webidl
/// Node? nextSibling();
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Next sibling node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-nextsibling
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/nextSibling
pub export fn dom_treewalker_nextsibling(walker: *DOMTreeWalker) ?*DOMNode {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    return if (tw.nextSibling()) |node| @ptrCast(node) else null;
}

/// Navigate to previous node in tree order.
///
/// ## WebIDL
/// ```webidl
/// Node? previousNode();
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Previous node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-previousnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/previousNode
pub export fn dom_treewalker_previousnode(walker: *DOMTreeWalker) ?*DOMNode {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    return if (tw.previousNode()) |node| @ptrCast(node) else null;
}

/// Navigate to next node in tree order.
///
/// ## WebIDL
/// ```webidl
/// Node? nextNode();
/// ```
///
/// ## Parameters
/// - `walker`: TreeWalker handle
///
/// ## Returns
/// Next node, or null if none
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-treewalker-nextnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker/nextNode
pub export fn dom_treewalker_nextnode(walker: *DOMTreeWalker) ?*DOMNode {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    return if (tw.nextNode()) |node| @ptrCast(node) else null;
}

// ============================================================================
// TreeWalker Lifecycle
// ============================================================================

/// Release a TreeWalker and free its memory.
///
/// ## Parameters
/// - `walker`: TreeWalker handle
pub export fn dom_treewalker_release(walker: *DOMTreeWalker) void {
    const tw: *TreeWalker = @ptrCast(@alignCast(walker));
    tw.deinit();
}
