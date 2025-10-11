const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

// ============================================================================
// BATCH OPERATIONS BENCHMARKS
// ============================================================================

pub fn benchBatchInsert(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(parent);

    // Insert 100 elements
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const child = try Element.create(allocator, "div");
        _ = try parent.appendChild(child);
    }
}
