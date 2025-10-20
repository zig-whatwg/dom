const std = @import("std");
const dom = @import("dom");

// Import all commonly used types
const Node = dom.Node;
const NodeType = dom.NodeType;
const NodeVTable = dom.NodeVTable;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;
const ShadowRoot = dom.ShadowRoot;

test "Text - creation and cleanup" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.prototype.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.text, text.prototype.node_type);
    try std.testing.expectEqual(@as(u32, 1), text.prototype.getRefCount());
    try std.testing.expectEqualStrings("Hello World", text.data);
    try std.testing.expectEqual(@as(usize, 11), text.length());

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("#text", text.prototype.nodeName());
    try std.testing.expectEqualStrings("Hello World", text.prototype.nodeValue().?);
}

test "Text - empty content" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "");
    defer text.prototype.release();

    try std.testing.expectEqual(@as(usize, 0), text.length());
    try std.testing.expectEqualStrings("", text.data);
}

test "Text - set node value" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "original");
    defer text.prototype.release();

    try std.testing.expectEqualStrings("original", text.data);

    // Change via nodeValue setter
    try text.prototype.setNodeValue("updated");
    try std.testing.expectEqualStrings("updated", text.data);

    // Verify generation incremented
    try std.testing.expect(text.prototype.generation > 0);
}

test "Text - substringData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.prototype.release();

    // Substring with count
    {
        const sub = try text.substringData(allocator, 0, 5);
        defer allocator.free(sub);
        try std.testing.expectEqualStrings("Hello", sub);
    }

    // Substring from middle
    {
        const sub = try text.substringData(allocator, 6, 5);
        defer allocator.free(sub);
        try std.testing.expectEqualStrings("World", sub);
    }

    // Substring to end (no count)
    {
        const sub = try text.substringData(allocator, 6, null);
        defer allocator.free(sub);
        try std.testing.expectEqualStrings("World", sub);
    }

    // Out of bounds
    try std.testing.expectError(error.IndexOutOfBounds, text.substringData(allocator, 100, 1));
}

test "Text - appendData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello");
    defer text.prototype.release();

    try text.appendData(" World");
    try std.testing.expectEqualStrings("Hello World", text.data);

    try text.appendData("!");
    try std.testing.expectEqualStrings("Hello World!", text.data);
}

test "Text - insertData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.prototype.release();

    // Insert in middle
    try text.insertData(5, " Beautiful");
    try std.testing.expectEqualStrings("Hello Beautiful World", text.data);

    // Insert at start
    try text.insertData(0, "Oh ");
    try std.testing.expectEqualStrings("Oh Hello Beautiful World", text.data);

    // Insert at end
    try text.insertData(text.data.len, "!");
    try std.testing.expectEqualStrings("Oh Hello Beautiful World!", text.data);

    // Out of bounds
    try std.testing.expectError(error.IndexOutOfBounds, text.insertData(1000, "fail"));
}

test "Text - deleteData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello Beautiful World");
    defer text.prototype.release();

    // Delete from middle
    try text.deleteData(5, 10); // Remove " Beautiful"
    try std.testing.expectEqualStrings("Hello World", text.data);

    // Delete from start
    try text.deleteData(0, 6); // Remove "Hello "
    try std.testing.expectEqualStrings("World", text.data);

    // Delete to end (count too large)
    try text.deleteData(0, 1000);
    try std.testing.expectEqualStrings("", text.data);

    // Out of bounds
    try std.testing.expectError(error.IndexOutOfBounds, text.deleteData(1000, 1));
}

test "Text - replaceData" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.prototype.release();

    // Replace in middle
    try text.replaceData(6, 5, "Zig");
    try std.testing.expectEqualStrings("Hello Zig", text.data);

    // Replace at start
    try text.replaceData(0, 5, "Hi");
    try std.testing.expectEqualStrings("Hi Zig", text.data);

    // Replace everything
    try text.replaceData(0, text.data.len, "New");
    try std.testing.expectEqualStrings("New", text.data);

    // Out of bounds
    try std.testing.expectError(error.IndexOutOfBounds, text.replaceData(1000, 1, "fail"));
}

test "Text - cloneNode" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.prototype.release();

    // Clone
    const cloned_node = try text.prototype.cloneNode(false);
    defer cloned_node.release();

    const cloned: *Text = @fieldParentPtr("prototype", cloned_node);

    // Verify clone properties
    try std.testing.expectEqualStrings("Hello World", cloned.data);
    try std.testing.expectEqual(@as(u32, 1), cloned.prototype.getRefCount());

    // Verify independence
    try text.appendData("!");
    try std.testing.expectEqualStrings("Hello World!", text.data);
    try std.testing.expectEqualStrings("Hello World", cloned.data); // Unchanged
}

test "Text - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple creation
    {
        const text = try Text.create(allocator, "test");
        defer text.prototype.release();
    }

    // Test 2: Modifications
    {
        const text = try Text.create(allocator, "test");
        defer text.prototype.release();

        try text.appendData(" more");
        try text.insertData(0, "prefix ");
        try text.deleteData(0, 7);
        try text.replaceData(0, 4, "TEST");
        try text.prototype.setNodeValue("final");
    }

    // Test 3: Clone
    {
        const text = try Text.create(allocator, "original");
        defer text.prototype.release();

        const cloned = try text.prototype.cloneNode(false);
        defer cloned.release();
    }

    // Test 4: Multiple acquire/release
    {
        const text = try Text.create(allocator, "test");
        defer text.prototype.release();

        text.prototype.acquire();
        defer text.prototype.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Text - ref counting" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "test");
    defer text.prototype.release();

    // Initial ref count
    try std.testing.expectEqual(@as(u32, 1), text.prototype.getRefCount());

    // Acquire
    text.prototype.acquire();
    try std.testing.expectEqual(@as(u32, 2), text.prototype.getRefCount());

    // Release
    text.prototype.release();
    try std.testing.expectEqual(@as(u32, 1), text.prototype.getRefCount());
}

test "Text.splitText - basic split" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text = try doc.createTextNode("Hello World");
    _ = try parent.prototype.appendChild(&text.prototype);

    // Split at offset 6 (after "Hello ")
    const second = try text.splitText(6);

    // First part
    try std.testing.expectEqualStrings("Hello ", text.data);

    // Second part
    try std.testing.expectEqualStrings("World", second.data);

    // Both should be children of parent
    try std.testing.expectEqual(@as(usize, 2), parent.prototype.childNodes().length());

    // Second should be next sibling of first
    try std.testing.expect(text.prototype.next_sibling == &second.prototype);
}

test "Text.splitText - split at boundaries" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("Test");
    defer text1.prototype.release();

    // Split at 0 - first part empty
    const second1 = try text1.splitText(0);
    defer second1.prototype.release();

    try std.testing.expectEqualStrings("", text1.data);
    try std.testing.expectEqualStrings("Test", second1.data);

    const text2 = try doc.createTextNode("Test");
    defer text2.prototype.release();

    // Split at length - second part empty
    const second2 = try text2.splitText(4);
    defer second2.prototype.release();

    try std.testing.expectEqualStrings("Test", text2.data);
    try std.testing.expectEqualStrings("", second2.data);
}

test "Text.splitText - orphaned node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Orphan Text");
    defer text.prototype.release();

    // Split orphaned node (no parent)
    const second = try text.splitText(7);
    defer second.prototype.release();

    try std.testing.expectEqualStrings("Orphan ", text.data);
    try std.testing.expectEqualStrings("Text", second.data);

    // Neither should have a parent
    try std.testing.expect(text.prototype.parent_node == null);
    try std.testing.expect(second.prototype.parent_node == null);

    // Should not be siblings
    try std.testing.expect(text.prototype.next_sibling == null);
    try std.testing.expect(second.prototype.previous_sibling == null);
}

test "Text.splitText - invalid offset" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Test");
    defer text.prototype.release();

    // Offset greater than length
    try std.testing.expectError(
        error.IndexSizeError,
        text.splitText(100),
    );
}

test "Text.splitText - UTF-16 with BMP characters" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // "comté" = "com"(3) + "t"(1) + "é"(1) = 5 UTF-16 code units
    const text = try doc.createTextNode("comté");
    defer text.prototype.release();

    // Split at UTF-16 offset 3 (after "com")
    const second = try text.splitText(3);
    defer second.prototype.release();

    try std.testing.expectEqualStrings("com", text.data);
    try std.testing.expectEqualStrings("té", second.data);
}

test "Text.splitText - UTF-16 with supplementary characters" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // "Hello 𝄞" = "Hello "(6) + "𝄞"(2 UTF-16 code units) = 8 UTF-16 code units
    const text = try doc.createTextNode("Hello 𝄞");
    defer text.prototype.release();

    // Split at UTF-16 offset 6 (before "𝄞")
    const second = try text.splitText(6);
    defer second.prototype.release();

    try std.testing.expectEqualStrings("Hello ", text.data);
    try std.testing.expectEqualStrings("𝄞", second.data);
}

test "Text.splitText - UTF-16 mixed characters in tree" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    defer parent.prototype.release();

    // "世界𝄞" = "世"(1) + "界"(1) + "𝄞"(2) = 4 UTF-16 code units
    const text = try doc.createTextNode("世界𝄞");
    _ = try parent.prototype.appendChild(&text.prototype);

    // Split at UTF-16 offset 2 (after "世界", before "𝄞")
    const second = try text.splitText(2);

    try std.testing.expectEqualStrings("世界", text.data);
    try std.testing.expectEqualStrings("𝄞", second.data);
    try std.testing.expect(text.prototype.next_sibling == &second.prototype);
    try std.testing.expect(second.prototype.parent_node == &parent.prototype);
}

test "Text - wholeText with single text node" {
    const allocator = std.testing.allocator;

    const text = try Text.create(allocator, "Hello World");
    defer text.prototype.release();

    const whole = try text.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("Hello World", whole);
}

test "Text - wholeText with contiguous text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const text1 = try doc.createTextNode("Hello ");
    const text2 = try doc.createTextNode("beautiful ");
    const text3 = try doc.createTextNode("world!");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);
    _ = try parent.prototype.appendChild(&text3.prototype);

    // wholeText from middle node should concatenate all three
    const whole = try text2.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("Hello beautiful world!", whole);
}

test "Text - wholeText with non-text siblings" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const text1 = try doc.createTextNode("Hello");
    const elem = try doc.createElement("span");
    const text2 = try doc.createTextNode("World");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&elem.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    // wholeText from text1 should only include text1 (element breaks contiguity)
    const whole1 = try text1.wholeText(allocator);
    defer allocator.free(whole1);
    try std.testing.expectEqualStrings("Hello", whole1);

    // wholeText from text2 should only include text2
    const whole2 = try text2.wholeText(allocator);
    defer allocator.free(whole2);
    try std.testing.expectEqualStrings("World", whole2);
}

test "Text - wholeText with empty text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const text1 = try doc.createTextNode("");
    const text2 = try doc.createTextNode("Content");
    const text3 = try doc.createTextNode("");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);
    _ = try parent.prototype.appendChild(&text3.prototype);

    // wholeText should include empty strings too
    const whole = try text2.wholeText(allocator);
    defer allocator.free(whole);

    try std.testing.expectEqualStrings("Content", whole);
}
