//! RareData pattern implementation for Node.
//!
//! This module implements WebKit's RareData pattern to save memory on nodes.
//! Most nodes don't need event listeners, mutation observers, or user data.
//! By allocating these features on-demand, we save 40-80 bytes per common node.
//!
//! ## Architecture Pattern (from WebKit)
//! - Common case: rare_data = null (most nodes, 0 bytes overhead)
//! - Rare case: rare_data allocated (only when features used)
//! - Saves memory on 90%+ of nodes in typical DOM tree
//!
//! Reference: WebKit's NodeRareData, ElementRareData

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Callback function type for mutation observers.
///
/// Called when a mutation occurs on an observed node.
/// Context is user-provided data (e.g., JS object, CDP handler, etc.)
pub const MutationCallback = *const fn (context: *anyopaque) void;

/// Callback function type for event listeners.
///
/// Called when an event is dispatched to a node.
/// Context is user-provided data (e.g., JS function, callback object, etc.)
pub const EventCallback = *const fn (context: *anyopaque) void;

/// Event listener registration.
pub const EventListener = struct {
    /// Event type (e.g., "click", "input", "change")
    event_type: []const u8,

    /// Callback function
    callback: EventCallback,

    /// User context (passed to callback)
    context: *anyopaque,

    /// Capture phase (true) or bubble phase (false)
    capture: bool,

    /// Remove after first invocation
    once: bool,

    /// Passive listener (won't call preventDefault)
    passive: bool,
};

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
        fn cb(context: *anyopaque) void {
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
        fn cb(_: *anyopaque) void {}
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
            fn cb(_: *anyopaque) void {}
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
        const cb1 = struct {
            fn cb(_: *anyopaque) void {}
        }.cb;

        try rare_data.addEventListener(.{
            .event_type = "click",
            .callback = cb1,
            .context = @ptrCast(&ctx),
            .capture = false,
            .once = false,
            .passive = false,
        });

        try rare_data.addMutationObserver(.{
            .callback = cb1,
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
        fn cb(_: *anyopaque) void {}
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
    try rare_data.addMutationObserver(.{
        .callback = callback,
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
