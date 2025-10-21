//! AbortSignal C-ABI Bindings
//!
//! Provides C-compatible bindings for the AbortSignal interface.
//! AbortSignal allows aborting ongoing async operations.
//!
//! ## Exported Functions
//! - dom_abortsignal_abort() - Static factory for pre-aborted signal
//! - dom_abortsignal_get_aborted() - Check if aborted
//! - dom_abortsignal_throwifaborted() - Throw if aborted (returns error code)
//! - dom_abortsignal_acquire() - Increment reference count
//! - dom_abortsignal_release() - Decrement reference count

const std = @import("std");
const dom = @import("dom");
const AbortSignal = dom.AbortSignal;
const dom_types = @import("dom_types.zig");

/// Opaque AbortSignal handle for C
pub const DOMAbortSignal = opaque {};

/// Create a pre-aborted signal (static factory).
///
/// Returns a signal that's already aborted with optional reason.
/// Useful for immediately-aborted operations.
///
/// ## Parameters
/// - `reason`: Abort reason (opaque pointer, can be NULL)
///   - NULL = default reason ("AbortError" DOMException)
///   - non-NULL = custom reason (user-managed)
///
/// ## Returns
/// AbortSignal handle (never NULL, already aborted)
///
/// ## Memory Management
/// Returned signal has ref_count = 1. Caller MUST call release() when done.
///
/// ## Example
/// ```c
/// // Pre-aborted with default reason
/// DOMAbortSignal* signal = dom_abortsignal_abort(NULL);
///
/// // Check if aborted
/// if (dom_abortsignal_get_aborted(signal)) {
///     printf("Signal is aborted\n");
/// }
///
/// dom_abortsignal_release(signal);
/// ```
///
/// ## WebIDL
/// ```webidl
/// [NewObject] static AbortSignal abort(optional any reason);
/// ```
pub export fn dom_abortsignal_abort(reason: ?*anyopaque) *DOMAbortSignal {
    const allocator = std.heap.c_allocator;
    const signal = AbortSignal.abort(allocator, reason) catch {
        @panic("Failed to allocate AbortSignal");
    };
    return @ptrCast(signal);
}

/// Check if signal has been aborted.
///
/// ## Parameters
/// - `signal`: AbortSignal handle
///
/// ## Returns
/// 1 if aborted, 0 if not aborted
///
/// ## Example
/// ```c
/// if (dom_abortsignal_get_aborted(signal)) {
///     printf("Operation was cancelled\n");
///     return ERROR_ABORTED;
/// }
///
/// // Continue operation...
/// ```
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean aborted;
/// ```
pub export fn dom_abortsignal_get_aborted(signal: *DOMAbortSignal) u8 {
    const sig: *AbortSignal = @ptrCast(@alignCast(signal));
    return if (sig.isAborted()) 1 else 0;
}

/// Throw if signal has been aborted.
///
/// In C, "throw" means return an error code. Returns 0 if not aborted,
/// DOM_ERROR_INVALID_STATE if aborted.
///
/// ## Parameters
/// - `signal`: AbortSignal handle
///
/// ## Returns
/// - 0 if not aborted (success)
/// - DOM_ERROR_INVALID_STATE (11) if aborted
///
/// ## Example
/// ```c
/// int err = dom_abortsignal_throwifaborted(signal);
/// if (err != 0) {
///     printf("Operation aborted: %s\n", dom_error_code_message(err));
///     return err;
/// }
///
/// // Continue operation...
/// ```
///
/// ## WebIDL
/// ```webidl
/// undefined throwIfAborted();
/// ```
pub export fn dom_abortsignal_throwifaborted(signal: *DOMAbortSignal) i32 {
    const sig: *AbortSignal = @ptrCast(@alignCast(signal));
    sig.throwIfAborted() catch {
        // AbortError maps to InvalidStateError in DOM error codes
        return @intFromEnum(dom_types.DOMErrorCode.InvalidStateError);
    };
    return 0; // Success (not aborted)
}

/// Increment signal reference count.
///
/// Call this when sharing the signal with another owner.
/// Each acquire() MUST be balanced with a release().
///
/// ## Parameters
/// - `signal`: AbortSignal handle
///
/// ## Example
/// ```c
/// DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
///
/// // Share with another context
/// dom_abortsignal_acquire(signal);
/// my_context->signal = signal;
///
/// // Later, both contexts must release
/// dom_abortsignal_release(my_context->signal);
/// dom_abortcontroller_release(controller);
/// ```
pub export fn dom_abortsignal_acquire(signal: *DOMAbortSignal) void {
    const sig: *AbortSignal = @ptrCast(@alignCast(signal));
    sig.acquire();
}

/// Decrement signal reference count.
///
/// Automatically frees the signal when ref_count reaches 0.
/// MUST be called by every owner when done with the signal.
///
/// ## Parameters
/// - `signal`: AbortSignal handle
///
/// ## Example
/// ```c
/// DOMAbortSignal* signal = dom_abortsignal_abort(NULL);
/// // ... use signal ...
/// dom_abortsignal_release(signal);
/// // signal is now invalid
/// ```
pub export fn dom_abortsignal_release(signal: *DOMAbortSignal) void {
    const sig: *AbortSignal = @ptrCast(@alignCast(signal));
    sig.release();
}
