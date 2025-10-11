const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;
const MutationObserver = dom.MutationObserver;
const MutationRecord = dom.MutationRecord;

// ============================================================================
// MUTATION OBSERVER BENCHMARKS
// ============================================================================

pub fn benchCreateObserver(allocator: std.mem.Allocator) !void {
    const callback = struct {
        fn cb(_: []const *MutationRecord, _: *anyopaque) void {}
    }.cb;

    const observer = try MutationObserver.init(allocator, callback);
    defer observer.deinit();
}

pub fn benchObserveChildList(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(target);

    const callback = struct {
        fn cb(_: []const *MutationRecord, _: *anyopaque) void {}
    }.cb;

    const observer = try MutationObserver.init(allocator, callback);
    defer observer.deinit();

    try observer.observe(target, .{ .child_list = true });
}

pub fn benchObserveAttributes(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(target);

    const callback = struct {
        fn cb(_: []const *MutationRecord, _: *anyopaque) void {}
    }.cb;

    const observer = try MutationObserver.init(allocator, callback);
    defer observer.deinit();

    try observer.observe(target, .{ .attributes = true });
}

pub fn benchObserveSubtree(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(target);

    const callback = struct {
        fn cb(_: []const *MutationRecord, _: *anyopaque) void {}
    }.cb;

    const observer = try MutationObserver.init(allocator, callback);
    defer observer.deinit();

    try observer.observe(target, .{
        .child_list = true,
        .subtree = true,
    });
}

pub fn benchDisconnectObserver(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(target);

    const callback = struct {
        fn cb(_: []const *MutationRecord, _: *anyopaque) void {}
    }.cb;

    const observer = try MutationObserver.init(allocator, callback);
    defer observer.deinit();

    try observer.observe(target, .{ .child_list = true });
    observer.disconnect();
}

pub fn benchTakeRecords(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(target);

    const callback = struct {
        fn cb(_: []const *MutationRecord, _: *anyopaque) void {}
    }.cb;

    const observer = try MutationObserver.init(allocator, callback);
    defer observer.deinit();

    try observer.observe(target, .{ .child_list = true });

    // Trigger a mutation
    const child = try Element.create(allocator, "span");
    _ = try target.appendChild(child);

    // Take pending records
    const records = try observer.takeRecords();
    defer {
        for (records) |record| {
            record.deinit();
        }
        allocator.free(records);
    }
}

pub fn benchMultipleObservers(allocator: std.mem.Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();

    const target = try Element.create(allocator, "div");
    _ = try doc.node.appendChild(target);

    const callback = struct {
        fn cb(_: []const *MutationRecord, _: *anyopaque) void {}
    }.cb;

    // Create multiple observers on same target
    const observer1 = try MutationObserver.init(allocator, callback);
    defer observer1.deinit();

    const observer2 = try MutationObserver.init(allocator, callback);
    defer observer2.deinit();

    const observer3 = try MutationObserver.init(allocator, callback);
    defer observer3.deinit();

    try observer1.observe(target, .{ .child_list = true });
    try observer2.observe(target, .{ .attributes = true });
    try observer3.observe(target, .{ .child_list = true, .subtree = true });
}
