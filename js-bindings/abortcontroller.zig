//! AbortController C-ABI Bindings
//!
//! Provides C-compatible bindings for the AbortController interface.
//! AbortController provides a simple way to create and control an AbortSignal.
//!
//! ## Exported Functions
//! - dom_abortcontroller_new() - Create new AbortController
//! - dom_abortcontroller_get_signal() - Get the signal ([SameObject])
//! - dom_abortcontroller_abort() - Trigger abort with optional reason
//! - dom_abortcontroller_release() - Release controller

const std = @import("std");
const dom = @import("dom");
const AbortController = dom.AbortController;
const AbortSignal = dom.AbortSignal;

/// Opaque AbortController handle for C
pub const DOMAbortController = opaque {};

/// Create a new AbortController.
///
/// The controller is created with ref_count = 1 (caller owns initial reference).
/// The controller owns its signal - do not release the signal separately.
///
/// ## Returns
/// AbortController handle (never NULL, panics on OOM)
///
/// ## Example
/// ```c
/// DOMAbortController* controller = dom_abortcontroller_new();
/// DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
/// dom_abortcontroller_abort(controller, NULL);
/// dom_abortcontroller_release(controller);
/// ```
///
/// ## WebIDL
/// ```webidl
/// [Exposed=*]
/// interface AbortController {
///   constructor();
/// };
/// ```
pub export fn dom_abortcontroller_new() *DOMAbortController {
    const allocator = std.heap.c_allocator;
    const controller = AbortController.init(allocator) catch {
        @panic("Failed to allocate AbortController");
    };
    return @ptrCast(controller);
}

/// Get the controller's signal.
///
/// The signal is [SameObject] per WebIDL - always returns the same instance.
/// The signal is owned by the controller - do NOT release it separately.
///
/// ## Parameters
/// - `controller`: AbortController handle
///
/// ## Returns
/// AbortSignal handle (never NULL)
///
/// ## Example
/// ```c
/// DOMAbortController* controller = dom_abortcontroller_new();
/// DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
///
/// // Signal is [SameObject] - always same pointer
/// DOMAbortSignal* signal2 = dom_abortcontroller_get_signal(controller);
/// // signal == signal2
///
/// // Pass signal to operations
/// dom_fetch_with_abort(url, signal);
///
/// dom_abortcontroller_release(controller);
/// ```
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute AbortSignal signal;
/// ```
pub export fn dom_abortcontroller_get_signal(controller: *DOMAbortController) *AbortSignal {
    const ctrl: *AbortController = @ptrCast(@alignCast(controller));
    return ctrl.signal;
}

/// Abort the controller's signal with an optional reason.
///
/// Triggers abort on the signal. If already aborted, this is a no-op.
/// The reason parameter is JavaScript "any" type (opaque pointer).
///
/// ## Parameters
/// - `controller`: AbortController handle
/// - `reason`: Abort reason (opaque pointer, can be NULL)
///   - NULL = default reason ("AbortError" DOMException)
///   - non-NULL = custom reason (user-managed)
///
/// ## Example
/// ```c
/// // Abort with default reason
/// dom_abortcontroller_abort(controller, NULL);
///
/// // Abort with custom reason (user-managed pointer)
/// MyErrorContext* ctx = malloc(sizeof(MyErrorContext));
/// ctx->code = TIMEOUT_ERROR;
/// dom_abortcontroller_abort(controller, (void*)ctx);
/// // Controller does NOT own ctx - you must free it
/// ```
///
/// ## WebIDL
/// ```webidl
/// undefined abort(optional any reason);
/// ```
pub export fn dom_abortcontroller_abort(controller: *DOMAbortController, reason: ?*anyopaque) void {
    const ctrl: *AbortController = @ptrCast(@alignCast(controller));
    ctrl.abort(reason) catch {
        // Abort can fail with OOM (event allocation)
        // In C-ABI, we can't propagate errors, so panic
        @panic("Failed to abort controller");
    };
}

/// Release an AbortController.
///
/// Frees the controller and releases its signal.
/// After this call, the controller handle is invalid.
///
/// ## Parameters
/// - `controller`: AbortController handle
///
/// ## Example
/// ```c
/// DOMAbortController* controller = dom_abortcontroller_new();
/// // ... use controller ...
/// dom_abortcontroller_release(controller);
/// // controller is now invalid
/// ```
pub export fn dom_abortcontroller_release(controller: *DOMAbortController) void {
    const ctrl: *AbortController = @ptrCast(@alignCast(controller));
    ctrl.deinit();
}
