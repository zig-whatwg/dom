//! Comprehensive DOM Feature Demo
//!
//! This demonstrates core DOM features:
//! 1. CustomEvent - Events with custom data
//! 2. AbortController + AbortSignal - Async operation control
//! 3. Range - Fragment selection and manipulation
//! 4. TreeWalker + NodeIterator - Tree traversal with filtering
//!
//! Run with: zig build run-comprehensive-demo

const std = @import("std");
const dom = @import("dom");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== Comprehensive DOM Feature Demo ===\n\n", .{});

    // 1. CustomEvent Demo
    std.debug.print("1. CustomEvent Demo\n", .{});
    std.debug.print("   Creating custom event with payload...\n", .{});

    const custom_data = try allocator.create(i32);
    custom_data.* = 42;
    defer allocator.destroy(custom_data);

    const custom_event = try dom.CustomEvent.initWithDetail(
        allocator,
        "userAction",
        custom_data,
    );
    defer custom_event.release();

    std.debug.print("   Event type: {s}\n", .{custom_event.event.type_name});
    if (custom_event.getDetail(i32)) |detail| {
        std.debug.print("   Event detail: {d}\n\n", .{detail.*});
    }

    // 2. AbortController + AbortSignal Demo
    std.debug.print("2. AbortController + AbortSignal Demo\n", .{});
    std.debug.print("   Creating abort controller for async operation...\n", .{});

    const controller = try dom.AbortController.init(allocator);
    defer controller.deinit();

    const signal = controller.signal;
    std.debug.print("   Signal aborted: {}\n", .{signal.aborted});

    std.debug.print("   Aborting operation...\n", .{});
    controller.abort();
    std.debug.print("   Signal aborted: {}\n\n", .{signal.aborted});

    // 3. Range Demo
    std.debug.print("3. Range Demo\n", .{});
    std.debug.print("   Creating text nodes in a container...\n", .{});

    const div = try dom.Node.init(allocator, .element_node, "div");
    defer div.release();

    const text1 = try dom.Node.init(allocator, .text_node, "Hello ");
    _ = try div.appendChild(text1);

    const text2 = try dom.Node.init(allocator, .text_node, "World!");
    _ = try div.appendChild(text2);

    std.debug.print("   Created: <div>Hello World!</div>\n", .{});

    const range = try dom.Range.init(allocator);
    defer range.deinit();

    try range.selectNodeContents(div);
    std.debug.print("   Range selected: startOffset={d}, endOffset={d}\n", .{
        range.start_offset,
        range.end_offset,
    });
    std.debug.print("   Range collapsed: {}\n", .{range.collapsed()});

    // Clone the range
    const cloned = try range.cloneRange();
    defer cloned.deinit();
    std.debug.print("   Cloned range: startOffset={d}, endOffset={d}\n\n", .{
        cloned.start_offset,
        cloned.end_offset,
    });

    // 4. TreeWalker + NodeIterator Demo
    std.debug.print("4. TreeWalker + NodeIterator Demo\n", .{});

    // Create a tree structure
    const root = try dom.Node.init(allocator, .element_node, "root");
    defer root.release();

    const child1 = try dom.Node.init(allocator, .element_node, "child1");
    _ = try root.appendChild(child1);

    const text_node = try dom.Node.init(allocator, .text_node, "text");
    _ = try root.appendChild(text_node);

    const child2 = try dom.Node.init(allocator, .element_node, "child2");
    _ = try root.appendChild(child2);

    const grandchild = try dom.Node.init(allocator, .element_node, "grandchild");
    _ = try child2.appendChild(grandchild);

    std.debug.print("   Created tree:\n", .{});
    std.debug.print("   root\n", .{});
    std.debug.print("   ├── child1\n", .{});
    std.debug.print("   ├── text\n", .{});
    std.debug.print("   └── child2\n", .{});
    std.debug.print("       └── grandchild\n\n", .{});

    // TreeWalker demo - filter elements only
    std.debug.print("   TreeWalker (SHOW_ELEMENT):\n", .{});
    const walker = try dom.TreeWalker.init(
        allocator,
        root,
        dom.NodeFilter.SHOW_ELEMENT,
        null,
    );
    defer walker.deinit();

    var node_count: usize = 0;
    if (walker.firstChild()) |first| {
        std.debug.print("     First child: {s}\n", .{first.node_name});
        node_count += 1;

        while (walker.nextSibling()) |next| {
            std.debug.print("     Next sibling: {s}\n", .{next.node_name});
            node_count += 1;
        }
    }
    std.debug.print("   Found {d} element children\n\n", .{node_count});

    // NodeIterator demo - iterate all nodes
    std.debug.print("   NodeIterator (SHOW_ALL):\n", .{});
    const iterator = try dom.NodeIterator.init(
        allocator,
        root,
        dom.NodeFilter.SHOW_ALL,
        null,
    );
    defer iterator.deinit();

    node_count = 0;
    while (iterator.nextNode()) |node| {
        const type_name = switch (node.node_type) {
            .element_node => "Element",
            .text_node => "Text",
            else => "Other",
        };
        std.debug.print("     {s}: {s}\n", .{ type_name, node.node_name });
        node_count += 1;
    }
    std.debug.print("   Found {d} total nodes\n\n", .{node_count});

    std.debug.print("=== All Phase 2A Features Working! ===\n\n", .{});
}
