//! Text Interface (§4.7)
//!
//! This module implements the Text interface as specified by the WHATWG DOM Standard.
//! Text nodes represent the actual text content of elements and are the most common
//! type of node in a DOM tree after elements. They store mutable character data and
//! provide methods for text manipulation.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.7 Interface Text**: https://dom.spec.whatwg.org/#interface-text
//! - **§4.8 Interface CharacterData**: https://dom.spec.whatwg.org/#interface-characterdata
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node (base)
//!
//! ## MDN Documentation
//!
//! - Text: https://developer.mozilla.org/en-US/docs/Web/API/Text
//! - Text.data: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/data
//! - Text.length: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/length
//! - Text.substringData(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/substringData
//! - Text.splitText(): https://developer.mozilla.org/en-US/docs/Web/API/Text/splitText
//!
//! ## Core Features
//!
//! ### Text Content Storage
//! Text nodes store mutable string content that can be modified:
//! ```zig
//! const text = try Text.create(allocator, "Hello, World!");
//! defer text.prototype.release();
//!
//! // Access via node.nodeValue
//! const content = text.prototype.nodeValue(); // "Hello, World!"
//!
//! // Or via data field
//! const data = text.data; // "Hello, World!"
//! ```
//!
//! ### Character Data Manipulation
//! Text provides methods for substring operations, insertion, deletion:
//! ```zig
//! const text = try Text.create(allocator, "Hello World");
//! defer text.prototype.release();
//!
//! // Get substring
//! const sub = try text.substringData(0, 5); // "Hello"
//! defer allocator.free(sub);
//!
//! // Append text
//! try text.appendData(" Zig!");
//! // text.data = "Hello World Zig!"
//! ```
//!
//! ### Text Splitting
//! Split text nodes at a specific offset for editing operations:
//! ```zig
//! const parent = try Element.create(allocator, "p");
//! defer parent.prototype.release();
//!
//! const text = try Text.create(allocator, "Hello World");
//! _ = try parent.prototype.appendChild(&text.prototype);
//!
//! // Split at offset 6 (after "Hello ")
//! const second_half = try text.splitText(6);
//! // text.data = "Hello "
//! // second_half.data = "World"
//! // Both are children of parent
//! ```
//!
//! ## Text Node Structure
//!
//! Text nodes extend Node with character data storage:
//! - **node**: Base Node struct (MUST be first field for @fieldParentPtr)
//! - **data**: Owned string ([]u8) containing text content
//! - **vtable**: Node vtable for polymorphic behavior
//!
//! Size beyond Node: 16 bytes (for data slice)
//!
//! ## Memory Management
//!
//! Text nodes use reference counting through Node interface:
//! ```zig
//! const text = try Text.create(allocator, "Example");
//! defer text.prototype.release(); // Decrements ref_count, frees if 0
//!
//! // When sharing ownership:
//! text.prototype.acquire(); // Increment ref_count
//! other_structure.text_node = &text.prototype;
//! // Both owners must call release()
//! ```
//!
//! When a text node is released (ref_count reaches 0):
//! 1. Text data string is freed (allocator.free(data))
//! 2. Node base is freed
//! 3. Children are released recursively (though text nodes rarely have children)
//!
//! ## Usage Examples
//!
//! ### Creating Text Nodes
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! // Direct creation (simple, for tests)
//! const text1 = try Text.create(allocator, "Hello");
//! defer text1.prototype.release();
//!
//! // Via Document factory (RECOMMENDED - with string interning)
//! const doc = try Document.init(allocator);
//! defer doc.release();
//! const text2 = try doc.createTextNode("World");
//! defer text2.prototype.release();
//! ```
//!
//! ### Building Text Content
//! ```zig
//! const paragraph = try Element.create(allocator, "p");
//! defer paragraph.prototype.release();
//!
//! // Add text content
//! const text = try Text.create(allocator, "This is a ");
//! _ = try paragraph.prototype.appendChild(&text.prototype);
//!
//! const emphasis = try Element.create(allocator, "em");
//! _ = try paragraph.prototype.appendChild(&emphasis.prototype);
//!
//! const emphText = try Text.create(allocator, "very");
//! _ = try emphasis.prototype.appendChild(&emphText.prototype);
//!
//! const moreText = try Text.create(allocator, " important message.");
//! _ = try paragraph.prototype.appendChild(&moreText.prototype);
//!
//! // Result: <p>This is a <em>very</em> important message.</p>
//! ```
//!
//! ### Manipulating Text Data
//! ```zig
//! const text = try Text.create(allocator, "Initial");
//! defer text.prototype.release();
//!
//! // Append text
//! try text.appendData(" content");
//! // text.data = "Initial content"
//!
//! // Insert text
//! try text.insertData(8, "new ");
//! // text.data = "Initial new content"
//!
//! // Delete text
//! try text.deleteData(8, 4);
//! // text.data = "Initial content"
//!
//! // Replace text
//! try text.replaceData(0, 7, "Final");
//! // text.data = "Final content"
//! ```
//!
//! ## Common Patterns
//!
//! ### Whitespace Normalization
//! ```zig
//! fn normalizeWhitespace(text: *Text) !void {
//!     const allocator = text.prototype.allocator;
//!     var normalized = std.ArrayList(u8).init(allocator);
//!     defer normalized.deinit();
//!
//!     var in_whitespace = false;
//!     for (text.data) |char| {
//!         if (std.ascii.isWhitespace(char)) {
//!             if (!in_whitespace) {
//!                 try normalized.append(' ');
//!                 in_whitespace = true;
//!             }
//!         } else {
//!             try normalized.append(char);
//!             in_whitespace = false;
//!         }
//!     }
//!
//!     // Replace with normalized text
//!     allocator.free(text.data);
//!     text.data = try normalized.toOwnedSlice();
//! }
//! ```
//!
//! ### Text Extraction
//! ```zig
//! fn getTextContent(node: *Node, allocator: Allocator) ![]u8 {
//!     var buffer = std.ArrayList(u8).init(allocator);
//!     defer buffer.deinit();
//!
//!     // Traverse tree and collect all text nodes
//!     var current = node.first_child;
//!     while (current) |child| : (current = child.next_sibling) {
//!         if (child.node_type == .text) {
//!             const text = @fieldParentPtr(Text, "node", child);
//!             try buffer.appendSlice(text.data);
//!         } else {
//!             const child_text = try getTextContent(child, allocator);
//!             defer allocator.free(child_text);
//!             try buffer.appendSlice(child_text);
//!         }
//!     }
//!
//!     return buffer.toOwnedSlice();
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Batch Modifications** - Use appendData/replaceData instead of multiple small changes
//! 2. **Avoid Frequent Splits** - splitText() allocates new nodes, use sparingly
//! 3. **String Interning** - Use Document.createTextNode() for repeated strings
//! 4. **Buffer Building** - For complex text assembly, use ArrayList then create once
//! 5. **Whitespace** - Remove unnecessary whitespace text nodes during parsing
//! 6. **Normalize Adjacent** - Merge adjacent text nodes for better tree structure
//! 7. **Read-Only Access** - Use text.data directly instead of substringData(0, length)
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // data (read-write) - CharacterData interface
//! Object.defineProperty(Text.prototype, 'data', {
//!   get: function() { return zig.text_get_data(this._ptr); },
//!   set: function(value) { zig.text_set_data(this._ptr, value); }
//! });
//!
//! // length (readonly) - CharacterData interface
//! Object.defineProperty(Text.prototype, 'length', {
//!   get: function() { return zig.text_get_length(this._ptr); }
//! });
//!
//! // wholeText (readonly)
//! Object.defineProperty(Text.prototype, 'wholeText', {
//!   get: function() { return zig.text_get_whole_text(this._ptr); }
//! });
//!
//! // Text inherits all Node properties (nodeType, nodeName, nodeValue, etc.)
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // CharacterData methods
//! Text.prototype.substringData = function(offset, count) {
//!   return zig.text_substringData(this._ptr, offset, count);
//! };
//!
//! Text.prototype.appendData = function(data) {
//!   zig.text_appendData(this._ptr, data);
//! };
//!
//! Text.prototype.insertData = function(offset, data) {
//!   zig.text_insertData(this._ptr, offset, data);
//! };
//!
//! Text.prototype.deleteData = function(offset, count) {
//!   zig.text_deleteData(this._ptr, offset, count);
//! };
//!
//! Text.prototype.replaceData = function(offset, count, data) {
//!   zig.text_replaceData(this._ptr, offset, count, data);
//! };
//!
//! // Text-specific methods
//! Text.prototype.splitText = function(offset) {
//!   return zig.text_splitText(this._ptr, offset);
//! };
//!
//! // Text inherits all Node methods (appendChild, etc.)
//! // Text inherits all EventTarget methods (addEventListener, etc.)
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - Text extends Node via struct embedding (node is first field)
//! - Text.data is owned by the Text node (allocated, must be freed)
//! - Node.nodeValue() returns text.data for text nodes
//! - Text nodes rarely have children (but spec allows it)
//! - nodeName is always "#text" for text nodes
//! - Text nodes cannot have attributes
//! - splitText() creates sibling, not child node
//! - CharacterData methods (appendData, etc.) are on Text struct directly

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;

/// Text node representing character data in the DOM.
///
/// Text nodes store mutable string content and provide methods for
/// character data manipulation (substring, append, insert, delete, replace).
///
/// ## Memory Layout
/// - Embeds Node as first field (for vtable polymorphism)
/// - Stores text data as owned string (allocated)
/// - Text content can be modified via nodeValue or data accessors
pub const Text = struct {
    /// Base Node (MUST be first field for @fieldParentPtr to work)
    prototype: Node,

    /// Text content (owned string, 16 bytes)
    /// Allocated and freed by this Text node
    data: []u8,

    /// Vtable for Text nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };

    /// Creates a new Text node with the specified content.
    ///
    /// ## Memory Management
    /// Returns Text with ref_count=1. Caller MUST call `text.prototype.release()`.
    /// Text content is duplicated and owned by the Text node.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    /// - `content`: Initial text content (will be duplicated)
    ///
    /// ## Returns
    /// New text node with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const text = try Text.create(allocator, "Hello World");
    /// defer text.prototype.release();
    /// ```
    pub fn create(allocator: Allocator, content: []const u8) !*Text {
        return createWithVTable(allocator, content, &vtable);
    }

    /// Creates a text node with a custom vtable (enables extensibility).
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `content`: Text content
    /// - `node_vtable`: Custom NodeVTable for polymorphic behavior
    ///
    /// ## Returns
    /// Text pointer with custom vtable installed
    pub fn createWithVTable(
        allocator: Allocator,
        content: []const u8,
        node_vtable: *const NodeVTable,
    ) !*Text {
        const text = try allocator.create(Text);
        errdefer allocator.destroy(text);

        // Duplicate text content (owned by this node)
        const data = try allocator.dupe(u8, content);
        errdefer allocator.free(data);

        // Initialize base Node
        text.prototype = .{
            .prototype = .{
                .vtable = &node_mod.eventtarget_vtable,
            },
            .vtable = node_vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .text,
            .flags = 0,
            .node_id = 0,
            .generation = 0,
            .allocator = allocator,
            .parent_node = null,
            .previous_sibling = null,
            .first_child = null,
            .last_child = null,
            .next_sibling = null,
            .owner_document = null,
            .rare_data = null,
        };

        // Initialize Text-specific fields
        text.data = data;

        return text;
    }

    /// Returns the text content length in bytes.
    pub fn length(self: *const Text) usize {
        return self.data.len;
    }

    /// Returns a substring of the text content.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for substring
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes (or null for rest of string)
    ///
    /// ## Returns
    /// Owned string slice. Caller must free with allocator.
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate substring
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn substringData(
        self: *const Text,
        allocator: Allocator,
        offset: usize,
        count: ?usize,
    ) ![]u8 {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = if (count) |c|
            @min(offset + c, self.data.len)
        else
            self.data.len;

        return allocator.dupe(u8, self.data[offset..end]);
    }

    /// Appends text to the end of the current content.
    ///
    /// ## Parameters
    /// - `text_to_append`: Text to append
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    pub fn appendData(self: *Text, text_to_append: []const u8) !void {
        const new_data = try std.mem.concat(
            self.prototype.allocator,
            u8,
            &[_][]const u8{ self.data, text_to_append },
        );

        self.prototype.allocator.free(self.data);
        self.data = new_data;
        self.prototype.generation += 1;
    }

    /// Inserts text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Byte offset where to insert
    /// - `text_to_insert`: Text to insert
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn insertData(self: *Text, offset: usize, text_to_insert: []const u8) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const new_data = try std.mem.concat(
            self.prototype.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], text_to_insert, self.data[offset..] },
        );

        self.prototype.allocator.free(self.data);
        self.data = new_data;
        self.prototype.generation += 1;
    }

    /// Deletes text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes to delete
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn deleteData(self: *Text, offset: usize, count: usize) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = @min(offset + count, self.data.len);

        const new_data = try std.mem.concat(
            self.prototype.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], self.data[end..] },
        );

        self.prototype.allocator.free(self.data);
        self.data = new_data;
        self.prototype.generation += 1;
    }

    /// Replaces text at the specified offset.
    ///
    /// ## Parameters
    /// - `offset`: Starting byte offset
    /// - `count`: Number of bytes to replace
    /// - `replacement`: Replacement text
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate new string
    /// - `error.IndexOutOfBounds`: Offset exceeds data length
    pub fn replaceData(
        self: *Text,
        offset: usize,
        count: usize,
        replacement: []const u8,
    ) !void {
        if (offset > self.data.len) {
            return error.IndexOutOfBounds;
        }

        const end = @min(offset + count, self.data.len);

        const new_data = try std.mem.concat(
            self.prototype.allocator,
            u8,
            &[_][]const u8{ self.data[0..offset], replacement, self.data[end..] },
        );

        self.prototype.allocator.free(self.data);
        self.data = new_data;
        self.prototype.generation += 1;
    }

    /// Splits this text node at the specified offset.
    ///
    /// Implements WHATWG DOM Text.splitText() per §4.10.1.
    ///
    /// ## WHATWG Specification
    /// - **Algorithm**: https://dom.spec.whatwg.org/#dom-text-splittext
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] Text splitText(unsigned long offset);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Text.splitText(): https://developer.mozilla.org/en-US/docs/Web/API/Text/splitText
    ///
    /// ## Behavior
    /// Splits the text node at the given offset, creating a new Text node containing
    /// the text after the offset. The original node is truncated to contain only the
    /// text before the offset.
    ///
    /// If the node has a parent, the new node is inserted as the next sibling of this node.
    ///
    /// ## Parameters
    /// - `offset`: The offset at which to split (0 to data.length)
    ///
    /// ## Returns
    /// The newly created Text node containing text after the offset
    ///
    /// ## Errors
    /// - `error.IndexSizeError`: Offset is greater than data length
    /// - `error.OutOfMemory`: Failed to allocate new text node or data
    ///
    /// ## Example
    /// ```zig
    /// const text = try doc.createTextNode("Hello World");
    /// _ = try parent.prototype.appendChild(&text.prototype);
    ///
    /// const second = try text.splitText(6);
    /// // text.data = "Hello "
    /// // second.data = "World"
    /// // second is now next sibling of text in parent
    /// ```
    ///
    /// ## Spec Notes
    /// The split happens BEFORE the character at offset. So splitText(0) creates
    /// an empty node and moves all text to the new node.
    pub fn splitText(self: *Text, offset: usize) !*Text {
        // Step 1: Validate offset
        if (offset > self.data.len) {
            return error.IndexSizeError;
        }

        // Step 2: Create new text node with text after offset
        // Text.create will dupe the content, so just pass the slice
        const new_text = try Text.create(self.prototype.allocator, self.data[offset..]);
        errdefer new_text.prototype.release();

        // Set owner document from the original text node's document
        // (following the same pattern as cloneNode)
        new_text.prototype.owner_document = self.prototype.owner_document;

        // Step 3: Truncate this node's data to before offset
        const truncated = try self.prototype.allocator.dupe(u8, self.data[0..offset]);
        self.prototype.allocator.free(self.data);
        self.data = truncated;

        // Step 4: If this node has a parent, insert new node after this one
        if (self.prototype.parent_node) |parent| {
            // Insert new_text after self
            _ = try parent.insertBefore(&new_text.prototype, self.prototype.next_sibling);
        }

        self.prototype.generation += 1;
        return new_text;
    }

    /// Returns the combined text of all adjacent text nodes.
    ///
    /// Implements WHATWG DOM Text.wholeText per §4.7.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute DOMString wholeText;
    /// ```
    ///
    /// ## MDN Documentation
    /// - wholeText: https://developer.mozilla.org/en-US/docs/Web/API/Text/wholeText
    ///
    /// ## Algorithm (from spec §4.7)
    /// Concatenate data of contiguous Text nodes (those that can be reached by traversing
    /// previous/next sibling Text nodes).
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-text-wholetext
    /// - WebIDL: dom.idl:459
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for the combined string
    ///
    /// ## Returns
    /// Combined text of all adjacent text nodes (caller must free)
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("div");
    /// const text1 = try doc.createTextNode("Hello");
    /// _ = try parent.prototype.appendChild(&text1.prototype);
    /// const text2 = try doc.createTextNode(" ");
    /// _ = try parent.prototype.appendChild(&text2.prototype);
    /// const text3 = try doc.createTextNode("World");
    /// _ = try parent.prototype.appendChild(&text3.prototype);
    ///
    /// const whole = try text2.wholeText(allocator);
    /// defer allocator.free(whole);
    /// // whole = "Hello World"
    /// ```
    pub fn wholeText(self: *const Text, allocator: Allocator) ![]const u8 {
        var list: std.ArrayList(u8) = .{};
        errdefer list.deinit(allocator);

        // Find the first text node in the contiguous sequence
        var first: *Node = @constCast(&self.prototype);
        while (first.previous_sibling) |prev| {
            if (prev.node_type == .text) {
                first = prev;
            } else {
                break;
            }
        }

        // Concatenate all contiguous text nodes
        var current: ?*Node = first;
        while (current) |node| {
            if (node.node_type == .text) {
                const text_node: *const Text = @fieldParentPtr("prototype", node);
                try list.appendSlice(allocator, text_node.data);
                current = node.next_sibling;
            } else {
                break;
            }
        }

        return try list.toOwnedSlice(allocator);
    }

    // ========================================================================
    // NonDocumentTypeChildNode Mixin (WHATWG DOM §4.2.7)
    // ========================================================================

    /// Returns the previous sibling that is an element.
    ///
    /// Implements WHATWG DOM NonDocumentTypeChildNode.previousElementSibling property.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? previousElementSibling;
    /// ```
    ///
    /// ## MDN Documentation
    /// - previousElementSibling: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/previousElementSibling
    ///
    /// ## Algorithm (from spec §4.2.7)
    /// Return the first preceding sibling of this that is an element, or null if there is no such sibling.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-previouselementsibling
    /// - WebIDL: dom.idl:138
    ///
    /// ## Returns
    /// Previous element sibling or null
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const elem = try doc.createElement("child");
    /// _ = try parent.prototype.appendChild(&elem.prototype);
    /// const text = try doc.createTextNode("text");
    /// _ = try parent.prototype.appendChild(&text.prototype);
    ///
    /// // text.previousElementSibling() returns elem
    /// try std.testing.expect(text.previousElementSibling() == elem);
    /// ```
    pub fn previousElementSibling(self: *const Text) ?*@import("element.zig").Element {
        var current = self.prototype.previous_sibling;
        while (current) |sibling| {
            if (sibling.node_type == .element) {
                return @fieldParentPtr("prototype", sibling);
            }
            current = sibling.previous_sibling;
        }
        return null;
    }

    /// Returns the next sibling that is an element.
    ///
    /// Implements WHATWG DOM NonDocumentTypeChildNode.nextElementSibling property.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? nextElementSibling;
    /// ```
    ///
    /// ## MDN Documentation
    /// - nextElementSibling: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/nextElementSibling
    ///
    /// ## Algorithm (from spec §4.2.7)
    /// Return the first following sibling of this that is an element, or null if there is no such sibling.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-nextelementsibling
    /// - WebIDL: dom.idl:139
    ///
    /// ## Returns
    /// Next element sibling or null
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const text = try doc.createTextNode("text");
    /// _ = try parent.prototype.appendChild(&text.prototype);
    /// const elem = try doc.createElement("child");
    /// _ = try parent.prototype.appendChild(&elem.prototype);
    ///
    /// // text.nextElementSibling() returns elem
    /// try std.testing.expect(text.nextElementSibling() == elem);
    /// ```
    pub fn nextElementSibling(self: *const Text) ?*@import("element.zig").Element {
        var current = self.prototype.next_sibling;
        while (current) |sibling| {
            if (sibling.node_type == .element) {
                return @fieldParentPtr("prototype", sibling);
            }
            current = sibling.next_sibling;
        }
        return null;
    }

    // ========================================================================
    // Slottable Mixin
    // ========================================================================

    /// Returns the slot element this text node is assigned to.
    ///
    /// ## WHATWG Specification
    /// - **Slottable mixin**: https://dom.spec.whatwg.org/#mixin-slottable
    ///
    /// ## WebIDL
    /// ```webidl
    /// interface mixin Slottable {
    ///   readonly attribute HTMLSlotElement? assignedSlot;
    /// };
    /// Text includes Slottable;
    /// ```
    ///
    /// ## MDN Documentation
    /// - Text nodes can be assigned to slots just like elements
    ///
    /// ## Returns
    /// The slot element (tag name "slot") this text node is assigned to, or null
    ///
    /// ## Note
    /// In a generic DOM library, we return Element (not HTMLSlotElement).
    /// HTML libraries can extend this to return HTMLSlotElement specifically.
    pub fn assignedSlot(self: *const Text) ?*@import("element.zig").Element {
        const Element = @import("element.zig").Element;

        // Check if rare data exists
        const rare_data = self.prototype.rare_data orelse return null;

        // Check if assigned slot exists
        const slot_ptr = rare_data.assigned_slot orelse return null;

        // Cast to Element (slot is just an Element with tag name "slot")
        const slot: *Element = @ptrCast(@alignCast(slot_ptr));
        return slot;
    }

    /// Sets the assigned slot for this text node (internal use).
    ///
    /// ## Parameters
    /// - `slot`: The slot element to assign this text node to (or null to clear)
    ///
    /// ## Note
    /// This is called internally during slot assignment. Users should not call this directly.
    pub fn setAssignedSlot(self: *Text, slot: ?*@import("element.zig").Element) !void {
        if (slot == null) {
            // Clear assigned slot
            if (self.prototype.rare_data) |rare_data| {
                rare_data.assigned_slot = null;
            }
            return;
        }

        // Ensure rare data exists
        const rare_data = try self.prototype.ensureRareData();

        // Set assigned slot (WEAK reference)
        rare_data.assigned_slot = @ptrCast(slot.?);
    }

    // ========================================================================
    // ChildNode Mixin (WHATWG DOM §4.2.8)
    // ========================================================================

    /// NodeOrString union for ChildNode variadic methods.
    ///
    /// Represents the WebIDL `(Node or DOMString)` union type.
    pub const NodeOrString = union(enum) {
        node: *Node,
        string: []const u8,
    };

    /// Removes this text node from its parent.
    ///
    /// Implements WHATWG DOM ChildNode.remove() per §4.2.8.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined remove();
    /// ```
    ///
    /// ## MDN Documentation
    /// - remove(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/remove
    ///
    /// ## Algorithm (from spec §4.2.8)
    /// If this's parent is null, return. Otherwise, remove this from its parent.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-remove
    /// - WebIDL: dom.idl:148
    pub fn remove(self: *Text) !void {
        if (self.prototype.parent_node) |parent| {
            _ = try parent.removeChild(&self.prototype);
        }
    }

    /// Inserts nodes before this text node.
    ///
    /// Implements WHATWG DOM ChildNode.before() per §4.2.8.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined before((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - before(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/before
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-before
    /// - WebIDL: dom.idl:145
    pub fn before(self: *Text, nodes: []const NodeOrString) !void {
        const parent = self.prototype.parent_node orelse return;

        const result = try convertNodesToNode(&self.prototype, nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try parent.insertBefore(node_to_insert, &self.prototype);

        if (should_release) {
            returned_node.release();
        }
    }

    /// Inserts nodes after this text node.
    ///
    /// Implements WHATWG DOM ChildNode.after() per §4.2.8.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined after((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - after(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/after
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-after
    /// - WebIDL: dom.idl:146
    pub fn after(self: *Text, nodes: []const NodeOrString) !void {
        const parent = self.prototype.parent_node orelse return;

        const result = try convertNodesToNode(&self.prototype, nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try parent.insertBefore(node_to_insert, self.prototype.next_sibling);

        if (should_release) {
            returned_node.release();
        }
    }

    /// Replaces this text node with other nodes.
    ///
    /// Implements WHATWG DOM ChildNode.replaceWith() per §4.2.8.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined replaceWith((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - replaceWith(): https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/replaceWith
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-replacewith
    /// - WebIDL: dom.idl:147
    pub fn replaceWith(self: *Text, nodes: []const NodeOrString) !void {
        const parent = self.prototype.parent_node orelse return;

        const result = try convertNodesToNode(&self.prototype, nodes);

        if (result) |r| {
            _ = try parent.replaceChild(r.node, &self.prototype);
            if (r.should_release_after_insert) {
                r.prototype.release();
            }
        } else {
            _ = try parent.removeChild(&self.prototype);
        }
    }

    /// Result of converting nodes/strings
    const ConvertResult = struct {
        node: *Node,
        should_release_after_insert: bool,
    };

    /// Helper: Convert slice of nodes/strings into a single node.
    fn convertNodesToNode(parent: *Node, items: []const NodeOrString) !?ConvertResult {
        if (items.len == 0) return null;

        const owner_doc = parent.owner_document orelse {
            return error.InvalidStateError;
        };

        const Document = @import("document.zig").Document;
        if (owner_doc.node_type != .document) {
            return error.InvalidStateError;
        }
        const doc: *Document = @fieldParentPtr("prototype", owner_doc);

        if (items.len == 1) {
            switch (items[0]) {
                .node => |n| {
                    return ConvertResult{
                        .node = n,
                        .should_release_after_insert = false,
                    };
                },
                .string => |s| {
                    const text = try doc.createTextNode(s);
                    return ConvertResult{
                        .node = &text.prototype,
                        .should_release_after_insert = false,
                    };
                },
            }
        }

        const fragment = try doc.createDocumentFragment();
        errdefer fragment.prototype.release();

        for (items) |item| {
            switch (item) {
                .node => |n| {
                    _ = try fragment.prototype.appendChild(n);
                },
                .string => |s| {
                    const text = try doc.createTextNode(s);
                    _ = try fragment.prototype.appendChild(&text.prototype);
                },
            }
        }

        return ConvertResult{
            .node = &fragment.prototype,
            .should_release_after_insert = true,
        };
    }

    // === Private vtable implementations ===

    /// Vtable implementation: adopting steps (no-op for Text)
    ///
    /// Text nodes own their data, so no re-interning is needed during adoption.
    fn adoptingStepsImpl(_: *Node, _: ?*Node) !void {
        // No-op: Text data is already owned by the node
    }

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const text: *Text = @fieldParentPtr("prototype", node);

        // Release document reference if owned by a document
        if (text.prototype.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                // Get Document from its node field (node is first field)
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner_doc);
                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        text.prototype.deinitRareData();

        text.prototype.allocator.free(text.data);
        text.prototype.allocator.destroy(text);
    }

    /// Vtable implementation: node name (always "#text")
    fn nodeNameImpl(_: *const Node) []const u8 {
        return "#text";
    }

    /// Vtable implementation: node value (returns text content)
    fn nodeValueImpl(node: *const Node) ?[]const u8 {
        const text: *const Text = @fieldParentPtr("prototype", node);
        return text.data;
    }

    /// Vtable implementation: set node value (updates text content)
    fn setNodeValueImpl(node: *Node, value: []const u8) !void {
        const text: *Text = @fieldParentPtr("prototype", node);

        // Allocate new content
        const new_data = try node.allocator.dupe(u8, value);

        // Free old and replace
        node.allocator.free(text.data);
        text.data = new_data;
        node.generation += 1;
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        const text: *const Text = @fieldParentPtr("prototype", node);

        // Text nodes have no children, so deep is ignored
        _ = deep;

        // Create new text with same content
        const cloned = try Text.create(node.allocator, text.data);

        // Preserve owner document (WHATWG DOM §4.5.1 Clone algorithm)
        cloned.prototype.owner_document = text.prototype.owner_document;

        return &cloned.prototype;
    }

    /// Internal: Clones text using a specific allocator.
    ///
    /// Used by `Document.importNode()` to clone text nodes into a different
    /// document's allocator.
    ///
    /// ## Parameters
    /// - `text`: The text node to clone
    /// - `allocator`: The allocator to use for the cloned text node
    ///
    /// ## Returns
    /// A new cloned text node allocated with the specified allocator
    pub fn cloneWithAllocator(text: *const Text, allocator: Allocator) Allocator.Error!*Node {
        // Create new text with same content using the provided allocator
        const cloned = try Text.create(allocator, text.data);

        // Preserve owner document (will be updated by adopt())
        cloned.prototype.owner_document = text.prototype.owner_document;

        return &cloned.prototype;
    }
};

