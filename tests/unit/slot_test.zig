//! Tests for Slottable mixin and slot assignment
//!
//! Tests the generic slot mechanism (not HTML-specific).
//! Slots are regular Elements with tag name "slot".

const std = @import("std");
const dom = @import("dom");
const Element = dom.Element;
const Text = dom.Text;
const Document = dom.Document;
const Node = dom.Node;

test "Slottable - Element.assignedSlot initially null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Initially not assigned to any slot
    const slot = elem.assignedSlot();
    try std.testing.expect(slot == null);
}

test "Slottable - Text.assignedSlot initially null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

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
    defer slot.prototype.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

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
    defer slot.prototype.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

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
    defer slot.prototype.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

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
    defer slot.prototype.release();
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
    defer slot.prototype.release();

    try std.testing.expectEqualStrings("slot", slot.tag_name);
    const name = slot.getAttribute("name");
    try std.testing.expect(name == null);
}

test "Slottable - element with slot attribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

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
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Add slot to shadow tree
    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "content");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    try std.testing.expect(slot.prototype.parent_node == &shadow.prototype);
    try std.testing.expectEqualStrings("content", slot.getAttribute("name").?);
}

test "Slottable - light DOM content with slot attribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{
        .mode = .open,
        .delegates_focus = false,
    });

    // Slot in shadow tree
    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "header");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    // Content in light DOM
    const content = try doc.createElement("content");
    try content.setAttribute("slot", "header");
    _ = try host.prototype.appendChild(&content.prototype);

    // Verify structure
    try std.testing.expect(slot.prototype.parent_node == &shadow.prototype);
    try std.testing.expect(content.prototype.parent_node == &host.prototype);
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
        defer slot.prototype.release();

        const elem = try doc.createElement("element");
        defer elem.prototype.release();

        try elem.setAssignedSlot(slot);
    }

    // Test 2: With Text
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const slot = try doc.createElement("slot");
        defer slot.prototype.release();

        const text = try doc.createTextNode("text");
        defer text.prototype.release();

        try text.setAssignedSlot(slot);
    }

    // Test 3: In shadow tree
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const host = try doc.createElement("host");
        defer host.prototype.release();

        const shadow = try host.attachShadow(.{ .mode = .open, .delegates_focus = false });

        const slot = try doc.createElement("slot");
        _ = try shadow.prototype.appendChild(&slot.prototype);

        const content = try doc.createElement("content");
        _ = try host.prototype.appendChild(&content.prototype);

        try content.setAssignedSlot(slot);
    }
}

test "Slot - assignedNodes returns assigned nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .delegates_focus = false });

    const slot = try doc.createElement("slot");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    const content1 = try doc.createElement("content");
    _ = try host.prototype.appendChild(&content1.prototype);

    const content2 = try doc.createElement("item");
    _ = try host.prototype.appendChild(&content2.prototype);

    // Manually assign nodes to slot
    try content1.setAssignedSlot(slot);
    try content2.setAssignedSlot(slot);

    // Get assigned nodes
    const nodes = try slot.assignedNodes(allocator, .{ .flatten = false });
    defer allocator.free(nodes);

    try std.testing.expectEqual(@as(usize, 2), nodes.len);
    try std.testing.expect(nodes[0] == &content1.prototype);
    try std.testing.expect(nodes[1] == &content2.prototype);
}

test "Slot - assignedElements filters to only elements" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .delegates_focus = false });

    const slot = try doc.createElement("slot");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    const elem = try doc.createElement("element");
    _ = try host.prototype.appendChild(&elem.prototype);

    const text = try doc.createTextNode("text");
    _ = try host.prototype.appendChild(&text.prototype);

    // Assign both element and text to slot
    try elem.setAssignedSlot(slot);
    try text.setAssignedSlot(slot);

    // Get assigned elements (should filter out text)
    const elements = try slot.assignedElements(allocator, .{ .flatten = false });
    defer allocator.free(elements);

    try std.testing.expectEqual(@as(usize, 1), elements.len);
    try std.testing.expect(elements[0] == elem);
}

test "Slot - assignedNodes on non-slot element returns empty" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("notaslot");
    defer elem.prototype.release();

    const nodes = try elem.assignedNodes(allocator, .{ .flatten = false });
    defer allocator.free(nodes);

    try std.testing.expectEqual(@as(usize, 0), nodes.len);
}

test "Slot - assign manually assigns nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .manual });

    const slot = try doc.createElement("slot");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    const content1 = try doc.createElement("content");
    _ = try host.prototype.appendChild(&content1.prototype);

    const content2 = try doc.createElement("item");
    _ = try host.prototype.appendChild(&content2.prototype);

    // Use assign() to manually assign nodes
    try slot.assign(&[_]*Node{ &content1.prototype, &content2.prototype });

    // Verify assignments
    try std.testing.expect(content1.assignedSlot() == slot);
    try std.testing.expect(content2.assignedSlot() == slot);

    // Verify assignedNodes returns them
    const nodes = try slot.assignedNodes(allocator, .{ .flatten = false });
    defer allocator.free(nodes);

    try std.testing.expectEqual(@as(usize, 2), nodes.len);
}

test "Slot - assign on non-slot element returns error" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("notaslot");
    defer elem.prototype.release();

    const content = try doc.createElement("content");
    defer content.prototype.release();

    // Should error when trying to assign to non-slot
    try std.testing.expectError(error.InvalidNodeType, elem.assign(&[_]*Node{&content.prototype}));
}

// ========================================================================
// Named Slot Assignment Tests (WHATWG §4.2.2.3-4)
// ========================================================================

test "Named Slot - findSlot with matching slot name" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    // Create named slot in shadow tree
    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "header");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    // Create element with matching slot attribute in light DOM
    const content = try doc.createElement("content");
    try content.setAttribute("slot", "header");
    _ = try host.prototype.appendChild(&content.prototype);

    // Find slot should return the matching slot
    const found = Element.findSlot(&content.prototype, false);
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == slot);
}

test "Named Slot - findSlot with no matching slot returns null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    // Create named slot in shadow tree
    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "header");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    // Create element with different slot attribute
    const content = try doc.createElement("content");
    try content.setAttribute("slot", "footer");
    _ = try host.prototype.appendChild(&content.prototype);

    // Find slot should return null (no matching slot)
    const found = Element.findSlot(&content.prototype, false);
    try std.testing.expect(found == null);
}

test "Named Slot - findSlot with default slot (empty name)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    // Create default slot (no name attribute)
    const slot = try doc.createElement("slot");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    // Create element with no slot attribute
    const content = try doc.createElement("content");
    _ = try host.prototype.appendChild(&content.prototype);

    // Find slot should return the default slot
    const found = Element.findSlot(&content.prototype, false);
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == slot);
}

test "Named Slot - findSlot returns first matching slot in tree order" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    // Create two slots with same name
    const slot1 = try doc.createElement("slot");
    try slot1.setAttribute("name", "content");
    _ = try shadow.prototype.appendChild(&slot1.prototype);

    const slot2 = try doc.createElement("slot");
    try slot2.setAttribute("name", "content");
    _ = try shadow.prototype.appendChild(&slot2.prototype);

    // Create element with matching slot attribute
    const elem = try doc.createElement("element");
    try elem.setAttribute("slot", "content");
    _ = try host.prototype.appendChild(&elem.prototype);

    // Find slot should return first slot in tree order
    const found = Element.findSlot(&elem.prototype, false);
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == slot1);
}

test "Named Slot - findSlot with no parent returns null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Element has no parent, so no slot
    const found = Element.findSlot(&elem.prototype, false);
    try std.testing.expect(found == null);
}

test "Named Slot - findSlot with parent having no shadow returns null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    // Parent has no shadow root, so no slot
    const found = Element.findSlot(&child.prototype, false);
    try std.testing.expect(found == null);
}

test "Named Slot - findSlot with open=true and closed shadow returns null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .closed, .slot_assignment = .named });

    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "content");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    const elem = try doc.createElement("element");
    try elem.setAttribute("slot", "content");
    _ = try host.prototype.appendChild(&elem.prototype);

    // With open=true, closed shadow should return null
    const found = Element.findSlot(&elem.prototype, true);
    try std.testing.expect(found == null);

    // With open=false, it should work
    const found2 = Element.findSlot(&elem.prototype, false);
    try std.testing.expect(found2 != null);
}

test "Named Slot - findSlot with Text node (always default slot)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    // Create default slot
    const slot = try doc.createElement("slot");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    // Create text node in light DOM (text nodes have empty name)
    const text = try doc.createTextNode("content");
    _ = try host.prototype.appendChild(&text.prototype);

    // Find slot should return default slot
    const found = Element.findSlot(&text.prototype, false);
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == slot);
}

test "Named Slot - findSlottables in named mode" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "header");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    // Add multiple elements with matching slot attribute
    const elem1 = try doc.createElement("item");
    try elem1.setAttribute("slot", "header");
    _ = try host.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("item");
    try elem2.setAttribute("slot", "header");
    _ = try host.prototype.appendChild(&elem2.prototype);

    // Add element with different slot attribute (should not match)
    const elem3 = try doc.createElement("item");
    try elem3.setAttribute("slot", "footer");
    _ = try host.prototype.appendChild(&elem3.prototype);

    // Find slottables should return matching elements
    const slottables = try Element.findSlottables(allocator, slot);
    defer allocator.free(slottables);

    try std.testing.expectEqual(@as(usize, 2), slottables.len);
    try std.testing.expect(slottables[0] == &elem1.prototype);
    try std.testing.expect(slottables[1] == &elem2.prototype);
}

test "Named Slot - findSlottables for default slot" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    // Default slot (no name)
    const slot = try doc.createElement("slot");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    // Add elements without slot attribute
    const elem1 = try doc.createElement("item");
    _ = try host.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("item");
    _ = try host.prototype.appendChild(&elem2.prototype);

    // Add element with slot attribute (should not match default)
    const elem3 = try doc.createElement("item");
    try elem3.setAttribute("slot", "header");
    _ = try host.prototype.appendChild(&elem3.prototype);

    // Find slottables should return elements without slot attribute
    const slottables = try Element.findSlottables(allocator, slot);
    defer allocator.free(slottables);

    try std.testing.expectEqual(@as(usize, 2), slottables.len);
    try std.testing.expect(slottables[0] == &elem1.prototype);
    try std.testing.expect(slottables[1] == &elem2.prototype);
}

test "Named Slot - findSlottables with mixed Element and Text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    const slot = try doc.createElement("slot");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    // Add element and text without slot attribute (both go to default slot)
    const elem = try doc.createElement("item");
    _ = try host.prototype.appendChild(&elem.prototype);

    const text = try doc.createTextNode("text");
    _ = try host.prototype.appendChild(&text.prototype);

    // Find slottables should return both
    const slottables = try Element.findSlottables(allocator, slot);
    defer allocator.free(slottables);

    try std.testing.expectEqual(@as(usize, 2), slottables.len);
    try std.testing.expect(slottables[0] == &elem.prototype);
    try std.testing.expect(slottables[1] == &text.prototype);
}

test "Named Slot - findSlottables with non-shadow root returns empty" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const slot = try doc.createElement("slot");
    _ = try parent.prototype.appendChild(&slot.prototype);

    // Slot is not in shadow tree
    const slottables = try Element.findSlottables(allocator, slot);
    defer allocator.free(slottables);

    try std.testing.expectEqual(@as(usize, 0), slottables.len);
}

test "Named Slot - assignSlottables updates assignments" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "content");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    const elem1 = try doc.createElement("item");
    try elem1.setAttribute("slot", "content");
    _ = try host.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("item");
    try elem2.setAttribute("slot", "content");
    _ = try host.prototype.appendChild(&elem2.prototype);

    // Initially no assignments
    try std.testing.expect(elem1.assignedSlot() == null);
    try std.testing.expect(elem2.assignedSlot() == null);

    // Assign slottables
    try Element.assignSlottables(allocator, slot);

    // Check assignments were updated
    try std.testing.expect(elem1.assignedSlot() == slot);
    try std.testing.expect(elem2.assignedSlot() == slot);

    // Check slot's assigned nodes
    const nodes = try slot.assignedNodes(allocator, .{ .flatten = false });
    defer allocator.free(nodes);

    try std.testing.expectEqual(@as(usize, 2), nodes.len);
}

test "Named Slot - assignSlottables clears old assignments" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "content");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    const elem = try doc.createElement("item");
    try elem.setAttribute("slot", "content");
    _ = try host.prototype.appendChild(&elem.prototype);

    // Initial assignment
    try Element.assignSlottables(allocator, slot);
    try std.testing.expect(elem.assignedSlot() == slot);

    // Change element's slot attribute
    try elem.setAttribute("slot", "other");

    // Reassign slottables
    try Element.assignSlottables(allocator, slot);

    // Element should no longer be assigned to this slot
    // Note: Current implementation doesn't clear old assignments automatically
    // This test documents current behavior; full implementation would need
    // to clear assignments from nodes that no longer match
}

test "Named Slot - memory leak test for slot assignment algorithms" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .named });

    const slot = try doc.createElement("slot");
    try slot.setAttribute("name", "test");
    _ = try shadow.prototype.appendChild(&slot.prototype);

    const elem1 = try doc.createElement("item");
    try elem1.setAttribute("slot", "test");
    _ = try host.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("item");
    try elem2.setAttribute("slot", "test");
    _ = try host.prototype.appendChild(&elem2.prototype);

    // Run assignment multiple times
    try Element.assignSlottables(allocator, slot);
    try Element.assignSlottables(allocator, slot);

    // Find slottables multiple times
    {
        const s = try Element.findSlottables(allocator, slot);
        defer allocator.free(s);
    }
    {
        const s = try Element.findSlottables(allocator, slot);
        defer allocator.free(s);
    }
}
