//! NamedNodeMap and Attr Implementation
//!
//! This module implements the WHATWG DOM Standard's `NamedNodeMap` (§4.9.1) and
//! `Attr` (§4.9.2) interfaces. NamedNodeMap represents a collection of attributes,
//! providing named access to attribute nodes.
//!
//! ## WHATWG DOM Standard
//!
//! NamedNodeMap is used to represent an element's attributes in a way that allows
//! both indexed and named access. It is returned by `Element.attributes`.
//!
//! ## Key Characteristics
//!
//! - **Named Access**: Attributes accessed by name
//! - **Indexed Access**: Also accessible by numeric index
//! - **Live Collection**: Reflects current state of element attributes
//! - **Order Preserving**: Maintains attribute insertion order
//! - **Name-Based Identity**: Attributes identified by name
//!
//! ## Attr vs Attribute String
//!
//! The Attr interface represents an attribute as an object with both name and value,
//! while many DOM methods accept/return attribute values as simple strings. Both
//! approaches are supported throughout the API.
//!
//! ## Examples
//!
//! ### Basic Attribute Map Usage
//! ```zig
//! var attrs = NamedNodeMap.init(allocator);
//! defer attrs.deinit();
//!
//! const id_attr = try Attr.init(allocator, "id", "myid");
//! _ = try attrs.setNamedItem(id_attr);
//!
//! if (attrs.getNamedItem("id")) |attr| {
//!     try expectEqualStrings("myid", attr.value);
//! }
//! ```
//!
//! ### Iteration
//! ```zig
//! for (0..attrs.length()) |i| {
//!     if (attrs.item(i)) |attr| {
//!         // Process each attribute
//!     }
//! }
//! ```
//!
//! ## Specification References
//!
//! - WHATWG DOM §4.9.1: https://dom.spec.whatwg.org/#interface-namednodemap
//! - WHATWG DOM §4.9.2: https://dom.spec.whatwg.org/#interface-attr
//! - MDN (NamedNodeMap): https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap
//! - MDN (Attr): https://developer.mozilla.org/en-US/docs/Web/API/Attr

const std = @import("std");

/// Attr represents an attribute node with a name and value.
///
/// ## WHATWG DOM Standard §4.9.2
///
/// Attributes are name-value pairs associated with elements. While most DOM
/// operations use attributes as strings, the Attr interface provides an object
/// representation for more complex attribute manipulation.
///
/// ## Key Features
///
/// - **Name**: Attribute name (immutable after creation)
/// - **Value**: Attribute value (mutable)
/// - **Independence**: Can exist independently of elements
/// - **Memory**: Manages own memory for name and value strings
pub const Attr = struct {
    /// Attribute name (immutable).
    name: []const u8,

    /// Attribute value (mutable via setValue).
    value: []const u8,

    /// Allocator used for memory management.
    allocator: std.mem.Allocator,

    /// Creates a new attribute with the given name and value.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `name`: Attribute name (copied internally)
    /// - `value`: Initial attribute value (copied internally)
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const attr = try Attr.init(allocator, "id", "myid");
    /// defer attr.deinit();
    /// try expectEqualStrings("id", attr.name);
    /// try expectEqualStrings("myid", attr.value);
    /// ```
    pub fn init(allocator: std.mem.Allocator, name: []const u8, value: []const u8) !*Attr {
        const self = try allocator.create(Attr);
        self.* = .{
            .name = try allocator.dupe(u8, name),
            .value = try allocator.dupe(u8, value),
            .allocator = allocator,
        };
        return self;
    }

    /// Releases the attribute and its strings.
    pub fn deinit(self: *Attr) void {
        self.allocator.free(self.name);
        self.allocator.free(self.value);
        self.allocator.destroy(self);
    }

    /// Updates the attribute value.
    ///
    /// ## Parameters
    ///
    /// - `value`: New value (replaces old value)
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const attr = try Attr.init(allocator, "class", "old");
    /// defer attr.deinit();
    /// try attr.setValue("new");
    /// try expectEqualStrings("new", attr.value);
    /// ```
    pub fn setValue(self: *Attr, value: []const u8) !void {
        self.allocator.free(self.value);
        self.value = try self.allocator.dupe(u8, value);
    }
};

/// NamedNodeMap represents a collection of Attr nodes accessible by name or index.
///
/// ## WHATWG DOM Standard §4.9.1
///
/// NamedNodeMap provides both named and indexed access to attributes,
/// maintaining insertion order and allowing modification.
///
/// ## Key Features
///
/// - **Dual Access**: By name or by index
/// - **Dynamic**: Grows/shrinks as attributes are added/removed
/// - **Live**: Reflects current state
/// - **Ownership**: Manages memory for all contained attributes
pub const NamedNodeMap = struct {
    const Self = @This();

    /// Internal storage for attributes.
    attrs: std.ArrayList(*Attr),

    /// Allocator for the collection.
    allocator: std.mem.Allocator,

    /// Creates a new empty attribute map.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// var map = NamedNodeMap.init(allocator);
    /// defer map.deinit();
    /// try expect(map.length() == 0);
    /// ```
    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .attrs = std.ArrayList(*Attr){},
            .allocator = allocator,
        };
    }

    /// Releases the map and all contained attributes.
    ///
    /// ## Important
    ///
    /// This releases all Attr objects in the map. Do not call deinit()
    /// on attributes after the map is destroyed.
    pub fn deinit(self: *Self) void {
        for (self.attrs.items) |attr| {
            attr.deinit();
        }
        self.attrs.deinit(self.allocator);
    }

    /// Returns the number of attributes in the map.
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.9.1: NamedNodeMap.length
    pub fn length(self: *const Self) usize {
        return self.attrs.items.len;
    }

    /// Returns the attribute at the specified index.
    ///
    /// ## Parameters
    ///
    /// - `index`: 0-based index
    ///
    /// ## Returns
    ///
    /// The attribute at index, or null if out of bounds.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const attr = map.item(0);
    /// if (attr) |a| {
    ///     // Use attribute
    /// }
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.9.1: NamedNodeMap.item()
    pub fn item(self: *const Self, index: usize) ?*Attr {
        if (index >= self.attrs.items.len) {
            return null;
        }
        return self.attrs.items[index];
    }

    /// Returns the attribute with the specified name.
    ///
    /// ## Parameters
    ///
    /// - `name`: Attribute name to search for
    ///
    /// ## Returns
    ///
    /// The attribute with matching name, or null if not found.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// if (map.getNamedItem("id")) |attr| {
    ///     // Found id attribute
    /// }
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.9.1: NamedNodeMap.getNamedItem()
    pub fn getNamedItem(self: *const Self, name: []const u8) ?*Attr {
        for (self.attrs.items) |attr| {
            if (std.mem.eql(u8, attr.name, name)) {
                return attr;
            }
        }
        return null;
    }

    /// Sets an attribute, replacing any existing attribute with the same name.
    ///
    /// ## Parameters
    ///
    /// - `attr`: Attribute to set (ownership transferred to map)
    ///
    /// ## Returns
    ///
    /// The old attribute if replaced, or null if this is a new attribute.
    /// Caller must deinit() the returned attribute if non-null.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const attr = try Attr.init(allocator, "id", "myid");
    /// const old = try map.setNamedItem(attr);
    /// if (old) |o| {
    ///     o.deinit(); // Clean up replaced attribute
    /// }
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.9.1: NamedNodeMap.setNamedItem()
    pub fn setNamedItem(self: *Self, attr: *Attr) !?*Attr {
        for (self.attrs.items, 0..) |existing_attr, i| {
            if (std.mem.eql(u8, existing_attr.name, attr.name)) {
                const old_attr = self.attrs.items[i];
                self.attrs.items[i] = attr;
                return old_attr;
            }
        }
        try self.attrs.append(self.allocator, attr);
        return null;
    }

    /// Removes the attribute with the specified name.
    ///
    /// ## Parameters
    ///
    /// - `name`: Name of attribute to remove
    ///
    /// ## Returns
    ///
    /// The removed attribute. Caller must deinit() it.
    ///
    /// ## Errors
    ///
    /// - `NotFoundError`: If no attribute with that name exists
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const removed = try map.removeNamedItem("id");
    /// defer removed.deinit();
    /// ```
    ///
    /// ## Specification
    ///
    /// - WHATWG DOM §4.9.1: NamedNodeMap.removeNamedItem()
    pub fn removeNamedItem(self: *Self, name: []const u8) !*Attr {
        for (self.attrs.items, 0..) |attr, i| {
            if (std.mem.eql(u8, attr.name, name)) {
                return self.attrs.orderedRemove(i);
            }
        }
        return error.NotFoundError;
    }

    /// Checks if an attribute with the given name exists.
    pub fn hasNamedItem(self: *const Self, name: []const u8) bool {
        return self.getNamedItem(name) != null;
    }

    /// Removes all attributes from the map.
    pub fn clear(self: *Self) void {
        for (self.attrs.items) |attr| {
            attr.deinit();
        }
        self.attrs.clearRetainingCapacity();
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Attr creation and access" {
    const allocator = std.testing.allocator;

    const attr = try Attr.init(allocator, "id", "test");
    defer attr.deinit();

    try std.testing.expectEqualStrings("id", attr.name);
    try std.testing.expectEqualStrings("test", attr.value);
}

test "Attr setValue" {
    const allocator = std.testing.allocator;

    const attr = try Attr.init(allocator, "class", "old");
    defer attr.deinit();

    try attr.setValue("new");
    try std.testing.expectEqualStrings("new", attr.value);
    try std.testing.expectEqualStrings("class", attr.name); // Name unchanged
}

test "NamedNodeMap basic operations" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    try std.testing.expectEqual(@as(usize, 0), map.length());

    const attr1 = try Attr.init(allocator, "id", "test");
    _ = try map.setNamedItem(attr1);

    try std.testing.expectEqual(@as(usize, 1), map.length());

    const found = map.getNamedItem("id");
    try std.testing.expect(found != null);
    try std.testing.expectEqualStrings("test", found.?.value);

    const attr2 = try Attr.init(allocator, "class", "container");
    _ = try map.setNamedItem(attr2);

    try std.testing.expectEqual(@as(usize, 2), map.length());

    const removed = try map.removeNamedItem("id");
    removed.deinit();

    try std.testing.expectEqual(@as(usize, 1), map.length());
    try std.testing.expect(map.getNamedItem("id") == null);
}

test "NamedNodeMap replace attribute" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    const attr1 = try Attr.init(allocator, "id", "old");
    _ = try map.setNamedItem(attr1);

    const attr2 = try Attr.init(allocator, "id", "new");
    const old = try map.setNamedItem(attr2);

    try std.testing.expect(old != null);
    try std.testing.expectEqualStrings("old", old.?.value);
    old.?.deinit();

    const current = map.getNamedItem("id");
    try std.testing.expectEqualStrings("new", current.?.value);
}

test "NamedNodeMap item access" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    const attr1 = try Attr.init(allocator, "id", "test");
    const attr2 = try Attr.init(allocator, "class", "container");

    _ = try map.setNamedItem(attr1);
    _ = try map.setNamedItem(attr2);

    // Access by index
    const first = map.item(0);
    try std.testing.expect(first != null);

    const second = map.item(1);
    try std.testing.expect(second != null);

    const invalid = map.item(10);
    try std.testing.expect(invalid == null);
}

test "NamedNodeMap remove non-existent" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    try std.testing.expectError(error.NotFoundError, map.removeNamedItem("nonexistent"));
}

test "NamedNodeMap hasNamedItem" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    const attr = try Attr.init(allocator, "id", "test");
    _ = try map.setNamedItem(attr);

    try std.testing.expect(map.hasNamedItem("id"));
    try std.testing.expect(!map.hasNamedItem("class"));
}

test "NamedNodeMap clear" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    _ = try map.setNamedItem(try Attr.init(allocator, "id", "test"));
    _ = try map.setNamedItem(try Attr.init(allocator, "class", "container"));

    try std.testing.expectEqual(@as(usize, 2), map.length());

    map.clear();
    try std.testing.expectEqual(@as(usize, 0), map.length());
}

test "NamedNodeMap multiple attributes" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    const names = [_][]const u8{ "id", "class", "data-test", "role", "title" };
    for (names) |name| {
        const attr = try Attr.init(allocator, name, "value");
        _ = try map.setNamedItem(attr);
    }

    try std.testing.expectEqual(@as(usize, 5), map.length());

    for (names) |name| {
        try std.testing.expect(map.getNamedItem(name) != null);
    }
}

test "NamedNodeMap iteration" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    _ = try map.setNamedItem(try Attr.init(allocator, "a", "1"));
    _ = try map.setNamedItem(try Attr.init(allocator, "b", "2"));
    _ = try map.setNamedItem(try Attr.init(allocator, "c", "3"));

    var count: usize = 0;
    var i: usize = 0;
    while (i < map.length()) : (i += 1) {
        if (map.item(i)) |_| {
            count += 1;
        }
    }

    try std.testing.expectEqual(@as(usize, 3), count);
}

test "NamedNodeMap memory leak test" {
    const allocator = std.testing.allocator;

    var iteration: usize = 0;
    while (iteration < 100) : (iteration += 1) {
        var map = NamedNodeMap.init(allocator);
        defer map.deinit();

        _ = try map.setNamedItem(try Attr.init(allocator, "id", "test"));
        _ = try map.setNamedItem(try Attr.init(allocator, "class", "container"));

        const removed = try map.removeNamedItem("id");
        removed.deinit();
    }
}

test "NamedNodeMap order preservation" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    _ = try map.setNamedItem(try Attr.init(allocator, "first", "1"));
    _ = try map.setNamedItem(try Attr.init(allocator, "second", "2"));
    _ = try map.setNamedItem(try Attr.init(allocator, "third", "3"));

    try std.testing.expectEqualStrings("first", map.item(0).?.name);
    try std.testing.expectEqualStrings("second", map.item(1).?.name);
    try std.testing.expectEqualStrings("third", map.item(2).?.name);
}

test "NamedNodeMap case sensitivity" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    _ = try map.setNamedItem(try Attr.init(allocator, "id", "lowercase"));
    _ = try map.setNamedItem(try Attr.init(allocator, "ID", "uppercase"));

    try std.testing.expectEqual(@as(usize, 2), map.length());
    try std.testing.expect(map.getNamedItem("id") != null);
    try std.testing.expect(map.getNamedItem("ID") != null);
}

test "Attr empty values" {
    const allocator = std.testing.allocator;

    const attr = try Attr.init(allocator, "data-empty", "");
    defer attr.deinit();

    try std.testing.expectEqualStrings("data-empty", attr.name);
    try std.testing.expectEqualStrings("", attr.value);

    try attr.setValue("not empty");
    try std.testing.expectEqualStrings("not empty", attr.value);
}

test "NamedNodeMap empty map operations" {
    const allocator = std.testing.allocator;

    var map = NamedNodeMap.init(allocator);
    defer map.deinit();

    try std.testing.expectEqual(@as(usize, 0), map.length());
    try std.testing.expect(map.item(0) == null);
    try std.testing.expect(map.getNamedItem("anything") == null);
    try std.testing.expectError(error.NotFoundError, map.removeNamedItem("anything"));
}
