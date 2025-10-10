//! StaticRange Interface - WHATWG DOM Standard §5.4
//! ===================================================
//!
//! The StaticRange interface represents an immutable range that does not automatically
//! update when the DOM tree is mutated. Unlike Range objects which are "live" and track
//! changes, StaticRange provides a lightweight, read-only snapshot of range boundaries.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-staticrange
//! - **Section**: §5.4 Interface StaticRange
//!
//! ## MDN Documentation
//! - **StaticRange**: https://developer.mozilla.org/en-US/docs/Web/API/StaticRange
//! - **StaticRange()**: https://developer.mozilla.org/en-US/docs/Web/API/StaticRange/StaticRange
//!
//! ## Key Concepts
//!
//! ### Immutability
//! StaticRange objects cannot be modified after creation. All properties are readonly,
//! and there are no methods to adjust the range boundaries. This immutability enables
//! significant performance optimizations.
//!
//! ### No DOM Tracking
//! Unlike Range objects, StaticRange does not maintain references to live ranges or
//! update when nodes are moved, removed, or modified. This makes StaticRange much
//! lighter weight but means it can become "stale" if the DOM changes.
//!
//! ### Validation
//! StaticRange performs minimal validation. It can represent invalid ranges such as:
//! - Start boundary after end boundary
//! - Offsets beyond node length
//! - Detached nodes
//!
//! This is intentional for performance - validation is deferred to the point of use.
//!
//! ### Use Cases
//! StaticRange is ideal for:
//! - Selection APIs that need to capture a point in time
//! - Input events that report text ranges
//! - Annotation systems that store range positions
//! - Performance-critical code that doesn't need live tracking
//!
//! ## Architecture
//!
//! ```
//! StaticRange
//! ├── start_container (*Node) - Start boundary node
//! ├── start_offset (usize) - Offset within start node
//! ├── end_container (*Node) - End boundary node
//! ├── end_offset (usize) - Offset within end node
//! └── allocator - Memory management
//!
//! Boundary Points:
//! (start_container, start_offset) ─────> [selected content] <───── (end_container, end_offset)
//! ```
//!
//! ## StaticRange vs Range
//!
//! | Feature | StaticRange | Range |
//! |---------|-------------|-------|
//! | Mutability | Immutable | Mutable (setStart, setEnd, etc.) |
//! | DOM Tracking | No | Yes (updates with mutations) |
//! | Validation | Minimal | Strict (throws on invalid) |
//! | Performance | Fast | Slower (tracking overhead) |
//! | Memory | Lightweight | Heavier (mutation tracking) |
//! | Methods | Read-only accessors | Full manipulation API |
//!
//! ## Usage Examples
//!
//! ### Basic StaticRange Creation
//! ```zig
//! const text = try Text.init(allocator, "Hello, World!");
//! defer text.release();
//!
//! const range = try StaticRange.init(allocator, .{
//!     .start_container = &text.character_data.node,
//!     .start_offset = 0,
//!     .end_container = &text.character_data.node,
//!     .end_offset = 5,
//! });
//! defer range.deinit();
//!
//! // Range represents "Hello"
//! try std.testing.expectEqual(@as(usize, 0), range.startOffset());
//! try std.testing.expectEqual(@as(usize, 5), range.endOffset());
//! try std.testing.expect(!range.collapsed());
//! ```
//!
//! ### Collapsed Range (Empty Selection)
//! ```zig
//! const text = try Text.init(allocator, "Text");
//! defer text.release();
//!
//! // Collapsed range at position 3 (like a cursor)
//! const collapsed = try StaticRange.init(allocator, .{
//!     .start_container = &text.character_data.node,
//!     .start_offset = 3,
//!     .end_container = &text.character_data.node,
//!     .end_offset = 3,
//! });
//! defer collapsed.deinit();
//!
//! try std.testing.expect(collapsed.collapsed());
//! ```
//!
//! ### Cross-Node Range
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const div = try doc.createElement("div");
//! const text1 = try doc.createTextNode("First ");
//! const text2 = try doc.createTextNode("Second");
//!
//! _ = try div.appendChild(&text1.character_data.node);
//! _ = try div.appendChild(&text2.character_data.node);
//!
//! // Range from middle of first text to middle of second
//! const range = try StaticRange.init(allocator, .{
//!     .start_container = &text1.character_data.node,
//!     .start_offset = 3,
//!     .end_container = &text2.character_data.node,
//!     .end_offset = 3,
//! });
//! defer range.deinit();
//!
//! // Represents "rst Sec"
//! ```
//!
//! ### Capturing Selection for Later Use
//! ```zig
//! // Capture current selection position
//! fn captureSelection(allocator: Allocator, selection_node: *Node, offset: usize) !*StaticRange {
//!     return StaticRange.init(allocator, .{
//!         .start_container = selection_node,
//!         .start_offset = offset,
//!         .end_container = selection_node,
//!         .end_offset = offset,
//!     });
//! }
//!
//! const saved_position = try captureSelection(allocator, text_node, 10);
//! defer saved_position.deinit();
//!
//! // ... DOM changes happen ...
//!
//! // Position is preserved even if DOM was modified
//! // (though it may now be invalid)
//! ```
//!
//! ### Input Event Range Reporting
//! ```zig
//! // Example: beforeinput event reports affected range
//! pub fn reportInputRange(
//!     allocator: Allocator,
//!     target: *Node,
//!     start: usize,
//!     end: usize
//! ) !*StaticRange {
//!     // StaticRange is perfect for one-time event data
//!     return StaticRange.init(allocator, .{
//!         .start_container = target,
//!         .start_offset = start,
//!         .end_container = target,
//!         .end_offset = end,
//!     });
//! }
//! ```
//!
//! ## Memory Management
//!
//! ### Allocation
//! StaticRange is allocated on the heap and must be explicitly freed:
//! ```zig
//! const range = try StaticRange.init(allocator, init_params);
//! defer range.deinit(); // Required cleanup
//! ```
//!
//! ### Node References
//! StaticRange holds raw pointers to nodes but does **not** retain them. The caller
//! must ensure referenced nodes remain valid for the lifetime of the StaticRange:
//!
//! ```zig
//! // ✅ CORRECT: Node outlives range
//! const node = try Node.init(allocator, .text_node, "#text");
//! defer node.release();
//!
//! const range = try StaticRange.init(allocator, .{
//!     .start_container = node,
//!     .start_offset = 0,
//!     .end_container = node,
//!     .end_offset = 5,
//! });
//! defer range.deinit();
//!
//! // ❌ INCORRECT: Range outlives node
//! var node_ptr: *Node = undefined;
//! {
//!     const node = try Node.init(allocator, .text_node, "#text");
//!     node_ptr = node;
//!     node.release(); // Node freed here!
//! }
//! const range = try StaticRange.init(allocator, .{
//!     .start_container = node_ptr, // Dangling pointer!
//!     // ...
//! });
//! ```
//!
//! ### No Cleanup Overhead
//! Since StaticRange doesn't track mutations, there are no mutation observers,
//! range lists, or other cleanup to perform. `deinit()` simply frees the struct.
//!
//! ## Thread Safety
//!
//! StaticRange objects are **immutable after creation**, making them safe to read
//! from multiple threads simultaneously without synchronization. However:
//!
//! - Creation must be synchronized if using a non-thread-safe allocator
//! - The referenced nodes are **not** thread-safe
//! - Ensure nodes aren't modified from other threads while reading the range
//!
//! ## Specification Compliance
//!
//! This implementation follows WHATWG DOM Standard §5.4:
//! - ✅ Immutable after creation
//! - ✅ Minimal validation (can represent invalid ranges)
//! - ✅ startContainer, startOffset, endContainer, endOffset (readonly)
//! - ✅ collapsed property
//! - ✅ No mutation tracking
//! - ✅ Lightweight implementation

const std = @import("std");
const Node = @import("node.zig").Node;

/// StaticRangeInit dictionary for initialization
///
/// Provides the boundary points for a new StaticRange.
/// All fields are required.
pub const StaticRangeInit = struct {
    start_container: *Node,
    start_offset: usize,
    end_container: *Node,
    end_offset: usize,
};

/// StaticRange represents an immutable range
///
/// ## Specification
///
/// WHATWG DOM Standard §5.4
///
/// ## Differences from Range
///
/// - Immutable: Cannot be modified after creation
/// - Lightweight: No mutation tracking
/// - No validation: Can represent invalid ranges
/// - Faster: No overhead of live range maintenance
///
/// ## Example
///
/// ```zig
/// const static_range = try StaticRange.init(allocator, .{
///     .start_container = text_node,
///     .start_offset = 0,
///     .end_container = text_node,
///     .end_offset = 5,
/// });
/// defer static_range.deinit();
/// ```
pub const StaticRange = struct {
    /// Start boundary point - node
    start_container: *Node,

    /// Start boundary point - offset
    start_offset: usize,

    /// End boundary point - node
    end_container: *Node,

    /// End boundary point - offset
    end_offset: usize,

    /// Memory allocator
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a StaticRange
    ///
    /// Creates a new immutable range with the specified boundary points.
    /// No validation is performed - the range can be invalid (e.g., start > end).
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `init_params`: Initialization parameters with boundary points
    ///
    /// ## Returns
    ///
    /// A new StaticRange instance.
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If allocation fails
    ///
    /// ## Note
    ///
    /// Unlike Range, StaticRange does not validate the boundary points.
    /// It can represent invalid ranges (e.g., where start > end, or offsets
    /// beyond node length). This is intentional for performance.
    ///
    /// The caller must ensure referenced nodes remain valid for the
    /// lifetime of the StaticRange, as no reference counting is performed.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const text = try Text.init(allocator, "Hello");
    /// defer text.release();
    ///
    /// const range = try StaticRange.init(allocator, .{
    ///     .start_container = &text.character_data.node,
    ///     .start_offset = 0,
    ///     .end_container = &text.character_data.node,
    ///     .end_offset = 5,
    /// });
    /// defer range.deinit();
    /// ```
    pub fn init(allocator: std.mem.Allocator, init_params: StaticRangeInit) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .start_container = init_params.start_container,
            .start_offset = init_params.start_offset,
            .end_container = init_params.end_container,
            .end_offset = init_params.end_offset,
            .allocator = allocator,
        };
        return self;
    }

    /// Get the start container
    ///
    /// Returns the node containing the start boundary point of the range.
    ///
    /// ## Returns
    ///
    /// The start container node (never null).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const container = range.startContainer();
    /// ```
    pub fn startContainer(self: *const Self) *Node {
        return self.start_container;
    }

    /// Get the start offset
    ///
    /// Returns the offset within the start container where the range begins.
    /// For text nodes, this is a character offset. For element nodes, this
    /// is a child node index.
    ///
    /// ## Returns
    ///
    /// The start offset (0-based).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const offset = range.startOffset(); // e.g., 5
    /// ```
    pub fn startOffset(self: *const Self) usize {
        return self.start_offset;
    }

    /// Get the end container
    ///
    /// Returns the node containing the end boundary point of the range.
    ///
    /// ## Returns
    ///
    /// The end container node (never null).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const container = range.endContainer();
    /// ```
    pub fn endContainer(self: *const Self) *Node {
        return self.end_container;
    }

    /// Get the end offset
    ///
    /// Returns the offset within the end container where the range ends.
    /// For text nodes, this is a character offset. For element nodes, this
    /// is a child node index.
    ///
    /// ## Returns
    ///
    /// The end offset (0-based).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const offset = range.endOffset(); // e.g., 10
    /// ```
    pub fn endOffset(self: *const Self) usize {
        return self.end_offset;
    }

    /// Check if the range is collapsed
    ///
    /// A range is collapsed when its start and end boundary points are identical,
    /// representing a single position rather than a span of content (like a cursor
    /// position in a text editor).
    ///
    /// ## Returns
    ///
    /// `true` if start equals end, `false` otherwise.
    ///
    /// ## Example
    ///
    /// ```zig
    /// // Collapsed range (cursor position)
    /// const cursor = try StaticRange.init(allocator, .{
    ///     .start_container = node,
    ///     .start_offset = 5,
    ///     .end_container = node,
    ///     .end_offset = 5,
    /// });
    /// try std.testing.expect(cursor.collapsed()); // true
    ///
    /// // Non-collapsed range (selection)
    /// const selection = try StaticRange.init(allocator, .{
    ///     .start_container = node,
    ///     .start_offset = 0,
    ///     .end_container = node,
    ///     .end_offset = 5,
    /// });
    /// try std.testing.expect(!selection.collapsed()); // false
    /// ```
    pub fn collapsed(self: *const Self) bool {
        return self.start_container == self.end_container and
            self.start_offset == self.end_offset;
    }

    /// Free the StaticRange
    ///
    /// Releases the memory allocated for this StaticRange. This does **not**
    /// affect the referenced nodes - they are not retained or released.
    ///
    /// Must be called when done with the StaticRange to avoid memory leaks.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const range = try StaticRange.init(allocator, init_params);
    /// defer range.deinit(); // Automatic cleanup
    /// ```
    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "StaticRange - basic creation" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "#text");
    defer node.release();

    const range = try StaticRange.init(allocator, .{
        .start_container = node,
        .start_offset = 0,
        .end_container = node,
        .end_offset = 5,
    });
    defer range.deinit();

    try std.testing.expectEqual(node, range.startContainer());
    try std.testing.expectEqual(@as(usize, 0), range.startOffset());
    try std.testing.expectEqual(node, range.endContainer());
    try std.testing.expectEqual(@as(usize, 5), range.endOffset());
}

test "StaticRange - collapsed" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "#text");
    defer node.release();

    const collapsed_range = try StaticRange.init(allocator, .{
        .start_container = node,
        .start_offset = 3,
        .end_container = node,
        .end_offset = 3,
    });
    defer collapsed_range.deinit();

    try std.testing.expect(collapsed_range.collapsed());

    const not_collapsed = try StaticRange.init(allocator, .{
        .start_container = node,
        .start_offset = 0,
        .end_container = node,
        .end_offset = 5,
    });
    defer not_collapsed.deinit();

    try std.testing.expect(!not_collapsed.collapsed());
}

test "StaticRange - with different nodes" {
    const allocator = std.testing.allocator;

    const node1 = try Node.init(allocator, .text_node, "#text1");
    defer node1.release();

    const node2 = try Node.init(allocator, .text_node, "#text2");
    defer node2.release();

    const range = try StaticRange.init(allocator, .{
        .start_container = node1,
        .start_offset = 2,
        .end_container = node2,
        .end_offset = 4,
    });
    defer range.deinit();

    try std.testing.expectEqual(node1, range.startContainer());
    try std.testing.expectEqual(node2, range.endContainer());
    try std.testing.expect(!range.collapsed());
}

test "StaticRange - allows invalid ranges" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "#text");
    defer node.release();

    // StaticRange allows start > end (invalid but permitted)
    const invalid_range = try StaticRange.init(allocator, .{
        .start_container = node,
        .start_offset = 10,
        .end_container = node,
        .end_offset = 5,
    });
    defer invalid_range.deinit();

    try std.testing.expectEqual(@as(usize, 10), invalid_range.startOffset());
    try std.testing.expectEqual(@as(usize, 5), invalid_range.endOffset());
}

test "StaticRange - memory leak test" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "#text");
    defer node.release();

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const range = try StaticRange.init(allocator, .{
            .start_container = node,
            .start_offset = 0,
            .end_container = node,
            .end_offset = i,
        });
        range.deinit();
    }
}
