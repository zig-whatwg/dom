//! DocumentType Node Implementation (WHATWG DOM)
//!
//! This module implements the DocumentType interface representing the document's DTD (Document Type Declaration).
//! A DocumentType node represents the <!DOCTYPE> declaration that may appear at the beginning of a document.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **DocumentType Interface**: https://dom.spec.whatwg.org/#documenttype
//! - **Document.doctype**: https://dom.spec.whatwg.org/#dom-document-doctype
//!
//! ## MDN Documentation
//!
//! - DocumentType: https://developer.mozilla.org/en-US/docs/Web/API/DocumentType
//! - Document.doctype: https://developer.mozilla.org/en-US/docs/Web/API/Document/doctype
//! - DocumentType.name: https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/name
//! - DocumentType.publicId: https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/publicId
//! - DocumentType.systemId: https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/systemId
//!
//! ## Core Features
//!
//! ### Basic Usage
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! // Create a DocumentType node (typically done by parser)
//! const doctype = try DocumentType.create(allocator, "xml", "", "");
//! defer doctype.prototype.release();
//!
//! // Access properties
//! const name = doctype.name;  // "xml"
//! const publicId = doctype.publicId;  // ""
//! const systemId = doctype.systemId;  // ""
//! ```
//!
//! ### HTML5 DOCTYPE
//! ```zig
//! // HTML5 doctype: <!DOCTYPE html>
//! const doctype = try DocumentType.create(allocator, "html", "", "");
//! ```
//!
//! ### XML DOCTYPE with Public ID
//! ```zig
//! // XML with public ID: <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
//! const doctype = try DocumentType.create(
//!     allocator,
//!     "svg",
//!     "-//W3C//DTD SVG 1.1//EN",
//!     "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"
//! );
//! ```
//!
//! ## Architecture
//!
//! DocumentType extends Node with three string properties:
//! - `name`: The document type name (e.g., "html", "xml", "svg")
//! - `publicId`: The public identifier (often empty for HTML5)
//! - `systemId`: The system identifier (URL to DTD, often empty for HTML5)
//!
//! All strings are interned via Document.string_pool for memory efficiency.
//!
//! ## Spec Compliance
//!
//! This implementation follows WHATWG DOM §4.10 exactly:
//! - ✅ DocumentType extends Node
//! - ✅ Read-only name, publicId, systemId properties
//! - ✅ nodeName returns the name
//! - ✅ nodeValue returns null
//! - ✅ Cannot have children (no appendChild, etc.)
//! - ✅ Can be adopted into different documents

const std = @import("std");
const Allocator = std.mem.Allocator;
const Node = @import("node.zig").Node;
const NodeVTable = @import("node.zig").NodeVTable;

/// DocumentType represents a document's DTD (Document Type Declaration).
///
/// This node type represents the <!DOCTYPE> declaration that may appear
/// at the beginning of a document.
///
/// ## WebIDL
/// ```webidl
/// interface DocumentType : Node {
///   readonly attribute DOMString name;
///   readonly attribute DOMString publicId;
///   readonly attribute DOMString systemId;
/// };
/// ```
///
/// ## Spec References
/// - Interface: https://dom.spec.whatwg.org/#documenttype
/// - WebIDL: dom.idl:91-95
pub const DocumentType = struct {
    /// Base Node (MUST be first field for @fieldParentPtr)
    prototype: Node,

    /// The document type name (e.g., "html", "xml", "svg")
    /// This is an interned string from Document.string_pool
    name: []const u8,

    /// The public identifier (e.g., "-//W3C//DTD XHTML 1.0 Strict//EN")
    /// Empty string for HTML5 doctypes
    /// This is an interned string from Document.string_pool
    publicId: []const u8,

    /// The system identifier (e.g., "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd")
    /// Empty string for HTML5 doctypes
    /// This is an interned string from Document.string_pool
    systemId: []const u8,

    /// Vtable for DocumentType nodes.
    pub const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };

    /// Creates a new DocumentType node.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] DocumentType createDocumentType(DOMString name, DOMString publicId, DOMString systemId);
    /// ```
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for the node
    /// - `name`: Document type name (will be interned)
    /// - `publicId`: Public identifier (will be interned)
    /// - `systemId`: System identifier (will be interned)
    ///
    /// ## Returns
    /// New DocumentType node with ref_count = 1 (caller owns the reference)
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate node or intern strings
    ///
    /// ## Example
    /// ```zig
    /// // HTML5 doctype
    /// const doctype = try DocumentType.create(allocator, "html", "", "");
    /// defer doctype.prototype.release();
    /// ```
    ///
    /// ## Spec References
    /// - DOMImplementation.createDocumentType: https://dom.spec.whatwg.org/#dom-domimplementation-createdocumenttype
    pub fn create(allocator: Allocator, name: []const u8, publicId: []const u8, systemId: []const u8) !*DocumentType {
        const doctype = try allocator.create(DocumentType);
        errdefer allocator.destroy(doctype);

        // Intern strings (when added to document, will be re-interned from document pool)
        const name_copy = try allocator.dupe(u8, name);
        errdefer allocator.free(name_copy);

        const publicId_copy = try allocator.dupe(u8, publicId);
        errdefer allocator.free(publicId_copy);

        const systemId_copy = try allocator.dupe(u8, systemId);
        errdefer allocator.free(systemId_copy);

        const node_mod = @import("node.zig");
        doctype.* = DocumentType{
            .prototype = .{
                .prototype = .{
                    .vtable = &node_mod.eventtarget_vtable,
                },
                .vtable = &vtable,
                .ref_count_and_parent = std.atomic.Value(u32).init(1),
                .node_type = .document_type,
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
            .name = name_copy,
            .publicId = publicId_copy,
            .systemId = systemId_copy,
        };

        return doctype;
    }

    // ========================================================================
    // Node Vtable Implementations
    // ========================================================================

    /// Vtable implementation: deinit
    /// Called when node is being destroyed (ref_count reaches 0)
    fn deinitImpl(node: *Node) void {
        const doctype: *DocumentType = @fieldParentPtr("prototype", node);
        const allocator = node.allocator;

        // Free strings only if created standalone (not via Document.createDocumentType)
        // When created via Document, strings are interned in string_pool and shouldn't be freed
        if (node.owner_document == null) {
            allocator.free(doctype.name);
            allocator.free(doctype.publicId);
            allocator.free(doctype.systemId);
        }

        // Destroy the node itself
        allocator.destroy(doctype);
    }

    /// Vtable implementation: nodeName
    /// Returns the document type name
    fn nodeNameImpl(node: *const Node) []const u8 {
        const doctype: *const DocumentType = @fieldParentPtr("prototype", node);
        return doctype.name;
    }

    /// Vtable implementation: nodeValue
    /// Always returns null for DocumentType nodes
    fn nodeValueImpl(_: *const Node) ?[]const u8 {
        return null;
    }

    /// Vtable implementation: set_node_value
    /// Does nothing for DocumentType nodes (nodeValue is always null)
    fn setNodeValueImpl(_: *Node, _: []const u8) !void {
        // No-op: DocumentType nodes have no value
    }

    /// Vtable implementation: cloneNode
    /// Creates a copy of this DocumentType node
    fn cloneNodeImpl(node: *const Node, _: bool) !*Node {
        const doctype: *const DocumentType = @fieldParentPtr("prototype", node);
        const allocator = node.allocator;

        // Create new DocumentType with same properties
        const cloned = try create(allocator, doctype.name, doctype.publicId, doctype.systemId);

        return &cloned.prototype;
    }

    /// Internal: Clones document type using a specific allocator.
    ///
    /// Used by `Document.importNode()` to clone document types into a different
    /// document's allocator.
    ///
    /// ## Parameters
    /// - `doctype`: The document type to clone
    /// - `allocator`: The allocator to use for the cloned document type
    ///
    /// ## Returns
    /// A new cloned document type allocated with the specified allocator
    pub fn cloneWithAllocator(doctype: *const DocumentType, allocator: Allocator) Allocator.Error!*Node {
        // Create new DocumentType with same properties using the provided allocator
        const cloned = try create(allocator, doctype.name, doctype.publicId, doctype.systemId);

        return &cloned.prototype;
    }

    /// Vtable implementation: adoptingSteps
    /// Called when DocumentType is adopted into another document
    fn adoptingStepsImpl(_: *Node, _: ?*Node) !void {
        // No-op: DocumentType strings are already interned per-document
        // When appendChild is called, Document will re-intern if needed
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DocumentType - create and access properties" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("", doctype.publicId);
    try std.testing.expectEqualStrings("", doctype.systemId);
}

test "DocumentType - XML with public and system IDs" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(
        allocator,
        "svg",
        "-//W3C//DTD SVG 1.1//EN",
        "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd",
    );
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("svg", doctype.name);
    try std.testing.expectEqualStrings("-//W3C//DTD SVG 1.1//EN", doctype.publicId);
    try std.testing.expectEqualStrings("http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd", doctype.systemId);
}

test "DocumentType - nodeName returns name" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    const node_name = doctype.prototype.nodeName();
    try std.testing.expectEqualStrings("html", node_name);
}

test "DocumentType - nodeValue is null" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    try std.testing.expect(doctype.prototype.nodeValue() == null);
}

test "DocumentType - cloneNode creates copy" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "public", "system");
    defer doctype.prototype.release();

    const cloned_node = try doctype.prototype.cloneNode(false);
    defer cloned_node.release();

    const cloned: *DocumentType = @fieldParentPtr("prototype", cloned_node);

    try std.testing.expectEqualStrings("html", cloned.name);
    try std.testing.expectEqualStrings("public", cloned.publicId);
    try std.testing.expectEqualStrings("system", cloned.systemId);
}

test "DocumentType - node_type is correct" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    try std.testing.expect(doctype.prototype.node_type == .document_type);
}
