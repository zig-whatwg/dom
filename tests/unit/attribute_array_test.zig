const std = @import("std");
const dom = @import("dom");
const AttributeArray = dom.attribute_array.AttributeArray;

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualStrings = testing.expectEqualStrings;

test "AttributeArray: init creates empty array" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try expectEqual(@as(usize, 0), attrs.count());
    try expectEqual(@as(u8, 0), attrs.inline_count);
}

test "AttributeArray: set and get single attribute" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try attrs.set("class", null, "container");

    try expectEqual(@as(usize, 1), attrs.count());
    const value = attrs.get("class", null);
    try expect(value != null);
    try expectEqualStrings("container", value.?);
}

test "AttributeArray: inline storage for 4 attributes" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try attrs.set("a", null, "1");
    try attrs.set("b", null, "2");
    try attrs.set("c", null, "3");
    try attrs.set("d", null, "4");

    // All in inline storage
    try expectEqual(@as(usize, 4), attrs.count());
    try expectEqual(@as(u8, 4), attrs.inline_count);
    try expectEqual(@as(usize, 0), attrs.attributes.items.len);

    // Verify all values
    try expectEqualStrings("1", attrs.get("a", null).?);
    try expectEqualStrings("2", attrs.get("b", null).?);
    try expectEqualStrings("3", attrs.get("c", null).?);
    try expectEqualStrings("4", attrs.get("d", null).?);
}

test "AttributeArray: migration to heap on 5th attribute" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    // Fill inline storage
    try attrs.set("a", null, "1");
    try attrs.set("b", null, "2");
    try attrs.set("c", null, "3");
    try attrs.set("d", null, "4");

    // 5th attribute triggers migration
    try attrs.set("e", null, "5");

    // Now using heap
    try expectEqual(@as(usize, 5), attrs.count());
    try expectEqual(@as(u8, 0), attrs.inline_count); // Mark for heap
    try expectEqual(@as(usize, 5), attrs.attributes.items.len);

    // Verify all values still accessible
    try expectEqualStrings("1", attrs.get("a", null).?);
    try expectEqualStrings("2", attrs.get("b", null).?);
    try expectEqualStrings("3", attrs.get("c", null).?);
    try expectEqualStrings("4", attrs.get("d", null).?);
    try expectEqualStrings("5", attrs.get("e", null).?);
}

test "AttributeArray: set replaces existing value" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try attrs.set("class", null, "old");
    try expectEqualStrings("old", attrs.get("class", null).?);

    try attrs.set("class", null, "new");
    try expectEqualStrings("new", attrs.get("class", null).?);

    // Count unchanged
    try expectEqual(@as(usize, 1), attrs.count());
}

test "AttributeArray: remove from inline storage" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try attrs.set("a", null, "1");
    try attrs.set("b", null, "2");
    try attrs.set("c", null, "3");

    const removed = attrs.remove("b", null);
    try expect(removed);

    try expectEqual(@as(usize, 2), attrs.count());
    try expect(attrs.get("b", null) == null);
    try expectEqualStrings("1", attrs.get("a", null).?);
    try expectEqualStrings("3", attrs.get("c", null).?);
}

test "AttributeArray: remove from heap storage" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    // Fill and overflow to heap
    try attrs.set("a", null, "1");
    try attrs.set("b", null, "2");
    try attrs.set("c", null, "3");
    try attrs.set("d", null, "4");
    try attrs.set("e", null, "5");

    const removed = attrs.remove("c", null);
    try expect(removed);

    try expectEqual(@as(usize, 4), attrs.count());
    try expect(attrs.get("c", null) == null);
}

test "AttributeArray: remove non-existent attribute" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try attrs.set("a", null, "1");

    const removed = attrs.remove("missing", null);
    try expect(!removed);
    try expectEqual(@as(usize, 1), attrs.count());
}

test "AttributeArray: has checks existence" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try attrs.set("class", null, "container");

    try expect(attrs.has("class", null));
    try expect(!attrs.has("id", null));
}

test "AttributeArray: iterator inline storage" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try attrs.set("a", null, "1");
    try attrs.set("b", null, "2");
    try attrs.set("c", null, "3");

    var iter = attrs.iterator();
    var count: usize = 0;
    while (iter.next()) |attr| {
        count += 1;
        // Verify it's one of our attributes
        const is_valid = std.mem.eql(u8, attr.name.local_name, "a") or
            std.mem.eql(u8, attr.name.local_name, "b") or
            std.mem.eql(u8, attr.name.local_name, "c");
        try expect(is_valid);
    }
    try expectEqual(@as(usize, 3), count);
}

test "AttributeArray: iterator heap storage" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    // Overflow to heap
    try attrs.set("a", null, "1");
    try attrs.set("b", null, "2");
    try attrs.set("c", null, "3");
    try attrs.set("d", null, "4");
    try attrs.set("e", null, "5");

    var iter = attrs.iterator();
    var count: usize = 0;
    while (iter.next()) |_| {
        count += 1;
    }
    try expectEqual(@as(usize, 5), count);
}

test "AttributeArray: namespaced attributes" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    try attrs.set("class", null, "container");
    try attrs.set("lang", xml_ns, "en");

    // Get by namespace
    try expectEqualStrings("en", attrs.get("lang", xml_ns).?);

    // null namespace != xml namespace
    try expect(attrs.get("lang", null) == null);

    // Remove by namespace
    const removed = attrs.remove("lang", xml_ns);
    try expect(removed);
    try expect(attrs.get("lang", xml_ns) == null);
}

test "AttributeArray: null vs empty namespace distinction" {
    const allocator = testing.allocator;
    var attrs = AttributeArray.init(allocator);
    defer attrs.deinit();

    try attrs.set("attr", null, "null-ns");
    try attrs.set("attr", "", "empty-ns");

    // Two different attributes!
    try expectEqualStrings("null-ns", attrs.get("attr", null).?);
    try expectEqualStrings("empty-ns", attrs.get("attr", "").?);

    try expectEqual(@as(usize, 2), attrs.count());
}

test "AttributeArray: memory layout size" {
    const size = @sizeOf(AttributeArray);

    // Expected: 304 bytes
    //   ArrayListUnmanaged(Attribute): 24 bytes
    //   Allocator: 16 bytes
    //   [4]Attribute: 256 bytes (4 * 64)
    //   u8: 1 byte
    //   padding: 7 bytes
    try expectEqual(@as(usize, 304), size);
}
