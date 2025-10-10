const std = @import("std");

/// Represents the different phases of event propagation.
///
/// ## Overview
///
/// During event dispatch, an event progresses through different phases as it
/// travels through the DOM tree. Understanding these phases is crucial for
/// proper event handling and event delegation patterns.
///
/// The event flow has three phases:
/// 1. **Capture Phase**: Event travels from root to target
/// 2. **Target Phase**: Event reaches its target
/// 3. **Bubble Phase**: Event travels from target back to root (if bubbles is true)
///
/// ## Phases
///
/// - `none` (0): The event is not currently being dispatched. This is the initial
///   and final state of an event.
///
/// - `capturing_phase` (1): The event is in the capture phase, traveling from the
///   root to the target. Event listeners registered with `capture: true` are
///   invoked during this phase.
///
/// - `at_target` (2): The event has reached its target. Both capture and bubble
///   phase listeners on the target are invoked during this phase.
///
/// - `bubbling_phase` (3): The event is in the bubble phase, traveling from the
///   target back to the root. Event listeners registered with `capture: false`
///   are invoked during this phase. This phase only occurs if the event's
///   `bubbles` property is true.
///
/// ## Usage Example
///
/// ```zig
/// const handleEvent = struct {
///     fn callback(event: *Event) void {
///         switch (event.event_phase) {
///             .none => std.debug.print("Event not dispatching\n", .{}),
///             .capturing_phase => std.debug.print("Capture phase\n", .{}),
///             .at_target => std.debug.print("At target\n", .{}),
///             .bubbling_phase => std.debug.print("Bubble phase\n", .{}),
///         }
///     }
/// }.callback;
/// ```
///
/// ## Specification Compliance
///
/// The numeric values match the DOM specification constants:
/// - NONE = 0
/// - CAPTURING_PHASE = 1
/// - AT_TARGET = 2
/// - BUBBLING_PHASE = 3
///
/// ## Reference
///
/// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-eventphase
/// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Event/eventPhase
pub const EventPhase = enum(u16) {
    /// The event is not currently being dispatched.
    /// This is both the initial state before dispatch and the final state after.
    none = 0,

    /// The event is traveling from the root towards the target.
    /// Listeners with capture=true are invoked in this phase.
    capturing_phase = 1,

    /// The event has reached its target.
    /// All listeners on the target are invoked regardless of capture flag.
    at_target = 2,

    /// The event is traveling from the target back to the root.
    /// Listeners with capture=false are invoked in this phase.
    /// Only occurs if the event's bubbles property is true.
    bubbling_phase = 3,
};

/// Represents an event that takes place in the DOM.
///
/// ## Overview
///
/// An Event object is created whenever something happens that scripts might want
/// to know about - a user clicking on something, a document loading, an animation
/// finishing, and so on. The Event interface is the base for all events in the DOM.
///
/// Events are dispatched to EventTarget objects, which can register event listeners
/// to be notified when events of a particular type occur. The event object contains
/// information about what happened and provides methods to control event propagation.
///
/// ## Key Concepts
///
/// ### Event Type
/// Each event has a type (e.g., "click", "load", "error") that identifies what
/// kind of event it is. Event types are case-sensitive strings.
///
/// ### Event Target
/// The target is the object to which the event was originally dispatched. It
/// remains constant throughout event propagation.
///
/// ### Current Target
/// During event dispatch, the currentTarget changes to indicate which object's
/// event listeners are currently being invoked.
///
/// ### Event Propagation
/// Events can propagate through a tree structure in three phases:
/// 1. Capture (root to target)
/// 2. Target (at the target)
/// 3. Bubble (target to root, if bubbles is true)
///
/// ### Cancelation
/// If an event is cancelable, calling preventDefault() will signal that the
/// event's default action should not be taken.
///
/// ### Composition
/// Events with composed=true can cross shadow DOM boundaries; those with
/// composed=false are confined to their shadow tree.
///
/// ## Usage Example
///
/// ```zig
/// const allocator = std.heap.page_allocator;
///
/// // Create a custom event
/// const event = try Event.init(allocator, "customEvent", .{
///     .bubbles = true,      // Event will bubble
///     .cancelable = true,   // Can be cancelled
///     .composed = false,    // Won't cross shadow boundaries
/// });
/// defer event.deinit();
///
/// // Check event properties
/// std.debug.print("Type: {s}\n", .{event.type_name});
/// std.debug.print("Bubbles: {}\n", .{event.bubbles});
/// std.debug.print("Trusted: {}\n", .{event.is_trusted});
///
/// // Control event propagation
/// event.stopPropagation();          // Stop propagation
/// event.preventDefault();            // Cancel default action
///
/// // Check state
/// if (event.default_prevented) {
///     std.debug.print("Default action was prevented\n", .{});
/// }
/// ```
///
/// ## Specification Compliance
///
/// This implementation follows the WHATWG DOM Standard (§2.2 Interface Event):
/// - Event creation with constructor (new Event)
/// - Event initialization flags (bubbles, cancelable, composed)
/// - Event phase tracking (none, capturing, at_target, bubbling)
/// - Event propagation control (stopPropagation, stopImmediatePropagation)
/// - Default action prevention (preventDefault, defaultPrevented)
/// - Trust indication (isTrusted)
/// - Timestamp tracking (timeStamp)
/// - Composed path support (composedPath)
///
/// ## Implementation Notes
///
/// ### Memory Management
/// Events are allocated on the heap and must be freed with deinit().
/// The event type string is duplicated and managed internally.
///
/// ### Trust Flag
/// The isTrusted flag is set to false for synthetic events created via the
/// constructor. Only events created by the user agent are trusted.
///
/// ### Timestamp
/// The timestamp is set to the current time in milliseconds when the event
/// is created, using std.time.milliTimestamp().
///
/// ### Targets
/// Both target and currentTarget are stored as opaque pointers to allow
/// flexibility in what can be an event target.
///
/// ## Reference
///
/// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#interface-event
/// * WHATWG DOM Standard (Event Creation): https://dom.spec.whatwg.org/#dom-event-event
/// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Event
pub const Event = struct {
    const Self = @This();

    /// The type of event (e.g., "click", "load", "error").
    /// This is a case-sensitive string that identifies the event.
    /// Set during construction and remains constant.
    type_name: []const u8,

    /// The object to which the event was originally dispatched.
    /// Set by the dispatch algorithm and remains constant during propagation.
    /// Null before dispatch.
    target: ?*anyopaque,

    /// The object whose event listeners are currently being invoked.
    /// Changes during event propagation as the event moves through targets.
    /// Null when not being dispatched.
    current_target: ?*anyopaque,

    /// The current phase of event propagation.
    /// One of: none, capturing_phase, at_target, or bubbling_phase.
    event_phase: EventPhase,

    /// Indicates whether the event bubbles up through the DOM.
    /// If true, the event will propagate from target to root after the target phase.
    /// If false, only capture and target phases occur.
    bubbles: bool,

    /// Indicates whether the event's default action can be prevented.
    /// If true, calling preventDefault() will set default_prevented to true.
    /// If false, preventDefault() has no effect.
    cancelable: bool,

    /// Indicates whether the event will cross shadow DOM boundaries.
    /// If true, the event can propagate into and out of shadow trees.
    /// If false, the event is confined to its shadow tree.
    composed: bool,

    /// Indicates whether preventDefault() has been called.
    /// Initially false. Set to true when preventDefault() is called on a
    /// cancelable event.
    default_prevented: bool,

    /// Indicates whether stopPropagation() has been called.
    /// When true, prevents the event from reaching any further targets
    /// in the propagation path.
    propagation_stopped: bool,

    /// Indicates whether stopImmediatePropagation() has been called.
    /// When true, prevents any remaining listeners from being called,
    /// even on the current target.
    immediate_propagation_stopped: bool,

    /// The time when the event was created, in milliseconds since epoch.
    /// Set to std.time.milliTimestamp() during initialization.
    timestamp: i64,

    /// Indicates whether the event was created by the user agent.
    /// True for events created by the browser, false for synthetic events
    /// created via the Event constructor.
    is_trusted: bool,

    /// The memory allocator used for this event.
    /// Stored to enable proper cleanup in deinit().
    allocator: std.mem.Allocator,

    /// A dictionary of options for configuring a new Event.
    ///
    /// This structure corresponds to the EventInit dictionary in the DOM
    /// specification. It allows configuring the event's behavior during
    /// creation.
    ///
    /// ## Fields
    ///
    /// - `bubbles`: Controls whether the event will bubble through the DOM tree.
    ///   Default: false
    ///
    /// - `cancelable`: Controls whether the event's default action can be prevented.
    ///   Default: false
    ///
    /// - `composed`: Controls whether the event crosses shadow DOM boundaries.
    ///   Default: false
    ///
    /// ## Default Behavior
    ///
    /// If not specified, all flags default to false, meaning the event:
    /// - Will not bubble (only capture and target phases)
    /// - Cannot be cancelled
    /// - Will not cross shadow boundaries
    ///
    /// ## Usage Examples
    ///
    /// ### Non-Bubbling Event
    /// ```zig
    /// const event = try Event.init(allocator, "load", .{});
    /// // bubbles=false, cancelable=false, composed=false
    /// ```
    ///
    /// ### Bubbling, Cancelable Event
    /// ```zig
    /// const event = try Event.init(allocator, "click", .{
    ///     .bubbles = true,
    ///     .cancelable = true,
    /// });
    /// // composed defaults to false
    /// ```
    ///
    /// ### Composed Event (Shadow DOM)
    /// ```zig
    /// const event = try Event.init(allocator, "custom", .{
    ///     .bubbles = true,
    ///     .composed = true,
    /// });
    /// // Can cross shadow boundaries
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Per the DOM specification (§2.2), EventInit dictionary:
    /// ```webidl
    /// dictionary EventInit {
    ///   boolean bubbles = false;
    ///   boolean cancelable = false;
    ///   boolean composed = false;
    /// };
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dictdef-eventinit
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Event/Event
    pub const InitOptions = struct {
        /// If true, the event will bubble up through the DOM tree.
        /// Enables the bubbling phase of event propagation.
        /// Defaults to false per the specification.
        bubbles: bool = false,

        /// If true, the event's default action can be prevented via preventDefault().
        /// If false, preventDefault() calls are ignored.
        /// Defaults to false per the specification.
        cancelable: bool = false,

        /// If true, the event will trigger listeners outside of a shadow root.
        /// Allows the event to cross shadow DOM boundaries.
        /// Defaults to false per the specification.
        composed: bool = false,
    };

    /// Creates a new Event object.
    ///
    /// The Event constructor creates a new Event with the specified type and
    /// optional configuration. The event is created in a synthetic (non-trusted)
    /// state and can be dispatched to any EventTarget.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: The memory allocator to use for the event and its data.
    ///   The allocator is stored and used during deinit() for cleanup.
    ///
    /// - `type_name`: A case-sensitive string representing the name of the event.
    ///   Common types include "click", "load", "error", etc. Custom types are allowed.
    ///   The string is duplicated internally.
    ///
    /// - `options`: An InitOptions struct to configure the event's properties.
    ///   Controls bubbling, cancelability, and composition behavior.
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created Event object. The caller is responsible
    /// for calling deinit() when the event is no longer needed.
    ///
    /// ## Initialization
    ///
    /// The event is initialized with:
    /// - `type_name`: Copy of the provided type string
    /// - `target`: null (set during dispatch)
    /// - `current_target`: null (set during dispatch)
    /// - `event_phase`: none
    /// - `bubbles`: From options (default false)
    /// - `cancelable`: From options (default false)
    /// - `composed`: From options (default false)
    /// - `default_prevented`: false
    /// - `propagation_stopped`: false
    /// - `immediate_propagation_stopped`: false
    /// - `timestamp`: Current time in milliseconds
    /// - `is_trusted`: false (synthetic event)
    /// - `allocator`: Stored for cleanup
    ///
    /// ## Memory Management
    ///
    /// This method allocates memory for:
    /// 1. The Event struct itself
    /// 2. A copy of the type_name string
    ///
    /// Both allocations are freed by deinit(). If allocation fails, an error
    /// is returned and no memory is leaked.
    ///
    /// ## Errors
    ///
    /// Returns an error if:
    /// - Memory allocation fails for the Event struct (OutOfMemory)
    /// - Memory allocation fails for the type_name string (OutOfMemory)
    ///
    /// If an error occurs, all successfully allocated memory is freed before
    /// returning the error.
    ///
    /// ## Examples
    ///
    /// ### Basic Event Creation
    /// ```zig
    /// const allocator = std.heap.page_allocator;
    ///
    /// const event = try Event.init(allocator, "click", .{});
    /// defer event.deinit();
    ///
    /// std.debug.print("Type: {s}\n", .{event.type_name});
    /// // Output: Type: click
    /// ```
    ///
    /// ### Bubbling Event
    /// ```zig
    /// const event = try Event.init(allocator, "custom", .{
    ///     .bubbles = true,
    /// });
    /// defer event.deinit();
    ///
    /// if (event.bubbles) {
    ///     std.debug.print("This event will bubble\n", .{});
    /// }
    /// ```
    ///
    /// ### Cancelable Event
    /// ```zig
    /// const event = try Event.init(allocator, "submit", .{
    ///     .bubbles = true,
    ///     .cancelable = true,
    /// });
    /// defer event.deinit();
    ///
    /// event.preventDefault();
    /// if (event.default_prevented) {
    ///     std.debug.print("Form submission prevented\n", .{});
    /// }
    /// ```
    ///
    /// ### Composed Event (Shadow DOM)
    /// ```zig
    /// const event = try Event.init(allocator, "slotchange", .{
    ///     .bubbles = true,
    ///     .composed = true,
    /// });
    /// defer event.deinit();
    ///
    /// // This event can cross shadow boundaries
    /// ```
    ///
    /// ### Error Handling
    /// ```zig
    /// const event = Event.init(allocator, "click", .{}) catch |err| {
    ///     std.debug.print("Failed to create event: {}\n", .{err});
    ///     return err;
    /// };
    /// defer event.deinit();
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// This method implements the Event constructor defined in DOM Standard §2.2:
    /// "event = new Event(type [, eventInitDict])"
    ///
    /// Key specification points:
    /// - Event type is case-sensitive
    /// - isTrusted is false for synthetic events
    /// - timeStamp is set to creation time
    /// - All propagation flags are initially false
    /// - target and currentTarget are null until dispatch
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-event
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Event/Event
    pub fn init(allocator: std.mem.Allocator, type_name: []const u8, options: InitOptions) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        const type_copy = try allocator.dupe(u8, type_name);
        errdefer allocator.free(type_copy);

        self.* = .{
            .type_name = type_copy,
            .target = null,
            .current_target = null,
            .event_phase = .none,
            .bubbles = options.bubbles,
            .cancelable = options.cancelable,
            .composed = options.composed,
            .default_prevented = false,
            .propagation_stopped = false,
            .immediate_propagation_stopped = false,
            .timestamp = std.time.milliTimestamp(),
            .is_trusted = false,
            .allocator = allocator,
        };
        return self;
    }

    /// Frees all resources associated with the Event.
    ///
    /// This method must be called when the event is no longer needed to prevent
    /// memory leaks. It frees both the type_name string and the Event struct itself.
    ///
    /// ## Safety
    ///
    /// After calling deinit(), the Event pointer is invalid and must not be used.
    /// Using the event after deinit() results in undefined behavior.
    ///
    /// ## Memory Cleanup
    ///
    /// Frees:
    /// 1. The type_name string (allocated during init)
    /// 2. The Event struct itself (allocated during init)
    ///
    /// ## Example
    ///
    /// ```zig
    /// const event = try Event.init(allocator, "click", .{});
    /// // Use the event...
    /// event.deinit(); // Clean up when done
    /// ```
    ///
    /// ## Best Practice
    ///
    /// Use `defer` to ensure cleanup happens even if errors occur:
    ///
    /// ```zig
    /// const event = try Event.init(allocator, "click", .{});
    /// defer event.deinit();
    /// // Use the event...
    /// // deinit() is called automatically when scope exits
    /// ```
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.type_name);
        self.allocator.destroy(self);
    }

    /// Prevents the default action associated with the event.
    ///
    /// If the event is cancelable, calling this method signals that the default
    /// action should not be taken. For example, calling preventDefault() on a
    /// form submit event prevents the form from being submitted.
    ///
    /// ## Behavior
    ///
    /// ### Cancelable Events
    /// If the event's `cancelable` property is true:
    /// - Sets `default_prevented` to true
    /// - Signals to the dispatcher that the default action should not occur
    ///
    /// ### Non-Cancelable Events
    /// If the event's `cancelable` property is false:
    /// - The call has no effect
    /// - `default_prevented` remains false
    /// - No error or warning is generated
    ///
    /// ## When to Use
    ///
    /// Common use cases:
    /// - Prevent form submission (`submit` event)
    /// - Prevent link navigation (`click` event on links)
    /// - Prevent context menu (`contextmenu` event)
    /// - Prevent text selection (`selectstart` event)
    /// - Prevent drag operations (`dragstart` event)
    ///
    /// ## Checking Prevention
    ///
    /// After dispatching, check `defaultPrevented` or the return value of
    /// `dispatchEvent()`:
    /// - `dispatchEvent()` returns false if preventDefault was called
    /// - `event.default_prevented` is true if preventDefault was called
    ///
    /// ## Examples
    ///
    /// ### Preventing Form Submission
    /// ```zig
    /// const handleSubmit = struct {
    ///     fn callback(event: *Event) void {
    ///         // Validate form...
    ///         if (!formIsValid()) {
    ///             event.preventDefault(); // Don't submit
    ///             std.debug.print("Form invalid, submission prevented\n", .{});
    ///         }
    ///     }
    /// }.callback;
    /// ```
    ///
    /// ### Preventing Link Navigation
    /// ```zig
    /// const handleClick = struct {
    ///     fn callback(event: *Event) void {
    ///         event.preventDefault(); // Don't navigate
    ///         // Handle click with custom code instead
    ///     }
    /// }.callback;
    /// ```
    ///
    /// ### Checking if Prevented
    /// ```zig
    /// const event = try Event.init(allocator, "submit", .{
    ///     .cancelable = true,
    /// });
    /// defer event.deinit();
    ///
    /// event.preventDefault();
    ///
    /// if (event.default_prevented) {
    ///     std.debug.print("Default action was prevented\n", .{});
    /// }
    /// ```
    ///
    /// ### Non-Cancelable Event
    /// ```zig
    /// const event = try Event.init(allocator, "load", .{
    ///     .cancelable = false,
    /// });
    /// defer event.deinit();
    ///
    /// event.preventDefault(); // Has no effect
    ///
    /// std.debug.assert(!event.default_prevented); // Still false
    /// ```
    ///
    /// ## Specification Notes
    ///
    /// Per the DOM specification, preventDefault() should be called during event
    /// dispatch. Calling it after dispatch has no effect on the event's outcome,
    /// though the `default_prevented` flag will still be set.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-preventdefault
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Event/preventDefault
    pub fn preventDefault(self: *Self) void {
        if (self.cancelable) {
            self.default_prevented = true;
        }
    }

    /// Prevents further propagation of the current event.
    ///
    /// When called during event dispatch, this method prevents the event from
    /// reaching any subsequent targets in the propagation path. However, it does
    /// NOT prevent other listeners on the current target from being called.
    ///
    /// ## Behavior
    ///
    /// ### Effect on Propagation
    /// - Sets the `propagation_stopped` flag to true
    /// - Prevents the event from reaching targets beyond the current one
    /// - Does NOT affect listeners on the current target
    ///
    /// ### Phase-Specific Behavior
    ///
    /// **Capture Phase**:
    /// - Remaining capture phase targets are skipped
    /// - Target phase listeners ARE invoked
    /// - Bubble phase is skipped
    ///
    /// **Target Phase**:
    /// - All listeners on the target ARE invoked
    /// - Bubble phase is skipped
    ///
    /// **Bubble Phase**:
    /// - Remaining bubble phase targets are skipped
    ///
    /// ## Difference from stopImmediatePropagation
    ///
    /// - `stopPropagation()`: Other listeners on current target still execute
    /// - `stopImmediatePropagation()`: No more listeners execute at all
    ///
    /// ## When to Use
    ///
    /// Use when you want to:
    /// - Handle an event at a specific level without propagating further
    /// - Prevent parent handlers from being called
    /// - Implement event delegation with specific stopping points
    /// - Optimize performance by limiting propagation
    ///
    /// ## Examples
    ///
    /// ### Stop Bubbling to Parent
    /// ```zig
    /// const handleClick = struct {
    ///     fn callback(event: *Event) void {
    ///         std.debug.print("Handling click\n", .{});
    ///         event.stopPropagation(); // Don't let parents handle this
    ///     }
    /// }.callback;
    /// ```
    ///
    /// ### Multiple Listeners on Same Target
    /// ```zig
    /// // Both of these will execute even if first calls stopPropagation
    /// target.addEventListener("click", listener1, .{});
    /// target.addEventListener("click", listener2, .{});
    ///
    /// const listener1 = struct {
    ///     fn callback(event: *Event) void {
    ///         std.debug.print("Listener 1\n", .{});
    ///         event.stopPropagation();
    ///     }
    /// }.callback;
    ///
    /// const listener2 = struct {
    ///     fn callback(event: *Event) void {
    ///         // This WILL execute because it's on the same target
    ///         std.debug.print("Listener 2\n", .{});
    ///     }
    /// }.callback;
    /// ```
    ///
    /// ### Event Delegation Pattern
    /// ```zig
    /// const handleDelegatedClick = struct {
    ///     fn callback(event: *Event) void {
    ///         // Handle the event based on target
    ///         // Then stop it from bubbling up
    ///         event.stopPropagation();
    ///     }
    /// }.callback;
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Per DOM Standard §2.2:
    /// "The stopPropagation() method steps are to set this's stop propagation flag."
    ///
    /// The dispatch algorithm checks this flag at each step and skips further
    /// propagation when it is set.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-stoppropagation
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Event/stopPropagation
    pub fn stopPropagation(self: *Self) void {
        self.propagation_stopped = true;
    }

    /// Prevents all further listener invocation for this event.
    ///
    /// When called during event dispatch, this method immediately stops all event
    /// processing. No other listeners will be called, not even on the current target.
    /// This is the most aggressive way to stop event processing.
    ///
    /// ## Behavior
    ///
    /// ### Immediate Effect
    /// - Sets both `propagation_stopped` and `immediate_propagation_stopped` flags
    /// - Stops the current listener loop immediately
    /// - No subsequent listeners are invoked, even on the current target
    /// - No further propagation occurs
    ///
    /// ### Listener Execution Order
    ///
    /// If multiple listeners are registered on the same target:
    /// ```
    /// Listener 1 executes
    /// Listener 2 executes and calls stopImmediatePropagation()
    /// Listener 3 DOES NOT execute  ← stopped
    /// Listener 4 DOES NOT execute  ← stopped
    /// ```
    ///
    /// ## Difference from stopPropagation
    ///
    /// | Method | Current Target Listeners | Propagation |
    /// |--------|-------------------------|-------------|
    /// | stopPropagation() | All execute | Stopped |
    /// | stopImmediatePropagation() | Remaining skipped | Stopped |
    ///
    /// ## When to Use
    ///
    /// Use when you need to:
    /// - Completely stop all event processing
    /// - Ensure no other code can respond to the event
    /// - Handle critical events that should not be processed further
    /// - Prevent conflicts between multiple handlers
    ///
    /// ## Use Cases
    ///
    /// - **Critical Error Handling**: Stop all processing when an error occurs
    /// - **Security**: Prevent potentially malicious handlers from executing
    /// - **Performance**: Skip unnecessary listeners when outcome is determined
    /// - **Exclusive Handling**: Ensure only one handler processes the event
    ///
    /// ## Examples
    ///
    /// ### Stop All Listeners
    /// ```zig
    /// target.addEventListener("click", listener1, .{});
    /// target.addEventListener("click", listener2, .{});
    /// target.addEventListener("click", listener3, .{});
    ///
    /// const listener1 = struct {
    ///     fn callback(event: *Event) void {
    ///         std.debug.print("Listener 1 executes\n", .{});
    ///     }
    /// }.callback;
    ///
    /// const listener2 = struct {
    ///     fn callback(event: *Event) void {
    ///         std.debug.print("Listener 2 executes\n", .{});
    ///         event.stopImmediatePropagation(); // Stop here
    ///     }
    /// }.callback;
    ///
    /// const listener3 = struct {
    ///     fn callback(event: *Event) void {
    ///         // This will NOT execute
    ///         std.debug.print("Listener 3 would execute\n", .{});
    ///     }
    /// }.callback;
    /// ```
    ///
    /// ### Critical Error Handler
    /// ```zig
    /// const handleCriticalError = struct {
    ///     fn callback(event: *Event) void {
    ///         std.debug.print("Critical error detected!\n", .{});
    ///         event.stopImmediatePropagation();
    ///         // No other handlers should process this
    ///     }
    /// }.callback;
    /// ```
    ///
    /// ### Exclusive Processing
    /// ```zig
    /// const handleExclusive = struct {
    ///     fn callback(event: *Event) void {
    ///         if (shouldHandleExclusively()) {
    ///             // Process the event
    ///             processEvent(event);
    ///             // Prevent any other handlers
    ///             event.stopImmediatePropagation();
    ///         }
    ///     }
    /// }.callback;
    /// ```
    ///
    /// ### Checking State
    /// ```zig
    /// const event = try Event.init(allocator, "click", .{});
    /// defer event.deinit();
    ///
    /// event.stopImmediatePropagation();
    ///
    /// std.debug.assert(event.propagation_stopped);
    /// std.debug.assert(event.immediate_propagation_stopped);
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Per DOM Standard §2.2:
    /// "The stopImmediatePropagation() method steps are to set this's stop
    /// propagation flag and this's stop immediate propagation flag."
    ///
    /// The dispatch algorithm checks the immediate propagation flag within the
    /// listener invocation loop and breaks immediately when it is set.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-stopimmediatepropagation
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Event/stopImmediatePropagation
    pub fn stopImmediatePropagation(self: *Self) void {
        self.propagation_stopped = true;
        self.immediate_propagation_stopped = true;
    }

    /// Returns the event's path, which is an array of objects on which listeners
    /// will be invoked.
    ///
    /// The composed path represents the sequence of EventTarget objects that will
    /// (or did) receive the event during dispatch. The path depends on the event's
    /// `composed` flag and shadow DOM boundaries.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: The memory allocator to use for the returned path array.
    ///   The caller is responsible for freeing the returned slice.
    ///
    /// ## Returns
    ///
    /// An array of opaque pointers representing the event's propagation path.
    /// The caller must free this array when done:
    ///
    /// ```zig
    /// const path = try event.composedPath(allocator);
    /// defer allocator.free(path);
    /// ```
    ///
    /// ## Path Composition
    ///
    /// ### Without Shadow DOM
    /// The path is simply the chain from target to root:
    /// ```
    /// [root, parent, child, target]
    /// ```
    ///
    /// ### With Shadow DOM (composed: false)
    /// The path stops at shadow boundaries:
    /// ```
    /// [shadow-root, shadow-child, target]
    /// ```
    ///
    /// ### With Shadow DOM (composed: true)
    /// The path crosses shadow boundaries:
    /// ```
    /// [document, host, shadow-root, shadow-child, target]
    /// ```
    ///
    /// ## Implementation Note
    ///
    /// The current implementation returns an empty path as a stub. A complete
    /// implementation would:
    /// 1. Start at the event's target
    /// 2. Traverse up through parent nodes
    /// 3. Handle shadow DOM boundaries based on `composed` flag
    /// 4. Return the path in order from root to target
    ///
    /// This requires the Node tree structure (§4.2) to be implemented.
    ///
    /// ## Usage Examples
    ///
    /// ### Basic Usage
    /// ```zig
    /// const event = try Event.init(allocator, "click", .{
    ///     .composed = true,
    /// });
    /// defer event.deinit();
    ///
    /// const path = try event.composedPath(allocator);
    /// defer allocator.free(path);
    ///
    /// for (path) |target| {
    ///     std.debug.print("Target: {*}\n", .{target});
    /// }
    /// ```
    ///
    /// ### Checking Path Length
    /// ```zig
    /// const path = try event.composedPath(allocator);
    /// defer allocator.free(path);
    ///
    /// std.debug.print("Event will visit {} targets\n", .{path.len});
    /// ```
    ///
    /// ## Specification Compliance
    ///
    /// Per DOM Standard §2.2, composedPath() returns the event's path with
    /// shadow tree nodes filtered based on the shadow root's mode and the
    /// current target.
    ///
    /// The algorithm is defined in detail in §2.2 but requires:
    /// - Node tree structure
    /// - Shadow DOM support
    /// - Path tracking during dispatch
    ///
    /// ## Future Implementation
    ///
    /// When Node tree is implemented, this method should:
    /// 1. Build path from target to root
    /// 2. Filter shadow tree nodes appropriately
    /// 3. Return ordered array of targets
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-composedpath
    /// * MDN Web Docs: https://developer.mozilla.org/en-US/docs/Web/API/Event/composedPath
    pub fn composedPath(self: *Self, allocator: std.mem.Allocator) ![]const *anyopaque {
        _ = self;
        // Stub implementation - returns empty path
        // Full implementation requires Node tree structure
        return try allocator.alloc(*anyopaque, 0);
    }

    // ========================================================================
    // LEGACY PROPERTIES AND METHODS
    // ========================================================================
    // The following properties and methods are legacy features maintained
    // for backwards compatibility with older code. Modern code should use
    // the standard equivalents.

    /// Returns the event's target (legacy alias).
    ///
    /// This is a legacy property that returns the same value as `target`.
    /// It exists for backwards compatibility with Internet Explorer.
    ///
    /// ## Specification
    ///
    /// Per DOM Standard §2.2:
    /// "The srcElement getter steps are to return this's target."
    ///
    /// ## Modern Alternative
    ///
    /// Use `event.target` instead of `event.srcElement`.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-srcelement
    pub fn getSrcElement(self: *const Self) ?*anyopaque {
        return self.target;
    }

    /// Gets or sets the stop propagation flag (legacy property).
    ///
    /// This is a legacy property that acts as an alias for stopPropagation().
    /// - Getting returns true if propagation is stopped
    /// - Setting to true calls stopPropagation()
    ///
    /// ## Specification
    ///
    /// Per DOM Standard §2.2:
    /// "The cancelBubble getter steps are to return true if this's stop
    /// propagation flag is set; otherwise false. The cancelBubble setter
    /// steps are to set this's stop propagation flag if the given value
    /// is true; otherwise do nothing."
    ///
    /// ## Modern Alternative
    ///
    /// Use `event.stopPropagation()` instead of setting `cancelBubble`.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-cancelbubble
    pub fn getCancelBubble(self: *const Self) bool {
        return self.propagation_stopped;
    }

    pub fn setCancelBubble(self: *Self, value: bool) void {
        if (value) {
            self.propagation_stopped = true;
        }
    }

    /// Gets or sets the return value (legacy property).
    ///
    /// This is a legacy property that acts as the inverse of defaultPrevented.
    /// - Getting returns false if defaultPrevented is true, otherwise true
    /// - Setting to false calls preventDefault() if the event is cancelable
    ///
    /// ## Specification
    ///
    /// Per DOM Standard §2.2:
    /// "The returnValue getter steps are to return false if this's canceled
    /// flag is set; otherwise true. The returnValue setter steps are to set
    /// the canceled flag with this if the given value is false; otherwise
    /// do nothing."
    ///
    /// ## Modern Alternative
    ///
    /// Use `event.preventDefault()` and `event.defaultPrevented` instead.
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-returnvalue
    pub fn getReturnValue(self: *const Self) bool {
        return !self.default_prevented;
    }

    pub fn setReturnValue(self: *Self, value: bool) void {
        if (!value and self.cancelable) {
            self.default_prevented = true;
        }
    }

    /// Initializes the event's properties (legacy method).
    ///
    /// This is a legacy method for initializing an event after construction.
    /// It is maintained for backwards compatibility but is redundant with
    /// the Event constructor.
    ///
    /// ## Parameters
    ///
    /// - `type_name`: The event type
    /// - `bubbles`: Whether the event bubbles (default false)
    /// - `cancelable`: Whether the event is cancelable (default false)
    ///
    /// ## Behavior
    ///
    /// Per DOM Standard §2.2:
    /// "If this's dispatch flag is set, then return."
    ///
    /// This prevents reinitializing an event that is currently being dispatched.
    ///
    /// ## Modern Alternative
    ///
    /// Use the Event constructor instead:
    /// ```zig
    /// const event = try Event.init(allocator, "click", .{
    ///     .bubbles = true,
    ///     .cancelable = true,
    /// });
    /// ```
    ///
    /// ## Reference
    ///
    /// * WHATWG DOM Standard: https://dom.spec.whatwg.org/#dom-event-initevent
    pub fn initEvent(self: *Self, type_name: []const u8, bubbles: bool, cancelable: bool) !void {
        // If the event is currently being dispatched, do nothing
        if (self.event_phase != .none) {
            return;
        }

        // Reinitialize the event properties
        self.allocator.free(self.type_name);
        self.type_name = try self.allocator.dupe(u8, type_name);
        self.bubbles = bubbles;
        self.cancelable = cancelable;
        self.default_prevented = false;
        self.propagation_stopped = false;
        self.immediate_propagation_stopped = false;
        self.target = null;
        self.current_target = null;
        self.event_phase = .none;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "Event creation" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{
        .bubbles = true,
        .cancelable = true,
        .composed = false,
    });
    defer event.deinit();

    try std.testing.expectEqualStrings("click", event.type_name);
    try std.testing.expectEqual(true, event.bubbles);
    try std.testing.expectEqual(true, event.cancelable);
    try std.testing.expectEqual(false, event.composed);
    try std.testing.expectEqual(false, event.default_prevented);
    try std.testing.expectEqual(EventPhase.none, event.event_phase);
}

test "Event preventDefault" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "submit", .{
        .bubbles = true,
        .cancelable = true,
    });
    defer event.deinit();

    try std.testing.expectEqual(false, event.default_prevented);
    event.preventDefault();
    try std.testing.expectEqual(true, event.default_prevented);
}

test "Event preventDefault non-cancelable" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "custom", .{
        .bubbles = false,
        .cancelable = false,
    });
    defer event.deinit();

    event.preventDefault();
    try std.testing.expectEqual(false, event.default_prevented);
}

test "Event stopPropagation" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    try std.testing.expectEqual(false, event.propagation_stopped);
    event.stopPropagation();
    try std.testing.expectEqual(true, event.propagation_stopped);
}

test "Event stopImmediatePropagation" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    try std.testing.expectEqual(false, event.propagation_stopped);
    try std.testing.expectEqual(false, event.immediate_propagation_stopped);
    event.stopImmediatePropagation();
    try std.testing.expectEqual(true, event.propagation_stopped);
    try std.testing.expectEqual(true, event.immediate_propagation_stopped);
}

test "Event default options" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "custom", .{});
    defer event.deinit();

    try std.testing.expectEqual(false, event.bubbles);
    try std.testing.expectEqual(false, event.cancelable);
    try std.testing.expectEqual(false, event.composed);
}

test "Event isTrusted is false for synthetic events" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    try std.testing.expectEqual(false, event.is_trusted);
}

test "Event composedPath returns empty array" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    const path = try event.composedPath(allocator);
    defer allocator.free(path);

    try std.testing.expectEqual(@as(usize, 0), path.len);
}

test "Event phase transitions" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    // Initial phase should be none
    try std.testing.expectEqual(EventPhase.none, event.event_phase);

    // Simulate phase transitions (as would happen during dispatch)
    event.event_phase = .capturing_phase;
    try std.testing.expectEqual(EventPhase.capturing_phase, event.event_phase);

    event.event_phase = .at_target;
    try std.testing.expectEqual(EventPhase.at_target, event.event_phase);

    event.event_phase = .bubbling_phase;
    try std.testing.expectEqual(EventPhase.bubbling_phase, event.event_phase);

    event.event_phase = .none;
    try std.testing.expectEqual(EventPhase.none, event.event_phase);
}

test "Event stopPropagation does not affect stopImmediatePropagation" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    // Initially both flags are false
    try std.testing.expectEqual(false, event.propagation_stopped);
    try std.testing.expectEqual(false, event.immediate_propagation_stopped);

    // Call stopPropagation
    event.stopPropagation();
    try std.testing.expectEqual(true, event.propagation_stopped);
    try std.testing.expectEqual(false, event.immediate_propagation_stopped);
}

test "Event stopImmediatePropagation sets both flags" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    // Call stopImmediatePropagation
    event.stopImmediatePropagation();

    // Both flags should be set
    try std.testing.expectEqual(true, event.propagation_stopped);
    try std.testing.expectEqual(true, event.immediate_propagation_stopped);
}

test "Event multiple preventDefault calls" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "submit", .{
        .cancelable = true,
    });
    defer event.deinit();

    // First call
    event.preventDefault();
    try std.testing.expectEqual(true, event.default_prevented);

    // Second call should have no additional effect
    event.preventDefault();
    try std.testing.expectEqual(true, event.default_prevented);

    // Third call
    event.preventDefault();
    try std.testing.expectEqual(true, event.default_prevented);
}

test "Event timestamp is set at creation" {
    const allocator = std.testing.allocator;

    const before = std.time.milliTimestamp();
    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();
    const after = std.time.milliTimestamp();

    // Timestamp should be between before and after
    try std.testing.expect(event.timestamp >= before);
    try std.testing.expect(event.timestamp <= after);
}

test "Event target and currentTarget distinction" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    // Initially both should be null
    try std.testing.expectEqual(@as(?*anyopaque, null), event.target);
    try std.testing.expectEqual(@as(?*anyopaque, null), event.current_target);

    // Simulate dispatch setting different values
    var dummy_target: u32 = 1;
    var dummy_current: u32 = 2;

    event.target = &dummy_target;
    event.current_target = &dummy_current;

    // They should be different
    try std.testing.expect(event.target != event.current_target);
}

test "Event all options combinations" {
    const allocator = std.testing.allocator;

    // Test all false (default)
    const event1 = try Event.init(allocator, "test", .{});
    defer event1.deinit();
    try std.testing.expectEqual(false, event1.bubbles);
    try std.testing.expectEqual(false, event1.cancelable);
    try std.testing.expectEqual(false, event1.composed);

    // Test all true
    const event2 = try Event.init(allocator, "test", .{
        .bubbles = true,
        .cancelable = true,
        .composed = true,
    });
    defer event2.deinit();
    try std.testing.expectEqual(true, event2.bubbles);
    try std.testing.expectEqual(true, event2.cancelable);
    try std.testing.expectEqual(true, event2.composed);

    // Test mixed combinations
    const event3 = try Event.init(allocator, "test", .{
        .bubbles = true,
        .cancelable = false,
        .composed = true,
    });
    defer event3.deinit();
    try std.testing.expectEqual(true, event3.bubbles);
    try std.testing.expectEqual(false, event3.cancelable);
    try std.testing.expectEqual(true, event3.composed);
}

test "Event type validation - empty string" {
    const allocator = std.testing.allocator;

    // Empty string should be valid per spec
    const event = try Event.init(allocator, "", .{});
    defer event.deinit();

    try std.testing.expectEqualStrings("", event.type_name);
}

test "Event type validation - special characters" {
    const allocator = std.testing.allocator;

    // Special characters should be allowed
    const event1 = try Event.init(allocator, "custom:event", .{});
    defer event1.deinit();
    try std.testing.expectEqualStrings("custom:event", event1.type_name);

    const event2 = try Event.init(allocator, "event-name", .{});
    defer event2.deinit();
    try std.testing.expectEqualStrings("event-name", event2.type_name);

    const event3 = try Event.init(allocator, "event_name", .{});
    defer event3.deinit();
    try std.testing.expectEqualStrings("event_name", event3.type_name);
}

test "Event type validation - case sensitivity" {
    const allocator = std.testing.allocator;

    const event1 = try Event.init(allocator, "click", .{});
    defer event1.deinit();

    const event2 = try Event.init(allocator, "Click", .{});
    defer event2.deinit();

    const event3 = try Event.init(allocator, "CLICK", .{});
    defer event3.deinit();

    // All should be different
    try std.testing.expect(!std.mem.eql(u8, event1.type_name, event2.type_name));
    try std.testing.expect(!std.mem.eql(u8, event1.type_name, event3.type_name));
    try std.testing.expect(!std.mem.eql(u8, event2.type_name, event3.type_name));
}

test "Event memory leak test - rapid creation and destruction" {
    const allocator = std.testing.allocator;

    // Create and destroy many events rapidly
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const event = try Event.init(allocator, "test", .{
            .bubbles = true,
            .cancelable = true,
            .composed = true,
        });
        event.deinit();
    }

    // If there were leaks, the test allocator would catch them
}

test "Event composed flag behavior" {
    const allocator = std.testing.allocator;

    // Non-composed event
    const event1 = try Event.init(allocator, "custom", .{
        .composed = false,
    });
    defer event1.deinit();
    try std.testing.expectEqual(false, event1.composed);

    // Composed event
    const event2 = try Event.init(allocator, "custom", .{
        .composed = true,
    });
    defer event2.deinit();
    try std.testing.expectEqual(true, event2.composed);
}

test "Event bubbling flag behavior" {
    const allocator = std.testing.allocator;

    // Non-bubbling event
    const event1 = try Event.init(allocator, "load", .{
        .bubbles = false,
    });
    defer event1.deinit();
    try std.testing.expectEqual(false, event1.bubbles);

    // Bubbling event
    const event2 = try Event.init(allocator, "click", .{
        .bubbles = true,
    });
    defer event2.deinit();
    try std.testing.expectEqual(true, event2.bubbles);
}

test "Event cancelable flag with multiple preventDefault attempts" {
    const allocator = std.testing.allocator;

    // Cancelable event
    const event1 = try Event.init(allocator, "submit", .{
        .cancelable = true,
    });
    defer event1.deinit();

    event1.preventDefault();
    try std.testing.expectEqual(true, event1.default_prevented);

    // Non-cancelable event
    const event2 = try Event.init(allocator, "load", .{
        .cancelable = false,
    });
    defer event2.deinit();

    // Multiple attempts should have no effect
    event2.preventDefault();
    event2.preventDefault();
    event2.preventDefault();
    try std.testing.expectEqual(false, event2.default_prevented);
}

test "Event state after stopPropagation and preventDefault" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{
        .bubbles = true,
        .cancelable = true,
    });
    defer event.deinit();

    // Both should work independently
    event.stopPropagation();
    event.preventDefault();

    try std.testing.expectEqual(true, event.propagation_stopped);
    try std.testing.expectEqual(false, event.immediate_propagation_stopped);
    try std.testing.expectEqual(true, event.default_prevented);
}

test "Event composedPath memory management" {
    const allocator = std.testing.allocator;

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    // Call composedPath multiple times
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const path = try event.composedPath(allocator);
        defer allocator.free(path);
        try std.testing.expectEqual(@as(usize, 0), path.len);
    }
}
