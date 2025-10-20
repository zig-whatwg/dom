const std = @import("std");
const dom = @import("dom");
const AbortSignal = dom.AbortSignal;
const AbortController = dom.AbortController;

test "abort event fired with correct event type" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var event_type_correct = false;

    const Context = struct {
        correct: *bool,
    };
    var ctx = Context{ .correct = &event_type_correct };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            if (std.mem.eql(u8, event.event_type, "abort")) {
                c.correct.* = true;
            }
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try controller.abort(null);

    try std.testing.expect(event_type_correct);
}

test "addEventListener works with abort event" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var listener_called = false;

    const Context = struct {
        called: *bool,
    };
    var ctx = Context{ .called = &listener_called };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.called.* = true;
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try std.testing.expect(!listener_called);

    try controller.abort(null);

    try std.testing.expect(listener_called);
}

test "removeEventListener prevents abort event" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var listener_called = false;

    const Context = struct {
        called: *bool,
    };
    var ctx = Context{ .called = &listener_called };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.called.* = true;
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    controller.signal.removeEventListener("abort", callback, @ptrCast(&ctx), false);

    try controller.abort(null);

    try std.testing.expect(!listener_called);
}

test "event properties: bubbles is false" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var bubbles_correct = false;

    const Context = struct {
        correct: *bool,
    };
    var ctx = Context{ .correct = &bubbles_correct };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            if (!event.bubbles) {
                c.correct.* = true;
            }
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try controller.abort(null);

    try std.testing.expect(bubbles_correct);
}

test "event properties: cancelable is false" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var cancelable_correct = false;

    const Context = struct {
        correct: *bool,
    };
    var ctx = Context{ .correct = &cancelable_correct };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            if (!event.cancelable) {
                c.correct.* = true;
            }
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try controller.abort(null);

    try std.testing.expect(cancelable_correct);
}

test "abort event on already-aborted signal does not fire" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.abort(allocator, null);
    defer signal.release();

    var listener_called = false;

    const Context = struct {
        called: *bool,
    };
    var ctx = Context{ .called = &listener_called };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.called.* = true;
        }
    }.cb;

    try signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try std.testing.expect(!listener_called);
}

test "multiple event listeners all called" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var listener1_called = false;
    var listener2_called = false;
    var listener3_called = false;

    const Context = struct {
        called: *bool,
    };
    var ctx1 = Context{ .called = &listener1_called };
    var ctx2 = Context{ .called = &listener2_called };
    var ctx3 = Context{ .called = &listener3_called };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.called.* = true;
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx1), false, false, false, null);
    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx2), false, false, false, null);
    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx3), false, false, false, null);

    try controller.abort(null);

    try std.testing.expect(listener1_called);
    try std.testing.expect(listener2_called);
    try std.testing.expect(listener3_called);
}

test "abort event fires synchronously" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var event_fired = false;

    const Context = struct {
        fired: *bool,
    };
    var ctx = Context{ .fired = &event_fired };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.fired.* = true;
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try std.testing.expect(!event_fired);

    try controller.abort(null);

    try std.testing.expect(event_fired);
}

test "event listener with once option called only once" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    var call_count: usize = 0;

    const Context = struct {
        count: *usize,
    };
    var ctx = Context{ .count = &call_count };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.count.* += 1;
        }
    }.cb;

    try signal.addEventListener("test", callback, @ptrCast(&ctx), false, true, false, null);

    var event1 = dom.Event.init("test", .{});
    _ = try signal.dispatchEvent(&event1);

    try std.testing.expectEqual(@as(usize, 1), call_count);

    var event2 = dom.Event.init("test", .{});
    _ = try signal.dispatchEvent(&event2);

    try std.testing.expectEqual(@as(usize, 1), call_count);
}

test "event listener with capture mode" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var capture_called = false;

    const Context = struct {
        called: *bool,
    };
    var ctx = Context{ .called = &capture_called };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.called.* = true;
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), true, false, false, null);

    try controller.abort(null);

    try std.testing.expect(capture_called);
}
