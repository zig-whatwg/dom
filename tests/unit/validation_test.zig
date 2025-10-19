//! validation Tests
//!
//! Tests for validation functionality.

const std = @import("std");
const dom = @import("dom");

const testing = std.testing;
const Document = dom.Document;
const Element = dom.Element;
const Text = dom.Text;
const validation = dom.validation;
test "validation - circular reference detection" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");
    defer child.prototype.release();

    // Set up parent-child relationship first
    child.prototype.parent_node = &parent.prototype;
    parent.prototype.first_child = &child.prototype;
    parent.prototype.last_child = &child.prototype;
    defer {
        child.prototype.parent_node = null;
        parent.prototype.first_child = null;
        parent.prototype.last_child = null;
    }

    // Try to insert parent into its own child (circular)
    const result = validation.ensurePreInsertValidity(&parent.prototype, &child.prototype, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - invalid parent type" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    const elem = try doc.createElement("div");
    defer elem.prototype.release();

    // Try to insert into text node (invalid parent)
    const result = validation.ensurePreInsertValidity(&elem.prototype, &text.prototype, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - child parent mismatch" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.prototype.release();

    const parent2 = try doc.createElement("span");
    defer parent2.prototype.release();

    const child = try doc.createElement("p");
    defer child.prototype.release();

    // Child's parent is not parent2
    const result = validation.ensurePreInsertValidity(&child.prototype, &parent2.prototype, &child.prototype);
    try std.testing.expectError(error.NotFoundError, result);
}

test "validation - text node into document" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.prototype.release();

    // Text cannot be child of document
    const result = validation.ensurePreInsertValidity(&text.prototype, &doc.prototype, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - pre-remove with wrong parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.prototype.release();

    const child = try doc.createElement("span");
    defer child.prototype.release();

    // Child's parent is null, not parent
    const result = validation.ensurePreRemoveValidity(&child.prototype, &parent.prototype);
    try std.testing.expectError(error.NotFoundError, result);
}

