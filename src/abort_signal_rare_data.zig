//! SignalRareData (AbortSignal Optimization)
//!
//! This module implements the RareData pattern specifically for AbortSignal. Similar to
//! NodeRareData, this enables memory optimization by allocating signal features (event
//! listeners, abort algorithms, dependent signals) only when actually used. Most signals
//! are simple and don't need these features.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§3.1 Interface AbortSignal**: https://dom.spec.whatwg.org/#interface-abortsignal
//! - **§2.7 Interface EventTarget**: https://dom.spec.whatwg.org/#interface-eventtarget (event listeners)
//! - **§3.1.3 Abort Algorithms**: https://dom.spec.whatwg.org/#abortsignal-abort-algorithms
//!
//! ## MDN Documentation
//!
//! - AbortSignal: https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal
//! - AbortSignal.any(): https://developer.mozilla.org/en-US/docs/Web/API/AbortSignal/any_static
//! - EventTarget: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget
//!
//! ## Core Features
//!
//! ### Lazy Allocation
//! SignalRareData is only allocated when signal uses optional features:
//! ```zig
//! const signal = try AbortSignal.init(allocator);
//! defer signal.deinit();
//! // signal.rare_data = null (48 bytes)
//!
//! try signal.addEventListener("abort", callback, ctx, .{});
//! // signal.rare_data now allocated (~128 bytes total)
//! ```
//!
//! ### Memory Comparison
//! Compare memory with and without RareData pattern:
//! ```zig
//! // WITHOUT RareData (all features always allocated):
//! // Every signal: 48 + 80 = 128 bytes
//! // 10,000 signals: 1.28 MB
//!
//! // WITH RareData (lazy allocation):
//! // Simple signals (80%): 48 bytes
//! // Signals with features (20%): 128 bytes
//! // 10,000 signals: 8K×48 + 2K×128 = 640 KB
//! // Savings: 50% memory reduction!
//! ```
//!
//! ### Stored Features
//! SignalRareData holds optional AbortSignal features:
//! ```zig
//! pub const SignalRareData = struct {
//!     event_listeners: ?StringHashMap(ArrayList(EventListener)),
//!     abort_algorithms: ArrayList(AbortAlgorithmStorage),
//!     source_signals: ?ArrayList(*anyopaque),
//!     dependent_signals: ?ArrayList(*anyopaque),
//! };
//! ```
//!
//! ## SignalRareData Structure
//!
//! SignalRareData contains four categories of optional features:
//!
//! **1. Event Listeners** (EventTarget feature)
//! - Null until first addEventListener()
//! - HashMap of event type → listener list
//! - Most signals don't need listeners
//!
//! **2. Abort Algorithms** (run before abort event)
//! - ArrayList of callback + context pairs
//! - Used by Fetch API, Streams for cleanup
//! - Only needed for advanced use cases
//!
//! **3. Source Signals** (for AbortSignal.any())
//! - Null for independent signals
//! - List of signals this depends on
//! - Only for composite signals
//!
//! **4. Dependent Signals** (for AbortSignal.any())
//! - Null if no dependents
//! - List of signals that depend on this
//! - Only for signals used in AbortSignal.any()
//!
//! ## Memory Management
//!
//! SignalRareData is owned by AbortSignal and freed automatically:
//! ```zig
//! const signal = try AbortSignal.init(allocator);
//! defer signal.deinit(); // Frees rare_data if allocated
//!
//! try signal.addEventListener("abort", callback, ctx, .{});
//! // rare_data allocated
//!
//! // signal.deinit() will:
//! // 1. Call rare_data.deinit() (frees all ArrayLists)
//! // 2. Free rare_data struct
//! // 3. Free signal
//! ```
//!
//! ## Usage Examples
//!
//! ### Checking for Features
//! ```zig
//! fn hasListeners(signal: *AbortSignal) bool {
//!     if (signal.rare_data) |rare_data| {
//!         if (rare_data.event_listeners) |listeners| {
//!             return listeners.count() > 0;
//!         }
//!     }
//!     return false;
//! }
//! ```
//!
//! ### Abort Algorithm Storage
//! ```zig
//! fn addCleanup(signal: *AbortSignal, cleanup_fn: AbortCallback, ctx: *anyopaque) !void {
//!     const rare_data = try signal.ensureRareData();
//!
//!     const algorithm = try allocator.create(AbortAlgorithm);
//!     algorithm.* = .{ .callback = cleanup_fn, .context = ctx };
//!
//!     try rare_data.abort_algorithms.append(@ptrCast(algorithm));
//! }
//! ```
//!
//! ### Dependent Signal Tracking
//! ```zig
//! fn trackDependent(source: *AbortSignal, dependent: *AbortSignal) !void {
//!     const rare_data = try source.ensureRareData();
//!
//!     if (rare_data.dependent_signals == null) {
//!         rare_data.dependent_signals = std.ArrayList(*anyopaque).init(allocator);
//!     }
//!
//!     try rare_data.dependent_signals.?.append(@ptrCast(dependent));
//! }
//! ```
//!
//! ## Common Patterns
//!
//! ### Conditional Cleanup
//! ```zig
//! fn cleanupSignal(signal: *AbortSignal) void {
//!     if (signal.rare_data) |rare_data| {
//!         // Cleanup abort algorithms
//!         for (rare_data.abort_algorithms.items) |algo_ptr| {
//!             const algo = @as(*AbortAlgorithm, @ptrCast(@alignCast(algo_ptr)));
//!             allocator.destroy(algo);
//!         }
//!         rare_data.abort_algorithms.clearRetainingCapacity();
//!     }
//! }
//! ```
//!
//! ### Memory Statistics
//! ```zig
//! fn getSignalMemoryStats(signal: *AbortSignal) struct { base: usize, rare: usize } {
//!     const base_size = 48; // AbortSignal size
//!     const rare_size = if (signal.rare_data != null) 80 else 0;
//!     return .{ .base = base_size, .rare = rare_size };
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Avoid Early Allocation** - Don't call ensureRareData() unless necessary
//! 2. **Share Signals** - Reuse signals across operations instead of creating many
//! 3. **Simple Signals** - Most signals don't need listeners or algorithms
//! 4. **Batch Operations** - Add multiple algorithms before triggering abort
//! 5. **Lazy Init** - All RareData fields start null, allocated on demand
//! 6. **Memory Profiling** - Track rare_data allocation rate in production
//!
//! ## Implementation Notes
//!
//! - SignalRareData inspired by WebKit's NodeRareData pattern
//! - Most signals (80%+) don't need rare features
//! - Memory savings: 50% on typical signal-heavy applications
//! - anyopaque used to avoid circular dependencies with AbortSignal
//! - Source/dependent signals are weak references (not refcounted)
//! - Event listeners use StringHashMap for fast type lookup
//! - Abort algorithms run in order added (FIFO)
//! - All fields lazy-initialized (null until first use)

const std = @import("std");
const Allocator = std.mem.Allocator;
const EventListener = @import("event_target.zig").EventListener;
const EventCallback = @import("event_target.zig").EventCallback;

// Forward declaration to break dependency cycle
// AbortAlgorithm is defined in abort_signal.zig as a struct with callback + context
// We use anyopaque here to store it without importing abort_signal.zig
const AbortAlgorithmStorage = *anyopaque;

/// Rare data storage for AbortSignal.
///
/// Allocated on-demand when signal uses rare features:
/// - Event listeners (addEventListener)
/// - Abort algorithms (addAlgorithm)
/// - Dependent signals (AbortSignal.any)
/// - Source signals (AbortSignal.any)
pub const SignalRareData = struct {
    /// Memory allocator
    allocator: Allocator,

    /// Event listeners (inherited from EventTarget)
    /// Null until first addEventListener call
    /// Key: event type, Value: list of listeners for that type
    event_listeners: ?std.StringHashMap(std.ArrayList(EventListener)) = null,

    /// Abort algorithms (run when signal aborts)
    /// Allocated immediately (empty ArrayList)
    /// Algorithms run BEFORE abort event fires
    /// Each element is an allocated AbortAlgorithm struct (stored as anyopaque)
    abort_algorithms: std.ArrayList(AbortAlgorithmStorage),

    /// Source signals (for dependent signals only)
    /// Null if this is independent signal
    /// Contains raw pointers to signals this depends on
    /// IMPORTANT: These are NOT strong references
    /// Type: *AbortSignal (stored as anyopaque to avoid circular dependency)
    source_signals: ?std.ArrayList(*anyopaque) = null,

    /// Dependent signals (signals that depend on this)
    /// Null if no dependents
    /// Contains raw pointers to signals that depend on this
    /// IMPORTANT: These are NOT strong references
    /// Type: *AbortSignal (stored as anyopaque to avoid circular dependency)
    dependent_signals: ?std.ArrayList(*anyopaque) = null,

    /// Creates a new SignalRareData structure.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    ///
    /// ## Returns
    /// New rare data with abort_algorithms pre-allocated (empty)
    pub fn init(allocator: Allocator) SignalRareData {
        return .{
            .allocator = allocator,
            .event_listeners = null,
            .abort_algorithms = std.ArrayList(AbortAlgorithmStorage){},
            .source_signals = null,
            .dependent_signals = null,
        };
    }

    /// Cleans up all allocated rare data.
    ///
    /// Frees all lists and maps, but does NOT release referenced signals
    /// (source_signals and dependent_signals are raw pointers).
    pub fn deinit(self: *SignalRareData) void {
        // Clean up event listeners
        if (self.event_listeners) |*listeners| {
            var it = listeners.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.deinit(self.allocator);
            }
            listeners.deinit();
        }

        // Clean up abort algorithms
        self.abort_algorithms.deinit(self.allocator);

        // Clean up source signals list (NOT the signals themselves)
        if (self.source_signals) |*sources| {
            sources.deinit(self.allocator);
        }

        // Clean up dependent signals list (NOT the signals themselves)
        if (self.dependent_signals) |*deps| {
            deps.deinit(self.allocator);
        }
    }

    // === Event Listener Management (EventTarget Interface) ===

    /// Ensures event listener map is allocated.
    fn ensureEventListeners(self: *SignalRareData) !*std.StringHashMap(std.ArrayList(EventListener)) {
        if (self.event_listeners == null) {
            self.event_listeners = std.StringHashMap(std.ArrayList(EventListener)).init(self.allocator);
        }
        return &self.event_listeners.?;
    }

    /// Adds an event listener for the specified event type.
    ///
    /// ## Parameters
    /// - `listener`: Event listener configuration
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate storage
    pub fn addEventListener(self: *SignalRareData, listener: EventListener) !void {
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
        self: *SignalRareData,
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

    /// Checks if there are any event listeners for the specified type.
    ///
    /// ## Returns
    /// true if at least one listener exists for this event type
    pub fn hasEventListeners(self: *const SignalRareData, event_type: []const u8) bool {
        if (self.event_listeners) |listeners| {
            if (listeners.get(event_type)) |list| {
                return list.items.len > 0;
            }
        }
        return false;
    }

    /// Gets all event listeners for the specified type.
    ///
    /// ## Returns
    /// Slice of listeners (empty if none registered)
    pub fn getEventListeners(
        self: *const SignalRareData,
        event_type: []const u8,
    ) []const EventListener {
        if (self.event_listeners) |listeners| {
            if (listeners.get(event_type)) |list| {
                return list.items;
            }
        }
        return &[_]EventListener{};
    }
};
