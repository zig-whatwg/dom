/**
 * Simple dispatch test to debug callback issues
 */

#include <stdio.h>
#include <string.h>

typedef struct DOMDocument DOMDocument;
typedef struct DOMElement DOMElement;
typedef struct DOMEvent DOMEvent;
typedef struct DOMEventTarget DOMEventTarget;

extern DOMDocument* dom_document_new(void);
extern void dom_document_release(DOMDocument* doc);
extern DOMElement* dom_document_createelement(DOMDocument* doc, const char* name);
extern void dom_element_release(DOMElement* elem);

extern DOMEvent* dom_event_new(const char* type, unsigned char bubbles, unsigned char cancelable, unsigned char composed);
extern const char* dom_event_get_type(DOMEvent* event);
extern void dom_event_release(DOMEvent* event);

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

static int g_counter = 0;

void simple_callback(DOMEvent* event, void* user_data) {
    printf("[Callback] Called! user_data=%p\n", user_data);
    printf("[Callback] Event=%p\n", (void*)event);
    
    const char* type = dom_event_get_type(event);
    printf("[Callback] Event type=%s\n", type ? type : "(null)");
    
    if (user_data) {
        int* counter = (int*)user_data;
        printf("[Callback] Before increment: *counter=%d\n", *counter);
        (*counter)++;
        printf("[Callback] After increment: *counter=%d\n", *counter);
    }
}

int main(void) {
    printf("=== Simple Dispatch Test ===\n\n");
    
    DOMDocument* doc = dom_document_new();
    printf("1. Document created: %p\n", (void*)doc);
    
    DOMElement* elem = dom_document_createelement(doc, "button");
    printf("2. Element created: %p\n", (void*)elem);
    
    g_counter = 0;
    printf("3. Counter initialized: %d\n", g_counter);
    printf("4. Counter address: %p\n", (void*)&g_counter);
    
    int result = dom_eventtarget_addeventlistener(
        (DOMEventTarget*)elem,
        "click",
        simple_callback,
        &g_counter,
        0, 0, 0
    );
    printf("5. Listener added: result=%d\n", result);
    
    DOMEvent* event = dom_event_new("click", 1, 1, 0);
    printf("6. Event created: %p\n", (void*)event);
    
    const char* type = dom_event_get_type(event);
    printf("7. Event type before dispatch: %s\n", type);
    
    printf("8. Dispatching...\n");
    dom_eventtarget_dispatchevent((DOMEventTarget*)elem, event);
    
    printf("9. After dispatch, counter=%d\n", g_counter);
    
    dom_event_release(event);
    dom_element_release(elem);
    dom_document_release(doc);
    
    if (g_counter == 1) {
        printf("\n✅ SUCCESS: Callback was invoked exactly once\n");
        return 0;
    } else {
        printf("\n❌ FAILURE: Counter=%d (expected 1)\n", g_counter);
        return 1;
    }
}
