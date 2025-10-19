//! Tree Validation Algorithms (§4.2.4)
//!
//! This module implements the tree mutation validation algorithms as specified by the WHATWG
//! DOM Standard. These algorithms ensure that DOM tree modifications maintain structural
//! integrity and prevent invalid hierarchies (circular references, invalid parent-child
//! relationships, etc.).
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.2.4 Mutation Algorithms**: https://dom.spec.whatwg.org/#mutation-algorithms
//! - **§4.2.4.1 Pre-insert Validity**: https://dom.spec.whatwg.org/#concept-node-ensure-pre-insertion-validity
//! - **§4.2.4.2 Replace Validity**: https://dom.spec.whatwg.org/#concept-node-replace
//! - **§4.2.4.3 Pre-remove Validity**: https://dom.spec.whatwg.org/#concept-node-pre-remove
//!
//! ## MDN Documentation
//!
//! - Node.appendChild(): https://developer.mozilla.org/en-US/docs/Web/API/Node/appendChild
//! - Node.insertBefore(): https://developer.mozilla.org/en-US/docs/Web/API/Node/insertBefore
//! - Node.replaceChild(): https://developer.mozilla.org/en-US/docs/Web/API/Node/replaceChild
//! - Node.removeChild(): https://developer.mozilla.org/en-US/docs/Web/API/Node/removeChild
//! - DOMException: https://developer.mozilla.org/en-US/docs/Web/API/DOMException
//!
//! ## Core Features
//!
//! ### Pre-Insert Validation
//! Validates node can be inserted into parent before child:
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! defer parent.prototype.release();
//!
//! const child = try Element.create(allocator, "span");
//!
//! // Validate before inserting
//! try ensurePreInsertValidity(&child.prototype, &parent.prototype, null);
//! // If validation passes, insertion is safe
//! _ = try parent.prototype.appendChild(&child.prototype);
//! ```
//!
//! ### Replace Validation
//! Validates node can replace child in parent:
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! defer parent.prototype.release();
//!
//! const old_child = try Element.create(allocator, "span");
//! _ = try parent.prototype.appendChild(&old_child.prototype);
//!
//! const new_child = try Element.create(allocator, "p");
//!
//! // Validate replacement
//! try ensureReplaceValidity(new_child, &parent.prototype, &old_child.prototype);
//! _ = try parent.prototype.replaceChild(new_child, &old_child.prototype);
//! ```
//!
//! ### Pre-Remove Validation
//! Validates child can be removed from parent:
//! ```zig
//! const parent = try Element.create(allocator, "div");
//! defer parent.prototype.release();
//!
//! const child = try Element.create(allocator, "span");
//! _ = try parent.prototype.appendChild(&child.prototype);
//!
//! // Validate removal
//! try ensurePreRemoveValidity(&child.prototype, &parent.prototype);
//! _ = try parent.prototype.removeChild(&child.prototype);
//! ```
//!
//! ## Validation Rules
//!
//! ### Pre-Insert Validity (§4.2.4.1)
//! Checks performed:
//! 1. **Parent Type** - Must be Document, DocumentFragment, or Element
//! 2. **Circular Reference** - Node must not be ancestor of parent
//! 3. **Child Parent** - If child provided, must be child of parent
//! 4. **Node Type** - Must be DocumentFragment, DocumentType, Element, Text, Comment, or ProcessingInstruction
//! 5. **Text in Document** - Text nodes cannot be children of Document
//! 6. **DocumentType Placement** - DocumentType must be child of Document only
//! 7. **Document Children** - Document can only have one Element and one DocumentType
//!
//! ### Replace Validity (§4.2.4.2)
//! Checks performed:
//! 1. All Pre-Insert checks (except for child being non-null)
//! 2. Child must exist and be child of parent
//!
//! ### Pre-Remove Validity (§4.2.4.3)
//! Checks performed:
//! 1. Child must exist and be child of parent
//!
//! ## Error Types
//!
//! **HierarchyRequestError:**
//! - Invalid parent type
//! - Circular reference (node is ancestor of parent)
//! - Invalid node type for insertion
//! - Text node as Document child
//! - DocumentType as non-Document child
//! - Multiple element children in Document
//! - DocumentType after element in Document
//!
//! **NotFoundError:**
//! - Child is not a child of parent
//! - Child is null when required
//!
//! ## Memory Management
//!
//! Validation functions are pure - they don't allocate or modify memory:
//! ```zig
//! // No memory management needed for validation
//! try ensurePreInsertValidity(node, parent, child);
//! // No cleanup required
//! ```
//!
//! ## Usage Examples
//!
//! ### Safe Insertion with Validation
//! ```zig
//! fn safeAppendChild(parent: *Node, child: *Node) !*Node {
//!     // Validate first
//!     try ensurePreInsertValidity(child, parent, null);
//!
//!     // Safe to insert
//!     return try parent.appendChild(child);
//! }
//! ```
//!
//! ### Preventing Circular References
//! ```zig
//! const grandparent = try Element.create(allocator, "div");
//! defer grandparent.prototype.release();
//!
//! const parent = try Element.create(allocator, "div");
//! _ = try grandparent.prototype.appendChild(&parent.prototype);
//!
//! const child = try Element.create(allocator, "span");
//! _ = try parent.prototype.appendChild(&child.prototype);
//!
//! // Try to create circular reference (child → parent → grandparent → child)
//! const result = ensurePreInsertValidity(&grandparent.prototype, &child.prototype, null);
//! // Returns error.HierarchyRequestError ✅
//! ```
//!
//! ### Document Structure Validation
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const html = try doc.createElement("html");
//! _ = try doc.prototype.appendChild(&html.prototype); // First element - OK
//!
//! const html2 = try doc.createElement("html");
//! const result = ensurePreInsertValidity(&html2.prototype, &doc.prototype, null);
//! // Returns error.HierarchyRequestError (Document already has element child)
//! ```
//!
//! ## Common Patterns
//!
//! ### Validation Wrapper
//! ```zig
//! fn validateAndInsert(parent: *Node, child: *Node, ref_child: ?*Node) !*Node {
//!     try ensurePreInsertValidity(child, parent, ref_child);
//!     return if (ref_child) |ref|
//!         try parent.insertBefore(child, ref)
//!     else
//!         try parent.appendChild(child);
//! }
//! ```
//!
//! ### Batch Validation
//! ```zig
//! fn validateBatch(parent: *Node, children: []*Node) !void {
//!     for (children) |child| {
//!         try ensurePreInsertValidity(child, parent, null);
//!     }
//!     // All validations passed - safe to insert all
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Fast Path** - Validation is O(depth) for ancestor check, optimize hot paths
//! 2. **Batch Validate** - Validate all nodes before inserting to avoid partial insertion
//! 3. **Skip When Safe** - Internal operations can skip validation if structure guaranteed
//! 4. **Cache Parent Type** - Parent type check is first, cache if doing many insertions
//! 5. **Early Exit** - Validation returns on first error, order checks by likelihood
//!
//! ## Implementation Notes
//!
//! - All functions follow WHATWG DOM specification exactly (step-by-step)
//! - Validation is pure (no side effects, no memory allocation)
//! - Error types match DOMException names from spec
//! - isHostIncludingInclusiveAncestor implements spec's ancestor check algorithm
//! - Document children validation enforces: at most one Element, at most one DocumentType
//! - DocumentType must come before Element in Document (if both present)
//! - Text nodes explicitly forbidden as Document children (use Text in Element instead)

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;

/// DOM exception errors per WHATWG DOM specification
pub const DOMError = error{
    HierarchyRequestError,
    NotFoundError,
    InUseAttributeError,
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
    // Step 1: Parent must be Document, DocumentFragment, ShadowRoot, or Element
    if (parent.node_type != .document and
        parent.node_type != .document_fragment and
        parent.node_type != .shadow_root and
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
    // Step 1: Parent must be Document, DocumentFragment, ShadowRoot, or Element
    if (parent.node_type != .document and
        parent.node_type != .document_fragment and
        parent.node_type != .shadow_root and
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
