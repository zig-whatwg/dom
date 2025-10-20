// WPT Test: ParentNode-append.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/ParentNode-append.html
//
// Tests ParentNode.append() behavior as specified in WHATWG DOM Standard § 4.2.6
// https://dom.spec.whatwg.org/#dom-parentnode-append

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const DocumentFragment = dom.DocumentFragment;

// Pre-insertion validation hierarchy tests (Step 2, 4, 5, 6)
// These test hierarchy constraint errors per WHATWG DOM § 4.2.3

test "append: If node is a host-including inclusive ancestor of parent, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Remove default documentElement if present
    if (doc.prototype.first_child) |child| {
        _ = try doc.prototype.removeChild(child);
        child.release();
    }

    const html = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&html.prototype);

    const body = try doc.createElement("body");
    _ = try html.prototype.appendChild(&body.prototype);

    // Attempting to append body to itself
    const result1 = body.append(&[_]Element.NodeOrString{.{ .node = &body.prototype }});
    try std.testing.expectError(error.HierarchyRequestError, result1);

    // Attempting to append documentElement (html) to body (which is a descendant)
    const result2 = body.append(&[_]Element.NodeOrString{.{ .node = &html.prototype }});
    try std.testing.expectError(error.HierarchyRequestError, result2);
}

test "append: If node is not DocumentFragment, DocumentType, Element, Text, ProcessingInstruction, or Comment, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const body = try doc.createElement("body");
    _ = try doc.prototype.appendChild(&body.prototype);

    // Attempting to append a Document to an element
    const result = body.append(&[_]Element.NodeOrString{.{ .node = &doc2.prototype }});
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "append: If node is a Text and parent is a document, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    // Document doesn't have .append(), so we test via appendChild which has same validation
    const result = doc.prototype.appendChild(&text.prototype);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "append: If node is a doctype and parent is not a document, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    _ = try doc.prototype.insertBefore(&doctype.prototype, doc.prototype.first_child);

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    // Attempting to append doctype to an element
    const result = elem.append(&[_]Element.NodeOrString{.{ .node = &doctype.prototype }});
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "append: If node is DocumentFragment with multiple elements and parent is a document, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Remove existing documentElement
    if (doc.prototype.first_child) |child| {
        _ = try doc.prototype.removeChild(child);
        child.release();
    }

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    const elem_a = try doc.createElement("elem-a");
    const elem_b = try doc.createElement("elem-b");

    _ = try df.prototype.appendChild(&elem_a.prototype);
    _ = try df.prototype.appendChild(&elem_b.prototype);

    // Document doesn't have .append(), so we test via appendChild which has same validation
    const result = doc.prototype.appendChild(&df.prototype);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "append: If node is DocumentFragment with an element and parent is a document with another element, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&html.prototype);

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    const elem = try doc.createElement("container");
    _ = try df.prototype.appendChild(&elem.prototype);

    // Document doesn't have .append(), so we test via appendChild which has same validation
    const result = doc.prototype.appendChild(&df.prototype);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "append: If node is an Element and parent is a document with another element, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&html.prototype);

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    // Document doesn't have .append(), so we test via appendChild which has same validation
    const result = doc.prototype.appendChild(&elem.prototype);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "append: If node is a doctype and parent is a document with another doctype, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype1 = try doc.createDocumentType("html", "", "");
    _ = try doc.prototype.insertBefore(&doctype1.prototype, doc.prototype.first_child);

    // Remove documentElement so we can have multiple doctypes scenario
    if (doc.prototype.first_child) |child| {
        if (child.node_type == .element) {
            _ = try doc.prototype.removeChild(child);
            child.release();
        }
    }

    const doctype2 = try doc.createDocumentType("html2", "", "");
    defer doctype2.prototype.release();

    // Document doesn't have .append(), so we test via appendChild which has same validation
    const result = doc.prototype.appendChild(&doctype2.prototype);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "append: If node is a doctype and parent is a document with an element, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&html.prototype);

    // Remove existing doctype if any
    var maybe_child = doc.prototype.first_child;
    while (maybe_child) |child| {
        const next = child.next_sibling;
        if (child.node_type == .document_type) {
            _ = try doc.prototype.removeChild(child);
            child.release();
        }
        maybe_child = next;
    }

    const doctype = try doc.createDocumentType("html", "", "");
    defer doctype.prototype.release();

    // Document doesn't have .append(), so we test via appendChild which has same validation
    const result = doc.prototype.appendChild(&doctype.prototype);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

// Element.append() tests

test "Element.append() without any argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    try parent.append(&[_]Element.NodeOrString{});
    try std.testing.expectEqual(@as(?*dom.Node, null), parent.prototype.first_child);
}

test "Element.append() with only text as an argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    try parent.append(&[_]Element.NodeOrString{.{ .string = "text" }});

    try std.testing.expect(parent.prototype.first_child != null);
    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Element.append() with only one element as an argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const child = try doc.createElement("child");

    try parent.append(&[_]Element.NodeOrString{.{ .node = &child.prototype }});

    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
}

test "Element.append() with text as an argument, on a parent having a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const existing_child = try doc.createElement("existing");
    _ = try parent.prototype.appendChild(&existing_child.prototype);

    try parent.append(&[_]Element.NodeOrString{.{ .string = "text" }});

    try std.testing.expectEqual(&existing_child.prototype, parent.prototype.first_child.?);
    try std.testing.expect(parent.prototype.last_child != null);
    const text_content = try parent.prototype.last_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Element.append() with one element and text as argument, on a parent having a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const existing_child = try doc.createElement("existing");
    _ = try parent.prototype.appendChild(&existing_child.prototype);

    const new_child = try doc.createElement("new");

    try parent.append(&[_]Element.NodeOrString{
        .{ .node = &new_child.prototype },
        .{ .string = "text" },
    });

    try std.testing.expectEqual(&existing_child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&new_child.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expect(parent.prototype.last_child != null);
    const text_content = try parent.prototype.last_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Element.append() with the same element twice" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const elem_x = try doc.createElement("elem-x");
    const elem_y = try doc.createElement("elem-y");

    try parent.append(&[_]Element.NodeOrString{
        .{ .node = &elem_x.prototype },
        .{ .node = &elem_y.prototype },
        .{ .node = &elem_x.prototype },
    });

    // Should only have 2 children (x moves to the end)
    var count: usize = 0;
    var maybe_child = parent.prototype.first_child;
    while (maybe_child) |child| : (maybe_child = child.next_sibling) {
        count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), count);

    // Order should be: y, x
    try std.testing.expectEqual(&elem_y.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&elem_x.prototype, parent.prototype.last_child.?);
}

// DocumentFragment.append() tests

test "DocumentFragment.append() without any argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    try parent.append(&[_]DocumentFragment.NodeOrString{});
    try std.testing.expectEqual(@as(?*dom.Node, null), parent.prototype.first_child);
}

test "DocumentFragment.append() with only text as an argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    try parent.append(&[_]DocumentFragment.NodeOrString{.{ .string = "text" }});

    try std.testing.expect(parent.prototype.first_child != null);
    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "DocumentFragment.append() with only one element as an argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    const child = try doc.createElement("child");

    try parent.append(&[_]DocumentFragment.NodeOrString{.{ .node = &child.prototype }});

    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
}

test "DocumentFragment.append() with text as an argument, on a parent having a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    const existing_child = try doc.createElement("existing");
    _ = try parent.prototype.appendChild(&existing_child.prototype);

    try parent.append(&[_]DocumentFragment.NodeOrString{.{ .string = "text" }});

    try std.testing.expectEqual(&existing_child.prototype, parent.prototype.first_child.?);
    try std.testing.expect(parent.prototype.last_child != null);
    const text_content = try parent.prototype.last_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "DocumentFragment.append() with one element and text as argument, on a parent having a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    const existing_child = try doc.createElement("existing");
    _ = try parent.prototype.appendChild(&existing_child.prototype);

    const new_child = try doc.createElement("new");

    try parent.append(&[_]DocumentFragment.NodeOrString{
        .{ .node = &new_child.prototype },
        .{ .string = "text" },
    });

    try std.testing.expectEqual(&existing_child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&new_child.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expect(parent.prototype.last_child != null);
    const text_content = try parent.prototype.last_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "DocumentFragment.append() with the same element twice" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    const elem_x = try doc.createElement("elem-x");
    const elem_y = try doc.createElement("elem-y");

    try parent.append(&[_]DocumentFragment.NodeOrString{
        .{ .node = &elem_x.prototype },
        .{ .node = &elem_y.prototype },
        .{ .node = &elem_x.prototype },
    });

    // Should only have 2 children (x moves to the end)
    var count: usize = 0;
    var maybe_child = parent.prototype.first_child;
    while (maybe_child) |child| : (maybe_child = child.next_sibling) {
        count += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), count);

    // Order should be: y, x
    try std.testing.expectEqual(&elem_y.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&elem_x.prototype, parent.prototype.last_child.?);
}

// Note: JavaScript tests for append(null) and append(undefined) are not applicable in Zig
// because Zig is statically typed and doesn't have null/undefined JavaScript semantics.
// The NodeOrString union handles nodes and strings explicitly at compile time.
