# DOM Library Extensibility Guide

This document explains how to extend the generic DOM library to create specialized implementations like HTML-DOM or XML-DOM.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prototype Chain](#prototype-chain)
- [Extension Points](#extension-points)
- [Complete Example: HTMLElement](#complete-example-htmlelement)
- [Factory Injection](#factory-injection)
- [Best Practices](#best-practices)

## Architecture Overview

The DOM library uses a **prototype-based architecture** following WHATWG specifications:

```
EventTarget (8 bytes)
  ├─ Node : EventTarget (104 bytes)
  │    ├─ Element : Node
  │    ├─ Text : Node
  │    ├─ Document : Node
  │    └─ ShadowRoot : Node
  └─ AbortSignal : EventTarget (56 bytes)
```

### Key Concepts

1. **Prototype Chain**: All types have a `prototype` field as their first field
2. **VTable Polymorphism**: Custom behavior via `NodeVTable` injection
3. **Factory Injection**: Custom types returned from `Document` methods
4. **Zero Breaking Changes**: Existing code works unchanged

## Prototype Chain

The `prototype` field pattern enables clean inheritance:

```zig
// EventTarget (base)
pub const EventTarget = struct {
    vtable: *const EventTargetVTable,
};

// Node extends EventTarget
pub const Node = struct {
    prototype: EventTarget,  // MUST be first field
    vtable: *const NodeVTable,
    // ... other fields
};

// Element extends Node  
pub const Element = struct {
    prototype: Node,  // MUST be first field
    tag_name: []const u8,
    // ... other fields
};
```

**Why "prototype"?**
- Aligns with JavaScript `Object.getPrototypeOf()` semantics
- Uniform naming across all types
- Self-documenting inheritance chain
- Enables `@fieldParentPtr("prototype", ...)` for upcasting

## Extension Points

### 1. Custom VTable (Polymorphic Behavior)

Override virtual methods for custom behavior:

```zig
const HTMLElement = struct {
    element: Element,  // Contains prototype chain
    
    // Custom fields
    inner_html: []const u8,
    
    // Custom vtable
    const html_vtable = NodeVTable{
        .deinit = htmlDeinit,
        .node_name = htmlNodeName,
        .node_value = htmlNodeValue,
        .set_node_value = htmlSetNodeValue,
        .clone_node = htmlCloneNode,
        .adopting_steps = htmlAdoptingSteps,
    };
    
    fn htmlDeinit(node: *Node) void {
        const elem: *Element = @fieldParentPtr("prototype", node);
        const html_elem: *HTMLElement = @fieldParentPtr("element", elem);
        // Custom cleanup
        html_elem.element.prototype.allocator.free(html_elem.inner_html);
        // Call default Element deinit
        Element.deinitImpl(node);
    }
    
    // ... other vtable implementations
};
```

### 2. Factory Injection (Custom Types from Document)

Inject factories so `Document.createElement()` returns your custom type:

```zig
fn createHTMLElement(allocator: Allocator, tag_name: []const u8) !*Element {
    // Create Element with custom vtable
    const elem = try Element.createWithVTable(
        allocator,
        tag_name,
        &HTMLElement.html_vtable,
    );
    
    // Wrap in HTMLElement container
    const html_elem = try allocator.create(HTMLElement);
    html_elem.* = .{
        .element = elem.*,
        .inner_html = "",
    };
    
    // Return as Element pointer (upcast)
    return &html_elem.element;
}

// Create HTML document with factory
const factories = Document.FactoryConfig{
    .element_factory = createHTMLElement,
};
const doc = try Document.initWithFactories(allocator, factories);

// Now createElement returns HTMLElement!
const elem = try doc.createElement("div");
// elem is *Element, but vtable points to HTMLElement.html_vtable
```

## Complete Example: HTMLElement

Here's a complete example of extending Element to create HTMLElement:

```zig
const std = @import("std");
const dom = @import("dom");

pub const HTMLElement = struct {
    /// Base Element (contains full prototype chain: EventTarget → Node → Element)
    element: dom.Element,
    
    /// HTML-specific fields
    inner_html: []const u8,
    outer_html: []const u8,
    class_list: std.ArrayList([]const u8),
    
    /// Custom NodeVTable for HTMLElement
    pub const html_vtable = dom.NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };
    
    /// Factory function for Document.initWithFactories()
    pub fn createForDocument(
        allocator: std.mem.Allocator,
        tag_name: []const u8,
    ) !*dom.Element {
        // Create base element with custom vtable
        const elem = try dom.Element.createWithVTable(
            allocator,
            tag_name,
            &html_vtable,
        );
        errdefer elem.prototype.release();
        
        // Allocate HTMLElement wrapper
        const html_elem = try allocator.create(HTMLElement);
        errdefer allocator.destroy(html_elem);
        
        html_elem.* = .{
            .element = elem.*,  // Copy Element struct
            .inner_html = "",
            .outer_html = "",
            .class_list = std.ArrayList([]const u8).init(allocator),
        };
        
        // Free the temporary Element (we copied its contents)
        allocator.destroy(elem);
        
        // Return as Element pointer
        return &html_elem.element;
    }
    
    // VTable implementations
    
    fn deinitImpl(node: *dom.Node) void {
        // Upcast to Element
        const elem: *dom.Element = @fieldParentPtr("prototype", node);
        // Upcast to HTMLElement
        const html_elem: *HTMLElement = @fieldParentPtr("element", elem);
        
        // Clean up HTML-specific data
        html_elem.class_list.deinit();
        html_elem.element.prototype.allocator.free(html_elem.inner_html);
        html_elem.element.prototype.allocator.free(html_elem.outer_html);
        
        // Call base Element deinit (handles attributes, bloom filter, Node base)
        dom.Element.deinitImpl(node);
        
        // Free HTMLElement struct itself
        const allocator = html_elem.element.prototype.allocator;
        allocator.destroy(html_elem);
    }
    
    fn nodeNameImpl(node: *const dom.Node) []const u8 {
        // HTML element names are uppercase per spec
        const elem: *const dom.Element = @fieldParentPtr("prototype", node);
        return toUpperCase(elem.tag_name);
    }
    
    fn cloneNodeImpl(node: *const dom.Node, deep: bool) !*dom.Node {
        const elem: *const dom.Element = @fieldParentPtr("prototype", node);
        const html_elem: *const HTMLElement = @fieldParentPtr("element", elem);
        
        // Clone with custom vtable
        const cloned_elem = try dom.Element.createWithVTable(
            html_elem.element.prototype.allocator,
            html_elem.element.tag_name,
            &html_vtable,
        );
        
        // Copy HTML-specific data
        const cloned_html = try html_elem.element.prototype.allocator.create(HTMLElement);
        cloned_html.* = .{
            .element = cloned_elem.*,
            .inner_html = try html_elem.element.prototype.allocator.dupe(u8, html_elem.inner_html),
            .outer_html = try html_elem.element.prototype.allocator.dupe(u8, html_elem.outer_html),
            .class_list = try html_elem.class_list.clone(),
        };
        
        // Clone attributes and children (if deep)
        // ... (omitted for brevity)
        
        return &cloned_html.element.prototype;
    }
    
    // ... other vtable implementations
    
    // HTML-specific methods
    
    pub fn innerHTML(self: *const HTMLElement) []const u8 {
        return self.inner_html;
    }
    
    pub fn setInnerHTML(self: *HTMLElement, html: []const u8) !void {
        const allocator = self.element.prototype.allocator;
        allocator.free(self.inner_html);
        self.inner_html = try allocator.dupe(u8, html);
        // Parse and set children from HTML...
    }
    
    pub fn classList(self: *HTMLElement) [][]const u8 {
        return self.class_list.items;
    }
};

// Usage

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Create HTML document with factory
    const factories = dom.Document.FactoryConfig{
        .element_factory = HTMLElement.createForDocument,
    };
    const doc = try dom.Document.initWithFactories(allocator, factories);
    defer doc.release();
    
    // createElement now returns HTMLElement (via Element pointer)!
    const div = try doc.createElement("div");
    
    // Can cast to HTMLElement for HTML-specific operations
    const html_div: *HTMLElement = @fieldParentPtr("element", div);
    try html_div.setInnerHTML("<p>Hello World</p>");
    
    std.debug.print("innerHTML: {s}\n", .{html_div.innerHTML()});
}
```

## Factory Injection

### Document-Level Factories

The recommended approach for most use cases:

```zig
const factories = Document.FactoryConfig{
    .element_factory = HTMLElement.createForDocument,
    .text_factory = HTMLText.createForDocument,  // Optional
    .comment_factory = null,  // Use default Comment
};

const doc = try Document.initWithFactories(allocator, factories);

// All document methods use your factories:
const elem = try doc.createElement("div");      // HTMLElement
const text = try doc.createTextNode("hello");   // HTMLText (if factory provided)
const comment = try doc.createComment("note");  // Default Comment
```

### Direct Creation with VTable

For standalone nodes not created via Document:

```zig
const elem = try Element.createWithVTable(
    allocator,
    "custom",
    &MyCustomElement.vtable,
);
defer elem.prototype.release();
```

## Best Practices

### 1. **Preserve Prototype Chain**

Always place base type as first field:

```zig
// ✅ CORRECT
pub const HTMLElement = struct {
    element: Element,  // First field
    // ... HTML-specific fields
};

// ❌ WRONG
pub const HTMLElement = struct {
    inner_html: []const u8,  // Wrong order!
    element: Element,
};
```

### 2. **Use @fieldParentPtr Correctly**

Upcast through the prototype chain:

```zig
fn deinitImpl(node: *Node) void {
    // Upcast Node → Element
    const elem: *Element = @fieldParentPtr("prototype", node);
    // Upcast Element → HTMLElement
    const html_elem: *HTMLElement = @fieldParentPtr("element", elem);
    // Now access HTMLElement fields
}
```

### 3. **Call Base Deinit**

Always call the base type's deinit:

```zig
fn deinitImpl(node: *Node) void {
    const html_elem: *HTMLElement = // ... upcast
    
    // 1. Clean up your fields first
    html_elem.class_list.deinit();
    
    // 2. Call base deinit (handles Element fields + Node cleanup)
    Element.deinitImpl(node);
    
    // 3. Free your wrapper struct last
    const allocator = html_elem.element.prototype.allocator;
    allocator.destroy(html_elem);
}
```

### 4. **Handle Memory Correctly**

The factory pattern requires careful memory management:

```zig
pub fn createForDocument(allocator: Allocator, tag_name: []const u8) !*Element {
    // Create base element
    const elem = try Element.createWithVTable(allocator, tag_name, &vtable);
    errdefer elem.prototype.release();
    
    // Allocate wrapper
    const wrapper = try allocator.create(Wrapper);
    errdefer allocator.destroy(wrapper);
    
    // Copy Element contents to wrapper
    wrapper.element = elem.*;
    
    // Free temporary Element (contents copied)
    allocator.destroy(elem);
    
    // Return as Element pointer (upcast)
    return &wrapper.element;
}
```

### 5. **Test Thoroughly**

Test all vtable methods and memory cleanup:

```zig
test "HTMLElement - custom behavior" {
    const allocator = std.testing.allocator;
    
    const factories = Document.FactoryConfig{
        .element_factory = HTMLElement.createForDocument,
    };
    const doc = try Document.initWithFactories(allocator, factories);
    defer doc.release();
    
    const div = try doc.createElement("div");
    const html_div: *HTMLElement = @fieldParentPtr("element", div);
    
    // Test HTML-specific methods
    try html_div.setInnerHTML("<p>Test</p>");
    try std.testing.expectEqualStrings("<p>Test</p>", html_div.innerHTML());
    
    // Memory automatically cleaned up via doc.release()
}
```

## Performance Considerations

- **VTable indirection**: One extra pointer dereference per virtual call (negligible)
- **Memory overhead**: Wrapper struct adds your custom fields only
- **Factory overhead**: One function call during creation (negligible)
- **Zero runtime cost** for code not using extensions

## Common Patterns

### XML Document

```zig
const XMLElement = struct {
    element: Element,
    namespace_uri: []const u8,
    
    // Custom vtable with XML-specific behavior
    pub const xml_vtable = NodeVTable{ /* ... */ };
    
    pub fn createForDocument(allocator: Allocator, tag_name: []const u8) !*Element {
        // Similar to HTMLElement pattern
    }
};

const xml_factories = Document.FactoryConfig{
    .element_factory = XMLElement.createForDocument,
};
const xml_doc = try Document.initWithFactories(allocator, xml_factories);
```

### Custom Elements (Web Components)

```zig
const CustomElement = struct {
    element: Element,
    shadow_root: ?*ShadowRoot,
    
    pub const custom_vtable = NodeVTable{ /* ... */ };
    
    pub fn createForDocument(allocator: Allocator, tag_name: []const u8) !*Element {
        // Check if tag_name contains hyphen (custom element requirement)
        if (std.mem.indexOf(u8, tag_name, "-") == null) {
            // Not a custom element, use default
            return Element.create(allocator, tag_name);
        }
        // Create custom element with shadow DOM support
    }
};
```

## Reference

- **WHATWG DOM Standard**: https://dom.spec.whatwg.org/
- **HTML Standard**: https://html.spec.whatwg.org/
- **XML Standard**: https://www.w3.org/TR/xml/

---

For questions or contributions, see [CONTRIBUTING.md](CONTRIBUTING.md).
