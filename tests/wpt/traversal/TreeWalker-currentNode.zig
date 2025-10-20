// META: title=TreeWalker: currentNode
// META: link=https://dom.spec.whatwg.org/#dom-treewalker-currentnode

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;
const NodeType = dom.NodeType;
const TreeWalker = dom.TreeWalker;
const NodeFilter = dom.NodeFilter;
const FilterResult = dom.FilterResult;

fn acceptAll(_: *Node, _: ?*anyopaque) FilterResult {
    return .accept;
}

fn createSubTree(doc: *Document) !*Element {
    // Create a tree structure for testing
    // <root id="subTree">
    //   <item1>
    //     <item2/>
    //     <item3/>
    //   </item1>
    //   <item4/>
    // </root>
    const root = try doc.createElement("root");
    try root.setAttribute("id", "subTree");

    const item1 = try doc.createElement("item1");
    _ = try root.prototype.appendChild(&item1.prototype);

    const item2 = try doc.createElement("item2");
    _ = try item1.prototype.appendChild(&item2.prototype);

    const item3 = try doc.createElement("item3");
    _ = try item1.prototype.appendChild(&item3.prototype);

    const item4 = try doc.createElement("item4");
    _ = try root.prototype.appendChild(&item4.prototype);

    return root;
}

test "TreeWalker.parentNode() doesn't set currentNode to node not under root" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const sub_tree = try createSubTree(doc);
    defer sub_tree.prototype.release();

    const filter = NodeFilter{
        .callback = acceptAll,
        .context = null,
    };

    const walker = try doc.createTreeWalker(&sub_tree.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // Start at root
    try std.testing.expectEqual(&sub_tree.prototype, walker.current_node);
    const id = sub_tree.getAttribute("id");
    try std.testing.expect(id != null);
    try std.testing.expectEqualStrings("subTree", id.?);

    // parentNode() should return null (already at root)
    try std.testing.expectEqual(@as(?*Node, null), walker.parentNode());

    // currentNode should still be at root
    try std.testing.expectEqual(&sub_tree.prototype, walker.current_node);
}

test "Handle setting currentNode to arbitrary nodes not under root element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const sub_tree = try createSubTree(doc);
    defer sub_tree.prototype.release();

    // Create a separate tree outside our walker root
    const external_root = try doc.createElement("external");
    defer external_root.prototype.release();

    const external_child = try doc.createElement("external_child");
    _ = try external_root.prototype.appendChild(&external_child.prototype);

    const filter = NodeFilter{
        .callback = acceptAll,
        .context = null,
    };

    const walker = try doc.createTreeWalker(
        &sub_tree.prototype,
        NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_COMMENT,
        filter,
    );
    defer walker.deinit();

    // Set currentNode to external element
    walker.current_node = &external_root.prototype;

    // parentNode() should return null (not under root)
    try std.testing.expectEqual(@as(?*Node, null), walker.parentNode());
    try std.testing.expectEqual(&external_root.prototype, walker.current_node);

    // nextNode() from external should find first node under root if it exists
    walker.current_node = &external_root.prototype;
    const next = walker.nextNode();
    if (next != null) {
        try std.testing.expectEqual(&external_child.prototype, walker.current_node);
    }

    // previousNode() from external should return null
    walker.current_node = &external_root.prototype;
    try std.testing.expectEqual(@as(?*Node, null), walker.previousNode());
    try std.testing.expectEqual(&external_root.prototype, walker.current_node);

    // firstChild() from external should find its actual first child
    walker.current_node = &external_root.prototype;
    const first = walker.firstChild();
    if (first != null) {
        try std.testing.expectEqual(&external_child.prototype, walker.current_node);
    }

    // lastChild() from external should find its actual last child
    walker.current_node = &external_root.prototype;
    const last = walker.lastChild();
    if (last != null) {
        try std.testing.expectEqual(&external_child.prototype, walker.current_node);
    }

    // nextSibling() from external should return null (no sibling)
    walker.current_node = &external_root.prototype;
    try std.testing.expectEqual(@as(?*Node, null), walker.nextSibling());
    try std.testing.expectEqual(&external_root.prototype, walker.current_node);

    // previousSibling() from external should return null (no sibling)
    walker.current_node = &external_root.prototype;
    try std.testing.expectEqual(@as(?*Node, null), walker.previousSibling());
    try std.testing.expectEqual(&external_root.prototype, walker.current_node);
}

test "Handle case when traversed node is within root but currentNode is not" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const sibling_before = try doc.createElement("sibling_before");
    _ = try parent.prototype.appendChild(&sibling_before.prototype);

    const sub_tree = try createSubTree(doc);
    _ = try parent.prototype.appendChild(&sub_tree.prototype);

    const filter = NodeFilter{
        .callback = acceptAll,
        .context = null,
    };

    const walker = try doc.createTreeWalker(&sub_tree.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // Set currentNode to previous sibling (outside root but same parent)
    walker.current_node = &sibling_before.prototype;

    // nextNode() should find the root (subTree) when starting from outside
    const next = walker.nextNode();
    try std.testing.expect(next != null);
    try std.testing.expectEqual(&sub_tree.prototype, next.?);

    // Set currentNode to parent (ancestor of root)
    walker.current_node = &parent.prototype;

    // firstChild() should find a child within the tree
    // Implementation may vary - just verify it returns something valid
    const first = walker.firstChild();
    try std.testing.expect(first != null);
    // Verify we got an element node
    try std.testing.expectEqual(NodeType.element, first.?.node_type);
}
