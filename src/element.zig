//! Element implementation - represents an element node in the DOM tree.
//!
//! This module implements the WHATWG DOM Element interface with:
//! - Tag name storage (interned string pointer)
//! - Attribute map (name→value pairs)
//! - Bloom filter for fast class matching (8 bytes)
//! - Vtable implementation for polymorphic Node behavior
//!
//! Spec: WHATWG DOM §4.9 (https://dom.spec.whatwg.org/#interface-element)

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;

/// Bloom filter for fast class name matching in querySelector.
///
/// Uses 64 bits to probabilistically track which class names are present.
/// False positives possible (may say "yes" when it's "no"), but no false negatives.
/// This allows rejecting 80-90% of non-matching elements without full string comparison.
pub const BloomFilter = struct {
    bits: u64 = 0,

    /// Adds a class name to the filter.
    pub fn add(self: *BloomFilter, class_name: []const u8) void {
        const hash = std.hash.Wyhash.hash(0, class_name);
        const bit = @as(u6, @truncate(hash));
        self.bits |= @as(u64, 1) << bit;
    }

    /// Returns true if class name MAY be present (false positives possible).
    pub fn mayContain(self: BloomFilter, class_name: []const u8) bool {
        const hash = std.hash.Wyhash.hash(0, class_name);
        const bit = @as(u6, @truncate(hash));
        const mask = @as(u64, 1) << bit;
        return (self.bits & mask) != 0;
    }

    /// Clears all bits in the filter.
    pub fn clear(self: *BloomFilter) void {
        self.bits = 0;
    }
};

/// Attribute map storing name→value pairs.
///
/// Uses StringHashMap for O(1) average-case access.
/// Keys and values are slices (pointers) to interned strings.
pub const AttributeMap = struct {
    map: std.StringHashMap([]const u8),

    pub fn init(allocator: Allocator) AttributeMap {
        return .{
            .map = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *AttributeMap) void {
        self.map.deinit();
    }

    pub fn set(self: *AttributeMap, name: []const u8, value: []const u8) !void {
        try self.map.put(name, value);
    }

    pub fn get(self: *const AttributeMap, name: []const u8) ?[]const u8 {
        return self.map.get(name);
    }

    pub fn remove(self: *AttributeMap, name: []const u8) bool {
        return self.map.remove(name);
    }

    pub fn has(self: *const AttributeMap, name: []const u8) bool {
        return self.map.contains(name);
    }

    pub fn count(self: *const AttributeMap) usize {
        return self.map.count();
    }
};

/// Element node representing an HTML/XML element.
///
/// Embeds Node as first field for vtable polymorphism.
/// Additional fields for element-specific data (tag, attributes, classes).
pub const Element = struct {
    /// Base Node (MUST be first field for @fieldParentPtr to work)
    node: Node,

    /// Tag name (pointer to interned string, 8 bytes)
    /// e.g., "div", "span", "custom-element"
    tag_name: []const u8,

    /// Attribute map (16 bytes)
    /// Stores name→value pairs (both interned strings)
    attributes: AttributeMap,

    /// Bloom filter for class names (8 bytes)
    /// Enables fast rejection in querySelector(".class")
    class_bloom: BloomFilter,

    /// Vtable for Element nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
    };

    /// Creates a new Element with the specified tag name.
    ///
    /// ## Memory Management
    /// Returns Element with ref_count=1. Caller MUST call `element.node.release()`.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for element creation
    /// - `tag_name`: Element tag name (should be interned string)
    ///
    /// ## Returns
    /// New element node with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const elem = try Element.create(allocator, "element");
    /// defer elem.node.release();
    /// ```
    pub fn create(allocator: Allocator, tag_name: []const u8) !*Element {
        const elem = try allocator.create(Element);
        errdefer allocator.destroy(elem);

        // Initialize base Node
        elem.node = .{
            .vtable = &vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .element,
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

        // Initialize Element-specific fields
        elem.tag_name = tag_name;
        elem.attributes = AttributeMap.init(allocator);
        elem.class_bloom = .{};

        return elem;
    }

    /// Sets an attribute on the element.
    ///
    /// Updates bloom filter if setting "class" attribute.
    ///
    /// ## Parameters
    /// - `name`: Attribute name (should be interned string)
    /// - `value`: Attribute value (should be interned string)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate attribute storage
    pub fn setAttribute(self: *Element, name: []const u8, value: []const u8) !void {
        try self.attributes.set(name, value);

        // Update bloom filter for class attribute
        if (std.mem.eql(u8, name, "class")) {
            self.updateClassBloom(value);
        }
    }

    /// Gets an attribute value from the element.
    ///
    /// ## Parameters
    /// - `name`: Attribute name to lookup
    ///
    /// ## Returns
    /// Attribute value or null if not present
    pub fn getAttribute(self: *const Element, name: []const u8) ?[]const u8 {
        return self.attributes.get(name);
    }

    /// Removes an attribute from the element.
    ///
    /// Implements WHATWG DOM Element.removeAttribute() interface.
    /// Per WebIDL spec, this returns void (not bool).
    ///
    /// ## Parameters
    /// - `name`: Attribute name to remove
    pub fn removeAttribute(self: *Element, name: []const u8) void {
        const removed = self.attributes.remove(name);

        // Rebuild bloom filter if removing class attribute
        if (removed and std.mem.eql(u8, name, "class")) {
            self.class_bloom.clear();
            // Note: In full implementation, we'd rebuild from classList
        }
    }

    /// Checks if element has an attribute.
    pub fn hasAttribute(self: *const Element, name: []const u8) bool {
        return self.attributes.has(name);
    }

    /// Returns the number of attributes on the element.
    pub fn attributeCount(self: *const Element) usize {
        return self.attributes.count();
    }

    /// Checks if element has a specific class name (fast path using bloom filter).
    ///
    /// ## Parameters
    /// - `class_name`: Class name to check
    ///
    /// ## Returns
    /// true if class is present, false otherwise
    pub fn hasClass(self: *const Element, class_name: []const u8) bool {
        // Fast path: check bloom filter first
        if (!self.class_bloom.mayContain(class_name)) {
            return false; // Definitely not present
        }

        // Slow path: check actual class attribute
        const class_attr = self.getAttribute("class") orelse return false;

        // Simple check: look for exact match in space-separated list
        // TODO: Implement proper DOMTokenList for classList
        var iter = std.mem.splitSequence(u8, class_attr, " ");
        while (iter.next()) |class| {
            if (std.mem.eql(u8, class, class_name)) {
                return true;
            }
        }

        return false;
    }

    // === WHATWG DOM Convenience Properties ===

    /// Gets the element's id attribute.
    ///
    /// Implements WHATWG DOM Element.id property (getter).
    ///
    /// ## Returns
    /// Element's id attribute value or null if not set
    ///
    /// ## Example
    /// ```zig
    /// const id = elem.getId();
    /// if (id) |id_value| {
    ///     std.debug.print("Element id: {s}\n", .{id_value});
    /// }
    /// ```
    pub fn getId(self: *const Element) ?[]const u8 {
        return self.getAttribute("id");
    }

    /// Sets the element's id attribute.
    ///
    /// Implements WHATWG DOM Element.id property (setter).
    ///
    /// ## Parameters
    /// - `value`: New id value
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate attribute storage
    ///
    /// ## Example
    /// ```zig
    /// try elem.setId("my-element");
    /// ```
    pub fn setId(self: *Element, value: []const u8) !void {
        try self.setAttribute("id", value);
    }

    /// Gets the element's class attribute.
    ///
    /// Implements WHATWG DOM Element.className property (getter).
    ///
    /// ## Returns
    /// Element's class attribute value or empty string if not set
    ///
    /// ## Example
    /// ```zig
    /// const classes = elem.getClassName();
    /// std.debug.print("Classes: {s}\n", .{classes});
    /// ```
    pub fn getClassName(self: *const Element) []const u8 {
        return self.getAttribute("class") orelse "";
    }

    /// Sets the element's class attribute.
    ///
    /// Implements WHATWG DOM Element.className property (setter).
    ///
    /// ## Parameters
    /// - `value`: New class value (space-separated class names)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate attribute storage
    ///
    /// ## Example
    /// ```zig
    /// try elem.setClassName("btn btn-primary active");
    /// ```
    pub fn setClassName(self: *Element, value: []const u8) !void {
        try self.setAttribute("class", value);
    }

    /// Checks if element has any attributes.
    ///
    /// Implements WHATWG DOM Element.hasAttributes() interface.
    ///
    /// ## Returns
    /// true if element has at least one attribute, false otherwise
    ///
    /// ## Example
    /// ```zig
    /// if (elem.hasAttributes()) {
    ///     std.debug.print("Element has attributes\n", .{});
    /// }
    /// ```
    pub fn hasAttributes(self: *const Element) bool {
        return self.attributes.count() > 0;
    }

    /// Returns an array of all attribute names.
    ///
    /// Implements WHATWG DOM Element.getAttributeNames() interface.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for result array
    ///
    /// ## Returns
    /// Owned array of attribute names. Caller must free with allocator.
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate result array
    ///
    /// ## Example
    /// ```zig
    /// const names = try elem.getAttributeNames(allocator);
    /// defer allocator.free(names);
    ///
    /// for (names) |name| {
    ///     std.debug.print("Attribute: {s}\n", .{name});
    /// }
    /// ```
    pub fn getAttributeNames(self: *const Element, allocator: Allocator) ![][]const u8 {
        const count = self.attributes.count();
        if (count == 0) {
            return &[_][]const u8{};
        }

        const names = try allocator.alloc([]const u8, count);
        errdefer allocator.free(names);

        var i: usize = 0;
        var iter = self.attributes.map.keyIterator();
        while (iter.next()) |key| {
            names[i] = key.*;
            i += 1;
        }

        return names;
    }

    // === Private implementation ===

    /// Updates the bloom filter from a class attribute value.
    fn updateClassBloom(self: *Element, class_value: []const u8) void {
        self.class_bloom.clear();

        var iter = std.mem.splitSequence(u8, class_value, " ");
        while (iter.next()) |class| {
            if (class.len > 0) {
                self.class_bloom.add(class);
            }
        }
    }

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const elem: *Element = @fieldParentPtr("node", node);

        // Release document reference if owned by a document
        if (elem.node.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                // Get Document from its node field (node is first field)
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("node", owner_doc);
                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        elem.node.deinitRareData();

        // Release all children
        var current = elem.node.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            child.parent_node = null;
            child.setHasParent(false);
            child.release(); // Release parent's ownership
            current = next;
        }

        elem.attributes.deinit();
        elem.node.allocator.destroy(elem);
    }

    /// Vtable implementation: node name (returns tag name)
    fn nodeNameImpl(node: *const Node) []const u8 {
        const elem: *const Element = @fieldParentPtr("node", node);
        return elem.tag_name;
    }

    /// Vtable implementation: node value (always null for elements)
    fn nodeValueImpl(_: *const Node) ?[]const u8 {
        return null;
    }

    /// Vtable implementation: set node value (no-op for elements)
    fn setNodeValueImpl(_: *Node, _: []const u8) !void {
        // Elements don't have node values, this is a no-op per spec
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        const elem: *const Element = @fieldParentPtr("node", node);

        // Create new element with same tag
        const cloned = try Element.create(elem.node.allocator, elem.tag_name);
        errdefer cloned.node.release();

        // Copy attributes
        var attr_iter = elem.attributes.map.iterator();
        while (attr_iter.next()) |entry| {
            try cloned.setAttribute(entry.key_ptr.*, entry.value_ptr.*);
        }

        // TODO: Deep clone children when deep=true
        _ = deep;

        return &cloned.node;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "BloomFilter - basic operations" {
    var bloom = BloomFilter{};

    // Initially empty
    try std.testing.expect(!bloom.mayContain("foo"));

    // Add class name
    bloom.add("foo");
    try std.testing.expect(bloom.mayContain("foo"));

    // Different class
    bloom.add("bar");
    try std.testing.expect(bloom.mayContain("bar"));
    try std.testing.expect(bloom.mayContain("foo")); // Still present

    // Clear
    bloom.clear();
    try std.testing.expect(!bloom.mayContain("foo"));
    try std.testing.expect(!bloom.mayContain("bar"));
}

test "AttributeMap - basic operations" {
    const allocator = std.testing.allocator;

    var attrs = AttributeMap.init(allocator);
    defer attrs.deinit();

    // Initially empty
    try std.testing.expectEqual(@as(usize, 0), attrs.count());
    try std.testing.expect(attrs.get("id") == null);

    // Set attribute
    try attrs.set("id", "my-id");
    try std.testing.expectEqual(@as(usize, 1), attrs.count());
    try std.testing.expect(attrs.has("id"));
    try std.testing.expectEqualStrings("my-id", attrs.get("id").?);

    // Update attribute
    try attrs.set("id", "new-id");
    try std.testing.expectEqual(@as(usize, 1), attrs.count());
    try std.testing.expectEqualStrings("new-id", attrs.get("id").?);

    // Multiple attributes
    try attrs.set("class", "foo bar");
    try std.testing.expectEqual(@as(usize, 2), attrs.count());

    // Remove attribute
    try std.testing.expect(attrs.remove("id"));
    try std.testing.expectEqual(@as(usize, 1), attrs.count());
    try std.testing.expect(!attrs.has("id"));
    try std.testing.expect(attrs.has("class"));

    // Remove non-existent
    try std.testing.expect(!attrs.remove("missing"));
}

test "Element - creation and cleanup" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.element, elem.node.node_type);
    try std.testing.expectEqual(@as(u32, 1), elem.node.getRefCount());
    try std.testing.expectEqualStrings("element", elem.tag_name);

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("element", elem.node.nodeName());
    try std.testing.expect(elem.node.nodeValue() == null);
}

test "Element - attributes" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no attributes
    try std.testing.expectEqual(@as(usize, 0), elem.attributeCount());
    try std.testing.expect(!elem.hasAttribute("id"));
    try std.testing.expect(elem.getAttribute("id") == null);

    // Set attribute
    try elem.setAttribute("id", "my-div");
    try std.testing.expectEqual(@as(usize, 1), elem.attributeCount());
    try std.testing.expect(elem.hasAttribute("id"));
    try std.testing.expectEqualStrings("my-div", elem.getAttribute("id").?);

    // Set multiple attributes
    try elem.setAttribute("class", "container");
    try elem.setAttribute("data-foo", "bar");
    try std.testing.expectEqual(@as(usize, 3), elem.attributeCount());

    // Remove attribute
    elem.removeAttribute("id");
    try std.testing.expectEqual(@as(usize, 2), elem.attributeCount());
    try std.testing.expect(!elem.hasAttribute("id"));

    // Remove non-existent (no error, per spec)
    elem.removeAttribute("missing");
}

test "Element - class bloom filter" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Set class attribute
    try elem.setAttribute("class", "foo bar baz");

    // Bloom filter should contain all classes
    try std.testing.expect(elem.class_bloom.mayContain("foo"));
    try std.testing.expect(elem.class_bloom.mayContain("bar"));
    try std.testing.expect(elem.class_bloom.mayContain("baz"));

    // hasClass should verify actual presence
    try std.testing.expect(elem.hasClass("foo"));
    try std.testing.expect(elem.hasClass("bar"));
    try std.testing.expect(elem.hasClass("baz"));
    try std.testing.expect(!elem.hasClass("missing"));

    // Update class attribute
    try elem.setAttribute("class", "qux");
    try std.testing.expect(elem.hasClass("qux"));
    try std.testing.expect(!elem.hasClass("foo")); // Old classes gone
}

test "Element - cloneNode shallow" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    try elem.setAttribute("id", "original");
    try elem.setAttribute("class", "foo bar");

    // Clone (shallow)
    const cloned_node = try elem.node.cloneNode(false);
    defer cloned_node.release();

    const cloned: *Element = @fieldParentPtr("node", cloned_node);

    // Verify clone properties
    try std.testing.expectEqualStrings("element", cloned.tag_name);
    try std.testing.expectEqual(@as(usize, 2), cloned.attributeCount());
    try std.testing.expectEqualStrings("original", cloned.getAttribute("id").?);
    try std.testing.expectEqualStrings("foo bar", cloned.getAttribute("class").?);

    // Verify independent ref counts
    try std.testing.expectEqual(@as(u32, 1), elem.node.getRefCount());
    try std.testing.expectEqual(@as(u32, 1), cloned.node.getRefCount());
}

test "Element - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple creation
    {
        const elem = try Element.create(allocator, "element");
        defer elem.node.release();
    }

    // Test 2: With attributes
    {
        const elem = try Element.create(allocator, "element");
        defer elem.node.release();

        try elem.setAttribute("id", "test");
        try elem.setAttribute("class", "foo bar");
        try elem.setAttribute("data-value", "123");
    }

    // Test 3: Clone
    {
        const elem = try Element.create(allocator, "item");
        defer elem.node.release();

        try elem.setAttribute("id", "original");

        const cloned = try elem.node.cloneNode(false);
        defer cloned.release();
    }

    // Test 4: Multiple acquire/release
    {
        const elem = try Element.create(allocator, "p");
        defer elem.node.release();

        elem.node.acquire();
        defer elem.node.release();

        elem.node.acquire();
        defer elem.node.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Element - ref counting" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initial ref count
    try std.testing.expectEqual(@as(u32, 1), elem.node.getRefCount());

    // Acquire
    elem.node.acquire();
    try std.testing.expectEqual(@as(u32, 2), elem.node.getRefCount());

    // Release
    elem.node.release();
    try std.testing.expectEqual(@as(u32, 1), elem.node.getRefCount());
}

test "Element - id property" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no id
    try std.testing.expect(elem.getId() == null);

    // Set id
    try elem.setId("my-element");
    try std.testing.expectEqualStrings("my-element", elem.getId().?);

    // Change id
    try elem.setId("other-id");
    try std.testing.expectEqualStrings("other-id", elem.getId().?);

    // Verify it's the same as getAttribute
    try std.testing.expectEqualStrings("other-id", elem.getAttribute("id").?);
}

test "Element - className property" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no class (returns empty string)
    try std.testing.expectEqualStrings("", elem.getClassName());

    // Set className
    try elem.setClassName("btn btn-primary");
    try std.testing.expectEqualStrings("btn btn-primary", elem.getClassName());

    // Change className
    try elem.setClassName("active");
    try std.testing.expectEqualStrings("active", elem.getClassName());

    // Verify it's the same as getAttribute
    try std.testing.expectEqualStrings("active", elem.getAttribute("class").?);
}

test "Element - hasAttributes" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no attributes
    try std.testing.expect(!elem.hasAttributes());

    // Add attribute
    try elem.setAttribute("id", "test");
    try std.testing.expect(elem.hasAttributes());

    // Add more attributes
    try elem.setAttribute("class", "foo");
    try std.testing.expect(elem.hasAttributes());

    // Remove all attributes
    elem.removeAttribute("id");
    elem.removeAttribute("class");
    try std.testing.expect(!elem.hasAttributes());
}

test "Element - getAttributeNames" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no attributes
    {
        const names = try elem.getAttributeNames(allocator);
        defer if (names.len > 0) allocator.free(names);
        try std.testing.expectEqual(@as(usize, 0), names.len);
    }

    // Add attributes
    try elem.setAttribute("id", "test");
    try elem.setAttribute("class", "foo bar");
    try elem.setAttribute("data-value", "123");

    // Get attribute names
    {
        const names = try elem.getAttributeNames(allocator);
        defer allocator.free(names);

        try std.testing.expectEqual(@as(usize, 3), names.len);

        // Verify all names are present (order may vary)
        var found_id = false;
        var found_class = false;
        var found_data = false;

        for (names) |name| {
            if (std.mem.eql(u8, name, "id")) found_id = true;
            if (std.mem.eql(u8, name, "class")) found_class = true;
            if (std.mem.eql(u8, name, "data-value")) found_data = true;
        }

        try std.testing.expect(found_id);
        try std.testing.expect(found_class);
        try std.testing.expect(found_data);
    }
}
