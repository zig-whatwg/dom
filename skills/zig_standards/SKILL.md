# Zig Programming Standards Skill

## When to use this skill

Load this skill automatically when:
- Writing or refactoring Zig code
- Implementing DOM algorithms in Zig
- Designing struct layouts and type systems
- Managing memory with Document and allocators
- Handling errors in DOM operations
- Writing idiomatic Zig code

## What this skill provides

Zig-specific programming patterns and idioms for DOM implementation:
- Naming conventions and code style
- Error handling patterns (DOM errors → Zig error unions)
- Memory management patterns (Document factory or direct creation)
- Reference counting patterns
- Type safety best practices
- Comptime programming for zero-cost abstractions

## Critical: Memory Management Pattern

**Two valid creation patterns exist:**

### Pattern 1: Direct Creation (Simple, No Interning)

```zig
// Direct creation using allocator
const elem = try Element.create(allocator, "div");
defer elem.node.release();

// No string interning - each string allocates separately
```

### Pattern 2: Document Factory (RECOMMENDED - With Interning)

```zig
// Document-based creation with string interning
const doc = try Document.init(allocator);
defer doc.release();

const elem = try doc.createElement("div");
defer elem.node.release();

// Strings automatically interned via doc.string_pool
```

**Why use Document factory?**
- Automatic string interning (deduplication) via `string_pool`
- Shared string pool across all elements
- Better performance for repeated strings
- Document owns the string pool lifecycle

## Naming Conventions

```zig
// Types: PascalCase
pub const Element = struct { ... };
pub const NodeType = enum { ... };
pub const DOMError = error { ... };

// Functions and variables: snake_case
pub fn appendChild(parent: *Node, child: *Node) !void { ... }
pub fn getElementById(doc: *Document, id: []const u8) ?*Element { ... }
const my_variable: i32 = 42;
const node_count: usize = 0;

// Constants: SCREAMING_SNAKE_CASE
pub const MAX_TREE_DEPTH: usize = 1000;
pub const DEFAULT_CAPACITY: usize = 16;
pub const ELEMENT_NODE: u16 = 1;

// Private members: prefix with underscore when needed for clarity
const _internal_state: State = .init;
fn _internalHelper() void { ... }
```

## Error Handling

### Domain-Specific Error Sets

```zig
// Define error sets matching DOMException types
pub const DOMError = error{
    // DOM Level 1
    IndexSizeError,
    HierarchyRequestError,
    WrongDocumentError,
    InvalidCharacterError,
    NoModificationAllowedError,
    NotFoundError,
    NotSupportedError,
    InUseAttributeError,
    
    // DOM Level 2
    InvalidStateError,
    SyntaxError,
    InvalidModificationError,
    NamespaceError,
    InvalidAccessError,
};

pub const SecurityError = error{
    CircularReferenceDetected,
    MaxTreeDepthExceeded,
    TooManyNodes,
    TooManyChildren,
};

// Combine error sets for operations
pub fn createElement(
    self: *Document,
    local_name: []const u8,
) (Allocator.Error || DOMError)!*Element {
    // May fail with OutOfMemory OR InvalidCharacterError
}
```

### Error Union Patterns

```zig
// Use error unions, not sentinel values
// ✅ GOOD
pub fn findNode(id: []const u8) !*Node {
    return node orelse error.NotFoundError;
}

// ❌ BAD
pub fn findNode(id: []const u8) ?*Node {
    return node; // Loses error information
}

// Provide context in error handling
try validateTagName(tag_name) catch |err| switch (err) {
    error.InvalidCharacterError => return error.InvalidCharacterError,
    error.ReservedName => return error.InvalidCharacterError,
    else => return err,
};

// Use defer for cleanup even on error
pub fn operation(allocator: Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release(); // Runs even if error occurs
    
    const elem = try doc.createElement("div");
    defer elem.node.release(); // Guaranteed cleanup
    
    try someOperationThatMightFail(elem);
    // Cleanup happens automatically
}
```

## Memory Management Patterns

### Memory Management Workflow

**Choose the pattern based on your needs.**

```zig
// Pattern 1: Direct creation (tests, simple cases)
test "feature test" {
    const allocator = std.testing.allocator;
    
    const elem = try Element.create(allocator, "div");
    defer elem.node.release();
    
    // Use elem...
}

// Pattern 2: Document factory (RECOMMENDED for users)
pub fn userWorkflow(allocator: Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release();
    
    const elem = try doc.createElement("div"); // Strings interned via doc.string_pool
    defer elem.node.release();
    
    // Use elem...
}
```

### String Interning

**Strings are interned when using Document factory.**

```zig
// Document manages string pool for automatic deduplication
const doc = try Document.init(allocator);
defer doc.release();

const str1 = try doc.string_pool.intern("Hello");
const str2 = try doc.string_pool.intern("Hello");
// str1.ptr == str2.ptr (same memory address!)

// Elements created via Document use interned strings
const elem = try doc.createElement("div"); // "div" is interned
defer elem.node.release();

// Direct creation does NOT use string interning
const elem2 = try Element.create(allocator, "div"); // New allocation
defer elem2.node.release();
```

### Reference Counting Pattern

```zig
// Reference-counted objects (Node and subclasses)
pub const Node = struct {
    ref_count: usize = 1,  // Start at 1 (creator owns first reference)
    allocator: Allocator,
    
    pub fn acquire(self: *Node) void {
        self.ref_count += 1;
    }
    
    pub fn release(self: *Node) void {
        self.ref_count -= 1;
        if (self.ref_count == 0) {
            self.deinit();
        }
    }
    
    fn deinit(self: *Node) void {
        // Clean up resources
        self.allocator.destroy(self);
    }
};

// Rule 1: Creator owns initial reference
const elem = try Element.create(allocator, "div");
// elem.node.ref_count = 1, caller must release()

// Rule 2: Acquire before sharing
pub fn shareNode(node: *Node, other: *Container) void {
    node.acquire(); // ref_count = 2
    other.node = node;
    // Both owners must release()
}

// Rule 3: Release when done
pub fn cleanup(node: *Node) void {
    node.release(); // ref_count -= 1
    // Only destroyed when ref_count reaches 0
}

// Rule 4: Never release more than you own
// ❌ BAD
pub fn buggyCode(node: *Node) void {
    node.release();
    node.release(); // BUG: Double release!
}
```

### Simple Objects (Non-Refcounted)

```zig
// Objects that don't need reference counting (Range, etc.)
pub const Range = struct {
    allocator: Allocator,
    start_container: *Node,
    start_offset: u32,
    
    pub fn init(allocator: Allocator) !*Range {
        const range = try allocator.create(Range);
        range.* = .{
            .allocator = allocator,
            .start_container = undefined,
            .start_offset = 0,
        };
        return range;
    }
    
    pub fn deinit(self: *Range) void {
        self.allocator.destroy(self);
    }
};

// Usage
const range = try Range.init(allocator);
defer range.deinit();
```

### Ownership Documentation

**Always document ownership and memory management.**

```zig
/// Returns owned string. Caller must free using allocator.
pub fn toString(self: *Node, allocator: Allocator) ![]u8 {
    return allocator.dupe(u8, self.text);
}

/// Borrows reference. Do not free. Valid while node is alive.
pub fn getTagName(self: *Element) []const u8 {
    return self.tag_name;
}

/// Transfers ownership. Caller must call release() when done.
pub fn takeOwnership(self: *Node) *Node {
    self.acquire(); // Increment for new owner
    return self;
}
```

## Type Safety Patterns

### Enums for Fixed Sets

```zig
// Use enums for type-safe constants
pub const NodeType = enum(u16) {
    element = 1,
    text = 3,
    processing_instruction = 7,
    comment = 8,
    document = 9,
    document_type = 10,
    document_fragment = 11,
    
    pub fn fromU16(value: u16) ?NodeType {
        return std.meta.intToEnum(NodeType, value) catch null;
    }
};

// Usage
if (node.node_type == .element) {
    // Type-safe comparison
}
```

### Tagged Unions for Variants

```zig
// Use tagged unions for type variants
pub const NodeValue = union(enum) {
    element: *Element,
    text: *Text,
    comment: *Comment,
    document: *Document,
    
    pub fn asElement(self: NodeValue) ?*Element {
        return switch (self) {
            .element => |e| e,
            else => null,
        };
    }
    
    pub fn getNodeType(self: NodeValue) NodeType {
        return switch (self) {
            .element => .element,
            .text => .text,
            .comment => .comment,
            .document => .document,
        };
    }
};
```

### Bounds Checking

```zig
// Avoid @intCast/@floatCast when possible
// Use explicit bounds checking instead

// ❌ BAD - Unsafe cast
fn getByte(index: usize) u8 {
    return @intCast(index); // May truncate!
}

// ✅ GOOD - Explicit validation
fn getChild(parent: *Node, index: usize) !*Node {
    if (index >= parent.children.items.len) {
        return error.IndexSizeError;
    }
    return parent.children.items[index];
}

// ✅ GOOD - Checked math
fn addOffset(base: usize, offset: u32) !usize {
    const result = base + offset;
    if (result < base) return error.IntegerOverflow; // Overflow check
    return result;
}
```

## Comptime Programming

### Zero-Cost Abstractions

```zig
// Use comptime for generic data structures
fn ArrayList(comptime T: type) type {
    return struct {
        items: []T,
        capacity: usize,
        allocator: Allocator,
        
        pub fn init(allocator: Allocator) @This() {
            return .{
                .items = &[_]T{},
                .capacity = 0,
                .allocator = allocator,
            };
        }
        
        pub fn append(self: *@This(), item: T) !void {
            // Generic implementation
        }
    };
}

// Usage - zero runtime cost
var node_list = ArrayList(*Node).init(allocator);
var string_list = ArrayList([]const u8).init(allocator);
```

### Comptime Validation

```zig
// Use comptime assertions for compile-time checks
pub fn setNodeValue(comptime T: type, node: *Node, value: T) void {
    comptime {
        if (@sizeOf(T) > 64) {
            @compileError("Node value too large - max 64 bytes");
        }
        if (!@hasField(T, "ref_count")) {
            @compileError("Type must have ref_count field");
        }
    }
    // Implementation
}

// Comptime string operations
pub fn validateName(comptime name: []const u8) void {
    comptime {
        if (name.len == 0) {
            @compileError("Name cannot be empty");
        }
        if (name[0] >= '0' and name[0] <= '9') {
            @compileError("Name cannot start with digit");
        }
    }
}
```

## Common Patterns

### Optional Chaining

```zig
// Safe null navigation
pub fn getParentElement(node: *Node) ?*Element {
    if (node.parent_node) |parent| {
        if (parent.node_type == .element) {
            return @fieldParentPtr("node", parent);
        }
    }
    return null;
}

// With early return
pub fn findAncestor(node: *Node, tag_name: []const u8) ?*Element {
    var current = node.parent_node;
    while (current) |n| {
        if (n.node_type == .element) {
            const elem = @fieldParentPtr(Element, "node", n);
            if (std.mem.eql(u8, elem.tag_name, tag_name)) {
                return elem;
            }
        }
        current = n.parent_node;
    }
    return null;
}
```

### Defer for Cleanup

```zig
// ✅ GOOD - Guaranteed cleanup
pub fn processTree(allocator: Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release(); // Always runs
    
    const elem = try doc.createElement("div");
    defer elem.node.release(); // Always runs
    
    try operationThatMightFail(elem);
    // Cleanup happens even if error occurs
}

// Multiple defers execute in reverse order
pub fn complexOperation(allocator: Allocator) !void {
    const doc = try Document.init(allocator);
    defer doc.release(); // Runs last
    
    const elem1 = try doc.createElement("div");
    defer elem1.node.release(); // Runs second
    
    const elem2 = try doc.createElement("span");
    defer elem2.node.release(); // Runs first
    
    try process(elem1, elem2);
}
```

### Error Unions in Struct Fields

```zig
// Store result of fallible operation
pub const OperationResult = struct {
    success: bool,
    node: ?*Node,
    err: ?DOMError,
    
    pub fn ok(node: *Node) OperationResult {
        return .{ .success = true, .node = node, .err = null };
    }
    
    pub fn fail(err: DOMError) OperationResult {
        return .{ .success = false, .node = null, .err = err };
    }
};

// Or use error union directly
pub fn tryOperation() DOMError!*Node {
    return node orelse error.NotFoundError;
}
```

## Performance Considerations

### Minimize Allocations

```zig
// ✅ GOOD - Reuse buffer
pub fn processNodes(allocator: Allocator, nodes: []*Node) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    
    for (nodes) |node| {
        buffer.clearRetainingCapacity(); // Reuse allocation
        try buffer.appendSlice(node.node_value orelse "");
        // Process buffer...
    }
}

// ❌ BAD - Allocate per iteration
pub fn processNodes(allocator: Allocator, nodes: []*Node) !void {
    for (nodes) |node| {
        var buffer = std.ArrayList(u8).init(allocator); // New allocation!
        defer buffer.deinit();
        try buffer.appendSlice(node.node_value orelse "");
    }
}
```

### Inline Hot Paths

```zig
// Use inline for hot paths (small, frequently called functions)
pub inline fn isElement(node: *const Node) bool {
    return node.node_type == .element;
}

pub inline fn isTextNode(node: *const Node) bool {
    return node.node_type == .text;
}

// Use noinline for cold paths (error handling, rare cases)
noinline fn handleUnexpectedNodeType(node: *Node) noreturn {
    std.debug.panic("Unexpected node type: {}", .{node.node_type});
}
```

### Cache-Friendly Layouts

```zig
// ✅ GOOD - Hot fields first, cold fields last
pub const Node = struct {
    // Hot fields (accessed frequently)
    node_type: NodeType,        // 2 bytes
    ref_count: usize,            // 8 bytes
    parent_node: ?*Node,         // 8 bytes
    
    // Medium fields
    first_child: ?*Node,
    last_child: ?*Node,
    
    // Cold fields (accessed rarely)
    rare_data: ?*RareData,       // Optional, allocated on demand
};

// ✅ GOOD - Keep structs small and cacheline-friendly
// Aim for <= 64 bytes for hot structs
```

## Integration with Other Skills

This skill coordinates with:
- **whatwg_compliance** - Implements WebIDL signatures in idiomatic Zig
- **testing_requirements** - Zig testing patterns and std.testing.allocator
- **performance_optimization** - Zig-specific performance patterns
- **documentation_standards** - Zig doc comment format

Load all relevant skills together for complete guidance.
