//! Attr Interface (§4.10 - Attribute Nodes)
//!
//! This module implements the Attr interface as specified by the WHATWG DOM Standard.
//! Attr nodes represent attributes of Element nodes. Unlike other attributes access methods
//! (getAttribute, setAttribute), Attr provides an object-oriented view of attributes.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.10 Interface Attr**: https://dom.spec.whatwg.org/#interface-attr
//! - **§4.10 Interface Element**: https://dom.spec.whatwg.org/#interface-element
//! - **§4.4 Interface Node**: https://dom.spec.whatwg.org/#interface-node (base)
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface Attr : Node {
//!   readonly attribute DOMString? namespaceURI;
//!   readonly attribute DOMString? prefix;
//!   readonly attribute DOMString localName;
//!   readonly attribute DOMString name;
//!   [CEReactions] attribute DOMString value;
//!
//!   readonly attribute Element? ownerElement;
//!
//!   readonly attribute boolean specified; // useless; always returns true
//! };
//! ```
//!
//! ## MDN Documentation
//!
//! - Attr: https://developer.mozilla.org/en-US/docs/Web/API/Attr
//! - Attr.name: https://developer.mozilla.org/en-US/docs/Web/API/Attr/name
//! - Attr.value: https://developer.mozilla.org/en-US/docs/Web/API/Attr/value
//! - Attr.ownerElement: https://developer.mozilla.org/en-US/docs/Web/API/Attr/ownerElement
//!
//! ## Core Features
//!
//! ### Attribute Object View
//! Attr provides an object-oriented interface to attributes:
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const elem = try doc.createElement("input");
//! const attr = try doc.createAttribute("type");
//! attr.setValue("text");
//!
//! _ = try elem.setAttributeNode(attr);
//! // elem now has attribute: type="text"
//! ```
//!
//! ### Attribute Properties
//! Attr exposes detailed attribute information:
//! ```zig
//! const attr = try doc.createAttribute("id");
//! attr.setValue("main-content");
//!
//! const name = attr.name;        // "id"
//! const value = attr.value();    // "main-content"
//! const local = attr.localName;  // "id"
//! const ns = attr.namespaceURI;  // null (no namespace)
//! ```
//!
//! ### Owner Element
//! Attr tracks which element it belongs to:
//! ```zig
//! const elem = try doc.createElement("div");
//! const attr = try doc.createAttribute("class");
//! attr.setValue("container");
//!
//! std.debug.assert(attr.ownerElement == null); // Not attached yet
//! _ = try elem.setAttributeNode(attr);
//! std.debug.assert(attr.ownerElement == elem); // Now attached
//! ```
//!
//! ## Attr Node Structure
//!
//! Attr nodes extend Node with attribute-specific data:
//! - **node**: Base Node struct (MUST be first field for @fieldParentPtr)
//! - **local_name**: Attribute name (interned string, 8 bytes)
//! - **value**: Attribute value (owned string slice, 16 bytes)
//! - **namespace_uri**: Optional namespace (8 bytes)
//! - **prefix**: Optional prefix (8 bytes)
//! - **owner_element**: WEAK pointer to owning Element (8 bytes)
//!
//! Total additional size beyond Node: 48 bytes
//!
//! ## Memory Management
//!
//! Attr nodes use reference counting through Node interface:
//! ```zig
//! const attr = try doc.createAttribute("href");
//! defer attr.node.release(); // Decrements ref_count, frees if 0
//!
//! // When attached to element:
//! attr.node.acquire(); // Element holds a reference
//! _ = try elem.setAttributeNode(attr);
//! // Element will release when attribute is removed or element is destroyed
//! ```
//!
//! **CRITICAL: Owner Element Reference**
//! - `owner_element` is a WEAK pointer (does NOT hold reference)
//! - Element holds STRONG reference to Attr (via NamedNodeMap)
//! - When Element is destroyed, it releases all Attr nodes
//! - Attr.ownerElement becomes null when removed from element
//!
//! When an Attr node is released (ref_count reaches 0):
//! 1. Value string is freed (allocator.free(value))
//! 2. Node base is freed
//! 3. owner_element is NOT released (it's a weak pointer)
//!
//! ## Usage Examples
//!
//! ### Creating Attributes
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! // Via Document factory (RECOMMENDED - handles string interning)
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const attr = try doc.createAttribute("id");
//! attr.setValue("main");
//! defer attr.node.release();
//! ```
//!
//! ### Setting Attributes on Elements
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const elem = try doc.createElement("input");
//! const type_attr = try doc.createAttribute("type");
//! type_attr.setValue("text");
//!
//! const old_attr = try elem.setAttributeNode(type_attr);
//! std.debug.assert(old_attr == null); // No previous attribute
//! std.debug.assert(type_attr.ownerElement == elem);
//! ```
//!
//! ### Retrieving Attribute Nodes
//! ```zig
//! try elem.setAttribute("class", "btn btn-primary");
//!
//! if (elem.getAttributeNode("class")) |attr| {
//!     std.debug.print("Class: {s}\n", .{attr.value()});
//!     std.debug.assert(attr.ownerElement == elem);
//! }
//! ```
//!
//! ### Removing Attribute Nodes
//! ```zig
//! const attr = elem.getAttributeNode("id") orelse return;
//! const removed = try elem.removeAttributeNode(attr);
//! std.debug.assert(removed == attr);
//! std.debug.assert(attr.ownerElement == null); // Detached
//! ```
//!
//! ## Common Patterns
//!
//! ### Cloning Attributes
//! ```zig
//! const original = try doc.createAttribute("data-id");
//! original.setValue("12345");
//!
//! const cloned_node = try original.node.cloneNode(false);
//! const cloned = Node.downcast(cloned_node, Attr).?;
//! std.debug.assert(std.mem.eql(u8, cloned.value(), original.value()));
//! std.debug.assert(cloned.ownerElement == null); // Clones are detached
//! ```
//!
//! ### Moving Attributes Between Elements
//! ```zig
//! const elem1 = try doc.createElement("div");
//! const elem2 = try doc.createElement("span");
//!
//! const attr = try doc.createAttribute("class");
//! attr.setValue("highlight");
//!
//! _ = try elem1.setAttributeNode(attr);
//! std.debug.assert(attr.ownerElement == elem1);
//!
//! // Moving to elem2 automatically removes from elem1
//! _ = try elem2.setAttributeNode(attr);
//! std.debug.assert(attr.ownerElement == elem2);
//! std.debug.assert(elem1.getAttributeNode("class") == null);
//! ```
//!
//! ## Specification Notes
//!
//! ### Node Type Behavior
//! - `nodeType` is always `.attribute` (2)
//! - `nodeName` returns the attribute name (same as `.name`)
//! - `nodeValue` returns the attribute value (same as `.value`)
//! - `parentNode` is always null (attributes are not part of tree)
//!
//! ### Specified Property
//! - The `specified` property always returns `true`
//! - It's a legacy property from DOM Level 2
//! - In modern DOM, all Attr nodes are considered "specified"
//! - Kept for backward compatibility only
//!
//! ### Namespaced Attributes
//! - Use `Document.createAttributeNS()` for namespaced attributes
//! - `namespaceURI` and `prefix` are set during creation
//! - `localName` is the name without prefix
//! - `name` includes prefix if present (e.g., "xml:lang")
//!
//! ## Performance Considerations
//!
//! - **String Interning**: Attribute names should be interned via Document
//! - **Weak Pointers**: ownerElement is weak to avoid circular references
//! - **Direct Access**: For simple get/set, use Element.getAttribute() instead
//! - **Attr Nodes**: Only needed when treating attributes as first-class objects
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // name (readonly)
//! Object.defineProperty(Attr.prototype, 'name', {
//!   get: function() { return zig.attr_get_name(this._ptr); }
//! });
//!
//! // value (read-write)
//! Object.defineProperty(Attr.prototype, 'value', {
//!   get: function() { return zig.attr_get_value(this._ptr); },
//!   set: function(val) { zig.attr_set_value(this._ptr, val); }
//! });
//!
//! // ownerElement (readonly)
//! Object.defineProperty(Attr.prototype, 'ownerElement', {
//!   get: function() { return zig.attr_get_owner_element(this._ptr); }
//! });
//!
//! // specified (readonly, always true)
//! Object.defineProperty(Attr.prototype, 'specified', {
//!   get: function() { return true; }
//! });
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns.
//!
//! ## Implementation Notes
//!
//! - Attr extends Node via struct embedding (node is first field)
//! - Attr.value is owned by the Attr node (allocated, must be freed)
//! - Node.nodeValue() returns attr.value for attribute nodes
//! - Attr.ownerElement is a WEAK pointer (no reference counting)
//! - Attribute names are interned strings (when created via Document)
//! - Attr nodes do NOT participate in tree structure (no parent/siblings)
//! - Attr nodes CAN have children (Text nodes) per spec, but rarely used
//! - `specified` always returns true (legacy property)

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;
const DOMError = @import("validation.zig").DOMError;

// Forward declaration for Element
const Element = @import("element.zig").Element;

/// Attr node representing an attribute of an Element in the DOM.
///
/// Attr nodes provide an object-oriented view of element attributes,
/// with properties for name, value, namespace, and owner element.
///
/// ## Memory Layout
/// - Embeds Node as first field (for vtable polymorphism)
/// - Stores local_name as interned string (8 bytes)
/// - Stores value as owned string slice (16 bytes)
/// - Optional namespace_uri (8 bytes)
/// - Optional prefix (8 bytes)
/// - WEAK owner_element pointer (8 bytes)
pub const Attr = struct {
    /// Base Node (MUST be first field for @fieldParentPtr to work)
    node: Node,

    /// Local name of the attribute (interned string, 8 bytes)
    /// For non-namespaced attributes, this is the same as `name`
    local_name: []const u8,

    /// Attribute value (owned string, 16 bytes)
    /// Allocated and freed by this Attr node
    _value: []u8,

    /// Namespace URI (8 bytes)
    /// Null for non-namespaced attributes
    namespace_uri: ?[]const u8 = null,

    /// Namespace prefix (8 bytes)
    /// Null for non-namespaced attributes or default namespace
    prefix: ?[]const u8 = null,

    /// WEAK pointer to owning Element (8 bytes)
    /// This is NOT a strong reference - Element holds the strong reference to Attr
    /// Set to null when Attr is removed from Element
    owner_element: ?*Element = null,

    /// Vtable for Attr nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };

    /// Creates a new Attr node with the specified name.
    ///
    /// ## Memory Management
    /// Returns Attr with ref_count=1. Caller MUST call `attr.node.release()`.
    /// Attribute name is used as-is (not copied). Value is empty string initially.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for the Attr node
    /// - `local_name`: Attribute name (should be interned string)
    ///
    /// ## Returns
    /// Pointer to newly created Attr node, or error if allocation fails.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#interface-attr
    ///
    /// **WebIDL**: dom.idl:432-442
    pub fn create(allocator: Allocator, local_name: []const u8) !*Attr {
        const attr = try allocator.create(Attr);
        errdefer allocator.destroy(attr);

        // Allocate empty value
        const empty_value = try allocator.alloc(u8, 0);
        errdefer allocator.free(empty_value);

        // Initialize base Node
        attr.node = .{
            .prototype = .{
                .vtable = &node_mod.eventtarget_vtable,
            },
            .vtable = &vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .attribute,
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

        attr.local_name = local_name;
        attr._value = empty_value;
        attr.namespace_uri = null;
        attr.prefix = null;
        attr.owner_element = null;

        return attr;
    }

    /// Creates a new namespaced Attr node.
    ///
    /// ## Memory Management
    /// Returns Attr with ref_count=1. Caller MUST call `attr.node.release()`.
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for the Attr node
    /// - `namespace_uri`: Namespace URI (nullable)
    /// - `qualified_name`: Qualified name (may include prefix like "xml:lang")
    ///
    /// ## Returns
    /// Pointer to newly created namespaced Attr node.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-createattributens
    pub fn createNS(
        allocator: Allocator,
        namespace_uri: ?[]const u8,
        qualified_name: []const u8,
    ) !*Attr {
        // Parse qualified name to extract prefix and local name
        var prefix: ?[]const u8 = null;
        var local_name: []const u8 = qualified_name;

        if (std.mem.indexOf(u8, qualified_name, ":")) |colon_idx| {
            prefix = qualified_name[0..colon_idx];
            local_name = qualified_name[colon_idx + 1 ..];
        }

        const attr = try allocator.create(Attr);
        errdefer allocator.destroy(attr);

        // Allocate empty value
        const empty_value = try allocator.alloc(u8, 0);
        errdefer allocator.free(empty_value);

        // Initialize base Node
        attr.node = .{
            .prototype = .{
                .vtable = &node_mod.eventtarget_vtable,
            },
            .vtable = &vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .attribute,
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

        attr.local_name = local_name;
        attr._value = empty_value;
        attr.namespace_uri = namespace_uri;
        attr.prefix = prefix;
        attr.owner_element = null;

        return attr;
    }

    /// Returns the qualified name of the attribute.
    ///
    /// For namespaced attributes with a prefix, returns "prefix:localName".
    /// For non-namespaced attributes, returns just the local name.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-attr-name
    ///
    /// **WebIDL**: dom.idl:436
    pub fn name(self: *const Attr) []const u8 {
        if (self.prefix) |pfx| {
            // TODO: Consider caching this concatenation
            const allocator = self.node.allocator;
            const full_name = std.fmt.allocPrint(
                allocator,
                "{s}:{s}",
                .{ pfx, self.local_name },
            ) catch return self.local_name;
            return full_name;
        }
        return self.local_name;
    }

    /// Returns the attribute value.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-attr-value
    ///
    /// **WebIDL**: dom.idl:437
    pub fn value(self: *const Attr) []const u8 {
        return self._value;
    }

    /// Sets the attribute value.
    ///
    /// Frees the old value and allocates a new copy of the provided value.
    ///
    /// ## Parameters
    /// - `new_value`: New value to set
    ///
    /// ## Returns
    /// Error if allocation fails, otherwise void.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-attr-value
    ///
    /// **WebIDL**: dom.idl:437 [CEReactions]
    pub fn setValue(self: *Attr, new_value: []const u8) !void {
        const allocator = self.node.allocator;

        // Free old value
        allocator.free(self._value);

        // Allocate and copy new value
        const value_copy = try allocator.dupe(u8, new_value);
        self._value = value_copy;

        // TODO: Fire CEReactions if attached to element
    }

    /// Returns true if this attribute was explicitly specified.
    ///
    /// This is a legacy property from DOM Level 2 that always returns true
    /// in modern implementations. Kept for backward compatibility.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-attr-specified
    ///
    /// **WebIDL**: dom.idl:441
    pub fn specified(_: *const Attr) bool {
        return true; // Always true per spec
    }

    // VTable implementations

    fn deinitImpl(node: *Node) void {
        const self: *Attr = @fieldParentPtr("node", node);
        const allocator = node.allocator;

        // Free value
        allocator.free(self._value);

        // Note: We do NOT free local_name, namespace_uri, or prefix
        // as they may be interned strings or not owned by this Attr

        allocator.destroy(self);
    }

    fn nodeNameImpl(node: *const Node) []const u8 {
        const self: *const Attr = @fieldParentPtr("node", node);
        return self.name();
    }

    fn nodeValueImpl(node: *const Node) ?[]const u8 {
        const self: *const Attr = @fieldParentPtr("node", node);
        return self.value();
    }

    fn setNodeValueImpl(node: *Node, new_value: []const u8) !void {
        const self: *Attr = @fieldParentPtr("node", node);
        try self.setValue(new_value);
    }

    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        _ = deep; // Attr nodes don't have children
        const self: *const Attr = @fieldParentPtr("node", node);

        const cloned = if (self.namespace_uri != null or self.prefix != null)
            try createNS(node.allocator, self.namespace_uri, self.name())
        else
            try create(node.allocator, self.local_name);

        // Copy value
        try cloned.setValue(self.value());

        // Preserve owner document (WHATWG DOM clone algorithm)
        cloned.node.owner_document = self.node.owner_document;

        // Note: owner_element is NOT copied - clones are detached
        return &cloned.node;
    }

    fn adoptingStepsImpl(_: *Node, _: ?*Node) !void {
        // Attr nodes don't need special adoption steps
        // owner_element is managed by Element methods
    }
};

