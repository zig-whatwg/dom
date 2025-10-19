const std = @import("std");
const testing = std.testing;
const dom = @import("dom");

// Import all commonly used types
const Element = dom.Element;
const Text = dom.Text;
const Document = dom.Document;
const ElementIterator = dom.ElementIterator;

test "ElementIterator - skips text nodes" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Add mixed content
    const p1 = try doc.createElement("p");
    _ = try root.prototype.appendChild(&p1.prototype);

    const text1 = try Text.create(allocator, "text");
    // Don't defer release - it's now owned by the tree
    _ = try root.prototype.appendChild(&text1.prototype);

    const p2 = try doc.createElement("p");
    _ = try root.prototype.appendChild(&p2.prototype);

    // Iterator should only yield p1 and p2
    var iter = ElementIterator.init(&root.prototype);

    const elem1 = iter.next();
    try testing.expect(elem1 != null);
    try testing.expect(elem1.? == p1);

    const elem2 = iter.next();
    try testing.expect(elem2 != null);
    try testing.expect(elem2.? == p2);

    const elem3 = iter.next();
    try testing.expect(elem3 == null);
}

test "ElementIterator - depth-first order" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create tree:
    //   root
    //   ├── a
    //   │   └── b
    //   └── c
    const a = try doc.createElement("a");
    _ = try root.prototype.appendChild(&a.prototype);

    const b = try doc.createElement("b");
    _ = try a.prototype.appendChild(&b.prototype);

    const c = try doc.createElement("c");
    _ = try root.prototype.appendChild(&c.prototype);

    // Depth-first order: a, b, c
    var iter = ElementIterator.init(&root.prototype);

    try testing.expect(iter.next().? == a);
    try testing.expect(iter.next().? == b);
    try testing.expect(iter.next().? == c);
    try testing.expect(iter.next() == null);
}

test "ElementIterator - empty root" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&root.prototype);

    var iter = ElementIterator.init(&root.prototype);
    try testing.expect(iter.next() == null);
}

test "ElementIterator - reset" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&root.prototype);

    const p = try doc.createElement("p");
    _ = try root.prototype.appendChild(&p.prototype);

    var iter = ElementIterator.init(&root.prototype);
    try testing.expect(iter.next().? == p);
    try testing.expect(iter.next() == null);

    iter.reset();
    try testing.expect(iter.next().? == p);
    try testing.expect(iter.next() == null);
}
