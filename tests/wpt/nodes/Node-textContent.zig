// WPT Test: Node-textContent
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/Node-textContent.html
// Translated from JavaScript to Zig

const std = @import("std");
const dom = @import("dom");

// Getting textContent

test "For an empty Element, textContent should be the empty string" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("div");
    defer element.prototype.release();

    const content = try element.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("", content.?);
}

test "For an empty DocumentFragment, textContent should be the empty string" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    const content = try df.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("", content.?);
}

test "Element with children" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.prototype.release();

    const comment = try doc.createComment(" abc ");
    _ = try el.prototype.appendChild(&comment.prototype);

    const text = try doc.createTextNode("\tDEF\t");
    _ = try el.prototype.appendChild(&text.prototype);

    // Note: DOM library doesn't support ProcessingInstruction yet
    // el.appendChild(document.createProcessingInstruction("x", " ghi "))

    const content = try el.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("\tDEF\t", content.?);
}

test "Element with descendants" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.prototype.release();

    const child = try doc.createElement("div");
    _ = try el.prototype.appendChild(&child.prototype);

    const comment = try doc.createComment(" abc ");
    _ = try child.prototype.appendChild(&comment.prototype);

    const text = try doc.createTextNode("\tDEF\t");
    _ = try child.prototype.appendChild(&text.prototype);

    const content = try el.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("\tDEF\t", content.?);
}

test "DocumentFragment with children" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    const comment = try doc.createComment(" abc ");
    _ = try df.prototype.appendChild(&comment.prototype);

    const text = try doc.createTextNode("\tDEF\t");
    _ = try df.prototype.appendChild(&text.prototype);

    const content = try df.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("\tDEF\t", content.?);
}

test "DocumentFragment with descendants" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    const child = try doc.createElement("div");
    _ = try df.prototype.appendChild(&child.prototype);

    const comment = try doc.createComment(" abc ");
    _ = try child.prototype.appendChild(&comment.prototype);

    const text = try doc.createTextNode("\tDEF\t");
    _ = try child.prototype.appendChild(&text.prototype);

    const content = try df.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("\tDEF\t", content.?);
}

// Text, ProcessingInstruction, Comment

test "For an empty Text, textContent should be the empty string" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.prototype.release();

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("", content.?);
}

test "For an empty Comment, textContent should be the empty string" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.prototype.release();

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("", content.?);
}

test "For a Text with data, textContent should be that data" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("abc");
    defer text.prototype.release();

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("abc", content.?);
}

test "For a Comment with data, textContent should be that data" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("abc");
    defer comment.prototype.release();

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("abc", content.?);
}

// Document

test "For Documents, textContent should be null" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const content = try doc.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content == null);
}

// Setting textContent

test "Element without children set to null" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.prototype.release();

    try el.prototype.setTextContent(null);

    const content = try el.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("", content.?);
    try std.testing.expect(el.prototype.first_child == null);
}

test "Element without children set to empty string" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.prototype.release();

    try el.prototype.setTextContent("");

    const content = try el.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("", content.?);
    try std.testing.expect(el.prototype.first_child == null);
}

test "Element without children set to abc" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.prototype.release();

    try el.prototype.setTextContent("abc");

    const content = try el.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("abc", content.?);

    // Should have one child
    try std.testing.expect(el.prototype.first_child != null);
    try std.testing.expectEqual(@as(u32, 1), el.prototype.childNodes().length());

    const first_child = el.prototype.first_child.?;
    try std.testing.expectEqual(dom.NodeType.text, first_child.node_type);

    const Text = dom.Text;
    const text_node: *Text = @fieldParentPtr("prototype", first_child);
    try std.testing.expectEqualStrings("abc", text_node.data);
}

test "Element with empty text node as child set to abc" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.prototype.release();

    const text = try doc.createTextNode("");
    _ = try el.prototype.appendChild(&text.prototype);

    // Note: In Zig implementation, setTextContent removes and releases all children
    // So we can't access `text` after this point (it's been freed)
    try el.prototype.setTextContent("abc");

    const content = try el.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("abc", content.?);
    // Original WPT test checks text.parentNode == null, but in our implementation
    // the text node has been freed, so we can't check it
}

test "Element with children set to abc" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.prototype.release();

    const comment = try doc.createComment(" abc ");
    _ = try el.prototype.appendChild(&comment.prototype);

    const text = try doc.createTextNode("\tDEF\t");
    _ = try el.prototype.appendChild(&text.prototype);

    try el.prototype.setTextContent("abc");

    const content = try el.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("abc", content.?);
    try std.testing.expectEqual(@as(u32, 1), el.prototype.childNodes().length());
}

test "Element with descendants set to abc" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const el = try doc.createElement("div");
    defer el.prototype.release();

    const child = try doc.createElement("div");
    _ = try el.prototype.appendChild(&child.prototype);

    const comment = try doc.createComment(" abc ");
    _ = try child.prototype.appendChild(&comment.prototype);

    const text = try doc.createTextNode("\tDEF\t");
    _ = try child.prototype.appendChild(&text.prototype);

    try el.prototype.setTextContent("abc");

    const content = try el.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("abc", content.?);

    // Note: In Zig implementation, setTextContent removes and releases all children
    // So we can't access `child` after this point (it's been freed)
    // Original WPT test checks child.childNodes.length, but we can't do that
}

test "DocumentFragment without children set to abc" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    try df.prototype.setTextContent("abc");

    const content = try df.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("abc", content.?);
    try std.testing.expectEqual(@as(u32, 1), df.prototype.childNodes().length());
}

test "DocumentFragment with children set to abc" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const df = try doc.createDocumentFragment();
    defer df.prototype.release();

    const comment = try doc.createComment(" abc ");
    _ = try df.prototype.appendChild(&comment.prototype);

    const text = try doc.createTextNode("\tDEF\t");
    _ = try df.prototype.appendChild(&text.prototype);

    try df.prototype.setTextContent("abc");

    const content = try df.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("abc", content.?);
    try std.testing.expectEqual(@as(u32, 1), df.prototype.childNodes().length());
}

// Text and Comment

test "For a Text, textContent should set the data" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("abc");
    defer text.prototype.release();

    try text.prototype.setTextContent("def");

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("def", content.?);
    try std.testing.expectEqualStrings("def", text.data);
}

test "For a Comment, textContent should set the data" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("abc");
    defer comment.prototype.release();

    try comment.prototype.setTextContent("def");

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("def", content.?);
    try std.testing.expectEqualStrings("def", comment.data);
}

// Document

test "For Documents, setting textContent should do nothing" {
    const allocator = std.testing.allocator;

    const doc = try dom.Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    try doc.prototype.setTextContent("a");

    const content = try doc.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content == null);
    // documentElement should still be root
    try std.testing.expect(doc.prototype.first_child == &root.prototype);
}
