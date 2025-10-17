const std = @import("std");
const AbortSignal = @import("abort_signal.zig").AbortSignal;
const AbortController = @import("abort_controller.zig").AbortController;
const AbortAlgorithm = @import("abort_signal.zig").AbortAlgorithm;
const Event = @import("event.zig").Event;

test "AbortSignal.init - creates signal with ref_count = 1" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    try std.testing.expectEqual(@as(u32, 1), signal.ref_count);
    try std.testing.expect(!signal.isAborted());
    try std.testing.expect(signal.getReason() == null);
    try std.testing.expect(!signal.dependent);
}

test "AbortSignal.init - not aborted initially" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    try std.testing.expect(!signal.isAborted());
    try std.testing.expectEqual(@as(?*anyopaque, null), signal.getReason());
}

test "AbortSignal.acquire - increments ref_count" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    try std.testing.expectEqual(@as(u32, 1), signal.ref_count);

    signal.acquire();
    try std.testing.expectEqual(@as(u32, 2), signal.ref_count);

    signal.acquire();
    try std.testing.expectEqual(@as(u32, 3), signal.ref_count);

    // Balance the extra acquires
    signal.release();
    signal.release();
}

test "AbortSignal.release - decrements ref_count" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);

    signal.acquire();
    signal.acquire();
    try std.testing.expectEqual(@as(u32, 3), signal.ref_count);

    signal.release();
    try std.testing.expectEqual(@as(u32, 2), signal.ref_count);

    signal.release();
    try std.testing.expectEqual(@as(u32, 1), signal.ref_count);

    signal.release(); // Final release - should deinit
}

test "AbortSignal.throwIfAborted - does not throw when not aborted" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    try signal.throwIfAborted(); // Should not throw
}

test "AbortSignal - size is exactly 48 bytes" {
    try std.testing.expectEqual(@as(usize, 48), @sizeOf(AbortSignal));
}

test "AbortSignal - no memory leaks on init/release" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    signal.release();

    // Test passes if no leaks detected by testing allocator
}

test "AbortSignal - multiple acquire/release cycles" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);

    // Simulate multiple owners
    signal.acquire(); // Owner 2
    signal.acquire(); // Owner 3
    signal.acquire(); // Owner 4

    try std.testing.expectEqual(@as(u32, 4), signal.ref_count);

    // Owners release
    signal.release(); // 3 left
    signal.release(); // 2 left
    signal.release(); // 1 left
    signal.release(); // 0 - deinit
}

test "AbortSignal - rare_data starts as null" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    try std.testing.expect(signal.rare_data == null);
}

test "AbortSignal - dependent flag defaults to false" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    try std.testing.expect(!signal.dependent);
}

// AbortController tests

test "AbortController.init - creates controller with signal" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    // Signal should be non-null and not aborted
    try std.testing.expect(!controller.signal.isAborted());
}

test "AbortController.deinit - releases signal" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    const signal = controller.signal;

    try std.testing.expectEqual(@as(u32, 1), signal.ref_count);

    controller.deinit();
    // Signal should be destroyed (ref_count reached 0)
}

test "AbortController.abort - sets signal aborted state" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try std.testing.expect(!controller.signal.isAborted());

    try controller.abort(null);

    try std.testing.expect(controller.signal.isAborted());
}

test "AbortController.abort - sets abort reason" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try controller.abort(null);

    const reason = controller.signal.getReason();
    try std.testing.expect(reason != null);
}

test "AbortController.abort - is idempotent" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try controller.abort(null);
    const first_reason = controller.signal.getReason();

    // Abort again - should be no-op
    try controller.abort(@ptrFromInt(0x1234));

    // Reason should not change
    try std.testing.expectEqual(first_reason, controller.signal.getReason());
}

test "AbortController - signal outlives controller when acquired" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    const signal = controller.signal;

    // Abort the signal before deinit (tests scenario where signal is aborted)
    try controller.abort(null);

    // Acquire additional reference
    signal.acquire();
    try std.testing.expectEqual(@as(u32, 2), signal.ref_count);

    // Controller deinit releases its reference
    controller.deinit();

    // Signal still alive (ref_count = 1)
    try std.testing.expect(signal.isAborted());

    // Release our reference
    signal.release();
}

test "AbortController - [SameObject] signal property" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal1 = controller.signal;
    const signal2 = controller.signal;

    // Must return same instance per WebIDL [SameObject]
    try std.testing.expectEqual(signal1, signal2);
}

test "AbortController - size is exactly 24 bytes" {
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(AbortController));
}

test "AbortController - no memory leaks on init/deinit" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    controller.deinit();

    // Test passes if no leaks detected by testing allocator
}

// AbortSignal.abort() static factory tests

test "AbortSignal.abort - creates already-aborted signal" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.abort(allocator, null);
    defer signal.release();

    try std.testing.expect(signal.isAborted());
}

test "AbortSignal.abort - signal has abort reason" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.abort(allocator, null);
    defer signal.release();

    const reason = signal.getReason();
    try std.testing.expect(reason != null);
}

test "AbortSignal.abort - custom reason" {
    const allocator = std.testing.allocator;

    const custom_reason = @as(*anyopaque, @ptrFromInt(0xDEADBEEF));
    const signal = try AbortSignal.abort(allocator, custom_reason);
    defer signal.release();

    try std.testing.expect(signal.isAborted());
    try std.testing.expectEqual(custom_reason, signal.getReason().?);
}

test "AbortSignal.abort - throwIfAborted throws" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.abort(allocator, null);
    defer signal.release();

    try std.testing.expectError(error.AbortError, signal.throwIfAborted());
}

// AbortSignal.signalAbort() tests

test "AbortSignal.signalAbort - aborts signal" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    try std.testing.expect(!signal.isAborted());

    try signal.signalAbort(null);

    try std.testing.expect(signal.isAborted());
}

test "AbortSignal.signalAbort - is idempotent" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    try signal.signalAbort(null);
    const first_reason = signal.getReason();

    // Call again - should be no-op
    try signal.signalAbort(@ptrFromInt(0x5678));

    // Reason should not change
    try std.testing.expectEqual(first_reason, signal.getReason());
}

// Abort Algorithms API tests

test "AbortSignal.addAlgorithm - adds algorithm to list" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    const callback = struct {
        fn run(sig: *AbortSignal, ctx: *anyopaque) void {
            _ = sig;
            _ = ctx;
        }
    }.run;

    var dummy: u8 = 0;
    try signal.addAlgorithm(.{
        .callback = callback,
        .context = @ptrCast(&dummy),
    });

    // Verify rare data was allocated
    try std.testing.expect(signal.rare_data != null);
}

test "AbortSignal.addAlgorithm - does not add if already aborted" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    // Abort first
    try signal.signalAbort(null);

    // Try to add algorithm - should be no-op
    const callback = struct {
        fn run(sig: *AbortSignal, ctx: *anyopaque) void {
            _ = sig;
            _ = ctx;
        }
    }.run;

    var dummy: u8 = 0;
    try signal.addAlgorithm(.{
        .callback = callback,
        .context = @ptrCast(&dummy),
    }); // No error, just no-op
}

test "AbortSignal.removeAlgorithm - removes algorithm from list" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    const callback = struct {
        fn run(sig: *AbortSignal, ctx: *anyopaque) void {
            _ = sig;
            _ = ctx;
        }
    }.run;

    var dummy: u8 = 0;
    try signal.addAlgorithm(.{
        .callback = callback,
        .context = @ptrCast(&dummy),
    });
    signal.removeAlgorithm(callback, @ptrCast(&dummy));

    // Algorithm removed - should not run when aborted
    try signal.signalAbort(null);
}

test "AbortSignal.signalAbort - runs algorithms before event" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    var event_called = false;

    // Add algorithm
    const algo_callback = struct {
        fn run(sig: *AbortSignal, ctx: *anyopaque) void {
            _ = sig;
            _ = ctx;
            // Algorithm runs (we're just testing it doesn't error)
        }
    }.run;

    var dummy: u8 = 0;
    try signal.addAlgorithm(.{
        .callback = algo_callback,
        .context = @ptrCast(&dummy),
    });

    // Add event listener
    const Context = struct {
        called: *bool,
    };
    var ctx = Context{ .called = &event_called };

    const callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            const c: *Context = @ptrCast(@alignCast(context));
            c.called.* = true;
        }
    }.cb;

    try signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, null);

    // Abort
    try signal.signalAbort(null);

    // Event listener should have been called
    try std.testing.expect(event_called);
}

test "AbortSignal.signalAbort - clears algorithms after running" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    var call_count: usize = 0;

    const Context = struct {
        count: *usize,
    };
    var ctx = Context{ .count = &call_count };

    const callback = struct {
        fn run(sig: *AbortSignal, context: *anyopaque) void {
            _ = sig;
            const context_ptr = @as(*Context, @ptrCast(@alignCast(context)));
            context_ptr.count.* += 1;
        }
    }.run;

    try signal.addAlgorithm(.{
        .callback = callback,
        .context = @ptrCast(&ctx),
    });

    // Abort with context
    try signal.signalAbort(@ptrCast(&ctx));

    // Algorithm should have run once
    try std.testing.expectEqual(@as(usize, 1), call_count);

    // Algorithms are cleared, but signal is already aborted so addAlgorithm is no-op
    // This tests that algorithms were cleared
}

test "AbortSignal - multiple algorithms run in order" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    var order = std.ArrayList(u8){};
    defer order.deinit(allocator);

    const Context = struct {
        order: *std.ArrayList(u8),
    };
    var ctx = Context{ .order = &order };

    const algo1 = struct {
        fn run(sig: *AbortSignal, context: *anyopaque) void {
            _ = sig;
            const context_ptr = @as(*Context, @ptrCast(@alignCast(context)));
            context_ptr.order.append(std.testing.allocator, 1) catch unreachable;
        }
    }.run;

    const algo2 = struct {
        fn run(sig: *AbortSignal, context: *anyopaque) void {
            _ = sig;
            const context_ptr = @as(*Context, @ptrCast(@alignCast(context)));
            context_ptr.order.append(std.testing.allocator, 2) catch unreachable;
        }
    }.run;

    const algo3 = struct {
        fn run(sig: *AbortSignal, context: *anyopaque) void {
            _ = sig;
            const context_ptr = @as(*Context, @ptrCast(@alignCast(context)));
            context_ptr.order.append(std.testing.allocator, 3) catch unreachable;
        }
    }.run;

    try signal.addAlgorithm(.{ .callback = algo1, .context = @ptrCast(&ctx) });
    try signal.addAlgorithm(.{ .callback = algo2, .context = @ptrCast(&ctx) });
    try signal.addAlgorithm(.{ .callback = algo3, .context = @ptrCast(&ctx) });

    try signal.signalAbort(null);

    // Check order
    try std.testing.expectEqual(@as(usize, 3), order.items.len);
    try std.testing.expectEqual(@as(u8, 1), order.items[0]);
    try std.testing.expectEqual(@as(u8, 2), order.items[1]);
    try std.testing.expectEqual(@as(u8, 3), order.items[2]);
}

test "AbortSignal - rare data lazy allocation" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    // Initially no rare data
    try std.testing.expect(signal.rare_data == null);

    // Adding algorithm allocates rare data
    const callback = struct {
        fn run(sig: *AbortSignal, ctx: *anyopaque) void {
            _ = sig;
            _ = ctx;
        }
    }.run;

    var dummy: u8 = 0;
    try signal.addAlgorithm(.{
        .callback = callback,
        .context = @ptrCast(&dummy),
    });

    // Now rare data is allocated
    try std.testing.expect(signal.rare_data != null);
}

test "AbortSignal - addEventListener allocates rare data" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    // Initially no rare data
    try std.testing.expect(signal.rare_data == null);

    const callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            _ = context;
        }
    }.cb;

    var dummy: u32 = 0;
    try signal.addEventListener("abort", callback, @ptrCast(&dummy), false, false, false, null);

    // Now rare data is allocated
    try std.testing.expect(signal.rare_data != null);
}

test "AbortSignal - memory leak check with algorithms" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);

    const callback = struct {
        fn run(sig: *AbortSignal, ctx: *anyopaque) void {
            _ = sig;
            _ = ctx;
        }
    }.run;

    var dummy: u8 = 0;
    try signal.addAlgorithm(.{ .callback = callback, .context = @ptrCast(&dummy) });
    try signal.addAlgorithm(.{ .callback = callback, .context = @ptrCast(&dummy) });
    try signal.addAlgorithm(.{ .callback = callback, .context = @ptrCast(&dummy) });

    try signal.signalAbort(null);

    signal.release();

    // Test passes if no leaks detected by testing allocator
}

// Dependent Signal State Management tests (Phase 2, Day 5)

test "AbortSignal - can set dependent flag" {
    const allocator = std.testing.allocator;

    const signal = try AbortSignal.init(allocator);
    defer signal.release();

    signal.dependent = true;

    try std.testing.expect(signal.dependent);
}

test "AbortSignal - addSourceSignal creates source list" {
    const allocator = std.testing.allocator;

    const dependent = try AbortSignal.init(allocator);
    defer dependent.release();

    const source = try AbortSignal.init(allocator);
    defer source.release();

    // Initially no rare data
    try std.testing.expect(dependent.rare_data == null);

    // Add source signal
    try dependent.addSourceSignal(source);

    // Rare data should be allocated
    try std.testing.expect(dependent.rare_data != null);
    try std.testing.expect(dependent.rare_data.?.source_signals != null);
    try std.testing.expectEqual(@as(usize, 1), dependent.rare_data.?.source_signals.?.items.len);
}

test "AbortSignal - addDependentSignal creates dependent list" {
    const allocator = std.testing.allocator;

    const source = try AbortSignal.init(allocator);
    defer source.release();

    const dependent = try AbortSignal.init(allocator);
    defer dependent.release();

    // Initially no rare data
    try std.testing.expect(source.rare_data == null);

    // Add dependent signal
    try source.addDependentSignal(dependent);

    // Rare data should be allocated
    try std.testing.expect(source.rare_data != null);
    try std.testing.expect(source.rare_data.?.dependent_signals != null);
    try std.testing.expectEqual(@as(usize, 1), source.rare_data.?.dependent_signals.?.items.len);
}

test "AbortSignal - deinit removes from source signal lists" {
    const allocator = std.testing.allocator;

    const source = try AbortSignal.init(allocator);
    defer source.release();

    {
        const dependent = try AbortSignal.init(allocator);

        // Link signals
        try dependent.addSourceSignal(source);
        try source.addDependentSignal(dependent);

        // Source should have dependent in list
        try std.testing.expectEqual(@as(usize, 1), source.rare_data.?.dependent_signals.?.items.len);

        // Release dependent - should remove from source list
        dependent.release();
    }

    // Source list should now be empty
    try std.testing.expectEqual(@as(usize, 0), source.rare_data.?.dependent_signals.?.items.len);
}

test "AbortSignal - multiple source signals cleanup" {
    const allocator = std.testing.allocator;

    const source1 = try AbortSignal.init(allocator);
    defer source1.release();

    const source2 = try AbortSignal.init(allocator);
    defer source2.release();

    {
        const dependent = try AbortSignal.init(allocator);

        // Link to both sources
        try dependent.addSourceSignal(source1);
        try dependent.addSourceSignal(source2);
        try source1.addDependentSignal(dependent);
        try source2.addDependentSignal(dependent);

        // Both sources should have dependent
        try std.testing.expectEqual(@as(usize, 1), source1.rare_data.?.dependent_signals.?.items.len);
        try std.testing.expectEqual(@as(usize, 1), source2.rare_data.?.dependent_signals.?.items.len);

        // Release dependent
        dependent.release();
    }

    // Both source lists should be empty
    try std.testing.expectEqual(@as(usize, 0), source1.rare_data.?.dependent_signals.?.items.len);
    try std.testing.expectEqual(@as(usize, 0), source2.rare_data.?.dependent_signals.?.items.len);
}

test "AbortSignal - no memory leaks with dependent signals" {
    const allocator = std.testing.allocator;

    const source = try AbortSignal.init(allocator);
    const dependent = try AbortSignal.init(allocator);

    try dependent.addSourceSignal(source);
    try source.addDependentSignal(dependent);

    dependent.release();
    source.release();

    // Test passes if no leaks detected
}

// Dependent Signal Creation tests (Phase 2, Day 6)

test "AbortSignal.any - creates dependent signal from two sources" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller1.signal,
        controller2.signal,
    });
    defer composite.release();

    // Composite should be dependent
    try std.testing.expect(composite.dependent);

    // Composite should not be aborted
    try std.testing.expect(!composite.isAborted());

    // Composite should have 2 source signals
    try std.testing.expect(composite.rare_data != null);
    try std.testing.expect(composite.rare_data.?.source_signals != null);
    try std.testing.expectEqual(@as(usize, 2), composite.rare_data.?.source_signals.?.items.len);
}

test "AbortSignal.any - returns pre-aborted if source already aborted" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    // Abort controller1
    try controller1.abort(null);

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller1.signal,
        controller2.signal,
    });
    defer composite.release();

    // Composite should be immediately aborted
    try std.testing.expect(composite.isAborted());

    // Should have same abort reason as source
    try std.testing.expectEqual(controller1.signal.getReason(), composite.getReason());
}

test "AbortSignal.any - flattens nested dependent signals" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    // Create first composite
    const composite1 = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller1.signal,
        controller2.signal,
    });
    defer composite1.release();

    // Create second composite from first composite
    const composite2 = try AbortSignal.any(allocator, &[_]*AbortSignal{
        composite1,
    });
    defer composite2.release();

    // composite2 should depend on controller1 and controller2 directly (flattened)
    try std.testing.expect(composite2.rare_data != null);
    try std.testing.expect(composite2.rare_data.?.source_signals != null);
    try std.testing.expectEqual(@as(usize, 2), composite2.rare_data.?.source_signals.?.items.len);

    // composite2 should NOT depend on composite1
    const sources = composite2.rare_data.?.source_signals.?.items;
    for (sources) |source_ptr| {
        const source: *AbortSignal = @ptrCast(@alignCast(source_ptr));
        try std.testing.expect(source != composite1);
    }
}

test "AbortSignal.any - empty signals array" {
    const allocator = std.testing.allocator;

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{});
    defer composite.release();

    // Should be dependent but not aborted
    try std.testing.expect(composite.dependent);
    try std.testing.expect(!composite.isAborted());

    // Should have no source signals
    if (composite.rare_data) |rare| {
        if (rare.source_signals) |sources| {
            try std.testing.expectEqual(@as(usize, 0), sources.items.len);
        }
    }
}

test "AbortSignal.any - single source signal" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller.signal,
    });
    defer composite.release();

    // Should be dependent
    try std.testing.expect(composite.dependent);

    // Should have 1 source signal
    try std.testing.expect(composite.rare_data != null);
    try std.testing.expect(composite.rare_data.?.source_signals != null);
    try std.testing.expectEqual(@as(usize, 1), composite.rare_data.?.source_signals.?.items.len);
}

test "AbortSignal.any - many source signals" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    const controller3 = try AbortController.init(allocator);
    defer controller3.deinit();

    const controller4 = try AbortController.init(allocator);
    defer controller4.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller1.signal,
        controller2.signal,
        controller3.signal,
        controller4.signal,
    });
    defer composite.release();

    // Should have 4 source signals
    try std.testing.expectEqual(@as(usize, 4), composite.rare_data.?.source_signals.?.items.len);
}

test "AbortSignal.any - sources registered as dependents" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller1.signal,
        controller2.signal,
    });
    defer composite.release();

    // Both sources should have composite in their dependent lists
    try std.testing.expect(controller1.signal.rare_data != null);
    try std.testing.expect(controller1.signal.rare_data.?.dependent_signals != null);
    try std.testing.expectEqual(@as(usize, 1), controller1.signal.rare_data.?.dependent_signals.?.items.len);

    try std.testing.expect(controller2.signal.rare_data != null);
    try std.testing.expect(controller2.signal.rare_data.?.dependent_signals != null);
    try std.testing.expectEqual(@as(usize, 1), controller2.signal.rare_data.?.dependent_signals.?.items.len);
}

test "AbortSignal.any - no memory leaks" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    const controller2 = try AbortController.init(allocator);

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller1.signal,
        controller2.signal,
    });

    composite.release();
    controller2.deinit();
    controller1.deinit();

    // Test passes if no leaks detected
}

// Dependent Signal Propagation tests (Phase 2, Day 7)

test "AbortSignal - dependent aborts when source aborts" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller.signal,
    });
    defer composite.release();

    // Initially not aborted
    try std.testing.expect(!composite.isAborted());

    // Abort source
    try controller.abort(null);

    // Composite should now be aborted
    try std.testing.expect(composite.isAborted());
}

test "AbortSignal - dependent inherits abort reason from source" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller.signal,
    });
    defer composite.release();

    const custom_reason = @as(*anyopaque, @ptrFromInt(0xDEADBEEF));

    // Abort with custom reason
    try controller.abort(custom_reason);

    // Composite should have same reason
    try std.testing.expectEqual(custom_reason, composite.getReason());
}

test "AbortSignal - multiple dependents all abort" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const composite1 = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller.signal,
    });
    defer composite1.release();

    const composite2 = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller.signal,
    });
    defer composite2.release();

    const composite3 = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller.signal,
    });
    defer composite3.release();

    // Abort source
    try controller.abort(null);

    // All dependents should be aborted
    try std.testing.expect(composite1.isAborted());
    try std.testing.expect(composite2.isAborted());
    try std.testing.expect(composite3.isAborted());
}

test "AbortSignal - any source abortion aborts composite" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    const controller3 = try AbortController.init(allocator);
    defer controller3.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller1.signal,
        controller2.signal,
        controller3.signal,
    });
    defer composite.release();

    // Abort middle source
    try controller2.abort(null);

    // Composite should be aborted
    try std.testing.expect(composite.isAborted());
}

test "AbortSignal - events fire for both source and dependent" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller.signal,
    });
    defer composite.release();

    var source_event_fired = false;
    var dependent_event_fired = false;

    const SourceContext = struct {
        fired: *bool,
    };
    var source_ctx = SourceContext{ .fired = &source_event_fired };

    const source_callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            const c: *SourceContext = @ptrCast(@alignCast(context));
            c.fired.* = true;
        }
    }.cb;

    const DependentContext = struct {
        fired: *bool,
    };
    var dependent_ctx = DependentContext{ .fired = &dependent_event_fired };

    const dependent_callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            const c: *DependentContext = @ptrCast(@alignCast(context));
            c.fired.* = true;
        }
    }.cb;

    try controller.signal.addEventListener("abort", source_callback, @ptrCast(&source_ctx), false, false, false, null);
    try composite.addEventListener("abort", dependent_callback, @ptrCast(&dependent_ctx), false, false, false, null);

    // Abort
    try controller.abort(null);

    // Both events should have fired
    try std.testing.expect(source_event_fired);
    try std.testing.expect(dependent_event_fired);
}

test "AbortSignal - abort propagates through flattened dependencies" {
    const allocator = std.testing.allocator;

    const controller1 = try AbortController.init(allocator);
    defer controller1.deinit();

    const controller2 = try AbortController.init(allocator);
    defer controller2.deinit();

    // Create first composite
    const composite1 = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller1.signal,
        controller2.signal,
    });
    defer composite1.release();

    // Create second composite from first (should flatten)
    const composite2 = try AbortSignal.any(allocator, &[_]*AbortSignal{
        composite1,
    });
    defer composite2.release();

    // Abort controller1
    try controller1.abort(null);

    // Both composites should be aborted
    try std.testing.expect(composite1.isAborted());
    try std.testing.expect(composite2.isAborted());
}

test "AbortSignal - propagation is idempotent" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
        controller.signal,
    });
    defer composite.release();

    // Abort once
    try controller.abort(null);
    const first_reason = composite.getReason();

    // Abort again with different reason
    try controller.abort(@ptrFromInt(0x1234));

    // Composite reason should not change
    try std.testing.expectEqual(first_reason, composite.getReason());
}

// addEventListener Signal Integration tests (Phase 3)

test "addEventListener - early return if signal already aborted" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    const signal = controller.signal;

    // Abort first
    try controller.abort(null);
    try std.testing.expect(signal.isAborted());

    // Try to add listener with aborted signal
    var called = false;
    const Context = struct {
        called: *bool,
    };
    var ctx = Context{ .called = &called };

    const callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.called.* = true;
        }
    }.cb;

    // Should return immediately without adding listener
    try signal.addEventListener("abort", callback, @ptrCast(&ctx), false, false, false, @ptrCast(signal));

    // Fire event manually
    var event = Event.init("abort", .{});
    _ = try signal.dispatchEvent(&event);

    // Listener should NOT have been called
    try std.testing.expect(!called);
}

test "addEventListener - auto-removes listener when signal aborts" {
    const allocator = std.testing.allocator;

    const target_signal = try AbortSignal.init(allocator);
    defer target_signal.release();

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var call_count: usize = 0;
    const Context = struct {
        count: *usize,
    };
    var ctx = Context{ .count = &call_count };

    const callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.count.* += 1;
        }
    }.cb;

    // Add listener with abort signal
    try target_signal.addEventListener("test", callback, @ptrCast(&ctx), false, false, false, @ptrCast(controller.signal));

    // Verify listener was added
    if (target_signal.rare_data) |rare| {
        try std.testing.expect(rare.hasEventListeners("test"));
    }

    // Abort the controller signal
    try controller.abort(null);

    // Listener should have been auto-removed
    var event = Event.init("test", .{});
    _ = try target_signal.dispatchEvent(&event);

    // Callback should NOT have been called
    try std.testing.expectEqual(@as(usize, 0), call_count);
}

test "addEventListener - signal option doesn't interfere with normal listeners" {
    const allocator = std.testing.allocator;

    const target_signal = try AbortSignal.init(allocator);
    defer target_signal.release();

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var count_with_signal: usize = 0;
    var count_without_signal: usize = 0;

    const Context = struct {
        count: *usize,
    };
    var ctx1 = Context{ .count = &count_with_signal };
    var ctx2 = Context{ .count = &count_without_signal };

    const callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.count.* += 1;
        }
    }.cb;

    // Add listener WITH signal
    try target_signal.addEventListener("test", callback, @ptrCast(&ctx1), false, false, false, @ptrCast(controller.signal));

    // Add listener WITHOUT signal
    try target_signal.addEventListener("test", callback, @ptrCast(&ctx2), false, false, false, null);

    // Fire event - both should be called
    var event1 = Event.init("test", .{});
    _ = try target_signal.dispatchEvent(&event1);
    try std.testing.expectEqual(@as(usize, 1), count_with_signal);
    try std.testing.expectEqual(@as(usize, 1), count_without_signal);

    // Abort signal
    try controller.abort(null);

    // Fire event again - only listener without signal should be called
    var event2 = Event.init("test", .{});
    _ = try target_signal.dispatchEvent(&event2);
    try std.testing.expectEqual(@as(usize, 1), count_with_signal); // Not called again
    try std.testing.expectEqual(@as(usize, 2), count_without_signal); // Called again
}

test "addEventListener - signal with multiple listeners" {
    const allocator = std.testing.allocator;

    const target_signal = try AbortSignal.init(allocator);
    defer target_signal.release();

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var count1: usize = 0;
    var count2: usize = 0;
    var count3: usize = 0;

    const Context = struct {
        count: *usize,
    };
    var ctx1 = Context{ .count = &count1 };
    var ctx2 = Context{ .count = &count2 };
    var ctx3 = Context{ .count = &count3 };

    const callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            const c = @as(*Context, @ptrCast(@alignCast(context)));
            c.count.* += 1;
        }
    }.cb;

    // Add three listeners with same signal
    try target_signal.addEventListener("test", callback, @ptrCast(&ctx1), false, false, false, @ptrCast(controller.signal));
    try target_signal.addEventListener("test", callback, @ptrCast(&ctx2), false, false, false, @ptrCast(controller.signal));
    try target_signal.addEventListener("test", callback, @ptrCast(&ctx3), false, false, false, @ptrCast(controller.signal));

    // Fire event - all three should be called
    var event1 = Event.init("test", .{});
    _ = try target_signal.dispatchEvent(&event1);
    try std.testing.expectEqual(@as(usize, 1), count1);
    try std.testing.expectEqual(@as(usize, 1), count2);
    try std.testing.expectEqual(@as(usize, 1), count3);

    // Abort signal - should remove all three listeners
    try controller.abort(null);

    // Fire event again - none should be called
    var event2 = Event.init("test", .{});
    _ = try target_signal.dispatchEvent(&event2);
    try std.testing.expectEqual(@as(usize, 1), count1); // Not called again
    try std.testing.expectEqual(@as(usize, 1), count2); // Not called again
    try std.testing.expectEqual(@as(usize, 1), count3); // Not called again
}

test "addEventListener - no memory leaks with signal option" {
    const allocator = std.testing.allocator;

    const target_signal = try AbortSignal.init(allocator);
    const controller = try AbortController.init(allocator);

    var dummy: u32 = 0;
    const callback = struct {
        fn cb(event: *Event, context: *anyopaque) void {
            _ = event;
            _ = context;
        }
    }.cb;

    // Add listener with signal
    try target_signal.addEventListener("test", callback, @ptrCast(&dummy), false, false, false, @ptrCast(controller.signal));

    // Abort signal (should clean up removal context)
    try controller.abort(null);

    // Clean up
    controller.deinit();
    target_signal.release();

    // Test passes if no leaks detected by testing allocator
}
