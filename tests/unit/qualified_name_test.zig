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

// === parse() function tests ===

test "parse: simple name without prefix" {
    const result = try dom.qualified_name.parse("div");
    
    try expect(result.prefix == null);
    try expectEqualStrings("div", result.local_name);
}

test "parse: qualified name with prefix" {
    const result = try dom.qualified_name.parse("svg:circle");
    
    try expectEqualStrings("svg", result.prefix.?);
    try expectEqualStrings("circle", result.local_name);
}

test "parse: xml prefix" {
    const result = try dom.qualified_name.parse("xml:lang");
    
    try expectEqualStrings("xml", result.prefix.?);
    try expectEqualStrings("lang", result.local_name);
}

test "parse: xlink prefix" {
    const result = try dom.qualified_name.parse("xlink:href");
    
    try expectEqualStrings("xlink", result.prefix.?);
    try expectEqualStrings("href", result.local_name);
}

test "parse: name with hyphens and underscores" {
    const result = try dom.qualified_name.parse("data-user_id");
    
    try expect(result.prefix == null);
    try expectEqualStrings("data-user_id", result.local_name);
}

test "parse: name with periods" {
    const result = try dom.qualified_name.parse("com.example.attr");
    
    try expect(result.prefix == null);
    try expectEqualStrings("com.example.attr", result.local_name);
}

test "parse: prefixed name with hyphens" {
    const result = try dom.qualified_name.parse("my-prefix:local-name");
    
    try expectEqualStrings("my-prefix", result.prefix.?);
    try expectEqualStrings("local-name", result.local_name);
}

// === parse() error cases ===

test "parse: empty string error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse(""));
}

test "parse: starts with colon error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse(":div"));
}

test "parse: ends with colon error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse("div:"));
}

test "parse: multiple colons error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse("a:b:c"));
}

test "parse: starts with digit error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse("123div"));
}

test "parse: starts with hyphen error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse("-div"));
}

test "parse: contains space error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse("div span"));
}

test "parse: contains special characters error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse("div@id"));
}

test "parse: prefix starts with digit error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse("123:div"));
}

test "parse: local name starts with digit error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.parse("svg:123"));
}

// === validateXMLName() tests ===

test "validateXMLName: valid simple name" {
    try dom.qualified_name.validateXMLName("div");
}

test "validateXMLName: valid name with underscore" {
    try dom.qualified_name.validateXMLName("_private");
}

test "validateXMLName: valid name with hyphens" {
    try dom.qualified_name.validateXMLName("my-element");
}

test "validateXMLName: valid name with digits" {
    try dom.qualified_name.validateXMLName("h1");
}

test "validateXMLName: valid name with periods" {
    try dom.qualified_name.validateXMLName("com.example");
}

test "validateXMLName: valid mixed case" {
    try dom.qualified_name.validateXMLName("MyElement");
}

test "validateXMLName: valid all uppercase" {
    try dom.qualified_name.validateXMLName("DIV");
}

test "validateXMLName: empty string error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.validateXMLName(""));
}

test "validateXMLName: starts with digit error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.validateXMLName("123"));
}

test "validateXMLName: starts with hyphen error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.validateXMLName("-name"));
}

test "validateXMLName: starts with period error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.validateXMLName(".name"));
}

test "validateXMLName: contains space error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.validateXMLName("my element"));
}

test "validateXMLName: contains special character error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.validateXMLName("my@element"));
}

test "validateXMLName: contains bracket error" {
    try testing.expectError(error.InvalidCharacterError, dom.qualified_name.validateXMLName("my[element]"));
}
