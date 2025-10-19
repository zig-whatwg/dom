const std = @import("std");
const dom = @import("dom");
const Attr = dom.Attr;
const NodeType = dom.NodeType;

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualStrings = testing.expectEqualStrings;

test "Attr: create and basic properties" {
    const allocator = testing.allocator;

    const attr = try Attr.create(allocator, "id");
    defer attr.node.release();

    try expectEqualStrings("id", attr.local_name);
    try expectEqualStrings("id", attr.name());
    try expectEqualStrings("", attr.value());
    try expect(attr.namespace_uri == null);
    try expect(attr.prefix == null);
    try expect(attr.owner_element == null);
    try expect(attr.specified());
    try expectEqual(NodeType.attribute, attr.node.node_type);
}

test "Attr: setValue" {
    const allocator = testing.allocator;

    const attr = try Attr.create(allocator, "class");
    defer attr.node.release();

    try attr.setValue("container");
    try expectEqualStrings("container", attr.value());

    try attr.setValue("highlight");
    try expectEqualStrings("highlight", attr.value());
}

test "Attr: createNS with namespace" {
    const allocator = testing.allocator;

    const attr = try Attr.createNS(
        allocator,
        "http://www.w3.org/XML/1998/namespace",
        "xml:lang",
    );
    defer attr.node.release();

    try expectEqualStrings("lang", attr.local_name);
    try expectEqualStrings("xml", attr.prefix.?);
    try expectEqualStrings("http://www.w3.org/XML/1998/namespace", attr.namespace_uri.?);
}

test "Attr: node properties" {
    const allocator = testing.allocator;

    const attr = try Attr.create(allocator, "data-id");
    defer attr.node.release();

    try attr.setValue("12345");

    try expectEqualStrings("data-id", attr.node.nodeName());
    const node_value = attr.node.nodeValue();
    try expectEqualStrings("12345", node_value.?);
}

test "Attr: cloneNode" {
    const allocator = testing.allocator;

    const original = try Attr.create(allocator, "href");
    defer original.node.release();
    try original.setValue("https://example.com");

    const cloned_node = try original.node.cloneNode(false);
    defer cloned_node.release();

    const cloned: *Attr = @fieldParentPtr("node", cloned_node);
    try expectEqualStrings(original.local_name, cloned.local_name);
    try expectEqualStrings(original.value(), cloned.value());
    try expect(cloned.owner_element == null); // Clones are detached
}

test "Attr: memory leak check" {
    const allocator = testing.allocator;

    const attr = try Attr.create(allocator, "title");
    defer attr.node.release();

    try attr.setValue("Test Title");
    try attr.setValue("Updated Title");
    try attr.setValue("Final Title");

    // Verify no leaks via testing allocator
}
