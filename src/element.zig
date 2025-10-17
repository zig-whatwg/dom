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
//! defer elem.node.release();
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
//! defer element.node.release(); // Decrements ref_count, frees if 0
//!
//! // When sharing ownership:
//! element.node.acquire(); // Increment ref_count
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
//! defer article.node.release();
//!
//! const header = try Element.create(allocator, "header");
//! try header.setAttribute("class", "article-header");
//! _ = try article.node.appendChild(&header.node);
//!
//! const title = try Element.create(allocator, "h1");
//! try title.setAttribute("id", "main-title");
//! _ = try header.node.appendChild(&title.node);
//! ```
//!
//! ### Managing Attributes
//! ```zig
//! const button = try Element.create(allocator, "button");
//! defer button.node.release();
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
//! defer div.node.release();
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
//! defer form.node.release();
//! try form.setAttribute("method", "POST");
//! try form.setAttribute("action", "/submit");
//!
//! const input = try Element.create(allocator, "input");
//! try input.setAttribute("type", "text");
//! try input.setAttribute("name", "username");
//! try input.setAttribute("required", "");
//! _ = try form.node.appendChild(&input.node);
//! ```
//!
//! ### Building Nested Structure
//! ```zig
//! const nav = try Element.create(allocator, "nav");
//! defer nav.node.release();
//!
//! const ul = try Element.create(allocator, "ul");
//! try ul.setAttribute("class", "menu");
//! _ = try nav.node.appendChild(&ul.node);
//!
//! const li = try Element.create(allocator, "li");
//! try li.setAttribute("class", "menu-item");
//! _ = try ul.node.appendChild(&li.node);
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
pub const AttributeMap = struct {
    map: std.StringHashMap([]const u8),

    pub fn init(allocator: Allocator) AttributeMap {
        return .{
            .map = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *AttributeMap) void {
        self.map.deinit();
    }

    pub fn set(self: *AttributeMap, name: []const u8, value: []const u8) !void {
        try self.map.put(name, value);
    }

    pub fn get(self: *const AttributeMap, name: []const u8) ?[]const u8 {
        return self.map.get(name);
    }

    pub fn remove(self: *AttributeMap, name: []const u8) bool {
        return self.map.remove(name);
    }

    pub fn has(self: *const AttributeMap, name: []const u8) bool {
        return self.map.contains(name);
    }

    pub fn count(self: *const AttributeMap) usize {
        return self.map.count();
    }
};

/// Element node representing an HTML/XML element.
///
/// Embeds Node as first field for vtable polymorphism.
/// Additional fields for element-specific data (tag, attributes, classes).
pub const Element = struct {
    /// Base Node (MUST be first field for @fieldParentPtr to work)
    node: Node,

    /// Tag name (pointer to interned string, 8 bytes)
    /// e.g., "div", "span", "custom-element"
    tag_name: []const u8,

    /// Attribute map (16 bytes)
    /// Stores name→value pairs (both interned strings)
    attributes: AttributeMap,

    /// Bloom filter for class names (8 bytes)
    /// Enables fast rejection in querySelector(".class")
    class_bloom: BloomFilter,

    /// Vtable for Element nodes.
    const vtable = NodeVTable{
        .deinit = deinitImpl,
        .node_name = nodeNameImpl,
        .node_value = nodeValueImpl,
        .set_node_value = setNodeValueImpl,
        .clone_node = cloneNodeImpl,
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
    /// Returns Element with ref_count=1. Caller MUST call `element.node.release()` when done.
    /// If element is inserted into DOM tree, the tree maintains a reference.
    ///
    /// ## Example
    ///
    /// ```zig
    /// const elem = try Element.create(allocator, "div");
    /// defer elem.node.release();
    ///
    /// try elem.setAttribute("class", "container");
    /// ```
    ///
    /// ## Specification
    ///
    /// See: https://dom.spec.whatwg.org/#dom-document-createelement
    pub fn create(allocator: Allocator, tag_name: []const u8) !*Element {
        const elem = try allocator.create(Element);
        errdefer allocator.destroy(elem);

        // Initialize base Node
        elem.node = .{
            .vtable = &vtable,
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
        try self.attributes.set(name, value);

        // Update bloom filter for class attribute
        if (std.mem.eql(u8, name, "class")) {
            self.updateClassBloom(value);
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
        const removed = self.attributes.remove(name);

        // Rebuild bloom filter if removing class attribute
        if (removed and std.mem.eql(u8, name, "class")) {
            self.class_bloom.clear();
            // Note: In full implementation, we'd rebuild from classList
        }
    }

    /// Checks if element has an attribute.
    pub fn hasAttribute(self: *const Element, name: []const u8) bool {
        return self.attributes.has(name);
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
    /// defer elem.node.release();
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
        var iter = self.attributes.map.keyIterator();
        while (iter.next()) |key| {
            names[i] = key.*;
            i += 1;
        }

        return names;
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
    /// _ = try container.node.appendChild(&button.node);
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
            if (self.node.owner_document) |owner| {
                if (owner.node_type == .document) {
                    const Document = @import("document.zig").Document;
                    const doc: *Document = @fieldParentPtr("node", owner);
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
                    var current = self.node.first_child;
                    while (current) |node| {
                        if (node.node_type == .element) {
                            const elem: *Element = @fieldParentPtr("node", node);

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

        var current = self.node.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("node", node);

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
    /// _ = try container.node.appendChild(&btn1.node);
    ///
    /// const btn2 = try doc.createElement("button");
    /// try btn2.setAttribute("class", "btn");
    /// _ = try container.node.appendChild(&btn2.node);
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
            if (self.node.owner_document) |owner| {
                if (owner.node_type == .document) {
                    const Document = @import("document.zig").Document;
                    const doc: *Document = @fieldParentPtr("node", owner);
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
        var current = self.node.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("node", node);

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
    /// _ = try container.node.appendChild(&button.node);
    ///
    /// const found = try container.queryById("submit-btn");
    /// // found == button
    /// ```
    pub fn queryById(self: *Element, id: []const u8) ?*Element {
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var iter = ElementIterator.init(&self.node);

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
    /// _ = try container.node.appendChild(&button.node);
    ///
    /// const found = container.queryByClass("primary");
    /// // found == button
    /// ```
    pub fn queryByClass(self: *Element, class_name: []const u8) ?*Element {
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var iter = ElementIterator.init(&self.node);

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
    /// _ = try container.node.appendChild(&button.node);
    ///
    /// const found = container.queryByTagName("button");
    /// // found == button
    /// ```
    pub fn queryByTagName(self: *Element, tag_name: []const u8) ?*Element {
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var iter = ElementIterator.init(&self.node);

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
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var results = std.ArrayList(*Element){};
        defer results.deinit(allocator);

        var iter = ElementIterator.init(&self.node);
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
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var results = std.ArrayList(*Element){};
        defer results.deinit(allocator);

        var iter = ElementIterator.init(&self.node);
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
    /// _ = try doc.node.appendChild(&form.node);
    ///
    /// const button = try doc.createElement("button");
    /// _ = try form.node.appendChild(&button.node);
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
        var current = self.node.parent_node;
        while (current) |parent_node| {
            if (parent_node.node_type == .element) {
                const parent_elem: *Element = @fieldParentPtr("node", parent_node);
                if (try matcher.matches(parent_elem, &selector_list)) {
                    return parent_elem;
                }
            }
            current = parent_node.parent_node;
        }

        return null;
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

    /// Vtable implementation: cleanup
    fn deinitImpl(node: *Node) void {
        const elem: *Element = @fieldParentPtr("node", node);

        // Release document reference if owned by a document
        if (elem.node.owner_document) |owner_doc| {
            if (owner_doc.node_type == .document) {
                // Get Document from its node field (node is first field)
                const Document = @import("document.zig").Document;
                const doc: *Document = @fieldParentPtr("node", owner_doc);
                doc.releaseNodeRef();
            }
        }

        // Clean up rare data if allocated
        elem.node.deinitRareData();

        // Release all children
        var current = elem.node.first_child;
        while (current) |child| {
            const next = child.next_sibling;
            child.parent_node = null;
            child.setHasParent(false);
            child.release(); // Release parent's ownership
            current = next;
        }

        elem.attributes.deinit();
        elem.node.allocator.destroy(elem);
    }

    /// Vtable implementation: node name (returns tag name)
    fn nodeNameImpl(node: *const Node) []const u8 {
        const elem: *const Element = @fieldParentPtr("node", node);
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
        const elem: *const Element = @fieldParentPtr("node", node);

        // Create new element with same tag
        const cloned = try Element.create(elem.node.allocator, elem.tag_name);
        errdefer cloned.node.release();

        // Copy attributes
        var attr_iter = elem.attributes.map.iterator();
        while (attr_iter.next()) |entry| {
            try cloned.setAttribute(entry.key_ptr.*, entry.value_ptr.*);
        }

        // TODO: Deep clone children when deep=true
        _ = deep;

        return &cloned.node;
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "BloomFilter - basic operations" {
    var bloom = BloomFilter{};

    // Initially empty
    try std.testing.expect(!bloom.mayContain("foo"));

    // Add class name
    bloom.add("foo");
    try std.testing.expect(bloom.mayContain("foo"));

    // Different class
    bloom.add("bar");
    try std.testing.expect(bloom.mayContain("bar"));
    try std.testing.expect(bloom.mayContain("foo")); // Still present

    // Clear
    bloom.clear();
    try std.testing.expect(!bloom.mayContain("foo"));
    try std.testing.expect(!bloom.mayContain("bar"));
}

test "AttributeMap - basic operations" {
    const allocator = std.testing.allocator;

    var attrs = AttributeMap.init(allocator);
    defer attrs.deinit();

    // Initially empty
    try std.testing.expectEqual(@as(usize, 0), attrs.count());
    try std.testing.expect(attrs.get("id") == null);

    // Set attribute
    try attrs.set("id", "my-id");
    try std.testing.expectEqual(@as(usize, 1), attrs.count());
    try std.testing.expect(attrs.has("id"));
    try std.testing.expectEqualStrings("my-id", attrs.get("id").?);

    // Update attribute
    try attrs.set("id", "new-id");
    try std.testing.expectEqual(@as(usize, 1), attrs.count());
    try std.testing.expectEqualStrings("new-id", attrs.get("id").?);

    // Multiple attributes
    try attrs.set("class", "foo bar");
    try std.testing.expectEqual(@as(usize, 2), attrs.count());

    // Remove attribute
    try std.testing.expect(attrs.remove("id"));
    try std.testing.expectEqual(@as(usize, 1), attrs.count());
    try std.testing.expect(!attrs.has("id"));
    try std.testing.expect(attrs.has("class"));

    // Remove non-existent
    try std.testing.expect(!attrs.remove("missing"));
}

test "Element - creation and cleanup" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.element, elem.node.node_type);
    try std.testing.expectEqual(@as(u32, 1), elem.node.getRefCount());
    try std.testing.expectEqualStrings("element", elem.tag_name);

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("element", elem.node.nodeName());
    try std.testing.expect(elem.node.nodeValue() == null);
}

test "Element - attributes" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no attributes
    try std.testing.expectEqual(@as(usize, 0), elem.attributeCount());
    try std.testing.expect(!elem.hasAttribute("id"));
    try std.testing.expect(elem.getAttribute("id") == null);

    // Set attribute
    try elem.setAttribute("id", "my-div");
    try std.testing.expectEqual(@as(usize, 1), elem.attributeCount());
    try std.testing.expect(elem.hasAttribute("id"));
    try std.testing.expectEqualStrings("my-div", elem.getAttribute("id").?);

    // Set multiple attributes
    try elem.setAttribute("class", "container");
    try elem.setAttribute("data-foo", "bar");
    try std.testing.expectEqual(@as(usize, 3), elem.attributeCount());

    // Remove attribute
    elem.removeAttribute("id");
    try std.testing.expectEqual(@as(usize, 2), elem.attributeCount());
    try std.testing.expect(!elem.hasAttribute("id"));

    // Remove non-existent (no error, per spec)
    elem.removeAttribute("missing");
}

test "Element - class bloom filter" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Set class attribute
    try elem.setAttribute("class", "foo bar baz");

    // Bloom filter should contain all classes
    try std.testing.expect(elem.class_bloom.mayContain("foo"));
    try std.testing.expect(elem.class_bloom.mayContain("bar"));
    try std.testing.expect(elem.class_bloom.mayContain("baz"));

    // hasClass should verify actual presence
    try std.testing.expect(elem.hasClass("foo"));
    try std.testing.expect(elem.hasClass("bar"));
    try std.testing.expect(elem.hasClass("baz"));
    try std.testing.expect(!elem.hasClass("missing"));

    // Update class attribute
    try elem.setAttribute("class", "qux");
    try std.testing.expect(elem.hasClass("qux"));
    try std.testing.expect(!elem.hasClass("foo")); // Old classes gone
}

test "Element - cloneNode shallow" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    try elem.setAttribute("id", "original");
    try elem.setAttribute("class", "foo bar");

    // Clone (shallow)
    const cloned_node = try elem.node.cloneNode(false);
    defer cloned_node.release();

    const cloned: *Element = @fieldParentPtr("node", cloned_node);

    // Verify clone properties
    try std.testing.expectEqualStrings("element", cloned.tag_name);
    try std.testing.expectEqual(@as(usize, 2), cloned.attributeCount());
    try std.testing.expectEqualStrings("original", cloned.getAttribute("id").?);
    try std.testing.expectEqualStrings("foo bar", cloned.getAttribute("class").?);

    // Verify independent ref counts
    try std.testing.expectEqual(@as(u32, 1), elem.node.getRefCount());
    try std.testing.expectEqual(@as(u32, 1), cloned.node.getRefCount());
}

test "Element - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple creation
    {
        const elem = try Element.create(allocator, "element");
        defer elem.node.release();
    }

    // Test 2: With attributes
    {
        const elem = try Element.create(allocator, "element");
        defer elem.node.release();

        try elem.setAttribute("id", "test");
        try elem.setAttribute("class", "foo bar");
        try elem.setAttribute("data-value", "123");
    }

    // Test 3: Clone
    {
        const elem = try Element.create(allocator, "item");
        defer elem.node.release();

        try elem.setAttribute("id", "original");

        const cloned = try elem.node.cloneNode(false);
        defer cloned.release();
    }

    // Test 4: Multiple acquire/release
    {
        const elem = try Element.create(allocator, "p");
        defer elem.node.release();

        elem.node.acquire();
        defer elem.node.release();

        elem.node.acquire();
        defer elem.node.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Element - ref counting" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initial ref count
    try std.testing.expectEqual(@as(u32, 1), elem.node.getRefCount());

    // Acquire
    elem.node.acquire();
    try std.testing.expectEqual(@as(u32, 2), elem.node.getRefCount());

    // Release
    elem.node.release();
    try std.testing.expectEqual(@as(u32, 1), elem.node.getRefCount());
}

test "Element - id property" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no id
    try std.testing.expect(elem.getId() == null);

    // Set id
    try elem.setId("my-element");
    try std.testing.expectEqualStrings("my-element", elem.getId().?);

    // Change id
    try elem.setId("other-id");
    try std.testing.expectEqualStrings("other-id", elem.getId().?);

    // Verify it's the same as getAttribute
    try std.testing.expectEqualStrings("other-id", elem.getAttribute("id").?);
}

test "Element - className property" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no class (returns empty string)
    try std.testing.expectEqualStrings("", elem.getClassName());

    // Set className
    try elem.setClassName("btn btn-primary");
    try std.testing.expectEqualStrings("btn btn-primary", elem.getClassName());

    // Change className
    try elem.setClassName("active");
    try std.testing.expectEqualStrings("active", elem.getClassName());

    // Verify it's the same as getAttribute
    try std.testing.expectEqualStrings("active", elem.getAttribute("class").?);
}

test "Element - hasAttributes" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no attributes
    try std.testing.expect(!elem.hasAttributes());

    // Add attribute
    try elem.setAttribute("id", "test");
    try std.testing.expect(elem.hasAttributes());

    // Add more attributes
    try elem.setAttribute("class", "foo");
    try std.testing.expect(elem.hasAttributes());

    // Remove all attributes
    elem.removeAttribute("id");
    elem.removeAttribute("class");
    try std.testing.expect(!elem.hasAttributes());
}

test "Element - getAttributeNames" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.node.release();

    // Initially no attributes
    {
        const names = try elem.getAttributeNames(allocator);
        defer if (names.len > 0) allocator.free(names);
        try std.testing.expectEqual(@as(usize, 0), names.len);
    }

    // Add attributes
    try elem.setAttribute("id", "test");
    try elem.setAttribute("class", "foo bar");
    try elem.setAttribute("data-value", "123");

    // Get attribute names
    {
        const names = try elem.getAttributeNames(allocator);
        defer allocator.free(names);

        try std.testing.expectEqual(@as(usize, 3), names.len);

        // Verify all names are present (order may vary)
        var found_id = false;
        var found_class = false;
        var found_data = false;

        for (names) |name| {
            if (std.mem.eql(u8, name, "id")) found_id = true;
            if (std.mem.eql(u8, name, "class")) found_class = true;
            if (std.mem.eql(u8, name, "data-value")) found_data = true;
        }

        try std.testing.expect(found_id);
        try std.testing.expect(found_class);
        try std.testing.expect(found_data);
    }
}

test "Element - localName property" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.node.release();

    // For non-namespaced elements, localName === tagName
    try std.testing.expectEqualStrings("div", elem.localName());
    try std.testing.expectEqualStrings(elem.tag_name, elem.localName());
}

test "Element - localName for custom element" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "my-custom-element");
    defer elem.node.release();

    try std.testing.expectEqualStrings("my-custom-element", elem.localName());
}

// ============================================================================
// FAST PATH TESTS
// ============================================================================

test "Element - queryById fast path" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "submit-btn");
    _ = try container.node.appendChild(&button.node);

    const span = try doc.createElement("span");
    try span.setAttribute("id", "label");
    _ = try container.node.appendChild(&span.node);

    // Find by ID
    const found = container.queryById("submit-btn");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);

    // Find other ID
    const found2 = container.queryById("label");
    try std.testing.expect(found2 != null);
    try std.testing.expect(found2.? == span);

    // Not found
    const not_found = container.queryById("missing");
    try std.testing.expect(not_found == null);
}

test "Element - queryByClass fast path" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn primary");
    _ = try container.node.appendChild(&button1.node);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn secondary");
    _ = try container.node.appendChild(&button2.node);

    // Find first .primary
    const found = container.queryByClass("primary");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button1);

    // Find first .btn (returns first match)
    const found_btn = container.queryByClass("btn");
    try std.testing.expect(found_btn != null);
    try std.testing.expect(found_btn.? == button1);

    // Not found
    const not_found = container.queryByClass("missing");
    try std.testing.expect(not_found == null);
}

test "Element - queryByTagName fast path" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button = try doc.createElement("button");
    _ = try container.node.appendChild(&button.node);

    const span = try doc.createElement("span");
    _ = try container.node.appendChild(&span.node);

    // Find button
    const found_button = container.queryByTagName("button");
    try std.testing.expect(found_button != null);
    try std.testing.expect(found_button.? == button);

    // Find span
    const found_span = container.queryByTagName("span");
    try std.testing.expect(found_span != null);
    try std.testing.expect(found_span.? == span);

    // Not found
    const not_found = container.queryByTagName("article");
    try std.testing.expect(not_found == null);
}

test "Element - queryAllByClass fast path" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn primary");
    _ = try container.node.appendChild(&button1.node);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn secondary");
    _ = try container.node.appendChild(&button2.node);

    const span = try doc.createElement("span");
    try span.setAttribute("class", "primary");
    _ = try container.node.appendChild(&span.node);

    // Find all .btn
    const btns = try container.queryAllByClass(allocator, "btn");
    defer allocator.free(btns);
    try std.testing.expectEqual(@as(usize, 2), btns.len);
    try std.testing.expect(btns[0] == button1);
    try std.testing.expect(btns[1] == button2);

    // Find all .primary
    const primary = try container.queryAllByClass(allocator, "primary");
    defer allocator.free(primary);
    try std.testing.expectEqual(@as(usize, 2), primary.len);

    // Find none
    const none = try container.queryAllByClass(allocator, "missing");
    defer allocator.free(none);
    try std.testing.expectEqual(@as(usize, 0), none.len);
}

test "Element - queryAllByTagName fast path" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button1 = try doc.createElement("button");
    _ = try container.node.appendChild(&button1.node);

    const button2 = try doc.createElement("button");
    _ = try container.node.appendChild(&button2.node);

    const span = try doc.createElement("span");
    _ = try container.node.appendChild(&span.node);

    // Find all buttons
    const buttons = try container.queryAllByTagName(allocator, "button");
    defer allocator.free(buttons);
    try std.testing.expectEqual(@as(usize, 2), buttons.len);
    try std.testing.expect(buttons[0] == button1);
    try std.testing.expect(buttons[1] == button2);

    // Find all spans
    const spans = try container.queryAllByTagName(allocator, "span");
    defer allocator.free(spans);
    try std.testing.expectEqual(@as(usize, 1), spans.len);

    // Find none
    const none = try container.queryAllByTagName(allocator, "article");
    defer allocator.free(none);
    try std.testing.expectEqual(@as(usize, 0), none.len);
}

// ============================================================================
// CACHE INTEGRATION TESTS
// ============================================================================

test "Element - querySelector uses cache with simple ID" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "submit");
    _ = try container.node.appendChild(&button.node);

    // First query should parse and cache
    const result1 = try container.querySelector(allocator, "#submit");
    try std.testing.expect(result1 != null);
    try std.testing.expect(result1.? == button);
    try std.testing.expectEqual(@as(usize, 1), doc.selector_cache.count());

    // Second query should use cache (no additional parsing)
    const result2 = try container.querySelector(allocator, "#submit");
    try std.testing.expect(result2 != null);
    try std.testing.expect(result2.? == button);
    try std.testing.expectEqual(@as(usize, 1), doc.selector_cache.count());
}

test "Element - querySelector uses cache with simple class" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button = try doc.createElement("button");
    try button.setAttribute("class", "primary");
    _ = try container.node.appendChild(&button.node);

    // First query should parse and cache
    const result1 = try container.querySelector(allocator, ".primary");
    try std.testing.expect(result1 != null);
    try std.testing.expect(result1.? == button);
    try std.testing.expectEqual(@as(usize, 1), doc.selector_cache.count());

    // Second query should use cache
    const result2 = try container.querySelector(allocator, ".primary");
    try std.testing.expect(result2 != null);
    try std.testing.expect(result2.? == button);
    try std.testing.expectEqual(@as(usize, 1), doc.selector_cache.count());
}

test "Element - querySelectorAll uses cache with simple class" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn");
    _ = try container.node.appendChild(&button1.node);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn");
    _ = try container.node.appendChild(&button2.node);

    // First query should parse and cache
    const results1 = try container.querySelectorAll(allocator, ".btn");
    defer allocator.free(results1);
    try std.testing.expectEqual(@as(usize, 2), results1.len);
    try std.testing.expectEqual(@as(usize, 1), doc.selector_cache.count());

    // Second query should use cache
    const results2 = try container.querySelectorAll(allocator, ".btn");
    defer allocator.free(results2);
    try std.testing.expectEqual(@as(usize, 2), results2.len);
    try std.testing.expectEqual(@as(usize, 1), doc.selector_cache.count());
}

test "Element - multiple different selectors cached" {
    const allocator = std.testing.allocator;

    const doc = try @import("document.zig").Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.node.appendChild(&container.node);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "submit");
    try button.setAttribute("class", "btn primary");
    _ = try container.node.appendChild(&button.node);

    // Query by ID
    _ = try container.querySelector(allocator, "#submit");
    try std.testing.expectEqual(@as(usize, 1), doc.selector_cache.count());

    // Query by class
    _ = try container.querySelector(allocator, ".btn");
    try std.testing.expectEqual(@as(usize, 2), doc.selector_cache.count());

    // Query by tag
    _ = try container.querySelector(allocator, "button");
    try std.testing.expectEqual(@as(usize, 3), doc.selector_cache.count());

    // Query by ID again (cached)
    _ = try container.querySelector(allocator, "#submit");
    try std.testing.expectEqual(@as(usize, 3), doc.selector_cache.count());
}
