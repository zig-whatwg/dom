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
/// - `data`: The character data string
/// - `allocator`: Allocator for the returned substring
/// - `offset`: Starting position (0-based)
/// - `count`: Number of characters to extract (null = to end)
///
/// ## Returns
/// Owned substring (caller must free)
///
/// ## Errors
/// - `IndexOutOfBounds`: offset > data.len
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
    if (offset > data.len) {
        return error.IndexOutOfBounds;
    }

    const actual_count = count orelse (data.len - offset);
    const end = @min(offset + actual_count, data.len);

    return try allocator.dupe(u8, data[offset..end]);
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
/// - `offset`: Position to insert at (0-based)
/// - `text_to_insert`: String to insert
///
/// ## Errors
/// - `IndexOutOfBounds`: offset > data.len
/// - `OutOfMemory`: Failed to allocate new string
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-characterdata-insertdata
/// - WebIDL: dom.idl:88
pub fn insertData(
    data_ptr: *[]u8,
    allocator: Allocator,
    offset: usize,
    text_to_insert: []const u8,
) !void {
    if (offset > data_ptr.len) {
        return error.IndexOutOfBounds;
    }

    const new_data = try std.mem.concat(
        allocator,
        u8,
        &[_][]const u8{
            data_ptr.*[0..offset],
            text_to_insert,
            data_ptr.*[offset..],
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
/// - `offset`: Starting position (0-based)
/// - `count`: Number of characters to delete
///
/// ## Errors
/// - `IndexOutOfBounds`: offset > data.len
/// - `OutOfMemory`: Failed to allocate new string
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-characterdata-deletedata
/// - WebIDL: dom.idl:89
pub fn deleteData(
    data_ptr: *[]u8,
    allocator: Allocator,
    offset: usize,
    count: usize,
) !void {
    if (offset > data_ptr.len) {
        return error.IndexOutOfBounds;
    }

    const end = @min(offset + count, data_ptr.len);

    const new_data = try std.mem.concat(
        allocator,
        u8,
        &[_][]const u8{
            data_ptr.*[0..offset],
            data_ptr.*[end..],
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
/// - `offset`: Starting position (0-based)
/// - `count`: Number of characters to replace
/// - `replacement`: New string to insert
///
/// ## Errors
/// - `IndexOutOfBounds`: offset > data.len
/// - `OutOfMemory`: Failed to allocate new string
///
/// ## Spec References
/// - Algorithm: https://dom.spec.whatwg.org/#dom-characterdata-replacedata
/// - WebIDL: dom.idl:90
pub fn replaceData(
    data_ptr: *[]u8,
    allocator: Allocator,
    offset: usize,
    count: usize,
    replacement: []const u8,
) !void {
    if (offset > data_ptr.len) {
        return error.IndexOutOfBounds;
    }

    const end = @min(offset + count, data_ptr.len);

    const new_data = try std.mem.concat(
        allocator,
        u8,
        &[_][]const u8{
            data_ptr.*[0..offset],
            replacement,
            data_ptr.*[end..],
        },
    );

    allocator.free(data_ptr.*);
    data_ptr.* = new_data;
}

