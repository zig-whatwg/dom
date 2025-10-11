const std = @import("std");
const dom = @import("dom");
const Element = dom.Element;
const Text = dom.Text;

// ============================================================================
// DOM CRUD BENCHMARKS
// ============================================================================

pub fn benchCreateElement(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();
}

pub fn benchCreateElementWithAttributes(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();
    try Element.setAttribute(elem, "id", "test");
    try Element.setAttribute(elem, "class", "active");
    try Element.setAttribute(elem, "data-value", "123");
}

pub fn benchCreateTextNode(allocator: std.mem.Allocator) !void {
    const text = try Text.init(allocator, "Hello, World!");
    defer text.release();
}

pub fn benchAppendChild(allocator: std.mem.Allocator) !void {
    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "span");
    _ = try parent.appendChild(child);
}

pub fn benchAppendMultipleChildren(allocator: std.mem.Allocator) !void {
    const parent = try Element.create(allocator, "div");
    defer parent.release();

    var i: usize = 0;
    while (i < 10) : (i += 1) {
        const child = try Element.create(allocator, "span");
        _ = try parent.appendChild(child);
    }
}

pub fn benchRemoveChild(allocator: std.mem.Allocator) !void {
    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "span");
    // Don't defer - removeChild() releases the node internally
    _ = try parent.appendChild(child);

    _ = try parent.removeChild(child);
}

pub fn benchSetAttribute(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();
    try Element.setAttribute(elem, "data-value", "test");
}

pub fn benchGetAttribute(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();
    try Element.setAttribute(elem, "data-value", "test");
    _ = Element.getAttribute(elem, "data-value");
}

pub fn benchClassOperations(allocator: std.mem.Allocator) !void {
    const elem = try Element.create(allocator, "div");
    defer elem.release();
    try Element.setClassName(elem, "active");
}
