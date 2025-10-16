//! DOM tree validation functions per WHATWG DOM §4.2.4
//!
//! This module implements the validation algorithms required for tree manipulation:
//! - Pre-insert validity checking
//! - Replace validity checking
//! - Pre-remove validity checking
//!
//! All functions follow WHATWG DOM specification exactly.
//! Spec: https://dom.spec.whatwg.org/#mutation-algorithms

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// DOM exception errors per WHATWG DOM specification
pub const DOMError = error{
    HierarchyRequestError,
    NotFoundError,
};

/// Ensures pre-insert validity of a node into a parent before a child.
///
/// Implements WHATWG DOM "ensure pre-insert validity" algorithm per §4.2.4.
///
/// ## Algorithm Steps
/// 1. If parent is not Document, DocumentFragment, or Element → HierarchyRequestError
/// 2. If node is host-including inclusive ancestor of parent → HierarchyRequestError
/// 3. If child non-null and child's parent ≠ parent → NotFoundError
/// 4. If node is not DocumentFragment, DocumentType, Element, or CharacterData → HierarchyRequestError
/// 5. If (node is Text and parent is Document) OR (node is DocumentType and parent is not Document) → HierarchyRequestError
/// 6. If parent is Document, additional element/doctype constraints → HierarchyRequestError
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-node-ensure-pre-insertion-validity
pub fn ensurePreInsertValidity(
    node: *Node,
    parent: *Node,
    child: ?*Node,
) DOMError!void {
    // Step 1: Parent must be Document, DocumentFragment, or Element
    if (parent.node_type != .document and
        parent.node_type != .document_fragment and
        parent.node_type != .element)
    {
        return error.HierarchyRequestError;
    }

    // Step 2: Node must not be ancestor of parent (circular reference check)
    if (isHostIncludingInclusiveAncestor(node, parent)) {
        return error.HierarchyRequestError;
    }

    // Step 3: If child is non-null, its parent must be parent
    if (child) |c| {
        if (c.parent_node != parent) {
            return error.NotFoundError;
        }
    }

    // Step 4: Node must be valid type for insertion
    if (node.node_type != .document_fragment and
        node.node_type != .document_type and
        node.node_type != .element and
        node.node_type != .text and
        node.node_type != .comment and
        node.node_type != .processing_instruction)
    {
        return error.HierarchyRequestError;
    }

    // Step 5: Text nodes cannot be children of Document
    if (node.node_type == .text and parent.node_type == .document) {
        return error.HierarchyRequestError;
    }

    // Step 5 (continued): DocumentType can only be child of Document
    if (node.node_type == .document_type and parent.node_type != .document) {
        return error.HierarchyRequestError;
    }

    // Step 6: If parent is a document, check element/doctype constraints
    if (parent.node_type == .document) {
        try ensureDocumentConstraints(node, parent, child);
    }
}

/// Ensures replace validity of replacing child with node within parent.
///
/// Implements WHATWG DOM "ensure replace validity" algorithm per §4.2.4.
/// Similar to pre-insert validity but with different document constraints.
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-node-replace
pub fn ensureReplaceValidity(
    node: *Node,
    child: *Node,
    parent: *Node,
) DOMError!void {
    // Step 1: Parent must be Document, DocumentFragment, or Element
    if (parent.node_type != .document and
        parent.node_type != .document_fragment and
        parent.node_type != .element)
    {
        return error.HierarchyRequestError;
    }

    // Step 2: Node must not be ancestor of parent
    if (isHostIncludingInclusiveAncestor(node, parent)) {
        return error.HierarchyRequestError;
    }

    // Step 3: Child's parent must be parent
    if (child.parent_node != parent) {
        return error.NotFoundError;
    }

    // Step 4: Node must be valid type
    if (node.node_type != .document_fragment and
        node.node_type != .document_type and
        node.node_type != .element and
        node.node_type != .text and
        node.node_type != .comment and
        node.node_type != .processing_instruction)
    {
        return error.HierarchyRequestError;
    }

    // Step 5: Text/doctype validation
    if (node.node_type == .text and parent.node_type == .document) {
        return error.HierarchyRequestError;
    }

    if (node.node_type == .document_type and parent.node_type != .document) {
        return error.HierarchyRequestError;
    }

    // Step 6: If parent is document, check element/doctype constraints
    // Note: Different from pre-insert - must exclude child being replaced
    if (parent.node_type == .document) {
        try ensureDocumentReplaceConstraints(node, child, parent);
    }
}

/// Ensures pre-remove validity of removing child from parent.
///
/// Implements WHATWG DOM "pre-remove" validation per §4.2.4.
///
/// ## Spec Reference
/// https://dom.spec.whatwg.org/#concept-node-pre-remove
pub fn ensurePreRemoveValidity(
    child: *Node,
    parent: *Node,
) DOMError!void {
    // If child's parent is not parent, throw NotFoundError
    if (child.parent_node != parent) {
        return error.NotFoundError;
    }
}

// === Helper Functions ===

/// Returns true if node is a host-including inclusive ancestor of parent.
///
/// This checks for circular references - if node is an ancestor of parent,
/// inserting node into parent would create a cycle.
fn isHostIncludingInclusiveAncestor(node: *const Node, parent: *const Node) bool {
    // Check if they're the same node
    if (node == parent) return true;

    // Walk up parent chain looking for node
    var current = parent.parent_node;
    while (current) |p| {
        if (p == node) return true;
        current = p.parent_node;
    }

    return false;
}

/// Ensures document element/doctype constraints for pre-insert.
///
/// Per WHATWG DOM §4.2.4, documents have strict rules about elements and doctypes.
fn ensureDocumentConstraints(
    node: *Node,
    parent: *Node,
    child: ?*Node,
) DOMError!void {
    switch (node.node_type) {
        .document_fragment => {
            // Fragment must not have more than one element child
            var element_count: usize = 0;
            var has_text: bool = false;

            var current = node.first_child;
            while (current) |c| {
                if (c.node_type == .element) element_count += 1;
                if (c.node_type == .text) has_text = true;
                current = c.next_sibling;
            }

            // More than one element or has text child
            if (element_count > 1 or has_text) {
                return error.HierarchyRequestError;
            }

            // If fragment has one element child, check document constraints
            if (element_count == 1) {
                // Parent already has an element child (other than child being replaced)
                if (parentHasElementChild(parent, child)) {
                    return error.HierarchyRequestError;
                }

                // Child is a doctype
                if (child) |c| {
                    if (c.node_type == .document_type) {
                        return error.HierarchyRequestError;
                    }
                }

                // A doctype is following child
                if (child) |c| {
                    if (doctypeIsFollowing(c)) {
                        return error.HierarchyRequestError;
                    }
                } else {
                    // child is null, check if parent has any doctype
                    if (parentHasDoctype(parent)) {
                        return error.HierarchyRequestError;
                    }
                }
            }
        },

        .element => {
            // Parent has an element child
            if (parentHasElementChild(parent, child)) {
                return error.HierarchyRequestError;
            }

            // Child is a doctype
            if (child) |c| {
                if (c.node_type == .document_type) {
                    return error.HierarchyRequestError;
                }
            }

            // A doctype is following child
            if (child) |c| {
                if (doctypeIsFollowing(c)) {
                    return error.HierarchyRequestError;
                }
            } else {
                // child is null, check if parent has any doctype
                if (parentHasDoctype(parent)) {
                    return error.HierarchyRequestError;
                }
            }
        },

        .document_type => {
            // Parent has a doctype child
            if (parentHasDoctype(parent)) {
                return error.HierarchyRequestError;
            }

            // Child is non-null and an element is preceding child
            if (child) |c| {
                if (elementIsPreceding(c)) {
                    return error.HierarchyRequestError;
                }
            } else {
                // Child is null and parent has an element child
                if (parentHasElementChild(parent, null)) {
                    return error.HierarchyRequestError;
                }
            }
        },

        else => {},
    }
}

/// Ensures document element/doctype constraints for replace.
///
/// Similar to ensureDocumentConstraints but excludes child being replaced.
fn ensureDocumentReplaceConstraints(
    node: *Node,
    child: *Node,
    parent: *Node,
) DOMError!void {
    switch (node.node_type) {
        .document_fragment => {
            // Fragment must not have more than one element child or any text
            var element_count: usize = 0;
            var has_text: bool = false;

            var current = node.first_child;
            while (current) |c| {
                if (c.node_type == .element) element_count += 1;
                if (c.node_type == .text) has_text = true;
                current = c.next_sibling;
            }

            if (element_count > 1 or has_text) {
                return error.HierarchyRequestError;
            }

            // If fragment has one element child
            if (element_count == 1) {
                // Parent has an element child that is not child
                if (parentHasElementChildExcluding(parent, child)) {
                    return error.HierarchyRequestError;
                }

                // A doctype is following child
                if (doctypeIsFollowing(child)) {
                    return error.HierarchyRequestError;
                }
            }
        },

        .element => {
            // Parent has an element child that is not child
            if (parentHasElementChildExcluding(parent, child)) {
                return error.HierarchyRequestError;
            }

            // A doctype is following child
            if (doctypeIsFollowing(child)) {
                return error.HierarchyRequestError;
            }
        },

        .document_type => {
            // Parent has a doctype child that is not child
            if (parentHasDoctypeExcluding(parent, child)) {
                return error.HierarchyRequestError;
            }

            // An element is preceding child
            if (elementIsPreceding(child)) {
                return error.HierarchyRequestError;
            }
        },

        else => {},
    }
}

/// Returns true if parent has an element child (optionally excluding one child).
fn parentHasElementChild(parent: *Node, exclude: ?*Node) bool {
    var current = parent.first_child;
    while (current) |c| {
        if (exclude) |excl| {
            if (c == excl) {
                current = c.next_sibling;
                continue;
            }
        }

        if (c.node_type == .element) return true;
        current = c.next_sibling;
    }
    return false;
}

/// Returns true if parent has an element child excluding the specified child.
fn parentHasElementChildExcluding(parent: *Node, child: *Node) bool {
    var current = parent.first_child;
    while (current) |c| {
        if (c == child) {
            current = c.next_sibling;
            continue;
        }

        if (c.node_type == .element) return true;
        current = c.next_sibling;
    }
    return false;
}

/// Returns true if parent has a doctype child.
fn parentHasDoctype(parent: *Node) bool {
    var current = parent.first_child;
    while (current) |c| {
        if (c.node_type == .document_type) return true;
        current = c.next_sibling;
    }
    return false;
}

/// Returns true if parent has a doctype child excluding the specified child.
fn parentHasDoctypeExcluding(parent: *Node, child: *Node) bool {
    var current = parent.first_child;
    while (current) |c| {
        if (c == child) {
            current = c.next_sibling;
            continue;
        }

        if (c.node_type == .document_type) return true;
        current = c.next_sibling;
    }
    return false;
}

/// Returns true if a doctype is following node in sibling list.
fn doctypeIsFollowing(node: *Node) bool {
    var current = node.next_sibling;
    while (current) |c| {
        if (c.node_type == .document_type) return true;
        current = c.next_sibling;
    }
    return false;
}

/// Returns true if an element is preceding node in sibling list.
fn elementIsPreceding(node: *Node) bool {
    var current = node.previous_sibling;
    while (current) |c| {
        if (c.node_type == .element) return true;
        current = c.previous_sibling;
    }
    return false;
}

// ============================================================================
// TESTS
// ============================================================================

const Element = @import("element.zig").Element;
const Document = @import("document.zig").Document;

test "validation - circular reference detection" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child = try doc.createElement("span");
    defer child.node.release();

    // Set up parent-child relationship first
    child.node.parent_node = &parent.node;
    parent.node.first_child = &child.node;
    parent.node.last_child = &child.node;
    defer {
        child.node.parent_node = null;
        parent.node.first_child = null;
        parent.node.last_child = null;
    }

    // Try to insert parent into its own child (circular)
    const result = ensurePreInsertValidity(&parent.node, &child.node, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - invalid parent type" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.node.release();

    const elem = try doc.createElement("div");
    defer elem.node.release();

    // Try to insert into text node (invalid parent)
    const result = ensurePreInsertValidity(&elem.node, &text.node, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - child parent mismatch" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent1 = try doc.createElement("div");
    defer parent1.node.release();

    const parent2 = try doc.createElement("span");
    defer parent2.node.release();

    const child = try doc.createElement("p");
    defer child.node.release();

    // Child's parent is not parent2
    const result = ensurePreInsertValidity(&child.node, &parent2.node, &child.node);
    try std.testing.expectError(error.NotFoundError, result);
}

test "validation - text node into document" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("text");
    defer text.node.release();

    // Text cannot be child of document
    const result = ensurePreInsertValidity(&text.node, &doc.node, null);
    try std.testing.expectError(error.HierarchyRequestError, result);
}

test "validation - pre-remove with wrong parent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    defer parent.node.release();

    const child = try doc.createElement("span");
    defer child.node.release();

    // Child's parent is null, not parent
    const result = ensurePreRemoveValidity(&child.node, &parent.node);
    try std.testing.expectError(error.NotFoundError, result);
}
