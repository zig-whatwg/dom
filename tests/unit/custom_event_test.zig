const std = @import("std");
const dom = @import("dom");
const CustomEvent = dom.CustomEvent;

test "CustomEvent - create with detail" {
    const MyData = struct { value: u32, message: []const u8 };
    var data = MyData{ .value = 42, .message = "hello" };

    const event = CustomEvent.init("test-event", .{
        .event_options = .{ .bubbles = true, .cancelable = false, .composed = false },
        .detail = &data,
    });

    try std.testing.expectEqualStrings("test-event", event.event.event_type);
    try std.testing.expect(event.event.bubbles == true);
    try std.testing.expect(event.event.cancelable == false);
    try std.testing.expect(event.detail != null);

    // Type-safe access
    const retrieved = event.getDetail(MyData).?;
    try std.testing.expectEqual(@as(u32, 42), retrieved.value);
    try std.testing.expectEqualStrings("hello", retrieved.message);
}

test "CustomEvent - null detail" {
    const event = CustomEvent.init("test-event", .{
        .event_options = .{ .bubbles = false, .cancelable = false, .composed = false },
        .detail = null,
    });

    try std.testing.expectEqualStrings("test-event", event.event.event_type);
    try std.testing.expect(event.detail == null);
    try std.testing.expect(event.getDetail(u32) == null);
}

test "CustomEvent - initCustomEvent legacy" {
    const MyData = struct { count: i32 };
    var data = MyData{ .count = 100 };

    var event = CustomEvent.init("initial", .{});

    event.initCustomEvent("updated", true, true, &data);

    try std.testing.expectEqualStrings("updated", event.event.event_type);
    try std.testing.expect(event.event.bubbles == true);
    try std.testing.expect(event.event.cancelable == true);

    const retrieved = event.getDetail(MyData).?;
    try std.testing.expectEqual(@as(i32, 100), retrieved.count);
}

test "CustomEvent - complex data structure" {
    const UserData = struct {
        id: u32,
        name: []const u8,
        is_admin: bool,
    };

    var user = UserData{
        .id = 123,
        .name = "alice",
        .is_admin = true,
    };

    const event = CustomEvent.init("user-action", .{
        .event_options = .{ .bubbles = true, .cancelable = true, .composed = false },
        .detail = &user,
    });

    const retrieved = event.getDetail(UserData).?;
    try std.testing.expectEqual(@as(u32, 123), retrieved.id);
    try std.testing.expectEqualStrings("alice", retrieved.name);
    try std.testing.expect(retrieved.is_admin == true);
}
