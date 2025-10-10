//! Reference Counting Utility
//!
//! This module provides a generic reference counting wrapper for any type.
//! Reference counting is a memory management technique where objects track
//! how many references exist to them, and automatically deallocate when the
//! count reaches zero.
//!
//! ## Key Characteristics
//!
//! - **Automatic Cleanup**: Objects are freed when ref count reaches 0
//! - **Generic**: Works with any type T
//! - **Optional Deinit**: Calls T.deinit() if it exists
//! - **Manual Management**: Caller controls retain/release
//! - **No Cycles**: Cannot detect reference cycles (use weak refs)
//!
//! ## Usage Pattern
//!
//! ```zig
//! const rc = try RefCounted(MyType).init(allocator, my_value);
//! rc.retain();  // Increment count
//! rc.release(); // Decrement count (auto-frees at 0)
//! ```
//!
//! ## DOM Usage
//!
//! While not directly used in the public DOM API, reference counting is
//! internally used by Node and related interfaces to manage object lifetimes
//! without requiring manual cleanup by users.
//!
//! ## Examples
//!
//! ### Basic Reference Counting
//! ```zig
//! const Value = struct { data: i32 };
//! const rc = try RefCounted(Value).init(allocator, .{ .data = 42 });
//! defer rc.release(); // Auto-cleanup when ref count hits 0
//! ```
//!
//! ### Shared Ownership
//! ```zig
//! const rc = try RefCounted(Value).init(allocator, value);
//! const ref2 = rc; // Share pointer
//! ref2.retain();   // Increment count
//!
//! rc.release();    // Count: 1
//! ref2.release();  // Count: 0, object freed
//! ```
//!
//! ### With Custom Cleanup
//! ```zig
//! const Resource = struct {
//!     buffer: []u8,
//!     pub fn deinit(self: *@This()) void {
//!         // Custom cleanup
//!     }
//! };
//! const rc = try RefCounted(Resource).init(allocator, resource);
//! rc.release(); // Calls resource.deinit() before freeing
//! ```
//!
//! ## Memory Management
//!
//! - Initial ref count is 1
//! - `retain()` increments count
//! - `release()` decrements and frees at 0
//! - If T has `deinit()`, it's called before freeing
//! - Allocator must remain valid until final release

const std = @import("std");

/// Creates a reference-counted wrapper for type T.
///
/// ## Generic Type Parameter
///
/// - `T`: The type to wrap with reference counting
///
/// ## Features
///
/// - **Atomic Safety**: Not thread-safe (use mutex for concurrent access)
/// - **Automatic Deinit**: Calls T.deinit() if declared
/// - **Zero-Cost**: Minimal overhead (single usize for count)
/// - **Type-Safe**: Full compile-time type checking
///
/// ## Memory Layout
///
/// ```
/// RefCounted(T) = {
///     ref_count: usize,    // Reference counter
///     allocator: Allocator, // For deallocation
///     value: T             // Actual data
/// }
/// ```
///
/// ## Examples
///
/// ### Simple Value Type
/// ```zig
/// const Point = struct { x: f32, y: f32 };
/// const RCPoint = RefCounted(Point);
/// const pt = try RCPoint.init(allocator, .{ .x = 1.0, .y = 2.0 });
/// defer pt.release();
/// ```
///
/// ### Complex Type with Cleanup
/// ```zig
/// const Buffer = struct {
///     data: []u8,
///     pub fn deinit(self: *@This()) void {
///         // cleanup
///     }
/// };
/// const RCBuffer = RefCounted(Buffer);
/// ```
pub fn RefCounted(comptime T: type) type {
    return struct {
        const Self = @This();

        /// Current reference count (starts at 1).
        ref_count: usize,

        /// Allocator used for deallocation.
        allocator: std.mem.Allocator,

        /// The wrapped value.
        value: T,

        /// Creates a new reference-counted value.
        ///
        /// ## Parameters
        ///
        /// - `allocator`: Memory allocator
        /// - `value`: Initial value (moved into wrapper)
        ///
        /// ## Returns
        ///
        /// Pointer to new RefCounted wrapper with ref count of 1.
        ///
        /// ## Examples
        ///
        /// ```zig
        /// const Value = struct { n: i32 };
        /// const rc = try RefCounted(Value).init(allocator, .{ .n = 42 });
        /// defer rc.release();
        /// try expect(rc.ref_count == 1);
        /// try expect(rc.value.n == 42);
        /// ```
        ///
        /// ### Ownership Transfer
        /// ```zig
        /// // Value is moved, not copied
        /// var data = Data{ .buffer = buffer };
        /// const rc = try RefCounted(Data).init(allocator, data);
        /// // data is now owned by rc
        /// ```
        pub fn init(allocator: std.mem.Allocator, value: T) !*Self {
            const self = try allocator.create(Self);
            self.* = .{
                .ref_count = 1,
                .allocator = allocator,
                .value = value,
            };
            return self;
        }

        /// Increments the reference count.
        ///
        /// ## Usage
        ///
        /// Call this when creating a new reference to the same object.
        ///
        /// ## Examples
        ///
        /// ```zig
        /// const rc = try RefCounted(Value).init(allocator, value);
        /// try expect(rc.ref_count == 1);
        ///
        /// const alias = rc; // Share pointer
        /// alias.retain();   // Now both valid
        /// try expect(rc.ref_count == 2);
        ///
        /// rc.release();     // Count: 1
        /// alias.release();  // Count: 0, freed
        /// ```
        ///
        /// ### Pattern: Shared Ownership
        /// ```zig
        /// fn shareReference(rc: *RefCounted(T)) *RefCounted(T) {
        ///     rc.retain();
        ///     return rc;
        /// }
        /// ```
        pub fn retain(self: *Self) void {
            self.ref_count += 1;
        }

        /// Decrements the reference count and frees if zero.
        ///
        /// ## Behavior
        ///
        /// 1. Decrements ref_count
        /// 2. If count reaches 0:
        ///    - Calls value.deinit() if T has deinit method
        ///    - Frees the wrapper
        ///
        /// ## Examples
        ///
        /// ```zig
        /// const rc = try RefCounted(Value).init(allocator, value);
        /// rc.release(); // Freed immediately (count was 1)
        /// ```
        ///
        /// ### Multiple References
        /// ```zig
        /// const rc = try RefCounted(Value).init(allocator, value);
        /// rc.retain();
        /// rc.retain();
        /// try expect(rc.ref_count == 3);
        ///
        /// rc.release(); // Count: 2
        /// rc.release(); // Count: 1
        /// rc.release(); // Count: 0, freed
        /// ```
        ///
        /// ### With Deinit
        /// ```zig
        /// const Resource = struct {
        ///     name: []u8,
        ///     pub fn deinit(self: *@This()) void {
        ///         // Called automatically before free
        ///     }
        /// };
        /// const rc = try RefCounted(Resource).init(allocator, resource);
        /// rc.release(); // Calls resource.deinit(), then frees
        /// ```
        ///
        /// ## Safety
        ///
        /// - Do not access after final release
        /// - Do not call release more times than retain + 1
        /// - Not thread-safe without external synchronization
        pub fn release(self: *Self) void {
            self.ref_count -= 1;
            if (self.ref_count == 0) {
                if (@hasDecl(T, "deinit")) {
                    self.value.deinit();
                }
                self.allocator.destroy(self);
            }
        }
    };
}

// ============================================================================
// Tests
// ============================================================================

test "RefCounted basic operations" {
    const allocator = std.testing.allocator;

    const TestStruct = struct {
        value: i32,
    };

    const rc = try RefCounted(TestStruct).init(allocator, .{ .value = 42 });
    try std.testing.expectEqual(@as(usize, 1), rc.ref_count);
    try std.testing.expectEqual(@as(i32, 42), rc.value.value);

    rc.retain();
    try std.testing.expectEqual(@as(usize, 2), rc.ref_count);

    rc.release();
    try std.testing.expectEqual(@as(usize, 1), rc.ref_count);

    rc.release();
}

test "RefCounted with deinit" {
    const allocator = std.testing.allocator;

    const TestStructWithDeinit = struct {
        buffer: []u8,

        pub fn deinit(self: *@This()) void {
            _ = self;
        }
    };

    const buffer = try allocator.alloc(u8, 10);
    defer allocator.free(buffer);

    const rc = try RefCounted(TestStructWithDeinit).init(allocator, .{ .buffer = buffer });
    rc.release();
}

test "RefCounted multiple retains" {
    const allocator = std.testing.allocator;

    const Value = struct { n: i32 };
    const rc = try RefCounted(Value).init(allocator, .{ .n = 100 });

    rc.retain();
    rc.retain();
    rc.retain();
    try std.testing.expectEqual(@as(usize, 4), rc.ref_count);

    rc.release();
    rc.release();
    rc.release();
    try std.testing.expectEqual(@as(usize, 1), rc.ref_count);

    rc.release(); // Final release
}

test "RefCounted shared ownership pattern" {
    const allocator = std.testing.allocator;

    const Data = struct { value: i32 };
    const rc1 = try RefCounted(Data).init(allocator, .{ .value = 42 });

    // Simulate sharing
    const rc2 = rc1;
    rc2.retain();

    try std.testing.expectEqual(@as(usize, 2), rc1.ref_count);
    try std.testing.expectEqual(@as(usize, 2), rc2.ref_count);

    rc1.release();
    try std.testing.expectEqual(@as(usize, 1), rc2.ref_count);

    rc2.release(); // Final release
}

test "RefCounted zero initial value" {
    const allocator = std.testing.allocator;

    const Value = struct { n: i32 };
    const rc = try RefCounted(Value).init(allocator, .{ .n = 0 });
    defer rc.release();

    try std.testing.expectEqual(@as(i32, 0), rc.value.n);
}

test "RefCounted with struct" {
    const allocator = std.testing.allocator;

    const Point = struct {
        x: f32,
        y: f32,
    };

    const rc = try RefCounted(Point).init(allocator, .{ .x = 1.5, .y = 2.5 });
    defer rc.release();

    try std.testing.expectEqual(@as(f32, 1.5), rc.value.x);
    try std.testing.expectEqual(@as(f32, 2.5), rc.value.y);
}

test "RefCounted memory leak test" {
    const allocator = std.testing.allocator;

    const Value = struct { data: [100]u8 };

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const rc = try RefCounted(Value).init(allocator, .{ .data = undefined });
        rc.retain();
        rc.retain();
        rc.release();
        rc.release();
        rc.release();
    }
}

test "RefCounted with nested struct" {
    const allocator = std.testing.allocator;

    const Inner = struct { value: i32 };
    const Outer = struct { inner: Inner, flag: bool };

    const rc = try RefCounted(Outer).init(allocator, .{
        .inner = .{ .value = 42 },
        .flag = true,
    });
    defer rc.release();

    try std.testing.expectEqual(@as(i32, 42), rc.value.inner.value);
    try std.testing.expectEqual(true, rc.value.flag);
}

test "RefCounted single retain-release" {
    const allocator = std.testing.allocator;

    const Value = struct { n: i32 };
    const rc = try RefCounted(Value).init(allocator, .{ .n = 1 });

    rc.retain();
    try std.testing.expectEqual(@as(usize, 2), rc.ref_count);

    rc.release();
    try std.testing.expectEqual(@as(usize, 1), rc.ref_count);

    rc.release(); // Final
}

test "RefCounted immediate release" {
    const allocator = std.testing.allocator;

    const Value = struct { n: i32 };
    const rc = try RefCounted(Value).init(allocator, .{ .n = 1 });

    // Immediate release (no retains)
    rc.release();
}
