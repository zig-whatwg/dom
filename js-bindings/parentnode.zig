//! ParentNode Mixin C-ABI Bindings
//!
//! This module provides C-compatible bindings for the WHATWG DOM ParentNode mixin methods.
//! ParentNode provides modern convenience methods for manipulating a node's children.
//!
//! ## WebIDL Interface
//!
//! ```webidl
//! interface mixin ParentNode {
//!   [CEReactions, Unscopable] undefined prepend((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined append((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined replaceChildren((Node or DOMString)... nodes);
//! };
//! ```
//!
//! Note: Other ParentNode members (children, querySelector, etc.) are already exposed
//! through Element and Document bindings.
//!
//! ## Spec References
//!
//! - **WHATWG DOM**: https://dom.spec.whatwg.org/#interface-parentnode
//! - **MDN ParentNode**: https://developer.mozilla.org/en-US/docs/Web/API/ParentNode
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
//! // Append single node
//! DOMElement* child = dom_document_createelement(doc, "child");
//! DOMNode* nodes[1] = { (DOMNode*)child };
//! dom_parentnode_append((DOMNode*)parent, nodes, 1);
//!
//! // Prepend multiple nodes
//! DOMNode* nodes[3] = { node1, node2, node3 };
//! dom_parentnode_prepend((DOMNode*)parent, nodes, 3);
//!
//! // Replace all children
//! DOMNode* new_children[2] = { new1, new2 };
//! dom_parentnode_replacechildren((DOMNode*)parent, new_children, 2);
//! ```

const std = @import("std");
const root = @import("root.zig");
const dom = @import("dom");
const Node = dom.Node;
const Element = dom.Element;
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;
const DOMNode = root.DOMNode;
const DOMErrorCode = root.DOMErrorCode;
const zigErrorToDOMError = root.zigErrorToDOMError;

// ============================================================================
// ParentNode Methods
// ============================================================================

/// Prepend nodes at the beginning of this node's children.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined prepend((Node or DOMString)... nodes);
/// ```
///
/// ## Parameters
/// - `parent`: Node to prepend to (must be Element, Document, or DocumentFragment)
/// - `nodes`: Array of nodes to prepend
/// - `count`: Number of nodes in array
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Note
/// Nodes are inserted at the beginning in array order.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-parentnode-prepend
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend
pub export fn dom_parentnode_prepend(
    parent: *DOMNode,
    nodes: [*]const *DOMNode,
    count: u32,
) DOMErrorCode {
    const parent_node: *Node = @ptrCast(@alignCast(parent));
    const allocator = std.heap.c_allocator;

    // Call the appropriate prepend based on node type
    switch (parent_node.node_type) {
        .element => {
            const elem: *Element = @fieldParentPtr("prototype", parent_node);

            // Convert to Element.NodeOrString
            var node_or_strings = allocator.alloc(Element.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            elem.prepend(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        .document => {
            const doc: *Document = @fieldParentPtr("prototype", parent_node);

            // Convert to Document.NodeOrString
            var node_or_strings = allocator.alloc(Document.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            doc.prepend(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        .document_fragment => {
            const frag: *DocumentFragment = @fieldParentPtr("prototype", parent_node);

            // Convert to DocumentFragment.NodeOrString
            var node_or_strings = allocator.alloc(DocumentFragment.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            frag.prepend(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        else => return DOMErrorCode.HierarchyRequestError,
    }

    return DOMErrorCode.Success;
}

/// Append nodes at the end of this node's children.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined append((Node or DOMString)... nodes);
/// ```
///
/// ## Parameters
/// - `parent`: Node to append to (must be Element, Document, or DocumentFragment)
/// - `nodes`: Array of nodes to append
/// - `count`: Number of nodes in array
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Note
/// Nodes are inserted at the end in array order.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-parentnode-append
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/append
pub export fn dom_parentnode_append(
    parent: *DOMNode,
    nodes: [*]const *DOMNode,
    count: u32,
) DOMErrorCode {
    const parent_node: *Node = @ptrCast(@alignCast(parent));
    const allocator = std.heap.c_allocator;

    // Call the appropriate append based on node type
    switch (parent_node.node_type) {
        .element => {
            const elem: *Element = @fieldParentPtr("prototype", parent_node);

            // Convert to Element.NodeOrString
            var node_or_strings = allocator.alloc(Element.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            elem.append(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        .document => {
            const doc: *Document = @fieldParentPtr("prototype", parent_node);

            // Convert to Document.NodeOrString
            var node_or_strings = allocator.alloc(Document.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            doc.append(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        .document_fragment => {
            const frag: *DocumentFragment = @fieldParentPtr("prototype", parent_node);

            // Convert to parent_node.NodeOrString
            var node_or_strings = allocator.alloc(DocumentFragment.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            frag.append(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        else => return DOMErrorCode.HierarchyRequestError,
    }

    return DOMErrorCode.Success;
}

/// Replace all children with new nodes.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined replaceChildren((Node or DOMString)... nodes);
/// ```
///
/// ## Parameters
/// - `parent`: Node whose children to replace (must be Element, Document, or DocumentFragment)
/// - `nodes`: Array of replacement nodes
/// - `count`: Number of nodes in array
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Note
/// All existing children are removed and replaced with the given nodes.
/// Pass count=0 to remove all children.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-parentnode-replacechildren
/// - https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceChildren
pub export fn dom_parentnode_replacechildren(
    parent: *DOMNode,
    nodes: [*]const *DOMNode,
    count: u32,
) DOMErrorCode {
    const parent_node: *Node = @ptrCast(@alignCast(parent));
    const allocator = std.heap.c_allocator;

    // Call the appropriate replaceChildren based on node type
    switch (parent_node.node_type) {
        .element => {
            const elem: *Element = @fieldParentPtr("prototype", parent_node);

            // Convert to Element.NodeOrString
            var node_or_strings = allocator.alloc(Element.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            elem.replaceChildren(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        .document => {
            const doc: *Document = @fieldParentPtr("prototype", parent_node);

            // Convert to Document.NodeOrString
            var node_or_strings = allocator.alloc(Document.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            doc.replaceChildren(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        .document_fragment => {
            const frag: *DocumentFragment = @fieldParentPtr("prototype", parent_node);

            // Convert to parent_node.NodeOrString
            var node_or_strings = allocator.alloc(DocumentFragment.NodeOrString, count) catch {
                return DOMErrorCode.QuotaExceededError;
            };
            defer allocator.free(node_or_strings);

            for (0..count) |i| {
                const node: *Node = @ptrCast(@alignCast(nodes[i]));
                node_or_strings[i] = .{ .node = node };
            }

            frag.replaceChildren(node_or_strings) catch |err| {
                return zigErrorToDOMError(err);
            };
        },
        else => return DOMErrorCode.HierarchyRequestError,
    }

    return DOMErrorCode.Success;
}
