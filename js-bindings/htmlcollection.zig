//! HTMLCollection C-ABI Bindings
//!
//! C-ABI bindings for the HTMLCollection interface per WHATWG DOM specification.
//! HTMLCollection is a live collection of Element nodes (text/comment nodes excluded).
//!
//! ## C API Overview
//!
//! ```c
//! // Get HTMLCollection
//! DOMHTMLCollection* dom_element_get_children(DOMElement* elem);
//!
//! // Access items
//! uint32_t dom_htmlcollection_get_length(DOMHTMLCollection* collection);
//! DOMElement* dom_htmlcollection_item(DOMHTMLCollection* collection, uint32_t index);
//! DOMElement* dom_htmlcollection_nameditem(DOMHTMLCollection* collection, const char* name);
//!
//! // Release
//! void dom_htmlcollection_release(DOMHTMLCollection* collection);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window, LegacyUnenumerableNamedProperties]
//! interface HTMLCollection {
//!   readonly attribute unsigned long length;
//!   getter Element? item(unsigned long index);
//!   getter Element? namedItem(DOMString name);
//! };
//! ```
//!
//! ## WHATWG Specification
//!
//! - HTMLCollection interface: https://dom.spec.whatwg.org/#interface-htmlcollection
//! - ParentNode.children: https://dom.spec.whatwg.org/#dom-parentnode-children
//!
//! ## MDN Documentation
//!
//! - HTMLCollection: https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection
//! - HTMLCollection.length: https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection/length
//! - HTMLCollection.item(): https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection/item
//! - HTMLCollection.namedItem(): https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection/namedItem

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const Element = dom.Element;
const HTMLCollection = dom.HTMLCollection;
const DOMElement = types.DOMElement;
const DOMHTMLCollection = types.DOMHTMLCollection;

// ============================================================================
// Properties
// ============================================================================

/// Get the length of an HTMLCollection.
///
/// Returns the number of elements in the collection. This is a live count that
/// reflects the current state of the DOM (elements only, no text/comment nodes).
///
/// ## WebIDL
/// ```webidl
/// readonly attribute unsigned long length;
/// ```
///
/// ## Parameters
/// - `collection`: HTMLCollection handle
///
/// ## Returns
/// Number of elements in the collection
///
/// ## Example
/// ```c
/// DOMHTMLCollection* children = dom_element_get_children(parent);
/// uint32_t count = dom_htmlcollection_get_length(children);
/// printf("Parent has %u element children\n", count);
/// dom_htmlcollection_release(children);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-htmlcollection-length
/// - https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection/length
pub export fn dom_htmlcollection_get_length(collection: *DOMHTMLCollection) u32 {
    const html_collection: *HTMLCollection = @ptrCast(@alignCast(collection));
    return @intCast(html_collection.length());
}

// ============================================================================
// Methods
// ============================================================================

/// Get an element at a specific index in the collection.
///
/// Returns the element at the specified index, or null if the index is out of bounds.
/// This is a live view - the returned element reflects the current DOM state.
///
/// ## WebIDL
/// ```webidl
/// getter Element? item(unsigned long index);
/// ```
///
/// ## Parameters
/// - `collection`: HTMLCollection handle
/// - `index`: Zero-based index
///
/// ## Returns
/// Element at index or null if out of bounds
///
/// ## Example
/// ```c
/// DOMHTMLCollection* children = dom_element_get_children(parent);
/// uint32_t count = dom_htmlcollection_get_length(children);
///
/// for (uint32_t i = 0; i < count; i++) {
///     DOMElement* child = dom_htmlcollection_item(children, i);
///     if (child != NULL) {
///         const char* tag = dom_element_get_tagname(child);
///         printf("Child %u: %s\n", i, tag);
///     }
/// }
///
/// dom_htmlcollection_release(children);
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-htmlcollection-item
/// - https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection/item
pub export fn dom_htmlcollection_item(collection: *DOMHTMLCollection, index: u32) ?*DOMElement {
    const html_collection: *HTMLCollection = @ptrCast(@alignCast(collection));
    const element = html_collection.item(@intCast(index));
    if (element) |elem| {
        return @ptrCast(@alignCast(elem));
    }
    return null;
}

/// Get an element by its id or name attribute.
///
/// Returns the first element in the collection with the specified id or name attribute.
/// This provides named access to collection items (e.g., form elements by name).
///
/// ## WebIDL
/// ```webidl
/// getter Element? namedItem(DOMString name);
/// ```
///
/// ## Parameters
/// - `collection`: HTMLCollection handle
/// - `name`: Value to match against id or name attributes
///
/// ## Returns
/// First element with matching id or name, or null if not found
///
/// ## Example
/// ```c
/// DOMHTMLCollection* forms = dom_document_get_forms(doc);
/// DOMElement* login_form = dom_htmlcollection_nameditem(forms, "loginForm");
/// if (login_form != NULL) {
///     printf("Found login form\n");
/// }
/// dom_htmlcollection_release(forms);
/// ```
///
/// ## Note
/// This method is primarily used for HTML-specific collections like document.forms.
/// In generic DOM (non-HTML), it may have limited utility.
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-htmlcollection-nameditem
/// - https://developer.mozilla.org/en-US/docs/Web/API/HTMLCollection/namedItem
pub export fn dom_htmlcollection_nameditem(collection: *DOMHTMLCollection, name: [*:0]const u8) ?*DOMElement {
    const html_collection: *HTMLCollection = @ptrCast(@alignCast(collection));
    const name_slice = std.mem.span(name);
    const element = html_collection.namedItem(name_slice);
    if (element) |elem| {
        return @ptrCast(@alignCast(elem));
    }
    return null;
}

// ============================================================================
// Memory Management
// ============================================================================

/// Release an HTMLCollection.
///
/// HTMLCollection is a value type in Zig but heap-allocated for C interop.
/// Call this when done with an HTMLCollection returned from the API.
///
/// ## Parameters
/// - `collection`: HTMLCollection handle to release
///
/// ## Example
/// ```c
/// DOMHTMLCollection* children = dom_element_get_children(parent);
/// // ... use children ...
/// dom_htmlcollection_release(children);
/// ```
///
/// ## Note
/// HTMLCollection doesn't own the elements it references. Releasing the collection
/// does NOT release the elements themselves - they are owned by their parent.
pub export fn dom_htmlcollection_release(collection: *DOMHTMLCollection) void {
    const allocator = std.heap.page_allocator;
    const html_collection: *HTMLCollection = @ptrCast(@alignCast(collection));
    allocator.destroy(html_collection);
}
