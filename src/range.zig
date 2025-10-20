//! Range Interface (§5)
//!
//! This module implements the Range and AbstractRange interfaces as specified by the WHATWG
//! DOM Standard. Range represents a mutable sequence of content within the DOM tree, supporting
//! selection, comparison, and content manipulation operations.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§5 Ranges**: https://dom.spec.whatwg.org/#ranges
//! - **§5.1 Interface AbstractRange**: https://dom.spec.whatwg.org/#interface-abstractrange
//! - **§5.2 Interface Range**: https://dom.spec.whatwg.org/#interface-range
//! - **§5.3 Boundary Points**: https://dom.spec.whatwg.org/#concept-range-bp
//!
//! ## MDN Documentation
//!
//! - Range: https://developer.mozilla.org/en-US/docs/Web/API/Range
//! - AbstractRange: https://developer.mozilla.org/en-US/docs/Web/API/AbstractRange
//! - Range.setStart(): https://developer.mozilla.org/en-US/docs/Web/API/Range/setStart
//! - Range.setEnd(): https://developer.mozilla.org/en-US/docs/Web/API/Range/setEnd
//! - Range.collapse(): https://developer.mozilla.org/en-US/docs/Web/API/Range/collapse
//!
//! ## Core Features
//!
//! ### Range Creation
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! // Create collapsed range at document start
//! const range = try doc.createRange();
//! defer range.deinit();
//! ```
//!
//! ### Boundary Management
//! ```zig
//! const elem = try doc.createElement("div");
//! const text = try doc.createTextNode("Hello");
//! _ = try elem.node.appendChild(&text.node);
//!
//! // Set range boundaries
//! try range.setStart(&text.node, 0);    // Start of "Hello"
//! try range.setEnd(&text.node, 5);      // End of "Hello"
//!
//! // Check if collapsed
//! const is_collapsed = range.collapsed(); // false
//! ```
//!
//! ### Position Shortcuts
//! ```zig
//! const parent = try doc.createElement("parent");
//! const child1 = try doc.createElement("child1");
//! const child2 = try doc.createElement("child2");
//! _ = try parent.node.appendChild(&child1.node);
//! _ = try parent.node.appendChild(&child2.node);
//!
//! // Set range before/after nodes
//! try range.setStartBefore(&child1.node);  // Before child1
//! try range.setEndAfter(&child2.node);     // After child2
//! ```
//!
//! ## Range Architecture
//!
//! ### AbstractRange (Base)
//! - **start_container**: Node containing start boundary
//! - **start_offset**: Offset within start container
//! - **end_container**: Node containing end boundary
//! - **end_offset**: Offset within end container
//! - **collapsed()**: True if start and end are equal
//!
//! ### Range (Mutable)
//! - Extends AbstractRange with mutable operations
//! - **allocator**: For content manipulation operations
//! - Validation on boundary changes
//! - Auto-collapse if end becomes before start
//!
//! ## Boundary Points
//!
//! A boundary point is a (node, offset) pair:
//! - **Element/DocumentFragment**: Offset is child index (0-based)
//! - **Text/Comment**: Offset is character position (0-based)
//! - **DocumentType**: Offset is always 0
//!
//! Example:
//! ```zig
//! // <div>He|llo</div>
//! // Boundary point: (text_node, 2) - between "e" and "l"
//!
//! // <div>|<span></span><p></p></div>
//! // Boundary point: (div, 0) - before first child
//!
//! // <div><span></span>|<p></p></div>
//! // Boundary point: (div, 1) - between children
//! ```
//!
//! ## Memory Management
//!
//! Range does NOT own its boundary nodes:
//! ```zig
//! const range = try doc.createRange();
//! defer range.deinit();  // Only frees Range struct, not nodes
//!
//! // Boundary nodes managed by document/tree
//! // Range just references them
//! ```
//!
//! ## Usage Examples
//!
//! ### Selecting Text
//! ```zig
//! const text = try doc.createTextNode("Hello World");
//! const range = try doc.createRange();
//! defer range.deinit();
//!
//! // Select "World" (characters 6-11)
//! try range.setStart(&text.node, 6);
//! try range.setEnd(&text.node, 11);
//! ```
//!
//! ### Selecting Element Contents
//! ```zig
//! const elem = try doc.createElement("div");
//! const child1 = try doc.createElement("span");
//! const child2 = try doc.createElement("p");
//! _ = try elem.node.appendChild(&child1.node);
//! _ = try elem.node.appendChild(&child2.node);
//!
//! const range = try doc.createRange();
//! defer range.deinit();
//!
//! // Select all children of elem
//! try range.selectNodeContents(&elem.node);
//! // Equivalent to:
//! // try range.setStart(&elem.node, 0);
//! // try range.setEnd(&elem.node, 2);
//! ```
//!
//! ### Collapsing Range
//! ```zig
//! const range = try doc.createRange();
//! defer range.deinit();
//!
//! try range.setStart(&node1, 5);
//! try range.setEnd(&node2, 10);
//!
//! // Collapse to start
//! try range.collapse(true);
//! // Now: start=(node1,5) end=(node1,5)
//!
//! // Collapse to end
//! try range.collapse(false);
//! // Now: start=(node2,10) end=(node2,10)
//! ```
//!
//! ## Common Patterns
//!
//! ### Validating Before Operations
//! ```zig
//! fn safeSetStart(range: *Range, node: *Node, offset: u32) !void {
//!     // Validation happens automatically in setStart
//!     try range.setStart(node, offset);
//! }
//! ```
//!
//! ### Creating Selection at Position
//! ```zig
//! fn createSelectionAt(doc: *Document, node: *Node, offset: u32) !*Range {
//!     const range = try doc.createRange();
//!     errdefer range.deinit();
//!
//!     try range.setStart(node, offset);
//!     try range.collapse(true);  // Collapsed at position
//!     return range;
//! }
//! ```
//!
//! ## Performance Notes
//!
//! Range is NOT performance-critical (typical use: user selection):
//! - Created during user interaction
//! - Modified a few times
//! - Used once for content manipulation
//! - Destroyed
//!
//! **No optimization needed:**
//! - No caching (common ancestor computed on-demand)
//! - No fast paths
//! - Focus on correctness and spec compliance
//!
//! ## Implementation Notes
//!
//! - Follows WHATWG DOM specification exactly (step-by-step algorithms)
//! - Validation during operations, not on storage
//! - No normalization (stores exactly what's provided)
//! - Auto-collapse if end becomes before start
//! - DocumentType nodes not allowed as boundary containers
//! - Offset validation against node length
//! - Error types match DOMException names from spec
//!
//! ## Design Decisions
//!
//! Based on browser research (Chrome/Blink, Firefox/Gecko, WebKit):
//! 1. **Simple structure** (follow WebKit pattern, no caching)
//! 2. **Validate on set** (not on storage like Gecko)
//! 3. **No fast paths** (correctness over performance)
//! 4. **Compute on demand** (commonAncestorContainer not cached)
//!
//! See `summaries/plans/range_api_browser_research.md` for details.
//!
//! ## JavaScript Bindings
//!
//! Range is used for text selection and DOM manipulation.
//!
//! ### Constructor
//! ```javascript
//! // Per WebIDL: constructor();
//! function Range() {
//!   this._ptr = zig.range_init();
//! }
//! ```
//!
//! ### Instance Properties (from AbstractRange)
//! ```javascript
//! // startContainer (readonly) - Per WebIDL: readonly attribute Node startContainer;
//! Object.defineProperty(Range.prototype, 'startContainer', {
//!   get: function() {
//!     const ptr = zig.range_get_startContainer(this._ptr);
//!     return wrapNode(ptr);
//!   }
//! });
//!
//! // startOffset (readonly) - Per WebIDL: readonly attribute unsigned long startOffset;
//! Object.defineProperty(Range.prototype, 'startOffset', {
//!   get: function() { return zig.range_get_startOffset(this._ptr); }
//! });
//!
//! // endContainer (readonly) - Per WebIDL: readonly attribute Node endContainer;
//! Object.defineProperty(Range.prototype, 'endContainer', {
//!   get: function() {
//!     const ptr = zig.range_get_endContainer(this._ptr);
//!     return wrapNode(ptr);
//!   }
//! });
//!
//! // endOffset (readonly) - Per WebIDL: readonly attribute unsigned long endOffset;
//! Object.defineProperty(Range.prototype, 'endOffset', {
//!   get: function() { return zig.range_get_endOffset(this._ptr); }
//! });
//!
//! // collapsed (readonly) - Per WebIDL: readonly attribute boolean collapsed;
//! Object.defineProperty(Range.prototype, 'collapsed', {
//!   get: function() { return zig.range_get_collapsed(this._ptr); }
//! });
//!
//! // commonAncestorContainer (readonly) - Per WebIDL: readonly attribute Node commonAncestorContainer;
//! Object.defineProperty(Range.prototype, 'commonAncestorContainer', {
//!   get: function() {
//!     const ptr = zig.range_get_commonAncestorContainer(this._ptr);
//!     return wrapNode(ptr);
//!   }
//! });
//! ```
//!
//! ### Instance Methods - Boundary Setting
//! ```javascript
//! // Per WebIDL: undefined setStart(Node node, unsigned long offset);
//! Range.prototype.setStart = function(node, offset) {
//!   zig.range_setStart(this._ptr, node._ptr, offset);
//! };
//!
//! // Per WebIDL: undefined setEnd(Node node, unsigned long offset);
//! Range.prototype.setEnd = function(node, offset) {
//!   zig.range_setEnd(this._ptr, node._ptr, offset);
//! };
//!
//! // Per WebIDL: undefined setStartBefore(Node node);
//! Range.prototype.setStartBefore = function(node) {
//!   zig.range_setStartBefore(this._ptr, node._ptr);
//! };
//!
//! // Per WebIDL: undefined setStartAfter(Node node);
//! Range.prototype.setStartAfter = function(node) {
//!   zig.range_setStartAfter(this._ptr, node._ptr);
//! };
//!
//! // Per WebIDL: undefined setEndBefore(Node node);
//! Range.prototype.setEndBefore = function(node) {
//!   zig.range_setEndBefore(this._ptr, node._ptr);
//! };
//!
//! // Per WebIDL: undefined setEndAfter(Node node);
//! Range.prototype.setEndAfter = function(node) {
//!   zig.range_setEndAfter(this._ptr, node._ptr);
//! };
//!
//! // Per WebIDL: undefined collapse(optional boolean toStart = false);
//! Range.prototype.collapse = function(toStart) {
//!   zig.range_collapse(this._ptr, toStart !== undefined ? toStart : false);
//! };
//!
//! // Per WebIDL: undefined selectNode(Node node);
//! Range.prototype.selectNode = function(node) {
//!   zig.range_selectNode(this._ptr, node._ptr);
//! };
//!
//! // Per WebIDL: undefined selectNodeContents(Node node);
//! Range.prototype.selectNodeContents = function(node) {
//!   zig.range_selectNodeContents(this._ptr, node._ptr);
//! };
//! ```
//!
//! ### Instance Methods - Comparison
//! ```javascript
//! // Per WebIDL: short compareBoundaryPoints(unsigned short how, Range sourceRange);
//! Range.prototype.compareBoundaryPoints = function(how, sourceRange) {
//!   return zig.range_compareBoundaryPoints(this._ptr, how, sourceRange._ptr);
//! };
//!
//! // Per WebIDL: boolean isPointInRange(Node node, unsigned long offset);
//! Range.prototype.isPointInRange = function(node, offset) {
//!   return zig.range_isPointInRange(this._ptr, node._ptr, offset);
//! };
//!
//! // Per WebIDL: short comparePoint(Node node, unsigned long offset);
//! Range.prototype.comparePoint = function(node, offset) {
//!   return zig.range_comparePoint(this._ptr, node._ptr, offset);
//! };
//!
//! // Per WebIDL: boolean intersectsNode(Node node);
//! Range.prototype.intersectsNode = function(node) {
//!   return zig.range_intersectsNode(this._ptr, node._ptr);
//! };
//! ```
//!
//! ### Instance Methods - Mutation ([CEReactions])
//! ```javascript
//! // Per WebIDL: [CEReactions] undefined deleteContents();
//! Range.prototype.deleteContents = function() {
//!   zig.range_deleteContents(this._ptr); // Triggers CEReactions
//! };
//!
//! // Per WebIDL: [CEReactions, NewObject] DocumentFragment extractContents();
//! Range.prototype.extractContents = function() {
//!   const ptr = zig.range_extractContents(this._ptr); // Returns new DocumentFragment
//!   return wrapDocumentFragment(ptr);
//! };
//!
//! // Per WebIDL: [CEReactions, NewObject] DocumentFragment cloneContents();
//! Range.prototype.cloneContents = function() {
//!   const ptr = zig.range_cloneContents(this._ptr); // Returns new DocumentFragment
//!   return wrapDocumentFragment(ptr);
//! };
//!
//! // Per WebIDL: [CEReactions] undefined insertNode(Node node);
//! Range.prototype.insertNode = function(node) {
//!   zig.range_insertNode(this._ptr, node._ptr); // Triggers CEReactions
//! };
//!
//! // Per WebIDL: [CEReactions] undefined surroundContents(Node newParent);
//! Range.prototype.surroundContents = function(newParent) {
//!   zig.range_surroundContents(this._ptr, newParent._ptr); // Triggers CEReactions
//! };
//! ```
//!
//! ### Instance Methods - Cloning and Legacy
//! ```javascript
//! // Per WebIDL: [NewObject] Range cloneRange();
//! Range.prototype.cloneRange = function() {
//!   const ptr = zig.range_cloneRange(this._ptr); // Returns new Range
//!   return wrapRange(ptr);
//! };
//!
//! // Per WebIDL: undefined detach();
//! Range.prototype.detach = function() {
//!   // No-op (legacy method, does nothing per spec)
//! };
//!
//! // Per WebIDL: stringifier;
//! Range.prototype.toString = function() {
//!   return zig.range_toString(this._ptr);
//! };
//! ```
//!
//! ### Constants
//! ```javascript
//! Range.START_TO_START = 0;
//! Range.START_TO_END = 1;
//! Range.END_TO_END = 2;
//! Range.END_TO_START = 3;
//! ```
//!
//! ### Usage Examples
//! ```javascript
//! // Create range
//! const range = new Range();
//!
//! // Select text content
//! const textNode = document.createTextNode('Hello World');
//! document.body.appendChild(textNode);
//! range.setStart(textNode, 0);
//! range.setEnd(textNode, 5); // Selects 'Hello'
//!
//! // Get selected text
//! const text = range.toString(); // 'Hello'
//!
//! // Check properties
//! console.log(range.startContainer); // Text node
//! console.log(range.startOffset);    // 0
//! console.log(range.collapsed);      // false
//!
//! // Extract content (removes from DOM)
//! const fragment = range.extractContents();
//! document.body.appendChild(fragment); // Re-insert elsewhere
//!
//! // Clone content (keeps original)
//! const clone = range.cloneContents();
//!
//! // Select entire node
//! const element = document.createElement('div');
//! range.selectNode(element);
//!
//! // Collapse to start
//! range.collapse(true); // Collapsed at start
//! console.log(range.collapsed); // true
//!
//! // Compare boundary points
//! const range2 = new Range();
//! range2.selectNodeContents(document.body);
//! const comparison = range.compareBoundaryPoints(Range.START_TO_START, range2);
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;
const Document = @import("document.zig").Document;
const DocumentFragment = @import("document_fragment.zig").DocumentFragment;
const DOMError = @import("validation.zig").DOMError;

/// Range error types per WHATWG DOM specification.
///
/// These map to DOMException names from the spec.
pub const RangeError = error{
    /// Node is DocumentType (not allowed in ranges)
    InvalidNodeTypeError,

    /// Offset exceeds node length
    IndexSizeError,

    /// Root containers don't match
    WrongDocumentError,

    /// Invalid state for operation
    InvalidStateError,

    /// Hierarchy error
    HierarchyRequestError,

    /// Index out of bounds (for character data operations)
    IndexOutOfBounds,
} || Allocator.Error || DOMError || anyerror;

/// Comparison types for boundary points per WHATWG DOM §5.3.
///
/// ## WebIDL
/// ```webidl
/// const unsigned short START_TO_START = 0;
/// const unsigned short START_TO_END = 1;
/// const unsigned short END_TO_END = 2;
/// const unsigned short END_TO_START = 3;
/// ```
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#dom-range-start_to_start
pub const BoundaryPointComparison = enum(u16) {
    /// Compare this range's start point to source range's start point
    start_to_start = 0,

    /// Compare this range's start point to source range's end point
    start_to_end = 1,

    /// Compare this range's end point to source range's end point
    end_to_end = 2,

    /// Compare this range's end point to source range's start point
    end_to_start = 3,
};

/// AbstractRange represents a sequence of content within the DOM.
///
/// Base interface for Range and StaticRange per WHATWG DOM §5.1.
/// AbstractRange is immutable - use Range for mutable operations.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=Window]
/// interface AbstractRange {
///   readonly attribute Node startContainer;
///   readonly attribute unsigned long startOffset;
///   readonly attribute Node endContainer;
///   readonly attribute unsigned long endOffset;
///   readonly attribute boolean collapsed;
/// };
/// ```
///
/// ## Spec Reference
/// - Interface: https://dom.spec.whatwg.org/#interface-abstractrange
/// - WebIDL: dom.idl lines 475-481
///
/// ## Memory Layout
/// Size: 32 bytes (4 pointers/u32s on 64-bit systems)
pub const AbstractRange = struct {
    /// Start boundary container node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Node startContainer;
    /// ```
    start_container: *Node,

    /// Offset within start container (0-based).
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute unsigned long startOffset;
    /// ```
    start_offset: u32,

    /// End boundary container node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Node endContainer;
    /// ```
    end_container: *Node,

    /// Offset within end container (0-based).
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute unsigned long endOffset;
    /// ```
    end_offset: u32,

    /// Returns true if start and end boundary points are equal.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute boolean collapsed;
    /// ```
    ///
    /// ## Algorithm
    /// Range is collapsed if start container equals end container AND
    /// start offset equals end offset.
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-collapsed
    pub fn collapsed(self: *const AbstractRange) bool {
        return self.start_container == self.end_container and
            self.start_offset == self.end_offset;
    }
};

/// Range represents a mutable sequence of content within the DOM.
///
/// Provides methods for manipulating boundaries, comparing ranges,
/// and extracting/deleting content.
///
/// ## WebIDL
/// ```webidl
/// [Exposed=Window]
/// interface Range : AbstractRange {
///   constructor();
///
///   readonly attribute Node commonAncestorContainer;
///
///   undefined setStart(Node node, unsigned long offset);
///   undefined setEnd(Node node, unsigned long offset);
///   undefined setStartBefore(Node node);
///   undefined setStartAfter(Node node);
///   undefined setEndBefore(Node node);
///   undefined setEndAfter(Node node);
///   undefined collapse(optional boolean toStart = false);
///   undefined selectNode(Node node);
///   undefined selectNodeContents(Node node);
///
///   const unsigned short START_TO_START = 0;
///   const unsigned short START_TO_END = 1;
///   const unsigned short END_TO_END = 2;
///   const unsigned short END_TO_START = 3;
///   short compareBoundaryPoints(unsigned short how, Range sourceRange);
///
///   [CEReactions] undefined deleteContents();
///   [CEReactions, NewObject] DocumentFragment extractContents();
///   [CEReactions, NewObject] DocumentFragment cloneContents();
///   [CEReactions] undefined insertNode(Node node);
///   [CEReactions] undefined surroundContents(Node newParent);
///
///   [NewObject] Range cloneRange();
///   undefined detach();
///
///   boolean isPointInRange(Node node, unsigned long offset);
///   short comparePoint(Node node, unsigned long offset);
///
///   boolean intersectsNode(Node node);
///
///   stringifier;
/// };
/// ```
///
/// ## Spec Reference
/// - Interface: https://dom.spec.whatwg.org/#interface-range
/// - WebIDL: dom.idl lines 496-532
///
/// ## Memory Layout
/// Size: 40 bytes (AbstractRange fields + allocator)
pub const Range = struct {
    /// Start boundary container node (from AbstractRange).
    start_container: *Node,

    /// Offset within start container (from AbstractRange).
    start_offset: u32,

    /// End boundary container node (from AbstractRange).
    end_container: *Node,

    /// Offset within end container (from AbstractRange).
    end_offset: u32,

    /// Allocator for content manipulation.
    allocator: Allocator,

    /// Creates a new collapsed range at document start.
    ///
    /// ## WebIDL
    /// ```webidl
    /// constructor();
    /// ```
    ///
    /// ## Algorithm
    /// Per WHATWG DOM §5.2:
    /// 1. Set start and end to (document, 0)
    /// 2. Range is collapsed at document start
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-range
    ///
    /// ## Usage
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const range = try Range.init(allocator, &doc.node);
    /// defer range.deinit();
    ///
    /// // Range is collapsed at document start
    /// try std.testing.expect(range.collapsed());
    /// ```
    pub fn init(allocator: Allocator, doc: *Document) !*Range {
        const self = try allocator.create(Range);
        self.* = .{
            .start_container = &doc.prototype,
            .start_offset = 0,
            .end_container = &doc.prototype,
            .end_offset = 0,
            .allocator = allocator,
        };
        return self;
    }

    /// Destroys the range, freeing its memory.
    ///
    /// Note: Does NOT free boundary nodes (they are managed by document/tree).
    ///
    /// ## Usage
    /// ```zig
    /// const range = try Range.init(allocator, &doc.node);
    /// defer range.deinit();
    /// ```
    pub fn deinit(self: *Range) void {
        self.allocator.destroy(self);
    }

    /// Returns true if start and end boundary points are equal.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute boolean collapsed;
    /// ```
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-collapsed
    pub fn collapsed(self: *const Range) bool {
        return self.start_container == self.end_container and
            self.start_offset == self.end_offset;
    }

    /// Sets the start boundary point.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined setStart(Node node, unsigned long offset);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// 1. If node is a doctype, throw InvalidNodeTypeError
    /// 2. If offset > node's length, throw IndexSizeError
    /// 3. Let bp be boundary point (node, offset)
    /// 4. Set start to bp
    /// 5. If end < start, set end = start
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-setstart
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node is DocumentType
    /// - `IndexSizeError`: offset > node's length
    ///
    /// ## Usage
    /// ```zig
    /// const text = try doc.createTextNode("Hello");
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// // Set start at position 2 in text ("He|llo")
    /// try range.setStart(&text.node, 2);
    /// ```
    pub fn setStart(self: *Range, node: *Node, offset: u32) RangeError!void {
        // Step 1: Validate node type
        if (node.node_type == .document_type) {
            return error.InvalidNodeTypeError;
        }

        // Step 2: Validate offset
        const length = nodeLength(node);
        if (offset > length) {
            return error.IndexSizeError;
        }

        // Step 3-4: Set start boundary
        self.start_container = node;
        self.start_offset = offset;

        // Step 5: If end is now before start, collapse to start
        const bp_start = BoundaryPoint{ .container = self.start_container, .offset = self.start_offset };
        const bp_end = BoundaryPoint{ .container = self.end_container, .offset = self.end_offset };

        if (compareBoundaryPointsImpl(bp_end, bp_start) == .before) {
            self.end_container = node;
            self.end_offset = offset;
        }
    }

    /// Sets the end boundary point.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined setEnd(Node node, unsigned long offset);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// 1. If node is a doctype, throw InvalidNodeTypeError
    /// 2. If offset > node's length, throw IndexSizeError
    /// 3. Let bp be boundary point (node, offset)
    /// 4. Set end to bp
    /// 5. If start > end, set start = end
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-setend
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node is DocumentType
    /// - `IndexSizeError`: offset > node's length
    ///
    /// ## Usage
    /// ```zig
    /// const text = try doc.createTextNode("Hello");
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// try range.setStart(&text.node, 0);
    /// try range.setEnd(&text.node, 5);  // Select all of "Hello"
    /// ```
    pub fn setEnd(self: *Range, node: *Node, offset: u32) RangeError!void {
        // Step 1: Validate node type
        if (node.node_type == .document_type) {
            return error.InvalidNodeTypeError;
        }

        // Step 2: Validate offset
        const length = nodeLength(node);
        if (offset > length) {
            return error.IndexSizeError;
        }

        // Step 3-4: Set end boundary
        self.end_container = node;
        self.end_offset = offset;

        // Step 5: If start is now after end, collapse to end
        const bp_start = BoundaryPoint{ .container = self.start_container, .offset = self.start_offset };
        const bp_end = BoundaryPoint{ .container = self.end_container, .offset = self.end_offset };

        if (compareBoundaryPointsImpl(bp_start, bp_end) == .after) {
            self.start_container = node;
            self.start_offset = offset;
        }
    }

    /// Collapses the range to one of its boundary points.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined collapse(optional boolean toStart = false);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// If toStart is true:
    ///   Set end to start
    /// Otherwise:
    ///   Set start to end
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-collapse
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// try range.setStart(&node1, 5);
    /// try range.setEnd(&node2, 10);
    ///
    /// // Collapse to start (node1, 5)
    /// try range.collapse(true);
    ///
    /// // Collapse to end (node2, 10)
    /// try range.collapse(false);
    /// ```
    pub fn collapse(self: *Range, toStart: bool) void {
        if (toStart) {
            // Collapse to start
            self.end_container = self.start_container;
            self.end_offset = self.start_offset;
        } else {
            // Collapse to end
            self.start_container = self.end_container;
            self.start_offset = self.end_offset;
        }
    }

    /// Selects the contents of a node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined selectNodeContents(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// 1. If node is a doctype, throw InvalidNodeTypeError
    /// 2. Let length be node's length
    /// 3. Set start to (node, 0)
    /// 4. Set end to (node, length)
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-selectnodecontents
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node is DocumentType
    ///
    /// ## Usage
    /// ```zig
    /// const elem = try doc.createElement("div");
    /// const child1 = try doc.createElement("span");
    /// const child2 = try doc.createElement("p");
    /// _ = try elem.node.appendChild(&child1.node);
    /// _ = try elem.node.appendChild(&child2.node);
    ///
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// // Select all children of elem
    /// try range.selectNodeContents(&elem.node);
    /// // Range: (elem, 0) to (elem, 2)
    /// ```
    pub fn selectNodeContents(self: *Range, node: *Node) RangeError!void {
        // Step 1: Validate node type
        if (node.node_type == .document_type) {
            return error.InvalidNodeTypeError;
        }

        // Step 2: Get node length
        const length = nodeLength(node);

        // Steps 3-4: Set boundaries
        self.start_container = node;
        self.start_offset = 0;
        self.end_container = node;
        self.end_offset = length;
    }

    /// Sets start boundary to just before a node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined setStartBefore(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// 1. Let parent be node's parent
    /// 2. If parent is null, throw InvalidNodeTypeError
    /// 3. Set start to (parent, node's index)
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-setstartbefore
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node has no parent
    ///
    /// ## Usage
    /// ```zig
    /// const parent = try doc.createElement("div");
    /// const child = try doc.createElement("span");
    /// _ = try parent.node.appendChild(&child.node);
    ///
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// // Set start before child
    /// try range.setStartBefore(&child.node);
    /// // Range start: (parent, 0)
    /// ```
    pub fn setStartBefore(self: *Range, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeTypeError;
        const offset = nodeIndex(node) catch return error.InvalidNodeTypeError;
        try self.setStart(parent, offset);
    }

    /// Sets start boundary to just after a node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined setStartAfter(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// 1. Let parent be node's parent
    /// 2. If parent is null, throw InvalidNodeTypeError
    /// 3. Set start to (parent, node's index + 1)
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-setstartafter
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node has no parent
    ///
    /// ## Usage
    /// ```zig
    /// const parent = try doc.createElement("div");
    /// const child = try doc.createElement("span");
    /// _ = try parent.node.appendChild(&child.node);
    ///
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// // Set start after child
    /// try range.setStartAfter(&child.node);
    /// // Range start: (parent, 1)
    /// ```
    pub fn setStartAfter(self: *Range, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeTypeError;
        const offset = nodeIndex(node) catch return error.InvalidNodeTypeError;
        try self.setStart(parent, offset + 1);
    }

    /// Sets end boundary to just before a node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined setEndBefore(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// 1. Let parent be node's parent
    /// 2. If parent is null, throw InvalidNodeTypeError
    /// 3. Set end to (parent, node's index)
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-setendbefore
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node has no parent
    pub fn setEndBefore(self: *Range, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeTypeError;
        const offset = nodeIndex(node) catch return error.InvalidNodeTypeError;
        try self.setEnd(parent, offset);
    }

    /// Sets end boundary to just after a node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined setEndAfter(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// 1. Let parent be node's parent
    /// 2. If parent is null, throw InvalidNodeTypeError
    /// 3. Set end to (parent, node's index + 1)
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-setendafter
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node has no parent
    pub fn setEndAfter(self: *Range, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeTypeError;
        const offset = nodeIndex(node) catch return error.InvalidNodeTypeError;
        try self.setEnd(parent, offset + 1);
    }

    /// Selects a node and its contents.
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined selectNode(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.2)
    /// 1. Let parent be node's parent
    /// 2. If parent is null, throw InvalidNodeTypeError
    /// 3. Let index be node's index
    /// 4. Set start to (parent, index)
    /// 5. Set end to (parent, index + 1)
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-selectnode
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node has no parent
    ///
    /// ## Usage
    /// ```zig
    /// const parent = try doc.createElement("div");
    /// const child = try doc.createElement("span");
    /// _ = try parent.prototype.appendChild(&child.prototype);
    ///
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// // Select the child node itself
    /// try range.selectNode(&child.prototype);
    /// // Range: (parent, 0) to (parent, 1)
    /// ```
    pub fn selectNode(self: *Range, node: *Node) RangeError!void {
        const parent = node.parent_node orelse return error.InvalidNodeTypeError;
        const index = try nodeIndex(node);
        self.start_container = parent;
        self.start_offset = index;
        self.end_container = parent;
        self.end_offset = index + 1;
    }

    /// Returns the deepest node that contains both boundary points.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Node commonAncestorContainer;
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.4)
    /// Find the lowest common ancestor of start and end containers.
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-commonancestorcontainer
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// try range.setStart(&elem1.prototype, 0);
    /// try range.setEnd(&elem2.prototype, 0);
    ///
    /// const ancestor = range.commonAncestorContainer();
    /// // Returns lowest node that contains both elem1 and elem2
    /// ```
    pub fn commonAncestorContainer(self: *const Range) *Node {
        return findCommonAncestor(self.start_container, self.end_container);
    }

    /// Compares boundary points between two ranges.
    ///
    /// ## WebIDL
    /// ```webidl
    /// short compareBoundaryPoints(unsigned short how, Range sourceRange);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.3)
    /// Compare boundary points according to the 'how' parameter.
    ///
    /// ## Parameters
    /// - `how`: Comparison type (START_TO_START, START_TO_END, etc.)
    /// - `source`: Source range to compare against
    ///
    /// ## Returns
    /// - -1 if this point is before source point
    /// - 0 if points are equal
    /// - 1 if this point is after source point
    ///
    /// ## Errors
    /// - `WrongDocumentError`: Ranges from different documents
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-compareboundarypoints
    ///
    /// ## Usage
    /// ```zig
    /// const range1 = try doc.createRange();
    /// defer range1.deinit();
    /// const range2 = try doc.createRange();
    /// defer range2.deinit();
    ///
    /// try range1.setStart(&text.prototype, 0);
    /// try range1.setEnd(&text.prototype, 5);
    /// try range2.setStart(&text.prototype, 3);
    /// try range2.setEnd(&text.prototype, 8);
    ///
    /// // Compare start of range1 to start of range2
    /// const result = try range1.compareBoundaryPoints(.start_to_start, range2);
    /// // result = -1 (range1 start is before range2 start)
    /// ```
    pub fn compareBoundaryPoints(
        self: *const Range,
        how: BoundaryPointComparison,
        source: *const Range,
    ) !i16 {
        // Select boundary points based on comparison type
        const this_point = switch (how) {
            .start_to_start, .end_to_start => BoundaryPoint{
                .container = self.start_container,
                .offset = self.start_offset,
            },
            .start_to_end, .end_to_end => BoundaryPoint{
                .container = self.end_container,
                .offset = self.end_offset,
            },
        };

        const source_point = switch (how) {
            .start_to_start, .start_to_end => BoundaryPoint{
                .container = source.start_container,
                .offset = source.start_offset,
            },
            .end_to_start, .end_to_end => BoundaryPoint{
                .container = source.end_container,
                .offset = source.end_offset,
            },
        };

        // Compare the selected boundary points
        const position = compareBoundaryPointsImpl(this_point, source_point);
        return switch (position) {
            .before => -1,
            .equal => 0,
            .after => 1,
        };
    }

    /// Compares a boundary point to this range.
    ///
    /// ## WebIDL
    /// ```webidl
    /// short comparePoint(Node node, unsigned long offset);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.3)
    /// 1. If node's root ≠ range's root, throw WrongDocumentError
    /// 2. If node is doctype, throw InvalidNodeTypeError
    /// 3. If offset > node's length, throw IndexSizeError
    /// 4. If (node, offset) is before start, return -1
    /// 5. If (node, offset) is after end, return 1
    /// 6. Otherwise return 0
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-comparepoint
    ///
    /// ## Errors
    /// - `WrongDocumentError`: node is from different document
    /// - `InvalidNodeTypeError`: node is DocumentType
    /// - `IndexSizeError`: offset > node's length
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// try range.setStart(&text.prototype, 2);
    /// try range.setEnd(&text.prototype, 8);
    ///
    /// // Is position 0 before/in/after range?
    /// const result = try range.comparePoint(&text.prototype, 0);
    /// // result = -1 (position 0 is before range start)
    /// ```
    pub fn comparePoint(self: *const Range, node: *Node, offset: u32) !i16 {
        // Step 1: Validate node type
        if (node.node_type == .document_type) {
            return error.InvalidNodeTypeError;
        }

        // Step 2: Validate offset
        const length = nodeLength(node);
        if (offset > length) {
            return error.IndexSizeError;
        }

        // Step 3: Create boundary point
        const point = BoundaryPoint{ .container = node, .offset = offset };
        const start = BoundaryPoint{ .container = self.start_container, .offset = self.start_offset };
        const end = BoundaryPoint{ .container = self.end_container, .offset = self.end_offset };

        // Step 4: Compare to start
        if (compareBoundaryPointsImpl(point, start) == .before) {
            return -1;
        }

        // Step 5: Compare to end
        if (compareBoundaryPointsImpl(point, end) == .after) {
            return 1;
        }

        // Step 6: Point is within range
        return 0;
    }

    /// Returns true if the point is within the range.
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean isPointInRange(Node node, unsigned long offset);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.3)
    /// 1. If node's root ≠ range's root, return false
    /// 2. If node is doctype, throw InvalidNodeTypeError
    /// 3. If offset > node's length, throw IndexSizeError
    /// 4. If (node, offset) is before start, return false
    /// 5. If (node, offset) is after end, return false
    /// 6. Otherwise return true
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-ispointinrange
    ///
    /// ## Errors
    /// - `InvalidNodeTypeError`: node is DocumentType
    /// - `IndexSizeError`: offset > node's length
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// try range.setStart(&text.prototype, 2);
    /// try range.setEnd(&text.prototype, 8);
    ///
    /// // Is position 5 in range?
    /// const in_range = try range.isPointInRange(&text.prototype, 5);
    /// // in_range = true
    /// ```
    pub fn isPointInRange(self: *const Range, node: *Node, offset: u32) !bool {
        // Step 1: Validate node type
        if (node.node_type == .document_type) {
            return error.InvalidNodeTypeError;
        }

        // Step 2: Validate offset
        const length = nodeLength(node);
        if (offset > length) {
            return error.IndexSizeError;
        }

        // Step 3: Create boundary point
        const point = BoundaryPoint{ .container = node, .offset = offset };
        const start = BoundaryPoint{ .container = self.start_container, .offset = self.start_offset };
        const end = BoundaryPoint{ .container = self.end_container, .offset = self.end_offset };

        // Step 4-5: Check if point is within range
        const after_start = compareBoundaryPointsImpl(point, start) != .before;
        const before_end = compareBoundaryPointsImpl(point, end) != .after;

        return after_start and before_end;
    }

    /// Returns true if the node intersects the range.
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean intersectsNode(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.3)
    /// 1. If node's root ≠ range's root, return false
    /// 2. Let parent be node's parent
    /// 3. If parent is null, return true
    /// 4. Let offset be node's index
    /// 5. Return (parent, offset) is before end AND (parent, offset + 1) is after start
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-intersectsnode
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// const parent = try doc.createElement("div");
    /// const child1 = try doc.createElement("span");
    /// const child2 = try doc.createElement("p");
    /// _ = try parent.prototype.appendChild(&child1.prototype);
    /// _ = try parent.prototype.appendChild(&child2.prototype);
    ///
    /// // Range selects child1
    /// try range.setStart(&parent.prototype, 0);
    /// try range.setEnd(&parent.prototype, 1);
    ///
    /// // Does range intersect child1?
    /// const intersects = range.intersectsNode(&child1.prototype);
    /// // intersects = true
    /// ```
    pub fn intersectsNode(self: *const Range, node: *Node) bool {
        // Step 2: Get parent
        const parent = node.parent_node orelse return true;

        // Step 4: Get node's index
        const offset = nodeIndex(node) catch return true;

        // Step 5: Check if node intersects range
        const before_point = BoundaryPoint{ .container = parent, .offset = offset };
        const after_point = BoundaryPoint{ .container = parent, .offset = offset + 1 };
        const start = BoundaryPoint{ .container = self.start_container, .offset = self.start_offset };
        const end = BoundaryPoint{ .container = self.end_container, .offset = self.end_offset };

        // Node intersects if: (parent, offset) < end AND (parent, offset+1) > start
        const before_end = compareBoundaryPointsImpl(before_point, end) == .before;
        const after_start = compareBoundaryPointsImpl(after_point, start) == .after;

        return before_end and after_start;
    }

    /// Deletes the contents of the range.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] undefined deleteContents();
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.4)
    /// Removes all nodes and partial content within the range from the DOM.
    /// Range is collapsed to start after deletion.
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-deletecontents
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// try range.setStart(&text.prototype, 2);
    /// try range.setEnd(&text.prototype, 8);
    ///
    /// // Delete "llo Wo" from "Hello World"
    /// try range.deleteContents();
    /// // text.data = "Herld"
    /// ```
    pub fn deleteContents(self: *Range) RangeError!void {
        _ = try self.processContents(.delete);
    }

    /// Extracts the contents of the range into a DocumentFragment.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, NewObject] DocumentFragment extractContents();
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.4)
    /// Removes all nodes and partial content within the range and returns them
    /// in a new DocumentFragment. Range is collapsed to start after extraction.
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-extractcontents
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// try range.setStart(&elem.prototype, 0);
    /// try range.setEnd(&elem.prototype, 2);
    ///
    /// const fragment = try range.extractContents();
    /// defer fragment.prototype.release();
    /// // fragment contains extracted children
    /// ```
    pub fn extractContents(self: *Range) RangeError!*DocumentFragment {
        return (try self.processContents(.extract)).?;
    }

    /// Clones the contents of the range into a DocumentFragment.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, NewObject] DocumentFragment cloneContents();
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.4)
    /// Copies all nodes and partial content within the range into a new
    /// DocumentFragment. Original nodes remain unchanged. Range is not collapsed.
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-clonecontents
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// try range.setStart(&elem.prototype, 0);
    /// try range.setEnd(&elem.prototype, 2);
    ///
    /// const fragment = try range.cloneContents();
    /// defer fragment.prototype.release();
    /// // fragment contains cloned children, originals unchanged
    /// ```
    pub fn cloneContents(self: *Range) RangeError!*DocumentFragment {
        return (try self.processContents(.clone)).?;
    }

    /// Inserts a node at the start of the range.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] undefined insertNode(Node node);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.5)
    /// 1. If start container is Text/Comment, split it at start offset
    /// 2. Otherwise, insert node at start offset
    /// 3. Set start and end to (parent, index)
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-insertnode
    ///
    /// ## Errors
    /// - `HierarchyRequestError`: Invalid insertion
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// const text = try doc.createTextNode("Hello");
    /// try range.setStart(&text.prototype, 2);
    /// try range.collapse(true);
    ///
    /// const elem = try doc.createElement("span");
    /// try range.insertNode(&elem.prototype);
    /// // Inserts elem at position 2 in text's parent
    /// ```
    pub fn insertNode(self: *Range, node: *Node) RangeError!void {
        const start_container = self.start_container;
        const start_offset = self.start_offset;

        // If start container is Text or Comment, we need to handle insertion
        if (start_container.node_type == .text or start_container.node_type == .comment) {
            const parent = start_container.parent_node orelse return error.HierarchyRequestError;

            // If we're at offset 0, insert before the text node
            if (start_offset == 0) {
                _ = try parent.insertBefore(node, start_container);
            } else {
                // Split the text/comment node at start_offset
                if (start_container.node_type == .text) {
                    const Text = @import("text.zig").Text;
                    const text_node: *Text = @fieldParentPtr("prototype", start_container);
                    _ = try text_node.splitText(start_offset);
                } else {
                    // Comment nodes don't have splitText, so we handle it manually
                    const Comment = @import("comment.zig").Comment;
                    const comment_node: *Comment = @fieldParentPtr("prototype", start_container);
                    const after_data = try comment_node.prototype.allocator.dupe(u8, comment_node.data[start_offset..]);
                    errdefer comment_node.prototype.allocator.free(after_data);

                    try comment_node.deleteData(start_offset, @intCast(comment_node.data.len - start_offset));

                    const new_comment = try Comment.create(comment_node.prototype.allocator, after_data);
                    comment_node.prototype.allocator.free(after_data);

                    _ = try parent.insertBefore(&new_comment.prototype, start_container.next_sibling);
                }

                // Insert the node after the original text node (which now contains only the first part)
                _ = try parent.insertBefore(node, start_container.next_sibling);
            }
        } else {
            // Container is Element or DocumentFragment
            // Find the child at start_offset
            var ref_child: ?*Node = null;
            var current = start_container.first_child;
            var index: u32 = 0;

            while (current) |child| {
                if (index == start_offset) {
                    ref_child = child;
                    break;
                }
                index += 1;
                current = child.next_sibling;
            }

            // Insert node before ref_child (or at end if ref_child is null)
            _ = try start_container.insertBefore(node, ref_child);
        }
    }

    /// Wraps the range contents with a new parent node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] undefined surroundContents(Node newParent);
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.5)
    /// 1. If start/end containers are different and not ancestors, throw
    /// 2. Extract contents
    /// 3. Insert newParent at range start
    /// 4. Append extracted contents to newParent
    /// 5. Select newParent
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-surroundcontents
    ///
    /// ## Errors
    /// - `InvalidStateError`: Range partially selects a node
    /// - `HierarchyRequestError`: newParent is invalid
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// const text = try doc.createTextNode("Hello");
    /// try range.selectNodeContents(&text.prototype);
    ///
    /// const span = try doc.createElement("span");
    /// try range.surroundContents(&span.prototype);
    /// // Wraps text content in span
    /// ```
    pub fn surroundContents(self: *Range, new_parent: *Node) RangeError!void {
        // Check if range partially selects nodes
        // If start and end containers are different, they must be in ancestor relationship
        if (self.start_container != self.end_container) {
            const start_is_ancestor = nodeContains(self.start_container, self.end_container);
            const end_is_ancestor = nodeContains(self.end_container, self.start_container);

            if (!start_is_ancestor and !end_is_ancestor) {
                return error.InvalidStateError;
            }
        }

        // Extract the contents
        const fragment = try self.extractContents();
        errdefer fragment.prototype.release();

        // Remove any existing children from newParent
        while (new_parent.first_child) |child| {
            _ = try new_parent.removeChild(child);
            child.release();
        }

        // Insert newParent at the range position
        try self.insertNode(new_parent);

        // Append the extracted contents to newParent
        _ = new_parent.appendChild(&fragment.prototype) catch unreachable;

        // Release the fragment (it's now empty since we appended it)
        fragment.prototype.release();

        // Select newParent
        try self.selectNode(new_parent);
    }

    /// Creates a clone of this range.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] Range cloneRange();
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.5)
    /// Create a new Range with the same boundaries as this range.
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-clonerange
    ///
    /// ## Usage
    /// ```zig
    /// const range1 = try doc.createRange();
    /// defer range1.deinit();
    ///
    /// try range1.setStart(&node.prototype, 0);
    /// try range1.setEnd(&node.prototype, 5);
    ///
    /// const range2 = try range1.cloneRange();
    /// defer range2.deinit();
    /// // range2 has same boundaries as range1
    /// ```
    pub fn cloneRange(self: *const Range) RangeError!*Range {
        const cloned = try self.allocator.create(Range);
        cloned.* = .{
            .start_container = self.start_container,
            .start_offset = self.start_offset,
            .end_container = self.end_container,
            .end_offset = self.end_offset,
            .allocator = self.allocator,
        };
        return cloned;
    }

    /// Detaches the range (no-op for compatibility).
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined detach();
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.5)
    /// This method is a no-op. It exists for historical reasons.
    ///
    /// ## Spec Reference
    /// https://dom.spec.whatwg.org/#dom-range-detach
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// range.detach(); // Does nothing
    /// ```
    pub fn detach(self: *Range) void {
        _ = self;
        // No-op per spec
    }

    /// Returns the text representation of the range contents.
    ///
    /// ## WebIDL
    /// ```webidl
    /// stringifier;
    /// ```
    ///
    /// ## Algorithm (WHATWG §5.5)
    /// 1. Let s be an empty string
    /// 2. If start node equals end node and it is a Text node:
    ///    - Return substring from start offset to end offset
    /// 3. If start node is a Text node:
    ///    - Append substring from start offset to end
    /// 4. Append concatenation of Text node data (in tree order) for nodes contained in range
    /// 5. If end node is a Text node:
    ///    - Append substring from 0 to end offset
    /// 6. Return s
    ///
    /// ## Spec Reference
    /// - WHATWG DOM §5.5: https://dom.spec.whatwg.org/#dom-range-stringifier
    /// - MDN Range.toString(): https://developer.mozilla.org/en-US/docs/Web/API/Range/toString
    ///
    /// ## Memory
    /// Caller owns the returned string and must free it.
    ///
    /// ## Usage
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// const text = try doc.createTextNode("Hello World");
    /// try range.setStart(&text.prototype, 0);
    /// try range.setEnd(&text.prototype, 5);
    ///
    /// const str = try range.toString(allocator);
    /// defer allocator.free(str);
    /// // str = "Hello"
    /// ```
    pub fn toString(self: *const Range, allocator: Allocator) ![]const u8 {
        // Step 1: If range is collapsed, return empty string
        if (self.collapsed()) {
            return try allocator.dupe(u8, "");
        }

        // Step 2: If start and end are in same Text node
        if (self.start_container == self.end_container and
            self.start_container.node_type == .text)
        {
            const Text = @import("text.zig").Text;
            const text_node: *const Text = @fieldParentPtr("prototype", self.start_container);
            const substring = text_node.data[self.start_offset..self.end_offset];
            return try allocator.dupe(u8, substring);
        }

        // Steps 3-5: Complex case - accumulate text from multiple nodes
        var result = std.ArrayList(u8){};
        defer result.deinit(allocator);

        // Traverse all nodes in the range in tree order and collect text
        try self.collectTextInRange(allocator, &result);

        return result.toOwnedSlice(allocator);
    }

    /// Collects all text content within the range in tree order.
    ///
    /// This implements the WHATWG algorithm for gathering text:
    /// 1. If start container is Text, include partial text from start offset to end
    /// 2. Include all Text nodes fully contained in range
    /// 3. If end container is Text (and different from start), include partial text from 0 to end offset
    fn collectTextInRange(
        self: *const Range,
        allocator: Allocator,
        result: *std.ArrayList(u8),
    ) !void {
        // Find common ancestor to traverse from
        const ancestor = findCommonAncestor(self.start_container, self.end_container);

        // Traverse tree in document order
        try self.traverseAndCollect(allocator, result, ancestor);
    }

    /// Traverses nodes in tree order and collects text based on range boundaries.
    fn traverseAndCollect(
        self: *const Range,
        allocator: Allocator,
        result: *std.ArrayList(u8),
        node: *Node,
    ) !void {
        // For each node, determine its relationship to the range
        const position = self.getNodePosition(node);

        switch (position) {
            .before, .after => return, // Node is outside range

            .partial_start => {
                // This node contains the start boundary
                if (node.node_type == .text) {
                    const Text = @import("text.zig").Text;
                    const text_node: *const Text = @fieldParentPtr("prototype", node);
                    const end_offset = if (node == self.end_container) self.end_offset else text_node.data.len;
                    try result.appendSlice(allocator, text_node.data[self.start_offset..end_offset]);
                } else {
                    // Traverse children
                    var child = node.first_child;
                    while (child) |c| {
                        try self.traverseAndCollect(allocator, result, c);
                        child = c.next_sibling;
                    }
                }
            },

            .partial_end => {
                // This node contains the end boundary (but not start)
                if (node.node_type == .text) {
                    const Text = @import("text.zig").Text;
                    const text_node: *const Text = @fieldParentPtr("prototype", node);
                    try result.appendSlice(allocator, text_node.data[0..self.end_offset]);
                } else {
                    // Traverse children
                    var child = node.first_child;
                    while (child) |c| {
                        try self.traverseAndCollect(allocator, result, c);
                        child = c.next_sibling;
                    }
                }
            },

            .contained => {
                // Node is fully contained in range
                if (node.node_type == .text) {
                    const Text = @import("text.zig").Text;
                    const text_node: *const Text = @fieldParentPtr("prototype", node);
                    try result.appendSlice(allocator, text_node.data);
                } else {
                    // Traverse children
                    var child = node.first_child;
                    while (child) |c| {
                        try self.traverseAndCollect(allocator, result, c);
                        child = c.next_sibling;
                    }
                }
            },

            .contains_range => {
                // Node contains both boundaries - traverse children
                var child = node.first_child;
                while (child) |c| {
                    try self.traverseAndCollect(allocator, result, c);
                    child = c.next_sibling;
                }
            },
        }
    }

    /// Position of a node relative to the range.
    const NodePosition = enum {
        before, // Node is completely before range
        after, // Node is completely after range
        partial_start, // Node contains start boundary
        partial_end, // Node contains end boundary (but not start)
        contained, // Node is fully contained in range
        contains_range, // Node contains both boundaries
    };

    /// Determines the position of a node relative to the range.
    fn getNodePosition(self: *const Range, node: *Node) NodePosition {
        const contains_start = nodeContains(node, self.start_container);
        const contains_end = nodeContains(node, self.end_container);

        if (contains_start and contains_end) {
            if (node == self.start_container and node == self.end_container) {
                return .contains_range; // Same node
            }
            return .contains_range;
        }

        if (contains_start) {
            if (node == self.start_container) {
                return .partial_start;
            }
            return .contains_range; // Ancestor of start
        }

        if (contains_end) {
            if (node == self.end_container) {
                return .partial_end;
            }
            return .contains_range; // Ancestor of end
        }

        // Check if node is fully contained in range
        if (self.intersectsNode(node)) {
            // Need to check if it's truly contained or just intersects
            const parent = node.parent_node orelse return .before;
            const offset = nodeIndex(node) catch return .before;

            const node_start = BoundaryPoint{ .container = parent, .offset = offset };
            const node_end = BoundaryPoint{ .container = parent, .offset = offset + 1 };
            const range_start = BoundaryPoint{ .container = self.start_container, .offset = self.start_offset };
            const range_end = BoundaryPoint{ .container = self.end_container, .offset = self.end_offset };

            const after_range_start = compareBoundaryPointsImpl(node_start, range_start) != .before;
            const before_range_end = compareBoundaryPointsImpl(node_end, range_end) != .after;

            if (after_range_start and before_range_end) {
                return .contained;
            }
        }

        // Check if node is before or after range
        if (node.parent_node) |parent| {
            const offset = nodeIndex(node) catch return .before;
            const node_point = BoundaryPoint{ .container = parent, .offset = offset };
            const range_start = BoundaryPoint{ .container = self.start_container, .offset = self.start_offset };

            if (compareBoundaryPointsImpl(node_point, range_start) == .before) {
                return .before;
            }
        }

        return .after;
    }

    /// Content manipulation action type.
    const ContentAction = enum {
        delete, // Remove content from DOM
        extract, // Remove and return in fragment
        clone, // Copy without removing
    };

    /// Processes range contents according to action.
    ///
    /// Core algorithm shared by deleteContents, extractContents, cloneContents.
    ///
    /// ## Algorithm (WHATWG §5.4)
    /// 1. If collapsed, return empty fragment (or null for delete)
    /// 2. If same container, handle text/element directly
    /// 3. If different containers:
    ///    a. Process partial start node
    ///    b. Process complete nodes between
    ///    c. Process partial end node
    /// 4. Collapse range (for delete/extract only)
    fn processContents(
        self: *Range,
        action: ContentAction,
    ) RangeError!?*DocumentFragment {
        // Step 1: Handle collapsed range
        if (self.collapsed()) {
            if (action == .extract or action == .clone) {
                // Get document from start container
                const doc = getOwnerDocument(self.start_container);
                return try DocumentFragment.create(doc.prototype.allocator);
            }
            return null;
        }

        // Step 2: Create fragment for extract/clone
        var fragment: ?*DocumentFragment = null;
        if (action != .delete) {
            const doc = getOwnerDocument(self.start_container);
            fragment = try DocumentFragment.create(doc.prototype.allocator);
        }
        errdefer if (fragment) |f| f.prototype.release();

        // Step 3: Same container - simple case
        if (self.start_container == self.end_container) {
            try self.processSameContainer(action, fragment);
            return fragment;
        }

        // Step 4: Different containers - complex case
        try self.processDifferentContainers(action, fragment);

        return fragment;
    }

    /// Processes contents when start and end are in same container.
    fn processSameContainer(
        self: *Range,
        action: ContentAction,
        fragment: ?*DocumentFragment,
    ) RangeError!void {
        const container = self.start_container;

        // Text/Comment nodes: handle character data
        if (container.node_type == .text or container.node_type == .comment) {
            const Text = @import("text.zig").Text;
            const Comment = @import("comment.zig").Comment;

            if (container.node_type == .text) {
                const text_node: *Text = @fieldParentPtr("prototype", container);

                if (action == .clone) {
                    // Clone the substring
                    const substring = text_node.data[self.start_offset..self.end_offset];
                    const cloned_text = try Text.create(text_node.prototype.allocator, substring);
                    _ = fragment.?.prototype.appendChild(&cloned_text.prototype) catch unreachable;
                } else {
                    // Extract or delete
                    if (action == .extract) {
                        const substring = text_node.data[self.start_offset..self.end_offset];
                        const extracted_text = try Text.create(text_node.prototype.allocator, substring);
                        _ = fragment.?.prototype.appendChild(&extracted_text.prototype) catch unreachable;
                    }
                    // Delete the range from the text
                    try text_node.deleteData(self.start_offset, self.end_offset - self.start_offset);
                    // Collapse to start
                    self.collapse(true);
                }
            } else {
                const comment_node: *Comment = @fieldParentPtr("prototype", container);

                if (action == .clone) {
                    const substring = comment_node.data[self.start_offset..self.end_offset];
                    const cloned_comment = try Comment.create(comment_node.prototype.allocator, substring);
                    _ = fragment.?.prototype.appendChild(&cloned_comment.prototype) catch unreachable;
                } else {
                    if (action == .extract) {
                        const substring = comment_node.data[self.start_offset..self.end_offset];
                        const extracted_comment = try Comment.create(comment_node.prototype.allocator, substring);
                        _ = fragment.?.prototype.appendChild(&extracted_comment.prototype) catch unreachable;
                    }
                    try comment_node.deleteData(self.start_offset, self.end_offset - self.start_offset);
                    self.collapse(true);
                }
            }
        } else {
            // Element/DocumentFragment: remove children between offsets
            const start_offset = self.start_offset;
            const end_offset = self.end_offset;

            // Collect children to process
            var children_to_process = std.ArrayList(*Node){};
            defer children_to_process.deinit(self.allocator);

            var current_child = container.first_child;
            var index: u32 = 0;
            while (current_child) |child| {
                if (index >= start_offset and index < end_offset) {
                    try children_to_process.append(self.allocator, child);
                }
                index += 1;
                current_child = child.next_sibling;
            }

            // Process collected children
            for (children_to_process.items) |child| {
                if (action == .clone) {
                    const cloned = child.cloneNode(true) catch |err| return err;
                    _ = fragment.?.prototype.appendChild(cloned) catch unreachable;
                } else {
                    // Extract or delete
                    _ = try container.removeChild(child);
                    if (action == .extract) {
                        _ = fragment.?.prototype.appendChild(child) catch unreachable;
                    } else {
                        child.release();
                    }
                }
            }

            // Collapse to start for delete/extract
            if (action != .clone) {
                self.collapse(true);
            }
        }
    }

    /// Processes contents when start and end are in different containers.
    fn processDifferentContainers(
        self: *Range,
        action: ContentAction,
        fragment: ?*DocumentFragment,
    ) RangeError!void {
        // Find common ancestor
        const common_ancestor = findCommonAncestor(self.start_container, self.end_container);

        // Save original boundaries
        const original_start_container = self.start_container;
        const original_start_offset = self.start_offset;
        const original_end_container = self.end_container;
        const original_end_offset = self.end_offset;

        // Find the children of common ancestor that contain start and end
        var start_ancestor = original_start_container;
        while (start_ancestor.parent_node) |parent| {
            if (parent == common_ancestor) break;
            start_ancestor = parent;
        }

        var end_ancestor = original_end_container;
        while (end_ancestor.parent_node) |parent| {
            if (parent == common_ancestor) break;
            end_ancestor = parent;
        }

        // Collect nodes to process between start_ancestor and end_ancestor
        var nodes_to_process = std.ArrayList(*Node){};
        defer nodes_to_process.deinit(self.allocator);

        var current = start_ancestor.next_sibling;
        while (current) |node| {
            if (node == end_ancestor) break;
            try nodes_to_process.append(self.allocator, node);
            current = node.next_sibling;
        }

        // Process start container (partial)
        if (original_start_container.node_type == .text or original_start_container.node_type == .comment) {
            const Text = @import("text.zig").Text;
            const Comment = @import("comment.zig").Comment;

            if (original_start_container.node_type == .text) {
                const text_node: *Text = @fieldParentPtr("prototype", original_start_container);
                const length = text_node.data.len;

                if (action == .clone) {
                    const substring = text_node.data[original_start_offset..length];
                    const cloned = try Text.create(text_node.prototype.allocator, substring);
                    _ = fragment.?.prototype.appendChild(&cloned.prototype) catch unreachable;
                } else {
                    if (action == .extract) {
                        const substring = text_node.data[original_start_offset..length];
                        const extracted = try Text.create(text_node.prototype.allocator, substring);
                        _ = fragment.?.prototype.appendChild(&extracted.prototype) catch unreachable;
                    }
                    try text_node.deleteData(original_start_offset, @intCast(length - original_start_offset));
                }
            } else {
                const comment_node: *Comment = @fieldParentPtr("prototype", original_start_container);
                const length = comment_node.data.len;

                if (action == .clone) {
                    const substring = comment_node.data[original_start_offset..length];
                    const cloned = try Comment.create(comment_node.prototype.allocator, substring);
                    _ = fragment.?.prototype.appendChild(&cloned.prototype) catch unreachable;
                } else {
                    if (action == .extract) {
                        const substring = comment_node.data[original_start_offset..length];
                        const extracted = try Comment.create(comment_node.prototype.allocator, substring);
                        _ = fragment.?.prototype.appendChild(&extracted.prototype) catch unreachable;
                    }
                    try comment_node.deleteData(original_start_offset, @intCast(length - original_start_offset));
                }
            }
        }

        // Process complete nodes between start and end
        for (nodes_to_process.items) |node| {
            if (action == .clone) {
                const cloned = node.cloneNode(true) catch |err| return err;
                _ = fragment.?.prototype.appendChild(cloned) catch unreachable;
            } else {
                _ = try common_ancestor.removeChild(node);
                if (action == .extract) {
                    _ = fragment.?.prototype.appendChild(node) catch unreachable;
                } else {
                    node.release();
                }
            }
        }

        // Process end container (partial)
        if (original_end_container.node_type == .text or original_end_container.node_type == .comment) {
            const Text = @import("text.zig").Text;
            const Comment = @import("comment.zig").Comment;

            if (original_end_container.node_type == .text) {
                const text_node: *Text = @fieldParentPtr("prototype", original_end_container);

                if (action == .clone) {
                    const substring = text_node.data[0..original_end_offset];
                    const cloned = try Text.create(text_node.prototype.allocator, substring);
                    _ = fragment.?.prototype.appendChild(&cloned.prototype) catch unreachable;
                } else {
                    if (action == .extract) {
                        const substring = text_node.data[0..original_end_offset];
                        const extracted = try Text.create(text_node.prototype.allocator, substring);
                        _ = fragment.?.prototype.appendChild(&extracted.prototype) catch unreachable;
                    }
                    try text_node.deleteData(0, original_end_offset);
                }
            } else {
                const comment_node: *Comment = @fieldParentPtr("prototype", original_end_container);

                if (action == .clone) {
                    const substring = comment_node.data[0..original_end_offset];
                    const cloned = try Comment.create(comment_node.prototype.allocator, substring);
                    _ = fragment.?.prototype.appendChild(&cloned.prototype) catch unreachable;
                } else {
                    if (action == .extract) {
                        const substring = comment_node.data[0..original_end_offset];
                        const extracted = try Comment.create(comment_node.prototype.allocator, substring);
                        _ = fragment.?.prototype.appendChild(&extracted.prototype) catch unreachable;
                    }
                    try comment_node.deleteData(0, original_end_offset);
                }
            }
        }

        // Collapse to start for delete/extract
        if (action != .clone) {
            self.start_container = original_start_container;
            self.start_offset = original_start_offset;
            self.end_container = original_start_container;
            self.end_offset = original_start_offset;
        }
    }
};

// === Helper Types and Functions ===

/// Boundary point for internal comparisons.
///
/// Represents a position in the DOM tree as (node, offset) pair.
const BoundaryPoint = struct {
    container: *Node,
    offset: u32,
};

/// Relative position of two boundary points.
const BoundaryPointPosition = enum {
    before,
    equal,
    after,
};

/// Returns the length of a node for Range purposes.
///
/// ## Algorithm (WHATWG §5.5)
/// - Element/DocumentFragment: childCount
/// - CharacterData: data.length
/// - DocumentType/Other: 0
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-node-length
fn nodeLength(node: *Node) u32 {
    return switch (node.node_type) {
        .element, .document, .document_fragment, .shadow_root => blk: {
            var count: u32 = 0;
            var child = node.first_child;
            while (child) |c| {
                count += 1;
                child = c.next_sibling;
            }
            break :blk count;
        },
        .text => blk: {
            const Text = @import("text.zig").Text;
            const text_node: *const Text = @fieldParentPtr("prototype", node);
            break :blk @intCast(text_node.data.len);
        },
        .cdata_section => blk: {
            const Text = @import("text.zig").Text;
            const CDATASection = @import("cdata_section.zig").CDATASection;
            const text_node: *const Text = @fieldParentPtr("prototype", node);
            const cdata_node: *const CDATASection = @fieldParentPtr("prototype", text_node);
            break :blk @intCast(cdata_node.prototype.data.len);
        },
        .comment => blk: {
            const Comment = @import("comment.zig").Comment;
            const comment_node: *const Comment = @fieldParentPtr("prototype", node);
            break :blk @intCast(comment_node.data.len);
        },
        .document_type => 0,
        .processing_instruction => 0,
        .attribute => 0,
    };
}

/// Returns the index of a node within its parent.
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-tree-index
fn nodeIndex(node: *Node) !u32 {
    const parent = node.parent_node orelse return error.InvalidNodeTypeError;

    var index: u32 = 0;
    var sibling = parent.first_child;
    while (sibling) |s| {
        if (s == node) return index;
        index += 1;
        sibling = s.next_sibling;
    }

    return error.NotFoundError;
}

/// Compares two boundary points in tree order.
///
/// ## Algorithm (WHATWG §5.3)
/// 1. If containers are same: compare offsets
/// 2. If one contains the other: containing comes first
/// 3. Otherwise: find common ancestor and compare positions
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-range-bp-position
fn compareBoundaryPointsImpl(a: BoundaryPoint, b: BoundaryPoint) BoundaryPointPosition {
    // Step 1: Same container - compare offsets
    if (a.container == b.container) {
        if (a.offset < b.offset) return .before;
        if (a.offset > b.offset) return .after;
        return .equal;
    }

    // Step 2: Check if one contains the other
    // If a contains b, a comes before
    if (nodeContains(a.container, b.container)) {
        // Find which child of a contains b
        const child_offset = childOffsetForContainer(a.container, b.container);
        if (a.offset <= child_offset) return .before;
        return .after;
    }

    // If b contains a, b comes before (so a comes after)
    if (nodeContains(b.container, a.container)) {
        const child_offset = childOffsetForContainer(b.container, a.container);
        if (child_offset < b.offset) return .before;
        return .after;
    }

    // Step 3: Neither contains the other - compare tree positions
    const ordering = nodeTreeOrder(a.container, b.container);
    return if (ordering == .before) .before else .after;
}

/// Returns true if ancestor contains descendant (inclusive).
fn nodeContains(ancestor: *Node, descendant: *Node) bool {
    if (ancestor == descendant) return true;

    var current = descendant.parent_node;
    while (current) |parent| {
        if (parent == ancestor) return true;
        current = parent.parent_node;
    }

    return false;
}

/// Returns the child index offset that contains or is an ancestor of node.
///
/// Assumes container contains node (caller must verify).
fn childOffsetForContainer(container: *Node, node: *Node) u32 {
    var current = node;

    // Walk up from node until we find direct child of container
    while (current.parent_node) |parent| {
        if (parent == container) {
            // current is direct child of container
            return nodeIndex(current) catch 0;
        }
        current = parent;
    }

    return 0;
}

/// Compares two nodes in tree order.
const TreeOrder = enum {
    before,
    after,
};

fn nodeTreeOrder(a: *Node, b: *Node) TreeOrder {
    // Find common ancestor
    const ancestor = findCommonAncestor(a, b);

    // Find which children of ancestor contain a and b
    var a_child = a;
    while (a_child.parent_node) |parent| {
        if (parent == ancestor) break;
        a_child = parent;
    }

    var b_child = b;
    while (b_child.parent_node) |parent| {
        if (parent == ancestor) break;
        b_child = parent;
    }

    // Compare positions of children
    var current = ancestor.first_child;
    while (current) |c| {
        if (c == a_child) return .before;
        if (c == b_child) return .after;
        current = c.next_sibling;
    }

    // Should not reach here if both nodes in same tree
    return .before;
}

/// Finds lowest common ancestor of two nodes.
fn findCommonAncestor(a: *Node, b: *Node) *Node {
    // Quick check: same node
    if (a == b) return a;

    // Check if one contains the other
    if (nodeContains(a, b)) return a;
    if (nodeContains(b, a)) return b;

    // Walk ancestors of a, checking if each contains b
    var ancestor = a;
    while (ancestor.parent_node) |parent| {
        if (nodeContains(parent, b)) return parent;
        ancestor = parent;
    }

    // Should not reach here if both in same tree
    return ancestor;
}

/// Gets the owner document of a node.
fn getOwnerDocument(node: *Node) *Document {
    if (node.node_type == .document) {
        return @fieldParentPtr("prototype", node);
    }
    // owner_document should always be set for non-document nodes
    const owner = node.owner_document orelse unreachable;
    return @fieldParentPtr("prototype", owner);
}
