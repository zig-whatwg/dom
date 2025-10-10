//! AbortController Interface - WHATWG DOM Standard §3.1
//! =====================================================
//!
//! AbortController provides a way to abort one or more asynchronous operations.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-abortcontroller
//! - **Section**: §3.1 Interface AbortController
//!
//! ## MDN Documentation
//! - **AbortController**: https://developer.mozilla.org/en-US/docs/Web/API/AbortController
//! - **signal**: https://developer.mozilla.org/en-US/docs/Web/API/AbortController/signal
//! - **abort()**: https://developer.mozilla.org/en-US/docs/Web/API/AbortController/abort
//!
//! ## Overview
//!
//! AbortController allows you to abort one or more Web requests as and when desired.
//! It provides a signal property which can be passed to abortable operations, and
//! an abort() method to signal cancellation.
//!
//! ## Usage Examples
//!
//! ### Basic Abort Pattern
//! ```zig
//! const controller = try AbortController.init(allocator);
//! defer controller.deinit();
//!
//! // Pass signal to async operation
//! doAsyncWork(controller.signal);
//!
//! // Later, abort if needed
//! controller.abort();
//! ```
//!
//! ### With Reason
//! ```zig
//! const controller = try AbortController.init(allocator);
//! defer controller.deinit();
//!
//! // Abort with a specific reason
//! try controller.abortWithReason("Request timeout");
//!
//! if (controller.signal.aborted) {
//!     std.debug.print("Aborted: {s}\n", .{controller.signal.reason.?});
//! }
//! ```

const std = @import("std");
const AbortSignal = @import("abort_signal.zig").AbortSignal;

/// AbortController allows aborting asynchronous operations
///
/// ## Specification
///
/// From WHATWG DOM Standard §3.1:
/// "An AbortController object allows you to abort one or more asynchronous
/// operations."
///
/// ## Design
///
/// - Each controller owns exactly one AbortSignal
/// - Calling abort() marks the signal as aborted
/// - The signal can be passed to multiple operations
/// - Once aborted, the controller stays aborted
///
/// ## Memory Management
///
/// The controller owns its signal. Calling deinit() cleans up both.
pub const AbortController = struct {
    /// The signal associated with this controller
    signal: *AbortSignal,

    /// Memory allocator
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a new AbortController
    ///
    /// Creates a new controller with a fresh (non-aborted) signal.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the controller
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created AbortController.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const controller = try AbortController.init(allocator);
    /// defer controller.deinit();
    ///
    /// try std.testing.expect(!controller.signal.aborted);
    /// ```
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        const signal = try AbortSignal.init(allocator);
        errdefer signal.deinit();

        self.* = .{
            .signal = signal,
            .allocator = allocator,
        };

        return self;
    }

    /// Abort all operations using this controller's signal
    ///
    /// Marks the signal as aborted without a specific reason.
    /// This is equivalent to calling abortWithReason(null).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const controller = try AbortController.init(allocator);
    /// defer controller.deinit();
    ///
    /// controller.abort();
    /// try std.testing.expect(controller.signal.aborted);
    /// ```
    pub fn abort(self: *Self) void {
        self.signal.signalAbort(null) catch {};
    }

    /// Abort with a specific reason
    ///
    /// Marks the signal as aborted and stores the given reason.
    /// This allows consumers to understand why the operation was cancelled.
    ///
    /// ## Parameters
    ///
    /// - `reason`: The reason for aborting
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const controller = try AbortController.init(allocator);
    /// defer controller.deinit();
    ///
    /// try controller.abortWithReason("User cancelled request");
    /// try std.testing.expectEqualStrings("User cancelled request", controller.signal.reason.?);
    /// ```
    pub fn abortWithReason(self: *Self, reason: []const u8) !void {
        try self.signal.signalAbort(reason);
    }

    /// Clean up resources
    ///
    /// Frees the signal and all associated memory.
    pub fn deinit(self: *Self) void {
        self.signal.deinit();
        self.allocator.destroy(self);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "AbortController creation" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try std.testing.expect(!controller.signal.aborted);
    try std.testing.expect(controller.signal.reason == null);
}

test "AbortController.abort()" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    controller.abort();

    try std.testing.expect(controller.signal.aborted);
    try std.testing.expect(controller.signal.reason == null);
}

test "AbortController.abortWithReason()" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try controller.abortWithReason("Test cancellation");

    try std.testing.expect(controller.signal.aborted);
    try std.testing.expectEqualStrings("Test cancellation", controller.signal.reason.?);
}

test "AbortController abort is idempotent" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    try controller.abortWithReason("First");
    try controller.abortWithReason("Second");

    // Should keep first reason
    try std.testing.expectEqualStrings("First", controller.signal.reason.?);
}

test "AbortController signal can be shared" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    // Simulate passing signal to multiple operations
    const signal1 = controller.signal;
    const signal2 = controller.signal;

    try std.testing.expect(!signal1.aborted);
    try std.testing.expect(!signal2.aborted);

    controller.abort();

    try std.testing.expect(signal1.aborted);
    try std.testing.expect(signal2.aborted);
}

test "AbortController with event listener" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    var called = false;

    const Callback = struct {
        var was_called: *bool = undefined;

        fn onAbort(event: *@import("event.zig").Event) void {
            _ = event;
            was_called.* = true;
        }
    };
    Callback.was_called = &called;

    try controller.signal.addEventListener(Callback.onAbort);

    controller.abort();

    try std.testing.expect(called);
}

test "AbortController memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const controller = try AbortController.init(allocator);
        controller.abort();
        controller.deinit();
    }
}

test "AbortController practical example - timeout" {
    const allocator = std.testing.allocator;

    // Simulated async operation that checks abort signal
    const AsyncOp = struct {
        fn doWork(signal: *AbortSignal) !void {
            var steps: usize = 0;
            while (steps < 10) : (steps += 1) {
                // Check if operation should be cancelled
                try signal.throwIfAborted();

                // Simulate work
                // In real code, this would be actual async work
            }
        }
    };

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    // Start work and abort immediately
    controller.abort();

    // Operation should fail with Aborted error
    try std.testing.expectError(error.Aborted, AsyncOp.doWork(controller.signal));
}

test "AbortController multiple abort calls" {
    const allocator = std.testing.allocator;

    const controller = try AbortController.init(allocator);
    defer controller.deinit();

    // First abort
    controller.abort();
    try std.testing.expect(controller.signal.aborted);

    // Second abort should be safe (no-op)
    controller.abort();
    try std.testing.expect(controller.signal.aborted);

    // Third abort with reason should not change original (no) reason
    try controller.abortWithReason("New reason");
    try std.testing.expect(controller.signal.aborted);
    try std.testing.expect(controller.signal.reason == null); // Still null from first abort
}
