//! EventTarget mixin - Generic event dispatching for any type.
//!
//! Provides addEventListener(), removeEventListener(), and dispatchEvent()
//! for any type that:
//! - Has a `rare_data: ?*RareDataType` field
//! - Implements `ensureRareData() !*RareDataType` method
//! - RareDataType implements event listener storage interface
//!
//! This mixin enables EventTarget functionality for both Node (DOM tree) and
//! non-Node types like AbortSignal, XMLHttpRequest, WebSocket, etc.
//!
//! ## Architecture
//! Uses Zig's comptime generics and `usingnamespace` to inject EventTarget
//! methods into any compatible type with zero runtime overhead.
//!
//! ## Example Usage
//! ```zig
//! pub const Node = struct {
//!     rare_data: ?*NodeRareData,
//!     pub usingnamespace EventTargetMixin(@This());
//!
//!     pub fn ensureRareData(self: *Node) !*NodeRareData {
//!         // Implementation
//!     }
//! };
//!
//! pub const AbortSignal = struct {
//!     rare_data: ?*SignalRareData,
//!     pub usingnamespace EventTargetMixin(@This());
//!
//!     pub fn ensureRareData(self: *AbortSignal) !*SignalRareData {
//!         // Implementation
//!     }
//! };
//! ```
//!
//! ## WHATWG DOM Compliance
//! Implements EventTarget interface per WHATWG DOM §2.7-§2.9.
//!
//! ## Spec References
//! - Interface: https://dom.spec.whatwg.org/#interface-eventtarget
//! - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl

const std = @import("std");
const Event = @import("event.zig").Event;
const Allocator = std.mem.Allocator;

/// EventCallback signature per WHATWG DOM §2.7.
///
/// Called when an event is dispatched to a target.
/// Receives the Event object and user-provided context.
/// Matches EventListener.handleEvent(Event) signature from WebIDL.
///
/// ## Parameters
/// - `event`: The Event being dispatched
/// - `context`: User-provided context (e.g., object pointer, state)
pub const EventCallback = *const fn (event: *Event, context: *anyopaque) void;

/// Event listener registration per WHATWG DOM §2.7.
///
/// Stores listener configuration including callback, capture phase,
/// once flag, and passive flag.
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

/// Mixin to add EventTarget functionality to any type T.
///
/// Implements WHATWG DOM EventTarget interface per §2.7-§2.9.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=*]
/// interface EventTarget {
///   constructor();
///
///   undefined addEventListener(DOMString type, EventListener? callback,
///                              optional (AddEventListenerOptions or boolean) options = {});
///   undefined removeEventListener(DOMString type, EventListener? callback,
///                                  optional (EventListenerOptions or boolean) options = {});
///   boolean dispatchEvent(Event event);
/// };
/// ```
///
/// ## Requirements
/// Type T must have:
/// - `rare_data: ?*RareDataType` field
/// - `ensureRareData(self: *T) !*RareDataType` method
/// - RareDataType must implement:
///   - `addEventListener(EventListener) !void`
///   - `removeEventListener([]const u8, EventCallback, bool) bool`
///   - `hasEventListeners([]const u8) bool`
///   - `getEventListeners([]const u8) []const EventListener`
///
/// ## Comptime Validation
/// The mixin validates requirements at compile time, providing clear error
/// messages if type T doesn't meet the interface contract.
///
/// ## Usage
/// ```zig
/// pub const Node = struct {
///     rare_data: ?*NodeRareData,
///     pub usingnamespace EventTargetMixin(@This());
///
///     pub fn ensureRareData(self: *Node) !*NodeRareData {
///         if (self.rare_data == null) {
///             self.rare_data = try self.allocator.create(NodeRareData);
///             self.rare_data.?.* = NodeRareData.init(self.allocator);
///         }
///         return self.rare_data.?;
///     }
/// };
/// ```
///
/// ## Spec References
/// - EventTarget: https://dom.spec.whatwg.org/#interface-eventtarget
/// - addEventListener: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
/// - removeEventListener: https://dom.spec.whatwg.org/#dom-eventtarget-removeeventlistener
/// - dispatchEvent: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
pub fn EventTargetMixin(comptime T: type) type {
    // Compile-time verification of interface requirements
    comptime {
        // Verify rare_data field exists
        if (!@hasField(T, "rare_data")) {
            @compileError(@typeName(T) ++ " must have 'rare_data' field for EventTarget mixin. " ++
                "Add: rare_data: ?*RareDataType");
        }

        // Verify ensureRareData method exists
        if (!@hasDecl(T, "ensureRareData")) {
            @compileError(@typeName(T) ++ " must have 'ensureRareData()' method for EventTarget mixin. " ++
                "Add: pub fn ensureRareData(self: *" ++ @typeName(T) ++ ") !*RareDataType { ... }");
        }
    }

    return struct {
        /// Registers an event listener.
        ///
        /// Implements WHATWG DOM EventTarget.addEventListener() per §2.7.
        ///
        /// ## WebIDL
        /// ```webidl
        /// undefined addEventListener(DOMString type, EventListener? callback,
        ///                            optional (AddEventListenerOptions or boolean) options = {});
        /// ```
        ///
        /// ## Algorithm (WHATWG DOM §2.7)
        /// 1. Let capture, passive, once be options values
        /// 2. If callback is null, return
        /// 3. Ensure event listener list exists
        /// 4. Add listener to list (if not duplicate)
        ///
        /// ## Parameters
        /// - `self`: Target object
        /// - `event_type`: Event type to listen for (e.g., "click", "abort")
        /// - `callback`: Function to call when event dispatched
        /// - `context`: User context passed to callback
        /// - `capture`: Listen in capture phase (true) or bubble phase (false)
        /// - `once`: Remove listener after first invocation
        /// - `passive`: Listener won't call preventDefault()
        ///
        /// ## Errors
        /// - `error.OutOfMemory`: Failed to allocate listener storage
        ///
        /// ## Example
        /// ```zig
        /// const callback = struct {
        ///     fn handle(event: *Event, ctx: *anyopaque) void {
        ///         const my_data = @as(*MyData, @ptrCast(@alignCast(ctx)));
        ///         std.debug.print("Event: {s}\n", .{event.type});
        ///     }
        /// }.handle;
        ///
        /// var my_data = MyData{};
        /// try target.addEventListener("click", callback, @ptrCast(&my_data), false, false, false);
        /// ```
        ///
        /// ## Spec References
        /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
        /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:57
        pub fn addEventListener(
            self: *T,
            event_type: []const u8,
            callback: EventCallback,
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

        /// Removes an event listener from the target.
        ///
        /// Implements WHATWG DOM EventTarget.removeEventListener() per §2.7.
        ///
        /// ## WebIDL
        /// ```webidl
        /// undefined removeEventListener(DOMString type, EventListener? callback,
        ///                                optional (EventListenerOptions or boolean) options = {});
        /// ```
        ///
        /// ## Algorithm (WHATWG DOM §2.7)
        /// 1. If callback is null, return
        /// 2. Find listener in list matching (type, callback, capture)
        /// 3. Remove listener if found
        ///
        /// Note: Per WebIDL spec, this returns void (not bool).
        /// Matches by event type, callback pointer, and capture phase.
        ///
        /// ## Parameters
        /// - `self`: Target object
        /// - `event_type`: Event type to remove listener for
        /// - `callback`: Callback function pointer to match
        /// - `capture`: Capture phase to match
        ///
        /// ## Example
        /// ```zig
        /// target.removeEventListener("click", callback, false);
        /// ```
        ///
        /// ## Spec References
        /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-removeeventlistener
        /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:60
        pub fn removeEventListener(
            self: *T,
            event_type: []const u8,
            callback: EventCallback,
            capture: bool,
        ) void {
            if (self.rare_data) |rare| {
                _ = rare.removeEventListener(event_type, callback, capture);
            }
        }

        /// Dispatches an event to this target.
        ///
        /// Implements WHATWG DOM EventTarget.dispatchEvent() per §2.7, §2.9.
        ///
        /// ## WebIDL
        /// ```webidl
        /// boolean dispatchEvent(Event event);
        /// ```
        ///
        /// ## Algorithm (WHATWG DOM §2.9 - Phase 1 Simplified)
        /// 1. Validate event state (not already dispatching, initialized)
        /// 2. Set isTrusted = false, dispatch_flag = true
        /// 3. Set target, currentTarget, eventPhase = AT_TARGET
        /// 4. Invoke listeners on target (no capture/bubble in Phase 1)
        /// 5. Handle passive listeners, "once" listeners
        /// 6. Stop on stopImmediatePropagation
        /// 7. Cleanup: reset event_phase, currentTarget, dispatch_flag
        /// 8. Return !canceled_flag
        ///
        /// ## Note
        /// Phase 1 implementation - dispatches to target only.
        /// Future phases will add:
        /// - Tree traversal (capture/bubble phases)
        /// - Event path construction
        /// - Shadow DOM retargeting
        ///
        /// ## Parameters
        /// - `self`: Target object
        /// - `event`: Event to dispatch
        ///
        /// ## Returns
        /// - `true` if event was not canceled
        /// - `false` if preventDefault() was called
        ///
        /// ## Errors
        /// - `error.InvalidStateError`: Event is already being dispatched or not initialized
        ///
        /// ## Example
        /// ```zig
        /// var event = Event.init("click", .{ .cancelable = true });
        /// const result = try target.dispatchEvent(&event);
        /// if (!result) {
        ///     // Event was canceled
        /// }
        /// ```
        ///
        /// ## Spec References
        /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
        /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:62
        pub fn dispatchEvent(self: *T, event: *Event) !bool {
            // Step 1: Validate event state
            // Per spec §2.7: "If event's dispatch flag is set, or if its
            // initialized flag is not set, then throw an InvalidStateError DOMException."
            if (event.dispatch_flag) {
                return error.InvalidStateError;
            }
            if (!event.initialized_flag) {
                return error.InvalidStateError;
            }

            // Step 2: Set flags per spec §2.7 step 2
            // "Initialize event's isTrusted attribute to false."
            event.is_trusted = false;

            // Step 3: Dispatch (simplified for Phase 1 - no tree traversal)
            // Set dispatch flag per spec §2.9 step 1
            event.dispatch_flag = true;

            // Set event target and phase
            event.target = @ptrCast(self);
            event.current_target = @ptrCast(self);
            event.event_phase = .at_target;

            // Step 4: Invoke listeners on target (Phase 1 - no capture/bubble)
            if (self.rare_data) |rare| {
                if (rare.hasEventListeners(event.event_type)) {
                    const listeners = rare.getEventListeners(event.event_type);

                    // Iterate through listeners (spec §2.9 step 6)
                    // Note: We iterate directly over the slice. Per spec, we should clone
                    // to handle listeners added/removed during dispatch, but for Phase 1
                    // we keep it simple.
                    for (listeners) |listener| {
                        // Skip if type doesn't match (safety check)
                        if (!std.mem.eql(u8, listener.event_type, event.event_type)) {
                            continue;
                        }

                        // Check stopImmediatePropagation (spec §2.9 inner invoke step 14)
                        if (event.stop_immediate_propagation_flag) {
                            break;
                        }

                        // Handle "once" listeners - remove before invoking
                        // (spec §2.9 inner invoke step 5)
                        if (listener.once) {
                            self.removeEventListener(
                                listener.event_type,
                                listener.callback,
                                listener.capture,
                            );
                        }

                        // Set passive listener flag (spec §2.9 inner invoke step 9)
                        const prev_passive = event.in_passive_listener_flag;
                        if (listener.passive) {
                            event.in_passive_listener_flag = true;
                        }

                        // Invoke callback (spec §2.9 inner invoke step 11)
                        listener.callback(event, listener.context);

                        // Unset passive listener flag (spec §2.9 inner invoke step 12)
                        event.in_passive_listener_flag = prev_passive;
                    }
                }
            }

            // Step 5: Cleanup (spec §2.9 steps 7-10)
            // "Set event's eventPhase attribute to NONE."
            event.event_phase = .none;
            // "Set event's currentTarget attribute to null."
            event.current_target = null;
            // "Unset event's dispatch flag..."
            event.dispatch_flag = false;
            // Note: We don't clear stop_propagation_flag or
            // stop_immediate_propagation_flag per spec §2.9 step 10

            // Step 6: Return result (spec §2.9 step 13)
            // "Return false if event's canceled flag is set; otherwise true."
            return !event.canceled_flag;
        }

        /// Checks if target has event listeners for the specified type.
        ///
        /// ## Parameters
        /// - `self`: Target object
        /// - `event_type`: Event type to check
        ///
        /// ## Returns
        /// true if target has listeners for this event type, false otherwise
        pub fn hasEventListeners(self: *const T, event_type: []const u8) bool {
            if (self.rare_data) |rare| {
                return rare.hasEventListeners(event_type);
            }
            return false;
        }

        /// Returns all event listeners for a specific event type.
        ///
        /// ## Parameters
        /// - `self`: Target object
        /// - `event_type`: Event type to query
        ///
        /// ## Returns
        /// Slice of listeners (empty if none registered)
        pub fn getEventListeners(self: *const T, event_type: []const u8) []const EventListener {
            if (self.rare_data) |rare| {
                return rare.getEventListeners(event_type);
            }
            return &[_]EventListener{};
        }
    };
}
