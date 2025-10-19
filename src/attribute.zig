//! Attribute: Struct representing a single element attribute.
//!
//! This module provides the internal representation of attributes used by
//! Element's attribute storage. It combines QualifiedName (for namespace support)
//! with the attribute value.
//!
//! ## Design
//!
//! Based on browser research (Chrome, Firefox, WebKit), this implementation:
//! - Stores qualified name (local, namespace, prefix) + value
//! - Uses interned strings for O(1) comparison
//! - Supports matching by (localName, namespace) tuple
//! - Preserves prefix for serialization
//!
//! ## Browser Comparison
//!
//! **Chrome/Blink**: 16 bytes per attribute (pointer to shared QualifiedName + value)
//! **Firefox/Gecko**: 24 bytes per attribute (tagged pointer optimization)
//! **Ours**: 56 bytes per attribute (QualifiedName inline)
//!
//! Future optimization: Store *QualifiedName instead of inline struct (saves 40 bytes).
//!
//! ## Usage
//!
//! ```zig
//! const Attribute = @import("attribute.zig").Attribute;
//!
//! // Non-namespaced
//! const attr1 = Attribute.init("class", "container");
//!
//! // Namespaced
//! const attr2 = Attribute.initNS(
//!     "http://www.w3.org/XML/1998/namespace",
//!     "xml:lang",
//!     "en"
//! );
//!
//! // Matching
//! if (attr2.matches("lang", "http://www.w3.org/XML/1998/namespace")) {
//!     // Found!
//! }
//! ```

const std = @import("std");
const Allocator = std.mem.Allocator;
const QualifiedName = @import("qualified_name.zig").QualifiedName;

/// Attribute represents a single element attribute.
///
/// Stores qualified name + value, both with interned strings.
/// Used internally by AttributeArray for element attribute storage.
///
/// ## Memory Layout
///
/// ```
/// Attribute:
///   name: QualifiedName  (48 bytes - 3 slices)
///   value: []const u8    (16 bytes - slice)
///   Total: 64 bytes
/// ```
///
/// Note: Larger than browsers (16-24 bytes) due to inline QualifiedName.
/// Future optimization: pointer to interned QualifiedName (reduces to 24 bytes).
pub const Attribute = struct {
    /// Qualified name (local, namespace, prefix).
    ///
    /// MUST have interned strings via Document.string_pool.
    name: QualifiedName,

    /// Attribute value (interned).
    ///
    /// MUST be interned via Document.string_pool.
    value: []const u8,

    /// Creates a non-namespaced attribute.
    ///
    /// ## Parameters
    ///
    /// - `name`: Attribute name (should be interned)
    /// - `value`: Attribute value (should be interned)
    ///
    /// ## Returns
    ///
    /// Attribute with null namespace and null prefix.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const attr = Attribute.init("class", "container");
    /// ```
    pub fn init(name: []const u8, value: []const u8) Attribute {
        return .{
            .name = QualifiedName.init(name),
            .value = value,
        };
    }

    /// Creates a namespaced attribute.
    ///
    /// Parses qualified_name to extract prefix and local name.
    ///
    /// ## Parameters
    ///
    /// - `namespace_uri`: Namespace URI (nullable, should be interned)
    /// - `qualified_name`: Qualified name (e.g., "xml:lang", should be interned)
    /// - `value`: Attribute value (should be interned)
    ///
    /// ## Returns
    ///
    /// Attribute with parsed qualified name.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const attr = Attribute.initNS(
    ///     "http://www.w3.org/XML/1998/namespace",
    ///     "xml:lang",
    ///     "en"
    /// );
    /// // attr.name.local_name = "lang"
    /// // attr.name.prefix = "xml"
    /// // attr.value = "en"
    /// ```
    pub fn initNS(
        namespace_uri: ?[]const u8,
        qualified_name: []const u8,
        value: []const u8,
    ) Attribute {
        return .{
            .name = QualifiedName.initNS(namespace_uri, qualified_name),
            .value = value,
        };
    }

    /// Checks if this attribute matches (localName, namespace).
    ///
    /// Uses string comparison (O(n)). Prefix is ignored (not part of identity).
    ///
    /// ## Parameters
    ///
    /// - `local_name`: Local name to match
    /// - `namespace_uri`: Namespace URI to match (nullable)
    ///
    /// ## Returns
    ///
    /// true if (localName, namespace) match.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const attr = Attribute.initNS(
    ///     "http://www.w3.org/XML/1998/namespace",
    ///     "xml:lang",
    ///     "en"
    /// );
    ///
    /// try expect(attr.matches("lang", "http://www.w3.org/XML/1998/namespace"));
    /// try expect(!attr.matches("lang", null)); // Different namespace
    /// ```
    pub fn matches(
        self: Attribute,
        local_name: []const u8,
        namespace_uri: ?[]const u8,
    ) bool {
        return self.name.eqlStrings(local_name, namespace_uri);
    }

    /// Returns the qualified name for this attribute.
    ///
    /// Allocates new string if prefix exists. Otherwise returns local_name.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Allocator for formatting (only used if prefix exists)
    ///
    /// ## Returns
    ///
    /// Qualified name string. Caller owns memory if prefix exists.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const attr = Attribute.initNS(null, "xml:lang", "en");
    /// const qname = try attr.qualifiedName(allocator);
    /// defer if (attr.name.prefix != null) allocator.free(qname);
    /// // qname = "xml:lang"
    /// ```
    pub fn qualifiedName(self: Attribute, allocator: Allocator) ![]const u8 {
        return try self.name.toString(allocator);
    }
};
