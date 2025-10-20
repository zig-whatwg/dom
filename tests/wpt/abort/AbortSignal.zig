const std = @import("std");
const dom = @import("dom");
const AbortSignal = dom.AbortSignal;
const AbortController = dom.AbortController;

test "AbortSignal.abort() static returns an already aborted signal" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.abort(allocator, null);
    defer signal.release();

    try std.testing.expect(signal.isAborted());
}

test "signal returned by AbortSignal.abort() should not fire abort event" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.abort(allocator, null);
    defer signal.release();

    var event_called = false;
    const Context = struct {
        called: *bool,
    };
    var ctx = Context{ .called = &event_called };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.called.* = true;
        }
    }.cb;

    try signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try std.testing.expect(!event_called);
}

test "AbortController abort() should fire event synchronously" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal = controller.signal;
    var state: u8 = 0;

    try std.testing.expect(!signal.isAborted());
    try std.testing.expect(signal.getReason() == null);

    const Context = struct {
        state: *u8,
    };
    var ctx = Context{ .state = &state };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            std.testing.expectEqual(@as(u8, 0), c.state.*) catch unreachable;
            c.state.* = 1;
        }
    }.cb;

    try signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try controller.abort(null);

    try std.testing.expectEqual(@as(u8, 1), state);
    try std.testing.expect(signal.isAborted());
    try std.testing.expect(signal.getReason() != null);

    try controller.abort(null);
}

test "controller.signal should always return the same object" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal1 = controller.signal;
    try std.testing.expectEqual(signal1, controller.signal);

    try controller.abort(null);
    try std.testing.expectEqual(signal1, controller.signal);
}

test "controller.abort() should do nothing the second time it is called" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal = controller.signal;
    var event_count: usize = 0;

    const Context = struct {
        count: *usize,
    };
    var ctx = Context{ .count = &event_count };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.count.* += 1;
        }
    }.cb;

    try signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try controller.abort(null);
    try std.testing.expect(signal.isAborted());
    try std.testing.expectEqual(@as(usize, 1), event_count);

    try controller.abort(null);
    try std.testing.expect(signal.isAborted());
    try std.testing.expectEqual(@as(usize, 1), event_count);
}

test "event handler should not be called if added after controller.abort()" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try controller.abort(null);

    var event_called = false;
    const Context = struct {
        called: *bool,
    };
    var ctx = Context{ .called = &event_called };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.called.* = true;
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try std.testing.expect(!event_called);
}

test "the abort event should have the right properties" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal = controller.signal;

    const Context = struct {
        signal: *AbortSignal,
        checked: *bool,
    };
    var checked = false;
    var ctx = Context{ .signal = signal, .checked = &checked };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            std.testing.expectEqualStrings("abort", event.event_type) catch unreachable;
            std.testing.expect(!event.bubbles) catch unreachable;
            c.checked.* = true;
        }
    }.cb;

    try signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try controller.abort(null);

    try std.testing.expect(checked);
}

test "AbortController abort(reason) should set signal.reason" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal = controller.signal;

    try std.testing.expect(signal.getReason() == null);

    const custom_reason = @as(*anyopaque, @ptrFromInt(0xCAFEBABE));
    try controller.abort(custom_reason);

    try std.testing.expect(signal.isAborted());
    try std.testing.expectEqual(custom_reason, signal.getReason());
}

test "aborting AbortController without reason creates an AbortError DOMException" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal = controller.signal;

    try std.testing.expect(signal.getReason() == null);

    try controller.abort(null);

    try std.testing.expect(signal.isAborted());
    try std.testing.expect(signal.getReason() != null);
}

test "static aborting signal should have right properties" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.abort(allocator, null);
    defer signal.release();

    try std.testing.expect(signal.isAborted());
    try std.testing.expect(signal.getReason() != null);
}

test "static aborting signal with reason should set signal.reason" {
    const allocator = std.testing.allocator;

    const custom_reason = @as(*anyopaque, @ptrFromInt(0xDEADBEEF));
    const signal = try AbortSignal.abort(allocator, custom_reason);
    defer signal.release();

    try std.testing.expect(signal.isAborted());
    try std.testing.expectEqual(custom_reason, signal.getReason());
}

test "throwIfAborted() should throw abort.reason if signal aborted" {
    const allocator = std.testing.allocator;

    const custom_reason = @as(*anyopaque, @ptrFromInt(0xBAADF00D));
    const signal = try AbortSignal.abort(allocator, custom_reason);
    defer signal.release();

    try std.testing.expect(signal.isAborted());
    try std.testing.expectError(error.AbortError, signal.throwIfAborted());
}

test "throwIfAborted() should not throw if signal not aborted" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try std.testing.expect(!controller.signal.isAborted());
    try controller.signal.throwIfAborted();
}

test "AbortSignal.reason returns the same DOMException" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.abort(allocator, null);
    defer signal.release();

    const reason1 = signal.getReason();
    const reason2 = signal.getReason();

    try std.testing.expect(reason1 != null);
    try std.testing.expectEqual(reason1, reason2);
}

test "AbortController.signal.reason returns the same DOMException" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try controller.abort(null);

    const reason1 = controller.signal.getReason();
    const reason2 = controller.signal.getReason();

    try std.testing.expect(reason1 != null);
    try std.testing.expectEqual(reason1, reason2);
}
