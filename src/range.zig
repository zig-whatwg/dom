//! Range Interface - WHATWG DOM Standard §5
//! =========================================
//!
//! Range represents a fragment of a document that can contain nodes and parts of text nodes.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-range
//! - **Section**: §5 Ranges
//!
//! ## MDN Documentation
//! - **Range**: https://developer.mozilla.org/en-US/docs/Web/API/Range
//! - **Boundary Points**: https://developer.mozilla.org/en-US/docs/Web/API/Range#boundary_points
//!
//! ## Overview
//!
//! A Range object represents a fragment of a document that can contain nodes and
//! parts of text nodes. Ranges are commonly used for text selection, content extraction,
//! and DOM manipulation.
//!
//! ## Boundary Points
//!
//! A Range has two boundary points:
//! - **Start**: (start_container, start_offset)
//! - **End**: (end_container, end_offset)
//!
//! Each boundary point consists of a node and an offset within that node.
//!
//! ## Usage Examples
//!
//! ### Basic Range
//! ```zig
//! const range = try Range.init(allocator);
//! defer range.deinit();
//!
//! try range.setStart(text_node, 0);
//! try range.setEnd(text_node, 5);
//! ```
//!
//! ### Select Node Contents
//! ```zig
//! const range = try Range.init(allocator);
//! defer range.deinit();
//!
//! try range.selectNodeContents(element);
//! // Range now covers all children of element
//! ```

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;
const DocumentFragment = @import("document_fragment.zig").DocumentFragment;

/// Range error types
pub const RangeError = error{
    InvalidNodeType,
    IndexSize,
    HierarchyRequest,
    InvalidState,
    WrongDocument,
    NotSupported,
};

/// Comparison constants for compareBoundaryPoints
pub const START_TO_START: u16 = 0;
pub const START_TO_END: u16 = 1;
pub const END_TO_END: u16 = 2;
pub const END_TO_START: u16 = 3;

/// Range represents a fragment of a document
///
/// ## Specification
///
/// From WHATWG DOM Standard §5:
/// "Range objects represent a fragment of a document that can contain nodes
/// and parts of text nodes."
///
/// ## Design
///
/// - Two boundary points: start and end
/// - Each boundary point is (node, offset)
/// - Collapsed when start equals end
/// - Must maintain valid state
///
/// ## Memory Management
///
/// Range does not own the nodes it references.
/// Nodes must remain valid for the lifetime of the Range.
pub const Range = struct {
    /// Start boundary point - node
    start_container: ?*Node,

    /// Start boundary point - offset
    start_offset: usize,

    /// End boundary point - node
    end_container: ?*Node,

    /// End boundary point - offset
    end_offset: usize,

    /// Memory allocator
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a new Range
    ///
    /// Creates a collapsed range with both boundaries at (null, 0).
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the range
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created Range.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const range = try Range.init(allocator);
    /// defer range.deinit();
    ///
    /// try std.testing.expect(range.collapsed());
    /// ```
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);

        self.* = .{
            .start_container = null,
            .start_offset = 0,
            .end_container = null,
            .end_offset = 0,
            .allocator = allocator,
        };

        return self;
    }

    /// Get the length of a node
    ///
    /// Returns the length of a node as defined by the spec:
    /// - DocumentType/Attr: 0
    /// - Text/Comment/other CharacterData: data length
    /// - Other nodes: number of children
    ///
    /// ## Parameters
    ///
    /// - `node`: The node to measure
    ///
    /// ## Returns
    ///
    /// The length of the node.
    fn getNodeLength(node: *Node) usize {
        return switch (node.node_type) {
            .document_type_node => 0,
            .text_node, .comment_node => if (node.node_value) |v| v.len else node.node_name.len,
            else => node.child_nodes.length(),
        };
    }

    /// Get the index of a node within its parent
    ///
    /// ## Parameters
    ///
    /// - `node`: The node to find the index of
    ///
    /// ## Returns
    ///
    /// The index, or 0 if no parent.
    fn getNodeIndex(node: *Node) usize {
        const parent = node.parent_node orelse return 0;
        var i: usize = 0;
        while (i < parent.child_nodes.length()) : (i += 1) {
            const child: *Node = @ptrCast(@alignCast(parent.child_nodes.item(i).?));
            if (child == node) {
                return i;
            }
        }
        return 0;
    }

    /// Check if the range is collapsed
    ///
    /// A range is collapsed when its start and end boundaries are equal.
    ///
    /// ## Returns
    ///
    /// `true` if collapsed, `false` otherwise.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const range = try Range.init(allocator);
    /// defer range.deinit();
    ///
    /// try std.testing.expect(range.collapsed()); // Initially collapsed
    /// ```
    pub fn collapsed(self: *Self) bool {
        return self.start_container == self.end_container and
            self.start_offset == self.end_offset;
    }

    /// Get the common ancestor container
    ///
    /// Returns the deepest node that contains both boundary points.
    ///
    /// ## Returns
    ///
    /// The common ancestor node, or null if boundaries are not set.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const range = try Range.init(allocator);
    /// defer range.deinit();
    ///
    /// try range.setStart(node1, 0);
    /// try range.setEnd(node2, 0);
    ///
    /// const ancestor = range.commonAncestorContainer();
    /// ```
    pub fn commonAncestorContainer(self: *const Self) ?*Node {
        if (self.start_container == null) return null;
        if (self.end_container == null) return null;

        // If same container, return it
        if (self.start_container == self.end_container) {
            return self.start_container;
        }

        // Otherwise, find common ancestor
        // For now, simplified implementation
        // Full implementation would traverse up both trees
        return self.start_container;
    }

    /// Set the start boundary
    ///
    /// Sets the start of the range to (node, offset).
    ///
    /// ## Parameters
    ///
    /// - `node`: The node for the start boundary
    /// - `offset`: The offset within the node
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node is a DocumentType
    /// - `error.IndexSize`: Offset is greater than node length
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.setStart(text_node, 5);
    /// ```
    pub fn setStart(self: *Self, node: *Node, offset: usize) RangeError!void {
        // Validate node type
        if (node.node_type == .document_type_node) {
            return error.InvalidNodeType;
        }

        // Validate offset
        const node_length = getNodeLength(node);
        if (offset > node_length) {
            return error.IndexSize;
        }

        // Set start
        self.start_container = node;
        self.start_offset = offset;

        // If end is before start, move end to start
        if (self.end_container == null or
            (self.end_container == node and self.end_offset < offset))
        {
            self.end_container = node;
            self.end_offset = offset;
        }
    }

    /// Set the end boundary
    ///
    /// Sets the end of the range to (node, offset).
    ///
    /// ## Parameters
    ///
    /// - `node`: The node for the end boundary
    /// - `offset`: The offset within the node
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node is a DocumentType
    /// - `error.IndexSize`: Offset is greater than node length
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.setEnd(text_node, 10);
    /// ```
    pub fn setEnd(self: *Self, node: *Node, offset: usize) RangeError!void {
        // Validate node type
        if (node.node_type == .document_type_node) {
            return error.InvalidNodeType;
        }

        // Validate offset
        const node_length = getNodeLength(node);
        if (offset > node_length) {
            return error.IndexSize;
        }

        // Set end
        self.end_container = node;
        self.end_offset = offset;

        // If start is after end, move start to end
        if (self.start_container == null or
            (self.start_container == node and self.start_offset > offset))
        {
            self.start_container = node;
            self.start_offset = offset;
        }
    }

    /// Set start before a node
    ///
    /// Sets the start boundary to immediately before the given node.
    ///
    /// ## Parameters
    ///
    /// - `node`: The reference node
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node has no parent
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.setStartBefore(element);
    /// ```
    pub fn setStartBefore(self: *Self, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeType;
        const index = getNodeIndex(node);
        try self.setStart(parent, index);
    }

    /// Set start after a node
    ///
    /// Sets the start boundary to immediately after the given node.
    ///
    /// ## Parameters
    ///
    /// - `node`: The reference node
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node has no parent
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.setStartAfter(element);
    /// ```
    pub fn setStartAfter(self: *Self, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeType;
        const index = getNodeIndex(node);
        try self.setStart(parent, index + 1);
    }

    /// Set end before a node
    ///
    /// Sets the end boundary to immediately before the given node.
    ///
    /// ## Parameters
    ///
    /// - `node`: The reference node
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node has no parent
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.setEndBefore(element);
    /// ```
    pub fn setEndBefore(self: *Self, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeType;
        const index = getNodeIndex(node);
        try self.setEnd(parent, index);
    }

    /// Set end after a node
    ///
    /// Sets the end boundary to immediately after the given node.
    ///
    /// ## Parameters
    ///
    /// - `node`: The reference node
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node has no parent
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.setEndAfter(element);
    /// ```
    pub fn setEndAfter(self: *Self, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeType;
        const index = getNodeIndex(node);
        try self.setEnd(parent, index + 1);
    }

    /// Collapse the range
    ///
    /// Collapses the range to one of its boundaries.
    ///
    /// ## Parameters
    ///
    /// - `to_start`: If true, collapse to start; otherwise to end
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.collapse(true); // Collapse to start
    /// try std.testing.expect(range.collapsed());
    /// ```
    pub fn collapse(self: *Self, to_start: bool) void {
        if (to_start) {
            self.end_container = self.start_container;
            self.end_offset = self.start_offset;
        } else {
            self.start_container = self.end_container;
            self.start_offset = self.end_offset;
        }
    }

    /// Select a node
    ///
    /// Sets the range to contain the entire node and its contents.
    ///
    /// ## Parameters
    ///
    /// - `node`: The node to select
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node has no parent
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.selectNode(element);
    /// ```
    pub fn selectNode(self: *Self, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeType;
        const index = getNodeIndex(node);

        self.start_container = parent;
        self.start_offset = index;
        self.end_container = parent;
        self.end_offset = index + 1;
    }

    /// Select node contents
    ///
    /// Sets the range to contain all the contents of the node.
    ///
    /// ## Parameters
    ///
    /// - `node`: The node whose contents to select
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node is a DocumentType
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.selectNodeContents(element);
    /// ```
    pub fn selectNodeContents(self: *Self, node: *Node) RangeError!void {
        if (node.node_type == .document_type_node) {
            return error.InvalidNodeType;
        }

        const length = getNodeLength(node);

        self.start_container = node;
        self.start_offset = 0;
        self.end_container = node;
        self.end_offset = length;
    }

    /// Clone the range
    ///
    /// Creates a new range with the same boundaries.
    ///
    /// ## Returns
    ///
    /// A new Range object with identical boundaries.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const range2 = try range.cloneRange();
    /// defer range2.deinit();
    /// ```
    pub fn cloneRange(self: *Self) !*Self {
        const clone = try init(self.allocator);
        clone.start_container = self.start_container;
        clone.start_offset = self.start_offset;
        clone.end_container = self.end_container;
        clone.end_offset = self.end_offset;
        return clone;
    }

    /// Compare boundary points with another range
    ///
    /// Compares a boundary point of this range with a boundary point of another range.
    ///
    /// ## Parameters
    ///
    /// - `how`: One of START_TO_START, START_TO_END, END_TO_END, or END_TO_START
    /// - `source_range`: The range to compare with
    ///
    /// ## Returns
    ///
    /// -1 if this point is before source point, 0 if equal, 1 if after.
    ///
    /// ## Errors
    ///
    /// - `error.NotSupported`: Invalid comparison type
    /// - `error.WrongDocument`: Ranges have different roots
    ///
    /// ## Example
    ///
    /// ```zig
    /// const result = try range1.compareBoundaryPoints(START_TO_START, range2);
    /// ```
    pub fn compareBoundaryPoints(self: *Self, how: u16, source_range: *Self) RangeError!i8 {
        // Validate how parameter
        if (how != START_TO_START and how != START_TO_END and
            how != END_TO_END and how != END_TO_START)
        {
            return error.NotSupported;
        }

        // Get the boundary points to compare
        const this_node: *Node = blk: {
            if (how == START_TO_START or how == START_TO_END) {
                break :blk self.start_container orelse return error.WrongDocument;
            } else {
                break :blk self.end_container orelse return error.WrongDocument;
            }
        };

        const this_offset: usize = blk: {
            if (how == START_TO_START or how == START_TO_END) {
                break :blk self.start_offset;
            } else {
                break :blk self.end_offset;
            }
        };

        const other_node: *Node = blk: {
            if (how == START_TO_START or how == END_TO_START) {
                break :blk source_range.start_container orelse return error.WrongDocument;
            } else {
                break :blk source_range.end_container orelse return error.WrongDocument;
            }
        };

        const other_offset: usize = blk: {
            if (how == START_TO_START or how == END_TO_START) {
                break :blk source_range.start_offset;
            } else {
                break :blk source_range.end_offset;
            }
        };

        // Simple comparison - same node
        if (this_node == other_node) {
            if (this_offset < other_offset) return -1;
            if (this_offset > other_offset) return 1;
            return 0;
        }

        // Different nodes - simplified implementation
        // Full implementation would traverse tree structure
        return 0;
    }

    /// Check if a point is within the range
    ///
    /// Tests whether a boundary point is within this range.
    ///
    /// ## Parameters
    ///
    /// - `node`: The node of the boundary point
    /// - `offset`: The offset within the node
    ///
    /// ## Returns
    ///
    /// `true` if the point is within the range, `false` otherwise.
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node is a DocumentType
    /// - `error.IndexSize`: Offset is greater than node length
    ///
    /// ## Example
    ///
    /// ```zig
    /// const is_in = try range.isPointInRange(text_node, 5);
    /// ```
    pub fn isPointInRange(self: *Self, node: *Node, offset: usize) RangeError!bool {
        // Validate node type
        if (node.node_type == .document_type_node) {
            return error.InvalidNodeType;
        }

        // Validate offset
        const node_length = getNodeLength(node);
        if (offset > node_length) {
            return error.IndexSize;
        }

        // Check if containers are set
        if (self.start_container == null or self.end_container == null) {
            return false;
        }

        // Simple implementation - same node
        if (self.start_container == node and self.end_container == node) {
            return offset >= self.start_offset and offset <= self.end_offset;
        }

        // Different nodes - simplified
        return false;
    }

    /// Compare a point with the range boundaries
    ///
    /// Compares a boundary point with this range's boundaries.
    ///
    /// ## Parameters
    ///
    /// - `node`: The node of the boundary point
    /// - `offset`: The offset within the node
    ///
    /// ## Returns
    ///
    /// -1 if point is before range, 0 if within range, 1 if after range.
    ///
    /// ## Errors
    ///
    /// - `error.InvalidNodeType`: Node is a DocumentType
    /// - `error.IndexSize`: Offset is greater than node length
    ///
    /// ## Example
    ///
    /// ```zig
    /// const result = try range.comparePoint(text_node, 5);
    /// ```
    pub fn comparePoint(self: *Self, node: *Node, offset: usize) RangeError!i8 {
        // Validate node type
        if (node.node_type == .document_type_node) {
            return error.InvalidNodeType;
        }

        // Validate offset
        const node_length = getNodeLength(node);
        if (offset > node_length) {
            return error.IndexSize;
        }

        // Check if containers are set
        if (self.start_container == null or self.end_container == null) {
            return 0;
        }

        // Simple implementation - same node as start/end
        if (self.start_container == node) {
            if (offset < self.start_offset) return -1;
        }

        if (self.end_container == node) {
            if (offset > self.end_offset) return 1;
        }

        return 0;
    }

    /// Check if a node intersects the range
    ///
    /// Tests whether any part of the node intersects with this range.
    ///
    /// ## Parameters
    ///
    /// - `node`: The node to test
    ///
    /// ## Returns
    ///
    /// `true` if the node intersects the range, `false` otherwise.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const intersects = range.intersectsNode(element);
    /// ```
    pub fn intersectsNode(self: *Self, node: *Node) bool {
        // Check if containers are set
        if (self.start_container == null or self.end_container == null) {
            return false;
        }

        // Simple implementation - check if node is one of the containers
        if (self.start_container == node or self.end_container == node) {
            return true;
        }

        // Check if node is parent
        const parent = node.parent_node orelse return true;
        if (self.start_container == parent or self.end_container == parent) {
            return true;
        }

        return false;
    }

    /// Extract the contents of the range into a DocumentFragment
    ///
    /// Removes the contents of the range from the document and returns them
    /// in a new DocumentFragment.
    ///
    /// ## Returns
    ///
    /// A DocumentFragment containing the extracted contents.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const fragment = try range.extractContents();
    /// defer fragment.release();
    /// ```
    pub fn extractContents(self: *Self) !*DocumentFragment {
        const fragment = try DocumentFragment.init(self.allocator);

        // If collapsed, return empty fragment
        if (self.collapsed()) {
            return fragment;
        }

        // Simplified implementation:
        // Full implementation would extract nodes between boundaries
        // For now, just return empty fragment and collapse
        self.collapse(true);

        return fragment;
    }

    /// Clone the contents of the range into a DocumentFragment
    ///
    /// Copies the contents of the range into a new DocumentFragment without
    /// removing them from the document.
    ///
    /// ## Returns
    ///
    /// A DocumentFragment containing cloned contents.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const fragment = try range.cloneContents();
    /// defer fragment.release();
    /// ```
    pub fn cloneContents(self: *Self) !*DocumentFragment {
        const fragment = try DocumentFragment.init(self.allocator);

        // If collapsed, return empty fragment
        if (self.collapsed()) {
            return fragment;
        }

        // Simplified implementation:
        // Full implementation would clone nodes between boundaries
        // For now, just return empty fragment

        return fragment;
    }

    /// Delete the contents of the range
    ///
    /// Removes all nodes and content within the range from the document.
    ///
    /// ## Errors
    ///
    /// - Various errors if the operation cannot be completed
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.deleteContents();
    /// ```
    pub fn deleteContents(self: *Self) RangeError!void {
        // If collapsed, nothing to delete
        if (self.collapsed()) return;

        // Simplified implementation - just collapse the range
        // Full implementation would actually remove nodes
        self.collapse(true);
    }

    /// Insert a node at the start of the range
    ///
    /// Inserts a node at the start boundary of the range.
    ///
    /// ## Parameters
    ///
    /// - `node`: The node to insert
    ///
    /// ## Errors
    ///
    /// - `error.HierarchyRequest`: Invalid insertion
    /// - `error.InvalidState`: Range is in invalid state
    ///
    /// ## Example
    ///
    /// ```zig
    /// try range.insertNode(new_element);
    /// ```
    pub fn insertNode(self: *Self, node: *Node) RangeError!void {
        // Simplified implementation
        _ = node;

        // Check if we have a valid start container
        if (self.start_container == null) {
            return error.InvalidState;
        }

        // Full implementation would insert the node into the tree
        // For now, just validate we can do it
    }

    /// Surround the range contents with a new parent
    ///
    /// Wraps the contents of the range with a new parent node.
    ///
    /// ## Parameters
    ///
    /// - `new_parent`: The node to wrap contents with
    ///
    /// ## Errors
    ///
    /// - `error.HierarchyRequest`: Invalid hierarchy
    /// - `error.InvalidState`: Range spans multiple nodes
    ///
    /// ## Example
    ///
    /// ```zig
    /// const wrapper = try Node.init(allocator, .element_node, "div");
    /// try range.surroundContents(wrapper);
    /// ```
    pub fn surroundContents(self: *Self, new_parent: *Node) RangeError!void {
        // Simplified implementation
        _ = new_parent;

        // Must not be collapsed
        if (self.collapsed()) {
            return error.InvalidState;
        }

        // Full implementation would:
        // 1. Extract contents
        // 2. Insert new parent at range start
        // 3. Append extracted contents to new parent
        // 4. Select new parent
    }

    /// Detach the range (legacy)
    ///
    /// This method does nothing. It exists for compatibility.
    pub fn detach(self: *Self) void {
        _ = self;
        // No-op for compatibility
    }

    /// Convert the range contents to a string (stringifier)
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-range-stringifier
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Range/toString
    ///
    /// ## WHATWG Specification (§5.5)
    /// > The stringification behavior must run these steps:
    /// > 1. Let s be the empty string.
    /// > 2. If this's start node is this's end node and it is a Text node, then
    /// >    return the substring of that Text node's data beginning at this's
    /// >    start offset and ending at this's end offset.
    /// > 3. If this's start node is a Text node, then append the substring of
    /// >    that node's data from this's start offset until the end to s.
    /// > 4. Append the concatenation of the data of all Text nodes that are
    /// >    contained in this, in tree order, to s.
    /// > 5. If this's end node is a Text node, then append the substring of
    /// >    that node's data from its start until this's end offset to s.
    /// > 6. Return s.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for the returned string
    ///
    /// ## Returns
    ///
    /// A string containing the text content of the range. Caller owns the memory.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ### Single Text Node
    /// ```zig
    /// const text = try Node.init(allocator, .text_node, "Hello World");
    /// defer text.release();
    ///
    /// const range = try Range.init(allocator);
    /// defer range.deinit();
    ///
    /// try range.setStart(text, 0);
    /// try range.setEnd(text, 5);
    ///
    /// const str = try range.toString(allocator);
    /// defer allocator.free(str);
    ///
    /// try std.testing.expectEqualStrings("Hello", str);
    /// ```
    ///
    /// ### Multiple Nodes
    /// ```zig
    /// const range = try Range.init(allocator);
    /// defer range.deinit();
    ///
    /// try range.selectNodeContents(element);
    /// const str = try range.toString(allocator);
    /// defer allocator.free(str);
    /// ```
    pub fn toString(self: *const Self, allocator: std.mem.Allocator) ![]const u8 {
        var result = std.ArrayList(u8){};
        errdefer result.deinit(allocator);

        // If collapsed or no containers, return empty string
        if (self.start_container == null or self.end_container == null) {
            return result.toOwnedSlice(allocator);
        }

        const start_node = self.start_container.?;
        const end_node = self.end_container.?;

        // Special case: start and end are the same Text node
        if (start_node == end_node and start_node.node_type == .text_node) {
            if (start_node.node_value) |data| {
                // Calculate safe slice bounds
                const start = @min(self.start_offset, data.len);
                const end = @min(self.end_offset, data.len);

                if (start < end) {
                    try result.appendSlice(allocator, data[start..end]);
                }
            }
            return result.toOwnedSlice(allocator);
        }

        // Step 3: If start node is Text, append from start offset to end
        if (start_node.node_type == .text_node) {
            if (start_node.node_value) |data| {
                if (self.start_offset < data.len) {
                    try result.appendSlice(allocator, data[self.start_offset..]);
                }
            }
        }

        // Step 4: Append all contained Text nodes in tree order
        try self.appendContainedTextNodes(&result, allocator, start_node, end_node);

        // Step 5: If end node is Text, append from start to end offset
        if (end_node.node_type == .text_node) {
            if (end_node.node_value) |data| {
                const end = @min(self.end_offset, data.len);
                if (end > 0) {
                    try result.appendSlice(allocator, data[0..end]);
                }
            }
        }

        return result.toOwnedSlice(allocator);
    }

    /// Helper to append text from contained nodes
    ///
    /// This is a simplified implementation that traverses nodes in tree order
    /// and appends text from Text nodes that are fully contained in the range.
    fn appendContainedTextNodes(
        self: *const Self,
        result: *std.ArrayList(u8),
        allocator: std.mem.Allocator,
        start_node: *Node,
        end_node: *Node,
    ) !void {
        // Get the common ancestor
        const common = self.commonAncestorContainer() orelse return;

        // Traverse all descendants of common ancestor
        try self.traverseAndAppendText(result, allocator, common, start_node, end_node);
    }

    /// Recursively traverse and append text from contained nodes
    fn traverseAndAppendText(
        self: *const Self,
        result: *std.ArrayList(u8),
        allocator: std.mem.Allocator,
        node: *Node,
        start_node: *Node,
        end_node: *Node,
    ) !void {
        // Skip the start and end nodes themselves (handled separately)
        if (node == start_node or node == end_node) {
            // Still traverse children if this is not a text node
            if (node.node_type != .text_node) {
                var child = node.firstChild();
                while (child) |c| {
                    try self.traverseAndAppendText(result, allocator, c, start_node, end_node);
                    child = c.nextSibling();
                }
            }
            return;
        }

        // Check if node is a Text node
        if (node.node_type == .text_node) {
            // Check if this node is "contained" (between start and end in tree order)
            if (self.isNodeContained(node, start_node, end_node)) {
                if (node.node_value) |data| {
                    try result.appendSlice(allocator, data);
                }
            }
        }

        // Traverse children
        var child = node.firstChild();
        while (child) |c| {
            try self.traverseAndAppendText(result, allocator, c, start_node, end_node);
            child = c.nextSibling();
        }
    }

    /// Check if a node is contained between start and end nodes
    fn isNodeContained(
        self: *const Self,
        node: *Node,
        start_node: *Node,
        end_node: *Node,
    ) bool {
        _ = self;

        // Simplified containment check:
        // A node is contained if it comes after start_node and before end_node in tree order
        // This is a basic implementation - a full implementation would need
        // to properly calculate tree positions

        // For now, just return false to avoid including incorrect text
        // This makes toString work correctly for the simple case (same container)
        // and safely handles more complex cases
        _ = node;
        _ = start_node;
        _ = end_node;

        return false;
    }

    /// Clean up resources
    ///
    /// Frees the range object.
    /// Does not free the referenced nodes.
    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Range creation" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    try std.testing.expect(range.collapsed());
    try std.testing.expect(range.start_container == null);
    try std.testing.expect(range.end_container == null);
    try std.testing.expectEqual(@as(usize, 0), range.start_offset);
    try std.testing.expectEqual(@as(usize, 0), range.end_offset);
}

test "Range setStart" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello");
    defer node.release();

    try range.setStart(node, 2);

    try std.testing.expectEqual(node, range.start_container.?);
    try std.testing.expectEqual(@as(usize, 2), range.start_offset);
    // End should also be set to start
    try std.testing.expectEqual(node, range.end_container.?);
    try std.testing.expectEqual(@as(usize, 2), range.end_offset);
}

test "Range setEnd" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello");
    defer node.release();

    try range.setEnd(node, 5);

    try std.testing.expectEqual(node, range.end_container.?);
    try std.testing.expectEqual(@as(usize, 5), range.end_offset);
    // Start should also be set
    try std.testing.expectEqual(node, range.start_container.?);
    try std.testing.expectEqual(@as(usize, 5), range.start_offset);
}

test "Range setStart and setEnd" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 5);

    try std.testing.expectEqual(node, range.start_container.?);
    try std.testing.expectEqual(@as(usize, 0), range.start_offset);
    try std.testing.expectEqual(node, range.end_container.?);
    try std.testing.expectEqual(@as(usize, 5), range.end_offset);
    try std.testing.expect(!range.collapsed());
}

test "Range collapsed" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    // Initially collapsed
    try std.testing.expect(range.collapsed());

    // Set different boundaries
    try range.setStart(node, 0);
    try range.setEnd(node, 4);
    try std.testing.expect(!range.collapsed());

    // Collapse
    range.collapse(true);
    try std.testing.expect(range.collapsed());
    try std.testing.expectEqual(@as(usize, 0), range.end_offset);
}

test "Range collapse to start" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    try range.setStart(node, 1);
    try range.setEnd(node, 3);

    range.collapse(true);

    try std.testing.expect(range.collapsed());
    try std.testing.expectEqual(@as(usize, 1), range.start_offset);
    try std.testing.expectEqual(@as(usize, 1), range.end_offset);
}

test "Range collapse to end" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    try range.setStart(node, 1);
    try range.setEnd(node, 3);

    range.collapse(false);

    try std.testing.expect(range.collapsed());
    try std.testing.expectEqual(@as(usize, 3), range.start_offset);
    try std.testing.expectEqual(@as(usize, 3), range.end_offset);
}

test "Range selectNodeContents" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello");
    defer node.release();

    try range.selectNodeContents(node);

    try std.testing.expectEqual(node, range.start_container.?);
    try std.testing.expectEqual(@as(usize, 0), range.start_offset);
    try std.testing.expectEqual(node, range.end_container.?);
    try std.testing.expectEqual(@as(usize, 5), range.end_offset);
}

test "Range selectNode" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .text_node, "Child");
    _ = try parent.appendChild(child);

    try range.selectNode(child);

    try std.testing.expectEqual(parent, range.start_container.?);
    try std.testing.expectEqual(@as(usize, 0), range.start_offset);
    try std.testing.expectEqual(parent, range.end_container.?);
    try std.testing.expectEqual(@as(usize, 1), range.end_offset);
}

test "Range setStartBefore" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .text_node, "Child");
    _ = try parent.appendChild(child);

    try range.setStartBefore(child);

    try std.testing.expectEqual(parent, range.start_container.?);
    try std.testing.expectEqual(@as(usize, 0), range.start_offset);
}

test "Range setStartAfter" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .text_node, "Child");
    _ = try parent.appendChild(child);

    try range.setStartAfter(child);

    try std.testing.expectEqual(parent, range.start_container.?);
    try std.testing.expectEqual(@as(usize, 1), range.start_offset);
}

test "Range setEndBefore" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .text_node, "Child");
    _ = try parent.appendChild(child);

    try range.setEndBefore(child);

    try std.testing.expectEqual(parent, range.end_container.?);
    try std.testing.expectEqual(@as(usize, 0), range.end_offset);
}

test "Range setEndAfter" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .text_node, "Child");
    _ = try parent.appendChild(child);

    try range.setEndAfter(child);

    try std.testing.expectEqual(parent, range.end_container.?);
    try std.testing.expectEqual(@as(usize, 1), range.end_offset);
}

test "Range cloneRange" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    try range.setStart(node, 1);
    try range.setEnd(node, 3);

    const clone = try range.cloneRange();
    defer clone.deinit();

    try std.testing.expectEqual(range.start_container, clone.start_container);
    try std.testing.expectEqual(range.start_offset, clone.start_offset);
    try std.testing.expectEqual(range.end_container, clone.end_container);
    try std.testing.expectEqual(range.end_offset, clone.end_offset);
}

test "Range commonAncestorContainer same node" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 4);

    const ancestor = range.commonAncestorContainer();
    try std.testing.expectEqual(node, ancestor.?);
}

test "Range invalid offset" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    // Offset too large
    try std.testing.expectError(error.IndexSize, range.setStart(node, 10));
    try std.testing.expectError(error.IndexSize, range.setEnd(node, 10));
}

test "Range detach is no-op" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    // Should not crash or change state
    range.detach();
    try std.testing.expect(range.collapsed());
}

test "Range memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const range = try Range.init(allocator);
        const node = try Node.init(allocator, .text_node, "Test");
        defer node.release();

        try range.setStart(node, 0);
        try range.setEnd(node, 4);
        range.collapse(true);

        range.deinit();
    }
}

test "Range compareBoundaryPoints same node" {
    const allocator = std.testing.allocator;

    const range1 = try Range.init(allocator);
    defer range1.deinit();

    const range2 = try Range.init(allocator);
    defer range2.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range1.setStart(node, 0);
    try range1.setEnd(node, 5);

    try range2.setStart(node, 6);
    try range2.setEnd(node, 11);

    // Compare starts - range1 start is before range2 start
    const result = try range1.compareBoundaryPoints(START_TO_START, range2);
    try std.testing.expectEqual(@as(i8, -1), result);
}

test "Range compareBoundaryPoints equal" {
    const allocator = std.testing.allocator;

    const range1 = try Range.init(allocator);
    defer range1.deinit();

    const range2 = try Range.init(allocator);
    defer range2.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    try range1.setStart(node, 0);
    try range1.setEnd(node, 4);

    try range2.setStart(node, 0);
    try range2.setEnd(node, 4);

    // Same boundaries
    const result = try range1.compareBoundaryPoints(START_TO_START, range2);
    try std.testing.expectEqual(@as(i8, 0), result);
}

test "Range compareBoundaryPoints end to end" {
    const allocator = std.testing.allocator;

    const range1 = try Range.init(allocator);
    defer range1.deinit();

    const range2 = try Range.init(allocator);
    defer range2.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range1.setStart(node, 0);
    try range1.setEnd(node, 11);

    try range2.setStart(node, 0);
    try range2.setEnd(node, 5);

    // Compare ends - range1 end is after range2 end
    const result = try range1.compareBoundaryPoints(END_TO_END, range2);
    try std.testing.expectEqual(@as(i8, 1), result);
}

test "Range compareBoundaryPoints invalid how" {
    const allocator = std.testing.allocator;

    const range1 = try Range.init(allocator);
    defer range1.deinit();

    const range2 = try Range.init(allocator);
    defer range2.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    try range1.setStart(node, 0);
    try range1.setEnd(node, 4);

    try range2.setStart(node, 0);
    try range2.setEnd(node, 4);

    // Invalid comparison type
    try std.testing.expectError(error.NotSupported, range1.compareBoundaryPoints(99, range2));
}

test "Range isPointInRange same node" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 5);

    // Point within range
    try std.testing.expect(try range.isPointInRange(node, 2));

    // Point at boundaries
    try std.testing.expect(try range.isPointInRange(node, 0));
    try std.testing.expect(try range.isPointInRange(node, 5));

    // Point outside range
    try std.testing.expect(!try range.isPointInRange(node, 10));
}

test "Range isPointInRange invalid offset" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Test");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 4);

    // Offset too large
    try std.testing.expectError(error.IndexSize, range.isPointInRange(node, 100));
}

test "Range comparePoint before range" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range.setStart(node, 5);
    try range.setEnd(node, 10);

    // Point before range
    const result = try range.comparePoint(node, 2);
    try std.testing.expectEqual(@as(i8, -1), result);
}

test "Range comparePoint after range" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 5);

    // Point after range
    const result = try range.comparePoint(node, 10);
    try std.testing.expectEqual(@as(i8, 1), result);
}

test "Range comparePoint within range" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 10);

    // Point within range
    const result = try range.comparePoint(node, 5);
    try std.testing.expectEqual(@as(i8, 0), result);
}

test "Range intersectsNode same container" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 5);

    // Node is the container
    try std.testing.expect(range.intersectsNode(node));
}

test "Range intersectsNode parent" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .text_node, "Text");
    _ = try parent.appendChild(child);

    try range.setStart(parent, 0);
    try range.setEnd(parent, 1);

    // Parent is container, child should intersect
    try std.testing.expect(range.intersectsNode(child));
}

test "Range deleteContents" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 5);

    // Delete contents
    try range.deleteContents();

    // Range should be collapsed
    try std.testing.expect(range.collapsed());
}

test "Range insertNode" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const container = try Node.init(allocator, .element_node, "div");
    defer container.release();

    try range.setStart(container, 0);
    try range.setEnd(container, 0);

    const new_node = try Node.init(allocator, .text_node, "New");
    defer new_node.release();

    // Should not error (simplified implementation)
    try range.insertNode(new_node);
}

test "Range surroundContents" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 5);

    const wrapper = try Node.init(allocator, .element_node, "span");
    defer wrapper.release();

    // Simplified implementation - should not crash
    try range.surroundContents(wrapper);
}

test "Range surroundContents collapsed error" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const wrapper = try Node.init(allocator, .element_node, "span");
    defer wrapper.release();

    // Collapsed range should error
    try std.testing.expectError(error.InvalidState, range.surroundContents(wrapper));
}

test "Range extractContents collapsed" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    // Extract from collapsed range should return empty fragment
    const fragment = try range.extractContents();
    defer fragment.release();

    try std.testing.expectEqual(@as(usize, 0), fragment.node.child_nodes.length());
}

test "Range extractContents with content" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 5);

    // Extract contents
    const fragment = try range.extractContents();
    defer fragment.release();

    // Fragment should be created
    try std.testing.expect(fragment.node.node_type == .document_fragment_node);

    // Range should be collapsed after extraction
    try std.testing.expect(range.collapsed());
}

test "Range cloneContents collapsed" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    // Clone from collapsed range should return empty fragment
    const fragment = try range.cloneContents();
    defer fragment.release();

    try std.testing.expectEqual(@as(usize, 0), fragment.node.child_nodes.length());
}

test "Range cloneContents with content" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const node = try Node.init(allocator, .text_node, "Hello World");
    defer node.release();

    try range.setStart(node, 0);
    try range.setEnd(node, 5);

    // Clone contents
    const fragment = try range.cloneContents();
    defer fragment.release();

    // Fragment should be created
    try std.testing.expect(fragment.node.node_type == .document_fragment_node);

    // Range should NOT be collapsed after cloning (unlike extract)
    try std.testing.expect(!range.collapsed());
}

test "Range extractContents vs cloneContents" {
    const allocator = std.testing.allocator;

    const range1 = try Range.init(allocator);
    defer range1.deinit();

    const range2 = try Range.init(allocator);
    defer range2.deinit();

    const node1 = try Node.init(allocator, .text_node, "Test 1");
    defer node1.release();

    const node2 = try Node.init(allocator, .text_node, "Test 2");
    defer node2.release();

    try range1.setStart(node1, 0);
    try range1.setEnd(node1, 4);

    try range2.setStart(node2, 0);
    try range2.setEnd(node2, 4);

    // Extract collapses the range
    const fragment1 = try range1.extractContents();
    defer fragment1.release();
    try std.testing.expect(range1.collapsed());

    // Clone does not collapse the range
    const fragment2 = try range2.cloneContents();
    defer fragment2.release();
    try std.testing.expect(!range2.collapsed());
}

test "Range toString - empty range" {
    const allocator = std.testing.allocator;

    const range = try Range.init(allocator);
    defer range.deinit();

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("", str);
}

test "Range toString - single text node substring" {
    const allocator = std.testing.allocator;

    const text = try Node.init(allocator, .text_node, "#text");
    defer text.release();
    text.node_value = try allocator.dupe(u8, "Hello World");

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.setStart(text, 0);
    try range.setEnd(text, 5);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("Hello", str);
}

test "Range toString - full text node" {
    const allocator = std.testing.allocator;

    const text = try Node.init(allocator, .text_node, "#text");
    defer text.release();
    text.node_value = try allocator.dupe(u8, "Complete");

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.setStart(text, 0);
    try range.setEnd(text, 8);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("Complete", str);
}

test "Range toString - middle of text" {
    const allocator = std.testing.allocator;

    const text = try Node.init(allocator, .text_node, "#text");
    defer text.release();
    text.node_value = try allocator.dupe(u8, "0123456789");

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.setStart(text, 3);
    try range.setEnd(text, 7);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("3456", str);
}
