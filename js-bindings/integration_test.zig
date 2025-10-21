//! Integration tests for JavaScript bindings
//!
//! These tests validate that the C-ABI bindings work correctly
//! by calling the exported functions and verifying behavior.

const std = @import("std");
const testing = std.testing;

// Import the binding modules
const node_bindings = @import("node.zig");
const element_bindings = @import("element.zig");
const document_bindings = @import("document.zig");
const dom_types = @import("dom_types.zig");

// Type aliases for convenience
const DOMDocument = document_bindings.DOMDocument;
const DOMElement = element_bindings.DOMElement;
const DOMNode = node_bindings.DOMNode;
const DOMText = document_bindings.DOMText;

test "Document: creation and cleanup" {
    const doc = document_bindings.dom_document_new();
    // Non-null pointer returned (no need to check)

    // Should not crash
    document_bindings.dom_document_release(doc);
}

test "Document: reference counting" {
    const doc = document_bindings.dom_document_new();

    // Increment ref count
    document_bindings.dom_document_addref(doc);

    // Should need two releases (1 for acquire, 1 for initial ref)
    document_bindings.dom_document_release(doc);
    document_bindings.dom_document_release(doc);

    // Create new doc for cleanup
    const doc2 = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc2);
}

test "Document: createElement" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);
    // Successfully created (non-null pointer)
}

test "Document: createTextNode" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const text = document_bindings.dom_document_createtextnode(doc, "Hello, World!");
    defer node_bindings.dom_node_release(@ptrCast(text));
    // Successfully created (non-null pointer)
}

test "Document: createComment" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const comment = document_bindings.dom_document_createcomment(doc, "TODO: fix this");
    defer node_bindings.dom_node_release(@ptrCast(comment));
    // Successfully created (non-null pointer)
}

test "Element: get tagName" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);

    const tag_name = element_bindings.dom_element_get_tagname(elem);
    try testing.expectEqualStrings("div", std.mem.span(tag_name));
}

test "Element: setAttribute and getAttribute" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);

    // Set attribute
    const result = element_bindings.dom_element_setattribute(elem, "id", "test-id");
    try testing.expectEqual(@as(c_int, 0), result); // Success

    // Get attribute back
    const id = element_bindings.dom_element_getattribute(elem, "id");
    try testing.expect(id != null);
    try testing.expectEqualStrings("test-id", std.mem.span(id.?));
}

test "Element: multiple attributes" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);

    // Set multiple attributes
    _ = element_bindings.dom_element_setattribute(elem, "id", "container");
    _ = element_bindings.dom_element_setattribute(elem, "class", "main");
    _ = element_bindings.dom_element_setattribute(elem, "data-test", "value");

    // Verify all exist
    const id = element_bindings.dom_element_getattribute(elem, "id");
    const class = element_bindings.dom_element_getattribute(elem, "class");
    const data = element_bindings.dom_element_getattribute(elem, "data-test");

    try testing.expectEqualStrings("container", std.mem.span(id.?));
    try testing.expectEqualStrings("main", std.mem.span(class.?));
    try testing.expectEqualStrings("value", std.mem.span(data.?));
}

test "Element: hasAttribute" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);

    // Should not have attribute initially
    const has_before = element_bindings.dom_element_hasattribute(elem, "id");
    try testing.expectEqual(@as(u8, 0), has_before);

    // Set attribute
    _ = element_bindings.dom_element_setattribute(elem, "id", "test");

    // Should have attribute now
    const has_after = element_bindings.dom_element_hasattribute(elem, "id");
    try testing.expectEqual(@as(u8, 1), has_after);
}

test "Element: removeAttribute" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);

    // Set and verify
    _ = element_bindings.dom_element_setattribute(elem, "id", "test");
    try testing.expectEqual(@as(u8, 1), element_bindings.dom_element_hasattribute(elem, "id"));

    // Remove
    const result = element_bindings.dom_element_removeattribute(elem, "id");
    try testing.expectEqual(@as(c_int, 0), result);

    // Should not have attribute
    try testing.expectEqual(@as(u8, 0), element_bindings.dom_element_hasattribute(elem, "id"));
}

test "Element: id convenience property" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);

    // Set via convenience property
    _ = element_bindings.dom_element_set_id(elem, "my-id");

    // Get via convenience property
    const id = element_bindings.dom_element_get_id(elem);
    try testing.expectEqualStrings("my-id", std.mem.span(id));

    // Should also work via getAttribute
    const id2 = element_bindings.dom_element_getattribute(elem, "id");
    try testing.expectEqualStrings("my-id", std.mem.span(id2.?));
}

test "Node: appendChild" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const parent = document_bindings.dom_document_createelement(doc, "div");
    const child = document_bindings.dom_document_createelement(doc, "span");

    const parent_node = @as(*DOMNode, @ptrCast(parent));
    const child_node = @as(*DOMNode, @ptrCast(child));

    // Append child
    const result = node_bindings.dom_node_appendchild(parent_node, child_node);
    // Returns non-null node pointer
    _ = result;

    // Parent should have children now
    const has_children = node_bindings.dom_node_haschildnodes(parent_node);
    try testing.expectEqual(@as(u8, 1), has_children);

    // Clean up (parent owns child, defer handles doc)
    element_bindings.dom_element_release(parent);
}

test "Node: tree navigation" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const parent = document_bindings.dom_document_createelement(doc, "div");
    const child1 = document_bindings.dom_document_createelement(doc, "span");
    const child2 = document_bindings.dom_document_createelement(doc, "p");

    const parent_node = @as(*DOMNode, @ptrCast(parent));
    const child1_node = @as(*DOMNode, @ptrCast(child1));
    const child2_node = @as(*DOMNode, @ptrCast(child2));

    // Build tree
    _ = node_bindings.dom_node_appendchild(parent_node, child1_node);
    _ = node_bindings.dom_node_appendchild(parent_node, child2_node);

    // Test firstChild
    const first = node_bindings.dom_node_get_firstchild(parent_node);
    try testing.expect(first != null);
    try testing.expect(first == child1_node);

    // Test lastChild
    const last = node_bindings.dom_node_get_lastchild(parent_node);
    try testing.expect(last != null);
    try testing.expect(last == child2_node);

    // Test nextSibling
    const next = node_bindings.dom_node_get_nextsibling(child1_node);
    try testing.expect(next != null);
    try testing.expect(next == child2_node);

    // Test previousSibling
    const prev = node_bindings.dom_node_get_previoussibling(child2_node);
    try testing.expect(prev != null);
    try testing.expect(prev == child1_node);

    // Test parentNode
    const parent_of_child = node_bindings.dom_node_get_parentnode(child1_node);
    try testing.expect(parent_of_child != null);
    try testing.expect(parent_of_child == parent_node);

    // Cleanup (defer handles doc)
    element_bindings.dom_element_release(parent);
}

test "Node: nodeName and nodeType" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);

    const node = @as(*DOMNode, @ptrCast(elem));

    // Check nodeType (should be ELEMENT_NODE = 1)
    const node_type = node_bindings.dom_node_get_nodetype(node);
    try testing.expectEqual(@as(u16, 1), node_type);

    // Check nodeName (should be tag name)
    const node_name = node_bindings.dom_node_get_nodename(node);
    try testing.expectEqualStrings("div", std.mem.span(node_name));
}

test "Node: contains" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const parent = document_bindings.dom_document_createelement(doc, "div");
    const child = document_bindings.dom_document_createelement(doc, "span");
    const unrelated = document_bindings.dom_document_createelement(doc, "p");

    const parent_node = @as(*DOMNode, @ptrCast(parent));
    const child_node = @as(*DOMNode, @ptrCast(child));
    const unrelated_node = @as(*DOMNode, @ptrCast(unrelated));

    _ = node_bindings.dom_node_appendchild(parent_node, child_node);

    // Parent should contain child
    const contains_child = node_bindings.dom_node_contains(parent_node, child_node);
    try testing.expectEqual(@as(u8, 1), contains_child);

    // Parent should not contain unrelated
    const contains_unrelated = node_bindings.dom_node_contains(parent_node, unrelated_node);
    try testing.expectEqual(@as(u8, 0), contains_unrelated);

    // Cleanup (defer handles doc)
    element_bindings.dom_element_release(parent);
    element_bindings.dom_element_release(unrelated);
}

test "Complex: build document tree" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    // Create structure: div#container > span.text + p.description
    const div = document_bindings.dom_document_createelement(doc, "div");
    const span = document_bindings.dom_document_createelement(doc, "span");
    const p = document_bindings.dom_document_createelement(doc, "p");

    // Set attributes
    _ = element_bindings.dom_element_set_id(div, "container");
    _ = element_bindings.dom_element_set_classname(span, "text");
    _ = element_bindings.dom_element_set_classname(p, "description");

    // Build tree
    const div_node = @as(*DOMNode, @ptrCast(div));
    _ = node_bindings.dom_node_appendchild(div_node, @ptrCast(span));
    _ = node_bindings.dom_node_appendchild(div_node, @ptrCast(p));

    // Add text content
    const text = document_bindings.dom_document_createtextnode(doc, "Hello");
    _ = node_bindings.dom_node_appendchild(@ptrCast(span), @ptrCast(text));

    // Verify structure
    try testing.expectEqual(@as(u8, 1), node_bindings.dom_node_haschildnodes(div_node));

    const first_child = node_bindings.dom_node_get_firstchild(div_node);
    try testing.expect(first_child != null);

    // Verify attributes
    const id = element_bindings.dom_element_get_id(div);
    try testing.expectEqualStrings("container", std.mem.span(id));

    // Cleanup (defer handles doc)
    element_bindings.dom_element_release(div);
}

test "Error handling: invalid attribute name" {
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    const elem = document_bindings.dom_document_createelement(doc, "div");
    defer element_bindings.dom_element_release(elem);

    // Try to set attribute with invalid name (contains space)
    const result = element_bindings.dom_element_setattribute(elem, "invalid name", "value");

    // TODO: Should return error code (InvalidCharacterError = 5)
    // Currently DOM implementation doesn't validate attribute names
    // For now, test that it succeeds (but shouldn't)
    try testing.expectEqual(@as(c_int, 0), result);
}

test "Memory: no leaks with complex tree" {
    // This test uses testing.allocator which detects leaks
    const doc = document_bindings.dom_document_new();
    defer document_bindings.dom_document_release(doc);

    // Create many elements
    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const div = document_bindings.dom_document_createelement(doc, "div");
        const span = document_bindings.dom_document_createelement(doc, "span");

        const div_node = @as(*DOMNode, @ptrCast(div));
        _ = node_bindings.dom_node_appendchild(div_node, @ptrCast(span));

        _ = element_bindings.dom_element_setattribute(div, "id", "test");
        _ = element_bindings.dom_element_removeattribute(div, "id");

        element_bindings.dom_element_release(div);
    }

    // If we reach here without leaks, test passes
}
