#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "dom.h"

void test_classList_basic() {
    printf("Test 1: Basic classList operations\n");
    
    DOMDocument* doc = dom_document_new();
    assert(doc != NULL);
    
    DOMElement* elem = dom_document_createelement(doc, "container");
    assert(elem != NULL);
    
    // Set class attribute
    int result = dom_element_setattribute(elem, "class", "foo bar baz");
    assert(result == 0);
    
    // Get classList
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    assert(classList != NULL);
    
    // Check length
    uint32_t length = dom_domtokenlist_get_length(classList);
    printf("  Length: %u (expected 3)\n", length);
    assert(length == 3);
    
    // Check value
    const char* value = dom_domtokenlist_get_value(classList);
    printf("  Value: '%s' (expected 'foo bar baz')\n", value);
    assert(strcmp(value, "foo bar baz") == 0);
    
    // Check contains
    assert(dom_domtokenlist_contains(classList, "foo") == 1);
    assert(dom_domtokenlist_contains(classList, "bar") == 1);
    assert(dom_domtokenlist_contains(classList, "baz") == 1);
    assert(dom_domtokenlist_contains(classList, "qux") == 0);
    printf("  contains() working correctly\n");
    
    // Check item
    const char* item0 = dom_domtokenlist_item(classList, 0);
    const char* item1 = dom_domtokenlist_item(classList, 1);
    const char* item2 = dom_domtokenlist_item(classList, 2);
    const char* item3 = dom_domtokenlist_item(classList, 3);
    
    assert(item0 != NULL && strcmp(item0, "foo") == 0);
    assert(item1 != NULL && strcmp(item1, "bar") == 0);
    assert(item2 != NULL && strcmp(item2, "baz") == 0);
    assert(item3 == NULL); // Out of bounds
    printf("  item() working correctly\n");
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ Basic classList operations passed\n\n");
}

void test_classList_add() {
    printf("Test 2: classList.add()\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    // Start with empty class
    dom_element_setattribute(elem, "class", "");
    
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    
    // Add single token
    const char* tokens1[] = {"active"};
    int result = dom_domtokenlist_add(classList, tokens1, 1);
    assert(result == 0);
    assert(dom_domtokenlist_get_length(classList) == 1);
    assert(dom_domtokenlist_contains(classList, "active") == 1);
    printf("  Added single token 'active'\n");
    
    // Add multiple tokens
    const char* tokens2[] = {"btn", "btn-primary", "disabled"};
    result = dom_domtokenlist_add(classList, tokens2, 3);
    assert(result == 0);
    assert(dom_domtokenlist_get_length(classList) == 4);
    assert(dom_domtokenlist_contains(classList, "btn") == 1);
    assert(dom_domtokenlist_contains(classList, "btn-primary") == 1);
    assert(dom_domtokenlist_contains(classList, "disabled") == 1);
    printf("  Added multiple tokens\n");
    
    // Add duplicate (should be ignored)
    const char* tokens3[] = {"active"};
    result = dom_domtokenlist_add(classList, tokens3, 1);
    assert(result == 0);
    assert(dom_domtokenlist_get_length(classList) == 4); // Still 4, not 5
    printf("  Duplicate token ignored correctly\n");
    
    // Verify final value
    const char* value = dom_domtokenlist_get_value(classList);
    printf("  Final value: '%s'\n", value);
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ classList.add() passed\n\n");
}

void test_classList_remove() {
    printf("Test 3: classList.remove()\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    // Start with multiple classes
    dom_element_setattribute(elem, "class", "foo bar baz qux active disabled");
    
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    assert(dom_domtokenlist_get_length(classList) == 6);
    
    // Remove single token
    const char* tokens1[] = {"foo"};
    int result = dom_domtokenlist_remove(classList, tokens1, 1);
    assert(result == 0);
    assert(dom_domtokenlist_get_length(classList) == 5);
    assert(dom_domtokenlist_contains(classList, "foo") == 0);
    printf("  Removed single token 'foo'\n");
    
    // Remove multiple tokens
    const char* tokens2[] = {"bar", "qux", "disabled"};
    result = dom_domtokenlist_remove(classList, tokens2, 3);
    assert(result == 0);
    assert(dom_domtokenlist_get_length(classList) == 2);
    assert(dom_domtokenlist_contains(classList, "bar") == 0);
    assert(dom_domtokenlist_contains(classList, "qux") == 0);
    assert(dom_domtokenlist_contains(classList, "disabled") == 0);
    printf("  Removed multiple tokens\n");
    
    // Remove non-existent token (should be no-op)
    const char* tokens3[] = {"nonexistent"};
    result = dom_domtokenlist_remove(classList, tokens3, 1);
    assert(result == 0);
    assert(dom_domtokenlist_get_length(classList) == 2);
    printf("  Non-existent token removal handled correctly\n");
    
    // Verify remaining tokens
    assert(dom_domtokenlist_contains(classList, "baz") == 1);
    assert(dom_domtokenlist_contains(classList, "active") == 1);
    
    const char* value = dom_domtokenlist_get_value(classList);
    printf("  Final value: '%s'\n", value);
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ classList.remove() passed\n\n");
}

void test_classList_toggle() {
    printf("Test 4: classList.toggle()\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    dom_element_setattribute(elem, "class", "foo bar");
    
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    
    // Toggle existing token (should remove)
    uint8_t result = dom_domtokenlist_toggle(classList, "foo", -1);
    assert(result == 0); // false = removed
    assert(dom_domtokenlist_contains(classList, "foo") == 0);
    printf("  Toggled 'foo' off\n");
    
    // Toggle non-existent token (should add)
    result = dom_domtokenlist_toggle(classList, "baz", -1);
    assert(result == 1); // true = added
    assert(dom_domtokenlist_contains(classList, "baz") == 1);
    printf("  Toggled 'baz' on\n");
    
    // Force add (even if exists)
    dom_domtokenlist_toggle(classList, "bar", 1);
    assert(dom_domtokenlist_contains(classList, "bar") == 1);
    dom_domtokenlist_toggle(classList, "qux", 1);
    assert(dom_domtokenlist_contains(classList, "qux") == 1);
    printf("  Force add working\n");
    
    // Force remove (even if doesn't exist)
    dom_domtokenlist_toggle(classList, "bar", 0);
    assert(dom_domtokenlist_contains(classList, "bar") == 0);
    dom_domtokenlist_toggle(classList, "nonexistent", 0);
    assert(dom_domtokenlist_contains(classList, "nonexistent") == 0);
    printf("  Force remove working\n");
    
    const char* value = dom_domtokenlist_get_value(classList);
    printf("  Final value: '%s'\n", value);
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ classList.toggle() passed\n\n");
}

void test_classList_replace() {
    printf("Test 5: classList.replace()\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    dom_element_setattribute(elem, "class", "btn btn-primary active");
    
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    
    // Replace existing token
    uint8_t result = dom_domtokenlist_replace(classList, "btn-primary", "btn-secondary");
    assert(result == 1); // true = replaced
    assert(dom_domtokenlist_contains(classList, "btn-primary") == 0);
    assert(dom_domtokenlist_contains(classList, "btn-secondary") == 1);
    printf("  Replaced 'btn-primary' with 'btn-secondary'\n");
    
    // Try to replace non-existent token
    result = dom_domtokenlist_replace(classList, "nonexistent", "something");
    assert(result == 0); // false = not found
    printf("  Non-existent token replacement returned false\n");
    
    // Verify final state
    assert(dom_domtokenlist_get_length(classList) == 3);
    assert(dom_domtokenlist_contains(classList, "btn") == 1);
    assert(dom_domtokenlist_contains(classList, "btn-secondary") == 1);
    assert(dom_domtokenlist_contains(classList, "active") == 1);
    
    const char* value = dom_domtokenlist_get_value(classList);
    printf("  Final value: '%s'\n", value);
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ classList.replace() passed\n\n");
}

void test_classList_setValue() {
    printf("Test 6: classList value setter\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    dom_element_setattribute(elem, "class", "old classes here");
    
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    
    // Set new value (replaces all tokens)
    int result = dom_domtokenlist_set_value(classList, "new tokens here");
    assert(result == 0);
    
    const char* value = dom_domtokenlist_get_value(classList);
    assert(strcmp(value, "new tokens here") == 0);
    printf("  Set value to 'new tokens here'\n");
    
    // Verify tokens
    assert(dom_domtokenlist_get_length(classList) == 3);
    assert(dom_domtokenlist_contains(classList, "new") == 1);
    assert(dom_domtokenlist_contains(classList, "tokens") == 1);
    assert(dom_domtokenlist_contains(classList, "here") == 1);
    assert(dom_domtokenlist_contains(classList, "old") == 0);
    assert(dom_domtokenlist_contains(classList, "classes") == 0);
    printf("  Tokens updated correctly\n");
    
    // Set empty value
    result = dom_domtokenlist_set_value(classList, "");
    assert(result == 0);
    assert(dom_domtokenlist_get_length(classList) == 0);
    printf("  Set empty value\n");
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ classList value setter passed\n\n");
}

void test_classList_iteration() {
    printf("Test 7: classList iteration with item()\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    dom_element_setattribute(elem, "class", "alpha beta gamma delta epsilon");
    
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    
    uint32_t length = dom_domtokenlist_get_length(classList);
    printf("  Iterating %u tokens:\n", length);
    
    const char* expected[] = {"alpha", "beta", "gamma", "delta", "epsilon"};
    
    for (uint32_t i = 0; i < length; i++) {
        const char* token = dom_domtokenlist_item(classList, i);
        assert(token != NULL);
        printf("    [%u] = '%s'\n", i, token);
        assert(strcmp(token, expected[i]) == 0);
    }
    
    // Test out of bounds
    const char* oob = dom_domtokenlist_item(classList, 999);
    assert(oob == NULL);
    printf("  Out of bounds returns NULL\n");
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ classList iteration passed\n\n");
}

void test_classList_whitespace() {
    printf("Test 8: classList with various whitespace\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    // Multiple spaces, tabs, newlines (should normalize)
    dom_element_setattribute(elem, "class", "  foo    bar\t\tbaz\n\nqux  ");
    
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    
    uint32_t length = dom_domtokenlist_get_length(classList);
    printf("  Length: %u (expected 4)\n", length);
    assert(length == 4);
    
    assert(dom_domtokenlist_contains(classList, "foo") == 1);
    assert(dom_domtokenlist_contains(classList, "bar") == 1);
    assert(dom_domtokenlist_contains(classList, "baz") == 1);
    assert(dom_domtokenlist_contains(classList, "qux") == 1);
    printf("  All tokens found despite irregular whitespace\n");
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ Whitespace handling passed\n\n");
}

void test_classList_empty() {
    printf("Test 9: classList on element with no class attribute\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    // No class attribute set
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    assert(classList != NULL);
    
    uint32_t length = dom_domtokenlist_get_length(classList);
    printf("  Length: %u (expected 0)\n", length);
    assert(length == 0);
    
    const char* value = dom_domtokenlist_get_value(classList);
    printf("  Value: '%s' (expected empty)\n", value);
    assert(strcmp(value, "") == 0);
    
    // Add to empty list
    const char* tokens[] = {"first"};
    int result = dom_domtokenlist_add(classList, tokens, 1);
    assert(result == 0);
    assert(dom_domtokenlist_get_length(classList) == 1);
    assert(dom_domtokenlist_contains(classList, "first") == 1);
    printf("  Added token to empty list\n");
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ Empty classList operations passed\n\n");
}

void test_classList_supports() {
    printf("Test 10: classList.supports() (validation)\n");
    
    DOMDocument* doc = dom_document_new();
    DOMElement* elem = dom_document_createelement(doc, "container");
    
    DOMDOMTokenList* classList = dom_element_get_classlist(elem);
    
    // For classList, supports() should always return true (no validation)
    uint8_t result = dom_domtokenlist_supports(classList, "any-token");
    printf("  supports('any-token'): %u (expected 1)\n", result);
    assert(result == 1);
    
    result = dom_domtokenlist_supports(classList, "another-token");
    printf("  supports('another-token'): %u (expected 1)\n", result);
    assert(result == 1);
    
    printf("  Note: For classList, supports() always returns true\n");
    printf("  (Validation only applies to specific token lists like rel)\n");
    
    dom_domtokenlist_release(classList);
    dom_element_release(elem);
    dom_document_release(doc);
    
    printf("  ✓ classList.supports() passed\n\n");
}

int main() {
    printf("==============================================\n");
    printf("DOMTokenList C-ABI Tests\n");
    printf("==============================================\n\n");
    
    test_classList_basic();
    test_classList_add();
    test_classList_remove();
    test_classList_toggle();
    test_classList_replace();
    test_classList_setValue();
    test_classList_iteration();
    test_classList_whitespace();
    test_classList_empty();
    test_classList_supports();
    
    printf("==============================================\n");
    printf("All DOMTokenList tests passed! ✓\n");
    printf("==============================================\n");
    
    return 0;
}
