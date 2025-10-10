# DOM Inheritance Model in Zig

## Current Architecture

### How It Works

The current implementation uses **composition over inheritance**, which is idiomatic Zig. Here's the structure:

```zig
// Node is the base structure
pub const Node = struct {
    event_target: EventTarget,      // Embedded EventTarget
    node_type: NodeType,             // Element, Text, Comment, etc.
    node_name: []const u8,
    node_value: ?[]const u8,
    parent_node: ?*Node,
    child_nodes: NodeList,
    owner_document: ?*anyopaque,
    ref_count: usize,
    allocator: std.mem.Allocator,
    element_data_ptr: ?*anyopaque,   // Points to ElementData for elements
    // ... Node methods work on *Node
};

// Element-specific data stored separately
pub const ElementData = struct {
    tag_name: []const u8,
    attributes: NamedNodeMap,
    class_list: DOMTokenList,
};

// Element provides static functions that operate on *Node
pub const Element = struct {
    pub fn create(allocator: Allocator, tag_name: []const u8) !*Node { ... }
    pub fn setAttribute(node: *Node, name: []const u8, value: []const u8) !void { ... }
    pub fn getAttribute(node: *const Node, name: []const u8) ?[]const u8 { ... }
    // ... all Element methods take *Node as first parameter
};
```

### Key Points

1. **All elements are `*Node` pointers**
   - `Element.create()` returns `*Node`, not a separate Element type
   - The node's `node_type` is `.element_node`
   - Element-specific data is stored in `element_data_ptr`

2. **Element methods are static functions**
   - They take `*Node` as the first parameter
   - They operate on any Node where `node_type == .element_node`

3. **All Node methods work on elements**
   - Since elements ARE nodes, all Node methods work:
   - `node.appendChild()`, `node.removeChild()`, etc.
   - Full tree manipulation capabilities

## Can You Create HTML Elements?

**Yes, absolutely!** Here's how you would do it:

### Example: Creating an HTMLDivElement

```zig
// examples/html_element_demo.zig
const std = @import("std");
const dom = @import("dom");
const Node = dom.Node;
const Element = dom.Element;

/// HTMLDivElement - Inherits all Element functionality
pub const HTMLDivElement = struct {
    // Store the underlying Node pointer
    node: *Node,
    
    /// Create a new div element
    pub fn create(allocator: std.mem.Allocator) !*HTMLDivElement {
        // Create the underlying element
        const node = try Element.create(allocator, "div");
        
        // Wrap it in our HTMLDivElement
        const div = try allocator.create(HTMLDivElement);
        div.* = .{ .node = node };
        
        return div;
    }
    
    /// Clean up (calls node.release())
    pub fn release(self: *HTMLDivElement) void {
        self.node.release();
        self.node.allocator.destroy(self);
    }
    
    // All Element methods are available through delegation
    pub fn setAttribute(self: *HTMLDivElement, name: []const u8, value: []const u8) !void {
        return Element.setAttribute(self.node, name, value);
    }
    
    pub fn getAttribute(self: *const HTMLDivElement, name: []const u8) ?[]const u8 {
        return Element.getAttribute(self.node, name);
    }
    
    pub fn appendChild(self: *HTMLDivElement, child: *Node) !*Node {
        return self.node.appendChild(child);
    }
    
    // Add div-specific methods
    pub fn setAlign(self: *HTMLDivElement, align: []const u8) !void {
        return self.setAttribute("align", align);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Create an HTMLDivElement
    const div = try HTMLDivElement.create(allocator);
    defer div.release();
    
    // Use Element methods
    try div.setAttribute("id", "main-content");
    try div.setAttribute("class", "container");
    
    // Use div-specific method
    try div.setAlign("center");
    
    // Use Node methods (tree manipulation)
    const span = try Element.create(allocator, "span");
    _ = try div.appendChild(span);
    
    std.debug.print("Created div with ID: {s}\n", .{div.getAttribute("id").?});
}
```

### Better Approach: Using Composition Pattern

For a cleaner API that avoids manual delegation, you could use Zig's struct embedding:

```zig
/// HTMLElement - Base for all HTML elements
pub const HTMLElement = struct {
    node: *Node,
    
    // Common HTML element methods
    pub fn getId(self: *const HTMLElement) ?[]const u8 {
        return Element.getAttribute(self.node, "id");
    }
    
    pub fn setId(self: *HTMLElement, id: []const u8) !void {
        return Element.setAttribute(self.node, "id", id);
    }
    
    pub fn getClassName(self: *const HTMLElement) ![]const u8 {
        return Element.getClassName(self.node);
    }
    
    pub fn setClassName(self: *HTMLElement, class_name: []const u8) !void {
        return Element.setClassName(self.node, class_name);
    }
};

/// HTMLDivElement - Specific div element
pub const HTMLDivElement = struct {
    base: HTMLElement,  // Embed HTMLElement
    
    pub fn create(allocator: std.mem.Allocator) !*HTMLDivElement {
        const node = try Element.create(allocator, "div");
        const div = try allocator.create(HTMLDivElement);
        div.* = .{ .base = .{ .node = node } };
        return div;
    }
    
    pub fn release(self: *HTMLDivElement) void {
        self.base.node.release();
        self.base.node.allocator.destroy(self);
    }
    
    // Inherit all HTMLElement methods via base
    pub fn setId(self: *HTMLDivElement, id: []const u8) !void {
        return self.base.setId(id);
    }
    
    pub fn appendChild(self: *HTMLDivElement, child: *Node) !*Node {
        return self.base.node.appendChild(child);
    }
    
    // Div-specific attributes
    pub fn setAlign(self: *HTMLDivElement, align: []const u8) !void {
        return Element.setAttribute(self.base.node, "align", align);
    }
};

/// HTMLInputElement - Specific input element
pub const HTMLInputElement = struct {
    base: HTMLElement,
    
    pub fn create(allocator: std.mem.Allocator) !*HTMLInputElement {
        const node = try Element.create(allocator, "input");
        const input = try allocator.create(HTMLInputElement);
        input.* = .{ .base = .{ .node = node } };
        return input;
    }
    
    pub fn release(self: *HTMLInputElement) void {
        self.base.node.release();
        self.base.node.allocator.destroy(self);
    }
    
    // Input-specific methods
    pub fn setType(self: *HTMLInputElement, input_type: []const u8) !void {
        return Element.setAttribute(self.base.node, "type", input_type);
    }
    
    pub fn setValue(self: *HTMLInputElement, value: []const u8) !void {
        return Element.setAttribute(self.base.node, "value", value);
    }
    
    pub fn getValue(self: *const HTMLInputElement) ?[]const u8 {
        return Element.getAttribute(self.base.node, "value");
    }
    
    pub fn setPlaceholder(self: *HTMLInputElement, placeholder: []const u8) !void {
        return Element.setAttribute(self.base.node, "placeholder", placeholder);
    }
};
```

### Usage Example

```zig
const div = try HTMLDivElement.create(allocator);
defer div.release();

try div.setId("main");
try div.setClassName("container mx-auto");
try div.setAlign("center");

const input = try HTMLInputElement.create(allocator);
defer input.release();

try input.setType("text");
try input.setPlaceholder("Enter your name");
try input.setValue("John Doe");

_ = try div.appendChild(input.base.node);

std.debug.print("Input value: {s}\n", .{input.getValue().?});
```

## What You Get From Element

Every HTML element you create will have access to all Element methods:

### Attributes
- `setAttribute()`, `getAttribute()`
- `removeAttribute()`, `hasAttribute()`
- `toggleAttribute()`
- `getAttributeNames()`

### Classes
- `getClassName()`, `setClassName()`
- Access to `classList` (DOMTokenList)

### Tree Traversal
- `getElementById()`
- `getElementsByTagName()`
- `getElementsByClassName()`
- `querySelector()`, `querySelectorAll()`
- `matches()`

### Element Navigation
- `getFirstElementChild()`
- `getLastElementChild()`
- `getChildElementCount()`

### Plus All Node Methods
- `appendChild()`, `insertBefore()`, `removeChild()`, `replaceChild()`
- `cloneNode()`
- `contains()`
- `compareDocumentPosition()`
- Full tree manipulation

### Plus All EventTarget Methods
- `addEventListener()`, `removeEventListener()`
- `dispatchEvent()`
- Full event system

## Recommendations

### For a Complete HTML DOM Implementation

If you want to build a full HTML DOM implementation on top of this, I recommend:

1. **Create an html.zig module**
   ```zig
   // src/html.zig
   pub const HTMLElement = @import("html/element.zig").HTMLElement;
   pub const HTMLDivElement = @import("html/div_element.zig").HTMLDivElement;
   pub const HTMLSpanElement = @import("html/span_element.zig").HTMLSpanElement;
   pub const HTMLInputElement = @import("html/input_element.zig").HTMLInputElement;
   // ... etc
   ```

2. **Use composition pattern** (shown above)
   - Base `HTMLElement` struct with common methods
   - Specific elements embed `HTMLElement`
   - Delegate to underlying `Node`

3. **Add HTML-specific validation**
   ```zig
   pub fn setValue(self: *HTMLInputElement, value: []const u8) !void {
       // Validate that this is actually an input element
       const data = Element.getData(self.base.node);
       if (!std.mem.eql(u8, data.tag_name, "INPUT")) {
           return error.InvalidElement;
       }
       return Element.setAttribute(self.base.node, "value", value);
   }
   ```

4. **Implement HTML-specific behavior**
   ```zig
   pub fn submit(self: *HTMLFormElement) !void {
       // Fire submit event
       // Validate form
       // Collect form data
       // etc.
   }
   ```

## Summary

✅ **Yes, you can create HTML elements that inherit all Element functionality**

The current implementation:
- Uses composition (idiomatic Zig)
- All Element methods operate on `*Node`
- Elements ARE nodes, so they have full Node capabilities
- You can wrap nodes in HTML-specific structs

**To create HTML elements:**
1. Create wrapper structs (HTMLDivElement, etc.)
2. Store the underlying `*Node` pointer
3. Delegate to Element/Node methods
4. Add HTML-specific methods as needed

This gives you the full power of inheritance without the complexity, and stays true to Zig's philosophy of explicit, simple composition over implicit inheritance.
