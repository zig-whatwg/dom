const std = @import("std");
const Allocator = std.mem.Allocator;
const AbortSignal = @import("abort_signal.zig").AbortSignal;

/// AbortController - Controls an AbortSignal.
///
/// Implements WHATWG DOM AbortController interface per §3.1.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=*]
/// interface AbortController {
///   constructor();
///   [SameObject] readonly attribute AbortSignal signal;
///   undefined abort(optional any reason);
/// };
/// ```
///
/// ## Memory Management
/// - Owns the AbortSignal (creates on init)
/// - Calls signal.release() on deinit
/// - Signal may outlive controller if user acquired additional references
///
/// ## Example
/// ```zig
/// const controller = try AbortController.init(allocator);
/// defer controller.deinit();
///
/// // Get signal (same object every time per [SameObject])
/// const signal = controller.signal;
///
/// // Pass signal to async operation
/// try fetchData(url, signal);
///
/// // Later, abort the operation
/// try controller.abort(null);
/// ```
///
/// ## Spec References
/// - Interface: https://dom.spec.whatwg.org/#interface-abortcontroller
/// - Algorithm: https://dom.spec.whatwg.org/#abortcontroller-signal-abort
/// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
pub const AbortController = struct {
    /// Memory allocator (16 bytes: ptr + vtable)
    allocator: Allocator,

    /// Owned AbortSignal (8 bytes)
    /// - Created in init()
    /// - [SameObject] per WebIDL (always returns same instance)
    /// - Controller owns initial reference (does NOT call acquire)
    /// - Calls release() in deinit()
    signal: *AbortSignal,

    // Total size: 24 bytes (very small!)

    /// Creates a new AbortController with a fresh AbortSignal.
    ///
    /// Implements WHATWG DOM AbortController() constructor per §3.1.
    ///
    /// ## Algorithm
    /// Per spec: "The new AbortController() constructor steps are:
    /// 1. Let signal be a new AbortSignal object
    /// 2. Set this's signal to signal"
    ///
    /// ## Memory Management
    /// - Creates AbortSignal with ref_count = 1
    /// - Controller owns this reference
    /// - Calls signal.release() in deinit()
    ///
    /// ## Returns
    /// New controller with owned signal
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate controller or signal
    ///
    /// ## Example
    /// ```zig
    /// const controller = try AbortController.init(allocator);
    /// defer controller.deinit();
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-abortcontroller-abortcontroller
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
    pub fn init(allocator: Allocator) !*AbortController {
        const controller = try allocator.create(AbortController);
        errdefer allocator.destroy(controller);

        // Create owned signal (ref_count = 1)
        const signal = try AbortSignal.init(allocator);
        errdefer signal.release();

        controller.* = .{
            .allocator = allocator,
            .signal = signal,
        };

        return controller;
    }

    /// Destroys the controller and releases the signal.
    ///
    /// Releases the owned signal reference. Signal may continue to exist
    /// if other references were acquired.
    ///
    /// ## Example
    /// ```zig
    /// const controller = try AbortController.init(allocator);
    /// defer controller.deinit(); // Safe cleanup
    /// ```
    pub fn deinit(self: *AbortController) void {
        // Release owned signal reference
        self.signal.release();

        // Free controller
        self.allocator.destroy(self);
    }

    /// Aborts the controller's signal with an optional reason.
    ///
    /// Implements WHATWG DOM AbortController.abort() per §3.1.2.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined abort(optional any reason);
    /// ```
    ///
    /// ## Algorithm
    /// Per spec: "The abort(reason) method steps are to signal abort on this's
    /// signal with reason if it is given."
    ///
    /// ## Parameters
    /// - `reason`: Optional abort reason (JavaScript "any" type)
    ///   - null = use default reason (treated as "AbortError")
    ///   - non-null = custom reason (DOMException, string, etc.)
    ///
    /// ## Side Effects
    /// - Sets signal.abort_reason (if not already aborted)
    /// - Runs all abort algorithms
    /// - Fires "abort" event
    /// - Propagates to dependent signals
    ///
    /// ## Example
    /// ```zig
    /// // Abort with default reason
    /// try controller.abort(null);
    ///
    /// // Abort with custom reason
    /// const reason = try allocator.create(CustomError);
    /// try controller.abort(@ptrCast(reason));
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-abortcontroller-abort
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
    pub fn abort(self: *AbortController, reason: ?*anyopaque) !void {
        try self.signal.signalAbort(reason);
    }
};

// Compile-time size verification
comptime {
    const expected_size = 24;
    const actual_size = @sizeOf(AbortController);
    if (actual_size != expected_size) {
        @compileError(std.fmt.comptimePrint(
            "AbortController size mismatch: expected {d} bytes, got {d} bytes",
            .{ expected_size, actual_size },
        ));
    }
}
