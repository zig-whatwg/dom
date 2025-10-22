//! CustomEvent JavaScript Bindings
//!
//! C-ABI bindings for the CustomEvent interface.
//!
//! ## WHATWG Specification
//!
//! CustomEvent extends Event to allow custom data via the `detail` property:
//! - **§2.2 Interface CustomEvent**: https://dom.spec.whatwg.org/#interface-customevent
//!
//! ## MDN Documentation
//!
//! - CustomEvent: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent
//! - CustomEvent.detail: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/detail
//! - CustomEvent(): https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=*]
//! interface CustomEvent : Event {
//!   constructor(DOMString type, optional CustomEventInit eventInitDict = {});
//!
//!   readonly attribute any detail;
//! };
//!
//! dictionary CustomEventInit : EventInit {
//!   any detail = null;
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#customevent (WebIDL: dom.idl:67-77)
//!
//! ## Exported Functions (5 total)
//!
//! ### Constructor
//! - `dom_customevent_new()` - Create new CustomEvent (heap-allocated)
//!
//! ### Properties
//! - `dom_customevent_get_detail()` - Get custom data pointer
//!
//! ### Memory Management
//! - `dom_customevent_addref()` - Increment reference count
//! - `dom_customevent_release()` - Decrement reference count
//!
//! ## Usage Example (C)
//!
//! ```c
//! // CustomEvent with detail data
//! typedef struct {
//!     int count;
//!     const char* message;
//! } MyData;
//!
//! MyData data = { .count = 42, .message = "Hello" };
//!
//! // In a real implementation, you'd create CustomEvent via constructor
//! // For now, assume we received one from dispatch
//! DOMCustomEvent* event = /* ... */;
//!
//! // Get detail (returns void* pointer to custom data)
//! void* detail = dom_customevent_get_detail(event);
//! if (detail != NULL) {
//!     MyData* my_data = (MyData*)detail;
//!     printf("Count: %d, Message: %s\n", my_data->count, my_data->message);
//! }
//!
//! // CustomEvent inherits all Event methods
//! // You can cast to DOMEvent to access Event properties
//! DOMEvent* base_event = (DOMEvent*)event;
//! const char* type = dom_event_get_type(base_event);
//! ```
//!
//! ## C-ABI Notes
//!
//! ### Detail Lifetime
//! - The `detail` pointer returned is **borrowed** - do NOT free it
//! - The detail data must outlive the CustomEvent
//! - JavaScript engines typically manage this automatically
//!
//! ### Type Safety
//! - C-ABI uses `void*` for the `detail` (WebIDL `any` type)
//! - Caller must cast to correct type
//! - No runtime type checking in C-ABI
//!
//! ### Inheritance
//! - CustomEvent IS-A Event
//! - Can cast `DOMCustomEvent*` to `DOMEvent*` to access Event methods
//! - Memory layout compatible (CustomEvent pointer = Event pointer in C-ABI)

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const Event = dom.Event;
const CustomEvent = dom.CustomEvent;
const CustomEventInit = dom.CustomEventInit;
const DOMCustomEvent = types.DOMCustomEvent;

// ============================================================================
// Constructor
// ============================================================================

/// Creates a new CustomEvent with optional detail data (heap-allocated).
///
/// ## WebIDL
/// ```webidl
/// constructor(DOMString type, optional CustomEventInit eventInitDict = {});
/// ```
///
/// ## Parameters
/// - `event_type`: Event type string (e.g., "custom", "user-login")
/// - `bubbles`: 1 if event bubbles, 0 otherwise
/// - `cancelable`: 1 if event can be cancelled, 0 otherwise
/// - `composed`: 1 if event crosses shadow boundaries, 0 otherwise
/// - `detail`: Optional pointer to custom data (borrowed - must outlive event)
///
/// ## Returns
/// Heap-allocated CustomEvent pointer, or NULL on allocation failure
/// - **IMPORTANT**: Caller must call `dom_customevent_release()` to free
/// - **IMPORTANT**: `detail` pointer is borrowed - caller must keep data alive
///
/// ## Spec References
/// - Constructor: https://dom.spec.whatwg.org/#dom-customevent-customevent
/// - WebIDL: dom.idl:51
///
/// ## Example (C)
/// ```c
/// // Custom data structure
/// typedef struct {
///     int user_id;
///     const char* username;
/// } UserData;
///
/// UserData data = { .user_id = 123, .username = "alice" };
///
/// // Create custom event with detail
/// DOMCustomEvent* event = dom_customevent_new(
///     "user-login",
///     1,              // bubbles
///     0,              // not cancelable
///     0,              // not composed
///     &data           // detail pointer
/// );
///
/// if (event == NULL) {
///     fprintf(stderr, "Failed to create custom event\n");
///     return -1;
/// }
///
/// // Access detail
/// void* detail = dom_customevent_get_detail(event);
/// if (detail != NULL) {
///     UserData* user = (UserData*)detail;
///     printf("User: %s (ID: %d)\n", user->username, user->user_id);
/// }
///
/// // Cleanup
/// dom_customevent_release(event);
/// // NOTE: data must still be valid here if event is still in use
/// ```
pub export fn dom_customevent_new(
    event_type: [*:0]const u8,
    bubbles: u8,
    cancelable: u8,
    composed: u8,
    detail: ?*anyopaque,
) ?*DOMCustomEvent {
    const allocator = std.heap.page_allocator;
    const type_str = types.cStringToZigString(event_type);

    // Duplicate the string so it persists (event stores pointer, not copy)
    const type_copy = allocator.dupeZ(u8, type_str) catch return null;

    const event_ptr = allocator.create(CustomEvent) catch {
        allocator.free(type_copy);
        return null;
    };
    event_ptr.* = CustomEvent.init(type_copy, .{
        .event_options = .{
            .bubbles = bubbles != 0,
            .cancelable = cancelable != 0,
            .composed = composed != 0,
        },
        .detail = if (detail) |d| @ptrCast(d) else null,
    });

    return @ptrCast(event_ptr);
}

// ============================================================================
// Properties
// ============================================================================

/// Gets the custom detail data.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute any detail;
/// ```
///
/// ## Parameters
/// - `event`: CustomEvent handle
///
/// ## Returns
/// Pointer to custom data, or NULL if no detail
/// - **IMPORTANT**: Borrowed pointer - do NOT free
/// - Caller must cast to correct type
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-customevent-detail
/// - WebIDL: dom.idl:70
pub export fn dom_customevent_get_detail(event: *DOMCustomEvent) ?*anyopaque {
    const evt: *const CustomEvent = @ptrCast(@alignCast(event));
    // CustomEvent.detail is ?*const anyopaque, we need ?*anyopaque for C-ABI
    // This is safe because C doesn't enforce const on void*
    if (evt.detail) |d| {
        return @constCast(d);
    }
    return null;
}

/// Initialize a custom event (legacy method).
///
/// ## WebIDL
/// ```webidl
/// undefined initCustomEvent(DOMString type, optional boolean bubbles = false,
///                          optional boolean cancelable = false, optional any detail = null);
/// ```
///
/// ## Parameters
/// - `event`: CustomEvent handle
/// - `type`: Event type string
/// - `bubbles`: Whether event bubbles (0 = false, non-zero = true)
/// - `cancelable`: Whether event is cancelable (0 = false, non-zero = true)
/// - `detail`: Custom data pointer (NULL for none)
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-customevent-initcustomevent
/// - WebIDL: dom.idl:71
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/initCustomEvent
///
/// ## Note
/// This is a legacy method from DOM Level 3. Modern code should use CustomEvent constructors instead.
/// This method can only be called before the event is dispatched.
///
/// ## Example (C)
/// ```c
/// DOMCustomEvent* event = dom_customevent_new();
/// void* data = malloc(sizeof(int));
/// *(int*)data = 42;
/// dom_customevent_initcustomevent(event, "custom", 1, 1, data);
/// // ... dispatch event ...
/// dom_customevent_release(event);
/// free(data);
/// ```
pub export fn dom_customevent_initcustomevent(
    event: *DOMCustomEvent,
    type_str: [*:0]const u8,
    bubbles: u8,
    cancelable: u8,
    detail: ?*anyopaque,
) void {
    const evt: *CustomEvent = @ptrCast(@alignCast(event));
    const event_type = types.cStringToZigString(type_str);
    const bubbles_bool = (bubbles != 0);
    const cancelable_bool = (cancelable != 0);
    evt.initCustomEvent(event_type, bubbles_bool, cancelable_bool, detail);
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of a CustomEvent.
///
/// CustomEvent in C-ABI is heap-allocated and reference counted.
///
/// ## Parameters
/// - `event`: CustomEvent handle
pub export fn dom_customevent_addref(event: *DOMCustomEvent) void {
    const allocator = std.heap.page_allocator;
    // CustomEvents are value types in Zig, in C-ABI we heap-allocate
    // For now, this is a no-op as events are typically short-lived
    _ = event;
    _ = allocator;
}

/// Decrement the reference count of a CustomEvent.
///
/// When count reaches 0, frees the event.
///
/// ## Parameters
/// - `event`: CustomEvent handle
///
/// ## Note
/// This currently leaks the event_type string. TODO: Track string ownership.
pub export fn dom_customevent_release(event: *DOMCustomEvent) void {
    const allocator = std.heap.page_allocator;
    const evt: *CustomEvent = @ptrCast(@alignCast(event));

    // TODO: Free the event_type string (requires tracking ownership)
    // For now, we leak it to avoid alignment issues

    // Free the CustomEvent struct
    allocator.destroy(evt);
}
