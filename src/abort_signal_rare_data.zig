//! RareData implementation for AbortSignal.
//!
//! This module implements the RareData pattern for AbortSignal to save memory.
//! Most signals don't need event listeners, abort algorithms, or dependent signals.
//! By allocating these features on-demand, we keep basic signals at 48 bytes.
//!
//! ## Memory Savings
//! - Basic signal (no rare data): 48 bytes
//! - Signal with rare data: 48 + ~80 bytes = 128 bytes
//! - Savings: Only allocate when features actually used

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
