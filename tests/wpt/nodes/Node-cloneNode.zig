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
    defer element.prototype.release(); // Must release orphaned nodes
    const copy = try element.prototype.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&element.prototype != copy);

    // Should have same nodeType and nodeName
    try std.testing.expectEqual(element.prototype.node_type, copy.node_type);
    try std.testing.expect(std.mem.eql(u8, element.prototype.nodeName(), copy.nodeName()));
}

test "cloneNode() shallow copy does not clone children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const copy = try parent.prototype.cloneNode(false);
    defer copy.release();

    // Original has children
    try std.testing.expect(parent.prototype.hasChildNodes());

    // Copy should not have children
    try std.testing.expect(!copy.hasChildNodes());
}

test "cloneNode() deep copy clones children" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release(); // Must release orphaned nodes
    const child = try doc.createElement("child");
    const grandchild = try doc.createElement("grandchild");

    _ = try child.prototype.appendChild(&grandchild.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);

    const copy = try parent.prototype.cloneNode(true);
    defer copy.release();

    // Original has children
    try std.testing.expect(parent.prototype.hasChildNodes());

    // Copy should also have children
    try std.testing.expect(copy.hasChildNodes());

    // Copy should have same number of children (but different objects)
    try std.testing.expect(copy.first_child != null);
    try std.testing.expect(copy.first_child.? != parent.prototype.first_child.?);
}

test "cloneNode() copies attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.prototype.release(); // Must release orphaned nodes
    try element.setAttribute("id", "test");
    try element.setAttribute("class", "foo bar");

    const copy_node = try element.prototype.cloneNode(false);
    defer copy_node.release();

    // Get the Element from the cloned Node
    const copy: *Element = @fieldParentPtr("prototype", copy_node);

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
    defer text.prototype.release(); // Must release orphaned nodes
    const copy = try text.prototype.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&text.prototype != copy);

    // Should have same node type
    try std.testing.expectEqual(text.prototype.node_type, copy.node_type);

    // Should have same text content
    const copy_text: *Text = @fieldParentPtr("prototype", copy);
    try std.testing.expect(std.mem.eql(u8, text.data, copy_text.data));
}

test "cloneNode() comment node" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("test comment");
    defer comment.prototype.release(); // Must release orphaned nodes
    const copy = try comment.prototype.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&comment.prototype != copy);

    // Should have same node type
    try std.testing.expectEqual(comment.prototype.node_type, copy.node_type);

    // Should have same comment data
    const copy_comment: *Comment = @fieldParentPtr("prototype", copy);
    try std.testing.expect(std.mem.eql(u8, comment.data, copy_comment.data));
}

test "cloneNode() preserves owner document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.prototype.release(); // Must release orphaned nodes
    const copy = try element.prototype.cloneNode(false);
    defer copy.release();

    // Both should have same owner document
    try std.testing.expect(element.prototype.getOwnerDocument() == copy.getOwnerDocument());
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
    defer fragment.prototype.release();

    // Add children to original
    const element = try doc.createElement("element");
    _ = try fragment.prototype.appendChild(&element.prototype);

    // Shallow clone
    const copy = try fragment.prototype.cloneNode(false);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&fragment.prototype != copy);

    // Should have same nodeType
    try std.testing.expectEqual(fragment.prototype.node_type, copy.node_type);
    try std.testing.expectEqual(NodeType.document_fragment, copy.node_type);

    // Should have same nodeName
    try std.testing.expect(std.mem.eql(u8, fragment.prototype.nodeName(), copy.nodeName()));
    try std.testing.expect(std.mem.eql(u8, "#document-fragment", copy.nodeName()));

    // Original has children
    try std.testing.expect(fragment.prototype.hasChildNodes());

    // Copy should not have children (shallow)
    try std.testing.expect(!copy.hasChildNodes());
}

test "cloneNode() DocumentFragment deep copy" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    // Build tree structure
    const container = try doc.createElement("container");
    const item = try doc.createElement("item");
    const text = try doc.createTextNode("content");

    _ = try item.prototype.appendChild(&text.prototype);
    _ = try container.prototype.appendChild(&item.prototype);
    _ = try fragment.prototype.appendChild(&container.prototype);

    // Deep clone
    const copy = try fragment.prototype.cloneNode(true);
    defer copy.release();

    // Should be different objects
    try std.testing.expect(&fragment.prototype != copy);

    // Should have same nodeType
    try std.testing.expectEqual(NodeType.document_fragment, copy.node_type);

    // Both should have children
    try std.testing.expect(fragment.prototype.hasChildNodes());
    try std.testing.expect(copy.hasChildNodes());

    // Children should be different objects
    try std.testing.expect(copy.first_child != null);
    try std.testing.expect(copy.first_child.? != fragment.prototype.first_child.?);

    // Verify deep cloning (grandchildren cloned)
    const original_child = fragment.prototype.first_child.?;
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
    defer fragment.prototype.release();

    // Add different node types
    const elem = try doc.createElement("element");
    const text = try doc.createTextNode("text node");
    const comment = try doc.createComment("comment node");

    _ = try fragment.prototype.appendChild(&elem.prototype);
    _ = try fragment.prototype.appendChild(&text.prototype);
    _ = try fragment.prototype.appendChild(&comment.prototype);

    // Deep clone
    const copy = try fragment.prototype.cloneNode(true);
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
    defer level1.prototype.release();
    const level2 = try doc.createElement("level2");
    const level3 = try doc.createElement("level3");
    const text = try doc.createTextNode("deep content");

    _ = try level3.prototype.appendChild(&text.prototype);
    _ = try level2.prototype.appendChild(&level3.prototype);
    _ = try level1.prototype.appendChild(&level2.prototype);

    // Deep clone
    const copy = try level1.prototype.cloneNode(true);
    defer copy.release();

    // Verify all levels are different objects
    const orig_level2 = level1.prototype.first_child.?;
    const copy_level2 = copy.first_child.?;
    try std.testing.expect(orig_level2 != copy_level2);

    const orig_level3 = orig_level2.first_child.?;
    const copy_level3 = copy_level2.first_child.?;
    try std.testing.expect(orig_level3 != copy_level3);

    const orig_text = orig_level3.first_child.?;
    const copy_text = copy_level3.first_child.?;
    try std.testing.expect(orig_text != copy_text);

    // Verify text content preserved
    const orig_text_node: *Text = @fieldParentPtr("prototype", orig_text);
    const copy_text_node: *Text = @fieldParentPtr("prototype", copy_text);
    try std.testing.expect(std.mem.eql(u8, orig_text_node.data, copy_text_node.data));
}

test "cloneNode() deep copy preserves sibling relationships" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    // Add three siblings
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    const child3 = try doc.createElement("child3");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Deep clone
    const copy = try parent.prototype.cloneNode(true);
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
    defer original.prototype.release();
    try original.setAttribute("id", "original");

    // Clone
    const copy_node = try original.prototype.cloneNode(false);
    defer copy_node.release();
    const copy: *Element = @fieldParentPtr("prototype", copy_node);

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
    defer original.prototype.release();
    try original.setAttribute("data-test", "value");

    // Clone
    const copy_node = try original.prototype.cloneNode(false);
    defer copy_node.release();
    const copy: *Element = @fieldParentPtr("prototype", copy_node);

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
    defer original.prototype.release();

    // Shallow clone
    const copy = try original.prototype.cloneNode(false);
    defer copy.release();

    // Add children to original AFTER cloning
    const child1 = try doc.createElement("child1");
    const child2 = try doc.createElement("child2");
    _ = try original.prototype.appendChild(&child1.prototype);
    _ = try original.prototype.appendChild(&child2.prototype);

    // Original now has children
    try std.testing.expect(original.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), original.prototype.childNodes().length());

    // Clone should still have no children
    try std.testing.expect(!copy.hasChildNodes());
}

// ============================================================================
// Multiple Attribute Tests
// ============================================================================

test "setAttribute/getAttribute with 6 attributes (heap migration)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.prototype.release();

    // Set 6 attributes (should migrate to heap after 4th)
    try element.setAttribute("attr1", "value1");
    try element.setAttribute("attr2", "value2");
    try element.setAttribute("attr3", "value3");
    try element.setAttribute("data-id", "test-id");
    try element.setAttribute("data-name", "test-name");
    try element.setAttribute("flag", "");

    // Verify all can be retrieved
    try std.testing.expectEqualStrings("value1", element.getAttribute("attr1").?);
    try std.testing.expectEqualStrings("value2", element.getAttribute("attr2").?);
    try std.testing.expectEqualStrings("value3", element.getAttribute("attr3").?);
    try std.testing.expectEqualStrings("test-id", element.getAttribute("data-id").?);
    try std.testing.expectEqualStrings("test-name", element.getAttribute("data-name").?);
    try std.testing.expectEqualStrings("", element.getAttribute("flag").?);
}

test "cloneNode() copies multiple attributes correctly" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("element");
    defer element.prototype.release();

    // Set multiple attributes
    try element.setAttribute("attr1", "value1");
    try element.setAttribute("attr2", "value2");
    try element.setAttribute("attr3", "value3");
    try element.setAttribute("data-id", "test-id");
    try element.setAttribute("data-name", "test-name");
    try element.setAttribute("flag", "");

    // Clone
    const copy_node = try element.prototype.cloneNode(false);
    defer copy_node.release();
    const copy: *Element = @fieldParentPtr("prototype", copy_node);

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
    defer element.prototype.release();
    try element.setAttribute("data-empty", "");

    // Clone
    const copy_node = try element.prototype.cloneNode(false);
    defer copy_node.release();
    const copy: *Element = @fieldParentPtr("prototype", copy_node);

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
    defer text.prototype.release();

    const copy = try text.prototype.cloneNode(false);
    defer copy.release();

    const copy_text: *Text = @fieldParentPtr("prototype", copy);
    try std.testing.expectEqual(@as(usize, 0), copy_text.data.len);
}

test "cloneNode() text node with whitespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("  \n\t  ");
    defer text.prototype.release();

    const copy = try text.prototype.cloneNode(false);
    defer copy.release();

    const copy_text: *Text = @fieldParentPtr("prototype", copy);
    try std.testing.expect(std.mem.eql(u8, text.data, copy_text.data));
    try std.testing.expect(std.mem.eql(u8, "  \n\t  ", copy_text.data));
}

test "cloneNode() comment node with empty string" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.prototype.release();

    const copy = try comment.prototype.cloneNode(false);
    defer copy.release();

    const copy_comment: *Comment = @fieldParentPtr("prototype", copy);
    try std.testing.expectEqual(@as(usize, 0), copy_comment.data.len);
}

test "cloneNode() comment node with special characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("TODO: fix <bug> & test");
    defer comment.prototype.release();

    const copy = try comment.prototype.cloneNode(false);
    defer copy.release();

    const copy_comment: *Comment = @fieldParentPtr("prototype", copy);
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
        defer elem.prototype.release();

        const copy = try elem.prototype.cloneNode(false);
        defer copy.release();

        try std.testing.expect(std.mem.eql(u8, elem.prototype.nodeName(), copy.nodeName()));
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
        defer elem.prototype.release();

        const copy = try elem.prototype.cloneNode(false);
        defer copy.release();

        try std.testing.expect(std.mem.eql(u8, elem.prototype.nodeName(), copy.nodeName()));
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
    defer root.prototype.release();

    const section = try doc.createElement("section");
    const item = try doc.createElement("item");
    const title = try doc.createTextNode("Title text");
    _ = try item.prototype.appendChild(&title.prototype);
    _ = try section.prototype.appendChild(&item.prototype);
    _ = try root.prototype.appendChild(&section.prototype);

    const content = try doc.createElement("content");
    const block1 = try doc.createElement("block");
    const text1 = try doc.createTextNode("First block");
    _ = try block1.prototype.appendChild(&text1.prototype);
    _ = try content.prototype.appendChild(&block1.prototype);

    const block2 = try doc.createElement("block");
    const text2 = try doc.createTextNode("Second block");
    _ = try block2.prototype.appendChild(&text2.prototype);
    _ = try content.prototype.appendChild(&block2.prototype);
    _ = try root.prototype.appendChild(&content.prototype);

    // Deep clone
    const copy = try root.prototype.cloneNode(true);
    defer copy.release();

    // Verify structure preserved
    try std.testing.expect(copy.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), copy.childNodes().length());

    // Verify section
    const copy_section = copy.first_child.?;
    try std.testing.expectEqual(NodeType.element, copy_section.node_type);
    try std.testing.expect(copy_section != &section.prototype);

    // Verify content
    const copy_content = copy_section.next_sibling.?;
    try std.testing.expectEqual(NodeType.element, copy_content.node_type);
    try std.testing.expectEqual(@as(usize, 2), copy_content.childNodes().length());
}
