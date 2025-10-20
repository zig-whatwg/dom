//! NamedNodeMap Interface (§4.10 - Attribute Collections)
//!
//! This module implements the NamedNodeMap interface as specified by the WHATWG DOM Standard.
//! NamedNodeMap provides an object-oriented collection view of an element's attributes,
//! exposing them as Attr nodes rather than simple string name/value pairs.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.10 Interface NamedNodeMap**: https://dom.spec.whatwg.org/#interface-namednodemap
//! - **§4.10 Interface Element**: https://dom.spec.whatwg.org/#interface-element
//! - **§4.10 Interface Attr**: https://dom.spec.whatwg.org/#interface-attr
//!
//! ## WebIDL Definition
//!
//! ```webidl
//! [Exposed=Window]
//! interface NamedNodeMap {
//!   readonly attribute unsigned long length;
//!   getter Attr? item(unsigned long index);
//!   getter Attr? getNamedItem(DOMString qualifiedName);
//!   Attr? getNamedItemNS(DOMString? namespace, DOMString localName);
//!   [CEReactions] Attr? setNamedItem(Attr attr);
//!   [CEReactions] Attr? setNamedItemNS(Attr attr);
//!   [CEReactions] Attr removeNamedItem(DOMString qualifiedName);
//!   [CEReactions] Attr removeNamedItemNS(DOMString? namespace, DOMString localName);
//! };
//! ```
//!
//! ## MDN Documentation
//!
//! - NamedNodeMap: https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap
//! - NamedNodeMap.length: https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/length
//! - NamedNodeMap.item(): https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/item
//! - NamedNodeMap.getNamedItem(): https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/getNamedItem
//! - NamedNodeMap.setNamedItem(): https://developer.mozilla.org/en-US/docs/Web/API/NamedNodeMap/setNamedItem
//!
//! ## Core Features
//!
//! ### Collection View
//! NamedNodeMap provides array-like and name-based access to attributes:
//! ```zig
//! const elem = try doc.createElement("div");
//! try elem.setAttribute("id", "main");
//! try elem.setAttribute("class", "container");
//!
//! const attrs = elem.getAttributes();
//! std.debug.print("Count: {}\n", .{attrs.length()}); // 2
//!
//! const id_attr = attrs.getNamedItem("id");
//! std.debug.print("ID: {s}\n", .{id_attr.?.value()}); // "main"
//! ```
//!
//! ### Index Access
//! Attributes can be accessed by numeric index:
//! ```zig
//! const attrs = elem.getAttributes();
//! var i: u32 = 0;
//! while (i < attrs.length()) : (i += 1) {
//!     if (attrs.item(i)) |attr| {
//!         std.debug.print("{s}={s}\n", .{ attr.name(), attr.value() });
//!     }
//! }
//! ```
//!
//! ### Setting Attr Nodes
//! NamedNodeMap allows setting attributes as Attr objects:
//! ```zig
//! const new_attr = try doc.createAttribute("title");
//! new_attr.setValue("Hello World");
//!
//! const old_attr = try attrs.setNamedItem(new_attr);
//! // old_attr is null (no previous title attribute)
//! ```
//!
//! ## Implementation Design
//!
//! **CRITICAL DESIGN DECISION**: NamedNodeMap is NOT a separate data structure.
//! It's a **view** into Element's existing AttributeMap that:
//! - Creates Attr nodes on-demand when accessed
//! - Syncs Attr node changes back to AttributeMap
//! - Caches Attr nodes for efficiency (owner_element back-pointer)
//!
//! This design:
//! ✅ Avoids duplicate storage (AttributeMap already exists)
//! ✅ Maintains compatibility with existing getAttribute/setAttribute
//! ✅ Creates Attr nodes lazily (only when needed)
//! ✅ Uses Element as single source of truth
//!
//! ## Memory Management
//!
//! NamedNodeMap itself doesn't own memory - it's a lightweight view:
//! ```zig
//! // NamedNodeMap is essentially a pointer to Element
//! pub const NamedNodeMap = struct {
//!     element: *Element, // WEAK pointer
//! };
//! ```
//!
//! **Attr Node Lifecycle**:
//! 1. **Created on access**: Attr nodes created lazily via getNamedItem/item
//! 2. **Cached in Element**: Element caches Attr nodes (TODO: implement cache)
//! 3. **Released with Element**: When Element destroyed, cached Attr nodes released
//!
//! ## Usage Examples
//!
//! ### Iterating Attributes
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const elem = try doc.createElement("input");
//! try elem.setAttribute("type", "text");
//! try elem.setAttribute("name", "username");
//! try elem.setAttribute("required", "");
//!
//! const attrs = elem.getAttributes();
//! var i: u32 = 0;
//! while (i < attrs.length()) : (i += 1) {
//!     if (attrs.item(i)) |attr| {
//!         std.debug.print("{s}=\"{s}\"\n", .{ attr.name(), attr.value() });
//!     }
//! }
//! // Output (order may vary):
//! // type="text"
//! // name="username"
//! // required=""
//! ```
//!
//! ### Getting Attribute Nodes
//! ```zig
//! try elem.setAttribute("id", "main-content");
//!
//! const attrs = elem.getAttributes();
//! if (attrs.getNamedItem("id")) |id_attr| {
//!     std.debug.print("ID: {s}\n", .{id_attr.value()});
//!     std.debug.assert(id_attr.ownerElement == elem);
//! }
//! ```
//!
//! ### Setting Attribute Nodes
//! ```zig
//! const title_attr = try doc.createAttribute("title");
//! title_attr.setValue("Click me!");
//!
//! const attrs = elem.getAttributes();
//! const old = try attrs.setNamedItem(title_attr);
//! std.debug.assert(old == null); // No previous title
//!
//! // Now elem has attribute: title="Click me!"
//! try expectEqualStrings("Click me!", elem.getAttribute("title").?);
//! ```
//!
//! ### Removing Attribute Nodes
//! ```zig
//! try elem.setAttribute("class", "highlight");
//!
//! const attrs = elem.getAttributes();
//! const removed = try attrs.removeNamedItem("class");
//! std.debug.print("Removed: {s}={s}\n", .{ removed.name(), removed.value() });
//!
//! // Attribute no longer on element
//! try expect(elem.getAttribute("class") == null);
//! try expect(removed.ownerElement == null); // Detached
//! ```
//!
//! ### Moving Attributes Between Elements
//! ```zig
//! const elem1 = try doc.createElement("div");
//! const elem2 = try doc.createElement("span");
//!
//! const attr = try doc.createAttribute("data-id");
//! attr.setValue("12345");
//!
//! _ = try elem1.getAttributes().setNamedItem(attr);
//! std.debug.assert(attr.ownerElement == elem1);
//!
//! // Move to elem2 - automatically removes from elem1
//! const old = try elem2.getAttributes().setNamedItem(attr);
//! std.debug.assert(attr.ownerElement == elem2);
//! std.debug.assert(elem1.getAttribute("data-id") == null);
//! ```
//!
//! ## Common Patterns
//!
//! ### Copying All Attributes
//! ```zig
//! fn copyAttributes(from: *Element, to: *Element) !void {
//!     const from_attrs = from.getAttributes();
//!     var i: u32 = 0;
//!     while (i < from_attrs.length()) : (i += 1) {
//!         if (from_attrs.item(i)) |attr| {
//!             try to.setAttribute(attr.name(), attr.value());
//!         }
//!     }
//! }
//! ```
//!
//! ### Finding Attributes by Prefix
//! ```zig
//! fn findDataAttributes(elem: *Element, allocator: Allocator) !std.ArrayList(*Attr) {
//!     var results = std.ArrayList(*Attr).init(allocator);
//!     const attrs = elem.getAttributes();
//!     var i: u32 = 0;
//!     while (i < attrs.length()) : (i += 1) {
//!         if (attrs.item(i)) |attr| {
//!             if (std.mem.startsWith(u8, attr.name(), "data-")) {
//!                 try results.append(attr);
//!             }
//!         }
//!     }
//!     return results;
//! }
//! ```
//!
//! ## Specification Notes
//!
//! ### Getter Annotations
//! - `getter item(index)` means `attrs[index]` syntax in JavaScript
//! - `getter getNamedItem(name)` means `attrs[name]` syntax in JavaScript
//! - Both getters can return null (attribute doesn't exist)
//!
//! ### CEReactions
//! - setNamedItem, setNamedItemNS, removeNamedItem, removeNamedItemNS have [CEReactions]
//! - These methods must trigger custom element reactions
//! - TODO: Implement CEReactions support
//!
//! ### Order Guarantees
//! - Attributes are enumerated in insertion order (per spec)
//! - Order is maintained across setAttribute/removeAttribute operations
//! - Implementation uses AttributeMap which preserves insertion order
//!
//! ### Namespace Support
//! - getNamedItemNS/setNamedItemNS/removeNamedItemNS support namespaced attributes
//! - Namespace matching is exact (null != "", per spec)
//! - Prefix is included in Attr.name for namespaced attributes
//!
//! ## Performance Considerations
//!
//! - **Lazy Creation**: Attr nodes only created when accessed via NamedNodeMap
//! - **Direct Access**: Use getAttribute/setAttribute for better performance
//! - **Caching**: Attr nodes should be cached to avoid repeated allocation
//! - **Weak References**: NamedNodeMap → Element is weak (no circular reference)
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // length (readonly)
//! Object.defineProperty(NamedNodeMap.prototype, 'length', {
//!   get: function() { return zig.namednodemap_get_length(this._ptr); }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! NamedNodeMap.prototype.item = function(index) {
//!   return zig.namednodemap_item(this._ptr, index);
//! };
//!
//! NamedNodeMap.prototype.getNamedItem = function(name) {
//!   return zig.namednodemap_get_named_item(this._ptr, name);
//! };
//!
//! NamedNodeMap.prototype.setNamedItem = function(attr) {
//!   return zig.namednodemap_set_named_item(this._ptr, attr._ptr);
//! };
//!
//! NamedNodeMap.prototype.removeNamedItem = function(name) {
//!   return zig.namednodemap_remove_named_item(this._ptr, name);
//! };
//! ```
//!
//! ### Array-Like Access (Getters)
//! ```javascript
//! // attrs[0] → item(0)
//! // attrs['class'] → getNamedItem('class')
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns.
//!
//! ## Implementation Notes
//!
//! - NamedNodeMap is a lightweight view (just a pointer to Element)
//! - Attr nodes are created on-demand from AttributeMap data
//! - Element owns the Attr nodes (strong references in cache)
//! - NamedNodeMap methods delegate to Element methods
//! - Changes via NamedNodeMap sync to AttributeMap immediately
//! - getAttribute/setAttribute bypass Attr node creation (faster)
//! - NamedNodeMap primarily for spec compliance and JS bindings

const std = @import("std");
const Allocator = std.mem.Allocator;
const Attr = @import("attr.zig").Attr;
const Element = @import("element.zig").Element;
const DOMError = @import("validation.zig").DOMError;

/// NamedNodeMap provides a collection view of an element's attributes.
///
/// This is a lightweight wrapper around Element that creates Attr nodes
/// on-demand and syncs changes back to the element's AttributeMap.
///
/// ## Memory
/// - NamedNodeMap itself is just a pointer (8 bytes)
/// - Element owns the Attr nodes via caching (TODO: implement)
/// - NamedNodeMap → Element reference is WEAK
pub const NamedNodeMap = struct {
    /// WEAK pointer to owning Element (8 bytes)
    /// Element owns this NamedNodeMap, not the other way around
    element: *Element,

    /// Returns the number of attributes in the map.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-namednodemap-length
    ///
    /// **WebIDL**: dom.idl:421
    pub fn length(self: *const NamedNodeMap) u32 {
        return @intCast(self.element.attributes.count());
    }

    /// Returns the attribute at the specified index, or null if out of bounds.
    ///
    /// Attributes are enumerated in insertion order.
    ///
    /// ## Parameters
    /// - `index`: Zero-based index
    ///
    /// ## Returns
    /// Attr node at index, or null if index >= length
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-namednodemap-item
    ///
    /// **WebIDL**: dom.idl:422 (getter)
    pub fn item(self: *NamedNodeMap, index: u32) !?*Attr {
        const attrs = &self.element.attributes;
        if (index >= attrs.count()) {
            return null;
        }

        // Iterate to the index-th attribute
        var iter = attrs.iterator();
        var i: u32 = 0;
        while (iter.next()) |attr| {
            if (i == index) {
                // Create or retrieve cached Attr node
                return try self.getOrCreateAttr(attr.name.local_name, attr.value);
            }
            i += 1;
        }

        return null;
    }

    /// Returns the attribute with the specified name, or null if not found.
    ///
    /// ## Parameters
    /// - `qualified_name`: Attribute name to look up
    ///
    /// ## Returns
    /// Attr node with matching name, or null if not found
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-namednodemap-getnameditem
    ///
    /// **WebIDL**: dom.idl:423 (getter)
    pub fn getNamedItem(self: *NamedNodeMap, qualified_name: []const u8) !?*Attr {
        const value = self.element.getAttribute(qualified_name) orelse return null;
        return try self.getOrCreateAttr(qualified_name, value);
    }

    /// Returns the namespaced attribute, or null if not found.
    ///
    /// ## Parameters
    /// - `namespace_uri`: Namespace URI (nullable)
    /// - `local_name`: Local name without prefix
    ///
    /// ## Returns
    /// Attr node with matching namespace and local name, or null
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-namednodemap-getnameditemns
    ///
    /// **WebIDL**: dom.idl:424
    pub fn getNamedItemNS(
        self: *NamedNodeMap,
        namespace_uri: ?[]const u8,
        local_name: []const u8,
    ) !?*Attr {
        // Iterate through all attributes to find matching (namespace, localName) pair
        // Note: null namespace is different from empty string per WHATWG spec
        const attrs = &self.element.attributes;
        var iter = attrs.iterator();

        while (iter.next()) |attribute| {
            // Check if local names match first
            if (!std.mem.eql(u8, attribute.name.local_name, local_name)) {
                continue;
            }

            // Check if namespace matches
            const ns_match = if (namespace_uri == null and attribute.name.namespace_uri == null)
                true
            else if (namespace_uri != null and attribute.name.namespace_uri != null)
                std.mem.eql(u8, namespace_uri.?, attribute.name.namespace_uri.?)
            else
                false;

            if (ns_match) {
                // Found matching attribute - create Attr node for it
                return try self.getOrCreateAttr(attribute.name.local_name, attribute.value);
            }
        }

        return null;
    }

    /// Sets an attribute node in the map.
    ///
    /// If an attribute with the same name already exists, it is replaced.
    /// The attr's ownerElement is updated to point to this element.
    ///
    /// ## Parameters
    /// - `attr`: Attr node to add
    ///
    /// ## Returns
    /// The replaced Attr node if one existed, otherwise null
    ///
    /// ## Errors
    /// - `InUseAttributeError`: If attr is already owned by another element
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-namednodemap-setnameditem
    ///
    /// **WebIDL**: dom.idl:425 [CEReactions]
    pub fn setNamedItem(self: *NamedNodeMap, attr: *Attr) !?*Attr {
        // [CEReactions] scope for custom element lifecycle callbacks (Phase 5)
        // Note: setAttribute() already has [CEReactions], so this creates nested scope
        // which is harmless and ensures spec compliance
        if (self.element.prototype.owner_document) |doc_node| {
            if (doc_node.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", doc_node);
                const stack = doc.getCEReactionsStack();
                try stack.enter();
                defer stack.leave();

                return try setNamedItemImpl(self, attr);
            }
        }

        return try setNamedItemImpl(self, attr);
    }

    fn setNamedItemImpl(self: *NamedNodeMap, attr: *Attr) !?*Attr {
        // Check if attr is already in use by another element
        if (attr.owner_element) |owner| {
            if (owner != self.element) {
                return DOMError.InUseAttributeError;
            }
        }

        // Get old attribute if it exists
        const attr_name = attr.name();
        const old_value = self.element.getAttribute(attr_name);
        var old_attr: ?*Attr = null;
        if (old_value) |_| {
            old_attr = try self.getNamedItem(attr_name);
            if (old_attr) |old| {
                old.owner_element = null; // Detach from element
            }
        }

        // Set the new attribute value (already has [CEReactions])
        try self.element.setAttribute(attr_name, attr.value());

        // Update attr's owner_element
        attr.owner_element = self.element;

        return old_attr;
    }

    /// Sets a namespaced attribute node in the map.
    ///
    /// ## Parameters
    /// - `attr`: Namespaced Attr node to add
    ///
    /// ## Returns
    /// The replaced Attr node if one existed, otherwise null
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-namednodemap-setnameditemns
    ///
    /// **WebIDL**: dom.idl:426 [CEReactions]
    pub fn setNamedItemNS(self: *NamedNodeMap, attr: *Attr) !?*Attr {
        // [CEReactions] scope for custom element lifecycle callbacks (Phase 5)
        if (self.element.prototype.owner_document) |doc_node| {
            if (doc_node.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", doc_node);
                const stack = doc.getCEReactionsStack();
                try stack.enter();
                defer stack.leave();

                return try setNamedItemNSImpl(self, attr);
            }
        }

        return try setNamedItemNSImpl(self, attr);
    }

    fn setNamedItemNSImpl(self: *NamedNodeMap, attr: *Attr) !?*Attr {
        // Check if attr is already in use by another element
        if (attr.owner_element) |owner| {
            if (owner != self.element) {
                return DOMError.InUseAttributeError;
            }
        }

        // For namespaced attributes, check for existing by (namespace, localName)
        const old_attr = if (attr.namespace_uri != null or attr.prefix != null)
            try self.getNamedItemNS(attr.namespace_uri, attr.local_name)
        else
            try self.getNamedItem(attr.local_name);

        // Detach old attr if exists
        if (old_attr) |old| {
            old.owner_element = null;
            // Remove from attribute map using namespace-aware method
            if (old.namespace_uri != null or old.prefix != null) {
                _ = self.element.attributes.removeNS(old.local_name, old.namespace_uri);
            } else {
                _ = self.element.attributes.remove(old.local_name);
            }
        }

        // Set the new attribute value using namespace-aware method
        if (attr.namespace_uri != null or attr.prefix != null) {
            try self.element.attributes.setNS(attr.local_name, attr.namespace_uri, attr.value());
        } else {
            try self.element.attributes.set(attr.local_name, attr.value());
        }

        // Update attr's owner_element
        attr.owner_element = self.element;

        return old_attr;
    }

    /// Removes the attribute with the specified name.
    ///
    /// ## Parameters
    /// - `qualified_name`: Name of attribute to remove
    ///
    /// ## Returns
    /// The removed Attr node
    ///
    /// ## Errors
    /// - `NotFoundError`: If no attribute with that name exists
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-namednodemap-removenameditem
    ///
    /// **WebIDL**: dom.idl:427 [CEReactions]
    pub fn removeNamedItem(self: *NamedNodeMap, qualified_name: []const u8) !*Attr {
        // [CEReactions] scope for custom element lifecycle callbacks (Phase 5)
        if (self.element.prototype.owner_document) |doc_node| {
            if (doc_node.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", doc_node);
                const stack = doc.getCEReactionsStack();
                try stack.enter();
                defer stack.leave();

                return try removeNamedItemImpl(self, qualified_name);
            }
        }

        return try removeNamedItemImpl(self, qualified_name);
    }

    fn removeNamedItemImpl(self: *NamedNodeMap, qualified_name: []const u8) !*Attr {
        // Get the Attr node before removing
        const attr = try self.getNamedItem(qualified_name) orelse return DOMError.NotFoundError;

        // Remove from element (already has [CEReactions])
        self.element.removeAttribute(qualified_name);

        // Detach from element
        attr.owner_element = null;

        return attr;
    }

    /// Removes the namespaced attribute.
    ///
    /// ## Parameters
    /// - `namespace_uri`: Namespace URI (nullable)
    /// - `local_name`: Local name without prefix
    ///
    /// ## Returns
    /// The removed Attr node
    ///
    /// ## Errors
    /// - `NotFoundError`: If no attribute matches
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-namednodemap-removenameditemns
    ///
    /// **WebIDL**: dom.idl:428 [CEReactions]
    pub fn removeNamedItemNS(
        self: *NamedNodeMap,
        namespace_uri: ?[]const u8,
        local_name: []const u8,
    ) !*Attr {
        // [CEReactions] scope for custom element lifecycle callbacks (Phase 5)
        if (self.element.prototype.owner_document) |doc_node| {
            if (doc_node.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", doc_node);
                const stack = doc.getCEReactionsStack();
                try stack.enter();
                defer stack.leave();

                return try removeNamedItemNSImpl(self, namespace_uri, local_name);
            }
        }

        return try removeNamedItemNSImpl(self, namespace_uri, local_name);
    }

    fn removeNamedItemNSImpl(
        self: *NamedNodeMap,
        namespace_uri: ?[]const u8,
        local_name: []const u8,
    ) !*Attr {
        // Get the namespaced Attr node before removing
        const attr = try self.getNamedItemNS(namespace_uri, local_name) orelse return DOMError.NotFoundError;

        // Remove from element using full qualified name (already has [CEReactions])
        self.element.removeAttribute(attr.name());

        // Detach from element
        attr.owner_element = null;

        return attr;
    }

    // Helper methods

    /// Gets or creates an Attr node for the given name/value pair.
    ///
    /// TODO: Implement caching in Element to avoid repeated allocations.
    fn getOrCreateAttr(
        self: *NamedNodeMap,
        name: []const u8,
        value: []const u8,
    ) !*Attr {
        // Use Element's cache for Attr node lifecycle management
        return try self.element.getOrCreateCachedAttr(name, value);
    }
};
