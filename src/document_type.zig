//! DocumentType - DOCTYPE Declaration Node
//!
//! WHATWG DOM Standard §4.6
//! https://dom.spec.whatwg.org/#interface-documenttype
//!
//! DocumentType nodes represent the DOCTYPE declaration in a document.

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// DocumentType represents a DOCTYPE declaration
///
/// ## Specification
///
/// WHATWG DOM Standard §4.6
///
/// ## Example
///
/// ```zig
/// const doctype = try DocumentType.init(allocator, "html", "", "");
/// defer doctype.release();
///
/// std.debug.print("<!DOCTYPE {s}>\n", .{doctype.name()});
/// ```
pub const DocumentType = struct {
    /// Underlying Node
    node: *Node,

    /// Allocator
    allocator: std.mem.Allocator,

    /// DOCTYPE name (e.g., "html")
    doctype_name: []const u8,

    /// Public ID
    public_id: []const u8,

    /// System ID
    system_id: []const u8,

    const Self = @This();

    /// Initialize a DocumentType node
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `name`: The DOCTYPE name (e.g., "html")
    /// - `public_id`: The public identifier
    /// - `system_id`: The system identifier
    ///
    /// ## Returns
    ///
    /// A new DocumentType instance.
    ///
    /// ## Example
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
    /// ```
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

    /// Get the DOCTYPE name
    ///
    /// ## Returns
    ///
    /// The name of the DOCTYPE (e.g., "html").
    pub fn name(self: *const Self) []const u8 {
        return self.doctype_name;
    }

    /// Get the public ID
    ///
    /// ## Returns
    ///
    /// The public identifier string.
    pub fn publicId(self: *const Self) []const u8 {
        return self.public_id;
    }

    /// Get the system ID
    ///
    /// ## Returns
    ///
    /// The system identifier string.
    pub fn systemId(self: *const Self) []const u8 {
        return self.system_id;
    }

    /// Release the DocumentType (decrements reference count)
    ///
    /// This should be called when done with the DocumentType.
    /// The actual cleanup happens when reference count reaches zero.
    pub fn release(self: *Self) void {
        self.node.release();
    }

    /// Clean up the DocumentType (called by Node when ref count = 0)
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.doctype_name);
        self.allocator.free(self.public_id);
        self.allocator.free(self.system_id);
        self.allocator.destroy(self);
    }
};

// Tests
test "DocumentType HTML5" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.init(allocator, "html", "", "");
    defer doctype.release();

    try std.testing.expectEqualStrings("html", doctype.name());
    try std.testing.expectEqualStrings("", doctype.publicId());
    try std.testing.expectEqualStrings("", doctype.systemId());
    try std.testing.expectEqual(NodeType.document_type_node, doctype.node.node_type);
}

test "DocumentType XHTML" {
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

test "DocumentType XML" {
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

test "DocumentType node properties" {
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

test "DocumentType empty IDs" {
    const allocator = std.testing.allocator;

    const doctype = try DocumentType.init(allocator, "test", "", "");
    defer doctype.release();

    try std.testing.expectEqualStrings("", doctype.publicId());
    try std.testing.expectEqualStrings("", doctype.systemId());
}

test "DocumentType reference counting" {
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

test "DocumentType memory leak test" {
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
