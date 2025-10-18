//! DocumentFragment Interface (§4.11)
//!
//! This module implements the DocumentFragment interface as specified by the WHATWG DOM Standard.
//! DocumentFragment is a lightweight container for temporarily holding groups of nodes. It's commonly
//! used for efficient batch DOM operations where multiple nodes need to be inserted together.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.11 Interface DocumentFragment**: https://dom.spec.whatwg.org/#interface-documentfragment
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#parentnode
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node (base)
//!
//! ## MDN Documentation
//!
//! - DocumentFragment: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
//! - DocumentFragment(): https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/DocumentFragment
//! - Document.createDocumentFragment(): https://developer.mozilla.org/en-US/docs/Web/API/Document/createDocumentFragment
//! - Using DocumentFragment: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment#usage_notes
//!
//! ## Core Features
//!
//! ### Lightweight Container
//! DocumentFragment is a minimal node container with no special behavior:
//! ```zig
//! const fragment = try DocumentFragment.create(allocator);
//! defer fragment.node.release();
//!
//! // Add children to fragment
//! const div = try Element.create(allocator, "div");
//! _ = try fragment.node.appendChild(&div.node);
//!
//! const text = try Text.create(allocator, "Content");
//! _ = try div.node.appendChild(&text.node);
//! ```
//!
//! ### Batch Insertion
//! When inserted, fragment's children move to the target (fragment becomes empty):
//! ```zig
//! const parent = try Element.create(allocator, "ul");
//! defer parent.node.release();
//!
//! const fragment = try DocumentFragment.create(allocator);
//! defer fragment.node.release();
//!
//! // Build multiple list items in fragment
//! for (0..3) |i| {
//!     const li = try Element.create(allocator, "li");
//!     _ = try fragment.node.appendChild(&li.node);
//! }
//!
//! // Insert all at once (single reflow)
//! _ = try parent.node.appendChild(&fragment.node);
//! // fragment.node.first_child is now null (children moved)
//! // parent now has 3 <li> children
//! ```
//!
//! ### Query Support
//! DocumentFragment supports ParentNode query methods:
//! ```zig
//! const fragment = try DocumentFragment.create(allocator);
//! defer fragment.node.release();
//!
//! // Build structure
//! const div = try Element.create(allocator, "div");
//! try div.setAttribute("class", "container");
//! _ = try fragment.node.appendChild(&div.node);
//!
//! // Query works on fragment
//! const found = try fragment.querySelector(".container");
//! // found == div
//! ```
//!
//! ## DocumentFragment Structure
//!
//! DocumentFragment is the simplest node type - just Node with no extra fields:
//! - **node**: Base Node struct (MUST be first field for @fieldParentPtr)
//! - **vtable**: Node vtable for polymorphic behavior
//!
//! Size beyond Node: 0 bytes (no additional fields)
//!
//! **Key Properties:**
//! - nodeName is always "#document-fragment"
//! - nodeValue is always null
//! - Never has a parent (always orphaned)
//! - Can contain any node type except Document/DocumentType
//! - When inserted, children are transferred (fragment becomes empty)
//!
//! ## Memory Management
//!
//! DocumentFragment uses reference counting through Node interface:
//! ```zig
//! const fragment = try DocumentFragment.create(allocator);
//! defer fragment.node.release(); // Decrements ref_count, frees if 0
//!
//! // When sharing ownership:
//! fragment.node.acquire(); // Increment ref_count
//! other_structure.fragment = &fragment.node;
//! // Both owners must call release()
//! ```
//!
//! When released (ref_count reaches 0):
//! 1. All children are released recursively
//! 2. Node base is freed
//!
//! ## Usage Examples
//!
//! ### Efficient List Building
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! const container = try Element.create(allocator, "ul");
//! defer container.node.release();
//!
//! // Build items off-document for better performance
//! const fragment = try DocumentFragment.create(allocator);
//! defer fragment.node.release();
//!
//! const items = [_][]const u8{ "Apple", "Banana", "Cherry" };
//! for (items) |name| {
//!     const li = try Element.create(allocator, "li");
//!     const text = try Text.create(allocator, name);
//!     _ = try li.node.appendChild(&text.node);
//!     _ = try fragment.node.appendChild(&li.node);
//! }
//!
//! // Single insertion (triggers one reflow, not three)
//! _ = try container.node.appendChild(&fragment.node);
//! ```
//!
//! ### Template Cloning
//! ```zig
//! fn cloneTemplate(template: *Element, allocator: Allocator) !*DocumentFragment {
//!     const fragment = try DocumentFragment.create(allocator);
//!
//!     // Clone all template children into fragment
//!     var current = template.node.first_child;
//!     while (current) |child| : (current = child.next_sibling) {
//!         const clone = try child.cloneNode(true); // Deep clone
//!         _ = try fragment.node.appendChild(clone);
//!     }
//!
//!     return fragment;
//! }
//! ```
//!
//! ### Building Complex Structures
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const fragment = try doc.createDocumentFragment();
//! defer fragment.node.release();
//!
//! // Build article structure
//! const article = try doc.createElement("article");
//! const header = try doc.createElement("header");
//! const h1 = try doc.createElement("h1");
//! const title = try doc.createTextNode("Article Title");
//!
//! _ = try h1.node.appendChild(&title.node);
//! _ = try header.node.appendChild(&h1.node);
//! _ = try article.node.appendChild(&header.node);
//! _ = try fragment.node.appendChild(&article.node);
//!
//! // Insert complete structure
//! _ = try doc.body.?.node.appendChild(&fragment.node);
//! ```
//!
//! ## Common Patterns
//!
//! ### Safe Multi-Insert
//! ```zig
//! fn insertMultiple(parent: *Node, nodes: []*Node) !void {
//!     const fragment = try DocumentFragment.create(parent.allocator);
//!     defer fragment.node.release();
//!
//!     // Gather all nodes in fragment first
//!     for (nodes) |node| {
//!         _ = try fragment.node.appendChild(node);
//!     }
//!
//!     // Single insertion
//!     _ = try parent.appendChild(&fragment.node);
//! }
//! ```
//!
//! ### Fragment Factory
//! ```zig
//! fn createListFragment(items: []const []const u8, allocator: Allocator) !*DocumentFragment {
//!     const fragment = try DocumentFragment.create(allocator);
//!     errdefer fragment.node.release();
//!
//!     for (items) |item| {
//!         const li = try Element.create(allocator, "li");
//!         errdefer li.node.release();
//!
//!         const text = try Text.create(allocator, item);
//!         _ = try li.node.appendChild(&text.node);
//!         _ = try fragment.node.appendChild(&li.node);
//!     }
//!
//!     return fragment;
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Batch Insertions** - Build complex structures in fragment, insert once
//! 2. **Reduce Reflows** - Fragment insertion triggers one reflow vs N reflows
//! 3. **Off-Document Building** - Construct DOM trees off-document for speed
//! 4. **Reuse Fragments** - Clear and reuse instead of creating new ones
//! 5. **Template Patterns** - Clone fragment instead of rebuilding structures
//! 6. **Query Before Insert** - Run queries on fragment before inserting (faster)
//!
//! ## JavaScript Bindings
//!
//! ### DocumentFragment Constructor
//! ```javascript
//! // Create new document fragment
//! const fragment = new DocumentFragment();
//!
//! // In bindings implementation:
//! function DocumentFragment() {
//!   this._ptr = zig.document_fragment_create();
//! }
//! ```
//!
//! ### Instance Properties
//! ```javascript
//! // children (readonly) - ParentNode mixin
//! Object.defineProperty(DocumentFragment.prototype, 'children', {
//!   get: function() { return zig.document_fragment_get_children(this._ptr); }
//! });
//!
//! // childElementCount (readonly) - ParentNode mixin
//! Object.defineProperty(DocumentFragment.prototype, 'childElementCount', {
//!   get: function() { return zig.document_fragment_get_child_element_count(this._ptr); }
//! });
//!
//! // firstElementChild (readonly) - ParentNode mixin
//! Object.defineProperty(DocumentFragment.prototype, 'firstElementChild', {
//!   get: function() { return zig.document_fragment_get_first_element_child(this._ptr); }
//! });
//!
//! // lastElementChild (readonly) - ParentNode mixin
//! Object.defineProperty(DocumentFragment.prototype, 'lastElementChild', {
//!   get: function() { return zig.document_fragment_get_last_element_child(this._ptr); }
//! });
//!
//! // DocumentFragment inherits all Node properties (nodeType, nodeName, childNodes, etc.)
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! // ParentNode mixin methods
//! DocumentFragment.prototype.querySelector = function(selectors) {
//!   return zig.document_fragment_querySelector(this._ptr, selectors);
//! };
//!
//! DocumentFragment.prototype.querySelectorAll = function(selectors) {
//!   return zig.document_fragment_querySelectorAll(this._ptr, selectors);
//! };
//!
//! // DocumentFragment inherits all Node methods (appendChild, insertBefore, etc.)
//! // DocumentFragment inherits all EventTarget methods (addEventListener, etc.)
//! ```
//!
//! ### Usage Note
//! ```javascript
//! // Build structure in fragment
//! const fragment = new DocumentFragment();
//! const div = document.createElement('div');
//! const span = document.createElement('span');
//! div.appendChild(span);
//! fragment.appendChild(div);
//!
//! // Insert into document (fragment's children move, fragment becomes empty)
//! document.body.appendChild(fragment);
//! console.log(fragment.childNodes.length); // 0 - children were transferred
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - DocumentFragment extends Node with no additional fields (smallest node type)
//! - nodeName is always "#document-fragment"
//! - nodeValue is always null (cannot be set)
//! - Never has a parent node (parent_node is always null)
//! - Supports ParentNode mixin (querySelector, children, etc.)
//! - When inserted via appendChild/insertBefore, children are transferred
//! - After insertion, fragment.first_child becomes null
//! - Fragment itself is NOT inserted (only its children)
//! - Useful for DocumentFragment-specific optimizations in rendering engines

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;

/// DocumentFragment node - lightweight document container.
///
/// DocumentFragments are used to hold a temporary collection of nodes
/// that can be inserted into a document as a batch. This is more efficient
/// than inserting nodes one by one.
///
/// ## Key Properties
/// - Has no parent (always orphaned)
/// - Can contain any node type except Document
/// - When inserted, its children are moved (not the fragment itself)
pub const DocumentFragment = struct {
    /// Base Node (MUST be first field for @fieldParentPtr)
    node: Node,

    /// Vtable for DocumentFragment nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };

    /// Creates a new DocumentFragment node.
    ///
    /// ## Memory Management
    /// Returns DocumentFragment with ref_count=1. Caller MUST call `fragment.node.release()`.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    ///
    /// ## Returns
    /// New document fragment with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const fragment = try DocumentFragment.create(allocator);
    /// defer fragment.node.release();
    /// ```
    pub fn create(allocator: Allocator) !*DocumentFragment {
        const fragment = try allocator.create(DocumentFragment);
        errdefer allocator.destroy(fragment);

        // Initialize base Node
        fragment.node = .{
            .vtable = &vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .document_fragment,
            .flags = 0,
            .node_id = 0,
            .generation = 0,
            .allocator = allocator,
            .parent_node = null,
            .previous_sibling = null,
            .first_child = null,
            .last_child = null,
            .next_sibling = null,
            .owner_document = null,
            .rare_data = null,
        };

        return fragment;
    }

    // ========================================================================
    // ParentNode Mixin - Query Selector
    // ========================================================================

    /// Returns the first element that matches the specified CSS selector.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#dom-parentnode-queryselector
    ///
    /// ## WebIDL
    /// ```webidl
    /// Element? querySelector(DOMString selectors);
    /// ```
    ///
    /// ## MDN Documentation
    /// - DocumentFragment.querySelector(): https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/querySelector
    ///
    /// ## Usage
    /// ```zig
    /// const fragment = try DocumentFragment.create(allocator);
    /// defer fragment.node.release();
    ///
    /// const button = try Element.create(allocator, "button");
    /// try button.setAttribute("class", "btn");
    /// _ = try fragment.node.appendChild(&button.node);
    ///
    /// // Find button in fragment
    /// const result = try fragment.querySelector(allocator, ".btn");
    /// // result == button
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// // Instance method on DocumentFragment.prototype
    /// const fragment = document.createDocumentFragment();
    /// const button = fragment.querySelector('button.primary');
    /// // Returns: Element or null
    /// ```
    pub fn querySelector(self: *DocumentFragment, allocator: Allocator, selectors: []const u8) !?*@import("element.zig").Element {
        const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
        const Parser = @import("selector/parser.zig").Parser;
        const Matcher = @import("selector/matcher.zig").Matcher;
        const Element = @import("element.zig").Element;

        // Parse selector
        var tokenizer = Tokenizer.init(allocator, selectors);
        var parser = try Parser.init(allocator, &tokenizer);
        defer parser.deinit();

        var selector_list = try parser.parse();
        defer selector_list.deinit();

        // Create matcher
        const matcher = Matcher.init(allocator);

        // Traverse children in tree order
        var current = self.node.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("node", node);

                // Check if element matches
                if (try matcher.matches(elem, &selector_list)) {
                    return elem;
                }

                // Recursively search descendants
                if (try elem.querySelector(allocator, selectors)) |found| {
                    return found;
                }
            }
            current = node.next_sibling;
        }

        return null;
    }

    /// Returns all elements that match the specified CSS selector.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#dom-parentnode-queryselectorall
    ///
    /// ## WebIDL
    /// ```webidl
    /// [NewObject] NodeList querySelectorAll(DOMString selectors);
    /// ```
    ///
    /// ## MDN Documentation
    /// - DocumentFragment.querySelectorAll(): https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/querySelectorAll
    ///
    /// ## Usage
    /// ```zig
    /// const fragment = try DocumentFragment.create(allocator);
    /// defer fragment.node.release();
    ///
    /// // Add elements...
    ///
    /// // Find all buttons
    /// const results = try fragment.querySelectorAll(allocator, "button");
    /// defer allocator.free(results);
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// // Instance method on DocumentFragment.prototype
    /// const fragment = document.createDocumentFragment();
    /// const buttons = fragment.querySelectorAll('button.primary');
    /// // Returns: NodeList (array-like, always defined)
    /// ```
    pub fn querySelectorAll(self: *DocumentFragment, allocator: Allocator, selectors: []const u8) ![]const *@import("element.zig").Element {
        const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
        const Parser = @import("selector/parser.zig").Parser;
        const Matcher = @import("selector/matcher.zig").Matcher;
        const Element = @import("element.zig").Element;

        // Parse selector
        var tokenizer = Tokenizer.init(allocator, selectors);
        var parser = try Parser.init(allocator, &tokenizer);
        defer parser.deinit();

        var selector_list = try parser.parse();
        defer selector_list.deinit();

        // Create matcher
        const matcher = Matcher.init(allocator);

        // Collect matching elements
        var results = std.ArrayList(*Element){};
        defer results.deinit(allocator);

        // Traverse children in tree order
        var current = self.node.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("node", node);

                // Check if element matches
                if (try matcher.matches(elem, &selector_list)) {
                    try results.append(allocator, elem);
                }

                // Recursively search descendants (reuse Element's helper)
                try elem.querySelectorAllHelper(allocator, &matcher, &selector_list, &results);
            }
            current = node.next_sibling;
        }

        return try results.toOwnedSlice(allocator);
    }

    /// Returns a live collection of element children.
    ///
    /// Implements WHATWG DOM ParentNode.children property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [SameObject] readonly attribute HTMLCollection children;
    /// ```
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-children
    /// - WebIDL: dom.idl:119
    ///
    /// ## Returns
    /// Live ElementCollection of element children
    pub fn children(self: *DocumentFragment) @import("element_collection.zig").ElementCollection {
        return @import("element_collection.zig").ElementCollection.init(&self.node);
    }

    /// Returns the first child that is an element.
    ///
    /// Implements WHATWG DOM ParentNode.firstElementChild property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? firstElementChild;
    /// ```
    ///
    /// ## MDN Documentation
    /// - firstElementChild: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/firstElementChild
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// Return the first child of this that is an element, or null if there is no such child.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-firstelementchild
    /// - WebIDL: dom.idl:120
    ///
    /// ## Returns
    /// First element child or null
    pub fn firstElementChild(self: *const DocumentFragment) ?*@import("element.zig").Element {
        var current = self.node.first_child;
        while (current) |child| {
            if (child.node_type == .element) {
                return @fieldParentPtr("node", child);
            }
            current = child.next_sibling;
        }
        return null;
    }

    /// Returns the last child that is an element.
    ///
    /// Implements WHATWG DOM ParentNode.lastElementChild property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? lastElementChild;
    /// ```
    ///
    /// ## MDN Documentation
    /// - lastElementChild: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/lastElementChild
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// Return the last child of this that is an element, or null if there is no such child.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-lastelementchild
    /// - WebIDL: dom.idl:121
    ///
    /// ## Returns
    /// Last element child or null
    pub fn lastElementChild(self: *const DocumentFragment) ?*@import("element.zig").Element {
        var current = self.node.last_child;
        while (current) |child| {
            if (child.node_type == .element) {
                return @fieldParentPtr("node", child);
            }
            current = child.previous_sibling;
        }
        return null;
    }

    /// Returns the number of children that are elements.
    ///
    /// Implements WHATWG DOM ParentNode.childElementCount property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute unsigned long childElementCount;
    /// ```
    ///
    /// ## MDN Documentation
    /// - childElementCount: https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/childElementCount
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// Return the number of children of this that are elements.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-childelementcount
    /// - WebIDL: dom.idl:122
    ///
    /// ## Returns
    /// Count of element children (0 if none)
    pub fn childElementCount(self: *const DocumentFragment) u32 {
        var count: u32 = 0;
        var current = self.node.first_child;
        while (current) |child| {
            if (child.node_type == .element) {
                count += 1;
            }
            current = child.next_sibling;
        }
        return count;
    }

    /// NodeOrString union for ParentNode variadic methods.
    ///
    /// Represents the WebIDL `(Node or DOMString)` union type.
    pub const NodeOrString = union(enum) {
        node: *Node,
        string: []const u8,
    };

    /// Inserts nodes or strings before the first child.
    ///
    /// Implements WHATWG DOM ParentNode.prepend() per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined prepend((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - prepend(): https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/prepend
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Pre-insert node into this before this's first child
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-prepend
    /// - WebIDL: dom.idl:124
    pub fn prepend(self: *DocumentFragment, nodes: []const NodeOrString) !void {
        const result = try convertNodesToNode(&self.node, nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try self.node.insertBefore(node_to_insert, self.node.first_child);

        if (should_release) {
            returned_node.release();
        }
    }

    /// Inserts nodes or strings after the last child.
    ///
    /// Implements WHATWG DOM ParentNode.append() per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined append((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - append(): https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/append
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Append node to this
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-append
    /// - WebIDL: dom.idl:125
    pub fn append(self: *DocumentFragment, nodes: []const NodeOrString) !void {
        const result = try convertNodesToNode(&self.node, nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try self.node.appendChild(node_to_insert);

        if (should_release) {
            returned_node.release();
        }
    }

    /// Replaces all children with new nodes or strings.
    ///
    /// Implements WHATWG DOM ParentNode.replaceChildren() per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined replaceChildren((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - replaceChildren(): https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment/replaceChildren
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Ensure pre-replace validity of node
    /// 3. Replace all children of this with node
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-replacechildren
    /// - WebIDL: dom.idl:126
    pub fn replaceChildren(self: *DocumentFragment, nodes: []const NodeOrString) !void {
        const result = try convertNodesToNode(&self.node, nodes);

        while (self.node.first_child) |child| {
            const removed = try self.node.removeChild(child);
            removed.release();
        }

        if (result) |r| {
            const returned_node = try self.node.appendChild(r.node);
            if (r.should_release_after_insert) {
                returned_node.release();
            }
        }
    }

    // === Private vtable implementations ===

    /// Result of converting nodes/strings
    const ConvertResult = struct {
        node: *Node,
        should_release_after_insert: bool,
    };

    /// Helper: Convert slice of nodes/strings into a single node.
    fn convertNodesToNode(parent: *Node, items: []const NodeOrString) !?ConvertResult {
        if (items.len == 0) return null;

        const owner_doc = parent.owner_document orelse {
            return error.InvalidStateError;
        };

        const Document = @import("document.zig").Document;
        if (owner_doc.node_type != .document) {
            return error.InvalidStateError;
        }
        const doc: *Document = @fieldParentPtr("node", owner_doc);

        if (items.len == 1) {
            switch (items[0]) {
                .node => |n| {
                    return ConvertResult{
                        .node = n,
                        .should_release_after_insert = false,
                    };
                },
                .string => |s| {
                    const text = try doc.createTextNode(s);
                    return ConvertResult{
                        .node = &text.node,
                        .should_release_after_insert = false,
                    };
                },
            }
        }

        const fragment = try doc.createDocumentFragment();
        errdefer fragment.node.release();

        for (items) |item| {
            switch (item) {
                .node => |n| {
                    _ = try fragment.node.appendChild(n);
                },
                .string => |s| {
                    const text = try doc.createTextNode(s);
                    _ = try fragment.node.appendChild(&text.node);
                },
            }
        }

        return ConvertResult{
            .node = &fragment.node,
            .should_release_after_insert = true,
        };
    }

    /// Vtable implementation: adopting steps (no-op for DocumentFragment)
    ///
    /// DocumentFragments don't have node-specific data to update during adoption.
    fn adoptingStepsImpl(_: *Node, _: ?*Node) !void {
        // No-op: DocumentFragment has no data to update
    }

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const fragment: *DocumentFragment = @fieldParentPtr("node", node);

        // Release document reference if owned by a document
        if (fragment.node.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("node", owner_doc);
                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        fragment.node.deinitRareData();

        // Free all children
        var current = fragment.node.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            child.parent_node = null;
            child.setHasParent(false);
            child.release();
            current = next;
        }

        fragment.node.allocator.destroy(fragment);
    }

    /// Vtable implementation: node name (always "#document-fragment")
    fn nodeNameImpl(_: *const Node) []const u8 {
        return "#document-fragment";
    }

    /// Vtable implementation: node value (always null for document fragments)
    fn nodeValueImpl(_: *const Node) ?[]const u8 {
        return null;
    }

    /// Vtable implementation: set node value (no-op for document fragments)
    fn setNodeValueImpl(_: *Node, _: []const u8) !void {
        // Document fragments have no value
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        const fragment: *const DocumentFragment = @fieldParentPtr("node", node);
        _ = fragment;

        // Create new fragment
        const new_fragment = try DocumentFragment.create(node.allocator);

        // If deep clone, clone all children
        if (deep) {
            var current = node.first_child;
            while (current) |child| {
                const cloned_child = try child.cloneNode(deep);
                errdefer cloned_child.release();

                _ = try new_fragment.node.appendChild(cloned_child);

                current = child.next_sibling;
            }
        }

        return &new_fragment.node;
    }
};

// === Tests ===

test "DocumentFragment - creation and cleanup" {
    const allocator = std.testing.allocator;

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.node.release();

    try std.testing.expect(fragment.node.node_type == .document_fragment);
    try std.testing.expectEqualStrings("#document-fragment", fragment.node.nodeName());
    try std.testing.expect(fragment.node.nodeValue() == null);
}

test "DocumentFragment - can hold children" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try DocumentFragment.create(allocator);
    defer fragment.node.release();

    const elem1 = try doc.createElement("div");
    const elem2 = try doc.createElement("span");

    _ = try fragment.node.appendChild(&elem1.node);
    _ = try fragment.node.appendChild(&elem2.node);

    try std.testing.expect(fragment.node.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), fragment.node.childNodes().length());
}

test "DocumentFragment - clone shallow" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    const elem = try doc.createElement("div");
    _ = try fragment.node.appendChild(&elem.node);

    // Shallow clone
    const clone = try fragment.node.cloneNode(false);
    defer clone.release();

    try std.testing.expect(clone.node_type == .document_fragment);
    try std.testing.expect(!clone.hasChildNodes());
}

test "DocumentFragment - clone deep" {
    const allocator = std.testing.allocator;

    const Document = @import("document.zig").Document;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.node.release();

    const elem = try doc.createElement("div");
    _ = try fragment.node.appendChild(&elem.node);

    // Deep clone
    const clone = try fragment.node.cloneNode(true);
    defer clone.release();

    try std.testing.expect(clone.node_type == .document_fragment);
    try std.testing.expect(clone.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 1), clone.childNodes().length());
}
