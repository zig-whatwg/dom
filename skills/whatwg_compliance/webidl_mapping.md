# WebIDL to Zig Type Mapping Reference

Complete reference for mapping WebIDL types and extended attributes to Zig idioms.

## Basic Type Mappings

### Scalar Types

| WebIDL | Zig | Size | Range | Notes |
|--------|-----|------|-------|-------|
| `boolean` | `bool` | 1 byte | true/false | |
| `byte` | `i8` | 1 byte | -128 to 127 | Signed |
| `octet` | `u8` | 1 byte | 0 to 255 | Unsigned |
| `short` | `i16` | 2 bytes | -32768 to 32767 | |
| `unsigned short` | `u16` | 2 bytes | 0 to 65535 | |
| `long` | `i32` | 4 bytes | -2³¹ to 2³¹-1 | |
| `unsigned long` | `u32` | 4 bytes | 0 to 2³²-1 | **Most common for counts** |
| `long long` | `i64` | 8 bytes | -2⁶³ to 2⁶³-1 | |
| `unsigned long long` | `u64` | 8 bytes | 0 to 2⁶⁴-1 | |
| `float` | `f32` | 4 bytes | IEEE 754 | Rarely used in DOM |
| `double` | `f64` | 8 bytes | IEEE 754 | |
| `unrestricted double` | `f64` | 8 bytes | Allows NaN/Infinity | |

### String Types

| WebIDL | Zig | Notes |
|--------|-----|-------|
| `DOMString` | `[]const u8` | UTF-8 encoded, may contain invalid sequences |
| `DOMString?` | `?[]const u8` | Nullable string |
| `ByteString` | `[]const u8` | Byte sequence, not necessarily UTF-8 |
| `USVString` | `[]const u8` | UTF-8, validated as Unicode Scalar Values |

**Important**: All strings in this implementation use UTF-8 encoding. String interning is available when using Document factory methods.

### Object Types

| WebIDL | Zig | Notes |
|--------|-----|-------|
| `object` | `*anyopaque` | Opaque pointer to any type |
| `any` | Union or `anyopaque` | Context-dependent |
| `undefined` | `void` | **CRITICAL**: No return value (not bool!) |
| `null` | N/A | Use optional types instead |

### Interface Types

| WebIDL | Zig | Notes |
|--------|-----|-------|
| `Node` | `*Node` | Non-null pointer |
| `Node?` | `?*Node` | Nullable pointer |
| `Element` | `*Element` | Non-null pointer |
| `Element?` | `?*Element` | Nullable pointer |

### Collection Types

| WebIDL | Zig | Notes |
|--------|-----|-------|
| `sequence<T>` | `[]T` or `ArrayList(T)` | Dynamic array |
| `FrozenArray<T>` | `[]const T` | Immutable array |
| `record<K, V>` | `HashMap(K, V)` | Key-value map |

## Extended Attributes

### `[CEReactions]` - Custom Element Reactions

Indicates method triggers custom element lifecycle callbacks.

**WebIDL:**
```webidl
[CEReactions] undefined setAttribute(DOMString name, DOMString value);
```

**Zig Implementation:**
```zig
pub fn setAttribute(self: *Element, name: []const u8, value: []const u8) void {
    // 1. Perform operation
    self.attributes.set(name, value);
    
    // 2. Trigger custom element reactions (if this is a custom element)
    if (self.is_custom_element) {
        self.triggerAttributeChangedCallback(name, old_value, value);
    }
}
```

### `[NewObject]` - Returns New Instance

Method returns a newly allocated object.

**WebIDL:**
```webidl
[NewObject] Element createElement(DOMString localName);
```

**Zig Implementation:**
```zig
// Returns new Element with ref_count = 1
// Caller MUST call element.release() when done
pub fn createElement(self: *Document, local_name: []const u8) !*Element {
    return try Element.create(self.context, local_name);
    // Allocation may fail → error return
}
```

**Memory Management:**
- Caller owns the returned reference
- Must call `.release()` when done
- Return type includes `!` for allocation errors

### `[SameObject]` - Returns Cached Instance

Attribute must return THE SAME object instance on every access.

**WebIDL:**
```webidl
[SameObject] readonly attribute NodeList childNodes;
```

**Zig Implementation:**
```zig
pub fn childNodes(self: *Node) *NodeList {
    // Return cached NodeList from rare data
    if (self.rare_data) |rare| {
        return &rare.child_nodes_list;
    }
    
    // Initialize rare data and cache on first access
    self.ensureRareData();
    return &self.rare_data.?.child_nodes_list;
}
```

**Critical:**
- Cache in struct (often rare data)
- Never allocate new object on property access
- Return pointer to cached instance

### `[Exposed=Window]` - Availability

Indicates where interface is available.

**WebIDL:**
```webidl
[Exposed=Window] interface Element : Node { }
[Exposed=*] interface Event { } // Available everywhere
[Exposed=(Window,Worker)] interface AbortSignal { }
```

**Zig Implementation:**
- Usually doesn't affect implementation
- Relevant for runtime environment checks
- This implementation targets browser-compatible environment

### `[LegacyNullToEmptyString]` - Null Conversion

Converts null parameter to empty string.

**WebIDL:**
```webidl
undefined setParameter([LegacyNullToEmptyString] DOMString value);
```

**Zig Implementation:**
```zig
pub fn setParameter(self: *Self, value: ?[]const u8) void {
    const actual_value = value orelse ""; // Convert null to ""
    // Use actual_value
}
```

### `[Unscopable]` - JavaScript-Specific

Affects JavaScript prototype chain, not relevant to Zig implementation.

**WebIDL:**
```webidl
[CEReactions, Unscopable] undefined append((Node or DOMString)... nodes);
```

**Zig Implementation:**
```zig
// Ignore [Unscopable], implement normally
pub fn append(self: *ParentNode, nodes: []const NodeOrString) !void {
    // Implementation
}
```

### `[PutForwards=value]` - Property Forwarding

Property assignment forwards to sub-property.

**WebIDL:**
```webidl
[SameObject, PutForwards=value] readonly attribute DOMTokenList classList;
```

**Zig Implementation:**
```zig
// Getting: Return DOMTokenList
pub fn classList(self: *Element) *DOMTokenList {
    return &self.class_list;
}

// Setting: Forward to classList.value
// element.classList = "foo bar" → element.classList.value = "foo bar"
// Usually handled by JavaScript bindings, not core Zig implementation
```

## Nullable Types

### Optional Parameters

**WebIDL:**
```webidl
Node insertBefore(Node node, Node? child);
//                                    ^ nullable
```

**Zig Implementation:**
```zig
pub fn insertBefore(
    self: *Node,
    node: *Node,
    child: ?*Node,  // Optional parameter
) !*Node {
    if (child) |ref_child| {
        // Insert before ref_child
    } else {
        // Insert at end (child is null)
    }
}
```

### Nullable Return Types

**WebIDL:**
```webidl
Element? getElementById(DOMString elementId);
//     ^ nullable return
```

**Zig Implementation:**
```zig
pub fn getElementById(self: *Document, element_id: []const u8) ?*Element {
    return self.findElementById(element_id); // May return null
}
```

## Union Types

**WebIDL:**
```webidl
undefined append((Node or DOMString)... nodes);
//                ^^^^^^^^^^^^^^^^^ union type
```

**Zig Implementation:**
```zig
pub const NodeOrString = union(enum) {
    node: *Node,
    string: []const u8,
};

pub fn append(self: *ParentNode, nodes: []const NodeOrString) !void {
    for (nodes) |item| {
        switch (item) {
            .node => |n| try self.appendChildNode(n),
            .string => |s| {
                const text = try Text.create(self.context, s);
                try self.appendChildNode(text.node);
            },
        }
    }
}
```

## Variadic Parameters

**WebIDL:**
```webidl
undefined append((Node or DOMString)... nodes);
//                                      ^^^ variadic
```

**Zig Implementation:**
```zig
// Use slice for variadic parameters
pub fn append(self: *ParentNode, nodes: []const NodeOrString) !void {
    for (nodes) |node| {
        // Process each node
    }
}

// Usage:
const nodes = [_]NodeOrString{
    .{ .node = child1 },
    .{ .string = "text" },
    .{ .node = child2 },
};
try parent.append(&nodes);
```

## Dictionary Types

**WebIDL:**
```webidl
dictionary EventInit {
  boolean bubbles = false;
  boolean cancelable = false;
  boolean composed = false;
};
```

**Zig Implementation:**
```zig
pub const EventInit = struct {
    bubbles: bool = false,
    cancelable: bool = false,
    composed: bool = false,
};

// Usage:
const event = try Event.init(context, "click", .{
    .bubbles = true,
    .cancelable = true,
});
```

## Enum Types

**WebIDL:**
```webidl
enum ShadowRootMode { "open", "closed" };
```

**Zig Implementation:**
```zig
pub const ShadowRootMode = enum {
    open,
    closed,
    
    pub fn fromString(s: []const u8) ?ShadowRootMode {
        if (std.mem.eql(u8, s, "open")) return .open;
        if (std.mem.eql(u8, s, "closed")) return .closed;
        return null;
    }
    
    pub fn toString(self: ShadowRootMode) []const u8 {
        return switch (self) {
            .open => "open",
            .closed => "closed",
        };
    }
};
```

## Callback Types

**WebIDL:**
```webidl
callback interface EventListener {
  undefined handleEvent(Event event);
};
```

**Zig Implementation:**
```zig
pub const EventListener = struct {
    ptr: *anyopaque,
    handleEventFn: *const fn (*anyopaque, *Event) void,
    
    pub fn handleEvent(self: EventListener, event: *Event) void {
        self.handleEventFn(self.ptr, event);
    }
};

// Or use function pointer directly:
pub const EventListenerFn = *const fn (*Event) void;
```

## Constants

**WebIDL:**
```webidl
interface Node {
  const unsigned short ELEMENT_NODE = 1;
  const unsigned short TEXT_NODE = 3;
};
```

**Zig Implementation:**
```zig
pub const Node = struct {
    pub const ELEMENT_NODE: u16 = 1;
    pub const TEXT_NODE: u16 = 3;
    
    // Or use enum:
    pub const Type = enum(u16) {
        element = 1,
        text = 3,
        comment = 8,
        document = 9,
    };
};
```

## Error Handling

WebIDL uses exceptions, Zig uses error unions.

**WebIDL:**
```webidl
Element createElement(DOMString localName);
// Throws InvalidCharacterError if localName invalid
```

**Zig Implementation:**
```zig
pub const DOMError = error{
    InvalidCharacterError,
    HierarchyRequestError,
    NotFoundError,
};

pub fn createElement(
    self: *Document,
    local_name: []const u8,
) (Allocator.Error || DOMError)!*Element {
    // Validate
    try validateName(local_name); // May return error.InvalidCharacterError
    
    // Allocate
    const elem = try Element.create(self.context, local_name); // May return error.OutOfMemory
    
    return elem;
}
```

## Common Patterns

### Getter/Setter Pairs

**WebIDL:**
```webidl
attribute DOMString id;
```

**Zig Implementation:**
```zig
// Getter
pub fn id(self: *Element) []const u8 {
    return self.getAttribute("id") orelse "";
}

// Setter
pub fn setId(self: *Element, value: []const u8) !void {
    try self.setAttribute("id", value);
}
```

### Readonly Attributes

**WebIDL:**
```webidl
readonly attribute DOMString tagName;
```

**Zig Implementation:**
```zig
// Only getter, no setter
pub fn tagName(self: *Element) []const u8 {
    return self.tag_name;
}
```

### Method Overloading (Not in WebIDL, but common pattern)

**WebIDL:**
```webidl
Node insertBefore(Node node, Node? child);
Node appendChild(Node node);
```

**Zig Implementation:**
```zig
// No overloading in Zig, use different names or optional parameters
pub fn insertBefore(self: *Node, node: *Node, child: ?*Node) !*Node { }
pub fn appendChild(self: *Node, node: *Node) !*Node { }
```

## Quick Reference

### Most Common Mappings

```zig
// WebIDL → Zig Quick Reference
undefined                    → void
DOMString                    → []const u8
DOMString?                   → ?[]const u8
unsigned long                → u32
Node                         → *Node
Node?                        → ?*Node
sequence<Node>               → []const *Node
[NewObject] Element          → !*Element
[SameObject] NodeList        → *NodeList
(Node or DOMString)          → union { node: *Node, string: []const u8 }
```

### Type Checklist

When mapping a WebIDL signature:
1. ✅ Check return type (`undefined` → `void`)
2. ✅ Check nullability (`?` marker)
3. ✅ Check extended attributes ([NewObject], [SameObject])
4. ✅ Check for union types
5. ✅ Check for variadic parameters (...)
6. ✅ Map errors to Zig error unions
7. ✅ Add `!` for fallible operations (allocation, validation)
