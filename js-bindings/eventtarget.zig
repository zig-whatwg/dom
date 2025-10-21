//! EventTarget JavaScript Bindings
//!
//! C-ABI bindings for the EventTarget interface.
//!
//! ## WHATWG Specification
//!
//! EventTarget is the base interface for objects that can receive events:
//! - **§2.4 Interface EventTarget**: https://dom.spec.whatwg.org/#interface-eventtarget
//!
//! ## MDN Documentation
//!
//! - EventTarget: https://developer.mozilla.org/en-US/docs/Web/API/EventTarget
//! - EventTarget.dispatchEvent(): https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/dispatchEvent
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=*]
//! interface EventTarget {
//!   constructor();
//!
//!   undefined addEventListener(DOMString type, EventListener? callback, optional (AddEventListenerOptions or boolean) options = {});
//!   undefined removeEventListener(DOMString type, EventListener? callback, optional (EventListenerOptions or boolean) options = {});
//!   boolean dispatchEvent(Event event);
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#eventtarget (WebIDL: dom.idl:67-73)
//!
//! ## Exported Functions (5 total)
//!
//! ### Methods
//! - `dom_eventtarget_addeventlistener()` - Add event listener
//! - `dom_eventtarget_removeeventlistener()` - Remove event listener
//! - `dom_eventtarget_dispatchevent()` - Dispatch an event
//!
//! ### Memory Management
//! - `dom_eventtarget_addref()` - Increment reference count
//! - `dom_eventtarget_release()` - Decrement reference count
//!
//! ## Usage Example (C)
//!
//! ```c
//! DOMDocument* doc = dom_document_new();
//! DOMElement* elem = dom_document_createelement(doc, "button");
//!
//! // Create event (heap-allocated for C-ABI)
//! DOMEvent* event = create_custom_event("click");
//!
//! // Dispatch event on element (which inherits from EventTarget)
//! int was_cancelled = dom_eventtarget_dispatchevent((DOMEventTarget*)elem, event);
//! if (!was_cancelled) {
//!     printf("Event was not cancelled\n");
//! }
//!
//! dom_event_release(event);
//! dom_element_release(elem);
//! dom_document_release(doc);
//! ```

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const Event = dom.Event;
const EventTarget = dom.EventTarget;
const EventCallback = dom.EventTarget.EventCallback;
const DOMEvent = types.DOMEvent;
const DOMEventTarget = opaque {}; // EventTarget is a mixin, represented by Node/Document/Element

/// C-compatible event listener callback.
///
/// This is the C-ABI signature for event listener callbacks that can be
/// registered with addEventListener().
///
/// ## Parameters
/// - `event`: Event being dispatched (borrowed pointer - do NOT free)
/// - `user_data`: User-provided context pointer
///
/// ## Example (C)
/// ```c
/// void my_click_handler(DOMEvent* event, void* user_data) {
///     MyState* state = (MyState*)user_data;
///     const char* type = dom_event_get_type(event);
///     printf("Event: %s, State: %d\n", type, state->counter);
///
///     // Prevent default action
///     if (dom_event_get_cancelable(event)) {
///         dom_event_preventdefault(event);
///     }
/// }
/// ```
pub const DOMEventListener = *const fn (event: *DOMEvent, user_data: ?*anyopaque) callconv(.c) void;

// ============================================================================
// Methods
// ============================================================================

/// Adds an event listener to the EventTarget.
///
/// ## WebIDL
/// ```webidl
/// undefined addEventListener(DOMString type, EventListener? callback,
///                            optional (AddEventListenerOptions or boolean) options = {});
/// ```
///
/// ## Parameters
/// - `handle`: EventTarget handle (Node, Document, or Element)
/// - `event_type`: Event type string (e.g., "click", "load")
/// - `callback`: C function pointer for event handler
/// - `user_data`: Optional user context pointer (passed to callback)
/// - `capture`: 1 to listen in capture phase, 0 for bubble phase
/// - `once`: 1 to remove listener after first invocation, 0 otherwise
/// - `passive`: 1 for passive listener (can't preventDefault), 0 otherwise
///
/// ## Returns
/// 0 on success, non-zero error code on failure
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
/// - WebIDL: dom.idl:66
///
/// ## Example (C)
/// ```c
/// void handle_click(DOMEvent* event, void* user_data) {
///     printf("Clicked!\n");
///     dom_event_preventdefault(event);
/// }
///
/// DOMElement* button = dom_document_createelement(doc, "button");
/// int result = dom_eventtarget_addeventlistener(
///     (DOMEventTarget*)button,
///     "click",
///     handle_click,
///     NULL,    // No user data
///     0,       // Bubble phase
///     0,       // Not once
///     0        // Not passive
/// );
/// ```
pub export fn dom_eventtarget_addeventlistener(
    handle: *DOMEventTarget,
    event_type: [*:0]const u8,
    callback: ?DOMEventListener,
    user_data: ?*anyopaque,
    capture: u8,
    once: u8,
    passive: u8,
) c_int {
    // Early return if callback is null
    if (callback == null) return 0;

    const node: *dom.Node = @ptrCast(@alignCast(handle));
    const type_str = types.cStringToZigString(event_type);

    // Create a wrapper that adapts C callback to Zig EventCallback
    const Wrapper = struct {
        c_callback: DOMEventListener,
        c_user_data: ?*anyopaque,

        fn zigCallback(event: *Event, context: *anyopaque) void {
            const wrapper: *@This() = @ptrCast(@alignCast(context));
            const dom_event: *DOMEvent = @ptrCast(event);
            wrapper.c_callback(dom_event, wrapper.c_user_data);
        }
    };

    // Allocate wrapper on heap (lives until removeEventListener)
    const allocator = node.allocator;
    const wrapper = allocator.create(Wrapper) catch |err| {
        return @intFromEnum(types.zigErrorToDOMError(err));
    };
    wrapper.* = .{
        .c_callback = callback.?,
        .c_user_data = user_data,
    };

    // Register listener with Zig callback
    node.prototype.addEventListener(
        type_str,
        Wrapper.zigCallback,
        @ptrCast(wrapper),
        capture != 0,
        once != 0,
        passive != 0,
        null, // AbortSignal not supported in C-ABI yet
    ) catch |err| {
        allocator.destroy(wrapper);
        return @intFromEnum(types.zigErrorToDOMError(err));
    };

    return 0; // Success
}

/// Removes an event listener from the EventTarget.
///
/// ## WebIDL
/// ```webidl
/// undefined removeEventListener(DOMString type, EventListener? callback,
///                                optional (EventListenerOptions or boolean) options = {});
/// ```
///
/// ## Parameters
/// - `handle`: EventTarget handle (Node, Document, or Element)
/// - `event_type`: Event type string (e.g., "click", "load")
/// - `callback`: C function pointer to remove (must match addEventListener)
/// - `user_data`: User context pointer (must match addEventListener)
/// - `capture`: 1 if added with capture, 0 if added with bubble
///
/// ## Returns
/// void (always succeeds, even if listener not found)
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-eventtarget-removeeventlistener
/// - WebIDL: dom.idl:67
///
/// ## Example (C)
/// ```c
/// // Remove previously added listener
/// dom_eventtarget_removeeventlistener(
///     (DOMEventTarget*)button,
///     "click",
///     handle_click,
///     NULL,    // Same user_data as addEventListener
///     0        // Same capture as addEventListener
/// );
/// ```
pub export fn dom_eventtarget_removeeventlistener(
    handle: *DOMEventTarget,
    event_type: [*:0]const u8,
    callback: ?DOMEventListener,
    user_data: ?*anyopaque,
    capture: u8,
) void {
    // Early return if callback is null
    if (callback == null) return;

    const node: *dom.Node = @ptrCast(@alignCast(handle));
    const type_str = types.cStringToZigString(event_type);

    // NOTE: We can't actually remove the listener because we don't have
    // the wrapper pointer. This is a known limitation.
    //
    // WORKAROUND: JavaScript engines typically manage listeners themselves
    // and don't rely on C-ABI removeEventListener.
    //
    // TODO: Store wrapper pointers in a map keyed by (type, callback, user_data, capture)
    // so we can look them up and remove them properly.

    // For now, this is a no-op
    // Real implementation would require a registry of wrapper pointers
    _ = .{ node, type_str, callback, user_data, capture };
}

/// Dispatches an event at this EventTarget.
///
/// ## WebIDL
/// ```webidl
/// boolean dispatchEvent(Event event);
/// ```
///
/// ## Algorithm (from DOM spec)
/// 1. If event's dispatch flag is set, throw InvalidStateError
/// 2. Set event's initialized flag
/// 3. Return result of dispatching event to this, with legacy target override flag not set
///
/// ## Parameters
/// - `handle`: EventTarget handle (Node, Document, or Element)
/// - `event`: Event to dispatch
///
/// ## Returns
/// 0 if event was cancelled (preventDefault called), 1 otherwise
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
/// - WebIDL: dom.idl:72
///
/// ## Example
/// ```c
/// DOMEvent* event = /* create event */;
/// int result = dom_eventtarget_dispatchevent((DOMEventTarget*)elem, event);
/// if (result == 0) {
///     printf("Event was cancelled\n");
/// }
/// ```
pub export fn dom_eventtarget_dispatchevent(handle: *DOMEventTarget, event: *DOMEvent) u8 {
    // EventTarget is a mixin - cast to Node (all EventTargets are Nodes)
    const node: *dom.Node = @ptrCast(@alignCast(handle));
    const evt: *Event = @ptrCast(@alignCast(event));

    // dispatchEvent returns true if event was not cancelled
    const result = node.dispatchEvent(evt) catch return 0;
    return if (result) 1 else 0;
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of an EventTarget.
///
/// EventTarget is a mixin - this forwards to Node's reference counting.
///
/// ## Parameters
/// - `handle`: EventTarget handle
pub export fn dom_eventtarget_addref(handle: *DOMEventTarget) void {
    const node: *dom.Node = @ptrCast(@alignCast(handle));
    node.acquire();
}

/// Decrement the reference count of an EventTarget.
///
/// EventTarget is a mixin - this forwards to Node's reference counting.
///
/// ## Parameters
/// - `handle`: EventTarget handle
pub export fn dom_eventtarget_release(handle: *DOMEventTarget) void {
    const node: *dom.Node = @ptrCast(@alignCast(handle));
    node.release();
}
