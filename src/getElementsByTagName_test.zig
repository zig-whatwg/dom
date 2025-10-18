//! Phase 2 Verification Tests: getElementsByTagName with mutation-time map updates

const std = @import("std");
const Document = @import("document.zig").Document;

test "getElementsByTagName - elements added to map on appendChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create root element (Document can only have one element child)
    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    // Initially, tag_map should have no "div" entries
    const initial = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 0), initial.length());

    // Create element but DON'T append it yet
    const div1 = try doc.createElement("div");

    // Should still be 0 because element is not connected
    const before_append = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 0), before_append.length());

    // Append to root element
    _ = try root.node.appendChild(&div1.node);

    // NOW it should be in the tag_map
    const after_append = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 1), after_append.length());
}

test "getElementsByTagName - elements removed from map on removeChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const div1 = try doc.createElement("div");
    _ = try root.node.appendChild(&div1.node);

    // Should be 1 element
    const before_remove = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 1), before_remove.length());

    // Remove from root
    _ = try root.node.removeChild(&div1.node);
    div1.node.release();

    // Should be 0 elements
    const after_remove = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 0), after_remove.length());
}

test "getElementsByTagName - multiple elements with same tag" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const div1 = try doc.createElement("div");
    const div2 = try doc.createElement("div");
    const span1 = try doc.createElement("span");

    _ = try root.node.appendChild(&div1.node);
    _ = try root.node.appendChild(&div2.node);
    _ = try root.node.appendChild(&span1.node);

    const divs = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 2), divs.length());

    const spans = doc.getElementsByTagName("span");
    try std.testing.expectEqual(@as(usize, 1), spans.length());
}

test "getElementsByTagName - nested elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const div1 = try doc.createElement("div");
    _ = try root.node.appendChild(&div1.node);

    const div2 = try doc.createElement("div");
    _ = try div1.node.appendChild(&div2.node);

    // All nested divs should be in tag_map
    const divs = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 2), divs.length());

    // Remove root - should remove all descendants from tag_map
    _ = try doc.node.removeChild(&root.node);
    root.node.release();

    const after_remove = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 0), after_remove.length());
}

test "getElementsByTagName - live collection behavior" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    // Get collection before adding elements
    const divs = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 0), divs.length());

    // Add first div
    const div1 = try doc.createElement("div");
    _ = try root.node.appendChild(&div1.node);

    // Collection should update automatically (live)
    try std.testing.expectEqual(@as(usize, 1), divs.length());

    // Add second div
    const div2 = try doc.createElement("div");
    _ = try root.node.appendChild(&div2.node);

    // Collection should reflect the addition
    try std.testing.expectEqual(@as(usize, 2), divs.length());

    // Remove first div
    _ = try root.node.removeChild(&div1.node);
    div1.node.release();

    // Collection should reflect the removal
    try std.testing.expectEqual(@as(usize, 1), divs.length());
}
