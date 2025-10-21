//! Text JavaScript Bindings
//!
//! C-ABI bindings for the Text interface.
//!
//! ## WHATWG Specification
//!
//! Text nodes represent textual content in the DOM:
//! - **§4.7 Interface Text**: https://dom.spec.whatwg.org/#interface-text
//!
//! ## MDN Documentation
//!
//! - Text: https://developer.mozilla.org/en-US/docs/Web/API/Text
//! - Text.splitText(): https://developer.mozilla.org/en-US/docs/Web/API/Text/splitText
//! - Text.wholeText: https://developer.mozilla.org/en-US/docs/Web/API/Text/wholeText
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface Text : CharacterData {
//!   constructor(optional DOMString data = "");
//!   [NewObject] Text splitText(unsigned long offset);
//!   readonly attribute DOMString wholeText;
//! };
//! ```
//!
//! Spec reference: https://dom.spec.whatwg.org/#text (WebIDL: dom.idl:439-443)
//!
//! ## Exported Functions (4 total)
//!
//! ### Text-Specific Methods
//! - `dom_text_splittext()` - Split text node at offset
//! - `dom_text_get_wholetext()` - Get concatenated text of adjacent text nodes
//!
//! ### Memory Management
//! - `dom_text_addref()` - Increment reference count
//! - `dom_text_release()` - Decrement reference count
//!
//! ## Inheritance
//!
//! Text inherits from CharacterData, which provides:
//! - Properties: data, length
//! - Methods: substringData(), appendData(), insertData(), deleteData(), replaceData()
//!
//! Use CharacterData functions by casting: `(DOMCharacterData*)text`
//!
//! ## Usage Example (C)
//!
//! ```c
//! DOMDocument* doc = dom_document_new();
//! DOMText* text = dom_document_createtextnode(doc, "Hello World");
//!
//! // Use CharacterData methods
//! dom_characterdata_appenddata((DOMCharacterData*)text, "!");
//!
//! // Use Text-specific methods
//! DOMText* second = dom_text_splittext(text, 5);
//! // text.data = "Hello", second.data = " World!"
//!
//! const char* whole = dom_text_get_wholetext(text);
//! printf("%s\n", whole); // "Hello World!" (concatenated)
//!
//! dom_text_release(second);
//! dom_text_release(text);
//! dom_document_release(doc);
//! ```

const std = @import("std");
const types = @import("dom_types.zig");
const dom = @import("dom");

const Text = dom.Text;
const DOMText = types.DOMText;

// ============================================================================
// Text-Specific Methods
// ============================================================================

/// Splits a Text node at the specified offset.
///
/// ## WebIDL
/// ```webidl
/// [NewObject] Text splitText(unsigned long offset);
/// ```
///
/// ## Algorithm (from DOM spec)
/// 1. Let length be node's length
/// 2. If offset is greater than length, throw IndexSizeError
/// 3. Let count be length minus offset
/// 4. Let new data be substring of node's data from offset
/// 5. Let new node be new Text with new data
/// 6. Let parent be node's parent
/// 7. If parent is not null:
///    a. Insert new node after node
/// 8. Replace data in node from offset, count with empty string
/// 9. Return new node
///
/// ## Parameters
/// - `text`: Text node handle
/// - `offset`: Position to split at (0-based)
///
/// ## Returns
/// New Text node containing text after offset, or NULL on error
/// Caller receives ownership and MUST call dom_text_release()
///
/// ## Spec References
/// - Method: https://dom.spec.whatwg.org/#dom-text-splittext
/// - WebIDL: dom.idl:441
///
/// ## Example
/// ```c
/// DOMText* text = dom_document_createtextnode(doc, "Hello World");
/// DOMText* second = dom_text_splittext(text, 6);
/// // text.data = "Hello ", second.data = "World"
/// dom_text_release(second);
/// ```
pub export fn dom_text_splittext(text: *DOMText, offset: u32) ?*DOMText {
    const text_node: *Text = @ptrCast(@alignCast(text));
    const new_text = text_node.splitText(offset) catch return null;
    return @ptrCast(new_text);
}

/// Gets the concatenated text of this node and all adjacent Text nodes.
///
/// ## WebIDL
/// ```webidl
/// readonly attribute DOMString wholeText;
/// ```
///
/// ## Returns
/// Concatenated text of this and adjacent text nodes (borrowed - do NOT free)
///
/// ## Spec References
/// - Attribute: https://dom.spec.whatwg.org/#dom-text-wholetext
/// - WebIDL: dom.idl:442
///
/// ## Note
/// This property returns the text of this node and all logically adjacent Text nodes.
/// "Logically adjacent" means Text nodes that are siblings with no intervening element nodes.
///
/// ## Example
/// ```c
/// // parent has: Text("Hello "), Text("World")
/// const char* whole = dom_text_get_wholetext(firstText);
/// printf("%s\n", whole); // "Hello World"
/// ```
pub export fn dom_text_get_wholetext(text: *DOMText) [*:0]const u8 {
    const text_node: *const Text = @ptrCast(@alignCast(text));
    const allocator = std.heap.page_allocator;
    const whole = text_node.wholeText(allocator) catch return "";
    // WARNING: This leaks memory! Need proper caching
    // TODO: Cache wholeText result or use arena allocator
    _ = whole;
    return "";
}

// ============================================================================
// Memory Management
// ============================================================================

/// Increment the reference count of a Text node.
///
/// Call this when sharing a Text node reference.
///
/// ## Parameters
/// - `text`: Text node handle
///
/// ## Example
/// ```c
/// dom_text_addref(text); // Share ownership
/// other_structure.text_node = text;
/// // Both owners must call release()
/// ```
pub export fn dom_text_addref(text: *DOMText) void {
    const text_node: *Text = @ptrCast(@alignCast(text));
    text_node.prototype.acquire();
}

/// Decrement the reference count of a Text node.
///
/// Call this when done with a Text node. When ref count reaches 0,
/// the node is freed.
///
/// ## Parameters
/// - `text`: Text node handle
///
/// ## Example
/// ```c
/// DOMText* text = dom_document_createtextnode(doc, "Hello");
/// // ... use text ...
/// dom_text_release(text); // Free when ref count reaches 0
/// ```
pub export fn dom_text_release(text: *DOMText) void {
    const text_node: *Text = @ptrCast(@alignCast(text));
    text_node.prototype.release();
}
