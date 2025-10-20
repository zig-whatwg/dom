// META: title=Element.getElementsByTagName
// META: link=https://dom.spec.whatwg.org/#dom-element-getelementsbytagname

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const HTMLCollection = dom.HTMLCollection;

test "Interfaces" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("container");
    defer element.prototype.release();

    const list = element.getElementsByTagName("item");

    try std.testing.expect(@TypeOf(list) == HTMLCollection);
}

test "Matching the context object" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("container");
    defer element.prototype.release();

    // getElementsByTagName should not match the context object itself
    const list = element.getElementsByTagName("container");

    try std.testing.expectEqual(@as(usize, 0), list.length());
}

test "Basic tree structure" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("container");
    defer element.prototype.release();

    const text = try doc.createTextNode("text");
    _ = try element.prototype.appendChild(&text.prototype);

    const p = try doc.createElement("p");
    _ = try element.prototype.appendChild(&p.prototype);

    const a = try doc.createElement("a");
    _ = try p.prototype.appendChild(&a.prototype);
    const link_text = try doc.createTextNode("link");
    _ = try a.prototype.appendChild(&link_text.prototype);

    const b = try doc.createElement("b");
    _ = try p.prototype.appendChild(&b.prototype);
    const bold_text = try doc.createTextNode("bold");
    _ = try b.prototype.appendChild(&bold_text.prototype);

    const comment = try doc.createComment("comment");
    _ = try element.prototype.appendChild(&comment.prototype);

    // Test getting "p" tags
    const p_list = element.getElementsByTagName("p");
    try std.testing.expectEqual(@as(usize, 1), p_list.length());
    try std.testing.expect(p_list.item(0) == p);

    // Test getting "a" tags
    const a_list = element.getElementsByTagName("a");
    try std.testing.expectEqual(@as(usize, 1), a_list.length());

    // Test getting "b" tags
    const b_list = element.getElementsByTagName("b");
    try std.testing.expectEqual(@as(usize, 1), b_list.length());
}

test "Live collection updates" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("container");
    defer element.prototype.release();

    const list = element.getElementsByTagName("item");

    try std.testing.expectEqual(@as(usize, 0), list.length());

    const item1 = try doc.createElement("item");
    _ = try element.prototype.appendChild(&item1.prototype);

    try std.testing.expectEqual(@as(usize, 1), list.length());

    const item2 = try doc.createElement("item");
    _ = try element.prototype.appendChild(&item2.prototype);

    try std.testing.expectEqual(@as(usize, 2), list.length());

    const removed = try element.prototype.removeChild(&item1.prototype);
    removed.release();

    try std.testing.expectEqual(@as(usize, 1), list.length());
}
