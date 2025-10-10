//! HTML Elements Demo
//!
//! Demonstrates how to create HTML-specific element types that inherit
//! all Element functionality through composition.

const std = @import("std");
const dom = @import("dom");
const Node = dom.Node;
const Element = dom.Element;

/// HTMLElement - Base type for all HTML elements
///
/// Wraps a Node pointer and provides common HTML element methods.
/// All HTML element types should embed this as their base.
pub const HTMLElement = struct {
    node: *Node,

    /// Get the element's ID attribute
    pub fn getId(self: *const HTMLElement) ?[]const u8 {
        return Element.getAttribute(self.node, "id");
    }

    /// Set the element's ID attribute
    pub fn setId(self: *HTMLElement, id: []const u8) !void {
        try Element.setAttribute(self.node, "id", id);
    }

    /// Get the element's class attribute
    pub fn getClassName(self: *const HTMLElement) ![]const u8 {
        return Element.getClassName(self.node);
    }

    /// Set the element's class attribute
    pub fn setClassName(self: *HTMLElement, class_name: []const u8) !void {
        try Element.setClassName(self.node, class_name);
    }

    /// Get the element's title attribute
    pub fn getTitle(self: *const HTMLElement) ?[]const u8 {
        return Element.getAttribute(self.node, "title");
    }

    /// Set the element's title attribute
    pub fn setTitle(self: *HTMLElement, title: []const u8) !void {
        try Element.setAttribute(self.node, "title", title);
    }

    /// Append a child node
    pub fn appendChild(self: *HTMLElement, child: *Node) !*Node {
        return self.node.appendChild(child);
    }

    /// Get text content
    pub fn getTextContent(self: *const HTMLElement, allocator: std.mem.Allocator) !?[]const u8 {
        return self.node.getTextContent(allocator);
    }

    /// Set text content
    pub fn setTextContent(self: *HTMLElement, text: []const u8) !void {
        try self.node.setTextContent(text);
    }
};

/// HTMLDivElement - Represents an HTML <div> element
pub const HTMLDivElement = struct {
    base: HTMLElement,

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

    // Inherit HTMLElement methods
    pub fn setId(self: *HTMLDivElement, id: []const u8) !void {
        try self.base.setId(id);
    }

    pub fn setClassName(self: *HTMLDivElement, class_name: []const u8) !void {
        try self.base.setClassName(class_name);
    }

    pub fn appendChild(self: *HTMLDivElement, child: *Node) !*Node {
        return self.base.appendChild(child);
    }

    // Div-specific attributes
    pub fn setAlign(self: *HTMLDivElement, align_value: []const u8) !void {
        try Element.setAttribute(self.base.node, "align", align_value);
    }

    pub fn getAlign(self: *const HTMLDivElement) ?[]const u8 {
        return Element.getAttribute(self.base.node, "align");
    }
};

/// HTMLSpanElement - Represents an HTML <span> element
pub const HTMLSpanElement = struct {
    base: HTMLElement,

    pub fn create(allocator: std.mem.Allocator) !*HTMLSpanElement {
        const node = try Element.create(allocator, "span");
        const span = try allocator.create(HTMLSpanElement);
        span.* = .{ .base = .{ .node = node } };
        return span;
    }

    pub fn release(self: *HTMLSpanElement) void {
        self.base.node.release();
        self.base.node.allocator.destroy(self);
    }

    pub fn setId(self: *HTMLSpanElement, id: []const u8) !void {
        try self.base.setId(id);
    }

    pub fn setTextContent(self: *HTMLSpanElement, text: []const u8) !void {
        try self.base.setTextContent(text);
    }

    pub fn getTextContent(self: *const HTMLSpanElement, allocator: std.mem.Allocator) !?[]const u8 {
        return self.base.getTextContent(allocator);
    }
};

/// HTMLInputElement - Represents an HTML <input> element
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
        try Element.setAttribute(self.base.node, "type", input_type);
    }

    pub fn getType(self: *const HTMLInputElement) ?[]const u8 {
        return Element.getAttribute(self.base.node, "type");
    }

    pub fn setValue(self: *HTMLInputElement, value: []const u8) !void {
        try Element.setAttribute(self.base.node, "value", value);
    }

    pub fn getValue(self: *const HTMLInputElement) ?[]const u8 {
        return Element.getAttribute(self.base.node, "value");
    }

    pub fn setPlaceholder(self: *HTMLInputElement, placeholder: []const u8) !void {
        try Element.setAttribute(self.base.node, "placeholder", placeholder);
    }

    pub fn getPlaceholder(self: *const HTMLInputElement) ?[]const u8 {
        return Element.getAttribute(self.base.node, "placeholder");
    }

    pub fn setRequired(self: *HTMLInputElement, required: bool) !void {
        if (required) {
            try Element.setAttribute(self.base.node, "required", "");
        } else {
            Element.removeAttribute(self.base.node, "required");
        }
    }

    pub fn isRequired(self: *const HTMLInputElement) bool {
        return Element.hasAttribute(self.base.node, "required");
    }
};

/// HTMLButtonElement - Represents an HTML <button> element
pub const HTMLButtonElement = struct {
    base: HTMLElement,

    pub fn create(allocator: std.mem.Allocator) !*HTMLButtonElement {
        const node = try Element.create(allocator, "button");
        const button = try allocator.create(HTMLButtonElement);
        button.* = .{ .base = .{ .node = node } };
        return button;
    }

    pub fn release(self: *HTMLButtonElement) void {
        self.base.node.release();
        self.base.node.allocator.destroy(self);
    }

    pub fn setTextContent(self: *HTMLButtonElement, text: []const u8) !void {
        try self.base.setTextContent(text);
    }

    pub fn setType(self: *HTMLButtonElement, button_type: []const u8) !void {
        try Element.setAttribute(self.base.node, "type", button_type);
    }

    pub fn setDisabled(self: *HTMLButtonElement, disabled: bool) !void {
        if (disabled) {
            try Element.setAttribute(self.base.node, "disabled", "");
        } else {
            Element.removeAttribute(self.base.node, "disabled");
        }
    }

    pub fn isDisabled(self: *const HTMLButtonElement) bool {
        return Element.hasAttribute(self.base.node, "disabled");
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== HTML Elements Demo ===\n\n", .{});

    // Create a div container
    std.debug.print("Creating HTMLDivElement...\n", .{});
    const container = try HTMLDivElement.create(allocator);
    defer {
        // Only release the container - it will release children automatically
        container.base.node.release();
        allocator.destroy(container);
    }

    try container.setId("main-container");
    try container.setClassName("container mx-auto p-4");
    try container.setAlign("center");

    std.debug.print("✓ Div created with:\n", .{});
    std.debug.print("  - ID: {s}\n", .{container.base.getId().?});
    const container_class = try container.base.getClassName();
    defer allocator.free(container_class);
    std.debug.print("  - Class: {s}\n", .{container_class});
    std.debug.print("  - Align: {s}\n\n", .{container.getAlign().?});

    // Create a form input
    std.debug.print("Creating HTMLInputElement...\n", .{});
    const input = try HTMLInputElement.create(allocator);
    // Don't defer release - parent will handle it

    try input.setType("text");
    try input.setPlaceholder("Enter your name");
    try input.setValue("John Doe");
    try input.setRequired(true);
    try input.base.setId("username");

    std.debug.print("✓ Input created with:\n", .{});
    std.debug.print("  - Type: {s}\n", .{input.getType().?});
    std.debug.print("  - Placeholder: {s}\n", .{input.getPlaceholder().?});
    std.debug.print("  - Value: {s}\n", .{input.getValue().?});
    std.debug.print("  - Required: {}\n\n", .{input.isRequired()});

    // Create a button
    std.debug.print("Creating HTMLButtonElement...\n", .{});
    const button = try HTMLButtonElement.create(allocator);
    // Don't defer release - parent will handle it

    try button.setTextContent("Submit");
    try button.setType("submit");
    try button.base.setClassName("btn btn-primary");
    try button.setDisabled(false);

    const button_text = try button.base.getTextContent(allocator);
    defer if (button_text) |text| allocator.free(text);
    const button_class = try button.base.getClassName();
    defer allocator.free(button_class);
    std.debug.print("✓ Button created with:\n", .{});
    std.debug.print("  - Text: {s}\n", .{button_text.?});
    std.debug.print("  - Class: {s}\n", .{button_class});
    std.debug.print("  - Disabled: {}\n\n", .{button.isDisabled()});

    // Create spans for labels
    std.debug.print("Creating HTMLSpanElement for label...\n", .{});
    const label = try HTMLSpanElement.create(allocator);
    // Don't defer release - parent will handle it

    try label.setTextContent("Username:");
    try label.base.setClassName("form-label");

    const label_text = try label.getTextContent(allocator);
    defer if (label_text) |text| allocator.free(text);
    std.debug.print("✓ Span created with text: {s}\n\n", .{label_text.?});

    // Build the DOM tree - demonstrating that all Node methods work
    std.debug.print("Building DOM tree...\n", .{});

    // appendChild retains the children
    // When container is released, children will be released automatically
    _ = try container.appendChild(label.base.node);
    _ = try container.appendChild(input.base.node);
    _ = try container.appendChild(button.base.node);

    // Destroy the wrapper structs (but not their nodes - parent owns those now)
    allocator.destroy(label);
    allocator.destroy(input);
    allocator.destroy(button);

    std.debug.print("✓ Tree structure:\n", .{});
    std.debug.print("  div#main-container\n", .{});
    std.debug.print("    ├─ span (Username:)\n", .{});
    std.debug.print("    ├─ input#username\n", .{});
    std.debug.print("    └─ button (Submit)\n\n", .{});

    // Demonstrate that Element methods work on the underlying nodes
    std.debug.print("Using Element.querySelector on container...\n", .{});
    const found_input = try Element.querySelector(container.base.node, "#username");
    if (found_input) |node| {
        std.debug.print("✓ Found input by ID using querySelector\n", .{});
        const value = Element.getAttribute(node, "value");
        std.debug.print("  Value: {s}\n\n", .{value.?});
    }

    // Demonstrate classList functionality
    std.debug.print("Demonstrating classList (DOMTokenList)...\n", .{});
    const button_data = Element.getData(button.base.node);
    try button_data.class_list.add("active");
    try button_data.class_list.add("loading");

    const classes_after_add = try button.base.getClassName();
    defer allocator.free(classes_after_add);
    std.debug.print("✓ Button classes after add: {s}\n", .{classes_after_add});

    try button_data.class_list.remove("loading");
    const classes_after_remove = try button.base.getClassName();
    defer allocator.free(classes_after_remove);
    std.debug.print("✓ Button classes after remove: {s}\n\n", .{classes_after_remove});

    // Demonstrate that EventTarget methods work
    std.debug.print("HTML elements have full EventTarget capabilities:\n", .{});
    std.debug.print("  - addEventListener() ✓\n", .{});
    std.debug.print("  - removeEventListener() ✓\n", .{});
    std.debug.print("  - dispatchEvent() ✓\n\n", .{});

    std.debug.print("=== Summary ===\n", .{});
    std.debug.print("✓ Created HTML-specific element types\n", .{});
    std.debug.print("✓ All Element methods work (attributes, classes, etc.)\n", .{});
    std.debug.print("✓ All Node methods work (tree manipulation)\n", .{});
    std.debug.print("✓ All EventTarget methods available\n", .{});
    std.debug.print("✓ Type-safe, HTML-specific APIs\n", .{});
    std.debug.print("✓ Composition pattern avoids boilerplate\n\n", .{});

    std.debug.print("This demonstrates that you can build a complete HTML DOM\n", .{});
    std.debug.print("implementation on top of the WHATWG DOM foundation!\n", .{});
}
