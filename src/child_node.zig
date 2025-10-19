//! ChildNode Mixin (§4.2.7)
//!
//! This module implements the ChildNode interface mixin as specified by the WHATWG DOM Standard.
//! ChildNode provides modern convenience methods for manipulating nodes in relation to their siblings.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.2.7 Mixin ChildNode**: https://dom.spec.whatwg.org/#interface-childnode
//!
//! ## WebIDL
//!
//! ```webidl
//! interface mixin ChildNode {
//!   [CEReactions, Unscopable] undefined before((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined after((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined replaceWith((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined remove();
//! };
//! DocumentType includes ChildNode;
//! Element includes ChildNode;
//! CharacterData includes ChildNode;
//! ```
//!
//! ## MDN Documentation
//!
//! - ChildNode: https://developer.mozilla.org/en-US/docs/Web/API/ChildNode
//! - ChildNode.before(): https://developer.mozilla.org/en-US/docs/Web/API/Element/before
//! - ChildNode.after(): https://developer.mozilla.org/en-US/docs/Web/API/Element/after
//! - ChildNode.replaceWith(): https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith
//! - ChildNode.remove(): https://developer.mozilla.org/en-US/docs/Web/API/Element/remove
//!
//! ## Applied To
//!
//! The ChildNode mixin is included by:
//! - **Element** - All element nodes
//! - **CharacterData** - Text and Comment nodes
//! - **DocumentType** - DOCTYPE declarations
//!
//! ## Core Features
//!
//! ### Modern Convenience Methods
//! ChildNode provides ergonomic methods for common DOM manipulations:
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const elem = try doc.createElement("item");
//! const parent = try doc.createElement("container");
//! _ = try parent.prototype.appendChild(&elem.prototype);
//!
//! // Modern removal (vs. parent.removeChild(elem))
//! elem.remove();
//!
//! // Insert siblings with one call
//! const sibling = try doc.createElement("sibling");
//! try elem.after(&[_]NodeOrString{.{ .node = &sibling.prototype }});
//! ```
//!
//! ### Variadic Node/String Arguments
//! Methods accept slices of NodeOrString unions:
//! ```zig
//! // Multiple nodes and strings in one call
//! try elem.before(&[_]NodeOrString{
//!     .{ .node = &node1.prototype },
//!     .{ .string = "text content" },
//!     .{ .node = &node2.prototype },
//! });
//! ```
//!
//! ### Automatic Text Node Creation
//! String arguments are automatically converted to Text nodes:
//! ```zig
//! try elem.after(&[_]NodeOrString{.{ .string = "Hello" }});
//! // Creates and inserts a Text node with "Hello"
//! ```
//!
//! ## Performance
//!
//! - **Fast path for single node**: No DocumentFragment created
//! - **Batch operations**: Multiple nodes use temporary DocumentFragment
//! - **Early returns**: Null parent or empty arrays return immediately
//! - **Reuses primitives**: Delegates to insertBefore/removeChild
//!
//! ## Memory Management
//!
//! All methods handle reference counting correctly:
//! - Temporary Text nodes and DocumentFragments are properly managed
//! - No manual acquire/release needed when using NodeOrString
//! - Methods are safe to use with testing.allocator
//!
//! ## Implementation Notes
//!
//! Based on browser implementations (Chrome/Blink, Firefox/Gecko, WebKit):
//! - All browsers use the same pattern: convert nodes → delegate to primitives
//! - Single node fast path is critical for performance
//! - DocumentFragment is used only for multiple nodes
//! - No special tree manipulation logic beyond existing insertBefore/removeChild

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const Document = @import("document.zig").Document;
const DocumentFragment = @import("document_fragment.zig").DocumentFragment;
const Text = @import("text.zig").Text;

/// Union type for methods accepting either a Node pointer or a DOMString.
///
/// This matches the WebIDL union type `(Node or DOMString)` used in variadic
/// ChildNode methods.
///
/// ## Usage
/// ```zig
/// const nodes = [_]NodeOrString{
///     .{ .node = &element.prototype },
///     .{ .string = "text content" },
/// };
/// try element.before(&nodes);
/// ```
pub const NodeOrString = union(enum) {
    node: *Node,
    string: []const u8,
};

/// Convert a slice of NodeOrString items into a single Node.
///
/// ## Algorithm (WHATWG §4.2.7)
///
/// This implements the "converting nodes into a node" algorithm:
/// 1. If nodes is empty, return null
/// 2. If nodes contains a single item:
///    - If Node: return that node (fast path)
///    - If DOMString: create Text node with that string
/// 3. If nodes contains multiple items:
///    - Create a DocumentFragment
///    - For each item, convert strings to Text nodes
///    - Append all nodes to the fragment
///    - Return the fragment
///
/// ## Performance
///
/// - **Fast path**: Single node avoids DocumentFragment allocation
/// - **Empty slice**: Immediate return (no allocations)
/// - **Multiple nodes**: Creates temporary DocumentFragment
///
/// ## Spec Reference
///
/// - Algorithm: https://dom.spec.whatwg.org/#converting-nodes-into-a-node
/// - WebIDL: dom.idl lines 144-149
///
/// ## Parameters
///
/// - `owner_doc`: Document to create Text nodes and DocumentFragment
/// - `nodes`: Slice of NodeOrString items to convert
///
/// ## Returns
///
/// Single Node pointer, or null if nodes is empty
fn convertNodesToNode(
    owner_doc: *Document,
    nodes: []const NodeOrString,
) !?*Node {
    if (nodes.len == 0) return null;

    // Fast path: single node
    if (nodes.len == 1) {
        return switch (nodes[0]) {
            .node => |n| n,
            .string => |s| blk: {
                const text = try owner_doc.createTextNode(s);
                break :blk &text.prototype;
            },
        };
    }

    // Multiple nodes: create DocumentFragment
    const fragment = try owner_doc.createDocumentFragment();

    for (nodes) |item| {
        const node = switch (item) {
            .node => |n| n,
            .string => |s| blk: {
                const text = try owner_doc.createTextNode(s);
                break :blk &text.prototype;
            },
        };
        _ = try fragment.prototype.appendChild(node);
    }

    return &fragment.prototype;
}

// ============================================================================
// ChildNode Mixin Methods
// ============================================================================

/// Insert nodes before this node.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined before((Node or DOMString)... nodes);
/// ```
///
/// ## Algorithm (WHATWG §4.2.7)
///
/// 1. Let parent be this's parent
/// 2. If parent is null, return (no-op)
/// 3. Let viablePreviousSibling be this's first preceding sibling not in nodes, or null
/// 4. Convert nodes into node
/// 5. Pre-insert node into parent before this
///
/// ## Spec Reference
///
/// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-before
/// - WebIDL: dom.idl line 145
///
/// ## MDN Documentation
///
/// - ChildNode.before(): https://developer.mozilla.org/en-US/docs/Web/API/Element/before
///
/// ## Parameters
///
/// - `self`: The node to insert before
/// - `nodes`: Slice of nodes and/or strings to insert
///
/// ## Errors
///
/// Returns WHATWG DOM errors from insertBefore:
/// - `HierarchyRequestError` - Invalid parent/child relationship
/// - `OutOfMemory` - Allocation failure
///
/// ## Example
///
/// ```zig
/// const doc = try Document.init(allocator);
/// defer doc.release();
///
/// const parent = try doc.createElement("container");
/// const elem = try doc.createElement("item");
/// _ = try parent.prototype.appendChild(&elem.prototype);
///
/// const sibling = try doc.createElement("sibling");
/// try elem.before(&[_]NodeOrString{.{ .node = &sibling.prototype }});
/// // Result: <container><sibling/><item/></container>
/// ```
pub fn before(self: *Node, nodes: []const NodeOrString) !void {
    const parent = self.parent_node orelse return; // No parent = no-op

    // Find owner document for text node creation
    const owner_doc = self.ownerDocument() orelse return;

    // Convert nodes
    const node = try convertNodesToNode(owner_doc, nodes) orelse return;

    // Insert before self
    _ = try parent.insertBefore(node, self);
}

/// Insert nodes after this node.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined after((Node or DOMString)... nodes);
/// ```
///
/// ## Algorithm (WHATWG §4.2.7)
///
/// 1. Let parent be this's parent
/// 2. If parent is null, return (no-op)
/// 3. Let viableNextSibling be this's first following sibling not in nodes, or null
/// 4. Convert nodes into node
/// 5. Pre-insert node into parent before viableNextSibling
///
/// ## Spec Reference
///
/// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-after
/// - WebIDL: dom.idl line 146
///
/// ## MDN Documentation
///
/// - ChildNode.after(): https://developer.mozilla.org/en-US/docs/Web/API/Element/after
///
/// ## Parameters
///
/// - `self`: The node to insert after
/// - `nodes`: Slice of nodes and/or strings to insert
///
/// ## Errors
///
/// Returns WHATWG DOM errors from insertBefore:
/// - `HierarchyRequestError` - Invalid parent/child relationship
/// - `OutOfMemory` - Allocation failure
///
/// ## Example
///
/// ```zig
/// const doc = try Document.init(allocator);
/// defer doc.release();
///
/// const parent = try doc.createElement("container");
/// const elem = try doc.createElement("item");
/// _ = try parent.prototype.appendChild(&elem.prototype);
///
/// const sibling = try doc.createElement("sibling");
/// try elem.after(&[_]NodeOrString{.{ .node = &sibling.prototype }});
/// // Result: <container><item/><sibling/></container>
/// ```
pub fn after(self: *Node, nodes: []const NodeOrString) !void {
    const parent = self.parent_node orelse return; // No parent = no-op

    const owner_doc = self.ownerDocument() orelse return;

    const node = try convertNodesToNode(owner_doc, nodes) orelse return;

    // Insert after self = insert before next sibling (or append if last)
    _ = try parent.insertBefore(node, self.next_sibling);
}

/// Replace this node with nodes.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined replaceWith((Node or DOMString)... nodes);
/// ```
///
/// ## Algorithm (WHATWG §4.2.7)
///
/// 1. Let parent be this's parent
/// 2. If parent is null, return (no-op)
/// 3. Let viableNextSibling be this's first following sibling not in nodes, or null
/// 4. Convert nodes into node
/// 5. If this's parent is parent, replace this with node within parent
/// 6. Otherwise, pre-insert node into parent before viableNextSibling
///
/// ## Spec Reference
///
/// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-replacewith
/// - WebIDL: dom.idl line 147
///
/// ## MDN Documentation
///
/// - ChildNode.replaceWith(): https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith
///
/// ## Parameters
///
/// - `self`: The node to replace
/// - `nodes`: Slice of nodes and/or strings to use as replacement
///
/// ## Errors
///
/// Returns WHATWG DOM errors from replaceChild:
/// - `HierarchyRequestError` - Invalid parent/child relationship
/// - `OutOfMemory` - Allocation failure
///
/// ## Example
///
/// ```zig
/// const doc = try Document.init(allocator);
/// defer doc.release();
///
/// const parent = try doc.createElement("container");
/// const oldElem = try doc.createElement("old");
/// _ = try parent.prototype.appendChild(&oldElem.prototype);
///
/// const newElem = try doc.createElement("new");
/// try oldElem.replaceWith(&[_]NodeOrString{.{ .node = &newElem.prototype }});
/// // Result: <container><new/></container>
/// ```
pub fn replaceWith(self: *Node, nodes: []const NodeOrString) !void {
    const parent = self.parent_node orelse return; // No parent = no-op

    const owner_doc = self.ownerDocument() orelse return;

    const node = try convertNodesToNode(owner_doc, nodes) orelse return;

    // Replace this node with the new node(s)
    _ = try parent.replaceChild(node, self);
}

/// Remove this node from its parent.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined remove();
/// ```
///
/// ## Algorithm (WHATWG §4.2.7)
///
/// 1. If this's parent is null, return (no-op)
/// 2. Remove this from its parent
///
/// ## Spec Reference
///
/// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-remove
/// - WebIDL: dom.idl line 148
///
/// ## MDN Documentation
///
/// - ChildNode.remove(): https://developer.mozilla.org/en-US/docs/Web/API/Element/remove
///
/// ## Parameters
///
/// - `self`: The node to remove
///
/// ## Errors
///
/// This method does not return errors. If the node has no parent, it's a no-op.
/// Any errors from removeChild are ignored (shouldn't happen in practice).
///
/// ## Example
///
/// ```zig
/// const doc = try Document.init(allocator);
/// defer doc.release();
///
/// const parent = try doc.createElement("container");
/// const elem = try doc.createElement("item");
/// _ = try parent.prototype.appendChild(&elem.prototype);
///
/// elem.remove();
/// // Result: <container/> (elem is detached)
/// ```
pub fn remove(self: *Node) void {
    const parent = self.parent_node orelse return;
    _ = parent.removeChild(self) catch {}; // Ignore errors (shouldn't happen)
}
