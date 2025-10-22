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

// ============================================================================
// ParentNode Mixin
// ============================================================================

/// Returns a live HTMLCollection of element children.
///
/// ## WebIDL
/// ```webidl
/// [SameObject] readonly attribute HTMLCollection children;
/// ```
///
/// ## Parameters
/// - `fragment`: DocumentFragment handle
///
/// ## Returns
/// Live HTMLCollection of element children (caller must release)
///
/// ## Spec References
/// - ParentNode mixin: https://dom.spec.whatwg.org/#dom-parentnode-children
/// - WebIDL: dom.idl:163
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
///
/// ## Note
/// [SameObject] - should return same collection object each call
/// For C-ABI, we return a new collection each time (caller must release)
///
/// ## Example (C)
/// ```c
/// DOMHTMLCollection* elements = dom_documentfragment_get_children(fragment);
/// uint32_t count = dom_htmlcollection_get_length(elements);
/// for (uint32_t i = 0; i < count; i++) {
///     DOMElement* elem = dom_htmlcollection_item(elements, i);
///     // Process element
/// }
/// dom_htmlcollection_release(elements);
/// ```
pub export fn dom_documentfragment_get_children(fragment: *DOMDocumentFragment) *types.DOMHTMLCollection {
    const frag: *DocumentFragment = @ptrCast(@alignCast(fragment));
    const collection = frag.children();

    // Allocate on heap for C-ABI
    const allocator = std.heap.c_allocator;
    const collection_ptr = allocator.create(dom.HTMLCollection) catch {
        @panic("Failed to allocate HTMLCollection");
    };
    collection_ptr.* = collection;

    return @ptrCast(collection_ptr);
}

/// Returns the first element child, or NULL if none.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? firstElementChild;
/// ```
///
/// ## Parameters
/// - `fragment`: DocumentFragment handle
///
/// ## Returns
/// First element child or NULL
///
/// ## Spec References
/// - ParentNode mixin: https://dom.spec.whatwg.org/#dom-parentnode-firstelementchild
/// - WebIDL: dom.idl:164
///
/// ## Example (C)
/// ```c
/// DOMElement* first = dom_documentfragment_get_firstelementchild(fragment);
/// if (first) {
///     printf("First element: %s\n", dom_element_get_tagname(first));
/// }
/// ```
pub export fn dom_documentfragment_get_firstelementchild(fragment: *DOMDocumentFragment) ?*types.DOMElement {
    const frag: *const DocumentFragment = @ptrCast(@alignCast(fragment));
    const first = frag.firstElementChild() orelse return null;
    return @ptrCast(first);
}

/// Returns the last element child, or NULL if none.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element? lastElementChild;
/// ```
///
/// ## Parameters
/// - `fragment`: DocumentFragment handle
///
/// ## Returns
/// Last element child or NULL
///
/// ## Spec References
/// - ParentNode mixin: https://dom.spec.whatwg.org/#dom-parentnode-lastelementchild
/// - WebIDL: dom.idl:165
///
/// ## Example (C)
/// ```c
/// DOMElement* last = dom_documentfragment_get_lastelementchild(fragment);
/// if (last) {
///     printf("Last element: %s\n", dom_element_get_tagname(last));
/// }
/// ```
pub export fn dom_documentfragment_get_lastelementchild(fragment: *DOMDocumentFragment) ?*types.DOMElement {
    const frag: *const DocumentFragment = @ptrCast(@alignCast(fragment));
    const last = frag.lastElementChild() orelse return null;
    return @ptrCast(last);
}

/// Returns the number of element children.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long childElementCount;
/// ```
///
/// ## Parameters
/// - `fragment`: DocumentFragment handle
///
/// ## Returns
/// Number of element children (text nodes, comments, etc. not counted)
///
/// ## Spec References
/// - ParentNode mixin: https://dom.spec.whatwg.org/#dom-parentnode-childelementcount
/// - WebIDL: dom.idl:166
///
/// ## Example (C)
/// ```c
/// uint32_t count = dom_documentfragment_get_childelementcount(fragment);
/// printf("Fragment has %u element children\n", count);
/// ```
pub export fn dom_documentfragment_get_childelementcount(fragment: *DOMDocumentFragment) u32 {
    const frag: *const DocumentFragment = @ptrCast(@alignCast(fragment));
    return frag.childElementCount();
}

/// Find first descendant element matching a CSS selector.
///
/// ## WebIDL
/// ```webidl
/// Element? querySelector(DOMString selectors);
/// ```
///
/// ## Parameters
/// - `fragment`: DocumentFragment handle
/// - `selectors`: CSS selector string
///
/// ## Returns
/// First matching element or NULL if none found
///
/// ## Spec References
/// - ParentNode mixin: https://dom.spec.whatwg.org/#dom-parentnode-queryselector
/// - WebIDL: dom.idl:171
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/querySelector
///
/// ## Example (C)
/// ```c
/// DOMElement* button = dom_documentfragment_queryselector(fragment, ".primary");
/// if (button) {
///     printf("Found primary button\n");
/// }
/// ```
pub export fn dom_documentfragment_queryselector(fragment: *DOMDocumentFragment, selectors: [*:0]const u8) ?*types.DOMElement {
    const frag: *DocumentFragment = @ptrCast(@alignCast(fragment));
    const selector_string = types.cStringToZigString(selectors);
    const allocator = std.heap.c_allocator;

    const result = frag.querySelector(allocator, selector_string) catch {
        return null;
    };

    return if (result) |elem| @ptrCast(elem) else null;
}

/// Find all descendant elements matching a CSS selector.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] NodeList querySelectorAll(DOMString selectors);
/// ```
///
/// ## Parameters
/// - `fragment`: DocumentFragment handle
/// - `selectors`: CSS selector string
///
/// ## Returns
/// Static NodeList of matching elements (caller must free with dom_nodelist_static_release)
/// Returns NULL on error or empty result
///
/// ## Spec References
/// - ParentNode mixin: https://dom.spec.whatwg.org/#dom-parentnode-queryselectorall
/// - WebIDL: dom.idl:172
/// - MDN: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/querySelectorAll
///
/// ## Note
/// Returns a static snapshot (not live) of matching elements at query time.
///
/// ## Example (C)
/// ```c
/// DOMNodeList* results = dom_documentfragment_queryselectorall(fragment, ".item");
/// if (results) {
///     uint32_t count = dom_nodelist_static_get_length(results);
///     for (uint32_t i = 0; i < count; i++) {
///         DOMNode* node = dom_nodelist_static_item(results, i);
///         // Process node
///     }
///     dom_nodelist_static_release(results);
/// }
/// ```
pub export fn dom_documentfragment_queryselectorall(fragment: *DOMDocumentFragment, selectors: [*:0]const u8) ?*types.DOMNodeList {
    const frag: *DocumentFragment = @ptrCast(@alignCast(fragment));
    const selector_string = types.cStringToZigString(selectors);
    const allocator = std.heap.c_allocator;

    const results = frag.querySelectorAll(allocator, selector_string) catch {
        return null;
    };

    if (results.len == 0) {
        return null;
    }

    // Create static snapshot wrapper (same pattern as Document/Element)
    const Element = dom.Element;
    const StaticNodeList = struct {
        elements: [*]*Element,
        count: usize,
    };

    const heap_results = allocator.dupe(*Element, results) catch {
        return null;
    };

    const wrapper = allocator.create(StaticNodeList) catch {
        allocator.free(heap_results);
        return null;
    };

    wrapper.* = StaticNodeList{
        .elements = heap_results.ptr,
        .count = heap_results.len,
    };

    return @ptrCast(wrapper);
}
