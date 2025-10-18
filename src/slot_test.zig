//! Tests for Slottable mixin and slot assignment
//!
//! Tests the generic slot mechanism (not HTML-specific).
//! Slots are regular Elements with tag name "slot".

const std = @import("std");
const Element = @import("element.zig").Element;
const Text = @import("text.zig").Text;
const Document = @import("document.zig").Document;

test "Slottable - Element.assignedSlot initially null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.node.release();

    // Initially not assigned to any slot
    const slot = elem.assignedSlot();
    try std.testing.expect(slot == null);
}

test "Slottable - Text.assignedSlot initially null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.node.release();

    // Initially not assigned to any slot
    const slot = text.assignedSlot();
    try std.testing.expect(slot == null);
}

test "Slottable - Element manual slot assignment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create a slot element (just an Element with tag name "slot")
    const slot = try doc.createElement("slot");
    defer slot.node.release();

    const elem = try doc.createElement("element");
    defer elem.node.release();

    // Manually assign element to slot
    try elem.setAssignedSlot(slot);

    // Element should be assigned to slot
    const assigned = elem.assignedSlot();
    try std.testing.expect(assigned != null);
    try std.testing.expect(assigned.? == slot);
}

test "Slottable - Text manual slot assignment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const slot = try doc.createElement("slot");
    defer slot.node.release();

    const text = try doc.createTextNode("text");
    defer text.node.release();

    // Manually assign text to slot
    try text.setAssignedSlot(slot);

    // Text should be assigned to slot
    const assigned = text.assignedSlot();
    try std.testing.expect(assigned != null);
    try std.testing.expect(assigned.? == slot);
}

test "Slottable - clear assignment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const slot = try doc.createElement("slot");
    defer slot.node.release();

    const elem = try doc.createElement("element");
    defer elem.node.release();

    // Assign to slot
    try elem.setAssignedSlot(slot);
    try std.testing.expect(elem.assignedSlot() != null);

    // Clear assignment
    try elem.setAssignedSlot(null);
    try std.testing.expect(elem.assignedSlot() == null);
}

test "Slottable - slot with name attribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Named slot
    const slot = try doc.createElement("slot");
    defer slot.node.release();
    try slot.setAttribute("name", "header");

    try std.testing.expectEqualStrings("slot", slot.tag_name);
    const name = slot.getAttribute("name");
    try std.testing.expect(name != null);
    try std.testing.expectEqualStrings("header", name.?);
}

test "Slottable - default slot (no name)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Default slot (no name attribute)
    const slot = try doc.createElement("slot");
    defer slot.node.release();

    try std.testing.expectEqualStrings("slot", slot.tag_name);
    const name = slot.getAttribute("name");
    try std.testing.expect(name == null);
}

test "Slottable - element with slot attribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.node.release();

    // Set slot attribute (indicates which slot this element should go to)
    try elem.setAttribute("slot", "header");

    const slot_attr = elem.getAttribute("slot");
    try std.testing.expect(slot_attr != null);
    try std.testing.expectEqualStrings("header", slot_attr.?);
}

test "Slottable - slot in shadow tree" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.node.release();

    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add slot to shadow tree
    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "content");
    _ = try shadow.node.appendChild(&slot.node);

    try std.testing.expect(slot.node.parent_node == &shadow.node);
    try std.testing.expectEqualStrings("content", slot.getAttribute("name").?);
}

test "Slottable - light DOM content with slot attribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.node.release();

    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Slot in shadow tree
    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "header");
    _ = try shadow.node.appendChild(&slot.node);

    // Content in light DOM
    const content = try doc.createElement("content");
    try content.setAttribute("slot", "header");
    _ = try host.node.appendChild(&content.node);

    // Verify structure
    try std.testing.expect(slot.node.parent_node == &shadow.node);
    try std.testing.expect(content.node.parent_node == &host.node);
    try std.testing.expectEqualStrings("header", slot.getAttribute("name").?);
    try std.testing.expectEqualStrings("header", content.getAttribute("slot").?);
}

test "Slottable - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple assignment
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const slot = try doc.createElement("slot");
        defer slot.node.release();

        const elem = try doc.createElement("element");
        defer elem.node.release();

        try elem.setAssignedSlot(slot);
    }

    // Test 2: With Text
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const slot = try doc.createElement("slot");
        defer slot.node.release();

        const text = try doc.createTextNode("text");
        defer text.node.release();

        try text.setAssignedSlot(slot);
    }

    // Test 3: In shadow tree
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const host = try doc.createElement("host");
        defer host.node.release();

        const shadow = try host.attachShadow(.{ .mode = .open, .delegates_focus = false });

        const slot = try doc.createElement("slot");
        _ = try shadow.node.appendChild(&slot.node);

        const content = try doc.createElement("content");
        _ = try host.node.appendChild(&content.node);

        try content.setAssignedSlot(slot);
    }
}
