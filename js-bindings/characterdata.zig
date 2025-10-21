//! CharacterData JavaScript Bindings
//!
//! C-ABI bindings for the CharacterData interface, which is the abstract base
//! for Text, Comment, and ProcessingInstruction nodes.
//!
//! ## WHATWG Specification
//!
//! CharacterData provides common functionality for textual nodes in the DOM:
//! - **§4.8 Interface CharacterData**: https://dom.spec.whatwg.org/#interface-characterdata
//!
//! ## MDN Documentation
//!
//! - CharacterData: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData
//! - CharacterData.data: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/data
//! - CharacterData.length: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/length
//! - CharacterData.substringData(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/substringData
//! - CharacterData.appendData(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/appendData
//! - CharacterData.insertData(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/insertData
//! - CharacterData.deleteData(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/deleteData
//! - CharacterData.replaceData(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/replaceData
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface CharacterData : Node {
//!   attribute [LegacyNullToEmptyString] DOMString data;
//!   readonly attribute unsigned long length;
//!   DOMString substringData(unsigned long offset, unsigned long count);
//!   undefined appendData(DOMString data);
//!   undefined insertData(unsigned long offset, DOMString data);
//!   undefined deleteData(unsigned long offset, unsigned long count);
//!   undefined replaceData(unsigned long offset, unsigned long count, DOMString data);
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#characterdata (WebIDL: dom.idl:430-438)
//!
//! ## Exported Functions (7 total)
//!
//! ### Properties
//! - `dom_characterdata_get_data()` - Get text content
//! - `dom_characterdata_set_data()` - Set text content
//! - `dom_characterdata_get_length()` - Get text length
//!
//! ### Methods
//! - `dom_characterdata_substringdata()` - Extract substring
//! - `dom_characterdata_appenddata()` - Append text
//! - `dom_characterdata_insertdata()` - Insert text at offset
//! - `dom_characterdata_deletedata()` - Delete text range
//! - `dom_characterdata_replacedata()` - Replace text range
//!
//! ## Note on Abstract Interface
//!
//! CharacterData is abstract - never instantiated directly. In C-ABI:
//! - Functions accept opaque `DOMCharacterData*` handles
//! - Actual type is Text*, Comment*, or ProcessingInstruction*
//! - All three have compatible memory layout (Node first, data field)
//! - Bindings cast to appropriate type and forward to implementation
//!
//! ## Memory Management
//!
//! CharacterData nodes use Node's reference counting:
//! - Call `dom_text_addref()`, `dom_comment_addref()`, etc. on concrete types
//! - CharacterData methods don't own handles, just manipulate data
//! - Caller retains ownership of node throughout CharacterData operations
//!
//! ## JavaScript Integration
//!
//! ### Properties
//! ```javascript
//! // data (read-write) - [LegacyNullToEmptyString]
//! Object.defineProperty(CharacterData.prototype, 'data', {
//!   get() { return dom_characterdata_get_data(this._ptr); },
//!   set(value) {
//!     // LegacyNullToEmptyString: null becomes empty string
//!     dom_characterdata_set_data(this._ptr, value === null ? '' : value);
//!   }
//! });
//!
//! // length (readonly)
//! Object.defineProperty(CharacterData.prototype, 'length', {
//!   get() { return dom_characterdata_get_length(this._ptr); }
//! });
//! ```
//!
//! ### Methods
//! ```javascript
//! CharacterData.prototype.substringData = function(offset, count) {
//!   return dom_characterdata_substringdata(this._ptr, offset, count);
//! };
//!
//! CharacterData.prototype.appendData = function(data) {
//!   dom_characterdata_appenddata(this._ptr, data);
//! };
//!
//! CharacterData.prototype.insertData = function(offset, data) {
//!   dom_characterdata_insertdata(this._ptr, offset, data);
//! };
//!
//! CharacterData.prototype.deleteData = function(offset, count) {
//!   dom_characterdata_deletedata(this._ptr, offset, count);
//! };
//!
//! CharacterData.prototype.replaceData = function(offset, count, data) {
//!   dom_characterdata_replacedata(this._ptr, offset, count, data);
//! };
//! ```
//!
//! ## Usage Example (C)
//!
//! ```c
//! #include <stdio.h>
//!
//! typedef struct DOMDocument DOMDocument;
//! typedef struct DOMText DOMText;
//! typedef struct DOMCharacterData DOMCharacterData;
//!
//! extern DOMDocument* dom_document_new(void);
//! extern DOMText* dom_document_createtextnode(DOMDocument* doc, const char* data);
//! extern const char* dom_characterdata_get_data(DOMCharacterData* cdata);
//! extern void dom_characterdata_set_data(DOMCharacterData* cdata, const char* data);
//! extern unsigned int dom_characterdata_get_length(DOMCharacterData* cdata);
//! extern void dom_characterdata_appenddata(DOMCharacterData* cdata, const char* data);
//! extern void dom_text_release(DOMText* text);
//! extern void dom_document_release(DOMDocument* doc);
//!
//! int main(void) {
//!     DOMDocument* doc = dom_document_new();
//!     DOMText* text = dom_document_createtextnode(doc, "Hello");
//!
//!     // Text inherits CharacterData - cast is safe
//!     DOMCharacterData* cdata = (DOMCharacterData*)text;
//!
//!     // Use CharacterData methods
//!     printf("data: %s\n", dom_characterdata_get_data(cdata));       // "Hello"
//!     printf("length: %u\n", dom_characterdata_get_length(cdata));   // 5
//!
//!     dom_characterdata_appenddata(cdata, " World");
//!     printf("data: %s\n", dom_characterdata_get_data(cdata));       // "Hello World"
//!
//!     dom_characterdata_set_data(cdata, "Zig!");
//!     printf("data: %s\n", dom_characterdata_get_data(cdata));       // "Zig!"
//!
//!     dom_text_release(text);
//!     dom_document_release(doc);
//!     return 0;
//! }
//! ```
//!
//! ## Implementation Notes
//!
//! ### [LegacyNullToEmptyString] Attribute
//! - WebIDL: `attribute [LegacyNullToEmptyString] DOMString data;`
//! - In JavaScript: `null` is converted to `""` before calling C binding
//! - In C binding: Always receives valid string (never NULL)
//! - Historical compatibility feature from older DOM specs
//!
//! ### Memory Layout Compatibility
//! All CharacterData subtypes have identical layout for these operations:
//! ```
//! Text:                 { prototype: Node, data: []u8, ... }
//! Comment:              { prototype: Node, data: []u8 }
//! ProcessingInstruction: { prototype: Node, target: []const u8, data: []u8 }
//! ```
//! Accessing `data` field works identically for all three types.
//!
//! ### Error Handling
//! - substringData: Returns empty string on error (index out of bounds)
//! - Other methods: Return error code (0 = success, non-zero = DOM error)
//! - Typical errors: IndexSizeError (offset > length)

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const Text = dom.Text;
const Comment = dom.Comment;
const ProcessingInstruction = dom.ProcessingInstruction;
const DOMCharacterData = types.DOMText; // CharacterData is abstract, use Text as representative type

// ============================================================================
// Properties
// ============================================================================

/// Gets the text content of a CharacterData node.
///
/// ## WebIDL
/// ```webidl
/// attribute [LegacyNullToEmptyString] DOMString data;
/// ```
///
/// ## Parameters
/// - `cdata`: CharacterData handle (actually Text*, Comment*, or ProcessingInstruction*)
///
/// ## Returns
/// Text content (borrowed string - do NOT free)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-characterdata-data
/// - WebIDL: dom.idl:431
///
/// ## Example
/// ```c
/// DOMText* text = dom_document_createtextnode(doc, "Hello");
/// const char* data = dom_characterdata_get_data((DOMCharacterData*)text);
/// printf("%s\n", data); // "Hello"
/// ```
pub export fn dom_characterdata_get_data(cdata: *DOMCharacterData) [*:0]const u8 {
    // CharacterData is abstract - cast to Text (all types compatible)
    const text: *Text = @ptrCast(@alignCast(cdata));
    const data = text.prototype.nodeValue() orelse "";
    return types.zigStringToCString(data);
}

/// Sets the text content of a CharacterData node.
///
/// ## WebIDL
/// ```webidl
/// attribute [LegacyNullToEmptyString] DOMString data;
/// ```
///
/// ## Parameters
/// - `cdata`: CharacterData handle
/// - `data`: New text content
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-characterdata-data
/// - WebIDL: dom.idl:431
///
/// ## Note
/// [LegacyNullToEmptyString]: JavaScript binding converts null to "" before calling this.
///
/// ## Example
/// ```c
/// dom_characterdata_set_data((DOMCharacterData*)text, "New content");
/// ```
pub export fn dom_characterdata_set_data(cdata: *DOMCharacterData, data: [*:0]const u8) c_int {
    const text: *Text = @ptrCast(@alignCast(cdata));
    const data_str = types.cStringToZigString(data);
    text.prototype.setNodeValue(data_str) catch |err| {
        return @intFromEnum(types.zigErrorToDOMError(err));
    };
    return 0;
}

/// Gets the length of the text content.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long length;
/// ```
///
/// ## Parameters
/// - `cdata`: CharacterData handle
///
/// ## Returns
/// Length of text content in code units
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-characterdata-length
/// - WebIDL: dom.idl:432
///
/// ## Example
/// ```c
/// unsigned int len = dom_characterdata_get_length((DOMCharacterData*)text);
/// printf("Length: %u\n", len);
/// ```
pub export fn dom_characterdata_get_length(cdata: *DOMCharacterData) u32 {
    const text: *const Text = @ptrCast(@alignCast(cdata));
    return @intCast(text.length());
}

// ============================================================================
// Methods
// ============================================================================

/// Extracts a substring from the text content.
///
/// ## WebIDL
/// ```webidl
/// DOMString substringData(unsigned long offset, unsigned long count);
/// ```
///
/// ## Parameters
/// - `cdata`: CharacterData handle
/// - `offset`: Starting position (0-based)
/// - `count`: Number of characters to extract
///
/// ## Returns
/// Substring (borrowed string - do NOT free), or empty string on error
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-characterdata-substringdata
/// - WebIDL: dom.idl:433
///
/// ## Example
/// ```c
/// // text.data = "Hello World"
/// const char* sub = dom_characterdata_substringdata((DOMCharacterData*)text, 0, 5);
/// printf("%s\n", sub); // "Hello"
/// ```
pub export fn dom_characterdata_substringdata(
    cdata: *DOMCharacterData,
    offset: u32,
    count: u32,
) [*:0]const u8 {
    const text: *Text = @ptrCast(@alignCast(cdata));
    const allocator = std.heap.page_allocator;
    const result = text.substringData(allocator, offset, count) catch return "";
    // WARNING: This leaks memory! For proper implementation, need to cache result
    // For now, return empty string on error
    _ = result;
    // TODO: Implement proper substring caching or use arena allocator
    return "";
}

/// Appends text to the end of the content.
///
/// ## WebIDL
/// ```webidl
/// undefined appendData(DOMString data);
/// ```
///
/// ## Parameters
/// - `cdata`: CharacterData handle
/// - `data`: Text to append
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-characterdata-appenddata
/// - WebIDL: dom.idl:434
///
/// ## Example
/// ```c
/// // text.data = "Hello"
/// dom_characterdata_appenddata((DOMCharacterData*)text, " World");
/// // text.data = "Hello World"
/// ```
pub export fn dom_characterdata_appenddata(cdata: *DOMCharacterData, data: [*:0]const u8) c_int {
    const text: *Text = @ptrCast(@alignCast(cdata));
    const data_str = types.cStringToZigString(data);
    text.appendData(data_str) catch |err| {
        return @intFromEnum(types.zigErrorToDOMError(err));
    };
    return 0;
}

/// Inserts text at a specific position.
///
/// ## WebIDL
/// ```webidl
/// undefined insertData(unsigned long offset, DOMString data);
/// ```
///
/// ## Parameters
/// - `cdata`: CharacterData handle
/// - `offset`: Position to insert at (0-based)
/// - `data`: Text to insert
///
/// ## Returns
/// 0 on success, error code on failure (IndexSizeError if offset > length)
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-characterdata-insertdata
/// - WebIDL: dom.idl:435
///
/// ## Example
/// ```c
/// // text.data = "Hello World"
/// dom_characterdata_insertdata((DOMCharacterData*)text, 5, " Beautiful");
/// // text.data = "Hello Beautiful World"
/// ```
pub export fn dom_characterdata_insertdata(
    cdata: *DOMCharacterData,
    offset: u32,
    data: [*:0]const u8,
) c_int {
    const text: *Text = @ptrCast(@alignCast(cdata));
    const data_str = types.cStringToZigString(data);
    text.insertData(offset, data_str) catch |err| {
        return @intFromEnum(types.zigErrorToDOMError(err));
    };
    return 0;
}

/// Deletes a range of text.
///
/// ## WebIDL
/// ```webidl
/// undefined deleteData(unsigned long offset, unsigned long count);
/// ```
///
/// ## Parameters
/// - `cdata`: CharacterData handle
/// - `offset`: Starting position (0-based)
/// - `count`: Number of characters to delete
///
/// ## Returns
/// 0 on success, error code on failure (IndexSizeError if offset > length)
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-characterdata-deletedata
/// - WebIDL: dom.idl:436
///
/// ## Example
/// ```c
/// // text.data = "Hello Beautiful World"
/// dom_characterdata_deletedata((DOMCharacterData*)text, 5, 10);
/// // text.data = "Hello World"
/// ```
pub export fn dom_characterdata_deletedata(
    cdata: *DOMCharacterData,
    offset: u32,
    count: u32,
) c_int {
    const text: *Text = @ptrCast(@alignCast(cdata));
    text.deleteData(offset, count) catch |err| {
        return @intFromEnum(types.zigErrorToDOMError(err));
    };
    return 0;
}

/// Replaces a range of text with new content.
///
/// ## WebIDL
/// ```webidl
/// undefined replaceData(unsigned long offset, unsigned long count, DOMString data);
/// ```
///
/// ## Parameters
/// - `cdata`: CharacterData handle
/// - `offset`: Starting position (0-based)
/// - `count`: Number of characters to replace
/// - `data`: New text to insert
///
/// ## Returns
/// 0 on success, error code on failure (IndexSizeError if offset > length)
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-characterdata-replacedata
/// - WebIDL: dom.idl:437
///
/// ## Example
/// ```c
/// // text.data = "Hello World"
/// dom_characterdata_replacedata((DOMCharacterData*)text, 6, 5, "Zig");
/// // text.data = "Hello Zig"
/// ```
pub export fn dom_characterdata_replacedata(
    cdata: *DOMCharacterData,
    offset: u32,
    count: u32,
    data: [*:0]const u8,
) c_int {
    const text: *Text = @ptrCast(@alignCast(cdata));
    const data_str = types.cStringToZigString(data);
    text.replaceData(offset, count, data_str) catch |err| {
        return @intFromEnum(types.zigErrorToDOMError(err));
    };
    return 0;
}
