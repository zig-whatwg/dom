//! Core Node implementation with WebKit-style reference counting.
//!
//! This module implements the fundamental DOM Node with:
//! - Packed ref_count + has_parent in single u32 (saves 12 bytes)
//! - Weak parent/sibling pointers (prevents circular references)
//! - Vtable-based polymorphism (allows extension by Browser/HTML projects)
//! - Target size: ≤96 bytes per node
//!
//! Spec: WHATWG DOM §4 (https://dom.spec.whatwg.org/#nodes)

const std = @import("std");
const Allocator = std.mem.Allocator;
const NodeRareData = @import("rare_data.zig").NodeRareData;

/// Node types per WHATWG DOM specification.
pub const NodeType = enum(u8) {
    element = 1,
    text = 3,
    comment = 8,
    document = 9,
    document_type = 10,
    document_fragment = 11,
    processing_instruction = 7,

    /// Returns the numeric value used in the DOM API.
    pub fn value(self: NodeType) u8 {
        return @intFromEnum(self);
    }
};

/// Virtual table for polymorphic Node behavior.
///
/// This enables different node types (Element, Text, Comment, etc.) to have
/// custom implementations while sharing the same Node base structure.
/// All browsers use vtables (C++ virtual methods) for this purpose.
pub const NodeVTable = struct {
    /// Cleanup function called when ref_count reaches 0 and node has no parent.
    deinit: *const fn (*Node) void,

    /// Returns the node name (tag name for elements, "#text" for text nodes, etc.)
    node_name: *const fn (*const Node) []const u8,

    /// Returns the node value (null for elements, text content for text nodes, etc.)
    node_value: *const fn (*const Node) ?[]const u8,

    /// Sets the node value (errors for read-only nodes)
    set_node_value: *const fn (*Node, []const u8) anyerror!void,

    /// Clones the node (shallow or deep)
    clone_node: *const fn (*const Node, bool) anyerror!*Node,
};

/// Core DOM Node structure.
///
/// Memory layout optimized for size (target: ≤96 bytes).
/// All pointers are 8 bytes on 64-bit systems.
///
/// ## Memory Management
/// - Reference counted (acquire/release pattern)
/// - Parent pointers are WEAK (no ref_count increment)
/// - Child/sibling pointers are STRONG (via has_parent flag)
/// - Node is destroyed when ref_count=0 AND has_parent=false
///
/// ## Usage
/// ```zig
/// const node = try Node.init(allocator, vtable, .element);
/// defer node.release(); // REQUIRED
///
/// node.acquire(); // Share ownership
/// defer node.release(); // Release shared ownership
/// ```
pub const Node = struct {
    /// Virtual table for polymorphic dispatch (8 bytes)
    vtable: *const NodeVTable,

    /// PACKED: 31-bit ref_count + 1-bit has_parent flag (4 bytes)
    ///
    /// This optimization saves 12 bytes per node vs separate fields.
    /// - Bits 0-30: Reference count (max 2,147,483,647)
    /// - Bit 31: has_parent flag (1 = has parent, 0 = no parent)
    ///
    /// The has_parent flag prevents premature destruction when:
    /// - Node is in tree (parent owns it via strong reference)
    /// - Node ref_count can drop to 0, but it's kept alive by parent
    ref_count_and_parent: std.atomic.Value(u32),

    /// Node type (1 byte)
    node_type: NodeType,

    /// Flags for various boolean properties (1 byte)
    /// Bits: [unused(6), is_connected(1), is_in_shadow_tree(1)]
    flags: u8,

    /// Unique node ID within document (2 bytes)
    /// Used for equality checks and debugging
    /// Max 65,535 nodes per document (sufficient for most pages)
    node_id: u16,

    /// Generation counter for detecting stale references (4 bytes)
    /// Incremented on major mutations
    /// Max 4,294,967,295 mutations (sufficient for long-lived pages)
    generation: u32,

    /// Allocator used to create this node (8 bytes)
    allocator: Allocator,

    /// WEAK pointer to parent (8 bytes)
    /// Does NOT increment ref_count (prevents circular references)
    parent_node: ?*Node,

    /// WEAK pointer to previous sibling (8 bytes)
    previous_sibling: ?*Node,

    /// STRONG pointer to first child (8 bytes)
    /// Child's has_parent flag set to 1 (parent owns child)
    first_child: ?*Node,

    /// STRONG pointer to last child (8 bytes)
    /// Child's has_parent flag set to 1 (parent owns child)
    last_child: ?*Node,

    /// STRONG pointer to next sibling (8 bytes)
    /// Only STRONG if sibling has parent (transitively owned)
    next_sibling: ?*Node,

    /// WEAK pointer to owner document (8 bytes)
    /// Document uses separate dual ref counting
    owner_document: ?*Node, // TODO: Type as *Document once implemented

    /// Pointer to rare data (allocated on demand) (8 bytes)
    /// Stores infrequently-used features (event listeners, observers, etc.)
    /// Most nodes don't need this, saving 40-80 bytes
    rare_data: ?*NodeRareData,

    // === Size Verification ===
    comptime {
        const size = @sizeOf(Node);
        if (size > 96) {
            const msg = std.fmt.comptimePrint("Node size ({d} bytes) exceeded 96 byte limit! Keep it small.", .{size});
            @compileError(msg);
        }
    }

    // === Bit manipulation constants ===
    const HAS_PARENT_BIT: u32 = 1 << 31;
    const REF_COUNT_MASK: u32 = 0x7FFF_FFFF; // 31 bits
    const MAX_REF_COUNT: u32 = REF_COUNT_MASK;

    // === Flag bit positions ===
    const FLAG_IS_CONNECTED: u8 = 1 << 0;
    const FLAG_IS_IN_SHADOW_TREE: u8 = 1 << 1;

    /// Initializes a new Node with ref_count = 1.
    ///
    /// ## Memory Management
    /// Caller MUST call `release()` when done to prevent memory leaks.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    /// - `vtable`: Virtual table for polymorphic behavior
    /// - `node_type`: Type of node being created
    ///
    /// ## Returns
    /// New node with ref_count=1, caller owns the reference
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    pub fn init(
        allocator: Allocator,
        vtable: *const NodeVTable,
        node_type: NodeType,
    ) Allocator.Error!*Node {
        const node = try allocator.create(Node);
        node.* = .{
            .vtable = vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1), // ref_count=1, has_parent=0
            .node_type = node_type,
            .flags = 0,
            .node_id = 0, // Set by Document when inserted
            .generation = 0,
            .allocator = allocator,
            .parent_node = null,
            .previous_sibling = null,
            .first_child = null,
            .last_child = null,
            .next_sibling = null,
            .owner_document = null,
            .rare_data = null,
        };
        return node;
    }

    /// Increments the reference count atomically.
    ///
    /// Call this when sharing ownership of the node.
    /// MUST be paired with a corresponding `release()` call.
    ///
    /// ## Example
    /// ```zig
    /// node.acquire(); // Share ownership
    /// other_container.node = node;
    /// // Both must call release()
    /// ```
    pub fn acquire(self: *Node) void {
        const old = self.ref_count_and_parent.fetchAdd(1, .monotonic);
        const ref_count = old & REF_COUNT_MASK;

        // Safety: Check for overflow (extremely unlikely)
        if (ref_count >= MAX_REF_COUNT) {
            @panic("Node ref_count overflow! This should never happen.");
        }
    }

    /// Decrements the reference count atomically.
    ///
    /// When ref_count reaches 0 AND has_parent=false, the node is destroyed.
    /// MUST be called exactly once for each `acquire()` or `init()`.
    ///
    /// ## Example
    /// ```zig
    /// const node = try Node.init(allocator, vtable, .element);
    /// defer node.release(); // REQUIRED
    /// ```
    pub fn release(self: *Node) void {
        const old = self.ref_count_and_parent.fetchSub(1, .monotonic);
        const ref_count = old & REF_COUNT_MASK;
        const has_parent = (old & HAS_PARENT_BIT) != 0;

        // Destroy when:
        // - ref_count reaches 0 (no external owners)
        // - AND has_parent=false (not owned by parent)
        if (ref_count == 1 and !has_parent) {
            self.vtable.deinit(self);
        }
    }

    /// Sets the has_parent flag atomically.
    ///
    /// This flag prevents premature destruction when node is in tree.
    /// Parent-child relationship is STRONG (parent owns child).
    ///
    /// ## Parameters
    /// - `value`: true = has parent (in tree), false = no parent (detached)
    pub fn setHasParent(self: *Node, value: bool) void {
        if (value) {
            _ = self.ref_count_and_parent.fetchOr(HAS_PARENT_BIT, .monotonic);
        } else {
            _ = self.ref_count_and_parent.fetchAnd(~HAS_PARENT_BIT, .monotonic);
        }
    }

    /// Returns the current reference count (for debugging/testing).
    pub fn getRefCount(self: *const Node) u32 {
        const value = self.ref_count_and_parent.load(.monotonic);
        return value & REF_COUNT_MASK;
    }

    /// Returns the has_parent flag (for debugging/testing).
    pub fn hasParent(self: *const Node) bool {
        const value = self.ref_count_and_parent.load(.monotonic);
        return (value & HAS_PARENT_BIT) != 0;
    }

    // === Convenience flag accessors ===

    pub fn isConnected(self: *const Node) bool {
        return (self.flags & FLAG_IS_CONNECTED) != 0;
    }

    pub fn setConnected(self: *Node, value: bool) void {
        if (value) {
            self.flags |= FLAG_IS_CONNECTED;
        } else {
            self.flags &= ~FLAG_IS_CONNECTED;
        }
    }

    pub fn isInShadowTree(self: *const Node) bool {
        return (self.flags & FLAG_IS_IN_SHADOW_TREE) != 0;
    }

    // === Polymorphic dispatch methods ===

    /// Returns the node name (delegates to vtable).
    pub fn nodeName(self: *const Node) []const u8 {
        return self.vtable.node_name(self);
    }

    /// Returns the node value (delegates to vtable).
    pub fn nodeValue(self: *const Node) ?[]const u8 {
        return self.vtable.node_value(self);
    }

    /// Sets the node value (delegates to vtable).
    pub fn setNodeValue(self: *Node, value: []const u8) !void {
        return self.vtable.set_node_value(self, value);
    }

    /// Clones the node (delegates to vtable).
    pub fn cloneNode(self: *const Node, deep: bool) !*Node {
        return self.vtable.clone_node(self, deep);
    }

    // === Node Tree Query Methods (WHATWG DOM) ===

    /// Returns the owner document of this node.
    ///
    /// Implements WHATWG DOM Node.ownerDocument property.
    /// Returns typed Document pointer instead of generic Node pointer.
    ///
    /// Per WHATWG spec: "The ownerDocument getter steps are to return null,
    /// if this is a document; otherwise this's node document."
    ///
    /// ## Returns
    /// Owner document or null if node is itself a document
    ///
    /// ## Example
    /// ```zig
    /// if (node.getOwnerDocument()) |doc| {
    ///     const elem = try doc.createElement("div");
    ///     defer elem.node.release();
    /// }
    /// ```
    pub fn getOwnerDocument(self: *const Node) ?*@import("document.zig").Document {
        // Return null for Document nodes per spec
        if (self.node_type == .document) {
            return null;
        }

        if (self.owner_document) |owner| {
            if (owner.node_type == .document) {
                return @fieldParentPtr("node", owner);
            }
        }
        return null;
    }

    /// Returns a live NodeList of child nodes.
    ///
    /// Implements WHATWG DOM Node.childNodes property.
    /// Returns a live collection that automatically reflects DOM changes.
    ///
    /// ## Returns
    /// Live NodeList of children
    ///
    /// ## Example
    /// ```zig
    /// const children = node.childNodes();
    /// for (0..children.length()) |i| {
    ///     if (children.item(i)) |child| {
    ///         std.debug.print("Child {}: {s}\n", .{i, child.nodeName()});
    ///     }
    /// }
    /// ```
    pub fn childNodes(self: *Node) @import("node_list.zig").NodeList {
        return @import("node_list.zig").NodeList.init(self);
    }

    /// Returns true if the node has any child nodes.
    ///
    /// Implements WHATWG DOM Node.hasChildNodes() interface.
    ///
    /// ## Returns
    /// true if node has at least one child, false otherwise
    ///
    /// ## Example
    /// ```zig
    /// if (node.hasChildNodes()) {
    ///     std.debug.print("Node has children\n", .{});
    /// }
    /// ```
    pub fn hasChildNodes(self: *const Node) bool {
        return self.first_child != null;
    }

    /// Returns the parent element of this node.
    ///
    /// Implements WHATWG DOM Node.parentElement property.
    /// Similar to parentNode, but returns null if parent is not an Element.
    ///
    /// ## Returns
    /// Parent element or null if parent is not an element (or no parent)
    ///
    /// ## Example
    /// ```zig
    /// if (node.parentElement()) |parent_elem| {
    ///     const tag = parent_elem.tag_name;
    ///     std.debug.print("Parent element: {s}\n", .{tag});
    /// }
    /// ```
    pub fn parentElement(self: *const Node) ?*@import("element.zig").Element {
        if (self.parent_node) |parent| {
            if (parent.node_type == .element) {
                return @fieldParentPtr("node", parent);
            }
        }
        return null;
    }

    // === RareData management ===

    /// Ensures rare data is allocated.
    ///
    /// Call this before accessing rare features (event listeners, observers, etc.)
    ///
    /// ## Returns
    /// Pointer to rare data structure
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate rare data
    pub fn ensureRareData(self: *Node) !*NodeRareData {
        if (self.rare_data == null) {
            const rare = try self.allocator.create(NodeRareData);
            rare.* = NodeRareData.init(self.allocator);
            self.rare_data = rare;
        }
        return self.rare_data.?;
    }

    /// Returns rare data if allocated, null otherwise.
    pub fn getRareData(self: *const Node) ?*NodeRareData {
        return self.rare_data;
    }

    /// Checks if node has rare data allocated.
    pub fn hasRareData(self: *const Node) bool {
        return self.rare_data != null;
    }

    /// Frees rare data if allocated.
    ///
    /// Called during node cleanup by vtable deinit implementations.
    /// PUBLIC for Element/Text/Comment/Document to call.
    pub fn deinitRareData(self: *Node) void {
        if (self.rare_data) |rare| {
            rare.deinit();
            self.allocator.destroy(rare);
            self.rare_data = null;
        }
    }

    // === Event Listener API (WHATWG-style delegation to RareData) ===

    /// Adds an event listener to the node.
    ///
    /// Implements WHATWG EventTarget.addEventListener() interface.
    /// Internally delegates to RareData for storage.
    ///
    /// ## Parameters
    /// - `event_type`: Event type (e.g., "click", "input", "change")
    /// - `callback`: Event callback function
    /// - `context`: User context (passed to callback)
    /// - `capture`: Capture phase (true) or bubble phase (false)
    /// - `once`: Remove after first invocation
    /// - `passive`: Passive listener (won't call preventDefault)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate storage
    ///
    /// ## Example
    /// ```zig
    /// const callback = struct {
    ///     fn handle(ctx: *anyopaque) void {
    ///         const data: *MyData = @ptrCast(@alignCast(ctx));
    ///         // Handle event
    ///     }
    /// }.handle;
    ///
    /// var my_data = MyData{};
    /// try node.addEventListener("click", callback, @ptrCast(&my_data), false, false, false);
    /// ```
    pub fn addEventListener(
        self: *Node,
        event_type: []const u8,
        callback: @import("rare_data.zig").EventCallback,
        context: *anyopaque,
        capture: bool,
        once: bool,
        passive: bool,
    ) !void {
        const rare = try self.ensureRareData();
        try rare.addEventListener(.{
            .event_type = event_type,
            .callback = callback,
            .context = context,
            .capture = capture,
            .once = once,
            .passive = passive,
        });
    }

    /// Removes an event listener from the node.
    ///
    /// Implements WHATWG EventTarget.removeEventListener() interface.
    /// Per WebIDL spec, this returns void (not bool).
    /// Matches by event type, callback pointer, and capture phase.
    ///
    /// ## Parameters
    /// - `event_type`: Event type to remove listener for
    /// - `callback`: Callback function pointer to match
    /// - `capture`: Capture phase to match
    ///
    /// ## Example
    /// ```zig
    /// node.removeEventListener("click", callback, false);
    /// ```
    pub fn removeEventListener(
        self: *Node,
        event_type: []const u8,
        callback: @import("rare_data.zig").EventCallback,
        capture: bool,
    ) void {
        if (self.rare_data) |rare| {
            _ = rare.removeEventListener(event_type, callback, capture);
        }
    }

    /// Checks if node has event listeners for the specified type.
    ///
    /// ## Parameters
    /// - `event_type`: Event type to check
    ///
    /// ## Returns
    /// true if node has listeners for this event type, false otherwise
    pub fn hasEventListeners(self: *const Node, event_type: []const u8) bool {
        if (self.rare_data) |rare| {
            return rare.hasEventListeners(event_type);
        }
        return false;
    }

    /// Returns all event listeners for a specific event type.
    ///
    /// ## Parameters
    /// - `event_type`: Event type to query
    ///
    /// ## Returns
    /// Slice of listeners (empty if none registered)
    pub fn getEventListeners(self: *const Node, event_type: []const u8) []const @import("rare_data.zig").EventListener {
        if (self.rare_data) |rare| {
            return rare.getEventListeners(event_type);
        }
        return &[_]@import("rare_data.zig").EventListener{};
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "Node - size constraint" {
    const size = @sizeOf(Node);
    try std.testing.expect(size <= 96);

    // Print actual size for documentation
    std.debug.print("\nNode size: {d} bytes (target: ≤96)\n", .{size});
}

test "Node - packed ref_count and has_parent" {
    // Verify bit packing works correctly
    const node_with_ref_1_no_parent: u32 = 1;
    const node_with_ref_1_has_parent: u32 = 1 | Node.HAS_PARENT_BIT;
    const node_with_ref_100_no_parent: u32 = 100;

    // Extract ref_count
    try std.testing.expectEqual(@as(u32, 1), node_with_ref_1_no_parent & Node.REF_COUNT_MASK);
    try std.testing.expectEqual(@as(u32, 1), node_with_ref_1_has_parent & Node.REF_COUNT_MASK);
    try std.testing.expectEqual(@as(u32, 100), node_with_ref_100_no_parent & Node.REF_COUNT_MASK);

    // Extract has_parent
    try std.testing.expect((node_with_ref_1_no_parent & Node.HAS_PARENT_BIT) == 0);
    try std.testing.expect((node_with_ref_1_has_parent & Node.HAS_PARENT_BIT) != 0);
}

test "Node - ref counting basic operations" {
    const allocator = std.testing.allocator;

    // Minimal vtable for testing
    const test_vtable = NodeVTable{
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
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initial ref_count should be 1
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());
    try std.testing.expect(!node.hasParent());

    // Acquire increments ref_count
    node.acquire();
    try std.testing.expectEqual(@as(u32, 2), node.getRefCount());

    // Release decrements ref_count
    node.release();
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());

    // Final release happens in defer
}

test "Node - has_parent flag operations" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
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
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially has no parent
    try std.testing.expect(!node.hasParent());

    // Set has_parent flag
    node.setHasParent(true);
    try std.testing.expect(node.hasParent());
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount()); // ref_count unchanged

    // Clear has_parent flag
    node.setHasParent(false);
    try std.testing.expect(!node.hasParent());
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());
}

test "Node - memory leak test" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
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
    };

    // Test 1: Simple create and release
    {
        const node = try Node.init(allocator, &test_vtable, .element);
        defer node.release();
    }

    // Test 2: Multiple acquire/release
    {
        const node = try Node.init(allocator, &test_vtable, .element);
        defer node.release();

        node.acquire();
        defer node.release();

        node.acquire();
        defer node.release();
    }

    // If we get here without leaks, std.testing.allocator validates success
}

test "Node - flag operations" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
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
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially not connected
    try std.testing.expect(!node.isConnected());

    // Set connected flag
    node.setConnected(true);
    try std.testing.expect(node.isConnected());

    // Clear connected flag
    node.setConnected(false);
    try std.testing.expect(!node.isConnected());

    // Check shadow tree flag
    try std.testing.expect(!node.isInShadowTree());
}

test "Node - vtable dispatch" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "custom-name";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return "custom-value";
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
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Test vtable dispatch
    try std.testing.expectEqualStrings("custom-name", node.nodeName());
    try std.testing.expectEqualStrings("custom-value", node.nodeValue().?);

    // Test error returns
    try std.testing.expectError(error.NotSupported, node.setNodeValue("value"));
    try std.testing.expectError(error.NotSupported, node.cloneNode(false));
}

test "Node - rare data allocation" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
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
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially no rare data
    try std.testing.expect(!node.hasRareData());
    try std.testing.expect(node.getRareData() == null);

    // Ensure rare data
    const rare = try node.ensureRareData();
    try std.testing.expect(node.hasRareData());
    try std.testing.expect(node.getRareData() != null);
    try std.testing.expectEqual(rare, node.getRareData().?);

    // Second call returns same instance
    const rare2 = try node.ensureRareData();
    try std.testing.expectEqual(rare, rare2);
}

test "Node - rare data cleanup" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
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
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Allocate rare data and add features
    const rare = try node.ensureRareData();

    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *anyopaque) void {}
    }.cb;

    try rare.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try rare.setUserData("key", @ptrCast(&ctx));

    // Cleanup happens in defer node.release()
    // If this test passes without leaks, cleanup worked
}

test "Node - addEventListener wrapper" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
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
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *anyopaque) void {}
    }.cb;

    // Test WHATWG-style API
    try node.addEventListener("click", callback, @ptrCast(&ctx), false, false, false);

    // Verify listener was added
    try std.testing.expect(node.hasEventListeners("click"));
    try std.testing.expect(!node.hasEventListeners("input"));

    const listeners = node.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 1), listeners.len);

    // Remove listener
    node.removeEventListener("click", callback, false);
    try std.testing.expect(!node.hasEventListeners("click"));
}

test "Node - hasChildNodes" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
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
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially no children
    try std.testing.expect(!node.hasChildNodes());

    // Create a child (but don't connect yet - that's Phase 2)
    const child = try Node.init(allocator, &test_vtable, .element);
    defer child.release();

    // Manually set first_child for testing
    node.first_child = child;
    try std.testing.expect(node.hasChildNodes());

    // Clean up manual connection
    node.first_child = null;
}

test "Node - parentElement" {
    const allocator = std.testing.allocator;
    const Element = @import("element.zig").Element;

    // Create parent element
    const parent_elem = try Element.create(allocator, "div");
    defer parent_elem.node.release();

    // Create child text node
    const Text = @import("text.zig").Text;
    const child = try Text.create(allocator, "content");
    defer child.node.release();

    // Initially no parent
    try std.testing.expect(child.node.parentElement() == null);

    // Manually set parent for testing (Phase 2 will do this via appendChild)
    child.node.parent_node = &parent_elem.node;

    // parentElement should return the element
    const retrieved_parent = child.node.parentElement();
    try std.testing.expect(retrieved_parent != null);
    try std.testing.expectEqual(parent_elem, retrieved_parent.?);

    // Clean up manual connection
    child.node.parent_node = null;
}

test "Node - getOwnerDocument" {
    const allocator = std.testing.allocator;
    const Document = @import("document.zig").Document;

    // Create document
    const doc = try Document.init(allocator);
    defer doc.release();

    // Document's ownerDocument should be null per spec
    try std.testing.expect(doc.node.getOwnerDocument() == null);

    // Create element via document
    const elem = try doc.createElement("div");
    defer elem.node.release();

    // Element's ownerDocument should be the document
    const owner = elem.node.getOwnerDocument();
    try std.testing.expect(owner != null);
    try std.testing.expectEqual(doc, owner.?);

    // Create text node via document
    const text = try doc.createTextNode("test");
    defer text.node.release();

    // Text's ownerDocument should also be the document
    const text_owner = text.node.getOwnerDocument();
    try std.testing.expect(text_owner != null);
    try std.testing.expectEqual(doc, text_owner.?);
}

test "Node - childNodes" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
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
    };

    const parent = try Node.init(allocator, &test_vtable, .element);
    defer parent.release();

    // Initially no children
    const empty_list = parent.childNodes();
    try std.testing.expectEqual(@as(usize, 0), empty_list.length());

    // Add a child manually (Phase 2 will do this via appendChild)
    const child1 = try Node.init(allocator, &test_vtable, .element);
    defer child1.release();

    const child2 = try Node.init(allocator, &test_vtable, .element);
    defer child2.release();

    parent.first_child = child1;
    parent.last_child = child2;
    child1.next_sibling = child2;
    child1.parent_node = parent;
    child2.parent_node = parent;

    // NodeList should reflect children
    const list = parent.childNodes();
    try std.testing.expectEqual(@as(usize, 2), list.length());
    try std.testing.expectEqual(child1, list.item(0).?);
    try std.testing.expectEqual(child2, list.item(1).?);
    try std.testing.expect(list.item(2) == null);

    // Clean up manual connections
    parent.first_child = null;
    parent.last_child = null;
    child1.next_sibling = null;
    child1.parent_node = null;
    child2.parent_node = null;
}
