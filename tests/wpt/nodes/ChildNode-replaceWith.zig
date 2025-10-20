// WPT Test: ChildNode-replaceWith.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/ChildNode-replaceWith.html
//
// Tests ChildNode.replaceWith() behavior as specified in WHATWG DOM Standard § 4.5
// https://dom.spec.whatwg.org/#dom-childnode-replacewith

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

// Element.replaceWith() tests

test "Element.replaceWith() without any argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.replaceWith(&[_]Element.NodeOrString{});

    // Child should be removed, parent empty
    try std.testing.expectEqual(@as(usize, 0), countChildren(&parent.prototype));
}

test "Element.replaceWith() with empty string as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.replaceWith(&[_]Element.NodeOrString{.{ .string = "" }});

    // Child replaced with empty text node
    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    try std.testing.expect(parent.prototype.first_child.?.node_type == .text);
}

test "Element.replaceWith() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.replaceWith(&[_]Element.NodeOrString{.{ .string = "text" }});

    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    const text_content = try parent.prototype.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Element.replaceWith() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.replaceWith(&[_]Element.NodeOrString{.{ .node = &x.prototype }});

    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
}

test "Element.replaceWith() with sibling of child as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const y = try doc.createElement("elem-y");
    const child = try doc.createElement("child");
    defer child.prototype.release();
    const x = try doc.createElement("elem-x");
    const z = try doc.createElement("elem-z");

    _ = try parent.prototype.appendChild(&y.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);

    try child.replaceWith(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .node = &y.prototype },
        .{ .node = &z.prototype },
    });

    // Result: x, y, z (child replaced, siblings moved)
    try std.testing.expectEqual(@as(usize, 3), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&y.prototype, parent.prototype.first_child.?.next_sibling.?);
    try std.testing.expectEqual(&z.prototype, parent.prototype.last_child.?);
}

test "Element.replaceWith() with one sibling of child and text as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    defer child.prototype.release();
    const x = try doc.createElement("elem-x");
    const text1 = try doc.createTextNode("1");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&text1.prototype);

    try child.replaceWith(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .string = "2" },
    });

    // Result: x, 2, 1 (child replaced with x and "2", "1" remains)
    try std.testing.expectEqual(@as(usize, 3), countChildren(&parent.prototype));
}

test "Element.replaceWith() with one sibling of child and child itself as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    // Note: child ends up back in parent tree after replaceWith, so parent will release it
    const x = try doc.createElement("elem-x");
    const text_node = try doc.createTextNode("text");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&text_node.prototype);

    try child.replaceWith(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .node = &child.prototype },
    });

    // Result: x, child, text (child moves into replacement position)
    // The algorithm detects child is no longer in parent after conversion, uses insertBefore
    try std.testing.expectEqual(@as(usize, 3), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child.?.next_sibling.?);
}

test "Element.replaceWith() with one element and text as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.replaceWith(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .string = "text" },
    });

    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);

    const text_content = try parent.prototype.last_child.?.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("text", text_content.?);
}

test "Element.replaceWith() on a parentless child with two elements as arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    defer child.prototype.release();

    const x = try doc.createElement("elem-x");
    const y = try doc.createElement("elem-y");

    _ = try parent.prototype.appendChild(&x.prototype);
    _ = try parent.prototype.appendChild(&y.prototype);

    // Child has no parent, so this should be a no-op
    try child.replaceWith(&[_]Element.NodeOrString{
        .{ .node = &x.prototype },
        .{ .node = &y.prototype },
    });

    // Parent should still have x and y in original positions
    try std.testing.expectEqual(@as(usize, 2), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
    try std.testing.expectEqual(&y.prototype, parent.prototype.last_child.?);
}

// Text.replaceWith() tests

test "Text.replaceWith() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createTextNode("old");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.replaceWith(&[_]Text.NodeOrString{.{ .string = "new" }});

    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    const text_content = try parent.prototype.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("new", text_content.?);
}

test "Text.replaceWith() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createTextNode("test");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.replaceWith(&[_]Text.NodeOrString{.{ .node = &x.prototype }});

    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
}

// Comment.replaceWith() tests

test "Comment.replaceWith() with only text as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createComment("old");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    try child.replaceWith(&[_]Comment.NodeOrString{.{ .string = "new" }});

    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    const text_content = try parent.prototype.textContent(allocator);
    defer if (text_content) |c| allocator.free(c);
    try std.testing.expectEqualStrings("new", text_content.?);
}

test "Comment.replaceWith() with only one element as an argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createComment("test");
    defer child.prototype.release();
    _ = try parent.prototype.appendChild(&child.prototype);

    const x = try doc.createElement("elem-x");

    try child.replaceWith(&[_]Comment.NodeOrString{.{ .node = &x.prototype }});

    try std.testing.expectEqual(@as(usize, 1), countChildren(&parent.prototype));
    try std.testing.expectEqual(&x.prototype, parent.prototype.first_child.?);
}

// Note: JavaScript tests for replaceWith(null) and replaceWith(undefined) are not applicable in Zig
// because Zig is statically typed and doesn't have null/undefined JavaScript semantics.
// The NodeOrString union handles nodes and strings explicitly at compile time.
