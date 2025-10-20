//! CharacterData Interface (§4.8)
//!
//! This module provides shared functionality for Text and Comment nodes as specified
//! by the WHATWG DOM Standard. CharacterData is an abstract interface that both Text
//! and Comment inherit from, providing common string manipulation methods.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.8 Interface CharacterData**: https://dom.spec.whatwg.org/#interface-characterdata
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node (base)
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
//! ## Architecture Note
//!
//! In JavaScript/WebIDL, CharacterData is an abstract interface:
//! ```
//! Node (base)
//!   └── CharacterData (abstract)
//!        ├── Text
//!        └── Comment
//! ```
//!
//! In Zig, we implement this as:
//! - Text and Comment each have `prototype: Node` as first field
//! - Both have `data: []u8` as second field
//! - This module provides **shared helper functions** that operate on the data field
//! - Text.zig and Comment.zig forward calls to these helpers
//!
//! This approach:
//! - ✅ Maintains @fieldParentPtr compatibility
//! - ✅ Eliminates code duplication
//! - ✅ Follows WHATWG spec (CharacterData is abstract, not instantiable)
//! - ✅ Preserves existing API surface (no breaking changes)
//!
//! ## Core Features
//!
//! ### String Manipulation
//! CharacterData provides methods for manipulating character data:
//! ```zig
//! // Via Text node
//! const text = try Text.create(allocator, "Hello World");
//! defer text.prototype.release();
//!
//! // Append data
//! try text.appendData(" Zig!"); // "Hello World Zig!"
//!
//! // Insert data
//! try text.insertData(5, " Beautiful"); // "Hello Beautiful World Zig!"
//!
//! // Delete data
//! try text.deleteData(5, 10); // "Hello World Zig!"
//!
//! // Replace data
//! try text.replaceData(6, 5, "Zig"); // "Hello Zig Zig!"
//! ```
//!
//! ### Substring Extraction
//! ```zig
//! const sub = try text.substringData(allocator, 0, 5);
//! defer allocator.free(sub);
//! // sub = "Hello"
//! ```
//!
//! ## JavaScript Bindings
//!
//! CharacterData is an abstract interface in the DOM - it's never instantiated directly.
//! Instead, Text and Comment nodes inherit these properties and methods.
//!
//! ### Instance Properties
//! ```javascript
//! // data (read-write) - Per WebIDL: attribute [LegacyNullToEmptyString] DOMString data;
//! Object.defineProperty(CharacterData.prototype, 'data', {
//!   get: function() { return zig.characterdata_get_data(this._ptr); },
//!   set: function(value) {
//!     // LegacyNullToEmptyString: Convert null to empty string
//!     zig.characterdata_set_data(this._ptr, value === null ? '' : value);
//!   }
//! });
//!
//! // length (readonly) - Per WebIDL: readonly attribute unsigned long length;
//! Object.defineProperty(CharacterData.prototype, 'length', {
//!   get: function() { return zig.characterdata_get_length(this._ptr); }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // Per WebIDL: DOMString substringData(unsigned long offset, unsigned long count);
//! CharacterData.prototype.substringData = function(offset, count) {
//!   return zig.characterdata_substringData(this._ptr, offset, count);
//! };
//!
//! // Per WebIDL: undefined appendData(DOMString data);
//! CharacterData.prototype.appendData = function(data) {
//!   zig.characterdata_appendData(this._ptr, data);
//!   // No return - 'undefined' in WebIDL
//! };
//!
//! // Per WebIDL: undefined insertData(unsigned long offset, DOMString data);
//! CharacterData.prototype.insertData = function(offset, data) {
//!   zig.characterdata_insertData(this._ptr, offset, data);
//! };
//!
//! // Per WebIDL: undefined deleteData(unsigned long offset, unsigned long count);
//! CharacterData.prototype.deleteData = function(offset, count) {
//!   zig.characterdata_deleteData(this._ptr, offset, count);
//! };
//!
//! // Per WebIDL: undefined replaceData(unsigned long offset, unsigned long count, DOMString data);
//! CharacterData.prototype.replaceData = function(offset, count, data) {
//!   zig.characterdata_replaceData(this._ptr, offset, count, data);
//! };
//! ```
//!
//! ### Inheritance
//! ```javascript
//! // Text and Comment inherit all CharacterData properties and methods
//! // Text inherits: data, length, substringData, appendData, insertData, deleteData, replaceData
//! // Comment inherits: data, length, substringData, appendData, insertData, deleteData, replaceData
//! ```
//!
//! ### Usage Examples
//! ```javascript
//! // Create text node (Text inherits from CharacterData)
//! const text = document.createTextNode('Hello');
//!
//! // Use CharacterData properties
//! console.log(text.data);    // 'Hello'
//! console.log(text.length);  // 5
//!
//! // Use CharacterData methods
//! text.appendData(' World');        // text.data = 'Hello World'
//! text.insertData(5, ' Beautiful'); // text.data = 'Hello Beautiful World'
//! text.deleteData(5, 10);           // text.data = 'Hello World'
//! text.replaceData(6, 5, 'Zig');    // text.data = 'Hello Zig'
//!
//! // Extract substring
//! const sub = text.substringData(0, 5); // 'Hello'
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Extract a substring from character data.
///
/// Implements WHATWG DOM CharacterData.substringData() per §4.8.
///
/// ## WebIDL
/// ```webidl
/// DOMString substringData(unsigned long offset, unsigned long count);
/// ```
///
/// ## Algorithm (from spec §4.8)
/// 1. If offset > length, throw IndexSizeError
/// 2. Let end = min(offset + count, length)
/// 3. Return substring from offset to end
///
/// ## Parameters
/// - `data`: The character data string (UTF-8)
/// - `allocator`: Allocator for the returned substring
/// - `offset`: Starting position in UTF-16 code units (per WHATWG spec)
/// - `count`: Number of UTF-16 code units to extract (null = to end)
///
/// ## Returns
/// Owned substring (caller must free)
///
/// ## Errors
/// - `IndexOutOfBounds`: offset > length (in UTF-16 code units)
///
/// ## Note
/// Per WHATWG DOM, offsets are measured in UTF-16 code units (DOMString is UTF-16).
/// This function converts UTF-16 offsets to UTF-8 byte positions internally.
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-characterdata-substringdata
/// - WebIDL: dom.idl:86
pub fn substringData(
    data: []const u8,
    allocator: Allocator,
    offset: usize,
    count: ?usize,
) ![]u8 {
    const string_utils = @import("string_utils.zig");

    // Get length in UTF-16 code units
    const utf16_len = string_utils.utf16Length(data);

    if (offset > utf16_len) {
        return error.IndexOutOfBounds;
    }

    // Convert UTF-16 offset to UTF-8 byte offset
    const start_byte = string_utils.utf16OffsetToUtf8Byte(data, offset);

    // Calculate end position in UTF-16 code units, then convert to bytes
    const actual_count = count orelse (utf16_len - offset);
    const end_utf16 = @min(offset + actual_count, utf16_len);
    const end_byte = string_utils.utf16OffsetToUtf8Byte(data, end_utf16);

    return try allocator.dupe(u8, data[start_byte..end_byte]);
}

/// Append data to the end of character data.
///
/// Implements WHATWG DOM CharacterData.appendData() per §4.8.
///
/// ## WebIDL
/// ```webidl
/// undefined appendData(DOMString data);
/// ```
///
/// ## Algorithm (from spec §4.8)
/// Replace data with its current value plus the given data.
///
/// ## Parameters
/// - `data_ptr`: Pointer to the data field to modify
/// - `allocator`: Allocator for the new string
/// - `text_to_append`: String to append
///
/// ## Errors
/// - `OutOfMemory`: Failed to allocate new string
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-characterdata-appenddata
/// - WebIDL: dom.idl:87
pub fn appendData(
    data_ptr: *[]u8,
    allocator: Allocator,
    text_to_append: []const u8,
) !void {
    const new_data = try std.mem.concat(
        allocator,
        u8,
        &[_][]const u8{ data_ptr.*, text_to_append },
    );

    allocator.free(data_ptr.*);
    data_ptr.* = new_data;
}

/// Insert data at a specified offset.
///
/// Implements WHATWG DOM CharacterData.insertData() per §4.8.
///
/// ## WebIDL
/// ```webidl
/// undefined insertData(unsigned long offset, DOMString data);
/// ```
///
/// ## Algorithm (from spec §4.8)
/// 1. If offset > length, throw IndexSizeError
/// 2. Insert data at offset position
///
/// ## Parameters
/// - `data_ptr`: Pointer to the data field to modify
/// - `allocator`: Allocator for the new string
/// - `offset`: Position to insert at in UTF-16 code units (0-based)
/// - `text_to_insert`: String to insert
///
/// ## Errors
/// - `IndexOutOfBounds`: offset > data.len (in UTF-16 code units)
/// - `OutOfMemory`: Failed to allocate new string
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-characterdata-insertdata
/// - WebIDL: dom.idl:88
///
/// ## Implementation Notes
/// Per WHATWG spec, offset is measured in UTF-16 code units (DOMString semantics).
/// We convert UTF-16 offsets to UTF-8 byte offsets internally.
pub fn insertData(
    data_ptr: *[]u8,
    allocator: Allocator,
    offset: usize,
    text_to_insert: []const u8,
) !void {
    const string_utils = @import("string_utils.zig");

    // Calculate length in UTF-16 code units
    const utf16_len = string_utils.utf16Length(data_ptr.*);

    // Step 1: Validate offset (in UTF-16 code units)
    if (offset > utf16_len) {
        return error.IndexOutOfBounds;
    }

    // Step 2: Convert UTF-16 offset to UTF-8 byte offset
    const byte_offset = string_utils.utf16OffsetToUtf8Byte(data_ptr.*, offset);

    // Step 3: Insert at the byte offset
    const new_data = try std.mem.concat(
        allocator,
        u8,
        &[_][]const u8{
            data_ptr.*[0..byte_offset],
            text_to_insert,
            data_ptr.*[byte_offset..],
        },
    );

    allocator.free(data_ptr.*);
    data_ptr.* = new_data;
}

/// Delete a range of characters.
///
/// Implements WHATWG DOM CharacterData.deleteData() per §4.8.
///
/// ## WebIDL
/// ```webidl
/// undefined deleteData(unsigned long offset, unsigned long count);
/// ```
///
/// ## Algorithm (from spec §4.8)
/// 1. If offset > length, throw IndexSizeError
/// 2. Let end = min(offset + count, length)
/// 3. Remove characters from offset to end
///
/// ## Parameters
/// - `data_ptr`: Pointer to the data field to modify
/// - `allocator`: Allocator for the new string
/// - `offset`: Starting position in UTF-16 code units (0-based)
/// - `count`: Number of UTF-16 code units to delete
///
/// ## Errors
/// - `IndexOutOfBounds`: offset > data.len (in UTF-16 code units)
/// - `OutOfMemory`: Failed to allocate new string
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-characterdata-deletedata
/// - WebIDL: dom.idl:89
///
/// ## Implementation Notes
/// Per WHATWG spec, offset and count are measured in UTF-16 code units (DOMString semantics).
/// We convert UTF-16 offsets to UTF-8 byte offsets internally.
pub fn deleteData(
    data_ptr: *[]u8,
    allocator: Allocator,
    offset: usize,
    count: usize,
) !void {
    const string_utils = @import("string_utils.zig");

    // Calculate length in UTF-16 code units
    const utf16_len = string_utils.utf16Length(data_ptr.*);

    // Step 1: Validate offset (in UTF-16 code units)
    if (offset > utf16_len) {
        return error.IndexOutOfBounds;
    }

    // Step 2: Calculate end position (in UTF-16 code units)
    const end_utf16 = @min(offset + count, utf16_len);

    // Step 3: Convert UTF-16 offsets to UTF-8 byte offsets
    const start_byte = string_utils.utf16OffsetToUtf8Byte(data_ptr.*, offset);
    const end_byte = string_utils.utf16OffsetToUtf8Byte(data_ptr.*, end_utf16);

    // Step 4: Delete the range
    const new_data = try std.mem.concat(
        allocator,
        u8,
        &[_][]const u8{
            data_ptr.*[0..start_byte],
            data_ptr.*[end_byte..],
        },
    );

    allocator.free(data_ptr.*);
    data_ptr.* = new_data;
}

/// Replace a range of characters with new data.
///
/// Implements WHATWG DOM CharacterData.replaceData() per §4.8.
///
/// ## WebIDL
/// ```webidl
/// undefined replaceData(unsigned long offset, unsigned long count, DOMString data);
/// ```
///
/// ## Algorithm (from spec §4.8)
/// 1. If offset > length, throw IndexSizeError
/// 2. Let end = min(offset + count, length)
/// 3. Replace characters from offset to end with replacement
///
/// ## Parameters
/// - `data_ptr`: Pointer to the data field to modify
/// - `allocator`: Allocator for the new string
/// - `offset`: Starting position in UTF-16 code units (0-based)
/// - `count`: Number of UTF-16 code units to replace
/// - `replacement`: New string to insert
///
/// ## Errors
/// - `IndexOutOfBounds`: offset > data.len (in UTF-16 code units)
/// - `OutOfMemory`: Failed to allocate new string
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-characterdata-replacedata
/// - WebIDL: dom.idl:90
///
/// ## Implementation Notes
/// Per WHATWG spec, offset and count are measured in UTF-16 code units (DOMString semantics).
/// We convert UTF-16 offsets to UTF-8 byte offsets internally.
pub fn replaceData(
    data_ptr: *[]u8,
    allocator: Allocator,
    offset: usize,
    count: usize,
    replacement: []const u8,
) !void {
    const string_utils = @import("string_utils.zig");

    // Calculate length in UTF-16 code units
    const utf16_len = string_utils.utf16Length(data_ptr.*);

    // Step 1: Validate offset (in UTF-16 code units)
    if (offset > utf16_len) {
        return error.IndexOutOfBounds;
    }

    // Step 2: Calculate end position (in UTF-16 code units)
    const end_utf16 = @min(offset + count, utf16_len);

    // Step 3: Convert UTF-16 offsets to UTF-8 byte offsets
    const start_byte = string_utils.utf16OffsetToUtf8Byte(data_ptr.*, offset);
    const end_byte = string_utils.utf16OffsetToUtf8Byte(data_ptr.*, end_utf16);

    // Step 4: Replace the range
    const new_data = try std.mem.concat(
        allocator,
        u8,
        &[_][]const u8{
            data_ptr.*[0..start_byte],
            replacement,
            data_ptr.*[end_byte..],
        },
    );

    allocator.free(data_ptr.*);
    data_ptr.* = new_data;
}
