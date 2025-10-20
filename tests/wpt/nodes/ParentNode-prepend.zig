// WPT Test: ParentNode-prepend.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/ParentNode-prepend.html
//
// Tests ParentNode.prepend() behavior as specified in WHATWG DOM Standard § 4.2.6
// https://dom.spec.whatwg.org/#dom-parentnode-prepend

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const DocumentFragment = dom.DocumentFragment;

// Pre-insertion validation hierarchy tests (Step 2, 4, 5, 6)
// These test hierarchy constraint errors per WHATWG DOM § 4.2.3

test "prepend: If node is a host-including inclusive ancestor of parent, throw HierarchyRequestError" {
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

    // Attempting to prepend body to itself
    const result1 = body.prepend(&[_]Element.NodeOrString{.{ .node = &body.prototype }});
    try std.testing.expectError(error.HierarchyRequestError, result1);

    // Attempting to prepend documentElement (html) to body (which is a descendant)
    const result2 = body.prepend(&[_]Element.NodeOrString{.{ .node = &html.prototype }});
    try std.testing.expectError(error.HierarchyRequestError, result2);
}

test "prepend: If node is not DocumentFragment, DocumentType, Element, Text, ProcessingInstruction, or Comment, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const body = try doc.createElement("body");
    defer body.prototype.release();

    // Attempting to prepend a Document to an element
    const result = body.prepend(&[_]Element.NodeOrString{.{ .node = &doc2.prototype }});
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "prepend: If node is a Text and parent is a document, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    // Document doesn't have .prepend(), so we test via insertBefore which has same validation
    const result = doc.prototype.insertBefore(&text.prototype, doc.prototype.first_child);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "prepend: If node is a doctype and parent is not a document, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    _ = try doc.prototype.insertBefore(&doctype.prototype, doc.prototype.first_child);

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    // Attempting to prepend doctype to an element
    const result = elem.prepend(&[_]Element.NodeOrString{.{ .node = &doctype.prototype }});
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "prepend: If node is DocumentFragment with multiple elements and parent is a document, throw HierarchyRequestError" {
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

    // Document doesn't have .prepend(), so we test via insertBefore which has same validation
    const result = doc.prototype.insertBefore(&df.prototype, doc.prototype.first_child);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "prepend: If node is DocumentFragment with an element and parent is a document with another element, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&html.prototype);

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    const elem = try doc.createElement("container");
    _ = try df.prototype.appendChild(&elem.prototype);

    // Document doesn't have .prepend(), so we test via insertBefore which has same validation
    const result = doc.prototype.insertBefore(&df.prototype, doc.prototype.first_child);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "prepend: If node is an Element and parent is a document with another element, throw HierarchyRequestError" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&html.prototype);

    const elem = try doc.createElement("container");
    defer elem.prototype.release();

    // Document doesn't have .prepend(), so we test via insertBefore which has same validation
    const result = doc.prototype.insertBefore(&elem.prototype, doc.prototype.first_child);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "prepend: If node is a doctype and parent is a document with another doctype, throw HierarchyRequestError" {
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

    // Document doesn't have .prepend(), so we test via insertBefore which has same validation
    const result = doc.prototype.insertBefore(&doctype2.prototype, doc.prototype.first_child);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

// Note: The test "If node is a doctype and parent is a document with an element" is skipped
// for prepend as per the WPT test comment: "Skip `.prepend` as this doesn't throw if `child` is an element"

// Element.prepend() tests

test "Element.prepend() without any argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    try parent.prepend(&[_]Element.NodeOrString{});
    try std.testing.expectEqual(@as(?*dom.Node, null), parent.prototype.first_child);
}

test "Element.prepend() with only text as an argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    try parent.prepend(&[_]Element.NodeOrString{.{ .string = "text" }});

    try std.testing.expect(parent.prototype.first_child != null);
    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Element.prepend() with only one element as an argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const child = try doc.createElement("child");

    try parent.prepend(&[_]Element.NodeOrString{.{ .node = &child.prototype }});

    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
}

test "Element.prepend() with text as an argument, on a parent having a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const existing_child = try doc.createElement("existing");
    _ = try parent.prototype.appendChild(&existing_child.prototype);

    try parent.prepend(&[_]Element.NodeOrString{.{ .string = "text" }});

    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
    try std.testing.expectEqual(&existing_child.prototype, parent.prototype.first_child.?.next_sibling.?);
}

test "Element.prepend() with one element and text as argument, on a parent having a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const existing_child = try doc.createElement("existing");
    _ = try parent.prototype.appendChild(&existing_child.prototype);

    const new_child = try doc.createElement("new");

    try parent.prepend(&[_]Element.NodeOrString{
        .{ .node = &new_child.prototype },
        .{ .string = "text" },
    });

    try std.testing.expectEqual(&new_child.prototype, parent.prototype.first_child.?);
    const text_content = try parent.prototype.first_child.?.next_sibling.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
    try std.testing.expectEqual(&existing_child.prototype, parent.prototype.last_child.?);
}

// DocumentFragment.prepend() tests

test "DocumentFragment.prepend() without any argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    try parent.prepend(&[_]DocumentFragment.NodeOrString{});
    try std.testing.expectEqual(@as(?*dom.Node, null), parent.prototype.first_child);
}

test "DocumentFragment.prepend() with only text as an argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    try parent.prepend(&[_]DocumentFragment.NodeOrString{.{ .string = "text" }});

    try std.testing.expect(parent.prototype.first_child != null);
    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "DocumentFragment.prepend() with only one element as an argument, on a parent having no child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    const child = try doc.createElement("child");

    try parent.prepend(&[_]DocumentFragment.NodeOrString{.{ .node = &child.prototype }});

    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
}

test "DocumentFragment.prepend() with text as an argument, on a parent having a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    const existing_child = try doc.createElement("existing");
    _ = try parent.prototype.appendChild(&existing_child.prototype);

    try parent.prepend(&[_]DocumentFragment.NodeOrString{.{ .string = "text" }});

    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
    try std.testing.expectEqual(&existing_child.prototype, parent.prototype.first_child.?.next_sibling.?);
}

test "DocumentFragment.prepend() with one element and text as argument, on a parent having a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createDocumentFragment();
    defer parent.prototype.release();

    const existing_child = try doc.createElement("existing");
    _ = try parent.prototype.appendChild(&existing_child.prototype);

    const new_child = try doc.createElement("new");

    try parent.prepend(&[_]DocumentFragment.NodeOrString{
        .{ .node = &new_child.prototype },
        .{ .string = "text" },
    });

    try std.testing.expectEqual(&new_child.prototype, parent.prototype.first_child.?);
    const text_content = try parent.prototype.first_child.?.next_sibling.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expect(text_content != null);
    try std.testing.expectEqualStrings("text", text_content.?);
    try std.testing.expectEqual(&existing_child.prototype, parent.prototype.last_child.?);
}

// Note: JavaScript tests for prepend(null) and prepend(undefined) are not applicable in Zig
// because Zig is statically typed and doesn't have null/undefined JavaScript semantics.
// The NodeOrString union handles nodes and strings explicitly at compile time.
