# Performance Optimization Skill

## When to use this skill

Load when implementing or optimizing:
- Query selectors and element matching
- Tree traversal operations
- String operations and validation
- Collection operations (NodeList, HTMLCollection)
- Hot paths in DOM operations

## What this skill provides

DOM-specific performance optimization strategies:
- Fast paths for common cases (ASCII, simple selectors)
- Bloom filters for query selector optimization
- Allocation minimization patterns
- Cache-friendly data structures
- Early exit conditions

##

 Critical: Performance is Mandatory

**This is a DOM implementation. Performance is CRITICAL, not optional.**

All DOM operations are hot paths in web applications. Slow DOM = slow web.

## Fast Paths for Common Cases

### ASCII Fast Path

Most element names are pure ASCII. Optimize for this.

```zig
// ✅ GOOD: Fast path for ASCII (most common case)
pub fn validateName(name: []const u8) !bool {
    // Fast path: pure ASCII check
    var is_ascii = true;
    for (name) |byte| {
        if (byte >= 0x80) {
            is_ascii = false;
            break;
        }
    }
    
    if (is_ascii) {
        return validateAsciiName(name); // Fast validation, no UTF-8 decoding
    }
    
    // Slow path: Unicode validation (rare)
    return validateUnicodeName(name);
}

// ❌ BAD: Always using slow path
pub fn validateName(name: []const u8) !bool {
    return validateUnicodeName(name); // Always decodes UTF-8, even for ASCII
}
```

## Bloom Filters for Query Selectors

Use bloom filters to quickly reject non-matching elements.

```zig
pub const BloomFilter = struct {
    bits: u64 = 0,
    
    pub fn add(self: *BloomFilter, class_name: []const u8) void {
        const hash = std.hash.Wyhash.hash(0, class_name);
        self.bits |= @as(u64, 1) << @truncate(@as(u6, @intCast(hash)));
    }
    
    pub fn mayContain(self: BloomFilter, class_name: []const u8) bool {
        const hash = std.hash.Wyhash.hash(0, class_name);
        const mask = @as(u64, 1) << @truncate(@as(u6, @intCast(hash)));
        return (self.bits & mask) != 0;
    }
};

// Use in querySelector for fast rejection
pub fn querySelector(root: *Node, selector: []const u8) !?*Node {
    // Build bloom filter from selector classes
    var filter = BloomFilter{};
    // ... extract classes from selector and add to filter
    
    // Tree traversal
    var current = root.first_child;
    while (current) |node| {
        if (node.node_type == .element) {
            const elem = @fieldParentPtr(Element, "node", node);
            
            // Fast rejection: if bloom filter says no, definitely no match
            if (!filter.mayContain(elem.className)) {
                current = node.next_sibling;
                continue; // Skip expensive full match
            }
            
            // Full match only if bloom filter says maybe
            if (try matchesSelector(elem, selector)) {
                return node;
            }
        }
        current = node.next_sibling;
    }
    return null;
}
```

## Minimize Allocations

### Reuse Buffers

```zig
// ✅ GOOD: Reuse buffer across iterations
pub fn processNodes(allocator: Allocator, nodes: []*Node) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    
    for (nodes) |node| {
        buffer.clearRetainingCapacity(); // Reuse allocation
        try buffer.appendSlice(node.text);
        // Process buffer...
    }
}

// ❌ BAD: Allocate per iteration
pub fn processNodes(allocator: Allocator, nodes: []*Node) !void {
    for (nodes) |node| {
        var buffer = std.ArrayList(u8).init(allocator); // New allocation!
        defer buffer.deinit();
        try buffer.appendSlice(node.text);
    }
}
```

### Stack Allocation for Small Buffers

```zig
// ✅ GOOD: Stack allocation for small, fixed-size buffers
pub fn formatNodeType(node_type: NodeType) [32]u8 {
    var buffer: [32]u8 = undefined;
    const name = @tagName(node_type);
    @memcpy(buffer[0..name.len], name);
    return buffer;
}

// For larger or dynamic buffers, use allocator
pub fn serializeNode(node: *Node, allocator: Allocator) ![]u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    // Build string...
    return buffer.toOwnedSlice();
}
```

## Cache-Friendly Data Structures

### Array of Structs (Good)

```zig
// ✅ GOOD: Array of structs (contiguous memory, cache-friendly)
pub const NodeList = struct {
    nodes: []Node, // All nodes in contiguous memory
    length: usize,
};

// Iteration is cache-friendly
for (list.nodes) |node| {
    // All nodes are adjacent in memory → fewer cache misses
}
```

### Array of Pointers (Less Good)

```zig
// ❌ LESS GOOD: Array of pointers (scattered memory, cache misses)
pub const NodeList = struct {
    nodes: []*Node, // Pointers to nodes scattered in memory
    length: usize,
};

// Iteration has cache misses
for (list.nodes) |node_ptr| {
    // Each node may be far apart in memory → cache misses
}
```

**When to use pointers:**
- Polymorphism required (Node subclasses)
- Objects are large (> 64 bytes)
- Shared ownership (reference counting)

## Early Exit Conditions

Check cheapest conditions first.

```zig
// ✅ GOOD: Check cheapest conditions first
pub fn matches(element: *Element, selector: Selector) bool {
    // Check tag first (cheap pointer comparison)
    if (selector.tag) |tag| {
        if (!std.mem.eql(u8, element.tag_name, tag)) {
            return false; // Early exit - most rejections happen here
        }
    }
    
    // Check classes (more expensive - iterate attributes)
    if (selector.classes.items.len > 0) {
        for (selector.classes.items) |class| {
            if (!element.hasClass(class)) return false;
        }
    }
    
    // Check attributes (most expensive - parse and compare)
    if (selector.attributes.items.len > 0) {
        for (selector.attributes.items) |attr| {
            if (!element.matchesAttribute(attr)) return false;
        }
    }
    
    return true;
}

// ❌ BAD: Check expensive conditions first
pub fn matches(element: *Element, selector: Selector) bool {
    // Expensive attribute checks happen even if tag doesn't match!
    if (selector.attributes.items.len > 0) {
        for (selector.attributes.items) |attr| {
            if (!element.matchesAttribute(attr)) return false;
        }
    }
    
    if (selector.tag) |tag| {
        if (!std.mem.eql(u8, element.tag_name, tag)) {
            return false; // Should have checked this first!
        }
    }
    
    return true;
}
```

## String Operations

### Interning for Deduplication

**Use Document's string pool for automatic interning.**

```zig
const doc = try Document.init(allocator);
defer doc.release();

// These share the same memory via document's string pool
const str1 = try doc.string_pool.intern("div");
const str2 = try doc.string_pool.intern("div");
// str1.ptr == str2.ptr → Saves memory, fast comparison

// Elements created via Document automatically use interned strings
const elem = try doc.createElement("div"); // "div" is interned
```

### Fast String Comparison

```zig
// ✅ GOOD: Pointer comparison for interned strings
pub fn tagNameEquals(elem: *Element, tag_name: []const u8) bool {
    if (elem.tag_name.ptr == tag_name.ptr) {
        return true; // Same interned string - instant comparison
    }
    return std.mem.eql(u8, elem.tag_name, tag_name);
}

// For case-insensitive (HTML)
pub fn tagNameEqualsIgnoreCase(elem: *Element, tag_name: []const u8) bool {
    return std.ascii.eqlIgnoreCase(elem.tag_name, tag_name);
}
```

## Inline Hot Paths

```zig
// Inline small, frequently called functions
pub inline fn isElement(node: *const Node) bool {
    return node.node_type == .element;
}

pub inline fn isTextNode(node: *const Node) bool {
    return node.node_type == .text;
}

pub inline fn hasChildren(node: *const Node) bool {
    return node.first_child != null;
}

// Don't inline large or cold functions
pub fn complexValidation(name: []const u8) !bool {
    // Large function - don't inline
}
```

## Benchmarking

Always benchmark performance-critical code.

```zig
test "benchmark - querySelector performance" {
    const allocator = std.testing.allocator;
    const iterations = 10000;
    
    // Setup
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const root = try setupLargeTree(doc); // Create test tree
    defer root.node.release();
    
    // Benchmark
    var timer = try std.time.Timer.start();
    
    for (0..iterations) |_| {
        const result = try querySelector(root.node, ".my-class");
        _ = result;
    }
    
    const elapsed = timer.read();
    const ns_per_op = elapsed / iterations;
    
    std.debug.print("querySelector: {} ns/op\n", .{ns_per_op});
    
    // Assert performance requirement
    try std.testing.expect(ns_per_op < 100_000); // Must be < 100μs
}
```

## Common Performance Patterns

### Lazy Initialization

```zig
// Initialize rare data only when needed
pub fn getRareData(node: *Node) *RareData {
    if (node.rare_data == null) {
        node.rare_data = RareData.init(node.context.allocator);
    }
    return node.rare_data.?;
}
```

### Copy-on-Write

```zig
// Share read-only data, copy only when modifying
pub const Attributes = struct {
    data: []Attr,
    is_shared: bool,
    
    pub fn clone(self: *Attributes) !void {
        if (self.is_shared) {
            self.data = try allocator.dupe(Attr, self.data);
            self.is_shared = false;
        }
    }
    
    pub fn set(self: *Attributes, name: []const u8, value: []const u8) !void {
        try self.clone(); // Copy before modifying
        // Modify self.data...
    }
};
```

### Small String Optimization

```zig
// Store small strings inline, large strings allocated
pub const SmallString = union(enum) {
    small: [23]u8, // Inline storage for <= 23 bytes
    large: []u8,   // Heap allocated for > 23 bytes
    
    pub fn fromSlice(allocator: Allocator, s: []const u8) !SmallString {
        if (s.len <= 23) {
            var small: [23]u8 = undefined;
            @memcpy(small[0..s.len], s);
            return .{ .small = small };
        } else {
            const large = try allocator.dupe(u8, s);
            return .{ .large = large };
        }
    }
};
```

## Performance Verification

```bash
# Always verify performance hasn't regressed
zig build bench -Doptimize=ReleaseFast

# Profile hot paths
zig build -Doptimize=ReleaseFast
perf record -g ./zig-out/bin/benchmark
perf report

# Compare with previous benchmarks
# Ensure < 10% regression for existing operations
```

## Integration with Other Skills

This skill coordinates with:
- **zig_standards** - Use Zig idioms for optimal performance
- **whatwg_compliance** - Balance spec compliance with performance
- **testing_requirements** - Benchmark tests to catch regressions

Load all relevant skills for complete optimization guidance.
