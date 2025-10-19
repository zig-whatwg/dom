const std = @import("std");
const testing = std.testing;
const dom = @import("dom");

const StaticRange = dom.StaticRange;
const StaticRangeInit = dom.StaticRangeInit;
const Document = dom.Document;

// ============================================================================
// Phase 2: isValid() Tests - Valid Ranges
// ============================================================================

test "StaticRange.isValid: true for collapsed range at valid offset" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello");

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 2, // In bounds (0-5)
        .end_container = &text.prototype,
        .end_offset = 2,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(range.isValid());
}

test "StaticRange.isValid: true for range within single text node" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello world"); // length = 11

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 0,
        .end_container = &text.prototype,
        .end_offset = 5, // In bounds
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(range.isValid());
}

test "StaticRange.isValid: true for range at exact text length" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello"); // length = 5

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 0,
        .end_container = &text.prototype,
        .end_offset = 5, // Exactly at length (valid!)
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(range.isValid());
}

test "StaticRange.isValid: true for range within element children" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("parent");
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try elem.prototype.appendChild(&child1.prototype);
    _ = try elem.prototype.appendChild(&child2.prototype);

    // elem has 2 children
    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 0,
        .end_container = &elem.prototype,
        .end_offset = 2, // In bounds (0-2)
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    elem.prototype.release();

    try testing.expect(range.isValid());
}

test "StaticRange.isValid: true for multi-node range in tree order" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try root.prototype.appendChild(&child1.prototype);
    _ = try root.prototype.appendChild(&child2.prototype);

    // Range from child1 to child2 (tree order: child1 before child2)
    const init = StaticRangeInit{
        .start_container = &child1.prototype,
        .start_offset = 0,
        .end_container = &child2.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    try testing.expect(range.isValid());
    root.prototype.release();
}

test "StaticRange.isValid: true for range spanning parent to child" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    // Range from parent to child (parent contains child in tree order)
    const init = StaticRangeInit{
        .start_container = &parent.prototype,
        .start_offset = 0,
        .end_container = &child.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    parent.prototype.release();

    try testing.expect(range.isValid());
}

test "StaticRange.isValid: true for empty element (0 children)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("empty");
    // elem has 0 children

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 0,
        .end_container = &elem.prototype,
        .end_offset = 0, // Valid: 0 ≤ 0
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    elem.prototype.release();

    try testing.expect(range.isValid());
}

// ============================================================================
// Phase 2: isValid() Tests - Invalid Ranges (Out of Bounds)
// ============================================================================

test "StaticRange.isValid: false for out-of-bounds start offset" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hi"); // length = 2

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 5, // > 2 (out of bounds!)
        .end_container = &text.prototype,
        .end_offset = 2,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(!range.isValid());
}

test "StaticRange.isValid: false for out-of-bounds end offset" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello"); // length = 5

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 0,
        .end_container = &text.prototype,
        .end_offset = 10, // > 5 (out of bounds!)
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(!range.isValid());
}

test "StaticRange.isValid: false for both offsets out of bounds" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("empty"); // 0 children

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 5, // > 0 (out of bounds!)
        .end_container = &elem.prototype,
        .end_offset = 10, // > 0 (out of bounds!)
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    elem.prototype.release();

    try testing.expect(!range.isValid());
}

test "StaticRange.isValid: false for start offset beyond element children" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("parent");
    const child = try doc.createElement("child");
    _ = try elem.prototype.appendChild(&child.prototype);
    // elem has 1 child

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 5, // > 1 (out of bounds!)
        .end_container = &elem.prototype,
        .end_offset = 1,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    elem.prototype.release();

    try testing.expect(!range.isValid());
}

// ============================================================================
// Phase 2: isValid() Tests - Invalid Ranges (Reversed Tree Order)
// ============================================================================

test "StaticRange.isValid: false for reversed offsets in same node" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello"); // length = 5

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 4, // Start AFTER end
        .end_container = &text.prototype,
        .end_offset = 2,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(!range.isValid());
}

test "StaticRange.isValid: false for reversed tree order (siblings)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try root.prototype.appendChild(&child1.prototype);
    _ = try root.prototype.appendChild(&child2.prototype);

    // Start at child2, end at child1 (reversed!)
    const init = StaticRangeInit{
        .start_container = &child2.prototype,
        .start_offset = 0,
        .end_container = &child1.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    root.prototype.release();

    try testing.expect(!range.isValid());
}

test "StaticRange.isValid: false for child to ancestor (reversed)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    // Start at child, end at parent (child is AFTER parent's start in tree order)
    const init = StaticRangeInit{
        .start_container = &child.prototype,
        .start_offset = 0,
        .end_container = &parent.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    parent.prototype.release();

    try testing.expect(!range.isValid());
}

// ============================================================================
// Phase 2: isValid() Tests - Invalid Ranges (Different Trees)
// ============================================================================

test "StaticRange.isValid: false for nodes in different documents" {
    const allocator = testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const elem1 = try doc1.createElement("elem1");
    const elem2 = try doc2.createElement("elem2");

    // elem1 and elem2 have different roots (doc1 vs doc2)
    const init = StaticRangeInit{
        .start_container = &elem1.prototype,
        .start_offset = 0,
        .end_container = &elem2.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    elem1.prototype.release();
    elem2.prototype.release();

    try testing.expect(!range.isValid());
}

test "StaticRange.isValid: false for detached nodes with different roots" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("detached1");
    const elem2 = try doc.createElement("detached2");

    // Both detached, different roots (each is its own root)
    const init = StaticRangeInit{
        .start_container = &elem1.prototype,
        .start_offset = 0,
        .end_container = &elem2.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    elem1.prototype.release();
    elem2.prototype.release();

    try testing.expect(!range.isValid());
}

// ============================================================================
// Phase 2: isValid() Tests - Edge Cases
// ============================================================================

test "StaticRange.isValid: true for empty text node" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode(""); // length = 0

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 0,
        .end_container = &text.prototype,
        .end_offset = 0, // Valid: 0 ≤ 0
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(range.isValid());
}

test "StaticRange.isValid: false for offset beyond empty text node" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode(""); // length = 0

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 0,
        .end_container = &text.prototype,
        .end_offset = 1, // > 0 (out of bounds!)
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(!range.isValid());
}

test "StaticRange.isValid: true for deeply nested valid range" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const level1 = try doc.createElement("level1");
    const level2 = try doc.createElement("level2");
    const level3 = try doc.createElement("level3");
    const text1 = try doc.createTextNode("start");
    const text2 = try doc.createTextNode("end");

    _ = try level1.prototype.appendChild(&level2.prototype);
    _ = try level2.prototype.appendChild(&level3.prototype);
    _ = try level3.prototype.appendChild(&text1.prototype);
    _ = try level3.prototype.appendChild(&text2.prototype);

    // Range from text1 to text2 (siblings, tree order preserved)
    const init = StaticRangeInit{
        .start_container = &text1.prototype,
        .start_offset = 0,
        .end_container = &text2.prototype,
        .end_offset = 3,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    try testing.expect(range.isValid());

    level1.prototype.release();
}

test "StaticRange.isValid: true for range at exact boundary" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("abc"); // length = 3

    // Start and end both at length (valid: offset ≤ length)
    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 3,
        .end_container = &text.prototype,
        .end_offset = 3,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(range.isValid());
}

test "StaticRange.isValid: false for start offset exactly one beyond length" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("abc"); // length = 3

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 4, // Exactly 1 beyond length (invalid!)
        .end_container = &text.prototype,
        .end_offset = 3,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);
    text.prototype.release();

    try testing.expect(!range.isValid());
}
