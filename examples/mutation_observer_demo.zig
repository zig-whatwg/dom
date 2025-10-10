//! MutationObserver Demo
//!
//! Demonstrates observing DOM mutations with MutationObserver.
//!
//! Run with: zig build run-mutation-demo

const std = @import("std");
const dom = @import("dom");

var mutations_observed: usize = 0;

fn onMutation(records: []const *dom.MutationRecord, observer: *anyopaque) void {
    _ = observer;

    std.debug.print("\n🔔 Mutation Observer Callback Fired!\n", .{});
    std.debug.print("   Received {d} mutation record(s)\n\n", .{records.len});

    for (records, 0..) |record, i| {
        mutations_observed += 1;
        std.debug.print("   Record #{d}:\n", .{i + 1});
        std.debug.print("   ├─ Type: {s}\n", .{record.getTypeString()});
        std.debug.print("   ├─ Target: {s}\n", .{record.target.node_name});

        switch (record.type) {
            .child_list => {
                std.debug.print("   ├─ Added: {d} node(s)\n", .{record.added_nodes.length()});
                std.debug.print("   └─ Removed: {d} node(s)\n", .{record.removed_nodes.length()});
            },
            .attributes => {
                if (record.attribute_name) |name| {
                    std.debug.print("   ├─ Attribute: {s}\n", .{name});
                }
                if (record.old_value) |old| {
                    std.debug.print("   └─ Old Value: {s}\n", .{old});
                } else {
                    std.debug.print("   └─ Old Value: (not tracked)\n", .{});
                }
            },
            .character_data => {
                if (record.old_value) |old| {
                    std.debug.print("   └─ Old Data: {s}\n", .{old});
                } else {
                    std.debug.print("   └─ Old Data: (not tracked)\n", .{});
                }
            },
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== MutationObserver Demo ===\n\n", .{});

    // Create a tree structure
    const container = try dom.Node.init(allocator, .element_node, "div");
    defer container.release();

    const child1 = try dom.Node.init(allocator, .element_node, "span");
    _ = try container.appendChild(child1);

    const child2 = try dom.Node.init(allocator, .text_node, "Hello World");
    _ = try container.appendChild(child2);

    std.debug.print("Initial tree:\n", .{});
    std.debug.print("div\n", .{});
    std.debug.print("├── span\n", .{});
    std.debug.print("└── text: 'Hello World'\n\n", .{});

    // Demo 1: childList observation
    std.debug.print("Demo 1: Observing childList mutations\n", .{});
    std.debug.print("─────────────────────────────────────\n", .{});

    const observer1 = try dom.MutationObserver.init(allocator, onMutation);
    defer observer1.deinit();

    try observer1.observe(container, .{
        .child_list = true,
        .subtree = false,
    });

    std.debug.print("Observer attached. Adding a new child...\n", .{});

    // Simulate adding a child
    const new_child = try dom.Node.init(allocator, .element_node, "p");
    _ = try container.appendChild(new_child);

    // Create and queue a mutation record
    const record1 = try dom.MutationRecord.init(allocator, .child_list, container);
    try record1.setAddedNodes(&[_]*dom.Node{new_child});
    try observer1.queueRecord(record1);

    // Trigger callback
    observer1.notify();

    // Demo 2: attributes observation with old value
    std.debug.print("\nDemo 2: Observing attribute mutations (with old values)\n", .{});
    std.debug.print("──────────────────────────────────────────────────────\n", .{});

    const observer2 = try dom.MutationObserver.init(allocator, onMutation);
    defer observer2.deinit();

    try observer2.observe(child1, .{
        .attributes = true,
        .attribute_old_value = true,
    });

    std.debug.print("Observer attached. Changing 'class' attribute...\n", .{});

    // Simulate attribute change
    const record2 = try dom.MutationRecord.init(allocator, .attributes, child1);
    try record2.setAttributeInfo("class", null);
    try record2.setOldValue("old-class");
    try observer2.queueRecord(record2);

    observer2.notify();

    // Demo 3: characterData observation
    std.debug.print("\nDemo 3: Observing characterData mutations\n", .{});
    std.debug.print("────────────────────────────────────────\n", .{});

    const observer3 = try dom.MutationObserver.init(allocator, onMutation);
    defer observer3.deinit();

    try observer3.observe(child2, .{
        .character_data = true,
        .character_data_old_value = true,
    });

    std.debug.print("Observer attached. Changing text content...\n", .{});

    // Simulate text change
    const record3 = try dom.MutationRecord.init(allocator, .character_data, child2);
    try record3.setOldValue("Hello World");
    try observer3.queueRecord(record3);

    observer3.notify();

    // Demo 4: takeRecords
    std.debug.print("\nDemo 4: Taking records without callback\n", .{});
    std.debug.print("──────────────────────────────────────\n", .{});

    const observer4 = try dom.MutationObserver.init(allocator, onMutation);
    defer observer4.deinit();

    try observer4.observe(container, .{ .child_list = true });

    // Queue some records
    const record4a = try dom.MutationRecord.init(allocator, .child_list, container);
    try observer4.queueRecord(record4a);

    const record4b = try dom.MutationRecord.init(allocator, .child_list, container);
    try observer4.queueRecord(record4b);

    std.debug.print("Queued 2 mutation records. Calling takeRecords()...\n\n", .{});

    const taken_records = try observer4.takeRecords();
    defer {
        for (taken_records) |record| record.deinit();
        allocator.free(taken_records);
    }

    std.debug.print("Took {d} records from the queue.\n", .{taken_records.len});
    std.debug.print("Observer queue is now empty: {}\n\n", .{observer4.record_queue.items.len == 0});

    // Demo 5: disconnect
    std.debug.print("Demo 5: Disconnecting observer\n", .{});
    std.debug.print("─────────────────────────────────\n", .{});

    const observer5 = try dom.MutationObserver.init(allocator, onMutation);
    defer observer5.deinit();

    try observer5.observe(container, .{ .child_list = true });
    std.debug.print("Observer is active: {}\n", .{observer5.active});

    observer5.disconnect();
    std.debug.print("After disconnect, observer is active: {}\n", .{observer5.active});
    std.debug.print("Observed nodes cleared: {}\n\n", .{observer5.observed_nodes.items.len == 0});

    // Summary
    std.debug.print("=== Summary ===\n\n", .{});
    std.debug.print("Total mutations observed: {d}\n", .{mutations_observed});
    std.debug.print("\nMutationObserver is essential for:\n", .{});
    std.debug.print("  • Reactive UI frameworks\n", .{});
    std.debug.print("  • DOM change tracking\n", .{});
    std.debug.print("  • Performance monitoring\n", .{});
    std.debug.print("  • Custom element implementations\n\n", .{});
}
