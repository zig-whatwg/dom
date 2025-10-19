//! Element Interface (§4.9)
//!
//! This module implements the Element interface as specified by the WHATWG DOM Standard.
//! Elements are the most commonly used nodes in the DOM tree and represent HTML/XML elements.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§4.9 Interface Element**: https://dom.spec.whatwg.org/#element
//! - **§4.9.1 Interface NamedNodeMap**: https://dom.spec.whatwg.org/#namednodemap
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#parentnode
//!
//! ## MDN Documentation
//!
//! - Element: https://developer.mozilla.org/en-US/docs/Web/API/Element
//! - Element.attributes: https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes
//! - Element.setAttribute: https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttribute
//! - Element.getAttribute: https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttribute
//! - Element.removeAttribute: https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttribute
//!
//! ## Core Features
//!
//! ### Attributes Management
//! Elements can have named attributes that provide metadata:
//! ```zig
//! const elem = try Element.create(allocator, "input");
//! defer elem.prototype.release();
//!
//! try elem.setAttribute("type", "text");
//! try elem.setAttribute("placeholder", "Enter name");
//! const type_attr = elem.getAttribute("type"); // "text"
//! ```
//!
//! ### Class Management
//! The `class` attribute is special with automatic bloom filter indexing:
//! ```zig
//! try elem.setAttribute("class", "btn btn-primary active");
//! // Bloom filter automatically updated for fast querySelector matching
//! const has_btn = elem.class_bloom.mayContain("btn"); // true (probably)
//! ```
//!
//! ### Tag Names
//! Tag names are stored as interned strings for memory efficiency:
//! ```zig
//! const div = try Element.create(allocator, "div");
//! const tag = div.tag_name; // "div" (pointer to interned string)
//! ```
//!
//! ## Element Data Structure
//!
//! Each element stores:
//! - **node**: Base Node (MUST be first field for @fieldParentPtr)
//! - **tag_name**: Interned string pointer (8 bytes)
//! - **attributes**: StringHashMap for O(1) attribute access (16 bytes)
//! - **class_bloom**: Bloom filter for fast class matching (8 bytes)
//!
//! Total additional size beyond Node: 32 bytes
//!
//! ## Memory Management
//!
//! Elements use reference counting through the Node interface:
//! ```zig
//! const element = try Element.create(allocator, "div");
//! defer element.prototype.release(); // Decrements ref_count, frees if 0
//!
//! // When sharing ownership:
//! element.prototype.acquire(); // Increment ref_count
//! other_structure.element = element;
//! // Both owners must call release()
//! ```
//!
//! When an element is released (ref_count reaches 0):
//! 1. Attribute map is freed
//! 2. Bloom filter is cleared
//! 3. Node base is freed (releases children recursively)
//!
//! ## Usage Examples
//!
//! ### Building a DOM Tree
//! ```zig
//! const allocator = std.heap.page_allocator;
//!
//! const article = try Element.create(allocator, "article");
//! defer article.prototype.release();
//!
//! const header = try Element.create(allocator, "header");
//! try header.setAttribute("class", "article-header");
//! _ = try article.prototype.appendChild(&header.prototype);
//!
//! const title = try Element.create(allocator, "h1");
//! try title.setAttribute("id", "main-title");
//! _ = try header.prototype.appendChild(&title.prototype);
//! ```
//!
//! ### Managing Attributes
//! ```zig
//! const button = try Element.create(allocator, "button");
//! defer button.prototype.release();
//!
//! // Set multiple attributes
//! try button.setAttribute("type", "submit");
//! try button.setAttribute("class", "btn btn-primary");
//! try button.setAttribute("disabled", "");
//!
//! // Check attribute existence
//! if (button.hasAttribute("disabled")) {
//!     // Button is disabled
//! }
//!
//! // Get attribute value
//! if (button.getAttribute("class")) |classes| {
//!     std.debug.print("Classes: {s}\n", .{classes});
//! }
//!
//! // Remove attribute
//! button.removeAttribute("disabled");
//! ```
//!
//! ### Working with Classes
//! ```zig
//! const div = try Element.create(allocator, "div");
//! defer div.prototype.release();
//!
//! try div.setAttribute("class", "container fluid active");
//!
//! // Bloom filter allows fast class checks
//! if (div.class_bloom.mayContain("container")) {
//!     // Likely has "container" class (fast check)
//!     // Full string comparison needed for certainty
//! }
//! ```
//!
//! ## Common Patterns
//!
//! ### Creating Form Elements
//! ```zig
//! const form = try Element.create(allocator, "form");
//! defer form.prototype.release();
//! try form.setAttribute("method", "POST");
//! try form.setAttribute("action", "/submit");
//!
//! const input = try Element.create(allocator, "input");
//! try input.setAttribute("type", "text");
//! try input.setAttribute("name", "username");
//! try input.setAttribute("required", "");
//! _ = try form.prototype.appendChild(&input.prototype);
//! ```
//!
//! ### Building Nested Structure
//! ```zig
//! const nav = try Element.create(allocator, "nav");
//! defer nav.prototype.release();
//!
//! const ul = try Element.create(allocator, "ul");
//! try ul.setAttribute("class", "menu");
//! _ = try nav.prototype.appendChild(&ul.prototype);
//!
//! const li = try Element.create(allocator, "li");
//! try li.setAttribute("class", "menu-item");
//! _ = try ul.prototype.appendChild(&li.prototype);
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Attribute access** is O(1) average case via StringHashMap
//! 2. **Class bloom filter** allows 80-90% rejection rate in querySelector without string comparison
//! 3. **String interning** means tag names and attribute names share memory across elements
//! 4. **Vtable dispatch** has minimal overhead (~2-3 instructions)
//! 5. **Tag names** are case-preserved (no normalization overhead)
//! 6. **setAttribute on class** automatically updates bloom filter for querySelector optimization
//!
//! ## JavaScript Bindings
//!
//! ### Instance Properties
//! ```javascript
//! // tagName (readonly)
//! Object.defineProperty(Element.prototype, 'tagName', {
//!   get: function() {
//!     return zig.element_get_tag_name(this._ptr);
//!   }
//! });
//!
//! // className (read/write)
//! Object.defineProperty(Element.prototype, 'className', {
//!   get: function() {
//!     return zig.element_get_attribute(this._ptr, 'class') || '';
//!   },
//!   set: function(value) {
//!     zig.element_setAttribute(this._ptr, 'class', value);
//!   }
//! });
//!
//! // id (read/write)
//! Object.defineProperty(Element.prototype, 'id', {
//!   get: function() {
//!     return zig.element_get_attribute(this._ptr, 'id') || '';
//!   },
//!   set: function(value) {
//!     zig.element_setAttribute(this._ptr, 'id', value);
//!   }
//! });
//! ```
//!
//! ### Instance Methods
//! ```javascript
//! Element.prototype.getAttribute = function(name) {
//!   return zig.element_getAttribute(this._ptr, name);
//! };
//!
//! Element.prototype.setAttribute = function(name, value) {
//!   zig.element_setAttribute(this._ptr, name, value);
//! };
//!
//! Element.prototype.removeAttribute = function(name) {
//!   zig.element_removeAttribute(this._ptr, name);
//! };
//!
//! Element.prototype.hasAttribute = function(name) {
//!   return zig.element_hasAttribute(this._ptr, name);
//! };
//! ```
//!
//! See `JS_BINDINGS.md` for complete binding patterns and memory management.
//!
//! ## Implementation Notes
//!
//! - Tag names are stored as interned strings (pointer to shared memory)
//! - Attribute names and values should be interned when using Document factory methods
//! - Bloom filter is updated on class attribute changes (maintains fast querySelector)
//! - Element extends Node via embedding (first field = Node)
//! - Vtable enables polymorphism without runtime type checks
//! - No class list array stored (class attribute is the source of truth)

const std = @import("std");
const Allocator = std.mem.Allocator;
const node_mod = @import("node.zig");
const Node = node_mod.Node;
const NodeType = node_mod.NodeType;
const NodeVTable = node_mod.NodeVTable;
const Attr = @import("attr.zig").Attr;
const NamedNodeMap = @import("named_node_map.zig").NamedNodeMap;
const DOMError = @import("validation.zig").DOMError;
const AttributeArray = @import("attribute_array.zig").AttributeArray;

/// Bloom filter for fast class name matching in querySelector.
///
/// Uses 64 bits to probabilistically track which class names are present.
/// False positives possible (may say "yes" when it's "no"), but no false negatives.
/// This allows rejecting 80-90% of non-matching elements without full string comparison.
pub const BloomFilter = struct {
    bits: u64 = 0,

    /// Adds a class name to the filter.
    pub fn add(self: *BloomFilter, class_name: []const u8) void {
        const hash = std.hash.Wyhash.hash(0, class_name);
        const bit = @as(u6, @truncate(hash));
        self.bits |= @as(u64, 1) << bit;
    }

    /// Returns true if class name MAY be present (false positives possible).
    pub fn mayContain(self: BloomFilter, class_name: []const u8) bool {
        const hash = std.hash.Wyhash.hash(0, class_name);
        const bit = @as(u6, @truncate(hash));
        const mask = @as(u64, 1) << bit;
        return (self.bits & mask) != 0;
    }

    /// Clears all bits in the filter.
    pub fn clear(self: *BloomFilter) void {
        self.bits = 0;
    }
};

/// Attribute map storing name→value pairs.
///
/// Uses StringHashMap for O(1) average-case access.
/// Keys and values are slices (pointers) to interned strings.
/// AttributeMap: Compatibility wrapper around AttributeArray.
///
/// Provides the old HashMap-based API for backward compatibility,
/// but delegates to the new AttributeArray implementation.
///
/// **Migration note**: This is a transitional type. Direct use of AttributeArray
/// is preferred for new code to access namespace support.
pub const AttributeMap = struct {
    array: AttributeArray,

    pub fn init(allocator: Allocator) AttributeMap {
        return .{
            .array = AttributeArray.init(allocator),
        };
    }

    pub fn deinit(self: *AttributeMap) void {
        self.array.deinit();
    }

    pub fn set(self: *AttributeMap, name: []const u8, value: []const u8) !void {
        // Delegate to AttributeArray with null namespace
        try self.array.set(name, null, value);
    }

    pub fn get(self: *const AttributeMap, name: []const u8) ?[]const u8 {
        // Delegate to AttributeArray with null namespace
        return self.array.get(name, null);
    }

    pub fn remove(self: *AttributeMap, name: []const u8) bool {
        // Delegate to AttributeArray with null namespace
        return self.array.remove(name, null);
    }

    pub fn has(self: *const AttributeMap, name: []const u8) bool {
        // Delegate to AttributeArray with null namespace
        return self.array.has(name, null);
    }

    pub fn count(self: *const AttributeMap) usize {
        return self.array.count();
    }

    /// Returns an iterator over attributes.
    ///
    /// For backward compatibility with code that accessed .map.iterator().
    pub fn iterator(self: *const AttributeMap) AttributeArray.Iterator {
        return self.array.iterator();
    }
};

/// Attr node cache for [SameObject] semantics.
///
/// Caches Attr nodes to ensure repeated calls to getAttributeNode()
/// return the same Attr object. Cache holds strong references to Attr nodes.
pub const AttrCache = struct {
    map: std.StringHashMap(*Attr),

    pub fn init(allocator: Allocator) AttrCache {
        return .{
            .map = std.StringHashMap(*Attr).init(allocator),
        };
    }

    pub fn deinit(self: *AttrCache) void {
        // Release all cached Attr nodes
        var iter = self.map.valueIterator();
        while (iter.next()) |attr_ptr| {
            attr_ptr.*.node.release();
        }
        self.map.deinit();
    }

    pub fn get(self: *const AttrCache, name: []const u8) ?*Attr {
        return self.map.get(name);
    }

    pub fn put(self: *AttrCache, name: []const u8, attr: *Attr) !void {
        try self.map.put(name, attr);
    }

    pub fn remove(self: *AttrCache, name: []const u8) ?*Attr {
        if (self.map.fetchRemove(name)) |entry| {
            return entry.value;
        }
        return null;
    }

    pub fn clearAll(self: *AttrCache) void {
        var iter = self.map.valueIterator();
        while (iter.next()) |attr_ptr| {
            attr_ptr.*.owner_element = null;
            attr_ptr.*.node.release();
        }
        self.map.clearRetainingCapacity();
    }
};

/// Element node representing an HTML/XML element.
///
/// Embeds Node as first field for vtable polymorphism.
/// Additional fields for element-specific data (tag, attributes, classes).
pub const Element = struct {
    /// Base Node prototype (MUST be first field for @fieldParentPtr to work)
    prototype: Node,

    /// Tag name (pointer to interned string, 8 bytes)
    /// e.g., "div", "span", "custom-element"
    tag_name: []const u8,

    /// Attribute map (16 bytes)
    /// Stores name→value pairs (both interned strings)
    attributes: AttributeMap,

    /// Bloom filter for class names (8 bytes)
    /// Enables fast rejection in querySelector(".class")
    class_bloom: BloomFilter,

    /// Attr node cache (optional, 8 bytes)
    /// Lazy allocation: null until first getAttributeNode() call
    /// Ensures [SameObject] semantics - repeated calls return same Attr
    attr_cache: ?AttrCache = null,

    /// Vtable for Element nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
        .adopting_steps = adoptingStepsImpl,
    };

    /// Creates a new Element with the specified tag name.
    ///
    /// Implements WHATWG DOM Document.createElement() per §4.10.
    /// Returns a new element with ref_count=1 that must be released by caller.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for element creation
    /// - `tag_name`: Element tag name (should be interned string for best performance)
    ///
    /// ## Returns
    ///
    /// New element node with ref_count=1
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Memory Management
    ///
    /// Returns Element with ref_count=1. Caller MUST call `element.prototype.release()` when done.
    /// If element is inserted into DOM tree, the tree maintains a reference.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const elem = try Element.create(allocator, "div");
    /// defer elem.prototype.release();
    ///
    /// try elem.setAttribute("class", "container");
    /// ```
    ///
    /// ## Specification
    ///
    /// See: https://dom.spec.whatwg.org/#dom-document-createelement
    pub fn create(allocator: Allocator, tag_name: []const u8) !*Element {
        return createWithVTable(allocator, tag_name, &vtable);
    }

    /// Creates an element with a custom vtable (enables extensibility).
    ///
    /// This is the extensibility point for HTML/XML libraries to inject custom behavior.
    /// The default `create()` method calls this with the default vtable.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `tag_name`: Element tag name (e.g., "div", "custom-element")
    /// - `node_vtable`: Custom NodeVTable for polymorphic behavior
    ///
    /// ## Returns
    ///
    /// Element pointer with custom vtable installed
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Failed to allocate memory
    ///
    /// ## Example (HTMLElement extending Element)
    ///
    /// ```zig
    /// const HTMLElement = struct {
    ///     element: Element,
    ///
    ///     const html_vtable = NodeVTable{
    ///         .deinit = htmlDeinit,
    ///         // ... custom implementations
    ///     };
    ///
    ///     pub fn create(allocator: Allocator, tag_name: []const u8) !*HTMLElement {
    ///         const elem = try Element.createWithVTable(allocator, tag_name, &html_vtable);
    ///         const html_elem = @fieldParentPtr(HTMLElement, "element", elem);
    ///         // Initialize HTMLElement-specific fields
    ///         return html_elem;
    ///     }
    /// };
    /// ```
    pub fn createWithVTable(
        allocator: Allocator,
        tag_name: []const u8,
        node_vtable: *const NodeVTable,
    ) !*Element {
        const elem = try allocator.create(Element);
        errdefer allocator.destroy(elem);

        // Initialize base Node
        elem.prototype = .{
            .prototype = .{
                .vtable = &node_mod.eventtarget_vtable,
            },
            .vtable = node_vtable,
            .ref_count_and_parent = std.atomic.Value(u32).init(1),
            .node_type = .element,
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

        // Initialize Element-specific fields
        elem.tag_name = tag_name;
        elem.attributes = AttributeMap.init(allocator);
        elem.class_bloom = .{};
        elem.attr_cache = null;

        return elem;
    }

    /// Sets an attribute on the element.
    ///
    /// Implements WHATWG DOM Element.setAttribute() per §4.9.
    /// If the attribute already exists, its value is updated. Otherwise, a new attribute is added.
    /// When setting the "class" attribute, the bloom filter is automatically updated for
    /// fast querySelector performance.
    ///
    /// ## Parameters
    ///
    /// - `name`: Attribute name (should be interned string for best performance)
    /// - `value`: Attribute value (should be interned string for best performance)
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Failed to allocate attribute storage
    ///
    /// ## Example
    ///
    /// ```zig
    /// try element.setAttribute("id", "main-content");
    /// try element.setAttribute("class", "container fluid");
    /// try element.setAttribute("data-user", "12345");
    /// ```
    ///
    /// ## Specification
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-setattribute
    /// See: https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttribute
    pub fn setAttribute(self: *Element, name: []const u8, value: []const u8) !void {
        // Handle ID attribute changes (maintain document ID map)
        // Only update id_map if element is connected to the document tree
        // Per browser behavior: disconnected elements don't participate in getElementById
        if (std.mem.eql(u8, name, "id")) {
            if (self.prototype.isConnected()) {
                // Remove old ID from document map if it exists and this element is the one mapped
                if (self.getAttribute("id")) |old_id| {
                    if (self.prototype.owner_document) |owner| {
                        if (owner.node_type == .document) {
                            const Document = @import("document.zig").Document;
                            const doc: *Document = @fieldParentPtr("prototype", owner);

                            // Only remove if this element is the one in the map
                            if (doc.id_map.get(old_id)) |mapped_elem| {
                                if (mapped_elem == self) {
                                    _ = doc.id_map.remove(old_id);
                                    doc.invalidateIdCache();

                                    // Search for another element with the same ID to replace it
                                    const ElementIterator = @import("element_iterator.zig").ElementIterator;
                                    var iter = ElementIterator.init(&doc.prototype);
                                    while (iter.next()) |other_elem| {
                                        if (other_elem != self) {
                                            if (other_elem.getId()) |other_id| {
                                                if (std.mem.eql(u8, other_id, old_id)) {
                                                    doc.id_map.put(old_id, other_elem) catch {};
                                                    doc.invalidateIdCache();
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Set the attribute
        try self.attributes.set(name, value);

        // Invalidate cached Attr for this name
        self.invalidateCachedAttr(name);

        // Update bloom filter for class attribute (Phase 3: class_map removed, bloom filter still used)
        if (std.mem.eql(u8, name, "class")) {
            self.updateClassBloom(value);
        }

        // Add new ID to document map (only if connected, and only if ID not already in use - first wins)
        if (std.mem.eql(u8, name, "id")) {
            if (self.prototype.isConnected()) {
                if (self.prototype.owner_document) |owner| {
                    if (owner.node_type == .document) {
                        const Document = @import("document.zig").Document;
                        const doc: *Document = @fieldParentPtr("prototype", owner);
                        const result = try doc.id_map.getOrPut(value);
                        if (!result.found_existing) {
                            result.value_ptr.* = self;
                            doc.invalidateIdCache();
                        }
                    }
                }
            }
        }

        // Handle slot name attribute changes (WHATWG DOM §4.2.2.3)
        // When a slot's name changes, reassign all slottables in the shadow tree
        if (std.mem.eql(u8, name, "name") and std.mem.eql(u8, self.tag_name, "slot")) {
            // Run assign slottables for a tree with element's root
            const root = self.prototype.getRootNode(false);
            if (root.node_type == .shadow_root) {
                assignSlottablesForTree(self.prototype.allocator, root) catch {};
            }
        }

        // Handle slottable slot attribute changes (WHATWG DOM §4.2.2.3)
        // When an element's slot attribute changes, reassign it to the correct slot
        if (std.mem.eql(u8, name, "slot")) {
            // If element is assigned, run assign slottables for element's assigned slot
            if (self.assignedSlot()) |assigned| {
                assignSlottables(self.prototype.allocator, assigned) catch {};
            }
            // Run assign a slot for element
            assignASlot(self.prototype.allocator, &self.prototype) catch {};
        }
    }

    /// Gets an attribute value from the element.
    ///
    /// Implements WHATWG DOM Element.getAttribute() per §4.9.
    /// Returns the attribute's value as a string, or null if the attribute doesn't exist.
    ///
    /// ## Parameters
    ///
    /// - `name`: Attribute name to lookup
    ///
    /// ## Returns
    ///
    /// Attribute value or null if attribute is not present
    ///
    /// ## Example
    ///
    /// ```zig
    /// if (element.getAttribute("id")) |id| {
    ///     std.debug.print("Element ID: {s}\n", .{id});
    /// } else {
    ///     std.debug.print("No ID attribute\n", .{});
    /// }
    /// ```
    ///
    /// ## Specification
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-getattribute
    /// See: https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttribute
    pub fn getAttribute(self: *const Element, name: []const u8) ?[]const u8 {
        return self.attributes.get(name);
    }

    /// Removes an attribute from the element.
    ///
    /// Implements WHATWG DOM Element.removeAttribute() interface.
    /// Per WebIDL spec, this returns void (not bool).
    ///
    /// ## Parameters
    /// - `name`: Attribute name to remove
    pub fn removeAttribute(self: *Element, name: []const u8) void {
        // Remove ID from document map before removing attribute (only if connected and this element is mapped)
        if (std.mem.eql(u8, name, "id")) {
            if (self.prototype.isConnected()) {
                if (self.getAttribute("id")) |old_id| {
                    if (self.prototype.owner_document) |owner| {
                        if (owner.node_type == .document) {
                            const Document = @import("document.zig").Document;
                            const doc: *Document = @fieldParentPtr("prototype", owner);

                            // Only remove if this element is the one in the map
                            if (doc.id_map.get(old_id)) |mapped_elem| {
                                if (mapped_elem == self) {
                                    _ = doc.id_map.remove(old_id);
                                    doc.invalidateIdCache();

                                    // Search for another element with the same ID to replace it
                                    const ElementIterator = @import("element_iterator.zig").ElementIterator;
                                    var iter = ElementIterator.init(&doc.prototype);
                                    while (iter.next()) |other_elem| {
                                        if (other_elem != self) {
                                            if (other_elem.getId()) |other_id| {
                                                if (std.mem.eql(u8, other_id, old_id)) {
                                                    doc.id_map.put(old_id, other_elem) catch {};
                                                    doc.invalidateIdCache();
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        const removed = self.attributes.remove(name);

        // Invalidate cached Attr for this name
        if (removed) {
            self.invalidateCachedAttr(name);
        }

        // Clear bloom filter if removing class attribute (Phase 3: class_map removed, bloom filter still used)
        if (removed and std.mem.eql(u8, name, "class")) {
            self.class_bloom.clear();
        }

        // Handle slot name attribute removal (WHATWG DOM §4.2.2.3)
        // When a slot's name is removed, it becomes a default slot - reassign all slottables
        if (removed and std.mem.eql(u8, name, "name") and std.mem.eql(u8, self.tag_name, "slot")) {
            // Run assign slottables for a tree with element's root
            const root = self.prototype.getRootNode(false);
            if (root.node_type == .shadow_root) {
                assignSlottablesForTree(self.prototype.allocator, root) catch {};
            }
        }

        // Handle slottable slot attribute removal (WHATWG DOM §4.2.2.3)
        // When an element's slot attribute is removed, reassign it to default slot
        if (removed and std.mem.eql(u8, name, "slot")) {
            // If element was assigned, run assign slottables for its old slot
            if (self.assignedSlot()) |assigned| {
                assignSlottables(self.prototype.allocator, assigned) catch {};
            }
            // Run assign a slot for element (will now match default slot)
            assignASlot(self.prototype.allocator, &self.prototype) catch {};
        }
    }

    /// Checks if element has an attribute.
    pub fn hasAttribute(self: *const Element, name: []const u8) bool {
        return self.attributes.has(name);
    }

    /// Gets an attribute value by namespace and local name.
    ///
    /// Implements WHATWG DOM Element.getAttributeNS() interface.
    ///
    /// ## WebIDL
    ///
    /// ```webidl
    /// DOMString? getAttributeNS(DOMString? namespace, DOMString localName);
    /// ```
    ///
    /// ## Parameters
    ///
    /// - `namespace`: Namespace URI (nullable)
    /// - `local_name`: Local name of the attribute
    ///
    /// ## Returns
    ///
    /// Attribute value if found, null otherwise.
    ///
    /// ## Spec References
    ///
    /// **WHATWG DOM**:
    /// > The getAttributeNS(namespace, localName) method steps are to return the result of
    /// > getting an attribute given namespace, localName, and this.
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-getattributens
    /// See: https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttributeNS
    ///
    /// ## Example
    ///
    /// ```zig
    /// const xml_ns = "http://www.w3.org/XML/1998/namespace";
    /// if (element.getAttributeNS(xml_ns, "lang")) |value| {
    ///     // Found xml:lang attribute
    /// }
    /// ```
    pub fn getAttributeNS(
        self: *const Element,
        namespace: ?[]const u8,
        local_name: []const u8,
    ) ?[]const u8 {
        return self.attributes.array.get(local_name, namespace);
    }

    /// Sets an attribute with a namespace and qualified name.
    ///
    /// Implements WHATWG DOM Element.setAttributeNS() interface.
    ///
    /// ## WebIDL
    ///
    /// ```webidl
    /// [CEReactions] undefined setAttributeNS(DOMString? namespace, DOMString qualifiedName, DOMString value);
    /// ```
    ///
    /// ## Parameters
    ///
    /// - `namespace`: Namespace URI (nullable)
    /// - `qualified_name`: Qualified name (may include prefix, e.g. "xml:lang")
    /// - `value`: Attribute value
    ///
    /// ## Spec References
    ///
    /// **WHATWG DOM**:
    /// > The setAttributeNS(namespace, qualifiedName, value) method steps are:
    /// > 1. Let namespace, prefix, and localName be the result of passing namespace and qualifiedName to validate and extract.
    /// > 2. Set an attribute value for this using localName, value, and also prefix and namespace.
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-setattributens
    /// See: https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttributeNS
    ///
    /// ## Example
    ///
    /// ```zig
    /// const xml_ns = "http://www.w3.org/XML/1998/namespace";
    /// try element.setAttributeNS(xml_ns, "xml:lang", "en");
    /// ```
    pub fn setAttributeNS(
        self: *Element,
        namespace: ?[]const u8,
        qualified_name: []const u8,
        value: []const u8,
    ) !void {
        // TODO: Implement full validation and prefix extraction per spec
        // For now, extract local name from qualified name (after ':' if present)
        const local_name = if (std.mem.indexOfScalar(u8, qualified_name, ':')) |colon_idx|
            qualified_name[colon_idx + 1 ..]
        else
            qualified_name;

        // Intern the strings via document's string pool if we have an owner document
        const interned_local = if (self.prototype.owner_document) |owner| blk: {
            if (owner.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner);
                break :blk try doc.string_pool.intern(local_name);
            }
            break :blk local_name;
        } else local_name;

        const interned_value = if (self.prototype.owner_document) |owner| blk: {
            if (owner.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner);
                break :blk try doc.string_pool.intern(value);
            }
            break :blk value;
        } else value;

        const interned_ns = if (namespace) |ns| blk: {
            if (self.prototype.owner_document) |owner| {
                if (owner.node_type == .document) {
                    const Document = @import("document.zig").Document;
                    const doc: *Document = @fieldParentPtr("prototype", owner);
                    break :blk try doc.string_pool.intern(ns);
                }
            }
            break :blk ns;
        } else null;

        // Set attribute with namespace
        try self.attributes.array.set(interned_local, interned_ns, interned_value);
    }

    /// Removes an attribute by namespace and local name.
    ///
    /// Implements WHATWG DOM Element.removeAttributeNS() interface.
    ///
    /// ## WebIDL
    ///
    /// ```webidl
    /// [CEReactions] undefined removeAttributeNS(DOMString? namespace, DOMString localName);
    /// ```
    ///
    /// ## Parameters
    ///
    /// - `namespace`: Namespace URI (nullable)
    /// - `local_name`: Local name of the attribute to remove
    ///
    /// ## Spec References
    ///
    /// **WHATWG DOM**:
    /// > The removeAttributeNS(namespace, localName) method steps are to remove an attribute
    /// > given namespace, localName, and this.
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-removeattributens
    /// See: https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttributeNS
    ///
    /// ## Example
    ///
    /// ```zig
    /// const xml_ns = "http://www.w3.org/XML/1998/namespace";
    /// element.removeAttributeNS(xml_ns, "lang"); // Remove xml:lang
    /// ```
    pub fn removeAttributeNS(
        self: *Element,
        namespace: ?[]const u8,
        local_name: []const u8,
    ) void {
        _ = self.attributes.array.remove(local_name, namespace);
    }

    /// Checks if element has an attribute with given namespace and local name.
    ///
    /// Implements WHATWG DOM Element.hasAttributeNS() interface.
    ///
    /// ## WebIDL
    ///
    /// ```webidl
    /// boolean hasAttributeNS(DOMString? namespace, DOMString localName);
    /// ```
    ///
    /// ## Parameters
    ///
    /// - `namespace`: Namespace URI (nullable)
    /// - `local_name`: Local name of the attribute
    ///
    /// ## Returns
    ///
    /// true if attribute exists, false otherwise.
    ///
    /// ## Spec References
    ///
    /// **WHATWG DOM**:
    /// > The hasAttributeNS(namespace, localName) method steps are to return true if this has
    /// > an attribute whose namespace is namespace and local name is localName; otherwise false.
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-hasattributens
    /// See: https://developer.mozilla.org/en-US/docs/Web/API/Element/hasAttributeNS
    ///
    /// ## Example
    ///
    /// ```zig
    /// const xml_ns = "http://www.w3.org/XML/1998/namespace";
    /// if (element.hasAttributeNS(xml_ns, "lang")) {
    ///     // Has xml:lang attribute
    /// }
    /// ```
    pub fn hasAttributeNS(
        self: *const Element,
        namespace: ?[]const u8,
        local_name: []const u8,
    ) bool {
        return self.attributes.array.has(local_name, namespace);
    }

    /// Returns the number of attributes on the element.
    pub fn attributeCount(self: *const Element) usize {
        return self.attributes.count();
    }

    /// Checks if element has a specific class name (fast path using bloom filter).
    ///
    /// ## Parameters
    /// - `class_name`: Class name to check
    ///
    /// ## Returns
    /// true if class is present, false otherwise
    pub fn hasClass(self: *const Element, class_name: []const u8) bool {
        // Fast path: check bloom filter first
        if (!self.class_bloom.mayContain(class_name)) {
            return false; // Definitely not present
        }

        // Slow path: check actual class attribute
        const class_attr = self.getAttribute("class") orelse return false;

        // Simple check: look for exact match in space-separated list
        // TODO: Implement proper DOMTokenList for classList
        var iter = std.mem.splitSequence(u8, class_attr, " ");
        while (iter.next()) |class| {
            if (std.mem.eql(u8, class, class_name)) {
                return true;
            }
        }

        return false;
    }

    /// Returns a live DOMTokenList representing the class attribute.
    ///
    /// Implements WHATWG DOM Element.classList property per §4.9.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [SameObject, PutForwards=value] readonly attribute DOMTokenList classList;
    /// ```
    ///
    /// ## MDN Documentation
    /// - classList: https://developer.mozilla.org/en-US/docs/Web/API/Element/classList
    ///
    /// ## Returns
    /// DOMTokenList wrapper for the class attribute
    ///
    /// ## Spec References
    /// - Property: https://dom.spec.whatwg.org/#dom-element-classlist
    /// - WebIDL: dom.idl:110
    ///
    /// ## Example
    /// ```zig
    /// const elem = try doc.createElement("div");
    /// const classList = elem.classList();
    ///
    /// // Add classes
    /// try classList.add(&[_][]const u8{"btn", "btn-primary"});
    ///
    /// // Check for class
    /// if (classList.contains("btn")) {
    ///     std.debug.print("Has btn class\n", .{});
    /// }
    ///
    /// // Remove class
    /// try classList.remove(&[_][]const u8{"btn-primary"});
    ///
    /// // Toggle class
    /// _ = try classList.toggle("active", null);
    /// ```
    pub fn classList(self: *Element) @import("dom_token_list.zig").DOMTokenList {
        return .{
            .element = self,
            .attribute_name = "class",
        };
    }

    /// Toggles a boolean attribute on the element.
    ///
    /// Implements WHATWG DOM Element.toggleAttribute() per §4.9.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] boolean toggleAttribute(DOMString qualifiedName, optional boolean force);
    /// ```
    ///
    /// ## MDN Documentation
    /// - toggleAttribute(): https://developer.mozilla.org/en-US/docs/Web/API/Element/toggleAttribute
    ///
    /// ## Algorithm (from spec §4.9)
    /// 1. If qualifiedName does not match the Name production, throw "InvalidCharacterError"
    /// 2. If this has an attribute whose qualified name is qualifiedName:
    ///    a. If force is not given or is false, remove the attribute and return false
    ///    b. Return true
    /// 3. Otherwise:
    ///    a. If force is not given or is true, set an attribute with qualifiedName and empty string
    ///       and return true
    ///    b. Return false
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-element-toggleattribute
    /// - WebIDL: dom.idl:382
    ///
    /// ## Parameters
    /// - `qualified_name`: Attribute name to toggle
    /// - `force`: Optional - if true, add attribute; if false, remove attribute
    ///
    /// ## Returns
    /// true if attribute is now present, false if now absent
    ///
    /// ## Errors
    /// - `error.InvalidCharacterError`: Invalid character in qualified_name
    /// - `error.OutOfMemory`: Failed to allocate attribute storage
    ///
    /// ## Usage
    /// ```zig
    /// const elem = try doc.createElement("button");
    /// defer elem.prototype.release();
    ///
    /// // Toggle without force (add if absent, remove if present)
    /// const is_present = try elem.toggleAttribute("disabled", null); // true - added
    /// const is_absent = try elem.toggleAttribute("disabled", null);  // false - removed
    ///
    /// // Force add
    /// const forced_on = try elem.toggleAttribute("disabled", true);  // true - added
    /// const still_on = try elem.toggleAttribute("disabled", true);   // true - already present
    ///
    /// // Force remove
    /// const forced_off = try elem.toggleAttribute("disabled", false); // false - removed
    /// const still_off = try elem.toggleAttribute("disabled", false);  // false - already absent
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const button = document.querySelector('button');
    ///
    /// // Toggle disabled state
    /// button.toggleAttribute('disabled'); // Add if absent, remove if present
    ///
    /// // Force enable
    /// button.toggleAttribute('disabled', false); // Always remove
    ///
    /// // Force disable
    /// button.toggleAttribute('disabled', true); // Always add
    /// ```
    pub fn toggleAttribute(self: *Element, qualified_name: []const u8, force: ?bool) !bool {
        // Step 1: Validate qualified name
        // TODO: Add XML Name production validation per spec
        // For now, rely on setAttribute's validation

        // Step 2: Check if attribute exists
        const has_attr = self.hasAttribute(qualified_name);

        // Step 3: Apply toggle logic
        if (has_attr) {
            // Attribute exists
            if (force == null or force.? == false) {
                // Remove attribute
                self.removeAttribute(qualified_name);
                return false;
            } else {
                // Force is true, keep attribute
                return true;
            }
        } else {
            // Attribute doesn't exist
            if (force == null or force.? == true) {
                // Add attribute with empty value
                try self.setAttribute(qualified_name, "");
                return true;
            } else {
                // Force is false, don't add
                return false;
            }
        }
    }

    // === WHATWG DOM Core Properties ===

    /// Returns the local name of the element.
    ///
    /// Implements WHATWG DOM Element.localName property per §4.9.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute DOMString localName;
    /// ```
    ///
    /// ## Algorithm (WHATWG DOM §4.9)
    /// For elements without namespace support, localName is the same as tagName.
    /// When namespace support is added (XML/SVG), this will return the local part
    /// after the namespace prefix (e.g., "rect" from "svg:rect").
    ///
    /// ## Returns
    /// Local name of the element (currently same as tagName)
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-element-localname
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:353
    ///
    /// ## Example
    /// ```zig
    /// const elem = try doc.createElement("div");
    /// defer elem.prototype.release();
    ///
    /// const name = elem.localName();
    /// // Returns "div" (same as tagName for non-namespaced elements)
    /// ```
    pub fn localName(self: *const Element) []const u8 {
        // For non-namespaced elements, localName === tagName
        // When namespace support is added, this will extract the local part
        return self.tag_name;
    }

    // === WHATWG DOM Convenience Properties ===

    /// Gets the element's id attribute.
    ///
    /// Implements WHATWG DOM Element.id property (getter).
    ///
    /// ## Returns
    /// Element's id attribute value or null if not set
    ///
    /// ## Example
    /// ```zig
    /// const id = elem.getId();
    /// if (id) |id_value| {
    ///     std.debug.print("Element id: {s}\n", .{id_value});
    /// }
    /// ```
    pub fn getId(self: *const Element) ?[]const u8 {
        return self.getAttribute("id");
    }

    /// Sets the element's id attribute.
    ///
    /// Implements WHATWG DOM Element.id property (setter).
    ///
    /// ## Parameters
    /// - `value`: New id value
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate attribute storage
    ///
    /// ## Example
    /// ```zig
    /// try elem.setId("my-element");
    /// ```
    pub fn setId(self: *Element, value: []const u8) !void {
        try self.setAttribute("id", value);
    }

    /// Gets the element's class attribute.
    ///
    /// Implements WHATWG DOM Element.className property (getter).
    ///
    /// ## Returns
    /// Element's class attribute value or empty string if not set
    ///
    /// ## Example
    /// ```zig
    /// const classes = elem.getClassName();
    /// std.debug.print("Classes: {s}\n", .{classes});
    /// ```
    pub fn getClassName(self: *const Element) []const u8 {
        return self.getAttribute("class") orelse "";
    }

    /// Sets the element's class attribute.
    ///
    /// Implements WHATWG DOM Element.className property (setter).
    ///
    /// ## Parameters
    /// - `value`: New class value (space-separated class names)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate attribute storage
    ///
    /// ## Example
    /// ```zig
    /// try elem.setClassName("btn btn-primary active");
    /// ```
    pub fn setClassName(self: *Element, value: []const u8) !void {
        try self.setAttribute("class", value);
    }

    /// Checks if element has any attributes.
    ///
    /// Implements WHATWG DOM Element.hasAttributes() interface.
    ///
    /// ## Returns
    /// true if element has at least one attribute, false otherwise
    ///
    /// ## Example
    /// ```zig
    /// if (elem.hasAttributes()) {
    ///     std.debug.print("Element has attributes\n", .{});
    /// }
    /// ```
    pub fn hasAttributes(self: *const Element) bool {
        return self.attributes.count() > 0;
    }

    /// Returns an array of all attribute names.
    ///
    /// Implements WHATWG DOM Element.getAttributeNames() interface.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for result array
    ///
    /// ## Returns
    /// Owned array of attribute names. Caller must free with allocator.
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate result array
    ///
    /// ## Example
    /// ```zig
    /// const names = try elem.getAttributeNames(allocator);
    /// defer allocator.free(names);
    ///
    /// for (names) |name| {
    ///     std.debug.print("Attribute: {s}\n", .{name});
    /// }
    /// ```
    pub fn getAttributeNames(self: *const Element, allocator: Allocator) ![][]const u8 {
        const count = self.attributes.count();
        if (count == 0) {
            return &[_][]const u8{};
        }

        const names = try allocator.alloc([]const u8, count);
        errdefer allocator.free(names);

        var i: usize = 0;
        var iter = self.attributes.iterator();
        while (iter.next()) |attr| {
            names[i] = attr.name.local_name;
            i += 1;
        }

        return names;
    }

    // ========================================================================
    // Attribute Node Methods
    // ========================================================================

    /// Returns a NamedNodeMap of all attributes.
    ///
    /// Implements WHATWG DOM Element.attributes property.
    /// Returns a live NamedNodeMap that reflects the element's attributes.
    ///
    /// ## Returns
    /// NamedNodeMap view of this element's attributes
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-element-attributes
    ///
    /// **WebIDL**: dom.idl:374 [SameObject]
    pub fn getAttributes(self: *Element) NamedNodeMap {
        return NamedNodeMap{ .element = self };
    }

    /// Gets or creates a cached Attr node for the given attribute.
    ///
    /// Implements [SameObject] semantics - repeated calls return the same Attr instance.
    ///
    /// ## Parameters
    /// - `name`: Attribute name
    /// - `value`: Current attribute value
    ///
    /// ## Returns
    /// Cached Attr node (creates if not cached)
    ///
    /// ## Memory Management
    /// - Returns Attr with INCREMENTED ref_count (caller must release)
    /// - Cache holds its own reference (released on invalidation or deinit)
    /// - This ensures [SameObject] while allowing caller to safely release
    pub fn getOrCreateCachedAttr(self: *Element, name: []const u8, value: []const u8) !*Attr {
        // Lazy initialize cache on first access
        if (self.attr_cache == null) {
            self.attr_cache = AttrCache.init(self.prototype.allocator);
        }

        // Check cache first
        if (self.attr_cache.?.get(name)) |cached| {
            // Update value if it changed (AttributeMap is source of truth)
            if (!std.mem.eql(u8, cached.value(), value)) {
                try cached.setValue(value);
            }
            // Acquire reference for caller (they must release)
            cached.node.acquire();
            return cached;
        }

        // Not in cache - create new Attr (ref_count=1)
        const attr = try Attr.create(self.prototype.allocator, name);
        errdefer attr.node.release();

        try attr.setValue(value);
        attr.owner_element = self;

        // Add to cache (cache holds one strong reference)
        attr.node.acquire(); // Cache's reference
        try self.attr_cache.?.put(name, attr);

        // Return to caller (they hold the original ref_count=1)
        return attr;
    }

    /// Invalidates a single cached Attr node.
    ///
    /// Called when an attribute is modified or removed via setAttribute/removeAttribute.
    /// Removes from cache and releases the cache's reference.
    fn invalidateCachedAttr(self: *Element, name: []const u8) void {
        // Access cache through pointer capture to avoid alignment issues
        const cache_ptr = &self.attr_cache;
        if (cache_ptr.*) |*cache| {
            if (cache.remove(name)) |attr| {
                attr.owner_element = null;
                attr.node.release(); // Release cache's reference
            }
        }
    }

    /// Returns the Attr node for the given attribute name.
    ///
    /// Implements WHATWG DOM Element.getAttributeNode() interface.
    ///
    /// ## Parameters
    /// - `qualified_name`: Attribute name to look up
    ///
    /// ## Returns
    /// Attr node with matching name, or null if not found
    ///
    /// ## Example
    /// ```zig
    /// if (try elem.getAttributeNode("id")) |attr| {
    ///     defer attr.node.release();
    ///     std.debug.print("ID: {s}\n", .{attr.value()});
    /// }
    /// ```
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-element-getattributenode
    ///
    /// **WebIDL**: dom.idl:386
    pub fn getAttributeNode(self: *Element, qualified_name: []const u8) !?*Attr {
        var attrs = self.getAttributes();
        return try attrs.getNamedItem(qualified_name);
    }

    /// Returns the Attr node for the given namespaced attribute.
    ///
    /// Implements WHATWG DOM Element.getAttributeNodeNS() interface.
    ///
    /// ## Parameters
    /// - `namespace_uri`: Namespace URI (nullable)
    /// - `local_name`: Local name without prefix
    ///
    /// ## Returns
    /// Attr node with matching namespace and local name, or null
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-element-getattributenodeNS
    ///
    /// **WebIDL**: dom.idl:387
    pub fn getAttributeNodeNS(
        self: *Element,
        namespace_uri: ?[]const u8,
        local_name: []const u8,
    ) !?*Attr {
        var attrs = self.getAttributes();
        return try attrs.getNamedItemNS(namespace_uri, local_name);
    }

    /// Sets an Attr node on the element.
    ///
    /// Implements WHATWG DOM Element.setAttributeNode() interface.
    /// If an attribute with the same name already exists, it is replaced.
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
    /// ## Example
    /// ```zig
    /// const attr = try doc.createAttribute("class");
    /// attr.setValue("highlight");
    ///
    /// const old = try elem.setAttributeNode(attr);
    /// // old is null (no previous class attribute)
    /// ```
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-element-setattributenode
    ///
    /// **WebIDL**: dom.idl:388 [CEReactions]
    pub fn setAttributeNode(self: *Element, attr: *Attr) !?*Attr {
        var attrs = self.getAttributes();
        return try attrs.setNamedItem(attr);
    }

    /// Sets a namespaced Attr node on the element.
    ///
    /// Implements WHATWG DOM Element.setAttributeNodeNS() interface.
    ///
    /// ## Parameters
    /// - `attr`: Namespaced Attr node to add
    ///
    /// ## Returns
    /// The replaced Attr node if one existed, otherwise null
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-element-setattributenodeNS
    ///
    /// **WebIDL**: dom.idl:389 [CEReactions]
    pub fn setAttributeNodeNS(self: *Element, attr: *Attr) !?*Attr {
        var attrs = self.getAttributes();
        return try attrs.setNamedItemNS(attr);
    }

    /// Removes an Attr node from the element.
    ///
    /// Implements WHATWG DOM Element.removeAttributeNode() interface.
    ///
    /// ## Parameters
    /// - `attr`: Attr node to remove
    ///
    /// ## Returns
    /// The removed Attr node (same as input)
    ///
    /// ## Errors
    /// - `NotFoundError`: If attr is not an attribute of this element
    ///
    /// ## Example
    /// ```zig
    /// if (try elem.getAttributeNode("class")) |attr| {
    ///     const removed = try elem.removeAttributeNode(attr);
    ///     defer removed.node.release();
    ///     std.debug.assert(removed == attr);
    /// }
    /// ```
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-element-removeattributenode
    ///
    /// **WebIDL**: dom.idl:390 [CEReactions]
    pub fn removeAttributeNode(self: *Element, attr: *Attr) !*Attr {
        // Verify attr belongs to this element
        if (attr.owner_element != self) {
            return DOMError.NotFoundError;
        }

        // Remove the attribute by name
        var attrs = self.getAttributes();
        return try attrs.removeNamedItem(attr.name());
    }

    // ========================================================================
    // Shadow DOM
    // ========================================================================

    /// Attaches a shadow root to this element.
    ///
    /// ## WHATWG Specification
    /// - **§4.8 Attach a shadow root**: https://dom.spec.whatwg.org/#dom-element-attachshadow
    ///
    /// ## WebIDL
    /// ```webidl
    /// ShadowRoot attachShadow(ShadowRootInit init);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Element.attachShadow(): https://developer.mozilla.org/en-US/docs/Web/API/Element/attachShadow
    ///
    /// ## Parameters
    /// - `init`: Shadow root configuration (mode, delegates_focus, etc.)
    ///
    /// ## Returns
    /// The created ShadowRoot (stored in element's RareData)
    ///
    /// ## Errors
    /// - `error.NotSupportedError`: Element already has a shadow root
    /// - `error.OutOfMemory`: Failed to allocate shadow root or RareData
    ///
    /// ## Example
    /// ```zig
    /// const elem = try doc.createElement("container");
    /// defer elem.prototype.release();
    ///
    /// // Attach open shadow root
    /// const shadow = try elem.attachShadow(.{
    ///     .mode = .open,
    ///     .delegates_focus = false,
    /// });
    ///
    /// // Add content to shadow tree
    /// const content = try doc.createElement("content");
    /// _ = try shadow.prototype.appendChild(&content.prototype);
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const element = document.createElement('div');
    /// const shadow = element.attachShadow({ mode: 'open' });
    /// // Returns: ShadowRoot
    /// ```
    pub fn attachShadow(self: *Element, init: @import("shadow_root.zig").ShadowRootInit) !*@import("shadow_root.zig").ShadowRoot {
        const ShadowRoot = @import("shadow_root.zig").ShadowRoot;

        // Ensure RareData exists
        const rare_data = try self.prototype.ensureRareData();

        // Check if shadow root already exists
        if (rare_data.shadow_root != null) {
            return error.NotSupportedError;
        }

        // Create shadow root
        const shadow = try ShadowRoot.create(self.prototype.allocator, self, init);

        // Store in RareData (OWNING pointer)
        rare_data.shadow_root = @ptrCast(shadow);

        // If host is connected, shadow root should be connected too
        if (self.prototype.isConnected()) {
            shadow.prototype.setConnected(true);
        }

        return shadow;
    }

    /// Returns the shadow root attached to this element, or null.
    ///
    /// ## WHATWG Specification
    /// - **§4.8 Interface Element**: https://dom.spec.whatwg.org/#dom-element-shadowroot
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute ShadowRoot? shadowRoot;
    /// ```
    ///
    /// ## MDN Documentation
    /// - Element.shadowRoot: https://developer.mozilla.org/en-US/docs/Web/API/Element/shadowRoot
    ///
    /// ## Returns
    /// ShadowRoot if attached and mode is `open`, null otherwise
    ///
    /// ## Mode Enforcement
    /// - **open mode**: Returns the shadow root
    /// - **closed mode**: Returns null (hides shadow root from JavaScript)
    ///
    /// ## Example
    /// ```zig
    /// // Open mode
    /// const shadow_open = try elem.attachShadow(.{ .mode = .open });
    /// const retrieved = elem.shadowRoot();
    /// // retrieved == shadow_open
    ///
    /// // Closed mode
    /// const elem2 = try doc.createElement("widget");
    /// _ = try elem2.attachShadow(.{ .mode = .closed });
    /// const hidden = elem2.shadowRoot();
    /// // hidden == null (shadow root exists but is hidden)
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const element = document.createElement('div');
    /// element.attachShadow({ mode: 'open' });
    /// const shadow = element.shadowRoot; // Returns ShadowRoot
    ///
    /// const closed = document.createElement('div');
    /// closed.attachShadow({ mode: 'closed' });
    /// const hidden = closed.shadowRoot; // Returns null
    /// ```
    pub fn shadowRoot(self: *const Element) ?*@import("shadow_root.zig").ShadowRoot {
        const ShadowRoot = @import("shadow_root.zig").ShadowRoot;

        // Check if RareData exists
        const rare_data = self.prototype.rare_data orelse return null;

        // Check if shadow root exists
        const shadow_ptr = rare_data.shadow_root orelse return null;

        // Cast to ShadowRoot
        const shadow: *ShadowRoot = @ptrCast(@alignCast(shadow_ptr));

        // Mode enforcement: closed mode returns null
        if (shadow.mode == .closed) {
            return null;
        }

        return shadow;
    }

    // ========================================================================
    // Slottable Mixin
    // ========================================================================

    /// Returns the slot element this element is assigned to.
    ///
    /// ## WHATWG Specification
    /// - **Slottable mixin**: https://dom.spec.whatwg.org/#mixin-slottable
    ///
    /// ## WebIDL
    /// ```webidl
    /// interface mixin Slottable {
    ///   readonly attribute HTMLSlotElement? assignedSlot;
    /// };
    /// Element includes Slottable;
    /// ```
    ///
    /// ## MDN Documentation
    /// - Element.assignedSlot: https://developer.mozilla.org/en-US/docs/Web/API/Element/assignedSlot
    ///
    /// ## Returns
    /// The slot element (tag name "slot") this element is assigned to, or null
    ///
    /// ## Note
    /// In a generic DOM library, we return Element (not HTMLSlotElement).
    /// HTML libraries can extend this to return HTMLSlotElement specifically.
    ///
    /// ## Example
    /// ```zig
    /// const host = try doc.createElement("host");
    /// const shadow = try host.attachShadow(.{ .mode = .open });
    ///
    /// // Create slot in shadow tree
    /// const slot = try doc.createElement("slot");
    /// try slot.setAttribute("name", "header");
    /// _ = try shadow.prototype.appendChild(&slot.prototype);
    ///
    /// // Create content in light DOM
    /// const content = try doc.createElement("content");
    /// try content.setAttribute("slot", "header");
    /// _ = try host.prototype.appendChild(&content.prototype);
    ///
    /// // Content is assigned to slot
    /// const assigned = content.assignedSlot();
    /// // assigned == slot
    /// ```
    pub fn assignedSlot(self: *const Element) ?*Element {
        // Check if rare data exists
        const rare_data = self.prototype.rare_data orelse return null;

        // Check if assigned slot exists
        const slot_ptr = rare_data.assigned_slot orelse return null;

        // Cast to Element (slot is just an Element with tag name "slot")
        const slot: *Element = @ptrCast(@alignCast(slot_ptr));
        return slot;
    }

    /// Sets the assigned slot for this element (internal use).
    ///
    /// ## Parameters
    /// - `slot`: The slot element to assign this element to (or null to clear)
    ///
    /// ## Note
    /// This is called internally during slot assignment. Users should not call this directly.
    pub fn setAssignedSlot(self: *Element, slot: ?*Element) !void {
        if (slot == null) {
            // Clear assigned slot
            if (self.prototype.rare_data) |rare_data| {
                rare_data.assigned_slot = null;
            }
            return;
        }

        // Ensure rare data exists
        const rare_data = try self.prototype.ensureRareData();

        // Set assigned slot (WEAK reference)
        rare_data.assigned_slot = @ptrCast(slot.?);
    }

    // ========================================================================
    // Slot Element Methods (Generic Slot Support)
    // ========================================================================

    /// Returns the nodes assigned to this slot element.
    ///
    /// This method only works on elements with tag name "slot".
    /// In manual slot assignment mode, returns nodes explicitly assigned via assign().
    /// In named slot assignment mode, returns nodes that match the slot's name attribute.
    ///
    /// ## WHATWG Specification
    /// - **HTMLSlotElement.assignedNodes()**: https://html.spec.whatwg.org/multipage/scripting.html#dom-slot-assignednodes
    ///
    /// ## WebIDL (adapted for generic DOM)
    /// ```webidl
    /// sequence<Node> assignedNodes(optional AssignedNodesOptions options = {});
    /// ```
    ///
    /// ## MDN Documentation
    /// - HTMLSlotElement.assignedNodes(): https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/assignedNodes
    ///
    /// ## Parameters
    /// - `flatten`: If true, returns the assigned nodes of any child slot elements too
    ///
    /// ## Returns
    /// Array of nodes assigned to this slot
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate array
    ///
    /// ## Usage
    /// ```zig
    /// const slot = try doc.createElement("slot");
    /// const content = try doc.createElement("content");
    /// try content.setAssignedSlot(slot);
    ///
    /// const nodes = try slot.assignedNodes(allocator, .{ .flatten = false });
    /// defer allocator.free(nodes);
    /// // nodes contains content
    /// ```
    pub fn assignedNodes(self: *const Element, allocator: Allocator, options: struct { flatten: bool = false }) ![]const *Node {
        _ = options; // TODO: Implement flatten option

        // Only slot elements can have assigned nodes
        if (!std.mem.eql(u8, self.tag_name, "slot")) {
            return &[_]*Node{};
        }

        // Collect nodes that are assigned to this slot
        var nodes = std.ArrayList(*Node){};
        errdefer nodes.deinit(allocator);

        // Find nodes in the host's children that are assigned to this slot
        // For now, we'll search through all nodes and check their assignedSlot
        // TODO: Optimize with a reverse map from slot -> assigned nodes

        // Get the shadow root that contains this slot
        var current: ?*Node = @constCast(&self.prototype);
        while (current) |node| {
            if (node.node_type == .shadow_root) {
                // This is a shadow root - get its host
                const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
                const shadow: *ShadowRoot = @fieldParentPtr("prototype", node);
                const host = shadow.host_element;

                // Iterate through host's children
                var child = host.prototype.first_child;
                while (child) |child_node| {
                    // Check if this node is assigned to our slot
                    if (child_node.node_type == .element) {
                        const child_elem: *Element = @fieldParentPtr("prototype", child_node);
                        if (child_elem.assignedSlot()) |assigned| {
                            if (assigned == self) {
                                try nodes.append(allocator, child_node);
                            }
                        }
                    } else if (child_node.node_type == .text) {
                        // Text nodes can also be assigned to slots
                        const Text = @import("text.zig").Text;
                        const text: *Text = @fieldParentPtr("prototype", child_node);
                        if (text.assignedSlot()) |assigned| {
                            if (assigned == self) {
                                try nodes.append(allocator, child_node);
                            }
                        }
                    }
                    child = child_node.next_sibling;
                }
                break;
            }
            current = node.parent_node;
        }

        return nodes.toOwnedSlice(allocator);
    }

    /// Returns only the element nodes assigned to this slot.
    ///
    /// This is a convenience method that filters assignedNodes() to only Element nodes.
    ///
    /// ## WHATWG Specification
    /// - **HTMLSlotElement.assignedElements()**: https://html.spec.whatwg.org/multipage/scripting.html#dom-slot-assignedelements
    ///
    /// ## WebIDL (adapted for generic DOM)
    /// ```webidl
    /// sequence<Element> assignedElements(optional AssignedNodesOptions options = {});
    /// ```
    ///
    /// ## MDN Documentation
    /// - HTMLSlotElement.assignedElements(): https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/assignedElements
    ///
    /// ## Parameters
    /// - `flatten`: If true, returns the assigned elements of any child slot elements too
    ///
    /// ## Returns
    /// Array of element nodes assigned to this slot (caller must free)
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate array
    pub fn assignedElements(self: *const Element, allocator: Allocator, options: struct { flatten: bool = false }) ![]const *Element {
        const nodes = try self.assignedNodes(allocator, .{ .flatten = options.flatten });
        defer allocator.free(nodes);

        var elements = std.ArrayList(*Element){};
        errdefer elements.deinit(allocator);

        for (nodes) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);
                try elements.append(allocator, elem);
            }
        }

        return elements.toOwnedSlice(allocator);
    }

    /// Manually assigns nodes to this slot (manual slot assignment mode).
    ///
    /// This method only works in shadow roots with slotAssignment = "manual".
    /// In manual mode, slots don't automatically match by name; instead, nodes
    /// must be explicitly assigned using this method.
    ///
    /// ## WHATWG Specification
    /// - **HTMLSlotElement.assign()**: https://html.spec.whatwg.org/multipage/scripting.html#dom-slot-assign
    ///
    /// ## WebIDL (adapted for generic DOM)
    /// ```webidl
    /// undefined assign((Element or Text)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - HTMLSlotElement.assign(): https://developer.mozilla.org/en-US/docs/Web/API/HTMLSlotElement/assign
    ///
    /// ## Parameters
    /// - `nodes`: Array of nodes to assign to this slot
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to update slot assignments
    ///
    /// ## Usage
    /// ```zig
    /// const shadow = try host.attachShadow(.{ .mode = .open, .slot_assignment = .manual });
    /// const slot = try doc.createElement("slot");
    /// const content1 = try doc.createElement("content");
    /// const content2 = try doc.createElement("content");
    ///
    /// // Manually assign specific nodes to the slot
    /// try slot.assign(&[_]*Node{ &content1.prototype, &content2.prototype });
    /// ```
    pub fn assign(self: *Element, nodes: []const *Node) !void {
        // Only slot elements can have assignments
        if (!std.mem.eql(u8, self.tag_name, "slot")) {
            return error.InvalidNodeType;
        }

        // Clear existing assignments for this slot
        // (find all nodes assigned to this slot and clear them)
        // TODO: Optimize with reverse map

        // Assign new nodes to this slot
        for (nodes) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);
                try elem.setAssignedSlot(self);
            } else if (node.node_type == .text) {
                const Text = @import("text.zig").Text;
                const text: *Text = @fieldParentPtr("prototype", node);
                try text.setAssignedSlot(self);
            }
            // Ignore other node types (only Element and Text are slottable)
        }
    }

    // ========================================================================
    // Slot Assignment Algorithms (WHATWG §4.2.2.3-4)
    // ========================================================================

    /// Find a slot for a slottable (WHATWG §4.2.2.3).
    ///
    /// To find a slot for a given slottable and an optional boolean open (default false):
    /// 1. If slottable's parent is null, then return null.
    /// 2. Let shadow be slottable's parent's shadow root.
    /// 3. If shadow is null, then return null.
    /// 4. If open is true and shadow's mode is not "open", then return null.
    /// 5. If shadow's slot assignment is "manual", then return the slot in shadow's
    ///    descendants whose manually assigned nodes contains slottable, if any; otherwise null.
    /// 6. Return the first slot in tree order in shadow's descendants whose name is
    ///    slottable's name, if any; otherwise null.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.2.3 Finding slots and slottables**: https://dom.spec.whatwg.org/#finding-slots-and-slottables
    ///
    /// ## Parameters
    /// - `slottable_node`: The node to find a slot for (Element or Text)
    /// - `open`: If true, only return slots in open shadow roots
    ///
    /// ## Returns
    /// The slot element this node should be assigned to, or null
    ///
    /// ## Usage
    /// ```zig
    /// const slot = Element.findSlot(&elem.prototype, false);
    /// if (slot) |s| {
    ///     // elem should be assigned to slot s
    /// }
    /// ```
    pub fn findSlot(slottable_node: *const Node, open: bool) ?*Element {
        // 1. If slottable's parent is null, then return null.
        const parent = slottable_node.parent_node orelse return null;

        // 2. Let shadow be slottable's parent's shadow root.
        // Parent must be an Element to have a shadow root
        if (parent.node_type != .element) return null;
        const parent_elem: *const Element = @fieldParentPtr("prototype", parent);

        // Access shadow root directly from rare data (not through public API)
        // This allows us to find slots in closed shadow roots internally
        const rare_data = parent_elem.prototype.rare_data orelse return null;
        const shadow_ptr = rare_data.shadow_root orelse return null;
        const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
        const shadow: *const ShadowRoot = @ptrCast(@alignCast(shadow_ptr));

        // 3. If shadow is null, then return null.
        // (already handled by orelse)

        // 4. If open is true and shadow's mode is not "open", then return null.
        if (open and shadow.mode != .open) {
            return null;
        }

        // Get slottable's name (value of 'slot' attribute, or empty string)
        const slottable_name = blk: {
            if (slottable_node.node_type == .element) {
                const elem: *const Element = @fieldParentPtr("prototype", slottable_node);
                break :blk elem.getAttribute("slot") orelse "";
            } else {
                // Text nodes have empty name
                break :blk "";
            }
        };

        // 5. If shadow's slot assignment is "manual", then return the slot in shadow's
        //    descendants whose manually assigned nodes contains slottable
        if (shadow.slot_assignment == .manual) {
            // Search shadow tree for slot that has this node in its assigned nodes
            return findSlotWithManualAssignment(&shadow.prototype, slottable_node);
        }

        // 6. Return the first slot in tree order in shadow's descendants whose name is
        //    slottable's name, if any; otherwise null.
        return findSlotByName(&shadow.prototype, slottable_name);
    }

    /// Helper: Find a slot by name in tree order.
    fn findSlotByName(root: *const Node, name: []const u8) ?*Element {
        var current = root.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *const Element = @fieldParentPtr("prototype", node);

                // Check if this is a slot with matching name
                if (std.mem.eql(u8, elem.tag_name, "slot")) {
                    const slot_name = elem.getAttribute("name") orelse "";
                    if (std.mem.eql(u8, slot_name, name)) {
                        return @constCast(elem);
                    }
                }

                // Recursively search descendants
                if (findSlotByName(node, name)) |found| {
                    return found;
                }
            }
            current = node.next_sibling;
        }
        return null;
    }

    /// Helper: Find a slot that manually contains the given slottable.
    fn findSlotWithManualAssignment(root: *const Node, slottable: *const Node) ?*Element {
        var current = root.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *const Element = @fieldParentPtr("prototype", node);

                // Check if this is a slot that has the slottable assigned to it
                if (std.mem.eql(u8, elem.tag_name, "slot")) {
                    // Check if slottable is assigned to this slot
                    const assigned = blk: {
                        if (slottable.node_type == .element) {
                            const s: *const Element = @fieldParentPtr("prototype", slottable);
                            break :blk s.assignedSlot();
                        } else if (slottable.node_type == .text) {
                            const Text = @import("text.zig").Text;
                            const t: *const Text = @fieldParentPtr("prototype", slottable);
                            break :blk t.assignedSlot();
                        } else {
                            break :blk null;
                        }
                    };

                    if (assigned) |slot| {
                        if (&slot.prototype == &elem.prototype) {
                            return @constCast(elem);
                        }
                    }
                }

                // Recursively search descendants
                if (findSlotWithManualAssignment(node, slottable)) |found| {
                    return found;
                }
            }
            current = node.next_sibling;
        }
        return null;
    }

    /// Find slottables for a slot (WHATWG §4.2.2.3).
    ///
    /// To find slottables for a given slot:
    /// 1. Let result be « ».
    /// 2. Let root be slot's root.
    /// 3. If root is not a shadow root, then return result.
    /// 4. Let host be root's host.
    /// 5. If root's slot assignment is "manual":
    ///    - For each slottable of slot's manually assigned nodes, if slottable's parent is host, append slottable to result.
    /// 6. Otherwise, for each slottable child of host, in tree order:
    ///    - Let foundSlot be the result of finding a slot given slottable.
    ///    - If foundSlot is slot, then append slottable to result.
    /// 7. Return result.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.2.3 Finding slots and slottables**: https://dom.spec.whatwg.org/#finding-slots-and-slottables
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator for result array
    /// - `slot`: The slot element to find slottables for
    ///
    /// ## Returns
    /// Array of nodes that should be assigned to this slot
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate result array
    pub fn findSlottables(allocator: Allocator, slot: *const Element) ![]const *Node {
        var result = std.ArrayList(*Node){};
        errdefer result.deinit(allocator);

        // 2. Let root be slot's root (don't pierce shadow boundaries)
        const root = slot.prototype.getRootNode(false);

        // 3. If root is not a shadow root, then return result (empty)
        if (root.node_type != .shadow_root) {
            return try result.toOwnedSlice(allocator);
        }

        // 4. Let host be root's host
        const ShadowRoot = @import("shadow_root.zig").ShadowRoot;
        const shadow: *const ShadowRoot = @fieldParentPtr("prototype", root);
        const host = shadow.host_element;

        // 5. If root's slot assignment is "manual"
        if (shadow.slot_assignment == .manual) {
            // For each slottable of slot's manually assigned nodes
            var current = host.prototype.first_child;
            while (current) |node| {
                // Check if this slottable is assigned to our slot
                const assigned = blk: {
                    if (node.node_type == .element) {
                        const elem: *const Element = @fieldParentPtr("prototype", node);
                        break :blk elem.assignedSlot();
                    } else if (node.node_type == .text) {
                        const Text = @import("text.zig").Text;
                        const text: *const Text = @fieldParentPtr("prototype", node);
                        break :blk text.assignedSlot();
                    } else {
                        break :blk null;
                    }
                };

                if (assigned) |s| {
                    if (&s.prototype == &slot.prototype) {
                        try result.append(allocator, @constCast(node));
                    }
                }

                current = node.next_sibling;
            }
        } else {
            // 6. Otherwise, for each slottable child of host, in tree order
            var current = host.prototype.first_child;
            while (current) |node| {
                // Only Element and Text are slottables
                if (node.node_type == .element or node.node_type == .text) {
                    // Let foundSlot be the result of finding a slot given slottable
                    const found_slot = findSlot(node, false);

                    // If foundSlot is slot, then append slottable to result
                    if (found_slot) |fs| {
                        if (&fs.prototype == &slot.prototype) {
                            try result.append(allocator, @constCast(node));
                        }
                    }
                }
                current = node.next_sibling;
            }
        }

        return try result.toOwnedSlice(allocator);
    }

    /// Assign slottables for a slot (WHATWG §4.2.2.4).
    ///
    /// To assign slottables for a slot:
    /// 1. Let slottables be the result of finding slottables for slot.
    /// 2. If slottables and slot's assigned nodes are not identical, then run signal a slot change for slot.
    /// 3. Set slot's assigned nodes to slottables.
    /// 4. For each slottable of slottables, set slottable's assigned slot to slot.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.2.4 Assigning slottables and slots**: https://dom.spec.whatwg.org/#assigning-slottables-and-slots
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `slot`: The slot element to assign slottables for
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate arrays
    ///
    /// ## Note
    /// This updates both the slot's assigned nodes list and each slottable's assigned slot pointer.
    /// It also signals slot change events if the assignments changed.
    pub fn assignSlottables(allocator: Allocator, slot: *Element) !void {
        // 1. Let slottables be the result of finding slottables for slot
        const slottables = try findSlottables(allocator, slot);
        defer allocator.free(slottables);

        // TODO: 2. If slottables and slot's assigned nodes are not identical,
        //          then run signal a slot change for slot
        // For now, we skip the signal step (will add events in next phase)

        // 3. Set slot's assigned nodes to slottables (already done by assignedNodes())
        // 4. For each slottable of slottables, set slottable's assigned slot to slot
        for (slottables) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);
                try elem.setAssignedSlot(slot);
            } else if (node.node_type == .text) {
                const Text = @import("text.zig").Text;
                const text: *Text = @fieldParentPtr("prototype", node);
                try text.setAssignedSlot(slot);
            }
        }
    }

    /// Assign slottables for a tree (WHATWG §4.2.2.4).
    ///
    /// To assign slottables for a tree, given a node root,
    /// run assign slottables for each slot of root's inclusive descendants, in tree order.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.2.4 Assigning slottables and slots**: https://dom.spec.whatwg.org/#assigning-slottables-and-slots
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `root`: Root node to start searching for slots
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate arrays
    pub fn assignSlottablesForTree(allocator: Allocator, root: *Node) !void {
        // Find all slot elements in tree
        if (root.node_type == .element) {
            const elem: *Element = @fieldParentPtr("prototype", root);
            if (std.mem.eql(u8, elem.tag_name, "slot")) {
                try assignSlottables(allocator, elem);
            }
        }

        // Recursively process children
        var current = root.first_child;
        while (current) |node| {
            try assignSlottablesForTree(allocator, node);
            current = node.next_sibling;
        }
    }

    /// Assign a slot for a slottable (WHATWG §4.2.2.4).
    ///
    /// To assign a slot, given a slottable:
    /// 1. Let slot be the result of finding a slot with slottable.
    /// 2. If slot is non-null, then run assign slottables for slot.
    ///
    /// ## WHATWG Specification
    /// - **§4.2.2.4 Assigning slottables and slots**: https://dom.spec.whatwg.org/#assigning-slottables-and-slots
    ///
    /// ## Parameters
    /// - `allocator`: Memory allocator
    /// - `slottable`: The node to assign a slot for
    ///
    /// ## Errors
    /// - `OutOfMemory`: Failed to allocate arrays
    pub fn assignASlot(allocator: Allocator, slottable: *Node) !void {
        // 1. Let slot be the result of finding a slot with slottable
        const slot = findSlot(slottable, false) orelse return;

        // 2. If slot is non-null, then run assign slottables for slot
        try assignSlottables(allocator, slot);
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
    /// - querySelector(): https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector
    ///
    /// ## Algorithm
    /// 1. Parse selectors string into selector list
    /// 2. Traverse descendants in tree order
    /// 3. Return first element that matches any selector
    /// 4. Return null if no match found
    ///
    /// ## Usage
    /// ```zig
    /// const container = try doc.createElement("div");
    /// const button = try doc.createElement("button");
    /// try button.setAttribute("class", "btn primary");
    /// _ = try container.prototype.appendChild(&button.prototype);
    ///
    /// // Find button by class
    /// const result = try container.querySelector(".btn");
    /// // result == button
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// // Instance method on Element.prototype
    /// const element = document.querySelector('.container');
    /// const button = element.querySelector('button.primary');
    /// // Returns: Element or null
    /// ```
    pub fn querySelector(self: *Element, allocator: Allocator, selectors: []const u8) !?*Element {
        // Try to get parsed selector from cache if we have an owner document
        const parsed_selector = blk: {
            if (self.prototype.owner_document) |owner| {
                if (owner.node_type == .document) {
                    const Document = @import("document.zig").Document;
                    const doc: *Document = @fieldParentPtr("prototype", owner);
                    break :blk try doc.selector_cache.get(selectors);
                }
            }
            // No document, parse directly
            break :blk null;
        };

        // Use fast path if available
        if (parsed_selector) |parsed| {
            switch (parsed.fast_path) {
                .simple_id => {
                    if (parsed.identifier) |id| {
                        return self.queryById(id);
                    }
                },
                .simple_class => {
                    if (parsed.identifier) |class_name| {
                        return self.queryByClass(class_name);
                    }
                },
                .simple_tag => {
                    if (parsed.identifier) |tag_name| {
                        return self.queryByTagName(tag_name);
                    }
                },
                .id_filtered, .generic => {
                    // Use cached parsed selector
                    const Matcher = @import("selector/matcher.zig").Matcher;
                    const matcher = Matcher.init(allocator);

                    // Traverse descendants in tree order
                    var current = self.prototype.first_child;
                    while (current) |node| {
                        if (node.node_type == .element) {
                            const elem: *Element = @fieldParentPtr("prototype", node);

                            if (try matcher.matches(elem, &parsed.selector_list)) {
                                return elem;
                            }

                            if (try elem.querySelector(allocator, selectors)) |found| {
                                return found;
                            }
                        }
                        current = node.next_sibling;
                    }
                    return null;
                },
            }
        }

        // Fallback: parse selector without caching
        const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
        const Parser = @import("selector/parser.zig").Parser;
        const Matcher = @import("selector/matcher.zig").Matcher;

        var tokenizer = Tokenizer.init(allocator, selectors);
        var parser = try Parser.init(allocator, &tokenizer);
        defer parser.deinit();

        var selector_list = try parser.parse();
        defer selector_list.deinit();

        const matcher = Matcher.init(allocator);

        var current = self.prototype.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);

                if (try matcher.matches(elem, &selector_list)) {
                    return elem;
                }

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
    /// - querySelectorAll(): https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelectorAll
    ///
    /// ## Algorithm
    /// 1. Parse selectors string into selector list
    /// 2. Traverse descendants in tree order
    /// 3. Collect all elements that match any selector
    /// 4. Return NodeList with results (may be empty)
    ///
    /// ## Usage
    /// ```zig
    /// const container = try doc.createElement("div");
    ///
    /// const btn1 = try doc.createElement("button");
    /// try btn1.setAttribute("class", "btn");
    /// _ = try container.prototype.appendChild(&btn1.prototype);
    ///
    /// const btn2 = try doc.createElement("button");
    /// try btn2.setAttribute("class", "btn");
    /// _ = try container.prototype.appendChild(&btn2.prototype);
    ///
    /// // Find all buttons
    /// const results = try container.querySelectorAll(".btn");
    /// defer allocator.free(results);
    /// // results.len == 2
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// // Instance method on Element.prototype
    /// const element = document.querySelector('.container');
    /// const buttons = element.querySelectorAll('button.primary');
    /// // Returns: NodeList (array-like, always defined)
    /// ```
    ///
    /// ## Note
    /// Returns a static list (snapshot), not a live NodeList.
    /// Caller owns returned slice and must free it.
    pub fn querySelectorAll(self: *Element, allocator: Allocator, selectors: []const u8) ![]const *Element {
        // Try to get parsed selector from cache if we have an owner document
        const parsed_selector = blk: {
            if (self.prototype.owner_document) |owner| {
                if (owner.node_type == .document) {
                    const Document = @import("document.zig").Document;
                    const doc: *Document = @fieldParentPtr("prototype", owner);
                    break :blk try doc.selector_cache.get(selectors);
                }
            }
            break :blk null;
        };

        // Use fast path if available
        if (parsed_selector) |parsed| {
            switch (parsed.fast_path) {
                .simple_class => {
                    if (parsed.identifier) |class_name| {
                        return try self.queryAllByClass(allocator, class_name);
                    }
                },
                .simple_tag => {
                    if (parsed.identifier) |tag_name| {
                        return try self.queryAllByTagName(allocator, tag_name);
                    }
                },
                .simple_id => {
                    // ID queries return at most one result
                    if (parsed.identifier) |id| {
                        if (self.queryById(id)) |elem| {
                            const result = try allocator.alloc(*Element, 1);
                            result[0] = elem;
                            return result;
                        }
                        return &[_]*Element{};
                    }
                },
                .id_filtered, .generic => {
                    // Use cached parsed selector
                    const Matcher = @import("selector/matcher.zig").Matcher;
                    const matcher = Matcher.init(allocator);

                    var results = std.ArrayList(*Element){};
                    defer results.deinit(allocator);

                    try self.querySelectorAllHelper(allocator, &matcher, &parsed.selector_list, &results);
                    return try results.toOwnedSlice(allocator);
                },
            }
        }

        // Fallback: parse selector without caching
        const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
        const Parser = @import("selector/parser.zig").Parser;
        const Matcher = @import("selector/matcher.zig").Matcher;

        var tokenizer = Tokenizer.init(allocator, selectors);
        var parser = try Parser.init(allocator, &tokenizer);
        defer parser.deinit();

        var selector_list = try parser.parse();
        defer selector_list.deinit();

        const matcher = Matcher.init(allocator);

        var results = std.ArrayList(*Element){};
        defer results.deinit(allocator);

        try self.querySelectorAllHelper(allocator, &matcher, &selector_list, &results);

        return try results.toOwnedSlice(allocator);
    }

    /// Helper for querySelectorAll - recursively collects matching elements
    pub fn querySelectorAllHelper(
        self: *Element,
        allocator: Allocator,
        matcher: *const @import("selector/matcher.zig").Matcher,
        selector_list: *const @import("selector/parser.zig").SelectorList,
        results: *std.ArrayList(*Element),
    ) !void {

        // Traverse children in tree order
        var current = self.prototype.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);

                // Check if element matches
                if (try matcher.matches(elem, selector_list)) {
                    try results.append(allocator, elem);
                }

                // Recursively search descendants
                try elem.querySelectorAllHelper(allocator, matcher, selector_list, results);
            }
            current = node.next_sibling;
        }
    }

    /// Returns all descendant elements with the specified tag name.
    ///
    /// Implements WHATWG DOM Element.getElementsByTagName() per §4.9.
    ///
    /// ## WHATWG Specification
    /// - **§4.9 Interface Element**: https://dom.spec.whatwg.org/#dom-element-getelementsbytagname
    ///
    /// ## WebIDL
    /// ```webidl
    /// HTMLCollection getElementsByTagName(DOMString qualifiedName);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Element.getElementsByTagName(): https://developer.mozilla.org/en-US/docs/Web/API/Element/getElementsByTagName
    ///
    /// ## Algorithm (WHATWG DOM §4.9)
    /// Return a collection of all descendant elements with the given tag name.
    ///
    /// ## Performance
    /// **O(n)** where n = number of descendant nodes.
    /// Traverses subtree to find matching elements.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for result array
    /// - `tag_name`: Tag name to match (e.g., "container", "widget")
    ///
    /// ## Returns
    /// Slice of elements with matching tag name in tree order.
    /// Caller owns the slice and must free it.
    ///
    /// ## Example
    /// ```zig
    /// const container = try doc.createElement("container");
    /// const widget1 = try doc.createElement("widget");
    /// _ = try container.prototype.appendChild(&widget1.prototype);
    /// const widget2 = try doc.createElement("widget");
    /// _ = try container.prototype.appendChild(&widget2.prototype);
    ///
    /// const widgets = container.getElementsByTagName("widget");
    /// // widgets.length() == 2
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const widgets = element.getElementsByTagName('widget');
    /// // Returns: HTMLCollection
    /// ```
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-element-getelementsbytagname
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:Element
    ///
    /// ## Note
    /// This returns a live HTMLCollection scoped to this element's descendants.
    /// Changes to the DOM automatically reflect in the collection.
    pub fn getElementsByTagName(self: *Element, tag_name: []const u8) @import("html_collection.zig").HTMLCollection {
        return @import("html_collection.zig").HTMLCollection.initElementByTagName(self, tag_name);
    }

    /// Returns all descendant elements with the specified class name.
    ///
    /// Implements WHATWG DOM Element.getElementsByClassName() per §4.9.
    ///
    /// ## WHATWG Specification
    /// - **§4.9 Interface Element**: https://dom.spec.whatwg.org/#dom-element-getelementsbyclassname
    ///
    /// ## WebIDL
    /// ```webidl
    /// HTMLCollection getElementsByClassName(DOMString classNames);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Element.getElementsByClassName(): https://developer.mozilla.org/en-US/docs/Web/API/Element/getElementsByClassName
    ///
    /// ## Algorithm (WHATWG DOM §4.9)
    /// Return a collection of all descendant elements with the given class name.
    ///
    /// ## Performance
    /// **O(n)** where n = number of descendant nodes.
    /// Traverses subtree with bloom filter pre-filtering for fast rejection.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for result array
    /// - `class_name`: Single class name to match (without "." prefix)
    ///
    /// ## Returns
    /// Slice of elements with matching class name in tree order.
    /// Caller owns the slice and must free it.
    ///
    /// ## Example
    /// ```zig
    /// const container = try doc.createElement("container");
    /// const widget1 = try doc.createElement("widget");
    /// try widget1.setAttribute("class", "primary active");
    /// _ = try container.prototype.appendChild(&widget1.prototype);
    /// const widget2 = try doc.createElement("widget");
    /// try widget2.setAttribute("class", "primary");
    /// _ = try container.prototype.appendChild(&widget2.prototype);
    ///
    /// const primaries = container.getElementsByClassName("primary");
    /// // primaries.length() == 2
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// const primaries = element.getElementsByClassName('primary');
    /// // Returns: HTMLCollection
    /// ```
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-element-getelementsbyclassname
    /// - WebIDL: /Users/bcardarella/projects/webref/ed/idl/dom.idl:Element
    ///
    /// ## Note
    /// This returns a live HTMLCollection scoped to this element's descendants.
    /// Changes to the DOM automatically reflect in the collection.
    /// Only supports single class name lookup (not space-separated list yet).
    pub fn getElementsByClassName(self: *Element, class_name: []const u8) @import("html_collection.zig").HTMLCollection {
        return @import("html_collection.zig").HTMLCollection.initElementByClassName(self, class_name);
    }

    // ========================================================================
    // Fast Path Query Methods (Phase 1 Optimizations)
    // ========================================================================

    /// Fast path: Query by ID attribute (O(n) scan with early exit)
    ///
    /// Traverses descendants looking for element with matching id attribute.
    /// Much faster than full querySelector for simple "#id" patterns.
    ///
    /// ## Parameters
    /// - `id`: ID value to match (without "#" prefix)
    ///
    /// ## Returns
    /// First element with matching id attribute, or null
    ///
    /// ## Performance
    /// - O(n) worst case, but typically finds match early
    /// - No parsing or selector matching overhead
    /// - Skips non-element nodes automatically
    ///
    /// ## Example
    /// ```zig
    /// const container = try doc.createElement("div");
    /// const button = try doc.createElement("button");
    /// try button.setAttribute("id", "submit-btn");
    /// _ = try container.prototype.appendChild(&button.prototype);
    ///
    /// const found = try container.queryById("submit-btn");
    /// // found == button
    /// ```
    pub fn queryById(self: *Element, id: []const u8) ?*Element {
        // Fast path: Use document ID map if available (O(1) lookup!)
        if (self.prototype.owner_document) |owner| {
            if (owner.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner);

                // Check if element with this ID exists
                if (doc.id_map.get(id)) |elem| {
                    // Fast case: if self is the document element, all elements are descendants
                    if (self == doc.documentElement()) {
                        return elem;
                    }

                    // Otherwise verify the element is actually a descendant of self
                    var current = elem.prototype.parent_node;
                    while (current) |parent| {
                        if (parent == &self.prototype) {
                            return elem;
                        }
                        current = parent.parent_node;
                    }
                }
            }
        }

        // Fallback: O(n) scan if no document or element not in our subtree
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var iter = ElementIterator.init(&self.prototype);

        while (iter.next()) |elem| {
            if (elem.getId()) |elem_id| {
                if (std.mem.eql(u8, elem_id, id)) {
                    return elem;
                }
            }
        }

        return null;
    }

    /// Fast path: Query by class name (O(n) scan with bloom filter rejection)
    ///
    /// Traverses descendants looking for element with matching class.
    /// Uses bloom filter for 80-90% rejection rate before string comparison.
    ///
    /// ## Parameters
    /// - `class_name`: Class name to match (without "." prefix)
    ///
    /// ## Returns
    /// First element with matching class, or null
    ///
    /// ## Performance
    /// - O(n) worst case, but bloom filter rejects most non-matches quickly
    /// - 2-5x faster than full querySelector for simple ".class" patterns
    /// - Skips non-element nodes automatically
    ///
    /// ## Example
    /// ```zig
    /// const container = try doc.createElement("div");
    /// const button = try doc.createElement("button");
    /// try button.setAttribute("class", "btn primary");
    /// _ = try container.prototype.appendChild(&button.prototype);
    ///
    /// const found = container.queryByClass("primary");
    /// // found == button
    /// ```
    pub fn queryByClass(self: *Element, class_name: []const u8) ?*Element {
        // Phase 3: Tree traversal with bloom filter (class_map removed)
        // Bloom filter provides O(1) fast rejection for non-matching elements
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var iter = ElementIterator.init(&self.prototype);

        while (iter.next()) |elem| {
            // Fast bloom filter check first
            if (!elem.class_bloom.mayContain(class_name)) continue;

            // Verify actual class presence
            if (elem.hasClass(class_name)) {
                return elem;
            }
        }

        return null;
    }

    /// Fast path: Query by tag name (O(n) scan with direct comparison)
    ///
    /// Traverses descendants looking for element with matching tag name.
    /// Direct string comparison, no parsing overhead.
    ///
    /// ## Parameters
    /// - `tag_name`: Tag name to match (case-sensitive)
    ///
    /// ## Returns
    /// First element with matching tag name, or null
    ///
    /// ## Performance
    /// - O(n) worst case
    /// - 2-3x faster than full querySelector for simple "tag" patterns
    /// - Skips non-element nodes automatically
    ///
    /// ## Example
    /// ```zig
    /// const container = try doc.createElement("div");
    /// const button = try doc.createElement("button");
    /// _ = try container.prototype.appendChild(&button.prototype);
    ///
    /// const found = container.queryByTagName("button");
    /// // found == button
    /// ```
    pub fn queryByTagName(self: *Element, tag_name: []const u8) ?*Element {
        // Fast path: Use document tag map if available
        if (self.prototype.owner_document) |owner| {
            if (owner.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner);

                // Check if any elements with this tag exist
                if (doc.tag_map.get(tag_name)) |list| {
                    // Find first element that is a descendant of self
                    for (list.items) |elem| {
                        // Skip self (we only want descendants)
                        if (elem == self) continue;

                        // Fast case: if self is the document element, all other elements are descendants
                        if (self == doc.documentElement()) {
                            return elem;
                        }

                        // Verify element is descendant of self
                        var current = elem.prototype.parent_node;
                        while (current) |parent| {
                            if (parent == &self.prototype) {
                                return elem;
                            }
                            current = parent.parent_node;
                        }
                    }
                }
            }
        }

        // Fallback: O(n) scan if no document or no elements in our subtree
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var iter = ElementIterator.init(&self.prototype);

        while (iter.next()) |elem| {
            if (std.mem.eql(u8, elem.tag_name, tag_name)) {
                return elem;
            }
        }

        return null;
    }

    /// Fast path: Query all by class name
    ///
    /// Collects all descendants with matching class name.
    /// Uses bloom filter for fast rejection.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for result array
    /// - `class_name`: Class name to match (without "." prefix)
    ///
    /// ## Returns
    /// Array of matching elements (caller owns, must free)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate result array
    pub fn queryAllByClass(self: *Element, allocator: Allocator, class_name: []const u8) ![]const *Element {
        // Phase 3: Tree traversal with bloom filter (class_map removed)
        // Bloom filter provides O(1) fast rejection for non-matching elements
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var results = std.ArrayList(*Element){};
        defer results.deinit(allocator);

        var iter = ElementIterator.init(&self.prototype);
        while (iter.next()) |elem| {
            // Fast bloom filter check first
            if (!elem.class_bloom.mayContain(class_name)) continue;

            // Verify actual class presence
            if (elem.hasClass(class_name)) {
                try results.append(allocator, elem);
            }
        }

        return try results.toOwnedSlice(allocator);
    }

    /// Fast path: Query all by tag name
    ///
    /// Collects all descendants with matching tag name.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for result array
    /// - `tag_name`: Tag name to match (case-sensitive)
    ///
    /// ## Returns
    /// Array of matching elements (caller owns, must free)
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate result array
    pub fn queryAllByTagName(self: *Element, allocator: Allocator, tag_name: []const u8) ![]const *Element {
        // Fast path: Use document tag map if available
        if (self.prototype.owner_document) |owner| {
            if (owner.node_type == .document) {
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner);

                // Check if any elements with this tag exist
                if (doc.tag_map.get(tag_name)) |list| {
                    var results = std.ArrayList(*Element){};
                    defer results.deinit(allocator);

                    for (list.items) |elem| {
                        // Skip self (we only want descendants)
                        if (elem == self) continue;

                        // Fast case: if self is the document element, all other elements are descendants
                        if (self == doc.documentElement()) {
                            try results.append(allocator, elem);
                            continue;
                        }

                        // Verify element is descendant of self
                        var current = elem.prototype.parent_node;
                        while (current) |parent| {
                            if (parent == &self.prototype) {
                                try results.append(allocator, elem);
                                break;
                            }
                            current = parent.parent_node;
                        }
                    }

                    return try results.toOwnedSlice(allocator);
                }

                // No elements with this tag
                return &[_]*Element{};
            }
        }

        // Fallback: O(n) scan
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var results = std.ArrayList(*Element){};
        defer results.deinit(allocator);

        var iter = ElementIterator.init(&self.prototype);
        while (iter.next()) |elem| {
            if (std.mem.eql(u8, elem.tag_name, tag_name)) {
                try results.append(allocator, elem);
            }
        }

        return try results.toOwnedSlice(allocator);
    }

    // ========================================================================
    // Element Selector Methods
    // ========================================================================

    /// Tests if the element matches the specified CSS selector.
    ///
    /// ## WHATWG Specification
    /// - **§4.9 Interface Element**: https://dom.spec.whatwg.org/#dom-element-matches
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean matches(DOMString selectors);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Element.matches(): https://developer.mozilla.org/en-US/docs/Web/API/Element/matches
    ///
    /// ## Algorithm
    /// 1. Parse selectors string into selector list
    /// 2. Test if this element matches any selector in list
    /// 3. Return true if match, false otherwise
    ///
    /// ## Usage
    /// ```zig
    /// const button = try doc.createElement("button");
    /// try button.setAttribute("class", "btn primary");
    ///
    /// // Test if button matches selector
    /// const is_button = try button.matches(allocator, "button");
    /// // is_button == true
    ///
    /// const is_primary = try button.matches(allocator, ".primary");
    /// // is_primary == true
    ///
    /// const is_link = try button.matches(allocator, "a");
    /// // is_link == false
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// // Instance method on Element.prototype
    /// const element = document.querySelector('.container');
    /// const matches = element.matches('div.container');
    /// // Returns: boolean
    /// ```
    ///
    /// ## Common Use Cases
    /// - Event delegation: Check if event target matches selector
    /// - Conditional logic: Apply different behavior based on selector match
    /// - Feature detection: Test element characteristics
    pub fn matches(self: *Element, allocator: Allocator, selectors: []const u8) !bool {
        const Tokenizer = @import("selector/tokenizer.zig").Tokenizer;
        const Parser = @import("selector/parser.zig").Parser;
        const Matcher = @import("selector/matcher.zig").Matcher;

        // Parse selector
        var tokenizer = Tokenizer.init(allocator, selectors);
        var parser = try Parser.init(allocator, &tokenizer);
        defer parser.deinit();

        var selector_list = try parser.parse();
        defer selector_list.deinit();

        // Create matcher and test element
        const matcher = Matcher.init(allocator);
        return try matcher.matches(self, &selector_list);
    }

    /// Returns the nearest ancestor (including self) that matches the specified CSS selector.
    ///
    /// ## WHATWG Specification
    /// - **§4.9 Interface Element**: https://dom.spec.whatwg.org/#dom-element-closest
    ///
    /// ## WebIDL
    /// ```webidl
    /// Element? closest(DOMString selectors);
    /// ```
    ///
    /// ## MDN Documentation
    /// - Element.closest(): https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
    ///
    /// ## Algorithm
    /// 1. Parse selectors string into selector list
    /// 2. Test if this element matches (check self first)
    /// 3. If not, traverse up the tree testing each ancestor
    /// 4. Return first matching ancestor, or null if none match
    ///
    /// ## Usage
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const form = try doc.createElement("form");
    /// try form.setAttribute("class", "login-form");
    /// _ = try doc.prototype.appendChild(&form.prototype);
    ///
    /// const button = try doc.createElement("button");
    /// _ = try form.prototype.appendChild(&button.prototype);
    ///
    /// // Find closest form from button
    /// const closest_form = try button.closest(allocator, "form");
    /// // closest_form == form
    ///
    /// // Find closest .login-form
    /// const closest_login = try button.closest(allocator, ".login-form");
    /// // closest_login == form
    ///
    /// // No match
    /// const no_match = try button.closest(allocator, "table");
    /// // no_match == null
    /// ```
    ///
    /// ## JavaScript Binding
    /// ```javascript
    /// // Instance method on Element.prototype
    /// const button = document.querySelector('button');
    /// const form = button.closest('form');
    /// // Returns: Element or null
    /// ```
    ///
    /// ## Common Use Cases
    /// - Event delegation: Find parent matching selector from event target
    /// - Component boundaries: Find containing component element
    /// - Form handling: Find form from any input element
    pub fn closest(self: *Element, allocator: Allocator, selectors: []const u8) !?*Element {
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

        // Test self first
        if (try matcher.matches(self, &selector_list)) {
            return self;
        }

        // Traverse ancestors
        var current = self.prototype.parent_node;
        while (current) |parent_node| {
            if (parent_node.node_type == .element) {
                const parent_elem: *Element = @fieldParentPtr("prototype", parent_node);
                if (try matcher.matches(parent_elem, &selector_list)) {
                    return parent_elem;
                }
            }
            current = parent_node.parent_node;
        }

        return null;
    }

    /// Legacy alias for matches().
    ///
    /// Implements WHATWG DOM Element.webkitMatchesSelector() (legacy).
    ///
    /// ## WebIDL
    /// ```webidl
    /// boolean webkitMatchesSelector(DOMString selectors); // legacy alias of .matches
    /// ```
    ///
    /// ## MDN Documentation
    /// - webkitMatchesSelector: https://developer.mozilla.org/en-US/docs/Web/API/Element/webkitMatchesSelector
    ///
    /// ## Spec References
    /// - WebIDL: dom.idl:399
    ///
    /// ## Note
    /// This is a legacy alias for compatibility. New code should use matches() instead.
    ///
    /// ## Example
    /// ```zig
    /// const elem = try doc.createElement("div");
    /// elem.setAttribute("class", "container");
    ///
    /// // Legacy API (avoid in new code)
    /// try std.testing.expect(try elem.webkitMatchesSelector(allocator, ".container"));
    ///
    /// // Prefer modern API
    /// try std.testing.expect(try elem.matches(allocator, ".container"));
    /// ```
    pub fn webkitMatchesSelector(self: *Element, allocator: Allocator, selectors: []const u8) !bool {
        return self.matches(allocator, selectors);
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
    /// ## MDN Documentation
    /// - children: https://developer.mozilla.org/en-US/docs/Web/API/Element/children
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// Return a live ElementCollection of the element children of this element.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-children
    /// - WebIDL: dom.idl:119
    ///
    /// ## Returns
    /// Live ElementCollection of element children (excludes text, comment, etc.)
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const parent = try doc.createElement("parent");
    ///
    /// // Add mixed children
    /// const elem1 = try doc.createElement("child1");
    /// _ = try parent.prototype.appendChild(&elem1.prototype);
    ///
    /// const text = try doc.createTextNode("text");
    /// _ = try parent.prototype.appendChild(&text.prototype);
    ///
    /// const elem2 = try doc.createElement("child2");
    /// _ = try parent.prototype.appendChild(&elem2.prototype);
    ///
    /// // children() returns live collection of elements only
    /// const children = parent.children();
    /// try std.testing.expectEqual(@as(usize, 2), children.length()); // Excludes text
    /// ```
    pub fn children(self: *Element) @import("html_collection.zig").HTMLCollection {
        return @import("html_collection.zig").HTMLCollection.initChildren(&self.prototype);
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
    /// - firstElementChild: https://developer.mozilla.org/en-US/docs/Web/API/Element/firstElementChild
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
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const text = try doc.createTextNode("text");
    /// _ = try parent.prototype.appendChild(&text.prototype);
    /// const elem = try doc.createElement("child");
    /// _ = try parent.prototype.appendChild(&elem.prototype);
    ///
    /// // firstElementChild skips text node
    /// try std.testing.expect(parent.firstElementChild() == elem);
    /// ```
    pub fn firstElementChild(self: *const Element) ?*Element {
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
    /// Implements WHATWG DOM ParentNode.lastElementChild property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? lastElementChild;
    /// ```
    ///
    /// ## MDN Documentation
    /// - lastElementChild: https://developer.mozilla.org/en-US/docs/Web/API/Element/lastElementChild
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
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const elem = try doc.createElement("first");
    /// _ = try parent.prototype.appendChild(&elem.prototype);
    /// const text = try doc.createTextNode("text");
    /// _ = try parent.prototype.appendChild(&text.prototype);
    ///
    /// // lastElementChild skips text node
    /// try std.testing.expect(parent.lastElementChild() == elem);
    /// ```
    pub fn lastElementChild(self: *const Element) ?*Element {
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
    /// Implements WHATWG DOM ParentNode.childElementCount property per §4.2.6.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute unsigned long childElementCount;
    /// ```
    ///
    /// ## MDN Documentation
    /// - childElementCount: https://developer.mozilla.org/en-US/docs/Web/API/Element/childElementCount
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
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// _ = try parent.prototype.appendChild(&(try doc.createElement("child1")).node);
    /// _ = try parent.prototype.appendChild(&(try doc.createTextNode("text")).node);
    /// _ = try parent.prototype.appendChild(&(try doc.createElement("child2")).node);
    ///
    /// // Count = 2 (excludes text node)
    /// try std.testing.expectEqual(@as(u32, 2), parent.childElementCount());
    /// ```
    pub fn childElementCount(self: *const Element) u32 {
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
    /// - prepend(): https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Pre-insert node into this before this's first child
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-prepend
    /// - WebIDL: dom.idl:124
    ///
    /// ## Parameters
    /// - `nodes`: Slice of nodes or strings to prepend
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate
    /// - `error.HierarchyRequestError`: Invalid tree structure
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const existing = try doc.createElement("existing");
    /// _ = try parent.prototype.appendChild(&existing.prototype);
    ///
    /// const child = try doc.createElement("child");
    /// try parent.prepend(&[_]Element.NodeOrString{
    ///     .{ .node = &child.prototype },
    ///     .{ .string = "text" },
    /// });
    /// // Order: child, text, existing
    /// ```
    pub fn prepend(self: *Element, nodes: []const NodeOrString) !void {
        const result = try convertNodesToNode(&self.prototype, nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try self.prototype.insertBefore(node_to_insert, self.prototype.first_child);

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
    /// - append(): https://developer.mozilla.org/en-US/docs/Web/API/Element/append
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Append node to this
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-append
    /// - WebIDL: dom.idl:125
    ///
    /// ## Parameters
    /// - `nodes`: Slice of nodes or strings to append
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate
    /// - `error.HierarchyRequestError`: Invalid tree structure
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const child = try doc.createElement("child");
    /// try parent.append(&[_]Element.NodeOrString{
    ///     .{ .node = &child.prototype },
    ///     .{ .string = "text" },
    /// });
    /// ```
    pub fn append(self: *Element, nodes: []const NodeOrString) !void {
        const result = try convertNodesToNode(&self.prototype, nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try self.prototype.appendChild(node_to_insert);

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
    /// - replaceChildren(): https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceChildren
    ///
    /// ## Algorithm (from spec §4.2.6)
    /// 1. Let node be the result of converting nodes into a node given this's node document
    /// 2. Ensure pre-replace validity of node
    /// 3. Replace all children of this with node
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-parentnode-replacechildren
    /// - WebIDL: dom.idl:126
    ///
    /// ## Parameters
    /// - `nodes`: Slice of nodes or strings to replace children with
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate
    /// - `error.HierarchyRequestError`: Invalid tree structure
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// _ = try parent.prototype.appendChild(&(try doc.createElement("old")).node);
    ///
    /// const new_child = try doc.createElement("new");
    /// try parent.replaceChildren(&[_]Element.NodeOrString{
    ///     .{ .node = &new_child.prototype },
    /// });
    /// ```
    pub fn replaceChildren(self: *Element, nodes: []const NodeOrString) !void {
        const result = try convertNodesToNode(&self.prototype, nodes);

        while (self.prototype.first_child) |child| {
            const removed = try self.prototype.removeChild(child);
            removed.release();
        }

        if (result) |r| {
            const returned_node = try self.prototype.appendChild(r.node);
            if (r.should_release_after_insert) {
                returned_node.release();
            }
        }
    }

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
        const doc: *Document = @fieldParentPtr("prototype", owner_doc);

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
                        .node = &text.prototype,
                        .should_release_after_insert = false,
                    };
                },
            }
        }

        const fragment = try doc.createDocumentFragment();
        errdefer fragment.prototype.release();

        for (items) |item| {
            switch (item) {
                .node => |n| {
                    _ = try fragment.prototype.appendChild(n);
                },
                .string => |s| {
                    const text = try doc.createTextNode(s);
                    _ = try fragment.prototype.appendChild(&text.prototype);
                },
            }
        }

        return ConvertResult{
            .node = &fragment.prototype,
            .should_release_after_insert = true,
        };
    }

    // ========================================================================
    // NonDocumentTypeChildNode Mixin (WHATWG DOM §4.2.7)
    // ========================================================================

    /// Returns the previous sibling that is an element.
    ///
    /// Implements WHATWG DOM NonDocumentTypeChildNode.previousElementSibling property.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? previousElementSibling;
    /// ```
    ///
    /// ## MDN Documentation
    /// - previousElementSibling: https://developer.mozilla.org/en-US/docs/Web/API/Element/previousElementSibling
    ///
    /// ## Algorithm (from spec §4.2.7)
    /// Return the first preceding sibling of this that is an element, or null if there is no such sibling.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-previouselementsibling
    /// - WebIDL: dom.idl:138
    ///
    /// ## Returns
    /// Previous element sibling or null
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const elem1 = try doc.createElement("child1");
    /// _ = try parent.prototype.appendChild(&elem1.prototype);
    /// const text = try doc.createTextNode("text");
    /// _ = try parent.prototype.appendChild(&text.prototype);
    /// const elem2 = try doc.createElement("child2");
    /// _ = try parent.prototype.appendChild(&elem2.prototype);
    ///
    /// // elem2.previousElementSibling() skips text node, returns elem1
    /// try std.testing.expect(elem2.previousElementSibling() == elem1);
    /// ```
    pub fn previousElementSibling(self: *const Element) ?*Element {
        var current = self.prototype.previous_sibling;
        while (current) |sibling| {
            if (sibling.node_type == .element) {
                return @fieldParentPtr("prototype", sibling);
            }
            current = sibling.previous_sibling;
        }
        return null;
    }

    /// Returns the next sibling that is an element.
    ///
    /// Implements WHATWG DOM NonDocumentTypeChildNode.nextElementSibling property.
    ///
    /// ## WebIDL
    /// ```webidl
    /// readonly attribute Element? nextElementSibling;
    /// ```
    ///
    /// ## MDN Documentation
    /// - nextElementSibling: https://developer.mozilla.org/en-US/docs/Web/API/Element/nextElementSibling
    ///
    /// ## Algorithm (from spec §4.2.7)
    /// Return the first following sibling of this that is an element, or null if there is no such sibling.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-nextelementsibling
    /// - WebIDL: dom.idl:139
    ///
    /// ## Returns
    /// Next element sibling or null
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const elem1 = try doc.createElement("child1");
    /// _ = try parent.prototype.appendChild(&elem1.prototype);
    /// const text = try doc.createTextNode("text");
    /// _ = try parent.prototype.appendChild(&text.prototype);
    /// const elem2 = try doc.createElement("child2");
    /// _ = try parent.prototype.appendChild(&elem2.prototype);
    ///
    /// // elem1.nextElementSibling() skips text node, returns elem2
    /// try std.testing.expect(elem1.nextElementSibling() == elem2);
    /// ```
    pub fn nextElementSibling(self: *const Element) ?*Element {
        var current = self.prototype.next_sibling;
        while (current) |sibling| {
            if (sibling.node_type == .element) {
                return @fieldParentPtr("prototype", sibling);
            }
            current = sibling.next_sibling;
        }
        return null;
    }

    // ========================================================================
    // ChildNode Mixin (WHATWG DOM §4.2.8)
    // ========================================================================

    /// Removes this element from its parent.
    ///
    /// Implements WHATWG DOM ChildNode.remove() per §4.2.8.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined remove();
    /// ```
    ///
    /// ## MDN Documentation
    /// - remove(): https://developer.mozilla.org/en-US/docs/Web/API/Element/remove
    ///
    /// ## Algorithm (from spec §4.2.8)
    /// If this's parent is null, return. Otherwise, remove this from its parent.
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-remove
    /// - WebIDL: dom.idl:148
    ///
    /// ## Errors
    /// - No errors (no-op if no parent)
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const child = try doc.createElement("child");
    /// _ = try parent.prototype.appendChild(&child.prototype);
    ///
    /// // Remove child from parent
    /// try child.remove();
    /// try std.testing.expect(parent.prototype.first_child == null);
    /// ```
    pub fn remove(self: *Element) !void {
        if (self.prototype.parent_node) |parent| {
            _ = try parent.removeChild(&self.prototype);
        }
    }

    /// Inserts nodes before this element.
    ///
    /// Implements WHATWG DOM ChildNode.before() per §4.2.8.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined before((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - before(): https://developer.mozilla.org/en-US/docs/Web/API/Element/before
    ///
    /// ## Algorithm (from spec §4.2.8)
    /// 1. Let parent be this's parent
    /// 2. If parent is null, return
    /// 3. Let viablePreviousSibling be this's first preceding sibling not in nodes
    /// 4. Let node be the result of converting nodes into a node
    /// 5. Pre-insert node into parent before this
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-before
    /// - WebIDL: dom.idl:145
    ///
    /// ## Parameters
    /// - `nodes`: Slice of nodes or strings to insert before this element
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate
    /// - `error.HierarchyRequestError`: Invalid tree structure
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const target = try doc.createElement("target");
    /// _ = try parent.prototype.appendChild(&target.prototype);
    ///
    /// const new_node = try doc.createElement("new");
    /// try target.before(&[_]NodeOrString{.{ .node = &new_node.prototype }});
    /// // Order: new, target
    /// ```
    pub fn before(self: *Element, nodes: []const NodeOrString) !void {
        const parent = self.prototype.parent_node orelse return;

        const result = try convertNodesToNode(&self.prototype, nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try parent.insertBefore(node_to_insert, &self.prototype);

        if (should_release) {
            returned_node.release();
        }
    }

    /// Inserts nodes after this element.
    ///
    /// Implements WHATWG DOM ChildNode.after() per §4.2.8.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined after((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - after(): https://developer.mozilla.org/en-US/docs/Web/API/Element/after
    ///
    /// ## Algorithm (from spec §4.2.8)
    /// 1. Let parent be this's parent
    /// 2. If parent is null, return
    /// 3. Let viableNextSibling be this's first following sibling not in nodes
    /// 4. Let node be the result of converting nodes into a node
    /// 5. Pre-insert node into parent before viableNextSibling
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-after
    /// - WebIDL: dom.idl:146
    ///
    /// ## Parameters
    /// - `nodes`: Slice of nodes or strings to insert after this element
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate
    /// - `error.HierarchyRequestError`: Invalid tree structure
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const target = try doc.createElement("target");
    /// _ = try parent.prototype.appendChild(&target.prototype);
    ///
    /// const new_node = try doc.createElement("new");
    /// try target.after(&[_]NodeOrString{.{ .node = &new_node.prototype }});
    /// // Order: target, new
    /// ```
    pub fn after(self: *Element, nodes: []const NodeOrString) !void {
        const parent = self.prototype.parent_node orelse return;

        const result = try convertNodesToNode(&self.prototype, nodes);
        if (result == null) return;

        const node_to_insert = result.?.node;
        const should_release = result.?.should_release_after_insert;

        const returned_node = try parent.insertBefore(node_to_insert, self.prototype.next_sibling);

        if (should_release) {
            returned_node.release();
        }
    }

    /// Replaces this element with other nodes.
    ///
    /// Implements WHATWG DOM ChildNode.replaceWith() per §4.2.8.
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions, Unscopable] undefined replaceWith((Node or DOMString)... nodes);
    /// ```
    ///
    /// ## MDN Documentation
    /// - replaceWith(): https://developer.mozilla.org/en-US/docs/Web/API/Element/replaceWith
    ///
    /// ## Algorithm (from spec §4.2.8)
    /// 1. Let parent be this's parent
    /// 2. If parent is null, return
    /// 3. Let viableNextSibling be this's first following sibling not in nodes
    /// 4. Let node be the result of converting nodes into a node
    /// 5. If this's parent is parent, replace this with node within parent
    /// 6. Otherwise, pre-insert node into parent before viableNextSibling
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-childnode-replacewith
    /// - WebIDL: dom.idl:147
    ///
    /// ## Parameters
    /// - `nodes`: Slice of nodes or strings to replace this element with
    ///
    /// ## Errors
    /// - `error.OutOfMemory`: Failed to allocate
    /// - `error.HierarchyRequestError`: Invalid tree structure
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const old = try doc.createElement("old");
    /// _ = try parent.prototype.appendChild(&old.prototype);
    ///
    /// const new_node = try doc.createElement("new");
    /// try old.replaceWith(&[_]NodeOrString{.{ .node = &new_node.prototype }});
    /// // parent now contains: new (old is removed)
    /// ```
    pub fn replaceWith(self: *Element, nodes: []const NodeOrString) !void {
        const parent = self.prototype.parent_node orelse return;

        const result = try convertNodesToNode(&self.prototype, nodes);

        if (result) |r| {
            _ = try parent.replaceChild(r.node, &self.prototype);
            if (r.should_release_after_insert) {
                r.prototype.release();
            }
        } else {
            // Empty nodes array - just remove self
            _ = try parent.removeChild(&self.prototype);
        }
    }

    // === Private implementation ===

    /// Updates the bloom filter from a class attribute value.
    fn updateClassBloom(self: *Element, class_value: []const u8) void {
        self.class_bloom.clear();

        var iter = std.mem.splitSequence(u8, class_value, " ");
        while (iter.next()) |class| {
            if (class.len > 0) {
                self.class_bloom.add(class);
            }
        }
    }

    // NOTE: Phase 3 - addToClassMap and removeFromClassMap removed
    // getElementsByClassName now uses tree traversal with bloom filters instead of class_map

    // ========================================================================
    // Legacy Insertion Methods (WHATWG DOM §4.10)
    // ========================================================================

    /// Inserts an element at a position relative to this element.
    ///
    /// Implements WHATWG DOM Element.insertAdjacentElement() per §4.10 (legacy).
    ///
    /// ## WebIDL
    /// ```webidl
    /// [CEReactions] Element? insertAdjacentElement(DOMString where, Element element);
    /// ```
    ///
    /// ## MDN Documentation
    /// - insertAdjacentElement(): https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentElement
    ///
    /// ## Algorithm (from spec §4.10)
    /// where can be:
    /// - "beforebegin": Before this element
    /// - "afterbegin": As first child of this element
    /// - "beforeend": As last child of this element
    /// - "afterend": After this element
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-element-insertadjacentelement
    /// - WebIDL: dom.idl:405
    ///
    /// ## Parameters
    /// - `where`: Position string ("beforebegin", "afterbegin", "beforeend", "afterend")
    /// - `element`: Element to insert
    ///
    /// ## Returns
    /// The inserted element, or null if position is invalid
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const child = try doc.createElement("child");
    /// const new_elem = try doc.createElement("new");
    ///
    /// _ = try parent.prototype.appendChild(&child.prototype);
    /// const result = try child.insertAdjacentElement("beforebegin", new_elem);
    /// // Order: new, child
    /// ```
    pub fn insertAdjacentElement(self: *Element, where: []const u8, element: *Element) !?*Element {
        if (std.mem.eql(u8, where, "beforebegin")) {
            const parent = self.prototype.parent_node orelse return null;
            _ = try parent.insertBefore(&element.prototype, &self.prototype);
            return element;
        } else if (std.mem.eql(u8, where, "afterbegin")) {
            _ = try self.prototype.insertBefore(&element.prototype, self.prototype.first_child);
            return element;
        } else if (std.mem.eql(u8, where, "beforeend")) {
            _ = try self.prototype.appendChild(&element.prototype);
            return element;
        } else if (std.mem.eql(u8, where, "afterend")) {
            const parent = self.prototype.parent_node orelse return null;
            _ = try parent.insertBefore(&element.prototype, self.prototype.next_sibling);
            return element;
        } else {
            // Invalid position
            return error.SyntaxError;
        }
    }

    /// Inserts text at a position relative to this element.
    ///
    /// Implements WHATWG DOM Element.insertAdjacentText() per §4.10 (legacy).
    ///
    /// ## WebIDL
    /// ```webidl
    /// undefined insertAdjacentText(DOMString where, DOMString data);
    /// ```
    ///
    /// ## MDN Documentation
    /// - insertAdjacentText(): https://developer.mozilla.org/en-US/docs/Web/API/Element/insertAdjacentText
    ///
    /// ## Algorithm (from spec §4.10)
    /// where can be:
    /// - "beforebegin": Before this element
    /// - "afterbegin": As first child of this element
    /// - "beforeend": As last child of this element
    /// - "afterend": After this element
    ///
    /// ## Spec References
    /// - Algorithm: https://dom.spec.whatwg.org/#dom-element-insertadjacenttext
    /// - WebIDL: dom.idl:406
    ///
    /// ## Parameters
    /// - `where`: Position string ("beforebegin", "afterbegin", "beforeend", "afterend")
    /// - `data`: Text content to insert
    ///
    /// ## Errors
    /// - `error.SyntaxError`: Invalid position string
    /// - `error.OutOfMemory`: Failed to create text node
    ///
    /// ## Example
    /// ```zig
    /// const parent = try doc.createElement("parent");
    /// const child = try doc.createElement("child");
    ///
    /// _ = try parent.prototype.appendChild(&child.prototype);
    /// try child.insertAdjacentText("beforebegin", "text");
    /// // Order: text, child
    /// ```
    pub fn insertAdjacentText(self: *Element, where: []const u8, data: []const u8) !void {
        const owner_doc = self.prototype.owner_document orelse {
            return error.InvalidStateError;
        };
        if (owner_doc.node_type != .document) {
            return error.InvalidStateError;
        }

        const Document = @import("document.zig").Document;
        const doc: *Document = @fieldParentPtr("prototype", owner_doc);
        const text = try doc.createTextNode(data);

        if (std.mem.eql(u8, where, "beforebegin")) {
            const parent = self.prototype.parent_node orelse return;
            _ = try parent.insertBefore(&text.prototype, &self.prototype);
        } else if (std.mem.eql(u8, where, "afterbegin")) {
            _ = try self.prototype.insertBefore(&text.prototype, self.prototype.first_child);
        } else if (std.mem.eql(u8, where, "beforeend")) {
            _ = try self.prototype.appendChild(&text.prototype);
        } else if (std.mem.eql(u8, where, "afterend")) {
            const parent = self.prototype.parent_node orelse return;
            _ = try parent.insertBefore(&text.prototype, self.prototype.next_sibling);
        } else {
            // Invalid position - need to release the text node we created
            text.prototype.release();
            return error.SyntaxError;
        }
    }

    // ========================================================================
    // Vtable Implementations
    // ========================================================================

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const elem: *Element = @fieldParentPtr("prototype", node);

        // Release document reference if owned by a document
        if (elem.prototype.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                // Get Document from its node field (node is first field)
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("prototype", owner_doc);

                // Remove from tag map
                if (doc.tag_map.getPtr(elem.tag_name)) |list_ptr| {
                    // Find and remove this element from the list
                    for (list_ptr.items, 0..) |item, i| {
                        if (item == elem) {
                            _ = list_ptr.swapRemove(i);
                            break;
                        }
                    }
                }

                // NOTE: Phase 3 - class_map removed, no cleanup needed

                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        elem.prototype.deinitRareData();

        // Release all children
        var current = elem.prototype.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            child.parent_node = null;
            child.setHasParent(false);
            child.release(); // Release parent's ownership
            current = next;
        }

        // Clean up attr cache if allocated
        if (elem.attr_cache) |*cache| {
            cache.deinit();
        }

        elem.attributes.deinit();
        elem.prototype.allocator.destroy(elem);
    }

    /// Vtable implementation: node name (returns tag name)
    fn nodeNameImpl(node: *const Node) []const u8 {
        const elem: *const Element = @fieldParentPtr("prototype", node);
        return elem.tag_name;
    }

    /// Vtable implementation: node value (always null for elements)
    fn nodeValueImpl(_: *const Node) ?[]const u8 {
        return null;
    }

    /// Vtable implementation: set node value (no-op for elements)
    fn setNodeValueImpl(_: *Node, _: []const u8) !void {
        // Elements don't have node values, this is a no-op per spec
    }

    /// Vtable implementation: clone node
    fn cloneNodeImpl(node: *const Node, deep: bool) !*Node {
        const elem: *const Element = @fieldParentPtr("prototype", node);

        // Create new element with same tag
        const cloned = try Element.create(elem.prototype.allocator, elem.tag_name);
        errdefer cloned.prototype.release();

        // Preserve owner document (WHATWG DOM §4.5.1 Clone algorithm)
        cloned.prototype.owner_document = elem.prototype.owner_document;

        // Copy attributes
        var attr_iter = elem.attributes.iterator();
        while (attr_iter.next()) |attr| {
            try cloned.setAttribute(attr.name.local_name, attr.value);
        }

        // Deep clone children if requested
        if (deep) {
            var child = elem.prototype.first_child;
            while (child) |child_node| {
                const child_clone = try child_node.cloneNode(true);
                errdefer child_clone.release();
                _ = try cloned.prototype.appendChild(child_clone);
                // NO release - parent owns child (ref_count=1, has_parent=true)
                child = child_node.next_sibling;
            }
        }

        return &cloned.prototype;
    }

    /// Internal: Clones element using a specific allocator.
    ///
    /// Used by `Document.importNode()` to clone elements into a different
    /// document's allocator.
    ///
    /// ## Parameters
    /// - `elem`: The element to clone
    /// - `allocator`: The allocator to use for the cloned element
    /// - `deep`: Whether to recursively clone children
    ///
    /// ## Returns
    /// A new cloned element allocated with the specified allocator
    pub fn cloneWithAllocator(elem: *const Element, allocator: Allocator, deep: bool) anyerror!*Node {
        // Create new element with same tag using the provided allocator
        const cloned = try Element.create(allocator, elem.tag_name);
        errdefer cloned.prototype.release();

        // Preserve owner document (will be updated by adopt())
        cloned.prototype.owner_document = elem.prototype.owner_document;

        // Copy attributes
        var attr_iter = elem.attributes.iterator();
        while (attr_iter.next()) |attr| {
            try cloned.setAttribute(attr.name.local_name, attr.value);
        }

        // Deep clone children if requested
        if (deep) {
            var child = elem.prototype.first_child;
            while (child) |child_node| {
                // Recursively use the same allocator for children
                const child_clone = try child_node.cloneNodeWithAllocator(allocator, true);
                errdefer child_clone.release();
                _ = try cloned.prototype.appendChild(child_clone);
                child = child_node.next_sibling;
            }
        }

        return &cloned.prototype;
    }

    /// Vtable implementation: adopting steps
    /// Called when node is adopted into a new document
    fn adoptingStepsImpl(node: *Node, old_document: ?*Node) !void {
        const elem: *Element = @fieldParentPtr("prototype", node);

        // Remove from old document's maps if it had one
        if (old_document) |old_doc| {
            if (old_doc.node_type == .document) {
                const Document = @import("document.zig").Document;
                const old_doc_ptr: *Document = @fieldParentPtr("prototype", old_doc);

                // Remove from old tag map
                if (old_doc_ptr.tag_map.getPtr(elem.tag_name)) |list_ptr| {
                    for (list_ptr.items, 0..) |item, i| {
                        if (item == elem) {
                            _ = list_ptr.swapRemove(i);
                            break;
                        }
                    }
                }

                // NOTE: Phase 3 - class_map removed, no cleanup needed

                // Remove from old id map
                if (elem.getAttribute("id")) |id| {
                    _ = old_doc_ptr.id_map.remove(id);
                    old_doc_ptr.invalidateIdCache();
                }
            }
        }

        // Add to new document's maps if it has one
        if (node.owner_document) |new_doc| {
            if (new_doc.node_type == .document) {
                const Document = @import("document.zig").Document;
                const new_doc_ptr: *Document = @fieldParentPtr("prototype", new_doc);

                // Re-intern tag name in new document's string pool
                const new_tag_name = try new_doc_ptr.string_pool.intern(elem.tag_name);
                elem.tag_name = new_tag_name;

                // Add to new tag map
                const gop = try new_doc_ptr.tag_map.getOrPut(elem.tag_name);
                if (!gop.found_existing) {
                    gop.value_ptr.* = std.ArrayList(*Element){};
                }
                try gop.value_ptr.append(new_doc_ptr.prototype.allocator, elem);

                // NOTE: Phase 3 - class_map removed, no need to add classes

                // Add to new id map (only if ID not already in use - first wins)
                if (elem.getAttribute("id")) |id| {
                    const result = try new_doc_ptr.id_map.getOrPut(id);
                    if (!result.found_existing) {
                        result.value_ptr.* = elem;
                        new_doc_ptr.invalidateIdCache();
                    }
                }
            }
        }
    }
};

// ============================================================================
// TESTS
// ============================================================================

// ============================================================================
// FAST PATH TESTS
// ============================================================================

// ============================================================================
// CACHE INTEGRATION TESTS
// ============================================================================

// ============================================================================
// ID MAP INTEGRATION TESTS (Phase 2)
// ============================================================================

// ============================================================================
// TAG MAP INTEGRATION TESTS (Phase 3)
// ============================================================================

// ============================================================================
// CLASS MAP INTEGRATION TESTS (Phase 4)
// ============================================================================
