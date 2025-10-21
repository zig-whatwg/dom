//! CDATASection Interface (§4.9)
//!
//! This module implements the CDATASection interface as specified by the WHATWG DOM Standard.
//! CDATASection is a specialized type of Text node used to represent CDATA sections in XML documents.
//! CDATA sections allow text that would otherwise be recognized as markup to be treated as character data.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.9 Interface CDATASection**: https://dom.spec.whatwg.org/#interface-cdatasection
//! - **§4.7 Interface Text**: https://dom.spec.whatwg.org/#interface-text (base)
//! - **§4.8 Interface CharacterData**: https://dom.spec.whatwg.org/#interface-characterdata (ancestor)
//!
//! ## WebIDL
//!
//! ```webidl
//! [Exposed=Window]
//! interface CDATASection : Text {
//! };
//! ```
//!
//! ## MDN Documentation
//!
//! - CDATASection: https://developer.mozilla.org/en-US/docs/Web/API/CDATASection
//! - CDATA sections: https://developer.mozilla.org/en-US/docs/Web/API/CDATASection#what_is_a_cdata_section
//!
//! ## Core Features
//!
//! ### CDATA Section Purpose
//! CDATA sections are used in XML to include text that might contain characters
//! that would otherwise be treated as markup (like `<`, `>`, `&`):
//! ```xml
//! <script>
//!   <![CDATA[
//!     if (a < b && b > c) {
//!       // This is valid inside CDATA
//!     }
//!   ]]>
//! </script>
//! ```
//!
//! ### Creating CDATA Sections
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const cdata = try doc.createCDATASection("x < y && y > z");
//! defer cdata.prototype.prototype.release();
//! ```
//!
//! ### CDATA vs Text Nodes
//! CDATASection inherits all Text node functionality:
//! ```zig
//! const cdata = try doc.createCDATASection("content");
//! defer cdata.prototype.prototype.release();
//!
//! // All Text methods work
//! try cdata.prototype.appendData(" more");
//! const substring = try cdata.prototype.substringData(allocator, 0, 7);
//! defer allocator.free(substring);
//!
//! // Node properties show CDATA type
//! const node_type = cdata.prototype.prototype.node_type; // .cdata_section
//! const node_name = cdata.prototype.prototype.vtable.node_name(&cdata.prototype.prototype); // "#cdata-section"
//! ```
//!
//! ## Node Structure
//!
//! CDATASection is a type alias to Text with a different node_type:
//! - **prototype**: Base Text struct (MUST be first field for @fieldParentPtr)
//! - Inherits all Text functionality (data storage, manipulation methods)
//! - Distinguished by node_type = .cdata_section
//! - nodeName = "#cdata-section"
//!
//! ## Memory Management
//!
//! CDATASection uses the same reference counting as Text nodes:
//! ```zig
//! const cdata = try doc.createCDATASection("Example");
//! defer cdata.prototype.prototype.release(); // Note: prototype.prototype (Text.node)
//!
//! // When sharing ownership:
//! cdata.prototype.prototype.acquire(); // Increment ref_count
//! other_structure.cdata_node = &cdata.prototype.prototype;
//! ```
//!
//! ## Usage Examples
//!
//! ### Creating CDATA Sections
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! // Create CDATA section (RECOMMENDED - via Document)
//! const cdata = try doc.createCDATASection("x < y");
//! defer cdata.prototype.prototype.release();
//!
//! // Direct creation (for tests)
//! const cdata2 = try CDATASection.create(allocator, "a && b");
//! defer cdata2.prototype.prototype.release();
//! ```
//!
//! ### Adding to Document Tree
//! ```zig
//! const element = try doc.createElement("script");
//! const cdata = try doc.createCDATASection("if (x < y) { }");
//!
//! _ = try element.prototype.appendChild(&cdata.prototype.prototype);
//! // <script><![CDATA[if (x < y) { }]]></script>
//! ```
//!
//! ### Manipulating CDATA Content
//! ```zig
//! const cdata = try doc.createCDATASection("Initial");
//! defer cdata.prototype.prototype.release();
//!
//! // Use all Text methods
//! try cdata.prototype.appendData(" content");
//! try cdata.prototype.insertData(8, " new");
//! try cdata.prototype.deleteData(0, 8);
//!
//! // Access data
//! const content = cdata.prototype.data; // "new content"
//! ```
//!
//! ## Common Patterns
//!
//! ### XML Document with CDATA
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const root = try doc.createElement("root");
//! _ = try doc.appendChild(&root.prototype);
//!
//! const script = try doc.createElement("script");
//! _ = try root.prototype.appendChild(&script.prototype);
//!
//! const cdata = try doc.createCDATASection("if (a < b && c > d) { }");
//! _ = try script.prototype.appendChild(&cdata.prototype.prototype);
//! ```
//!
//! ### Extracting CDATA Content
//! ```zig
//! fn getCDATAContent(node: *Node, allocator: Allocator) !?[]u8 {
//!     if (node.node_type != .cdata_section) return null;
//!
//!     const cdata = @fieldParentPtr(CDATASection, "prototype",
//!         @fieldParentPtr(Text, "prototype", node));
//!     return allocator.dupe(u8, cdata.prototype.data);
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Same as Text Nodes** - CDATASection has identical performance to Text
//! 2. **Document Factory** - Use createCDATASection() for string interning
//! 3. **Batch Modifications** - Use appendData/replaceData for efficiency
//! 4. **Type Checking** - Use node_type == .cdata_section to identify
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // CDATASection inherits ALL Text properties
//! // data (read-write) - CharacterData interface
//! Object.defineProperty(CDATASection.prototype, 'data', {
//!   get: function() { return zig.text_get_data(this._ptr); },
//!   set: function(value) { zig.text_set_data(this._ptr, value); }
//! });
//!
//! // length (readonly) - CharacterData interface
//! Object.defineProperty(CDATASection.prototype, 'length', {
//!   get: function() { return zig.text_get_length(this._ptr); }
//! });
//!
//! // nodeType returns CDATA_SECTION_NODE (4)
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // CDATASection inherits ALL Text/CharacterData methods
//! CDATASection.prototype.substringData = function(offset, count) {
//!   return zig.text_substringData(this._ptr, offset, count);
//! };
//!
//! CDATASection.prototype.appendData = function(data) {
//!   zig.text_appendData(this._ptr, data);
//! };
//!
//! CDATASection.prototype.splitText = function(offset) {
//!   return zig.text_splitText(this._ptr, offset);
//! };
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - CDATASection is a type alias to Text, not a separate struct
//! - Distinguished only by node_type (.cdata_section) and nodeName ("#cdata-section")
//! - Inherits all Text behavior and methods
//! - Used primarily in XML documents, rare in HTML
//! - CDATA sections are NOT parsed in HTML5 documents
//! - In XML, content between `<![CDATA[` and `]]>` becomes CDATASection nodes
//! - All character data methods work identically to Text
//! - Splitting a CDATA section (splitText) creates another CDATA section
//!
//! ## XML-Specific Behavior
//!
//! ### CDATA Section Restrictions
//! According to XML specification:
//! - Content MUST NOT contain the string `]]>`
//! - CDATA sections CANNOT be nested
//! - CDATA sections are NOT valid in HTML documents
//!
//! ### Serialization
//! When serializing to XML, CDATA content should be wrapped:
//! ```xml
//! <script><![CDATA[content here]]></script>
//! ```
//!
//! This library does NOT enforce XML restrictions (generic DOM implementation).
//! XML validation and serialization is left to higher-level libraries.

const std = @import("std");
const Allocator = std.mem.Allocator;
const text_mod = @import("text.zig");
const Text = text_mod.Text;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeVTable = node_mod.NodeVTable;
const Event = @import("event.zig").Event;
const EventCallback = @import("event_target.zig").EventCallback;

/// CDATASection node representing CDATA sections in XML documents.
///
/// CDATASection is identical to Text except for node_type and nodeName.
/// It inherits all Text functionality (data storage, manipulation methods).
///
/// ## Memory Layout
/// - Wraps Text struct (for polymorphism)
/// - Text embeds Node as first field
/// - Identified by node_type = .cdata_section
pub const CDATASection = struct {
    /// Base Text (MUST be first field for @fieldParentPtr to work)
    prototype: Text,

    /// Vtable for CDATASection nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };

    // ================================================================
    // Convenience Methods - Text/Node/EventTarget API Delegation (3 levels)
    // ================================================================
    // CDATASection → Text → Node → EventTarget

    // Text methods (via .prototype)
    pub inline fn getData(self: *const CDATASection) []const u8 {
        return self.prototype.data;
    }
    pub inline fn setData(self: *CDATASection, data: []const u8) !void {
        return try self.prototype.setData(data);
    }
    pub inline fn appendData(self: *CDATASection, data: []const u8) !void {
        return try self.prototype.appendData(data);
    }

    // Node methods (via .prototype.prototype)
    pub inline fn parentNode(self: *const CDATASection) ?*Node {
        return self.prototype.prototype.parent_node;
    }
    pub inline fn nextSibling(self: *const CDATASection) ?*Node {
        return self.prototype.prototype.next_sibling;
    }
    pub inline fn previousSibling(self: *const CDATASection) ?*Node {
        return self.prototype.prototype.previous_sibling;
    }
    pub inline fn isConnected(self: *const CDATASection) bool {
        return self.prototype.prototype.isConnected();
    }
    pub inline fn cloneNode(self: *const CDATASection, deep: bool) !*Node {
        return try self.prototype.prototype.cloneNode(deep);
    }

    // EventTarget methods (via .prototype.prototype.prototype)
    pub inline fn addEventListener(
        self: *CDATASection,
        event_type: []const u8,
        callback: EventCallback,
        context: *anyopaque,
        capture: bool,
        once: bool,
        passive: bool,
        signal: ?*anyopaque,
    ) !void {
        return try self.prototype.prototype.prototype.addEventListener(event_type, callback, context, capture, once, passive, signal);
    }
    pub inline fn removeEventListener(self: *CDATASection, event_type: []const u8, callback: EventCallback, capture: bool) void {
        self.prototype.prototype.prototype.removeEventListener(event_type, callback, capture);
    }
    pub inline fn dispatchEvent(self: *CDATASection, event: *Event) !bool {
        return try self.prototype.prototype.prototype.dispatchEvent(event);
    }

    /// Creates a new CDATASection node with the specified content.
    ///
    /// ## Memory Management
    /// Returns CDATASection with ref_count=1. Caller MUST call `cdata.prototype.prototype.release()`.
    /// CDATA content is duplicated and owned by the node.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    /// - `content`: Initial CDATA content (will be duplicated)
    ///
    /// ## Returns
    /// New CDATA section node with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const cdata = try CDATASection.create(allocator, "x < y && y > z");
    /// defer cdata.prototype.prototype.release();
    /// ```
    pub fn create(allocator: Allocator, content: []const u8) !*CDATASection {
        const cdata = try allocator.create(CDATASection);
        errdefer allocator.destroy(cdata);

        // Duplicate content (owned by this node)
        const data = try allocator.dupe(u8, content);
        errdefer allocator.free(data);

        // Initialize base Node (via Text)
        cdata.prototype = .{
            .prototype = .{
                .prototype = .{
                    .vtable = &node_mod.eventtarget_vtable,
                },
                .vtable = &vtable,
                .ref_count_and_parent = std.atomic.Value(u32).init(1),
                .node_type = .cdata_section, // DIFFERENT from Text
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
            },
            .data = data,
        };

        return cdata;
    }

    // -------------------------------------------------------------------------
    // Node VTable Implementation
    // -------------------------------------------------------------------------

    fn deinitImpl(node: *Node) void {
        const text: *Text = @fieldParentPtr("prototype", node);
        const cdata: *CDATASection = @fieldParentPtr("prototype", text);
        node.allocator.free(cdata.prototype.data);
        node.allocator.destroy(cdata);
    }

    fn nodeNameImpl(_: *const Node) []const u8 {
        return "#cdata-section"; // DIFFERENT from Text's "#text"
    }

    fn nodeValueImpl(node: *const Node) ?[]const u8 {
        const text: *const Text = @fieldParentPtr("prototype", node);
        const cdata: *const CDATASection = @fieldParentPtr("prototype", text);
        return cdata.prototype.data;
    }

    fn setNodeValueImpl(node: *Node, new_value: []const u8) !void {
        const text: *Text = @fieldParentPtr("prototype", node);
        const cdata: *CDATASection = @fieldParentPtr("prototype", text);

        // Capture old value for mutation observers
        const old_value = try node.allocator.dupe(u8, cdata.prototype.data);
        defer node.allocator.free(old_value);

        // Replace data
        const data = try node.allocator.dupe(u8, new_value);

        node.allocator.free(cdata.prototype.data);
        cdata.prototype.data = data;
        node.generation += 1;

        // Queue mutation record for characterData
        node_mod.queueMutationRecord(
            node,
            "characterData",
            null, // added_nodes
            null, // removed_nodes
            null, // previous_sibling
            null, // next_sibling
            null, // attribute_name
            null, // attribute_namespace
            old_value, // old_value
        ) catch {}; // Best effort
    }

    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        _ = deep; // CDATA sections don't typically have children, but copy them if present

        const text: *const Text = @fieldParentPtr("prototype", node);
        const cdata: *const CDATASection = @fieldParentPtr("prototype", text);

        // Create new CDATA section with same content
        const new_cdata = try CDATASection.create(node.allocator, cdata.prototype.data);

        // Copy owner document
        new_cdata.prototype.prototype.owner_document = node.owner_document;

        return &new_cdata.prototype.prototype;
    }

    fn adoptingStepsImpl(_: *Node, _: ?*Node) !void {
        // No special adoption steps for CDATA sections
    }

    // -------------------------------------------------------------------------
    // Public Methods
    // -------------------------------------------------------------------------

    /// Splits this CDATA section at the specified offset.
    ///
    /// Implements WHATWG DOM Text.splitText() but returns CDATASection instead of Text.
    ///
    /// ## WHATWG Specification
    /// - **Algorithm**: https://dom.spec.whatwg.org/#dom-text-splittext
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] Text splitText(unsigned long offset);
    /// ```
    ///
    /// ## Behavior
    /// Splits the CDATA section at the given offset, creating a new CDATASection node
    /// containing the text after the offset. The original node is truncated to contain
    /// only the text before the offset.
    ///
    /// If the node has a parent, the new node is inserted as the next sibling of this node.
    ///
    /// ## Parameters
    /// - `offset`: The offset at which to split (0 to data.length)
    ///
    /// ## Returns
    /// The newly created CDATASection node containing text after the offset
    ///
    /// ## Errors
    /// - `error.IndexSizeError`: Offset is greater than data length
    /// - `error.OutOfMemory`: Failed to allocate new node or data
    ///
    /// ## Example
    /// ```zig
    /// const cdata = try doc.createCDATASection("Hello World");
    /// _ = try parent.prototype.appendChild(&cdata.prototype.prototype);
    ///
    /// const second = try cdata.splitText(6);
    /// // cdata.prototype.data = "Hello "
    /// // second.prototype.data = "World"
    /// // second is now next sibling of cdata in parent
    /// ```
    pub fn splitText(self: *CDATASection, offset: usize) !*CDATASection {
        // Step 1: Validate offset
        if (offset > self.prototype.data.len) {
            return error.IndexSizeError;
        }

        // Step 2: Create new CDATA section with text after offset
        const new_cdata = try CDATASection.create(
            self.prototype.prototype.allocator,
            self.prototype.data[offset..],
        );
        errdefer new_cdata.prototype.prototype.release();

        // Set owner document from the original CDATA section's document
        new_cdata.prototype.prototype.owner_document = self.prototype.prototype.owner_document;

        // Step 3: Truncate this node's data to before offset
        const truncated = try self.prototype.prototype.allocator.dupe(u8, self.prototype.data[0..offset]);
        self.prototype.prototype.allocator.free(self.prototype.data);
        self.prototype.data = truncated;

        // Step 4: If this node has a parent, insert new node after this one
        if (self.prototype.prototype.parent_node) |parent| {
            // Insert new_cdata after self
            _ = try parent.insertBefore(&new_cdata.prototype.prototype, self.prototype.prototype.next_sibling);
        }

        self.prototype.prototype.generation += 1;
        return new_cdata;
    }
};

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------

const testing = std.testing;
