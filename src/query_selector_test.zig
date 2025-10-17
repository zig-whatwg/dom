//! Query Selector Tests
//!
//! Comprehensive tests for querySelector and querySelectorAll implementation.

const std = @import("std");
const testing = std.testing;
const Document = @import("document.zig").Document;
const Element = @import("element.zig").Element;
const DocumentFragment = @import("document_fragment.zig").DocumentFragment;

test "querySelector - simple type selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(&div.node);

    const result = try div.querySelector(allocator, "div");
    try testing.expect(result == null); // div is not a descendant of itself
}

test "querySelector - finds child element" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child = try doc.createElement("p");
    _ = try parent.node.appendChild(&child.node);

    const result = try parent.querySelector(allocator, "p");
    try testing.expect(result != null);
    try testing.expect(result.? == child);
}

test "querySelector - class selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("span");
    try child2.setAttribute("class", "highlight");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, ".highlight");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - ID selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("div");
    try child2.setAttribute("id", "main");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, "#main");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - compound selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    try child1.setAttribute("class", "text");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("p");
    try child2.setAttribute("class", "text highlight");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, "p.highlight");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - child combinator" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    const parent = try doc.createElement("div");
    try parent.setAttribute("class", "parent");
    _ = try root.node.appendChild(&parent.node);

    const child = try doc.createElement("p");
    _ = try parent.node.appendChild(&child.node);

    const result = try root.querySelector(allocator, "div.parent > p");
    try testing.expect(result != null);
    try testing.expect(result.? == child);
}

test "querySelector - returns null when no match" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child = try doc.createElement("p");
    _ = try parent.node.appendChild(&child.node);

    const result = try parent.querySelector(allocator, "span");
    try testing.expect(result == null);
}

test "querySelectorAll - finds multiple elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child2.node);

    const child3 = try doc.createElement("span");
    _ = try parent.node.appendChild(&child3.node);

    const results = try parent.querySelectorAll(allocator, "p");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == child1);
    try testing.expect(results[1] == child2);
}

test "querySelectorAll - returns empty array when no match" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child = try doc.createElement("p");
    _ = try parent.node.appendChild(&child.node);

    const results = try parent.querySelectorAll(allocator, "span");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 0), results.len);
}

test "querySelectorAll - with class selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    try child1.setAttribute("class", "text");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("div");
    try child2.setAttribute("class", "text");
    _ = try parent.node.appendChild(&child2.node);

    const child3 = try doc.createElement("span");
    _ = try parent.node.appendChild(&child3.node);

    const results = try parent.querySelectorAll(allocator, ".text");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == child1);
    try testing.expect(results[1] == child2);
}

test "querySelectorAll - finds nested elements" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("div");
    _ = try doc.node.appendChild(&root.node);

    const child1 = try doc.createElement("p");
    _ = try root.node.appendChild(&child1.node);

    const grandchild1 = try doc.createElement("span");
    _ = try child1.node.appendChild(&grandchild1.node);

    const child2 = try doc.createElement("div");
    _ = try root.node.appendChild(&child2.node);

    const grandchild2 = try doc.createElement("span");
    _ = try child2.node.appendChild(&grandchild2.node);

    const results = try root.querySelectorAll(allocator, "span");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == grandchild1);
    try testing.expect(results[1] == grandchild2);
}

test "Document.querySelector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.node.appendChild(&html.node);

    const body = try doc.createElement("body");
    _ = try html.node.appendChild(&body.node);

    const button = try doc.createElement("button");
    try button.setAttribute("class", "btn");
    _ = try body.node.appendChild(&button.node);

    const result = try doc.querySelector(".btn");
    try testing.expect(result != null);
    try testing.expect(result.? == button);
}

test "Document.querySelectorAll" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const html = try doc.createElement("html");
    _ = try doc.node.appendChild(&html.node);

    const body = try doc.createElement("body");
    _ = try html.node.appendChild(&body.node);

    const btn1 = try doc.createElement("button");
    _ = try body.node.appendChild(&btn1.node);

    const btn2 = try doc.createElement("button");
    _ = try body.node.appendChild(&btn2.node);

    const results = try doc.querySelectorAll("button");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == btn1);
    try testing.expect(results[1] == btn2);
}

test "DocumentFragment.querySelector" {
    const allocator = testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.node.release();

    const child1 = try Element.create(allocator, "p");
    _ = try fragment.node.appendChild(&child1.node);

    const child2 = try Element.create(allocator, "div");
    try child2.setAttribute("class", "target");
    _ = try fragment.node.appendChild(&child2.node);

    const result = try fragment.querySelector(allocator, ".target");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "DocumentFragment.querySelectorAll" {
    const allocator = testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.node.release();

    const child1 = try Element.create(allocator, "p");
    _ = try fragment.node.appendChild(&child1.node);

    const child2 = try Element.create(allocator, "p");
    _ = try fragment.node.appendChild(&child2.node);

    const results = try fragment.querySelectorAll(allocator, "p");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 2), results.len);
    try testing.expect(results[0] == child1);
    try testing.expect(results[1] == child2);
}

test "querySelector - attribute selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("input");
    try child1.setAttribute("type", "text");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("input");
    try child2.setAttribute("type", "submit");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, "input[type='submit']");
    try testing.expect(result != null);
    try testing.expect(result.? == child2);
}

test "querySelector - :first-child pseudo-class" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("ul");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("li");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("li");
    _ = try parent.node.appendChild(&child2.node);

    const result = try parent.querySelector(allocator, "li:first-child");
    try testing.expect(result != null);
    try testing.expect(result.? == child1);
}

test "querySelectorAll - universal selector" {
    const allocator = testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    _ = try doc.node.appendChild(&parent.node);

    const child1 = try doc.createElement("p");
    _ = try parent.node.appendChild(&child1.node);

    const child2 = try doc.createElement("span");
    _ = try parent.node.appendChild(&child2.node);

    const child3 = try doc.createElement("div");
    _ = try parent.node.appendChild(&child3.node);

    const results = try parent.querySelectorAll(allocator, "*");
    defer allocator.free(results);

    try testing.expectEqual(@as(usize, 3), results.len);
}
