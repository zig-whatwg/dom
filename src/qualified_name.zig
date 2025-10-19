//! QualifiedName: Structured attribute name representation.
//!
//! Represents a fully-qualified attribute name with (prefix, localName, namespaceURI) tuple.
//! Based on browser implementations (Chrome, Firefox, WebKit) which all use structured
//! qualified names for namespaced attributes.
//!
//! ## Key Concepts
//!
//! **Local Name**: The attribute name without any namespace prefix.
//! - Example: For "xml:lang", local name is "lang"
//! - Required, never null
//!
//! **Namespace URI**: The namespace identifier (not the prefix!).
//! - Example: "http://www.w3.org/XML/1998/namespace"
//! - Nullable (null = no namespace, which is the common case)
//! - Used for matching: attributes match by (localName, namespaceURI) tuple
//!
//! **Prefix**: The namespace prefix (for serialization only).
//! - Example: For "xml:lang", prefix is "xml"
//! - Nullable
//! - NOT used for matching! Only for toString() / serialization
//! - Two attributes with different prefixes but same (localName, namespace) are the SAME
//!
//! ## String Interning
//!
//! All strings MUST be interned via Document.string_pool for performance:
//! - Enables O(1) comparison via pointer equality (eql method)
//! - Matches browser behavior (AtomicString in Chrome/WebKit, nsAtom in Firefox)
//! - Critical for performance: typical element has 3-5 attributes with frequent lookups
//!
//! ## Browser Research
//!
//! **Chrome/Blink**:
//! - Uses QualifiedName struct with AtomicString fields
//! - Pointer equality for comparisons (O(1))
//! - Deduplicates QualifiedNames in global pool
//!
//! **Firefox/Gecko**:
//! - Uses nsAttrName with nsAtom for local name
//! - Integer namespace IDs instead of URI strings
//! - Tagged pointer optimization for null namespace (43% space savings)
//!
//! **WebKit**:
//! - Nearly identical to Chrome (shared ancestry)
//! - QualifiedName with AtomString fields
//!
//! ## Usage Example
//!
//! ```zig
//! const std = @import("std");
//! const QualifiedName = @import("qualified_name.zig").QualifiedName;
//!
//! // Non-namespaced attribute
//! const name1 = QualifiedName.init("class");
//!
//! // Namespaced attribute
//! const name2 = try QualifiedName.initNS(
//!     "http://www.w3.org/XML/1998/namespace",
//!     "xml:lang"
//! );
//! // name2.local_name = "lang"
//! // name2.prefix = "xml"
//! // name2.namespace_uri = "http://www.w3.org/XML/1998/namespace"
//!
//! // Matching by (local, namespace) - prefix ignored
//! const name3 = try QualifiedName.initNS(
//!     "http://www.w3.org/XML/1998/namespace",
//!     "foo:lang"  // Different prefix!
//! );
//! // name2.eqlStrings("lang", "http://www.w3.org/XML/1998/namespace") == true
//! // name3.eqlStrings("lang", "http://www.w3.org/XML/1998/namespace") == true
//! // name2 and name3 represent the SAME attribute!
//! ```
//!
//! ## Spec Compliance
//!
//! **WHATWG DOM**: https://dom.spec.whatwg.org/#concept-attribute
//!
//! > An attribute has a namespace (null or a namespace), namespace prefix (null or a string),
//! > local name (a string), and value (a string).
//!
//! **Key Spec Points**:
//! - Attributes are identified by (namespace, localName), NOT prefix
//! - Prefix is purely for serialization
//! - null namespace is distinct from empty string namespace
//!
//! **WebIDL**: dom.idl:374-390 (Attr interface)
//!
//! **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Attr

const std = @import("std");
const Allocator = std.mem.Allocator;

/// QualifiedName represents a fully-qualified attribute name.
///
/// Stores (prefix, localName, namespaceURI) tuple with interned strings.
/// All strings must be interned via Document.string_pool for O(1) comparison.
///
/// ## Memory Layout
///
/// ```
/// QualifiedName:
///   local_name: []const u8      (16 bytes - pointer + length)
///   namespace_uri: ?[]const u8  (16 bytes - optional slice)
///   prefix: ?[]const u8         (16 bytes - optional slice)
///   Total: 48 bytes
/// ```
///
/// Note: Larger than browser implementations (16-24 bytes) due to Zig slice representation.
/// Future optimization: Store pointer to interned QualifiedName struct (8 bytes).
///
/// ## Spec Compliance
///
/// **WHATWG DOM**: https://dom.spec.whatwg.org/#concept-attribute
///
/// **WebIDL**: dom.idl:374-390
pub const QualifiedName = struct {
    /// Local name (required, never null).
    ///
    /// The attribute name without namespace prefix.
    /// For "xml:lang", this is "lang".
    /// For "class", this is "class".
    ///
    /// MUST be interned via Document.string_pool.
    local_name: []const u8,

    /// Namespace URI (nullable).
    ///
    /// null = no namespace (common case ~90% of attributes)
    /// "http://www.w3.org/XML/1998/namespace" = XML namespace
    /// "http://www.w3.org/2000/svg" = SVG namespace
    ///
    /// Used for matching: two attributes match if (localName, namespaceURI) are equal.
    ///
    /// MUST be interned via Document.string_pool (if not null).
    namespace_uri: ?[]const u8,

    /// Prefix (nullable, for serialization only).
    ///
    /// For "xml:lang", this is "xml".
    /// For "class", this is null.
    ///
    /// NOT used for matching! Only for toString() and serialization.
    /// Two attributes with different prefixes but same (localName, namespace) are the SAME.
    ///
    /// MUST be interned via Document.string_pool (if not null).
    prefix: ?[]const u8,

    /// Creates a non-namespaced qualified name.
    ///
    /// ## Parameters
    ///
    /// - `local_name`: Attribute name (should be interned)
    ///
    /// ## Returns
    ///
    /// QualifiedName with null namespace and null prefix.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const name = QualifiedName.init("class");
    /// // name.local_name = "class"
    /// // name.namespace_uri = null
    /// // name.prefix = null
    /// ```
    pub fn init(local_name: []const u8) QualifiedName {
        return .{
            .local_name = local_name,
            .namespace_uri = null,
            .prefix = null,
        };
    }

    /// Creates a namespaced qualified name by parsing qualified name.
    ///
    /// Parses "prefix:localName" or just "localName" from qualified_name string.
    ///
    /// ## Parameters
    ///
    /// - `namespace_uri`: Namespace URI (nullable, should be interned)
    /// - `qualified_name`: Qualified name to parse (should be interned)
    ///
    /// ## Returns
    ///
    /// QualifiedName with parsed prefix and local name.
    ///
    /// ## Example
    ///
    /// ```zig
    /// // With prefix
    /// const name1 = try QualifiedName.initNS(
    ///     "http://www.w3.org/XML/1998/namespace",
    ///     "xml:lang"
    /// );
    /// // name1.local_name = "lang"
    /// // name1.prefix = "xml"
    ///
    /// // Without prefix
    /// const name2 = try QualifiedName.initNS(
    ///     "http://www.w3.org/2000/svg",
    ///     "viewBox"
    /// );
    /// // name2.local_name = "viewBox"
    /// // name2.prefix = null
    /// ```
    pub fn initNS(
        namespace_uri: ?[]const u8,
        qualified_name: []const u8,
    ) QualifiedName {
        // Parse "prefix:localName" or just "localName"
        if (std.mem.indexOf(u8, qualified_name, ":")) |colon| {
            const prefix = qualified_name[0..colon];
            const local = qualified_name[colon + 1 ..];
            return .{
                .local_name = local,
                .namespace_uri = namespace_uri,
                .prefix = prefix,
            };
        } else {
            return .{
                .local_name = qualified_name,
                .namespace_uri = namespace_uri,
                .prefix = null,
            };
        }
    }

    /// Returns the qualified name string (prefix:localName or just localName).
    ///
    /// Allocates new string for prefixed names. For non-prefixed names, returns local_name.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for string formatting (only used if prefix exists)
    ///
    /// ## Returns
    ///
    /// Qualified name string. Caller owns memory if prefix exists.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const name = try QualifiedName.initNS(null, "xml:lang");
    /// const str = try name.toString(allocator);
    /// defer if (name.prefix != null) allocator.free(str);
    /// // str = "xml:lang"
    /// ```
    pub fn toString(self: QualifiedName, allocator: Allocator) ![]const u8 {
        if (self.prefix) |prefix| {
            return std.fmt.allocPrint(allocator, "{s}:{s}", .{
                prefix,
                self.local_name,
            });
        } else {
            return self.local_name;
        }
    }

    /// Checks equality using pointer comparison (requires interned strings).
    ///
    /// O(1) comparison via pointer equality. Assumes all strings are interned
    /// via Document.string_pool.
    ///
    /// ## Parameters
    ///
    /// - `other`: QualifiedName to compare against
    ///
    /// ## Returns
    ///
    /// true if (localName, namespaceURI) match via pointer equality.
    ///
    /// ## Performance
    ///
    /// O(1) - just pointer comparisons, no string iteration.
    ///
    /// ## Example
    ///
    /// ```zig
    /// // Assuming strings are interned in doc.string_pool
    /// const name1 = QualifiedName.init(interned_class);
    /// const name2 = QualifiedName.init(interned_class);
    /// try expect(name1.eql(name2)); // true (same pointer)
    /// ```
    pub fn eql(self: QualifiedName, other: QualifiedName) bool {
        // O(1) comparison via pointer equality (strings are interned)
        const local_match = self.local_name.ptr == other.local_name.ptr;

        const ns_match = if (self.namespace_uri == null and other.namespace_uri == null)
            true
        else if (self.namespace_uri) |self_ns| blk: {
            if (other.namespace_uri) |other_ns| {
                break :blk self_ns.ptr == other_ns.ptr; // Pointer equality
            } else {
                break :blk false;
            }
        } else false;

        return local_match and ns_match;
    }

    /// Checks equality with explicit strings (for non-interned lookups).
    ///
    /// O(n) string comparison. Used during setAttribute() before strings are interned,
    /// or for lookups with non-interned strings.
    ///
    /// ## Parameters
    ///
    /// - `local_name`: Local name to match
    /// - `namespace_uri`: Namespace URI to match (nullable)
    ///
    /// ## Returns
    ///
    /// true if (localName, namespaceURI) match via string equality.
    ///
    /// ## Performance
    ///
    /// O(n) where n = string lengths. Slower than eql() but necessary for non-interned strings.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const name = try QualifiedName.initNS(
    ///     "http://www.w3.org/XML/1998/namespace",
    ///     "xml:lang"
    /// );
    ///
    /// // Match by local name + namespace (prefix ignored!)
    /// try expect(name.eqlStrings(
    ///     "lang",
    ///     "http://www.w3.org/XML/1998/namespace"
    /// )); // true
    ///
    /// // Different prefix = same attribute
    /// const name2 = try QualifiedName.initNS(
    ///     "http://www.w3.org/XML/1998/namespace",
    ///     "foo:lang"  // Different prefix!
    /// );
    /// try expect(name2.eqlStrings(
    ///     "lang",
    ///     "http://www.w3.org/XML/1998/namespace"
    /// )); // true - prefix doesn't matter
    /// ```
    pub fn eqlStrings(
        self: QualifiedName,
        local_name: []const u8,
        namespace_uri: ?[]const u8,
    ) bool {
        // Fallback: string comparison (O(n))
        const local_match = std.mem.eql(u8, self.local_name, local_name);

        const ns_match = if (namespace_uri) |ns| blk: {
            if (self.namespace_uri) |self_ns| {
                break :blk std.mem.eql(u8, self_ns, ns);
            } else {
                break :blk false;
            }
        } else self.namespace_uri == null;

        return local_match and ns_match;
    }
};

// Tests
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
