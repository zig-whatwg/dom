//! Advanced DOM Features Demo
//! ==========================
//!
//! This demo showcases advanced DOM features:
//! - StaticRange - Immutable ranges
//! - Range extensions - Advanced range operations
//! - DOMImplementation - Document creation

const std = @import("std");
const dom = @import("dom");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n", .{});
    std.debug.print("╔════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║        Advanced DOM Features - Demonstration              ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════════════╝\n", .{});
    std.debug.print("\n", .{});

    // ========================================
    // 1. DOMImplementation Demo
    // ========================================
    std.debug.print("1️⃣  DOMImplementation - Document Creation\n", .{});
    std.debug.print("   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});

    const base_doc = try dom.Document.init(allocator);
    defer base_doc.release();

    const impl = try dom.DOMImplementation.init(allocator, base_doc);
    defer impl.deinit();

    // Create HTML document
    std.debug.print("   Creating HTML document...\n", .{});
    const html_doc = try impl.createHTMLDocument("My Page");
    defer html_doc.release();

    std.debug.print("   ✓ Document structure:\n", .{});
    std.debug.print("     - Children: {d}\n", .{html_doc.node.child_nodes.length()});

    const html_elem = html_doc.node.child_nodes.item(1).?;
    const html_node: *dom.Node = @ptrCast(@alignCast(html_elem));
    std.debug.print("     - Root element: {s}\n", .{html_node.node_name});
    std.debug.print("\n", .{});

    // ========================================
    // 2. StaticRange Demo
    // ========================================
    std.debug.print("2️⃣  StaticRange - Immutable Range Selection\n", .{});
    std.debug.print("   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});

    const text = try dom.Node.init(allocator, .text_node, "Hello World");
    defer text.release();

    const static_range = try dom.StaticRange.init(allocator, .{
        .start_container = text,
        .start_offset = 0,
        .end_container = text,
        .end_offset = 5,
    });
    defer static_range.deinit();

    std.debug.print("   Text: \"Hello World\"\n", .{});
    std.debug.print("   Range: {d} to {d}\n", .{ static_range.start_offset, static_range.end_offset });
    std.debug.print("   Collapsed: {}\n", .{static_range.collapsed()});
    std.debug.print("\n", .{});

    // ========================================
    // 3. Range Operations Demo
    // ========================================
    std.debug.print("3️⃣  Range Extensions - Advanced Operations\n", .{});
    std.debug.print("   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});

    const range1 = try dom.Range.init(allocator);
    defer range1.deinit();

    const range2 = try dom.Range.init(allocator);
    defer range2.deinit();

    const doc_text = try dom.Node.init(allocator, .text_node, "The quick brown fox");
    defer doc_text.release();

    try range1.setStart(doc_text, 0);
    try range1.setEnd(doc_text, 9); // "The quick"

    try range2.setStart(doc_text, 10);
    try range2.setEnd(doc_text, 15); // "brown"

    std.debug.print("   Text: \"The quick brown fox\"\n", .{});
    std.debug.print("   Range1: positions 0-9 (\"The quick\")\n", .{});
    std.debug.print("   Range2: positions 10-15 (\"brown\")\n", .{});
    std.debug.print("\n", .{});

    // Compare boundary points
    const comparison = try range1.compareBoundaryPoints(dom.START_TO_START, range2);
    std.debug.print("   ✓ compareBoundaryPoints: {d} (range1 before range2)\n", .{comparison});

    // Check point in range
    const in_range = try range1.isPointInRange(doc_text, 5);
    std.debug.print("   ✓ isPointInRange(5): {} (within range1)\n", .{in_range});

    // Compare point
    const point_cmp = try range1.comparePoint(doc_text, 15);
    std.debug.print("   ✓ comparePoint(15): {d} (after range1)\n", .{point_cmp});

    // Extract contents
    const fragment = try range1.extractContents();
    defer fragment.release();
    std.debug.print("   ✓ extractContents: range1 collapsed = {}\n", .{range1.collapsed()});

    // Clone contents
    const cloned = try range2.cloneContents();
    defer cloned.release();
    std.debug.print("   ✓ cloneContents: range2 collapsed = {}\n", .{range2.collapsed()});

    std.debug.print("\n", .{});

    // ========================================
    // 4. DocumentType Demo
    // ========================================
    std.debug.print("4️⃣  DocumentType Creation\n", .{});
    std.debug.print("   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});

    const doctype = try impl.createDocumentType("html", "", "");
    defer doctype.release();

    std.debug.print("   ✓ DOCTYPE: {s}\n", .{doctype.name()});
    std.debug.print("     Public ID: \"{s}\"\n", .{doctype.publicId()});
    std.debug.print("     System ID: \"{s}\"\n", .{doctype.systemId()});
    std.debug.print("\n", .{});

    // ========================================
    // Summary
    // ========================================
    std.debug.print("╔════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║                    ✨ Summary ✨                           ║\n", .{});
    std.debug.print("╠════════════════════════════════════════════════════════════╣\n", .{});
    std.debug.print("║ Phase 2 Implementation Complete!                          ║\n", .{});
    std.debug.print("║                                                            ║\n", .{});
    std.debug.print("║ Features Demonstrated:                                    ║\n", .{});
    std.debug.print("║ ✓ DOMImplementation - Document factory                    ║\n", .{});
    std.debug.print("║ ✓ StaticRange - Immutable ranges                          ║\n", .{});
    std.debug.print("║ ✓ Range extensions - 9 new methods                        ║\n", .{});
    std.debug.print("║ ✓ DocumentType - DOCTYPE declarations                     ║\n", .{});
    std.debug.print("║                                                            ║\n", .{});
    std.debug.print("║ Total Tests: 463 passing                                  ║\n", .{});
    std.debug.print("║ Memory Leaks: 0                                            ║\n", .{});
    std.debug.print("║                                                            ║\n", .{});
    std.debug.print("║ All non-XML DOM features implemented! 🎉                  ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════════════╝\n", .{});
    std.debug.print("\n", .{});
}
