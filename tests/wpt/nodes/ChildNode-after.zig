// WPT Test: ChildNode-after.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/ChildNode-after.html
//
// Tests ChildNode.after() behavior as specified in WHATWG DOM Standard § 4.5
// https://dom.spec.whatwg.org/#dom-childnode-after

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

// Element.after() tests

test "Element.after() without any argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Element.NodeOrString{});

    // Child should still be the only child
    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
}

test "Element.after() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Element.NodeOrString{.{ .string = "text" }});

    // Should have 2 children: child, text
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);

    const text_content = try parent.prototype.last_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Element.after() with the empty string as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Element.NodeOrString{.{ .string = "" }});

    // Should have 2 children
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    // Last child should be empty text node
    try std.testing.expect(parent.prototype.last_child.?.node_type == .text);
    const TextType = @import("dom").Text;
    const text_node: *TextType = @fieldParentPtr("prototype", parent.prototype.last_child.?);
    try std.testing.expectEqualStrings("", text_node.data);
}

test "Element.after() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.after(&[_]Element.NodeOrString{.{ .node = &x.prototype }});

    // Should have 2 children: child, x
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.last_child.?);
}

test "Element.after() with one element and text as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.after(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .string = "text" },
    });

    // Should have 3 children: child, x, text
    try std.testing.expectEqual(@as(usize, 3), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?.next_sibling.?);

    const text_content = try parent.prototype.last_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Element.after() with context object itself as the argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Element.NodeOrString{
        .{ .string = "text" },
        .{ .node = &child.prototype },
    });

    // Child moves after itself with text - effectively just adds text after child
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    const text_content = try parent.prototype.first_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);

    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child.?);
}

test "Element.after() with context object itself and node as the arguments, switching positions" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const x = try doc.createElement("elem-x");
    const child = try doc.createElement("child");

    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Element.NodeOrString{
        .{ .node = &child.prototype },
        .{ .node = &x.prototype },
    });

    // Result: child, x (they switch positions)
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.last_child.?);
}

test "Element.after() with all siblings of child as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const y = try doc.createElement("elem-y");
    const child = try doc.createElement("child");
    const x = try doc.createElement("elem-x");
    const z = try doc.createElement("elem-z");

    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);

    try child.after(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .node = &y.prototype },
        .{ .node = &z.prototype },
    });

    // Result: child, x, y, z
    try std.testing.expectEqual(@as(usize, 4), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expectEqual(&y.prototype, parent.prototype.first_child.?.next_sibling.?.next_sibling.?);
    try std.testing.expectEqual(&z.prototype, parent.prototype.last_child.?);
}

test "Element.after() with some siblings of child as arguments; no changes in tree" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    const x = try doc.createElement("elem-x");
    const y = try doc.createElement("elem-y");
    const z = try doc.createElement("elem-z");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&z.prototype);

    try child.after(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .node = &y.prototype },
    });

    // Result: child, x, y, z (x and y already after child, just reordered)
    try std.testing.expectEqual(@as(usize, 4), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expectEqual(&y.prototype, parent.prototype.first_child.?.next_sibling.?.next_sibling.?);
    try std.testing.expectEqual(&z.prototype, parent.prototype.last_child.?);
}

test "Element.after() with some siblings of child as arguments; no changes in tree (variant)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    const v = try doc.createElement("elem-v");
    const x = try doc.createElement("elem-x");
    const y = try doc.createElement("elem-y");
    const z = try doc.createElement("elem-z");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&v.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&z.prototype);

    try child.after(&[_]Element.NodeOrString{
        .{ .node = &v.prototype },
        .{ .node = &x.prototype },
    });

    // Result: child, v, x, y, z
    try std.testing.expectEqual(@as(usize, 5), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&v.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?.next_sibling.?.next_sibling.?);
}

test "Element.after() when pre-insert behaves like append" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    const x = try doc.createElement("elem-x");
    const y = try doc.createElement("elem-y");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);

    try child.after(&[_]Element.NodeOrString{
        .{ .node = &y.prototype },
        .{ .node = &x.prototype },
    });

    // Result: child, y, x
    try std.testing.expectEqual(@as(usize, 3), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&y.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.last_child.?);
}

test "Element.after() with one sibling of child and text as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    const x = try doc.createElement("elem-x");
    const text1 = try doc.createTextNode("1");
    const y = try doc.createElement("elem-y");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);

    try child.after(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .string = "2" },
    });

    // Result: child, x, 2, 1, y
    try std.testing.expectEqual(@as(usize, 5), countChildren(&parent.prototype));
}

test "Element.after() on a child without any parent" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const x = try doc.createElement("elem-x");
    defer x.prototype.release();

    const y = try doc.createElement("elem-y");
    defer y.prototype.release();

    // Should be a no-op
    try x.after(&[_]Element.NodeOrString{.{ .node = &y.prototype }});

    try std.testing.expect(x.prototype.previous_sibling == null);
    try std.testing.expect(x.prototype.next_sibling == null);
}

// Text.after() tests

test "Text.after() without any argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createTextNode("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Text.NodeOrString{});

    // Child should still be the only child
    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
}

test "Text.after() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createTextNode("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Text.NodeOrString{.{ .string = "after" }});

    // Should have 2 children
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    const text_content = try parent.prototype.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("testafter", text_content.?);
}

test "Text.after() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createTextNode("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.after(&[_]Text.NodeOrString{.{ .node = &x.prototype }});

    // Should have 2 children: text, x
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.last_child.?);
}

// Comment.after() tests

test "Comment.after() without any argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createComment("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Comment.NodeOrString{});

    // Child should still be the only child
    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
}

test "Comment.after() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createComment("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.after(&[_]Comment.NodeOrString{.{ .string = "text" }});

    // Should have 2 children: comment, text
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));

    const text_content = try parent.prototype.last_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Comment.after() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createComment("test");
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.after(&[_]Comment.NodeOrString{.{ .node = &x.prototype }});

    // Should have 2 children: comment, x
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&x.prototype, parent.prototype.last_child.?);
}

// Note: JavaScript tests for after(null) and after(undefined) are not applicable in Zig
// because Zig is statically typed and doesn't have null/undefined JavaScript semantics.
// The NodeOrString union handles nodes and strings explicitly at compile time.
