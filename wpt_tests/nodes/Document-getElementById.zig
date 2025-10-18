// META: title=Document.getElementById
// META: link=https://dom.spec.whatwg.org/#dom-document-getelementbyid

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "getElementById with empty string argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const result = doc.getElementById("");
    try std.testing.expectEqual(@as(?*Element, null), result);
}

test "getElementById with null-like string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const element = try doc.createElement("div");
    try element.setAttribute("id", "null");
    _ = try root.node.appendChild(&element.node);

    const result = doc.getElementById("null");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == element);
}

test "getElementById with undefined-like string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const element = try doc.createElement("div");
    try element.setAttribute("id", "undefined");
    _ = try root.node.appendChild(&element.node);

    const result = doc.getElementById("undefined");
    try std.testing.expect(result != null);
    try std.testing.expect(result.? == element);
}

test "getElementById with script-inserted element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const TEST_ID = "test2";

    const test_elem = try doc.createElement("div");
    try test_elem.setAttribute("id", TEST_ID);
    _ = try root.node.appendChild(&test_elem.node);

    // Test: appended element
    const result = doc.getElementById(TEST_ID);
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("div", result.?.tag_name);

    // Test: removed element
    _ = try root.node.removeChild(&test_elem.node);
    test_elem.node.release();
    const removed = doc.getElementById(TEST_ID);
    try std.testing.expectEqual(@as(?*Element, null), removed);
}

test "getElementById updates when id attribute changes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const TEST_ID = "test3";
    const test_elem = try doc.createElement("div");
    try test_elem.setAttribute("id", TEST_ID);
    _ = try root.node.appendChild(&test_elem.node);

    // Update id
    const UPDATED_ID = "test3-updated";
    try test_elem.setAttribute("id", UPDATED_ID);
    const e = doc.getElementById(UPDATED_ID);
    try std.testing.expect(e == test_elem);

    const old = doc.getElementById(TEST_ID);
    try std.testing.expectEqual(@as(?*Element, null), old);

    // Remove id
    test_elem.removeAttribute("id");
    const e2 = doc.getElementById(UPDATED_ID);
    try std.testing.expectEqual(@as(?*Element, null), e2);
}

// getElementById should find element after appendChild (uses mutation-time id_map updates)
test "getElementById only finds elements in document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const TEST_ID = "test4-should-not-exist";

    const e = try doc.createElement("div");
    try e.setAttribute("id", TEST_ID);

    // Before appending, should not be found
    try std.testing.expectEqual(@as(?*Element, null), doc.getElementById(TEST_ID));

    // After appending, should be found
    _ = try root.node.appendChild(&e.node);
    try std.testing.expect(doc.getElementById(TEST_ID) == e);
}

// getElementById should return first element in tree order when duplicate IDs exist
test "getElementById returns first element in tree order" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const TEST_ID = "test5";

    // Create first element with id
    const target = try doc.createElement("div");
    try target.setAttribute("id", TEST_ID);
    try target.setAttribute("data-name", "1st");
    _ = try root.node.appendChild(&target.node);

    const result = doc.getElementById(TEST_ID);
    try std.testing.expect(result != null);
    const data_name = result.?.getAttribute("data-name");
    try std.testing.expect(data_name != null);
    try std.testing.expectEqualStrings("1st", data_name.?);

    // Add another element with same id
    const element4 = try doc.createElement("div");
    try element4.setAttribute("id", TEST_ID);
    try element4.setAttribute("data-name", "4th");
    _ = try root.node.appendChild(&element4.node);

    const target2 = doc.getElementById(TEST_ID);
    try std.testing.expect(target2 != null);
    const data_name2 = target2.?.getAttribute("data-name");
    try std.testing.expect(data_name2 != null);
    try std.testing.expectEqualStrings("1st", data_name2.?);

    // Remove first element
    _ = try root.node.removeChild(&target.node);
    target.node.release();
    const target3 = doc.getElementById(TEST_ID);
    try std.testing.expect(target3 != null);
    const data_name3 = target3.?.getAttribute("data-name");
    try std.testing.expect(data_name3 != null);
    try std.testing.expectEqualStrings("4th", data_name3.?);
}

test "getElementById with element not in document tree" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const TEST_ID = "test6";
    const s = try doc.createElement("div");
    try s.setAttribute("id", TEST_ID);

    // Append to another element, not to document
    const parent = try doc.createElement("div");
    defer parent.node.release(); // parent owns s, will release it
    _ = try parent.node.appendChild(&s.node);

    try std.testing.expectEqual(@as(?*Element, null), doc.getElementById(TEST_ID));
}

test "getElementById returns null for non-existent id" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const result = doc.getElementById("does-not-exist");
    try std.testing.expectEqual(@as(?*Element, null), result);
}

test "getElementById with multiple nested elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.node.appendChild(&root.node);

    const outer = try doc.createElement("outer");
    try outer.setAttribute("id", "outer");
    _ = try root.node.appendChild(&outer.node);

    const middle = try doc.createElement("middle");
    try middle.setAttribute("id", "middle");
    _ = try outer.node.appendChild(&middle.node);

    const inner = try doc.createElement("inner");
    try inner.setAttribute("id", "inner");
    _ = try middle.node.appendChild(&inner.node);

    try std.testing.expect(doc.getElementById("outer") == outer);
    try std.testing.expect(doc.getElementById("middle") == middle);
    try std.testing.expect(doc.getElementById("inner") == inner);
}
