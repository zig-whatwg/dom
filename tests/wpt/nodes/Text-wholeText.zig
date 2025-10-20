// META: title=Text - wholeText
// META: link=https://dom.spec.whatwg.org/#dom-text-wholetext

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Text = dom.Text;

test "wholeText returns text of all Text nodes logically adjacent to the node, in document order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    const t1 = try doc.createTextNode("a");
    const t2 = try doc.createTextNode("b");
    const t3 = try doc.createTextNode("c");

    // Single text node - wholeText equals its own textContent
    {
        const whole = try t1.wholeText(allocator);
        defer allocator.free(whole);
        try std.testing.expectEqualStrings(t1.data, whole);
    }

    _ = try parent.prototype.appendChild(&t1.prototype);

    // Text node in parent - still just its own content
    {
        const whole = try t1.wholeText(allocator);
        defer allocator.free(whole);
        try std.testing.expectEqualStrings(t1.data, whole);
    }

    _ = try parent.prototype.appendChild(&t2.prototype);

    // Two adjacent text nodes - wholeText combines both
    {
        const whole1 = try t1.wholeText(allocator);
        defer allocator.free(whole1);
        try std.testing.expectEqualStrings("ab", whole1);

        const whole2 = try t2.wholeText(allocator);
        defer allocator.free(whole2);
        try std.testing.expectEqualStrings("ab", whole2);
    }

    _ = try parent.prototype.appendChild(&t3.prototype);

    // Three adjacent text nodes - wholeText combines all
    {
        const whole1 = try t1.wholeText(allocator);
        defer allocator.free(whole1);
        try std.testing.expectEqualStrings("abc", whole1);

        const whole2 = try t2.wholeText(allocator);
        defer allocator.free(whole2);
        try std.testing.expectEqualStrings("abc", whole2);

        const whole3 = try t3.wholeText(allocator);
        defer allocator.free(whole3);
        try std.testing.expectEqualStrings("abc", whole3);
    }

    // Insert element between t2 and t3 - breaks adjacency
    const anchor = try doc.createElement("anchor");
    const anchor_text = try doc.createTextNode("I'm an Anchor");
    _ = try anchor.prototype.appendChild(&anchor_text.prototype);
    _ = try parent.prototype.insertBefore(&anchor.prototype, &t3.prototype);

    const span = try doc.createElement("span");
    const span_text = try doc.createTextNode("I'm a Span");
    _ = try span.prototype.appendChild(&span_text.prototype);
    _ = try parent.prototype.appendChild(&span.prototype);

    // Now t1 and t2 are adjacent, but t3 is separated by anchor element
    {
        const whole1 = try t1.wholeText(allocator);
        defer allocator.free(whole1);
        try std.testing.expectEqualStrings("ab", whole1);

        const whole2 = try t2.wholeText(allocator);
        defer allocator.free(whole2);
        try std.testing.expectEqualStrings("ab", whole2);

        const whole3 = try t3.wholeText(allocator);
        defer allocator.free(whole3);
        try std.testing.expectEqualStrings("c", whole3);
    }
}
