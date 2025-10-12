//! MutationObserver - Observe DOM Mutations
//!
//! WHATWG DOM Standard §4.3.1
//! https://dom.spec.whatwg.org/#interface-mutationobserver
//!
//! MutationObserver allows observing mutations to a DOM tree.

const std = @import("std");
const Node = @import("node.zig").Node;
const MutationRecord = @import("mutation_record.zig").MutationRecord;

// ============================================================================
// Security Limits (P2)
// ============================================================================

/// MutationObserver queue limits to prevent memory exhaustion
pub const MutationObserverLimits = struct {
    /// Maximum number of pending mutation records in queue
    /// Default: 10,000 records (reasonable for most use cases)
    pub const max_queue_size: usize = 10_000;
};

/// Options for observing mutations
pub const MutationObserverInit = struct {
    /// Observe child list mutations
    child_list: bool = false,

    /// Observe attribute mutations
    attributes: ?bool = null,

    /// Observe character data mutations
    character_data: ?bool = null,

    /// Observe subtree (descendants)
    subtree: bool = false,

    /// Record old attribute values
    attribute_old_value: ?bool = null,

    /// Record old character data
    character_data_old_value: ?bool = null,

    /// Filter to specific attributes (attribute names)
    attribute_filter: ?[]const []const u8 = null,
};

/// MutationObserver observes mutations to the DOM tree
///
/// ## Specification
///
/// WHATWG DOM Standard §4.3.1
///
/// ## Example
///
/// ```zig
/// fn callback(records: []const *MutationRecord, observer: *MutationObserver) void {
///     for (records) |record| {
///         std.debug.print("Mutation: {s}\n", .{record.getTypeString()});
///     }
/// }
///
/// const observer = try MutationObserver.init(allocator, callback);
/// defer observer.deinit();
///
/// try observer.observe(target, .{ .child_list = true, .subtree = true });
/// ```
pub const MutationObserver = struct {
    /// Callback function type (uses anyopaque to avoid circular dependency)
    pub const Callback = *const fn (records: []const *MutationRecord, observer: *anyopaque) void;

    /// Callback to invoke with mutation records
    callback: Callback,

    /// Queue of pending mutation records
    record_queue: std.ArrayList(*MutationRecord),

    /// Nodes being observed (weak references)
    observed_nodes: std.ArrayList(*Node),

    /// Allocator
    allocator: std.mem.Allocator,

    /// Whether observer is currently active
    active: bool,

    const Self = @This();

    /// Initialize a MutationObserver
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `callback`: Function to call with mutation records
    ///
    /// ## Returns
    ///
    /// A new MutationObserver instance.
    ///
    /// ## Example
    ///
    /// ```zig
    /// fn onMutation(records: []const *MutationRecord, observer: *MutationObserver) void {
    ///     std.debug.print("Got {d} mutations\n", .{records.len});
    /// }
    ///
    /// const observer = try MutationObserver.init(allocator, onMutation);
    /// defer observer.deinit();
    /// ```
    pub fn init(allocator: std.mem.Allocator, callback: Callback) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        self.* = .{
            .callback = callback,
            .record_queue = std.ArrayList(*MutationRecord){},
            .observed_nodes = std.ArrayList(*Node){},
            .allocator = allocator,
            .active = false,
        };

        return self;
    }

    /// Start observing a target node
    ///
    /// ## Parameters
    ///
    /// - `target`: Node to observe
    /// - `options`: Observation options
    ///
    /// ## Errors
    ///
    /// - `error.InvalidOptions`: Invalid option combination
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// try observer.observe(element, .{
    ///     .child_list = true,
    ///     .attributes = true,
    ///     .subtree = true,
    /// });
    /// ```
    pub fn observe(self: *Self, target: *Node, options: MutationObserverInit) !void {
        // Validate options per spec
        var validated_options = options;

        // If attributeOldValue or attributeFilter exists, set attributes to true
        if (options.attribute_old_value != null or options.attribute_filter != null) {
            if (validated_options.attributes == null) {
                validated_options.attributes = true;
            }
        }

        // If characterDataOldValue exists, set characterData to true
        if (options.character_data_old_value != null) {
            if (validated_options.character_data == null) {
                validated_options.character_data = true;
            }
        }

        // At least one of childList, attributes, or characterData must be true
        const child_list = validated_options.child_list;
        const attributes = validated_options.attributes orelse false;
        const character_data = validated_options.character_data orelse false;

        if (!child_list and !attributes and !character_data) {
            return error.InvalidOptions;
        }

        // Validate attributeOldValue
        if (validated_options.attribute_old_value != null and !attributes) {
            return error.InvalidOptions;
        }

        // Validate attributeFilter
        if (validated_options.attribute_filter != null and !attributes) {
            return error.InvalidOptions;
        }

        // Validate characterDataOldValue
        if (validated_options.character_data_old_value != null and !character_data) {
            return error.InvalidOptions;
        }

        // Add to observed nodes if not already there
        var found = false;
        for (self.observed_nodes.items) |node| {
            if (node == target) {
                found = true;
                break;
            }
        }

        if (!found) {
            try self.observed_nodes.append(self.allocator, target);
        }

        // In a full implementation, we would register this observer with the target node
        // For now, we store the configuration
        self.active = true;
    }

    /// Stop observing all nodes
    ///
    /// ## Example
    ///
    /// ```zig
    /// observer.disconnect();
    /// // Observer is no longer active
    /// ```
    pub fn disconnect(self: *Self) void {
        // Clear observed nodes
        self.observed_nodes.clearRetainingCapacity();

        // Clear record queue
        for (self.record_queue.items) |record| {
            record.deinit();
        }
        self.record_queue.clearRetainingCapacity();

        self.active = false;
    }

    /// Take all pending mutation records
    ///
    /// ## Returns
    ///
    /// Array of pending MutationRecord objects. The caller takes ownership.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const records = try observer.takeRecords();
    /// defer {
    ///     for (records) |record| record.deinit();
    ///     allocator.free(records);
    /// }
    /// ```
    pub fn takeRecords(self: *Self) ![]const *MutationRecord {
        const records = try self.allocator.dupe(*MutationRecord, self.record_queue.items);
        self.record_queue.clearRetainingCapacity();
        return records;
    }

    /// Queue a mutation record (internal use)
    ///
    /// ## Parameters
    ///
    /// - `record`: MutationRecord to queue
    ///
    /// ## Security (P2)
    ///
    /// Limits queue size to prevent memory exhaustion from rapid mutations.
    /// When limit is reached, oldest records are dropped (FIFO).
    pub fn queueRecord(self: *Self, record: *MutationRecord) !void {
        // P2 Security Fix: Limit queue size to prevent memory exhaustion
        if (self.record_queue.items.len >= MutationObserverLimits.max_queue_size) {
            // Drop oldest record to make room (FIFO)
            if (self.record_queue.items.len > 0) {
                const oldest = self.record_queue.orderedRemove(0);
                oldest.deinit();
            }
        }

        try self.record_queue.append(self.allocator, record);
    }

    /// Notify observer with pending records (internal use)
    ///
    /// This would typically be called from a microtask queue.
    pub fn notify(self: *Self) void {
        if (self.record_queue.items.len == 0) return;

        const records = self.record_queue.items;
        self.callback(records, self);

        // Clear the queue after notification
        for (self.record_queue.items) |record| {
            record.deinit();
        }
        self.record_queue.clearRetainingCapacity();
    }

    /// Clean up the observer
    pub fn deinit(self: *Self) void {
        self.disconnect();
        self.record_queue.deinit(self.allocator);
        self.observed_nodes.deinit(self.allocator);
        self.allocator.destroy(self);
    }
};

// Tests
var test_callback_count: usize = 0;
var test_callback_records: usize = 0;

fn testCallback(records: []const *MutationRecord, observer: *anyopaque) void {
    _ = observer;
    test_callback_count += 1;
    test_callback_records = records.len;
}

test "MutationObserver creation" {
    const allocator = std.testing.allocator;

    const observer = try MutationObserver.init(allocator, testCallback);
    defer observer.deinit();

    try std.testing.expect(observer.callback == testCallback);
    try std.testing.expectEqual(@as(usize, 0), observer.record_queue.items.len);
    try std.testing.expectEqual(false, observer.active);
}

test "MutationObserver observe" {
    const allocator = std.testing.allocator;

    const observer = try MutationObserver.init(allocator, testCallback);
    defer observer.deinit();

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    try observer.observe(target, .{ .child_list = true });

    try std.testing.expectEqual(true, observer.active);
    try std.testing.expectEqual(@as(usize, 1), observer.observed_nodes.items.len);
}

test "MutationObserver observe validation" {
    const allocator = std.testing.allocator;

    const observer = try MutationObserver.init(allocator, testCallback);
    defer observer.deinit();

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    // Should fail - no observation type specified
    try std.testing.expectError(error.InvalidOptions, observer.observe(target, .{}));

    // Should succeed - childList specified
    try observer.observe(target, .{ .child_list = true });

    // Should succeed - attributes implied by attributeOldValue
    observer.disconnect();
    try observer.observe(target, .{ .attribute_old_value = true });
}

test "MutationObserver disconnect" {
    const allocator = std.testing.allocator;

    const observer = try MutationObserver.init(allocator, testCallback);
    defer observer.deinit();

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    try observer.observe(target, .{ .child_list = true });
    try std.testing.expectEqual(true, observer.active);

    observer.disconnect();
    try std.testing.expectEqual(false, observer.active);
    try std.testing.expectEqual(@as(usize, 0), observer.observed_nodes.items.len);
}

test "MutationObserver takeRecords" {
    const allocator = std.testing.allocator;

    const observer = try MutationObserver.init(allocator, testCallback);
    defer observer.deinit();

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    // Queue some records
    const record1 = try MutationRecord.init(allocator, .child_list, target);
    try observer.queueRecord(record1);

    const record2 = try MutationRecord.init(allocator, .attributes, target);
    try observer.queueRecord(record2);

    // Take records
    const records = try observer.takeRecords();
    defer {
        for (records) |record| record.deinit();
        allocator.free(records);
    }

    try std.testing.expectEqual(@as(usize, 2), records.len);
    try std.testing.expectEqual(@as(usize, 0), observer.record_queue.items.len);
}

test "MutationObserver notify callback" {
    const allocator = std.testing.allocator;

    test_callback_count = 0;
    test_callback_records = 0;

    const observer = try MutationObserver.init(allocator, testCallback);
    defer observer.deinit();

    const target = try Node.init(allocator, .element_node, "div");
    defer target.release();

    // Queue records
    const record1 = try MutationRecord.init(allocator, .child_list, target);
    try observer.queueRecord(record1);

    const record2 = try MutationRecord.init(allocator, .child_list, target);
    try observer.queueRecord(record2);

    // Notify
    observer.notify();

    try std.testing.expectEqual(@as(usize, 1), test_callback_count);
    try std.testing.expectEqual(@as(usize, 2), test_callback_records);
    try std.testing.expectEqual(@as(usize, 0), observer.record_queue.items.len);
}

test "MutationObserver memory leak test" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const observer = try MutationObserver.init(allocator, testCallback);
        const target = try Node.init(allocator, .element_node, "div");
        defer target.release();

        try observer.observe(target, .{ .child_list = true });

        const record = try MutationRecord.init(allocator, .child_list, target);
        try observer.queueRecord(record);

        observer.deinit();
    }
}
