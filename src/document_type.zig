//! DocumentType Interface - WHATWG DOM Standard §4.6
//! ====================================================
//!
//! The DocumentType interface represents a doctype node in the document tree. In HTML
//! documents, this represents the `<!DOCTYPE html>` declaration that specifies the document
//! type. In XML documents, it can include public and system identifiers.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-documenttype
//! - **Section**: §4.6 Interface DocumentType
//!
//! ## MDN Documentation
//! - **DocumentType**: https://developer.mozilla.org/en-US/docs/Web/API/DocumentType
//! - **DocumentType.name**: https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/name
//! - **Document.doctype**: https://developer.mozilla.org/en-US/docs/Web/API/Document/doctype
//!
//! ## Key Concepts
//!
//! ### DOCTYPE Declaration
//! The DOCTYPE declaration tells the browser which version of HTML or XML is being used.
//! Modern HTML5 documents use the simple `<!DOCTYPE html>` form. Older HTML/XHTML versions
//! used more complex forms with public and system identifiers.
//!
//! ### Node Properties
//! DocumentType is a node type, so it participates in the DOM tree. However, it:
//! - Cannot have child nodes
//! - Must appear before the document element
//! - Has a node_type of `document_type_node` (10)
//!
//! ### Identifiers
//! - **name**: The DOCTYPE name (e.g., "html" for HTML documents)
//! - **publicId**: The public identifier (empty string for HTML5)
//! - **systemId**: The system identifier (empty string for HTML5)
//!
//! ## Architecture
//!
//! ```
//! DocumentType
//! ├── node (*Node) - Base node interface
//! ├── doctype_name ([]const u8) - DOCTYPE name
//! ├── public_id ([]const u8) - Public identifier
//! └── system_id ([]const u8) - System identifier
//! ```
//!
//! ## Usage Examples
//!
//! ### HTML5 DOCTYPE
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! // Create modern HTML5 doctype: <!DOCTYPE html>
//! const doctype = try DocumentType.init(allocator, "html", "", "");
//! defer doctype.release();
//!
//! std.debug.print("<!DOCTYPE {s}>\n", .{doctype.name()});
//! // Output: <!DOCTYPE html>
//! ```
//!
//! ### XHTML DOCTYPE
//! ```zig
//! // Create XHTML 1.0 Strict doctype with full identifiers
//! const doctype = try DocumentType.init(
//!     allocator,
//!     "html",
//!     "-//W3C//DTD XHTML 1.0 Strict//EN",
//!     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
//! );
//! defer doctype.release();
//!
//! std.debug.print("<!DOCTYPE {s} PUBLIC \"{s}\" \"{s}\">\n", .{
//!     doctype.name(),
//!     doctype.publicId(),
//!     doctype.systemId(),
//! });
//! ```
//!
//! ### Adding to Document
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const doctype = try DocumentType.init(allocator, "html", "", "");
//! _ = try doc.node.appendChild(doctype.node);
//!
//! // Create document element
//! const html = try doc.createElement("html");
//! _ = try doc.node.appendChild(html);
//! doc.document_element = html;
//! ```
//!
//! ### Custom XML DOCTYPE
//! ```zig
//! // Create custom XML doctype
//! const doctype = try DocumentType.init(
//!     allocator,
//!     "book",
//!     "-//Example//DTD Book 1.0//EN",
//!     "http://example.com/book.dtd"
//! );
//! defer doctype.release();
//!
//! std.debug.print("Name: {s}\n", .{doctype.name()});
//! std.debug.print("Public ID: {s}\n", .{doctype.publicId()});
//! std.debug.print("System ID: {s}\n", .{doctype.systemId()});
//! ```
//!
//! ## Memory Management
//!
//! DocumentType nodes use reference counting like all DOM nodes. The name, publicId,
//! and systemId strings are owned by the DocumentType and are freed when the reference
//! count reaches zero.
//!
//! ```zig
//! const doctype = try DocumentType.init(allocator, "html", "", "");
//! defer doctype.release(); // Decrements ref count, frees if 0
//!
//! // Or manage manually:
//! const doctype2 = try DocumentType.init(allocator, "html", "", "");
//! doctype2.node.retain(); // Increment ref count
//! doctype2.release(); // First release (count = 1)
//! doctype2.release(); // Second release (count = 0, frees)
//! ```
//!
//! ## Common DOCTYPE Declarations
//!
//! ### HTML5
//! ```zig
//! try DocumentType.init(allocator, "html", "", "");
//! // <!DOCTYPE html>
//! ```
//!
//! ### XHTML 1.0 Strict
//! ```zig
//! try DocumentType.init(
//!     allocator,
//!     "html",
//!     "-//W3C//DTD XHTML 1.0 Strict//EN",
//!     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
//! );
//! ```
//!
//! ### XHTML 1.0 Transitional
//! ```zig
//! try DocumentType.init(
//!     allocator,
//!     "html",
//!     "-//W3C//DTD XHTML 1.0 Transitional//EN",
//!     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
//! );
//! ```
//!
//! ### HTML 4.01 Strict
//! ```zig
//! try DocumentType.init(
//!     allocator,
//!     "html",
//!     "-//W3C//DTD HTML 4.01//EN",
//!     "http://www.w3.org/TR/html4/strict.dtd"
//! );
//! ```
//!
//! ## Thread Safety
//!
//! DocumentType is not thread-safe. All operations should be performed from a single thread.

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// DocumentType represents a DOCTYPE declaration node.
///
/// Stores the doctype name, public identifier, and system identifier for a document.
/// Used primarily at the beginning of HTML and XML documents to declare the document type.
///
/// See: https://dom.spec.whatwg.org/#interface-documenttype
/// See: https://developer.mozilla.org/en-US/docs/Web/API/DocumentType
pub const DocumentType = struct {
    const Self = @This();

    /// Base Node interface
    node: *Node,

    /// Memory allocator used for this DocumentType
    allocator: std.mem.Allocator,

    /// The DOCTYPE name (e.g., "html" for HTML documents)
    doctype_name: []const u8,

    /// The public identifier (empty string for HTML5)
    public_id: []const u8,

    /// The system identifier (empty string for HTML5)
    system_id: []const u8,

    /// Initialize a DocumentType node.
    ///
    /// Creates a new DocumentType node with the specified name and identifiers.
    /// The strings are copied and owned by the DocumentType.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the DocumentType
    /// - `doctype_name`: The DOCTYPE name (e.g., "html")
    /// - `public_id`: The public identifier (use "" for none)
    /// - `system_id`: The system identifier (use "" for none)
    ///
    /// ## Returns
    ///
    /// Returns a pointer to the created DocumentType. The caller must call `release()`
    /// when done to properly free resources.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// // HTML5 doctype: <!DOCTYPE html>
    /// const html5 = try DocumentType.init(allocator, "html", "", "");
    /// defer html5.release();
    ///
    /// // XHTML doctype with public and system IDs
    /// const xhtml = try DocumentType.init(
    ///     allocator,
    ///     "html",
    ///     "-//W3C//DTD XHTML 1.0 Strict//EN",
    ///     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
    /// );
    /// defer xhtml.release();
    ///
    /// // Custom XML doctype
    /// const xml = try DocumentType.init(
    ///     allocator,
    ///     "book",
    ///     "-//Example//DTD Book 1.0//EN",
    ///     "http://example.com/book.dtd"
    /// );
    /// defer xml.release();
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-domimplementation-createdocumenttype
    pub fn init(
        allocator: std.mem.Allocator,
        doctype_name: []const u8,
        public_id: []const u8,
        system_id: []const u8,
    ) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        // Create the underlying node
        const node = try Node.init(allocator, .document_type_node, doctype_name);
        errdefer node.release();

        // Duplicate strings for ownership
        const name_copy = try allocator.dupe(u8, doctype_name);
        errdefer allocator.free(name_copy);

        const public_id_copy = try allocator.dupe(u8, public_id);
        errdefer allocator.free(public_id_copy);

        const system_id_copy = try allocator.dupe(u8, system_id);
        errdefer allocator.free(system_id_copy);

        self.* = .{
            .node = node,
            .allocator = allocator,
            .doctype_name = name_copy,
            .public_id = public_id_copy,
            .system_id = system_id_copy,
        };

        // Store pointer to self in node for cleanup
        node.element_data_ptr = self;

        return self;
    }

    /// Get the DOCTYPE name.
    ///
    /// Returns the name of the DOCTYPE declaration. For HTML documents,
    /// this is typically "html".
    ///
    /// ## Returns
    ///
    /// The DOCTYPE name as a string slice.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const doctype = try DocumentType.init(allocator, "html", "", "");
    /// defer doctype.release();
    ///
    /// std.debug.print("Name: {s}\n", .{doctype.name()});
    /// // Output: Name: html
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-documenttype-name
    pub fn name(self: *const Self) []const u8 {
        return self.doctype_name;
    }

    /// Get the public identifier.
    ///
    /// Returns the public identifier of the DOCTYPE. For HTML5 documents,
    /// this is always an empty string. For older HTML/XHTML documents,
    /// this contains the FPI (Formal Public Identifier).
    ///
    /// ## Returns
    ///
    /// The public identifier string (may be empty).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const xhtml = try DocumentType.init(
    ///     allocator,
    ///     "html",
    ///     "-//W3C//DTD XHTML 1.0 Strict//EN",
    ///     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
    /// );
    /// defer xhtml.release();
    ///
    /// std.debug.print("Public ID: {s}\n", .{xhtml.publicId()});
    /// // Output: Public ID: -//W3C//DTD XHTML 1.0 Strict//EN
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-documenttype-publicid
    pub fn publicId(self: *const Self) []const u8 {
        return self.public_id;
    }

    /// Get the system identifier.
    ///
    /// Returns the system identifier of the DOCTYPE. For HTML5 documents,
    /// this is always an empty string. For older HTML/XHTML documents,
    /// this typically contains a URL to the DTD file.
    ///
    /// ## Returns
    ///
    /// The system identifier string (may be empty).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const xhtml = try DocumentType.init(
    ///     allocator,
    ///     "html",
    ///     "-//W3C//DTD XHTML 1.0 Strict//EN",
    ///     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
    /// );
    /// defer xhtml.release();
    ///
    /// std.debug.print("System ID: {s}\n", .{xhtml.systemId()});
    /// // Output: System ID: http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-documenttype-systemid
    pub fn systemId(self: *const Self) []const u8 {
        return self.system_id;
    }

    /// Release the DocumentType node.
    ///
    /// Decrements the reference count of the underlying node. When the reference
    /// count reaches zero, the node and all its resources are freed automatically.
    ///
    /// This should be called when you're done with the DocumentType, typically
    /// using `defer` immediately after creation (unless adding to a document tree).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const doctype = try DocumentType.init(allocator, "html", "", "");
    /// defer doctype.release(); // Ensures cleanup
    ///
    /// // Use doctype...
    /// ```
    pub fn release(self: *Self) void {
        self.node.release();
    }

    /// Clean up the DocumentType resources.
    ///
    /// This is called internally by the Node when the reference count reaches zero.
    /// Do not call this directly - use `release()` instead.
    ///
    /// Frees all owned strings and the DocumentType struct itself.
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.doctype_name);
        self.allocator.free(self.public_id);
        self.allocator.free(self.system_id);
        self.allocator.destroy(self);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DocumentType - HTML5" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.init(allocator, "html", "", "");
    defer doctype.release();

    try std.testing.expectEqualStrings("html", doctype.name());
    try std.testing.expectEqualStrings("", doctype.publicId());
    try std.testing.expectEqualStrings("", doctype.systemId());
    try std.testing.expectEqual(NodeType.document_type_node, doctype.node.node_type);
}

test "DocumentType - XHTML 1.0 Strict" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.init(
        allocator,
        "html",
        "-//W3C//DTD XHTML 1.0 Strict//EN",
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd",
    );
    defer doctype.release();

    try std.testing.expectEqualStrings("html", doctype.name());
    try std.testing.expectEqualStrings("-//W3C//DTD XHTML 1.0 Strict//EN", doctype.publicId());
    try std.testing.expectEqualStrings("http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd", doctype.systemId());
}

test "DocumentType - Custom XML" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.init(
        allocator,
        "root",
        "-//Example//DTD Example 1.0//EN",
        "http://example.com/example.dtd",
    );
    defer doctype.release();

    try std.testing.expectEqualStrings("root", doctype.name());
    try std.testing.expectEqualStrings("-//Example//DTD Example 1.0//EN", doctype.publicId());
    try std.testing.expectEqualStrings("http://example.com/example.dtd", doctype.systemId());
}

test "DocumentType - Node properties" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.init(allocator, "html", "", "");
    defer doctype.release();

    // Node should have correct type
    try std.testing.expectEqual(NodeType.document_type_node, doctype.node.node_type);

    // Node name should match doctype name
    try std.testing.expectEqualStrings("html", doctype.node.node_name);

    // Doctype nodes don't have children
    try std.testing.expectEqual(@as(usize, 0), doctype.node.child_nodes.length());
}

test "DocumentType - Empty identifiers" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.init(allocator, "test", "", "");
    defer doctype.release();

    try std.testing.expectEqualStrings("", doctype.publicId());
    try std.testing.expectEqualStrings("", doctype.systemId());
}

test "DocumentType - Reference counting" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.init(allocator, "html", "", "");

    // Initial ref count is 1
    try std.testing.expectEqual(@as(usize, 1), doctype.node.ref_count);

    // Retain increases ref count
    doctype.node.retain();
    try std.testing.expectEqual(@as(usize, 2), doctype.node.ref_count);

    // Release decreases ref count
    doctype.release();
    try std.testing.expectEqual(@as(usize, 1), doctype.node.ref_count);

    // Final release (cleans up)
    doctype.release();
}

test "DocumentType - Memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const doctype = try DocumentType.init(
            allocator,
            "html",
            "-//W3C//DTD XHTML 1.0 Strict//EN",
            "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd",
        );
        doctype.release();
    }
}
