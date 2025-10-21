//! ShadowRoot C-ABI Bindings
//!
//! C-ABI bindings for the ShadowRoot interface per WHATWG DOM specification.
//! ShadowRoot extends DocumentFragment to provide shadow DOM encapsulation.
//!
//! ## C API Overview
//!
//! ```c
//! // Attach shadow root to element
//! DOMShadowRoot* shadow = dom_element_attachshadow(elem, DOM_SHADOWROOT_MODE_OPEN, false);
//!
//! // Get shadow root properties
//! DOMShadowRootMode mode = dom_shadowroot_get_mode(shadow);
//! bool delegates = dom_shadowroot_get_delegatesfocus(shadow);
//! DOMElement* host = dom_shadowroot_get_host(shadow);
//!
//! // ShadowRoot inherits from Node (use dom_node_* functions)
//! dom_node_appendchild((DOMNode*)shadow, (DOMNode*)child);
//! ```
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface ShadowRoot : DocumentFragment {
//!   readonly attribute ShadowRootMode mode;
//!   readonly attribute boolean delegatesFocus;
//!   readonly attribute SlotAssignmentMode slotAssignment;
//!   readonly attribute boolean clonable;
//!   readonly attribute boolean serializable;
//!   readonly attribute Element host;
//!
//!   attribute EventHandler onslotchange;
//! };
//!
//! enum ShadowRootMode { "open", "closed" };
//! enum SlotAssignmentMode { "manual", "named" };
//! ```
//!
//! ## WHATWG Specification
//!
//! - ShadowRoot interface: https://dom.spec.whatwg.org/#interface-shadowroot
//! - Shadow tree: https://dom.spec.whatwg.org/#concept-shadow-tree
//! - Element.attachShadow(): https://dom.spec.whatwg.org/#dom-element-attachshadow
//!
//! ## MDN Documentation
//!
//! - ShadowRoot: https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot
//! - Element.attachShadow(): https://developer.mozilla.org/en-US/docs/Web/API/Element/attachShadow
//! - Using shadow DOM: https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_shadow_DOM

const std = @import("std");
const dom = @import("dom");
const types = @import("dom_types.zig");

const ShadowRoot = dom.ShadowRoot;
const Element = dom.Element;
const DOMShadowRoot = types.DOMShadowRoot;
const DOMElement = types.DOMElement;

// ============================================================================
// Properties
// ============================================================================

/// Get the mode of a shadow root.
///
/// Returns the mode (open or closed) of the shadow root.
/// - Open: Element.shadowRoot returns the shadow root
/// - Closed: Element.shadowRoot returns null (hidden from JS)
///
/// ## WebIDL
/// ```webidl
/// readonly attribute ShadowRootMode mode;
/// ```
///
/// ## Parameters
/// - `shadow`: ShadowRoot handle
///
/// ## Returns
/// 0 for open, 1 for closed
///
/// ## Example
/// ```c
/// DOMShadowRoot* shadow = dom_element_attachshadow(elem, DOM_SHADOWROOT_MODE_OPEN, false);
/// int mode = dom_shadowroot_get_mode(shadow);
/// // mode == 0 (open)
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-shadowroot-mode
/// - https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/mode
pub export fn dom_shadowroot_get_mode(shadow: *DOMShadowRoot) c_int {
    const shadow_root: *ShadowRoot = @ptrCast(@alignCast(shadow));
    return @intFromEnum(shadow_root.mode);
}

/// Get the delegatesFocus flag.
///
/// Returns whether the shadow root delegates focus to its first focusable element.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean delegatesFocus;
/// ```
///
/// ## Parameters
/// - `shadow`: ShadowRoot handle
///
/// ## Returns
/// true if focus is delegated, false otherwise
///
/// ## Example
/// ```c
/// DOMShadowRoot* shadow = dom_element_attachshadow(elem, DOM_SHADOWROOT_MODE_OPEN, true);
/// bool delegates = dom_shadowroot_get_delegatesfocus(shadow);
/// // delegates == true
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-shadowroot-delegatesfocus
/// - https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/delegatesFocus
pub export fn dom_shadowroot_get_delegatesfocus(shadow: *DOMShadowRoot) bool {
    const shadow_root: *ShadowRoot = @ptrCast(@alignCast(shadow));
    return shadow_root.delegates_focus;
}

/// Get the slot assignment mode.
///
/// Returns the slot assignment mode:
/// - 0 (named): Automatic slot assignment based on slot attribute
/// - 1 (manual): Manual slot assignment via HTMLSlotElement.assign()
///
/// ## WebIDL
/// ```webidl
/// readonly attribute SlotAssignmentMode slotAssignment;
/// ```
///
/// ## Parameters
/// - `shadow`: ShadowRoot handle
///
/// ## Returns
/// 0 for named, 1 for manual
///
/// ## Example
/// ```c
/// int mode = dom_shadowroot_get_slotassignment(shadow);
/// // mode == 0 (named, default)
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-shadowroot-slotassignment
/// - https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/slotAssignment
pub export fn dom_shadowroot_get_slotassignment(shadow: *DOMShadowRoot) c_int {
    const shadow_root: *ShadowRoot = @ptrCast(@alignCast(shadow));
    return @intFromEnum(shadow_root.slot_assignment);
}

/// Get the clonable flag.
///
/// Returns whether the shadow root can be cloned with cloneNode().
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean clonable;
/// ```
///
/// ## Parameters
/// - `shadow`: ShadowRoot handle
///
/// ## Returns
/// true if clonable, false otherwise
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-shadowroot-clonable
pub export fn dom_shadowroot_get_clonable(shadow: *DOMShadowRoot) bool {
    const shadow_root: *ShadowRoot = @ptrCast(@alignCast(shadow));
    return shadow_root.clonable;
}

/// Get the serializable flag.
///
/// Returns whether the shadow root is included in innerHTML.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute boolean serializable;
/// ```
///
/// ## Parameters
/// - `shadow`: ShadowRoot handle
///
/// ## Returns
/// true if serializable, false otherwise
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-shadowroot-serializable
pub export fn dom_shadowroot_get_serializable(shadow: *DOMShadowRoot) bool {
    const shadow_root: *ShadowRoot = @ptrCast(@alignCast(shadow));
    return shadow_root.serializable;
}

/// Get the host element.
///
/// Returns the element that hosts this shadow root.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute Element host;
/// ```
///
/// ## Parameters
/// - `shadow`: ShadowRoot handle
///
/// ## Returns
/// Host element (never null)
///
/// ## Example
/// ```c
/// DOMShadowRoot* shadow = dom_element_attachshadow(elem, DOM_SHADOWROOT_MODE_OPEN, false);
/// DOMElement* host = dom_shadowroot_get_host(shadow);
/// // host == elem
/// ```
///
/// ## Spec
/// - https://dom.spec.whatwg.org/#dom-shadowroot-host
/// - https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/host
pub export fn dom_shadowroot_get_host(shadow: *DOMShadowRoot) *DOMElement {
    const shadow_root: *ShadowRoot = @ptrCast(@alignCast(shadow));
    return @ptrCast(@alignCast(shadow_root.host_element));
}
