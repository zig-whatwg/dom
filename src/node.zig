//! # DOM Node Implementation
//!
//! ## Overview
//!
//! This module implements the W3C DOM Node interface, which is the primary datatype
//! for the entire Document Object Model. All objects in a document tree implement the
//! Node interface, making it the fundamental building block of the DOM.
//!
//! The Node interface provides a unified way to manipulate the tree structure and
//! access properties that are common to all node types (Element, Text, Comment,
//! Document, etc.). This implementation follows the WHATWG DOM Standard §4.4.
//!
//! ## Key Features
//!
//! - **Tree Structure**: Parent-child relationships with full traversal support
//! - **Reference Counting**: Automatic memory management with retain/release
//! - **Event Target Integration**: Full event system support via EventTarget
//! - **Node Manipulation**: Insert, append, remove, replace operations
//! - **Tree Traversal**: First/last child, previous/next sibling navigation
//! - **Node Comparison**: Contains, equality, and document position checks
//! - **Cloning**: Deep and shallow node cloning with subtrees
//! - **Normalization**: Combines adjacent text nodes and removes empty ones
//! - **Text Content**: Get/set text content of nodes and their descendants
//!
//! ## Node Types
//!
//! The DOM supports multiple node types, each serving a specific purpose:
//! - Element nodes (HTML/XML elements)
//! - Text nodes (textual content)
//! - Comment nodes (HTML/XML comments)
//! - Document nodes (root document)
//! - Document Type nodes (DOCTYPE declarations)
//! - Document Fragment nodes (lightweight containers)
//!
//! ## Memory Management
//!
//! This implementation uses reference counting for automatic memory management.
//! Each node starts with a reference count of 1. When a node is added as a child,
//! its reference count increases. When removed, it decreases. When the count
//! reaches 0, the node and all its children are deallocated.
//!
//! ## Specification Compliance
//!
//! This implementation aims for compliance with:
//! - WHATWG DOM Standard §4.4 (Interface Node)
//! - W3C DOM Level 3 Core Specification
//!
//! ## Reference
//!
//! * WHATWG DOM Standard: https://dom.spec.whatwg.org/#interface-node
//! * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node

const std = @import("std");
const EventTarget = @import("event_target.zig").EventTarget;
const Event = @import("event.zig").Event;
const NodeList = @import("node_list.zig").NodeList;

// ============================================================================
// Security Limits Configuration
// ============================================================================

/// Security limits to prevent DoS attacks and resource exhaustion.
/// These limits can be adjusted based on application requirements.
pub const SecurityLimits = struct {
    /// Maximum DOM tree depth to prevent stack overflow attacks (P0)
    /// Default: 1000 levels
    pub const max_tree_depth: usize = 1000;

    /// Maximum reference count to prevent overflow (P0)
    /// Default: 1 million references
    pub const max_ref_count: usize = 1_000_000;

    /// Maximum tag name length to prevent memory exhaustion (P2)
    /// Default: 256 characters (reasonable for XML/HTML)
    pub const max_tag_name_length: usize = 256;

    /// Maximum attribute name length (P2)
    /// Default: 256 characters
    pub const max_attribute_name_length: usize = 256;

    /// Maximum attribute value length (P2)
    /// Default: 64KB (reasonable for data attributes)
    pub const max_attribute_value_length: usize = 65536;

    /// Maximum text content length per operation (P2)
    /// Default: 1MB (reasonable for content)
    pub const max_text_content_length: usize = 1_048_576;

    /// Maximum children per node to prevent wide tree attacks (P1)
    /// Default: 10,000 children per node
    pub const max_children_per_node: usize = 10_000;

    /// Maximum total nodes per document to prevent memory exhaustion (P1)
    /// Default: 100,000 nodes per document
    pub const max_nodes_per_document: usize = 100_000;

    /// Maximum attributes per element to prevent attribute explosion (P1)
    /// Default: 1,000 attributes per element
    pub const max_attributes_per_element: usize = 1_000;

    /// Maximum event listeners per target to prevent listener accumulation (P1)
    /// Default: 1,000 listeners per target
    pub const max_listeners_per_target: usize = 1_000;
};

/// Errors related to security limit violations
pub const SecurityError = error{
    /// Tree depth exceeds maximum allowed depth
    MaxTreeDepthExceeded,

    /// Reference count would overflow
    RefCountOverflow,

    /// Reference count would underflow (released too many times)
    RefCountUnderflow,

    /// Circular reference detected in DOM tree
    CircularReferenceDetected,

    /// Tag name exceeds maximum length
    TagNameTooLong,

    /// Attribute name exceeds maximum length
    AttributeNameTooLong,

    /// Attribute value exceeds maximum length
    AttributeValueTooLong,

    /// Text content exceeds maximum length
    TextContentTooLong,

    /// Too many children in a single node (P1)
    TooManyChildren,

    /// Too many nodes in document (P1)
    TooManyNodes,

    /// Too many attributes on an element (P1)
    TooManyAttributes,

    /// Too many event listeners on a target (P1)
    TooManyListeners,
};

// ============================================================================
// Security Event Logging (P2)
// ============================================================================

/// Security event types for logging and monitoring
pub const SecurityEventType = enum {
    ref_count_overflow_attempt,
    ref_count_underflow_attempt,
    circular_reference_detected,
    max_tree_depth_exceeded,
    max_children_exceeded,
    max_nodes_exceeded,
    max_attributes_exceeded,
    tag_name_too_long,
    attribute_name_too_long,
    attribute_value_too_long,
    text_content_too_long,
};

/// Security event details
pub const SecurityEvent = struct {
    event_type: SecurityEventType,
    node_type: ?NodeType,
    node_name: ?[]const u8,
    message: []const u8,
    timestamp: i64,
};

/// Optional security event callback for logging/monitoring
/// Applications can set this to log security violations
pub var security_event_callback: ?*const fn (event: SecurityEvent) void = null;

/// Log a security event (P2)
fn logSecurityEvent(event_type: SecurityEventType, node_type: ?NodeType, node_name: ?[]const u8, message: []const u8) void {
    if (security_event_callback) |callback| {
        const event = SecurityEvent{
            .event_type = event_type,
            .node_type = node_type,
            .node_name = node_name,
            .message = message,
            .timestamp = std.time.milliTimestamp(),
        };
        callback(event);
    }
}

/// NodeType enumeration defines the type of a Node object.
///
/// ## Overview
///
/// Each node in the DOM tree has a specific type that determines its behavior
/// and the operations that can be performed on it. The numeric values are
/// standardized by the W3C DOM specification.
///
/// ## Node Type Values
///
/// - `element_node` (1): Represents an Element node (e.g., `<div>`, `<p>`)
/// - `attribute_node` (2): Represents an Attr node (deprecated in DOM4)
/// - `text_node` (3): Represents a Text node containing textual content
/// - `cdata_section_node` (4): Represents a CDATASection node (XML only)
/// - `processing_instruction_node` (7): Represents a ProcessingInstruction node
/// - `comment_node` (8): Represents a Comment node
/// - `document_node` (9): Represents the Document node (root)
/// - `document_type_node` (10): Represents a DocumentType node (DOCTYPE)
/// - `document_fragment_node` (11): Represents a DocumentFragment node
///
/// ## Examples
///
/// ```zig
/// const div_node = try Node.init(allocator, .element_node, "div");
/// const text_node = try Node.init(allocator, .text_node, "#text");
/// const comment_node = try Node.init(allocator, .comment_node, "#comment");
/// ```
///
/// ## Specification Compliance
///
/// Implements WHATWG DOM Standard §4.4 Node constants.
///
/// ## Reference
///
/// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-nodetype
/// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeType
pub const NodeType = enum(u16) {
    element_node = 1,
    attribute_node = 2,
    text_node = 3,
    cdata_section_node = 4,
    processing_instruction_node = 7,
    comment_node = 8,
    document_node = 9,
    document_type_node = 10,
    document_fragment_node = 11,
};

/// DocumentPosition represents the relative position of two nodes in the document.
///
/// ## Overview
///
/// This packed struct provides a bitmask for describing the relationship between
/// two nodes in terms of their position in the document tree. Multiple flags can
/// be set simultaneously to describe complex relationships.
///
/// ## Flags
///
/// - `disconnected`: Nodes are in different trees (no common ancestor)
/// - `preceding`: Other node precedes this node in document order
/// - `following`: Other node follows this node in document order
/// - `contains`: This node contains the other node (is an ancestor)
/// - `contained_by`: This node is contained by the other node (is a descendant)
/// - `implementation_specific`: Position is implementation-dependent
///
/// ## Examples
///
/// ```zig
/// const parent = try Node.init(allocator, .element_node, "div");
/// const child = try Node.init(allocator, .element_node, "span");
/// _ = try parent.appendChild(child);
///
/// const pos = parent.compareDocumentPosition(child);
/// // pos.contains == true, pos.following == true
/// ```
///
/// ## Specification Compliance
///
/// Implements WHATWG DOM Standard §4.4 compareDocumentPosition() method.
///
/// ## Reference
///
/// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-comparedocumentposition
/// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/compareDocumentPosition
pub const DocumentPosition = packed struct(u16) {
    disconnected: bool = false,
    preceding: bool = false,
    following: bool = false,
    contains: bool = false,
    contained_by: bool = false,
    implementation_specific: bool = false,
    _padding: u10 = 0,
};

/// Node represents a single node in the document tree.
///
/// ## Overview
///
/// The Node struct is the primary datatype for the entire DOM. Every object
/// located within a document is a node of some kind. Nodes can have parent-child
/// relationships and can be manipulated using a rich set of methods.
///
/// This implementation uses reference counting for memory management, ensuring
/// that nodes are automatically deallocated when they are no longer referenced.
///
/// ## Fields
///
/// - `event_target`: Embedded EventTarget for event handling capabilities
/// - `node_type`: The type of this node (element, text, comment, etc.)
/// - `node_name`: The name of the node (tag name for elements, "#text" for text nodes)
/// - `node_value`: The value of the node (text content for text nodes, null for elements)
/// - `parent_node`: Reference to the parent node, or null if this is the root
/// - `child_nodes`: List of child nodes
/// - `owner_document`: Reference to the document that owns this node
/// - `ref_count`: Reference count for memory management
/// - `allocator`: Memory allocator used for this node
/// - `element_data_ptr`: Optional pointer to element-specific data
///
/// ## Memory Management
///
/// Nodes use reference counting. Each node starts with ref_count = 1.
/// Call retain() to increment and release() to decrement. When ref_count
/// reaches 0, the node is automatically deallocated.
///
/// ## Examples
///
/// ### Basic Node Creation
///
/// ```zig
/// const allocator = std.testing.allocator;
/// const node = try Node.init(allocator, .element_node, "div");
/// defer node.release();
/// ```
///
/// ### Building a Tree
///
/// ```zig
/// const parent = try Node.init(allocator, .element_node, "div");
/// defer parent.release();
///
/// const child1 = try Node.init(allocator, .element_node, "span");
/// const child2 = try Node.init(allocator, .text_node, "#text");
/// child2.node_value = try allocator.dupe(u8, "Hello");
///
/// _ = try parent.appendChild(child1);
/// _ = try parent.appendChild(child2);
/// ```
///
/// ### Tree Traversal
///
/// ```zig
/// const first = parent.firstChild(); // Returns child1
/// const last = parent.lastChild();   // Returns child2
/// const next = child1.nextSibling(); // Returns child2
/// ```
///
/// ## Specification Compliance
///
/// Implements WHATWG DOM Standard §4.4 (Interface Node).
///
/// ## Reference
///
/// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#interface-node
/// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node
pub const Node = struct {
    const Self = @This();

    event_target: EventTarget,
    node_type: NodeType,
    node_name: []const u8,
    node_value: ?[]const u8,
    parent_node: ?*Node,
    child_nodes: NodeList,
    owner_document: ?*anyopaque,
    ref_count: usize,
    allocator: std.mem.Allocator,
    element_data_ptr: ?*anyopaque,

    /// Creates a new Node with the specified type and name.
    ///
    /// ## Overview
    ///
    /// Initializes a new Node instance with the given type and name. The node
    /// starts with a reference count of 1 and should be released when no longer
    /// needed using the release() method.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the node and its data
    /// - `node_type`: The type of node to create (element, text, comment, etc.)
    /// - `node_name`: The name of the node (will be copied)
    ///
    /// ## Returns
    ///
    /// Returns a pointer to the newly created Node, or an error if allocation fails.
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If memory allocation fails
    ///
    /// ## Examples
    ///
    /// ### Creating Different Node Types
    ///
    /// ```zig
    /// // Element node
    /// const div = try Node.init(allocator, .element_node, "div");
    /// defer div.release();
    ///
    /// // Text node
    /// const text = try Node.init(allocator, .text_node, "#text");
    /// defer text.release();
    ///
    /// // Comment node
    /// const comment = try Node.init(allocator, .comment_node, "#comment");
    /// defer comment.release();
    /// ```
    ///
    /// ## Memory Management
    ///
    /// The returned node has a reference count of 1. You must call release()
    /// when done to prevent memory leaks. If the node is added to a parent,
    /// the parent manages its lifetime.
    ///
    /// ## Specification Compliance
    ///
    /// Implements node creation as per WHATWG DOM Standard §4.4.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#interface-node
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node
    pub fn init(
        allocator: std.mem.Allocator,
        node_type: NodeType,
        node_name: []const u8,
    ) !*Self {
        const self = try allocator.create(Self);
        const name_copy = try allocator.dupe(u8, node_name);
        self.* = .{
            .event_target = EventTarget.init(allocator),
            .node_type = node_type,
            .node_name = name_copy,
            .node_value = null,
            .parent_node = null,
            .child_nodes = NodeList.init(allocator),
            .owner_document = null,
            .ref_count = 1,
            .allocator = allocator,
            .element_data_ptr = null,
        };
        return self;
    }

    /// Deinitializes the node and frees all associated resources.
    ///
    /// ## Overview
    ///
    /// Cleans up all memory associated with this node, including the node name,
    /// node value, element data, event target, and child nodes list. This method
    /// is called automatically by release() when the reference count reaches 0.
    ///
    /// ## Behavior
    ///
    /// - Frees the node name string
    /// - Frees the node value if present
    /// - Deinitializes element data if present
    /// - Deinitializes the embedded EventTarget
    /// - Deinitializes the child nodes list (but not the children themselves)
    ///
    /// ## Safety
    ///
    /// This method does NOT automatically release child nodes. The caller (typically
    /// the release() method) must ensure all children are properly removed before
    /// calling deinit().
    ///
    /// ## Note
    ///
    /// You should typically use release() instead of calling deinit() directly,
    /// as release() properly handles reference counting and child cleanup.
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.node_name);
        if (self.node_value) |value| {
            self.allocator.free(value);
        }

        // Clean up node-type-specific data
        if (self.element_data_ptr) |ptr| {
            switch (self.node_type) {
                .element_node => {
                    const ElementData = @import("element.zig").ElementData;
                    const data: *ElementData = @ptrCast(@alignCast(ptr));
                    data.deinit(self.allocator);
                    self.allocator.destroy(data);
                },
                .document_type_node => {
                    const DocumentType = @import("document_type.zig").DocumentType;
                    const doctype: *DocumentType = @ptrCast(@alignCast(ptr));
                    doctype.deinit();
                },
                .processing_instruction_node => {
                    const ProcessingInstruction = @import("processing_instruction.zig").ProcessingInstruction;
                    const pi: *ProcessingInstruction = @ptrCast(@alignCast(ptr));
                    pi.deinit();
                },
                else => {
                    // Other node types don't use element_data_ptr
                },
            }
        }

        self.event_target.deinit();
        self.child_nodes.deinit();
    }

    /// Increments the reference count of this node.
    ///
    /// ## Overview
    ///
    /// Increases the reference count by 1. This is called automatically when
    /// a node is added to a parent (appendChild, insertBefore, etc.) to prevent
    /// premature deallocation.
    ///
    /// ## Behavior
    ///
    /// Increments `ref_count` by 1. The node will not be deallocated until
    /// release() is called an equal number of times.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "div");
    /// // ref_count = 1
    ///
    /// node.retain();
    /// // ref_count = 2
    ///
    /// node.release();
    /// // ref_count = 1 (node still alive)
    ///
    /// node.release();
    /// // ref_count = 0 (node deallocated)
    /// ```
    ///
    /// ## Note
    ///
    /// You typically don't need to call this manually. The tree manipulation
    /// methods (appendChild, insertBefore, etc.) handle reference counting
    /// automatically.
    ///
    /// ## Reference
    ///
    /// * Reference Counting Pattern: https://en.wikipedia.org/wiki/Reference_counting
    pub fn retain(self: *Self) void {
        // P0 Security Fix: Prevent reference count overflow
        if (self.ref_count >= SecurityLimits.max_ref_count) {
            logSecurityEvent(.ref_count_overflow_attempt, self.node_type, self.node_name, "Reference count overflow detected - potential DoS attack or reference leak");
            @panic("Reference count overflow detected - potential DoS attack or reference leak");
        }
        self.ref_count += 1;
    }

    /// Decrements the reference count and deallocates if it reaches 0.
    ///
    /// ## Overview
    ///
    /// Decreases the reference count by 1. When the count reaches 0, this method
    /// automatically removes all children, calls deinit(), and deallocates the node.
    ///
    /// ## Behavior
    ///
    /// 1. Decrements `ref_count` by 1
    /// 2. If `ref_count` becomes 0:
    ///    - Removes all child nodes (calling release() on each)
    ///    - Calls deinit() to free resources
    ///    - Deallocates the node itself
    ///
    /// ## Examples
    ///
    /// ### Simple Release
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "div");
    /// // ref_count = 1
    /// node.release();
    /// // ref_count = 0, node is deallocated
    /// ```
    ///
    /// ### Release with Children
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try parent.appendChild(child);
    /// // parent ref_count = 1, child ref_count = 2
    ///
    /// parent.release();
    /// // Both parent and child are deallocated
    /// ```
    ///
    /// ## Safety
    ///
    /// This method properly cascades deallocation to all children, preventing
    /// memory leaks. All descendants are released recursively.
    ///
    /// ## Reference
    ///
    /// * Reference Counting Pattern: https://en.wikipedia.org/wiki/Reference_counting
    pub fn release(self: *Self) void {
        // P0 Security Fix: Prevent reference count underflow
        if (self.ref_count == 0) {
            logSecurityEvent(.ref_count_underflow_attempt, self.node_type, self.node_name, "Reference count underflow detected - node released too many times");
            @panic("Reference count underflow detected - node released too many times");
        }
        self.ref_count -= 1;
        if (self.ref_count == 0) {
            while (self.child_nodes.length() > 0) {
                if (self.child_nodes.item(0)) |child_ptr| {
                    const child: *Node = @ptrCast(@alignCast(child_ptr));
                    _ = self.removeChild(child) catch unreachable;
                }
            }
            self.deinit();
            self.allocator.destroy(self);
        }
    }

    /// Returns the first child of this node, or null if there are no children.
    ///
    /// ## Overview
    ///
    /// Retrieves the first child node in the child nodes list. This is equivalent
    /// to accessing childNodes[0] in the DOM specification.
    ///
    /// ## Returns
    ///
    /// - Returns a pointer to the first child node if children exist
    /// - Returns null if this node has no children
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Node.init(allocator, .element_node, "span");
    /// const child2 = try Node.init(allocator, .element_node, "p");
    ///
    /// _ = try parent.appendChild(child1);
    /// _ = try parent.appendChild(child2);
    ///
    /// const first = parent.firstChild();
    /// // first == child1
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.firstChild.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-firstchild
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/firstChild
    pub fn firstChild(self: *const Self) ?*Node {
        const child_ptr = self.child_nodes.item(0) orelse return null;
        return @ptrCast(@alignCast(child_ptr));
    }

    /// Returns the last child of this node, or null if there are no children.
    ///
    /// ## Overview
    ///
    /// Retrieves the last child node in the child nodes list. This is equivalent
    /// to accessing childNodes[childNodes.length - 1] in the DOM specification.
    ///
    /// ## Returns
    ///
    /// - Returns a pointer to the last child node if children exist
    /// - Returns null if this node has no children
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Node.init(allocator, .element_node, "span");
    /// const child2 = try Node.init(allocator, .element_node, "p");
    ///
    /// _ = try parent.appendChild(child1);
    /// _ = try parent.appendChild(child2);
    ///
    /// const last = parent.lastChild();
    /// // last == child2
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.lastChild.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-lastchild
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/lastChild
    pub fn lastChild(self: *const Self) ?*Node {
        const len = self.child_nodes.length();
        if (len == 0) return null;
        const child_ptr = self.child_nodes.item(len - 1) orelse return null;
        return @ptrCast(@alignCast(child_ptr));
    }

    /// Returns the previous sibling of this node, or null if there is none.
    ///
    /// ## Overview
    ///
    /// Finds and returns the node immediately preceding this node in its parent's
    /// child list. Returns null if this node is the first child or has no parent.
    ///
    /// ## Returns
    ///
    /// - Returns a pointer to the previous sibling if one exists
    /// - Returns null if this is the first child or has no parent
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Node.init(allocator, .element_node, "span");
    /// const child2 = try Node.init(allocator, .element_node, "p");
    /// const child3 = try Node.init(allocator, .element_node, "a");
    ///
    /// _ = try parent.appendChild(child1);
    /// _ = try parent.appendChild(child2);
    /// _ = try parent.appendChild(child3);
    ///
    /// const prev = child2.previousSibling();
    /// // prev == child1
    ///
    /// const none = child1.previousSibling();
    /// // none == null
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.previousSibling.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-previoussibling
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/previousSibling
    pub fn previousSibling(self: *const Self) ?*Node {
        const parent = self.parent_node orelse return null;
        for (parent.child_nodes.items.items, 0..) |child_ptr, i| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (child == self and i > 0) {
                const prev_ptr = parent.child_nodes.item(i - 1) orelse return null;
                return @ptrCast(@alignCast(prev_ptr));
            }
        }
        return null;
    }

    /// Returns the next sibling of this node, or null if there is none.
    ///
    /// ## Overview
    ///
    /// Finds and returns the node immediately following this node in its parent's
    /// child list. Returns null if this node is the last child or has no parent.
    ///
    /// ## Returns
    ///
    /// - Returns a pointer to the next sibling if one exists
    /// - Returns null if this is the last child or has no parent
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Node.init(allocator, .element_node, "span");
    /// const child2 = try Node.init(allocator, .element_node, "p");
    /// const child3 = try Node.init(allocator, .element_node, "a");
    ///
    /// _ = try parent.appendChild(child1);
    /// _ = try parent.appendChild(child2);
    /// _ = try parent.appendChild(child3);
    ///
    /// const next = child2.nextSibling();
    /// // next == child3
    ///
    /// const none = child3.nextSibling();
    /// // none == null
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.nextSibling.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-nextsibling
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/nextSibling
    pub fn nextSibling(self: *const Self) ?*Node {
        const parent = self.parent_node orelse return null;
        for (parent.child_nodes.items.items, 0..) |child_ptr, i| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (child == self and i + 1 < parent.child_nodes.length()) {
                const next_ptr = parent.child_nodes.item(i + 1) orelse return null;
                return @ptrCast(@alignCast(next_ptr));
            }
        }
        return null;
    }

    /// Returns true if this node has any children, false otherwise.
    pub fn hasChildNodes(self: *const Self) bool {
        return self.child_nodes.length() > 0;
    }

    /// Checks if adding new_child would create a circular reference.
    ///
    /// ## Security (P0)
    ///
    /// Detects cycles by checking if new_child is an ancestor of self.
    /// This prevents circular DOM structures that would cause memory leaks.
    ///
    /// ## Parameters
    ///
    /// - `new_child`: The node to check
    ///
    /// ## Returns
    ///
    /// true if adding new_child would create a cycle, false otherwise
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try parent.appendChild(child);
    ///
    /// // This would create a cycle: child -> parent -> child
    /// const would_cycle = try child.wouldCreateCycle(parent);
    /// // would_cycle == true
    /// ```
    fn wouldCreateCycle(self: *const Self, new_child: *const Node) !bool {
        // If new_child is self, that's a direct cycle
        if (self == new_child) {
            return true;
        }

        // Check if self is a descendant of new_child
        // by walking up new_child's ancestor chain
        var ancestor = new_child.parent_node;
        var depth: usize = 0;

        while (ancestor) |anc| {
            // P0 Security: Prevent infinite loop from existing cycles
            depth += 1;
            if (depth > SecurityLimits.max_tree_depth) {
                // If we've walked too far, there's likely already a cycle
                return SecurityError.MaxTreeDepthExceeded;
            }

            if (anc == self) {
                // self is an ancestor of new_child, so adding new_child
                // as a child of self would create a cycle
                return true;
            }
            ancestor = anc.parent_node;
        }

        return false;
    }

    /// Adds a node to the end of the list of children of this node.
    ///
    /// ## Overview
    ///
    /// Appends a child node to the end of this node's child list. If the child
    /// already has a parent, it is first removed from that parent before being
    /// appended to this node.
    ///
    /// ## Parameters
    ///
    /// - `new_child`: The node to append as a child
    ///
    /// ## Returns
    ///
    /// Returns the appended child node.
    ///
    /// ## Behavior
    ///
    /// 1. If new_child already has a parent, removes it from that parent
    /// 2. Increments new_child's reference count via retain()
    /// 3. Sets new_child's parent_node to this node
    /// 4. Adds new_child to this node's child list
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If growing the child list fails
    ///
    /// ## Examples
    ///
    /// ### Basic Append
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try parent.appendChild(child);
    /// // child is now managed by parent
    /// ```
    ///
    /// ### Moving Between Parents
    ///
    /// ```zig
    /// const parent1 = try Node.init(allocator, .element_node, "div");
    /// defer parent1.release();
    ///
    /// const parent2 = try Node.init(allocator, .element_node, "section");
    /// defer parent2.release();
    ///
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try parent1.appendChild(child);
    /// // child is in parent1
    ///
    /// _ = try parent2.appendChild(child);
    /// // child is now in parent2 (automatically removed from parent1)
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.appendChild().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-appendchild
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild
    pub fn appendChild(self: *Self, new_child: *Node) !*Node {
        // P0 Security Fix: Detect circular references before adding child
        // This prevents memory leaks from circular DOM structures
        if (try self.wouldCreateCycle(new_child)) {
            logSecurityEvent(.circular_reference_detected, self.node_type, self.node_name, "Circular reference detected in appendChild");
            return SecurityError.CircularReferenceDetected;
        }

        // P1 Security Fix: Limit number of children per node (wide tree attack)
        if (self.child_nodes.length() >= SecurityLimits.max_children_per_node) {
            logSecurityEvent(.max_children_exceeded, self.node_type, self.node_name, "Max children per node exceeded");
            return SecurityError.TooManyChildren;
        }

        if (new_child.parent_node) |old_parent| {
            new_child.retain(); // Retain before removing to prevent deallocation
            _ = try old_parent.removeChild(new_child);
        }

        new_child.parent_node = self;
        try self.child_nodes.append(new_child);

        return new_child;
    }

    /// Inserts a node before a reference node as a child of this node.
    ///
    /// ## Overview
    ///
    /// Inserts new_child before ref_child in this node's child list. If ref_child
    /// is null, this behaves like appendChild() (inserts at the end).
    ///
    /// ## Parameters
    ///
    /// - `new_child`: The node to insert
    /// - `ref_child`: The reference node before which to insert, or null to append
    ///
    /// ## Returns
    ///
    /// Returns the inserted node.
    ///
    /// ## Errors
    ///
    /// - `NotFoundError`: If ref_child is not a child of this node
    /// - `OutOfMemory`: If growing the child list fails
    ///
    /// ## Examples
    ///
    /// ### Insert Before Existing Child
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Node.init(allocator, .element_node, "span");
    /// const child2 = try Node.init(allocator, .element_node, "p");
    /// const new_child = try Node.init(allocator, .element_node, "a");
    ///
    /// _ = try parent.appendChild(child1);
    /// _ = try parent.appendChild(child2);
    ///
    /// _ = try parent.insertBefore(new_child, child2);
    /// // Order is now: child1, new_child, child2
    /// ```
    ///
    /// ### Insert as First Child
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const existing = try Node.init(allocator, .element_node, "span");
    /// _ = try parent.appendChild(existing);
    ///
    /// const new_first = try Node.init(allocator, .element_node, "header");
    /// _ = try parent.insertBefore(new_first, existing);
    /// // new_first is now the first child
    /// ```
    ///
    /// ### Insert with Null Reference (Appends)
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try parent.insertBefore(child, null);
    /// // Same as appendChild(child)
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.insertBefore().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-insertbefore
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/insertBefore
    pub fn insertBefore(self: *Self, new_child: *Node, ref_child: ?*Node) !*Node {
        if (ref_child == null) {
            return try self.appendChild(new_child);
        }

        // P0 Security Fix: Detect circular references before adding child
        if (try self.wouldCreateCycle(new_child)) {
            return SecurityError.CircularReferenceDetected;
        }

        // P1 Security Fix: Limit number of children per node
        if (self.child_nodes.length() >= SecurityLimits.max_children_per_node) {
            return SecurityError.TooManyChildren;
        }

        const ref = ref_child.?;
        var index: ?usize = null;
        for (self.child_nodes.items.items, 0..) |child_ptr, i| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (child == ref) {
                index = i;
                break;
            }
        }

        if (index == null) {
            return error.NotFoundError;
        }

        if (new_child.parent_node) |old_parent| {
            new_child.retain(); // Retain before removing to prevent deallocation
            _ = try old_parent.removeChild(new_child);
        }

        new_child.parent_node = self;
        try self.child_nodes.items.insert(self.allocator, index.?, new_child);

        return new_child;
    }

    /// Replaces one child node with another.
    ///
    /// ## Overview
    ///
    /// Replaces old_child with new_child in this node's child list. The old child
    /// is removed and its reference count is decremented. The new child is added
    /// and its reference count is incremented.
    ///
    /// ## Parameters
    ///
    /// - `new_child`: The node to insert
    /// - `old_child`: The node to remove
    ///
    /// ## Returns
    ///
    /// Returns the removed old_child node.
    ///
    /// ## Errors
    ///
    /// - `NotFoundError`: If old_child is not a child of this node
    ///
    /// ## Examples
    ///
    /// ### Basic Replacement
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const old_child = try Node.init(allocator, .element_node, "span");
    /// const new_child = try Node.init(allocator, .element_node, "p");
    ///
    /// _ = try parent.appendChild(old_child);
    /// const removed = try parent.replaceChild(new_child, old_child);
    /// // removed == old_child
    /// // parent now contains new_child instead
    /// ```
    ///
    /// ### Replacement in Middle of Children
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Node.init(allocator, .element_node, "a");
    /// const child2 = try Node.init(allocator, .element_node, "span");
    /// const child3 = try Node.init(allocator, .element_node, "b");
    ///
    /// _ = try parent.appendChild(child1);
    /// _ = try parent.appendChild(child2);
    /// _ = try parent.appendChild(child3);
    ///
    /// const new_middle = try Node.init(allocator, .element_node, "p");
    /// _ = try parent.replaceChild(new_middle, child2);
    /// // Order is now: child1, new_middle, child3
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.replaceChild().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-replacechild
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/replaceChild
    pub fn replaceChild(self: *Self, new_child: *Node, old_child: *Node) !*Node {
        // P0 Security Fix: Detect circular references before replacing child
        if (try self.wouldCreateCycle(new_child)) {
            return SecurityError.CircularReferenceDetected;
        }

        var index: ?usize = null;
        for (self.child_nodes.items.items, 0..) |child_ptr, i| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (child == old_child) {
                index = i;
                break;
            }
        }

        if (index == null) {
            return error.NotFoundError;
        }

        if (new_child.parent_node) |old_parent| {
            new_child.retain(); // Retain before removing to prevent deallocation
            _ = try old_parent.removeChild(new_child);
        }

        old_child.parent_node = null;
        self.child_nodes.items.items[index.?] = new_child;
        new_child.parent_node = self;
        old_child.release();

        return old_child;
    }

    /// Removes a child node from this node.
    ///
    /// ## Overview
    ///
    /// Removes old_child from this node's child list. The child's parent_node
    /// is set to null and its reference count is decremented.
    ///
    /// ## Parameters
    ///
    /// - `old_child`: The child node to remove
    ///
    /// ## Returns
    ///
    /// Returns the removed child node.
    ///
    /// ## Errors
    ///
    /// - `NotFoundError`: If old_child is not a child of this node
    ///
    /// ## Examples
    ///
    /// ### Basic Removal
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try parent.appendChild(child);
    ///
    /// const removed = try parent.removeChild(child);
    /// // removed == child
    /// // child is now detached from parent
    /// ```
    ///
    /// ### Remove from Multiple Children
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Node.init(allocator, .element_node, "span");
    /// const child2 = try Node.init(allocator, .element_node, "p");
    ///
    /// _ = try parent.appendChild(child1);
    /// _ = try parent.appendChild(child2);
    ///
    /// _ = try parent.removeChild(child1);
    /// // Only child2 remains in parent
    /// ```
    ///
    /// ## Memory Management
    ///
    /// After removal, the child's reference count is decremented. If this was the
    /// only reference, the child will be deallocated. If you want to keep the child
    /// alive, call retain() on it before removal.
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.removeChild().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-removechild
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild
    pub fn removeChild(self: *Self, old_child: *Node) !*Node {
        for (self.child_nodes.items.items, 0..) |child_ptr, i| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (child == old_child) {
                old_child.parent_node = null;
                self.child_nodes.remove(i);
                old_child.release();
                return old_child;
            }
        }
        return error.NotFoundError;
    }

    /// Returns true if the given node is a descendant of this node.
    ///
    /// ## Overview
    ///
    /// Checks whether the specified node is a descendant of this node. A node
    /// is considered a descendant if it is anywhere in the tree below this node,
    /// not just an immediate child.
    ///
    /// ## Parameters
    ///
    /// - `other`: The node to check, or null
    ///
    /// ## Returns
    ///
    /// - `true` if other is a descendant of this node
    /// - `false` if other is null or not a descendant
    ///
    /// ## Examples
    ///
    /// ### Check Direct Child
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try parent.appendChild(child);
    ///
    /// const contains_child = parent.contains(child);
    /// // contains_child == true
    /// ```
    ///
    /// ### Check Grandchild
    ///
    /// ```zig
    /// const grandparent = try Node.init(allocator, .element_node, "div");
    /// defer grandparent.release();
    ///
    /// const parent = try Node.init(allocator, .element_node, "section");
    /// const child = try Node.init(allocator, .element_node, "span");
    ///
    /// _ = try grandparent.appendChild(parent);
    /// _ = try parent.appendChild(child);
    ///
    /// const contains_grandchild = grandparent.contains(child);
    /// // contains_grandchild == true
    /// ```
    ///
    /// ### Check Non-Descendant
    ///
    /// ```zig
    /// const node1 = try Node.init(allocator, .element_node, "div");
    /// defer node1.release();
    ///
    /// const node2 = try Node.init(allocator, .element_node, "span");
    /// defer node2.release();
    ///
    /// const contains = node1.contains(node2);
    /// // contains == false
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.contains().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-contains
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/contains
    pub fn contains(self: *const Self, other: ?*const Node) bool {
        if (other == null) return false;
        var current = other;
        while (current) |node| {
            if (node == self) return true;
            current = node.parent_node;
        }
        return false;
    }

    /// Compares the position of this node against another node.
    ///
    /// ## Overview
    ///
    /// Returns a bitmask indicating the relative position of the specified node
    /// with respect to this node in the document. This is useful for determining
    /// tree relationships and document order.
    ///
    /// ## Parameters
    ///
    /// - `other`: The node to compare against
    ///
    /// ## Returns
    ///
    /// A DocumentPosition struct with flags indicating the relationship:
    /// - `disconnected`: Nodes are in different trees
    /// - `preceding`: Other node comes before this node
    /// - `following`: Other node comes after this node
    /// - `contains`: This node contains other node
    /// - `contained_by`: This node is contained by other node
    /// - `implementation_specific`: Position is implementation-dependent
    ///
    /// ## Examples
    ///
    /// ### Parent-Child Relationship
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try parent.appendChild(child);
    ///
    /// const pos = parent.compareDocumentPosition(child);
    /// // pos.contains == true
    /// // pos.following == true
    /// ```
    ///
    /// ### Disconnected Nodes
    ///
    /// ```zig
    /// const node1 = try Node.init(allocator, .element_node, "div");
    /// defer node1.release();
    ///
    /// const node2 = try Node.init(allocator, .element_node, "span");
    /// defer node2.release();
    ///
    /// const pos = node1.compareDocumentPosition(node2);
    /// // pos.disconnected == true
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.compareDocumentPosition().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-comparedocumentposition
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/compareDocumentPosition
    pub fn compareDocumentPosition(self: *const Self, other: *const Node) DocumentPosition {
        if (self == other) {
            return .{};
        }

        var pos = DocumentPosition{};

        if (self.contains(other)) {
            pos.contains = true;
            pos.following = true;
            return pos;
        }

        if (other.contains(self)) {
            pos.contained_by = true;
            pos.preceding = true;
            return pos;
        }

        const self_ancestors = self.getAncestors(self.allocator) catch {
            pos.disconnected = true;
            return pos;
        };
        defer self.allocator.free(self_ancestors);

        const other_ancestors = other.getAncestors(other.allocator) catch {
            pos.disconnected = true;
            return pos;
        };
        defer other.allocator.free(other_ancestors);

        var common_ancestor: ?*const Node = null;
        for (self_ancestors) |self_anc| {
            for (other_ancestors) |other_anc| {
                if (self_anc == other_anc) {
                    common_ancestor = self_anc;
                    break;
                }
            }
            if (common_ancestor != null) break;
        }

        if (common_ancestor == null) {
            pos.disconnected = true;
            pos.implementation_specific = true;
            return pos;
        }

        pos.preceding = true;
        return pos;
    }

    /// Helper function to get all ancestors of this node.
    ///
    /// ## Overview
    ///
    /// Collects all ancestor nodes from this node up to the root. Used internally
    /// by compareDocumentPosition() to find common ancestors.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the result array
    ///
    /// ## Returns
    ///
    /// Returns a slice of ancestor nodes from immediate parent to root.
    ///
    /// ## Memory
    ///
    /// The caller must free the returned slice using allocator.free().
    fn getAncestors(self: *const Self, allocator: std.mem.Allocator) ![]const *const Node {
        var ancestors = std.ArrayList(*const Node){};
        var current: ?*const Node = self.parent_node;
        while (current) |node| {
            try ancestors.append(allocator, node);
            current = node.parent_node;
        }
        return ancestors.toOwnedSlice(allocator);
    }

    /// Creates a copy of this node, optionally including its descendants.
    ///
    /// ## Overview
    ///
    /// Creates a duplicate of this node. If deep is true, recursively clones
    /// all descendant nodes as well. The clone is a new node with ref_count = 1
    /// and no parent.
    ///
    /// ## Parameters
    ///
    /// - `deep`: If true, recursively clone all descendants; if false, clone only this node
    ///
    /// ## Returns
    ///
    /// Returns a pointer to the newly created clone.
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If allocation fails during cloning
    ///
    /// ## Examples
    ///
    /// ### Shallow Clone
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "div");
    /// defer node.release();
    ///
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try node.appendChild(child);
    ///
    /// const clone = try node.cloneNode(false);
    /// defer clone.release();
    /// // clone has same type and name but no children
    /// ```
    ///
    /// ### Deep Clone
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "div");
    /// defer node.release();
    ///
    /// const child = try Node.init(allocator, .element_node, "span");
    /// _ = try node.appendChild(child);
    ///
    /// const clone = try node.cloneNode(true);
    /// defer clone.release();
    /// // clone has same structure with all children cloned
    /// ```
    ///
    /// ## Cloned Properties
    ///
    /// The clone includes:
    /// - node_type
    /// - node_name
    /// - node_value (if present)
    /// - All children (if deep is true)
    ///
    /// The clone does NOT include:
    /// - parent_node (always null)
    /// - Event listeners
    /// - User data
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.cloneNode().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-clonenode
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/cloneNode
    pub fn cloneNode(self: *const Self, deep: bool) !*Node {
        return self.cloneNodeWithDepth(deep, 0);
    }

    /// Internal helper for cloneNode with depth tracking (P0 Security)
    fn cloneNodeWithDepth(self: *const Self, deep: bool, current_depth: usize) !*Node {
        // P0 Security Fix: Prevent stack overflow from deep trees
        if (current_depth >= SecurityLimits.max_tree_depth) {
            return SecurityError.MaxTreeDepthExceeded;
        }

        const clone = try Node.init(self.allocator, self.node_type, self.node_name);

        if (self.node_value) |value| {
            clone.node_value = try self.allocator.dupe(u8, value);
        }

        if (deep) {
            for (self.child_nodes.items.items) |child_ptr| {
                const child: *Node = @ptrCast(@alignCast(child_ptr));
                const child_clone = try child.cloneNodeWithDepth(true, current_depth + 1);
                _ = try clone.appendChild(child_clone);
            }
        }

        return clone;
    }

    /// Normalizes the node and its descendants.
    ///
    /// ## Overview
    ///
    /// Puts all text nodes in the full depth of the sub-tree underneath this node
    /// into a "normal" form where only structure (e.g., elements, comments,
    /// processing instructions, CDATA sections) separates Text nodes.
    ///
    /// ## Behavior
    ///
    /// 1. Removes empty text nodes
    /// 2. Combines adjacent text nodes into single nodes
    /// 3. Recursively normalizes all descendant elements
    ///
    /// ## Examples
    ///
    /// ### Combining Adjacent Text Nodes
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const text1 = try Node.init(allocator, .text_node, "#text");
    /// text1.node_value = try allocator.dupe(u8, "Hello ");
    ///
    /// const text2 = try Node.init(allocator, .text_node, "#text");
    /// text2.node_value = try allocator.dupe(u8, "World");
    ///
    /// _ = try parent.appendChild(text1);
    /// _ = try parent.appendChild(text2);
    /// // parent has 2 text children
    ///
    /// parent.normalize();
    /// // parent now has 1 text child with value "Hello World"
    /// ```
    ///
    /// ### Removing Empty Text Nodes
    ///
    /// ```zig
    /// const parent = try Node.init(allocator, .element_node, "div");
    /// defer parent.release();
    ///
    /// const empty_text = try Node.init(allocator, .text_node, "#text");
    /// empty_text.node_value = try allocator.dupe(u8, "");
    ///
    /// _ = try parent.appendChild(empty_text);
    ///
    /// parent.normalize();
    /// // empty_text has been removed
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.normalize().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-normalize
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/normalize
    pub fn normalize(self: *Self) void {
        self.normalizeWithDepth(0);
    }

    /// Internal helper for normalize with depth tracking (P0 Security)
    fn normalizeWithDepth(self: *Self, current_depth: usize) void {
        // P0 Security Fix: Prevent stack overflow from deep trees
        if (current_depth >= SecurityLimits.max_tree_depth) {
            // Silently stop recursion at max depth to match normalize's void return
            return;
        }

        var i: usize = 0;
        while (i < self.child_nodes.length()) {
            const child_ptr = self.child_nodes.item(i) orelse {
                i += 1;
                continue;
            };
            const child: *Node = @ptrCast(@alignCast(child_ptr));

            if (child.node_type == .text_node) {
                if (child.node_value) |value| {
                    if (value.len == 0) {
                        _ = self.removeChild(child) catch {};
                        continue;
                    }
                }

                while (i + 1 < self.child_nodes.length()) {
                    const next_ptr = self.child_nodes.item(i + 1) orelse break;
                    const next: *Node = @ptrCast(@alignCast(next_ptr));

                    if (next.node_type != .text_node) break;

                    if (child.node_value) |child_val| {
                        if (next.node_value) |next_val| {
                            const combined = std.fmt.allocPrint(
                                self.allocator,
                                "{s}{s}",
                                .{ child_val, next_val },
                            ) catch break;

                            self.allocator.free(child_val);
                            child.node_value = combined;
                        }
                    }

                    _ = self.removeChild(next) catch break;
                }
            } else {
                child.normalizeWithDepth(current_depth + 1);
            }

            i += 1;
        }
    }

    /// Returns true if this node is equal to another node.
    ///
    /// ## Overview
    ///
    /// Tests whether two nodes are equal. Two nodes are equal if they have the
    /// same type, name, value, and children. This is a deep comparison that
    /// recursively checks all descendants.
    ///
    /// ## Parameters
    ///
    /// - `other`: The node to compare with, or null
    ///
    /// ## Returns
    ///
    /// - `true` if the nodes are equal (same structure and content)
    /// - `false` if other is null or the nodes differ
    ///
    /// ## Comparison Criteria
    ///
    /// Two nodes are equal if ALL of the following are true:
    /// - Same node_type
    /// - Same node_name
    /// - Same node_value (both null or both same string)
    /// - Same number of children
    /// - All children are equal (recursive comparison)
    ///
    /// ## Examples
    ///
    /// ### Equal Nodes
    ///
    /// ```zig
    /// const node1 = try Node.init(allocator, .element_node, "div");
    /// defer node1.release();
    ///
    /// const node2 = try Node.init(allocator, .element_node, "div");
    /// defer node2.release();
    ///
    /// const are_equal = node1.isEqualNode(node2);
    /// // are_equal == true
    /// ```
    ///
    /// ### Different Node Types
    ///
    /// ```zig
    /// const node1 = try Node.init(allocator, .element_node, "div");
    /// defer node1.release();
    ///
    /// const node2 = try Node.init(allocator, .text_node, "div");
    /// defer node2.release();
    ///
    /// const are_equal = node1.isEqualNode(node2);
    /// // are_equal == false
    /// ```
    ///
    /// ### Equal Trees
    ///
    /// ```zig
    /// const tree1 = try Node.init(allocator, .element_node, "div");
    /// defer tree1.release();
    /// const child1 = try Node.init(allocator, .element_node, "span");
    /// _ = try tree1.appendChild(child1);
    ///
    /// const tree2 = try Node.init(allocator, .element_node, "div");
    /// defer tree2.release();
    /// const child2 = try Node.init(allocator, .element_node, "span");
    /// _ = try tree2.appendChild(child2);
    ///
    /// const are_equal = tree1.isEqualNode(tree2);
    /// // are_equal == true
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.isEqualNode().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-isequalnode
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/isEqualNode
    pub fn isEqualNode(self: *const Self, other: ?*const Node) bool {
        if (other == null) return false;
        const other_node = other.?;

        if (self.node_type != other_node.node_type) return false;
        if (!std.mem.eql(u8, self.node_name, other_node.node_name)) return false;

        if (self.node_value) |self_val| {
            if (other_node.node_value) |other_val| {
                if (!std.mem.eql(u8, self_val, other_val)) return false;
            } else {
                return false;
            }
        } else if (other_node.node_value != null) {
            return false;
        }

        if (self.child_nodes.length() != other_node.child_nodes.length()) return false;

        for (self.child_nodes.items.items, 0..) |child_ptr, i| {
            const self_child: *Node = @ptrCast(@alignCast(child_ptr));
            const other_child_ptr = other_node.child_nodes.item(i) orelse return false;
            const other_child: *Node = @ptrCast(@alignCast(other_child_ptr));

            if (!self_child.isEqualNode(other_child)) return false;
        }

        return true;
    }

    /// Returns true if this node is the same as another node (reference equality).
    ///
    /// ## Overview
    ///
    /// Tests whether two node references point to the exact same node object.
    /// This is a simple pointer comparison, unlike isEqualNode() which performs
    /// a deep structural comparison.
    ///
    /// ## Parameters
    ///
    /// - `other`: The node to compare with, or null
    ///
    /// ## Returns
    ///
    /// - `true` if both references point to the same node object
    /// - `false` if other is null or points to a different node
    ///
    /// ## Examples
    ///
    /// ### Same Node
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "div");
    /// defer node.release();
    ///
    /// const same = node.isSameNode(node);
    /// // same == true
    /// ```
    ///
    /// ### Different Nodes
    ///
    /// ```zig
    /// const node1 = try Node.init(allocator, .element_node, "div");
    /// defer node1.release();
    ///
    /// const node2 = try Node.init(allocator, .element_node, "div");
    /// defer node2.release();
    ///
    /// const same = node1.isSameNode(node2);
    /// // same == false (even though they're equal)
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.isSameNode().
    /// Note: This method is a legacy alias for the === operator.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-issamenode
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/isSameNode
    pub fn isSameNode(self: *const Self, other: ?*const Node) bool {
        return self == other;
    }

    /// Looks up the namespace prefix associated with a namespace URI.
    ///
    /// ## Overview
    ///
    /// This is a stub implementation that currently returns null. Namespace
    /// support will be implemented in a future version.
    ///
    /// ## Parameters
    ///
    /// - `namespace`: The namespace URI to look up
    ///
    /// ## Returns
    ///
    /// Currently always returns null.
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.lookupPrefix().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-lookupprefix
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/lookupPrefix
    pub fn lookupPrefix(self: *const Self, namespace: ?[]const u8) ?[]const u8 {
        _ = self;
        _ = namespace;
        return null;
    }

    /// Looks up the namespace URI associated with a prefix.
    ///
    /// ## Overview
    ///
    /// This is a stub implementation that currently returns null. Namespace
    /// support will be implemented in a future version.
    ///
    /// ## Parameters
    ///
    /// - `prefix`: The namespace prefix to look up
    ///
    /// ## Returns
    ///
    /// Currently always returns null.
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.lookupNamespaceURI().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-lookupnamespaceuri
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/lookupNamespaceURI
    pub fn lookupNamespaceURI(self: *const Self, prefix: ?[]const u8) ?[]const u8 {
        _ = self;
        _ = prefix;
        return null;
    }

    /// Checks if a namespace is the default namespace.
    ///
    /// ## Overview
    ///
    /// This is a stub implementation that currently returns false. Namespace
    /// support will be implemented in a future version.
    ///
    /// ## Parameters
    ///
    /// - `namespace`: The namespace URI to check
    ///
    /// ## Returns
    ///
    /// Currently always returns false.
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.isDefaultNamespace().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-isdefaultnamespace
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/isDefaultNamespace
    pub fn isDefaultNamespace(self: *const Self, namespace: ?[]const u8) bool {
        _ = self;
        _ = namespace;
        return false;
    }

    /// Adds an event listener to this node.
    ///
    /// ## Overview
    ///
    /// Registers an event listener callback for a specific event type. This is
    /// a convenience wrapper around EventTarget.addEventListener().
    ///
    /// ## Parameters
    ///
    /// - `event_type`: The type of event to listen for (e.g., "click", "load")
    /// - `callback`: The function to call when the event occurs
    /// - `options`: Options controlling listener behavior (capture, once, passive)
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If allocation fails while adding the listener
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "button");
    /// defer node.release();
    ///
    /// try node.addEventListener("click", handleClick, .{});
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener
    pub fn addEventListener(
        self: *Self,
        event_type: []const u8,
        callback: *const fn (event: *Event) void,
        options: EventTarget.AddEventListenerOptions,
    ) !void {
        try self.event_target.addEventListener(event_type, callback, options);
    }

    /// Removes an event listener from this node.
    ///
    /// ## Overview
    ///
    /// Unregisters a previously registered event listener. This is a convenience
    /// wrapper around EventTarget.removeEventListener().
    ///
    /// ## Parameters
    ///
    /// - `event_type`: The type of event the listener was registered for
    /// - `callback`: The callback function that was registered
    /// - `capture`: Whether the listener was registered for the capture phase
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "button");
    /// defer node.release();
    ///
    /// try node.addEventListener("click", handleClick, .{});
    /// node.removeEventListener("click", handleClick, false);
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-eventtarget-removeeventlistener
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/removeEventListener
    pub fn removeEventListener(
        self: *Self,
        event_type: []const u8,
        callback: *const fn (event: *Event) void,
        capture: bool,
    ) void {
        self.event_target.removeEventListener(event_type, callback, capture);
    }

    /// Dispatches an event to this node.
    ///
    /// ## Overview
    ///
    /// Dispatches an event at this node, invoking all registered event listeners
    /// in the appropriate order. This is a convenience wrapper around
    /// EventTarget.dispatchEvent().
    ///
    /// ## Parameters
    ///
    /// - `event`: The event to dispatch
    ///
    /// ## Returns
    ///
    /// Returns false if the event is cancelable and preventDefault() was called;
    /// otherwise true.
    ///
    /// ## Errors
    ///
    /// - May propagate errors from event listener callbacks
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "div");
    /// defer node.release();
    ///
    /// const event = try Event.init(allocator, "custom");
    /// defer event.release();
    ///
    /// const result = try node.dispatchEvent(event);
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/dispatchEvent
    pub fn dispatchEvent(self: *Self, event: *Event) !bool {
        return try self.event_target.dispatchEvent(event);
    }

    /// Returns the root node of the tree containing this node.
    ///
    /// ## Overview
    ///
    /// Traverses up the tree from this node to find and return the root node
    /// (the topmost ancestor that has no parent).
    ///
    /// ## Returns
    ///
    /// Returns the root node of the tree. If this node has no parent, returns
    /// this node itself.
    ///
    /// ## Examples
    ///
    /// ### Node in Tree
    ///
    /// ```zig
    /// const root = try Node.init(allocator, .element_node, "html");
    /// defer root.release();
    ///
    /// const body = try Node.init(allocator, .element_node, "body");
    /// const div = try Node.init(allocator, .element_node, "div");
    ///
    /// _ = try root.appendChild(body);
    /// _ = try body.appendChild(div);
    ///
    /// const div_root = div.getRootNode();
    /// // div_root == root
    /// ```
    ///
    /// ### Isolated Node
    ///
    /// ```zig
    /// const node = try Node.init(allocator, .element_node, "div");
    /// defer node.release();
    ///
    /// const root = node.getRootNode();
    /// // root == node (node is its own root)
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.getRootNode().
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-getrootnode
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/getRootNode
    pub fn getRootNode(self: *const Self) *const Node {
        var root = self;
        while (root.parent_node) |parent| {
            root = parent;
        }
        return root;
    }

    /// Returns the text content of this node and its descendants.
    ///
    /// ## Overview
    ///
    /// Retrieves the textual content of this node and all its descendant text
    /// nodes, concatenated together. For text and comment nodes, returns their
    /// value directly. For other nodes, recursively collects all descendant text.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the result string
    ///
    /// ## Returns
    ///
    /// Returns the concatenated text content, or null if there is no text content.
    /// The caller must free the returned string.
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If allocation fails
    ///
    /// ## Examples
    ///
    /// ### Element with Text
    ///
    /// ```zig
    /// const div = try Node.init(allocator, .element_node, "div");
    /// defer div.release();
    ///
    /// const text = try Node.init(allocator, .text_node, "#text");
    /// text.node_value = try allocator.dupe(u8, "Hello World");
    /// _ = try div.appendChild(text);
    ///
    /// const content = try div.getTextContent(allocator);
    /// defer allocator.free(content.?);
    /// // content == "Hello World"
    /// ```
    ///
    /// ### Nested Elements
    ///
    /// ```zig
    /// const div = try Node.init(allocator, .element_node, "div");
    /// defer div.release();
    ///
    /// const span = try Node.init(allocator, .element_node, "span");
    /// const text1 = try Node.init(allocator, .text_node, "#text");
    /// text1.node_value = try allocator.dupe(u8, "Hello ");
    /// const text2 = try Node.init(allocator, .text_node, "#text");
    /// text2.node_value = try allocator.dupe(u8, "World");
    ///
    /// _ = try div.appendChild(text1);
    /// _ = try div.appendChild(span);
    /// _ = try span.appendChild(text2);
    ///
    /// const content = try div.getTextContent(allocator);
    /// defer allocator.free(content.?);
    /// // content == "Hello World"
    /// ```
    ///
    /// ## Memory Management
    ///
    /// The returned string is allocated and must be freed by the caller.
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.textContent getter.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-textcontent
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent
    pub fn getTextContent(self: *const Self, allocator: std.mem.Allocator) !?[]const u8 {
        if (self.node_type == .text_node or self.node_type == .comment_node) {
            if (self.node_value) |value| {
                return try allocator.dupe(u8, value);
            }
            return null;
        }

        var text_parts = std.ArrayList([]const u8){};
        defer text_parts.deinit(allocator);

        try self.collectTextContent(allocator, &text_parts);

        if (text_parts.items.len == 0) {
            return null;
        }

        return try std.mem.concat(allocator, u8, text_parts.items);
    }

    /// Helper function to recursively collect text content.
    ///
    /// ## Overview
    ///
    /// Recursively traverses the tree and collects text from all text and
    /// comment nodes. Used internally by getTextContent().
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `parts`: ArrayList to append text parts to
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If growing the list fails
    fn collectTextContent(self: *const Self, allocator: std.mem.Allocator, parts: *std.ArrayList([]const u8)) !void {
        return self.collectTextContentWithDepth(allocator, parts, 0);
    }

    /// Internal helper for collectTextContent with depth tracking (P0 Security)
    fn collectTextContentWithDepth(self: *const Self, allocator: std.mem.Allocator, parts: *std.ArrayList([]const u8), current_depth: usize) !void {
        // P0 Security Fix: Prevent stack overflow from deep trees
        if (current_depth >= SecurityLimits.max_tree_depth) {
            return SecurityError.MaxTreeDepthExceeded;
        }

        if (self.node_type == .text_node or self.node_type == .comment_node) {
            if (self.node_value) |value| {
                try parts.append(allocator, value);
            }
        }

        for (self.child_nodes.items.items) |child_ptr| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            try child.collectTextContentWithDepth(allocator, parts, current_depth + 1);
        }
    }

    /// Sets the text content of this node, replacing all children.
    ///
    /// ## Overview
    ///
    /// Removes all child nodes and replaces them with a single text node
    /// containing the specified text. If content is null, all children are
    /// removed and no text node is added.
    ///
    /// ## Parameters
    ///
    /// - `content`: The text content to set, or null to clear all children
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If allocation fails
    /// - `NotFoundError`: If removal fails (should not happen in normal use)
    ///
    /// ## Examples
    ///
    /// ### Set Text Content
    ///
    /// ```zig
    /// const div = try Node.init(allocator, .element_node, "div");
    /// defer div.release();
    ///
    /// try div.setTextContent("Hello World");
    /// // div now has one text child with value "Hello World"
    /// ```
    ///
    /// ### Clear Content
    ///
    /// ```zig
    /// const div = try Node.init(allocator, .element_node, "div");
    /// defer div.release();
    ///
    /// try div.setTextContent("Hello");
    /// try div.setTextContent(null);
    /// // div now has no children
    /// ```
    ///
    /// ### Replace Complex Structure
    ///
    /// ```zig
    /// const div = try Node.init(allocator, .element_node, "div");
    /// defer div.release();
    ///
    /// const span = try Node.init(allocator, .element_node, "span");
    /// _ = try div.appendChild(span);
    ///
    /// try div.setTextContent("New content");
    /// // span is removed, replaced with text node
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Implements WHATWG DOM Standard §4.4 Node.textContent setter.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-node-textcontent
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Node/textContent
    pub fn setTextContent(self: *Self, content: ?[]const u8) !void {
        while (self.child_nodes.length() > 0) {
            const child_ptr = self.child_nodes.item(0) orelse break;
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            _ = try self.removeChild(child);
        }

        if (content) |text| {
            const text_node = try Node.init(self.allocator, .text_node, "#text");
            text_node.node_value = try self.allocator.dupe(u8, text);
            _ = try self.appendChild(text_node);
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Node creation and basic properties" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");
    defer node.release();

    try std.testing.expectEqual(NodeType.element_node, node.node_type);
    try std.testing.expectEqualStrings("div", node.node_name);
    try std.testing.expectEqual(@as(usize, 1), node.ref_count);
}

test "Node appendChild and removeChild" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child1 = try Node.init(allocator, .element_node, "span");
    const child2 = try Node.init(allocator, .element_node, "p");

    _ = try parent.appendChild(child1);
    _ = try parent.appendChild(child2);

    try std.testing.expectEqual(@as(usize, 2), parent.child_nodes.length());
    try std.testing.expect(parent.hasChildNodes());

    const removed = try parent.removeChild(child1);
    try std.testing.expectEqual(child1, removed);
    try std.testing.expectEqual(@as(usize, 1), parent.child_nodes.length());
}

test "Node tree traversal" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child1 = try Node.init(allocator, .element_node, "span");
    const child2 = try Node.init(allocator, .element_node, "p");
    const child3 = try Node.init(allocator, .element_node, "a");

    _ = try parent.appendChild(child1);
    _ = try parent.appendChild(child2);
    _ = try parent.appendChild(child3);

    try std.testing.expectEqual(child1, parent.firstChild());
    try std.testing.expectEqual(child3, parent.lastChild());
    try std.testing.expectEqual(child2, child1.nextSibling());
    try std.testing.expectEqual(child2, child3.previousSibling());
}

test "Node cloneNode shallow" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");
    defer node.release();

    const child = try Node.init(allocator, .element_node, "span");
    _ = try node.appendChild(child);

    const clone = try node.cloneNode(false);
    defer clone.release();

    try std.testing.expectEqualStrings(node.node_name, clone.node_name);
    try std.testing.expectEqual(node.node_type, clone.node_type);
    try std.testing.expectEqual(@as(usize, 0), clone.child_nodes.length());
}

test "Node cloneNode deep" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");
    defer node.release();

    const child = try Node.init(allocator, .element_node, "span");
    _ = try node.appendChild(child);

    const clone = try node.cloneNode(true);
    defer clone.release();

    try std.testing.expectEqual(@as(usize, 1), clone.child_nodes.length());
}

test "Node contains" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .element_node, "span");
    _ = try parent.appendChild(child);

    const grandchild = try Node.init(allocator, .element_node, "a");
    _ = try child.appendChild(grandchild);

    try std.testing.expect(parent.contains(child));
    try std.testing.expect(parent.contains(grandchild));
    try std.testing.expect(!child.contains(parent));
}

test "Node textContent" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");
    defer node.release();

    try node.setTextContent("Hello World");
    try std.testing.expectEqual(@as(usize, 1), node.child_nodes.length());

    const text = try node.getTextContent(allocator);
    defer if (text) |t| allocator.free(t);

    try std.testing.expect(text != null);
    try std.testing.expectEqualStrings("Hello World", text.?);
}

test "Node insertBefore with valid reference" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child1 = try Node.init(allocator, .element_node, "first");
    const child2 = try Node.init(allocator, .element_node, "second");
    const new_child = try Node.init(allocator, .element_node, "inserted");

    _ = try parent.appendChild(child1);
    _ = try parent.appendChild(child2);

    _ = try parent.insertBefore(new_child, child2);

    try std.testing.expectEqual(@as(usize, 3), parent.child_nodes.length());
    try std.testing.expectEqual(child1, parent.firstChild());
    try std.testing.expectEqual(new_child, child1.nextSibling());
    try std.testing.expectEqual(child2, new_child.nextSibling());
}

test "Node insertBefore with null reference (appends)" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child1 = try Node.init(allocator, .element_node, "first");
    const child2 = try Node.init(allocator, .element_node, "second");

    _ = try parent.appendChild(child1);
    _ = try parent.insertBefore(child2, null);

    try std.testing.expectEqual(@as(usize, 2), parent.child_nodes.length());
    try std.testing.expectEqual(child2, parent.lastChild());
}

test "Node insertBefore with invalid reference" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .element_node, "child");
    const not_a_child = try Node.init(allocator, .element_node, "other");
    defer not_a_child.release();

    const result = parent.insertBefore(child, not_a_child);
    try std.testing.expectError(error.NotFoundError, result);
    child.release();
}

test "Node replaceChild valid" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const old_child = try Node.init(allocator, .element_node, "old");
    const new_child = try Node.init(allocator, .element_node, "new");

    _ = try parent.appendChild(old_child);

    const returned = try parent.replaceChild(new_child, old_child);

    try std.testing.expectEqual(old_child, returned);
    try std.testing.expectEqual(@as(usize, 1), parent.child_nodes.length());
    try std.testing.expectEqual(new_child, parent.firstChild());
}

test "Node replaceChild invalid" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const new_child = try Node.init(allocator, .element_node, "new");
    const not_a_child = try Node.init(allocator, .element_node, "other");
    defer not_a_child.release();

    const result = parent.replaceChild(new_child, not_a_child);
    try std.testing.expectError(error.NotFoundError, result);
    new_child.release();
}

test "Node reference counting with retain and release" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");

    try std.testing.expectEqual(@as(usize, 1), node.ref_count);

    node.retain();
    try std.testing.expectEqual(@as(usize, 2), node.ref_count);

    node.release();
    try std.testing.expectEqual(@as(usize, 1), node.ref_count);

    node.release();
    // Node should be deallocated now
}

test "Node compareDocumentPosition - same node" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");
    defer node.release();

    const pos = node.compareDocumentPosition(node);

    try std.testing.expect(!pos.disconnected);
    try std.testing.expect(!pos.preceding);
    try std.testing.expect(!pos.following);
    try std.testing.expect(!pos.contains);
    try std.testing.expect(!pos.contained_by);
}

test "Node compareDocumentPosition - parent contains child" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .element_node, "span");
    _ = try parent.appendChild(child);

    const pos = parent.compareDocumentPosition(child);

    try std.testing.expect(pos.contains);
    try std.testing.expect(pos.following);
}

test "Node compareDocumentPosition - child contained by parent" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const child = try Node.init(allocator, .element_node, "span");
    _ = try parent.appendChild(child);

    const pos = child.compareDocumentPosition(parent);

    try std.testing.expect(pos.contained_by);
    try std.testing.expect(pos.preceding);
}

test "Node compareDocumentPosition - disconnected nodes" {
    const allocator = std.testing.allocator;

    const node1 = try Node.init(allocator, .element_node, "div");
    defer node1.release();

    const node2 = try Node.init(allocator, .element_node, "span");
    defer node2.release();

    const pos = node1.compareDocumentPosition(node2);

    try std.testing.expect(pos.disconnected);
}

test "Node normalize removes empty text nodes" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const empty_text = try Node.init(allocator, .text_node, "#text");
    empty_text.node_value = try allocator.dupe(u8, "");
    _ = try parent.appendChild(empty_text);

    try std.testing.expectEqual(@as(usize, 1), parent.child_nodes.length());

    parent.normalize();

    try std.testing.expectEqual(@as(usize, 0), parent.child_nodes.length());
}

test "Node normalize combines adjacent text nodes" {
    const allocator = std.testing.allocator;

    const parent = try Node.init(allocator, .element_node, "div");
    defer parent.release();

    const text1 = try Node.init(allocator, .text_node, "#text");
    text1.node_value = try allocator.dupe(u8, "Hello ");

    const text2 = try Node.init(allocator, .text_node, "#text");
    text2.node_value = try allocator.dupe(u8, "World");

    _ = try parent.appendChild(text1);
    _ = try parent.appendChild(text2);

    try std.testing.expectEqual(@as(usize, 2), parent.child_nodes.length());

    parent.normalize();

    try std.testing.expectEqual(@as(usize, 1), parent.child_nodes.length());

    const remaining = parent.firstChild().?;
    try std.testing.expectEqualStrings("Hello World", remaining.node_value.?);
}

test "Node isEqualNode - equal simple nodes" {
    const allocator = std.testing.allocator;

    const node1 = try Node.init(allocator, .element_node, "div");
    defer node1.release();

    const node2 = try Node.init(allocator, .element_node, "div");
    defer node2.release();

    try std.testing.expect(node1.isEqualNode(node2));
}

test "Node isEqualNode - different types" {
    const allocator = std.testing.allocator;

    const node1 = try Node.init(allocator, .element_node, "div");
    defer node1.release();

    const node2 = try Node.init(allocator, .text_node, "div");
    defer node2.release();

    try std.testing.expect(!node1.isEqualNode(node2));
}

test "Node isEqualNode - different names" {
    const allocator = std.testing.allocator;

    const node1 = try Node.init(allocator, .element_node, "div");
    defer node1.release();

    const node2 = try Node.init(allocator, .element_node, "span");
    defer node2.release();

    try std.testing.expect(!node1.isEqualNode(node2));
}

test "Node isEqualNode - equal trees" {
    const allocator = std.testing.allocator;

    const tree1 = try Node.init(allocator, .element_node, "div");
    defer tree1.release();
    const child1 = try Node.init(allocator, .element_node, "span");
    _ = try tree1.appendChild(child1);

    const tree2 = try Node.init(allocator, .element_node, "div");
    defer tree2.release();
    const child2 = try Node.init(allocator, .element_node, "span");
    _ = try tree2.appendChild(child2);

    try std.testing.expect(tree1.isEqualNode(tree2));
}

test "Node isSameNode - same reference" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");
    defer node.release();

    try std.testing.expect(node.isSameNode(node));
}

test "Node isSameNode - different references" {
    const allocator = std.testing.allocator;

    const node1 = try Node.init(allocator, .element_node, "div");
    defer node1.release();

    const node2 = try Node.init(allocator, .element_node, "div");
    defer node2.release();

    try std.testing.expect(!node1.isSameNode(node2));
}

test "Node getRootNode - node in tree" {
    const allocator = std.testing.allocator;

    const root = try Node.init(allocator, .element_node, "html");
    defer root.release();

    const body = try Node.init(allocator, .element_node, "body");
    const div = try Node.init(allocator, .element_node, "div");

    _ = try root.appendChild(body);
    _ = try body.appendChild(div);

    const found_root = div.getRootNode();
    try std.testing.expectEqual(root, found_root);
}

test "Node getRootNode - isolated node" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");
    defer node.release();

    const root = node.getRootNode();
    try std.testing.expectEqual(node, root);
}

test "Node moving between parents" {
    const allocator = std.testing.allocator;

    const parent1 = try Node.init(allocator, .element_node, "div");
    defer parent1.release();

    const parent2 = try Node.init(allocator, .element_node, "section");
    defer parent2.release();

    const child = try Node.init(allocator, .element_node, "span");

    _ = try parent1.appendChild(child);
    try std.testing.expectEqual(@as(usize, 1), parent1.child_nodes.length());
    try std.testing.expectEqual(@as(usize, 0), parent2.child_nodes.length());
    try std.testing.expectEqual(@as(usize, 1), child.ref_count); // parent1 owns it

    _ = try parent2.appendChild(child);
    try std.testing.expectEqual(@as(usize, 0), parent1.child_nodes.length());
    try std.testing.expectEqual(@as(usize, 1), parent2.child_nodes.length());
    try std.testing.expectEqual(@as(usize, 1), child.ref_count); // parent2 owns it now
}

test "Node complex textContent with nested elements" {
    const allocator = std.testing.allocator;

    const div = try Node.init(allocator, .element_node, "div");
    defer div.release();

    const text1 = try Node.init(allocator, .text_node, "#text");
    text1.node_value = try allocator.dupe(u8, "Hello ");

    const span = try Node.init(allocator, .element_node, "span");
    const text2 = try Node.init(allocator, .text_node, "#text");
    text2.node_value = try allocator.dupe(u8, "beautiful ");

    const text3 = try Node.init(allocator, .text_node, "#text");
    text3.node_value = try allocator.dupe(u8, "World");

    _ = try div.appendChild(text1);
    _ = try div.appendChild(span);
    _ = try span.appendChild(text2);
    _ = try div.appendChild(text3);

    const content = try div.getTextContent(allocator);
    defer allocator.free(content.?);

    try std.testing.expectEqualStrings("Hello beautiful World", content.?);
}

test "Node setTextContent clears existing children" {
    const allocator = std.testing.allocator;

    const div = try Node.init(allocator, .element_node, "div");
    defer div.release();

    const span = try Node.init(allocator, .element_node, "span");
    _ = try div.appendChild(span);

    try std.testing.expectEqual(@as(usize, 1), div.child_nodes.length());

    try div.setTextContent("New content");

    try std.testing.expectEqual(@as(usize, 1), div.child_nodes.length());

    const first_child = div.firstChild().?;
    try std.testing.expectEqual(NodeType.text_node, first_child.node_type);
    try std.testing.expectEqualStrings("New content", first_child.node_value.?);
}
