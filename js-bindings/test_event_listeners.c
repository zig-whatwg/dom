/**
 * Test: Event Listeners (addEventListener, removeEventListener, dispatchEvent)
 * 
 * Tests event listener functionality:
 * - Adding event listeners with various options
 * - Dispatching events and invoking listeners
 * - Event propagation (bubble, capture)
 * - once flag (auto-remove after first invocation)
 * - passive flag
 * - Listener callback invocation with user data
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// Forward declarations
typedef struct DOMDocument DOMDocument;
typedef struct DOMElement DOMElement;
typedef struct DOMNode DOMNode;
typedef struct DOMEvent DOMEvent;
typedef struct DOMEventTarget DOMEventTarget;

// Document
extern DOMDocument* dom_document_new(void);
extern void dom_document_release(DOMDocument* doc);
extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* name);

// Element/Node
extern void dom_element_release(DOMElement* elem);

// Event properties (read-only, but needed for testing)
extern const char* dom_event_get_type(DOMEvent* event);
extern unsigned char dom_event_get_bubbles(DOMEvent* event);
extern unsigned char dom_event_get_cancelable(DOMEvent* event);

// EventTarget
extern int dom_eventtarget_addeventlistener(
    DOMEventTarget* target,
    const char* type,
    void (*callback)(DOMEvent* event, void* user_data),
    void* user_data,
    unsigned char capture,
    unsigned char once,
    unsigned char passive
);
extern void dom_eventtarget_removeeventlistener(
    DOMEventTarget* target,
    const char* type,
    void (*callback)(DOMEvent* event, void* user_data),
    void* user_data,
    unsigned char capture
);
extern unsigned char dom_eventtarget_dispatchevent(DOMEventTarget* target, DOMEvent* event);

// Test helpers
static int test_count = 0;
static int test_passed = 0;

#define TEST(name) \
    do { \
        test_count++; \
        printf("\n[TEST %d] %s\n", test_count, name); \
    } while(0)

#define ASSERT(expr, msg) \
    do { \
        if (!(expr)) { \
            printf("  ❌ FAILED: %s\n", msg); \
            printf("     Expression: %s\n", #expr); \
            return 1; \
        } \
        printf("  ✅ %s\n", msg); \
    } while(0)

#define TEST_PASS() \
    do { \
        test_passed++; \
        printf("  ✅ PASSED\n"); \
    } while(0)

// ============================================================================
// Test State
// ============================================================================

typedef struct {
    int counter;
    const char* last_event_type;
    int was_called;
} TestState;

// ============================================================================
// Test Callbacks
// ============================================================================

void simple_callback(DOMEvent* event, void* user_data) {
    TestState* state = (TestState*)user_data;
    state->counter++;
    state->last_event_type = dom_event_get_type(event);
    state->was_called = 1;
    printf("    [Callback] simple_callback called, counter=%d, type=%s\n", 
           state->counter, state->last_event_type);
}

void once_callback(DOMEvent* event, void* user_data) {
    TestState* state = (TestState*)user_data;
    state->counter++;
    state->was_called = 1;
    printf("    [Callback] once_callback called, counter=%d\n", state->counter);
}

void capture_callback(DOMEvent* event, void* user_data) {
    TestState* state = (TestState*)user_data;
    state->counter++;
    printf("    [Callback] capture_callback called, counter=%d\n", state->counter);
}

void bubble_callback(DOMEvent* event, void* user_data) {
    TestState* state = (TestState*)user_data;
    state->counter++;
    printf("    [Callback] bubble_callback called, counter=%d\n", state->counter);
}

// ============================================================================
// NOTE: Event Construction Not Yet Exposed
// ============================================================================
//
// These tests would be more complete if we could create Event objects from C.
// For now, we test:
// 1. addEventListener API (function signature, return values)
// 2. removeEventListener API (function signature)
//
// Full integration testing (dispatch + listener invocation) requires:
// - Event constructor exposure in C-ABI
// - Or helper functions to create test events
//
// Future work tracked for Phase 5 completion.
// ============================================================================

int main(void) {
    printf("====================================\n");
    printf("Event Listeners Test\n");
    printf("====================================\n");

    // ========================================================================
    // Test 1: addEventListener API exists and accepts valid parameters
    // ========================================================================
    TEST("addEventListener API with simple callback");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* elem = dom_document_createelement(doc, "button");
        ASSERT(elem != NULL, "Element created");

        TestState state = { .counter = 0, .last_event_type = NULL, .was_called = 0 };

        // Add event listener
        int result = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "click",
            simple_callback,
            &state,
            0, // bubble
            0, // not once
            0  // not passive
        );
        ASSERT(result == 0, "addEventListener succeeded");

        // NOTE: Can't test dispatch without Event constructor
        // This just verifies the function signature works
        printf("  ✅ Listener registered (dispatch not yet testable)\n");

        dom_element_release(elem);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 2: addEventListener with once=1
    // ========================================================================
    TEST("addEventListener with once flag");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* elem = dom_document_createelement(doc, "widget");
        ASSERT(elem != NULL, "Element created");

        TestState state = { .counter = 0, .last_event_type = NULL, .was_called = 0 };

        // Add event listener with once=1
        int result = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "load",
            once_callback,
            &state,
            0, // bubble
            1, // once=1
            0  // not passive
        );
        ASSERT(result == 0, "addEventListener with once=1 succeeded");

        printf("  ✅ Once listener registered\n");

        dom_element_release(elem);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 3: addEventListener with capture=1
    // ========================================================================
    TEST("addEventListener with capture flag");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* parent = dom_document_createelement(doc, "parent");
        ASSERT(parent != NULL, "Parent element created");

        TestState state = { .counter = 0, .last_event_type = NULL, .was_called = 0 };

        // Add capture listener on parent
        int result = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)parent,
            "click",
            capture_callback,
            &state,
            1, // capture=1
            0, // not once
            0  // not passive
        );
        ASSERT(result == 0, "addEventListener with capture=1 succeeded");

        printf("  ✅ Capture listener registered\n");

        dom_element_release(parent);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 4: addEventListener with passive=1
    // ========================================================================
    TEST("addEventListener with passive flag");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* elem = dom_document_createelement(doc, "scroller");
        ASSERT(elem != NULL, "Element created");

        TestState state = { .counter = 0, .last_event_type = NULL, .was_called = 0 };

        // Add passive listener
        int result = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "scroll",
            simple_callback,
            &state,
            0, // bubble
            0, // not once
            1  // passive=1
        );
        ASSERT(result == 0, "addEventListener with passive=1 succeeded");

        printf("  ✅ Passive listener registered\n");

        dom_element_release(elem);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 5: addEventListener with NULL callback (should succeed per spec)
    // ========================================================================
    TEST("addEventListener with NULL callback");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* elem = dom_document_createelement(doc, "widget");
        ASSERT(elem != NULL, "Element created");

        // Add NULL callback (spec says to early return)
        int result = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "click",
            NULL,  // NULL callback
            NULL,
            0, 0, 0
        );
        ASSERT(result == 0, "addEventListener with NULL callback returned success");

        printf("  ✅ NULL callback handled gracefully\n");

        dom_element_release(elem);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 6: removeEventListener API
    // ========================================================================
    TEST("removeEventListener API");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* elem = dom_document_createelement(doc, "button");
        ASSERT(elem != NULL, "Element created");

        TestState state = { .counter = 0, .last_event_type = NULL, .was_called = 0 };

        // Add listener
        int result = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "click",
            simple_callback,
            &state,
            0, 0, 0
        );
        ASSERT(result == 0, "addEventListener succeeded");

        // Remove listener
        dom_eventtarget_removeeventlistener(
            (DOMEventTarget*)elem,
            "click",
            simple_callback,
            &state,
            0  // Same capture as addEventListener
        );
        printf("  ✅ removeEventListener called (NOTE: stub implementation)\n");

        dom_element_release(elem);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 7: Multiple listeners on same element
    // ========================================================================
    TEST("Multiple listeners on same element");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* elem = dom_document_createelement(doc, "multi");
        ASSERT(elem != NULL, "Element created");

        TestState state1 = { .counter = 0, .last_event_type = NULL, .was_called = 0 };
        TestState state2 = { .counter = 0, .last_event_type = NULL, .was_called = 0 };

        // Add first listener
        int result1 = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "click",
            simple_callback,
            &state1,
            0, 0, 0
        );
        ASSERT(result1 == 0, "First listener added");

        // Add second listener (different callback/state)
        int result2 = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "click",
            bubble_callback,
            &state2,
            0, 0, 0
        );
        ASSERT(result2 == 0, "Second listener added");

        printf("  ✅ Multiple listeners registered\n");

        dom_element_release(elem);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Summary
    // ========================================================================
    printf("\n====================================\n");
    printf("Summary: %d/%d tests passed\n", test_passed, test_count);
    printf("====================================\n");

    printf("\nNOTE: Full integration testing (dispatch + listener invocation) requires\n");
    printf("      Event constructor exposure, which is tracked for future work.\n");
    printf("      These tests verify the addEventListener/removeEventListener API surface.\n");

    if (test_passed == test_count) {
        printf("\n🎉 All tests passed!\n\n");
        return 0;
    } else {
        printf("\n❌ Some tests failed\n\n");
        return 1;
    }
}
