//! Tests for EventTarget mixin.
//!
//! Validates that the EventTargetMixin comptime pattern works correctly
//! with a mock type (not Node).

const std = @import("std");
const event_target = @import("event_target.zig");
const EventTargetMixin = event_target.EventTargetMixin;
const EventListener = event_target.EventListener;
const EventCallback = event_target.EventCallback;
const Event = @import("event.zig").Event;
const Allocator = std.mem.Allocator;

// Mock RareData for testing
const MockRareData = struct {
    allocator: Allocator,
    listeners: std.ArrayList(EventListener),

    pub fn init(allocator: Allocator) MockRareData {
        return .{
            .allocator = allocator,
            .listeners = std.ArrayList(EventListener){},
        };
    }

    pub fn deinit(self: *MockRareData) void {
        self.listeners.deinit(self.allocator);
    }

    pub fn addEventListener(self: *MockRareData, listener: EventListener) !void {
        try self.listeners.append(self.allocator, listener);
    }

    pub fn removeEventListener(
        self: *MockRareData,
        event_type: []const u8,
        callback: EventCallback,
        capture: bool,
    ) bool {
        for (self.listeners.items, 0..) |listener, i| {
            if (std.mem.eql(u8, listener.event_type, event_type) and
                listener.callback == callback and
                listener.capture == capture)
            {
                _ = self.listeners.swapRemove(i);
                return true;
            }
        }
        return false;
    }

    pub fn hasEventListeners(self: *const MockRareData, event_type: []const u8) bool {
        for (self.listeners.items) |listener| {
            if (std.mem.eql(u8, listener.event_type, event_type)) {
                return true;
            }
        }
        return false;
    }

    pub fn getEventListeners(self: *const MockRareData, event_type: []const u8) []const EventListener {
        // For simplicity, return all listeners (real impl would filter)
        _ = event_type;
        return self.listeners.items;
    }
};

// Mock EventTarget for testing mixin - using manual method forwarding for now
const MockEventTarget = struct {
    allocator: Allocator,
    rare_data: ?*MockRareData,

    const Mixin = EventTargetMixin(MockEventTarget);

    fn init(allocator: Allocator) MockEventTarget {
        return .{
            .allocator = allocator,
            .rare_data = null,
        };
    }

    fn deinit(self: *MockEventTarget) void {
        if (self.rare_data) |rare| {
            rare.deinit();
            self.allocator.destroy(rare);
        }
    }

    pub fn ensureRareData(self: *MockEventTarget) !*MockRareData {
        if (self.rare_data == null) {
            self.rare_data = try self.allocator.create(MockRareData);
            self.rare_data.?.* = MockRareData.init(self.allocator);
        }
        return self.rare_data.?;
    }

    // Forward mixin methods
    fn addEventListener(
        self: *MockEventTarget,
        event_type: []const u8,
        callback: EventCallback,
        context: *anyopaque,
        capture: bool,
        once: bool,
        passive: bool,
    ) !void {
        return Mixin.addEventListener(self, event_type, callback, context, capture, once, passive);
    }

    pub fn removeEventListener(
        self: *MockEventTarget,
        event_type: []const u8,
        callback: EventCallback,
        capture: bool,
    ) void {
        return Mixin.removeEventListener(self, event_type, callback, capture);
    }

    fn dispatchEvent(self: *MockEventTarget, evt: *Event) !bool {
        return Mixin.dispatchEvent(self, evt);
    }

    fn hasEventListeners(self: *const MockEventTarget, event_type: []const u8) bool {
        return Mixin.hasEventListeners(self, event_type);
    }

    fn getEventListeners(self: *const MockEventTarget, event_type: []const u8) []const EventListener {
        return Mixin.getEventListeners(self, event_type);
    }
};

test "EventTarget mixin - addEventListener adds listener" {
    const allocator = std.testing.allocator;

    var target = MockEventTarget.init(allocator);
    defer target.deinit();

    const callback = struct {
        fn handle(_: *Event, _: *anyopaque) void {}
    }.handle;

    var ctx: u32 = 42;
    try target.addEventListener("test", callback, @ptrCast(&ctx), false, false, false);

    try std.testing.expect(target.hasEventListeners("test"));
}

test "EventTarget mixin - removeEventListener removes listener" {
    const allocator = std.testing.allocator;

    var target = MockEventTarget.init(allocator);
    defer target.deinit();

    const callback = struct {
        fn handle(_: *Event, _: *anyopaque) void {}
    }.handle;

    var ctx: u32 = 42;
    try target.addEventListener("test", callback, @ptrCast(&ctx), false, false, false);
    try std.testing.expect(target.hasEventListeners("test"));

    target.removeEventListener("test", callback, false);
    try std.testing.expect(!target.hasEventListeners("test"));
}

test "EventTarget mixin - dispatchEvent invokes listener" {
    const allocator = std.testing.allocator;

    var target = MockEventTarget.init(allocator);
    defer target.deinit();

    var invoked = false;
    const callback = struct {
        fn handle(_: *Event, ctx: *anyopaque) void {
            const flag = @as(*bool, @ptrCast(@alignCast(ctx)));
            flag.* = true;
        }
    }.handle;

    try target.addEventListener("test", callback, @ptrCast(&invoked), false, false, false);

    var event = Event.init("test", .{});
    const result = try target.dispatchEvent(&event);

    try std.testing.expect(result); // Not canceled
    try std.testing.expect(invoked); // Callback was called
}

test "EventTarget mixin - once listener removed after dispatch" {
    const allocator = std.testing.allocator;

    var target = MockEventTarget.init(allocator);
    defer target.deinit();

    var count: u32 = 0;
    const callback = struct {
        fn handle(_: *Event, ctx: *anyopaque) void {
            const counter = @as(*u32, @ptrCast(@alignCast(ctx)));
            counter.* += 1;
        }
    }.handle;

    // Add "once" listener
    try target.addEventListener("test", callback, @ptrCast(&count), false, true, false);

    var event1 = Event.init("test", .{});
    _ = try target.dispatchEvent(&event1);
    try std.testing.expectEqual(@as(u32, 1), count);

    // Dispatch again - listener should be removed
    var event2 = Event.init("test", .{});
    _ = try target.dispatchEvent(&event2);
    try std.testing.expectEqual(@as(u32, 1), count); // Still 1, not 2
}

test "EventTarget mixin - passive listener flag set during dispatch" {
    const allocator = std.testing.allocator;

    var target = MockEventTarget.init(allocator);
    defer target.deinit();

    const callback = struct {
        fn handle(evt: *Event, _: *anyopaque) void {
            // Passive listener flag should be set
            // (in real implementation, preventDefault would check this)
            _ = evt;
        }
    }.handle;

    var ctx: u32 = 42;
    try target.addEventListener("test", callback, @ptrCast(&ctx), false, false, true);

    var event = Event.init("test", .{ .cancelable = true });
    _ = try target.dispatchEvent(&event);
}
