// WPT Test: ChildNode-before.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/ChildNode-before.html
//
// Tests ChildNode.before() behavior as specified in WHATWG DOM Standard § 4.5
// https://dom.spec.whatwg.org/#dom-childnode-before

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;

// Helper to count children
fn countChildren(parent: *dom.Node) usize {
    var count: usize = 0;
    var maybe_child = parent.first_child;
    while (maybe_child) |child| : (maybe_child = child.next_sibling) {
        count += 1;
    }
    return count;
}

// Element.before() tests

test "Element.before() without any argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Element.NodeOrString{});

    // Child should still be the only child
    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
}

test "Element.before() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Element.NodeOrString{.{ .string = "text" }});

    // Should have 2 children: text, child
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);

    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?.next_sibling.?);
}

test "Element.before() with the empty string as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Element.NodeOrString{.{ .string = "" }});

    // Should have 2 children
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    // First child should be empty text node
    try std.testing.expect(parent.prototype.first_child.?.node_type == .text);
    const TextType = @import("dom").Text;
    const text_node: *TextType = @fieldParentPtr("prototype", parent.prototype.first_child.?);
    try std.testing.expectEqualStrings("", text_node.data);
}

test "Element.before() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.before(&[_]Element.NodeOrString{.{ .node = &x.prototype }});

    // Should have 2 children: x, child
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?.next_sibling.?);
}

test "Element.before() with one element and text as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.before(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .string = "text" },
    });

    // Should have 3 children: x, text, child
    try std.testing.expectEqual(@as(usize, 3), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);

    const text_content = try parent.prototype.first_child.?.next_sibling.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);

    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

test "Element.before() with context object itself as the argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Element.NodeOrString{
        .{ .string = "text" },
        .{ .node = &child.prototype },
    });

    // Child moves before itself with text - effectively just adds text before child
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);

    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

test "Element.before() with context object itself and node as the arguments, switching positions" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    const x = try doc.createElement("elem-x");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);

    try child.before(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .node = &child.prototype },
    });

    // Result: x, child (x moved before child)
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

test "Element.before() with all siblings of child as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const x = try doc.createElement("elem-x");
    const y = try doc.createElement("elem-y");
    const z = try doc.createElement("elem-z");
    const child = try doc.createElement("child");

    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);

    try child.before(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .node = &y.prototype },
        .{ .node = &z.prototype },
    });

    // Result: x, y, z, child
    try std.testing.expectEqual(@as(usize, 4), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&y.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expectEqual(&z.prototype, parent.prototype.first_child.?.next_sibling.?.next_sibling.?);
    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

test "Element.before() with some siblings of child as arguments; no changes in tree; viable sibling is first child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const x = try doc.createElement("elem-x");
    const y = try doc.createElement("elem-y");
    const z = try doc.createElement("elem-z");
    const child = try doc.createElement("child");

    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&z.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Element.NodeOrString{
        .{ .node = &y.prototype },
        .{ .node = &z.prototype },
    });

    // Result: x, y, z, child (y and z already before child, just reordered)
    try std.testing.expectEqual(@as(usize, 4), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&y.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expectEqual(&z.prototype, parent.prototype.first_child.?.next_sibling.?.next_sibling.?);
    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

test "Element.before() with some siblings of child as arguments; no changes in tree" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const v = try doc.createElement("elem-v");
    const x = try doc.createElement("elem-x");
    const y = try doc.createElement("elem-y");
    const z = try doc.createElement("elem-z");
    const child = try doc.createElement("child");

    _ = try parent.prototype.appendChild(&v.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&z.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Element.NodeOrString{
        .{ .node = &y.prototype },
        .{ .node = &z.prototype },
    });

    // Result: v, x, y, z, child
    try std.testing.expectEqual(@as(usize, 5), countChildren(&parent.prototype));
    try std.testing.expectEqual(&v.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?.next_sibling.?);
}

test "Element.before() when pre-insert behaves like prepend" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const x = try doc.createElement("elem-x");
    const y = try doc.createElement("elem-y");
    const child = try doc.createElement("child");

    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Element.NodeOrString{
        .{ .node = &y.prototype },
        .{ .node = &x.prototype },
    });

    // Result: y, x, child
    try std.testing.expectEqual(@as(usize, 3), countChildren(&parent.prototype));
    try std.testing.expectEqual(&y.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

test "Element.before() with one sibling of child and text as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const x = try doc.createElement("elem-x");
    const text1 = try doc.createTextNode("1");
    const y = try doc.createElement("elem-y");
    const child = try doc.createElement("child");

    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .string = "2" },
    });

    // Result: 1, y, x, 2, child
    try std.testing.expectEqual(@as(usize, 5), countChildren(&parent.prototype));
}

test "Element.before() on a child without any parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const x = try doc.createElement("elem-x");
    defer x.prototype.release();

    const y = try doc.createElement("elem-y");
    defer y.prototype.release();

    // Should be a no-op
    try x.before(&[_]Element.NodeOrString{.{ .node = &y.prototype }});

    try std.testing.expect(x.prototype.previous_sibling == null);
    try std.testing.expect(x.prototype.next_sibling == null);
}

// Text.before() tests

test "Text.before() without any argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createTextNode("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Text.NodeOrString{});

    // Child should still be the only child
    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
}

test "Text.before() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createTextNode("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Text.NodeOrString{.{ .string = "before" }});

    // Should have 2 children
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    const text_content = try parent.prototype.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("beforetest", text_content.?);
}

test "Text.before() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createTextNode("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.before(&[_]Text.NodeOrString{.{ .node = &x.prototype }});

    // Should have 2 children: x, text
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

// Comment.before() tests

test "Comment.before() without any argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createComment("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Comment.NodeOrString{});

    // Child should still be the only child
    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
}

test "Comment.before() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createComment("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.before(&[_]Comment.NodeOrString{.{ .string = "text" }});

    // Should have 2 children: text, comment
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Comment.before() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createComment("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.before(&[_]Comment.NodeOrString{.{ .node = &x.prototype }});

    // Should have 2 children: x, comment
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

// Note: JavaScript tests for before(null) and before(undefined) are not applicable in Zig
// because Zig is statically typed and doesn't have null/undefined JavaScript semantics.
// The NodeOrString union handles nodes and strings explicitly at compile time.
