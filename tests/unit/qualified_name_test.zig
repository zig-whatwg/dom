const std = @import("std");
const dom = @import("dom");
const QualifiedName = dom.qualified_name.QualifiedName;

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualStrings = testing.expectEqualStrings;

test "QualifiedName: init creates non-namespaced name" {
    const name = QualifiedName.init("class");

    try expectEqualStrings("class", name.local_name);
    try expect(name.namespace_uri == null);
    try expect(name.prefix == null);
}

test "QualifiedName: initNS parses prefixed name" {
    const name = QualifiedName.initNS(
        "http://www.w3.org/XML/1998/namespace",
        "xml:lang",
    );

    try expectEqualStrings("lang", name.local_name);
    try expectEqualStrings("http://www.w3.org/XML/1998/namespace", name.namespace_uri.?);
    try expectEqualStrings("xml", name.prefix.?);
}

test "QualifiedName: initNS handles non-prefixed name" {
    const name = QualifiedName.initNS(
        "http://www.w3.org/2000/svg",
        "viewBox",
    );

    try expectEqualStrings("viewBox", name.local_name);
    try expectEqualStrings("http://www.w3.org/2000/svg", name.namespace_uri.?);
    try expect(name.prefix == null);
}

test "QualifiedName: initNS with null namespace" {
    const name = QualifiedName.initNS(null, "data-id");

    try expectEqualStrings("data-id", name.local_name);
    try expect(name.namespace_uri == null);
    try expect(name.prefix == null);
}

test "QualifiedName: toString without prefix" {
    const allocator = testing.allocator;
    const name = QualifiedName.init("class");

    const str = try name.toString(allocator);
    // No allocation for non-prefixed, so no free needed
    try expectEqualStrings("class", str);
}

test "QualifiedName: toString with prefix" {
    const allocator = testing.allocator;
    const name = QualifiedName.initNS(null, "xml:lang");

    const str = try name.toString(allocator);
    defer allocator.free(str);

    try expectEqualStrings("xml:lang", str);
}

test "QualifiedName: eqlStrings with matching local and namespace" {
    const name = QualifiedName.initNS(
        "http://www.w3.org/XML/1998/namespace",
        "xml:lang",
    );

    try expect(name.eqlStrings("lang", "http://www.w3.org/XML/1998/namespace"));
}

test "QualifiedName: eqlStrings ignores prefix" {
    const name1 = QualifiedName.initNS(
        "http://www.w3.org/XML/1998/namespace",
        "xml:lang",
    );

    const name2 = QualifiedName.initNS(
        "http://www.w3.org/XML/1998/namespace",
        "foo:lang", // Different prefix!
    );

    // Both match by (localName, namespace)
    try expect(name1.eqlStrings("lang", "http://www.w3.org/XML/1998/namespace"));
    try expect(name2.eqlStrings("lang", "http://www.w3.org/XML/1998/namespace"));
}

test "QualifiedName: eqlStrings with null namespace" {
    const name = QualifiedName.init("class");

    try expect(name.eqlStrings("class", null));
    try expect(!name.eqlStrings("class", "http://example.com")); // Different namespace
    try expect(!name.eqlStrings("id", null)); // Different local name
}

test "QualifiedName: eqlStrings null vs empty namespace distinction" {
    const name_null = QualifiedName.initNS(null, "attr");
    const name_empty = QualifiedName.initNS("", "attr");

    try expect(name_null.eqlStrings("attr", null));
    try expect(!name_null.eqlStrings("attr", "")); // null != ""

    try expect(name_empty.eqlStrings("attr", ""));
    try expect(!name_empty.eqlStrings("attr", null)); // "" != null
}

test "QualifiedName: eql with pointer equality (simulated interning)" {
    // Simulate string interning by reusing same string
    const interned_class = "class";
    const interned_svg_ns = "http://www.w3.org/2000/svg";

    const name1 = QualifiedName.init(interned_class);
    const name2 = QualifiedName.init(interned_class);

    // Pointer equality works because both point to same interned string
    try expect(name1.eql(name2));

    // With namespace
    const name3 = QualifiedName.initNS(interned_svg_ns, "circle");
    const name4 = QualifiedName.initNS(interned_svg_ns, "circle");

    try expect(name3.eql(name4));
}

test "QualifiedName: eql with different pointers fails (not interned)" {
    // Different string instances (not interned)
    var buf1: [5]u8 = undefined;
    var buf2: [5]u8 = undefined;
    @memcpy(buf1[0..5], "class");
    @memcpy(buf2[0..5], "class");

    const name1 = QualifiedName.init(buf1[0..]);
    const name2 = QualifiedName.init(buf2[0..]);

    // Pointer equality fails (different pointers)
    try expect(!name1.eql(name2));

    // But eqlStrings works
    try expect(name1.eqlStrings("class", null));
    try expect(name2.eqlStrings("class", null));
}

test "QualifiedName: memory layout size" {
    // Document the size for performance tracking
    const size = @sizeOf(QualifiedName);

    // Expected: 48 bytes (3 slices, each 16 bytes on 64-bit)
    // This is larger than browsers (16-24 bytes) but acceptable for Zig
    try expect(size == 48);
}
