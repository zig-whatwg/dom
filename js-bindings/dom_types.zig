//! Common types and error codes for DOM JavaScript bindings
//!
//! This module provides shared types used across all DOM interface bindings,
//! including error code mappings from Zig errors to DOM exception codes.
//!
//! # Error Handling
//!
//! Functions that can fail return `c_int` status codes:
//! - `0` = Success
//! - Non-zero = DOMErrorCode (cast to get specific error)
//!
//! Example:
//! ```c
//! int result = dom_element_set_attribute(elem, "id", "foo");
//! if (result != 0) {
//!     // Error occurred
//!     DOMErrorCode error = (DOMErrorCode)result;
//!     const char* name = dom_error_code_name(error);
//!     printf("Error: %s\n", name);
//! }
//! ```
//!
//! # Memory Management
//!
//! All DOM objects use manual reference counting:
//! - `dom_*_addref()` - Increment reference count
//! - `dom_*_release()` - Decrement reference count (frees at zero)
//!
//! # String Ownership
//!
//! Strings returned from getters are **borrowed** - do NOT free them:
//! ```c
//! const char* tag = dom_element_get_tag_name(elem);
//! // Use tag, but don't free it!
//! ```
//!
//! Strings passed to setters are **copied** - you still own your string:
//! ```c
//! char* my_string = strdup("hello");
//! dom_element_set_attribute(elem, "title", my_string);
//! free(my_string);  // OK to free - DOM made a copy
//! ```

const std = @import("std");

// ============================================================================
// Opaque Type Definitions (C-ABI)
// ============================================================================

/// Opaque handle for DOM Document
pub const DOMDocument = opaque {};

/// Opaque handle for DOM Element
pub const DOMElement = opaque {};

/// Opaque handle for DOM Node
pub const DOMNode = opaque {};

/// Opaque handle for DOM Text
pub const DOMText = opaque {};

/// Opaque handle for DOM Comment
pub const DOMComment = opaque {};

/// Opaque handle for DOM CDATASection
pub const DOMCDATASection = opaque {};

/// Opaque handle for DOM ProcessingInstruction
pub const DOMProcessingInstruction = opaque {};

/// Opaque handle for DOM DocumentFragment
pub const DOMDocumentFragment = opaque {};

/// Opaque handle for DOM Attr
pub const DOMAttr = opaque {};

/// Opaque handle for DOM DOMTokenList
pub const DOMDOMTokenList = opaque {};

/// Opaque handle for DOM NamedNodeMap
pub const DOMNamedNodeMap = opaque {};

/// Opaque handle for DOM ShadowRoot
pub const DOMShadowRoot = opaque {};

/// Opaque handle for DOM CustomElementRegistry
pub const DOMCustomElementRegistry = opaque {};

/// Opaque handle for DOM NodeList
pub const DOMNodeList = opaque {};

/// Opaque handle for DOM HTMLCollection
pub const DOMHTMLCollection = opaque {};

/// Opaque handle for DOM DocumentType
pub const DOMDocumentType = opaque {};

/// Opaque handle for DOM DOMImplementation
pub const DOMDOMImplementation = opaque {};

/// Opaque handle for DOM Event
pub const DOMEvent = opaque {};

/// Opaque handle for DOM CustomEvent
pub const DOMCustomEvent = opaque {};

/// Opaque handle for DOM Range
pub const DOMRange = opaque {};

/// Opaque handle for DOM MutationObserver
pub const DOMMutationObserver = opaque {};

/// Opaque handle for DOM MutationRecord
pub const DOMMutationRecord = opaque {};

/// Opaque handle for DOM TreeWalker
pub const DOMTreeWalker = opaque {};

/// Opaque handle for DOM NodeIterator
pub const DOMNodeIterator = opaque {};

// ============================================================================
// DOM Error Codes
// ============================================================================

/// DOM exception error codes
///
/// These match the DOMException codes defined in the DOM specification:
/// https://webidl.spec.whatwg.org/#idl-DOMException-error-names
///
/// WebIDL defines these as DOMString names, but we use numeric codes
/// for C-ABI compatibility. The mapping is:
///
/// | Name                        | Legacy Code | Modern Equivalent      |
/// |-----------------------------|-------------|------------------------|
/// | IndexSizeError              | 1           | RangeError             |
/// | HierarchyRequestError       | 3           | -                      |
/// | WrongDocumentError          | 4           | -                      |
/// | InvalidCharacterError       | 5           | -                      |
/// | NoModificationAllowedError  | 7           | -                      |
/// | NotFoundError               | 8           | -                      |
/// | NotSupportedError           | 9           | -                      |
/// | InUseAttributeError         | 10          | -                      |
/// | InvalidStateError           | 11          | -                      |
/// | SyntaxError                 | 12          | SyntaxError            |
/// | InvalidModificationError    | 13          | -                      |
/// | NamespaceError              | 14          | -                      |
/// | InvalidAccessError          | 15          | -                      |
/// | TypeMismatchError           | 17          | TypeError              |
/// | SecurityError               | 18          | -                      |
/// | NetworkError                | 19          | -                      |
/// | AbortError                  | 20          | AbortError             |
/// | URLMismatchError            | 21          | -                      |
/// | QuotaExceededError          | 22          | QuotaExceededError     |
/// | TimeoutError                | 23          | -                      |
/// | InvalidNodeTypeError        | 24          | -                      |
/// | DataCloneError              | 25          | DataCloneError         |
///
pub const DOMErrorCode = enum(c_int) {
    /// No error (success)
    Success = 0,

    /// Index or size is negative or greater than allowed
    /// Spec: https://webidl.spec.whatwg.org/#indexsizeerror
    IndexSizeError = 1,

    /// A Node is inserted somewhere it doesn't belong
    /// Spec: https://dom.spec.whatwg.org/#hierarchyrequesterror
    HierarchyRequestError = 3,

    /// A Node is used in a different document than the one that created it
    /// Spec: https://dom.spec.whatwg.org/#wrongdocumenterror
    WrongDocumentError = 4,

    /// String contains invalid characters
    /// Spec: https://dom.spec.whatwg.org/#invalidcharactererror
    InvalidCharacterError = 5,

    /// Object cannot be modified
    /// Spec: https://webidl.spec.whatwg.org/#nomodificationallowederror
    NoModificationAllowedError = 7,

    /// Object cannot be found
    /// Spec: https://webidl.spec.whatwg.org/#notfounderror
    NotFoundError = 8,

    /// Operation is not supported
    /// Spec: https://webidl.spec.whatwg.org/#notsupportederror
    NotSupportedError = 9,

    /// Attribute is already in use
    /// Spec: https://dom.spec.whatwg.org/#inuseattributeerror
    InUseAttributeError = 10,

    /// Object is in an invalid state
    /// Spec: https://webidl.spec.whatwg.org/#invalidstateerror
    InvalidStateError = 11,

    /// String did not match expected pattern
    /// Spec: https://webidl.spec.whatwg.org/#syntaxerror
    SyntaxError = 12,

    /// Object cannot be modified in this way
    /// Spec: https://webidl.spec.whatwg.org/#invalidmodificationerror
    InvalidModificationError = 13,

    /// Operation violates namespace rules
    /// Spec: https://dom.spec.whatwg.org/#namespaceerror
    NamespaceError = 14,

    /// Object does not support the operation or argument
    /// Spec: https://webidl.spec.whatwg.org/#invalidaccesserror
    InvalidAccessError = 15,

    /// Type of object does not match expected type
    /// Spec: https://webidl.spec.whatwg.org/#typemismatcherror
    TypeMismatchError = 17,

    /// Operation is insecure
    /// Spec: https://webidl.spec.whatwg.org/#securityerror
    SecurityError = 18,

    /// Network error occurred
    /// Spec: https://webidl.spec.whatwg.org/#networkerror
    NetworkError = 19,

    /// Operation was aborted
    /// Spec: https://webidl.spec.whatwg.org/#aborterror
    AbortError = 20,

    /// URL does not match another URL
    /// Spec: https://webidl.spec.whatwg.org/#urlmismatcherror
    URLMismatchError = 21,

    /// Quota has been exceeded
    /// Spec: https://webidl.spec.whatwg.org/#quotaexceedederror
    QuotaExceededError = 22,

    /// Operation timed out
    /// Spec: https://webidl.spec.whatwg.org/#timeouterror
    TimeoutError = 23,

    /// Node type is incorrect for this operation
    /// Spec: https://dom.spec.whatwg.org/#invalidnodetypeerror
    InvalidNodeTypeError = 24,

    /// Object cannot be cloned
    /// Spec: https://webidl.spec.whatwg.org/#datacloneerror
    DataCloneError = 25,

    /// Unknown or unmapped error
    UnknownError = 999,
};

/// Convert Zig error to DOM error code
///
/// This function maps Zig error values (from the DOM implementation)
/// to standardized DOM exception codes that JavaScript engines expect.
///
/// # Parameters
/// - `err`: Zig error value from DOM operation
///
/// # Returns
/// Corresponding DOMErrorCode
///
/// # Example
/// ```zig
/// elem.setAttribute(name, value) catch |err| {
///     return @intFromEnum(zigErrorToDOMError(err));
/// };
/// ```
pub fn zigErrorToDOMError(err: anyerror) DOMErrorCode {
    return switch (err) {
        // Map specific Zig errors to DOM error codes
        error.IndexSizeError => .IndexSizeError,
        error.HierarchyRequestError => .HierarchyRequestError,
        error.WrongDocumentError => .WrongDocumentError,
        error.InvalidCharacterError => .InvalidCharacterError,
        error.NoModificationAllowedError => .NoModificationAllowedError,
        error.NotFoundError => .NotFoundError,
        error.NotSupportedError => .NotSupportedError,
        error.InUseAttributeError => .InUseAttributeError,
        error.InvalidStateError => .InvalidStateError,
        error.SyntaxError, error.InvalidSelector => .SyntaxError,
        error.InvalidModificationError => .InvalidModificationError,
        error.NamespaceError => .NamespaceError,
        error.InvalidAccessError => .InvalidAccessError,
        error.TypeMismatchError => .TypeMismatchError,
        error.SecurityError => .SecurityError,
        error.NetworkError => .NetworkError,
        error.AbortError => .AbortError,
        error.URLMismatchError => .URLMismatchError,
        error.QuotaExceededError => .QuotaExceededError,
        error.TimeoutError => .TimeoutError,
        error.InvalidNodeTypeError => .InvalidNodeTypeError,
        error.DataCloneError => .DataCloneError,

        // Memory errors (map to appropriate DOM error)
        error.OutOfMemory => .QuotaExceededError,

        // Generic fallback
        else => .UnknownError,
    };
}

/// Get error code name as string
///
/// Returns a null-terminated string with the DOMException name.
/// Useful for debugging and error messages.
///
/// # Parameters
/// - `code`: Error code
///
/// # Returns
/// Null-terminated string (do NOT free)
///
/// # Example
/// ```c
/// int result = dom_node_append_child(parent, child);
/// if (result != 0) {
///     const char* name = dom_error_code_name((DOMErrorCode)result);
///     fprintf(stderr, "DOM Error: %s\n", name);
/// }
/// ```
pub export fn dom_error_code_name(code: DOMErrorCode) [*:0]const u8 {
    return switch (code) {
        .Success => "Success",
        .IndexSizeError => "IndexSizeError",
        .HierarchyRequestError => "HierarchyRequestError",
        .WrongDocumentError => "WrongDocumentError",
        .InvalidCharacterError => "InvalidCharacterError",
        .NoModificationAllowedError => "NoModificationAllowedError",
        .NotFoundError => "NotFoundError",
        .NotSupportedError => "NotSupportedError",
        .InUseAttributeError => "InUseAttributeError",
        .InvalidStateError => "InvalidStateError",
        .SyntaxError => "SyntaxError",
        .InvalidModificationError => "InvalidModificationError",
        .NamespaceError => "NamespaceError",
        .InvalidAccessError => "InvalidAccessError",
        .TypeMismatchError => "TypeMismatchError",
        .SecurityError => "SecurityError",
        .NetworkError => "NetworkError",
        .AbortError => "AbortError",
        .URLMismatchError => "URLMismatchError",
        .QuotaExceededError => "QuotaExceededError",
        .TimeoutError => "TimeoutError",
        .InvalidNodeTypeError => "InvalidNodeTypeError",
        .DataCloneError => "DataCloneError",
        .UnknownError => "UnknownError",
    };
}

/// Get error code message as string
///
/// Returns a null-terminated string with a human-readable error message.
///
/// # Parameters
/// - `code`: Error code
///
/// # Returns
/// Null-terminated string (do NOT free)
///
/// # Example
/// ```c
/// const char* msg = dom_error_code_message(DOMErrorCode_InvalidCharacterError);
/// // msg = "String contains invalid characters"
/// ```
pub export fn dom_error_code_message(code: DOMErrorCode) [*:0]const u8 {
    return switch (code) {
        .Success => "Operation succeeded",
        .IndexSizeError => "Index or size is negative or greater than allowed",
        .HierarchyRequestError => "Node is inserted somewhere it doesn't belong",
        .WrongDocumentError => "Node is used in a different document",
        .InvalidCharacterError => "String contains invalid characters",
        .NoModificationAllowedError => "Object cannot be modified",
        .NotFoundError => "Object cannot be found",
        .NotSupportedError => "Operation is not supported",
        .InUseAttributeError => "Attribute is already in use",
        .InvalidStateError => "Object is in an invalid state",
        .SyntaxError => "String did not match expected pattern",
        .InvalidModificationError => "Object cannot be modified in this way",
        .NamespaceError => "Operation violates namespace rules",
        .InvalidAccessError => "Object does not support the operation or argument",
        .TypeMismatchError => "Type does not match expected type",
        .SecurityError => "Operation is insecure",
        .NetworkError => "Network error occurred",
        .AbortError => "Operation was aborted",
        .URLMismatchError => "URL does not match another URL",
        .QuotaExceededError => "Quota has been exceeded",
        .TimeoutError => "Operation timed out",
        .InvalidNodeTypeError => "Node type is incorrect for this operation",
        .DataCloneError => "Object cannot be cloned",
        .UnknownError => "An unknown error occurred",
    };
}

test "error code names" {
    const testing = std.testing;

    try testing.expectEqualStrings("Success", std.mem.span(dom_error_code_name(.Success)));
    try testing.expectEqualStrings("SyntaxError", std.mem.span(dom_error_code_name(.SyntaxError)));
    try testing.expectEqualStrings("NotFoundError", std.mem.span(dom_error_code_name(.NotFoundError)));
}

test "zig error conversion" {
    const testing = std.testing;

    try testing.expectEqual(DOMErrorCode.SyntaxError, zigErrorToDOMError(error.SyntaxError));
    try testing.expectEqual(DOMErrorCode.SyntaxError, zigErrorToDOMError(error.InvalidSelector));
    try testing.expectEqual(DOMErrorCode.NotFoundError, zigErrorToDOMError(error.NotFoundError));
    try testing.expectEqual(DOMErrorCode.QuotaExceededError, zigErrorToDOMError(error.OutOfMemory));
    try testing.expectEqual(DOMErrorCode.UnknownError, zigErrorToDOMError(error.Unexpected));
}

// ============================================================================
// String Conversion Helpers (C-ABI ↔ Zig)
// ============================================================================

/// Converts a Zig string slice to a C null-terminated string pointer.
///
/// This is safe for strings returned from the DOM because:
/// 1. Document.string_pool stores all strings with null terminators (dupeZ)
/// 2. Element tag_name, attribute names/values are all interned
/// 3. Text node data is stored with null terminator
///
/// ## Safety
/// The input slice MUST have a null terminator at slice.ptr[slice.len].
/// This is guaranteed for all strings from the DOM implementation.
///
/// ## Example
/// ```zig
/// const node_name = node.nodeName(); // Returns []const u8
/// const c_str = zigStringToCString(node_name); // Returns [*:0]const u8
/// ```
pub inline fn zigStringToCString(slice: []const u8) [*:0]const u8 {
    return @ptrCast(slice.ptr);
}

/// Converts a C null-terminated string to a Zig string slice.
///
/// Uses std.mem.span to find the null terminator and create a slice.
///
/// ## Example
/// ```zig
/// export fn dom_node_set_nodevalue(handle: *DOMNode, value: [*:0]const u8) c_int {
///     const zig_str = cStringToZigString(value);
///     // Use zig_str as []const u8
/// }
/// ```
pub inline fn cStringToZigString(c_str: [*:0]const u8) []const u8 {
    return std.mem.span(c_str);
}

/// Converts an optional Zig string to an optional C string.
///
/// Returns null if the input is null, otherwise converts the string.
pub inline fn zigStringToCStringOptional(slice: ?[]const u8) ?[*:0]const u8 {
    if (slice) |s| {
        return zigStringToCString(s);
    }
    return null;
}

/// Converts an optional C string to an optional Zig string.
///
/// Returns null if the input is null, otherwise converts the string.
pub inline fn cStringToZigStringOptional(c_str: ?[*:0]const u8) ?[]const u8 {
    if (c_str) |s| {
        return cStringToZigString(s);
    }
    return null;
}

test "string conversion helpers" {
    const testing = std.testing;

    // Test non-optional conversion
    const zig_str = "hello";
    const c_str = zigStringToCString(zig_str);
    try testing.expectEqual(@as(u8, 'h'), c_str[0]);
    try testing.expectEqual(@as(u8, 0), c_str[5]);

    // Test round-trip
    const back_to_zig = cStringToZigString(c_str);
    try testing.expectEqualStrings(zig_str, back_to_zig);

    // Test optional null
    const null_zig: ?[]const u8 = null;
    const null_c = zigStringToCStringOptional(null_zig);
    try testing.expectEqual(@as(?[*:0]const u8, null), null_c);

    // Test optional with value
    const some_zig: ?[]const u8 = "world";
    const some_c = zigStringToCStringOptional(some_zig);
    try testing.expect(some_c != null);
    const back_optional = cStringToZigStringOptional(some_c);
    try testing.expect(back_optional != null);
    try testing.expectEqualStrings("world", back_optional.?);
}
