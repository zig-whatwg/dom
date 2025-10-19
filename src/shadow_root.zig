//! ShadowRoot Interface (§4.8)
//!
//! This module implements the ShadowRoot interface as specified by the WHATWG DOM Standard.
//! ShadowRoot is a document fragment that forms the root of a shadow tree, enabling
//! encapsulation of DOM structure, style, and behavior from the main document tree.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.8 Interface ShadowRoot**: https://dom.spec.whatwg.org/#interface-shadowroot
//! - **§4.2.2 Shadow tree**: https://dom.spec.whatwg.org/#concept-shadow-tree
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#parentnode (inherited via DocumentFragment)
//!
//! ## MDN Documentation
//!
//! - ShadowRoot: https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot
//! - Element.attachShadow(): https://developer.mozilla.org/en-US/docs/Web/API/Element/attachShadow
//! - Using shadow DOM: https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_shadow_DOM
//!
//! ## Core Features
//!
//! ### Shadow Tree Encapsulation
//! ShadowRoot creates an isolated DOM subtree:
//! ```zig
//! const elem = try doc.createElement("container");
//! const shadow_root = try elem.attachShadow(.{
//!     .mode = .open,
//!     .delegates_focus = false,
//! });
//!
//! // Shadow tree is separate from main document tree
//! const content = try doc.createElement("content");
//! _ = try shadow_root.prototype.appendChild(&content.prototype);
//! ```
//!
//! ### Open vs Closed Mode
//! Mode controls JavaScript access to shadow root:
//! ```zig
//! // Open mode: elem.shadowRoot returns shadow root
//! const shadow_open = try elem.attachShadow(.{ .mode = .open });
//! // elem.shadowRoot != null
//!
//! // Closed mode: elem.shadowRoot returns null
//! const shadow_closed = try elem.attachShadow(.{ .mode = .closed });
//! // elem.shadowRoot == null (still exists, but hidden from JS)
//! ```
//!
//! ### Shadow Host
//! Every ShadowRoot has a host element:
//! ```zig
//! const shadow = try elem.attachShadow(.{ .mode = .open });
//! // shadow.host() == elem
//! ```
//!
//! ## ShadowRoot Structure
//!
//! ShadowRoot extends DocumentFragment with shadow-specific fields:
//! - **node**: Base Node struct (inherited from DocumentFragment)
//! - **mode**: open or closed (.open or .closed)
//! - **delegates_focus**: Focus delegation flag (bool)
//! - **slot_assignment**: Named or manual slot assignment (.named or .manual)
//! - **clonable**: Whether cloneable in cloneNode() (bool)
//! - **serializable**: Whether included in innerHTML (bool)
//! - **host**: NON-OWNING pointer to host element (*Element)
//!
//! Size beyond DocumentFragment: ~24 bytes (6 fields)
//!
//! ## Memory Management
//!
//! ### Ownership Pattern
//! - **Host Element → ShadowRoot** (STRONG): Element owns ShadowRoot via RareData
//! - **ShadowRoot → Host Element** (WEAK): Non-owning pointer to avoid cycles
//!
//! ```zig
//! // Element owns ShadowRoot through RareData
//! const elem = try doc.createElement("container");
//! defer elem.prototype.release(); // Frees ShadowRoot automatically
//!
//! const shadow = try elem.attachShadow(.{ .mode = .open });
//! // shadow.host points back to elem (non-owning)
//! // When elem is freed, ShadowRoot is freed via RareData cleanup
//! ```
//!
//! ### Lifecycle
//! ```zig
//! // 1. Create host element
//! const elem = try doc.createElement("widget");
//! defer elem.prototype.release();
//!
//! // 2. Attach shadow root (stored in elem's RareData)
//! const shadow = try elem.attachShadow(.{ .mode = .open });
//!
//! // 3. Add content to shadow tree
//! const content = try doc.createElement("content");
//! _ = try shadow.prototype.appendChild(&content.prototype);
//!
//! // 4. When elem is released, RareData cleanup:
//! //    - ShadowRoot.deinit() called
//! //    - Children released recursively
//! //    - ShadowRoot freed
//! ```
//!
//! ## Usage Examples
//!
//! ### Creating a Shadow Root
//! ```zig
//! const allocator = std.heap.page_allocator;
//! const Document = @import("document.zig").Document;
//!
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const container = try doc.createElement("container");
//! defer container.prototype.release();
//!
//! // Attach shadow root
//! const shadow = try container.attachShadow(.{
//!     .mode = .open,
//!     .delegates_focus = false,
//! });
//!
//! // Verify host relationship
//! try std.testing.expect(shadow.host() == container);
//! ```
//!
//! ### Building Shadow DOM Structure
//! ```zig
//! const shadow = try elem.attachShadow(.{ .mode = .open });
//!
//! // Build encapsulated structure
//! const wrapper = try doc.createElement("wrapper");
//! const heading = try doc.createElement("heading");
//! const text = try doc.createTextNode("Shadow Content");
//!
//! _ = try heading.prototype.appendChild(&text.prototype);
//! _ = try wrapper.prototype.appendChild(&heading.prototype);
//! _ = try shadow.prototype.appendChild(&wrapper.prototype);
//!
//! // Shadow tree is separate from main document tree
//! ```
//!
//! ### Mode Enforcement
//! ```zig
//! // Open mode: JS can access shadow root
//! const shadow_open = try elem.attachShadow(.{ .mode = .open });
//! // elem.shadowRoot() returns shadow_open
//!
//! // Closed mode: Hidden from JS
//! const elem2 = try doc.createElement("widget");
//! const shadow_closed = try elem2.attachShadow(.{ .mode = .closed });
//! // elem2.shadowRoot() returns null
//! // But shadow_closed still exists and works internally
//! ```
//!
//! ## Common Patterns
//!
//! ### Shadow DOM Template
//! ```zig
//! fn createShadowComponent(doc: *Document, host: *Element) !*ShadowRoot {
//!     const shadow = try host.attachShadow(.{
//!         .mode = .open,
//!         .delegates_focus = false,
//!     });
//!
//!     // Build template structure
//!     const container = try doc.createElement("container");
//!     const content = try doc.createElement("content");
//!     const text = try doc.createTextNode("Component Content");
//!
//!     _ = try content.prototype.appendChild(&text.prototype);
//!     _ = try container.prototype.appendChild(&content.prototype);
//!     _ = try shadow.prototype.appendChild(&container.prototype);
//!
//!     return shadow;
//! }
//! ```
//!
//! ### Query in Shadow Tree
//! ```zig
//! const shadow = try elem.attachShadow(.{ .mode = .open });
//!
//! // Add content
//! const button = try doc.createElement("button");
//! try button.setAttribute("class", "primary");
//! _ = try shadow.prototype.appendChild(&button.prototype);
//!
//! // Query shadow tree (inherits from DocumentFragment)
//! const found = try shadow.querySelector(allocator, ".primary");
//! // found == button
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Mode Selection** - Use closed mode only when truly needed (open is simpler)
//! 2. **Build Off-Document** - Construct shadow tree before attaching to document
//! 3. **Reuse Structures** - Clone shadow roots with clonable flag
//! 4. **Lazy Slot Assignment** - Use manual mode for complex slot patterns
//! 5. **Query Shadow Trees** - querySelector works on shadow roots (scoped)
//! 6. **Event Retargeting** - Shadow boundaries automatically retarget events
//!
//! ## Implementation Notes
//!
//! - ShadowRoot extends DocumentFragment (inherits all ParentNode methods)
//! - ShadowRoot stored in Element's RareData (lazy allocation)
//! - Host pointer is non-owning (prevents circular reference)
//! - Mode enforcement happens at Element.shadowRoot() getter
//! - Only one shadow root per element (attachShadow() throws if already exists)
//! - ShadowRoot freed when host element is freed
//! - Closed mode hides shadow root from JavaScript, but still accessible internally

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;
const DocumentFragment = @import("document_fragment.zig").DocumentFragment;
const Element = @import("element.zig").Element;

/// Shadow root mode (open or closed).
///
/// ## WHATWG Specification
/// - **§4.8 Enum ShadowRootMode**: https://dom.spec.whatwg.org/#enumdef-shadowrootmode
///
/// ## WebIDL
/// ```webidl
/// enum ShadowRootMode { "open", "closed" };
/// ```
///
/// ## Mode Behavior
/// - **open**: Element.shadowRoot returns the shadow root (accessible from JavaScript)
/// - **closed**: Element.shadowRoot returns null (hidden from JavaScript, but exists internally)
pub const ShadowRootMode = enum {
    open,
    closed,
};

/// Slot assignment mode (named or manual).
///
/// ## WHATWG Specification
/// - **§4.8 Enum SlotAssignmentMode**: https://dom.spec.whatwg.org/#enumdef-slotassignmentmode
///
/// ## WebIDL
/// ```webidl
/// enum SlotAssignmentMode { "manual", "named" };
/// ```
///
/// ## Mode Behavior
/// - **named**: Automatic slot assignment based on slot attribute (default)
/// - **manual**: Manual slot assignment via HTMLSlotElement.assign()
pub const SlotAssignmentMode = enum {
    named,
    manual,
};

/// Shadow root initialization options.
///
/// ## WHATWG Specification
/// - **§4.8 Dictionary ShadowRootInit**: https://dom.spec.whatwg.org/#dictdef-shadowrootinit
///
/// ## WebIDL
/// ```webidl
/// dictionary ShadowRootInit {
///   required ShadowRootMode mode;
///   boolean delegatesFocus = false;
///   SlotAssignmentMode slotAssignment = "named";
///   boolean clonable = false;
///   boolean serializable = false;
/// };
/// ```
pub const ShadowRootInit = struct {
    /// Shadow mode (required)
    mode: ShadowRootMode,

    /// Whether focus is delegated
    delegates_focus: bool = false,

    /// Slot assignment mode
    slot_assignment: SlotAssignmentMode = .named,

    /// Whether shadow root is clonable
    clonable: bool = false,

    /// Whether shadow root is serializable
    serializable: bool = false,
};

/// ShadowRoot node - shadow tree root.
///
/// ShadowRoot extends DocumentFragment to create an isolated DOM subtree
/// attached to a host element. It provides encapsulation for DOM structure,
/// style, and behavior.
///
/// ## Key Properties
/// - Extends DocumentFragment (can contain children, supports ParentNode)
/// - Has a host element (non-owning pointer)
/// - Mode controls JavaScript access (open vs closed)
/// - Supports slot-based content distribution
pub const ShadowRoot = struct {
    /// Base Node (MUST be first field for @fieldParentPtr)
    prototype: Node,

    /// Shadow mode (open or closed)
    mode: ShadowRootMode,

    /// Whether focus is delegated to first focusable element
    delegates_focus: bool,

    /// Slot assignment mode (named or manual)
    slot_assignment: SlotAssignmentMode,

    /// Whether shadow root can be cloned
    clonable: bool,

    /// Whether shadow root is included in innerHTML
    serializable: bool,

    /// Host element (NON-OWNING pointer to avoid circular reference)
    ///
    /// MEMORY: This is a weak pointer.
    /// - Element owns ShadowRoot via RareData
    /// - ShadowRoot points back to Element (non-owning)
    /// - No acquire() called, no release() needed
    host_element: *Element,

    /// Vtable for ShadowRoot nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };

    /// Creates a new ShadowRoot node.
    ///
    /// ## WHATWG Specification
    /// - **§4.8 Attach a shadow root**: https://dom.spec.whatwg.org/#concept-attach-a-shadow-root
    ///
    /// ## Memory Management
    /// Returns ShadowRoot with ref_count=1. Caller MUST call `shadow.prototype.release()`.
    /// Typically called via Element.attachShadow() which stores ShadowRoot in RareData.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for node creation
    /// - `host_elem`: Host element (non-owning pointer stored)
    /// - `init`: Shadow root configuration
    ///
    /// ## Returns
    /// New shadow root with ref_count=1
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example
    /// ```zig
    /// const shadow = try ShadowRoot.create(allocator, host_elem, .{
    ///     .mode = .open,
    ///     .delegates_focus = false,
    /// });
    /// defer shadow.prototype.release();
    /// ```
    pub fn create(allocator: Allocator, host_elem: *Element, init: ShadowRootInit) !*ShadowRoot {
        return createWithVTable(allocator, host_elem, init, &vtable);
    }

    /// Creates a shadow root with a custom vtable (enables extensibility).
    pub fn createWithVTable(
        allocator: Allocator,
        host_elem: *Element,
        init: ShadowRootInit,
        node_vtable: *const NodeVTable,
    ) !*ShadowRoot {
        const shadow = try allocator.create(ShadowRoot);
        errdefer allocator.destroy(shadow);

        // Initialize base Node with shadow_root type
        shadow.prototype = .{
            .prototype = .{
                .vtable = &node_mod.eventtarget_vtable,
            },
            .vtable = node_vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .shadow_root,
            .flags = 0,
            .node_id = 0,
            .generation = 0,
            .allocator = allocator,
            .parent_node = null,
            .previous_sibling = null,
            .first_child = null,
            .last_child = null,
            .next_sibling = null,
            .owner_document = host_elem.prototype.owner_document,
            .rare_data = null,
        };

        // Initialize shadow-specific fields
        shadow.mode = init.mode;
        shadow.delegates_focus = init.delegates_focus;
        shadow.slot_assignment = init.slot_assignment;
        shadow.clonable = init.clonable;
        shadow.serializable = init.serializable;
        shadow.host_element = host_elem; // Non-owning pointer

        return shadow;
    }

    /// Returns the host element for this shadow root.
    ///
    /// ## WHATWG Specification
    /// - **§4.8 Interface ShadowRoot**: https://dom.spec.whatwg.org/#dom-shadowroot-host
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element host;
    /// ```
    ///
    /// ## MDN Documentation
    /// - ShadowRoot.host: https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/host
    ///
    /// ## Returns
    /// Host element (non-owning pointer)
    ///
    /// ## Example
    /// ```zig
    /// const shadow = try elem.attachShadow(.{ .mode = .open });
    /// const host_elem = shadow.host();
    /// // host_elem == elem
    /// ```
    pub fn host(self: *const ShadowRoot) *Element {
        return self.host_element;
    }

    // ========================================================================
    // ParentNode Mixin - Inherited from DocumentFragment
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
    /// - ShadowRoot.querySelector(): https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/querySelector
    pub fn querySelector(self: *ShadowRoot, allocator: Allocator, selectors: []const u8) !?*Element {
        const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
        const Parser = @import("selector/parser.zig").Parser;
        const Matcher = @import("selector/matcher.zig").Matcher;

        // Parse selector
        var tokenizer = Tokenizer.init(allocator, selectors);
        var parser = try Parser.init(allocator, &tokenizer);
        defer parser.deinit();

        var selector_list = try parser.parse();
        defer selector_list.deinit();

        // Create matcher
        const matcher = Matcher.init(allocator);

        // Traverse children in tree order
        var current = self.prototype.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);

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
    /// - ShadowRoot.querySelectorAll(): https://developer.mozilla.org/en-US/docs/Web/API/ShadowRoot/querySelectorAll
    pub fn querySelectorAll(self: *ShadowRoot, allocator: Allocator, selectors: []const u8) ![]const *Element {
        const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
        const Parser = @import("selector/parser.zig").Parser;
        const Matcher = @import("selector/matcher.zig").Matcher;

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
        var current = self.prototype.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);

                // Check if element matches
                if (try matcher.matches(elem, &selector_list)) {
                    try results.append(allocator, elem);
                }

                // Recursively search descendants
                try elem.querySelectorAllHelper(allocator, &matcher, &selector_list, &results);
            }
            current = node.next_sibling;
        }

        return try results.toOwnedSlice(allocator);
    }

    /// Returns a live collection of element children.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [SameObject] readonly attribute HTMLCollection children;
    /// ```
    pub fn children(self: *ShadowRoot) @import("html_collection.zig").HTMLCollection {
        return @import("html_collection.zig").HTMLCollection.initChildren(&self.prototype);
    }

    /// Returns the first child that is an element.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? firstElementChild;
    /// ```
    pub fn firstElementChild(self: *const ShadowRoot) ?*Element {
        var current = self.prototype.first_child;
        while (current) |child| {
            if (child.node_type == .element) {
                return @fieldParentPtr("prototype", child);
            }
            current = child.next_sibling;
        }
        return null;
    }

    /// Returns the last child that is an element.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? lastElementChild;
    /// ```
    pub fn lastElementChild(self: *const ShadowRoot) ?*Element {
        var current = self.prototype.last_child;
        while (current) |child| {
            if (child.node_type == .element) {
                return @fieldParentPtr("prototype", child);
            }
            current = child.previous_sibling;
        }
        return null;
    }

    /// Returns the number of children that are elements.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute unsigned long childElementCount;
    /// ```
    pub fn childElementCount(self: *const ShadowRoot) u32 {
        var count: u32 = 0;
        var current = self.prototype.first_child;
        while (current) |child| {
            if (child.node_type == .element) {
                count += 1;
            }
            current = child.next_sibling;
        }
        return count;
    }

    // === Private vtable implementations ===

    /// Vtable implementation: adopting steps (no-op for ShadowRoot)
    ///
    /// ShadowRoots are not adopted (always owned by host element).
    fn adoptingStepsImpl(_: *Node, _: ?*Node) !void {
        // No-op: ShadowRoot is not adoptable
    }

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const shadow: *ShadowRoot = @fieldParentPtr("prototype", node);

        // Release document reference if owned by a document
        if (shadow.prototype.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner_doc);
                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        shadow.prototype.deinitRareData();

        // Free all children
        var current = shadow.prototype.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            child.parent_node = null;
            child.setHasParent(false);
            child.release();
            current = next;
        }

        shadow.prototype.allocator.destroy(shadow);
    }

    /// Vtable implementation: node name (always "#shadow-root")
    fn nodeNameImpl(_: *const Node) []const u8 {
        return "#shadow-root";
    }

    /// Vtable implementation: node value (always null for shadow roots)
    fn nodeValueImpl(_: *const Node) ?[]const u8 {
        return null;
    }

    /// Vtable implementation: set node value (no-op for shadow roots)
    fn setNodeValueImpl(_: *Node, _: []const u8) !void {
        // Shadow roots have no value
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        const shadow: *const ShadowRoot = @fieldParentPtr("prototype", node);

        // Only clonable shadow roots can be cloned
        if (!shadow.clonable) {
            return error.NotSupportedError;
        }

        // Create new shadow root with same configuration
        const new_shadow = try ShadowRoot.create(
            node.allocator,
            shadow.host_element,
            .{
                .mode = shadow.mode,
                .delegates_focus = shadow.delegates_focus,
                .slot_assignment = shadow.slot_assignment,
                .clonable = shadow.clonable,
                .serializable = shadow.serializable,
            },
        );

        // If deep clone, clone all children
        if (deep) {
            var current = node.first_child;
            while (current) |child| {
                const cloned_child = try child.cloneNode(deep);
                errdefer cloned_child.release();

                _ = try new_shadow.prototype.appendChild(cloned_child);

                current = child.next_sibling;
            }
        }

        return &new_shadow.prototype;
    }
};
