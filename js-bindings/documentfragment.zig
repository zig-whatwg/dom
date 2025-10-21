//! DocumentFragment C-ABI Bindings
//!
//! C-ABI bindings for the DocumentFragment interface per WHATWG DOM specification.
//! DocumentFragment is a lightweight container for batch DOM operations.
//!
//! ## C API Overview
//!
//! ```c
//! // Note: DocumentFragment inherits all Node methods
//! // Reference counting
//! void dom_documentfragment_addref(DOMDocumentFragment* fragment);
//! void dom_documentfragment_release(DOMDocumentFragment* fragment);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface DocumentFragment : Node {
//!   constructor();
//! };
//! ```
//!
//! ## WHATWG Specification
//!
//! - DocumentFragment interface: https://dom.spec.whatwg.org/#interface-documentfragment
//! - Document.createDocumentFragment: https://dom.spec.whatwg.org/#dom-document-createdocumentfragment
//!
//! ## MDN Documentation
//!
//! - DocumentFragment: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const DocumentFragment = dom.DocumentFragment;
const DOMDocumentFragment = types.DOMDocumentFragment;

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of a DocumentFragment node.
///
/// Call this when sharing a DocumentFragment node reference.
///
/// ## Parameters
/// - `fragment`: DocumentFragment handle
///
/// ## Example
/// ```c
/// DOMDocumentFragment* fragment = dom_document_createdocumentfragment(doc);
///
/// // Share with another owner
/// dom_documentfragment_addref(fragment);
/// other_owner = fragment;
///
/// // Both owners must release
/// dom_documentfragment_release(fragment);
/// dom_documentfragment_release(fragment);
/// ```
pub export fn dom_documentfragment_addref(fragment: *DOMDocumentFragment) void {
    const fragment_node: *DocumentFragment = @ptrCast(@alignCast(fragment));
    fragment_node.prototype.acquire();
}

/// Decrement the reference count of a DocumentFragment node.
///
/// Call this when done with a DocumentFragment node. When ref count reaches 0,
/// the node is freed.
///
/// ## Parameters
/// - `fragment`: DocumentFragment handle
///
/// ## Example
/// ```c
/// DOMDocumentFragment* fragment = dom_document_createdocumentfragment(doc);
///
/// // Build DOM structure in fragment
/// DOMElement* div = dom_document_createelement(doc, "div");
/// dom_node_appendchild((DOMNode*)fragment, (DOMNode*)div);
///
/// // Insert fragment into document
/// dom_node_appendchild(parent, (DOMNode*)fragment);
///
/// // Clean up
/// dom_documentfragment_release(fragment);
/// ```
///
/// ## Note
/// DocumentFragment is useful for batch operations. When inserted into the DOM,
/// its children are moved to the target location and the fragment becomes empty.
pub export fn dom_documentfragment_release(fragment: *DOMDocumentFragment) void {
    const fragment_node: *DocumentFragment = @ptrCast(@alignCast(fragment));
    fragment_node.prototype.release();
}
