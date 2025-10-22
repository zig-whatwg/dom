//! AbstractRange JavaScript Bindings
//!
//! C-ABI bindings for the AbstractRange interface.
//!
//! ## WHATWG Specification
//!
//! AbstractRange is the base interface for Range and StaticRange:
//! - **§5.1 Interface AbstractRange**: https://dom.spec.whatwg.org/#interface-abstractrange
//!
//! ## MDN Documentation
//!
//! - AbstractRange: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange
//! - AbstractRange.startContainer: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/startContainer
//! - AbstractRange.startOffset: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/startOffset
//! - AbstractRange.endContainer: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/endContainer
//! - AbstractRange.endOffset: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/endOffset
//! - AbstractRange.collapsed: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange/collapsed
//!
//! ## WebIDL Definition
//!
//! ```webidl
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
//! Spec reference: https://dom.spec.whatwg.org/#abstractrange (WebIDL: dom.idl:475-481)
//!
//! ## Exported Functions (5 total)
//!
//! ### Properties
//! - `dom_abstractrange_get_startcontainer()` - Start boundary node
//! - `dom_abstractrange_get_startoffset()` - Offset within start container
//! - `dom_abstractrange_get_endcontainer()` - End boundary node
//! - `dom_abstractrange_get_endoffset()` - Offset within end container
//! - `dom_abstractrange_get_collapsed()` - Whether range is collapsed
//!
//! ## Usage Example (C)
//!
//! ```c
//! // AbstractRange is abstract - use Range or StaticRange
//! DOMRange* range = dom_document_createrange(doc);
//!
//! // Cast to AbstractRange to use base interface
//! DOMAbstractRange* abstract = (DOMAbstractRange*)range;
//!
//! // Get boundary points
//! DOMNode* start_node = dom_abstractrange_get_startcontainer(abstract);
//! uint32_t start_offset = dom_abstractrange_get_startoffset(abstract);
//!
//! DOMNode* end_node = dom_abstractrange_get_endcontainer(abstract);
//! uint32_t end_offset = dom_abstractrange_get_endoffset(abstract);
//!
//! // Check if collapsed
//! if (dom_abstractrange_get_collapsed(abstract)) {
//!     printf("Range is collapsed (start == end)\n");
//! }
//!
//! dom_range_release(range);
//! ```

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const AbstractRange = dom.AbstractRange;
const Node = dom.Node;
const DOMAbstractRange = types.DOMAbstractRange;
const DOMNode = types.DOMNode;

// ============================================================================
// Properties
// ============================================================================

/// Gets the start container node.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node startContainer;
/// ```
///
/// ## Parameters
/// - `range`: AbstractRange handle
///
/// ## Returns
/// Start boundary container node (borrowed reference - do NOT release separately)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-abstractrange-startcontainer
/// - WebIDL: dom.idl:476
///
/// ## Example (C)
/// ```c
/// DOMNode* start_node = dom_abstractrange_get_startcontainer(abstract_range);
/// const char* node_name = dom_node_get_nodename(start_node);
/// ```
pub export fn dom_abstractrange_get_startcontainer(range: *DOMAbstractRange) *DOMNode {
    const abstract_range: *const AbstractRange = @ptrCast(@alignCast(range));
    return @ptrCast(abstract_range.start_container);
}

/// Gets the start offset.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long startOffset;
/// ```
///
/// ## Parameters
/// - `range`: AbstractRange handle
///
/// ## Returns
/// Offset within start container (0-based)
/// - For Text/Comment: Character offset
/// - For Element/DocumentFragment: Child index
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-abstractrange-startoffset
/// - WebIDL: dom.idl:477
///
/// ## Example (C)
/// ```c
/// uint32_t offset = dom_abstractrange_get_startoffset(abstract_range);
/// printf("Start offset: %u\n", offset);
/// ```
pub export fn dom_abstractrange_get_startoffset(range: *DOMAbstractRange) u32 {
    const abstract_range: *const AbstractRange = @ptrCast(@alignCast(range));
    return abstract_range.start_offset;
}

/// Gets the end container node.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Node endContainer;
/// ```
///
/// ## Parameters
/// - `range`: AbstractRange handle
///
/// ## Returns
/// End boundary container node (borrowed reference - do NOT release separately)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-abstractrange-endcontainer
/// - WebIDL: dom.idl:478
///
/// ## Example (C)
/// ```c
/// DOMNode* end_node = dom_abstractrange_get_endcontainer(abstract_range);
/// const char* node_name = dom_node_get_nodename(end_node);
/// ```
pub export fn dom_abstractrange_get_endcontainer(range: *DOMAbstractRange) *DOMNode {
    const abstract_range: *const AbstractRange = @ptrCast(@alignCast(range));
    return @ptrCast(abstract_range.end_container);
}

/// Gets the end offset.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long endOffset;
/// ```
///
/// ## Parameters
/// - `range`: AbstractRange handle
///
/// ## Returns
/// Offset within end container (0-based)
/// - For Text/Comment: Character offset
/// - For Element/DocumentFragment: Child index
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-abstractrange-endoffset
/// - WebIDL: dom.idl:479
///
/// ## Example (C)
/// ```c
/// uint32_t offset = dom_abstractrange_get_endoffset(abstract_range);
/// printf("End offset: %u\n", offset);
/// ```
pub export fn dom_abstractrange_get_endoffset(range: *DOMAbstractRange) u32 {
    const abstract_range: *const AbstractRange = @ptrCast(@alignCast(range));
    return abstract_range.end_offset;
}

/// Gets whether the range is collapsed (start == end).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean collapsed;
/// ```
///
/// ## Parameters
/// - `range`: AbstractRange handle
///
/// ## Returns
/// 1 if collapsed (start and end are equal), 0 otherwise
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-abstractrange-collapsed
/// - WebIDL: dom.idl:480
///
/// ## Note
/// A range is collapsed when:
/// - start_container == end_container AND
/// - start_offset == end_offset
///
/// ## Example (C)
/// ```c
/// if (dom_abstractrange_get_collapsed(abstract_range)) {
///     printf("Range is collapsed (insertion point)\n");
/// } else {
///     printf("Range spans content\n");
/// }
/// ```
pub export fn dom_abstractrange_get_collapsed(range: *DOMAbstractRange) u8 {
    const abstract_range: *const AbstractRange = @ptrCast(@alignCast(range));
    return if (abstract_range.collapsed()) 1 else 0;
}
