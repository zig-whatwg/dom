//! EventTarget Interface (§2.7-2.9)
//!
//! This module implements the EventTarget interface as specified by the WHATWG DOM Standard.
//! EventTarget is the base interface for all objects that can receive events and have listeners
//! registered on them. It provides the fundamental event system for the DOM.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§2.7 Interface EventTarget**: https://dom.spec.whatwg.org/#interface-eventtarget
//! - **§2.8 Observing Event Listeners**: https://dom.spec.whatwg.org/#observing-event-listeners
//! - **§2.9 Dispatching Events**: https://dom.spec.whatwg.org/#dispatching-events
//! - **§2.10 Firing Events**: https://dom.spec.whatwg.org/#firing-events
//!
//! ## MDN Documentation
//!
//! - EventTarget: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget
//! - EventTarget.addEventListener(): https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener
//! - EventTarget.removeEventListener(): https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/removeEventListener
//! - EventTarget.dispatchEvent(): https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/dispatchEvent
//! - Event flow: https://developer.mozilla.org/en-US/docs/Web/API/Event/eventPhase
//!
//! ## Core Features
//!
//! ### Adding Event Listeners
//! Register listeners for specific event types with optional capture/once/passive flags:
//! ```zig
//! const target = try Node.init(allocator, .element_node, "div");
//! defer target.release();
//!
//! try target.addEventListener("click", myCallback, context, .{
//!     .capture = false,  // Listen during bubble phase
//!     .once = false,     // Don't auto-remove after first fire
//!     .passive = false,  // Allow preventDefault()
//! });
//! ```
//!
//! ### Removing Event Listeners
//! Remove previously registered listeners (must match type, callback, capture):
//! ```zig
//! target.removeEventListener("click", myCallback, .{ .capture = false });
//! // Listener is removed, won't be called for future click events
//! ```
//!
//! ### Dispatching Events
//! Dispatch events through the event flow (capture → target → bubble):
//! ```zig
//! var event = Event.init("click", .{ .bubbles = true, .cancelable = true, .composed = false });
//! const was_cancelled = try target.dispatchEvent(&event);
//! // Returns true if any listener called preventDefault()
//! ```
//!
//! ## EventTarget Architecture
//!
//! EventTarget is now a **real struct** (not a mixin) that serves as the base type
//! for all objects that can receive events. It uses vtable-based polymorphism to
//! access parent's allocator and rare_data without storing them directly (saves memory).
//!
//! **Memory Layout:**
//! - EventTarget: 8 bytes (vtable pointer only)
//! - Node: EventTarget (8 bytes) + Node fields (88 bytes) = 96 bytes total
//! - AbortSignal: EventTarget (8 bytes) + AbortSignal fields = small struct
//!
//! **Prototype Chain (following JavaScript prototype semantics):**
//! ```zig
//! EventTarget (root - 8 bytes)
//!   ├─ Node : EventTarget (96 bytes total)
//!   │    ├─ Element : Node
//!   │    ├─ Text : Node
//!   │    ├─ Document : Node
//!   │    └─ ShadowRoot : DocumentFragment : Node
//!   └─ AbortSignal : EventTarget
//! ```
//!
//! **Extension Pattern:**
//! ```zig
//! pub const Node = struct {
//!     prototype: EventTarget,  // First field (8 bytes)
//!     // ... rest of Node fields ...
//!
//!     pub const vtable = EventTargetVTable{
//!         .deinit = deinitImpl,
//!         .get_allocator = getAllocatorImpl,
//!         .ensure_rare_data = ensureRareDataImpl,
//!     };
//! };
//! ```
//!
//! This enables EventTarget for both DOM nodes (Element, Document) and non-DOM objects
//! (AbortSignal, XMLHttpRequest, WebSocket).
//!
//! **Legacy Mixin (deprecated, will be removed):**
//! The `EventTargetMixin` comptime function is still available for backward compatibility
//! but will be removed once all types migrate to extending EventTarget directly.
//!
//! ## Event Flow Algorithm
//!
//! When dispatchEvent() is called, events propagate through three phases per WHATWG §2.9:
//!
//! **Phase 1: Capture (CAPTURING_PHASE)**
//! - Start at window/document root
//! - Traverse down to target
//! - Call listeners registered with capture=true
//!
//! **Phase 2: Target (AT_TARGET)**
//! - At the event target itself
//! - Call both capture and bubble listeners
//!
//! **Phase 3: Bubble (BUBBLING_PHASE)**
//! - Only if event.bubbles = true
//! - Traverse up from target to root
//! - Call listeners registered with capture=false
//!
//! ## Memory Management
//!
//! Event listeners are stored in RareData (allocated on demand):
//! ```zig
//! const node = try Node.init(allocator, .element_node, "button");
//! defer node.release();
//!
//! // First addEventListener() allocates RareData
//! try node.addEventListener("click", callback, ctx, .{});
//!
//! // Listeners stored in rare_data.event_listeners ArrayList
//! // Cleaned up when node is released
//! ```
//!
//! RareData pattern keeps Node struct small (96 bytes) when events aren't used.
//!
//! ## Usage Examples
//!
//! ### Basic Event Handling
//! ```zig
//! fn handleClick(event: *Event, context: *anyopaque) void {
//!     const state = @ptrCast(*MyState, @alignCast(@alignOf(MyState), context));
//!     std.debug.print("Clicked! State: {}\n", .{state});
//!
//!     // Prevent default browser action
//!     event.preventDefault();
//! }
//!
//! const allocator = std.heap.page_allocator;
//! const button = try Element.create(allocator, "button");
//! defer button.prototype.release();
//!
//! var state = MyState{ .counter = 0 };
//! try button.prototype.addEventListener("click", handleClick, &state, .{});
//!
//! // Dispatch event
//! var event = Event.init("click", .{ .bubbles = true, .cancelable = true, .composed = false });
//! _ = try button.prototype.dispatchEvent(&event);
//! ```
//!
//! ### Capture Phase Listeners
//! ```zig
//! // Parent listens during capture (before child)
//! try parent.addEventListener("click", parentCallback, parent_ctx, .{ .capture = true });
//!
//! // Child listens during bubble (after parent)
//! try child.addEventListener("click", childCallback, child_ctx, .{ .capture = false });
//!
//! // Click on child triggers:
//! // 1. parentCallback (capture phase, going down)
//! // 2. childCallback (at target phase)
//! // 3. parentCallback (bubble phase, going up) - if registered without capture too
//! ```
//!
//! ### Once-Only Listeners
//! ```zig
//! // Automatically removed after first invocation
//! try element.addEventListener("load", onLoad, ctx, .{ .once = true });
//!
//! // First dispatch: onLoad called, listener removed
//! var event1 = Event.init("load", .{ .bubbles = false, .cancelable = false, .composed = false });
//! _ = try element.dispatchEvent(&event1);
//!
//! // Second dispatch: onLoad NOT called (already removed)
//! var event2 = Event.init("load", .{ .bubbles = false, .cancelable = false, .composed = false });
//! _ = try element.dispatchEvent(&event2);
//! ```
//!
//! ## Common Patterns
//!
//! ### Event Delegation
//! ```zig
//! fn handleDelegation(event: *Event, context: *anyopaque) void {
//!     const target = @ptrCast(*Element, @alignCast(@alignOf(Element), event.target.?));
//!     if (std.mem.eql(u8, target.tag_name, "button")) {
//!         // Handle clicks on any button descendant
//!     }
//! }
//!
//! // Listen on parent instead of every child
//! try container.addEventListener("click", handleDelegation, ctx, .{});
//! ```
//!
//! ### Cleanup with AbortSignal
//! ```zig
//! const controller = try AbortController.init(allocator);
//! defer controller.deinit();
//!
//! // Listeners tied to signal lifecycle
//! try element.addEventListener("click", callback, ctx, .{ .signal = controller.signal });
//! try element.addEventListener("input", callback2, ctx, .{ .signal = controller.signal });
//!
//! // Abort removes ALL listeners tied to this signal
//! controller.abort();
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Use Event Delegation** - Attach one listener to parent instead of many to children
//! 2. **Passive Listeners** - Set passive=true for scroll/touch to allow browser optimizations
//! 3. **Once Flag** - Use once=true for one-time events (load, DOMContentLoaded)
//! 4. **Remove Unused Listeners** - Call removeEventListener() to free memory
//! 5. **Capture vs Bubble** - Use capture=true only when needed (rare)
//! 6. **Avoid Heavy Callbacks** - Keep event handlers fast, defer heavy work
//! 7. **RareData Efficiency** - Event listeners only allocate RareData on first addEventListener()
//! 8. **stopImmediatePropagation** - Prevents remaining listeners from firing (performance win)
//!
//! ## JavaScript Bindings
//!
//! **Note:** EventTarget is a mixin in this implementation. In JavaScript, it's exposed as
//! instance methods on objects that implement EventTarget (Node, Element, Document, etc.).
//!
//! ### Instance Methods (Mixed into Node, Element, Document, etc.)
//! ```javascript
//! // addEventListener - Register event listener
//! EventTarget.prototype.addEventListener = function(type, listener, options) {
//!   // Parse options (can be boolean for capture or object)
//!   const opts = typeof options === 'boolean'
//!     ? { capture: options }
//!     : (options || {});
//!
//!   return zig.eventtarget_addEventListener(
//!     this._ptr,
//!     type,
//!     listener,
//!     opts.capture || false,
//!     opts.once || false,
//!     opts.passive || false,
//!     opts.signal || null
//!   );
//! };
//!
//! // removeEventListener - Remove event listener
//! EventTarget.prototype.removeEventListener = function(type, listener, options) {
//!   // Parse options (can be boolean for capture or object)
//!   const opts = typeof options === 'boolean'
//!     ? { capture: options }
//!     : (options || {});
//!
//!   return zig.eventtarget_removeEventListener(
//!     this._ptr,
//!     type,
//!     listener,
//!     opts.capture || false
//!   );
//! };
//!
//! // dispatchEvent - Dispatch event through the event flow
//! EventTarget.prototype.dispatchEvent = function(event) {
//!   return zig.eventtarget_dispatchEvent(this._ptr, event._ptr);
//! };
//! ```
//!
//! ### EventListener Callback
//! ```javascript
//! // Event listener can be a function or object with handleEvent method
//!
//! // Function listener
//! element.addEventListener('click', function(event) {
//!   console.log('Clicked!', event.type);
//! });
//!
//! // Object listener with handleEvent method
//! const listener = {
//!   handleEvent: function(event) {
//!     console.log('Handled:', event.type);
//!   }
//! };
//! element.addEventListener('click', listener);
//! ```
//!
//! ### AddEventListenerOptions
//! ```javascript
//! element.addEventListener('scroll', handler, {
//!   capture: false,  // Listen in bubble phase (default)
//!   once: true,      // Remove after first invocation
//!   passive: true,   // Won't call preventDefault() (enables optimizations)
//!   signal: abortSignal  // AbortSignal to auto-remove on abort
//! });
//! ```
//!
//! ### Usage with AbortSignal
//! ```javascript
//! const controller = new AbortController();
//!
//! // Add multiple listeners tied to signal
//! element.addEventListener('click', handleClick, { signal: controller.signal });
//! element.addEventListener('input', handleInput, { signal: controller.signal });
//!
//! // Abort removes all listeners tied to this signal
//! controller.abort();
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - EventTarget is a **mixin**, not a base class (no inheritance in Zig)
//! - Event listeners stored in `rare_data.event_listeners: ArrayList(EventListener)`
//! - RareData allocated lazily (only when first listener added)
//! - Dispatch algorithm follows WHATWG spec exactly (capture → target → bubble)
//! - `once` listeners removed automatically after first invocation
//! - `passive` listeners cannot call preventDefault() (in_passive_listener_flag set)
//! - AbortSignal integration allows bulk listener removal
//! - Comptime mixin enables code reuse with zero runtime cost
//! - Works with any type meeting rare_data + ensureRareData() requirements

const std = @import("std");
const Event = @import("event.zig").Event;
const Allocator = std.mem.Allocator;

/// EventTarget virtual table for polymorphic behavior.
///
/// Enables EventTarget to access parent's allocator and rare_data
/// without storing them directly (saves memory).
///
/// ## Methods
/// - `deinit`: Cleanup function (releases resources)
/// - `get_allocator`: Returns allocator from parent struct
/// - `ensure_rare_data`: Returns rare_data from parent struct (allocates if needed)
///
/// ## Memory Layout
/// EventTarget = 8 bytes (vtable pointer only)
/// Parent struct provides allocator + rare_data via vtable indirection
pub const EventTargetVTable = struct {
    /// Cleanup function (called when EventTarget is destroyed)
    ///
    /// ## Parameters
    /// - `self`: EventTarget pointer
    deinit: *const fn (self: *EventTarget) void,

    /// Returns allocator from parent struct
    ///
    /// ## Parameters
    /// - `self`: EventTarget pointer
    ///
    /// ## Returns
    /// Allocator from parent
    get_allocator: *const fn (self: *const EventTarget) Allocator,

    /// Ensures rare_data is allocated and returns it
    ///
    /// ## Parameters
    /// - `self`: EventTarget pointer
    ///
    /// ## Returns
    /// Opaque pointer to parent's rare_data (must be cast to correct type)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate rare_data
    ensure_rare_data: *const fn (self: *EventTarget) anyerror!*anyopaque,
};

/// EventTarget struct (base type for all event-capable objects).
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
/// ## Memory Layout
/// - vtable: 8 bytes (pointer to EventTargetVTable)
/// - Total: 8 bytes
///
/// Uses parent's allocator and rare_data via vtable indirection.
///
/// ## Prototype Chain
/// ```
/// EventTarget (root - 8 bytes)
///   ├─ Node : EventTarget (96 bytes total)
///   │    ├─ Element : Node
///   │    ├─ Text : Node
///   │    ├─ Document : Node
///   │    └─ ShadowRoot : DocumentFragment : Node
///   └─ AbortSignal : EventTarget (small struct)
/// ```
///
/// ## Spec References
/// - EventTarget: https://dom.spec.whatwg.org/#interface-eventtarget
/// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:55-63
pub const EventTarget = struct {
    /// Virtual table for polymorphic dispatch (8 bytes)
    vtable: *const EventTargetVTable,

    // Size verification (8 bytes only!)
    comptime {
        const size = @sizeOf(EventTarget);
        if (size != 8) {
            const msg = std.fmt.comptimePrint("EventTarget size ({d} bytes) must be exactly 8 bytes!", .{size});
            @compileError(msg);
        }
    }

    /// Cleanup EventTarget (calls parent's deinit via vtable)
    pub fn deinit(self: *EventTarget) void {
        self.vtable.deinit(self);
    }

    /// Returns allocator from parent struct (via vtable)
    pub fn getAllocator(self: *const EventTarget) Allocator {
        return self.vtable.get_allocator(self);
    }

    /// Ensures rare_data is allocated (via vtable)
    ///
    /// ## Returns
    /// Opaque pointer to parent's rare_data (caller must cast to correct type)
    pub fn ensureRareData(self: *EventTarget) anyerror!*anyopaque {
        return self.vtable.ensure_rare_data(self);
    }

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
    /// ## Algorithm (WHATWG DOM §2.7.3)
    /// 1. Let capture, passive, once, signal be options values
    /// 2. If listener's signal is not null and is aborted, then return
    /// 3. If callback is null, return
    /// 4. Ensure event listener list exists
    /// 5. Add listener to list (if not duplicate)
    /// 6. If listener's signal is not null, then add abort steps to remove listener
    ///
    /// ## Parameters
    /// - `self`: Target object
    /// - `event_type`: Event type to listen for (e.g., "click", "abort")
    /// - `callback`: Function to call when event dispatched
    /// - `context`: User context passed to callback
    /// - `capture`: Listen in capture phase (true) or bubble phase (false)
    /// - `once`: Remove listener after first invocation
    /// - `passive`: Listener won't call preventDefault()
    /// - `signal`: Optional AbortSignal to auto-remove listener on abort
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate listener storage
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:57
    pub fn addEventListener(
        self: *EventTarget,
        event_type: []const u8,
        callback: EventCallback,
        context: *anyopaque,
        capture: bool,
        once: bool,
        passive: bool,
        signal: ?*anyopaque,
    ) !void {
        // Step 2: Early return if signal already aborted
        if (signal) |sig_ptr| {
            const AbortSignal = @import("abort_signal.zig").AbortSignal;
            const abort_signal = @as(*AbortSignal, @ptrCast(@alignCast(sig_ptr)));
            if (abort_signal.isAborted()) {
                return; // Don't add listener if already aborted
            }
        }

        // Get rare_data from parent via vtable
        const rare_data_ptr = try self.ensureRareData();
        const NodeRareData = @import("rare_data.zig").NodeRareData;
        const rare = @as(*NodeRareData, @ptrCast(@alignCast(rare_data_ptr)));

        try rare.addEventListener(.{
            .event_type = event_type,
            .callback = callback,
            .context = context,
            .capture = capture,
            .once = once,
            .passive = passive,
            .signal = signal,
        });

        // Step 6: Register abort algorithm if signal provided
        if (signal) |sig_ptr| {
            const AbortSignal = @import("abort_signal.zig").AbortSignal;
            const abort_signal = @as(*AbortSignal, @ptrCast(@alignCast(sig_ptr)));

            // Create removal context
            const RemovalContext = struct {
                target: *EventTarget,
                event_type: []const u8,
                callback: EventCallback,
                capture: bool,
            };

            const allocator = self.getAllocator();
            const removal_ctx = try allocator.create(RemovalContext);
            removal_ctx.* = .{
                .target = self,
                .event_type = event_type,
                .callback = callback,
                .capture = capture,
            };

            // Create abort algorithm that removes the listener
            const removal_callback = struct {
                fn remove(sig: *AbortSignal, ctx: *anyopaque) void {
                    const removal = @as(*RemovalContext, @ptrCast(@alignCast(ctx)));
                    removal.target.removeEventListener(
                        removal.event_type,
                        removal.callback,
                        removal.capture,
                    );
                    // Free the removal context
                    sig.allocator.destroy(removal);
                }
            }.remove;

            try abort_signal.addAlgorithm(.{
                .callback = removal_callback,
                .context = @ptrCast(removal_ctx),
            });
        }
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
    /// ## Parameters
    /// - `self`: Target object
    /// - `event_type`: Event type to remove listener for
    /// - `callback`: Callback function pointer to match
    /// - `capture`: Capture phase to match
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-removeeventlistener
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:60
    pub fn removeEventListener(
        self: *EventTarget,
        event_type: []const u8,
        callback: EventCallback,
        capture: bool,
    ) void {
        const rare_data_ptr = self.ensureRareData() catch return;
        const NodeRareData = @import("rare_data.zig").NodeRareData;
        const rare = @as(*NodeRareData, @ptrCast(@alignCast(rare_data_ptr)));
        _ = rare.removeEventListener(event_type, callback, capture);
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
    /// ## Algorithm (WHATWG DOM §2.9 - Simplified Phase 1)
    /// 1. Validate event state (not already dispatching, initialized)
    /// 2. Set isTrusted = false, dispatch_flag = true
    /// 3. Set target, currentTarget, eventPhase = AT_TARGET
    /// 4. Invoke listeners on target (no capture/bubble in Phase 1)
    /// 5. Handle passive listeners, "once" listeners
    /// 6. Stop on stopImmediatePropagation
    /// 7. Cleanup: reset event_phase, currentTarget, dispatch_flag
    /// 8. Return !canceled_flag
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
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:62
    pub fn dispatchEvent(self: *EventTarget, event: *Event) !bool {
        // Step 1: Validate event state
        if (event.dispatch_flag) {
            return error.InvalidStateError;
        }
        if (!event.initialized_flag) {
            return error.InvalidStateError;
        }

        // Step 2: Set flags
        event.is_trusted = false;

        // Step 3: Dispatch (simplified for Phase 1)
        event.dispatch_flag = true;
        event.target = @ptrCast(self);
        event.current_target = @ptrCast(self);
        event.event_phase = .at_target;

        // Build event path for composedPath() (Phase 4)
        // For now, just the target itself. Full tree traversal in future phases.
        const allocator = self.getAllocator();
        event.event_path = std.ArrayList(*anyopaque).init(allocator);
        try event.event_path.?.append(@ptrCast(self));
        defer event.clearEventPath(); // Clean up after dispatch

        // Step 4: Invoke listeners on target
        const rare_data_ptr = self.ensureRareData() catch {
            // No rare_data = no listeners
            event.event_phase = .none;
            event.current_target = null;
            event.dispatch_flag = false;
            return !event.canceled_flag;
        };

        const NodeRareData = @import("rare_data.zig").NodeRareData;
        const rare = @as(*NodeRareData, @ptrCast(@alignCast(rare_data_ptr)));

        if (rare.hasEventListeners(event.event_type)) {
            const listeners = rare.getEventListeners(event.event_type);

            for (listeners) |listener| {
                // Skip if type doesn't match
                if (!std.mem.eql(u8, listener.event_type, event.event_type)) {
                    continue;
                }

                // Check stopImmediatePropagation
                if (event.stop_immediate_propagation_flag) {
                    break;
                }

                // Handle "once" listeners - remove before invoking
                if (listener.once) {
                    self.removeEventListener(
                        listener.event_type,
                        listener.callback,
                        listener.capture,
                    );
                }

                // Set passive listener flag
                const prev_passive = event.in_passive_listener_flag;
                if (listener.passive) {
                    event.in_passive_listener_flag = true;
                }

                // Invoke callback
                listener.callback(event, listener.context);

                // Unset passive listener flag
                event.in_passive_listener_flag = prev_passive;
            }
        }

        // Step 5: Cleanup
        event.event_phase = .none;
        event.current_target = null;
        event.dispatch_flag = false;

        // Step 6: Return result
        return !event.canceled_flag;
    }

    /// Checks if target has event listeners for the specified type.
    pub fn hasEventListeners(self: *const EventTarget, event_type: []const u8) bool {
        // Cast away const for ensureRareData (won't allocate on const access)
        const rare_data_ptr = @constCast(self).ensureRareData() catch return false;
        const NodeRareData = @import("rare_data.zig").NodeRareData;
        const rare = @as(*const NodeRareData, @ptrCast(@alignCast(rare_data_ptr)));
        return rare.hasEventListeners(event_type);
    }

    /// Returns all event listeners for a specific event type.
    pub fn getEventListeners(self: *const EventTarget, event_type: []const u8) []const EventListener {
        // Cast away const for ensureRareData (won't allocate on const access)
        const rare_data_ptr = @constCast(self).ensureRareData() catch return &[_]EventListener{};
        const NodeRareData = @import("rare_data.zig").NodeRareData;
        const rare = @as(*const NodeRareData, @ptrCast(@alignCast(rare_data_ptr)));
        return rare.getEventListeners(event_type);
    }
};

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
/// once flag, passive flag, and optional AbortSignal.
///
/// ## WebIDL (AddEventListenerOptions)
/// ```webidl
/// dictionary AddEventListenerOptions : EventListenerOptions {
///   boolean passive;
///   boolean once = false;
///   AbortSignal signal;
/// };
/// ```
///
/// ## Spec References
/// - EventListener: https://dom.spec.whatwg.org/#callbackdef-eventlistener
/// - AddEventListenerOptions: https://dom.spec.whatwg.org/#dictdef-addeventlisteneroptions
/// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:50-54
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

    /// Optional AbortSignal to auto-remove listener on abort (NEW)
    /// Per WHATWG DOM §2.7.3 step 6: "If listener's signal is not null,
    /// then add the following abort steps to it: Remove an event listener"
    /// This enables automatic cleanup when operations are aborted.
    signal: ?*anyopaque = null, // Will be *AbortSignal once that type exists
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
        ///
        /// dictionary AddEventListenerOptions : EventListenerOptions {
        ///   boolean passive;
        ///   boolean once = false;
        ///   AbortSignal signal;
        /// };
        /// ```
        ///
        /// ## Algorithm (WHATWG DOM §2.7.3)
        /// 1. Let capture, passive, once, signal be options values
        /// 2. If listener's signal is not null and is aborted, then return
        /// 3. If callback is null, return
        /// 4. Ensure event listener list exists
        /// 5. Add listener to list (if not duplicate)
        /// 6. If listener's signal is not null, then add abort steps to remove listener
        ///
        /// ## Parameters
        /// - `self`: Target object
        /// - `event_type`: Event type to listen for (e.g., "click", "abort")
        /// - `callback`: Function to call when event dispatched
        /// - `context`: User context passed to callback
        /// - `capture`: Listen in capture phase (true) or bubble phase (false)
        /// - `once`: Remove listener after first invocation
        /// - `passive`: Listener won't call preventDefault()
        /// - `signal`: Optional AbortSignal to auto-remove listener on abort (NEW)
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
        /// // Without signal
        /// try target.addEventListener("click", callback, @ptrCast(&my_data), false, false, false, null);
        ///
        /// // With signal (when AbortSignal is implemented)
        /// // try target.addEventListener("click", callback, @ptrCast(&my_data), false, false, false, signal);
        /// ```
        ///
        /// ## Spec References
        /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
        /// - Signal option: https://dom.spec.whatwg.org/#add-an-event-listener
        /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:57
        pub fn addEventListener(
            self: *T,
            event_type: []const u8,
            callback: EventCallback,
            context: *anyopaque,
            capture: bool,
            once: bool,
            passive: bool,
            signal: ?*anyopaque, // Will be ?*AbortSignal once that type exists
        ) !void {
            // Step 2: Early return if signal already aborted
            // Per spec §2.7.3: "If listener's signal is not null and is aborted, then return"
            if (signal) |sig_ptr| {
                const AbortSignal = @import("abort_signal.zig").AbortSignal;
                const abort_signal = @as(*AbortSignal, @ptrCast(@alignCast(sig_ptr)));
                if (abort_signal.isAborted()) {
                    // std.debug.print("Signal already aborted, not adding listener\n", .{});
                    return; // Don't add listener if already aborted
                }
            }

            const rare = try self.ensureRareData();
            try rare.addEventListener(.{
                .event_type = event_type,
                .callback = callback,
                .context = context,
                .capture = capture,
                .once = once,
                .passive = passive,
                .signal = signal,
            });

            // Step 6: Register abort algorithm if signal provided
            // Per spec §2.7.3 step 6: "If listener's signal is not null, then add
            // the following abort steps to it: Remove an event listener with eventTarget and listener"
            if (signal) |sig_ptr| {
                const AbortSignal = @import("abort_signal.zig").AbortSignal;
                const abort_signal = @as(*AbortSignal, @ptrCast(@alignCast(sig_ptr)));

                // Create removal context
                const RemovalContext = struct {
                    target: *T,
                    event_type: []const u8,
                    callback: EventCallback,
                    capture: bool,
                };

                const removal_ctx = try abort_signal.allocator.create(RemovalContext);
                removal_ctx.* = .{
                    .target = self,
                    .event_type = event_type,
                    .callback = callback,
                    .capture = capture,
                };

                // Create abort algorithm that removes the listener
                const removal_callback = struct {
                    fn remove(sig: *AbortSignal, ctx: *anyopaque) void {
                        const removal = @as(*RemovalContext, @ptrCast(@alignCast(ctx)));
                        // Debug: Print removal attempt
                        // std.debug.print("Removing listener for event '{s}' (capture={})\n", .{removal.event_type, removal.capture});
                        removal.target.removeEventListener(
                            removal.event_type,
                            removal.callback,
                            removal.capture,
                        );
                        // Free the removal context
                        sig.allocator.destroy(removal);
                    }
                }.remove;

                try abort_signal.addAlgorithm(.{
                    .callback = removal_callback,
                    .context = @ptrCast(removal_ctx),
                });
            }
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
