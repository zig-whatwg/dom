//! Comment JavaScript Bindings
//!
//! C-ABI bindings for the Comment interface.
//!
//! ## WHATWG Specification
//!
//! Comment nodes represent comments in the DOM:
//! - **§4.9 Interface Comment**: https://dom.spec.whatwg.org/#interface-comment
//!
//! ## MDN Documentation
//!
//! - Comment: https://developer.mozilla.org/en-US/docs/Web/API/Comment
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface Comment : CharacterData {
//!   constructor(optional DOMString data = "");
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#comment (WebIDL: dom.idl:452-454)
//!
//! ## Exported Functions (2 total)
//!
//! ### Memory Management
//! - `dom_comment_addref()` - Increment reference count
//! - `dom_comment_release()` - Decrement reference count
//!
//! ## Inheritance
//!
//! Comment inherits from CharacterData, which provides:
//! - Properties: data, length
//! - Methods: substringData(), appendData(), insertData(), deleteData(), replaceData()
//!
//! Use CharacterData functions by casting: `(DOMCharacterData*)comment`
//!
//! ## Usage Example (C)
//!
//! ```c
//! DOMDocument* doc = dom_document_new();
//! DOMComment* comment = dom_document_createcomment(doc, " This is a comment ");
//!
//! // Use CharacterData methods
//! const char* data = dom_characterdata_get_data((DOMCharacterData*)comment);
//! printf("%s\n", data); // " This is a comment "
//!
//! dom_characterdata_appenddata((DOMCharacterData*)comment, " - Updated");
//!
//! // Clean up
//! dom_comment_release(comment);
//! dom_document_release(doc);
//! ```

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const Comment = dom.Comment;
const DOMComment = types.DOMComment;

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of a Comment node.
///
/// Call this when sharing a Comment node reference.
///
/// ## Parameters
/// - `comment`: Comment node handle
///
/// ## Example
/// ```c
/// dom_comment_addref(comment); // Share ownership
/// other_structure.comment_node = comment;
/// // Both owners must call release()
/// ```
pub export fn dom_comment_addref(comment: *DOMComment) void {
    const comment_node: *Comment = @ptrCast(@alignCast(comment));
    comment_node.prototype.acquire();
}

/// Decrement the reference count of a Comment node.
///
/// Call this when done with a Comment node. When ref count reaches 0,
/// the node is freed.
///
/// ## Parameters
/// - `comment`: Comment node handle
///
/// ## Example
/// ```c
/// DOMComment* comment = dom_document_createcomment(doc, " Comment ");
/// // ... use comment ...
/// dom_comment_release(comment); // Free when ref count reaches 0
/// ```
pub export fn dom_comment_release(comment: *DOMComment) void {
    const comment_node: *Comment = @ptrCast(@alignCast(comment));
    comment_node.prototype.release();
}
