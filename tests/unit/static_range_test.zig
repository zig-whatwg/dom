const std = @import("std");
const testing = std.testing;
const dom = @import("dom");

const StaticRange = dom.StaticRange;
const StaticRangeInit = dom.StaticRangeInit;
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const DocumentType = dom.DocumentType;
const Attr = dom.Attr;
const Node = dom.Node;

// ============================================================================
// Phase 1: Constructor Tests
// ============================================================================

test "StaticRange: construct with valid Element boundaries (collapsed)" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("container");

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 0,
        .end_container = &elem.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem.prototype.release();

    try testing.expectEqual(&elem.prototype, range.startContainer());
    try testing.expectEqual(@as(u32, 0), range.startOffset());
    try testing.expectEqual(&elem.prototype, range.endContainer());
    try testing.expectEqual(@as(u32, 0), range.endOffset());
    try testing.expect(range.collapsed());
}

test "StaticRange: construct with different start and end containers" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("start");
    const elem2 = try doc.createElement("end");

    const init = StaticRangeInit{
        .start_container = &elem1.prototype,
        .start_offset = 5,
        .end_container = &elem2.prototype,
        .end_offset = 10,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem1.prototype.release();
    elem2.prototype.release();

    try testing.expectEqual(&elem1.prototype, range.startContainer());
    try testing.expectEqual(@as(u32, 5), range.startOffset());
    try testing.expectEqual(&elem2.prototype, range.endContainer());
    try testing.expectEqual(@as(u32, 10), range.endOffset());
    try testing.expect(!range.collapsed());
}

test "StaticRange: construct with Text node boundaries" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hello world");

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 0,
        .end_container = &text.prototype,
        .end_offset = 5,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    text.prototype.release();

    try testing.expectEqual(&text.prototype, range.startContainer());
    try testing.expectEqual(@as(u32, 0), range.startOffset());
    try testing.expectEqual(&text.prototype, range.endContainer());
    try testing.expectEqual(@as(u32, 5), range.endOffset());
}

// ============================================================================
// Phase 1: Constructor Validation Tests (DocumentType/Attr rejection)
// ============================================================================

test "StaticRange: constructor rejects DocumentType as start container" {
    const allocator = testing.allocator;

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const init = StaticRangeInit{
        .start_container = &doctype.prototype,
        .start_offset = 0,
        .end_container = &elem.prototype,
        .end_offset = 0,
    };

    try testing.expectError(error.InvalidNodeTypeError, StaticRange.init(allocator, init));
}

test "StaticRange: constructor rejects DocumentType as end container" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const doctype = try DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 0,
        .end_container = &doctype.prototype,
        .end_offset = 0,
    };

    try testing.expectError(error.InvalidNodeTypeError, StaticRange.init(allocator, init));
}

test "StaticRange: constructor rejects Attr as start container" {
    const allocator = testing.allocator;

    const attr = try Attr.create(allocator, "id");
    defer attr.node.release();

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const init = StaticRangeInit{
        .start_container = &attr.node,
        .start_offset = 0,
        .end_container = &elem.prototype,
        .end_offset = 0,
    };

    try testing.expectError(error.InvalidNodeTypeError, StaticRange.init(allocator, init));
}

test "StaticRange: constructor rejects Attr as end container" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const attr = try Attr.create(allocator, "id");
    defer attr.node.release();

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 0,
        .end_container = &attr.node,
        .end_offset = 0,
    };

    try testing.expectError(error.InvalidNodeTypeError, StaticRange.init(allocator, init));
}

test "StaticRange: constructor rejects both DocumentType boundaries" {
    const allocator = testing.allocator;

    const doctype1 = try DocumentType.create(allocator, "html", "", "");
    defer doctype1.prototype.release();

    const doctype2 = try DocumentType.create(allocator, "svg", "", "");
    defer doctype2.prototype.release();

    const init = StaticRangeInit{
        .start_container = &doctype1.prototype,
        .start_offset = 0,
        .end_container = &doctype2.prototype,
        .end_offset = 0,
    };

    try testing.expectError(error.InvalidNodeTypeError, StaticRange.init(allocator, init));
}

// ============================================================================
// Phase 1: Constructor Allows Out-of-Bounds Offsets
// ============================================================================

test "StaticRange: constructor allows out-of-bounds start offset" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    // elem has 0 children

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 999, // WAY out of bounds!
        .end_container = &elem.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem.prototype.release();

    // Construction succeeds
    try testing.expectEqual(@as(u32, 999), range.startOffset());
    try testing.expectEqual(@as(u32, 0), range.endOffset());
}

test "StaticRange: constructor allows out-of-bounds end offset" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("hi"); // length = 2

    const init = StaticRangeInit{
        .start_container = &text.prototype,
        .start_offset = 0,
        .end_container = &text.prototype,
        .end_offset = 100, // > 2
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    text.prototype.release();

    // Construction succeeds
    try testing.expectEqual(@as(u32, 100), range.endOffset());
}

test "StaticRange: constructor allows both offsets out of bounds" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 999,
        .end_container = &elem.prototype,
        .end_offset = 9999,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem.prototype.release();

    try testing.expectEqual(@as(u32, 999), range.startOffset());
    try testing.expectEqual(@as(u32, 9999), range.endOffset());
}

// ============================================================================
// Phase 1: Accessor Tests
// ============================================================================

test "StaticRange: startContainer returns correct node" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 0,
        .end_container = &elem.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem.prototype.release();

    try testing.expectEqual(&elem.prototype, range.startContainer());
}

test "StaticRange: startOffset returns correct value" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 42,
        .end_container = &elem.prototype,
        .end_offset = 100,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem.prototype.release();

    try testing.expectEqual(@as(u32, 42), range.startOffset());
}

test "StaticRange: endContainer returns correct node" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("start");
    const elem2 = try doc.createElement("end");

    const init = StaticRangeInit{
        .start_container = &elem1.prototype,
        .start_offset = 0,
        .end_container = &elem2.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem1.prototype.release();
    elem2.prototype.release();

    try testing.expectEqual(&elem2.prototype, range.endContainer());
}

test "StaticRange: endOffset returns correct value" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 10,
        .end_container = &elem.prototype,
        .end_offset = 99,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem.prototype.release();

    try testing.expectEqual(@as(u32, 99), range.endOffset());
}

test "StaticRange: collapsed returns true when boundaries are identical" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 5,
        .end_container = &elem.prototype,
        .end_offset = 5,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem.prototype.release();

    try testing.expect(range.collapsed());
}

test "StaticRange: collapsed returns false when offsets differ" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 5,
        .end_container = &elem.prototype,
        .end_offset = 10,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem.prototype.release();

    try testing.expect(!range.collapsed());
}

test "StaticRange: collapsed returns false when containers differ" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("start");
    const elem2 = try doc.createElement("end");

    const init = StaticRangeInit{
        .start_container = &elem1.prototype,
        .start_offset = 0,
        .end_container = &elem2.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    defer range.deinit(allocator);

    // Release caller's initial refs (StaticRange acquired its own refs)
    elem1.prototype.release();
    elem2.prototype.release();

    try testing.expect(!range.collapsed());
}

// ============================================================================
// Phase 1: Memory Leak Tests
// ============================================================================

test "StaticRange: no memory leaks on construction and destruction" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 0,
        .end_container = &elem.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);
    elem.prototype.release(); // Release caller's ref (range acquired its own)
    range.deinit(allocator);

    // testing.allocator will fail if there are leaks
}

test "StaticRange: no memory leaks with multiple ranges" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    defer elem.prototype.release();

    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        const init = StaticRangeInit{
            .start_container = &elem.prototype,
            .start_offset = i,
            .end_container = &elem.prototype,
            .end_offset = i + 1,
        };

        const range = try StaticRange.init(allocator, init);
        range.deinit(allocator);
    }
}

test "StaticRange: nodes are ref-counted correctly" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("test");
    defer elem.prototype.release();

    // Initial ref_count from doc ownership
    const initial_count = elem.prototype.getRefCount();

    const init = StaticRangeInit{
        .start_container = &elem.prototype,
        .start_offset = 0,
        .end_container = &elem.prototype,
        .end_offset = 0,
    };

    const range = try StaticRange.init(allocator, init);

    // Range should have acquired refs (+2: start + end, but same node so just +1)
    const after_init_count = elem.prototype.getRefCount();
    try testing.expectEqual(initial_count + 2, after_init_count);

    range.deinit(allocator);

    // After deinit, refs should be released
    const after_deinit_count = elem.prototype.getRefCount();
    try testing.expectEqual(initial_count, after_deinit_count);
}
