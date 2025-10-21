//! StaticRange C-ABI Bindings
//!
//! Provides C-compatible bindings for the StaticRange interface.
//! StaticRange is a lightweight, immutable range that does NOT track DOM mutations.
//!
//! ## Exported Functions
//! - dom_staticrange_new() - Create new StaticRange with init dict
//! - dom_staticrange_get_startcontainer() - Get start container node
//! - dom_staticrange_get_startoffset() - Get start offset
//! - dom_staticrange_get_endcontainer() - Get end container node
//! - dom_staticrange_get_endoffset() - Get end offset
//! - dom_staticrange_get_collapsed() - Check if collapsed
//! - dom_staticrange_release() - Release StaticRange

const std = @import("std");
const dom = @import("dom");
const StaticRange = dom.StaticRange;
const StaticRangeInit = dom.StaticRangeInit;
const Node = dom.Node;
const dom_types = @import("dom_types.zig");

/// Opaque StaticRange handle for C
pub const DOMStaticRange = opaque {};

/// Create a new StaticRange.
///
/// Creates an immutable range from the provided boundary points.
/// Unlike Range, StaticRange does NOT track DOM mutations and allows
/// out-of-bounds offsets.
///
/// ## Parameters
/// - `start_container`: Start boundary node
/// - `start_offset`: Offset within start container (can be out of bounds)
/// - `end_container`: End boundary node
/// - `end_offset`: Offset within end container (can be out of bounds)
///
/// ## Returns
/// - StaticRange handle on success
/// - NULL on error (InvalidNodeTypeError if DocumentType or Attr)
///
/// ## Example
/// ```c
/// DOMDocument* doc = dom_document_new();
/// DOMText* text = dom_document_createtextnode(doc, "Hello");
///
/// // Create range selecting "Hell" (0-4)
/// DOMStaticRange* range = dom_staticrange_new(
///     (DOMNode*)text, 0,
///     (DOMNode*)text, 4
/// );
///
/// if (range) {
///     uint32_t start = dom_staticrange_get_startoffset(range);
///     uint32_t end = dom_staticrange_get_endoffset(range);
///     printf("Range: %u to %u\n", start, end);
///
///     dom_staticrange_release(range);
/// }
///
/// dom_document_release(doc);
/// ```
///
/// ## WebIDL
/// ```webidl
/// constructor(StaticRangeInit init);
/// ```
pub export fn dom_staticrange_new(
    start_container: *Node,
    start_offset: u32,
    end_container: *Node,
    end_offset: u32,
) ?*DOMStaticRange {
    const allocator = std.heap.c_allocator;

    const init = StaticRangeInit{
        .start_container = start_container,
        .start_offset = start_offset,
        .end_container = end_container,
        .end_offset = end_offset,
    };

    const range = StaticRange.init(allocator, init) catch {
        return null; // InvalidNodeTypeError
    };

    return @ptrCast(range);
}

/// Get the start container node.
///
/// ## Parameters
/// - `range`: StaticRange handle
///
/// ## Returns
/// Start container node (do NOT release - borrowed reference)
///
/// ## Example
/// ```c
/// DOMNode* start = dom_staticrange_get_startcontainer(range);
/// uint16_t type = dom_node_get_nodetype(start);
/// ```
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node startContainer;
/// ```
pub export fn dom_staticrange_get_startcontainer(range: *DOMStaticRange) *Node {
    const r: *StaticRange = @ptrCast(@alignCast(range));
    return r.startContainer();
}

/// Get the start offset.
///
/// ## Parameters
/// - `range`: StaticRange handle
///
/// ## Returns
/// Offset within start container (may be out of bounds)
///
/// ## Example
/// ```c
/// uint32_t offset = dom_staticrange_get_startoffset(range);
/// printf("Start offset: %u\n", offset);
/// ```
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long startOffset;
/// ```
pub export fn dom_staticrange_get_startoffset(range: *DOMStaticRange) u32 {
    const r: *StaticRange = @ptrCast(@alignCast(range));
    return r.startOffset();
}

/// Get the end container node.
///
/// ## Parameters
/// - `range`: StaticRange handle
///
/// ## Returns
/// End container node (do NOT release - borrowed reference)
///
/// ## Example
/// ```c
/// DOMNode* end = dom_staticrange_get_endcontainer(range);
/// const char* name = dom_node_get_nodename(end);
/// ```
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node endContainer;
/// ```
pub export fn dom_staticrange_get_endcontainer(range: *DOMStaticRange) *Node {
    const r: *StaticRange = @ptrCast(@alignCast(range));
    return r.endContainer();
}

/// Get the end offset.
///
/// ## Parameters
/// - `range`: StaticRange handle
///
/// ## Returns
/// Offset within end container (may be out of bounds)
///
/// ## Example
/// ```c
/// uint32_t offset = dom_staticrange_get_endoffset(range);
/// printf("End offset: %u\n", offset);
/// ```
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long endOffset;
/// ```
pub export fn dom_staticrange_get_endoffset(range: *DOMStaticRange) u32 {
    const r: *StaticRange = @ptrCast(@alignCast(range));
    return r.endOffset();
}

/// Check if range is collapsed.
///
/// A range is collapsed if start and end are at the same position
/// (same container and same offset).
///
/// ## Parameters
/// - `range`: StaticRange handle
///
/// ## Returns
/// 1 if collapsed, 0 otherwise
///
/// ## Example
/// ```c
/// // Collapsed range (insertion point)
/// DOMStaticRange* collapsed = dom_staticrange_new(
///     (DOMNode*)text, 5,
///     (DOMNode*)text, 5
/// );
///
/// if (dom_staticrange_get_collapsed(collapsed)) {
///     printf("Range is an insertion point\n");
/// }
/// ```
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean collapsed;
/// ```
pub export fn dom_staticrange_get_collapsed(range: *DOMStaticRange) u8 {
    const r: *StaticRange = @ptrCast(@alignCast(range));
    return if (r.collapsed()) 1 else 0;
}

/// Release a StaticRange.
///
/// Frees the range and releases references to its boundary nodes.
///
/// ## Parameters
/// - `range`: StaticRange handle
///
/// ## Example
/// ```c
/// DOMStaticRange* range = dom_staticrange_new(...);
/// // ... use range ...
/// dom_staticrange_release(range);
/// // range is now invalid
/// ```
pub export fn dom_staticrange_release(range: *DOMStaticRange) void {
    const r: *StaticRange = @ptrCast(@alignCast(range));
    r.deinit(r.allocator);
}
