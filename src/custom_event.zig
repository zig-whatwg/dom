//! CustomEvent Interface (§2.2)
//!
//! This module implements the CustomEvent interface as specified by the WHATWG DOM Standard.
//! CustomEvent extends Event to allow applications to attach custom data to events via the
//! `detail` property. This is the primary mechanism for passing application-specific data
//! through the event system.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§2.2 Interface CustomEvent**: https://dom.spec.whatwg.org/#interface-customevent
//! - **§2.2 Interface Event**: https://dom.spec.whatwg.org/#interface-event (base)
//!
//! ## MDN Documentation
//!
//! - CustomEvent: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent
//! - CustomEvent.detail: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/detail
//! - CustomEvent(): https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
//!
//! ## Core Features
//!
//! ### Custom Data Attachment
//! CustomEvent allows passing any data type through events:
//! ```zig
//! const MyData = struct { count: u32, message: []const u8 };
//! var data = MyData{ .count = 42, .message = "hello" };
//!
//! const event = CustomEvent.init("my-event", .{
//!     .event_options = .{ .bubbles = true, .cancelable = false, .composed = false },
//!     .detail = &data,
//! });
//!
//! // Later, in event handler:
//! if (event.getDetail(MyData)) |d| {
//!     std.debug.print("Count: {}, Message: {s}\n", .{d.count, d.message});
//! }
//! ```
//!
//! ### Type Safety with anyopaque
//! The `detail` field uses `?*const anyopaque` to represent WebIDL's `any` type:
//! - Can hold pointer to ANY Zig type
//! - Type-safe access via `getDetail(T)`
//! - Caller manages lifetime of detail data
//! - Zero runtime overhead (just a pointer)
//!
//! ### Lifetime Management
//! **CRITICAL**: The caller must ensure the detail data outlives the event:
//! ```zig
//! // ✅ CORRECT: Data outlives event
//! var data = MyData{ .count = 42, .message = "hello" };
//! const event = CustomEvent.init("my-event", .{ .detail = &data });
//! // Use event...
//! // data is still valid
//!
//! // ❌ WRONG: Data freed before event used
//! const event = blk: {
//!     var data = MyData{ .count = 42, .message = "hello" };
//!     break :blk CustomEvent.init("my-event", .{ .detail = &data });
//! }; // data is now invalid!
//! ```
//!
//! ## Memory Management
//!
//! CustomEvent itself is a plain struct (like Event):
//! ```zig
//! const event = CustomEvent.init("custom", .{ .detail = &my_data });
//! // No defer needed - CustomEvent is a plain struct
//! // BUT: my_data must remain valid as long as event is used
//! ```
//!
//! ## Usage Examples
//!
//! ### Basic Custom Event
//! ```zig
//! const std = @import("std");
//! const CustomEvent = @import("custom_event.zig").CustomEvent;
//!
//! const UserData = struct {
//!     user_id: u32,
//!     username: []const u8,
//! };
//!
//! var user = UserData{ .user_id = 123, .username = "alice" };
//!
//! const event = CustomEvent.init("user-login", .{
//!     .event_options = .{ .bubbles = true, .cancelable = false, .composed = false },
//!     .detail = &user,
//! });
//!
//! // Access detail with type safety
//! if (event.getDetail(UserData)) |u| {
//!     std.debug.print("User {s} logged in\n", .{u.username});
//! }
//! ```
//!
//! ### Null Detail (Event without data)
//! ```zig
//! const event = CustomEvent.init("notification", .{
//!     .event_options = .{ .bubbles = true, .cancelable = false, .composed = false },
//!     .detail = null, // No custom data
//! });
//! ```
//!
//! ### Complex Data Structures
//! ```zig
//! const FormData = struct {
//!     fields: std.StringHashMap([]const u8),
//!     is_valid: bool,
//!     errors: []const []const u8,
//! };
//!
//! var form_data = FormData{
//!     .fields = std.StringHashMap([]const u8).init(allocator),
//!     .is_valid = true,
//!     .errors = &[_][]const u8{},
//! };
//! defer form_data.fields.deinit();
//!
//! const event = CustomEvent.init("form-submit", .{
//!     .event_options = .{ .bubbles = true, .cancelable = true, .composed = false },
//!     .detail = &form_data,
//! });
//! ```

const std = @import("std");
const Event = @import("event.zig").Event;

/// CustomEvent extends Event with a detail property for custom data.
///
/// Implements WHATWG DOM CustomEvent interface per §2.2.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=*]
/// interface CustomEvent : Event {
///   constructor(DOMString type, optional CustomEventInit eventInitDict = {});
///
///   readonly attribute any detail;
///
///   undefined initCustomEvent(DOMString type, optional boolean bubbles = false,
///                             optional boolean cancelable = false, optional any detail = null);
/// };
///
/// dictionary CustomEventInit : EventInit {
///   any detail = null;
/// };
/// ```
///
/// ## Spec References
/// - Interface: https://dom.spec.whatwg.org/#interface-customevent
/// - WebIDL: dom.idl:50-60
pub const CustomEvent = struct {
    /// Base Event (CustomEvent extends Event)
    event: Event,

    /// Custom data attached to this event.
    ///
    /// Uses `?*const anyopaque` to represent WebIDL's `any` type.
    /// This allows passing any Zig type through events while maintaining type safety.
    ///
    /// ## Lifetime
    /// The pointed-to data MUST outlive the CustomEvent. The caller is responsible
    /// for ensuring the detail remains valid for the event's lifetime.
    ///
    /// ## Access
    /// Use `getDetail(T)` for type-safe access to the detail data.
    detail: ?*const anyopaque = null,

    /// Creates a new CustomEvent with the given type, options, and detail.
    ///
    /// Implements WHATWG DOM CustomEvent() constructor per §2.2.
    ///
    /// ## WebIDL
    /// ```webidl
    /// constructor(DOMString type, optional CustomEventInit eventInitDict = {});
    /// ```
    ///
    /// ## Parameters
    /// - `event_type`: The event type string (e.g., "user-login")
    /// - `options`: Optional initialization options including detail
    ///
    /// ## Returns
    /// New CustomEvent object
    ///
    /// ## Example
    /// ```zig
    /// const MyData = struct { value: u32 };
    /// var data = MyData{ .value = 42 };
    ///
    /// const event = CustomEvent.init("my-event", .{
    ///     .event_options = .{ .bubbles = true, .cancelable = false, .composed = false },
    ///     .detail = &data,
    /// });
    /// ```
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-customevent-customevent
    /// - WebIDL: dom.idl:51
    pub fn init(event_type: []const u8, options: CustomEventInit) CustomEvent {
        return .{
            .event = Event.init(event_type, options.event_options),
            .detail = options.detail,
        };
    }

    /// Returns the detail with type-safe casting.
    ///
    /// This method provides type-safe access to the detail property.
    /// The caller specifies the expected type, and the method performs the cast.
    ///
    /// ## Parameters
    /// - `T`: The expected type of the detail data
    ///
    /// ## Returns
    /// Pointer to the detail data cast to type `T`, or null if detail is null
    ///
    /// ## Safety
    /// The caller MUST ensure `T` matches the actual type of the detail data.
    /// Casting to the wrong type results in undefined behavior.
    ///
    /// ## Example
    /// ```zig
    /// const UserData = struct { id: u32, name: []const u8 };
    /// // ... create event with UserData detail ...
    ///
    /// if (event.getDetail(UserData)) |user| {
    ///     std.debug.print("User: {s}\n", .{user.name});
    /// }
    /// ```
    pub fn getDetail(self: *const CustomEvent, comptime T: type) ?*const T {
        if (self.detail) |d| {
            return @ptrCast(@alignCast(d));
        }
        return null;
    }

    /// Legacy initialization method (deprecated).
    ///
    /// Implements WHATWG DOM CustomEvent.initCustomEvent() per §2.3 (legacy).
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined initCustomEvent(DOMString type, optional boolean bubbles = false,
    ///                          optional boolean cancelable = false, optional any detail = null);
    /// ```
    ///
    /// ## Note
    /// This is a legacy API. New code should use the constructor instead.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-customevent-initcustomevent
    /// - WebIDL: dom.idl:55
    pub fn initCustomEvent(
        self: *CustomEvent,
        event_type: []const u8,
        bubbles: bool,
        cancelable: bool,
        detail: ?*const anyopaque,
    ) void {
        // Per spec: If this's dispatch flag is set, then return
        if (self.event.dispatch_flag) return;

        // Initialize the event
        self.event.event_type = event_type;
        self.event.bubbles = bubbles;
        self.event.cancelable = cancelable;
        self.event.initialized_flag = true;

        // Set detail
        self.detail = detail;
    }
};

/// Initialization options for CustomEvent.
///
/// Extends EventInit with a detail property.
///
/// ## WebIDL
/// ```webidl
/// dictionary CustomEventInit : EventInit {
///   any detail = null;
/// };
/// ```
///
/// ## Spec References
/// - WebIDL: dom.idl:58-60
pub const CustomEventInit = struct {
    /// Base event options (bubbles, cancelable, composed)
    event_options: Event.EventInit = .{},

    /// Custom data to attach to the event.
    ///
    /// Can be a pointer to any Zig type. The pointed-to data must outlive
    /// the CustomEvent. Defaults to null (no custom data).
    detail: ?*const anyopaque = null,
};
