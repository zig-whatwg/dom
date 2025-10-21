// META: title=Comment.nodeName
// META: link=https://dom.spec.whatwg.org/#dom-node-nodename

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;

test "Comment.nodeName returns #comment" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    defer comment.prototype.release();

    try std.testing.expectEqualStrings("#comment", comment.prototype.nodeName());
}

test "Comment.nodeName is constant" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment1 = try doc.createComment("first");
    defer comment1.prototype.release();

    const comment2 = try doc.createComment("second");
    defer comment2.prototype.release();

    try std.testing.expectEqualStrings("#comment", comment1.prototype.nodeName());
    try std.testing.expectEqualStrings("#comment", comment2.prototype.nodeName());
}
