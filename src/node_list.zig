//! NodeList Interface (§5.1)
//!
//! This module implements the NodeList interface as specified by the WHATWG DOM Standard.
//! NodeList is a live collection that provides indexed access to a list of nodes. The most
//! common use is Node.childNodes, which returns a live NodeList of a node's children.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§5.1 Interface NodeList**: https://dom.spec.whatwg.org/#interface-nodelist
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node (childNodes)
//! - **§5 Collections**: https://dom.spec.whatwg.org/#collections
//!
//! ## MDN Documentation
//!
//! - NodeList: https://developer.mozilla.org/en-US/docs/Web/API/NodeList
//! - NodeList.length: https://developer.mozilla.org/en-US/docs/Web/API/NodeList/length
//! - NodeList.item(): https://developer.mozilla.org/en-US/docs/Web/API/NodeList/item
//! - Node.childNodes: https://developer.mozilla.org/en-US/docs/Web/API/Node/childNodes
//! - Live vs Static NodeList: https://developer.mozilla.org/en-US/docs/Web/API/NodeList#live_vs._static_nodelists
//!
//! ## Core Features
//!
//! ### Live Collection
//! NodeList is a "live" collection - it automatically reflects DOM changes:
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! defer parent.node.release();
//!
//! const children = parent.node.childNodes();
//! try std.testing.expectEqual(@as(usize, 0), children.length());
//!
//! // Add child - list updates automatically
//! const child = try Element.create(allocator, "span");
//! _ = try parent.node.appendChild(&child.node);
//! try std.testing.expectEqual(@as(usize, 1), children.length()); // Now 1!
//! ```
//!
//! ### Indexed Access
//! Access nodes by index using item() or array-like notation:
//! ```zig
//! const parent = try Element.create(allocator, "ul");
//! defer parent.node.release();
//!
//! // Add children
//! for (0..3) |_| {
//!     const li = try Element.create(allocator, "li");
//!     _ = try parent.node.appendChild(&li.node);
//! }
//!
//! const children = parent.node.childNodes();
//! const first = children.item(0); // First child
//! const second = children.item(1); // Second child
//! const none = children.item(99); // null (out of bounds)
//! ```
//!
//! ### Iteration
//! Iterate over all nodes in the list:
//! ```zig
//! const children = parent.node.childNodes();
//! for (0..children.length()) |i| {
//!     if (children.item(i)) |node| {
//!         // Process node
//!         std.debug.print("Node type: {}\n", .{node.node_type});
//!     }
//! }
//! ```
//!
//! ## NodeList Structure
//!
//! NodeList is a lightweight view - it doesn't store nodes, just references the parent:
//! - **parent**: Pointer to parent node whose children are viewed
//!
//! Size: 8 bytes (just one pointer)
//!
//! **Key Properties:**
//! - **Live**: Reflects DOM changes automatically
//! - **Non-owning**: Doesn't own nodes, just provides access
//! - **O(n) operations**: length() and item() traverse linked list
//! - **No storage**: Doesn't allocate memory for node list
//! - **Zero-copy**: Just a view into existing tree structure
//!
//! ## Memory Management
//!
//! NodeList is a stack-allocated value type (not heap-allocated):
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! defer parent.node.release();
//!
//! const children = parent.node.childNodes();
//! // No defer needed - NodeList is a plain struct value
//!
//! // NodeList doesn't own nodes - parent owns them
//! ```
//!
//! **Important:**
//! - NodeList does NOT own the nodes it references
//! - Nodes are owned by their parent via tree structure
//! - Parent.release() frees all children automatically
//! - NodeList is just a view (like a slice, but live)
//!
//! ## Usage Examples
//!
//! ### Traversing Children
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! const container = try Element.create(allocator, "div");
//! defer container.node.release();
//!
//! // Add some children
//! for (0..5) |i| {
//!     const child = try Element.create(allocator, "span");
//!     _ = try container.node.appendChild(&child.node);
//! }
//!
//! // Iterate via NodeList
//! const children = container.node.childNodes();
//! for (0..children.length()) |i| {
//!     const child = children.item(i).?;
//!     std.debug.print("Child {}: {s}\n", .{i, child.nodeName()});
//! }
//! ```
//!
//! ### Live Collection Behavior
//! ```zig
//! const parent = try Element.create(allocator, "ul");
//! defer parent.node.release();
//!
//! const list = parent.node.childNodes();
//!
//! // Initially empty
//! try std.testing.expectEqual(@as(usize, 0), list.length());
//!
//! // Add child - list updates
//! const li1 = try Element.create(allocator, "li");
//! _ = try parent.node.appendChild(&li1.node);
//! try std.testing.expectEqual(@as(usize, 1), list.length());
//!
//! // Add another - list updates again
//! const li2 = try Element.create(allocator, "li");
//! _ = try parent.node.appendChild(&li2.node);
//! try std.testing.expectEqual(@as(usize, 2), list.length());
//!
//! // Remove child - list updates
//! _ = try parent.node.removeChild(&li1.node);
//! try std.testing.expectEqual(@as(usize, 1), list.length());
//! ```
//!
//! ### Safe Iteration During Modification
//! ```zig
//! fn removeAllChildren(parent: *Node) !void {
//!     const children = parent.childNodes();
//!
//!     // WRONG: Don't modify while iterating by index
//!     // for (0..children.length()) |i| {
//!     //     _ = try parent.removeChild(children.item(i).?); // Breaks!
//!     // }
//!
//!     // RIGHT: Remove first child repeatedly
//!     while (children.length() > 0) {
//!         const first = children.item(0).?;
//!         _ = try parent.removeChild(first);
//!     }
//! }
//! ```
//!
//! ## Common Patterns
//!
//! ### Converting to Array
//! ```zig
//! fn nodeListToArray(list: NodeList, allocator: Allocator) ![]const *Node {
//!     const len = list.length();
//!     const array = try allocator.alloc(*Node, len);
//!     errdefer allocator.free(array);
//!
//!     for (0..len) |i| {
//!         array[i] = list.item(i).?;
//!     }
//!
//!     return array;
//! }
//! ```
//!
//! ### Filtering Nodes
//! ```zig
//! fn filterByType(list: NodeList, node_type: NodeType, allocator: Allocator) !std.ArrayList(*Node) {
//!     var results = std.ArrayList(*Node).init(allocator);
//!     errdefer results.deinit();
//!
//!     for (0..list.length()) |i| {
//!         const node = list.item(i).?;
//!         if (node.node_type == node_type) {
//!             try results.append(node);
//!         }
//!     }
//!
//!     return results;
//! }
//! ```
//!
//! ### Reverse Iteration
//! ```zig
//! fn processReverse(list: NodeList) void {
//!     const len = list.length();
//!     var i = len;
//!     while (i > 0) {
//!         i -= 1;
//!         const node = list.item(i).?;
//!         // Process node
//!     }
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Cache Length** - length() is O(n), cache in loop: `const len = list.length()`
//! 2. **Forward Iteration** - Use for loop with cached length, not while
//! 3. **Avoid Repeated Access** - item() is O(n), store reference if used multiple times
//! 4. **Direct Traversal** - For single pass, use parent.first_child linked list directly
//! 5. **Snapshot if Modifying** - Convert to array before modifying DOM during iteration
//! 6. **Remove from End** - When removing nodes, iterate backwards to avoid index issues
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // length (readonly)
//! Object.defineProperty(NodeList.prototype, 'length', {
//!   get: function() { return zig.nodelist_get_length(this._ptr); }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // item(index) - Get node at index
//! NodeList.prototype.item = function(index) {
//!   return zig.nodelist_item(this._ptr, index);
//! };
//!
//! // Array-like indexed access (bracket notation)
//! // Implemented via Proxy or property descriptors:
//! NodeList.prototype[0] = { get: function() { return this.item(0); } };
//! // (In practice, bindings use Proxy for dynamic indexed access)
//! ```
//!
//! ### Iteration Support
//! ```javascript
//! // forEach() - Modern iteration (not part of WebIDL, but common)
//! NodeList.prototype.forEach = function(callback, thisArg) {
//!   for (let i = 0; i < this.length; i++) {
//!     callback.call(thisArg, this[i], i, this);
//!   }
//! };
//!
//! // for...of support (make iterable)
//! NodeList.prototype[Symbol.iterator] = function*() {
//!   for (let i = 0; i < this.length; i++) {
//!     yield this[i];
//!   }
//! };
//! ```
//!
//! ### Usage Examples
//! ```javascript
//! const children = element.childNodes;
//!
//! // Indexed access
//! const first = children[0];
//! const second = children.item(1);
//!
//! // Length property
//! console.log('Total children:', children.length);
//!
//! // Iteration
//! for (let i = 0; i < children.length; i++) {
//!   console.log('Child:', children[i]);
//! }
//!
//! // Modern iteration (if forEach/Symbol.iterator supported)
//! children.forEach(child => console.log(child));
//! for (const child of children) {
//!   console.log(child);
//! }
//! ```
//!
//! **Important:** NodeList is a **live collection** - it automatically reflects DOM changes.
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - NodeList is a plain struct (8 bytes, just parent pointer)
//! - No heap allocation (stack-allocated value type)
//! - length() traverses linked list each time (O(n))
//! - item() traverses from first_child (O(n) per call)
//! - Live collection - automatically reflects DOM mutations
//! - Non-owning - nodes owned by tree structure, not by NodeList
//! - Could be optimized with cached length in Node (space/time tradeoff)
//! - Direct linked list traversal (parent.first_child) faster than NodeList for single pass

const std = @import("std");
const Node = @import("node.zig").Node;

/// NodeList - live collection of nodes.
///
/// This is a "live" collection that automatically reflects changes to the DOM tree.
/// For childNodes, the list is backed by the node's linked list of children.
///
/// ## Memory Management
/// NodeList does NOT own the nodes - it merely provides a view into the tree.
/// Nodes are owned by their parent via the tree structure.
pub const NodeList = struct {
    /// Parent node whose children this list represents
    parent: *Node,

    /// Creates a new NodeList viewing the children of a parent node.
    ///
    /// ## Parameters
    /// - `parent`: Parent node whose children to view
    ///
    /// ## Returns
    /// NodeList viewing parent's children
    pub fn init(parent: *Node) NodeList {
        return .{
            .parent = parent,
        };
    }

    /// Returns the number of nodes in the list.
    ///
    /// Implements WHATWG DOM NodeList.length property.
    /// This traverses the child linked list to count nodes (O(n)).
    ///
    /// ## Returns
    /// Number of nodes in the list
    pub fn length(self: *const NodeList) usize {
        var count: usize = 0;
        var current = self.parent.first_child;
        while (current) |node| {
            count += 1;
            current = node.next_sibling;
        }
        return count;
    }

    /// Returns the node at the specified index.
    ///
    /// Implements WHATWG DOM NodeList.item() method.
    /// This traverses the child linked list (O(n)).
    ///
    /// ## Parameters
    /// - `index`: Zero-based index of node to retrieve
    ///
    /// ## Returns
    /// Node at index or null if index >= length
    ///
    /// ## Example
    /// ```zig
    /// const child = list.item(0); // First child
    /// if (child) |node| {
    ///     std.debug.print("First child: {s}\n", .{node.nodeName()});
    /// }
    /// ```
    pub fn item(self: *const NodeList, index: usize) ?*Node {
        var count: usize = 0;
        var current = self.parent.first_child;
        while (current) |node| {
            if (count == index) {
                return node;
            }
            count += 1;
            current = node.next_sibling;
        }
        return null;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "NodeList - empty list" {
    const allocator = std.testing.allocator;

    // Minimal vtable for testing
    const test_vtable = @import("node.zig").NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const parent = try Node.init(allocator, &test_vtable, .element);
    defer parent.release();

    const list = NodeList.init(parent);

    // Empty list
    try std.testing.expectEqual(@as(usize, 0), list.length());
    try std.testing.expect(list.item(0) == null);
}

test "NodeList - with children" {
    const allocator = std.testing.allocator;

    const test_vtable = @import("node.zig").NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const parent = try Node.init(allocator, &test_vtable, .element);
    defer parent.release();

    // Create three child nodes
    const child1 = try Node.init(allocator, &test_vtable, .element);
    defer child1.release();

    const child2 = try Node.init(allocator, &test_vtable, .element);
    defer child2.release();

    const child3 = try Node.init(allocator, &test_vtable, .element);
    defer child3.release();

    // Manually link children (Phase 2 will do this via appendChild)
    parent.first_child = child1;
    parent.last_child = child3;

    child1.next_sibling = child2;
    child2.next_sibling = child3;
    child3.next_sibling = null;

    child1.parent_node = parent;
    child2.parent_node = parent;
    child3.parent_node = parent;

    // Create NodeList
    const list = NodeList.init(parent);

    // Verify length
    try std.testing.expectEqual(@as(usize, 3), list.length());

    // Verify items
    try std.testing.expectEqual(child1, list.item(0).?);
    try std.testing.expectEqual(child2, list.item(1).?);
    try std.testing.expectEqual(child3, list.item(2).?);

    // Out of bounds
    try std.testing.expect(list.item(3) == null);

    // Clean up manual connections
    parent.first_child = null;
    parent.last_child = null;
    child1.next_sibling = null;
    child2.next_sibling = null;
    child1.parent_node = null;
    child2.parent_node = null;
    child3.parent_node = null;
}

test "NodeList - memory leak test" {
    const allocator = std.testing.allocator;

    const test_vtable = @import("node.zig").NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    // Test 1: Empty list
    {
        const parent = try Node.init(allocator, &test_vtable, .element);
        defer parent.release();

        const list = NodeList.init(parent);
        _ = list.length();
        _ = list.item(0);
    }

    // Test 2: List with children
    {
        const parent = try Node.init(allocator, &test_vtable, .element);
        defer parent.release();

        const child = try Node.init(allocator, &test_vtable, .element);
        defer child.release();

        parent.first_child = child;
        child.parent_node = parent;

        const list = NodeList.init(parent);
        _ = list.length();
        _ = list.item(0);

        // Clean up
        parent.first_child = null;
        child.parent_node = null;
    }

    // If we reach here without leaks, std.testing.allocator validates success
}
