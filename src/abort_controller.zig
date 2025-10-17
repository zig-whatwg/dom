//! AbortController Interface (§3.2)
//!
//! This module implements the AbortController interface as specified by the WHATWG DOM Standard.
//! AbortController provides a simple way to create and control an AbortSignal, enabling
//! cancellation of asynchronous operations. It's the primary interface users interact with
//! to signal abort requests.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§3.2 Interface AbortController**: https://dom.spec.whatwg.org/#interface-abortcontroller
//! - **§3.1 Interface AbortSignal**: https://dom.spec.whatwg.org/#interface-abortsignal
//! - **§3.2.1 Aborting**: https://dom.spec.whatwg.org/#aborting
//!
//! ## MDN Documentation
//!
//! - AbortController: https://developer.mozilla.org/en-US/docs/Web/API/AbortController
//! - AbortController(): https://developer.mozilla.org/en-US/docs/Web/API/AbortController/AbortController
//! - AbortController.signal: https://developer.mozilla.org/en-US/docs/Web/API/AbortController/signal
//! - AbortController.abort(): https://developer.mozilla.org/en-US/docs/Web/API/AbortController/abort
//! - Using AbortController: https://developer.mozilla.org/en-US/docs/Web/API/AbortController#examples
//!
//! ## Core Features
//!
//! ### Signal Access
//! Controller owns and provides access to an AbortSignal:
//! ```zig
//! const controller = try AbortController.init(allocator);
//! defer controller.deinit();
//!
//! const signal = controller.signal;
//! // signal is [SameObject] - always returns same instance
//! try std.testing.expect(controller.signal == signal);
//! ```
//!
//! ### Aborting Operations
//! Trigger abort with optional reason:
//! ```zig
//! const controller = try AbortController.init(allocator);
//! defer controller.deinit();
//!
//! // Abort with default reason ("AbortError")
//! try controller.abort(null);
//!
//! // Abort with custom reason
//! const reason = try DOMException.create(allocator, "TimeoutError", "Request timeout");
//! try controller.abort(reason);
//! ```
//!
//! ### Passing to Operations
//! Share signal with operations that support cancellation:
//! ```zig
//! const controller = try AbortController.init(allocator);
//! defer controller.deinit();
//!
//! // Pass signal to async operation
//! const result = fetchWithAbort("https://api.example.com", controller.signal);
//!
//! // User cancels
//! try controller.abort(null);
//! // Operation receives abort notification via signal
//! ```
//!
//! ## AbortController Structure
//!
//! AbortController is a simple wrapper around AbortSignal:
//! - **allocator**: Memory allocator (16 bytes)
//! - **signal**: Owned AbortSignal pointer (8 bytes)
//!
//! Total size: 24 bytes (very lightweight)
//!
//! **Key Properties:**
//! - Owns the AbortSignal (created in init, freed in deinit)
//! - signal attribute is [SameObject] (always returns same instance)
//! - Controller can only abort once (signal.aborted becomes immutable)
//! - Abort is synchronous (listeners fire immediately)
//!
//! ## Memory Management
//!
//! AbortController owns its signal and uses explicit deinit:
//! ```zig
//! const controller = try AbortController.init(allocator);
//! defer controller.deinit(); // Frees signal and controller
//!
//! // Signal is owned by controller
//! // Do NOT call signal.deinit() separately
//! ```
//!
//! **Important:**
//! - Controller owns the signal (creates it, frees it)
//! - Use defer controller.deinit() for cleanup
//! - Signal may outlive controller if user has references (not typical)
//! - Do NOT manually free controller.signal (controller owns it)
//!
//! ## Usage Examples
//!
//! ### Basic Cancellation
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! const controller = try AbortController.init(allocator);
//! defer controller.deinit();
//!
//! // Start operation
//! const fetch_thread = try std.Thread.spawn(.{}, fetchData, .{url, controller.signal});
//!
//! // User clicks cancel button
//! try controller.abort(null);
//!
//! // Operation receives abort signal and stops
//! fetch_thread.join();
//! ```
//!
//! ### Timeout Pattern
//! ```zig
//! fn fetchWithTimeout(url: []const u8, timeout_ms: u32, allocator: Allocator) ![]u8 {
//!     const controller = try AbortController.init(allocator);
//!     defer controller.deinit();
//!
//!     // Start timeout timer
//!     const timer_thread = try std.Thread.spawn(.{}, timerFunc, .{controller, timeout_ms});
//!     defer timer_thread.join();
//!
//!     // Start fetch with signal
//!     return try fetchWithAbort(url, controller.signal);
//! }
//!
//! fn timerFunc(controller: *AbortController, timeout_ms: u32) void {
//!     std.time.sleep(timeout_ms * std.time.ns_per_ms);
//!     controller.abort(null) catch {};
//! }
//! ```
//!
//! ### Multiple Operations, Single Controller
//! ```zig
//! fn fetchMultiple(urls: []const []const u8, allocator: Allocator) !void {
//!     const controller = try AbortController.init(allocator);
//!     defer controller.deinit();
//!
//!     // All operations share the same signal
//!     for (urls) |url| {
//!         const thread = try std.Thread.spawn(.{}, fetchWithAbort, .{url, controller.signal});
//!         // ... store threads ...
//!     }
//!
//!     // Single abort cancels ALL operations
//!     try controller.abort(null);
//! }
//! ```
//!
//! ## Common Patterns
//!
//! ### User-Initiated Cancellation
//! ```zig
//! const State = struct {
//!     controller: ?*AbortController = null,
//! };
//!
//! fn startOperation(state: *State, allocator: Allocator) !void {
//!     state.controller = try AbortController.init(allocator);
//!     // ... start async work with state.controller.signal ...
//! }
//!
//! fn cancelOperation(state: *State) !void {
//!     if (state.controller) |controller| {
//!         try controller.abort(null);
//!     }
//! }
//! ```
//!
//! ### Cleanup on Abort
//! ```zig
//! fn operationWithCleanup(controller: *AbortController, allocator: Allocator) !void {
//!     const resource = try allocator.alloc(u8, 1024);
//!     errdefer allocator.free(resource);
//!
//!     // Register cleanup on abort
//!     const cleanup = struct {
//!         fn run(signal: *AbortSignal, ctx: *anyopaque) void {
//!             _ = signal;
//!             const res = @as(*[]u8, @ptrCast(@alignCast(ctx)));
//!             allocator.free(res.*);
//!         }
//!     }.run;
//!
//!     try controller.signal.addAbortAlgorithm(cleanup, &resource);
//!
//!     // Do work...
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Reuse Controllers** - For sequential operations, create once and reuse if possible
//! 2. **Share Signals** - Pass signal to multiple operations instead of creating multiple controllers
//! 3. **Defer Cleanup** - Always use defer controller.deinit() for guaranteed cleanup
//! 4. **Abort Early** - Call abort() as soon as cancellation is requested
//! 5. **Lightweight** - Controller is only 24 bytes, cheap to create
//! 6. **Synchronous Abort** - abort() is synchronous, listeners fire immediately
//!
//! ## JavaScript Bindings
//!
//! ### AbortController Constructor
//! ```javascript
//! // Create new controller
//! const controller = new AbortController();
//!
//! // In bindings implementation:
//! function AbortController() {
//!   this._ptr = zig.abortcontroller_init();
//! }
//! ```
//!
//! ### Instance Properties
//! ```javascript
//! // signal (readonly) - [SameObject] per WebIDL
//! Object.defineProperty(AbortController.prototype, 'signal', {
//!   get: function() { return zig.abortcontroller_get_signal(this._ptr); }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // abort(reason) - Abort the signal with optional reason
//! AbortController.prototype.abort = function(reason) {
//!   zig.abortcontroller_abort(this._ptr, reason);
//! };
//! ```
//!
//! ### Usage Examples
//! ```javascript
//! // Basic usage
//! const controller = new AbortController();
//! const signal = controller.signal;
//!
//! // Use signal with fetch (or other abortable operation)
//! fetch('/api/data', { signal })
//!   .then(response => response.json())
//!   .then(data => console.log(data))
//!   .catch(err => {
//!     if (err.name === 'AbortError') {
//!       console.log('Fetch aborted');
//!     }
//!   });
//!
//! // Abort after timeout
//! setTimeout(() => {
//!   controller.abort('Timeout');
//! }, 5000);
//!
//! // Abort with custom reason
//! const abortButton = document.getElementById('abort');
//! abortButton.addEventListener('click', () => {
//!   controller.abort(new Error('User cancelled'));
//! });
//!
//! // Multiple operations with one signal
//! const multiController = new AbortController();
//! const multiSignal = multiController.signal;
//!
//! // All operations share the same signal
//! fetch('/api/data1', { signal: multiSignal });
//! fetch('/api/data2', { signal: multiSignal });
//! fetch('/api/data3', { signal: multiSignal });
//!
//! // One abort cancels all
//! multiController.abort();
//!
//! // Check signal state
//! console.log('Aborted:', controller.signal.aborted);
//! console.log('Reason:', controller.signal.reason);
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - AbortController owns the AbortSignal (creates and frees it)
//! - signal attribute is [SameObject] per WebIDL (always returns same pointer)
//! - abort() can be called multiple times (only first call has effect)
//! - Default abort reason is DOMException("AbortError")
//! - Controller size is 24 bytes (allocator + signal pointer)
//! - Not reference counted (use explicit deinit())
//! - Signal may outlive controller if external references exist (rare)
//! - Thread-safety not guaranteed (single-threaded by default)

const std = @import("std");
const Allocator = std.mem.Allocator;
const AbortSignal = @import("abort_signal.zig").AbortSignal;

/// AbortController - Controls an AbortSignal.
///
/// Implements WHATWG DOM AbortController interface per §3.2.
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
