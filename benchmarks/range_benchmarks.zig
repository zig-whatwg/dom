const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Range = dom.Range;
const DocumentFragment = dom.DocumentFragment;

// Range comparison constants (from WHATWG DOM spec)
const START_TO_START: u16 = 0;

// ============================================================================
// RANGE BENCHMARKS
// ============================================================================

pub fn benchCreateRange(allocator: std.mem.Allocator) !void {
    const range = try Range.init(allocator);
    defer range.deinit();
}

pub fn benchSetStart(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try Text.init(allocator, "Hello, World!");
    _ = try doc.node.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.setStart(text.character_data.node, 0);
}

pub fn benchSetEnd(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try Text.init(allocator, "Hello, World!");
    _ = try doc.node.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.setStart(text.character_data.node, 0);
    try range.setEnd(text.character_data.node, 5);
}

pub fn benchSelectNode(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(elem);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.selectNode(elem);
}

pub fn benchSelectNodeContents(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(elem);

    // Add some content
    const text = try Text.init(allocator, "Content");
    _ = try elem.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.selectNodeContents(elem);
}

pub fn benchCollapse(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try Text.init(allocator, "Hello, World!");
    _ = try doc.node.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.setStart(text.character_data.node, 0);
    try range.setEnd(text.character_data.node, 5);

    range.collapse(true); // Collapse to start
}

pub fn benchCloneRange(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try Text.init(allocator, "Hello, World!");
    _ = try doc.node.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.setStart(text.character_data.node, 0);
    try range.setEnd(text.character_data.node, 5);

    const cloned = try range.cloneRange();
    defer cloned.deinit();
}

pub fn benchExtractContents(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(elem);

    const text = try Text.init(allocator, "Hello, World!");
    _ = try elem.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.selectNodeContents(elem);

    const fragment = try range.extractContents();
    defer fragment.release();
}

pub fn benchCloneContents(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(elem);

    const text = try Text.init(allocator, "Hello, World!");
    _ = try elem.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.selectNodeContents(elem);

    const fragment = try range.cloneContents();
    defer fragment.release();
}

pub fn benchDeleteContents(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(elem);

    const text = try Text.init(allocator, "Hello, World!");
    _ = try elem.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.selectNodeContents(elem);
    try range.deleteContents();
}

pub fn benchInsertNode(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(elem);

    const text = try Text.init(allocator, "Hello, World!");
    _ = try elem.appendChild(text.character_data.node);

    const range = try Range.init(allocator);
    defer range.deinit();

    try range.setStart(text.character_data.node, 7);
    try range.setEnd(text.character_data.node, 7);

    const newText = try Text.init(allocator, "Beautiful ");
    try range.insertNode(newText.character_data.node);
}

pub fn benchCompareBoundaryPoints(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try Text.init(allocator, "Hello, World!");
    _ = try doc.node.appendChild(text.character_data.node);

    const range1 = try Range.init(allocator);
    defer range1.deinit();
    try range1.setStart(text.character_data.node, 0);
    try range1.setEnd(text.character_data.node, 5);

    const range2 = try Range.init(allocator);
    defer range2.deinit();
    try range2.setStart(text.character_data.node, 7);
    try range2.setEnd(text.character_data.node, 12);

    _ = try range1.compareBoundaryPoints(START_TO_START, range2);
}
