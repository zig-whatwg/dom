//! Range C-ABI Bindings
//!
//! C-ABI bindings for the Range interface per WHATWG DOM specification.
//! Range represents a mutable fragment of a document, supporting selection,
//! comparison, and content manipulation operations.
//!
//! ## C API Overview
//!
//! ```c
//! // Create range
//! DOMRange* range = dom_document_createrange(doc);
//!
//! // Set boundaries
//! dom_range_setstart(range, textNode, 0);
//! dom_range_setend(range, textNode, 5);
//!
//! // Check properties
//! uint8_t is_collapsed = dom_range_get_collapsed(range);
//! DOMNode* common = dom_range_get_commonancestorcontainer(range);
//!
//! // Manipulate content
//! dom_range_deletecontents(range);
//! DOMDocumentFragment* fragment = dom_range_extractcontents(range);
//!
//! // Cleanup
//! dom_range_release(range);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface Range : AbstractRange {
//!   constructor();
//!
//!   readonly attribute Node commonAncestorContainer;
//!
//!   undefined setStart(Node node, unsigned long offset);
//!   undefined setEnd(Node node, unsigned long offset);
//!   undefined setStartBefore(Node node);
//!   undefined setStartAfter(Node node);
//!   undefined setEndBefore(Node node);
//!   undefined setEndAfter(Node node);
//!   undefined collapse(optional boolean toStart = false);
//!   undefined selectNode(Node node);
//!   undefined selectNodeContents(Node node);
//!
//!   const unsigned short START_TO_START = 0;
//!   const unsigned short START_TO_END = 1;
//!   const unsigned short END_TO_END = 2;
//!   const unsigned short END_TO_START = 3;
//!   short compareBoundaryPoints(unsigned short how, Range sourceRange);
//!
//!   [CEReactions] undefined deleteContents();
//!   [CEReactions, NewObject] DocumentFragment extractContents();
//!   [NewObject] DocumentFragment cloneContents();
//!   [CEReactions] undefined insertNode(Node node);
//!   [CEReactions] undefined surroundContents(Node newParent);
//!
//!   [NewObject] Range cloneRange();
//!   undefined detach();
//!
//!   boolean isPointInRange(Node node, unsigned long offset);
//!   short comparePoint(Node node, unsigned long offset);
//!
//!   boolean intersectsNode(Node node);
//!
//!   stringifier;
//! };
//!
//! [Exposed=Window]
//! interface AbstractRange {
//!   readonly attribute Node startContainer;
//!   readonly attribute unsigned long startOffset;
//!   readonly attribute Node endContainer;
//!   readonly attribute unsigned long endOffset;
//!   readonly attribute boolean collapsed;
//! };
//! ```
//!
//! ## WHATWG Specification
//!
//! - Range interface: https://dom.spec.whatwg.org/#interface-range
//! - AbstractRange interface: https://dom.spec.whatwg.org/#interface-abstractrange
//! - Ranges: https://dom.spec.whatwg.org/#ranges
//!
//! ## MDN Documentation
//!
//! - Range: https://developer.mozilla.org/en-US/docs/Web/API/Range
//! - AbstractRange: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const Range = dom.Range;
const Node = dom.Node;
const DocumentFragment = dom.DocumentFragment;
const BoundaryPointComparison = dom.BoundaryPointComparison;
const DOMRange = types.DOMRange;
const DOMNode = types.DOMNode;
const DOMDocumentFragment = types.DOMDocumentFragment;
const DOMErrorCode = types.DOMErrorCode;
const zigErrorToDOMError = types.zigErrorToDOMError;

// ============================================================================
// AbstractRange Properties (inherited by Range)
// ============================================================================

/// Get the start container node.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node startContainer;
/// ```
///
/// ## Returns
/// Node containing the start boundary (borrowed, do NOT release)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-startcontainer
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/startContainer
pub export fn dom_range_get_startcontainer(range: *DOMRange) *DOMNode {
    const r: *Range = @ptrCast(@alignCast(range));
    return @ptrCast(r.start_container);
}

/// Get the start offset.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long startOffset;
/// ```
///
/// ## Returns
/// Offset within start container
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-startoffset
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/startOffset
pub export fn dom_range_get_startoffset(range: *DOMRange) u32 {
    const r: *Range = @ptrCast(@alignCast(range));
    return r.start_offset;
}

/// Get the end container node.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node endContainer;
/// ```
///
/// ## Returns
/// Node containing the end boundary (borrowed, do NOT release)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-endcontainer
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/endContainer
pub export fn dom_range_get_endcontainer(range: *DOMRange) *DOMNode {
    const r: *Range = @ptrCast(@alignCast(range));
    return @ptrCast(r.end_container);
}

/// Get the end offset.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long endOffset;
/// ```
///
/// ## Returns
/// Offset within end container
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-endoffset
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/endOffset
pub export fn dom_range_get_endoffset(range: *DOMRange) u32 {
    const r: *Range = @ptrCast(@alignCast(range));
    return r.end_offset;
}

/// Check if the range is collapsed (start equals end).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean collapsed;
/// ```
///
/// ## Returns
/// 1 if collapsed, 0 otherwise
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-collapsed
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/collapsed
pub export fn dom_range_get_collapsed(range: *DOMRange) u8 {
    const r: *Range = @ptrCast(@alignCast(range));
    return if (r.collapsed()) 1 else 0;
}

// ============================================================================
// Range Properties
// ============================================================================

/// Get the common ancestor container.
///
/// Returns the deepest node that contains both boundary points.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node commonAncestorContainer;
/// ```
///
/// ## Returns
/// Common ancestor node (borrowed, do NOT release)
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-commonancestorcontainer
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/commonAncestorContainer
pub export fn dom_range_get_commonancestorcontainer(range: *DOMRange) *DOMNode {
    const r: *Range = @ptrCast(@alignCast(range));
    return @ptrCast(r.commonAncestorContainer());
}

// ============================================================================
// Boundary Setting Methods
// ============================================================================

/// Set the start boundary point.
///
/// ## WebIDL
/// ```webidl
/// undefined setStart(Node node, unsigned long offset);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Container node for start boundary
/// - `offset`: Offset within node
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-setstart
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/setStart
pub export fn dom_range_setstart(range: *DOMRange, node: *DOMNode, offset: u32) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.setStart(n, offset) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Set the end boundary point.
///
/// ## WebIDL
/// ```webidl
/// undefined setEnd(Node node, unsigned long offset);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Container node for end boundary
/// - `offset`: Offset within node
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-setend
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/setEnd
pub export fn dom_range_setend(range: *DOMRange, node: *DOMNode, offset: u32) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.setEnd(n, offset) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Set the start boundary before a node.
///
/// ## WebIDL
/// ```webidl
/// undefined setStartBefore(Node node);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node to set start before
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-setstartbefore
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/setStartBefore
pub export fn dom_range_setstartbefore(range: *DOMRange, node: *DOMNode) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.setStartBefore(n) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Set the start boundary after a node.
///
/// ## WebIDL
/// ```webidl
/// undefined setStartAfter(Node node);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node to set start after
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-setstartafter
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/setStartAfter
pub export fn dom_range_setstartafter(range: *DOMRange, node: *DOMNode) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.setStartAfter(n) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Set the end boundary before a node.
///
/// ## WebIDL
/// ```webidl
/// undefined setEndBefore(Node node);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node to set end before
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-setendbefore
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/setEndBefore
pub export fn dom_range_setendbefore(range: *DOMRange, node: *DOMNode) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.setEndBefore(n) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Set the end boundary after a node.
///
/// ## WebIDL
/// ```webidl
/// undefined setEndAfter(Node node);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node to set end after
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-setendafter
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/setEndAfter
pub export fn dom_range_setendafter(range: *DOMRange, node: *DOMNode) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.setEndAfter(n) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Collapse the range to one boundary.
///
/// ## WebIDL
/// ```webidl
/// undefined collapse(optional boolean toStart = false);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `to_start`: 1 to collapse to start, 0 to collapse to end
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-collapse
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/collapse
pub export fn dom_range_collapse(range: *DOMRange, to_start: u8) void {
    const r: *Range = @ptrCast(@alignCast(range));
    r.collapse(to_start != 0);
}

/// Select a node's contents.
///
/// ## WebIDL
/// ```webidl
/// undefined selectNodeContents(Node node);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node whose contents to select
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-selectnodecontents
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/selectNodeContents
pub export fn dom_range_selectnodecontents(range: *DOMRange, node: *DOMNode) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.selectNodeContents(n) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Select a node (including the node itself).
///
/// ## WebIDL
/// ```webidl
/// undefined selectNode(Node node);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node to select
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-selectnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/selectNode
pub export fn dom_range_selectnode(range: *DOMRange, node: *DOMNode) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.selectNode(n) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

// ============================================================================
// Comparison Methods
// ============================================================================

/// Compare boundary points with another range.
///
/// ## WebIDL
/// ```webidl
/// const unsigned short START_TO_START = 0;
/// const unsigned short START_TO_END = 1;
/// const unsigned short END_TO_END = 2;
/// const unsigned short END_TO_START = 3;
/// short compareBoundaryPoints(unsigned short how, Range sourceRange);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `how`: Comparison type (0=START_TO_START, 1=START_TO_END, 2=END_TO_END, 3=END_TO_START)
/// - `source_range`: Range to compare with
///
/// ## Returns
/// -1, 0, or 1 indicating comparison result, or error code (>= 8) on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-compareboundarypoints
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/compareBoundaryPoints
pub export fn dom_range_compareboundarypoints(range: *DOMRange, how: u16, source_range: *DOMRange) i16 {
    const r: *Range = @ptrCast(@alignCast(range));
    const sr: *Range = @ptrCast(@alignCast(source_range));

    // Convert u16 to BoundaryPointComparison enum
    const comparison: BoundaryPointComparison = @enumFromInt(how);

    const result = r.compareBoundaryPoints(comparison, sr) catch |err| {
        return @as(i16, @intCast(@intFromEnum(zigErrorToDOMError(err))));
    };

    return result;
}

/// Compare a point with the range.
///
/// ## WebIDL
/// ```webidl
/// short comparePoint(Node node, unsigned long offset);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node containing the point
/// - `offset`: Offset within node
///
/// ## Returns
/// -1 if point is before range, 0 if in range, 1 if after range, or error code (>= 8) on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-comparepoint
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/comparePoint
pub export fn dom_range_comparepoint(range: *DOMRange, node: *DOMNode, offset: u32) i16 {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    const result = r.comparePoint(n, offset) catch |err| {
        return @as(i16, @intCast(@intFromEnum(zigErrorToDOMError(err))));
    };

    return result;
}

/// Check if a point is in the range.
///
/// ## WebIDL
/// ```webidl
/// boolean isPointInRange(Node node, unsigned long offset);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node containing the point
/// - `offset`: Offset within node
///
/// ## Returns
/// 1 if point is in range, 0 if not, or error code (>= 2) on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-ispointinrange
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/isPointInRange
pub export fn dom_range_ispointinrange(range: *DOMRange, node: *DOMNode, offset: u32) u8 {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    const result = r.isPointInRange(n, offset) catch {
        return 2; // Error
    };

    return if (result) 1 else 0;
}

/// Check if a node intersects the range.
///
/// ## WebIDL
/// ```webidl
/// boolean intersectsNode(Node node);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node to check
///
/// ## Returns
/// 1 if node intersects, 0 otherwise
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-intersectsnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/intersectsNode
pub export fn dom_range_intersectsnode(range: *DOMRange, node: *DOMNode) u8 {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    return if (r.intersectsNode(n)) 1 else 0;
}

// ============================================================================
// Content Manipulation Methods
// ============================================================================

/// Delete the contents of the range.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] undefined deleteContents();
/// ```
///
/// ## Parameters
/// - `range`: Range handle
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-deletecontents
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/deleteContents
pub export fn dom_range_deletecontents(range: *DOMRange) c_int {
    const r: *Range = @ptrCast(@alignCast(range));

    r.deleteContents() catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Extract the contents of the range into a DocumentFragment.
///
/// Removes the contents from the document.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions, NewObject] DocumentFragment extractContents();
/// ```
///
/// ## Parameters
/// - `range`: Range handle
///
/// ## Returns
/// DocumentFragment containing extracted contents (must be released by caller), or NULL on error
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-extractcontents
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/extractContents
pub export fn dom_range_extractcontents(range: *DOMRange) ?*DOMDocumentFragment {
    const r: *Range = @ptrCast(@alignCast(range));

    const fragment = r.extractContents() catch {
        return null;
    };

    return @ptrCast(fragment);
}

/// Clone the contents of the range into a DocumentFragment.
///
/// Does not remove contents from document.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] DocumentFragment cloneContents();
/// ```
///
/// ## Parameters
/// - `range`: Range handle
///
/// ## Returns
/// DocumentFragment containing cloned contents (must be released by caller), or NULL on error
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-clonecontents
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/cloneContents
pub export fn dom_range_clonecontents(range: *DOMRange) ?*DOMDocumentFragment {
    const r: *Range = @ptrCast(@alignCast(range));

    const fragment = r.cloneContents() catch {
        return null;
    };

    return @ptrCast(fragment);
}

/// Insert a node at the start of the range.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] undefined insertNode(Node node);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `node`: Node to insert
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-insertnode
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/insertNode
pub export fn dom_range_insertnode(range: *DOMRange, node: *DOMNode) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const n: *Node = @ptrCast(@alignCast(node));

    r.insertNode(n) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

/// Surround the range contents with a new parent.
///
/// ## WebIDL
/// ```webidl
/// [CEReactions] undefined surroundContents(Node newParent);
/// ```
///
/// ## Parameters
/// - `range`: Range handle
/// - `new_parent`: Node to wrap contents with
///
/// ## Returns
/// 0 on success, error code on failure
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-surroundcontents
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/surroundContents
pub export fn dom_range_surroundcontents(range: *DOMRange, new_parent: *DOMNode) c_int {
    const r: *Range = @ptrCast(@alignCast(range));
    const np: *Node = @ptrCast(@alignCast(new_parent));

    r.surroundContents(np) catch |err| {
        return @intFromEnum(zigErrorToDOMError(err));
    };

    return 0;
}

// ============================================================================
// Cloning and Lifecycle
// ============================================================================

/// Clone the range.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] Range cloneRange();
/// ```
///
/// ## Parameters
/// - `range`: Range handle
///
/// ## Returns
/// Cloned range (must be released by caller), or NULL on error
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-clonerange
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/cloneRange
pub export fn dom_range_clonerange(range: *DOMRange) ?*DOMRange {
    const r: *Range = @ptrCast(@alignCast(range));

    const cloned = r.cloneRange() catch {
        return null;
    };

    return @ptrCast(cloned);
}

/// Detach the range (no-op in modern DOM).
///
/// ## WebIDL
/// ```webidl
/// undefined detach();
/// ```
///
/// ## Parameters
/// - `range`: Range handle
///
/// ## Note
/// This method is a legacy no-op retained for compatibility.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-range-detach
/// - https://developer.mozilla.org/en-US/docs/Web/API/Range/detach
pub export fn dom_range_detach(range: *DOMRange) void {
    const r: *Range = @ptrCast(@alignCast(range));
    r.detach();
}

/// Release a Range.
///
/// Frees the range and all associated resources.
///
/// ## Parameters
/// - `range`: Range handle to release
///
/// ## Note
/// Does NOT affect the document tree or boundary nodes.
pub export fn dom_range_release(range: *DOMRange) void {
    const r: *Range = @ptrCast(@alignCast(range));
    r.deinit();
}
