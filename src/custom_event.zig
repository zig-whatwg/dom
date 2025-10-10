//! CustomEvent Interface - WHATWG DOM Standard §2.4
//! ==================================================
//!
//! CustomEvent extends Event to allow applications to carry custom data.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-customevent
//! - **Section**: §2.4 Interface CustomEvent
//!
//! ## MDN Documentation
//! - **CustomEvent**: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent
//! - **CustomEvent()**: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
//! - **detail**: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/detail
//!
//! ## Overview
//!
//! CustomEvent allows you to attach arbitrary data to events, making it useful for
//! application-specific communication patterns. The `detail` property can hold any
//! data structure you need to pass along with the event.
//!
//! ## Usage Examples
//!
//! ### Basic Custom Event
//! ```zig
//! const event = try CustomEvent.init(allocator, "user-login");
//! defer event.release();
//!
//! // Event carries no additional data
//! try std.testing.expectEqualStrings("user-login", event.event.type_name);
//! ```
//!
//! ### Custom Event with Detail Data
//! ```zig
//! const UserData = struct {
//!     id: u32,
//!     name: []const u8,
//! };
//!
//! const user = UserData{ .id = 123, .name = "Alice" };
//! const data_ptr: *const anyopaque = &user;
//!
//! const event = try CustomEvent.initWithDetail(allocator, "user-login", data_ptr);
//! defer event.release();
//!
//! // Retrieve the data
//! if (event.getDetail(UserData)) |user_data| {
//!     // user_data.id == 123
//!     // user_data.name == "Alice"
//! }
//! ```
//!
//! ### Bubbling Custom Event
//! ```zig
//! const event = try CustomEvent.create(allocator, "custom", .{
//!     .bubbles = true,
//!     .cancelable = true,
//!     .detail = data_ptr,
//! });
//! defer event.release();
//! ```
//!
//! ### With Event Dispatch
//! ```zig
//! const target = try EventTarget.init(allocator);
//! defer target.release();
//!
//! // Add listener
//! var listener = EventListener.init(myCallback);
//! try target.addEventListener("custom", &listener);
//!
//! // Dispatch custom event
//! const event = try CustomEvent.initWithDetail(allocator, "custom", data_ptr);
//! defer event.release();
//! _ = try target.dispatchEvent(&event.event);
//! ```
//!
//! ## Key Features
//!
//! - **Custom Data**: Attach any data via the `detail` property
//! - **Type Safety**: Use `getDetail(T)` for type-safe data retrieval
//! - **Event Options**: Supports all Event options (bubbles, cancelable, composed)
//! - **Standard Compliant**: Follows WHATWG DOM specification

const std = @import("std");
const Event = @import("event.zig").Event;

/// CustomEvent
///
/// Represents a custom event with associated detail data.
/// Extends the Event interface to carry application-specific information.
///
/// ## Fields
///
/// - `event`: The underlying Event object
/// - `detail`: Opaque pointer to custom data (can be any type)
///
/// ## Memory Management
///
/// The CustomEvent does NOT take ownership of the detail data.
/// The caller is responsible for managing the lifetime of detail data.
/// The detail pointer must remain valid for the lifetime of the event.
///
/// ## Example
///
/// ```zig
/// const data = MyStruct{ .value = 42 };
/// const event = try CustomEvent.initWithDetail(allocator, "test", &data);
/// defer event.release();
///
/// if (event.getDetail(MyStruct)) |my_data| {
///     // Use my_data
/// }
/// ```
pub const CustomEvent = struct {
    event: *Event,
    detail: ?*const anyopaque,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize CustomEvent with type only
    ///
    /// Creates a new CustomEvent with the given type and no detail data.
    /// The event is not bubbling, not cancelable, and not composed.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the event
    /// - `event_type`: The type of the event (e.g., "custom", "user-action")
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created CustomEvent.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const event = try CustomEvent.init(allocator, "my-event");
    /// defer event.release();
    ///
    /// try std.testing.expectEqualStrings("my-event", event.event.type_name);
    /// try std.testing.expect(event.detail == null);
    /// ```
    pub fn init(allocator: std.mem.Allocator, event_type: []const u8) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        const event = try Event.init(allocator, event_type, .{});
        errdefer event.deinit();

        self.* = .{
            .event = event,
            .detail = null,
            .allocator = allocator,
        };

        return self;
    }

    /// Initialize CustomEvent with detail data
    ///
    /// Creates a new CustomEvent with the given type and detail data.
    /// The event is not bubbling, not cancelable, and not composed by default.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the event
    /// - `event_type`: The type of the event
    /// - `detail`: Pointer to custom data (any type)
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created CustomEvent.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Memory Management
    ///
    /// The CustomEvent does NOT take ownership of detail.
    /// The caller must ensure detail remains valid for the event's lifetime.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const data = MyData{ .value = 123 };
    /// const event = try CustomEvent.initWithDetail(allocator, "data-event", &data);
    /// defer event.release();
    ///
    /// if (event.getDetail(MyData)) |retrieved| {
    ///     try std.testing.expectEqual(@as(i32, 123), retrieved.value);
    /// }
    /// ```
    pub fn initWithDetail(allocator: std.mem.Allocator, event_type: []const u8, detail: ?*const anyopaque) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        const event = try Event.init(allocator, event_type, .{});
        errdefer event.deinit();

        self.* = .{
            .event = event,
            .detail = detail,
            .allocator = allocator,
        };

        return self;
    }

    /// Create CustomEvent with options
    ///
    /// Creates a new CustomEvent with full control over event properties.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the event
    /// - `event_type`: The type of the event
    /// - `options`: CustomEventOptions with detail and Event properties
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created CustomEvent.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const data = UserInfo{ .id = 42, .name = "Alice" };
    /// const event = try CustomEvent.create(allocator, "user-login", .{
    ///     .bubbles = true,
    ///     .cancelable = true,
    ///     .detail = &data,
    /// });
    /// defer event.release();
    ///
    /// try std.testing.expect(event.event.bubbles);
    /// try std.testing.expect(event.event.cancelable);
    /// ```
    pub fn create(allocator: std.mem.Allocator, event_type: []const u8, options: CustomEventOptions) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        const event = try Event.init(allocator, event_type, .{
            .bubbles = options.bubbles,
            .cancelable = options.cancelable,
            .composed = options.composed,
        });
        errdefer event.deinit();

        self.* = .{
            .event = event,
            .detail = options.detail,
            .allocator = allocator,
        };

        return self;
    }

    /// Release CustomEvent
    ///
    /// Frees all resources associated with this CustomEvent.
    /// After calling this method, the CustomEvent pointer is invalid.
    ///
    /// ## Memory Management
    ///
    /// This method does NOT free the detail data. The caller is responsible
    /// for managing detail's lifetime.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const event = try CustomEvent.init(allocator, "test");
    /// defer event.release();
    /// // Event automatically released on scope exit
    /// ```
    pub fn release(self: *Self) void {
        self.event.deinit();
        self.allocator.destroy(self);
    }

    /// Get detail with type safety
    ///
    /// Retrieves the detail data cast to the specified type.
    /// Returns null if detail is null.
    ///
    /// ## Type Parameters
    ///
    /// - `T`: The expected type of the detail data
    ///
    /// ## Returns
    ///
    /// - Pointer to the detail data cast to `*const T`, or null if no detail
    ///
    /// ## Safety
    ///
    /// The caller must ensure that `T` matches the actual type of the detail data.
    /// Casting to the wrong type results in undefined behavior.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const UserData = struct { id: u32 };
    /// const user = UserData{ .id = 123 };
    ///
    /// const event = try CustomEvent.initWithDetail(allocator, "test", &user);
    /// defer event.release();
    ///
    /// if (event.getDetail(UserData)) |data| {
    ///     try std.testing.expectEqual(@as(u32, 123), data.id);
    /// }
    /// ```
    pub fn getDetail(self: *const Self, comptime T: type) ?*const T {
        if (self.detail) |ptr| {
            return @ptrCast(@alignCast(ptr));
        }
        return null;
    }

    /// Get the Event base object
    ///
    /// Returns a pointer to the underlying Event object for use with
    /// EventTarget.dispatchEvent() and other Event-based APIs.
    ///
    /// ## Returns
    ///
    /// Pointer to the underlying Event object.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const custom_event = try CustomEvent.init(allocator, "test");
    /// defer custom_event.release();
    ///
    /// const event_ptr = custom_event.getEvent();
    /// _ = try target.dispatchEvent(event_ptr);
    /// ```
    pub fn getEvent(self: *Self) *Event {
        return self.event;
    }

    // ========================================================================
    // Legacy API - WHATWG DOM Standard §2.4
    // ========================================================================

    /// Initialize CustomEvent (legacy method).
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-customevent-initcustomevent
    ///
    /// ## WHATWG Specification (§2.4)
    /// > The initCustomEvent(type, bubbles, cancelable, detail) method must run these steps:
    /// > 1. If this's dispatch flag is set, then return
    /// > 2. Initialize this with type, bubbles, and cancelable
    /// > 3. Set this's detail attribute to detail
    ///
    /// ## Note
    /// This is a legacy API. Modern code should use the CustomEvent constructor instead.
    /// This method is redundant with event constructors and is kept for backwards compatibility.
    ///
    /// ## Parameters
    ///
    /// - `event_type`: The type of the event
    /// - `bubbles`: Whether the event bubbles up through the DOM tree
    /// - `cancelable`: Whether the event can be canceled
    /// - `detail`: Custom data to attach to the event
    ///
    /// ## Examples
    ///
    /// ### Legacy Initialization
    /// ```zig
    /// const event = try CustomEvent.init(allocator, "");
    /// defer event.release();
    ///
    /// const data: i32 = 42;
    /// event.initCustomEvent("my-event", true, false, &data);
    ///
    /// try std.testing.expectEqualStrings("my-event", event.event.type_name);
    /// try std.testing.expect(event.event.bubbles);
    /// try std.testing.expect(!event.event.cancelable);
    /// ```
    ///
    /// ### Modern Alternative (Preferred)
    /// ```zig
    /// // Instead of initCustomEvent, use:
    /// const data: i32 = 42;
    /// const event = try CustomEvent.create(allocator, "my-event", .{
    ///     .bubbles = true,
    ///     .cancelable = false,
    ///     .detail = &data,
    /// });
    /// defer event.release();
    /// ```
    ///
    /// ## Behavior
    ///
    /// - If the event is currently being dispatched (event_phase != none), this method does nothing
    /// - Reinitializes the event's type, bubbles, and cancelable properties
    /// - Updates the detail property
    pub fn initCustomEvent(self: *Self, event_type: []const u8, bubbles: bool, cancelable: bool, detail: ?*const anyopaque) !void {
        // If the event is currently being dispatched, do nothing
        if (self.event.event_phase != .none) {
            return;
        }

        // Initialize the underlying event
        try self.event.initEvent(event_type, bubbles, cancelable);

        // Set the detail
        self.detail = detail;
    }
};

/// CustomEvent creation options
///
/// Options for creating a CustomEvent with specific properties.
pub const CustomEventOptions = struct {
    /// Whether the event bubbles up through the DOM tree
    bubbles: bool = false,

    /// Whether the event can be canceled with preventDefault()
    cancelable: bool = false,

    /// Whether the event crosses shadow DOM boundaries
    composed: bool = false,

    /// Custom data to attach to the event
    detail: ?*const anyopaque = null,
};

// ============================================================================
// Tests
// ============================================================================

test "CustomEvent creation without detail" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.init(allocator, "test-event");
    defer event.release();

    try std.testing.expectEqualStrings("test-event", event.event.type_name);
    try std.testing.expect(event.detail == null);
    try std.testing.expect(!event.event.bubbles);
    try std.testing.expect(!event.event.cancelable);
}

test "CustomEvent creation with detail" {
    const allocator = std.testing.allocator;

    const TestData = struct {
        value: i32,
        name: []const u8,
    };

    const data = TestData{ .value = 42, .name = "test" };
    const event = try CustomEvent.initWithDetail(allocator, "data-event", &data);
    defer event.release();

    try std.testing.expectEqualStrings("data-event", event.event.type_name);
    try std.testing.expect(event.detail != null);
}

test "CustomEvent getDetail" {
    const allocator = std.testing.allocator;

    const UserInfo = struct {
        id: u32,
        username: []const u8,
    };

    const user = UserInfo{ .id = 123, .username = "alice" };
    const event = try CustomEvent.initWithDetail(allocator, "user-event", &user);
    defer event.release();

    if (event.getDetail(UserInfo)) |retrieved| {
        try std.testing.expectEqual(@as(u32, 123), retrieved.id);
        try std.testing.expectEqualStrings("alice", retrieved.username);
    } else {
        try std.testing.expect(false); // Should have detail
    }
}

test "CustomEvent getDetail returns null when no detail" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.init(allocator, "test");
    defer event.release();

    const TestData = struct { value: i32 };
    const result = event.getDetail(TestData);
    try std.testing.expect(result == null);
}

test "CustomEvent create with options" {
    const allocator = std.testing.allocator;

    const data: i32 = 999;
    const event = try CustomEvent.create(allocator, "custom", .{
        .bubbles = true,
        .cancelable = true,
        .composed = false,
        .detail = &data,
    });
    defer event.release();

    try std.testing.expectEqualStrings("custom", event.event.type_name);
    try std.testing.expect(event.event.bubbles);
    try std.testing.expect(event.event.cancelable);
    try std.testing.expect(!event.event.composed);

    if (event.getDetail(i32)) |value| {
        try std.testing.expectEqual(@as(i32, 999), value.*);
    }
}

test "CustomEvent getEvent returns Event pointer" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.init(allocator, "test");
    defer event.release();

    const event_ptr = event.getEvent();
    try std.testing.expectEqualStrings("test", event_ptr.type_name);
}

test "CustomEvent with null detail pointer" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.initWithDetail(allocator, "test", null);
    defer event.release();

    try std.testing.expect(event.detail == null);
}

test "CustomEvent with struct detail" {
    const allocator = std.testing.allocator;

    const Point = struct {
        x: f32,
        y: f32,
    };

    const point = Point{ .x = 10.5, .y = 20.5 };
    const event = try CustomEvent.initWithDetail(allocator, "position", &point);
    defer event.release();

    if (event.getDetail(Point)) |p| {
        try std.testing.expectEqual(@as(f32, 10.5), p.x);
        try std.testing.expectEqual(@as(f32, 20.5), p.y);
    }
}

test "CustomEvent with nested struct detail" {
    const allocator = std.testing.allocator;

    const Address = struct {
        street: []const u8,
        city: []const u8,
    };

    const User = struct {
        id: u32,
        name: []const u8,
        address: Address,
    };

    const user = User{
        .id = 42,
        .name = "Bob",
        .address = .{
            .street = "123 Main St",
            .city = "Springfield",
        },
    };

    const event = try CustomEvent.initWithDetail(allocator, "user-data", &user);
    defer event.release();

    if (event.getDetail(User)) |u| {
        try std.testing.expectEqual(@as(u32, 42), u.id);
        try std.testing.expectEqualStrings("Bob", u.name);
        try std.testing.expectEqualStrings("123 Main St", u.address.street);
        try std.testing.expectEqualStrings("Springfield", u.address.city);
    }
}

test "CustomEvent with integer detail" {
    const allocator = std.testing.allocator;

    const value: u64 = 0xDEADBEEF;
    const event = try CustomEvent.initWithDetail(allocator, "number", &value);
    defer event.release();

    if (event.getDetail(u64)) |v| {
        try std.testing.expectEqual(@as(u64, 0xDEADBEEF), v.*);
    }
}

test "CustomEvent with string detail" {
    const allocator = std.testing.allocator;

    const message: []const u8 = "Hello, World!";
    const detail: *const anyopaque = @ptrCast(&message);
    const event = try CustomEvent.initWithDetail(allocator, "message", detail);
    defer event.release();

    if (event.getDetail([]const u8)) |msg| {
        try std.testing.expectEqualStrings("Hello, World!", msg.*);
    }
}

test "CustomEvent options default values" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.create(allocator, "test", .{});
    defer event.release();

    try std.testing.expect(!event.event.bubbles);
    try std.testing.expect(!event.event.cancelable);
    try std.testing.expect(!event.event.composed);
    try std.testing.expect(event.detail == null);
}

test "CustomEvent with array detail" {
    const allocator = std.testing.allocator;

    const numbers = [_]i32{ 1, 2, 3, 4, 5 };
    const event = try CustomEvent.initWithDetail(allocator, "numbers", &numbers);
    defer event.release();

    if (event.getDetail([5]i32)) |arr| {
        try std.testing.expectEqual(@as(i32, 1), arr[0]);
        try std.testing.expectEqual(@as(i32, 5), arr[4]);
    }
}

test "CustomEvent memory leak test" {
    const allocator = std.testing.allocator;

    // Test rapid creation and destruction
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const data: i32 = @intCast(i);
        const event = try CustomEvent.initWithDetail(allocator, "test", &data);
        defer event.release();

        if (event.getDetail(i32)) |value| {
            try std.testing.expectEqual(@as(i32, @intCast(i)), value.*);
        }
    }
}

test "CustomEvent with multiple creation methods" {
    const allocator = std.testing.allocator;

    // Method 1: init
    const event1 = try CustomEvent.init(allocator, "e1");
    defer event1.release();

    // Method 2: initWithDetail
    const data2: i32 = 2;
    const event2 = try CustomEvent.initWithDetail(allocator, "e2", &data2);
    defer event2.release();

    // Method 3: create
    const data3: i32 = 3;
    const event3 = try CustomEvent.create(allocator, "e3", .{
        .bubbles = true,
        .detail = &data3,
    });
    defer event3.release();

    try std.testing.expectEqualStrings("e1", event1.event.type_name);
    try std.testing.expectEqualStrings("e2", event2.event.type_name);
    try std.testing.expectEqualStrings("e3", event3.event.type_name);
}

test "CustomEvent composed flag" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.create(allocator, "composed-test", .{
        .composed = true,
    });
    defer event.release();

    try std.testing.expect(event.event.composed);
}

// ============================================================================
// Legacy API Tests - initCustomEvent
// ============================================================================

test "CustomEvent initCustomEvent - basic" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.init(allocator, "");
    defer event.release();

    const data: i32 = 42;
    try event.initCustomEvent("test-event", true, false, &data);

    try std.testing.expectEqualStrings("test-event", event.event.type_name);
    try std.testing.expect(event.event.bubbles);
    try std.testing.expect(!event.event.cancelable);

    if (event.getDetail(i32)) |value| {
        try std.testing.expectEqual(@as(i32, 42), value.*);
    }
}

test "CustomEvent initCustomEvent - no detail" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.init(allocator, "");
    defer event.release();

    try event.initCustomEvent("simple", false, true, null);

    try std.testing.expectEqualStrings("simple", event.event.type_name);
    try std.testing.expect(!event.event.bubbles);
    try std.testing.expect(event.event.cancelable);
    try std.testing.expect(event.detail == null);
}

test "CustomEvent initCustomEvent - replaces previous values" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.create(allocator, "original", .{
        .bubbles = true,
        .cancelable = true,
    });
    defer event.release();

    const data: i32 = 999;
    try event.initCustomEvent("replaced", false, false, &data);

    try std.testing.expectEqualStrings("replaced", event.event.type_name);
    try std.testing.expect(!event.event.bubbles);
    try std.testing.expect(!event.event.cancelable);

    if (event.getDetail(i32)) |value| {
        try std.testing.expectEqual(@as(i32, 999), value.*);
    }
}

test "CustomEvent initCustomEvent - with struct detail" {
    const allocator = std.testing.allocator;

    const UserData = struct {
        id: u32,
        name: []const u8,
    };

    const event = try CustomEvent.init(allocator, "");
    defer event.release();

    const user = UserData{ .id = 123, .name = "Alice" };
    try event.initCustomEvent("user-event", true, true, &user);

    try std.testing.expectEqualStrings("user-event", event.event.type_name);
    try std.testing.expect(event.event.bubbles);
    try std.testing.expect(event.event.cancelable);

    if (event.getDetail(UserData)) |data| {
        try std.testing.expectEqual(@as(u32, 123), data.id);
        try std.testing.expectEqualStrings("Alice", data.name);
    }
}

test "CustomEvent initCustomEvent - does nothing when dispatching" {
    const allocator = std.testing.allocator;

    const event = try CustomEvent.create(allocator, "original", .{
        .bubbles = true,
        .cancelable = false,
    });
    defer event.release();

    // Simulate event being dispatched by setting event_phase
    event.event.event_phase = .at_target;

    const data: i32 = 999;
    try event.initCustomEvent("should-not-change", false, true, &data);

    // Should keep original values since event is being dispatched
    try std.testing.expectEqualStrings("original", event.event.type_name);
    try std.testing.expect(event.event.bubbles);
    try std.testing.expect(!event.event.cancelable);
    try std.testing.expect(event.detail == null);

    // Reset event_phase
    event.event.event_phase = .none;
}
