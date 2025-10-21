//! ChildNode Mixin C-ABI Bindings
//!
//! This module provides C-compatible bindings for the WHATWG DOM ChildNode mixin.
//! ChildNode provides modern convenience methods for manipulating nodes relative to siblings.
//!
//! ## WebIDL Interface
//!
//! ```webidl
//! interface mixin ChildNode {
//!   [CEReactions, Unscopable] undefined before((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined after((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined replaceWith((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined remove();
//! };
//! ```
//!
//! ## Spec References
//!
//! - **WHATWG DOM**: https://dom.spec.whatwg.org/#interface-childnode
//! - **MDN ChildNode**: https://developer.mozilla.org/en-US/docs/Web/API/ChildNode
//!
//! ## C-ABI Design
//!
//! The WebIDL methods accept variadic (Node or DOMString) arguments. For C-ABI simplicity,
//! we provide array-based APIs that accept only nodes:
//!
//! - C callers can create Text nodes explicitly if needed
//! - Arrays are simpler than variadic functions in C
//! - Type safety is maintained (no union types needed)
//!
//! ## Usage Example (C)
//!
//! ```c
//! // Remove a node
//! dom_childnode_remove(element_node);
//!
//! // Insert single node before
//! DOMNode* sibling = (DOMNode*)dom_document_createelement(doc, "sibling");
//! dom_childnode_before(element_node, &sibling, 1);
//!
//! // Insert multiple nodes after
//! DOMNode* nodes[3] = {node1, node2, node3};
//! dom_childnode_after(element_node, nodes, 3);
//!
//! // Replace with nodes
//! DOMNode* replacements[2] = {new1, new2};
//! dom_childnode_replacewith(element_node, replacements, 2);
//! ```

const std = @import("std");
const root = @import("root.zig");
const dom = @import("dom");
const Node = dom.Node;
const NodeOrString = dom.child_node.NodeOrString;
const DOMNode = root.DOMNode;
const DOMErrorCode = root.DOMErrorCode;
const zigErrorToDOMError = root.zigErrorToDOMError;

// ============================================================================
// ChildNode Methods
// ============================================================================

/// Insert nodes before this node.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined before((Node or DOMString)... nodes);
/// ```
///
/// ## Parameters
/// - `child`: Node to insert before
/// - `nodes`: Array of nodes to insert
/// - `count`: Number of nodes in array
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Note
/// This node must have a parent. Nodes are inserted in array order.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-childnode-before
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/before
pub export fn dom_childnode_before(
    child: *DOMNode,
    nodes: [*]const *DOMNode,
    count: u32,
) DOMErrorCode {
    const child_node: *Node = @ptrCast(@alignCast(child));

    // Convert C array to Zig slice of NodeOrString
    const allocator = std.heap.c_allocator;
    var node_or_strings = allocator.alloc(NodeOrString, count) catch {
        return DOMErrorCode.QuotaExceededError;
    };
    defer allocator.free(node_or_strings);

    for (0..count) |i| {
        const node: *Node = @ptrCast(@alignCast(nodes[i]));
        node_or_strings[i] = .{ .node = node };
    }

    dom.child_node.before(child_node, node_or_strings) catch |err| {
        return zigErrorToDOMError(err);
    };

    return DOMErrorCode.Success;
}

/// Insert nodes after this node.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined after((Node or DOMString)... nodes);
/// ```
///
/// ## Parameters
/// - `child`: Node to insert after
/// - `nodes`: Array of nodes to insert
/// - `count`: Number of nodes in array
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Note
/// This node must have a parent. Nodes are inserted in array order.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-childnode-after
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/after
pub export fn dom_childnode_after(
    child: *DOMNode,
    nodes: [*]const *DOMNode,
    count: u32,
) DOMErrorCode {
    const child_node: *Node = @ptrCast(@alignCast(child));

    // Convert C array to Zig slice of NodeOrString
    const allocator = std.heap.c_allocator;
    var node_or_strings = allocator.alloc(NodeOrString, count) catch {
        return DOMErrorCode.QuotaExceededError;
    };
    defer allocator.free(node_or_strings);

    for (0..count) |i| {
        const node: *Node = @ptrCast(@alignCast(nodes[i]));
        node_or_strings[i] = .{ .node = node };
    }

    dom.child_node.after(child_node, node_or_strings) catch |err| {
        return zigErrorToDOMError(err);
    };

    return DOMErrorCode.Success;
}

/// Replace this node with other nodes.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined replaceWith((Node or DOMString)... nodes);
/// ```
///
/// ## Parameters
/// - `child`: Node to replace
/// - `nodes`: Array of replacement nodes
/// - `count`: Number of nodes in array
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Note
/// This node must have a parent. The node is removed and replaced with the given nodes.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-childnode-replacewith
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith
pub export fn dom_childnode_replacewith(
    child: *DOMNode,
    nodes: [*]const *DOMNode,
    count: u32,
) DOMErrorCode {
    const child_node: *Node = @ptrCast(@alignCast(child));

    // Convert C array to Zig slice of NodeOrString
    const allocator = std.heap.c_allocator;
    var node_or_strings = allocator.alloc(NodeOrString, count) catch {
        return DOMErrorCode.QuotaExceededError;
    };
    defer allocator.free(node_or_strings);

    for (0..count) |i| {
        const node: *Node = @ptrCast(@alignCast(nodes[i]));
        node_or_strings[i] = .{ .node = node };
    }

    dom.child_node.replaceWith(child_node, node_or_strings) catch |err| {
        return zigErrorToDOMError(err);
    };

    return DOMErrorCode.Success;
}

/// Remove this node from its parent.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined remove();
/// ```
///
/// ## Parameters
/// - `child`: Node to remove
///
/// ## Note
/// This is a convenience method equivalent to `parent.removeChild(child)`.
/// If the node has no parent, this is a no-op.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-childnode-remove
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/remove
pub export fn dom_childnode_remove(child: *DOMNode) void {
    const child_node: *Node = @ptrCast(@alignCast(child));
    dom.child_node.remove(child_node);
}
