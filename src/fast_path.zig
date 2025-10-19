//! Fast path detection and optimization for querySelector operations
//!
//! This module provides optimizations for common selector patterns:
//! - Simple ID selectors: #id
//! - Simple class selectors: .class
//! - Simple tag selectors: tag
//!
//! These patterns skip the full CSS parser and matcher for significant
//! performance improvements (10-500x faster).

const std = @import("std");

/// Fast path types for querySelector optimization
pub const FastPathType = enum {
    /// Simple ID selector: "#id"
    simple_id,

    /// Simple class selector: ".class"
    simple_class,

    /// Simple tag selector: "div"
    simple_tag,

    /// Complex selector with ID that can filter search scope
    id_filtered,

    /// Generic complex selector (use full parser/matcher)
    generic,
};

/// Detect if a selector string matches a fast path pattern
pub fn detectFastPath(selectors: []const u8) FastPathType {
    const trimmed = std.mem.trim(u8, selectors, &std.ascii.whitespace);

    if (trimmed.len == 0) return .generic;

    // Fast path: Simple ID selector "#id"
    if (trimmed.len > 1 and trimmed[0] == '#') {
        if (isSimpleIdentifier(trimmed[1..])) {
            return .simple_id;
        }
    }

    // Fast path: Simple class selector ".class"
    if (trimmed.len > 1 and trimmed[0] == '.') {
        if (isSimpleIdentifier(trimmed[1..])) {
            return .simple_class;
        }
    }

    // Fast path: Simple tag selector "div"
    if (isSimpleTagName(trimmed)) {
        return .simple_tag;
    }

    // Check for ID filtering opportunity: "article#main .content"
    if (std.mem.indexOf(u8, trimmed, "#")) |_| {
        return .id_filtered;
    }

    return .generic;
}

/// Check if a string is a valid CSS identifier (alphanumeric, -, _, non-ASCII)
fn isSimpleIdentifier(s: []const u8) bool {
    if (s.len == 0) return false;

    // First character: letter, underscore, or non-ASCII
    const first = s[0];
    if (!std.ascii.isAlphabetic(first) and first != '_' and first < 128) {
        return false;
    }

    // Rest: alphanumeric, hyphen, underscore, or non-ASCII
    for (s[1..]) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_' and c != '-' and c < 128) {
            return false;
        }
    }

    return true;
}

/// Check if a string is a valid HTML tag name
fn isSimpleTagName(s: []const u8) bool {
    if (s.len == 0) return false;

    // Tag names: alphanumeric and hyphen only
    for (s) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '-') {
            return false;
        }
    }

    return true;
}

/// Extract the identifier from a simple selector string
/// For "#id" returns "id", for ".class" returns "class"
pub fn extractIdentifier(selectors: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, selectors, &std.ascii.whitespace);
    if (trimmed.len > 1 and (trimmed[0] == '#' or trimmed[0] == '.')) {
        return trimmed[1..];
    }
    return trimmed;
}

// Tests
const testing = std.testing;








