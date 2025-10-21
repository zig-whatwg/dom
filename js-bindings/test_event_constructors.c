/**
 * Test: Event Constructors and Integration
 * 
 * Tests event creation and full integration:
 * - Event constructor (dom_event_new)
 * - CustomEvent constructor (dom_customevent_new)
 * - Full integration: addEventListener → create event → dispatch → callback invoked
 * - Event properties after construction
 * - CustomEvent detail data
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
typedef struct DOMCustomEvent DOMCustomEvent;
typedef struct DOMEventTarget DOMEventTarget;

// Document
extern DOMDocument* dom_document_new(void);
extern void dom_document_release(DOMDocument* doc);
extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* name);

// Element
extern void dom_element_release(DOMElement* elem);

// Event constructor
extern DOMEvent* dom_event_new(const char* type, unsigned char bubbles, unsigned char cancelable, unsigned char composed);

// CustomEvent constructor
extern DOMCustomEvent* dom_customevent_new(const char* type, unsigned char bubbles, unsigned char cancelable, unsigned char composed, void* detail);

// Event properties
extern const char* dom_event_get_type(DOMEvent* event);
extern unsigned char dom_event_get_bubbles(DOMEvent* event);
extern unsigned char dom_event_get_cancelable(DOMEvent* event);
extern unsigned char dom_event_get_composed(DOMEvent* event);
extern unsigned char dom_event_get_istrusted(DOMEvent* event);
extern double dom_event_get_timestamp(DOMEvent* event);

// Event methods
extern void dom_event_preventdefault(DOMEvent* event);
extern unsigned char dom_event_get_defaultprevented(DOMEvent* event);

// CustomEvent properties
extern void* dom_customevent_get_detail(DOMCustomEvent* event);

// Event memory
extern void dom_event_release(DOMEvent* event);
extern void dom_customevent_release(DOMCustomEvent* event);

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
    int callback_count;
    const char* last_event_type;
    int last_bubbles;
    int last_cancelable;
    void* last_detail;
} CallbackState;

// ============================================================================
// Test Callbacks
// ============================================================================

void event_callback(DOMEvent* event, void* user_data) {
    CallbackState* state = (CallbackState*)user_data;
    state->callback_count++;
    state->last_event_type = dom_event_get_type(event);
    state->last_bubbles = dom_event_get_bubbles(event);
    state->last_cancelable = dom_event_get_cancelable(event);
    
    printf("    [Callback] Event fired: type=%s, bubbles=%d, cancelable=%d, count=%d\n",
           state->last_event_type, state->last_bubbles, state->last_cancelable, state->callback_count);
}

void customevent_callback(DOMEvent* event, void* user_data) {
    CallbackState* state = (CallbackState*)user_data;
    state->callback_count++;
    
    // Cast to CustomEvent to access detail
    DOMCustomEvent* custom = (DOMCustomEvent*)event;
    state->last_detail = dom_customevent_get_detail(custom);
    
    printf("    [Callback] CustomEvent fired: detail=%p, count=%d\n",
           state->last_detail, state->callback_count);
}

void prevent_callback(DOMEvent* event, void* user_data) {
    int* counter = (int*)user_data;
    (*counter)++;
    printf("    [Callback] Preventing default...\n");
    dom_event_preventdefault(event);
}

// ============================================================================
// Tests
// ============================================================================

int main(void) {
    printf("====================================\n");
    printf("Event Constructors and Integration\n");
    printf("====================================\n");

    // ========================================================================
    // Test 1: Event constructor creates event with correct properties
    // ========================================================================
    TEST("Event constructor (dom_event_new)");
    {
        // Create event: click, bubbles=1, cancelable=1, composed=0
        DOMEvent* event = dom_event_new("click", 1, 1, 0);
        ASSERT(event != NULL, "Event created");

        // Check properties
        const char* type = dom_event_get_type(event);
        ASSERT(strcmp(type, "click") == 0, "Event type is 'click'");
        
        unsigned char bubbles = dom_event_get_bubbles(event);
        ASSERT(bubbles == 1, "Event bubbles");
        
        unsigned char cancelable = dom_event_get_cancelable(event);
        ASSERT(cancelable == 1, "Event is cancelable");
        
        unsigned char composed = dom_event_get_composed(event);
        ASSERT(composed == 0, "Event is not composed");

        // isTrusted should be false (created by script, not user agent)
        unsigned char is_trusted = dom_event_get_istrusted(event);
        ASSERT(is_trusted == 0, "Event is not trusted (created by script)");

        // timestamp should be set
        double timestamp = dom_event_get_timestamp(event);
        ASSERT(timestamp >= 0.0, "Event has valid timestamp");

        dom_event_release(event);

        TEST_PASS();
    }

    // ========================================================================
    // Test 2: Event with different options
    // ========================================================================
    TEST("Event with different options (non-bubbling, non-cancelable)");
    {
        // Create load event: bubbles=0, cancelable=0, composed=1
        DOMEvent* event = dom_event_new("load", 0, 0, 1);
        ASSERT(event != NULL, "Event created");

        const char* type = dom_event_get_type(event);
        ASSERT(strcmp(type, "load") == 0, "Event type is 'load'");
        
        unsigned char bubbles = dom_event_get_bubbles(event);
        ASSERT(bubbles == 0, "Event does not bubble");
        
        unsigned char cancelable = dom_event_get_cancelable(event);
        ASSERT(cancelable == 0, "Event is not cancelable");
        
        unsigned char composed = dom_event_get_composed(event);
        ASSERT(composed == 1, "Event is composed");

        dom_event_release(event);

        TEST_PASS();
    }

    // ========================================================================
    // Test 3: CustomEvent constructor with NULL detail
    // ========================================================================
    TEST("CustomEvent constructor with NULL detail");
    {
        DOMCustomEvent* event = dom_customevent_new("custom", 1, 1, 0, NULL);
        ASSERT(event != NULL, "CustomEvent created");

        // Check detail is NULL
        void* detail = dom_customevent_get_detail(event);
        ASSERT(detail == NULL, "Detail is NULL");

        // Check base Event properties work (CustomEvent extends Event)
        DOMEvent* base_event = (DOMEvent*)event;
        const char* type = dom_event_get_type(base_event);
        ASSERT(strcmp(type, "custom") == 0, "Event type is 'custom'");

        dom_customevent_release(event);

        TEST_PASS();
    }

    // ========================================================================
    // Test 4: CustomEvent constructor with detail data
    // ========================================================================
    TEST("CustomEvent constructor with detail data");
    {
        typedef struct {
            int user_id;
            const char* username;
        } UserData;

        UserData user = { .user_id = 123, .username = "alice" };

        DOMCustomEvent* event = dom_customevent_new("user-login", 1, 0, 0, &user);
        ASSERT(event != NULL, "CustomEvent created");

        // Check detail pointer
        void* detail_ptr = dom_customevent_get_detail(event);
        ASSERT(detail_ptr != NULL, "Detail is not NULL");
        ASSERT(detail_ptr == &user, "Detail points to user data");

        // Access detail data
        UserData* retrieved = (UserData*)detail_ptr;
        ASSERT(retrieved->user_id == 123, "Detail user_id matches");
        ASSERT(strcmp(retrieved->username, "alice") == 0, "Detail username matches");

        dom_customevent_release(event);

        TEST_PASS();
    }

    // ========================================================================
    // Test 5: INTEGRATION - addEventListener + dispatchEvent + callback
    // ========================================================================
    TEST("INTEGRATION: addEventListener + dispatch + callback invoked");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* button = dom_document_createelement(doc, "button");
        ASSERT(button != NULL, "Button created");

        CallbackState state = { 
            .callback_count = 0, 
            .last_event_type = NULL,
            .last_bubbles = 0,
            .last_cancelable = 0,
            .last_detail = NULL
        };

        // Add event listener
        int add_result = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)button,
            "click",
            event_callback,
            &state,
            0, 0, 0  // bubble, not once, not passive
        );
        ASSERT(add_result == 0, "Event listener added");
        ASSERT(state.callback_count == 0, "Callback not yet called");

        // Create event
        DOMEvent* event = dom_event_new("click", 1, 1, 0);
        ASSERT(event != NULL, "Event created");

        // Dispatch event
        printf("    Dispatching event...\n");
        unsigned char was_cancelled = dom_eventtarget_dispatchevent(
            (DOMEventTarget*)button,
            event
        );
        
        // Check callback was invoked
        ASSERT(state.callback_count == 1, "Callback invoked exactly once");
        ASSERT(state.last_event_type != NULL, "Callback received event type");
        ASSERT(strcmp(state.last_event_type, "click") == 0, "Event type is 'click'");
        ASSERT(state.last_bubbles == 1, "Event bubbles flag correct");
        ASSERT(state.last_cancelable == 1, "Event cancelable flag correct");
        ASSERT(was_cancelled == 1, "Event was not cancelled");

        dom_event_release(event);
        dom_element_release(button);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 6: INTEGRATION - CustomEvent with detail through dispatch
    // ========================================================================
    TEST("INTEGRATION: CustomEvent with detail through dispatch");
    {
        DOMDocument* doc = dom_document_new();
        ASSERT(doc != NULL, "Document created");

        DOMElement* elem = dom_document_createelement(doc, "widget");
        ASSERT(elem != NULL, "Element created");

        typedef struct {
            int count;
            const char* message;
        } MyData;

        MyData data = { .count = 42, .message = "hello" };

        CallbackState state = { 
            .callback_count = 0, 
            .last_detail = NULL
        };

        // Add custom event listener
        int add_result = dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "my-event",
            customevent_callback,
            &state,
            0, 0, 0
        );
        ASSERT(add_result == 0, "Custom event listener added");

        // Create custom event with detail
        DOMCustomEvent* event = dom_customevent_new("my-event", 1, 0, 0, &data);
        ASSERT(event != NULL, "CustomEvent created");

        // Dispatch custom event (cast to DOMEvent)
        printf("    Dispatching custom event...\n");
        dom_eventtarget_dispatchevent(
            (DOMEventTarget*)elem,
            (DOMEvent*)event
        );

        // Check callback was invoked with detail
        ASSERT(state.callback_count == 1, "Callback invoked exactly once");
        ASSERT(state.last_detail != NULL, "Callback received detail");
        ASSERT(state.last_detail == &data, "Detail pointer matches");

        // Verify detail data
        MyData* retrieved = (MyData*)state.last_detail;
        ASSERT(retrieved->count == 42, "Detail count matches");
        ASSERT(strcmp(retrieved->message, "hello") == 0, "Detail message matches");

        dom_customevent_release(event);
        dom_element_release(elem);
        dom_document_release(doc);

        TEST_PASS();
    }

    // ========================================================================
    // Test 7: INTEGRATION - preventDefault in callback
    // ========================================================================
    TEST("INTEGRATION: preventDefault in callback");
    {
        DOMDocument* doc = dom_document_new();
        DOMElement* elem = dom_document_createelement(doc, "form");

        int counter = 0;
        dom_eventtarget_addeventlistener(
            (DOMEventTarget*)elem,
            "submit",
            prevent_callback,
            &counter,
            0, 0, 0
        );

        DOMEvent* event = dom_event_new("submit", 1, 1, 0);
        
        // Dispatch - should return 0 because default was prevented
        unsigned char result = dom_eventtarget_dispatchevent(
            (DOMEventTarget*)elem,
            event
        );
        
        ASSERT(counter == 1, "Callback invoked");
        ASSERT(result == 0, "dispatchEvent returns 0 (default prevented)");
        
        unsigned char was_prevented = dom_event_get_defaultprevented(event);
        ASSERT(was_prevented == 1, "Event defaultPrevented is true");

        dom_event_release(event);
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

    if (test_passed == test_count) {
        printf("\n🎉 All tests passed! Event system 100%% complete!\n\n");
        return 0;
    } else {
        printf("\n❌ Some tests failed\n\n");
        return 1;
    }
}
