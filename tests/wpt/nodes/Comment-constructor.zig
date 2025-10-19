// META: title=Comment constructor
// META: link=https://dom.spec.whatwg.org/#dom-comment

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Comment = dom.Comment;
const Node = dom.Node;

test "Comment constructor: no arguments" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("", comment.data);
    try std.testing.expect(comment.prototype.getOwnerDocument() == doc);
}

test "Comment constructor: undefined → empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // In Zig, undefined becomes empty string
    const comment = try doc.createComment("");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("", comment.data);
}

test "Comment constructor: null string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("null");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("null", comment.data);
}

test "Comment constructor: number becomes string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("42");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("42", comment.data);
}

test "Comment constructor: empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("", comment.data);
}

test "Comment constructor: single dash" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("-");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("-", comment.data);
}

test "Comment constructor: double dash" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("--");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("--", comment.data);
}

test "Comment constructor: comment close marker" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("-->");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("-->", comment.data);
}

test "Comment constructor: comment open marker" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("<!--");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("<!--", comment.data);
}

test "Comment constructor: null character" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("\x00");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("\x00", comment.data);
}

test "Comment constructor: null character with text" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("\x00test");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("\x00test", comment.data);
}

test "Comment constructor: HTML entity (not decoded)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Comment data is literal - no HTML entity decoding
    const comment = try doc.createComment("&amp;");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("&amp;", comment.data);
}

test "Comment constructor: nodeValue matches data" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test data");
    defer comment.prototype.release();

    const node_value = comment.prototype.nodeValue();

    try std.testing.expect(node_value != null);
    try std.testing.expectEqualStrings("test data", node_value.?);
    try std.testing.expectEqualStrings("test data", comment.data);
}

test "Comment constructor: correct owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test");
    defer comment.prototype.release();

    try std.testing.expect(comment.prototype.getOwnerDocument() == doc);
}
