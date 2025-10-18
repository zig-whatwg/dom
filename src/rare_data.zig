//! RareData Pattern (Performance Optimization)
//!
//! This module implements the RareData pattern for memory optimization, inspired by WebKit's
//! NodeRareData and ElementRareData. Most DOM nodes don't need event listeners, mutation
//! observers, or user data. By allocating these features on-demand only when used, we save
//! significant memory on typical DOM trees where 90%+ of nodes are simple.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§2.7 Interface EventTarget**: https://dom.spec.whatwg.org/#interface-eventtarget (event listeners)
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node (base node features)
//! - **§3 Mutation Observers**: https://dom.spec.whatwg.org/#mutation-observers (optional feature)
//!
//! ## MDN Documentation
//!
//! - EventTarget: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget
//! - MutationObserver: https://developer.mozilla.org/en-US/docs/Web/API/MutationObserver
//! - Node: https://developer.mozilla.org/en-US/docs/Web/API/Node
//! - Memory optimization: https://developer.mozilla.org/en-US/docs/Web/Performance/Optimizing_startup_performance
//!
//! ## Core Features
//!
//! ### Lazy Allocation
//! RareData is only allocated when a node uses rare features:
//! ```zig
//! const node = try Node.init(allocator, .element_node, "div");
//! defer node.release();
//! // node.rare_data = null (common case, 0 bytes overhead)
//!
//! // First addEventListener() allocates RareData
//! try node.addEventListener("click", callback, ctx, .{});
//! // node.rare_data != null (now allocated, ~80 bytes)
//! ```
//!
//! ### Memory Savings
//! Compare memory usage with and without RareData pattern:
//! ```zig
//! // WITHOUT RareData (all features always allocated):
//! // Every node: 96 + 80 = 176 bytes
//! // 100,000 nodes: 17.6 MB
//!
//! // WITH RareData (lazy allocation):
//! // Common nodes (90%): 96 bytes
//! // Rare nodes (10%): 96 + 8 (pointer) + 80 (RareData) = 184 bytes
//! // 100,000 nodes: 90K×96 + 10K×184 = 10.5 MB
//! // Savings: 40% memory reduction!
//! ```
//!
//! ### Stored Features
//! RareData holds optional node features:
//! ```zig
//! pub const NodeRareData = struct {
//!     event_listeners: ArrayList(EventListener),  // EventTarget feature
//!     mutation_observers: ArrayList(MutationObserver),  // MutationObserver feature
//!     user_data: ?*anyopaque,  // Custom user data
//! };
//! ```
//!
//! ## RareData Pattern
//!
//! The pattern works as follows:
//!
//! **1. Node has optional pointer:**
//! ```zig
//! pub const Node = struct {
//!     rare_data: ?*NodeRareData = null,  // null by default (8 bytes pointer)
//!     // ... other fields ...
//! };
//! ```
//!
//! **2. Allocate on first use:**
//! ```zig
//! pub fn ensureRareData(self: *Node) !*NodeRareData {
//!     if (self.rare_data == null) {
//!         self.rare_data = try self.allocator.create(NodeRareData);
//!         self.rare_data.?.* = NodeRareData.init(self.allocator);
//!     }
//!     return self.rare_data.?;
//! }
//! ```
//!
//! **3. Access when needed:**
//! ```zig
//! pub fn addEventListener(self: *Node, ...) !void {
//!     const rare_data = try self.ensureRareData();  // Allocate if needed
//!     try rare_data.event_listeners.append(...);
//! }
//! ```
//!
//! ## Memory Management
//!
//! RareData is owned by the Node and freed when Node is released:
//! ```zig
//! const node = try Node.init(allocator, .element_node, "div");
//! defer node.release(); // Automatically frees rare_data if allocated
//!
//! try node.addEventListener("click", callback, ctx, .{});
//! // rare_data allocated
//!
//! // node.release() will:
//! // 1. Call rare_data.deinit() (frees ArrayList)
//! // 2. Free rare_data struct
//! // 3. Free node
//! ```
//!
//! ## Usage Examples
//!
//! ### Checking if RareData Exists
//! ```zig
//! fn hasEventListeners(node: *Node) bool {
//!     if (node.rare_data) |rare_data| {
//!         return rare_data.event_listeners.items.len > 0;
//!     }
//!     return false;
//! }
//! ```
//!
//! ### Lazy Feature Access
//! ```zig
//! fn addMutationObserver(node: *Node, observer: MutationObserver) !void {
//!     const rare_data = try node.ensureRareData();
//!     try rare_data.mutation_observers.append(observer);
//! }
//! ```
//!
//! ### User Data Storage
//! ```zig
//! fn setUserData(node: *Node, data: *anyopaque) !void {
//!     const rare_data = try node.ensureRareData();
//!     rare_data.user_data = data;
//! }
//!
//! fn getUserData(node: *Node) ?*anyopaque {
//!     if (node.rare_data) |rare_data| {
//!         return rare_data.user_data;
//!     }
//!     return null;
//! }
//! ```
//!
//! ## Common Patterns
//!
//! ### Conditional Cleanup
//! ```zig
//! fn cleanupNode(node: *Node) void {
//!     if (node.rare_data) |rare_data| {
//!         // Only cleanup if allocated
//!         for (rare_data.event_listeners.items) |listener| {
//!             // Cleanup listeners
//!         }
//!         rare_data.event_listeners.clearRetainingCapacity();
//!     }
//! }
//! ```
//!
//! ### Statistics Collection
//! ```zig
//! fn countNodesWithRareData(root: *Node) struct { total: usize, with_rare: usize } {
//!     var total: usize = 0;
//!     var with_rare: usize = 0;
//!
//!     var current = root;
//!     // Traverse tree
//!     total += 1;
//!     if (current.rare_data != null) {
//!         with_rare += 1;
//!     }
//!
//!     return .{ .total = total, .with_rare = with_rare };
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Avoid Early Allocation** - Don't call ensureRareData() unless necessary
//! 2. **Batch Operations** - Minimize rare_data allocations by batching feature additions
//! 3. **Check Before Access** - Use `if (rare_data) |rd|` pattern for conditional access
//! 4. **Memory Profiling** - Track rare_data allocation rate in production
//! 5. **Optimize Common Path** - Fast path assumes rare_data = null (no allocation)
//! 6. **Consider Alternatives** - For features used by 50%+ of nodes, consider moving to Node struct
//!
//! ## Implementation Notes
//!
//! - RareData pattern inspired by WebKit's NodeRareData/ElementRareData
//! - Typical DOM trees: 90%+ nodes don't need rare features
//! - Memory savings: 40-50% on large DOM trees
//! - Trade-off: Extra pointer indirection when rare_data IS used
//! - ensureRareData() is idempotent (safe to call multiple times)
//! - RareData freed automatically when Node is released
//! - Event listeners, mutation observers, user data stored together
//! - Could be split into multiple rare data types for finer granularity

const std = @import("std");
const Allocator = std.mem.Allocator;
const Event = @import("event.zig").Event;

// Re-export EventTarget types for backward compatibility
pub const EventCallback = @import("event_target.zig").EventCallback;
pub const EventListener = @import("event_target.zig").EventListener;

/// Callback function type for mutation observers.
///
/// Called when a mutation occurs on an observed node.
/// Context is user-provided data (e.g., JS object, CDP handler, etc.)
pub const MutationCallback = *const fn (context: *anyopaque) void;

/// Mutation observer registration.
pub const MutationObserver = struct {
    /// Callback function
    callback: MutationCallback,

    /// User context (passed to callback)
    context: *anyopaque,

    /// Observe child list changes
    observe_children: bool,

    /// Observe attribute changes
    observe_attributes: bool,

    /// Observe character data changes
    observe_character_data: bool,

    /// Observe subtree (descendants) changes
    observe_subtree: bool,
};

/// Rare data storage for Node.
///
/// Allocated on-demand when node uses rare features.
/// Only ~10% of nodes in typical DOM tree need this.
///
/// ## Memory Savings
/// Without RareData:
/// - Every node: 96 + 80 = 176 bytes
/// - 100,000 nodes: 17.6 MB
///
/// With RareData:
/// - Common nodes (90%): 96 bytes
/// - Rare nodes (10%): 96 + 80 = 176 bytes
/// - 100,000 nodes: (90,000 × 96) + (10,000 × 176) = 8.64 + 1.76 = 10.4 MB
/// - Savings: 7.2 MB (41%)
pub const NodeRareData = struct {
    allocator: Allocator,

    /// Event listeners (allocated when first listener added)
    /// Key: event type, Value: list of listeners for that type
    event_listeners: ?std.StringHashMap(std.ArrayList(EventListener)),

    /// Mutation observers (allocated when first observer added)
    mutation_observers: ?std.ArrayList(MutationObserver),

    /// User data (allocated when first data set)
    /// Key: data key, Value: opaque user data pointer
    user_data: ?std.StringHashMap(*anyopaque),

    /// Custom element data (allocated for custom elements)
    /// Opaque pointer to custom element definition/state
    custom_element_data: ?*anyopaque,

    /// Animation data (allocated for animated nodes)
    /// Opaque pointer to animation state/timeline
    animation_data: ?*anyopaque,

    /// Shadow root (allocated for elements with attached shadow DOM)
    /// OWNING pointer - Element owns ShadowRoot via RareData
    /// ShadowRoot freed when Element is released
    shadow_root: ?*anyopaque,

    /// Assigned slot (WEAK pointer for Slottable mixin)
    /// Points to the slot element this node is assigned to
    /// Null if not assigned to any slot
    /// WEAK reference - slot element owns itself, this node doesn't own the slot
    assigned_slot: ?*anyopaque,

    /// Creates a new RareData structure.
    ///
    /// All fields initialized to null (allocated on first use).
    pub fn init(allocator: Allocator) NodeRareData {
        return .{
            .allocator = allocator,
            .event_listeners = null,
            .mutation_observers = null,
            .user_data = null,
            .custom_element_data = null,
            .animation_data = null,
            .shadow_root = null,
            .assigned_slot = null,
        };
    }

    /// Cleans up all allocated rare data.
    pub fn deinit(self: *NodeRareData) void {
        // Clean up event listeners
        if (self.event_listeners) |*listeners| {
            var it = listeners.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.deinit(self.allocator);
            }
            listeners.deinit();
        }

        // Clean up mutation observers
        if (self.mutation_observers) |*observers| {
            observers.deinit(self.allocator);
        }

        // Clean up user data
        if (self.user_data) |*data| {
            data.deinit();
        }

        // Clean up shadow root (OWNING pointer)
        if (self.shadow_root) |shadow_ptr| {
            const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
            const shadow: *ShadowRoot = @ptrCast(@alignCast(shadow_ptr));
            shadow.node.release();
        }

        // Note: custom_element_data and animation_data are opaque pointers
        // Caller is responsible for cleaning up their contents before deinit
    }

    /// Ensures event listener map is allocated.
    fn ensureEventListeners(self: *NodeRareData) !*std.StringHashMap(std.ArrayList(EventListener)) {
        if (self.event_listeners == null) {
            self.event_listeners = std.StringHashMap(std.ArrayList(EventListener)).init(self.allocator);
        }
        return &self.event_listeners.?;
    }

    /// Ensures mutation observer list is allocated.
    fn ensureMutationObservers(self: *NodeRareData) !*std.ArrayList(MutationObserver) {
        if (self.mutation_observers == null) {
            self.mutation_observers = std.ArrayList(MutationObserver){};
        }
        return &self.mutation_observers.?;
    }

    /// Ensures user data map is allocated.
    fn ensureUserData(self: *NodeRareData) !*std.StringHashMap(*anyopaque) {
        if (self.user_data == null) {
            self.user_data = std.StringHashMap(*anyopaque).init(self.allocator);
        }
        return &self.user_data.?;
    }

    // === Event Listener Management ===

    /// Adds an event listener for the specified event type.
    ///
    /// ## Parameters
    /// - `listener`: Event listener configuration
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate storage
    pub fn addEventListener(self: *NodeRareData, listener: EventListener) !void {
        const listeners = try self.ensureEventListeners();

        const result = try listeners.getOrPut(listener.event_type);
        if (!result.found_existing) {
            result.value_ptr.* = std.ArrayList(EventListener){};
        }

        try result.value_ptr.append(self.allocator, listener);
    }

    /// Removes an event listener.
    ///
    /// Matches by event type, callback pointer, and capture phase.
    ///
    /// ## Returns
    /// true if listener was found and removed, false otherwise
    pub fn removeEventListener(
        self: *NodeRareData,
        event_type: []const u8,
        callback: EventCallback,
        capture: bool,
    ) bool {
        if (self.event_listeners) |*listeners| {
            if (listeners.getPtr(event_type)) |list| {
                // Find matching listener
                for (list.items, 0..) |listener, i| {
                    if (listener.callback == callback and listener.capture == capture) {
                        _ = list.swapRemove(i);

                        // Clean up empty list
                        if (list.items.len == 0) {
                            list.deinit(self.allocator);
                            _ = listeners.remove(event_type);
                        }

                        return true;
                    }
                }
            }
        }

        return false;
    }

    /// Returns all event listeners for a specific event type.
    ///
    /// ## Returns
    /// Slice of listeners (empty if none registered)
    pub fn getEventListeners(self: *const NodeRareData, event_type: []const u8) []const EventListener {
        const listeners = self.event_listeners orelse return &[_]EventListener{};
        const list = listeners.get(event_type) orelse return &[_]EventListener{};
        return list.items;
    }

    /// Returns true if node has any event listeners for the specified type.
    pub fn hasEventListeners(self: *const NodeRareData, event_type: []const u8) bool {
        const listeners = self.event_listeners orelse return false;
        return listeners.contains(event_type);
    }

    // === Mutation Observer Management ===

    /// Adds a mutation observer.
    ///
    /// ## Parameters
    /// - `observer`: Mutation observer configuration
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate storage
    pub fn addMutationObserver(self: *NodeRareData, observer: MutationObserver) !void {
        const observers = try self.ensureMutationObservers();
        try observers.append(self.allocator, observer);
    }

    /// Removes a mutation observer.
    ///
    /// Matches by callback pointer and context.
    ///
    /// ## Returns
    /// true if observer was found and removed, false otherwise
    pub fn removeMutationObserver(
        self: *NodeRareData,
        callback: MutationCallback,
        context: *anyopaque,
    ) bool {
        if (self.mutation_observers) |*observers| {
            for (observers.items, 0..) |observer, i| {
                if (observer.callback == callback and observer.context == context) {
                    _ = observers.swapRemove(i);
                    return true;
                }
            }
        }

        return false;
    }

    /// Returns all mutation observers.
    pub fn getMutationObservers(self: *const NodeRareData) []const MutationObserver {
        const observers = self.mutation_observers orelse return &[_]MutationObserver{};
        return observers.items;
    }

    /// Returns true if node has any mutation observers.
    pub fn hasMutationObservers(self: *const NodeRareData) bool {
        if (self.mutation_observers) |observers| {
            return observers.items.len > 0;
        }
        return false;
    }

    // === User Data Management ===

    /// Sets user data with the specified key.
    ///
    /// ## Parameters
    /// - `key`: Data key (string identifier)
    /// - `value`: Opaque pointer to user data
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate storage
    pub fn setUserData(self: *NodeRareData, key: []const u8, value: *anyopaque) !void {
        const data = try self.ensureUserData();
        try data.put(key, value);
    }

    /// Gets user data for the specified key.
    ///
    /// ## Returns
    /// User data pointer or null if not found
    pub fn getUserData(self: *const NodeRareData, key: []const u8) ?*anyopaque {
        const data = self.user_data orelse return null;
        return data.get(key);
    }

    /// Removes user data for the specified key.
    ///
    /// ## Returns
    /// true if data was found and removed, false otherwise
    pub fn removeUserData(self: *NodeRareData, key: []const u8) bool {
        if (self.user_data) |*data| {
            return data.remove(key);
        }
        return false;
    }

    /// Returns true if node has user data for the specified key.
    pub fn hasUserData(self: *const NodeRareData, key: []const u8) bool {
        const data = self.user_data orelse return false;
        return data.contains(key);
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "NodeRareData - initialization" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Initially all fields are null (not allocated)
    try std.testing.expect(rare_data.event_listeners == null);
    try std.testing.expect(rare_data.mutation_observers == null);
    try std.testing.expect(rare_data.user_data == null);
    try std.testing.expect(rare_data.custom_element_data == null);
    try std.testing.expect(rare_data.animation_data == null);
}

test "NodeRareData - event listeners" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Test context
    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const val: *u32 = @ptrCast(@alignCast(context));
            _ = val;
        }
    }.cb;

    // Add event listener
    try rare_data.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    // Verify listener was added
    try std.testing.expect(rare_data.hasEventListeners("click"));
    try std.testing.expect(!rare_data.hasEventListeners("input"));

    const listeners = rare_data.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 1), listeners.len);
    try std.testing.expectEqual(callback, listeners[0].callback);
    try std.testing.expect(!listeners[0].capture);

    // Add another listener for same event
    try rare_data.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = true, // Different capture phase
        .once = false,
        .passive = false,
    });

    const listeners2 = rare_data.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 2), listeners2.len);

    // Remove one listener
    const removed = rare_data.removeEventListener("click", callback, false);
    try std.testing.expect(removed);

    const listeners3 = rare_data.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 1), listeners3.len);
    try std.testing.expect(listeners3[0].capture); // Only capture phase remains
}

test "NodeRareData - mutation observers" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Test context
    var ctx: u32 = 42;
    const callback = struct {
        fn cb(context: *anyopaque) void {
            const val: *u32 = @ptrCast(@alignCast(context));
            _ = val;
        }
    }.cb;

    // Initially no observers
    try std.testing.expect(!rare_data.hasMutationObservers());
    try std.testing.expectEqual(@as(usize, 0), rare_data.getMutationObservers().len);

    // Add mutation observer
    try rare_data.addMutationObserver(.{
        .callback = callback,
        .context = @ptrCast(&ctx),
        .observe_children = true,
        .observe_attributes = true,
        .observe_character_data = false,
        .observe_subtree = false,
    });

    // Verify observer was added
    try std.testing.expect(rare_data.hasMutationObservers());

    const observers = rare_data.getMutationObservers();
    try std.testing.expectEqual(@as(usize, 1), observers.len);
    try std.testing.expectEqual(callback, observers[0].callback);
    try std.testing.expect(observers[0].observe_children);
    try std.testing.expect(observers[0].observe_attributes);
    try std.testing.expect(!observers[0].observe_character_data);

    // Add another observer
    try rare_data.addMutationObserver(.{
        .callback = callback,
        .context = @ptrCast(&ctx),
        .observe_children = false,
        .observe_attributes = false,
        .observe_character_data = true,
        .observe_subtree = true,
    });

    try std.testing.expectEqual(@as(usize, 2), rare_data.getMutationObservers().len);

    // Remove observer
    const removed = rare_data.removeMutationObserver(callback, @ptrCast(&ctx));
    try std.testing.expect(removed);

    try std.testing.expectEqual(@as(usize, 1), rare_data.getMutationObservers().len);
}

test "NodeRareData - user data" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Test data
    var value1: u32 = 42;
    var value2: u32 = 100;

    // Initially no user data
    try std.testing.expect(!rare_data.hasUserData("key1"));
    try std.testing.expect(rare_data.getUserData("key1") == null);

    // Set user data
    try rare_data.setUserData("key1", @ptrCast(&value1));
    try std.testing.expect(rare_data.hasUserData("key1"));

    const retrieved1 = rare_data.getUserData("key1");
    try std.testing.expect(retrieved1 != null);
    const val1: *u32 = @ptrCast(@alignCast(retrieved1.?));
    try std.testing.expectEqual(@as(u32, 42), val1.*);

    // Set another key
    try rare_data.setUserData("key2", @ptrCast(&value2));
    try std.testing.expect(rare_data.hasUserData("key2"));

    // Update existing key
    value1 = 99;
    const retrieved1b = rare_data.getUserData("key1");
    const val1b: *u32 = @ptrCast(@alignCast(retrieved1b.?));
    try std.testing.expectEqual(@as(u32, 99), val1b.*);

    // Remove user data
    const removed = rare_data.removeUserData("key1");
    try std.testing.expect(removed);
    try std.testing.expect(!rare_data.hasUserData("key1"));
    try std.testing.expect(rare_data.getUserData("key1") == null);

    // key2 still exists
    try std.testing.expect(rare_data.hasUserData("key2"));
}

test "NodeRareData - multiple event types" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, _: *anyopaque) void {}
    }.cb;

    // Add listeners for different events
    try rare_data.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try rare_data.addEventListener(.{
        .event_type = "input",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try rare_data.addEventListener(.{
        .event_type = "change",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    // Verify all events registered
    try std.testing.expect(rare_data.hasEventListeners("click"));
    try std.testing.expect(rare_data.hasEventListeners("input"));
    try std.testing.expect(rare_data.hasEventListeners("change"));
    try std.testing.expect(!rare_data.hasEventListeners("blur"));

    // Each event has one listener
    try std.testing.expectEqual(@as(usize, 1), rare_data.getEventListeners("click").len);
    try std.testing.expectEqual(@as(usize, 1), rare_data.getEventListeners("input").len);
    try std.testing.expectEqual(@as(usize, 1), rare_data.getEventListeners("change").len);
}

test "NodeRareData - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple init/deinit
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();
    }

    // Test 2: With event listeners
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();

        var ctx: u32 = 42;
        const callback = struct {
            fn cb(_: *Event, _: *anyopaque) void {}
        }.cb;

        try rare_data.addEventListener(.{
            .event_type = "click",
            .callback = callback,
            .context = @ptrCast(&ctx),
            .capture = false,
            .once = false,
            .passive = false,
        });

        try rare_data.addEventListener(.{
            .event_type = "input",
            .callback = callback,
            .context = @ptrCast(&ctx),
            .capture = false,
            .once = false,
            .passive = false,
        });
    }

    // Test 3: With mutation observers
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();

        var ctx: u32 = 42;
        const callback = struct {
            fn cb(_: *anyopaque) void {}
        }.cb;

        try rare_data.addMutationObserver(.{
            .callback = callback,
            .context = @ptrCast(&ctx),
            .observe_children = true,
            .observe_attributes = true,
            .observe_character_data = false,
            .observe_subtree = false,
        });
    }

    // Test 4: With user data
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();

        var value: u32 = 42;
        try rare_data.setUserData("key", @ptrCast(&value));
    }

    // Test 5: With everything
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();

        var ctx: u32 = 42;
        const callback = struct {
            fn cb(_: *Event, _: *anyopaque) void {}
        }.cb;

        try rare_data.addEventListener(.{
            .event_type = "click",
            .callback = callback,
            .context = @ptrCast(&ctx),
            .capture = false,
            .once = false,
            .passive = false,
        });

        const mut_callback = struct {
            fn cb(_: *anyopaque) void {}
        }.cb;

        try rare_data.addMutationObserver(.{
            .callback = mut_callback,
            .context = @ptrCast(&ctx),
            .observe_children = true,
            .observe_attributes = false,
            .observe_character_data = false,
            .observe_subtree = false,
        });

        try rare_data.setUserData("key", @ptrCast(&ctx));
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "NodeRareData - lazy allocation" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Initially nothing allocated
    try std.testing.expect(rare_data.event_listeners == null);
    try std.testing.expect(rare_data.mutation_observers == null);
    try std.testing.expect(rare_data.user_data == null);

    // Add event listener - only event_listeners allocated
    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, _: *anyopaque) void {}
    }.cb;

    try rare_data.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try std.testing.expect(rare_data.event_listeners != null);
    try std.testing.expect(rare_data.mutation_observers == null); // Still null
    try std.testing.expect(rare_data.user_data == null); // Still null

    // Add user data - now user_data allocated
    try rare_data.setUserData("key", @ptrCast(&ctx));

    try std.testing.expect(rare_data.event_listeners != null);
    try std.testing.expect(rare_data.mutation_observers == null); // Still null
    try std.testing.expect(rare_data.user_data != null);

    // Add mutation observer - now everything allocated
    const mut_callback2 = struct {
        fn cb(_: *anyopaque) void {}
    }.cb;

    try rare_data.addMutationObserver(.{
        .callback = mut_callback2,
        .context = @ptrCast(&ctx),
        .observe_children = true,
        .observe_attributes = false,
        .observe_character_data = false,
        .observe_subtree = false,
    });

    try std.testing.expect(rare_data.event_listeners != null);
    try std.testing.expect(rare_data.mutation_observers != null);
    try std.testing.expect(rare_data.user_data != null);
}
