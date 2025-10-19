// WPT Test: DocumentFragment-constructor.html
// Source: https://github.com/web-platform-tests/wpt/blob/master/dom/nodes/DocumentFragment-constructor.html
//
// Tests DocumentFragment constructor behavior as specified in WHATWG DOM Standard § 4.7
// https://dom.spec.whatwg.org/#dom-documentfragment-documentfragment

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;

test "Sets the owner document to the current global object associated document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    // Owner document should be the document we created it from
    const owner = fragment.prototype.getOwnerDocument();
    try std.testing.expect(owner != null);
    try std.testing.expectEqual(doc, owner.?);
}

test "Create a valid document DocumentFragment" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    const text = try doc.createTextNode("");
    _ = try fragment.prototype.appendChild(&text.prototype);

    try std.testing.expectEqual(&text.prototype, fragment.prototype.first_child);
}
