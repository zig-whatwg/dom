// META: title=TreeWalker: Basic test
// META: link=https://dom.spec.whatwg.org/#interface-treewalker

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Node = dom.Node;
const NodeType = dom.NodeType;
const TreeWalker = dom.TreeWalker;
const NodeFilter = dom.NodeFilter;

fn createSampleDOM(doc: *Document) !*Element {
    // Tree structure:
    //             #a
    //             |
    //        +----+----+
    //        |         |
    //       "b"        #c
    //                  |
    //             +----+----+
    //             |         |
    //            #d      <!--j-->
    //             |
    //        +----+----+
    //        |    |    |
    //       "e"  #f   "i"
    //             |
    //          +--+--+
    //          |     |
    //         "g" <!--h-->

    const a = try doc.createElement("a");
    try a.setAttribute("id", "a");

    const b = try doc.createTextNode("b");
    _ = try a.prototype.appendChild(&b.prototype);

    const c = try doc.createElement("c");
    try c.setAttribute("id", "c");
    _ = try a.prototype.appendChild(&c.prototype);

    const d = try doc.createElement("d");
    try d.setAttribute("id", "d");
    _ = try c.prototype.appendChild(&d.prototype);

    const e = try doc.createTextNode("e");
    _ = try d.prototype.appendChild(&e.prototype);

    const f = try doc.createElement("f");
    try f.setAttribute("id", "f");
    _ = try d.prototype.appendChild(&f.prototype);

    const g = try doc.createTextNode("g");
    _ = try f.prototype.appendChild(&g.prototype);

    const h = try doc.createComment("h");
    _ = try f.prototype.appendChild(&h.prototype);

    const i = try doc.createTextNode("i");
    _ = try d.prototype.appendChild(&i.prototype);

    const j = try doc.createComment("j");
    _ = try c.prototype.appendChild(&j.prototype);

    return a;
}

test "Construct a TreeWalker by document.createTreeWalker(root)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    defer root.prototype.release();

    const walker = try doc.createTreeWalker(&root.prototype, 0xFFFFFFFF, null);
    defer walker.deinit();

    try std.testing.expectEqual(&root.prototype, walker.root);
    try std.testing.expectEqual(0xFFFFFFFF, walker.what_to_show);
    try std.testing.expectEqual(@as(?NodeFilter, null), walker.node_filter);
    try std.testing.expectEqual(&root.prototype, walker.current_node);
}

test "Construct a TreeWalker with zero whatToShow" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    defer root.prototype.release();

    const walker = try doc.createTreeWalker(&root.prototype, 0, null);
    defer walker.deinit();

    try std.testing.expectEqual(&root.prototype, walker.root);
    try std.testing.expectEqual(0, walker.what_to_show);
    try std.testing.expectEqual(@as(?NodeFilter, null), walker.node_filter);
    try std.testing.expectEqual(&root.prototype, walker.current_node);
}

test "Construct a TreeWalker with specific whatToShow" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    defer root.prototype.release();

    const walker = try doc.createTreeWalker(&root.prototype, 42, null);
    defer walker.deinit();

    try std.testing.expectEqual(&root.prototype, walker.root);
    try std.testing.expectEqual(&root.prototype, walker.current_node);
    try std.testing.expectEqual(42, walker.what_to_show);
    try std.testing.expectEqual(@as(?NodeFilter, null), walker.node_filter);
}

test "Walk over nodes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createSampleDOM(doc);
    defer root.prototype.release();

    const walker = try doc.createTreeWalker(&root.prototype, 0xFFFFFFFF, null);
    defer walker.deinit();

    // Start at root
    const elem_a = root;
    try std.testing.expectEqual(&elem_a.prototype, walker.current_node);
    const attr_id = elem_a.getAttribute("id");
    try std.testing.expect(attr_id != null);
    try std.testing.expectEqualStrings("a", attr_id.?);

    // parentNode() should return null (at root)
    try std.testing.expectEqual(@as(?*Node, null), walker.parentNode());
    try std.testing.expectEqual(&elem_a.prototype, walker.current_node);

    // firstChild() -> text node "b"
    const text_b_node = walker.firstChild();
    try std.testing.expect(text_b_node != null);
    try std.testing.expectEqual(NodeType.text, text_b_node.?.node_type);
    const text_b: *Text = @fieldParentPtr("prototype", text_b_node.?);
    try std.testing.expectEqualStrings("b", text_b.data);
    try std.testing.expectEqual(text_b_node.?, walker.current_node);

    // nextSibling() -> element #c
    const elem_c_node = walker.nextSibling();
    try std.testing.expect(elem_c_node != null);
    try std.testing.expectEqual(NodeType.element, elem_c_node.?.node_type);
    const elem_c: *Element = @fieldParentPtr("prototype", elem_c_node.?);
    const c_id = elem_c.getAttribute("id");
    try std.testing.expect(c_id != null);
    try std.testing.expectEqualStrings("c", c_id.?);
    try std.testing.expectEqual(elem_c_node.?, walker.current_node);

    // lastChild() -> comment "j"
    const comment_j_node = walker.lastChild();
    try std.testing.expect(comment_j_node != null);
    try std.testing.expectEqual(NodeType.comment, comment_j_node.?.node_type);
    const comment_j: *Comment = @fieldParentPtr("prototype", comment_j_node.?);
    try std.testing.expectEqualStrings("j", comment_j.data);
    try std.testing.expectEqual(comment_j_node.?, walker.current_node);

    // previousSibling() -> element #d
    const elem_d_node = walker.previousSibling();
    try std.testing.expect(elem_d_node != null);
    try std.testing.expectEqual(NodeType.element, elem_d_node.?.node_type);
    const elem_d: *Element = @fieldParentPtr("prototype", elem_d_node.?);
    const d_id = elem_d.getAttribute("id");
    try std.testing.expect(d_id != null);
    try std.testing.expectEqualStrings("d", d_id.?);
    try std.testing.expectEqual(elem_d_node.?, walker.current_node);

    // nextNode() -> text "e"
    const text_e_node = walker.nextNode();
    try std.testing.expect(text_e_node != null);
    try std.testing.expectEqual(NodeType.text, text_e_node.?.node_type);
    const text_e: *Text = @fieldParentPtr("prototype", text_e_node.?);
    try std.testing.expectEqualStrings("e", text_e.data);
    try std.testing.expectEqual(text_e_node.?, walker.current_node);

    // parentNode() -> element #d
    const back_to_d = walker.parentNode();
    try std.testing.expect(back_to_d != null);
    try std.testing.expectEqual(elem_d_node.?, back_to_d.?);
    try std.testing.expectEqual(elem_d_node.?, walker.current_node);

    // previousNode() -> element #c
    const back_to_c = walker.previousNode();
    try std.testing.expect(back_to_c != null);
    try std.testing.expectEqual(elem_c_node.?, back_to_c.?);
    try std.testing.expectEqual(elem_c_node.?, walker.current_node);

    // nextSibling() should return null (no more siblings)
    try std.testing.expectEqual(@as(?*Node, null), walker.nextSibling());
    try std.testing.expectEqual(elem_c_node.?, walker.current_node);

    // Set currentNode to #f
    const elem_f_node = elem_d.prototype.first_child.?.next_sibling.?;
    try std.testing.expectEqual(NodeType.element, elem_f_node.node_type);
    const elem_f: *Element = @fieldParentPtr("prototype", elem_f_node);
    const f_id = elem_f.getAttribute("id");
    try std.testing.expect(f_id != null);
    try std.testing.expectEqualStrings("f", f_id.?);

    walker.current_node = elem_f_node;
    try std.testing.expectEqual(elem_f_node, walker.current_node);
}
