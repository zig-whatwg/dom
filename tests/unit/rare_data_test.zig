//! rare_data Tests
//!
//! Tests for rare_data functionality.

const std = @import("std");
const dom = @import("dom");

const testing = std.testing;
const Node = dom.Node;
const RareData = dom.RareData;
const NodeRareData = dom.NodeRareData;
const EventListener = dom.EventListener;
const Event = dom.Event;
const Document = dom.Document;

test "NodeRareData - initialization" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Initially all fields are null (not allocated)
    try std.testing.expect(rare_data.event_listeners == null);
    try std.testing.expect(rare_data.mutation_observers == null);
    try std.testing.expect(rare_data.user_data == null);
    try std.testing.expect(rare_data.custom_element_data == null);
    try std.testing.expect(rare_data.animation_data == null);
}

test "NodeRareData - event listeners" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Test context
    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, context: *anyopaque) void {
            const val: *u32 = @ptrCast(@alignCast(context));
            _ = val;
        }
    }.cb;

    // Add event listener
    try rare_data.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    // Verify listener was added
    try std.testing.expect(rare_data.hasEventListeners("click"));
    try std.testing.expect(!rare_data.hasEventListeners("input"));

    const listeners = rare_data.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 1), listeners.len);
    try std.testing.expectEqual(callback, listeners[0].callback);
    try std.testing.expect(!listeners[0].capture);

    // Add another listener for same event
    try rare_data.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = true, // Different capture phase
        .once = false,
        .passive = false,
    });

    const listeners2 = rare_data.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 2), listeners2.len);

    // Remove one listener
    const removed = rare_data.removeEventListener("click", callback, false);
    try std.testing.expect(removed);

    const listeners3 = rare_data.getEventListeners("click");
    try std.testing.expectEqual(@as(usize, 1), listeners3.len);
    try std.testing.expect(listeners3[0].capture); // Only capture phase remains
}

test "NodeRareData - mutation observers" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Test context
    var ctx: u32 = 42;
    const callback = struct {
        fn cb(context: *anyopaque) void {
            const val: *u32 = @ptrCast(@alignCast(context));
            _ = val;
        }
    }.cb;

    // Initially no observers
    try std.testing.expect(!rare_data.hasMutationObservers());
    try std.testing.expectEqual(@as(usize, 0), rare_data.getMutationObservers().len);

    // Add mutation observer
    try rare_data.addMutationObserver(.{
        .callback = callback,
        .context = @ptrCast(&ctx),
        .observe_children = true,
        .observe_attributes = true,
        .observe_character_data = false,
        .observe_subtree = false,
    });

    // Verify observer was added
    try std.testing.expect(rare_data.hasMutationObservers());

    const observers = rare_data.getMutationObservers();
    try std.testing.expectEqual(@as(usize, 1), observers.len);
    try std.testing.expectEqual(callback, observers[0].callback);
    try std.testing.expect(observers[0].observe_children);
    try std.testing.expect(observers[0].observe_attributes);
    try std.testing.expect(!observers[0].observe_character_data);

    // Add another observer
    try rare_data.addMutationObserver(.{
        .callback = callback,
        .context = @ptrCast(&ctx),
        .observe_children = false,
        .observe_attributes = false,
        .observe_character_data = true,
        .observe_subtree = true,
    });

    try std.testing.expectEqual(@as(usize, 2), rare_data.getMutationObservers().len);

    // Remove observer
    const removed = rare_data.removeMutationObserver(callback, @ptrCast(&ctx));
    try std.testing.expect(removed);

    try std.testing.expectEqual(@as(usize, 1), rare_data.getMutationObservers().len);
}

test "NodeRareData - user data" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Test data
    var value1: u32 = 42;
    var value2: u32 = 100;

    // Initially no user data
    try std.testing.expect(!rare_data.hasUserData("key1"));
    try std.testing.expect(rare_data.getUserData("key1") == null);

    // Set user data
    try rare_data.setUserData("key1", @ptrCast(&value1));
    try std.testing.expect(rare_data.hasUserData("key1"));

    const retrieved1 = rare_data.getUserData("key1");
    try std.testing.expect(retrieved1 != null);
    const val1: *u32 = @ptrCast(@alignCast(retrieved1.?));
    try std.testing.expectEqual(@as(u32, 42), val1.*);

    // Set another key
    try rare_data.setUserData("key2", @ptrCast(&value2));
    try std.testing.expect(rare_data.hasUserData("key2"));

    // Update existing key
    value1 = 99;
    const retrieved1b = rare_data.getUserData("key1");
    const val1b: *u32 = @ptrCast(@alignCast(retrieved1b.?));
    try std.testing.expectEqual(@as(u32, 99), val1b.*);

    // Remove user data
    const removed = rare_data.removeUserData("key1");
    try std.testing.expect(removed);
    try std.testing.expect(!rare_data.hasUserData("key1"));
    try std.testing.expect(rare_data.getUserData("key1") == null);

    // key2 still exists
    try std.testing.expect(rare_data.hasUserData("key2"));
}

test "NodeRareData - multiple event types" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, _: *anyopaque) void {}
    }.cb;

    // Add listeners for different events
    try rare_data.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try rare_data.addEventListener(.{
        .event_type = "input",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try rare_data.addEventListener(.{
        .event_type = "change",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    // Verify all events registered
    try std.testing.expect(rare_data.hasEventListeners("click"));
    try std.testing.expect(rare_data.hasEventListeners("input"));
    try std.testing.expect(rare_data.hasEventListeners("change"));
    try std.testing.expect(!rare_data.hasEventListeners("blur"));

    // Each event has one listener
    try std.testing.expectEqual(@as(usize, 1), rare_data.getEventListeners("click").len);
    try std.testing.expectEqual(@as(usize, 1), rare_data.getEventListeners("input").len);
    try std.testing.expectEqual(@as(usize, 1), rare_data.getEventListeners("change").len);
}

test "NodeRareData - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple init/deinit
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();
    }

    // Test 2: With event listeners
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();

        var ctx: u32 = 42;
        const callback = struct {
            fn cb(_: *Event, _: *anyopaque) void {}
        }.cb;

        try rare_data.addEventListener(.{
            .event_type = "click",
            .callback = callback,
            .context = @ptrCast(&ctx),
            .capture = false,
            .once = false,
            .passive = false,
        });

        try rare_data.addEventListener(.{
            .event_type = "input",
            .callback = callback,
            .context = @ptrCast(&ctx),
            .capture = false,
            .once = false,
            .passive = false,
        });
    }

    // Test 3: With mutation observers
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();

        var ctx: u32 = 42;
        const callback = struct {
            fn cb(_: *anyopaque) void {}
        }.cb;

        try rare_data.addMutationObserver(.{
            .callback = callback,
            .context = @ptrCast(&ctx),
            .observe_children = true,
            .observe_attributes = true,
            .observe_character_data = false,
            .observe_subtree = false,
        });
    }

    // Test 4: With user data
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();

        var value: u32 = 42;
        try rare_data.setUserData("key", @ptrCast(&value));
    }

    // Test 5: With everything
    {
        var rare_data = NodeRareData.init(allocator);
        defer rare_data.deinit();

        var ctx: u32 = 42;
        const callback = struct {
            fn cb(_: *Event, _: *anyopaque) void {}
        }.cb;

        try rare_data.addEventListener(.{
            .event_type = "click",
            .callback = callback,
            .context = @ptrCast(&ctx),
            .capture = false,
            .once = false,
            .passive = false,
        });

        const mut_callback = struct {
            fn cb(_: *anyopaque) void {}
        }.cb;

        try rare_data.addMutationObserver(.{
            .callback = mut_callback,
            .context = @ptrCast(&ctx),
            .observe_children = true,
            .observe_attributes = false,
            .observe_character_data = false,
            .observe_subtree = false,
        });

        try rare_data.setUserData("key", @ptrCast(&ctx));
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "NodeRareData - lazy allocation" {
    const allocator = std.testing.allocator;

    var rare_data = NodeRareData.init(allocator);
    defer rare_data.deinit();

    // Initially nothing allocated
    try std.testing.expect(rare_data.event_listeners == null);
    try std.testing.expect(rare_data.mutation_observers == null);
    try std.testing.expect(rare_data.user_data == null);

    // Add event listener - only event_listeners allocated
    var ctx: u32 = 42;
    const callback = struct {
        fn cb(_: *Event, _: *anyopaque) void {}
    }.cb;

    try rare_data.addEventListener(.{
        .event_type = "click",
        .callback = callback,
        .context = @ptrCast(&ctx),
        .capture = false,
        .once = false,
        .passive = false,
    });

    try std.testing.expect(rare_data.event_listeners != null);
    try std.testing.expect(rare_data.mutation_observers == null); // Still null
    try std.testing.expect(rare_data.user_data == null); // Still null

    // Add user data - now user_data allocated
    try rare_data.setUserData("key", @ptrCast(&ctx));

    try std.testing.expect(rare_data.event_listeners != null);
    try std.testing.expect(rare_data.mutation_observers == null); // Still null
    try std.testing.expect(rare_data.user_data != null);

    // Add mutation observer - now everything allocated
    const mut_callback2 = struct {
        fn cb(_: *anyopaque) void {}
    }.cb;

    try rare_data.addMutationObserver(.{
        .callback = mut_callback2,
        .context = @ptrCast(&ctx),
        .observe_children = true,
        .observe_attributes = false,
        .observe_character_data = false,
        .observe_subtree = false,
    });

    try std.testing.expect(rare_data.event_listeners != null);
    try std.testing.expect(rare_data.mutation_observers != null);
    try std.testing.expect(rare_data.user_data != null);
}
