//! CDATASection JavaScript Bindings
//!
//! C-ABI bindings for the CDATASection interface.
//!
//! ## WHATWG Specification
//!
//! CDATASection nodes represent CDATA sections in XML documents:
//! - **§4.10 Interface CDATASection**: https://dom.spec.whatwg.org/#interface-cdatasection
//!
//! ## MDN Documentation
//!
//! - CDATASection: https://developer.mozilla.org/en-US/docs/Web/API/CDATASection
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface CDATASection : Text {
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#cdatasection (WebIDL: dom.idl:446-448)
//!
//! ## Exported Functions (2 total)
//!
//! ### Memory Management
//! - `dom_cdatasection_addref()` - Increment reference count
//! - `dom_cdatasection_release()` - Decrement reference count
//!
//! ## Inheritance
//!
//! CDATASection inherits from Text, which inherits from CharacterData:
//! - Text methods: splitText(), wholeText
//! - CharacterData: data, length, substringData(), appendData(), insertData(), deleteData(), replaceData()
//!
//! Use Text functions by casting: `(DOMText*)cdata`
//! Use CharacterData functions by casting: `(DOMCharacterData*)cdata`
//!
//! ## Usage Example (C)
//!
//! ```c
//! DOMDocument* doc = dom_document_new();
//! DOMCDATASection* cdata = dom_document_createcdatasection(doc, "<xml>data</xml>");
//!
//! // Use CharacterData methods
//! const char* data = dom_characterdata_get_data((DOMCharacterData*)cdata);
//! printf("%s\n", data); // "<xml>data</xml>"
//!
//! // Use Text methods
//! DOMText* second = dom_text_splittext((DOMText*)cdata, 5);
//! dom_text_release(second);
//!
//! // Clean up
//! dom_cdatasection_release(cdata);
//! dom_document_release(doc);
//! ```
//!
//! ## Note
//!
//! CDATA sections are only valid in XML documents, not HTML.
//! They allow including text that would otherwise be treated as markup.
//!
//! Example in XML:
//! ```xml
//! <script><![CDATA[
//!   if (x < 10) { ... }
//! ]]></script>
//! ```

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const CDATASection = dom.CDATASection;
const DOMCDATASection = types.DOMCDATASection;

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of a CDATASection node.
///
/// Call this when sharing a CDATASection node reference.
///
/// ## Parameters
/// - `cdata`: CDATASection node handle
///
/// ## Example
/// ```c
/// dom_cdatasection_addref(cdata); // Share ownership
/// other_structure.cdata_node = cdata;
/// // Both owners must call release()
/// ```
pub export fn dom_cdatasection_addref(cdata: *DOMCDATASection) void {
    const cdata_node: *CDATASection = @ptrCast(@alignCast(cdata));
    cdata_node.prototype.prototype.acquire();
}

/// Decrement the reference count of a CDATASection node.
///
/// Call this when done with a CDATASection node. When ref count reaches 0,
/// the node is freed.
///
/// ## Parameters
/// - `cdata`: CDATASection node handle
///
/// ## Example
/// ```c
/// DOMCDATASection* cdata = dom_document_createcdatasection(doc, "data");
/// // ... use cdata ...
/// dom_cdatasection_release(cdata); // Free when ref count reaches 0
/// ```
pub export fn dom_cdatasection_release(cdata: *DOMCDATASection) void {
    const cdata_node: *CDATASection = @ptrCast(@alignCast(cdata));
    cdata_node.prototype.prototype.release();
}
