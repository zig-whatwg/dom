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
const Event = dom.Event;

test "Node - size constraint" {
    const size = @sizeOf(Node);
    try std.testing.expect(size <= 104); // Node now includes EventTarget prototype (8 bytes)

    // Print actual size for documentation
    std.debug.print("\nNode size: {d} bytes (target: ≤104 with EventTarget)\n", .{size});
}

test "Node - packed ref_count and has_parent" {
    // Verify bit packing works correctly
    const node_with_ref_1_no_parent: u32 = 1;
    const node_with_ref_1_has_parent: u32 = 1 | Node.HAS_PARENT_BIT;
    const node_with_ref_100_no_parent: u32 = 100;

    // Extract ref_count
    try std.testing.expectEqual(@as(u32, 1), node_with_ref_1_no_parent & Node.REF_COUNT_MASK);
    try std.testing.expectEqual(@as(u32, 1), node_with_ref_1_has_parent & Node.REF_COUNT_MASK);
    try std.testing.expectEqual(@as(u32, 100), node_with_ref_100_no_parent & Node.REF_COUNT_MASK);

    // Extract has_parent
    try std.testing.expect((node_with_ref_1_no_parent & Node.HAS_PARENT_BIT) == 0);
    try std.testing.expect((node_with_ref_1_has_parent & Node.HAS_PARENT_BIT) != 0);
}

test "Node - ref counting basic operations" {
    const allocator = std.testing.allocator;

    // Minimal vtable for testing
    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initial ref_count should be 1
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());
    try std.testing.expect(!node.hasParent());

    // Acquire increments ref_count
    node.acquire();
    try std.testing.expectEqual(@as(u32, 2), node.getRefCount());

    // Release decrements ref_count
    node.release();
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());

    // Final release happens in defer
}

test "Node - has_parent flag operations" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially has no parent
    try std.testing.expect(!node.hasParent());

    // Set has_parent flag
    node.setHasParent(true);
    try std.testing.expect(node.hasParent());
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount()); // ref_count unchanged

    // Clear has_parent flag
    node.setHasParent(false);
    try std.testing.expect(!node.hasParent());
    try std.testing.expectEqual(@as(u32, 1), node.getRefCount());
}

test "Node - memory leak test" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    // Test 1: Simple create and release
    {
        const node = try Node.init(allocator, &test_vtable, .element);
        defer node.release();
    }

    // Test 2: Multiple acquire/release
    {
        const node = try Node.init(allocator, &test_vtable, .element);
        defer node.release();

        node.acquire();
        defer node.release();

        node.acquire();
        defer node.release();
    }

    // If we get here without leaks, std.testing.allocator validates success
}

test "Node - flag operations" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially not connected
    try std.testing.expect(!node.isConnected());

    // Set connected flag
    node.setConnected(true);
    try std.testing.expect(node.isConnected());

    // Clear connected flag
    node.setConnected(false);
    try std.testing.expect(!node.isConnected());

    // Check shadow tree flag
    try std.testing.expect(!node.isInShadowTree());
}

test "Node - vtable dispatch" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "custom-name";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return "custom-value";
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Test vtable dispatch
    try std.testing.expectEqualStrings("custom-name", node.nodeName());
    try std.testing.expectEqualStrings("custom-value", node.nodeValue().?);

    // Test error returns
    try std.testing.expectError(error.NotSupported, node.setNodeValue("value"));
    try std.testing.expectError(error.NotSupported, node.cloneNode(false));
}

test "Node - rare data allocation" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially no rare data
    try std.testing.expect(!node.hasRareData());
    try std.testing.expect(node.getRareData() == null);

    // Ensure rare data
    const rare = try node.ensureRareData();
    try std.testing.expect(node.hasRareData());
    try std.testing.expect(node.getRareData() != null);
    try std.testing.expectEqual(rare, node.getRareData().?);

    // Second call returns same instance
    const rare2 = try node.ensureRareData();
    try std.testing.expectEqual(rare, rare2);
}

test "Node - rare data cleanup" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Allocate rare data and add features
    const rare = try node.ensureRareData();

    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, _: *anyopaque) void {}
    }.cb;

    try rare.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try rare.setUserData("key", @ptrCast(&ctx));

    // Cleanup happens in defer node.release()
    // If this test passes without leaks, cleanup worked
}

test "Node - addEventListener wrapper" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, _: *anyopaque) void {}
    }.cb;

    // Test WHATWG-style API
    try node.addEventListener("click", callback, @ptrCast(&ctx), false, false, false, null);

    // Verify listener was added
    try std.testing.expect(node.hasEventListeners("click"));
    try std.testing.expect(!node.hasEventListeners("input"));

    const listeners = node.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 1), listeners.len);

    // Remove listener
    node.removeEventListener("click", callback, false);
    try std.testing.expect(!node.hasEventListeners("click"));
}

test "Node - hasChildNodes" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const node = try Node.init(allocator, &test_vtable, .element);
    defer node.release();

    // Initially no children
    try std.testing.expect(!node.hasChildNodes());

    // Create a child (but don't connect yet - that's Phase 2)
    const child = try Node.init(allocator, &test_vtable, .element);
    defer child.release();

    // Manually set first_child for testing
    node.first_child = child;
    try std.testing.expect(node.hasChildNodes());

    // Clean up manual connection
    node.first_child = null;
}

test "Node - parentElement" {
    const allocator = std.testing.allocator;

    // Create parent element
    const parent_elem = try Element.create(allocator, "div");
    defer parent_elem.prototype.release();

    // Create child text node
    const child = try Text.create(allocator, "content");
    defer child.prototype.release();

    // Initially no parent
    try std.testing.expect(child.prototype.parentElement() == null);

    // Manually set parent for testing (Phase 2 will do this via appendChild)
    child.prototype.parent_node = &parent_elem.prototype;

    // parentElement should return the element
    const retrieved_parent = child.prototype.parentElement();
    try std.testing.expect(retrieved_parent != null);
    try std.testing.expectEqual(parent_elem, retrieved_parent.?);

    // Clean up manual connection
    child.prototype.parent_node = null;
}

test "Node - getOwnerDocument" {
    const allocator = std.testing.allocator;

    // Create document
    const doc = try Document.init(allocator);
    defer doc.release();

    // Document's ownerDocument should be null per spec
    try std.testing.expect(doc.prototype.getOwnerDocument() == null);

    // Create element via document
    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Element's ownerDocument should be the document
    const owner = elem.prototype.getOwnerDocument();
    try std.testing.expect(owner != null);
    try std.testing.expectEqual(doc, owner.?);

    // Create text node via document
    const text = try doc.createTextNode("test");
    defer text.prototype.release();

    // Text's ownerDocument should also be the document
    const text_owner = text.prototype.getOwnerDocument();
    try std.testing.expect(text_owner != null);
    try std.testing.expectEqual(doc, text_owner.?);
}

test "Node - childNodes" {
    const allocator = std.testing.allocator;

    const test_vtable = NodeVTable{
        .deinit = struct {
            fn deinit(node: *Node) void {
                node.deinitRareData();
                node.allocator.destroy(node);
            }
        }.deinit,
        .node_name = struct {
            fn name(_: *const Node) []const u8 {
                return "test";
            }
        }.name,
        .node_value = struct {
            fn value(_: *const Node) ?[]const u8 {
                return null;
            }
        }.value,
        .set_node_value = struct {
            fn setValue(_: *Node, _: []const u8) !void {
                return error.NotSupported;
            }
        }.setValue,
        .clone_node = struct {
            fn clone(_: *const Node, _: bool) !*Node {
                return error.NotSupported;
            }
        }.clone,
        .adopting_steps = struct {
            fn adoptingSteps(_: *Node, _: ?*Node) !void {}
        }.adoptingSteps,
    };

    const parent = try Node.init(allocator, &test_vtable, .element);
    defer parent.release();

    // Initially no children
    const empty_list = parent.childNodes();
    try std.testing.expectEqual(@as(usize, 0), empty_list.length());

    // Add a child manually (Phase 2 will do this via appendChild)
    const child1 = try Node.init(allocator, &test_vtable, .element);
    defer child1.release();

    const child2 = try Node.init(allocator, &test_vtable, .element);
    defer child2.release();

    parent.first_child = child1;
    parent.last_child = child2;
    child1.next_sibling = child2;
    child1.parent_node = parent;
    child2.parent_node = parent;

    // NodeList should reflect children
    const list = parent.childNodes();
    try std.testing.expectEqual(@as(usize, 2), list.length());
    try std.testing.expectEqual(child1, list.item(0).?);
    try std.testing.expectEqual(child2, list.item(1).?);
    try std.testing.expect(list.item(2) == null);

    // Clean up manual connections
    parent.first_child = null;
    parent.last_child = null;
    child1.next_sibling = null;
    child1.parent_node = null;
    child2.parent_node = null;
}

test "Node.appendChild - adds child successfully" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child = try doc.createElement("item");
    // NO defer - parent will own it

    _ = try parent.prototype.appendChild(&child.prototype);

    // Verify parent-child relationship
    try std.testing.expectEqual(&parent.prototype, child.prototype.parent_node);
    try std.testing.expectEqual(&child.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&child.prototype, parent.prototype.last_child);
    try std.testing.expect(child.prototype.hasParent());
}

test "Node.appendChild - adds multiple children in order" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    const child3 = try doc.createElement("strong");
    // NO defers - parent owns them

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Verify order
    try std.testing.expectEqual(&child1.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&child3.prototype, parent.prototype.last_child);
    try std.testing.expectEqual(&child2.prototype, child1.prototype.next_sibling);
    try std.testing.expectEqual(&child3.prototype, child2.prototype.next_sibling);
}

test "Node.appendChild - moves node from old parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("element");
    defer parent1.prototype.release();

    const parent2 = try doc.createElement("section");
    defer parent2.prototype.release();

    const child = try doc.createElement("item");
    // NO defer - will be owned by one of the parents

    // Add to parent1
    _ = try parent1.prototype.appendChild(&child.prototype);
    try std.testing.expectEqual(&parent1.prototype, child.prototype.parent_node);

    // Move to parent2
    _ = try parent2.prototype.appendChild(&child.prototype);
    try std.testing.expectEqual(&parent2.prototype, child.prototype.parent_node);
    try std.testing.expect(parent1.prototype.first_child == null);
}

test "Node.appendChild - rejects text node under document" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release(); // NOT added to parent, so we own it

    // Should fail - text cannot be child of document
    try std.testing.expectError(
        error.HierarchyRequestError,
        doc.prototype.appendChild(&text.prototype),
    );
}

test "Node.insertBefore - inserts at beginning" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    // NO defers - parent owns them

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.insertBefore(&child2.prototype, &child1.prototype);

    // child2 should be first
    try std.testing.expectEqual(&child2.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&child1.prototype, child2.prototype.next_sibling);
}

test "Node.insertBefore - inserts in middle" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    const child3 = try doc.createElement("strong");
    // NO defers - parent owns them

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);
    _ = try parent.prototype.insertBefore(&child2.prototype, &child3.prototype);

    // Order should be: child1, child2, child3
    try std.testing.expectEqual(&child1.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&child2.prototype, child1.prototype.next_sibling);
    try std.testing.expectEqual(&child3.prototype, child2.prototype.next_sibling);
}

test "Node.insertBefore - with null child appends" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    // NO defers - parent owns them

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.insertBefore(&child2.prototype, null);

    // child2 should be last
    try std.testing.expectEqual(&child2.prototype, parent.prototype.last_child);
}

test "Node.insertBefore - rejects if child not in parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const other = try doc.createElement("section");
    defer other.prototype.release();

    const child = try doc.createElement("item");
    // child will be owned by other, NOT parent

    const new_child = try doc.createElement("text-block");
    defer new_child.prototype.release(); // Will NOT be added

    _ = try other.prototype.appendChild(&child.prototype);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.prototype.insertBefore(&new_child.prototype, &child.prototype),
    );
}

test "Node.removeChild - removes child successfully" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child = try doc.createElement("item");
    defer child.prototype.release(); // Released AFTER removal

    _ = try parent.prototype.appendChild(&child.prototype);
    const removed = try parent.prototype.removeChild(&child.prototype);

    try std.testing.expectEqual(&child.prototype, removed);
    try std.testing.expect(child.prototype.parent_node == null);
    try std.testing.expect(!child.prototype.hasParent());
}

test "Node.removeChild - removes middle child" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    defer child2.prototype.release(); // Released AFTER removal
    const child3 = try doc.createElement("strong");
    // child1 and child3 owned by parent

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    _ = try parent.prototype.removeChild(&child2.prototype);

    // child1 and child3 should be linked
    try std.testing.expectEqual(&child3.prototype, child1.prototype.next_sibling);
    try std.testing.expect(child2.prototype.parent_node == null);
}

test "Node.removeChild - rejects if not parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const other = try doc.createElement("section");
    defer other.prototype.release();

    const child = try doc.createElement("item");
    // child owned by other

    _ = try other.prototype.appendChild(&child.prototype);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.prototype.removeChild(&child.prototype),
    );
}

test "Node.replaceChild - replaces child successfully" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const old_child = try doc.createElement("item");
    defer old_child.prototype.release(); // Released AFTER removal

    const new_child = try doc.createElement("text-block");
    // new_child owned by parent after replacement

    _ = try parent.prototype.appendChild(&old_child.prototype);
    const removed = try parent.prototype.replaceChild(&new_child.prototype, &old_child.prototype);

    try std.testing.expectEqual(&old_child.prototype, removed);
    try std.testing.expectEqual(&new_child.prototype, parent.prototype.first_child);
    try std.testing.expect(old_child.prototype.parent_node == null);
}

test "Node.replaceChild - preserves sibling order" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const child1 = try doc.createElement("item");
    const child2 = try doc.createElement("text-block");
    defer child2.prototype.release(); // Released AFTER replacement
    const child3 = try doc.createElement("strong");
    const new_child = try doc.createElement("em");
    // child1, new_child, child3 owned by parent

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    _ = try parent.prototype.replaceChild(&new_child.prototype, &child2.prototype);

    // Order should be: child1, new_child, child3
    try std.testing.expectEqual(&child1.prototype, parent.prototype.first_child);
    try std.testing.expectEqual(&new_child.prototype, child1.prototype.next_sibling);
    try std.testing.expectEqual(&child3.prototype, new_child.prototype.next_sibling);
}

test "Node.replaceChild - rejects if child not in parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("element");
    defer parent.prototype.release();

    const other = try doc.createElement("section");
    defer other.prototype.release();

    const child = try doc.createElement("item");
    // child owned by other

    const new_child = try doc.createElement("text-block");
    defer new_child.prototype.release(); // NOT added

    _ = try other.prototype.appendChild(&child.prototype);

    // Should fail - child is not a child of parent
    try std.testing.expectError(
        error.NotFoundError,
        parent.prototype.replaceChild(&new_child.prototype, &child.prototype),
    );
}

test "Node.appendChild - propagates connected state" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    // root owned by doc after appendChild

    const child = try doc.createElement("container");
    const grandchild = try doc.createElement("element");
    // child and grandchild owned by tree

    // Build tree
    _ = try child.prototype.appendChild(&grandchild.prototype);
    _ = try root.prototype.appendChild(&child.prototype);

    // Connect root to document (document is always connected)
    _ = try doc.prototype.appendChild(&root.prototype);

    // Should propagate to child and grandchild
    try std.testing.expect(root.prototype.isConnected());
    try std.testing.expect(child.prototype.isConnected());
    try std.testing.expect(grandchild.prototype.isConnected());
}

test "Node.removeChild - propagates disconnected state" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    // root owned by doc

    const child = try doc.createElement("container");
    defer child.prototype.release(); // Released AFTER removal

    const grandchild = try doc.createElement("element");
    // grandchild owned by child

    // Build connected tree
    _ = try child.prototype.appendChild(&grandchild.prototype);
    _ = try root.prototype.appendChild(&child.prototype);
    _ = try doc.prototype.appendChild(&root.prototype);

    // All should be connected
    try std.testing.expect(root.prototype.isConnected());
    try std.testing.expect(child.prototype.isConnected());
    try std.testing.expect(grandchild.prototype.isConnected());

    // Remove child
    _ = try root.prototype.removeChild(&child.prototype);

    // root still connected, child and grandchild disconnected
    try std.testing.expect(root.prototype.isConnected());
    try std.testing.expect(!child.prototype.isConnected());
    try std.testing.expect(!grandchild.prototype.isConnected());
}

test "Node.textContent - getter returns null for Document" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const content = try doc.prototype.textContent(allocator);
    try std.testing.expect(content == null);
}

test "Node.textContent - getter returns text node data" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello, World!");
    defer text.prototype.release();

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello, World!", content.?);
}

test "Node.textContent - getter returns comment data" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("This is a comment");
    defer comment.prototype.release();

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("This is a comment", content.?);
}

test "Node.textContent - getter collects descendant text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const text1 = try doc.createTextNode("Hello ");
    const text2 = try doc.createTextNode("World");
    const text3 = try doc.createTextNode("!");

    _ = try div.prototype.appendChild(&text1.prototype);
    _ = try div.prototype.appendChild(&text2.prototype);
    _ = try div.prototype.appendChild(&text3.prototype);

    const content = try div.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello World!", content.?);
}

test "Node.textContent - getter collects nested text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const span = try doc.createElement("span");
    const text1 = try doc.createTextNode("Hello ");
    const text2 = try doc.createTextNode("World");

    _ = try span.prototype.appendChild(&text1.prototype);
    _ = try div.prototype.appendChild(&span.prototype);
    _ = try div.prototype.appendChild(&text2.prototype);

    const content = try div.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("Hello World", content.?);
}

test "Node.textContent - getter returns empty string for empty element" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const content = try div.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    // Per WPT tests, empty elements return empty string, not null
    try std.testing.expect(content != null);
    try std.testing.expectEqualStrings("", content.?);
}

test "Node.textContent - setter does nothing for Document" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Should not error, but does nothing
    try doc.prototype.setTextContent("This should be ignored");

    const content = try doc.prototype.textContent(allocator);
    try std.testing.expect(content == null);
}

test "Node.textContent - setter replaces text node data" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Old text");
    defer text.prototype.release();

    try text.prototype.setTextContent("New text");

    const content = try text.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New text", content.?);
}

test "Node.textContent - setter replaces comment data" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("Old comment");
    defer comment.prototype.release();

    try comment.prototype.setTextContent("New comment");

    const content = try comment.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New comment", content.?);
}

test "Node.textContent - setter removes all children and inserts text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    // Add some children (owned by tree, no defer needed)
    const span = try doc.createElement("span");
    const text1 = try doc.createTextNode("Old");

    _ = try span.prototype.appendChild(&text1.prototype);
    _ = try div.prototype.appendChild(&span.prototype);

    // Set text content - should remove all children (releasing span and text1)
    try div.prototype.setTextContent("New text");

    // Should have exactly one child (text node)
    try std.testing.expect(div.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 1), div.prototype.childNodes().length());
    try std.testing.expectEqual(NodeType.text, div.prototype.first_child.?.node_type);

    const content = try div.prototype.textContent(allocator);
    defer if (content) |c| allocator.free(c);

    try std.testing.expectEqualStrings("New text", content.?);
}

test "Node.textContent - setter with empty string removes all children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const text = try doc.createTextNode("Some text");
    // text owned by div after appendChild
    _ = try div.prototype.appendChild(&text.prototype);

    try std.testing.expect(div.prototype.hasChildNodes());

    // Set to empty string - should remove all children (releasing text)
    try div.prototype.setTextContent("");

    try std.testing.expect(!div.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(?*Node, null), div.prototype.first_child);
}

test "Node.textContent - setter with null removes all children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    const text = try doc.createTextNode("Some text");
    // text owned by div after appendChild
    _ = try div.prototype.appendChild(&text.prototype);

    try std.testing.expect(div.prototype.hasChildNodes());

    // Set to null - should remove all children (releasing text)
    try div.prototype.setTextContent(null);

    try std.testing.expect(!div.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(?*Node, null), div.prototype.first_child);
}

test "Node.textContent - setter propagates connected state" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    // root owned by document after appendChild, no defer needed

    // Connect to document
    _ = try doc.prototype.appendChild(&root.prototype);

    // Set text content
    try root.prototype.setTextContent("Connected text");

    // New text node should be connected
    try std.testing.expect(root.prototype.first_child != null);
    try std.testing.expect(root.prototype.first_child.?.isConnected());
}

test "Node.textContent - no memory leaks" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.prototype.release();

    // Set multiple times
    try div.prototype.setTextContent("First");
    try div.prototype.setTextContent("Second");
    try div.prototype.setTextContent("Third");
    try div.prototype.setTextContent(null);

    // Get multiple times
    for (0..10) |_| {
        const content = try div.prototype.textContent(allocator);
        if (content) |c| allocator.free(c);
    }

    // Test passes if no leaks detected by testing allocator
}

test "Node.isSameNode - returns true for same node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.isSameNode(&elem.prototype));
}

test "Node.isSameNode - returns false for different nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("div");
    defer elem2.prototype.release();

    try std.testing.expect(!elem1.prototype.isSameNode(&elem2.prototype));
}

test "Node.isSameNode - returns false for null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.isSameNode(null));
}

test "Node.getRootNode - returns document for connected node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);
    _ = try doc.prototype.appendChild(&parent.prototype);

    const root = child.prototype.getRootNode(false);
    try std.testing.expect(root == &doc.prototype);
}

test "Node.getRootNode - returns self for disconnected single node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const root = elem.prototype.getRootNode(false);
    try std.testing.expect(root == &elem.prototype);
}

test "Node.getRootNode - returns topmost disconnected node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    // Not connected to document
    const root = child.prototype.getRootNode(false);
    try std.testing.expect(root == &parent.prototype);
}

test "Node.getRootNode - composed parameter (no shadow DOM yet)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");

    _ = try doc.prototype.appendChild(&elem.prototype);

    // Both should return same result (no shadow DOM)
    const root1 = elem.prototype.getRootNode(false);
    const root2 = elem.prototype.getRootNode(true);

    try std.testing.expect(root1 == root2);
    try std.testing.expect(root1 == &doc.prototype);
}

test "Node.contains - returns true for self (inclusive)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.contains(&elem.prototype));
}

test "Node.contains - returns true for direct child" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(parent.prototype.contains(&child.prototype));
}

test "Node.contains - returns true for deep descendant" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const grandparent = try doc.createElement("div");
    defer grandparent.prototype.release();

    const parent = try doc.createElement("section");
    const child = try doc.createElement("span");

    _ = try grandparent.prototype.appendChild(&parent.prototype);
    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(grandparent.prototype.contains(&child.prototype));
}

test "Node.contains - returns false for parent (not ancestor of child)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    try std.testing.expect(!child.prototype.contains(&parent.prototype));
}

test "Node.contains - returns false for sibling" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    try std.testing.expect(!child1.prototype.contains(&child2.prototype));
    try std.testing.expect(!child2.prototype.contains(&child1.prototype));
}

test "Node.contains - returns false for null (per spec)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.contains(null));
}

test "Node.baseURI - returns empty string (placeholder)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const uri = elem.prototype.baseURI();
    try std.testing.expectEqualStrings("", uri);
}

test "Node.compareDocumentPosition - returns 0 for same node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    const pos = elem.prototype.compareDocumentPosition(&elem.prototype);
    try std.testing.expectEqual(@as(u16, 0), pos);
}

test "Node.compareDocumentPosition - disconnected nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("span");
    defer elem2.prototype.release();

    const pos = elem1.prototype.compareDocumentPosition(&elem2.prototype);

    // Must have DISCONNECTED flag
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_DISCONNECTED) != 0);
    // Must have IMPLEMENTATION_SPECIFIC flag
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC) != 0);
    // Must have either PRECEDING or FOLLOWING
    try std.testing.expect((pos & (Node.DOCUMENT_POSITION_PRECEDING | Node.DOCUMENT_POSITION_FOLLOWING)) != 0);
}

test "Node.compareDocumentPosition - parent contains child" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    const pos = child.prototype.compareDocumentPosition(&parent.prototype);

    // Parent CONTAINS child (from child's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_CONTAINS) != 0);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

test "Node.compareDocumentPosition - child contained by parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");

    _ = try parent.prototype.appendChild(&child.prototype);

    const pos = parent.prototype.compareDocumentPosition(&child.prototype);

    // Child CONTAINED_BY parent (from parent's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_CONTAINED_BY) != 0);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_FOLLOWING) != 0);
}

test "Node.compareDocumentPosition - sibling order (preceding)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const pos = child2.prototype.compareDocumentPosition(&child1.prototype);

    // child1 PRECEDES child2 (from child2's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

test "Node.compareDocumentPosition - sibling order (following)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child1 = try doc.createElement("span");
    const child2 = try doc.createElement("p");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    const pos = child1.prototype.compareDocumentPosition(&child2.prototype);

    // child2 FOLLOWS child1 (from child1's perspective)
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_FOLLOWING) != 0);
}

test "Node.compareDocumentPosition - complex tree order" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    defer root.prototype.release();

    const branch1 = try doc.createElement("section");
    const branch2 = try doc.createElement("article");
    const leaf1 = try doc.createElement("span");
    const leaf2 = try doc.createElement("p");

    _ = try root.prototype.appendChild(&branch1.prototype);
    _ = try root.prototype.appendChild(&branch2.prototype);
    _ = try branch1.prototype.appendChild(&leaf1.prototype);
    _ = try branch2.prototype.appendChild(&leaf2.prototype);

    // leaf1 precedes leaf2 (different branches, branch1 before branch2)
    const pos = leaf2.prototype.compareDocumentPosition(&leaf1.prototype);
    try std.testing.expect((pos & Node.DOCUMENT_POSITION_PRECEDING) != 0);
}

test "Node.isEqualNode - returns true for same node" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(elem.prototype.isEqualNode(&elem.prototype));
}

test "Node.isEqualNode - returns false for null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    try std.testing.expect(!elem.prototype.isEqualNode(null));
}

test "Node.isEqualNode - returns true for equal elements (no attributes)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("div");
    defer elem2.prototype.release();

    try std.testing.expect(elem1.prototype.isEqualNode(&elem2.prototype));
}

test "Node.isEqualNode - returns false for different tag names" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("span");
    defer elem2.prototype.release();

    try std.testing.expect(!elem1.prototype.isEqualNode(&elem2.prototype));
}

test "Node.dispatchEvent - basic dispatch returns true" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var event = Event.init("click", .{});
    const result = try elem.prototype.dispatchEvent(&event);

    // Should return true (not canceled)
    try std.testing.expect(result);
}

test "Node.dispatchEvent - invokes listener with event" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var invoked: bool = false;
    const callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const flag: *bool = @ptrCast(@alignCast(context));
            flag.* = true;
            // Verify event properties
            std.testing.expectEqualStrings("click", evt.event_type) catch unreachable;
            std.testing.expect(evt.target != null) catch unreachable;
        }
    }.cb;

    try elem.prototype.addEventListener("click", callback, @ptrCast(&invoked), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event);

    try std.testing.expect(invoked);
}

test "Node.dispatchEvent - returns false when preventDefault called" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    const callback = struct {
        fn cb(evt: *Event, _: *anyopaque) void {
            evt.preventDefault();
        }
    }.cb;

    try elem.prototype.addEventListener("click", callback, undefined, false, false, false, null);

    var event = Event.init("click", .{ .cancelable = true });
    const result = try elem.prototype.dispatchEvent(&event);

    // Should return false (canceled)
    try std.testing.expect(!result);
    try std.testing.expect(event.canceled_flag);
}

test "Node.dispatchEvent - once listener removed after dispatch" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var count: u32 = 0;
    const callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
        }
    }.cb;

    // Add listener with once=true
    try elem.prototype.addEventListener("click", callback, @ptrCast(&count), false, true, false, null);

    // First dispatch
    var event1 = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event1);
    try std.testing.expectEqual(@as(u32, 1), count);

    // Second dispatch - listener should be removed
    var event2 = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event2);
    try std.testing.expectEqual(@as(u32, 1), count); // Still 1, not 2
}

test "Node.dispatchEvent - passive listener blocks preventDefault" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    const callback = struct {
        fn cb(evt: *Event, _: *anyopaque) void {
            // Try to prevent default (should be blocked because passive=true)
            evt.preventDefault();
        }
    }.cb;

    // Add passive listener
    try elem.prototype.addEventListener("click", callback, undefined, false, false, true, null);

    var event = Event.init("click", .{ .cancelable = true });
    const result = try elem.prototype.dispatchEvent(&event);

    // preventDefault should have been ignored
    try std.testing.expect(result); // Returns true
    try std.testing.expect(!event.canceled_flag); // Not canceled
}

test "Node.dispatchEvent - stopImmediatePropagation prevents remaining listeners" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var count: u32 = 0;

    const callback1 = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
        }
    }.cb;

    const callback2 = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
            // Stop propagation
            evt.stopImmediatePropagation();
        }
    }.cb;

    const callback3 = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const counter: *u32 = @ptrCast(@alignCast(context));
            counter.* += 1;
        }
    }.cb;

    try elem.prototype.addEventListener("click", callback1, @ptrCast(&count), false, false, false, null);
    try elem.prototype.addEventListener("click", callback2, @ptrCast(&count), false, false, false, null);
    try elem.prototype.addEventListener("click", callback3, @ptrCast(&count), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event);

    // Only first two listeners should be invoked
    try std.testing.expectEqual(@as(u32, 2), count);
}

test "Node.dispatchEvent - rejects already dispatching event" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var event = Event.init("click", .{});
    event.dispatch_flag = true; // Manually set dispatch flag

    // Should return InvalidStateError
    try std.testing.expectError(error.InvalidStateError, elem.prototype.dispatchEvent(&event));
}

test "Node.dispatchEvent - sets event properties correctly" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    const callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const expected_node: *Node = @ptrCast(@alignCast(context));
            // During dispatch
            const target_node: *Node = @ptrCast(@alignCast(evt.target.?));
            const current_node: *Node = @ptrCast(@alignCast(evt.current_target.?));
            std.testing.expect(target_node == expected_node) catch unreachable;
            std.testing.expect(current_node == expected_node) catch unreachable;
            std.testing.expectEqual(Event.EventPhase.at_target, evt.event_phase) catch unreachable;
            std.testing.expect(!evt.is_trusted) catch unreachable; // Always false for dispatchEvent
        }
    }.cb;

    try elem.prototype.addEventListener("click", callback, @ptrCast(&elem.prototype), false, false, false, null);

    var event = Event.init("click", .{});
    _ = try elem.prototype.dispatchEvent(&event);

    // After dispatch - should be cleaned up
    try std.testing.expectEqual(Event.EventPhase.none, event.event_phase);
    try std.testing.expect(event.current_target == null);
    try std.testing.expect(!event.dispatch_flag);
}

test "Node.dispatchEvent - composed event crosses shadow boundary" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create: host -> shadow root -> inner element
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open });
    const inner = try doc.createElement("inner");
    _ = try shadow.prototype.appendChild(&inner.prototype);

    var listener_called = false;
    const callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const called: *bool = @ptrCast(@alignCast(context));
            called.* = true;
            // When listener is on host, target should be retargeted to host
            // (not implemented yet - this test will fail initially)
            _ = evt;
        }
    }.cb;

    // Add listener to host element
    try host.prototype.addEventListener("click", callback, @ptrCast(&listener_called), false, false, false, null);

    // Dispatch composed event from inner element
    var event = Event.init("click", .{ .composed = true, .bubbles = true, .cancelable = false });
    _ = try inner.prototype.dispatchEvent(&event);

    // Listener on host should have been called (event crossed shadow boundary)
    try std.testing.expect(listener_called);
}

test "Node.dispatchEvent - non-composed event stops at shadow boundary" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create: host -> shadow root -> inner element
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open });
    const inner = try doc.createElement("inner");
    _ = try shadow.prototype.appendChild(&inner.prototype);

    var host_called = false;
    var shadow_called = false;

    const host_callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const called: *bool = @ptrCast(@alignCast(context));
            called.* = true;
        }
    }.cb;

    const shadow_callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const called: *bool = @ptrCast(@alignCast(context));
            called.* = true;
        }
    }.cb;

    // Add listener to host element (outside shadow tree)
    try host.prototype.addEventListener("click", host_callback, @ptrCast(&host_called), false, false, false, null);

    // Add listener to shadow root (boundary)
    try shadow.prototype.addEventListener("click", shadow_callback, @ptrCast(&shadow_called), false, false, false, null);

    // Dispatch NON-composed event from inner element
    var event = Event.init("click", .{ .composed = false, .bubbles = true, .cancelable = false });
    _ = try inner.prototype.dispatchEvent(&event);

    // Listener on shadow root should have been called
    try std.testing.expect(shadow_called);

    // Listener on host should NOT have been called (event stopped at shadow boundary)
    try std.testing.expect(!host_called);
}

test "Node.dispatchEvent - event retargeting across shadow boundary" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create: host -> shadow root -> inner element
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open });
    const inner = try doc.createElement("inner");
    _ = try shadow.prototype.appendChild(&inner.prototype);

    const TargetCheck = struct {
        expected_target: *Node,
        actual_target: ?*Node = null,
    };

    var host_check = TargetCheck{ .expected_target = &host.prototype };
    var shadow_check = TargetCheck{ .expected_target = &inner.prototype };

    const host_callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const check: *TargetCheck = @ptrCast(@alignCast(context));
            check.actual_target = @ptrCast(@alignCast(evt.target.?));
        }
    }.cb;

    const shadow_callback = struct {
        fn cb(evt: *Event, context: *anyopaque) void {
            const check: *TargetCheck = @ptrCast(@alignCast(context));
            check.actual_target = @ptrCast(@alignCast(evt.target.?));
        }
    }.cb;

    // Add listener to host element (outside shadow tree)
    try host.prototype.addEventListener("click", host_callback, @ptrCast(&host_check), false, false, false, null);

    // Add listener to shadow root (inside shadow tree)
    try shadow.prototype.addEventListener("click", shadow_callback, @ptrCast(&shadow_check), false, false, false, null);

    // Dispatch composed event from inner element
    var event = Event.init("click", .{ .composed = true, .bubbles = true, .cancelable = false });
    _ = try inner.prototype.dispatchEvent(&event);

    // Listener inside shadow tree sees real target (inner element)
    try std.testing.expect(shadow_check.actual_target == &inner.prototype);

    // Listener outside shadow tree should see retargeted target (host element)
    // Currently sees the real target (inner element) - needs retargeting
    try std.testing.expect(host_check.actual_target != null);

    // Verify retargeting works correctly
    // Listener outside shadow tree should see retargeted target (host element)
    try std.testing.expect(host_check.actual_target == &host.prototype);
}

test "Event.composedPath - respects composed flag with shadow DOM" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create: host -> shadow root -> inner
    const host = try doc.createElement("host");
    defer host.prototype.release();

    const shadow = try host.attachShadow(.{ .mode = .open });
    const inner = try doc.createElement("inner");
    _ = try shadow.prototype.appendChild(&inner.prototype);

    // Test 1: Composed event crosses shadow boundary
    {
        const TestContext = struct {
            allocator: std.mem.Allocator,
            path_length: usize = 0,
            inner: *Node,
            shadow: *Node,
            host: *Node,
        };

        var ctx = TestContext{
            .allocator = allocator,
            .inner = &inner.prototype,
            .shadow = &shadow.prototype,
            .host = &host.prototype,
        };

        const callback = struct {
            fn cb(evt: *Event, context: *anyopaque) void {
                const c: *TestContext = @ptrCast(@alignCast(context));
                var path = evt.composedPath(c.allocator) catch unreachable;
                defer path.deinit(c.allocator);

                // Should have: inner, shadow root, host
                c.path_length = path.items.len;
                std.testing.expectEqual(@as(usize, 3), path.items.len) catch unreachable;

                // Verify order
                const node0: *Node = @ptrCast(@alignCast(path.items[0]));
                const node1: *Node = @ptrCast(@alignCast(path.items[1]));
                const node2: *Node = @ptrCast(@alignCast(path.items[2]));

                std.testing.expect(node0 == c.inner) catch unreachable;
                std.testing.expect(node1 == c.shadow) catch unreachable;
                std.testing.expect(node2 == c.host) catch unreachable;
            }
        }.cb;

        try host.prototype.addEventListener("click", callback, @ptrCast(&ctx), false, false, false, null);

        var event = Event.init("click", .{ .composed = true, .bubbles = true, .cancelable = false });
        _ = try inner.prototype.dispatchEvent(&event);

        // Verify callback was called
        try std.testing.expectEqual(@as(usize, 3), ctx.path_length);
    }

    // Test 2: Non-composed event stops at shadow boundary
    {
        const TestContext = struct {
            allocator: std.mem.Allocator,
            path_length: usize = 0,
            inner: *Node,
            shadow: *Node,
        };

        var ctx = TestContext{
            .allocator = allocator,
            .inner = &inner.prototype,
            .shadow = &shadow.prototype,
        };

        const callback = struct {
            fn cb(evt: *Event, context: *anyopaque) void {
                const c: *TestContext = @ptrCast(@alignCast(context));
                var path = evt.composedPath(c.allocator) catch unreachable;
                defer path.deinit(c.allocator);

                // Should have: inner, shadow root (stops at boundary)
                c.path_length = path.items.len;
                std.testing.expectEqual(@as(usize, 2), path.items.len) catch unreachable;

                // Verify order
                const node0: *Node = @ptrCast(@alignCast(path.items[0]));
                const node1: *Node = @ptrCast(@alignCast(path.items[1]));

                std.testing.expect(node0 == c.inner) catch unreachable;
                std.testing.expect(node1 == c.shadow) catch unreachable;
            }
        }.cb;

        try shadow.prototype.addEventListener("click", callback, @ptrCast(&ctx), false, false, false, null);

        var event = Event.init("click", .{ .composed = false, .bubbles = true, .cancelable = false });
        _ = try inner.prototype.dispatchEvent(&event);

        // Verify callback was called
        try std.testing.expectEqual(@as(usize, 2), ctx.path_length);
    }
}

test "Node.isEqualNode - returns false for different attribute values" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();
    try elem1.setAttribute("id", "test1");

    const elem2 = try doc.createElement("div");
    defer elem2.prototype.release();
    try elem2.setAttribute("id", "test2");

    try std.testing.expect(!elem1.prototype.isEqualNode(&elem2.prototype));
}

test "Node.isEqualNode - returns false for different attribute counts" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("div");
    defer elem1.prototype.release();
    try elem1.setAttribute("id", "test");

    const elem2 = try doc.createElement("div");
    defer elem2.prototype.release();
    try elem2.setAttribute("id", "test");
    try elem2.setAttribute("class", "foo");

    try std.testing.expect(!elem1.prototype.isEqualNode(&elem2.prototype));
}

test "Node.isEqualNode - returns true for equal text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("Hello");
    defer text1.prototype.release();

    const text2 = try doc.createTextNode("Hello");
    defer text2.prototype.release();

    try std.testing.expect(text1.prototype.isEqualNode(&text2.prototype));
}

test "Node.isEqualNode - returns false for different text content" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text1 = try doc.createTextNode("Hello");
    defer text1.prototype.release();

    const text2 = try doc.createTextNode("World");
    defer text2.prototype.release();

    try std.testing.expect(!text1.prototype.isEqualNode(&text2.prototype));
}

test "Node.isEqualNode - returns true for equal subtrees" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Build first tree
    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release();
    try parent1.setAttribute("id", "container");

    const child1a = try doc.createElement("span");
    const text1 = try doc.createTextNode("Hello");

    _ = try child1a.prototype.appendChild(&text1.prototype);
    _ = try parent1.prototype.appendChild(&child1a.prototype);

    // Build identical tree
    const parent2 = try doc.createElement("div");
    defer parent2.prototype.release();
    try parent2.setAttribute("id", "container");

    const child2a = try doc.createElement("span");
    const text2 = try doc.createTextNode("Hello");

    _ = try child2a.prototype.appendChild(&text2.prototype);
    _ = try parent2.prototype.appendChild(&child2a.prototype);

    try std.testing.expect(parent1.prototype.isEqualNode(&parent2.prototype));
}

test "Node.isEqualNode - returns false for different child counts" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release();

    const child1 = try doc.createElement("span");

    _ = try parent1.prototype.appendChild(&child1.prototype);

    const parent2 = try doc.createElement("div");
    defer parent2.prototype.release();

    const child2a = try doc.createElement("span");
    const child2b = try doc.createElement("p");

    _ = try parent2.prototype.appendChild(&child2a.prototype);
    _ = try parent2.prototype.appendChild(&child2b.prototype);

    try std.testing.expect(!parent1.prototype.isEqualNode(&parent2.prototype));
}

test "Node.isEqualNode - returns false for different child order" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release();

    const child1a = try doc.createElement("span");
    const child1b = try doc.createElement("p");

    _ = try parent1.prototype.appendChild(&child1a.prototype);
    _ = try parent1.prototype.appendChild(&child1b.prototype);

    const parent2 = try doc.createElement("div");
    defer parent2.prototype.release();

    const child2a = try doc.createElement("p");
    const child2b = try doc.createElement("span");

    _ = try parent2.prototype.appendChild(&child2a.prototype);
    _ = try parent2.prototype.appendChild(&child2b.prototype);

    try std.testing.expect(!parent1.prototype.isEqualNode(&parent2.prototype));
}

test "Node.appendChild - cross-document adoption" {
    const allocator = std.testing.allocator;

    // Create two documents
    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    // Create element in doc1 with attributes
    const elem = try doc1.createElement("element");
    try elem.setAttribute("attr1", "value1");
    try elem.setAttribute("data-id", "test-id");

    // Add to doc1's tree
    const container1 = try doc1.createElement("container");
    _ = try doc1.prototype.appendChild(&container1.prototype);
    _ = try container1.prototype.appendChild(&elem.prototype);

    // Verify initial state
    try std.testing.expect(elem.prototype.getOwnerDocument() == doc1);
    try std.testing.expectEqualStrings("value1", elem.getAttribute("attr1").?);

    // Move to doc2 via appendChild (should trigger adoption)
    const container2 = try doc2.createElement("container");
    _ = try doc2.prototype.appendChild(&container2.prototype);
    _ = try container2.prototype.appendChild(&elem.prototype);

    // Verify adoption occurred
    try std.testing.expect(elem.prototype.getOwnerDocument() == doc2);
    try std.testing.expectEqualStrings("value1", elem.getAttribute("attr1").?);
    try std.testing.expectEqualStrings("test-id", elem.getAttribute("data-id").?);

    // elem should no longer be in doc1's tree
    try std.testing.expect(container1.prototype.first_child == null);
}

test "Node - supports any case in tag names" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Can create elements with different case variations
    const lower = try doc.createElement("element");
    defer lower.prototype.release();
    const upper = try doc.createElement("ELEMENT");
    defer upper.prototype.release();
    const mixed = try doc.createElement("Element");
    defer mixed.prototype.release();

    // Each preserves its own casing (NOT normalized)
    try std.testing.expect(std.mem.eql(u8, lower.tag_name, "element"));
    try std.testing.expect(std.mem.eql(u8, upper.tag_name, "ELEMENT"));
    try std.testing.expect(std.mem.eql(u8, mixed.tag_name, "Element"));

    // They are different tag names
    try std.testing.expect(!std.mem.eql(u8, lower.tag_name, upper.tag_name));
    try std.testing.expect(!std.mem.eql(u8, lower.tag_name, mixed.tag_name));
}

test "Node - nodeName() preserves original casing" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem1 = try doc.createElement("container");
    defer elem1.prototype.release();
    const elem2 = try doc.createElement("CONTAINER");
    defer elem2.prototype.release();
    const elem3 = try doc.createElement("Container");
    defer elem3.prototype.release();

    // nodeName() returns the exact casing used in createElement
    try std.testing.expect(std.mem.eql(u8, elem1.prototype.nodeName(), "container"));
    try std.testing.expect(std.mem.eql(u8, elem2.prototype.nodeName(), "CONTAINER"));
    try std.testing.expect(std.mem.eql(u8, elem3.prototype.nodeName(), "Container"));

    // They are NOT equal
    try std.testing.expect(!std.mem.eql(u8, elem1.prototype.nodeName(), elem2.prototype.nodeName()));
}

test "Node - supports any case in attribute names (case-sensitive matching)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Can set attributes with any casing
    try elem.setAttribute("data-id", "123");
    try elem.setAttribute("DATA-NAME", "456");
    try elem.setAttribute("Data-Value", "789");

    // getAttribute is case-sensitive (exact match only)
    const lower = elem.getAttribute("data-id");
    try std.testing.expect(lower != null);
    try std.testing.expect(std.mem.eql(u8, lower.?, "123"));

    // Different casing does NOT match
    const upper_miss = elem.getAttribute("DATA-ID");
    try std.testing.expect(upper_miss == null);

    // Uppercase attribute exists
    const upper = elem.getAttribute("DATA-NAME");
    try std.testing.expect(upper != null);
    try std.testing.expect(std.mem.eql(u8, upper.?, "456"));

    // Lowercase does NOT match uppercase attribute
    const lower_miss = elem.getAttribute("data-name");
    try std.testing.expect(lower_miss == null);

    // Mixed case attribute exists
    const mixed = elem.getAttribute("Data-Value");
    try std.testing.expect(mixed != null);
    try std.testing.expect(std.mem.eql(u8, mixed.?, "789"));
}

test "Node - setAttribute with different case creates separate attributes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Set with lowercase
    try elem.setAttribute("key", "value1");

    // Set with uppercase creates DIFFERENT attribute
    try elem.setAttribute("KEY", "value2");

    // Both attributes exist independently
    const lower = elem.getAttribute("key");
    try std.testing.expect(lower != null);
    try std.testing.expect(std.mem.eql(u8, lower.?, "value1"));

    const upper = elem.getAttribute("KEY");
    try std.testing.expect(upper != null);
    try std.testing.expect(std.mem.eql(u8, upper.?, "value2"));

    // Should have 2 separate attributes
    try std.testing.expect(elem.hasAttribute("key"));
    try std.testing.expect(elem.hasAttribute("KEY"));
}

test "Node - hasAttribute is case-sensitive" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    try elem.setAttribute("attr1", "value");

    // Only exact case matches
    try std.testing.expect(elem.hasAttribute("attr1"));
    try std.testing.expect(!elem.hasAttribute("ATTR1"));
    try std.testing.expect(!elem.hasAttribute("Attr1"));
    try std.testing.expect(!elem.hasAttribute("aTtR1"));
}

test "Node - removeAttribute is case-sensitive" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Set with lowercase
    try elem.setAttribute("data-test", "value");
    try std.testing.expect(elem.hasAttribute("data-test"));

    // Remove with uppercase does NOT remove lowercase attribute
    elem.removeAttribute("DATA-TEST");

    // Lowercase attribute still exists
    try std.testing.expect(elem.hasAttribute("data-test"));

    // Now remove with correct case
    elem.removeAttribute("data-test");
    try std.testing.expect(!elem.hasAttribute("data-test"));
}

test "Node.normalize - merges adjacent text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const text2 = try doc.createTextNode(" ");
    const text3 = try doc.createTextNode("World");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);
    _ = try parent.prototype.appendChild(&text3.prototype);

    // Before: 3 text nodes
    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    // After: 1 text node with merged data
    try std.testing.expectEqual(@as(usize, 1), parent.prototype.childNodes().length());

    const merged = parent.prototype.first_child.?;
    try std.testing.expectEqual(NodeType.text, merged.node_type);

    const merged_text: *Text = @fieldParentPtr("prototype", merged);
    try std.testing.expectEqualStrings("Hello World", merged_text.data);
}

test "Node.normalize - removes empty text nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const empty = try doc.createTextNode("");
    const text2 = try doc.createTextNode("World");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&empty.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    // Before: 3 text nodes (one empty)
    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    // After: 1 text node (empty removed, others merged)
    try std.testing.expectEqual(@as(usize, 1), parent.prototype.childNodes().length());

    const merged = parent.prototype.first_child.?;
    const merged_text: *Text = @fieldParentPtr("prototype", merged);
    try std.testing.expectEqualStrings("HelloWorld", merged_text.data);
}

test "Node.normalize - respects element boundaries" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const text1 = try doc.createTextNode("Hello");
    const elem = try doc.createElement("span");
    const text2 = try doc.createTextNode("World");

    _ = try parent.prototype.appendChild(&text1.prototype);
    _ = try parent.prototype.appendChild(&elem.prototype);
    _ = try parent.prototype.appendChild(&text2.prototype);

    // Before: text, element, text
    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    try parent.prototype.normalize();

    // After: text nodes NOT merged across element boundary
    try std.testing.expectEqual(@as(usize, 3), parent.prototype.childNodes().length());

    const first = parent.prototype.first_child.?;
    const first_text: *Text = @fieldParentPtr("prototype", first);
    try std.testing.expectEqualStrings("Hello", first_text.data);

    const last = parent.prototype.last_child.?;
    const last_text: *Text = @fieldParentPtr("prototype", last);
    try std.testing.expectEqualStrings("World", last_text.data);
}

test "Node.normalize - recursively normalizes descendants" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&parent.prototype);

    const child = try doc.createElement("child");
    _ = try parent.prototype.appendChild(&child.prototype);

    const text1 = try doc.createTextNode("A");
    const text2 = try doc.createTextNode("B");
    _ = try child.prototype.appendChild(&text1.prototype);
    _ = try child.prototype.appendChild(&text2.prototype);

    // Before: child has 2 text nodes
    try std.testing.expectEqual(@as(usize, 2), child.prototype.childNodes().length());

    try parent.prototype.normalize();

    // After: child has 1 merged text node
    try std.testing.expectEqual(@as(usize, 1), child.prototype.childNodes().length());

    const merged = child.prototype.first_child.?;
    const merged_text: *Text = @fieldParentPtr("prototype", merged);
    try std.testing.expectEqualStrings("AB", merged_text.data);
}

test "Node.normalize - handles document fragments" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    const text1 = try doc.createTextNode("Frag");
    const text2 = try doc.createTextNode("ment");
    _ = try fragment.prototype.appendChild(&text1.prototype);
    _ = try fragment.prototype.appendChild(&text2.prototype);

    try std.testing.expectEqual(@as(usize, 2), fragment.prototype.childNodes().length());

    try fragment.prototype.normalize();

    try std.testing.expectEqual(@as(usize, 1), fragment.prototype.childNodes().length());

    const merged = fragment.prototype.first_child.?;
    const merged_text: *Text = @fieldParentPtr("prototype", merged);
    try std.testing.expectEqualStrings("Fragment", merged_text.data);
}
