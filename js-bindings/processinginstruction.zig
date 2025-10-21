//! ProcessingInstruction JavaScript Bindings
//!
//! C-ABI bindings for the ProcessingInstruction interface.
//!
//! ## WHATWG Specification
//!
//! ProcessingInstruction nodes represent processing instructions in XML documents:
//! - **§4.11 Interface ProcessingInstruction**: https://dom.spec.whatwg.org/#interface-processinginstruction
//!
//! ## MDN Documentation
//!
//! - ProcessingInstruction: https://developer.mozilla.org/en-US/docs/Web/API/ProcessingInstruction
//! - ProcessingInstruction.target: https://developer.mozilla.org/en-US/docs/Web/API/ProcessingInstruction/target
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface ProcessingInstruction : CharacterData {
//!   readonly attribute DOMString target;
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#processinginstruction (WebIDL: dom.idl:449-451)
//!
//! ## Exported Functions (3 total)
//!
//! ### Properties
//! - `dom_processinginstruction_get_target()` - Get target application name
//!
//! ### Memory Management
//! - `dom_processinginstruction_addref()` - Increment reference count
//! - `dom_processinginstruction_release()` - Decrement reference count
//!
//! ## Inheritance
//!
//! ProcessingInstruction inherits from CharacterData, which provides:
//! - Properties: data, length
//! - Methods: substringData(), appendData(), insertData(), deleteData(), replaceData()
//!
//! Use CharacterData functions by casting: `(DOMCharacterData*)pi`
//!
//! ## Usage Example (C)
//!
//! ```c
//! DOMDocument* doc = dom_document_new();
//! DOMProcessingInstruction* pi = dom_document_createprocessinginstruction(
//!     doc,
//!     "xml-stylesheet",
//!     "href='style.css' type='text/css'"
//! );
//!
//! // Get target
//! const char* target = dom_processinginstruction_get_target(pi);
//! printf("Target: %s\n", target); // "xml-stylesheet"
//!
//! // Use CharacterData methods for data
//! const char* data = dom_characterdata_get_data((DOMCharacterData*)pi);
//! printf("Data: %s\n", data); // "href='style.css' type='text/css'"
//!
//! // Clean up
//! dom_processinginstruction_release(pi);
//! dom_document_release(doc);
//! ```
//!
//! ## Note
//!
//! Processing instructions are only valid in XML documents, not HTML.
//! Common examples:
//! - `<?xml version="1.0" encoding="UTF-8"?>` (XML declaration)
//! - `<?xml-stylesheet href="style.css" type="text/css"?>` (Stylesheet PI)
//! - Custom application instructions

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const ProcessingInstruction = dom.ProcessingInstruction;
const DOMProcessingInstruction = types.DOMProcessingInstruction;

// ============================================================================
// Properties
// ============================================================================

/// Gets the target of a ProcessingInstruction node.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString target;
/// ```
///
/// ## Parameters
/// - `pi`: ProcessingInstruction handle
///
/// ## Returns
/// Target application name (borrowed string - do NOT free)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-processinginstruction-target
/// - WebIDL: dom.idl:450
///
/// ## Example
/// ```c
/// DOMProcessingInstruction* pi = dom_document_createprocessinginstruction(
///     doc, "xml-stylesheet", "href='style.css'"
/// );
/// const char* target = dom_processinginstruction_get_target(pi);
/// printf("%s\n", target); // "xml-stylesheet"
/// ```
pub export fn dom_processinginstruction_get_target(pi: *DOMProcessingInstruction) [*:0]const u8 {
    const pi_node: *const ProcessingInstruction = @ptrCast(@alignCast(pi));
    return types.zigStringToCString(pi_node.target);
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of a ProcessingInstruction node.
///
/// Call this when sharing a ProcessingInstruction node reference.
///
/// ## Parameters
/// - `pi`: ProcessingInstruction handle
///
/// ## Example
/// ```c
/// dom_processinginstruction_addref(pi); // Share ownership
/// other_structure.pi_node = pi;
/// // Both owners must call release()
/// ```
pub export fn dom_processinginstruction_addref(pi: *DOMProcessingInstruction) void {
    const pi_node: *ProcessingInstruction = @ptrCast(@alignCast(pi));
    pi_node.prototype.prototype.acquire();
}

/// Decrement the reference count of a ProcessingInstruction node.
///
/// Call this when done with a ProcessingInstruction node. When ref count reaches 0,
/// the node is freed.
///
/// ## Parameters
/// - `pi`: ProcessingInstruction handle
///
/// ## Example
/// ```c
/// DOMProcessingInstruction* pi = dom_document_createprocessinginstruction(
///     doc, "xml", "version='1.0'"
/// );
/// // ... use pi ...
/// dom_processinginstruction_release(pi); // Free when ref count reaches 0
/// ```
pub export fn dom_processinginstruction_release(pi: *DOMProcessingInstruction) void {
    const pi_node: *ProcessingInstruction = @ptrCast(@alignCast(pi));
    pi_node.prototype.prototype.release();
}
