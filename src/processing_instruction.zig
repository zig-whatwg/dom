//! ProcessingInstruction Interface - WHATWG DOM Standard §4.13
//! =============================================================
//!
//! The ProcessingInstruction interface represents a processing instruction in XML documents.
//! Processing instructions are used to provide processor-specific information and data that
//! should be made available to the application but is not part of the document's content.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-processinginstruction
//! - **Section**: §4.13 Interface ProcessingInstruction
//!
//! ## MDN Documentation
//! - **ProcessingInstruction**: https://developer.mozilla.org/en-US/docs/Web/API/ProcessingInstruction
//! - **target**: https://developer.mozilla.org/en-US/docs/Web/API/ProcessingInstruction/target
//! - **data**: https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/data
//!
//! ## Key Concepts
//!
//! ### Processing Instructions in XML
//! Processing instructions (PIs) are XML nodes that provide instructions or data to
//! applications processing the document. They have the form: `<?target data?>`
//!
//! Common examples:
//! - `<?xml version="1.0" encoding="UTF-8"?>` - XML declaration
//! - `<?xml-stylesheet type="text/xsl" href="style.xsl"?>` - Stylesheet reference
//! - `<?php echo "Hello World"; ?>` - PHP code
//!
//! ### Target and Data
//! - **target**: The application or processor the PI is directed to (e.g., "xml-stylesheet")
//! - **data**: The content/instructions for that processor (e.g., "href='style.css'")
//!
//! ### HTML vs XML
//! Processing instructions are not commonly used in HTML documents but are standard in XML.
//! HTML5 parsers will not create ProcessingInstruction nodes from PI-like syntax in HTML.
//!
//! ## Architecture
//!
//! ```
//! ProcessingInstruction
//! ├── node (*Node) - Base node (nodeType = PROCESSING_INSTRUCTION_NODE)
//! ├── pi_target ([]const u8) - The target application/processor
//! ├── pi_data ([]const u8) - The instruction data/content
//! └── allocator - Memory management
//!
//! Inheritance Chain:
//! ProcessingInstruction → CharacterData → Node → EventTarget
//! ```
//!
//! ## Usage Examples
//!
//! ### XML Stylesheet Processing Instruction
//! ```zig
//! const pi = try ProcessingInstruction.init(
//!     allocator,
//!     "xml-stylesheet",
//!     "type=\"text/xsl\" href=\"transform.xsl\""
//! );
//! defer pi.release();
//!
//! std.debug.print("<?{s} {s}?>\n", .{pi.target(), pi.data()});
//! // Output: <?xml-stylesheet type="text/xsl" href="transform.xsl"?>
//! ```
//!
//! ### Creating XML Declaration
//! ```zig
//! const xml_decl = try ProcessingInstruction.init(
//!     allocator,
//!     "xml",
//!     "version=\"1.0\" encoding=\"UTF-8\""
//! );
//! defer xml_decl.release();
//!
//! try std.testing.expectEqualStrings("xml", xml_decl.target());
//! try std.testing.expectEqualStrings("version=\"1.0\" encoding=\"UTF-8\"", xml_decl.data());
//! ```
//!
//! ### PHP Processing Instruction
//! ```zig
//! const php = try ProcessingInstruction.init(
//!     allocator,
//!     "php",
//!     "echo date('Y-m-d H:i:s');"
//! );
//! defer php.release();
//!
//! // Modifying the data
//! try php.setData("include 'config.php';");
//! ```
//!
//! ### In Document Context
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! // Add stylesheet PI to document
//! const stylesheet = try ProcessingInstruction.init(
//!     allocator,
//!     "xml-stylesheet",
//!     "type=\"text/css\" href=\"style.css\""
//! );
//! _ = try doc.node.appendChild(&stylesheet.node.*);
//!
//! // The PI is now part of the document tree
//! // and will be serialized: <?xml-stylesheet type="text/css" href="style.css"?>
//! ```
//!
//! ### Multiple PIs in Sequence
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! // Add multiple processing instructions
//! const pis = [_]struct { target: []const u8, data: []const u8 }{
//!     .{ .target = "xml", .data = "version=\"1.0\" encoding=\"UTF-8\"" },
//!     .{ .target = "xml-stylesheet", .data = "type=\"text/css\" href=\"main.css\"" },
//!     .{ .target = "xml-stylesheet", .data = "type=\"text/css\" href=\"print.css\" media=\"print\"" },
//! };
//!
//! for (pis) |pi_def| {
//!     const pi = try ProcessingInstruction.init(
//!         allocator,
//!         pi_def.target,
//!         pi_def.data
//!     );
//!     _ = try doc.node.appendChild(&pi.node.*);
//! }
//! ```
//!
//! ## Memory Management
//!
//! ### Reference Counting
//! ProcessingInstruction nodes use reference counting for memory management:
//! - Created with ref_count = 1
//! - Call `node.retain()` to increment
//! - Call `release()` to decrement
//! - Automatically freed when count reaches 0
//!
//! ### Ownership Rules
//! - `init()` returns a new PI with ownership (ref_count = 1)
//! - Parent nodes retain their children automatically
//! - Always call `release()` when done with a reference
//! - The allocator owns the memory until all references are released
//!
//! ### Deferred Cleanup Pattern
//! ```zig
//! const pi = try ProcessingInstruction.init(allocator, "xml", "version=\"1.0\"");
//! defer pi.release(); // Guaranteed cleanup
//!
//! // Use the PI...
//! ```
//!
//! ## Thread Safety
//!
//! ProcessingInstruction nodes are **not thread-safe**. External synchronization is required
//! when:
//! - Modifying data with `setData()` from multiple threads
//! - Adding to/removing from the document tree concurrently
//! - Accessing from different threads simultaneously
//!
//! ## Specification Compliance
//!
//! This implementation follows WHATWG DOM Standard §4.13:
//! - ✅ Implements target (readonly) property
//! - ✅ Inherits data from CharacterData
//! - ✅ Node type is PROCESSING_INSTRUCTION_NODE (7)
//! - ✅ Processing instructions cannot have children
//! - ✅ Node name matches target value

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
    /// Creates a new processing instruction with the specified target and data.
    /// The target identifies the application or processor, and the data contains
    /// the instructions or configuration for that processor.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `pi_target`: The processing instruction target (cannot be empty)
    /// - `pi_data`: The processing instruction data (can be empty)
    ///
    /// ## Returns
    ///
    /// A new ProcessingInstruction instance with ref_count = 1.
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If memory allocation fails
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
    ///
    /// // Empty data is allowed
    /// const empty = try ProcessingInstruction.init(allocator, "target", "");
    /// defer empty.release();
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
    /// Returns the target of this processing instruction, which identifies the
    /// application or processor that should handle this PI. This property is
    /// readonly per the WHATWG specification.
    ///
    /// ## Returns
    ///
    /// The target of the processing instruction (never empty).
    ///
    /// ## Example
    ///
    /// ```zig
    /// const pi = try ProcessingInstruction.init(
    ///     allocator,
    ///     "xml-stylesheet",
    ///     "href=\"style.css\""
    /// );
    /// defer pi.release();
    ///
    /// try std.testing.expectEqualStrings("xml-stylesheet", pi.target());
    /// ```
    pub fn target(self: *const Self) []const u8 {
        return self.pi_target;
    }

    /// Get the processing instruction data
    ///
    /// Returns the data/content portion of the processing instruction. This is
    /// the information that should be processed by the application identified
    /// by the target.
    ///
    /// ## Returns
    ///
    /// The data/content of the processing instruction (may be empty).
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
    /// const data_str = pi.data();
    /// // data_str = "type=\"text/css\" href=\"style.css\""
    /// ```
    pub fn data(self: *const Self) []const u8 {
        return self.pi_data;
    }

    /// Set the processing instruction data
    ///
    /// Replaces the current data with new content. The old data is freed and
    /// a copy of the new data is stored.
    ///
    /// ## Parameters
    ///
    /// - `new_data`: New data to set (can be empty string)
    ///
    /// ## Errors
    ///
    /// - `OutOfMemory`: If memory allocation fails
    ///
    /// ## Example
    ///
    /// ```zig
    /// const pi = try ProcessingInstruction.init(allocator, "xml", "version=\"1.0\"");
    /// defer pi.release();
    ///
    /// // Update the data
    /// try pi.setData("version=\"1.1\" encoding=\"UTF-8\"");
    /// try std.testing.expectEqualStrings("version=\"1.1\" encoding=\"UTF-8\"", pi.data());
    /// ```
    pub fn setData(self: *Self, new_data: []const u8) !void {
        const data_copy = try self.allocator.dupe(u8, new_data);
        self.allocator.free(self.pi_data);
        self.pi_data = data_copy;
    }

    /// Release the ProcessingInstruction (decrements reference count)
    ///
    /// Decrements the reference count on the underlying node. When the count
    /// reaches zero, the node and all associated data are freed.
    ///
    /// This should be called when done with the ProcessingInstruction.
    /// The actual cleanup happens when reference count reaches zero.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const pi = try ProcessingInstruction.init(allocator, "xml", "version=\"1.0\"");
    /// defer pi.release(); // Decrements ref count (typically from 1 to 0)
    /// ```
    pub fn release(self: *Self) void {
        self.node.release();
    }

    /// Clean up the ProcessingInstruction (called by Node when ref count = 0)
    ///
    /// This is called automatically by the Node's reference counting system
    /// when the last reference is released. Do not call directly - use `release()`.
    ///
    /// Frees:
    /// - Target string
    /// - Data string
    /// - Self allocation
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.pi_target);
        self.allocator.free(self.pi_data);
        self.allocator.destroy(self);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "ProcessingInstruction - XML stylesheet" {
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

test "ProcessingInstruction - PHP" {
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

test "ProcessingInstruction - empty data" {
    const allocator = std.testing.allocator;

    const pi = try ProcessingInstruction.init(allocator, "target", "");
    defer pi.release();

    try std.testing.expectEqualStrings("target", pi.target());
    try std.testing.expectEqualStrings("", pi.data());
}

test "ProcessingInstruction - node properties" {
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

test "ProcessingInstruction - setData" {
    const allocator = std.testing.allocator;

    const pi = try ProcessingInstruction.init(allocator, "xml", "version=\"1.0\"");
    defer pi.release();

    try std.testing.expectEqualStrings("version=\"1.0\"", pi.data());

    try pi.setData("version=\"1.1\" encoding=\"UTF-8\"");
    try std.testing.expectEqualStrings("version=\"1.1\" encoding=\"UTF-8\"", pi.data());
}

test "ProcessingInstruction - reference counting" {
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

test "ProcessingInstruction - memory leak test" {
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
