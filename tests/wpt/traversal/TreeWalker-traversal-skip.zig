// META: title=TreeWalker: traversal-skip
// META: link=https://dom.spec.whatwg.org/#interface-treewalker

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Node = dom.Node;
const TreeWalker = dom.TreeWalker;
const NodeFilter = dom.NodeFilter;
const FilterResult = dom.FilterResult;

// Tree structure:
// <root>
//   <A1>
//     <B1>
//       <C1/>
//     </B1>
//     <B2/>
//     <B3/>
//   </A1>
// </root>

fn createTestTree(doc: *Document) !*Element {
    const root = try doc.createElement("root");
    try root.setAttribute("id", "root");

    const a1 = try doc.createElement("A1");
    try a1.setAttribute("id", "A1");
    _ = try root.prototype.appendChild(&a1.prototype);

    const b1 = try doc.createElement("B1");
    try b1.setAttribute("id", "B1");
    _ = try a1.prototype.appendChild(&b1.prototype);

    const b2 = try doc.createElement("B2");
    try b2.setAttribute("id", "B2");
    _ = try a1.prototype.appendChild(&b2.prototype);

    const b3 = try doc.createElement("B3");
    try b3.setAttribute("id", "B3");
    _ = try a1.prototype.appendChild(&b3.prototype);

    const c1 = try doc.createElement("C1");
    try c1.setAttribute("id", "C1");
    _ = try b1.prototype.appendChild(&c1.prototype);

    return root;
}

fn skipB1Filter(node: *Node, _: ?*anyopaque) FilterResult {
    if (node.node_type == .element) {
        const elem: *Element = @fieldParentPtr("prototype", node);
        const id = elem.getAttribute("id");
        if (id != null and std.mem.eql(u8, id.?, "B1")) {
            return .skip;
        }
    }
    return .accept;
}

fn skipB2Filter(node: *Node, _: ?*anyopaque) FilterResult {
    if (node.node_type == .element) {
        const elem: *Element = @fieldParentPtr("prototype", node);
        const id = elem.getAttribute("id");
        if (id != null and std.mem.eql(u8, id.?, "B2")) {
            return .skip;
        }
    }
    return .accept;
}

test "TreeWalker skip: nextNode" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createTestTree(doc);
    defer root.prototype.release();

    const filter = NodeFilter{
        .callback = skipB1Filter,
        .context = null,
    };

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // nextNode() should find A1
    const a1 = walker.nextNode();
    try std.testing.expect(a1 != null);
    const a1_elem: *Element = @fieldParentPtr("prototype", a1.?);
    try std.testing.expectEqualStrings("A1", a1_elem.getAttribute("id").?);

    // nextNode() should skip B1 but continue to C1
    const c1 = walker.nextNode();
    try std.testing.expect(c1 != null);
    const c1_elem: *Element = @fieldParentPtr("prototype", c1.?);
    try std.testing.expectEqualStrings("C1", c1_elem.getAttribute("id").?);

    // nextNode() should find B2
    const b2 = walker.nextNode();
    try std.testing.expect(b2 != null);
    const b2_elem: *Element = @fieldParentPtr("prototype", b2.?);
    try std.testing.expectEqualStrings("B2", b2_elem.getAttribute("id").?);

    // nextNode() should find B3
    const b3 = walker.nextNode();
    try std.testing.expect(b3 != null);
    const b3_elem: *Element = @fieldParentPtr("prototype", b3.?);
    try std.testing.expectEqualStrings("B3", b3_elem.getAttribute("id").?);
}

test "TreeWalker skip: firstChild" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createTestTree(doc);
    defer root.prototype.release();

    const filter = NodeFilter{
        .callback = skipB1Filter,
        .context = null,
    };

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // firstChild() from root should find A1
    const a1 = walker.firstChild();
    try std.testing.expect(a1 != null);
    const a1_elem: *Element = @fieldParentPtr("prototype", a1.?);
    try std.testing.expectEqualStrings("A1", a1_elem.getAttribute("id").?);

    // firstChild() from A1 should skip B1 and find C1 (descendant)
    const c1 = walker.firstChild();
    try std.testing.expect(c1 != null);
    const c1_elem: *Element = @fieldParentPtr("prototype", c1.?);
    try std.testing.expectEqualStrings("C1", c1_elem.getAttribute("id").?);
}

test "TreeWalker skip: nextSibling" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createTestTree(doc);
    defer root.prototype.release();

    const filter = NodeFilter{
        .callback = skipB2Filter,
        .context = null,
    };

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // firstChild() from root should find A1
    const a1 = walker.firstChild();
    try std.testing.expect(a1 != null);
    const a1_elem: *Element = @fieldParentPtr("prototype", a1.?);
    try std.testing.expectEqualStrings("A1", a1_elem.getAttribute("id").?);

    // firstChild() from A1 should find B1
    const b1 = walker.firstChild();
    try std.testing.expect(b1 != null);
    const b1_elem: *Element = @fieldParentPtr("prototype", b1.?);
    try std.testing.expectEqualStrings("B1", b1_elem.getAttribute("id").?);

    // nextSibling() from B1 should skip B2 and find B3
    const b3 = walker.nextSibling();
    try std.testing.expect(b3 != null);
    const b3_elem: *Element = @fieldParentPtr("prototype", b3.?);
    try std.testing.expectEqualStrings("B3", b3_elem.getAttribute("id").?);
}

test "TreeWalker skip: parentNode" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createTestTree(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const filter = NodeFilter{
        .callback = skipB1Filter,
        .context = null,
    };

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // Find C1
    const c1_node = doc.getElementById("C1");
    try std.testing.expect(c1_node != null);

    // Set currentNode to C1
    walker.current_node = &c1_node.?.prototype;

    // parentNode() from C1 should skip B1 and find A1
    const a1 = walker.parentNode();
    try std.testing.expect(a1 != null);
    const a1_elem: *Element = @fieldParentPtr("prototype", a1.?);
    try std.testing.expectEqualStrings("A1", a1_elem.getAttribute("id").?);
}

test "TreeWalker skip: previousSibling" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createTestTree(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const filter = NodeFilter{
        .callback = skipB2Filter,
        .context = null,
    };

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // Find B3
    const b3_node = doc.getElementById("B3");
    try std.testing.expect(b3_node != null);

    // Set currentNode to B3
    walker.current_node = &b3_node.?.prototype;

    // previousSibling() from B3 should skip B2 and find B1
    const b1 = walker.previousSibling();
    try std.testing.expect(b1 != null);
    const b1_elem: *Element = @fieldParentPtr("prototype", b1.?);
    try std.testing.expectEqualStrings("B1", b1_elem.getAttribute("id").?);
}

test "TreeWalker skip: previousNode" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createTestTree(doc);
    _ = try doc.prototype.appendChild(&root.prototype);

    const filter = NodeFilter{
        .callback = skipB1Filter,
        .context = null,
    };

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // Find B3
    const b3_node = doc.getElementById("B3");
    try std.testing.expect(b3_node != null);

    // Set currentNode to B3
    walker.current_node = &b3_node.?.prototype;

    // previousNode() from B3 should find B2
    const b2 = walker.previousNode();
    try std.testing.expect(b2 != null);
    const b2_elem: *Element = @fieldParentPtr("prototype", b2.?);
    try std.testing.expectEqualStrings("B2", b2_elem.getAttribute("id").?);

    // previousNode() from B2 should skip B1 but find C1 (its child)
    const c1 = walker.previousNode();
    try std.testing.expect(c1 != null);
    const c1_elem: *Element = @fieldParentPtr("prototype", c1.?);
    try std.testing.expectEqualStrings("C1", c1_elem.getAttribute("id").?);

    // previousNode() from C1 should skip B1 and find A1
    const a1 = walker.previousNode();
    try std.testing.expect(a1 != null);
    const a1_elem: *Element = @fieldParentPtr("prototype", a1.?);
    try std.testing.expectEqualStrings("A1", a1_elem.getAttribute("id").?);
}
