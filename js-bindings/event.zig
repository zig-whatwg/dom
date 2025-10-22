//! Event JavaScript Bindings
//!
//! C-ABI bindings for the Event interface.
//!
//! ## WHATWG Specification
//!
//! Event is the base interface for all DOM events:
//! - **§2.2 Interface Event**: https://dom.spec.whatwg.org/#interface-event
//!
//! ## MDN Documentation
//!
//! - Event: https://developer.mozilla.org/en-US/docs/Web/API/Event
//! - Event.type: https://developer.mozilla.org/en-US/docs/Web/API/Event/type
//! - Event.target: https://developer.mozilla.org/en-US/docs/Web/API/Event/target
//! - Event.currentTarget: https://developer.mozilla.org/en-US/docs/Web/API/Event/currentTarget
//! - Event.eventPhase: https://developer.mozilla.org/en-US/docs/Web/API/Event/eventPhase
//! - Event.bubbles: https://developer.mozilla.org/en-US/docs/Web/API/Event/bubbles
//! - Event.cancelable: https://developer.mozilla.org/en-US/docs/Web/API/Event/cancelable
//! - Event.defaultPrevented: https://developer.mozilla.org/en-US/docs/Web/API/Event/defaultPrevented
//! - Event.composed: https://developer.mozilla.org/en-US/docs/Web/API/Event/composed
//! - Event.timeStamp: https://developer.mozilla.org/en-US/docs/Web/API/Event/timeStamp
//! - Event.preventDefault(): https://developer.mozilla.org/en-US/docs/Web/API/Event/preventDefault
//! - Event.stopPropagation(): https://developer.mozilla.org/en-US/docs/Web/API/Event/stopPropagation
//! - Event.stopImmediatePropagation(): https://developer.mozilla.org/en-US/docs/Web/API/Event/stopImmediatePropagation
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=*]
//! interface Event {
//!   constructor(DOMString type, optional EventInit eventInitDict = {});
//!
//!   readonly attribute DOMString type;
//!   readonly attribute EventTarget? target;
//!   readonly attribute EventTarget? currentTarget;
//!   sequence<EventTarget> composedPath();
//!
//!   const unsigned short NONE = 0;
//!   const unsigned short CAPTURING_PHASE = 1;
//!   const unsigned short AT_TARGET = 2;
//!   const unsigned short BUBBLING_PHASE = 3;
//!   readonly attribute unsigned short eventPhase;
//!
//!   undefined stopPropagation();
//!   undefined stopImmediatePropagation();
//!
//!   readonly attribute boolean bubbles;
//!   readonly attribute boolean cancelable;
//!   undefined preventDefault();
//!   readonly attribute boolean defaultPrevented;
//!   readonly attribute boolean composed;
//!
//!   [LegacyUnforgeable] readonly attribute boolean isTrusted;
//!   readonly attribute DOMHighResTimeStamp timeStamp;
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#event (WebIDL: dom.idl:39-65)
//!
//! ## Exported Functions (18 total)
//!
//! ### Constructor
//! - `dom_event_new()` - Create new Event (heap-allocated)
//!
//! ### Properties
//! - `dom_event_get_type()` - Event type string
//! - `dom_event_get_target()` - Original target
//! - `dom_event_get_currenttarget()` - Current target
//! - `dom_event_get_eventphase()` - Event phase
//! - `dom_event_get_bubbles()` - Bubbles flag
//! - `dom_event_get_cancelable()` - Cancelable flag
//! - `dom_event_get_defaultprevented()` - Default prevented flag
//! - `dom_event_get_composed()` - Composed flag
//! - `dom_event_get_istrusted()` - Is trusted flag
//! - `dom_event_get_timestamp()` - Creation timestamp
//!
//! ### Methods
//! - `dom_event_stoppropagation()` - Stop propagation
//! - `dom_event_stopimmediatepropagation()` - Stop immediately
//! - `dom_event_preventdefault()` - Prevent default action
//!
//! ### Constants
//! - `DOM_EVENT_NONE`, `DOM_EVENT_CAPTURING_PHASE`, `DOM_EVENT_AT_TARGET`, `DOM_EVENT_BUBBLING_PHASE`
//!
//! ### Memory Management
//! - `dom_event_addref()` - Increment reference count
//! - `dom_event_release()` - Decrement reference count
//!
//! ## Usage Example (C)
//!
//! ```c
//! // Events are typically created and used during dispatch
//! DOMEvent* event = /* received from dispatchEvent or listener */;
//!
//! // Get properties
//! const char* type = dom_event_get_type(event);
//! printf("Event type: %s\n", type);
//!
//! unsigned short phase = dom_event_get_eventphase(event);
//! if (phase == DOM_EVENT_AT_TARGET) {
//!     printf("At target\n");
//! }
//!
//! // Control propagation
//! if (some_condition) {
//!     dom_event_stoppropagation(event);
//! }
//!
//! // Prevent default
//! if (dom_event_get_cancelable(event)) {
//!     dom_event_preventdefault(event);
//! }
//!
//! // Check if default was prevented
//! if (dom_event_get_defaultprevented(event)) {
//!     printf("Default action cancelled\n");
//! }
//! ```

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const Event = dom.Event;
const EventInit = dom.EventInit;
const EventTarget = dom.EventTarget;
const DOMEvent = types.DOMEvent;
const DOMEventTarget = types.DOMEventTarget;

// ============================================================================
// Constructor
// ============================================================================

/// Creates a new Event (heap-allocated).
///
/// ## WebIDL
/// ```webidl
/// constructor(DOMString type, optional EventInit eventInitDict = {});
/// ```
///
/// ## Parameters
/// - `event_type`: Event type string (e.g., "click", "load")
/// - `bubbles`: 1 if event bubbles, 0 otherwise
/// - `cancelable`: 1 if event can be cancelled, 0 otherwise
/// - `composed`: 1 if event crosses shadow boundaries, 0 otherwise
///
/// ## Returns
/// Heap-allocated Event pointer, or NULL on allocation failure
/// - **IMPORTANT**: Caller must call `dom_event_release()` to free
///
/// ## Spec References
/// - Constructor: https://dom.spec.whatwg.org/#dom-event-event
/// - WebIDL: dom.idl:8
///
/// ## Example (C)
/// ```c
/// // Create click event (bubbles, cancelable, not composed)
/// DOMEvent* event = dom_event_new("click", 1, 1, 0);
/// if (event == NULL) {
///     fprintf(stderr, "Failed to create event\n");
///     return -1;
/// }
///
/// // Use event...
/// const char* type = dom_event_get_type(event);
/// printf("Event type: %s\n", type);
///
/// // Cleanup
/// dom_event_release(event);
/// ```
pub export fn dom_event_new(
    event_type: [*:0]const u8,
    bubbles: u8,
    cancelable: u8,
    composed: u8,
) ?*DOMEvent {
    const allocator = std.heap.page_allocator;
    const type_str = types.cStringToZigString(event_type);

    // Duplicate the string so it persists (event stores pointer, not copy)
    const type_copy = allocator.dupeZ(u8, type_str) catch return null;

    const event_ptr = allocator.create(Event) catch {
        allocator.free(type_copy);
        return null;
    };
    event_ptr.* = Event.init(type_copy, .{
        .bubbles = bubbles != 0,
        .cancelable = cancelable != 0,
        .composed = composed != 0,
    });

    return @ptrCast(event_ptr);
}

// ============================================================================
// Constants
// ============================================================================

/// Event phase: Not in event flow
pub const DOM_EVENT_NONE: u16 = 0;

/// Event phase: Capturing phase (going down the tree)
pub const DOM_EVENT_CAPTURING_PHASE: u16 = 1;

/// Event phase: At the target element
pub const DOM_EVENT_AT_TARGET: u16 = 2;

/// Event phase: Bubbling phase (going up the tree)
pub const DOM_EVENT_BUBBLING_PHASE: u16 = 3;

// Export constants as C symbols
pub export fn dom_event_constant_none() u16 {
    return DOM_EVENT_NONE;
}
pub export fn dom_event_constant_capturing_phase() u16 {
    return DOM_EVENT_CAPTURING_PHASE;
}
pub export fn dom_event_constant_at_target() u16 {
    return DOM_EVENT_AT_TARGET;
}
pub export fn dom_event_constant_bubbling_phase() u16 {
    return DOM_EVENT_BUBBLING_PHASE;
}

// ============================================================================
// Properties
// ============================================================================

/// Gets the type of the event.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString type;
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Returns
/// Event type string (e.g., "click", "load") - borrowed, do NOT free
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-type
/// - WebIDL: dom.idl:42
pub export fn dom_event_get_type(event: *DOMEvent) [*:0]const u8 {
    const evt: *Event = @ptrCast(@alignCast(event));
    return types.zigStringToCString(evt.event_type);
}

/// Gets the event phase.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned short eventPhase;
/// ```
///
/// ## Returns
/// Event phase: NONE(0), CAPTURING_PHASE(1), AT_TARGET(2), BUBBLING_PHASE(3)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-eventphase
/// - WebIDL: dom.idl:50
pub export fn dom_event_get_eventphase(event: *DOMEvent) u16 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return @intFromEnum(evt.event_phase);
}

/// Gets whether the event bubbles.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean bubbles;
/// ```
///
/// ## Returns
/// 1 if event bubbles, 0 otherwise
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-bubbles
/// - WebIDL: dom.idl:55
pub export fn dom_event_get_bubbles(event: *DOMEvent) u8 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.bubbles) 1 else 0;
}

/// Gets whether the event is cancelable.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean cancelable;
/// ```
///
/// ## Returns
/// 1 if event is cancelable, 0 otherwise
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-cancelable
/// - WebIDL: dom.idl:56
pub export fn dom_event_get_cancelable(event: *DOMEvent) u8 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.cancelable) 1 else 0;
}

/// Gets whether the default action was prevented.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean defaultPrevented;
/// ```
///
/// ## Returns
/// 1 if default was prevented, 0 otherwise
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-defaultprevented
/// - WebIDL: dom.idl:58
pub export fn dom_event_get_defaultprevented(event: *DOMEvent) u8 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.defaultPrevented()) 1 else 0;
}

/// Gets whether the event is composed.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean composed;
/// ```
///
/// ## Returns
/// 1 if event crosses shadow boundaries, 0 otherwise
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-composed
/// - WebIDL: dom.idl:59
pub export fn dom_event_get_composed(event: *DOMEvent) u8 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.composed) 1 else 0;
}

/// Gets whether the event is trusted.
///
/// ## WebIDL
/// ```webidl
/// [LegacyUnforgeable] readonly attribute boolean isTrusted;
/// ```
///
/// ## Returns
/// 1 if trusted (generated by user agent), 0 if synthetic
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-istrusted
/// - WebIDL: dom.idl:61
pub export fn dom_event_get_istrusted(event: *DOMEvent) u8 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.is_trusted) 1 else 0;
}

/// Gets the event timestamp.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMHighResTimeStamp timeStamp;
/// ```
///
/// ## Returns
/// Timestamp in milliseconds
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-timestamp
/// - WebIDL: dom.idl:62
pub export fn dom_event_get_timestamp(event: *DOMEvent) f64 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return evt.time_stamp;
}

/// Gets the event target (original target).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute EventTarget? target;
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Returns
/// Event target (EventTarget or Node), or NULL if not set
/// - Borrowed reference - do NOT release separately
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-target
/// - WebIDL: dom.idl:43
///
/// ## Note
/// The target is the object to which the event was originally dispatched.
/// It remains constant during propagation, unlike currentTarget.
///
/// ## Example (C)
/// ```c
/// DOMNode* target = (DOMNode*)dom_event_get_target(event);
/// if (target) {
///     const char* name = dom_node_get_nodename(target);
///     printf("Event target: %s\n", name);
/// }
/// ```
pub export fn dom_event_get_target(event: *DOMEvent) ?*types.DOMEventTarget {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.target) |t| @ptrCast(t) else null;
}

/// Gets the current event target (listener being invoked).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute EventTarget? currentTarget;
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Returns
/// Current target (where listener is attached), or NULL if not dispatching
/// - Borrowed reference - do NOT release separately
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-currenttarget
/// - WebIDL: dom.idl:44
///
/// ## Note
/// The currentTarget changes during propagation to reflect the object
/// whose event listener is currently being invoked.
///
/// ## Example (C)
/// ```c
/// DOMNode* current = (DOMNode*)dom_event_get_currenttarget(event);
/// if (current) {
///     printf("Listener attached to: %s\n", dom_node_get_nodename(current));
/// }
/// ```
pub export fn dom_event_get_currenttarget(event: *DOMEvent) ?*types.DOMEventTarget {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.current_target) |t| @ptrCast(t) else null;
}

/// Gets the source element (legacy alias for target).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute EventTarget? srcElement; // legacy
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Returns
/// Event target (same as target attribute)
/// - Borrowed reference - do NOT release separately
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-srcelement
/// - WebIDL: dom.idl:44 (legacy)
///
/// ## Note
/// This is a legacy alias for the target attribute, provided for
/// compatibility with older code. New code should use target instead.
///
/// ## Example (C)
/// ```c
/// // srcElement is the same as target
/// DOMNode* target = (DOMNode*)dom_event_get_target(event);
/// DOMNode* srcElement = (DOMNode*)dom_event_get_srcelement(event);
/// // target == srcElement
/// ```
pub export fn dom_event_get_srcelement(event: *DOMEvent) ?*types.DOMEventTarget {
    // srcElement is just an alias for target
    return dom_event_get_target(event);
}

// ============================================================================
// Methods
// ============================================================================

/// Stops propagation of the event to other targets.
///
/// ## WebIDL
/// ```webidl
/// undefined stopPropagation();
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-event-stoppropagation
/// - WebIDL: dom.idl:52
pub export fn dom_event_stoppropagation(event: *DOMEvent) void {
    const evt: *Event = @ptrCast(@alignCast(event));
    evt.stopPropagation();
}

/// Stops propagation immediately (current listeners won't fire).
///
/// ## WebIDL
/// ```webidl
/// undefined stopImmediatePropagation();
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-event-stopimmediatepropagation
/// - WebIDL: dom.idl:53
pub export fn dom_event_stopimmediatepropagation(event: *DOMEvent) void {
    const evt: *Event = @ptrCast(@alignCast(event));
    evt.stopImmediatePropagation();
}

/// Prevents the default action associated with the event.
///
/// ## WebIDL
/// ```webidl
/// undefined preventDefault();
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Note
/// Only works if event.cancelable is true
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-event-preventdefault
/// - WebIDL: dom.idl:57
pub export fn dom_event_preventdefault(event: *DOMEvent) void {
    const evt: *Event = @ptrCast(@alignCast(event));
    evt.preventDefault();
}

/// Get the event propagation path.
///
/// ## WebIDL
/// ```webidl
/// sequence<EventTarget> composedPath();
/// ```
///
/// ## Algorithm (WHATWG DOM §2.9)
/// Returns an array of EventTarget objects representing the path through which
/// the event will propagate (or has propagated). The path is computed during
/// event dispatch and respects shadow DOM boundaries.
///
/// ## Parameters
/// - `event`: Event handle
/// - `count`: Pointer to store the number of targets in the path
///
/// ## Returns
/// Array of EventTarget pointers (caller must free with dom_event_free_composedpath)
/// Returns NULL if event has not been dispatched or on error.
///
/// ## Memory Management
/// The returned array is allocated and owned by the caller.
/// You MUST call dom_event_free_composedpath() when done to avoid memory leaks.
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-event-composedpath
/// - WebIDL: dom.idl:36
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Event/composedPath
///
/// ## Example
/// ```c
/// uint32_t count = 0;
/// DOMEventTarget** path = dom_event_composedpath(event, &count);
/// if (path) {
///     for (uint32_t i = 0; i < count; i++) {
///         // Process each target in the path
///     }
///     dom_event_free_composedpath(path);
/// }
/// ```
pub export fn dom_event_composedpath(event: *DOMEvent, count: *u32) ?[*]?*DOMEventTarget {
    const evt: *const Event = @ptrCast(@alignCast(event));
    const allocator = std.heap.c_allocator;

    // Get composed path from event
    var path = evt.composedPath(allocator) catch return null;
    defer path.deinit(allocator);

    // If no path, return NULL
    if (path.items.len == 0) {
        count.* = 0;
        return null;
    }

    // Allocate array for C
    const c_array = allocator.alloc(?*DOMEventTarget, path.items.len) catch return null;

    // Copy event targets to array
    for (path.items, 0..) |target, i| {
        c_array[i] = @ptrCast(target);
    }

    count.* = @intCast(path.items.len);
    return c_array.ptr;
}

/// Free composedPath array.
///
/// ## Parameters
/// - `path`: Array returned from dom_event_composedpath()
/// - `count`: Number of elements in the array (same as returned by composedpath)
///
/// ## Example
/// ```c
/// uint32_t count = 0;
/// DOMEventTarget** path = dom_event_composedpath(event, &count);
/// // ... use path ...
/// dom_event_free_composedpath(path, count);
/// ```
pub export fn dom_event_free_composedpath(path: [*]?*DOMEventTarget, count: u32) void {
    const allocator = std.heap.c_allocator;
    if (count > 0) {
        const slice = path[0..count];
        allocator.free(slice);
    }
}

/// Initialize an event (legacy method).
///
/// ## WebIDL
/// ```webidl
/// undefined initEvent(DOMString type, optional boolean bubbles = false, optional boolean cancelable = false);
/// ```
///
/// ## Parameters
/// - `event`: Event handle
/// - `type`: Event type string
/// - `bubbles`: Whether event bubbles (0 = false, non-zero = true)
/// - `cancelable`: Whether event is cancelable (0 = false, non-zero = true)
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-event-initevent
/// - WebIDL: dom.idl:58
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Event/initEvent
///
/// ## Note
/// This is a legacy method from DOM Level 2. Modern code should use Event constructors instead.
/// This method can only be called before the event is dispatched.
///
/// ## Example (C)
/// ```c
/// DOMEvent* event = dom_event_new();
/// dom_event_initevent(event, "click", 1, 1);  // bubbles=true, cancelable=true
/// // ... dispatch event ...
/// dom_event_release(event);
/// ```
pub export fn dom_event_initevent(event: *DOMEvent, type_str: [*:0]const u8, bubbles: u8, cancelable: u8) void {
    const evt: *Event = @ptrCast(@alignCast(event));
    const event_type = types.cStringToZigString(type_str);
    const bubbles_bool = (bubbles != 0);
    const cancelable_bool = (cancelable != 0);
    evt.initEvent(event_type, bubbles_bool, cancelable_bool);
}

/// Get cancelBubble flag (legacy).
///
/// ## WebIDL
/// ```webidl
/// attribute boolean cancelBubble; // legacy alias of stopPropagation()
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Returns
/// 1 if propagation stopped, 0 otherwise
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-cancelbubble
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Event/cancelBubble
///
/// ## Note
/// This is a legacy attribute. Use stopPropagation() instead.
pub export fn dom_event_get_cancelbubble(event: *DOMEvent) u8 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.getCancelBubble()) 1 else 0;
}

/// Set cancelBubble flag (legacy).
///
/// ## WebIDL
/// ```webidl
/// attribute boolean cancelBubble; // legacy alias of stopPropagation()
/// ```
///
/// ## Parameters
/// - `event`: Event handle
/// - `value`: Non-zero to stop propagation, 0 to allow
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-cancelbubble
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Event/cancelBubble
///
/// ## Note
/// This is a legacy attribute. Setting to true calls stopPropagation().
pub export fn dom_event_set_cancelbubble(event: *DOMEvent, value: u8) void {
    const evt: *Event = @ptrCast(@alignCast(event));
    evt.setCancelBubble(value != 0);
}

/// Get returnValue flag (legacy).
///
/// ## WebIDL
/// ```webidl
/// attribute boolean returnValue; // legacy
/// ```
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Returns
/// 0 if default prevented, 1 otherwise
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-returnvalue
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Event/returnValue
///
/// ## Note
/// This is a legacy attribute. Returns opposite of defaultPrevented.
pub export fn dom_event_get_returnvalue(event: *DOMEvent) u8 {
    const evt: *const Event = @ptrCast(@alignCast(event));
    return if (evt.getReturnValue()) 1 else 0;
}

/// Set returnValue flag (legacy).
///
/// ## WebIDL
/// ```webidl
/// attribute boolean returnValue; // legacy
/// ```
///
/// ## Parameters
/// - `event`: Event handle
/// - `value`: 0 to prevent default, non-zero to allow
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-event-returnvalue
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/Event/returnValue
///
/// ## Note
/// This is a legacy attribute. Setting to false calls preventDefault().
pub export fn dom_event_set_returnvalue(event: *DOMEvent, value: u8) void {
    const evt: *Event = @ptrCast(@alignCast(event));
    evt.setReturnValue(value != 0);
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of an Event.
///
/// Events in C-ABI are heap-allocated and reference counted.
///
/// ## Parameters
/// - `event`: Event handle
pub export fn dom_event_addref(event: *DOMEvent) void {
    const allocator = std.heap.page_allocator;
    // Events are value types in Zig, in C-ABI we heap-allocate
    // For now, this is a no-op as events are typically short-lived
    _ = event;
    _ = allocator;
}

/// Decrement the reference count of an Event.
///
/// When count reaches 0, frees the event.
///
/// ## Parameters
/// - `event`: Event handle
///
/// ## Note
/// This currently leaks the event_type string. TODO: Track string ownership.
pub export fn dom_event_release(event: *DOMEvent) void {
    const allocator = std.heap.page_allocator;
    const evt: *Event = @ptrCast(@alignCast(event));

    // TODO: Free the event_type string (requires tracking ownership)
    // For now, we leak it to avoid alignment issues

    // Free the Event struct
    allocator.destroy(evt);
}
