//! NodeFilter Interface - WHATWG DOM Standard §6.3
//! ==================================================
//!
//! NodeFilter provides a callback interface for filtering nodes during traversal.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-nodefilter
//! - **Section**: §6.3 Interface NodeFilter
//!
//! ## MDN Documentation
//! - **NodeFilter**: https://developer.mozilla.org/en-US/docs/Web/API/NodeFilter
//!
//! ## Overview
//!
//! NodeFilter is used by TreeWalker and NodeIterator to filter which nodes
//! are visible during tree traversal. It provides constants for filtering
//! decisions and whatToShow flags.

const std = @import("std");
const Node = @import("node.zig").Node;

/// Filter result constants
pub const FILTER_ACCEPT: u16 = 1;
pub const FILTER_REJECT: u16 = 2;
pub const FILTER_SKIP: u16 = 3;

/// WhatToShow constants - bitmask for node types
pub const SHOW_ALL: u32 = 0xFFFFFFFF;
pub const SHOW_ELEMENT: u32 = 0x1;
pub const SHOW_ATTRIBUTE: u32 = 0x2;
pub const SHOW_TEXT: u32 = 0x4;
pub const SHOW_CDATA_SECTION: u32 = 0x8;
pub const SHOW_ENTITY_REFERENCE: u32 = 0x10;
pub const SHOW_ENTITY: u32 = 0x20;
pub const SHOW_PROCESSING_INSTRUCTION: u32 = 0x40;
pub const SHOW_COMMENT: u32 = 0x80;
pub const SHOW_DOCUMENT: u32 = 0x100;
pub const SHOW_DOCUMENT_TYPE: u32 = 0x200;
pub const SHOW_DOCUMENT_FRAGMENT: u32 = 0x400;
pub const SHOW_NOTATION: u32 = 0x800;

/// NodeFilter callback type
///
/// Returns one of:
/// - FILTER_ACCEPT (1): Accept the node
/// - FILTER_REJECT (2): Reject the node and its descendants
/// - FILTER_SKIP (3): Skip the node but not its descendants
pub const FilterCallback = *const fn (node: *Node) u16;

/// Check if a node type matches the whatToShow mask
///
/// ## Parameters
///
/// - `node`: The node to check
/// - `what_to_show`: The bitmask of node types to show
///
/// ## Returns
///
/// `true` if the node type is included in the mask.
pub fn matchesWhatToShow(node: *Node, what_to_show: u32) bool {
    // If SHOW_ALL, always match
    if (what_to_show == SHOW_ALL) return true;

    const node_mask: u32 = switch (node.node_type) {
        .element_node => SHOW_ELEMENT,
        .text_node => SHOW_TEXT,
        .comment_node => SHOW_COMMENT,
        .document_node => SHOW_DOCUMENT,
        .document_type_node => SHOW_DOCUMENT_TYPE,
        .document_fragment_node => SHOW_DOCUMENT_FRAGMENT,
        else => 0,
    };

    return (what_to_show & node_mask) != 0;
}

/// Filter a node using whatToShow and optional callback
///
/// ## Parameters
///
/// - `node`: The node to filter
/// - `what_to_show`: The bitmask of node types to show
/// - `filter`: Optional filter callback
///
/// ## Returns
///
/// One of FILTER_ACCEPT, FILTER_REJECT, or FILTER_SKIP.
pub fn filterNode(node: *Node, what_to_show: u32, filter: ?FilterCallback) u16 {
    // First check whatToShow
    if (!matchesWhatToShow(node, what_to_show)) {
        return FILTER_SKIP;
    }

    // Then apply callback filter if present
    if (filter) |f| {
        return f(node);
    }

    return FILTER_ACCEPT;
}

// ============================================================================
// Tests
// ============================================================================

test "NodeFilter constants" {
    
    try std.testing.expectEqual(@as(u16, 1), FILTER_ACCEPT);
    try std.testing.expectEqual(@as(u16, 2), FILTER_REJECT);
    try std.testing.expectEqual(@as(u16, 3), FILTER_SKIP);
}

test "NodeFilter whatToShow constants" {
    
    try std.testing.expectEqual(@as(u32, 0xFFFFFFFF), SHOW_ALL);
    try std.testing.expectEqual(@as(u32, 0x1), SHOW_ELEMENT);
    try std.testing.expectEqual(@as(u32, 0x4), SHOW_TEXT);
    try std.testing.expectEqual(@as(u32, 0x80), SHOW_COMMENT);
}

test "NodeFilter matchesWhatToShow with SHOW_ALL" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "test");
    defer node.release();

    try std.testing.expect(matchesWhatToShow(node, SHOW_ALL));
}

test "NodeFilter matchesWhatToShow element" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .element_node, "div");
    defer node.release();

    try std.testing.expect(matchesWhatToShow(node, SHOW_ELEMENT));
    try std.testing.expect(!matchesWhatToShow(node, SHOW_TEXT));
}

test "NodeFilter matchesWhatToShow text" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "text");
    defer node.release();

    try std.testing.expect(matchesWhatToShow(node, SHOW_TEXT));
    try std.testing.expect(!matchesWhatToShow(node, SHOW_ELEMENT));
}

test "NodeFilter matchesWhatToShow combined mask" {
    const allocator = std.testing.allocator;

    const text = try Node.init(allocator, .text_node, "text");
    defer text.release();

    const elem = try Node.init(allocator, .element_node, "div");
    defer elem.release();

    const combined = SHOW_TEXT | SHOW_ELEMENT;
    try std.testing.expect(matchesWhatToShow(text, combined));
    try std.testing.expect(matchesWhatToShow(elem, combined));
}

test "NodeFilter filterNode without callback" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "test");
    defer node.release();

    const result = filterNode(node, SHOW_TEXT, null);
    try std.testing.expectEqual(FILTER_ACCEPT, result);
}

test "NodeFilter filterNode with callback accepting" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "test");
    defer node.release();

    const AcceptFilter = struct {
        fn accept(n: *Node) u16 {
            _ = n;
            return FILTER_ACCEPT;
        }
    };

    const result = filterNode(node, SHOW_TEXT, AcceptFilter.accept);
    try std.testing.expectEqual(FILTER_ACCEPT, result);
}

test "NodeFilter filterNode with callback rejecting" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "test");
    defer node.release();

    const RejectFilter = struct {
        fn reject(n: *Node) u16 {
            _ = n;
            return FILTER_REJECT;
        }
    };

    const result = filterNode(node, SHOW_TEXT, RejectFilter.reject);
    try std.testing.expectEqual(FILTER_REJECT, result);
}

test "NodeFilter filterNode with callback skipping" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "test");
    defer node.release();

    const SkipFilter = struct {
        fn skip(n: *Node) u16 {
            _ = n;
            return FILTER_SKIP;
        }
    };

    const result = filterNode(node, SHOW_TEXT, SkipFilter.skip);
    try std.testing.expectEqual(FILTER_SKIP, result);
}

test "NodeFilter filterNode whatToShow mismatch" {
    const allocator = std.testing.allocator;

    const node = try Node.init(allocator, .text_node, "test");
    defer node.release();

    const result = filterNode(node, SHOW_ELEMENT, null);
    try std.testing.expectEqual(FILTER_SKIP, result);
}
