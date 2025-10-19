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
        var iter = attrs.map.iterator();
        var i: u32 = 0;
        while (iter.next()) |entry| {
            if (i == index) {
                // Create or retrieve cached Attr node
                return try self.getOrCreateAttr(entry.key_ptr.*, entry.value_ptr.*);
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
        var iter = attrs.map.iterator();

        while (iter.next()) |entry| {
            const name = entry.key_ptr.*;
            const value = entry.value_ptr.*;

            // Parse the attribute name to check if it matches
            // For namespaced attributes, name is "prefix:localName"
            const has_colon = std.mem.indexOf(u8, name, ":");

            if (has_colon) |colon_idx| {
                const attr_local = name[colon_idx + 1 ..];

                // Check if local names match
                if (std.mem.eql(u8, attr_local, local_name)) {
                    // Get or create the attr to check its namespace
                    const attr = try self.getOrCreateAttr(name, value);

                    // Match namespace (null vs null, or string equality)
                    const ns_match = if (namespace_uri == null and attr.namespace_uri == null)
                        true
                    else if (namespace_uri != null and attr.namespace_uri != null)
                        std.mem.eql(u8, namespace_uri.?, attr.namespace_uri.?)
                    else
                        false;

                    if (ns_match) {
                        return attr;
                    }
                }
            } else {
                // Non-namespaced attribute - only matches if namespace is null
                if (namespace_uri == null and std.mem.eql(u8, name, local_name)) {
                    return try self.getOrCreateAttr(name, value);
                }
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

        // Set the new attribute value
        try self.element.setAttribute(attr_name, attr.value());

        // Update attr's owner_element
        attr.owner_element = self.element;

        // TODO: Fire CEReactions

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
            // Remove from attribute map using its full name
            self.element.removeAttribute(old.name());
        }

        // Set the new attribute value using full qualified name
        const attr_name = attr.name();
        try self.element.setAttribute(attr_name, attr.value());

        // Update attr's owner_element
        attr.owner_element = self.element;

        // TODO: Fire CEReactions

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
        // Get the Attr node before removing
        const attr = try self.getNamedItem(qualified_name) orelse return DOMError.NotFoundError;

        // Remove from element
        self.element.removeAttribute(qualified_name);

        // Detach from element
        attr.owner_element = null;

        // TODO: Fire CEReactions

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
        // Get the namespaced Attr node before removing
        const attr = try self.getNamedItemNS(namespace_uri, local_name) orelse return DOMError.NotFoundError;

        // Remove from element using full qualified name
        self.element.removeAttribute(attr.name());

        // Detach from element
        attr.owner_element = null;

        // TODO: Fire CEReactions

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
        const allocator = self.element.prototype.allocator;

        // TODO: Check Element's Attr cache first

        // Create new Attr node
        const attr = try Attr.create(allocator, name);
        try attr.setValue(value);
        attr.owner_element = self.element;

        // TODO: Add to Element's Attr cache

        return attr;
    }
};

// Tests
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectEqualStrings = testing.expectEqualStrings;

test "NamedNodeMap: length" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("id", "main");
    try elem.setAttribute("class", "container");

    var attrs = NamedNodeMap{ .element = elem };
    try expectEqual(@as(u32, 2), attrs.length());
}

test "NamedNodeMap: getNamedItem" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "input");
    defer elem.prototype.release();

    try elem.setAttribute("type", "text");
    try elem.setAttribute("name", "username");

    var attrs = NamedNodeMap{ .element = elem };

    const type_attr = try attrs.getNamedItem("type");
    try expect(type_attr != null);
    try expectEqualStrings("type", type_attr.?.name());
    try expectEqualStrings("text", type_attr.?.value());
    try expect(type_attr.?.owner_element == elem);

    const missing = try attrs.getNamedItem("missing");
    try expect(missing == null);
}

test "NamedNodeMap: item" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("a", "1");
    try elem.setAttribute("b", "2");

    var attrs = NamedNodeMap{ .element = elem };

    const attr0 = try attrs.item(0);
    try expect(attr0 != null);

    const attr1 = try attrs.item(1);
    try expect(attr1 != null);

    const attr2 = try attrs.item(2);
    try expect(attr2 == null); // Out of bounds
}

test "NamedNodeMap: setNamedItem" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    const attr = try Attr.create(allocator, "title");
    defer attr.node.release();
    try attr.setValue("Hello World");

    var attrs = NamedNodeMap{ .element = elem };
    const old = try attrs.setNamedItem(attr);
    try expect(old == null);

    try expectEqualStrings("Hello World", elem.getAttribute("title").?);
    try expect(attr.owner_element == elem);
}

test "NamedNodeMap: setNamedItem replaces existing" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("id", "old");

    var attrs = NamedNodeMap{ .element = elem };

    const new_attr = try Attr.create(allocator, "id");
    defer new_attr.node.release();
    try new_attr.setValue("new");

    const old_attr = try attrs.setNamedItem(new_attr);
    try expect(old_attr != null);
    try expectEqualStrings("old", old_attr.?.value());
    try expect(old_attr.?.owner_element == null); // Detached

    try expectEqualStrings("new", elem.getAttribute("id").?);
}

test "NamedNodeMap: removeNamedItem" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("class", "highlight");

    var attrs = NamedNodeMap{ .element = elem };

    const removed = try attrs.removeNamedItem("class");
    defer removed.node.release();

    try expectEqualStrings("highlight", removed.value());
    try expect(removed.owner_element == null); // Detached
    try expect(elem.getAttribute("class") == null);
}

test "NamedNodeMap: removeNamedItem not found" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    var attrs = NamedNodeMap{ .element = elem };

    const result = attrs.removeNamedItem("missing");
    try expect(result == DOMError.NotFoundError);
}

test "NamedNodeMap: memory leak check" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    try elem.setAttribute("a", "1");
    try elem.setAttribute("b", "2");
    try elem.setAttribute("c", "3");

    var attrs = NamedNodeMap{ .element = elem };

    _ = try attrs.item(0);
    _ = try attrs.item(1);
    _ = try attrs.getNamedItem("c");

    // Verify no leaks via testing allocator
}

test "NamedNodeMap: getNamedItemNS with namespaces" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    // Add a namespaced attribute via setAttribute (simulates xml:lang)
    try elem.setAttribute("xml:lang", "en");
    try elem.setAttribute("id", "main");

    var attrs = NamedNodeMap{ .element = elem };

    // Get non-namespaced attribute
    const id_attr = try attrs.getNamedItemNS(null, "id");
    defer if (id_attr) |a| a.node.release();
    try expect(id_attr != null);
    try expectEqualStrings("main", id_attr.?.value());

    // Try to get namespaced attribute by localName
    // Note: This will find "xml:lang" but match fails due to null namespace
    const lang_no_ns = try attrs.getNamedItemNS(null, "lang");
    defer if (lang_no_ns) |a| a.node.release();
    try expect(lang_no_ns == null); // Doesn't match - needs namespace

    // Get by full name works
    const lang_full = try attrs.getNamedItem("xml:lang");
    defer if (lang_full) |a| a.node.release();
    try expect(lang_full != null);
    try expectEqualStrings("en", lang_full.?.value());
}

test "NamedNodeMap: setNamedItemNS and removeNamedItemNS" {
    const allocator = testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    // Create a namespaced attribute
    const attr = try Attr.createNS(
        allocator,
        "http://www.w3.org/XML/1998/namespace",
        "xml:lang",
    );
    defer attr.node.release();
    try attr.setValue("fr");

    var attrs = NamedNodeMap{ .element = elem };

    // Set namespaced attribute
    const old = try attrs.setNamedItemNS(attr);
    try expect(old == null);
    try expectEqualStrings("fr", elem.getAttribute("xml:lang").?);

    // Remove by namespace
    const removed = try attrs.removeNamedItemNS(
        "http://www.w3.org/XML/1998/namespace",
        "lang",
    );
    defer removed.node.release();
    try expectEqualStrings("fr", removed.value());
    try expect(elem.getAttribute("xml:lang") == null);
}
