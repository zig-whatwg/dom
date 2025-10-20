//! NodeFilter Interface (WHATWG DOM)
//!
//! This module implements the NodeFilter callback interface as specified by the WHATWG DOM Standard.
//! NodeFilter provides filtering capabilities for NodeIterator and TreeWalker, allowing selective
//! traversal of the DOM tree based on node type and custom accept logic.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **NodeFilter**: https://dom.spec.whatwg.org/#callbackdef-nodefilter
//! - **Traversal**: https://dom.spec.whatwg.org/#traversal
//!
//! ## MDN Documentation
//!
//! - NodeFilter: https://developer.mozilla.org/en-US/docs/Web/API/NodeFilter
//! - NodeFilter.acceptNode(): https://developer.mozilla.org/en-US/docs/Web/API/NodeFilter/acceptNode
//!
//! ## Core Features
//!
//! ### Node Filtering
//! ```zig
//! // Custom filter function
//! fn myFilter(node: *Node, context: *anyopaque) FilterResult {
//!     _ = context;
//!     if (node.node_type == .element) {
//!         const elem: *Element = @fieldParentPtr("prototype", node);
//!         if (std.mem.eql(u8, elem.tag_name, "special")) {
//!             return .accept;
//!         }
//!     }
//!     return .skip;
//! }
//!
//! // Use with NodeIterator
//! const iterator = try doc.createNodeIterator(
//!     root,
//!     NodeFilter.SHOW_ELEMENT,
//!     .{ .callback = myFilter, .context = null }
//! );
//! ```
//!
//! ## Architecture
//!
//! NodeFilter is implemented as:
//! - Constants for `whatToShow` flags (bitfield for node types)
//! - Constants for `acceptNode()` results (accept, reject, skip)
//! - Callback function signature for custom filtering
//! - Helper functions for checking node visibility
//!
//! ## Spec Compliance
//!
//! This implementation follows WHATWG DOM §6 exactly:
//! - ✅ All `SHOW_*` constants (element, text, comment, etc.)
//! - ✅ All `FILTER_*` constants (accept, reject, skip)
//! - ✅ acceptNode() callback interface
//! - ✅ whatToShow bitfield matching
//!
//! ## JavaScript Bindings
//!
//! NodeFilter is a callback interface that provides filtering capabilities for tree traversal.
//!
//! ### Interface (Callback Object)
//! NodeFilter is typically implemented as an object with an `acceptNode` method:
//! ```javascript
//! // Per WebIDL: callback interface NodeFilter { unsigned short acceptNode(Node node); };
//! const myFilter = {
//!   acceptNode: function(node) {
//!     // Return NodeFilter.FILTER_ACCEPT, FILTER_REJECT, or FILTER_SKIP
//!     if (node.nodeName === 'ITEM') {
//!       return NodeFilter.FILTER_ACCEPT;
//!     }
//!     return NodeFilter.FILTER_SKIP;
//!   }
//! };
//!
//! // Or as a plain function (modern JavaScript)
//! function myFilter(node) {
//!   return node.nodeName === 'ITEM' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
//! }
//! ```
//!
//! ### Static Constants (Filter Results)
//! ```javascript
//! // Per WebIDL: const unsigned short FILTER_ACCEPT = 1;
//! NodeFilter.FILTER_ACCEPT = 1;
//!
//! // Per WebIDL: const unsigned short FILTER_REJECT = 2;
//! NodeFilter.FILTER_REJECT = 2;
//!
//! // Per WebIDL: const unsigned short FILTER_SKIP = 3;
//! NodeFilter.FILTER_SKIP = 3;
//! ```
//!
//! ### Static Constants (whatToShow Bitfield)
//! ```javascript
//! // Per WebIDL: const unsigned long SHOW_ALL = 0xFFFFFFFF;
//! NodeFilter.SHOW_ALL = 0xFFFFFFFF;
//!
//! // Per WebIDL: const unsigned long SHOW_ELEMENT = 0x1;
//! NodeFilter.SHOW_ELEMENT = 0x1;
//!
//! // Per WebIDL: const unsigned long SHOW_ATTRIBUTE = 0x2;
//! NodeFilter.SHOW_ATTRIBUTE = 0x2; // Legacy, not used in modern DOM
//!
//! // Per WebIDL: const unsigned long SHOW_TEXT = 0x4;
//! NodeFilter.SHOW_TEXT = 0x4;
//!
//! // Per WebIDL: const unsigned long SHOW_CDATA_SECTION = 0x8;
//! NodeFilter.SHOW_CDATA_SECTION = 0x8;
//!
//! // Per WebIDL: const unsigned long SHOW_ENTITY_REFERENCE = 0x10; // legacy
//! NodeFilter.SHOW_ENTITY_REFERENCE = 0x10; // Legacy, deprecated
//!
//! // Per WebIDL: const unsigned long SHOW_ENTITY = 0x20; // legacy
//! NodeFilter.SHOW_ENTITY = 0x20; // Legacy, deprecated
//!
//! // Per WebIDL: const unsigned long SHOW_PROCESSING_INSTRUCTION = 0x40;
//! NodeFilter.SHOW_PROCESSING_INSTRUCTION = 0x40;
//!
//! // Per WebIDL: const unsigned long SHOW_COMMENT = 0x80;
//! NodeFilter.SHOW_COMMENT = 0x80;
//!
//! // Per WebIDL: const unsigned long SHOW_DOCUMENT = 0x100;
//! NodeFilter.SHOW_DOCUMENT = 0x100;
//!
//! // Per WebIDL: const unsigned long SHOW_DOCUMENT_TYPE = 0x200;
//! NodeFilter.SHOW_DOCUMENT_TYPE = 0x200;
//!
//! // Per WebIDL: const unsigned long SHOW_DOCUMENT_FRAGMENT = 0x400;
//! NodeFilter.SHOW_DOCUMENT_FRAGMENT = 0x400;
//!
//! // Per WebIDL: const unsigned long SHOW_NOTATION = 0x800; // legacy
//! NodeFilter.SHOW_NOTATION = 0x800; // Legacy, deprecated
//! ```
//!
//! ### Usage Examples
//! ```javascript
//! // Example 1: Filter by node type (using whatToShow)
//! const iterator = document.createNodeIterator(
//!   root,
//!   NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT, // Only elements and text nodes
//!   null // No custom filter
//! );
//!
//! // Example 2: Custom filter (object with acceptNode method)
//! const walker = document.createTreeWalker(
//!   root,
//!   NodeFilter.SHOW_ELEMENT,
//!   {
//!     acceptNode: function(node) {
//!       // Accept only elements with 'data-item' attribute
//!       if (node.hasAttribute && node.hasAttribute('data-item')) {
//!         return NodeFilter.FILTER_ACCEPT;
//!       }
//!       return NodeFilter.FILTER_SKIP;
//!     }
//!   }
//! );
//!
//! // Example 3: Custom filter (function)
//! const filtered = document.createTreeWalker(
//!   root,
//!   NodeFilter.SHOW_ELEMENT,
//!   function(node) {
//!     // Reject 'container' elements and all their descendants
//!     if (node.nodeName === 'CONTAINER') {
//!       return NodeFilter.FILTER_REJECT;
//!     }
//!     // Accept 'item' elements
//!     if (node.nodeName === 'ITEM') {
//!       return NodeFilter.FILTER_ACCEPT;
//!     }
//!     // Skip other elements but continue to their children
//!     return NodeFilter.FILTER_SKIP;
//!   }
//! );
//!
//! // Example 4: Combining whatToShow with custom filter
//! const combined = document.createNodeIterator(
//!   root,
//!   NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_COMMENT, // Elements and comments
//!   {
//!     acceptNode: function(node) {
//!       if (node.nodeType === Node.ELEMENT_NODE) {
//!         // Accept elements with specific class
//!         return node.classList.contains('visible') ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
//!       }
//!       if (node.nodeType === Node.COMMENT_NODE) {
//!         // Accept comments containing 'TODO'
//!         return node.textContent.includes('TODO') ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
//!       }
//!       return NodeFilter.FILTER_SKIP;
//!     }
//!   }
//! );
//!
//! // Example 5: All nodes (no filtering)
//! const allNodes = document.createNodeIterator(
//!   root,
//!   NodeFilter.SHOW_ALL, // All node types
//!   null // No custom filter
//! );
//! ```
//!
//! ### Filter Return Values
//! - **FILTER_ACCEPT (1)**: Include the node in results
//! - **FILTER_REJECT (2)**: Skip node AND all descendants (TreeWalker only; NodeIterator treats as FILTER_SKIP)
//! - **FILTER_SKIP (3)**: Skip node but continue to descendants
//!
//! ### Common Patterns
//! ```javascript
//! // Pattern 1: Filter by element name
//! const byName = {
//!   acceptNode: (node) => node.nodeName === 'ITEM' ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP
//! };
//!
//! // Pattern 2: Filter by attribute
//! const byAttr = {
//!   acceptNode: (node) => node.hasAttribute && node.hasAttribute('data-id') ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP
//! };
//!
//! // Pattern 3: Filter by text content
//! const byText = {
//!   acceptNode: (node) => {
//!     if (node.nodeType === Node.TEXT_NODE) {
//!       return node.textContent.trim().length > 0 ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_SKIP;
//!     }
//!     return NodeFilter.FILTER_SKIP;
//!   }
//! };
//!
//! // Pattern 4: Reject entire subtrees
//! const rejectSubtrees = {
//!   acceptNode: (node) => {
//!     if (node.classList && node.classList.contains('hidden')) {
//!       return NodeFilter.FILTER_REJECT; // Skip this node AND all children
//!     }
//!     return NodeFilter.FILTER_ACCEPT;
//!   }
//! };
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// Filter result from acceptNode callback.
///
/// ## WebIDL
/// ```webidl
/// const unsigned short FILTER_ACCEPT = 1;
/// const unsigned short FILTER_REJECT = 2;
/// const unsigned short FILTER_SKIP = 3;
/// ```
///
/// ## Spec References
/// - Constants: https://dom.spec.whatwg.org/#callbackdef-nodefilter
/// - WebIDL: dom.idl:566-568
pub const FilterResult = enum(u16) {
    /// Accept the node. Iterator/TreeWalker includes it in results.
    accept = 1,

    /// Reject the node and its descendants. Iterator/TreeWalker skips entire subtree.
    /// Only meaningful for TreeWalker (NodeIterator treats reject same as skip).
    reject = 2,

    /// Skip the node but continue to descendants.
    skip = 3,
};

/// Callback function signature for custom node filtering.
///
/// ## WebIDL
/// ```webidl
/// callback interface NodeFilter {
///   unsigned short acceptNode(Node node);
/// };
/// ```
///
/// ## Parameters
/// - `node`: Node to filter
/// - `context`: Optional user context pointer
///
/// ## Returns
/// FilterResult indicating whether to accept, reject, or skip the node
///
/// ## Spec References
/// - Callback: https://dom.spec.whatwg.org/#callbackdef-nodefilter
/// - WebIDL: dom.idl:585
pub const FilterCallback = *const fn (node: *Node, context: ?*anyopaque) FilterResult;

/// NodeFilter implementation with callback and context.
///
/// ## Note
/// This struct wraps a callback function and optional context pointer.
/// It's used by NodeIterator and TreeWalker to filter nodes during traversal.
pub const NodeFilter = struct {
    /// Callback function for filtering nodes
    callback: FilterCallback,

    /// Optional user context passed to callback
    context: ?*anyopaque,

    /// Invokes the filter callback on a node.
    ///
    /// ## Parameters
    /// - `node`: Node to filter
    ///
    /// ## Returns
    /// FilterResult from the callback
    pub fn acceptNode(self: *const NodeFilter, node: *Node) FilterResult {
        return self.callback(node, self.context);
    }

    // ========================================================================
    // whatToShow Constants (Bitfield)
    // ========================================================================

    /// Show all nodes (all bits set).
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_ALL = 0xFFFFFFFF;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_all
    /// - WebIDL: dom.idl:571
    pub const SHOW_ALL: u32 = 0xFFFFFFFF;

    /// Show Element nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_ELEMENT = 0x1;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_element
    /// - WebIDL: dom.idl:572
    pub const SHOW_ELEMENT: u32 = 0x1;

    /// Show Attr nodes (legacy, not used in modern DOM).
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_ATTRIBUTE = 0x2;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_attribute
    /// - WebIDL: dom.idl:573
    pub const SHOW_ATTRIBUTE: u32 = 0x2;

    /// Show Text nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_TEXT = 0x4;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_text
    /// - WebIDL: dom.idl:574
    pub const SHOW_TEXT: u32 = 0x4;

    /// Show CDATASection nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_CDATA_SECTION = 0x8;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_cdata_section
    /// - WebIDL: dom.idl:575
    pub const SHOW_CDATA_SECTION: u32 = 0x8;

    /// Show EntityReference nodes (legacy, deprecated).
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_ENTITY_REFERENCE = 0x10; // legacy
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_entity_reference
    /// - WebIDL: dom.idl:576
    pub const SHOW_ENTITY_REFERENCE: u32 = 0x10;

    /// Show Entity nodes (legacy, deprecated).
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_ENTITY = 0x20; // legacy
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_entity
    /// - WebIDL: dom.idl:577
    pub const SHOW_ENTITY: u32 = 0x20;

    /// Show ProcessingInstruction nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_PROCESSING_INSTRUCTION = 0x40;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_processing_instruction
    /// - WebIDL: dom.idl:578
    pub const SHOW_PROCESSING_INSTRUCTION: u32 = 0x40;

    /// Show Comment nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_COMMENT = 0x80;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_comment
    /// - WebIDL: dom.idl:579
    pub const SHOW_COMMENT: u32 = 0x80;

    /// Show Document nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_DOCUMENT = 0x100;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_document
    /// - WebIDL: dom.idl:580
    pub const SHOW_DOCUMENT: u32 = 0x100;

    /// Show DocumentType nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_DOCUMENT_TYPE = 0x200;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_document_type
    /// - WebIDL: dom.idl:581
    pub const SHOW_DOCUMENT_TYPE: u32 = 0x200;

    /// Show DocumentFragment nodes.
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_DOCUMENT_FRAGMENT = 0x400;
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_document_fragment
    /// - WebIDL: dom.idl:582
    pub const SHOW_DOCUMENT_FRAGMENT: u32 = 0x400;

    /// Show Notation nodes (legacy, deprecated).
    ///
    /// ## WebIDL
    /// ```webidl
    /// const unsigned long SHOW_NOTATION = 0x800; // legacy
    /// ```
    ///
    /// ## Spec References
    /// - Constant: https://dom.spec.whatwg.org/#dom-nodefilter-show_notation
    /// - WebIDL: dom.idl:583
    pub const SHOW_NOTATION: u32 = 0x800;

    // ========================================================================
    // Helper Functions
    // ========================================================================

    /// Checks if a node matches the whatToShow bitfield.
    ///
    /// ## Algorithm
    /// Check if the bit corresponding to the node's type is set in whatToShow.
    ///
    /// ## Parameters
    /// - `node`: Node to check
    /// - `what_to_show`: Bitfield of node types to show
    ///
    /// ## Returns
    /// true if node type matches whatToShow, false otherwise
    ///
    /// ## Example
    /// ```zig
    /// if (NodeFilter.isNodeVisible(node, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT)) {
    ///     // Node is an element or text node
    /// }
    /// ```
    pub fn isNodeVisible(node: *const Node, what_to_show: u32) bool {
        const node_bit: u32 = switch (node.node_type) {
            .element => SHOW_ELEMENT,
            .attribute => SHOW_ATTRIBUTE,
            .text => SHOW_TEXT,
            .cdata_section => SHOW_CDATA_SECTION,
            .processing_instruction => SHOW_PROCESSING_INSTRUCTION,
            .comment => SHOW_COMMENT,
            .document => SHOW_DOCUMENT,
            .document_type => SHOW_DOCUMENT_TYPE,
            .document_fragment => SHOW_DOCUMENT_FRAGMENT,
            .shadow_root => SHOW_DOCUMENT_FRAGMENT, // Shadow roots treated as document fragments
        };

        return (what_to_show & node_bit) != 0;
    }
};
