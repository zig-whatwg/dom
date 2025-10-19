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
//!     event_listeners: ?StringHashMap(ArrayList(EventListener)),  // EventTarget feature
//!     mutation_observers: ?ArrayList(*anyopaque),  // MutationObserver registrations (WEAK)
//!     user_data: ?StringHashMap(*anyopaque),  // Custom user data
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
//! ### User Data Storage
//! ```zig
//! fn setUserData(node: *Node, key: []const u8, data: *anyopaque) !void {
//!     const rare_data = try node.ensureRareData();
//!     try rare_data.setUserData(key, data);
//! }
//!
//! fn getUserData(node: *Node, key: []const u8) ?*anyopaque {
//!     if (node.rare_data) |rare_data| {
//!         return rare_data.getUserData(key);
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

    /// Mutation observer registrations (allocated when first observer registered)
    /// WEAK pointers - MutationObserver owns registrations, not Node
    /// Registrations removed automatically when observer.disconnect() called
    mutation_observers: ?std.ArrayList(*anyopaque),

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

        // Clean up mutation observers ArrayList
        // Note: Pointers are WEAK (MutationObserver owns registrations)
        // But we own the ArrayList itself
        if (self.mutation_observers) |*list| {
            list.deinit(self.allocator);
        }

        // Clean up user data
        if (self.user_data) |*data| {
            data.deinit();
        }

        // Clean up shadow root (OWNING pointer)
        if (self.shadow_root) |shadow_ptr| {
            const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
            const shadow: *ShadowRoot = @ptrCast(@alignCast(shadow_ptr));
            shadow.prototype.release();
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
