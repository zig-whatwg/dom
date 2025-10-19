const std = @import("std");
const dom = @import("dom");
const Attribute = dom.attribute.Attribute;

const testing = std.testing;
const expect = testing.expect;
const expectEqualStrings = testing.expectEqualStrings;

test "Attribute: init creates non-namespaced attribute" {
    const attr = Attribute.init("class", "container");

    try expectEqualStrings("class", attr.name.local_name);
    try expect(attr.name.namespace_uri == null);
    try expect(attr.name.prefix == null);
    try expectEqualStrings("container", attr.value);
}

test "Attribute: initNS creates namespaced attribute" {
    const attr = Attribute.initNS(
        "http://www.w3.org/XML/1998/namespace",
        "xml:lang",
        "en",
    );

    try expectEqualStrings("lang", attr.name.local_name);
    try expectEqualStrings("http://www.w3.org/XML/1998/namespace", attr.name.namespace_uri.?);
    try expectEqualStrings("xml", attr.name.prefix.?);
    try expectEqualStrings("en", attr.value);
}

test "Attribute: matches by (local, namespace)" {
    const attr = Attribute.initNS(
        "http://www.w3.org/XML/1998/namespace",
        "xml:lang",
        "en",
    );

    try expect(attr.matches("lang", "http://www.w3.org/XML/1998/namespace"));
    try expect(!attr.matches("lang", null)); // Different namespace
    try expect(!attr.matches("class", "http://www.w3.org/XML/1998/namespace")); // Different local
}

test "Attribute: matches ignores prefix" {
    const attr1 = Attribute.initNS(
        "http://www.w3.org/XML/1998/namespace",
        "xml:lang",
        "en",
    );

    const attr2 = Attribute.initNS(
        "http://www.w3.org/XML/1998/namespace",
        "foo:lang", // Different prefix!
        "fr",
    );

    // Both match by (local, namespace)
    try expect(attr1.matches("lang", "http://www.w3.org/XML/1998/namespace"));
    try expect(attr2.matches("lang", "http://www.w3.org/XML/1998/namespace"));
}

test "Attribute: qualifiedName without prefix" {
    const allocator = testing.allocator;
    const attr = Attribute.init("class", "container");

    const qname = try attr.qualifiedName(allocator);
    try expectEqualStrings("class", qname);
}

test "Attribute: qualifiedName with prefix" {
    const allocator = testing.allocator;
    const attr = Attribute.initNS(null, "xml:lang", "en");

    const qname = try attr.qualifiedName(allocator);
    defer allocator.free(qname);

    try expectEqualStrings("xml:lang", qname);
}

test "Attribute: memory layout size" {
    const size = @sizeOf(Attribute);

    // Expected: 64 bytes (QualifiedName 48 + value slice 16)
    // Larger than browsers but acceptable for Zig
    try expect(size == 64);
}
