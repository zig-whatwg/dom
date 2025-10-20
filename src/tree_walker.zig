//! TreeWalker Interface (WHATWG DOM)
//!
//! This module implements the TreeWalker interface as specified by the WHATWG DOM Standard.
//! TreeWalker provides flexible navigation through a filtered view of the DOM tree with methods
//! for moving to parent, children, and siblings.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **TreeWalker**: https://dom.spec.whatwg.org/#interface-treewalker
//! - **Traversal Algorithms**: https://dom.spec.whatwg.org/#concept-tree-walker-traverse
//!
//! ## MDN Documentation
//!
//! - TreeWalker: https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker
//! - TreeWalker methods: https://developer.mozilla.org/en-US/docs/Web/API/TreeWalker#instance_methods
//!
//! ## Core Features
//!
//! ### Navigating the Tree
//! ```zig
//! const walker = try doc.createTreeWalker(
//!     root,
//!     NodeFilter.SHOW_ELEMENT,
//!     null // No custom filter
//! );
//! defer walker.deinit();
//!
//! // Navigate to first child
//! if (walker.firstChild()) |child| {
//!     std.debug.print("First child: {s}\n", .{child.nodeName()});
//! }
//!
//! // Navigate to next sibling
//! if (walker.nextSibling()) |sibling| {
//!     std.debug.print("Next sibling: {s}\n", .{sibling.nodeName()});
//! }
//!
//! // Navigate to parent
//! if (walker.parentNode()) |parent| {
//!     std.debug.print("Parent: {s}\n", .{parent.nodeName()});
//! }
//! ```
//!
//! ## JavaScript Bindings
//!
//! TreeWalker provides flexible DOM tree navigation with filtering support.
//!
//! ### Creation
//! TreeWalker is typically created via `Document.createTreeWalker()`:
//! ```javascript
//! // Per WebIDL: TreeWalker createTreeWalker(Node root, optional unsigned long whatToShow = 0xFFFFFFFF, optional NodeFilter? filter = null);
//! const walker = document.createTreeWalker(
//!   rootNode,
//!   NodeFilter.SHOW_ELEMENT,  // Optional: defaults to 0xFFFFFFFF (all nodes)
//!   null                       // Optional: custom filter function
//! );
//! ```
//!
//! ### Instance Properties
//! ```javascript
//! // Per WebIDL: [SameObject] readonly attribute Node root;
//! Object.defineProperty(TreeWalker.prototype, 'root', {
//!   get: function() { return wrapNode(zig.treewalker_get_root(this._ptr)); }
//! });
//!
//! // Per WebIDL: readonly attribute unsigned long whatToShow;
//! Object.defineProperty(TreeWalker.prototype, 'whatToShow', {
//!   get: function() { return zig.treewalker_get_whatToShow(this._ptr); }
//! });
//!
//! // Per WebIDL: readonly attribute NodeFilter? filter;
//! Object.defineProperty(TreeWalker.prototype, 'filter', {
//!   get: function() {
//!     const ptr = zig.treewalker_get_filter(this._ptr);
//!     return ptr ? wrapNodeFilter(ptr) : null;
//!   }
//! });
//!
//! // Per WebIDL: attribute Node currentNode;
//! // NOTE: currentNode is WRITABLE (unlike NodeIterator's referenceNode which is readonly)
//! Object.defineProperty(TreeWalker.prototype, 'currentNode', {
//!   get: function() { return wrapNode(zig.treewalker_get_currentNode(this._ptr)); },
//!   set: function(node) { zig.treewalker_set_currentNode(this._ptr, node._ptr); }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // Per WebIDL: Node? parentNode();
//! TreeWalker.prototype.parentNode = function() {
//!   const nodePtr = zig.treewalker_parentNode(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//!
//! // Per WebIDL: Node? firstChild();
//! TreeWalker.prototype.firstChild = function() {
//!   const nodePtr = zig.treewalker_firstChild(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//!
//! // Per WebIDL: Node? lastChild();
//! TreeWalker.prototype.lastChild = function() {
//!   const nodePtr = zig.treewalker_lastChild(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//!
//! // Per WebIDL: Node? previousSibling();
//! TreeWalker.prototype.previousSibling = function() {
//!   const nodePtr = zig.treewalker_previousSibling(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//!
//! // Per WebIDL: Node? nextSibling();
//! TreeWalker.prototype.nextSibling = function() {
//!   const nodePtr = zig.treewalker_nextSibling(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//!
//! // Per WebIDL: Node? previousNode();
//! TreeWalker.prototype.previousNode = function() {
//!   const nodePtr = zig.treewalker_previousNode(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//!
//! // Per WebIDL: Node? nextNode();
//! TreeWalker.prototype.nextNode = function() {
//!   const nodePtr = zig.treewalker_nextNode(this._ptr);
//!   return nodePtr ? wrapNode(nodePtr) : null;
//! };
//! ```
//!
//! ### Usage Examples
//! ```javascript
//! // Create walker for all element nodes
//! const root = document.createElement('container');
//! const level1 = document.createElement('level1');
//! const level2 = document.createElement('level2');
//! level1.appendChild(level2);
//! root.appendChild(level1);
//!
//! const walker = document.createTreeWalker(
//!   root,
//!   NodeFilter.SHOW_ELEMENT
//! );
//!
//! // Navigate to first child
//! const child = walker.firstChild();
//! console.log('First child:', child.nodeName); // 'LEVEL1'
//!
//! // Navigate to first child of current node
//! const grandchild = walker.firstChild();
//! console.log('Grandchild:', grandchild.nodeName); // 'LEVEL2'
//!
//! // Navigate back to parent
//! const parent = walker.parentNode();
//! console.log('Parent:', parent.nodeName); // 'LEVEL1'
//!
//! // Navigate to next sibling (if exists)
//! const sibling = walker.nextSibling();
//! console.log('Sibling:', sibling); // null (no siblings)
//!
//! // Set current node manually (IMPORTANT: TreeWalker allows this!)
//! walker.currentNode = root;
//! console.log('Reset to:', walker.currentNode.nodeName); // 'CONTAINER'
//!
//! // Traverse entire tree in document order
//! walker.currentNode = root;
//! let node;
//! while (node = walker.nextNode()) {
//!   console.log('Found:', node.nodeName);
//! }
//!
//! // Traverse backwards
//! while (node = walker.previousNode()) {
//!   console.log('Found:', node.nodeName);
//! }
//!
//! // Custom filter (only nodes with specific name)
//! const filtered = document.createTreeWalker(
//!   root,
//!   NodeFilter.SHOW_ELEMENT,
//!   {
//!     acceptNode: function(node) {
//!       return node.nodeName === 'LEVEL2' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
//!     }
//!   }
//! );
//!
//! filtered.currentNode = root;
//! while (node = filtered.nextNode()) {
//!   console.log('Filtered:', node.nodeName); // Only 'LEVEL2'
//! }
//!
//! // FILTER_REJECT skips entire subtree (useful for complex filtering)
//! const rejected = document.createTreeWalker(
//!   root,
//!   NodeFilter.SHOW_ELEMENT,
//!   {
//!     acceptNode: function(node) {
//!       if (node.nodeName === 'LEVEL1') {
//!         return NodeFilter.FILTER_REJECT; // Skip LEVEL1 and all its children
//!       }
//!       return NodeFilter.FILTER_ACCEPT;
//!     }
//!   }
//! );
//! ```
//!
//! ### Key Differences from NodeIterator
//! - **currentNode is writable**: You can manually set the current position
//! - **More navigation methods**: parentNode(), firstChild(), lastChild(), previousSibling(), nextSibling()
//! - **No detach() method**: TreeWalker never had this legacy method
//! - **FILTER_REJECT works**: Skips entire subtrees (NodeIterator treats it like FILTER_SKIP)
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeFilter = @import("node_filter.zig").NodeFilter;
const FilterResult = @import("node_filter.zig").FilterResult;

/// TreeWalker - Flexible tree navigation with filtering.
///
/// Implements WHATWG DOM TreeWalker per DOM spec.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=Window]
/// interface TreeWalker {
///   [SameObject] readonly attribute Node root;
///   readonly attribute unsigned long whatToShow;
///   readonly attribute NodeFilter? filter;
///            attribute Node currentNode;
///
///   Node? parentNode();
///   Node? firstChild();
///   Node? lastChild();
///   Node? previousSibling();
///   Node? nextSibling();
///   Node? previousNode();
///   Node? nextNode();
/// };
/// ```
pub const TreeWalker = struct {
    /// Allocator for walker cleanup
    allocator: Allocator,

    /// Root node of traversal (boundary)
    root: *Node,

    /// Current node position
    current_node: *Node,

    /// Bitfield of node types to show
    what_to_show: u32,

    /// Optional custom filter
    node_filter: ?NodeFilter,

    /// Creates a new TreeWalker.
    pub fn init(
        allocator: Allocator,
        root: *Node,
        what_to_show: u32,
        node_filter: ?NodeFilter,
    ) !*TreeWalker {
        const walker = try allocator.create(TreeWalker);
        walker.* = .{
            .allocator = allocator,
            .root = root,
            .current_node = root,
            .what_to_show = what_to_show,
            .node_filter = node_filter,
        };
        return walker;
    }

    /// Frees the walker.
    pub fn deinit(self: *TreeWalker) void {
        self.allocator.destroy(self);
    }

    /// Moves to parent node and returns it, or null if at root or no matching parent.
    pub fn parentNode(self: *TreeWalker) ?*Node {
        var node = self.current_node;
        while (node != self.root) {
            node = node.parent_node orelse return null;
            if (filterNode(self, node) == .accept) {
                self.current_node = node;
                return node;
            }
        }
        return null;
    }

    /// Moves to first child and returns it, or null if no matching children.
    pub fn firstChild(self: *TreeWalker) ?*Node {
        return traverseChildren(self, .first);
    }

    /// Moves to last child and returns it, or null if no matching children.
    pub fn lastChild(self: *TreeWalker) ?*Node {
        return traverseChildren(self, .last);
    }

    /// Moves to previous sibling and returns it, or null if no matching siblings.
    pub fn previousSibling(self: *TreeWalker) ?*Node {
        return traverseSiblings(self, .previous);
    }

    /// Moves to next sibling and returns it, or null if no matching siblings.
    pub fn nextSibling(self: *TreeWalker) ?*Node {
        return traverseSiblings(self, .next);
    }

    /// Moves to previous node in document order and returns it.
    pub fn previousNode(self: *TreeWalker) ?*Node {
        var node = self.current_node;
        while (node != self.root) {
            var sibling = node.previous_sibling;
            while (sibling) |sib| {
                node = sib;
                const result = filterNode(self, node);
                if (result == .reject) {
                    sibling = node.previous_sibling;
                    continue;
                }
                // Go to last child
                while (node.last_child) |child| {
                    node = child;
                    if (filterNode(self, node) == .reject) {
                        break;
                    }
                }
                if (filterNode(self, node) == .accept) {
                    self.current_node = node;
                    return node;
                }
                sibling = node.previous_sibling;
            }
            // No more siblings, go to parent
            if (node == self.root) return null;
            node = node.parent_node orelse return null;
            if (filterNode(self, node) == .accept) {
                self.current_node = node;
                return node;
            }
        }
        return null;
    }

    /// Moves to next node in document order and returns it.
    pub fn nextNode(self: *TreeWalker) ?*Node {
        var node = self.current_node;
        var result = FilterResult.accept;

        while (true) {
            // If not rejected, try children
            if (result != .reject) {
                var child = node.first_child;
                while (child) |ch| {
                    node = ch;
                    result = filterNode(self, node);
                    if (result == .accept) {
                        self.current_node = node;
                        return node;
                    }
                    if (result == .reject) {
                        child = node.next_sibling;
                    } else {
                        child = node.first_child;
                    }
                }
            }

            // No children, try next sibling
            if (node == self.root) return null;

            var sibling = node.next_sibling;
            while (sibling == null) {
                node = node.parent_node orelse return null;
                if (node == self.root) return null;
                sibling = node.next_sibling;
            }

            node = sibling.?;
            result = filterNode(self, node);
            if (result == .accept) {
                self.current_node = node;
                return node;
            }
        }
    }

    // Helper functions

    fn filterNode(self: *const TreeWalker, node: *Node) FilterResult {
        if (!NodeFilter.isNodeVisible(node, self.what_to_show)) {
            return .skip;
        }
        if (self.node_filter) |filter| {
            return filter.acceptNode(node);
        }
        return .accept;
    }

    const ChildDirection = enum { first, last };
    fn traverseChildren(self: *TreeWalker, direction: ChildDirection) ?*Node {
        var node = switch (direction) {
            .first => self.current_node.first_child,
            .last => self.current_node.last_child,
        } orelse return null;

        while (true) {
            const result = filterNode(self, node);
            if (result == .accept) {
                self.current_node = node;
                return node;
            }

            if (result == .skip) {
                const child = switch (direction) {
                    .first => node.first_child,
                    .last => node.last_child,
                };
                if (child) |ch| {
                    node = ch;
                    continue;
                }
            }

            // Move to next/previous sibling
            const sibling = switch (direction) {
                .first => node.next_sibling,
                .last => node.previous_sibling,
            };
            node = sibling orelse return null;
        }
    }

    const SiblingDirection = enum { previous, next };
    fn traverseSiblings(self: *TreeWalker, direction: SiblingDirection) ?*Node {
        var node = switch (direction) {
            .previous => self.current_node.previous_sibling,
            .next => self.current_node.next_sibling,
        } orelse return null;

        while (true) {
            const result = filterNode(self, node);
            if (result == .accept) {
                self.current_node = node;
                return node;
            }

            // If rejected, skip entire subtree
            if (result == .reject) {
                const sibling = switch (direction) {
                    .previous => node.previous_sibling,
                    .next => node.next_sibling,
                };
                node = sibling orelse return null;
                continue;
            }

            // If skipped, check children
            const child = switch (direction) {
                .previous => node.last_child,
                .next => node.first_child,
            };
            if (child) |ch| {
                node = ch;
                continue;
            }

            // No children, move to sibling
            const sibling = switch (direction) {
                .previous => node.previous_sibling,
                .next => node.next_sibling,
            };
            node = sibling orelse return null;
        }
    }
};
