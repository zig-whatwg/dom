//! validation Tests
//!
//! Tests for validation functionality.

const std = @import("std");
const dom = @import("dom");

const testing = std.testing;
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const validation = dom.validation;
test "validation - circular reference detection" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");
    defer child.prototype.release();

    // Set up parent-child relationship first
    child.prototype.parent_node = &parent.prototype;
    parent.prototype.first_child = &child.prototype;
    parent.prototype.last_child = &child.prototype;
    defer {
        child.prototype.parent_node = null;
        parent.prototype.first_child = null;
        parent.prototype.last_child = null;
    }

    // Try to insert parent into its own child (circular)
    const result = validation.ensurePreInsertValidity(&parent.prototype, &child.prototype, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - invalid parent type" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    // Try to insert into text node (invalid parent)
    const result = validation.ensurePreInsertValidity(&elem.prototype, &text.prototype, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - child parent mismatch" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release();

    const parent2 = try doc.createElement("span");
    defer parent2.prototype.release();

    const child = try doc.createElement("p");
    defer child.prototype.release();

    // Child's parent is not parent2
    const result = validation.ensurePreInsertValidity(&child.prototype, &parent2.prototype, &child.prototype);
    try std.testing.expectError(error.NotFoundError, result);
}

test "validation - text node into document" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    // Text cannot be child of document
    const result = validation.ensurePreInsertValidity(&text.prototype, &doc.prototype, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - pre-remove with wrong parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");
    defer child.prototype.release();

    // Child's parent is null, not parent
    const result = validation.ensurePreRemoveValidity(&child.prototype, &parent.prototype);
    try std.testing.expectError(error.NotFoundError, result);
}

// ============================================================================
// Qualified Name Validation Tests
// ============================================================================

test "validateAndExtract: simple name without namespace" {
    const result = try validation.validateAndExtract(null, "attribute");
    try std.testing.expect(result.namespace == null);
    try std.testing.expect(result.prefix == null);
    try std.testing.expectEqualStrings("attribute", result.local_name);
}

test "validateAndExtract: qualified name with prefix" {
    const xml_ns = "http://www.w3.org/XML/1998/namespace";
    const result = try validation.validateAndExtract(xml_ns, "xml:lang");
    try std.testing.expect(result.namespace != null);
    try std.testing.expectEqualStrings(xml_ns, result.namespace.?);
    try std.testing.expect(result.prefix != null);
    try std.testing.expectEqualStrings("xml", result.prefix.?);
    try std.testing.expectEqualStrings("lang", result.local_name);
}

test "validateAndExtract: empty namespace becomes null" {
    const result = try validation.validateAndExtract("", "attr");
    try std.testing.expect(result.namespace == null);
    try std.testing.expect(result.prefix == null);
    try std.testing.expectEqualStrings("attr", result.local_name);
}

test "validateAndExtract: xml prefix requires XML namespace" {
    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Valid: xml prefix with XML namespace
    const valid = try validation.validateAndExtract(xml_ns, "xml:lang");
    try std.testing.expectEqualStrings("xml", valid.prefix.?);

    // Invalid: xml prefix with wrong namespace
    const invalid1 = validation.validateAndExtract("http://example.com", "xml:lang");
    try std.testing.expectError(error.NamespaceError, invalid1);

    // Invalid: xml prefix with null namespace
    const invalid2 = validation.validateAndExtract(null, "xml:lang");
    try std.testing.expectError(error.NamespaceError, invalid2);
}

test "validateAndExtract: xmlns prefix requires XMLNS namespace" {
    const xmlns_ns = "http://www.w3.org/2000/xmlns/";

    // Valid: xmlns prefix with XMLNS namespace
    const valid = try validation.validateAndExtract(xmlns_ns, "xmlns:custom");
    try std.testing.expectEqualStrings("xmlns", valid.prefix.?);

    // Invalid: xmlns prefix with wrong namespace
    const invalid = validation.validateAndExtract("http://example.com", "xmlns:custom");
    try std.testing.expectError(error.NamespaceError, invalid);
}

test "validateAndExtract: xmlns name requires XMLNS namespace" {
    const xmlns_ns = "http://www.w3.org/2000/xmlns/";

    // Valid: xmlns name with XMLNS namespace
    const valid = try validation.validateAndExtract(xmlns_ns, "xmlns");
    try std.testing.expectEqualStrings("xmlns", valid.local_name);

    // Invalid: xmlns name with wrong namespace
    const invalid = validation.validateAndExtract("http://example.com", "xmlns");
    try std.testing.expectError(error.NamespaceError, invalid);
}

test "validateAndExtract: XMLNS namespace requires xmlns prefix or name" {
    const xmlns_ns = "http://www.w3.org/2000/xmlns/";

    // Valid: XMLNS namespace with xmlns prefix
    const valid1 = try validation.validateAndExtract(xmlns_ns, "xmlns:custom");
    try std.testing.expectEqualStrings(xmlns_ns, valid1.namespace.?);

    // Valid: XMLNS namespace with xmlns name
    const valid2 = try validation.validateAndExtract(xmlns_ns, "xmlns");
    try std.testing.expectEqualStrings(xmlns_ns, valid2.namespace.?);

    // Invalid: XMLNS namespace with other name
    const invalid = validation.validateAndExtract(xmlns_ns, "custom:attr");
    try std.testing.expectError(error.NamespaceError, invalid);
}

test "validateAndExtract: invalid characters in qualified name" {
    // Invalid: empty name
    const invalid1 = validation.validateAndExtract(null, "");
    try std.testing.expectError(error.InvalidCharacterError, invalid1);

    // Invalid: starts with digit
    const invalid2 = validation.validateAndExtract(null, "9invalid");
    try std.testing.expectError(error.InvalidCharacterError, invalid2);

    // Invalid: contains space
    const invalid3 = validation.validateAndExtract(null, "invalid name");
    try std.testing.expectError(error.InvalidCharacterError, invalid3);
}

test "validateAndExtract: invalid NCName (colon in local name)" {
    // Invalid: local name contains colon
    const invalid = validation.validateAndExtract(null, "pre:fix:local");
    try std.testing.expectError(error.InvalidCharacterError, invalid);
}

test "validateAndExtract: custom namespace with custom prefix" {
    const custom_ns = "http://example.com/custom";
    const result = try validation.validateAndExtract(custom_ns, "custom:attribute");
    try std.testing.expectEqualStrings(custom_ns, result.namespace.?);
    try std.testing.expectEqualStrings("custom", result.prefix.?);
    try std.testing.expectEqualStrings("attribute", result.local_name);
}
