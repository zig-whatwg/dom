//! ProcessingInstruction - PI Node
//!
//! WHATWG DOM Standard §4.13
//! https://dom.spec.whatwg.org/#interface-processinginstruction
//!
//! ProcessingInstruction nodes represent processing instructions in XML documents.
//! A processing instruction provides processor-specific data (e.g., <?xml-stylesheet?>).

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// ProcessingInstruction represents a processing instruction node
///
/// ## Specification
///
/// WHATWG DOM Standard §4.13
///
/// ## Example
///
/// ```zig
/// const pi = try ProcessingInstruction.init(
///     allocator,
///     "xml-stylesheet",
///     "type=\"text/css\" href=\"style.css\""
/// );
/// defer pi.release();
///
/// std.debug.print("<?{s} {s}?>\n", .{pi.target(), pi.data()});
/// ```
pub const ProcessingInstruction = struct {
    /// Underlying Node
    node: *Node,

    /// Allocator
    allocator: std.mem.Allocator,

    /// PI target (e.g., "xml-stylesheet")
    pi_target: []const u8,

    /// PI data/content
    pi_data: []const u8,

    const Self = @This();

    /// Initialize a ProcessingInstruction node
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `pi_target`: The processing instruction target
    /// - `pi_data`: The processing instruction data
    ///
    /// ## Returns
    ///
    /// A new ProcessingInstruction instance.
    ///
    /// ## Example
    ///
    /// ```zig
    /// // XML stylesheet PI
    /// const stylesheet = try ProcessingInstruction.init(
    ///     allocator,
    ///     "xml-stylesheet",
    ///     "type=\"text/xsl\" href=\"transform.xsl\""
    /// );
    /// defer stylesheet.release();
    ///
    /// // PHP processing instruction
    /// const php = try ProcessingInstruction.init(
    ///     allocator,
    ///     "php",
    ///     "echo 'Hello World';"
    /// );
    /// defer php.release();
    /// ```
    pub fn init(
        allocator: std.mem.Allocator,
        pi_target: []const u8,
        pi_data: []const u8,
    ) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        // Create the underlying node - PI nodes use target as node name
        const node = try Node.init(allocator, .processing_instruction_node, pi_target);
        errdefer node.release();

        // Duplicate strings for ownership
        const target_copy = try allocator.dupe(u8, pi_target);
        errdefer allocator.free(target_copy);

        const data_copy = try allocator.dupe(u8, pi_data);
        errdefer allocator.free(data_copy);

        self.* = .{
            .node = node,
            .allocator = allocator,
            .pi_target = target_copy,
            .pi_data = data_copy,
        };

        // Store pointer to self in node for cleanup
        node.element_data_ptr = self;

        return self;
    }

    /// Get the processing instruction target
    ///
    /// ## Returns
    ///
    /// The target of the processing instruction.
    pub fn target(self: *const Self) []const u8 {
        return self.pi_target;
    }

    /// Get the processing instruction data
    ///
    /// ## Returns
    ///
    /// The data/content of the processing instruction.
    pub fn data(self: *const Self) []const u8 {
        return self.pi_data;
    }

    /// Set the processing instruction data
    ///
    /// ## Parameters
    ///
    /// - `new_data`: New data to set
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If memory allocation fails
    pub fn setData(self: *Self, new_data: []const u8) !void {
        const data_copy = try self.allocator.dupe(u8, new_data);
        self.allocator.free(self.pi_data);
        self.pi_data = data_copy;
    }

    /// Release the ProcessingInstruction (decrements reference count)
    ///
    /// This should be called when done with the ProcessingInstruction.
    /// The actual cleanup happens when reference count reaches zero.
    pub fn release(self: *Self) void {
        self.node.release();
    }

    /// Clean up the ProcessingInstruction (called by Node when ref count = 0)
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.pi_target);
        self.allocator.free(self.pi_data);
        self.allocator.destroy(self);
    }
};

// Tests
test "ProcessingInstruction XML stylesheet" {
    const allocator = std.testing.allocator;

    const pi = try ProcessingInstruction.init(
        allocator,
        "xml-stylesheet",
        "type=\"text/css\" href=\"style.css\"",
    );
    defer pi.release();

    try std.testing.expectEqualStrings("xml-stylesheet", pi.target());
    try std.testing.expectEqualStrings("type=\"text/css\" href=\"style.css\"", pi.data());
    try std.testing.expectEqual(NodeType.processing_instruction_node, pi.node.node_type);
}

test "ProcessingInstruction PHP" {
    const allocator = std.testing.allocator;

    const pi = try ProcessingInstruction.init(
        allocator,
        "php",
        "echo 'Hello World';",
    );
    defer pi.release();

    try std.testing.expectEqualStrings("php", pi.target());
    try std.testing.expectEqualStrings("echo 'Hello World';", pi.data());
}

test "ProcessingInstruction empty data" {
    const allocator = std.testing.allocator;

    const pi = try ProcessingInstruction.init(allocator, "target", "");
    defer pi.release();

    try std.testing.expectEqualStrings("target", pi.target());
    try std.testing.expectEqualStrings("", pi.data());
}

test "ProcessingInstruction node properties" {
    const allocator = std.testing.allocator;

    const pi = try ProcessingInstruction.init(allocator, "xml-stylesheet", "href=\"style.css\"");
    defer pi.release();

    // Node should have correct type
    try std.testing.expectEqual(NodeType.processing_instruction_node, pi.node.node_type);

    // Node name should match target
    try std.testing.expectEqualStrings("xml-stylesheet", pi.node.node_name);

    // PI nodes don't have children
    try std.testing.expectEqual(@as(usize, 0), pi.node.child_nodes.length());
}

test "ProcessingInstruction setData" {
    const allocator = std.testing.allocator;

    const pi = try ProcessingInstruction.init(allocator, "xml", "version=\"1.0\"");
    defer pi.release();

    try std.testing.expectEqualStrings("version=\"1.0\"", pi.data());

    try pi.setData("version=\"1.1\" encoding=\"UTF-8\"");
    try std.testing.expectEqualStrings("version=\"1.1\" encoding=\"UTF-8\"", pi.data());
}

test "ProcessingInstruction reference counting" {
    const allocator = std.testing.allocator;

    const pi = try ProcessingInstruction.init(allocator, "xml", "version=\"1.0\"");

    // Initial ref count is 1
    try std.testing.expectEqual(@as(usize, 1), pi.node.ref_count);

    // Retain increases ref count
    pi.node.retain();
    try std.testing.expectEqual(@as(usize, 2), pi.node.ref_count);

    // Release decreases ref count
    pi.release();
    try std.testing.expectEqual(@as(usize, 1), pi.node.ref_count);

    // Final release (cleans up)
    pi.release();
}

test "ProcessingInstruction memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const pi = try ProcessingInstruction.init(
            allocator,
            "xml-stylesheet",
            "type=\"text/xsl\" href=\"transform.xsl\"",
        );
        pi.release();
    }
}
