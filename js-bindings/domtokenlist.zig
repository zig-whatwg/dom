//! DOMTokenList C-ABI Bindings
//!
//! C-ABI bindings for the DOMTokenList interface per WHATWG DOM specification.
//! DOMTokenList represents a set of space-separated tokens (most commonly used
//! for Element.classList).
//!
//! ## C API Overview
//!
//! ```c
//! // Get DOMTokenList
//! DOMDOMTokenList* dom_element_get_classlist(DOMElement* elem);
//!
//! // Properties
//! uint32_t dom_domtokenlist_get_length(DOMDOMTokenList* list);
//! const char* dom_domtokenlist_get_value(DOMDOMTokenList* list);
//! int dom_domtokenlist_set_value(DOMDOMTokenList* list, const char* value);
//!
//! // Query
//! const char* dom_domtokenlist_item(DOMDOMTokenList* list, uint32_t index);
//! uint8_t dom_domtokenlist_contains(DOMDOMTokenList* list, const char* token);
//! uint8_t dom_domtokenlist_supports(DOMDOMTokenList* list, const char* token);
//!
//! // Modification
//! int dom_domtokenlist_add(DOMDOMTokenList* list, const char** tokens, uint32_t count);
//! int dom_domtokenlist_remove(DOMDOMTokenList* list, const char** tokens, uint32_t count);
//! uint8_t dom_domtokenlist_toggle(DOMDOMTokenList* list, const char* token, int8_t force);
//! uint8_t dom_domtokenlist_replace(DOMDOMTokenList* list, const char* token, const char* newToken);
//!
//! // Release
//! void dom_domtokenlist_release(DOMDOMTokenList* list);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface DOMTokenList {
//!   readonly attribute unsigned long length;
//!   getter DOMString? item(unsigned long index);
//!   boolean contains(DOMString token);
//!   [CEReactions] undefined add(DOMString... tokens);
//!   [CEReactions] undefined remove(DOMString... tokens);
//!   [CEReactions] boolean toggle(DOMString token, optional boolean force);
//!   [CEReactions] boolean replace(DOMString token, DOMString newToken);
//!   boolean supports(DOMString token);
//!   [CEReactions] stringifier attribute DOMString value;
//!   iterable<DOMString>;
//! };
//! ```
//!
//! ## WHATWG Specification
//!
//! - DOMTokenList interface: https://dom.spec.whatwg.org/#domtokenlist
//! - Element.classList: https://dom.spec.whatwg.org/#dom-element-classlist
//!
//! ## MDN Documentation
//!
//! - DOMTokenList: https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList
//! - DOMTokenList.add(): https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/add
//! - DOMTokenList.remove(): https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/remove
//! - DOMTokenList.toggle(): https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/toggle

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const DOMTokenList = dom.DOMTokenList;
const DOMDOMTokenList = types.DOMDOMTokenList;
const DOMErrorCode = types.DOMErrorCode;
const zigErrorToDOMError = types.zigErrorToDOMError;
const zigStringToCString = types.zigStringToCString;
const zigStringToCStringOptional = types.zigStringToCStringOptional;
const cStringToZigString = types.cStringToZigString;

// ============================================================================
// C-ABI Token Cache
// ============================================================================

/// C-ABI wrapper that caches returned tokens as null-terminated strings.
/// The Zig DOMTokenList.item() returns slices into the attribute value string,
/// which aren't properly null-terminated for C. This uses a rotating buffer
/// to cache the last 8 tokens returned by item().
pub const TokenListWrapper = struct {
    token_list: DOMTokenList,
    token_buffers: [8][256:0]u8 = undefined, // 8 buffers for rotating cache (max 255 chars each)
    next_buffer_index: usize = 0,
};

// ============================================================================
// Properties
// ============================================================================

/// Get the length of a DOMTokenList.
///
/// Returns the number of unique tokens in the list. Duplicates are not counted.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long length;
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
///
/// ## Returns
/// Number of unique tokens in the list
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// uint32_t count = dom_domtokenlist_get_length(classList);
/// printf("Element has %u classes\n", count);
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-length
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/length
pub export fn dom_domtokenlist_get_length(list: *DOMDOMTokenList) u32 {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    return @intCast(wrapper.token_list.length());
}

/// Get the value attribute (string representation of tokens).
///
/// Returns the underlying attribute value as a space-separated string.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] stringifier attribute DOMString value;
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
///
/// ## Returns
/// Space-separated token string (borrowed, do NOT free)
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// const char* value = dom_domtokenlist_get_value(classList);
/// printf("Classes: %s\n", value);
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-value
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/value
pub export fn dom_domtokenlist_get_value(list: *DOMDOMTokenList) [*:0]const u8 {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const value = wrapper.token_list.value();
    return zigStringToCString(value);
}

/// Set the value attribute (replace all tokens).
///
/// Replaces the entire token list with the space-separated tokens in value.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] stringifier attribute DOMString value;
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
/// - `value`: Space-separated token string
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// int result = dom_domtokenlist_set_value(classList, "btn btn-primary active");
/// if (result != 0) {
///     printf("Error setting value\n");
/// }
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-value
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/value
pub export fn dom_domtokenlist_set_value(list: *DOMDOMTokenList, value: [*:0]const u8) c_int {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const value_slice = cStringToZigString(value);

    wrapper.token_list.setValue(value_slice) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    // Reset buffer rotation (optional, but keeps behavior predictable)
    wrapper.next_buffer_index = 0;

    return 0; // Success
}

// ============================================================================
// Query Methods
// ============================================================================

/// Get a token at a specific index.
///
/// Returns the token at the specified index, or null if out of bounds.
///
/// ## WebIDL
/// ```webidl
/// getter DOMString? item(unsigned long index);
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
/// - `index`: Zero-based index
///
/// ## Returns
/// Token at index (borrowed, do NOT free), or null if out of bounds
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// uint32_t count = dom_domtokenlist_get_length(classList);
/// for (uint32_t i = 0; i < count; i++) {
///     const char* token = dom_domtokenlist_item(classList, i);
///     if (token != NULL) {
///         printf("Token %u: %s\n", i, token);
///     }
/// }
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-item
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/item
pub export fn dom_domtokenlist_item(list: *DOMDOMTokenList, index: u32) ?[*:0]const u8 {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const token = wrapper.token_list.item(@intCast(index));
    if (token) |t| {
        // Use rotating buffer to cache tokens
        const buffer_idx = wrapper.next_buffer_index % wrapper.token_buffers.len;
        var buf = &wrapper.token_buffers[buffer_idx];

        // Copy token to buffer with null terminator
        if (t.len >= buf.len) {
            // Token too long for buffer
            return null;
        }
        @memcpy(buf[0..t.len], t);
        buf[t.len] = 0;

        // Move to next buffer for next call
        wrapper.next_buffer_index = (wrapper.next_buffer_index + 1) % wrapper.token_buffers.len;

        return @ptrCast(buf);
    }
    return null;
}

/// Check if a token exists in the list.
///
/// ## WebIDL
/// ```webidl
/// boolean contains(DOMString token);
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
/// - `token`: Token to search for
///
/// ## Returns
/// 1 if token exists, 0 otherwise
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// if (dom_domtokenlist_contains(classList, "active")) {
///     printf("Element is active\n");
/// }
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-contains
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/contains
pub export fn dom_domtokenlist_contains(list: *DOMDOMTokenList, token: [*:0]const u8) u8 {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const token_slice = cStringToZigString(token);
    return if (wrapper.token_list.contains(token_slice)) 1 else 0;
}

/// Check if a token is supported (validation).
///
/// Returns true if the token would be valid for this token list.
/// Currently always returns true (validation not implemented).
///
/// ## WebIDL
/// ```webidl
/// boolean supports(DOMString token);
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
/// - `token`: Token to validate
///
/// ## Returns
/// 1 if token is supported, 0 otherwise
///
/// ## Note
/// This method is primarily used for validating tokens in specific contexts
/// (e.g., rel attribute values). For generic class lists, it always returns true.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-supports
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/supports
pub export fn dom_domtokenlist_supports(list: *DOMDOMTokenList, token: [*:0]const u8) u8 {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const token_slice = cStringToZigString(token);

    const result = wrapper.token_list.supports(token_slice);

    return if (result) 1 else 0;
}

// ============================================================================
// Modification Methods
// ============================================================================

/// Add one or more tokens to the list.
///
/// Adds the specified tokens to the list if they don't already exist.
/// Duplicates are ignored (ordered set behavior).
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] undefined add(DOMString... tokens);
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
/// - `tokens`: Array of token strings
/// - `count`: Number of tokens in array
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// const char* tokens[] = {"btn", "btn-primary", "active"};
/// int result = dom_domtokenlist_add(classList, tokens, 3);
/// if (result != 0) {
///     printf("Error adding tokens\n");
/// }
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-add
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/add
pub export fn dom_domtokenlist_add(list: *DOMDOMTokenList, tokens: [*]const [*:0]const u8, count: u32) c_int {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const allocator = std.heap.page_allocator;

    // Convert C string array to Zig slice array
    const token_slices = allocator.alloc([]const u8, count) catch {
        return @intFromEnum(DOMErrorCode.QuotaExceededError);
    };
    defer allocator.free(token_slices);

    for (0..count) |i| {
        token_slices[i] = cStringToZigString(tokens[i]);
    }

    wrapper.token_list.add(token_slices) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0; // Success
}

/// Remove one or more tokens from the list.
///
/// Removes the specified tokens from the list if they exist.
/// Non-existent tokens are ignored.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] undefined remove(DOMString... tokens);
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
/// - `tokens`: Array of token strings
/// - `count`: Number of tokens in array
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// const char* tokens[] = {"active", "disabled"};
/// int result = dom_domtokenlist_remove(classList, tokens, 2);
/// if (result != 0) {
///     printf("Error removing tokens\n");
/// }
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-remove
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/remove
pub export fn dom_domtokenlist_remove(list: *DOMDOMTokenList, tokens: [*]const [*:0]const u8, count: u32) c_int {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const allocator = std.heap.page_allocator;

    // Convert C string array to Zig slice array
    const token_slices = allocator.alloc([]const u8, count) catch {
        return @intFromEnum(DOMErrorCode.QuotaExceededError);
    };
    defer allocator.free(token_slices);

    for (0..count) |i| {
        token_slices[i] = cStringToZigString(tokens[i]);
    }

    wrapper.token_list.remove(token_slices) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0; // Success
}

/// Toggle a token in the list.
///
/// If the token exists, removes it and returns false.
/// If the token doesn't exist, adds it and returns true.
/// Optional force parameter: 1 = always add, 0 = always remove, -1 = toggle.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] boolean toggle(DOMString token, optional boolean force);
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
/// - `token`: Token to toggle
/// - `force`: -1 = toggle, 0 = force remove, 1 = force add
///
/// ## Returns
/// 1 if token is now present, 0 if now absent
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
///
/// // Toggle (add if absent, remove if present)
/// uint8_t is_active = dom_domtokenlist_toggle(classList, "active", -1);
/// printf("Active: %d\n", is_active);
///
/// // Force add
/// dom_domtokenlist_toggle(classList, "enabled", 1);
///
/// // Force remove
/// dom_domtokenlist_toggle(classList, "disabled", 0);
///
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-toggle
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/toggle
pub export fn dom_domtokenlist_toggle(list: *DOMDOMTokenList, token: [*:0]const u8, force: i8) u8 {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const token_slice = cStringToZigString(token);

    // Convert C force (-1, 0, 1) to Zig optional bool
    const force_opt: ?bool = if (force == -1) null else if (force == 0) false else true;

    const result = wrapper.token_list.toggle(token_slice, force_opt) catch {
        return 0; // Error = token not present
    };

    return if (result) 1 else 0;
}

/// Replace a token with a new token.
///
/// Replaces the first occurrence of token with newToken.
/// Returns true if replacement occurred, false if token didn't exist.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] boolean replace(DOMString token, DOMString newToken);
/// ```
///
/// ## Parameters
/// - `list`: DOMTokenList handle
/// - `token`: Token to replace
/// - `newToken`: Replacement token
///
/// ## Returns
/// 1 if replacement occurred, 0 if token didn't exist
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// if (dom_domtokenlist_replace(classList, "btn-primary", "btn-secondary")) {
///     printf("Replaced primary with secondary\n");
/// } else {
///     printf("Primary class not found\n");
/// }
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-domtokenlist-replace
/// - https://developer.mozilla.org/en-US/docs/Web/API/DOMTokenList/replace
pub export fn dom_domtokenlist_replace(list: *DOMDOMTokenList, token: [*:0]const u8, new_token: [*:0]const u8) u8 {
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    const token_slice = cStringToZigString(token);
    const new_token_slice = cStringToZigString(new_token);

    const result = wrapper.token_list.replace(token_slice, new_token_slice) catch {
        return 0; // Error = replacement failed
    };

    return if (result) 1 else 0;
}

// ============================================================================
// Memory Management
// ============================================================================

/// Release a DOMTokenList.
///
/// DOMTokenList is a value type in Zig but heap-allocated for C interop.
/// Call this when done with a DOMTokenList returned from the API.
///
/// ## Parameters
/// - `list`: DOMTokenList handle to release
///
/// ## Example
/// ```c
/// DOMDOMTokenList* classList = dom_element_get_classlist(elem);
/// // ... use classList ...
/// dom_domtokenlist_release(classList);
/// ```
///
/// ## Note
/// DOMTokenList doesn't own the element or attribute. Releasing the list
/// does NOT affect the element's class attribute.
pub export fn dom_domtokenlist_release(list: *DOMDOMTokenList) void {
    const allocator = std.heap.page_allocator;
    const wrapper: *TokenListWrapper = @ptrCast(@alignCast(list));
    allocator.destroy(wrapper);
}
