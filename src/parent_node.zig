//! ParentNode Mixin (§4.2.6)
//!
//! This module implements the ParentNode interface mixin as specified by the WHATWG DOM Standard.
//! ParentNode provides modern convenience methods for manipulating a node's children.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#interface-parentnode
//!
//! ## WebIDL
//!
//! ```webidl
//! interface mixin ParentNode {
//!   [SameObject] readonly attribute HTMLCollection children;
//!   readonly attribute Element? firstElementChild;
//!   readonly attribute Element? lastElementChild;
//!   readonly attribute unsigned long childElementCount;
//!
//!   [CEReactions, Unscopable] undefined prepend((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined append((Node or DOMString)... nodes);
//!   [CEReactions, Unscopable] undefined replaceChildren((Node or DOMString)... nodes);
//!
//!   Element? querySelector(DOMString selectors);
//!   [NewObject] NodeList querySelectorAll(DOMString selectors);
//! };
//! Document includes ParentNode;
//! DocumentFragment includes ParentNode;
//! Element includes ParentNode;
//! ```
//!
//! ## MDN Documentation
//!
//! - ParentNode: https://developer.mozilla.org/en-US/docs/Web/API/ParentNode
//! - ParentNode.prepend(): https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend
//! - ParentNode.append(): https://developer.mozilla.org/en-US/docs/Web/API/Element/append
//! - ParentNode.replaceChildren(): https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceChildren
//!
//! ## Applied To
//!
//! The ParentNode mixin is included by:
//! - **Document** - The document node
//! - **DocumentFragment** - Document fragments
//! - **Element** - All element nodes
//!
//! ## Already Implemented
//!
//! The following ParentNode properties and methods are already implemented on the respective types:
//! - `children` - HTMLCollection of child elements
//! - `firstElementChild` / `lastElementChild` - First/last child element
//! - `childElementCount` - Number of child elements
//! - `querySelector()` / `querySelectorAll()` - Selector queries
//!
//! This module implements the remaining convenience methods:
//! - `prepend()` - Insert at beginning
//! - `append()` - Insert at end
//! - `replaceChildren()` - Replace all children
//!
//! ## Core Features
//!
//! ### Modern Convenience Methods
//! ParentNode provides ergonomic methods for common DOM manipulations:
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const parent = try doc.createElement("container");
//!
//! // Modern append (vs. parent.prototype.appendChild())
//! const child = try doc.createElement("item");
//! try parent.append(&[_]NodeOrString{.{ .node = &child.prototype }});
//!
//! // Prepend to beginning
//! const first = try doc.createElement("first");
//! try parent.prepend(&[_]NodeOrString{.{ .node = &first.prototype }});
//! ```
//!
//! ### Variadic Node/String Arguments
//! Methods accept slices of NodeOrString unions:
//! ```zig
//! // Multiple nodes and strings in one call
//! try parent.append(&[_]NodeOrString{
//!     .{ .node = &node1.prototype },
//!     .{ .string = "text content" },
//!     .{ .node = &node2.prototype },
//! });
//! ```
//!
//! ### Automatic Text Node Creation
//! String arguments are automatically converted to Text nodes:
//! ```zig
//! try parent.append(&[_]NodeOrString{.{ .string = "Hello" }});
//! // Creates and appends a Text node with "Hello"
//! ```
//!
//! ## Performance
//!
//! - **Fast path for single node**: No DocumentFragment created
//! - **Batch operations**: Multiple nodes use temporary DocumentFragment
//! - **Early returns**: Empty arrays return immediately
//! - **Reuses primitives**: Delegates to appendChild/insertBefore/removeChild
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
//! - No special tree manipulation logic beyond existing appendChild/insertBefore

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const Document = @import("document.zig").Document;
const DocumentFragment = @import("document_fragment.zig").DocumentFragment;
const Text = @import("text.zig").Text;

/// Union type for methods accepting either a Node pointer or a DOMString.
///
/// This matches the WebIDL union type `(Node or DOMString)` used in variadic
/// ParentNode methods.
///
/// ## Usage
/// ```zig
/// const nodes = [_]NodeOrString{
///     .{ .node = &element.prototype },
///     .{ .string = "text content" },
/// };
/// try parent.append(&nodes);
/// ```
pub const NodeOrString = union(enum) {
    node: *Node,
    string: []const u8,
};

/// Convert a slice of NodeOrString items into a single Node.
///
/// ## Algorithm (WHATWG §4.2.6)
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
/// - WebIDL: dom.idl lines 124-126
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
// ParentNode Mixin Methods
// ============================================================================

/// Insert nodes at the beginning of this node's children.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined prepend((Node or DOMString)... nodes);
/// ```
///
/// ## Algorithm (WHATWG §4.2.6)
///
/// 1. Convert nodes into node
/// 2. Pre-insert node into this before this's first child
///
/// ## Spec Reference
///
/// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-prepend
/// - WebIDL: dom.idl line 124
///
/// ## MDN Documentation
///
/// - ParentNode.prepend(): https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend
///
/// ## Parameters
///
/// - `self`: The parent node to prepend to
/// - `nodes`: Slice of nodes and/or strings to prepend
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
/// const child1 = try doc.createElement("item1");
/// _ = try parent.prototype.appendChild(&child1.prototype);
///
/// const child2 = try doc.createElement("item2");
/// try parent.prepend(&[_]NodeOrString{.{ .node = &child2.prototype }});
/// // Result: <container><item2/><item1/></container>
/// ```
pub fn prepend(self: *Node, nodes: []const NodeOrString) !void {
    const owner_doc = self.ownerDocument() orelse return;

    const node = try convertNodesToNode(owner_doc, nodes) orelse return;

    // Insert before first child
    _ = try self.insertBefore(node, self.first_child);
}

/// Insert nodes at the end of this node's children.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined append((Node or DOMString)... nodes);
/// ```
///
/// ## Algorithm (WHATWG §4.2.6)
///
/// 1. Convert nodes into node
/// 2. Append node to this
///
/// ## Spec Reference
///
/// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-append
/// - WebIDL: dom.idl line 125
///
/// ## MDN Documentation
///
/// - ParentNode.append(): https://developer.mozilla.org/en-US/docs/Web/API/Element/append
///
/// ## Parameters
///
/// - `self`: The parent node to append to
/// - `nodes`: Slice of nodes and/or strings to append
///
/// ## Errors
///
/// Returns WHATWG DOM errors from appendChild:
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
/// const child1 = try doc.createElement("item1");
/// const child2 = try doc.createElement("item2");
///
/// try parent.append(&[_]NodeOrString{
///     .{ .node = &child1.prototype },
///     .{ .node = &child2.prototype },
/// });
/// // Result: <container><item1/><item2/></container>
/// ```
pub fn append(self: *Node, nodes: []const NodeOrString) !void {
    const owner_doc = self.ownerDocument() orelse return;

    const node = try convertNodesToNode(owner_doc, nodes) orelse return;

    // Append to end
    _ = try self.appendChild(node);
}

/// Replace all children of this node with nodes.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, Unscopable] undefined replaceChildren((Node or DOMString)... nodes);
/// ```
///
/// ## Algorithm (WHATWG §4.2.6)
///
/// 1. Convert nodes into node
/// 2. Replace all with node within this
///
/// ## Spec Reference
///
/// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-replacechildren
/// - WebIDL: dom.idl line 126
///
/// ## MDN Documentation
///
/// - ParentNode.replaceChildren(): https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceChildren
///
/// ## Parameters
///
/// - `self`: The parent node whose children to replace
/// - `nodes`: Slice of nodes and/or strings to use as new children
///
/// ## Errors
///
/// Returns WHATWG DOM errors from removeChild/appendChild:
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
/// const oldChild = try doc.createElement("old");
/// _ = try parent.prototype.appendChild(&oldChild.prototype);
///
/// const newChild = try doc.createElement("new");
/// try parent.replaceChildren(&[_]NodeOrString{.{ .node = &newChild.prototype }});
/// // Result: <container><new/></container> (old is detached)
/// ```
pub fn replaceChildren(self: *Node, nodes: []const NodeOrString) !void {
    // Remove all existing children
    while (self.first_child) |child| {
        _ = try self.removeChild(child);
    }

    // Append new nodes (if any)
    if (nodes.len > 0) {
        try append(self, nodes);
    }
}

/// Moves node before child in this node's children.
///
/// Implements WHATWG DOM ParentNode.moveBefore() per §4.2.6.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] undefined moveBefore(Node node, Node? child);
/// ```
///
/// ## Algorithm (WHATWG DOM §4.2.6)
/// Moves node to a new position among this node's children:
/// 1. If node is not a child of this, throw NotFoundError
/// 2. If child is not null and not a child of this, throw NotFoundError
/// 3. If node == child, return (no-op)
/// 4. Remove node from its current position
/// 5. Insert node before child (or append if child is null)
///
/// ## Parameters
/// - `node`: Child node to move (must be a direct child of this)
/// - `child`: Reference child to move before (null = move to end)
///
/// ## Errors
/// - `error.NotFoundError`: Node or child is not a child of this node
/// - `error.OutOfMemory`: Failed to allocate during operation
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-movebefore
/// - WebIDL: dom.idl (ParentNode mixin)
///
/// ## Example
/// ```zig
/// const doc = try Document.init(allocator);
/// defer doc.release();
///
/// const parent = try doc.createElement("list");
/// const child1 = try doc.createElement("first");
/// const child2 = try doc.createElement("second");
/// const child3 = try doc.createElement("third");
///
/// _ = try parent.prototype.appendChild(&child1.prototype);
/// _ = try parent.prototype.appendChild(&child2.prototype);
/// _ = try parent.prototype.appendChild(&child3.prototype);
///
/// // Move child3 before child1
/// try parent.moveBefore(&child3.prototype, &child1.prototype);
/// // Order: third, first, second
///
/// // Move child2 to end (child = null)
/// try parent.moveBefore(&child2.prototype, null);
/// // Order: third, first, second
/// ```
pub fn moveBefore(self: *Node, node: *Node, child: ?*Node) !void {
    // Step 1: Verify node is a child of this
    if (node.parent_node != self) {
        return error.NotFoundError;
    }

    // Step 2: Verify child is null or a child of this
    if (child) |ref_child| {
        if (ref_child.parent_node != self) {
            return error.NotFoundError;
        }

        // Step 3: If node == child, return (no-op)
        if (node == ref_child) {
            return;
        }
    }

    // Step 4: Remove node from current position
    // We don't use removeChild because we're just moving within same parent
    // Update sibling pointers
    if (node.previous_sibling) |prev| {
        prev.next_sibling = node.next_sibling;
    } else {
        // node was first child
        self.first_child = node.next_sibling;
    }

    if (node.next_sibling) |next| {
        next.previous_sibling = node.previous_sibling;
    } else {
        // node was last child
        self.last_child = node.previous_sibling;
    }

    // Step 5: Insert node before child (or append if child is null)
    if (child) |ref_child| {
        // Insert before ref_child
        node.next_sibling = ref_child;
        node.previous_sibling = ref_child.previous_sibling;

        if (ref_child.previous_sibling) |prev| {
            prev.next_sibling = node;
        } else {
            // Inserting at beginning
            self.first_child = node;
        }

        ref_child.previous_sibling = node;
    } else {
        // Append to end (child is null)
        node.previous_sibling = self.last_child;
        node.next_sibling = null;

        if (self.last_child) |last| {
            last.next_sibling = node;
        } else {
            // Was empty, now first child
            self.first_child = node;
        }

        self.last_child = node;
    }

    // node.parent_node remains unchanged (same parent)
    // No need to update has_parent flag
    // No need to change connected state
    // No need to update document maps (same parent, same document)

    self.generation += 1;

    // Queue mutation record for childList (optional, for MutationObserver)
    const node_mod = @import("node.zig");
    var removed_array = [_]*Node{node};
    var added_array = [_]*Node{node};

    // Get the previous sibling before the move (for mutation record)
    const prev_sibling = if (child) |ref_child| ref_child.previous_sibling else self.last_child;
    const next_sibling = child;

    node_mod.queueMutationRecord(
        self,
        "childList",
        &added_array, // added_nodes (re-added at new position)
        &removed_array, // removed_nodes (removed from old position)
        prev_sibling, // previousSibling
        next_sibling, // nextSibling
        null, // attribute_name
        null, // attribute_namespace
        null, // old_value
    ) catch {}; // Best effort
}
