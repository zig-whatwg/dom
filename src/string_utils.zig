//! String utilities for UTF-8 to UTF-16 offset conversion.
//!
//! WHATWG DOM uses UTF-16 code units for DOMString offsets, but Zig strings are UTF-8.
//! This module provides conversion utilities to maintain spec compliance.
//!
//! ## UTF-16 Code Unit Counting
//!
//! Per WHATWG spec, offsets are measured in UTF-16 code units:
//! - ASCII characters (U+0000..U+007F): 1 UTF-16 code unit
//! - BMP characters (U+0080..U+FFFF): 1 UTF-16 code unit
//! - Supplementary characters (U+10000..U+10FFFF): 2 UTF-16 code units (surrogate pair)
//!
//! ## Examples
//!
//! ```zig
//! const str = "Hello 世界"; // "Hello " = 6 code units, "世" = 1, "界" = 1 → total 8
//! const offset = utf16OffsetToUtf8Byte(str, 6); // Returns byte offset for "世"
//! ```

const std = @import("std");

/// Converts a UTF-16 code unit offset to a UTF-8 byte offset.
///
/// ## Parameters
/// - `utf8_string`: The UTF-8 string
/// - `utf16_offset`: Offset in UTF-16 code units
///
/// ## Returns
/// The corresponding byte offset in the UTF-8 string, or the string length if offset is beyond end.
///
/// ## Algorithm
/// Iterates through the UTF-8 string, counting UTF-16 code units for each codepoint:
/// - U+0000..U+FFFF (BMP): 1 code unit
/// - U+10000..U+10FFFF (supplementary): 2 code units (surrogate pair)
pub fn utf16OffsetToUtf8Byte(utf8_string: []const u8, utf16_offset: usize) usize {
    var utf16_pos: usize = 0;
    var utf8_byte_pos: usize = 0;

    while (utf8_byte_pos < utf8_string.len) {
        if (utf16_pos >= utf16_offset) {
            return utf8_byte_pos;
        }

        // Get the codepoint length in bytes
        const len = std.unicode.utf8ByteSequenceLength(utf8_string[utf8_byte_pos]) catch 1;

        // Decode the codepoint to check if it's supplementary
        if (len > 0 and utf8_byte_pos + len <= utf8_string.len) {
            const codepoint = std.unicode.utf8Decode(utf8_string[utf8_byte_pos..][0..len]) catch {
                // Invalid UTF-8, treat as 1 code unit and advance 1 byte
                utf16_pos += 1;
                utf8_byte_pos += 1;
                continue;
            };

            // Supplementary characters (>= U+10000) need 2 UTF-16 code units (surrogate pair)
            if (codepoint >= 0x10000) {
                // Check if target offset falls within this surrogate pair
                if (utf16_pos + 1 == utf16_offset) {
                    // Offset points to the middle of surrogate pair - return start of codepoint
                    return utf8_byte_pos;
                }
                utf16_pos += 2;
            } else {
                utf16_pos += 1;
            }

            utf8_byte_pos += len;
        } else {
            // Invalid sequence, advance 1 byte
            utf16_pos += 1;
            utf8_byte_pos += 1;
        }
    }

    return utf8_byte_pos;
}

/// Converts a UTF-8 byte offset to a UTF-16 code unit offset.
///
/// ## Parameters
/// - `utf8_string`: The UTF-8 string
/// - `utf8_byte_offset`: Offset in UTF-8 bytes
///
/// ## Returns
/// The corresponding offset in UTF-16 code units.
pub fn utf8ByteToUtf16Offset(utf8_string: []const u8, utf8_byte_offset: usize) usize {
    var utf16_pos: usize = 0;
    var utf8_byte_pos: usize = 0;

    const clamped_offset = @min(utf8_byte_offset, utf8_string.len);

    while (utf8_byte_pos < clamped_offset) {
        const len = std.unicode.utf8ByteSequenceLength(utf8_string[utf8_byte_pos]) catch 1;

        if (len > 0 and utf8_byte_pos + len <= utf8_string.len) {
            const codepoint = std.unicode.utf8Decode(utf8_string[utf8_byte_pos..][0..len]) catch {
                utf16_pos += 1;
                utf8_byte_pos += 1;
                continue;
            };

            if (codepoint >= 0x10000) {
                utf16_pos += 2;
            } else {
                utf16_pos += 1;
            }

            utf8_byte_pos += len;
        } else {
            utf16_pos += 1;
            utf8_byte_pos += 1;
        }
    }

    return utf16_pos;
}

/// Returns the length of a UTF-8 string in UTF-16 code units.
///
/// ## Parameters
/// - `utf8_string`: The UTF-8 string
///
/// ## Returns
/// The length in UTF-16 code units.
///
/// ## Example
/// ```zig
/// const len = utf16Length("Hello"); // Returns 5
/// const len2 = utf16Length("Hello 世界"); // Returns 8 (6 + 1 + 1)
/// const len3 = utf16Length("Hello 𝄞"); // Returns 7 (6 + 2, 𝄞 is supplementary)
/// ```
pub fn utf16Length(utf8_string: []const u8) usize {
    return utf8ByteToUtf16Offset(utf8_string, utf8_string.len);
}
