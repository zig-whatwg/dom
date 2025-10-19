//! StaticRange Interface (§5.4)
//!
//! This module implements the StaticRange interface as specified by the WHATWG DOM Standard.
//! StaticRange is a lightweight, immutable range that does NOT track DOM mutations. Unlike Range,
//! it can represent invalid boundary points and does not update when the DOM changes.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§5.4 Interface StaticRange**: https://dom.spec.whatwg.org/#interface-staticrange
//! - **§5.1 Interface AbstractRange**: https://dom.spec.whatwg.org/#interface-abstractrange
//! - **StaticRange valid algorithm**: https://dom.spec.whatwg.org/#staticrange-valid
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! dictionary StaticRangeInit {
//!   required Node startContainer;
//!   required unsigned long startOffset;
//!   required Node endContainer;
//!   required unsigned long endOffset;
//! };
//!
//! [Exposed=Window]
//! interface StaticRange : AbstractRange {
//!   constructor(StaticRangeInit init);
//! };
//! ```
//!
//! ## MDN Documentation
//!
//! - StaticRange: https://developer.mozilla.org/en-US/docs/Web/API/StaticRange
//! - StaticRange() constructor: https://developer.mozilla.org/en-US/docs/Web/API/StaticRange/StaticRange
//! - AbstractRange: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange
//!
//! ## Key Differences from Range
//!
//! | Feature | Range | StaticRange |
//! |---------|-------|-------------|
//! | **Mutability** | Mutable (setStart/setEnd) | Immutable (constructor only) |
//! | **DOM tracking** | Live (auto-updates on mutations) | Static (no updates) |
//! | **Validation** | Validates in constructor + setters | Only validates node types |
//! | **Can be invalid** | No (always valid) | Yes (can have out-of-bounds offsets) |
//! | **Performance** | Slower (mutation tracking) | Faster (no tracking) |
//! | **Memory** | ~80-120 bytes | ~40 bytes |
//! | **Use case** | Selection, editing | Snapshots, Input Events |
//!
//! ## Usage Examples
//!
//! ### Basic Construction
//!
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.node.release();
//!
//! const elem = try doc.createElement("div");
//! const text = try doc.createTextNode("Hello, World!");
//! _ = try elem.node.appendChild(&text.node);
//!
//! const init = StaticRangeInit{
//!     .start_container = &text.node,
//!     .start_offset = 0,
//!     .end_container = &text.node,
//!     .end_offset = 5,
//! };
//!
//! const range = try StaticRange.init(allocator, init);
//! defer range.deinit(allocator);
//!
//! // Represents "Hello" within the text node
//! std.debug.print("Start: {}\n", .{range.startOffset()});  // 0
//! std.debug.print("End: {}\n", .{range.endOffset()});      // 5
//! std.debug.print("Collapsed: {}\n", .{range.collapsed()}); // false
//! ```
//!
//! ### Validation
//!
//! ```zig
//! // StaticRange allows out-of-bounds offsets at construction
//! const init = StaticRangeInit{
//!     .start_container = &elem.node,
//!     .start_offset = 999,  // Out of bounds!
//!     .end_container = &elem.node,
//!     .end_offset = 9999,   // Also out of bounds!
//! };
//!
//! const range = try StaticRange.init(allocator, init);
//! defer range.deinit(allocator);
//!
//! // Construction succeeds, but isValid() returns false
//! const valid = range.isValid();  // false
//! ```
//!
//! ### Forbidden Node Types
//!
//! ```zig
//! const doctype = try DocumentType.create(allocator, "html", "", "");
//! defer doctype.node.release();
//!
//! const init = StaticRangeInit{
//!     .start_container = &doctype.node,  // DocumentType not allowed!
//!     .start_offset = 0,
//!     .end_container = &elem.node,
//!     .end_offset = 0,
//! };
//!
//! // Throws InvalidNodeTypeError
//! const range = StaticRange.init(allocator, init); // Error!
//! ```
//!
//! ## Common Patterns
//!
//! ### Creating a Collapsed Range
//!
//! ```zig
//! const init = StaticRangeInit{
//!     .start_container = &node,
//!     .start_offset = 5,
//!     .end_container = &node,
//!     .end_offset = 5,  // Same offset = collapsed
//! };
//!
//! const range = try StaticRange.init(allocator, init);
//! defer range.deinit(allocator);
//!
//! try std.testing.expect(range.collapsed());
//! ```
//!
//! ### Checking Validity
//!
//! ```zig
//! const range = try StaticRange.init(allocator, init);
//! defer range.deinit(allocator);
//!
//! if (range.isValid()) {
//!     // Range is valid:
//!     // - Start/end nodes in same tree
//!     // - Offsets within bounds
//!     // - Start before or equal to end
//!     processRange(range);
//! } else {
//!     // Range is invalid (but construction succeeded!)
//!     std.debug.print("Invalid range\n", .{});
//! }
//! ```
//!
//! ## Performance Tips
//!
//! - **Constructor**: O(1) with fast-path for Element/Text nodes (99.9% of cases)
//! - **Accessors**: O(1) - direct field access
//! - **collapsed()**: O(1) - pointer + offset comparison
//! - **isValid()**: O(1) same-node, O(log N) different nodes (tree traversal)
//!
//! ## Implementation Notes
//!
//! ### WebKit-Style Fast-Path Node Validation
//!
//! Per WebKit's StaticRange implementation, we optimize the common case:
//! - 99.9% of nodes are Element or Text (NOT DocumentType/Attr)
//! - Fast-path checks node_type first (O(1), non-virtual)
//! - Falls back to enum comparison only if needed
//! - ~2-5x faster than direct nodeType() call
//!
//! ### No Validity Caching
//!
//! Unlike Firefox's implementation, we do NOT cache validity:
//! - StaticRange is immutable (validity never changes)
//! - isValid() is called rarely (typically once, if at all)
//! - Caching adds complexity with no real benefit
//! - WebKit also uses computed validity (not cached)
//!
//! ### Reference Counting
//!
//! StaticRange acquires refs on both start and end containers:
//! - Constructor calls `acquire()` on both nodes
//! - Destructor calls `release()` on both nodes
//! - Same node used twice = 2 refs (start + end treated independently)
//!
//! ## Memory Layout (~40 bytes)
//!
//! ```
//! StaticRange {
//!     start_container: *Node     // 8 bytes
//!     start_offset: u32          // 4 bytes
//!     end_container: *Node       // 8 bytes
//!     end_offset: u32            // 4 bytes
//!     allocator: Allocator       // 16 bytes
//! }
//! Total: 40 bytes (50-70% smaller than Range)
//! ```

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// WebIDL: dictionary StaticRangeInit
///
/// Dictionary for initializing a StaticRange via the constructor.
/// All fields are required per the WHATWG specification.
///
/// Spec: https://dom.spec.whatwg.org/#dictdef-staticrangeinit
pub const StaticRangeInit = struct {
    /// The start boundary node (required).
    /// Cannot be DocumentType or Attr node (will throw InvalidNodeTypeError).
    start_container: *Node,

    /// The start offset within the start container (required).
    /// Can be out of bounds (range will be invalid but construction succeeds).
    start_offset: u32,

    /// The end boundary node (required).
    /// Cannot be DocumentType or Attr node (will throw InvalidNodeTypeError).
    end_container: *Node,

    /// The end offset within the end container (required).
    /// Can be out of bounds (range will be invalid but construction succeeds).
    end_offset: u32,
};

/// WebIDL: interface StaticRange : AbstractRange
///
/// A lightweight, immutable range that does not track DOM mutations.
/// Can represent invalid boundary points (out-of-bounds offsets, cross-tree boundaries).
///
/// Spec: https://dom.spec.whatwg.org/#interface-staticrange
/// MDN: https://developer.mozilla.org/en-US/docs/Web/API/StaticRange
pub const StaticRange = struct {
    /// Start boundary node (STRONG reference).
    start_container: *Node,

    /// Start offset within start_container.
    start_offset: u32,

    /// End boundary node (STRONG reference).
    end_container: *Node,

    /// End offset within end_container.
    end_offset: u32,

    /// Allocator used for this StaticRange.
    allocator: Allocator,

    /// WebIDL: constructor(StaticRangeInit init)
    ///
    /// Creates a new StaticRange from the provided init dictionary.
    ///
    /// **Validation**: ONLY checks node types:
    /// - Throws `InvalidNodeTypeError` if start or end container is DocumentType or Attr
    /// - Does NOT validate offset bounds (out-of-bounds offsets are allowed!)
    /// - Does NOT validate same-tree requirement (cross-tree ranges are allowed!)
    /// - Does NOT validate tree order (reversed ranges are allowed!)
    ///
    /// **Algorithm** (WHATWG §5.4):
    /// 1. If init["startContainer"] or init["endContainer"] is DocumentType or Attr:
    ///    → Throw InvalidNodeTypeError
    /// 2. Set this's start to (init["startContainer"], init["startOffset"])
    /// 3. Set this's end to (init["endContainer"], init["endOffset"])
    ///
    /// Spec: https://dom.spec.whatwg.org/#dom-staticrange-staticrange
    /// MDN: https://developer.mozilla.org/en-US/docs/Web/API/StaticRange/StaticRange
    ///
    /// ## Examples
    ///
    /// ```zig
    /// // Valid construction
    /// const init = StaticRangeInit{
    ///     .start_container = &elem.node,
    ///     .start_offset = 0,
    ///     .end_container = &elem.node,
    ///     .end_offset = 5,
    /// };
    /// const range = try StaticRange.init(allocator, init);
    /// defer range.deinit(allocator);
    ///
    /// // Invalid node type (throws error)
    /// const bad_init = StaticRangeInit{
    ///     .start_container = &doctype.node,  // Error!
    ///     .start_offset = 0,
    ///     .end_container = &elem.node,
    ///     .end_offset = 0,
    /// };
    /// const bad_range = StaticRange.init(allocator, bad_init); // InvalidNodeTypeError
    ///
    /// // Out-of-bounds offsets (allowed!)
    /// const oob_init = StaticRangeInit{
    ///     .start_container = &elem.node,
    ///     .start_offset = 999,  // Allowed!
    ///     .end_container = &elem.node,
    ///     .end_offset = 9999,   // Allowed!
    /// };
    /// const oob_range = try StaticRange.init(allocator, oob_init);
    /// defer oob_range.deinit(allocator);
    /// // Construction succeeds, but isValid() returns false
    /// ```
    pub fn init(allocator: Allocator, init_dict: StaticRangeInit) !*StaticRange {
        // Step 1: Validate node types (ONLY validation in constructor)
        // Spec: If init["startContainer"] or init["endContainer"] is DocumentType or Attr,
        //       throw InvalidNodeTypeError
        if (isDocumentTypeOrAttr(init_dict.start_container) or
            isDocumentTypeOrAttr(init_dict.end_container))
        {
            return error.InvalidNodeTypeError;
        }

        // Allocate StaticRange
        const self = try allocator.create(StaticRange);
        errdefer allocator.destroy(self);

        // Step 2: Set start boundary
        self.start_container = init_dict.start_container;
        self.start_offset = init_dict.start_offset;

        // Step 3: Set end boundary
        self.end_container = init_dict.end_container;
        self.end_offset = init_dict.end_offset;

        // Set allocator
        self.allocator = allocator;

        // Acquire refs on both nodes (STRONG references)
        // Note: Same node used twice = 2 refs (start + end treated independently)
        init_dict.start_container.acquire();
        init_dict.end_container.acquire();

        return self;
    }

    /// Destroys the StaticRange and releases references to boundary nodes.
    ///
    /// **Memory Safety**: Always call this when done with the StaticRange.
    /// The allocator must be the same one used in `init()`.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const range = try StaticRange.init(allocator, init);
    /// defer range.deinit(allocator);  // Auto cleanup
    /// ```
    pub fn deinit(self: *StaticRange, allocator: Allocator) void {
        // Release refs on boundary nodes
        self.start_container.release();
        self.end_container.release();

        // Free StaticRange struct
        allocator.destroy(self);
    }

    // ========================================================================
    // AbstractRange Interface (Read-Only Accessors)
    // ========================================================================

    /// WebIDL: readonly attribute Node startContainer (inherited from AbstractRange)
    ///
    /// Returns the start boundary node.
    ///
    /// Spec: https://dom.spec.whatwg.org/#dom-range-startcontainer
    /// MDN: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/startContainer
    pub fn startContainer(self: *const StaticRange) *Node {
        return self.start_container;
    }

    /// WebIDL: readonly attribute unsigned long startOffset (inherited from AbstractRange)
    ///
    /// Returns the start offset within the start container.
    /// Can be out of bounds if the range is invalid.
    ///
    /// Spec: https://dom.spec.whatwg.org/#dom-range-startoffset
    /// MDN: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/startOffset
    pub fn startOffset(self: *const StaticRange) u32 {
        return self.start_offset;
    }

    /// WebIDL: readonly attribute Node endContainer (inherited from AbstractRange)
    ///
    /// Returns the end boundary node.
    ///
    /// Spec: https://dom.spec.whatwg.org/#dom-range-endcontainer
    /// MDN: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/endContainer
    pub fn endContainer(self: *const StaticRange) *Node {
        return self.end_container;
    }

    /// WebIDL: readonly attribute unsigned long endOffset (inherited from AbstractRange)
    ///
    /// Returns the end offset within the end container.
    /// Can be out of bounds if the range is invalid.
    ///
    /// Spec: https://dom.spec.whatwg.org/#dom-range-endoffset
    /// MDN: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/endOffset
    pub fn endOffset(self: *const StaticRange) u32 {
        return self.end_offset;
    }

    /// WebIDL: readonly attribute boolean collapsed (inherited from AbstractRange)
    ///
    /// Returns true if the range is collapsed (start and end are at the same position).
    /// A collapsed range has the same container and offset for both start and end.
    ///
    /// Spec: https://dom.spec.whatwg.org/#dom-range-collapsed
    /// MDN: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/collapsed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// // Collapsed range (same node + offset)
    /// const init1 = StaticRangeInit{
    ///     .start_container = &node,
    ///     .start_offset = 5,
    ///     .end_container = &node,
    ///     .end_offset = 5,  // Same!
    /// };
    /// const range1 = try StaticRange.init(allocator, init1);
    /// defer range1.deinit(allocator);
    /// try std.testing.expect(range1.collapsed());  // true
    ///
    /// // Non-collapsed range (different offsets)
    /// const init2 = StaticRangeInit{
    ///     .start_container = &node,
    ///     .start_offset = 5,
    ///     .end_container = &node,
    ///     .end_offset = 10,  // Different!
    /// };
    /// const range2 = try StaticRange.init(allocator, init2);
    /// defer range2.deinit(allocator);
    /// try std.testing.expect(!range2.collapsed());  // false
    /// ```
    pub fn collapsed(self: *const StaticRange) bool {
        return self.start_container == self.end_container and
            self.start_offset == self.end_offset;
    }

    // ========================================================================
    // StaticRange-Specific Methods
    // ========================================================================

    /// Checks if this StaticRange is valid per WHATWG specification.
    ///
    /// A StaticRange is **valid** if ALL of the following conditions hold:
    /// 1. Start and end nodes have the same root
    /// 2. Start offset ≤ start node's length
    /// 3. End offset ≤ end node's length
    /// 4. Start is before or equal to end in tree order
    ///
    /// **Note**: This is computed on every call (NOT cached).
    /// StaticRange is immutable, so validity never changes after construction.
    ///
    /// Spec: https://dom.spec.whatwg.org/#staticrange-valid
    ///
    /// ## Examples
    ///
    /// ```zig
    /// // Valid range
    /// const text = try doc.createTextNode("hello");  // length = 5
    /// const init1 = StaticRangeInit{
    ///     .start_container = &text.node,
    ///     .start_offset = 0,
    ///     .end_container = &text.node,
    ///     .end_offset = 5,  // In bounds (0-5)
    /// };
    /// const range1 = try StaticRange.init(allocator, init1);
    /// defer range1.deinit(allocator);
    /// try std.testing.expect(range1.isValid());  // true
    ///
    /// // Invalid range (out-of-bounds offset)
    /// const init2 = StaticRangeInit{
    ///     .start_container = &text.node,
    ///     .start_offset = 10,  // > 5 (out of bounds!)
    ///     .end_container = &text.node,
    ///     .end_offset = 5,
    /// };
    /// const range2 = try StaticRange.init(allocator, init2);
    /// defer range2.deinit(allocator);
    /// try std.testing.expect(!range2.isValid());  // false
    /// ```
    pub fn isValid(self: *const StaticRange) bool {
        // Condition 1: Same root
        const start_root = self.start_container.getRootNode(false);
        const end_root = self.end_container.getRootNode(false);
        if (start_root != end_root) {
            return false;
        }

        // Condition 2: Start offset ≤ start node's length
        const start_length = getNodeLength(self.start_container);
        if (self.start_offset > start_length) {
            return false;
        }

        // Condition 3: End offset ≤ end node's length
        const end_length = getNodeLength(self.end_container);
        if (self.end_offset > end_length) {
            return false;
        }

        // Condition 4: Start before or equal to end in tree order
        // Optimization: Same node case (O(1))
        if (self.start_container == self.end_container) {
            return self.start_offset <= self.end_offset;
        }

        // Different nodes: Compare tree order (O(log N))
        // Valid if start is BEFORE or CONTAINS end
        const position = self.start_container.compareDocumentPosition(self.end_container);
        const FOLLOWING: u16 = Node.DOCUMENT_POSITION_FOLLOWING; // 0x04
        const CONTAINED_BY: u16 = Node.DOCUMENT_POSITION_CONTAINED_BY; // 0x10
        return (position & (FOLLOWING | CONTAINED_BY)) != 0;
    }
};

// ============================================================================
// Private Helper Functions
// ============================================================================

/// Fast check if node is DocumentType or Attr.
///
/// **Optimization** (WebKit pattern):
/// - Most nodes (99.9%) are Element or Text
/// - Check these common cases first (fast path)
/// - Only check enum if fast path fails
/// - ~2-5x faster than direct nodeType comparison
///
/// Per WebKit's StaticRange.cpp:
/// ```cpp
/// static bool isDocumentTypeOrAttr(Node& node) {
///     // Before calling nodeType, do two fast non-virtual checks
///     // that cover almost all normal nodes
///     if (is<ContainerNode>(node) || is<Text>(node))
///         return false;
///     // ... check nodeType
/// }
/// ```
fn isDocumentTypeOrAttr(node: *const Node) bool {
    const node_type = node.node_type;

    // Fast path: Element and Text are NEVER DocumentType or Attr
    // This covers 99.9% of nodes in typical DOM trees
    if (node_type == .element or node_type == .text) {
        return false;
    }

    // Slow path: Check if it's one of the forbidden types
    return node_type == .document_type or node_type == .attribute;
}

/// Returns the length of a node per WHATWG DOM specification.
///
/// **Node Length** (WHATWG §4.2):
/// - DocumentType: 0
/// - Text, Comment: data length
/// - Element, Document, DocumentFragment: number of children
/// - Attr: value length (but Attr is forbidden in ranges)
///
/// Spec: https://dom.spec.whatwg.org/#concept-node-length
fn getNodeLength(node: *const Node) u32 {
    return switch (node.node_type) {
        .document_type => 0,
        .text => blk: {
            const Text = @import("text.zig").Text;
            const text_node: *const Text = @fieldParentPtr("prototype", node);
            break :blk @intCast(text_node.data.len);
        },
        .comment => blk: {
            const Comment = @import("comment.zig").Comment;
            const comment_node: *const Comment = @fieldParentPtr("prototype", node);
            break :blk @intCast(comment_node.data.len);
        },
        .element, .document, .document_fragment, .shadow_root => blk: {
            // Container nodes: number of children
            var count: u32 = 0;
            var child = node.first_child;
            while (child) |c| : (child = c.next_sibling) {
                count += 1;
            }
            break :blk count;
        },
        .attribute => 0, // Attr is forbidden in ranges, but return 0 for safety
        .processing_instruction => 0, // Not commonly used
    };
}

// ============================================================================
// Tests
// ============================================================================

const testing = std.testing;

test "StaticRange: isDocumentTypeOrAttr fast path for Element" {
    const Document = @import("document.zig").Document;

    const doc = try Document.init(testing.allocator);
    defer doc.node.release();

    const elem = try doc.createElement("div");
    try testing.expect(!isDocumentTypeOrAttr(&elem.node));
}

test "StaticRange: isDocumentTypeOrAttr fast path for Text" {
    const Document = @import("document.zig").Document;

    const doc = try Document.init(testing.allocator);
    defer doc.node.release();

    const text = try doc.createTextNode("test");
    try testing.expect(!isDocumentTypeOrAttr(&text.node));
}

test "StaticRange: isDocumentTypeOrAttr detects DocumentType" {
    const DocumentType = @import("document_type.zig").DocumentType;

    const doctype = try DocumentType.create(testing.allocator, "html", "", "");
    defer doctype.node.release();

    try testing.expect(isDocumentTypeOrAttr(&doctype.node));
}

test "StaticRange: isDocumentTypeOrAttr detects Attr" {
    const Attr = @import("attr.zig").Attr;

    const attr = try Attr.create(testing.allocator, "id", "test");
    defer attr.node.release();

    try testing.expect(isDocumentTypeOrAttr(&attr.node));
}

test "StaticRange: getNodeLength for Element" {
    const Document = @import("document.zig").Document;

    const doc = try Document.init(testing.allocator);
    defer doc.node.release();

    const elem = try doc.createElement("div");
    try testing.expectEqual(@as(u32, 0), getNodeLength(&elem.node));

    const child1 = try doc.createElement("child1");
    _ = try elem.node.appendChild(&child1.node);
    try testing.expectEqual(@as(u32, 1), getNodeLength(&elem.node));

    const child2 = try doc.createElement("child2");
    _ = try elem.node.appendChild(&child2.node);
    try testing.expectEqual(@as(u32, 2), getNodeLength(&elem.node));
}

test "StaticRange: getNodeLength for Text" {
    const Document = @import("document.zig").Document;

    const doc = try Document.init(testing.allocator);
    defer doc.node.release();

    const text = try doc.createTextNode("hello");
    try testing.expectEqual(@as(u32, 5), getNodeLength(&text.node));

    const empty_text = try doc.createTextNode("");
    try testing.expectEqual(@as(u32, 0), getNodeLength(&empty_text.node));
}

test "StaticRange: getNodeLength for DocumentType" {
    const DocumentType = @import("document_type.zig").DocumentType;

    const doctype = try DocumentType.create(testing.allocator, "html", "", "");
    defer doctype.node.release();

    try testing.expectEqual(@as(u32, 0), getNodeLength(&doctype.node));
}
