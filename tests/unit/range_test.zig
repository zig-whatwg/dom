const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Range = dom.Range;
const Element = dom.Element;
const Text = dom.Text;

// Phase 1: Basic Structure Tests (10 tests)

test "Range: create via Document.createRange" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const range = try doc.createRange();
    defer range.deinit();

    // Range should exist
    try std.testing.expect(range.start_container == &doc.prototype);
    try std.testing.expectEqual(@as(u32, 0), range.start_offset);
    try std.testing.expect(range.end_container == &doc.prototype);
    try std.testing.expectEqual(@as(u32, 0), range.end_offset);
}

test "Range: collapsed property - initially true" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const range = try doc.createRange();
    defer range.deinit();

    // Range starts collapsed at document
    try std.testing.expect(range.collapsed());
}

test "Range: collapsed property - false after setEnd" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&elem.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&elem.prototype, 0);
    try range.setEnd(&elem.prototype, 0);
    try std.testing.expect(range.collapsed());

    // Add child
    const child = try doc.createElement("span");
    _ = try elem.prototype.appendChild(&child.prototype);

    // Set end after child
    try range.setEnd(&elem.prototype, 1);
    try std.testing.expect(!range.collapsed());
}

test "Range: boundary getters" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&elem.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&elem.prototype, 0);
    try range.setEnd(&elem.prototype, 0);

    try std.testing.expect(range.start_container == &elem.prototype);
    try std.testing.expectEqual(@as(u32, 0), range.start_offset);
    try std.testing.expect(range.end_container == &elem.prototype);
    try std.testing.expectEqual(@as(u32, 0), range.end_offset);
}

test "Range: setStart - valid element container" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&elem.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    _ = try elem.prototype.appendChild(&child1.prototype);
    _ = try elem.prototype.appendChild(&child2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Set start at position 1 (between children)
    try range.setStart(&elem.prototype, 1);

    try std.testing.expect(range.start_container == &elem.prototype);
    try std.testing.expectEqual(@as(u32, 1), range.start_offset);
}

test "Range: setStart - valid text container" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();
    // Don't need to append - just use for range boundaries

    const range = try doc.createRange();
    defer range.deinit();

    // Set start at position 2 ("He|llo")
    try range.setStart(&text.prototype, 2);

    try std.testing.expect(range.start_container == &text.prototype);
    try std.testing.expectEqual(@as(u32, 2), range.start_offset);
}

test "Range: setStart - auto-collapse if end before start" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();
    // Don't need to append - just use for range boundaries

    const range = try doc.createRange();
    defer range.deinit();

    // Set end first
    try range.setEnd(&text.prototype, 2);
    try std.testing.expectEqual(@as(u32, 2), range.end_offset);

    // Set start after end - should auto-collapse to start
    try range.setStart(&text.prototype, 4);
    try std.testing.expectEqual(@as(u32, 4), range.start_offset);
    try std.testing.expectEqual(@as(u32, 4), range.end_offset); // Collapsed to start
    try std.testing.expect(range.collapsed());
}

test "Range: setStart - InvalidNodeTypeError for DocumentType" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try dom.DocumentType.create(allocator, "html", "", "");
    defer doctype.prototype.release();
    // Don't need to append - just test that DocumentType is rejected

    const range = try doc.createRange();
    defer range.deinit();

    // DocumentType not allowed
    const result = range.setStart(&doctype.prototype, 0);
    try std.testing.expectError(error.InvalidNodeTypeError, result);
}

test "Range: setStart - IndexSizeError for offset > length" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();
    // Don't need to append - just test offset validation

    const range = try doc.createRange();
    defer range.deinit();

    // Text length is 5, offset 6 is invalid
    const result = range.setStart(&text.prototype, 6);
    try std.testing.expectError(error.IndexSizeError, result);
}

test "Range: setEnd - valid and auto-collapse if start after end" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();
    // Don't need to append - just use for range boundaries

    const range = try doc.createRange();
    defer range.deinit();

    // Set start first
    try range.setStart(&text.prototype, 4);
    try std.testing.expectEqual(@as(u32, 4), range.start_offset);

    // Set end before start - should auto-collapse to end
    try range.setEnd(&text.prototype, 2);
    try std.testing.expectEqual(@as(u32, 2), range.start_offset); // Collapsed to end
    try std.testing.expectEqual(@as(u32, 2), range.end_offset);
    try std.testing.expect(range.collapsed());
}

// Phase 1 complete: 10 tests for basic structure ✅

// Phase 2: Comparison and Convenience Methods (15 tests)

test "Range: selectNode - selects node and its contents" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("span");
    _ = try parent.prototype.appendChild(&child.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Select the child node itself
    try range.selectNode(&child.prototype);

    // Range should be (parent, 0) to (parent, 1)
    try std.testing.expect(range.start_container == &parent.prototype);
    try std.testing.expectEqual(@as(u32, 0), range.start_offset);
    try std.testing.expect(range.end_container == &parent.prototype);
    try std.testing.expectEqual(@as(u32, 1), range.end_offset);
    try std.testing.expect(!range.collapsed());
}

test "Range: selectNode - error if no parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();
    // Not appended - no parent

    const range = try doc.createRange();
    defer range.deinit();

    const result = range.selectNode(&elem.prototype);
    try std.testing.expectError(error.InvalidNodeTypeError, result);
}

test "Range: commonAncestorContainer - same node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&elem.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&elem.prototype, 0);
    try range.setEnd(&elem.prototype, 0);

    const ancestor = range.commonAncestorContainer();
    try std.testing.expect(ancestor == &elem.prototype);
}

test "Range: commonAncestorContainer - different nodes with common parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&child1.prototype, 0);
    try range.setEnd(&child2.prototype, 0);

    const ancestor = range.commonAncestorContainer();
    try std.testing.expect(ancestor == &parent.prototype);
}

test "Range: compareBoundaryPoints - START_TO_START equal" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();

    const range1 = try doc.createRange();
    defer range1.deinit();
    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setStart(&text.prototype, 2);
    try range2.setStart(&text.prototype, 2);

    const result = try range1.compareBoundaryPoints(.start_to_start, range2);
    try std.testing.expectEqual(@as(i16, 0), result);
}

test "Range: compareBoundaryPoints - START_TO_START before" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();

    const range1 = try doc.createRange();
    defer range1.deinit();
    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setStart(&text.prototype, 2);
    try range2.setStart(&text.prototype, 5);

    const result = try range1.compareBoundaryPoints(.start_to_start, range2);
    try std.testing.expectEqual(@as(i16, -1), result);
}

test "Range: compareBoundaryPoints - START_TO_START after" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();

    const range1 = try doc.createRange();
    defer range1.deinit();
    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setStart(&text.prototype, 5);
    try range2.setStart(&text.prototype, 2);

    const result = try range1.compareBoundaryPoints(.start_to_start, range2);
    try std.testing.expectEqual(@as(i16, 1), result);
}

test "Range: compareBoundaryPoints - END_TO_END" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();

    const range1 = try doc.createRange();
    defer range1.deinit();
    const range2 = try doc.createRange();
    defer range2.deinit();

    try range1.setEnd(&text.prototype, 3);
    try range2.setEnd(&text.prototype, 5);

    const result = try range1.compareBoundaryPoints(.end_to_end, range2);
    try std.testing.expectEqual(@as(i16, -1), result); // 3 < 5
}

test "Range: comparePoint - before range" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 3);
    try range.setEnd(&text.prototype, 8);

    const result = try range.comparePoint(&text.prototype, 1);
    try std.testing.expectEqual(@as(i16, -1), result); // Before range
}

test "Range: comparePoint - in range" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 3);
    try range.setEnd(&text.prototype, 8);

    const result = try range.comparePoint(&text.prototype, 5);
    try std.testing.expectEqual(@as(i16, 0), result); // In range
}

test "Range: comparePoint - after range" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 3);
    try range.setEnd(&text.prototype, 8);

    const result = try range.comparePoint(&text.prototype, 10);
    try std.testing.expectEqual(@as(i16, 1), result); // After range
}

test "Range: isPointInRange - true" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 3);
    try range.setEnd(&text.prototype, 8);

    const in_range = try range.isPointInRange(&text.prototype, 5);
    try std.testing.expect(in_range);
}

test "Range: isPointInRange - false before" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 3);
    try range.setEnd(&text.prototype, 8);

    const in_range = try range.isPointInRange(&text.prototype, 1);
    try std.testing.expect(!in_range);
}

test "Range: isPointInRange - false after" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 3);
    try range.setEnd(&text.prototype, 8);

    const in_range = try range.isPointInRange(&text.prototype, 10);
    try std.testing.expect(!in_range);
}

test "Range: intersectsNode - true" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Range covers child1
    try range.setStart(&parent.prototype, 0);
    try range.setEnd(&parent.prototype, 1);

    const intersects = range.intersectsNode(&child1.prototype);
    try std.testing.expect(intersects);
}

test "Range: intersectsNode - false" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Range covers child1 only
    try range.setStart(&parent.prototype, 0);
    try range.setEnd(&parent.prototype, 1);

    const intersects = range.intersectsNode(&child2.prototype);
    try std.testing.expect(!intersects);
}

// Phase 2 complete: 15 tests for comparison methods ✅

// Phase 3: Content Manipulation (20 tests)

test "Range: deleteContents - collapsed range does nothing" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 2);
    range.collapse(true);

    // Delete on collapsed range should do nothing
    try range.deleteContents();

    try std.testing.expectEqualStrings("Hello", text.data);
}

test "Range: deleteContents - same container text node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    // Delete "llo Wo" (positions 2-8)
    try range.setStart(&text.prototype, 2);
    try range.setEnd(&text.prototype, 8);

    try range.deleteContents();

    try std.testing.expectEqualStrings("Herld", text.data);
    try std.testing.expect(range.collapsed());
    try std.testing.expectEqual(@as(u32, 2), range.start_offset);
}

test "Range: deleteContents - same container element children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    const child3 = try doc.createElement("b");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Delete children 1 and 2 (offsets 1-3)
    try range.setStart(&parent.prototype, 1);
    try range.setEnd(&parent.prototype, 3);

    try range.deleteContents();

    // Should only have child1 left
    try std.testing.expect(parent.prototype.first_child == &child1.prototype);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling == null);
    try std.testing.expect(range.collapsed());
}

test "Range: extractContents - collapsed range returns empty fragment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const range = try doc.createRange();
    defer range.deinit();

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expect(fragment.prototype.first_child == null);
}

test "Range: extractContents - same container text node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    // Extract "llo Wo" (positions 2-8)
    try range.setStart(&text.prototype, 2);
    try range.setEnd(&text.prototype, 8);

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    // Original text should be modified
    try std.testing.expectEqualStrings("Herld", text.data);

    // Fragment should contain extracted text
    try std.testing.expect(fragment.prototype.first_child != null);
    const extracted_text = fragment.prototype.first_child.?;
    try std.testing.expectEqual(dom.NodeType.text, extracted_text.node_type);

    const extracted: *Text = @fieldParentPtr("prototype", extracted_text);
    try std.testing.expectEqualStrings("llo Wo", extracted.data);
}

test "Range: extractContents - same container element children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    const child3 = try doc.createElement("b");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Extract children 1 and 2 (offsets 1-3)
    try range.setStart(&parent.prototype, 1);
    try range.setEnd(&parent.prototype, 3);

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    // Parent should only have child1 left
    try std.testing.expect(parent.prototype.first_child == &child1.prototype);
    try std.testing.expect(parent.prototype.first_child.?.next_sibling == null);

    // Fragment should have child2 and child3
    try std.testing.expect(fragment.prototype.first_child == &child2.prototype);
    try std.testing.expect(fragment.prototype.first_child.?.next_sibling == &child3.prototype);
}

test "Range: cloneContents - collapsed range returns empty fragment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const range = try doc.createRange();
    defer range.deinit();

    const fragment = try range.cloneContents();
    defer fragment.prototype.release();

    try std.testing.expect(fragment.prototype.first_child == null);
}

test "Range: cloneContents - same container text node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    // Clone "llo Wo" (positions 2-8)
    try range.setStart(&text.prototype, 2);
    try range.setEnd(&text.prototype, 8);

    const fragment = try range.cloneContents();
    defer fragment.prototype.release();

    // Original text should be unchanged
    try std.testing.expectEqualStrings("Hello World", text.data);

    // Fragment should contain cloned text
    try std.testing.expect(fragment.prototype.first_child != null);
    const cloned_text = fragment.prototype.first_child.?;

    const cloned: *Text = @fieldParentPtr("prototype", cloned_text);
    try std.testing.expectEqualStrings("llo Wo", cloned.data);

    // Range should NOT be collapsed (clone doesn't modify range)
    try std.testing.expect(!range.collapsed());
}

test "Range: cloneContents - same container element children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    const child3 = try doc.createElement("b");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Clone children 1 and 2 (offsets 1-3)
    try range.setStart(&parent.prototype, 1);
    try range.setEnd(&parent.prototype, 3);

    const fragment = try range.cloneContents();
    defer fragment.prototype.release();

    // Parent should still have all 3 children
    var child_count: u32 = 0;
    var current = parent.prototype.first_child;
    while (current) |c| {
        child_count += 1;
        current = c.next_sibling;
    }
    try std.testing.expectEqual(@as(u32, 3), child_count);

    // Fragment should have 2 cloned children
    var fragment_count: u32 = 0;
    current = fragment.prototype.first_child;
    while (current) |c| {
        fragment_count += 1;
        current = c.next_sibling;
    }
    try std.testing.expectEqual(@as(u32, 2), fragment_count);
}

test "Range: deleteContents - comment node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("Hello World");
    defer comment.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&comment.prototype, 2);
    try range.setEnd(&comment.prototype, 8);

    try range.deleteContents();

    try std.testing.expectEqualStrings("Herld", comment.data);
    try std.testing.expect(range.collapsed());
}

test "Range: extractContents - comment node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("Hello World");
    defer comment.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&comment.prototype, 2);
    try range.setEnd(&comment.prototype, 8);

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expectEqualStrings("Herld", comment.data);

    const Comment = dom.Comment;
    const extracted_comment: *Comment = @fieldParentPtr("prototype", fragment.prototype.first_child.?);
    try std.testing.expectEqualStrings("llo Wo", extracted_comment.data);
}

test "Range: cloneContents - comment node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("Hello World");
    defer comment.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&comment.prototype, 2);
    try range.setEnd(&comment.prototype, 8);

    const fragment = try range.cloneContents();
    defer fragment.prototype.release();

    // Original unchanged
    try std.testing.expectEqualStrings("Hello World", comment.data);

    const Comment = dom.Comment;
    const cloned_comment: *Comment = @fieldParentPtr("prototype", fragment.prototype.first_child.?);
    try std.testing.expectEqualStrings("llo Wo", cloned_comment.data);
}

test "Range: deleteContents - different containers with text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Delete from middle of text1 to middle of text2
    try range.setStart(&text1.prototype, 2); // "He|llo"
    try range.setEnd(&text2.prototype, 3); // "Wor|ld"

    try range.deleteContents();

    // text1 should have "He", text2 should have "ld"
    try std.testing.expectEqualStrings("He", text1.data);
    try std.testing.expectEqualStrings("ld", text2.data);
    try std.testing.expect(range.collapsed());
}

test "Range: extractContents - different containers with text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text1.prototype, 2);
    try range.setEnd(&text2.prototype, 3);

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expectEqualStrings("He", text1.data);
    try std.testing.expectEqualStrings("ld", text2.data);

    // Fragment should have extracted partial text nodes
    try std.testing.expect(fragment.prototype.first_child != null);
}

test "Range: cloneContents - different containers with text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text1.prototype, 2);
    try range.setEnd(&text2.prototype, 3);

    const fragment = try range.cloneContents();
    defer fragment.prototype.release();

    // Originals unchanged
    try std.testing.expectEqualStrings("Hello", text1.data);
    try std.testing.expectEqualStrings("World", text2.data);

    // Fragment has cloned partial text nodes
    try std.testing.expect(fragment.prototype.first_child != null);
}

test "Range: deleteContents - different containers with mixed content" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const elem = try doc.createElement("span");
    const text2 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&elem.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Delete from text1 middle, through elem, to text2 middle
    try range.setStart(&text1.prototype, 2);
    try range.setEnd(&text2.prototype, 3);

    try range.deleteContents();

    // text1 should have "He", elem should be gone, text2 should have "ld"
    try std.testing.expectEqualStrings("He", text1.data);
    try std.testing.expectEqualStrings("ld", text2.data);

    // elem should be removed
    var child_count: u32 = 0;
    var current = parent.prototype.first_child;
    while (current) |c| {
        child_count += 1;
        current = c.next_sibling;
    }
    try std.testing.expectEqual(@as(u32, 2), child_count); // Only text1 and text2 left
}

test "Range: extractContents - different containers with mixed content" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const elem = try doc.createElement("span");
    const text2 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&elem.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text1.prototype, 2);
    try range.setEnd(&text2.prototype, 3);

    const fragment = try range.extractContents();
    defer fragment.prototype.release();

    try std.testing.expectEqualStrings("He", text1.data);
    try std.testing.expectEqualStrings("ld", text2.data);

    // Fragment should contain partial texts and the elem
    var fragment_count: u32 = 0;
    var current = fragment.prototype.first_child;
    while (current) |c| {
        fragment_count += 1;
        current = c.next_sibling;
    }
    try std.testing.expect(fragment_count >= 1); // At least the elem and partial texts
}

test "Range: cloneContents - different containers with mixed content" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const elem = try doc.createElement("span");
    const text2 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&elem.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text1.prototype, 2);
    try range.setEnd(&text2.prototype, 3);

    const fragment = try range.cloneContents();
    defer fragment.prototype.release();

    // Originals unchanged
    try std.testing.expectEqualStrings("Hello", text1.data);
    try std.testing.expectEqualStrings("World", text2.data);

    // All 3 children still in parent
    var parent_count: u32 = 0;
    var current = parent.prototype.first_child;
    while (current) |c| {
        parent_count += 1;
        current = c.next_sibling;
    }
    try std.testing.expectEqual(@as(u32, 3), parent_count);

    // Fragment has clones
    try std.testing.expect(fragment.prototype.first_child != null);
}

// Phase 3 complete: 20 tests for content manipulation ✅

// Phase 4: Convenience Methods (10 tests)

test "Range: insertNode - into element container" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Insert at position 1 (between child1 and child2)
    try range.setStart(&parent.prototype, 1);
    range.collapse(true);

    const new_elem = try doc.createElement("b");
    try range.insertNode(&new_elem.prototype);

    // Check order: child1, new_elem, child2
    try std.testing.expect(parent.prototype.first_child == &child1.prototype);
    try std.testing.expect(child1.prototype.next_sibling == &new_elem.prototype);
    try std.testing.expect(new_elem.prototype.next_sibling == &child2.prototype);
}

test "Range: insertNode - into text node (splits it)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text = try doc.createTextNode("HelloWorld");
    _ = try parent.prototype.appendChild(&text.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Insert at position 5 in text (after "Hello")
    try range.setStart(&text.prototype, 5);
    range.collapse(true);

    const elem = try doc.createElement("span");
    try range.insertNode(&elem.prototype);

    // Text should be split: "Hello" [elem] "World"
    try std.testing.expectEqualStrings("Hello", text.data);

    // elem should be next sibling
    try std.testing.expect(text.prototype.next_sibling == &elem.prototype);

    // Next should be the split text with "World"
    const next_text_node = elem.prototype.next_sibling.?;
    const next_text: *Text = @fieldParentPtr("prototype", next_text_node);
    try std.testing.expectEqualStrings("World", next_text.data);
}

test "Range: surroundContents - wraps content in new parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text = try doc.createTextNode("Hello");
    _ = try parent.prototype.appendChild(&text.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Select the text content
    try range.selectNodeContents(&parent.prototype);

    const span = try doc.createElement("span");
    try range.surroundContents(&span.prototype);

    // parent should contain span, span should contain text
    try std.testing.expect(parent.prototype.first_child == &span.prototype);
    try std.testing.expect(span.prototype.first_child == &text.prototype);

    // Range should select span
    try std.testing.expect(range.start_container == &parent.prototype);
    try std.testing.expect(range.end_container == &parent.prototype);
}

test "Range: surroundContents - error on partially selected node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode("World");
    _ = try child1.prototype.appendChild(&text1.prototype);
    _ = try child2.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Select from middle of text1 to middle of text2 (partially selects child1 and child2)
    try range.setStart(&text1.prototype, 2);
    try range.setEnd(&text2.prototype, 3);

    const wrapper = try doc.createElement("b");
    defer wrapper.prototype.release();

    const result = range.surroundContents(&wrapper.prototype);
    try std.testing.expectError(error.InvalidStateError, result);
}

test "Range: cloneRange - creates independent copy" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range1 = try doc.createRange();
    defer range1.deinit();

    try range1.setStart(&text.prototype, 2);
    try range1.setEnd(&text.prototype, 8);

    const range2 = try range1.cloneRange();
    defer range2.deinit();

    // range2 should have same boundaries
    try std.testing.expect(range2.start_container == &text.prototype);
    try std.testing.expectEqual(@as(u32, 2), range2.start_offset);
    try std.testing.expect(range2.end_container == &text.prototype);
    try std.testing.expectEqual(@as(u32, 8), range2.end_offset);

    // Modifying range2 shouldn't affect range1
    try range2.setStart(&text.prototype, 0);
    try std.testing.expectEqual(@as(u32, 2), range1.start_offset);
    try std.testing.expectEqual(@as(u32, 0), range2.start_offset);
}

test "Range: detach - no-op" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const range = try doc.createRange();
    defer range.deinit();

    const text = try doc.createTextNode("Hello");
    defer text.prototype.release();

    try range.setStart(&text.prototype, 0);
    try range.setEnd(&text.prototype, 5);

    // detach() should do nothing
    range.detach();

    // Range should still be usable
    try std.testing.expect(!range.collapsed());
    try std.testing.expectEqual(@as(u32, 0), range.start_offset);
    try std.testing.expectEqual(@as(u32, 5), range.end_offset);
}

test "Range: insertNode - at start of text node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text = try doc.createTextNode("Hello");
    _ = try parent.prototype.appendChild(&text.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Insert at start of text (offset 0)
    try range.setStart(&text.prototype, 0);
    range.collapse(true);

    const elem = try doc.createElement("span");
    try range.insertNode(&elem.prototype);

    // elem should be inserted before text (no split needed)
    try std.testing.expect(parent.prototype.first_child == &elem.prototype);
    try std.testing.expect(elem.prototype.next_sibling == &text.prototype);
    try std.testing.expectEqualStrings("Hello", text.data); // Unchanged
}

test "Range: insertNode - at end of element" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("span");
    _ = try parent.prototype.appendChild(&child.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Insert at end (offset 1, after child)
    try range.setStart(&parent.prototype, 1);
    range.collapse(true);

    const new_elem = try doc.createElement("p");
    try range.insertNode(&new_elem.prototype);

    // new_elem should be after child
    try std.testing.expect(parent.prototype.first_child == &child.prototype);
    try std.testing.expect(child.prototype.next_sibling == &new_elem.prototype);
    try std.testing.expect(new_elem.prototype.next_sibling == null);
}

test "Range: surroundContents - with collapsed range" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&parent.prototype, 0);
    range.collapse(true);

    const span = try doc.createElement("span");
    try range.surroundContents(&span.prototype);

    // span should be inserted (empty)
    try std.testing.expect(parent.prototype.first_child == &span.prototype);
    try std.testing.expect(span.prototype.first_child == null);
}

test "Range: cloneRange - independent modification" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode("World");
    defer text1.prototype.release();
    defer text2.prototype.release();

    const range1 = try doc.createRange();
    defer range1.deinit();

    try range1.setStart(&text1.prototype, 0);
    try range1.setEnd(&text1.prototype, 5);

    const range2 = try range1.cloneRange();
    defer range2.deinit();

    // Change range2 to point to text2
    try range2.setStart(&text2.prototype, 0);
    try range2.setEnd(&text2.prototype, 5);

    // range1 should still point to text1
    try std.testing.expect(range1.start_container == &text1.prototype);
    try std.testing.expect(range2.start_container == &text2.prototype);
}

// Phase 4 complete: 10 tests for convenience methods ✅

// Phase 5: toString() Method (8 tests)

test "Range: toString - collapsed range returns empty string" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 5);
    range.collapse(true);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("", str);
}

test "Range: toString - single text node, complete text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 0);
    try range.setEnd(&text.prototype, 11);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("Hello World", str);
}

test "Range: toString - single text node, partial text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    const range = try doc.createRange();
    defer range.deinit();

    try range.setStart(&text.prototype, 6);
    try range.setEnd(&text.prototype, 11);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("World", str);
}

test "Range: toString - multiple text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode(" ");
    const text3 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);
    _ = try parent.prototype.appendChild(&text3.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Select all text nodes
    try range.setStart(&parent.prototype, 0);
    try range.setEnd(&parent.prototype, 3);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("Hello World", str);
}

test "Range: toString - mixed content with elements" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const elem = try doc.createElement("span");
    const text2 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&elem.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    // Add text inside span
    const inner_text = try doc.createTextNode(" Beautiful ");
    _ = try elem.prototype.appendChild(&inner_text.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Select all content
    try range.selectNodeContents(&parent.prototype);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("Hello Beautiful World", str);
}

test "Range: toString - cross-node partial text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode("World");
    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Select "lo" from text1 and "Wor" from text2
    try range.setStart(&text1.prototype, 3);
    try range.setEnd(&text2.prototype, 3);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("loWor", str);
}

test "Range: toString - nested elements" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child1 = try doc.createElement("p");
    const child2 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const text1 = try doc.createTextNode("First paragraph");
    const text2 = try doc.createTextNode("Second paragraph");
    _ = try child1.prototype.appendChild(&text1.prototype);
    _ = try child2.prototype.appendChild(&text2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Select both paragraphs
    try range.selectNodeContents(&parent.prototype);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("First paragraphSecond paragraph", str);
}

test "Range: toString - element-only range (no text)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const elem1 = try doc.createElement("span");
    const elem2 = try doc.createElement("p");
    _ = try parent.prototype.appendChild(&elem1.prototype);
    _ = try parent.prototype.appendChild(&elem2.prototype);

    const range = try doc.createRange();
    defer range.deinit();

    // Select elements with no text
    try range.selectNodeContents(&parent.prototype);

    const str = try range.toString(allocator);
    defer allocator.free(str);

    try std.testing.expectEqualStrings("", str);
}

// Phase 5 complete: 8 tests for toString() ✅
