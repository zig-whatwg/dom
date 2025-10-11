//! DOMImplementation Interface - WHATWG DOM Standard §4.5.1
//! ========================================================
//!
//! The DOMImplementation interface provides methods for creating documents and document types
//! independent of any particular document instance.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-domimplementation
//! - **Section**: §4.5.1 Interface DOMImplementation
//!
//! ## MDN Documentation
//! - **DOMImplementation**: https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation
//! - **createDocument()**: https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocument
//! - **createDocumentType()**: https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocumentType
//! - **createHTMLDocument()**: https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createHTMLDocument
//!
//! ## Overview
//!
//! DOMImplementation provides factory methods for creating new documents. It is associated
//! with a document and accessed via `document.implementation`.
//!
//! ## Key Methods
//!
//! - **createDocumentType**: Creates a DocumentType node
//! - **createDocument**: Creates an XML Document
//! - **createHTMLDocument**: Creates an HTML Document
//! - **hasFeature**: Always returns true (legacy compatibility)
//!
//! ## Usage Examples
//!
//! ### Create a Document Type
//! ```zig
//! const impl = try DOMImplementation.init(allocator, document);
//! defer impl.deinit();
//!
//! const doctype = try impl.createDocumentType("html", "", "");
//! defer doctype.deinit();
//! ```
//!
//! ### Create an XML Document
//! ```zig
//! const impl = try DOMImplementation.init(allocator, document);
//! defer impl.deinit();
//!
//! const doc = try impl.createDocument(
//!     "http://www.w3.org/1999/xhtml",
//!     "html",
//!     null
//! );
//! defer doc.release();
//! ```
//!
//! ### Create an HTML Document
//! ```zig
//! const impl = try DOMImplementation.init(allocator, document);
//! defer impl.deinit();
//!
//! const doc = try impl.createHTMLDocument("My Page");
//! defer doc.release();
//! ```

const std = @import("std");
const Node = @import("node.zig").Node;
const Document = @import("document.zig").Document;
const DocumentType = @import("document_type.zig").DocumentType;
const Element = @import("element.zig").Element;
const Text = @import("text.zig").Text;

/// DOMImplementation error types
pub const DOMImplementationError = error{
    InvalidCharacter,
    Namespace,
    OutOfMemory,
};

/// DOMImplementation provides document creation methods
///
/// ## Specification
///
/// From WHATWG DOM Standard §4.5.1:
/// "The DOMImplementation interface provides methods for creating documents
/// and document types independent of any particular document."
///
/// ## Design
///
/// - Associated with a document
/// - Factory methods for creating new documents
/// - Validates input parameters
/// - Maintains document relationships
///
/// ## Memory Management
///
/// DOMImplementation itself is lightweight.
/// Created documents/nodes must be released by caller.
pub const DOMImplementation = struct {
    /// Memory allocator
    allocator: std.mem.Allocator,

    /// Associated document
    document: *Document,

    const Self = @This();

    /// Initialize a DOMImplementation
    ///
    /// Creates a new DOMImplementation associated with a document.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `document`: The associated document
    ///
    /// ## Returns
    ///
    /// A pointer to the newly created DOMImplementation.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const impl = try DOMImplementation.init(allocator, document);
    /// defer impl.deinit();
    /// ```
    pub fn init(allocator: std.mem.Allocator, document: *Document) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .document = document,
        };
        return self;
    }

    /// Create a DocumentType node
    ///
    /// Creates a new DocumentType with the given name, public ID, and system ID.
    ///
    /// ## Parameters
    ///
    /// - `name`: The qualified name (e.g., "html")
    /// - `public_id`: The public identifier
    /// - `system_id`: The system identifier
    ///
    /// ## Returns
    ///
    /// A new DocumentType node.
    ///
    /// ## Errors
    ///
    /// - `error.InvalidCharacter`: Name contains invalid characters
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const doctype = try impl.createDocumentType("html", "", "");
    /// defer doctype.deinit();
    /// ```
    pub fn createDocumentType(
        self: *Self,
        name: []const u8,
        public_id: []const u8,
        system_id: []const u8,
    ) DOMImplementationError!*DocumentType {
        // Validate name (simplified - full validation would check more rules)
        if (name.len == 0) {
            return error.InvalidCharacter;
        }

        // Check for invalid characters
        for (name) |c| {
            if (c == 0 or c == '>' or std.ascii.isWhitespace(c)) {
                return error.InvalidCharacter;
            }
        }

        // Create the DocumentType
        return DocumentType.init(self.allocator, name, public_id, system_id);
    }

    /// Create an XML Document
    ///
    /// Creates a new XML document with optional namespace, qualified name, and doctype.
    ///
    /// ## Parameters
    ///
    /// - `namespace`: The namespace URI (or null)
    /// - `qualified_name`: The qualified name for the document element (or empty)
    /// - `doctype`: Optional DocumentType node
    ///
    /// ## Returns
    ///
    /// A new Document.
    ///
    /// ## Errors
    ///
    /// - `error.InvalidCharacter`: Invalid qualified name
    /// - `error.Namespace`: Namespace validation failed
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const doc = try impl.createDocument(
    ///     "http://www.w3.org/1999/xhtml",
    ///     "html",
    ///     null
    /// );
    /// defer doc.release();
    /// ```
    pub fn createDocument(
        self: *Self,
        namespace: ?[]const u8,
        qualified_name: []const u8,
        doctype: ?*DocumentType,
    ) DOMImplementationError!*Document {
        // Create a new document
        const doc = try Document.init(self.allocator);
        errdefer doc.release();

        // If doctype provided, append it
        if (doctype) |dt| {
            _ = doc.node.appendChild(dt.node) catch |err| {
                return switch (err) {
                    error.OutOfMemory => error.OutOfMemory,
                    else => error.InvalidCharacter,
                };
            };
        }

        // If qualified_name is not empty, create document element
        if (qualified_name.len > 0) {
            // Validate qualified name (simplified)
            if (qualified_name[0] == 0 or qualified_name[0] == '>') {
                return error.InvalidCharacter;
            }

            // Create the document element
            const element = try Element.create(self.allocator, qualified_name);
            errdefer element.release();

            // Note: Namespace handling simplified (XML features excluded)
            _ = namespace;

            // Append to document
            _ = doc.node.appendChild(element) catch |err| {
                return switch (err) {
                    error.OutOfMemory => error.OutOfMemory,
                    else => error.InvalidCharacter,
                };
            };
        }

        return doc;
    }

    /// Create an HTML Document
    ///
    /// Creates a new HTML document with basic structure and optional title.
    ///
    /// ## Parameters
    ///
    /// - `title`: Optional title for the document
    ///
    /// ## Returns
    ///
    /// A new HTML Document with basic structure.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const doc = try impl.createHTMLDocument("My Page");
    /// defer doc.release();
    /// ```
    pub fn createHTMLDocument(self: *Self, title: ?[]const u8) DOMImplementationError!*Document {
        // Create document
        const doc = try Document.init(self.allocator);
        errdefer doc.release();

        // Create doctype: <!DOCTYPE html>
        const doctype = try DocumentType.init(self.allocator, "html", "", "");
        errdefer doctype.deinit();

        _ = doc.node.appendChild(doctype.node) catch |err| {
            return switch (err) {
                error.OutOfMemory => error.OutOfMemory,
                else => error.InvalidCharacter,
            };
        };

        // Create html element
        const html = try Element.create(self.allocator, "html");
        errdefer html.release();

        _ = doc.node.appendChild(html) catch |err| {
            return switch (err) {
                error.OutOfMemory => error.OutOfMemory,
                else => error.InvalidCharacter,
            };
        };

        // Create head element
        const head = try Element.create(self.allocator, "head");
        errdefer head.release();

        _ = html.appendChild(head) catch |err| {
            return switch (err) {
                error.OutOfMemory => error.OutOfMemory,
                else => error.InvalidCharacter,
            };
        };

        // If title provided, create title element
        if (title) |t| {
            const title_elem = try Element.create(self.allocator, "title");
            errdefer title_elem.release();

            _ = head.appendChild(title_elem) catch |err| {
                return switch (err) {
                    error.OutOfMemory => error.OutOfMemory,
                    else => error.InvalidCharacter,
                };
            };

            // Add title text - create node directly to avoid wrapper leak
            const text_node = try Node.init(self.allocator, .text_node, t);
            errdefer text_node.release();

            _ = title_elem.appendChild(text_node) catch |err| {
                return switch (err) {
                    error.OutOfMemory => error.OutOfMemory,
                    else => error.InvalidCharacter,
                };
            };
        }

        // Create body element
        const body = try Element.create(self.allocator, "body");
        errdefer body.release();

        _ = html.appendChild(body) catch |err| {
            return switch (err) {
                error.OutOfMemory => error.OutOfMemory,
                else => error.InvalidCharacter,
            };
        };

        return doc;
    }

    /// Check if a feature is supported (always returns true)
    ///
    /// This method exists for legacy compatibility and always returns true.
    /// The DOM feature detection mechanism has been deprecated.
    ///
    /// ## Returns
    ///
    /// Always returns `true`.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const supported = impl.hasFeature();
    /// // supported is always true
    /// ```
    pub fn hasFeature(self: *Self) bool {
        _ = self;
        return true;
    }

    /// Clean up resources
    ///
    /// Frees the DOMImplementation object.
    /// Does not free the associated document.
    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DOMImplementation creation" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    try std.testing.expect(impl.document == doc);
}

test "DOMImplementation createDocumentType" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    const doctype = try impl.createDocumentType("html", "", "");
    defer doctype.release();

    try std.testing.expectEqualStrings("html", doctype.name());
    try std.testing.expectEqualStrings("", doctype.publicId());
    try std.testing.expectEqualStrings("", doctype.systemId());
}

test "DOMImplementation createDocumentType with IDs" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    const doctype = try impl.createDocumentType(
        "svg",
        "-//W3C//DTD SVG 1.1//EN",
        "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd",
    );
    defer doctype.release();

    try std.testing.expectEqualStrings("svg", doctype.name());
    try std.testing.expectEqualStrings("-//W3C//DTD SVG 1.1//EN", doctype.publicId());
    try std.testing.expectEqualStrings("http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd", doctype.systemId());
}

test "DOMImplementation createDocumentType invalid name" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    // Empty name
    try std.testing.expectError(error.InvalidCharacter, impl.createDocumentType("", "", ""));

    // Name with invalid character
    try std.testing.expectError(error.InvalidCharacter, impl.createDocumentType("ht>ml", "", ""));
}

test "DOMImplementation createDocument empty" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    const new_doc = try impl.createDocument(null, "", null);
    defer new_doc.release();

    try std.testing.expect(new_doc.node.node_type == .document_node);
    try std.testing.expectEqual(@as(usize, 0), new_doc.node.child_nodes.length());
}

test "DOMImplementation createDocument with element" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    const new_doc = try impl.createDocument(
        "http://www.w3.org/1999/xhtml",
        "html",
        null,
    );
    defer new_doc.release();

    try std.testing.expectEqual(@as(usize, 1), new_doc.node.child_nodes.length());

    const root_node: *Node = @ptrCast(@alignCast(new_doc.node.child_nodes.item(0).?));
    try std.testing.expect(root_node.node_type == .element_node);
    try std.testing.expectEqualStrings("html", root_node.node_name);
}

test "DOMImplementation createDocument with doctype" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    const doctype = try impl.createDocumentType("html", "", "");
    // Don't defer - ownership transfers to document

    const new_doc = try impl.createDocument(
        "http://www.w3.org/1999/xhtml",
        "html",
        doctype,
    );
    defer new_doc.release();

    try std.testing.expectEqual(@as(usize, 2), new_doc.node.child_nodes.length());

    // First child should be doctype
    const first_node: *Node = @ptrCast(@alignCast(new_doc.node.child_nodes.item(0).?));
    try std.testing.expect(first_node.node_type == .document_type_node);
}

test "DOMImplementation createHTMLDocument no title" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    const html_doc = try impl.createHTMLDocument(null);
    defer html_doc.release();

    // Should have doctype and html element
    try std.testing.expectEqual(@as(usize, 2), html_doc.node.child_nodes.length());

    // First child is doctype
    const doctype_node: *Node = @ptrCast(@alignCast(html_doc.node.child_nodes.item(0).?));
    try std.testing.expect(doctype_node.node_type == .document_type_node);

    // Second child is html
    const html_node: *Node = @ptrCast(@alignCast(html_doc.node.child_nodes.item(1).?));
    try std.testing.expect(html_node.node_type == .element_node);
    try std.testing.expectEqualStrings("html", html_node.node_name);

    // HTML should have head and body
    try std.testing.expectEqual(@as(usize, 2), html_node.child_nodes.length());

    const head_node: *Node = @ptrCast(@alignCast(html_node.child_nodes.item(0).?));
    try std.testing.expectEqualStrings("head", head_node.node_name);

    const body_node: *Node = @ptrCast(@alignCast(html_node.child_nodes.item(1).?));
    try std.testing.expectEqualStrings("body", body_node.node_name);
}

test "DOMImplementation createHTMLDocument with title" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    const html_doc = try impl.createHTMLDocument("Test Page");
    defer html_doc.release();

    // Get html element
    const html_node: *Node = @ptrCast(@alignCast(html_doc.node.child_nodes.item(1).?));

    // Get head element
    const head_node: *Node = @ptrCast(@alignCast(html_node.child_nodes.item(0).?));

    // Head should have title
    try std.testing.expectEqual(@as(usize, 1), head_node.child_nodes.length());

    const title_node: *Node = @ptrCast(@alignCast(head_node.child_nodes.item(0).?));
    try std.testing.expectEqualStrings("title", title_node.node_name);

    // Title should have text child
    try std.testing.expectEqual(@as(usize, 1), title_node.child_nodes.length());

    const text_node: *Node = @ptrCast(@alignCast(title_node.child_nodes.item(0).?));
    try std.testing.expect(text_node.node_type == .text_node);
    // For text nodes, the content is in node_name
    try std.testing.expectEqualStrings("Test Page", text_node.node_name);
}

test "DOMImplementation hasFeature" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = try DOMImplementation.init(allocator, doc);
    defer impl.deinit();

    // Always returns true
    try std.testing.expect(impl.hasFeature());
}

test "DOMImplementation memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const doc = try Document.init(allocator);
        defer doc.release();

        const impl = try DOMImplementation.init(allocator, doc);
        defer impl.deinit();

        const html_doc = try impl.createHTMLDocument("Test");
        defer html_doc.release();

        _ = impl.hasFeature();
    }
}
