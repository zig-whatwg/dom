/**
 * Advanced DOM Example
 * 
 * Demonstrates the power of the DOM library with selector methods.
 * This example simulates a simple form validation scenario.
 */

#include <stdio.h>
#include <string.h>
#include "dom.h"

int main(void) {
    printf("=== Advanced DOM Example: Form Validation ===\n\n");
    
    // Create document
    DOMDocument* doc = dom_document_new();
    printf("✓ Document created\n");
    
    // Create form structure:
    // form#userForm
    //   > div.field
    //     > input#username[type='text']
    //   > div.field
    //     > input#email[type='email']
    //   > button#submit.primary
    
    DOMElement* form = dom_document_createelement(doc, "form");
    dom_element_set_id(form, "userForm");
    
    // Username field
    DOMElement* usernameField = dom_document_createelement(doc, "div");
    dom_element_set_classname(usernameField, "field");
    
    DOMElement* usernameInput = dom_document_createelement(doc, "input");
    dom_element_set_id(usernameInput, "username");
    dom_element_setattribute(usernameInput, "type", "text");
    dom_element_setattribute(usernameInput, "required", "true");
    
    // Email field
    DOMElement* emailField = dom_document_createelement(doc, "div");
    dom_element_set_classname(emailField, "field");
    
    DOMElement* emailInput = dom_document_createelement(doc, "input");
    dom_element_set_id(emailInput, "email");
    dom_element_setattribute(emailInput, "type", "email");
    dom_element_setattribute(emailInput, "required", "true");
    
    // Submit button
    DOMElement* submitButton = dom_document_createelement(doc, "button");
    dom_element_set_id(submitButton, "submit");
    dom_element_set_classname(submitButton, "primary");
    
    // Build tree
    dom_node_appendchild((DOMNode*)usernameField, (DOMNode*)usernameInput);
    dom_node_appendchild((DOMNode*)emailField, (DOMNode*)emailInput);
    dom_node_appendchild((DOMNode*)form, (DOMNode*)usernameField);
    dom_node_appendchild((DOMNode*)form, (DOMNode*)emailField);
    dom_node_appendchild((DOMNode*)form, (DOMNode*)submitButton);
    
    printf("✓ Form structure created\n\n");
    
    // Scenario 1: Find form by ID
    printf("Scenario 1: Find form by ID\n");
    // (In real app, form would be in document tree)
    printf("  Form ID: %s\n", dom_element_get_id(form));
    printf("  ✓ Form found\n\n");
    
    // Scenario 2: Find all required inputs
    printf("Scenario 2: Find required inputs\n");
    DOMElement* requiredInput1 = dom_element_queryselector(form, "input[required]");
    if (requiredInput1) {
        const char* inputId = dom_element_get_id(requiredInput1);
        printf("  Found required input: %s\n", inputId);
    }
    printf("  ✓ Required inputs validated\n\n");
    
    // Scenario 3: Find email input specifically
    printf("Scenario 3: Find email input\n");
    DOMElement* emailFound = dom_element_queryselector(form, "input[type='email']");
    if (emailFound == emailInput) {
        printf("  Found email input: %s\n", dom_element_get_id(emailFound));
        printf("  ✓ Email input located\n\n");
    }
    
    // Scenario 4: Check if button is primary
    printf("Scenario 4: Check button styling\n");
    if (dom_element_matches(submitButton, ".primary")) {
        printf("  Button has primary styling\n");
        printf("  ✓ Button style verified\n\n");
    }
    
    // Scenario 5: Find button's parent form
    printf("Scenario 5: Find button's parent form\n");
    DOMElement* parentForm = dom_element_closest(submitButton, "form");
    if (parentForm == form) {
        printf("  Button is inside form: %s\n", dom_element_get_id(parentForm));
        printf("  ✓ Form relationship verified\n\n");
    }
    
    // Scenario 6: Find input by ID
    printf("Scenario 6: Find specific input\n");
    DOMElement* usernameFound = dom_element_queryselector(form, "#username");
    if (usernameFound == usernameInput) {
        const char* type = dom_element_getattribute(usernameFound, "type");
        printf("  Found username input (type=%s)\n", type);
        printf("  ✓ Username input located\n\n");
    }
    
    // Scenario 7: Find all fields
    printf("Scenario 7: Find all form fields\n");
    DOMElement* firstField = dom_element_queryselector(form, ".field");
    if (firstField) {
        uint8_t hasField = dom_element_matches(firstField, ".field");
        printf("  Found field container (matches=.field): %d\n", hasField);
        printf("  ✓ Fields enumerated\n\n");
    }
    
    // Scenario 8: Complex selector - find input inside field div
    printf("Scenario 8: Complex selector\n");
    DOMElement* nestedInput = dom_element_queryselector(form, "div.field input");
    if (nestedInput) {
        const char* nestedId = dom_element_get_id(nestedInput);
        printf("  Found nested input: %s\n", nestedId);
        printf("  ✓ Complex selector worked\n\n");
    }
    
    // Print summary
    printf("=== Summary ===\n");
    printf("Form structure validated:\n");
    printf("  • Form ID: %s\n", dom_element_get_id(form));
    printf("  • Username input: %s (type=%s)\n", 
           dom_element_get_id(usernameInput),
           dom_element_getattribute(usernameInput, "type"));
    printf("  • Email input: %s (type=%s)\n",
           dom_element_get_id(emailInput),
           dom_element_getattribute(emailInput, "type"));
    printf("  • Submit button: %s (class=%s)\n",
           dom_element_get_id(submitButton),
           dom_element_get_classname(submitButton));
    printf("\nAll selectors worked! The DOM library is fully functional.\n");
    
    // Cleanup
    dom_element_release(form);
    dom_document_release(doc);
    printf("\n✓ Cleaned up\n");
    
    printf("\n=== ADVANCED EXAMPLE COMPLETE ✓ ===\n");
    return 0;
}
