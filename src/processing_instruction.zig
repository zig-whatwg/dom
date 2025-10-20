//! ProcessingInstruction Interface (§4.9)
//!
//! This module implements the ProcessingInstruction interface as specified by the WHATWG DOM Standard.
//! ProcessingInstructions are used in XML to provide instructions to applications processing the document.
//! They consist of a target (the application name) and data (instructions for that application).
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.9 Interface ProcessingInstruction**: https://dom.spec.whatwg.org/#interface-processinginstruction
//! - **§4.8 Interface CharacterData**: https://dom.spec.whatwg.org/#interface-characterdata (base)
//!
//! ## WebIDL
//!
//! ```webidl
//! [Exposed=Window]
//! interface ProcessingInstruction : CharacterData {
//!   readonly attribute DOMString target;
//! };
//! ```
//!
//! ## MDN Documentation
//!
//! - ProcessingInstruction: https://developer.mozilla.org/en-US/docs/Web/API/ProcessingInstruction
//! - Processing instructions in XML: https://developer.mozilla.org/en-US/docs/Web/API/ProcessingInstruction#what_is_a_processing_instruction
//!
//! ## Core Features
//!
//! ### Processing Instruction Purpose
//! Processing instructions are used in XML to embed application-specific instructions:
//! ```xml
//! <?xml version="1.0" encoding="UTF-8"?>
//! <?xml-stylesheet type="text/css" href="style.css"?>
//! <document>
//!   <?custom-app instruction="value"?>
//! </document>
//! ```
//!
//! ### Creating Processing Instructions
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const pi = try doc.createProcessingInstruction("xml-stylesheet", "type=\"text/css\" href=\"style.css\"");
//! defer pi.prototype.prototype.release();
//! ```
//!
//! ### Target and Data
//! The target identifies the application, and data contains the instructions:
//! ```zig
//! const pi = try doc.createProcessingInstruction("xml-stylesheet", "type=\"text/css\"");
//! defer pi.prototype.prototype.release();
//!
//! // Access target and data
//! const target = pi.target; // "xml-stylesheet"
//! const data = pi.prototype.data; // "type=\"text/css\""
//!
//! // Modify data (target is readonly)
//! try pi.prototype.appendData(" href=\"style.css\"");
//! // data is now: "type=\"text/css\" href=\"style.css\""
//! ```
//!
//! ## Node Structure
//!
//! ProcessingInstruction wraps Text with an additional target field:
//! - **prototype**: Base Text struct (for CharacterData methods)
//! - **target**: Target application name (readonly, owned string)
//! - Distinguished by node_type = .processing_instruction
//! - nodeName = target (not "#processing-instruction")
//!
//! ## Memory Management
//!
//! ProcessingInstruction uses reference counting through Node interface:
//! ```zig
//! const pi = try doc.createProcessingInstruction("xml", "version=\"1.0\"");
//! defer pi.prototype.prototype.release(); // Note: prototype.prototype (Text.node)
//!
//! // When sharing ownership:
//! pi.prototype.prototype.acquire(); // Increment ref_count
//! other_structure.pi_node = &pi.prototype.prototype;
//! ```
//!
//! When released (ref_count reaches 0):
//! 1. Target string is freed
//! 2. Data string is freed
//! 3. Node base is freed
//!
//! ## Usage Examples
//!
//! ### Creating Processing Instructions
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! // XML declaration (RECOMMENDED - via Document)
//! const xml_decl = try doc.createProcessingInstruction("xml", "version=\"1.0\" encoding=\"UTF-8\"");
//! defer xml_decl.prototype.prototype.release();
//!
//! // Stylesheet link
//! const stylesheet = try doc.createProcessingInstruction("xml-stylesheet", "type=\"text/css\" href=\"style.css\"");
//! defer stylesheet.prototype.prototype.release();
//! ```
//!
//! ### Adding to Document Tree
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const pi = try doc.createProcessingInstruction("xml-stylesheet", "type=\"text/css\"");
//! _ = try doc.prototype.appendChild(&pi.prototype.prototype);
//! // Document now has PI as child
//! ```
//!
//! ### Manipulating Data
//! ```zig
//! const pi = try doc.createProcessingInstruction("app", "setting=1");
//! defer pi.prototype.prototype.release();
//!
//! // Use all Text/CharacterData methods
//! try pi.prototype.appendData(" flag=true");
//! try pi.prototype.insertData(0, "version=2 ");
//!
//! // Access data
//! const data = pi.prototype.data; // "version=2 setting=1 flag=true"
//! const target = pi.target; // "app"
//! ```
//!
//! ## Common Patterns
//!
//! ### XML Document with Processing Instructions
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! // Add XML declaration
//! const xml_decl = try doc.createProcessingInstruction("xml", "version=\"1.0\"");
//! _ = try doc.prototype.appendChild(&xml_decl.prototype.prototype);
//!
//! // Add stylesheet
//! const stylesheet = try doc.createProcessingInstruction("xml-stylesheet", "href=\"style.css\"");
//! _ = try doc.prototype.appendChild(&stylesheet.prototype.prototype);
//!
//! // Add root element
//! const root = try doc.createElement("root");
//! _ = try doc.prototype.appendChild(&root.prototype);
//! ```
//!
//! ### Extracting PI Data
//! ```zig
//! fn getProcessingInstructionData(node: *Node, allocator: Allocator) !?[]u8 {
//!     if (node.node_type != .processing_instruction) return null;
//!
//!     const text: *Text = @fieldParentPtr("prototype", node);
//!     const pi: *ProcessingInstruction = @fieldParentPtr("prototype", text);
//!     return allocator.dupe(u8, pi.prototype.data);
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Same as Text Nodes** - ProcessingInstruction has identical performance to Text
//! 2. **Document Factory** - Use createProcessingInstruction() for string interning
//! 3. **Batch Modifications** - Use appendData/replaceData for efficiency
//! 4. **Type Checking** - Use node_type == .processing_instruction to identify
//! 5. **Target is Readonly** - Target cannot be changed after creation
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // target (readonly)
//! Object.defineProperty(ProcessingInstruction.prototype, 'target', {
//!   get: function() { return zig.pi_get_target(this._ptr); }
//! });
//!
//! // ProcessingInstruction inherits ALL CharacterData properties
//! // data (read-write) - CharacterData interface
//! Object.defineProperty(ProcessingInstruction.prototype, 'data', {
//!   get: function() { return zig.text_get_data(this._ptr); },
//!   set: function(value) { zig.text_set_data(this._ptr, value); }
//! });
//!
//! // nodeType returns PROCESSING_INSTRUCTION_NODE (7)
//! // nodeName returns the target (e.g., "xml", "xml-stylesheet")
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // ProcessingInstruction inherits ALL CharacterData methods
//! ProcessingInstruction.prototype.substringData = function(offset, count) {
//!   return zig.text_substringData(this._ptr, offset, count);
//! };
//!
//! ProcessingInstruction.prototype.appendData = function(data) {
//!   zig.text_appendData(this._ptr, data);
//! };
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - ProcessingInstruction wraps Text struct with additional target field
//! - Distinguished by node_type (.processing_instruction) and nodeName (target)
//! - Inherits all Text/CharacterData behavior and methods
//! - Target is readonly after creation (per spec)
//! - Used primarily in XML documents, NOT in HTML
//! - HTML5 parsers do NOT create ProcessingInstruction nodes
//! - nodeName returns target, NOT "#processing-instruction"
//! - All character data methods work identically to Text
//!
//! ## XML-Specific Behavior
//!
//! ### Processing Instruction Restrictions
//! According to XML specification:
//! - Target MUST NOT be "xml" (case-insensitive) except for XML declaration
//! - Data MUST NOT contain the string `?>`
//! - Processing instructions are NOT valid in HTML documents
//!
//! ### Common Targets
//! - `xml` - XML declaration (version, encoding, standalone)
//! - `xml-stylesheet` - Stylesheet association
//! - Custom application names
//!
//! This library does NOT enforce XML restrictions (generic DOM implementation).
//! XML validation is left to higher-level libraries.

const std = @import("std");
const Allocator = std.mem.Allocator;
const text_mod = @import("text.zig");
const Text = text_mod.Text;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeVTable = node_mod.NodeVTable;

/// ProcessingInstruction node representing processing instructions in XML documents.
///
/// ProcessingInstruction wraps Text with an additional target field.
/// It inherits all Text functionality (data storage, manipulation methods).
///
/// ## Memory Layout
/// - Wraps Text struct (for CharacterData methods)
/// - Adds target field (readonly after creation)
/// - Identified by node_type = .processing_instruction
pub const ProcessingInstruction = struct {
    /// Base Text (MUST be first field for @fieldParentPtr to work)
    prototype: Text,

    /// Target application name (readonly, owned string)
    /// e.g., "xml", "xml-stylesheet", or custom application name
    target: []const u8,

    /// Vtable for ProcessingInstruction nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };

    /// Creates a new ProcessingInstruction node with the specified target and data.
    ///
    /// ## Memory Management
    /// Returns ProcessingInstruction with ref_count=1. Caller MUST call `pi.prototype.prototype.release()`.
    /// Target and data are duplicated and owned by the node.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    /// - `target_name`: Target application name (will be duplicated)
    /// - `data`: Instruction data (will be duplicated)
    ///
    /// ## Returns
    /// New processing instruction node with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const pi = try ProcessingInstruction.create(allocator, "xml-stylesheet", "type=\"text/css\"");
    /// defer pi.prototype.prototype.release();
    /// ```
    pub fn create(allocator: Allocator, target_name: []const u8, data: []const u8) !*ProcessingInstruction {
        const pi = try allocator.create(ProcessingInstruction);
        errdefer allocator.destroy(pi);

        // Duplicate target (owned by this node)
        const target = try allocator.dupe(u8, target_name);
        errdefer allocator.free(target);

        // Duplicate data (owned by this node)
        const data_copy = try allocator.dupe(u8, data);
        errdefer allocator.free(data_copy);

        // Initialize base Node (via Text)
        pi.prototype = .{
            .prototype = .{
                .prototype = .{
                    .vtable = &node_mod.eventtarget_vtable,
                },
                .vtable = &vtable,
                .ref_count_and_parent = std.atomic.Value(u32).init(1),
                .node_type = .processing_instruction,
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
            .data = data_copy,
        };
        pi.target = target;

        return pi;
    }

    // -------------------------------------------------------------------------
    // Node VTable Implementation
    // -------------------------------------------------------------------------

    fn deinitImpl(node: *Node) void {
        const text: *Text = @fieldParentPtr("prototype", node);
        const pi: *ProcessingInstruction = @fieldParentPtr("prototype", text);
        node.allocator.free(pi.target);
        node.allocator.free(pi.prototype.data);
        node.allocator.destroy(pi);
    }

    fn nodeNameImpl(node: *const Node) []const u8 {
        const text: *const Text = @fieldParentPtr("prototype", node);
        const pi: *const ProcessingInstruction = @fieldParentPtr("prototype", text);
        return pi.target; // nodeName returns target per spec
    }

    fn nodeValueImpl(node: *const Node) ?[]const u8 {
        const text: *const Text = @fieldParentPtr("prototype", node);
        const pi: *const ProcessingInstruction = @fieldParentPtr("prototype", text);
        return pi.prototype.data;
    }

    fn setNodeValueImpl(node: *Node, new_value: []const u8) !void {
        const text: *Text = @fieldParentPtr("prototype", node);
        const pi: *ProcessingInstruction = @fieldParentPtr("prototype", text);

        // Capture old value for mutation observers
        const old_value = try node.allocator.dupe(u8, pi.prototype.data);
        defer node.allocator.free(old_value);

        // Replace data
        const data = try node.allocator.dupe(u8, new_value);

        node.allocator.free(pi.prototype.data);
        pi.prototype.data = data;
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
        _ = deep; // PIs don't typically have children

        const text: *const Text = @fieldParentPtr("prototype", node);
        const pi: *const ProcessingInstruction = @fieldParentPtr("prototype", text);

        // Create new PI with same target and data
        const new_pi = try ProcessingInstruction.create(node.allocator, pi.target, pi.prototype.data);

        // Copy owner document
        new_pi.prototype.prototype.owner_document = node.owner_document;

        return &new_pi.prototype.prototype;
    }

    fn adoptingStepsImpl(_: *Node, _: ?*Node) !void {
        // No special adoption steps for processing instructions
    }
};

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------

const testing = std.testing;









