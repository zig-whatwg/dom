// META: title=Node.cloneNode
// META: link=https://dom.spec.whatwg.org/#dom-node-clonenode

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Node = dom.Node;
const NodeType = dom.NodeType;

test "cloneNode() shallow copy of element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.node.release(); // Must release orphaned nodes
    const copy = try element.node.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&element.node != copy);

    // Should have same nodeType and nodeName
    try std.testing.expectEqual(element.node.node_type, copy.node_type);
    try std.testing.expect(std.mem.eql(u8, element.node.nodeName(), copy.nodeName()));
}

test "cloneNode() shallow copy does not clone children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.node.release(); // Must release orphaned nodes
    const child = try doc.createElement("child");
    _ = try parent.node.appendChild(&child.node);

    const copy = try parent.node.cloneNode(false);
    defer copy.release();

    // Original has children
    try std.testing.expect(parent.node.hasChildNodes());

    // Copy should not have children
    try std.testing.expect(!copy.hasChildNodes());
}

test "cloneNode() deep copy clones children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.node.release(); // Must release orphaned nodes
    const child = try doc.createElement("child");
    const grandchild = try doc.createElement("grandchild");

    _ = try child.node.appendChild(&grandchild.node);
    _ = try parent.node.appendChild(&child.node);

    const copy = try parent.node.cloneNode(true);
    defer copy.release();

    // Original has children
    try std.testing.expect(parent.node.hasChildNodes());

    // Copy should also have children
    try std.testing.expect(copy.hasChildNodes());

    // Copy should have same number of children (but different objects)
    try std.testing.expect(copy.first_child != null);
    try std.testing.expect(copy.first_child.? != parent.node.first_child.?);
}

test "cloneNode() copies attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.node.release(); // Must release orphaned nodes
    try element.setAttribute("id", "test");
    try element.setAttribute("class", "foo bar");

    const copy_node = try element.node.cloneNode(false);
    defer copy_node.release();

    // Get the Element from the cloned Node
    const copy: *Element = @fieldParentPtr("node", copy_node);

    // Attributes should be copied
    try std.testing.expect(copy.getAttribute("id") != null);
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("id").?, "test"));
    try std.testing.expect(copy.getAttribute("class") != null);
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("class").?, "foo bar"));
}

test "cloneNode() text node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello, world!");
    defer text.node.release(); // Must release orphaned nodes
    const copy = try text.node.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&text.node != copy);

    // Should have same node type
    try std.testing.expectEqual(text.node.node_type, copy.node_type);

    // Should have same text content
    const copy_text: *Text = @fieldParentPtr("node", copy);
    try std.testing.expect(std.mem.eql(u8, text.data, copy_text.data));
}

test "cloneNode() comment node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    defer comment.node.release(); // Must release orphaned nodes
    const copy = try comment.node.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&comment.node != copy);

    // Should have same node type
    try std.testing.expectEqual(comment.node.node_type, copy.node_type);

    // Should have same comment data
    const copy_comment: *Comment = @fieldParentPtr("node", copy);
    try std.testing.expect(std.mem.eql(u8, comment.data, copy_comment.data));
}

test "cloneNode() preserves owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.node.release(); // Must release orphaned nodes
    const copy = try element.node.cloneNode(false);
    defer copy.release();

    // Both should have same owner document
    try std.testing.expect(element.node.getOwnerDocument() == copy.getOwnerDocument());
    try std.testing.expect(copy.getOwnerDocument() == doc);
}

// ============================================================================
// DocumentFragment Cloning Tests
// ============================================================================

test "cloneNode() DocumentFragment shallow copy" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    // Add children to original
    const element = try doc.createElement("element");
    _ = try fragment.node.appendChild(&element.node);

    // Shallow clone
    const copy = try fragment.node.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&fragment.node != copy);

    // Should have same nodeType
    try std.testing.expectEqual(fragment.node.node_type, copy.node_type);
    try std.testing.expectEqual(NodeType.document_fragment, copy.node_type);

    // Should have same nodeName
    try std.testing.expect(std.mem.eql(u8, fragment.node.nodeName(), copy.nodeName()));
    try std.testing.expect(std.mem.eql(u8, "#document-fragment", copy.nodeName()));

    // Original has children
    try std.testing.expect(fragment.node.hasChildNodes());

    // Copy should not have children (shallow)
    try std.testing.expect(!copy.hasChildNodes());
}

test "cloneNode() DocumentFragment deep copy" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    // Build tree structure
    const container = try doc.createElement("container");
    const item = try doc.createElement("item");
    const text = try doc.createTextNode("content");

    _ = try item.node.appendChild(&text.node);
    _ = try container.node.appendChild(&item.node);
    _ = try fragment.node.appendChild(&container.node);

    // Deep clone
    const copy = try fragment.node.cloneNode(true);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&fragment.node != copy);

    // Should have same nodeType
    try std.testing.expectEqual(NodeType.document_fragment, copy.node_type);

    // Both should have children
    try std.testing.expect(fragment.node.hasChildNodes());
    try std.testing.expect(copy.hasChildNodes());

    // Children should be different objects
    try std.testing.expect(copy.first_child != null);
    try std.testing.expect(copy.first_child.? != fragment.node.first_child.?);

    // Verify deep cloning (grandchildren cloned)
    const original_child = fragment.node.first_child.?;
    const cloned_child = copy.first_child.?;
    try std.testing.expect(original_child.first_child != null);
    try std.testing.expect(cloned_child.first_child != null);
    try std.testing.expect(original_child.first_child.? != cloned_child.first_child.?);
}

test "cloneNode() DocumentFragment with mixed node types" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    // Add different node types
    const elem = try doc.createElement("element");
    const text = try doc.createTextNode("text node");
    const comment = try doc.createComment("comment node");

    _ = try fragment.node.appendChild(&elem.node);
    _ = try fragment.node.appendChild(&text.node);
    _ = try fragment.node.appendChild(&comment.node);

    // Deep clone
    const copy = try fragment.node.cloneNode(true);
    defer copy.release();

    // Should have same number of children
    try std.testing.expectEqual(@as(usize, 3), copy.childNodes().length());

    // Verify node types preserved
    var current = copy.first_child;
    try std.testing.expect(current != null);
    try std.testing.expectEqual(NodeType.element, current.?.node_type);

    current = current.?.next_sibling;
    try std.testing.expect(current != null);
    try std.testing.expectEqual(NodeType.text, current.?.node_type);

    current = current.?.next_sibling;
    try std.testing.expect(current != null);
    try std.testing.expectEqual(NodeType.comment, current.?.node_type);
}

// ============================================================================
// Deep Clone Verification Tests
// ============================================================================

test "cloneNode() deep copy with grandchildren verification" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Build: level1 > level2 > level3 > text
    const level1 = try doc.createElement("level1");
    defer level1.node.release();
    const level2 = try doc.createElement("level2");
    const level3 = try doc.createElement("level3");
    const text = try doc.createTextNode("deep content");

    _ = try level3.node.appendChild(&text.node);
    _ = try level2.node.appendChild(&level3.node);
    _ = try level1.node.appendChild(&level2.node);

    // Deep clone
    const copy = try level1.node.cloneNode(true);
    defer copy.release();

    // Verify all levels are different objects
    const orig_level2 = level1.node.first_child.?;
    const copy_level2 = copy.first_child.?;
    try std.testing.expect(orig_level2 != copy_level2);

    const orig_level3 = orig_level2.first_child.?;
    const copy_level3 = copy_level2.first_child.?;
    try std.testing.expect(orig_level3 != copy_level3);

    const orig_text = orig_level3.first_child.?;
    const copy_text = copy_level3.first_child.?;
    try std.testing.expect(orig_text != copy_text);

    // Verify text content preserved
    const orig_text_node: *Text = @fieldParentPtr("node", orig_text);
    const copy_text_node: *Text = @fieldParentPtr("node", copy_text);
    try std.testing.expect(std.mem.eql(u8, orig_text_node.data, copy_text_node.data));
}

test "cloneNode() deep copy preserves sibling relationships" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    // Add three siblings
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    const child3 = try doc.createElement("child3");

    _ = try parent.node.appendChild(&child1.node);
    _ = try parent.node.appendChild(&child2.node);
    _ = try parent.node.appendChild(&child3.node);

    // Deep clone
    const copy = try parent.node.cloneNode(true);
    defer copy.release();

    // Verify sibling chain
    const copy_child1 = copy.first_child.?;
    try std.testing.expect(copy_child1.previous_sibling == null);
    try std.testing.expect(copy_child1.next_sibling != null);

    const copy_child2 = copy_child1.next_sibling.?;
    try std.testing.expect(copy_child2.previous_sibling == copy_child1);
    try std.testing.expect(copy_child2.next_sibling != null);

    const copy_child3 = copy_child2.next_sibling.?;
    try std.testing.expect(copy_child3.previous_sibling == copy_child2);
    try std.testing.expect(copy_child3.next_sibling == null);

    // Verify last_child
    try std.testing.expect(copy.last_child == copy_child3);
}

// ============================================================================
// Clone Independence Tests
// ============================================================================

test "cloneNode() modifications to original don't affect clone" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const original = try doc.createElement("element");
    defer original.node.release();
    try original.setAttribute("id", "original");

    // Clone
    const copy_node = try original.node.cloneNode(false);
    defer copy_node.release();
    const copy: *Element = @fieldParentPtr("node", copy_node);

    // Modify original
    try original.setAttribute("id", "modified");
    try original.setAttribute("class", "new-class");

    // Clone should be unchanged
    const copy_id = copy.getAttribute("id");
    try std.testing.expect(copy_id != null);
    try std.testing.expect(std.mem.eql(u8, copy_id.?, "original"));
    try std.testing.expect(copy.getAttribute("class") == null);
}

test "cloneNode() modifications to clone don't affect original" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const original = try doc.createElement("element");
    defer original.node.release();
    try original.setAttribute("data-test", "value");

    // Clone
    const copy_node = try original.node.cloneNode(false);
    defer copy_node.release();
    const copy: *Element = @fieldParentPtr("node", copy_node);

    // Modify clone
    try copy.setAttribute("data-test", "changed");
    try copy.setAttribute("data-new", "added");

    // Original should be unchanged
    const orig_test = original.getAttribute("data-test");
    try std.testing.expect(orig_test != null);
    try std.testing.expect(std.mem.eql(u8, orig_test.?, "value"));
    try std.testing.expect(original.getAttribute("data-new") == null);
}

test "cloneNode() adding children to original doesn't affect shallow clone" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const original = try doc.createElement("element");
    defer original.node.release();

    // Shallow clone
    const copy = try original.node.cloneNode(false);
    defer copy.release();

    // Add children to original AFTER cloning
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try original.node.appendChild(&child1.node);
    _ = try original.node.appendChild(&child2.node);

    // Original now has children
    try std.testing.expect(original.node.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), original.node.childNodes().length());

    // Clone should still have no children
    try std.testing.expect(!copy.hasChildNodes());
}

// ============================================================================
// Multiple Attribute Tests
// ============================================================================

test "cloneNode() copies multiple attributes correctly" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.node.release();

    // Set multiple attributes
    try element.setAttribute("attr1", "value1");
    try element.setAttribute("attr2", "value2");
    try element.setAttribute("attr3", "value3");
    try element.setAttribute("data-id", "test-id");
    try element.setAttribute("data-name", "test-name");
    try element.setAttribute("flag", "");

    // Clone
    const copy_node = try element.node.cloneNode(false);
    defer copy_node.release();
    const copy: *Element = @fieldParentPtr("node", copy_node);

    // Verify all attributes copied
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("attr1").?, "value1"));
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("attr2").?, "value2"));
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("attr3").?, "value3"));
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("data-id").?, "test-id"));
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("data-name").?, "test-name"));
    try std.testing.expect(std.mem.eql(u8, copy.getAttribute("flag").?, ""));
}

test "cloneNode() empty attribute value preserved" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.node.release();
    try element.setAttribute("data-empty", "");

    // Clone
    const copy_node = try element.node.cloneNode(false);
    defer copy_node.release();
    const copy: *Element = @fieldParentPtr("node", copy_node);

    // Empty value should be preserved
    const val = copy.getAttribute("data-empty");
    try std.testing.expect(val != null);
    try std.testing.expectEqual(@as(usize, 0), val.?.len);
}

// ============================================================================
// Text and Comment Node Edge Cases
// ============================================================================

test "cloneNode() text node with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.node.release();

    const copy = try text.node.cloneNode(false);
    defer copy.release();

    const copy_text: *Text = @fieldParentPtr("node", copy);
    try std.testing.expectEqual(@as(usize, 0), copy_text.data.len);
}

test "cloneNode() text node with whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("  \n\t  ");
    defer text.node.release();

    const copy = try text.node.cloneNode(false);
    defer copy.release();

    const copy_text: *Text = @fieldParentPtr("node", copy);
    try std.testing.expect(std.mem.eql(u8, text.data, copy_text.data));
    try std.testing.expect(std.mem.eql(u8, "  \n\t  ", copy_text.data));
}

test "cloneNode() comment node with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.node.release();

    const copy = try comment.node.cloneNode(false);
    defer copy.release();

    const copy_comment: *Comment = @fieldParentPtr("node", copy);
    try std.testing.expectEqual(@as(usize, 0), copy_comment.data.len);
}

test "cloneNode() comment node with special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("TODO: fix <bug> & test");
    defer comment.node.release();

    const copy = try comment.node.cloneNode(false);
    defer copy.release();

    const copy_comment: *Comment = @fieldParentPtr("node", copy);
    try std.testing.expect(std.mem.eql(u8, comment.data, copy_comment.data));
    try std.testing.expect(std.mem.eql(u8, "TODO: fix <bug> & test", copy_comment.data));
}

// ============================================================================
// Element Tag Name Tests
// ============================================================================

test "cloneNode() preserves element tag names" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elements = [_][]const u8{
        "element",
        "container",
        "item",
        "node",
        "component",
        "widget",
        "panel",
        "view",
        "content",
        "wrapper",
    };

    for (elements) |tag| {
        const elem = try doc.createElement(tag);
        defer elem.node.release();

        const copy = try elem.node.cloneNode(false);
        defer copy.release();

        try std.testing.expect(std.mem.eql(u8, elem.node.nodeName(), copy.nodeName()));
        try std.testing.expect(std.mem.eql(u8, tag, copy.nodeName()));
    }
}

test "cloneNode() preserves custom element tag names" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const custom_elements = [_][]const u8{
        "my-component",
        "custom-widget",
        "x-panel",
        "data-table",
    };

    for (custom_elements) |tag| {
        const elem = try doc.createElement(tag);
        defer elem.node.release();

        const copy = try elem.node.cloneNode(false);
        defer copy.release();

        try std.testing.expect(std.mem.eql(u8, elem.node.nodeName(), copy.nodeName()));
        try std.testing.expect(std.mem.eql(u8, tag, copy.nodeName()));
    }
}

// ============================================================================
// Complex Tree Structure Tests
// ============================================================================

test "cloneNode() complex nested structure" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Build complex structure: root > (section > item > text, content > (block > text, block > text))
    const root = try doc.createElement("root");
    defer root.node.release();

    const section = try doc.createElement("section");
    const item = try doc.createElement("item");
    const title = try doc.createTextNode("Title text");
    _ = try item.node.appendChild(&title.node);
    _ = try section.node.appendChild(&item.node);
    _ = try root.node.appendChild(&section.node);

    const content = try doc.createElement("content");
    const block1 = try doc.createElement("block");
    const text1 = try doc.createTextNode("First block");
    _ = try block1.node.appendChild(&text1.node);
    _ = try content.node.appendChild(&block1.node);

    const block2 = try doc.createElement("block");
    const text2 = try doc.createTextNode("Second block");
    _ = try block2.node.appendChild(&text2.node);
    _ = try content.node.appendChild(&block2.node);
    _ = try root.node.appendChild(&content.node);

    // Deep clone
    const copy = try root.node.cloneNode(true);
    defer copy.release();

    // Verify structure preserved
    try std.testing.expect(copy.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), copy.childNodes().length());

    // Verify section
    const copy_section = copy.first_child.?;
    try std.testing.expectEqual(NodeType.element, copy_section.node_type);
    try std.testing.expect(copy_section != &section.node);

    // Verify content
    const copy_content = copy_section.next_sibling.?;
    try std.testing.expectEqual(NodeType.element, copy_content.node_type);
    try std.testing.expectEqual(@as(usize, 2), copy_content.childNodes().length());
}
