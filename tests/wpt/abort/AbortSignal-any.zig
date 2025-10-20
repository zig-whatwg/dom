const std = @import("std");
const dom = @import("dom");
const AbortSignal = dom.AbortSignal;
const AbortController = dom.AbortController;

test "AbortSignal.any() works with an empty array of signals" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.any(allocator, &[_]*AbortSignal{});
    defer signal.release();

    try std.testing.expect(!signal.isAborted());
}

test "AbortSignal.any() follows a single signal" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const source = controller.signal;
    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{source});
    defer composite.release();

    try std.testing.expect(!composite.isAborted());
    try std.testing.expect(composite.getReason() == null);
    try std.testing.expect(source != composite);

    var event_fired = false;
    const Context = struct {
        fired: *bool,
        composite: *AbortSignal,
    };
    var ctx = Context{ .fired = &event_fired, .composite = composite };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.fired.* = true;
        }
    }.cb;

    try composite.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    const custom_reason = @as(*anyopaque, @ptrFromInt(0x1234));
    try controller.abort(custom_reason);

    try std.testing.expect(source.isAborted());
    try std.testing.expect(composite.isAborted());
    try std.testing.expect(event_fired);
    try std.testing.expectEqual(custom_reason, composite.getReason());
}

test "AbortSignal.any() follows multiple signals" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const controller1 = try AbortController.init(allocator);
        defer controller1.deinit();

        const controller2 = try AbortController.init(allocator);
        defer controller2.deinit();

        const controller3 = try AbortController.init(allocator);
        defer controller3.deinit();

        const controllers = [_]*AbortController{ controller1, controller2, controller3 };
        const signals = [_]*AbortSignal{ controller1.signal, controller2.signal, controller3.signal };

        const composite = try AbortSignal.any(allocator, &signals);
        defer composite.release();

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

        try composite.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

        try controllers[i].abort(null);

        try std.testing.expect(event_fired);
        try std.testing.expect(composite.isAborted());
        try std.testing.expect(composite.getReason() != null);
    }
}

test "AbortSignal.any() returns an aborted signal if passed an aborted signal" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    const controller3 = try AbortController.init(allocator);
    defer controller3.deinit();

    const reason1 = @as(*anyopaque, @ptrFromInt(0x1111));
    const reason2 = @as(*anyopaque, @ptrFromInt(0x2222));

    try controller2.abort(reason1);
    try controller3.abort(reason2);

    const signals = [_]*AbortSignal{ controller1.signal, controller2.signal, controller3.signal };
    const composite = try AbortSignal.any(allocator, &signals);
    defer composite.release();

    try std.testing.expect(composite.isAborted());
    try std.testing.expectEqual(reason1, composite.getReason());
}

test "AbortSignal.any() can be passed the same signal more than once" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal = controller.signal;
    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{ signal, signal });
    defer composite.release();

    try std.testing.expect(!composite.isAborted());

    const custom_reason = @as(*anyopaque, @ptrFromInt(0xABCD));
    try controller.abort(custom_reason);

    try std.testing.expect(composite.isAborted());
    try std.testing.expectEqual(custom_reason, composite.getReason());
}

test "AbortSignal.any() uses the first instance of a duplicate signal" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    const reason1 = @as(*anyopaque, @ptrFromInt(0xAAAA));
    const reason2 = @as(*anyopaque, @ptrFromInt(0xBBBB));

    try controller1.abort(reason1);
    try controller2.abort(reason2);

    const signals = [_]*AbortSignal{ controller1.signal, controller2.signal, controller1.signal };
    const composite = try AbortSignal.any(allocator, &signals);
    defer composite.release();

    try std.testing.expect(composite.isAborted());
    try std.testing.expectEqual(reason1, composite.getReason());
}

test "AbortSignal.any() signals are composable" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const controller1 = try AbortController.init(allocator);
        defer controller1.deinit();

        const controller2 = try AbortController.init(allocator);
        defer controller2.deinit();

        const controller3 = try AbortController.init(allocator);
        defer controller3.deinit();

        const controllers = [_]*AbortController{ controller1, controller2, controller3 };

        const composite1 = try AbortSignal.any(allocator, &[_]*AbortSignal{ controller1.signal, controller2.signal });
        defer composite1.release();

        const composite2 = try AbortSignal.any(allocator, &[_]*AbortSignal{ composite1, controller3.signal });
        defer composite2.release();

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

        try composite2.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

        try controllers[i].abort(null);

        try std.testing.expect(event_fired);
        try std.testing.expect(composite2.isAborted());
        try std.testing.expect(composite2.getReason() != null);
    }
}

test "AbortSignal.any() works with intermediate signals" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var combined = try AbortSignal.any(allocator, &[_]*AbortSignal{controller.signal});
    defer combined.release();

    const combined2 = try AbortSignal.any(allocator, &[_]*AbortSignal{combined});
    defer combined2.release();

    const combined3 = try AbortSignal.any(allocator, &[_]*AbortSignal{combined2});
    defer combined3.release();

    const combined4 = try AbortSignal.any(allocator, &[_]*AbortSignal{combined3});
    defer combined4.release();

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

    try combined4.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try std.testing.expect(!event_fired);
    try std.testing.expect(!combined4.isAborted());

    const custom_reason = @as(*anyopaque, @ptrFromInt(0xDEAD));
    try controller.abort(custom_reason);

    try std.testing.expect(event_fired);
    try std.testing.expect(combined4.isAborted());
    try std.testing.expectEqual(custom_reason, combined4.getReason());
}

test "Abort events for AbortSignal.any() signals fire in the right order" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var signals = std.ArrayList(*AbortSignal){};
    defer signals.deinit(allocator);

    try signals.append(allocator, controller.signal);

    const signal1 = try AbortSignal.any(allocator, &[_]*AbortSignal{controller.signal});
    defer signal1.release();
    try signals.append(allocator, signal1);

    const signal2 = try AbortSignal.any(allocator, &[_]*AbortSignal{controller.signal});
    defer signal2.release();
    try signals.append(allocator, signal2);

    const signal3 = try AbortSignal.any(allocator, &[_]*AbortSignal{signals.items[0]});
    defer signal3.release();
    try signals.append(allocator, signal3);

    const signal4 = try AbortSignal.any(allocator, &[_]*AbortSignal{signals.items[1]});
    defer signal4.release();
    try signals.append(allocator, signal4);

    var result = std.ArrayList(u8){};
    defer result.deinit(allocator);

    const Context = struct {
        result: *std.ArrayList(u8),
        index: u8,
    };

    var ctx0 = Context{ .result = &result, .index = 0 };
    var ctx1 = Context{ .result = &result, .index = 1 };
    var ctx2 = Context{ .result = &result, .index = 2 };
    var ctx3 = Context{ .result = &result, .index = 3 };
    var ctx4 = Context{ .result = &result, .index = 4 };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.result.append(std.testing.allocator, c.index + '0') catch unreachable;
        }
    }.cb;

    try signals.items[0].addEventListener("abort", callback, @ptrCast(&ctx0), false, false, false, null);
    try signals.items[1].addEventListener("abort", callback, @ptrCast(&ctx1), false, false, false, null);
    try signals.items[2].addEventListener("abort", callback, @ptrCast(&ctx2), false, false, false, null);
    try signals.items[3].addEventListener("abort", callback, @ptrCast(&ctx3), false, false, false, null);
    try signals.items[4].addEventListener("abort", callback, @ptrCast(&ctx4), false, false, false, null);

    try controller.abort(null);

    try std.testing.expectEqualStrings("01234", result.items);
}

test "Dependent signals for AbortSignal.any() are marked aborted before abort events fire" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal1 = try AbortSignal.any(allocator, &[_]*AbortSignal{controller.signal});
    defer signal1.release();

    const signal2 = try AbortSignal.any(allocator, &[_]*AbortSignal{signal1});
    defer signal2.release();

    var event_fired = false;

    const Context = struct {
        fired: *bool,
        controller: *AbortController,
        signal1: *AbortSignal,
        signal2: *AbortSignal,
        allocator: std.mem.Allocator,
    };
    var ctx = Context{
        .fired = &event_fired,
        .controller = controller,
        .signal1 = signal1,
        .signal2 = signal2,
        .allocator = allocator,
    };

    const callback = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));

            const signal3 = AbortSignal.any(c.allocator, &[_]*AbortSignal{c.signal2}) catch unreachable;
            defer signal3.release();

            std.testing.expect(c.controller.signal.isAborted()) catch unreachable;
            std.testing.expect(c.signal1.isAborted()) catch unreachable;
            std.testing.expect(c.signal2.isAborted()) catch unreachable;
            std.testing.expect(signal3.isAborted()) catch unreachable;

            c.fired.* = true;
        }
    }.cb;

    try controller.signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    try controller.abort(null);

    try std.testing.expect(event_fired);
}

test "Dependent signals for AbortSignal.any() are aborted correctly for reentrant aborts" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{ controller1.signal, controller2.signal });
    defer composite.release();

    var count: usize = 0;

    const Context = struct {
        count: *usize,
        controller2: *AbortController,
    };
    var ctx1 = Context{ .count = &count, .controller2 = controller2 };

    const callback1 = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            const reason2 = @as(*anyopaque, @ptrFromInt(0x2222));
            c.controller2.abort(reason2) catch unreachable;
        }
    }.cb;

    try controller1.signal.addEventListener("abort", callback1, @ptrCast(&ctx1), false, false, false, null);

    const Context2 = struct {
        count: *usize,
    };
    var ctx2 = Context2{ .count = &count };

    const callback2 = struct {
        fn cb(event: *dom.Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context2, @ptrCast(@alignCast(context)));
            c.count.* += 1;
        }
    }.cb;

    try composite.addEventListener("abort", callback2, @ptrCast(&ctx2), false, false, false, null);

    const reason1 = @as(*anyopaque, @ptrFromInt(0x1111));
    try controller1.abort(reason1);

    try std.testing.expectEqual(@as(usize, 1), count);
    try std.testing.expect(composite.isAborted());
    try std.testing.expectEqual(reason1, composite.getReason());
}

test "Dependent signals for AbortSignal.any() should use the same DOMException instance from the already aborted source signal" {
    const allocator = std.testing.allocator;

    const source = try AbortSignal.abort(allocator, null);
    defer source.release();

    const dependent = try AbortSignal.any(allocator, &[_]*AbortSignal{source});
    defer dependent.release();

    try std.testing.expect(source.getReason() != null);
    try std.testing.expectEqual(source.getReason(), dependent.getReason());
}

test "Dependent signals for AbortSignal.any() should use the same DOMException instance from the source signal being aborted later" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const source = controller.signal;
    const dependent = try AbortSignal.any(allocator, &[_]*AbortSignal{source});
    defer dependent.release();

    try controller.abort(null);

    try std.testing.expect(source.getReason() != null);
    try std.testing.expectEqual(source.getReason(), dependent.getReason());
}
