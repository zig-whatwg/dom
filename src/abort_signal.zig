const std = @import("std");
const Allocator = std.mem.Allocator;
const EventTargetMixin = @import("event_target.zig").EventTargetMixin;
const SignalRareData = @import("abort_signal_rare_data.zig").SignalRareData;
const Event = @import("event.zig").Event;

/// Minimal DOMException representation for abort reasons.
///
/// This is a simplified representation suitable for Zig. JavaScript bindings
/// should convert this to the appropriate DOMException object.
///
/// Per WHATWG DOM §4.3, a DOMException has:
/// - name: DOMString (e.g., "AbortError", "TimeoutError")
/// - message: DOMString (optional)
///
/// ## Example
/// ```zig
/// const reason = try DOMException.create(allocator, "AbortError", "Operation aborted");
/// defer allocator.destroy(reason);
/// ```
pub const DOMException = struct {
    /// Exception name (e.g., "AbortError", "TimeoutError")
    name: []const u8,

    /// Optional message
    message: []const u8,

    /// Creates a new DOMException.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `name`: Exception name (e.g., "AbortError")
    /// - `message`: Optional message
    ///
    /// ## Returns
    /// Pointer to allocated DOMException
    ///
    /// ## Memory Management
    /// Caller must destroy the returned pointer when done.
    pub fn create(
        allocator: Allocator,
        name: []const u8,
        message: []const u8,
    ) !*DOMException {
        const exception = try allocator.create(DOMException);
        exception.* = .{
            .name = name,
            .message = message,
        };
        return exception;
    }
};

/// Abort algorithm with context support.
///
/// Algorithms are run when signal aborts, BEFORE the abort event fires.
/// Used by Fetch API and other specs to cancel ongoing operations.
///
/// ## Rationale for Context Parameter
/// The WHATWG spec doesn't specify how algorithms capture state, but practical
/// implementation requires closures. Since Zig has no closures, we provide
/// explicit context via the struct pattern.
///
/// This enables addEventListener to register removal callbacks that reference
/// the EventTarget and listener details (spec §2.7.3 step 6).
///
/// ## Example
/// ```zig
/// const MyContext = struct {
///     data: []const u8,
/// };
///
/// const myCallback = struct {
///     fn run(signal: *AbortSignal, ctx: *anyopaque) void {
///         _ = signal;
///         const my_ctx = @as(*MyContext, @ptrCast(@alignCast(ctx)));
///         std.debug.print("Aborted with data: {s}\n", .{my_ctx.data});
///     }
/// }.run;
///
/// var ctx = MyContext{ .data = "example" };
/// const algo = AbortAlgorithm{
///     .callback = myCallback,
///     .context = @ptrCast(&ctx),
/// };
/// try signal.addAlgorithm(algo);
/// ```
pub const AbortAlgorithm = struct {
    callback: *const fn (*AbortSignal, *anyopaque) void,
    context: *anyopaque,
};

/// AbortSignal - Allows aborting ongoing async operations.
///
/// Implements WHATWG DOM AbortSignal interface per §3.2.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=*]
/// interface AbortSignal : EventTarget {
///   [NewObject] static AbortSignal abort(optional any reason);
///   [NewObject] static AbortSignal _any(sequence<AbortSignal> signals);
///   readonly attribute boolean aborted;
///   readonly attribute any reason;
///   undefined throwIfAborted();
///   attribute EventHandler onabort;
/// };
/// ```
///
/// ## Memory Management
/// - Reference counted (acquire/release pattern)
/// - Initial ref_count = 1 (caller owns)
/// - MUST call release() when done
/// - Dependent/source signals: raw pointers (NOT strong refs)
///
/// ## Example
/// ```zig
/// // Basic usage
/// const controller = try AbortController.init(allocator);
/// defer controller.deinit();
///
/// const signal = controller.signal;
/// try signal.addEventListener("abort", callback, ctx, false, false, false, null);
///
/// try controller.abort(null);
///
/// // Composite signals
/// const signal1 = controller1.signal;
/// const signal2 = controller2.signal;
/// const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{signal1, signal2});
/// defer composite.release();
/// ```
///
/// ## Spec References
/// - Interface: https://dom.spec.whatwg.org/#interface-abortsignal
/// - Algorithms: https://dom.spec.whatwg.org/#abortsignal-signal-abort
/// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
pub const AbortSignal = struct {
    /// Memory allocator (8 bytes)
    allocator: Allocator,

    /// Rare data (event listeners, abort algorithms, dependent signals) (8 bytes)
    /// Allocated on demand to keep small signals small
    rare_data: ?*SignalRareData = null,

    /// Reference count (4 bytes)
    /// - Starts at 1 (creator owns initial reference)
    /// - acquire() increments
    /// - release() decrements, deinit() when reaches 0
    ref_count: u32 = 1,

    /// Abort reason (8 bytes)
    /// - JavaScript "any" type (opaque pointer for future JS bindings)
    /// - null = not aborted
    /// - non-null = aborted with reason
    /// - Can be DOMException or custom user pointer
    abort_reason: ?*anyopaque = null,

    /// Is this a dependent signal? (1 byte)
    /// - true = created via AbortSignal.any()
    /// - false = independent signal (from AbortController or abort() factory)
    dependent: bool = false,

    /// Does this signal own the abort_reason? (1 byte)
    /// - true = abort_reason is owned and should be freed on deinit
    /// - false = abort_reason is borrowed and should NOT be freed
    owns_abort_reason: bool = false,

    /// Padding for alignment (6 bytes to reach 8-byte boundary)
    _padding: [6]u8 = undefined,

    // Total size: 48 bytes (small and efficient!)

    /// Creates a new AbortSignal.
    ///
    /// ## Memory Management
    /// Returns signal with ref_count = 1. Caller MUST call release() when done.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    ///
    /// ## Returns
    /// New AbortSignal (not aborted)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate signal
    ///
    /// ## Example
    /// ```zig
    /// const signal = try AbortSignal.init(allocator);
    /// defer signal.release();
    /// ```
    pub fn init(allocator: Allocator) !*AbortSignal {
        const signal = try allocator.create(AbortSignal);
        signal.* = .{
            .allocator = allocator,
            .rare_data = null,
            .ref_count = 1,
            .abort_reason = null,
            .dependent = false,
            .owns_abort_reason = false,
            ._padding = undefined,
        };
        return signal;
    }

    /// Increments the reference count.
    ///
    /// Call this when sharing the signal with another owner.
    /// Each acquire() MUST be balanced with a release().
    ///
    /// ## Example
    /// ```zig
    /// signal.acquire(); // ref_count = 2
    /// container.signal = signal;
    /// // Both owners must call release()
    /// ```
    pub fn acquire(self: *AbortSignal) void {
        self.ref_count += 1;
    }

    /// Decrements the reference count.
    ///
    /// Automatically calls deinit() when ref_count reaches 0.
    /// MUST be called by every owner when done with the signal.
    ///
    /// ## Example
    /// ```zig
    /// const signal = try AbortSignal.init(allocator);
    /// defer signal.release(); // Automatically deinits when ref_count = 0
    /// ```
    pub fn release(self: *AbortSignal) void {
        self.ref_count -= 1;
        if (self.ref_count == 0) {
            self.deinit();
        }
    }

    /// Destroys the signal and frees all associated memory.
    ///
    /// Called automatically by release() when ref_count reaches 0.
    /// Do NOT call directly - use release() instead.
    ///
    /// ## Cleanup
    /// - Frees any remaining abort algorithms
    /// - Removes self from all source signal's dependent lists
    /// - Clears dependent signal list (doesn't release dependents)
    /// - Frees rare data (if allocated)
    /// - Frees the signal itself
    fn deinit(self: *AbortSignal) void {
        // Step 1: Free owned abort reason (DOMException)
        if (self.owns_abort_reason) {
            if (self.abort_reason) |reason| {
                const exception = @as(*DOMException, @ptrCast(@alignCast(reason)));
                self.allocator.destroy(exception);
            }
        }

        if (self.rare_data) |rare| {
            // Step 2: Free any remaining abort algorithms
            for (rare.abort_algorithms.items) |algorithm_ptr| {
                const algorithm = @as(*AbortAlgorithm, @ptrCast(@alignCast(algorithm_ptr)));
                self.allocator.destroy(algorithm);
            }

            // Step 3: Remove self from all source signals' dependent lists
            // This prevents dangling pointers when this signal is destroyed
            if (rare.source_signals) |sources| {
                for (sources.items) |source_ptr| {
                    const source: *AbortSignal = @ptrCast(@alignCast(source_ptr));
                    if (source.rare_data) |source_rare| {
                        if (source_rare.dependent_signals) |*deps| {
                            removeSignalFromList(deps, self);
                        }
                    }
                }
            }

            // Step 4: Clean up rare data (this deinit()s the ArrayLists)
            rare.deinit();
            self.allocator.destroy(rare);
        }

        // Step 5: Destroy self
        self.allocator.destroy(self);
    }

    /// Helper: Remove signal from ArrayList of signals.
    ///
    /// Used to remove dependent signals from source signal lists during cleanup.
    ///
    /// ## Parameters
    /// - `list`: List to remove from
    /// - `signal`: Signal to remove
    fn removeSignalFromList(list: *std.ArrayList(*anyopaque), signal: *AbortSignal) void {
        const signal_ptr: *anyopaque = @ptrCast(signal);
        for (list.items, 0..) |item, i| {
            if (item == signal_ptr) {
                _ = list.orderedRemove(i);
                return;
            }
        }
    }

    /// Adds a source signal to this dependent signal.
    ///
    /// Used internally by createDependentAbortSignal() to link signals.
    /// The source signal is NOT acquired (raw pointer only).
    ///
    /// ## Parameters
    /// - `source`: Source signal to add
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate list
    ///
    /// ## Spec Compliance
    /// Per spec, source_signals is a "weak set" - prevents duplicate signals.
    pub fn addSourceSignal(self: *AbortSignal, source: *AbortSignal) !void {
        const rare = try self.ensureRareData();

        // Ensure source_signals list exists
        if (rare.source_signals == null) {
            rare.source_signals = std.ArrayList(*anyopaque){};
        }

        // Check for duplicates (spec says "set", not "list")
        const source_ptr: *anyopaque = @ptrCast(source);
        for (rare.source_signals.?.items) |item| {
            if (item == source_ptr) {
                return; // Already exists, don't add duplicate
            }
        }

        try rare.source_signals.?.append(self.allocator, source_ptr);
    }

    /// Adds a dependent signal to this source signal.
    ///
    /// Used internally by createDependentAbortSignal() to link signals.
    /// The dependent signal is NOT acquired (raw pointer only).
    ///
    /// ## Parameters
    /// - `dependent`: Dependent signal to add
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate list
    ///
    /// ## Spec Compliance
    /// Per spec, dependent_signals is a "weak set" - prevents duplicate signals.
    pub fn addDependentSignal(self: *AbortSignal, dependent: *AbortSignal) !void {
        const rare = try self.ensureRareData();

        // Ensure dependent_signals list exists
        if (rare.dependent_signals == null) {
            rare.dependent_signals = std.ArrayList(*anyopaque){};
        }

        // Check for duplicates (spec says "set", not "list")
        const dependent_ptr: *anyopaque = @ptrCast(dependent);
        for (rare.dependent_signals.?.items) |item| {
            if (item == dependent_ptr) {
                return; // Already exists, don't add duplicate
            }
        }

        try rare.dependent_signals.?.append(self.allocator, dependent_ptr);
    }

    /// Returns whether the signal has been aborted.
    ///
    /// Implements WHATWG DOM AbortSignal.aborted property per §3.2.3.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute boolean aborted;
    /// ```
    ///
    /// ## Algorithm
    /// Per spec: "The aborted getter steps are to return true if this's abort reason
    /// is not undefined; otherwise false."
    ///
    /// ## Returns
    /// true if aborted, false otherwise
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-abortsignal-aborted
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
    pub fn isAborted(self: *const AbortSignal) bool {
        return self.abort_reason != null;
    }

    /// Returns the abort reason.
    ///
    /// Implements WHATWG DOM AbortSignal.reason property per §3.2.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute any reason;
    /// ```
    ///
    /// ## Algorithm
    /// Per spec: "The reason getter steps are to return this's abort reason."
    ///
    /// ## Returns
    /// - null if not aborted
    /// - abort reason (opaque pointer) if aborted
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-abortsignal-reason
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
    pub fn getReason(self: *const AbortSignal) ?*anyopaque {
        return self.abort_reason;
    }

    /// Throws if the signal has been aborted.
    ///
    /// Implements WHATWG DOM AbortSignal.throwIfAborted() per §3.2.5.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined throwIfAborted();
    /// ```
    ///
    /// ## Algorithm
    /// Per spec: "The throwIfAborted() method steps are:
    /// 1. If this's abort reason is not undefined, then throw this's abort reason."
    ///
    /// ## Zig Limitation
    /// JavaScript can throw any value (objects, strings, etc.), but Zig can only
    /// throw error values. This implementation always throws `error.AbortError`
    /// regardless of the actual abort reason.
    ///
    /// To access the custom abort reason, use `getReason()` before checking:
    /// ```zig
    /// if (signal.isAborted()) {
    ///     const reason = signal.getReason();
    ///     // Handle custom reason
    ///     return error.AbortError;
    /// }
    /// ```
    ///
    /// ## Errors
    /// - `error.AbortError`: Signal has been aborted
    ///
    /// ## Example
    /// ```zig
    /// try signal.throwIfAborted(); // Throws if aborted
    /// // Continue with operation...
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-abortsignal-throwifaborted
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
    ///
    /// ## Spec Deviation
    /// This implementation does not throw the actual abort reason due to Zig
    /// language limitations. JavaScript bindings MUST convert the abort reason
    /// to the appropriate JavaScript exception type.
    pub fn throwIfAborted(self: *const AbortSignal) !void {
        if (self.abort_reason != null) {
            return error.AbortError;
        }
    }

    /// Ensures rare data is allocated.
    ///
    /// Called internally when rare data is needed (event listeners, abort algorithms, etc.).
    /// Idempotent - safe to call multiple times.
    ///
    /// ## Returns
    /// Pointer to rare data
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate rare data
    fn ensureRareData(self: *AbortSignal) !*SignalRareData {
        if (self.rare_data) |rare| {
            return rare;
        }

        // Allocate rare data
        const rare = try self.allocator.create(SignalRareData);
        rare.* = SignalRareData.init(self.allocator);
        self.rare_data = rare;
        return rare;
    }

    /// Aborts the signal (internal algorithm).
    ///
    /// Implements WHATWG DOM "signal abort" per §3.2.5.
    ///
    /// ## Algorithm
    /// Per spec:
    /// 1. If signal is aborted, then return
    /// 2. Set signal's abort reason to reason if given;
    ///    otherwise to a new "AbortError" DOMException
    /// 3. Let dependentSignalsToAbort be a new list
    /// 4. For each dependentSignal of signal's dependent signals:
    ///       a. If dependentSignal is not aborted:
    ///          i.  Set dependentSignal's abort reason to signal's abort reason
    ///          ii. Append dependentSignal to dependentSignalsToAbort
    /// 5. Run the abort steps for signal
    /// 6. For each dependentSignal of dependentSignalsToAbort,
    ///    run the abort steps for dependentSignal
    ///
    /// ## Parameters
    /// - `reason`: Optional abort reason (null = default AbortError)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate event or temporary list
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#abortsignal-signal-abort
    pub fn signalAbort(self: *AbortSignal, reason: ?*anyopaque) !void {
        // Step 1: Already aborted check (idempotent)
        if (self.isAborted()) return;

        // Step 2: Set abort reason
        // Per spec: "otherwise to a new 'AbortError' DOMException"
        if (reason) |r| {
            self.abort_reason = r;
            self.owns_abort_reason = false; // User-provided reason, don't own it
        } else {
            // Create default DOMException("AbortError")
            const default_exception = try DOMException.create(
                self.allocator,
                "AbortError",
                "The operation was aborted",
            );
            self.abort_reason = @ptrCast(default_exception);
            self.owns_abort_reason = true; // We created it, we own it
        }

        // Step 3-4: Collect dependents to abort
        var dependents_to_abort = std.ArrayList(*AbortSignal){};
        defer dependents_to_abort.deinit(self.allocator);

        if (self.rare_data) |rare| {
            if (rare.dependent_signals) |deps| {
                for (deps.items) |dependent_ptr| {
                    const dependent: *AbortSignal = @ptrCast(@alignCast(dependent_ptr));
                    if (!dependent.isAborted()) {
                        // Set dependent's abort reason to ours (borrowed reference)
                        dependent.abort_reason = self.abort_reason;
                        dependent.owns_abort_reason = false; // Dependent doesn't own it
                        try dependents_to_abort.append(self.allocator, dependent);
                    }
                }
            }
        }

        // Step 5: Run abort steps for self
        try runAbortSteps(self);

        // Step 6: Run abort steps for dependents
        for (dependents_to_abort.items) |dependent| {
            try runAbortSteps(dependent);
        }
    }

    /// Runs the abort steps for a signal (internal algorithm).
    ///
    /// Implements WHATWG DOM "run the abort steps" per §3.2.6.
    ///
    /// ## Algorithm
    /// Per spec:
    /// 1. For each algorithm of signal's abort algorithms: run algorithm
    /// 2. Empty signal's abort algorithms
    /// 3. Fire an event named "abort" at signal
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate event
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#abortsignal-abort-steps
    fn runAbortSteps(signal: *AbortSignal) !void {
        // Step 1-2: Run and clear abort algorithms
        if (signal.rare_data) |rare| {
            for (rare.abort_algorithms.items) |algorithm_ptr| {
                // Cast from anyopaque back to AbortAlgorithm struct
                const algorithm = @as(*AbortAlgorithm, @ptrCast(@alignCast(algorithm_ptr)));
                algorithm.callback(signal, algorithm.context);

                // Free the allocated algorithm struct
                signal.allocator.destroy(algorithm);
            }
            // Clear algorithms (makes abort idempotent)
            rare.abort_algorithms.clearRetainingCapacity();
        }

        // Step 3: Fire abort event
        var event = Event.init("abort", .{
            .bubbles = false,
            .cancelable = false,
        });
        _ = try signal.dispatchEvent(&event);
    }

    /// Adds an algorithm to run when signal aborts.
    ///
    /// Implements WHATWG DOM "add algorithm" per §3.2.4.
    ///
    /// ## Algorithm
    /// Per spec:
    /// 1. If signal is aborted, then return
    /// 2. Append algorithm to signal's abort algorithms
    ///
    /// ## Parameters
    /// - `algorithm`: AbortAlgorithm struct with callback and context
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate storage
    ///
    /// ## Memory Management
    /// The algorithm struct is COPIED and OWNED by the signal.
    /// It will be freed when the signal aborts or is destroyed.
    ///
    /// ## Example
    /// ```zig
    /// const MyContext = struct { value: i32 };
    /// var ctx = MyContext{ .value = 42 };
    ///
    /// const callback = struct {
    ///     fn run(sig: *AbortSignal, context: *anyopaque) void {
    ///         _ = sig;
    ///         const my_ctx = @as(*MyContext, @ptrCast(@alignCast(context)));
    ///         std.debug.print("Aborted with value: {}\n", .{my_ctx.value});
    ///     }
    /// }.run;
    ///
    /// try signal.addAlgorithm(.{
    ///     .callback = callback,
    ///     .context = @ptrCast(&ctx),
    /// });
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#abortsignal-add-algorithm
    pub fn addAlgorithm(self: *AbortSignal, algorithm: AbortAlgorithm) !void {
        // Step 1: Already aborted - don't add
        if (self.isAborted()) return;

        const rare = try self.ensureRareData();

        // Step 2: Check for duplicates (spec says "set", not "list")
        // Duplicate means same callback + context pair
        for (rare.abort_algorithms.items) |item| {
            const existing = @as(*AbortAlgorithm, @ptrCast(@alignCast(item)));
            if (existing.callback == algorithm.callback and
                existing.context == algorithm.context)
            {
                // Already exists, don't add duplicate
                return;
            }
        }

        // Step 3: Allocate and store algorithm struct
        const algo_copy = try self.allocator.create(AbortAlgorithm);
        algo_copy.* = algorithm;
        try rare.abort_algorithms.append(self.allocator, @ptrCast(algo_copy));
    }

    /// Removes an algorithm from the signal's abort algorithms.
    ///
    /// Implements WHATWG DOM "remove algorithm" per §3.2.4.
    ///
    /// ## Parameters
    /// - `callback`: Callback function pointer to match
    /// - `context`: Context pointer to match
    ///
    /// ## Note
    /// Matches by BOTH callback and context pointers. This enables removing
    /// specific algorithm instances when multiple algorithms share the same callback.
    ///
    /// ## Example
    /// ```zig
    /// signal.removeAlgorithm(callback, @ptrCast(&ctx));
    /// ```
    pub fn removeAlgorithm(
        self: *AbortSignal,
        callback: *const fn (*AbortSignal, *anyopaque) void,
        context: *anyopaque,
    ) void {
        if (self.rare_data) |rare| {
            for (rare.abort_algorithms.items, 0..) |item, i| {
                const algo = @as(*AbortAlgorithm, @ptrCast(@alignCast(item)));
                if (algo.callback == callback and algo.context == context) {
                    _ = rare.abort_algorithms.orderedRemove(i);
                    // Free the algorithm struct
                    self.allocator.destroy(algo);
                    return;
                }
            }
        }
    }

    /// Returns an already-aborted signal (static factory).
    ///
    /// Implements WHATWG DOM AbortSignal.abort() static method per §3.2.1.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] static AbortSignal abort(optional any reason);
    /// ```
    ///
    /// ## Algorithm
    /// Per spec:
    /// 1. Let signal be a new AbortSignal object
    /// 2. Set signal's abort reason to reason if given;
    ///    otherwise to a new "AbortError" DOMException
    /// 3. Return signal
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `reason`: Optional abort reason (null = default AbortError)
    ///
    /// ## Returns
    /// New signal (already aborted, no event fired)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate signal
    ///
    /// ## Example
    /// ```zig
    /// // Return immediately-aborted signal
    /// const signal = try AbortSignal.abort(allocator, null);
    /// defer signal.release();
    ///
    /// try std.testing.expect(signal.isAborted());
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-abortsignal-abort
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
    pub fn abort(allocator: Allocator, reason: ?*anyopaque) !*AbortSignal {
        const signal = try init(allocator);

        // Set abort reason
        // Per spec: "otherwise to a new 'AbortError' DOMException"
        if (reason) |r| {
            signal.abort_reason = r;
            signal.owns_abort_reason = false; // User-provided, don't own it
        } else {
            const default_exception = try DOMException.create(
                allocator,
                "AbortError",
                "The operation was aborted",
            );
            signal.abort_reason = @ptrCast(default_exception);
            signal.owns_abort_reason = true; // We created it, we own it
        }

        return signal;
    }

    /// Creates a dependent signal that aborts when ANY source signal aborts.
    ///
    /// Implements WHATWG DOM AbortSignal.any() static method per §3.2.2.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] static AbortSignal _any(sequence<AbortSignal> signals);
    /// ```
    ///
    /// ## Algorithm
    /// Per spec: "Return the result of creating a dependent abort signal from signals
    /// using AbortSignal and the current realm."
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `signals`: Array of source signals to monitor
    ///
    /// ## Returns
    /// New dependent signal that aborts when any source aborts
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate signal or lists
    ///
    /// ## Memory Management
    /// - Returned signal has ref_count = 1 (caller MUST release)
    /// - Source signals are NOT acquired (raw pointers only)
    /// - Caller MUST ensure source signals outlive dependent signal
    /// - Dependent signal cleans up links in deinit()
    ///
    /// ## Example
    /// ```zig
    /// const controller1 = try AbortController.init(allocator);
    /// defer controller1.deinit();
    ///
    /// const controller2 = try AbortController.init(allocator);
    /// defer controller2.deinit();
    ///
    /// const composite = try AbortSignal.any(allocator, &[_]*AbortSignal{
    ///     controller1.signal,
    ///     controller2.signal,
    /// });
    /// defer composite.release();
    ///
    /// // composite aborts when EITHER controller aborts
    /// try controller1.abort(null);
    /// std.debug.assert(composite.isAborted());
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-abortsignal-any
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl
    pub fn any(allocator: Allocator, signals: []const *AbortSignal) !*AbortSignal {
        return createDependentAbortSignal(allocator, signals);
    }

    /// Creates a dependent abort signal (internal algorithm).
    ///
    /// Implements WHATWG DOM "create a dependent abort signal" per §3.2.7.
    ///
    /// ## Algorithm
    /// Per spec:
    /// 1. Let resultSignal be a new AbortSignal object
    /// 2. For each signal of signals: if signal is aborted,
    ///    then set resultSignal's abort reason to signal's abort reason
    ///    and return resultSignal
    /// 3. Set resultSignal's dependent to true
    /// 4. For each signal of signals:
    ///       a. If signal's dependent is false:
    ///          i.  Append signal to resultSignal's source signals
    ///          ii. Append resultSignal to signal's dependent signals
    ///       b. Otherwise, for each sourceSignal of signal's source signals:
    ///          i.   Assert: sourceSignal is not aborted and not dependent
    ///          ii.  Append sourceSignal to resultSignal's source signals
    ///          iii. Append resultSignal to sourceSignal's dependent signals
    /// 5. Return resultSignal
    ///
    /// ## Key Insight: Dependency Flattening
    /// If a source signal is itself dependent, we don't create a chain.
    /// Instead, we link directly to the source signal's sources.
    /// This prevents multi-level dependency graphs.
    ///
    /// ## Example
    /// ```
    /// A, B = independent signals
    /// C = any([A, B])  // C depends on A and B
    /// D = any([C])     // D should depend on A and B, not on C
    ///
    /// Without flattening:
    ///   D → C → A
    ///         → B
    ///
    /// With flattening (correct):
    ///   D → A
    ///     → B
    /// ```
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `signals`: Source signals to depend on
    ///
    /// ## Returns
    /// New dependent signal
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#create-a-dependent-abort-signal
    fn createDependentAbortSignal(
        allocator: Allocator,
        signals: []const *AbortSignal,
    ) !*AbortSignal {
        // Step 1: Create result signal
        const result = try init(allocator);
        errdefer result.release();

        // Step 2: Early return if any source already aborted
        for (signals) |signal| {
            if (signal.isAborted()) {
                result.abort_reason = signal.abort_reason;
                return result;
            }
        }

        // Step 3: Mark as dependent
        result.dependent = true;

        // Step 4: Link to source signals (with flattening)
        for (signals) |signal| {
            if (!signal.dependent) {
                // 4a: Direct source signal (not dependent)

                // i. Append signal to resultSignal's source signals
                try result.addSourceSignal(signal);

                // ii. Append resultSignal to signal's dependent signals
                try signal.addDependentSignal(result);
            } else {
                // 4b: Source signal is itself dependent - flatten

                // Must have source_signals (it's dependent)
                if (signal.rare_data) |signal_rare| {
                    if (signal_rare.source_signals) |sources| {
                        for (sources.items) |source_ptr| {
                            const source: *AbortSignal = @ptrCast(@alignCast(source_ptr));

                            // i. Assert: sourceSignal is not aborted and not dependent
                            std.debug.assert(!source.isAborted());
                            std.debug.assert(!source.dependent);

                            // ii. Append sourceSignal to resultSignal's source signals
                            try result.addSourceSignal(source);

                            // iii. Append resultSignal to sourceSignal's dependent signals
                            try source.addDependentSignal(result);
                        }
                    }
                }
            }
        }

        // Step 5: Return result
        return result;
    }

    // EventTarget Interface
    // Delegates to rare data for event listener storage

    /// Adds an event listener to the signal.
    ///
    /// Implements WHATWG DOM EventTarget.addEventListener() per §3.1.2.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined addEventListener(DOMString type, EventListener? callback, ...);
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-addeventlistener
    pub fn addEventListener(
        self: *AbortSignal,
        event_type: []const u8,
        callback: @import("event_target.zig").EventCallback,
        context: *anyopaque,
        capture: bool,
        once: bool,
        passive: bool,
        signal: ?*anyopaque,
    ) !void {
        // Step 2: Early return if signal already aborted
        // Per spec §2.7.3: "If listener's signal is not null and is aborted, then return"
        if (signal) |sig_ptr| {
            const abort_signal = @as(*AbortSignal, @ptrCast(@alignCast(sig_ptr)));
            if (abort_signal.isAborted()) {
                return; // Don't add listener if already aborted
            }
        }

        const rare = try self.ensureRareData();
        const listener = @import("event_target.zig").EventListener{
            .event_type = event_type,
            .callback = callback,
            .context = context,
            .capture = capture,
            .once = once,
            .passive = passive,
            .signal = signal,
        };
        try rare.addEventListener(listener);

        // Step 6: Register abort algorithm if signal provided
        // Per spec §2.7.3 step 6: "If listener's signal is not null, then add
        // the following abort steps to it: Remove an event listener with eventTarget and listener"
        if (signal) |sig_ptr| {
            const abort_signal = @as(*AbortSignal, @ptrCast(@alignCast(sig_ptr)));

            // Create removal context
            const RemovalContext = struct {
                target: *AbortSignal,
                event_type: []const u8,
                callback: @import("event_target.zig").EventCallback,
                capture: bool,
            };

            const removal_ctx = try abort_signal.allocator.create(RemovalContext);
            removal_ctx.* = .{
                .target = self,
                .event_type = event_type,
                .callback = callback,
                .capture = capture,
            };

            // Create abort algorithm that removes the listener
            const removal_callback = struct {
                fn remove(sig: *AbortSignal, ctx: *anyopaque) void {
                    const removal = @as(*RemovalContext, @ptrCast(@alignCast(ctx)));
                    removal.target.removeEventListener(
                        removal.event_type,
                        removal.callback,
                        removal.target, // Pass target as context (unused but required)
                        removal.capture,
                    );
                    // Free the removal context
                    sig.allocator.destroy(removal);
                }
            }.remove;

            try abort_signal.addAlgorithm(.{
                .callback = removal_callback,
                .context = @ptrCast(removal_ctx),
            });
        }
    }

    /// Removes an event listener from the signal.
    ///
    /// Implements WHATWG DOM EventTarget.removeEventListener() per §3.1.3.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined removeEventListener(DOMString type, EventListener? callback, ...);
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-removeeventlistener
    pub fn removeEventListener(
        self: *AbortSignal,
        event_type: []const u8,
        callback: @import("event_target.zig").EventCallback,
        context: *anyopaque,
        capture: bool,
    ) void {
        if (self.rare_data) |rare| {
            _ = rare.removeEventListener(event_type, callback, capture);
        }
        _ = context; // Not used for matching (only callback + capture)
    }

    /// Dispatches an event to the signal.
    ///
    /// Implements WHATWG DOM EventTarget.dispatchEvent() per §3.1.4.
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean dispatchEvent(Event event);
    /// ```
    ///
    /// ## Spec Reference
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-eventtarget-dispatchevent
    pub fn dispatchEvent(self: *AbortSignal, event: *Event) !bool {
        // Get listeners for this event type
        const listeners = if (self.rare_data) |rare|
            rare.getEventListeners(event.event_type)
        else
            &[_]@import("event_target.zig").EventListener{};

        // Dispatch to all listeners
        for (listeners) |listener| {
            listener.callback(event, listener.context);

            // Remove "once" listeners after calling
            if (listener.once) {
                self.removeEventListener(
                    listener.event_type,
                    listener.callback,
                    listener.context,
                    listener.capture,
                );
            }
        }

        // Event is not cancelable for abort events
        return true;
    }
};

// Compile-time size verification
comptime {
    const expected_size = 48;
    const actual_size = @sizeOf(AbortSignal);
    if (actual_size != expected_size) {
        @compileError(std.fmt.comptimePrint(
            "AbortSignal size mismatch: expected {d} bytes, got {d} bytes",
            .{ expected_size, actual_size },
        ));
    }
}
