const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const Event = dom.Event;
const CustomEvent = dom.CustomEvent;

// ============================================================================
// EVENT SYSTEM BENCHMARKS
// ============================================================================

pub fn benchCreateEvent(allocator: std.mem.Allocator) !void {
    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();
}

pub fn benchCreateCustomEvent(allocator: std.mem.Allocator) !void {
    const event = try CustomEvent.init(allocator, "custom");
    defer event.release();
}

pub fn benchAddEventListener(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();

    const listener = struct {
        fn callback(_: *Event) void {}
    }.callback;

    try elem.addEventListener("click", listener, .{});
}

pub fn benchRemoveEventListener(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();

    const listener = struct {
        fn callback(_: *Event) void {}
    }.callback;

    try elem.addEventListener("click", listener, .{});
    elem.removeEventListener("click", listener, false);
}

pub fn benchDispatchEvent(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();

    const listener = struct {
        fn callback(_: *Event) void {}
    }.callback;

    try elem.addEventListener("click", listener, .{});

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    _ = try elem.dispatchEvent(event);
}

pub fn benchEventPropagation(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(parent);

    const child = try Element.create(allocator, "span");
    _ = try parent.appendChild(child);

    // Add listeners to both
    const listener = struct {
        fn callback(_: *Event) void {}
    }.callback;

    try parent.addEventListener("click", listener, .{});
    try child.addEventListener("click", listener, .{});

    // Dispatch event on child (will propagate to parent)
    const event = try Event.init(allocator, "click", .{ .bubbles = true });
    defer event.deinit();

    _ = try child.dispatchEvent(event);
}

pub fn benchEventCapture(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(parent);

    const child = try Element.create(allocator, "span");
    _ = try parent.appendChild(child);

    // Add capturing listener
    const listener = struct {
        fn callback(_: *Event) void {}
    }.callback;

    try parent.addEventListener("click", listener, .{ .capture = true });
    try child.addEventListener("click", listener, .{});

    const event = try Event.init(allocator, "click", .{ .bubbles = true });
    defer event.deinit();

    _ = try child.dispatchEvent(event);
}

pub fn benchMultipleListeners(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();

    const listener1 = struct {
        fn callback(_: *Event) void {}
    }.callback;
    const listener2 = struct {
        fn callback(_: *Event) void {}
    }.callback;
    const listener3 = struct {
        fn callback(_: *Event) void {}
    }.callback;

    // Add multiple listeners
    try elem.addEventListener("click", listener1, .{});
    try elem.addEventListener("click", listener2, .{});
    try elem.addEventListener("click", listener3, .{});

    const event = try Event.init(allocator, "click", .{});
    defer event.deinit();

    _ = try elem.dispatchEvent(event);
}

pub fn benchStopPropagation(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(parent);

    const child = try Element.create(allocator, "span");
    _ = try parent.appendChild(child);

    // Listener that stops propagation
    const listener_stop = struct {
        fn callback(event: *Event) void {
            event.stopPropagation();
        }
    }.callback;

    const listener_normal = struct {
        fn callback(_: *Event) void {}
    }.callback;

    try child.addEventListener("click", listener_stop, .{});
    try parent.addEventListener("click", listener_normal, .{});

    const event = try Event.init(allocator, "click", .{ .bubbles = true });
    defer event.deinit();

    _ = try child.dispatchEvent(event);
}
