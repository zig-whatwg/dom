//! Tests for Event Legacy Properties (Phase 8)
//!
//! Tests the legacy Event properties and methods:
//! - srcElement (alias of target)
//! - cancelBubble (writable alias of stopPropagation)
//! - returnValue (writable alias of preventDefault)
//! - initEvent() (legacy initialization method)

const std = @import("std");
const dom = @import("dom");
const Event = dom.Event;

test "Event.srcElement - alias of target" {
    const allocator = std.testing.allocator;

    // Create event target
    const target_ptr = try allocator.create(u32);
    defer allocator.destroy(target_ptr);
    target_ptr.* = 42;

    var event = Event.init("click", .{});
    event.target = target_ptr;

    // srcElement should return same as target
    const src = event.srcElement();
    try std.testing.expect(src != null);
    try std.testing.expectEqual(@as(?*anyopaque, target_ptr), src);
}

test "Event.srcElement - null when target is null" {
    var event = Event.init("click", .{});
    try std.testing.expect(event.srcElement() == null);
}

test "Event.cancelBubble - getter returns stop propagation flag" {
    var event = Event.init("click", .{ .bubbles = true });

    // Initially false
    try std.testing.expect(!event.getCancelBubble());

    // After stopPropagation, should be true
    event.stopPropagation();
    try std.testing.expect(event.getCancelBubble());
}

test "Event.cancelBubble - setter stops propagation when true" {
    var event = Event.init("click", .{ .bubbles = true });

    try std.testing.expect(!event.stop_propagation_flag);

    // Setting to true should stop propagation
    event.setCancelBubble(true);
    try std.testing.expect(event.stop_propagation_flag);
}

test "Event.cancelBubble - setter does nothing when false" {
    var event = Event.init("click", .{ .bubbles = true });

    // Stop propagation
    event.stopPropagation();
    try std.testing.expect(event.stop_propagation_flag);

    // Setting to false should not un-stop propagation (per spec)
    event.setCancelBubble(false);
    try std.testing.expect(event.stop_propagation_flag);
}

test "Event.returnValue - getter returns inverted canceled flag" {
    var event = Event.init("click", .{ .cancelable = true });

    // Initially true (not canceled)
    try std.testing.expect(event.getReturnValue());

    // After preventDefault, should be false
    event.preventDefault();
    try std.testing.expect(!event.getReturnValue());
}

test "Event.returnValue - setter prevents default when false" {
    var event = Event.init("submit", .{ .cancelable = true });

    try std.testing.expect(!event.canceled_flag);

    // Setting to false should prevent default
    event.setReturnValue(false);
    try std.testing.expect(event.canceled_flag);
}

test "Event.returnValue - setter does nothing when true" {
    var event = Event.init("submit", .{ .cancelable = true });

    // Prevent default
    event.preventDefault();
    try std.testing.expect(event.canceled_flag);

    // Setting to true should not un-cancel (per spec)
    event.setReturnValue(true);
    try std.testing.expect(event.canceled_flag);
}

test "Event.returnValue - respects cancelable flag" {
    var event = Event.init("load", .{ .cancelable = false });

    // Setting to false should not prevent default (not cancelable)
    event.setReturnValue(false);
    try std.testing.expect(!event.canceled_flag);
    try std.testing.expect(event.getReturnValue());
}

test "Event.initEvent - basic initialization" {
    var event = Event.init("", .{});

    event.initEvent("custom", true, true);

    try std.testing.expectEqualStrings("custom", event.event_type);
    try std.testing.expect(event.bubbles);
    try std.testing.expect(event.cancelable);
    try std.testing.expect(event.initialized_flag);
}

test "Event.initEvent - clears all flags" {
    var event = Event.init("click", .{ .bubbles = true, .cancelable = true });

    // Set various flags
    event.stopPropagation();
    event.stopImmediatePropagation();
    event.preventDefault();
    event.is_trusted = true;

    // Reinitialize
    event.initEvent("newtype", false, false);

    // All flags should be cleared
    try std.testing.expect(!event.stop_propagation_flag);
    try std.testing.expect(!event.stop_immediate_propagation_flag);
    try std.testing.expect(!event.canceled_flag);
    try std.testing.expect(!event.is_trusted); // Always set to false
    try std.testing.expect(event.target == null);
    try std.testing.expectEqualStrings("newtype", event.event_type);
    try std.testing.expect(!event.bubbles);
    try std.testing.expect(!event.cancelable);
}

test "Event.initEvent - no-op when dispatch flag is set" {
    var event = Event.init("click", .{});
    event.dispatch_flag = true;

    const original_type = event.event_type;

    // Should do nothing
    event.initEvent("newtype", true, true);

    try std.testing.expectEqualStrings(original_type, event.event_type);
    try std.testing.expect(!event.bubbles);
    try std.testing.expect(!event.cancelable);
}

test "Event.initEvent - default parameters" {
    var event = Event.init("old", .{});

    // Call with only required parameter
    event.initEvent("new", false, false);

    try std.testing.expectEqualStrings("new", event.event_type);
    try std.testing.expect(!event.bubbles);
    try std.testing.expect(!event.cancelable);
}

test "Event.initEvent - maintains initialized flag" {
    var event = Event.init("test", .{});
    try std.testing.expect(event.initialized_flag); // Already set by init

    event.initEvent("test", false, false);
    try std.testing.expect(event.initialized_flag); // Still set
}

test "Event legacy properties - integration test" {
    const allocator = std.testing.allocator;

    const target_ptr = try allocator.create(u32);
    defer allocator.destroy(target_ptr);

    var event = Event.init("", .{});

    // Initialize with legacy method
    event.initEvent("click", true, true);
    event.target = target_ptr;

    // Verify srcElement works
    try std.testing.expectEqual(@as(?*anyopaque, target_ptr), event.srcElement());

    // Use cancelBubble to stop propagation
    event.setCancelBubble(true);
    try std.testing.expect(event.getCancelBubble());
    try std.testing.expect(event.stop_propagation_flag);

    // Use returnValue to prevent default
    event.setReturnValue(false);
    try std.testing.expect(!event.getReturnValue());
    try std.testing.expect(event.canceled_flag);
}
