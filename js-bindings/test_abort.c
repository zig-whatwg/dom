/**
 * AbortController & AbortSignal C-ABI Tests
 * 
 * Tests for WHATWG DOM AbortController and AbortSignal interfaces.
 * 
 * Spec: https://dom.spec.whatwg.org/#interface-abortcontroller
 */

#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "dom.h"

// Test counters
static int tests_run = 0;
static int tests_passed = 0;

#define TEST(name) \
    do { \
        printf("Test: %s\n", name); \
        tests_run++; \
    } while(0)

#define ASSERT(expr) \
    do { \
        if (!(expr)) { \
            printf("  FAIL: %s (line %d)\n", #expr, __LINE__); \
            return; \
        } \
    } while(0)

#define PASS() \
    do { \
        printf("  PASS\n"); \
        tests_passed++; \
    } while(0)

// ============================================================================
// AbortController Tests
// ============================================================================

void test_abortcontroller_new() {
    TEST("AbortController.new()");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    ASSERT(controller != NULL);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_abortcontroller_get_signal() {
    TEST("AbortController.signal (get)");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    ASSERT(signal != NULL);
    
    // Signal should not be aborted initially
    ASSERT(dom_abortsignal_get_aborted(signal) == 0);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_abortcontroller_signal_sameobject() {
    TEST("AbortController.signal ([SameObject])");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    
    // Get signal twice - should be same pointer
    DOMAbortSignal* signal1 = dom_abortcontroller_get_signal(controller);
    DOMAbortSignal* signal2 = dom_abortcontroller_get_signal(controller);
    
    ASSERT(signal1 == signal2);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_abortcontroller_abort_default() {
    TEST("AbortController.abort() with default reason");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    // Initially not aborted
    ASSERT(dom_abortsignal_get_aborted(signal) == 0);
    
    // Abort with default reason (NULL)
    dom_abortcontroller_abort(controller, NULL);
    
    // Now aborted
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_abortcontroller_abort_custom_reason() {
    TEST("AbortController.abort() with custom reason");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    // Abort with custom reason (opaque pointer)
    int custom_reason = 42;
    dom_abortcontroller_abort(controller, (void*)&custom_reason);
    
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_abortcontroller_abort_idempotent() {
    TEST("AbortController.abort() is idempotent");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    // Abort twice
    dom_abortcontroller_abort(controller, NULL);
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    dom_abortcontroller_abort(controller, NULL);
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    dom_abortcontroller_release(controller);
    PASS();
}

// ============================================================================
// AbortSignal Tests
// ============================================================================

void test_abortsignal_abort_static() {
    TEST("AbortSignal.abort() static factory");
    
    // Create pre-aborted signal
    DOMAbortSignal* signal = dom_abortsignal_abort(NULL);
    
    ASSERT(signal != NULL);
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    dom_abortsignal_release(signal);
    PASS();
}

void test_abortsignal_abort_static_custom_reason() {
    TEST("AbortSignal.abort() with custom reason");
    
    int custom_reason = 123;
    DOMAbortSignal* signal = dom_abortsignal_abort((void*)&custom_reason);
    
    ASSERT(signal != NULL);
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    dom_abortsignal_release(signal);
    PASS();
}

void test_abortsignal_get_aborted() {
    TEST("AbortSignal.aborted (get)");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    // Initially false
    ASSERT(dom_abortsignal_get_aborted(signal) == 0);
    
    // Abort
    dom_abortcontroller_abort(controller, NULL);
    
    // Now true
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_abortsignal_throwifaborted_not_aborted() {
    TEST("AbortSignal.throwIfAborted() when not aborted");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    // Should return 0 (success) when not aborted
    int32_t result = dom_abortsignal_throwifaborted(signal);
    ASSERT(result == 0);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_abortsignal_throwifaborted_when_aborted() {
    TEST("AbortSignal.throwIfAborted() when aborted");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    // Abort
    dom_abortcontroller_abort(controller, NULL);
    
    // Should return error code when aborted
    int32_t result = dom_abortsignal_throwifaborted(signal);
    ASSERT(result == DOM_ERROR_INVALID_STATE);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_abortsignal_refcounting() {
    TEST("AbortSignal reference counting");
    
    // Create pre-aborted signal (ref_count = 1)
    DOMAbortSignal* signal = dom_abortsignal_abort(NULL);
    
    // Acquire (ref_count = 2)
    dom_abortsignal_acquire(signal);
    
    // First release (ref_count = 1)
    dom_abortsignal_release(signal);
    
    // Signal still valid - can check aborted
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    // Second release (ref_count = 0, signal freed)
    dom_abortsignal_release(signal);
    
    PASS();
}

// ============================================================================
// Integration Tests
// ============================================================================

void test_multiple_controllers() {
    TEST("Multiple controllers");
    
    DOMAbortController* controller1 = dom_abortcontroller_new();
    DOMAbortController* controller2 = dom_abortcontroller_new();
    
    DOMAbortSignal* signal1 = dom_abortcontroller_get_signal(controller1);
    DOMAbortSignal* signal2 = dom_abortcontroller_get_signal(controller2);
    
    // Different signals
    ASSERT(signal1 != signal2);
    
    // Abort first controller
    dom_abortcontroller_abort(controller1, NULL);
    
    ASSERT(dom_abortsignal_get_aborted(signal1) == 1);
    ASSERT(dom_abortsignal_get_aborted(signal2) == 0);
    
    // Abort second controller
    dom_abortcontroller_abort(controller2, NULL);
    
    ASSERT(dom_abortsignal_get_aborted(signal1) == 1);
    ASSERT(dom_abortsignal_get_aborted(signal2) == 1);
    
    dom_abortcontroller_release(controller1);
    dom_abortcontroller_release(controller2);
    PASS();
}

void test_signal_sharing() {
    TEST("Signal sharing with acquire/release");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    // Share signal with another context (simulate)
    dom_abortsignal_acquire(signal);
    DOMAbortSignal* shared_signal = signal;
    
    // Both references see same state
    dom_abortcontroller_abort(controller, NULL);
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    ASSERT(dom_abortsignal_get_aborted(shared_signal) == 1);
    
    // Release controller (signal ref_count = 2)
    dom_abortcontroller_release(controller);
    
    // Shared signal still valid
    ASSERT(dom_abortsignal_get_aborted(shared_signal) == 1);
    
    // Release shared reference (signal freed)
    dom_abortsignal_release(shared_signal);
    
    PASS();
}

void test_cancellable_operation_pattern() {
    TEST("Cancellable operation pattern");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    // Simulate operation checking signal
    int step_count = 0;
    
    // Step 1: Check before starting
    if (dom_abortsignal_get_aborted(signal)) {
        ASSERT(0); // Should not be aborted yet
    }
    step_count++;
    
    // Step 2: Do work, check again
    if (dom_abortsignal_get_aborted(signal)) {
        ASSERT(0); // Should not be aborted yet
    }
    step_count++;
    
    // User aborts
    dom_abortcontroller_abort(controller, NULL);
    
    // Step 3: Check and abort
    if (dom_abortsignal_get_aborted(signal)) {
        step_count++; // Operation cancelled
    } else {
        ASSERT(0); // Should be aborted
    }
    
    ASSERT(step_count == 3);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_throwifaborted_error_handling() {
    TEST("throwIfAborted error handling pattern");
    
    DOMAbortController* controller = dom_abortcontroller_new();
    DOMAbortSignal* signal = dom_abortcontroller_get_signal(controller);
    
    int result = 0;
    
    // Check 1: Not aborted
    int err = dom_abortsignal_throwifaborted(signal);
    if (err != 0) {
        ASSERT(0); // Should not error yet
    }
    result++;
    
    // Abort
    dom_abortcontroller_abort(controller, NULL);
    
    // Check 2: Aborted
    err = dom_abortsignal_throwifaborted(signal);
    if (err != 0) {
        ASSERT(err == DOM_ERROR_INVALID_STATE);
        const char* msg = dom_error_code_message(err);
        ASSERT(msg != NULL);
        result++;
    } else {
        ASSERT(0); // Should error
    }
    
    ASSERT(result == 2);
    
    dom_abortcontroller_release(controller);
    PASS();
}

void test_pre_aborted_signal_pattern() {
    TEST("Pre-aborted signal pattern");
    
    // Create pre-aborted signal
    DOMAbortSignal* signal = dom_abortsignal_abort(NULL);
    
    // Immediately aborted
    ASSERT(dom_abortsignal_get_aborted(signal) == 1);
    
    // throwIfAborted returns error
    int err = dom_abortsignal_throwifaborted(signal);
    ASSERT(err == DOM_ERROR_INVALID_STATE);
    
    dom_abortsignal_release(signal);
    PASS();
}

// ============================================================================
// Main Test Runner
// ============================================================================

int main(void) {
    printf("=== AbortController & AbortSignal Tests ===\n\n");
    
    // AbortController tests
    test_abortcontroller_new();
    test_abortcontroller_get_signal();
    test_abortcontroller_signal_sameobject();
    test_abortcontroller_abort_default();
    test_abortcontroller_abort_custom_reason();
    test_abortcontroller_abort_idempotent();
    
    // AbortSignal tests
    test_abortsignal_abort_static();
    test_abortsignal_abort_static_custom_reason();
    test_abortsignal_get_aborted();
    test_abortsignal_throwifaborted_not_aborted();
    test_abortsignal_throwifaborted_when_aborted();
    test_abortsignal_refcounting();
    
    // Integration tests
    test_multiple_controllers();
    test_signal_sharing();
    test_cancellable_operation_pattern();
    test_throwifaborted_error_handling();
    test_pre_aborted_signal_pattern();
    
    printf("\n=== Results ===\n");
    printf("Tests run: %d\n", tests_run);
    printf("Tests passed: %d\n", tests_passed);
    printf("Tests failed: %d\n", tests_run - tests_passed);
    
    return (tests_run == tests_passed) ? 0 : 1;
}
