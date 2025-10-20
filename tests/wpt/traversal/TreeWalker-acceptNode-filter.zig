// META: title=TreeWalker: acceptNode-filter
// META: link=https://dom.spec.whatwg.org/#callbackdef-nodefilter

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
//     <B1/>
//     <B2/>
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

test "TreeWalker with function filter" {
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

    // currentNode starts at root
    try std.testing.expectEqual(&root.prototype, walker.current_node);
    const root_id = root.getAttribute("id");
    try std.testing.expectEqualStrings("root", root_id.?);

    // firstChild() should find A1
    const a1 = walker.firstChild();
    try std.testing.expect(a1 != null);
    const a1_elem: *Element = @fieldParentPtr("prototype", a1.?);
    try std.testing.expectEqualStrings("A1", a1_elem.getAttribute("id").?);
    try std.testing.expectEqual(a1.?, walker.current_node);

    // nextNode() should skip B1 and find B2
    const b2 = walker.nextNode();
    try std.testing.expect(b2 != null);
    const b2_elem: *Element = @fieldParentPtr("prototype", b2.?);
    try std.testing.expectEqualStrings("B2", b2_elem.getAttribute("id").?);
    try std.testing.expectEqual(b2.?, walker.current_node);
}

test "TreeWalker with null filter" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createTestTree(doc);
    defer root.prototype.release();

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ELEMENT, null);
    defer walker.deinit();

    // currentNode starts at root
    try std.testing.expectEqual(&root.prototype, walker.current_node);
    const root_id = root.getAttribute("id");
    try std.testing.expectEqualStrings("root", root_id.?);

    // firstChild() should find A1
    const a1 = walker.firstChild();
    try std.testing.expect(a1 != null);
    const a1_elem: *Element = @fieldParentPtr("prototype", a1.?);
    try std.testing.expectEqualStrings("A1", a1_elem.getAttribute("id").?);
    try std.testing.expectEqual(a1.?, walker.current_node);

    // nextNode() should find B1 (no filtering)
    const b1 = walker.nextNode();
    try std.testing.expect(b1 != null);
    const b1_elem: *Element = @fieldParentPtr("prototype", b1.?);
    try std.testing.expectEqualStrings("B1", b1_elem.getAttribute("id").?);
    try std.testing.expectEqual(b1.?, walker.current_node);
}

test "TreeWalker filter receives correct node argument" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try createTestTree(doc);
    defer root.prototype.release();

    const Context = struct {
        last_checked_id: ?[]const u8 = null,
    };

    var ctx = Context{};

    const checkingFilter = struct {
        fn filter(node: *Node, context: ?*anyopaque) FilterResult {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);
                const id = elem.getAttribute("id");
                if (id != null) {
                    const c: *Context = @ptrCast(@alignCast(context.?));
                    c.last_checked_id = id.?;
                }
                if (id != null and std.mem.eql(u8, id.?, "B1")) {
                    return .skip;
                }
            }
            return .accept;
        }
    }.filter;

    const filter = NodeFilter{
        .callback = checkingFilter,
        .context = &ctx,
    };

    const walker = try doc.createTreeWalker(&root.prototype, NodeFilter.SHOW_ELEMENT, filter);
    defer walker.deinit();

    // nextNode() should call filter with A1
    const a1 = walker.nextNode();
    try std.testing.expect(a1 != null);
    try std.testing.expectEqualStrings("A1", ctx.last_checked_id.?);
}
