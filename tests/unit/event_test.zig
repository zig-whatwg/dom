//! event Tests
//!
//! Tests for event functionality.

const std = @import("std");
const dom = @import("dom");
const Event = dom.Event;

test "Event.init - creates event with type" {
    const event = Event.init("click", .{});
    try std.testing.expectEqualStrings("click", event.event_type);
    try std.testing.expect(event.initialized_flag == true);
    try std.testing.expect(event.is_trusted == false);
}

test "Event.init - uses default options" {
    const event = Event.init("custom", .{});
    try std.testing.expect(event.bubbles == false);
    try std.testing.expect(event.cancelable == false);
    try std.testing.expect(event.composed == false);
}

test "Event.init - respects bubbles option" {
    const event = Event.init("submit", .{ .bubbles = true });
    try std.testing.expect(event.bubbles == true);
}

test "Event.init - respects cancelable option" {
    const event = Event.init("click", .{ .cancelable = true });
    try std.testing.expect(event.cancelable == true);
}

test "Event.init - respects composed option" {
    const event = Event.init("change", .{ .composed = true });
    try std.testing.expect(event.composed == true);
}

test "Event.stopPropagation - sets stop propagation flag" {
    var event = Event.init("click", .{});
    try std.testing.expect(event.stop_propagation_flag == false);

    event.stopPropagation();
    try std.testing.expect(event.stop_propagation_flag == true);
}

test "Event.stopImmediatePropagation - sets both flags" {
    var event = Event.init("click", .{});
    try std.testing.expect(event.stop_propagation_flag == false);
    try std.testing.expect(event.stop_immediate_propagation_flag == false);

    event.stopImmediatePropagation();
    try std.testing.expect(event.stop_propagation_flag == true);
    try std.testing.expect(event.stop_immediate_propagation_flag == true);
}

test "Event.preventDefault - cancels cancelable event" {
    var event = Event.init("submit", .{ .cancelable = true });
    try std.testing.expect(event.defaultPrevented() == false);

    event.preventDefault();
    try std.testing.expect(event.defaultPrevented() == true);
}

test "Event.preventDefault - no effect on non-cancelable event" {
    var event = Event.init("click", .{ .cancelable = false });
    try std.testing.expect(event.defaultPrevented() == false);

    event.preventDefault();
    try std.testing.expect(event.defaultPrevented() == false);
}

test "Event.preventDefault - no effect in passive listener" {
    var event = Event.init("wheel", .{ .cancelable = true });
    event.in_passive_listener_flag = true;

    event.preventDefault();
    try std.testing.expect(event.defaultPrevented() == false);
}

test "Event.defaultPrevented - returns canceled state" {
    var event = Event.init("click", .{ .cancelable = true });
    try std.testing.expect(event.defaultPrevented() == false);

    event.canceled_flag = true;
    try std.testing.expect(event.defaultPrevented() == true);
}

test "Event - initial event_phase is none" {
    const event = Event.init("load", .{});
    try std.testing.expect(event.event_phase == .none);
}

test "Event - event_phase constants match spec" {
    try std.testing.expectEqual(@as(u16, 0), @intFromEnum(Event.EventPhase.none));
    try std.testing.expectEqual(@as(u16, 1), @intFromEnum(Event.EventPhase.capturing_phase));
    try std.testing.expectEqual(@as(u16, 2), @intFromEnum(Event.EventPhase.at_target));
    try std.testing.expectEqual(@as(u16, 3), @intFromEnum(Event.EventPhase.bubbling_phase));
}
