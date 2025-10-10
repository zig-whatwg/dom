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
//! - Element.classList: https://developer.mozilla.org/en-US/docs/Web/API/Element/classList
//! - Element.querySelector: https://developer.mozilla.org/en-US/docs/Web/API/Element/querySelector
//!
//! ## Core Features
//!
//! ### Attributes Management
//! Elements can have named attributes that provide metadata:
//! ```zig
//! const element = try Element.create(allocator, "input");
//! try Element.setAttribute(element, "type", "text");
//! try Element.setAttribute(element, "placeholder", "Enter name");
//! const type_attr = Element.getAttribute(element, "type"); // "text"
//! ```
//!
//! ### Class List Management
//! The `class` attribute is special and gets automatic classList synchronization:
//! ```zig
//! try Element.setClassName(element, "btn btn-primary active");
//! const data = Element.getData(element);
//! // data.class_list contains: ["btn", "btn-primary", "active"]
//! // class attribute also set to "btn btn-primary active"
//! ```
//!
//! ### DOM Traversal
//! Navigate the element tree efficiently:
//! ```zig
//! const first = Element.getFirstElementChild(parent); // Skip text nodes
//! const last = Element.getLastElementChild(parent);
//! const count = Element.getChildElementCount(parent);
//! ```
//!
//! ### CSS Selector Matching
//! Use CSS selectors to find elements:
//! ```zig
//! // Find first match
//! const button = try Element.querySelector(root, "button.submit");
//!
//! // Find all matches
//! const list = try Element.querySelectorAll(root, ".item");
//! defer { list.deinit(); allocator.destroy(list); }
//! ```
//!
//! ### Legacy Methods
//! Also supports legacy DOM methods:
//! ```zig
//! const elem = Element.getElementById(root, "myid");
//!
//! var list = NodeList.init(allocator);
//! try Element.getElementsByTagName(root, "div", &list);
//! try Element.getElementsByClassName(root, "highlight", &list);
//! ```
//!
//! ## Element Data Structure
//!
//! Each element stores:
//! - **tag_name**: Uppercased element tag (e.g., "DIV", "SPAN")
//! - **attributes**: NamedNodeMap of attribute name-value pairs
//! - **class_list**: DOMTokenList automatically synced with class attribute
//!
//! ## Memory Management
//!
//! Elements use reference counting through the Node interface:
//! ```zig
//! const element = try Element.create(allocator, "div");
//! defer element.release(); // Decrements ref count, frees if 0
//! ```
//!
//! When an element is released:
//! 1. Tag name string is freed
//! 2. All attributes are freed
//! 3. Class list is freed
//! 4. Node base is freed
//!
//! ## Common Patterns
//!
//! ### Building a DOM Tree
//! ```zig
//! const article = try Element.create(allocator, "article");
//! defer article.release();
//!
//! const header = try Element.create(allocator, "header");
//! try Element.setClassName(header, "article-header");
//! _ = try article.appendChild(header);
//!
//! const title = try Element.create(allocator, "h1");
//! try Element.setAttribute(title, "id", "main-title");
//! _ = try header.appendChild(title);
//! ```
//!
//! ### Finding Elements
//! ```zig
//! // By ID (fastest)
//! if (Element.getElementById(root, "user-profile")) |profile| {
//!     // Found the profile element
//! }
//!
//! // By CSS selector (flexible)
//! if (try Element.querySelector(root, "nav > ul.menu")) |menu| {
//!     // Found navigation menu
//! }
//!
//! // By class name (specific use case)
//! var items = NodeList.init(allocator);
//! defer items.deinit();
//! try Element.getElementsByClassName(root, "list-item selected", &items);
//! ```
//!
//! ### Dynamic Attributes
//! ```zig
//! // Toggle boolean attributes
//! _ = try Element.toggleAttribute(button, "disabled", null);
//!
//! // Get all attribute names
//! const names = try Element.getAttributeNames(element, allocator);
//! defer allocator.free(names);
//! for (names) |name| {
//!     const value = Element.getAttribute(element, name);
//! }
//! ```
//!
//! ## Performance Tips
//!
//! 1. **getElementById** is faster than querySelector for single elements
//! 2. **querySelector** stops at first match (good for single elements)
//! 3. **querySelectorAll** traverses entire tree (use specific selectors)
//! 4. **Class list operations** are automatically synced with class attribute
//! 5. **Tag names** are stored uppercase for case-insensitive matching

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;
const NamedNodeMap = @import("named_node_map.zig").NamedNodeMap;
const Attr = @import("named_node_map.zig").Attr;
const DOMTokenList = @import("dom_token_list.zig").DOMTokenList;
const NodeList = @import("node_list.zig").NodeList;
const selector = @import("selector.zig");

/// Element Data
///
/// Internal data structure storing element-specific information.
/// Each element node has an associated ElementData instance.
///
/// ## Fields
///
/// - `tag_name`: Uppercased element tag name (e.g., "DIV", "SPAN")
/// - `attributes`: NamedNodeMap of element attributes
/// - `class_list`: DOMTokenList synchronized with class attribute
///
/// ## Memory Layout
///
/// Tag name is heap-allocated and uppercased for case-insensitive matching.
/// Attributes and class list manage their own memory.
pub const ElementData = struct {
    tag_name: []const u8,
    attributes: NamedNodeMap,
    class_list: DOMTokenList,

    /// Initialize Element Data
    ///
    /// Creates a new ElementData with the specified tag name.
    /// Tag name is automatically uppercased.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator
    /// - `tag_name`: Element tag name (will be uppercased)
    ///
    /// ## Returns
    ///
    /// Initialized ElementData structure.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// var data = try ElementData.init(allocator, "div");
    /// defer data.deinit(allocator);
    /// // data.tag_name === "DIV"
    /// ```
    pub fn init(allocator: std.mem.Allocator, tag_name: []const u8) !ElementData {
        const tag_upper = try std.ascii.allocUpperString(allocator, tag_name);
        return .{
            .tag_name = tag_upper,
            .attributes = NamedNodeMap.init(allocator),
            .class_list = DOMTokenList.init(allocator),
        };
    }

    /// Deinitialize Element Data
    ///
    /// Frees all memory associated with this element data.
    ///
    /// ## Parameters
    ///
    /// - `self`: Element data to deinitialize
    /// - `allocator`: Memory allocator used during init
    pub fn deinit(self: *ElementData, allocator: std.mem.Allocator) void {
        allocator.free(self.tag_name);
        self.attributes.deinit();
        self.class_list.deinit();
    }
};

/// Element
///
/// Namespace for element-related operations.
/// Elements are created as Node objects with ElementData attached.
pub const Element = struct {
    /// Create Element
    ///
    /// Creates a new element node with the specified tag name.
    /// Tag name is automatically uppercased for case-insensitive matching.
    ///
    /// ## Parameters
    ///
    /// - `allocator`: Memory allocator for the element
    /// - `tag_name`: Element tag name (e.g., "div", "span")
    ///
    /// ## Returns
    ///
    /// Pointer to the created element node. Caller must call `release()`.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// // Create a div element
    /// const div = try Element.create(allocator, "div");
    /// defer div.release();
    ///
    /// // Create input element
    /// const input = try Element.create(allocator, "input");
    /// defer input.release();
    /// try Element.setAttribute(input, "type", "text");
    ///
    /// // Tag names are uppercased
    /// const span = try Element.create(allocator, "span");
    /// defer span.release();
    /// const data = Element.getData(span);
    /// // data.tag_name === "SPAN"
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-document-createelement
    pub fn create(allocator: std.mem.Allocator, tag_name: []const u8) !*Node {
        const element_data_ptr = try allocator.create(ElementData);
        element_data_ptr.* = try ElementData.init(allocator, tag_name);

        const node = try Node.init(allocator, .element_node, element_data_ptr.tag_name);
        node.element_data_ptr = element_data_ptr;

        return node;
    }

    /// Get Element Data
    ///
    /// Retrieves the ElementData structure for a node.
    /// Node must be an element node.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    ///
    /// ## Returns
    ///
    /// Pointer to the element's data.
    ///
    /// ## Safety
    ///
    /// Caller must ensure node is an element node.
    /// Accessing non-element nodes will cause undefined behavior.
    pub fn getData(node: *const Node) *ElementData {
        return @ptrCast(@alignCast(node.element_data_ptr.?));
    }

    /// Get Attribute Value
    ///
    /// Retrieves the value of the specified attribute.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    /// - `name`: Attribute name
    ///
    /// ## Returns
    ///
    /// Attribute value, or `null` if attribute doesn't exist.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "input");
    /// defer element.release();
    ///
    /// try Element.setAttribute(element, "type", "text");
    /// try Element.setAttribute(element, "placeholder", "Enter name");
    ///
    /// const type_attr = Element.getAttribute(element, "type");
    /// // type_attr === "text"
    ///
    /// const missing = Element.getAttribute(element, "disabled");
    /// // missing === null
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-getattribute
    pub fn getAttribute(node: *const Node, name: []const u8) ?[]const u8 {
        const data = getData(node);
        const attr = data.attributes.getNamedItem(name) orelse return null;
        return attr.value;
    }

    /// Set Attribute Value
    ///
    /// Sets the value of the specified attribute.
    /// If the attribute exists, its value is updated.
    /// If the attribute doesn't exist, it is created.
    ///
    /// Special handling for the "class" attribute:
    /// - Automatically updates the classList
    /// - Keeps class attribute and classList in sync
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    /// - `name`: Attribute name
    /// - `value`: Attribute value
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "div");
    /// defer element.release();
    ///
    /// // Set simple attribute
    /// try Element.setAttribute(element, "id", "main");
    ///
    /// // Update existing attribute
    /// try Element.setAttribute(element, "id", "header");
    ///
    /// // Set class attribute (updates classList too)
    /// try Element.setAttribute(element, "class", "container active");
    /// const data = Element.getData(element);
    /// // data.class_list.contains("container") === true
    /// // data.class_list.contains("active") === true
    ///
    /// // Set data attributes
    /// try Element.setAttribute(element, "data-user-id", "123");
    /// try Element.setAttribute(element, "data-role", "admin");
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-setattribute
    pub fn setAttribute(node: *Node, name: []const u8, value: []const u8) !void {
        const data = getData(node);
        if (data.attributes.getNamedItem(name)) |existing| {
            try existing.setValue(value);
        } else {
            const attr = try Attr.init(node.allocator, name, value);
            _ = try data.attributes.setNamedItem(attr);
        }

        // Keep class attribute and classList in sync
        if (std.mem.eql(u8, name, "class")) {
            try data.class_list.setValue(value);
        }
    }

    /// Remove Attribute
    ///
    /// Removes the specified attribute from the element.
    /// If the attribute doesn't exist, this is a no-op.
    ///
    /// Special handling for the "class" attribute:
    /// - Clears the classList when class attribute is removed
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    /// - `name`: Attribute name
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "div");
    /// defer element.release();
    ///
    /// try Element.setAttribute(element, "id", "test");
    /// try Element.setAttribute(element, "hidden", "");
    ///
    /// // Remove attributes
    /// Element.removeAttribute(element, "id");
    /// Element.removeAttribute(element, "hidden");
    ///
    /// // Removing non-existent attribute is safe
    /// Element.removeAttribute(element, "disabled");
    ///
    /// // Remove class attribute (clears classList)
    /// try Element.setAttribute(element, "class", "foo bar");
    /// Element.removeAttribute(element, "class");
    /// const data = Element.getData(element);
    /// // data.class_list.length() === 0
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-removeattribute
    pub fn removeAttribute(node: *Node, name: []const u8) void {
        const data = getData(node);
        if (data.attributes.removeNamedItem(name)) |attr| {
            attr.deinit();
        } else |_| {}

        // Clear classList when class attribute is removed
        if (std.mem.eql(u8, name, "class")) {
            data.class_list.setValue("") catch {};
        }
    }

    /// Has Attribute
    ///
    /// Tests whether an attribute exists on the element.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    /// - `name`: Attribute name
    ///
    /// ## Returns
    ///
    /// `true` if attribute exists, `false` otherwise.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "input");
    /// defer element.release();
    ///
    /// // Initially no attributes
    /// try std.testing.expect(!Element.hasAttribute(element, "disabled"));
    ///
    /// // Add attribute
    /// try Element.setAttribute(element, "disabled", "");
    /// try std.testing.expect(Element.hasAttribute(element, "disabled"));
    ///
    /// // Check boolean attributes
    /// try Element.setAttribute(element, "required", "");
    /// if (Element.hasAttribute(element, "required")) {
    ///     // Field is required
    /// }
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-hasattribute
    pub fn hasAttribute(node: *const Node, name: []const u8) bool {
        const data = getData(node);
        return data.attributes.getNamedItem(name) != null;
    }

    /// Toggle Attribute
    ///
    /// Toggles an attribute, optionally forcing it to a specific state.
    /// If no force value is provided, the attribute is toggled:
    /// - If present, it is removed
    /// - If absent, it is added with empty value
    ///
    /// If force is true, the attribute is always added.
    /// If force is false, the attribute is always removed.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    /// - `name`: Attribute name
    /// - `force`: Optional forced state (true=add, false=remove, null=toggle)
    ///
    /// ## Returns
    ///
    /// `true` if attribute is present after the operation, `false` otherwise.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "button");
    /// defer element.release();
    ///
    /// // Toggle (add if missing, remove if present)
    /// var result = try Element.toggleAttribute(element, "disabled", null);
    /// // result === true, attribute added
    ///
    /// result = try Element.toggleAttribute(element, "disabled", null);
    /// // result === false, attribute removed
    ///
    /// // Force add
    /// result = try Element.toggleAttribute(element, "hidden", true);
    /// // result === true, attribute added
    ///
    /// result = try Element.toggleAttribute(element, "hidden", true);
    /// // result === true, attribute still present
    ///
    /// // Force remove
    /// result = try Element.toggleAttribute(element, "hidden", false);
    /// // result === false, attribute removed
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-toggleattribute
    pub fn toggleAttribute(node: *Node, name: []const u8, force: ?bool) !bool {
        const exists = hasAttribute(node, name);

        if (force) |f| {
            if (f) {
                if (!exists) {
                    try setAttribute(node, name, "");
                }
                return true;
            } else {
                if (exists) {
                    removeAttribute(node, name);
                }
                return false;
            }
        }

        if (exists) {
            removeAttribute(node, name);
            return false;
        } else {
            try setAttribute(node, name, "");
            return true;
        }
    }

    /// Get Attribute Names
    ///
    /// Returns an array of all attribute names on the element.
    /// Memory for the array must be freed by the caller.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    /// - `allocator`: Memory allocator for the array
    ///
    /// ## Returns
    ///
    /// Array of attribute name strings. Caller must free with `allocator.free()`.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "input");
    /// defer element.release();
    ///
    /// try Element.setAttribute(element, "type", "text");
    /// try Element.setAttribute(element, "placeholder", "Enter name");
    /// try Element.setAttribute(element, "required", "");
    ///
    /// const names = try Element.getAttributeNames(element, allocator);
    /// defer allocator.free(names);
    /// // names === ["type", "placeholder", "required"]
    ///
    /// for (names) |name| {
    ///     const value = Element.getAttribute(element, name);
    ///     std.debug.print("{s}={s}\n", .{name, value.?});
    /// }
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-getattributenames
    pub fn getAttributeNames(node: *const Node, allocator: std.mem.Allocator) ![]const []const u8 {
        const data = getData(node);
        var names = try allocator.alloc([]const u8, data.attributes.length());
        for (data.attributes.attrs.items, 0..) |attr, i| {
            names[i] = attr.name;
        }
        return names;
    }

    /// Get Class Name
    ///
    /// Returns the value of the class attribute as a string.
    /// This is the serialized version of the classList.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    ///
    /// ## Returns
    ///
    /// Class attribute value string. Caller must free.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Example
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "div");
    /// defer element.release();
    ///
    /// try Element.setClassName(element, "container active");
    ///
    /// const class_name = try Element.getClassName(element);
    /// defer element.allocator.free(class_name);
    /// // class_name === "container active"
    /// ```
    pub fn getClassName(node: *const Node) ![]const u8 {
        const data = getData(node);
        return try data.class_list.toString(node.allocator);
    }

    /// Set Class Name
    ///
    /// Sets the class attribute and updates the classList.
    /// The class string is parsed into individual class tokens.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    /// - `class_name`: Space-separated class names
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "div");
    /// defer element.release();
    ///
    /// // Set single class
    /// try Element.setClassName(element, "container");
    ///
    /// // Set multiple classes
    /// try Element.setClassName(element, "btn btn-primary active");
    ///
    /// const data = Element.getData(element);
    /// // data.class_list.contains("btn") === true
    /// // data.class_list.contains("btn-primary") === true
    /// // data.class_list.contains("active") === true
    ///
    /// // Also sets class attribute
    /// const class_attr = Element.getAttribute(element, "class");
    /// // class_attr === "btn btn-primary active"
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-classname
    pub fn setClassName(node: *Node, class_name: []const u8) !void {
        const data = getData(node);
        try data.class_list.setValue(class_name);
        try setAttribute(node, "class", class_name);
    }

    /// Get Element By ID
    ///
    /// Searches the subtree for an element with the specified ID.
    /// Search is performed in depth-first, pre-order traversal.
    ///
    /// ## Parameters
    ///
    /// - `node`: Root node to search from (inclusive)
    /// - `id`: ID to search for
    ///
    /// ## Returns
    ///
    /// Element with matching ID, or `null` if not found.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const root = try Element.create(allocator, "div");
    /// defer root.release();
    ///
    /// const child = try Element.create(allocator, "span");
    /// try Element.setAttribute(child, "id", "target");
    /// _ = try root.appendChild(child);
    ///
    /// // Find by ID
    /// const found = Element.getElementById(root, "target");
    /// // found === child
    ///
    /// // Not found returns null
    /// const missing = Element.getElementById(root, "nonexistent");
    /// // missing === null
    /// ```
    ///
    /// ## Performance
    ///
    /// This is faster than querySelector for ID lookups.
    ///
    /// See: https://dom.spec.whatwg.org/#dom-nonelementparentnode-getelementbyid
    pub fn getElementById(node: *const Node, id: []const u8) ?*Node {
        if (node.node_type != .element_node) return null;

        if (getAttribute(node, "id")) |element_id| {
            if (std.mem.eql(u8, element_id, id)) {
                return @constCast(node);
            }
        }

        for (node.child_nodes.items.items) |child_ptr| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (getElementById(child, id)) |found| {
                return found;
            }
        }

        return null;
    }

    /// Get Elements By Tag Name
    ///
    /// Searches the subtree for all elements with the specified tag name.
    /// Tag name matching is case-insensitive.
    /// Use "*" to match all elements.
    ///
    /// ## Parameters
    ///
    /// - `node`: Root node to search from (inclusive)
    /// - `tag_name`: Tag name to search for (case-insensitive) or "*"
    /// - `list`: NodeList to append matching elements to
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const root = try Element.create(allocator, "div");
    /// defer root.release();
    ///
    /// const span1 = try Element.create(allocator, "span");
    /// _ = try root.appendChild(span1);
    ///
    /// const span2 = try Element.create(allocator, "span");
    /// _ = try root.appendChild(span2);
    ///
    /// const para = try Element.create(allocator, "p");
    /// _ = try root.appendChild(para);
    ///
    /// // Find all spans
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    /// try Element.getElementsByTagName(root, "span", &list);
    /// // list.length() === 2
    ///
    /// // Case insensitive
    /// try Element.getElementsByTagName(root, "SPAN", &list);
    /// // Still finds both spans
    ///
    /// // Find all elements
    /// try Element.getElementsByTagName(root, "*", &list);
    /// // list.length() === 4 (root + 3 children)
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-getelementsbytagname
    pub fn getElementsByTagName(node: *const Node, tag_name: []const u8, list: *NodeList) !void {
        if (node.node_type != .element_node) return;

        const data = getData(node);
        const tag_upper = try std.ascii.allocUpperString(node.allocator, tag_name);
        defer node.allocator.free(tag_upper);

        if (std.mem.eql(u8, data.tag_name, tag_upper) or std.mem.eql(u8, tag_name, "*")) {
            try list.append(@constCast(node));
        }

        for (node.child_nodes.items.items) |child_ptr| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            try getElementsByTagName(child, tag_name, list);
        }
    }

    /// Get Elements By Class Name
    ///
    /// Searches the subtree for all elements with the specified class names.
    /// If multiple class names are provided (space-separated), all must match.
    ///
    /// ## Parameters
    ///
    /// - `node`: Root node to search from (inclusive)
    /// - `class_names`: Space-separated class names (all must match)
    /// - `list`: NodeList to append matching elements to
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const root = try Element.create(allocator, "div");
    /// defer root.release();
    ///
    /// const elem1 = try Element.create(allocator, "div");
    /// try Element.setClassName(elem1, "item active");
    /// _ = try root.appendChild(elem1);
    ///
    /// const elem2 = try Element.create(allocator, "div");
    /// try Element.setClassName(elem2, "item");
    /// _ = try root.appendChild(elem2);
    ///
    /// const elem3 = try Element.create(allocator, "div");
    /// try Element.setClassName(elem3, "active");
    /// _ = try root.appendChild(elem3);
    ///
    /// var list = NodeList.init(allocator);
    /// defer list.deinit();
    ///
    /// // Find elements with "item" class
    /// try Element.getElementsByClassName(root, "item", &list);
    /// // list.length() === 2 (elem1, elem2)
    ///
    /// // Find elements with both "item" AND "active"
    /// try Element.getElementsByClassName(root, "item active", &list);
    /// // list.length() === 1 (only elem1)
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-getelementsbyclassname
    pub fn getElementsByClassName(node: *const Node, class_names: []const u8, list: *NodeList) !void {
        if (node.node_type != .element_node) return;

        const data = getData(node);
        var iter = std.mem.tokenizeAny(u8, class_names, &std.ascii.whitespace);
        var all_match = true;

        while (iter.next()) |class_name| {
            if (!data.class_list.contains(class_name)) {
                all_match = false;
                break;
            }
        }

        if (all_match and class_names.len > 0) {
            try list.append(@constCast(node));
        }

        for (node.child_nodes.items.items) |child_ptr| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            try getElementsByClassName(child, class_names, list);
        }
    }

    /// Get First Element Child
    ///
    /// Returns the first child node that is an element.
    /// Text nodes and other non-element nodes are skipped.
    ///
    /// ## Parameters
    ///
    /// - `node`: Parent node
    ///
    /// ## Returns
    ///
    /// First element child, or `null` if no element children.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// defer parent.release();
    ///
    /// // Add text node (ignored)
    /// const text = try Node.init(allocator, .text_node, "#text");
    /// _ = try parent.appendChild(text);
    ///
    /// // Add element children
    /// const child1 = try Element.create(allocator, "span");
    /// _ = try parent.appendChild(child1);
    ///
    /// const child2 = try Element.create(allocator, "p");
    /// _ = try parent.appendChild(child2);
    ///
    /// const first = Element.getFirstElementChild(parent);
    /// // first === child1 (text node was skipped)
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-parentnode-firstelementchild
    pub fn getFirstElementChild(node: *const Node) ?*Node {
        for (node.child_nodes.items.items) |child_ptr| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (child.node_type == .element_node) {
                return child;
            }
        }
        return null;
    }

    /// Get Last Element Child
    ///
    /// Returns the last child node that is an element.
    /// Text nodes and other non-element nodes are skipped.
    ///
    /// ## Parameters
    ///
    /// - `node`: Parent node
    ///
    /// ## Returns
    ///
    /// Last element child, or `null` if no element children.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Element.create(allocator, "span");
    /// _ = try parent.appendChild(child1);
    ///
    /// const child2 = try Element.create(allocator, "p");
    /// _ = try parent.appendChild(child2);
    ///
    /// // Add text node (ignored)
    /// const text = try Node.init(allocator, .text_node, "#text");
    /// _ = try parent.appendChild(text);
    ///
    /// const last = Element.getLastElementChild(parent);
    /// // last === child2 (text node was skipped)
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-parentnode-lastelementchild
    pub fn getLastElementChild(node: *const Node) ?*Node {
        var i = node.child_nodes.length();
        while (i > 0) {
            i -= 1;
            const child_ptr = node.child_nodes.item(i) orelse continue;
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (child.node_type == .element_node) {
                return child;
            }
        }
        return null;
    }

    /// Get Child Element Count
    ///
    /// Returns the number of element children.
    /// Text nodes and other non-element nodes are not counted.
    ///
    /// ## Parameters
    ///
    /// - `node`: Parent node
    ///
    /// ## Returns
    ///
    /// Number of element children.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "ul");
    /// defer parent.release();
    ///
    /// const item1 = try Element.create(allocator, "li");
    /// _ = try parent.appendChild(item1);
    ///
    /// const text = try Node.init(allocator, .text_node, " ");
    /// _ = try parent.appendChild(text);
    ///
    /// const item2 = try Element.create(allocator, "li");
    /// _ = try parent.appendChild(item2);
    ///
    /// const count = Element.getChildElementCount(parent);
    /// // count === 2 (text node not counted)
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-parentnode-childelementcount
    pub fn getChildElementCount(node: *const Node) usize {
        var count: usize = 0;
        for (node.child_nodes.items.items) |child_ptr| {
            const child: *Node = @ptrCast(@alignCast(child_ptr));
            if (child.node_type == .element_node) {
                count += 1;
            }
        }
        return count;
    }

    /// Matches Selector
    ///
    /// Tests whether the element matches a CSS selector.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node to test
    /// - `selector_str`: CSS selector string
    ///
    /// ## Returns
    ///
    /// `true` if element matches selector, `false` otherwise.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    /// - `error.InvalidSelector`: Malformed selector
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "button");
    /// defer element.release();
    ///
    /// try Element.setAttribute(element, "id", "submit-btn");
    /// try Element.setClassName(element, "btn btn-primary");
    ///
    /// try std.testing.expect(try Element.matches(element, "button"));
    /// try std.testing.expect(try Element.matches(element, "#submit-btn"));
    /// try std.testing.expect(try Element.matches(element, ".btn"));
    /// try std.testing.expect(try Element.matches(element, "button.btn-primary"));
    /// try std.testing.expect(!try Element.matches(element, "input"));
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-matches
    pub fn matches(node: *const Node, selector_str: []const u8) !bool {
        return try selector.matches(node, selector_str, node.allocator);
    }

    /// Query Selector
    ///
    /// Finds the first element in the subtree matching the CSS selector.
    ///
    /// ## Parameters
    ///
    /// - `node`: Root element to search from (inclusive)
    /// - `selector_str`: CSS selector string
    ///
    /// ## Returns
    ///
    /// First matching element, or `null` if no match.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    /// - `error.InvalidSelector`: Malformed selector
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const root = try Element.create(allocator, "div");
    /// defer root.release();
    ///
    /// const header = try Element.create(allocator, "header");
    /// _ = try root.appendChild(header);
    ///
    /// const title = try Element.create(allocator, "h1");
    /// try Element.setAttribute(title, "id", "title");
    /// _ = try header.appendChild(title);
    ///
    /// // Find by ID
    /// const found = try Element.querySelector(root, "#title");
    /// // found === title
    ///
    /// // Find by tag
    /// const h1 = try Element.querySelector(root, "h1");
    /// // h1 === title
    ///
    /// // No match
    /// const none = try Element.querySelector(root, ".nonexistent");
    /// // none === null
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-queryselector
    pub fn querySelector(node: *const Node, selector_str: []const u8) !?*Node {
        return try selector.querySelector(node, selector_str, node.allocator);
    }

    /// Query Selector All
    ///
    /// Finds all elements in the subtree matching the CSS selector.
    /// Returns a new NodeList containing the matches.
    ///
    /// ## Parameters
    ///
    /// - `node`: Root element to search from (inclusive)
    /// - `selector_str`: CSS selector string
    ///
    /// ## Returns
    ///
    /// NodeList of matching elements. Caller must deinit and destroy.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    /// - `error.InvalidSelector`: Malformed selector
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const root = try Element.create(allocator, "ul");
    /// defer root.release();
    ///
    /// const item1 = try Element.create(allocator, "li");
    /// try Element.setClassName(item1, "item");
    /// _ = try root.appendChild(item1);
    ///
    /// const item2 = try Element.create(allocator, "li");
    /// try Element.setClassName(item2, "item selected");
    /// _ = try root.appendChild(item2);
    ///
    /// const item3 = try Element.create(allocator, "li");
    /// _ = try root.appendChild(item3);
    ///
    /// // Find all items
    /// const items = try Element.querySelectorAll(root, ".item");
    /// defer {
    ///     items.deinit();
    ///     allocator.destroy(items);
    /// }
    /// // items.length() === 2
    ///
    /// // Find selected items
    /// const selected = try Element.querySelectorAll(root, ".selected");
    /// defer {
    ///     selected.deinit();
    ///     allocator.destroy(selected);
    /// }
    /// // selected.length() === 1
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-queryselectorall
    pub fn querySelectorAll(node: *const Node, selector_str: []const u8) !*NodeList {
        const list = try node.allocator.create(NodeList);
        list.* = NodeList.init(node.allocator);
        try selector.querySelectorAll(node, selector_str, list, node.allocator);
        return list;
    }

    /// Closest Ancestor Matching Selector
    ///
    /// Traverses the element and its ancestors (heading toward the document root)
    /// until it finds a node that matches the specified CSS selector.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element to start from (inclusive)
    /// - `selector_str`: CSS selector string
    ///
    /// ## Returns
    ///
    /// First matching ancestor element (including self), or `null` if no match.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    /// - `error.InvalidSelector`: Malformed selector
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const article = try Element.create(allocator, "article");
    /// defer article.release();
    /// try Element.setClassName(article, "post");
    ///
    /// const section = try Element.create(allocator, "section");
    /// _ = try article.appendChild(section);
    ///
    /// const para = try Element.create(allocator, "p");
    /// _ = try section.appendChild(para);
    ///
    /// // Find closest article from paragraph
    /// const found = try Element.closest(para, "article.post");
    /// // found === article
    ///
    /// // Element can match itself
    /// const self_match = try Element.closest(article, "article");
    /// // self_match === article
    ///
    /// // No match returns null
    /// const no_match = try Element.closest(para, ".nonexistent");
    /// // no_match === null
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-closest
    pub fn closest(node: *const Node, selector_str: []const u8) !?*Node {
        if (node.node_type != .element_node) return null;

        var current: ?*const Node = node;
        while (current) |elem| {
            if (elem.node_type != .element_node) {
                current = elem.parent_node;
                continue;
            }

            if (try matches(elem, selector_str)) {
                return @constCast(elem);
            }

            current = elem.parent_node;
        }

        return null;
    }

    /// WebKit Matches Selector (Legacy)
    ///
    /// Legacy alias for matches(). Tests whether the element matches a CSS selector.
    /// This method exists for backwards compatibility with older WebKit browsers.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node to test
    /// - `selector_str`: CSS selector string
    ///
    /// ## Returns
    ///
    /// `true` if element matches selector, `false` otherwise.
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    /// - `error.InvalidSelector`: Malformed selector
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const element = try Element.create(allocator, "button");
    /// defer element.release();
    ///
    /// try Element.setAttribute(element, "id", "submit");
    /// try Element.setClassName(element, "btn primary");
    ///
    /// try std.testing.expect(try Element.webkitMatchesSelector(element, "button"));
    /// try std.testing.expect(try Element.webkitMatchesSelector(element, "#submit"));
    /// try std.testing.expect(try Element.webkitMatchesSelector(element, ".btn"));
    /// ```
    ///
    /// ## Note
    ///
    /// This is a legacy method. Use matches() for new code.
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-matches
    pub fn webkitMatchesSelector(node: *const Node, selector_str: []const u8) !bool {
        return try matches(node, selector_str);
    }

    /// Insert Adjacent Element
    ///
    /// Inserts an element at a specified position relative to this element.
    ///
    /// ## Parameters
    ///
    /// - `node`: Reference element
    /// - `where`: Position string - "beforebegin", "afterbegin", "beforeend", "afterend"
    /// - `element`: Element to insert
    ///
    /// ## Returns
    ///
    /// The inserted element, or `null` if insertion failed.
    ///
    /// ## Position Values
    ///
    /// - **beforebegin**: Before this element (as previous sibling)
    /// - **afterbegin**: Just inside this element, before first child
    /// - **beforeend**: Just inside this element, after last child
    /// - **afterend**: After this element (as next sibling)
    ///
    /// ## Errors
    ///
    /// - `error.SyntaxError`: Invalid position string
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// defer parent.release();
    ///
    /// const child1 = try Element.create(allocator, "span");
    /// _ = try parent.appendChild(child1);
    ///
    /// // Insert before parent (requires parent to have a parent)
    /// const root = try Element.create(allocator, "body");
    /// defer root.release();
    /// _ = try root.appendChild(parent);
    ///
    /// const before = try Element.create(allocator, "header");
    /// const result1 = try Element.insertAdjacentElement(parent, "beforebegin", before);
    /// // result1 === before, inserted as previous sibling of parent
    ///
    /// // Insert as first child
    /// const first = try Element.create(allocator, "h1");
    /// const result2 = try Element.insertAdjacentElement(parent, "afterbegin", first);
    /// // result2 === first, inserted before child1
    ///
    /// // Insert as last child
    /// const last = try Element.create(allocator, "footer");
    /// const result3 = try Element.insertAdjacentElement(parent, "beforeend", last);
    /// // result3 === last, inserted after all children
    ///
    /// // Insert after parent
    /// const after = try Element.create(allocator, "aside");
    /// const result4 = try Element.insertAdjacentElement(parent, "afterend", after);
    /// // result4 === after, inserted as next sibling of parent
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-insertadjacentelement
    pub fn insertAdjacentElement(node: *Node, where: []const u8, element: *Node) !?*Node {
        // Normalize position string (case-insensitive comparison)
        const where_lower = try std.ascii.allocLowerString(node.allocator, where);
        defer node.allocator.free(where_lower);

        if (std.mem.eql(u8, where_lower, "beforebegin")) {
            const parent = node.parent_node orelse return null;
            _ = try parent.insertBefore(element, node);
            return element;
        } else if (std.mem.eql(u8, where_lower, "afterbegin")) {
            const first = node.firstChild();
            _ = try node.insertBefore(element, first);
            return element;
        } else if (std.mem.eql(u8, where_lower, "beforeend")) {
            _ = try node.appendChild(element);
            return element;
        } else if (std.mem.eql(u8, where_lower, "afterend")) {
            const parent = node.parent_node orelse return null;
            const next = node.nextSibling();
            _ = try parent.insertBefore(element, next);
            return element;
        } else {
            return error.SyntaxError;
        }
    }

    /// Insert Adjacent Text
    ///
    /// Inserts a text node with the given data at a specified position relative to this element.
    ///
    /// ## Parameters
    ///
    /// - `node`: Reference element
    /// - `where`: Position string - "beforebegin", "afterbegin", "beforeend", "afterend"
    /// - `data`: Text content for the new text node
    ///
    /// ## Position Values
    ///
    /// - **beforebegin**: Before this element (as previous sibling)
    /// - **afterbegin**: Just inside this element, before first child
    /// - **beforeend**: Just inside this element, after last child
    /// - **afterend**: After this element (as next sibling)
    ///
    /// ## Errors
    ///
    /// - `error.OutOfMemory`: Memory allocation failed
    /// - `error.SyntaxError`: Invalid position string
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const div = try Element.create(allocator, "div");
    /// defer div.release();
    ///
    /// const parent = try Element.create(allocator, "section");
    /// defer parent.release();
    /// _ = try parent.appendChild(div);
    ///
    /// // Insert text before element
    /// try Element.insertAdjacentText(div, "beforebegin", "Before ");
    ///
    /// // Insert text as first child
    /// try Element.insertAdjacentText(div, "afterbegin", "Start ");
    ///
    /// // Insert text as last child
    /// try Element.insertAdjacentText(div, "beforeend", " End");
    ///
    /// // Insert text after element
    /// try Element.insertAdjacentText(div, "afterend", " After");
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-element-insertadjacenttext
    pub fn insertAdjacentText(node: *Node, where: []const u8, data: []const u8) !void {
        const text_node = try Node.init(node.allocator, .text_node, "#text");
        text_node.node_value = try node.allocator.dupe(u8, data);

        _ = try insertAdjacentElement(node, where, text_node);
    }

    /// Get Previous Element Sibling
    ///
    /// Returns the element immediately preceding this element in its parent's child list.
    /// Text nodes and other non-element nodes are skipped.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    ///
    /// ## Returns
    ///
    /// Previous element sibling, or `null` if no such element exists.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// defer parent.release();
    ///
    /// const elem1 = try Element.create(allocator, "span");
    /// const text = try Node.init(allocator, .text_node, "#text");
    /// const elem2 = try Element.create(allocator, "p");
    ///
    /// _ = try parent.appendChild(elem1);
    /// _ = try parent.appendChild(text);
    /// _ = try parent.appendChild(elem2);
    ///
    /// const prev = Element.getPreviousElementSibling(elem2);
    /// // prev === elem1 (text node was skipped)
    ///
    /// const none = Element.getPreviousElementSibling(elem1);
    /// // none === null (no previous element)
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-previouselementsibling
    pub fn getPreviousElementSibling(node: *const Node) ?*Node {
        if (node.node_type != .element_node) return null;

        var current = node.previousSibling();
        while (current) |sibling| {
            if (sibling.node_type == .element_node) {
                return sibling;
            }
            current = sibling.previousSibling();
        }

        return null;
    }

    /// Get Next Element Sibling
    ///
    /// Returns the element immediately following this element in its parent's child list.
    /// Text nodes and other non-element nodes are skipped.
    ///
    /// ## Parameters
    ///
    /// - `node`: Element node
    ///
    /// ## Returns
    ///
    /// Next element sibling, or `null` if no such element exists.
    ///
    /// ## Examples
    ///
    /// ```zig
    /// const parent = try Element.create(allocator, "div");
    /// defer parent.release();
    ///
    /// const elem1 = try Element.create(allocator, "span");
    /// const text = try Node.init(allocator, .text_node, "#text");
    /// const elem2 = try Element.create(allocator, "p");
    ///
    /// _ = try parent.appendChild(elem1);
    /// _ = try parent.appendChild(text);
    /// _ = try parent.appendChild(elem2);
    ///
    /// const next = Element.getNextElementSibling(elem1);
    /// // next === elem2 (text node was skipped)
    ///
    /// const none = Element.getNextElementSibling(elem2);
    /// // none === null (no next element)
    /// ```
    ///
    /// See: https://dom.spec.whatwg.org/#dom-nondocumenttypechildnode-nextelementsibling
    pub fn getNextElementSibling(node: *const Node) ?*Node {
        if (node.node_type != .element_node) return null;

        var current = node.nextSibling();
        while (current) |sibling| {
            if (sibling.node_type == .element_node) {
                return sibling;
            }
            current = sibling.nextSibling();
        }

        return null;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Element creation" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    const data = Element.getData(element);
    try std.testing.expectEqualStrings("DIV", data.tag_name);
    try std.testing.expectEqual(NodeType.element_node, element.node_type);
}

test "Element attributes" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try std.testing.expect(!Element.hasAttribute(element, "id"));

    try Element.setAttribute(element, "id", "test");
    try std.testing.expect(Element.hasAttribute(element, "id"));

    const id = Element.getAttribute(element, "id");
    try std.testing.expect(id != null);
    try std.testing.expectEqualStrings("test", id.?);

    Element.removeAttribute(element, "id");
    try std.testing.expect(!Element.hasAttribute(element, "id"));
}

test "Element classList" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try Element.setClassName(element, "foo bar");
    const data = Element.getData(element);
    try std.testing.expect(data.class_list.contains("foo"));
    try std.testing.expect(data.class_list.contains("bar"));

    const class_attr = Element.getAttribute(element, "class");
    try std.testing.expect(class_attr != null);
}

test "Element toggleAttribute" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    const result1 = try Element.toggleAttribute(element, "hidden", null);
    try std.testing.expectEqual(true, result1);
    try std.testing.expect(Element.hasAttribute(element, "hidden"));

    const result2 = try Element.toggleAttribute(element, "hidden", null);
    try std.testing.expectEqual(false, result2);
    try std.testing.expect(!Element.hasAttribute(element, "hidden"));
}

test "Element getElementById" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "span");
    try Element.setAttribute(child, "id", "target");
    _ = try parent.appendChild(child);

    const found = Element.getElementById(parent, "target");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(child, found.?);
}

test "Element getElementsByTagName" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "span");
    _ = try parent.appendChild(child1);

    const child2 = try Element.create(allocator, "span");
    _ = try parent.appendChild(child2);

    const child3 = try Element.create(allocator, "p");
    _ = try parent.appendChild(child3);

    var list = NodeList.init(allocator);
    defer list.deinit();

    try Element.getElementsByTagName(parent, "span", &list);
    try std.testing.expectEqual(@as(usize, 2), list.length());
}

test "Element child element navigation" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const text_node = try Node.init(allocator, .text_node, "#text");
    _ = try parent.appendChild(text_node);

    const child1 = try Element.create(allocator, "span");
    _ = try parent.appendChild(child1);

    const child2 = try Element.create(allocator, "p");
    _ = try parent.appendChild(child2);

    try std.testing.expectEqual(child1, Element.getFirstElementChild(parent));
    try std.testing.expectEqual(child2, Element.getLastElementChild(parent));
    try std.testing.expectEqual(@as(usize, 2), Element.getChildElementCount(parent));
}

test "Element matches selector" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try Element.setAttribute(element, "id", "myid");
    try Element.setClassName(element, "foo bar");

    try std.testing.expect(try Element.matches(element, "div"));
    try std.testing.expect(try Element.matches(element, "#myid"));
    try std.testing.expect(try Element.matches(element, ".foo"));
    try std.testing.expect(try Element.matches(element, "div.foo#myid"));
    try std.testing.expect(!try Element.matches(element, "span"));
    try std.testing.expect(!try Element.matches(element, ".baz"));
}

test "Element querySelector" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "span");
    try Element.setAttribute(child1, "id", "first");
    _ = try parent.appendChild(child1);

    const child2 = try Element.create(allocator, "p");
    try Element.setClassName(child2, "highlight");
    _ = try parent.appendChild(child2);

    const child3 = try Element.create(allocator, "span");
    try Element.setClassName(child3, "highlight");
    _ = try parent.appendChild(child3);

    const found_id = try Element.querySelector(parent, "#first");
    try std.testing.expect(found_id != null);
    try std.testing.expectEqual(child1, found_id.?);

    const found_class = try Element.querySelector(parent, ".highlight");
    try std.testing.expect(found_class != null);
    try std.testing.expectEqual(child2, found_class.?);

    const found_tag = try Element.querySelector(parent, "span");
    try std.testing.expect(found_tag != null);
    try std.testing.expectEqual(child1, found_tag.?);

    const not_found = try Element.querySelector(parent, "#nonexistent");
    try std.testing.expect(not_found == null);
}

test "Element querySelectorAll" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child1 = try Element.create(allocator, "span");
    try Element.setClassName(child1, "item");
    _ = try parent.appendChild(child1);

    const child2 = try Element.create(allocator, "p");
    try Element.setClassName(child2, "item");
    _ = try parent.appendChild(child2);

    const child3 = try Element.create(allocator, "span");
    try Element.setClassName(child3, "other");
    _ = try parent.appendChild(child3);

    const list = try Element.querySelectorAll(parent, ".item");
    defer {
        list.deinit();
        allocator.destroy(list);
    }

    try std.testing.expectEqual(@as(usize, 2), list.length());

    const item0: *Node = @ptrCast(@alignCast(list.item(0).?));
    const item1: *Node = @ptrCast(@alignCast(list.item(1).?));
    try std.testing.expectEqual(child1, item0);
    try std.testing.expectEqual(child2, item1);

    const span_list = try Element.querySelectorAll(parent, "span");
    defer {
        span_list.deinit();
        allocator.destroy(span_list);
    }

    try std.testing.expectEqual(@as(usize, 2), span_list.length());
}

// ============================================================================
// Enhanced Tests - Edge Cases and Additional Coverage
// ============================================================================

test "Element tag name case insensitive" {
    const allocator = std.testing.allocator;

    const lower = try Element.create(allocator, "div");
    defer lower.release();

    const upper = try Element.create(allocator, "DIV");
    defer upper.release();

    const mixed = try Element.create(allocator, "DiV");
    defer mixed.release();

    const data_lower = Element.getData(lower);
    const data_upper = Element.getData(upper);
    const data_mixed = Element.getData(mixed);

    // All should be uppercased
    try std.testing.expectEqualStrings("DIV", data_lower.tag_name);
    try std.testing.expectEqualStrings("DIV", data_upper.tag_name);
    try std.testing.expectEqualStrings("DIV", data_mixed.tag_name);
}

test "Element multiple attributes" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "input");
    defer element.release();

    try Element.setAttribute(element, "type", "text");
    try Element.setAttribute(element, "placeholder", "Enter name");
    try Element.setAttribute(element, "required", "");
    try Element.setAttribute(element, "data-user-id", "123");

    try std.testing.expect(Element.hasAttribute(element, "type"));
    try std.testing.expect(Element.hasAttribute(element, "placeholder"));
    try std.testing.expect(Element.hasAttribute(element, "required"));
    try std.testing.expect(Element.hasAttribute(element, "data-user-id"));

    try std.testing.expectEqualStrings("text", Element.getAttribute(element, "type").?);
    try std.testing.expectEqualStrings("Enter name", Element.getAttribute(element, "placeholder").?);
    try std.testing.expectEqualStrings("", Element.getAttribute(element, "required").?);
    try std.testing.expectEqualStrings("123", Element.getAttribute(element, "data-user-id").?);
}

test "Element setAttribute updates existing" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try Element.setAttribute(element, "id", "first");
    try std.testing.expectEqualStrings("first", Element.getAttribute(element, "id").?);

    try Element.setAttribute(element, "id", "second");
    try std.testing.expectEqualStrings("second", Element.getAttribute(element, "id").?);

    const data = Element.getData(element);
    try std.testing.expectEqual(@as(usize, 1), data.attributes.length());
}

test "Element removeAttribute non-existent is safe" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    // Should not crash
    Element.removeAttribute(element, "nonexistent");
    Element.removeAttribute(element, "id");
    Element.removeAttribute(element, "class");
}

test "Element class attribute syncs with classList" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    // Setting class attribute updates classList
    try Element.setAttribute(element, "class", "foo bar baz");
    const data = Element.getData(element);
    try std.testing.expect(data.class_list.contains("foo"));
    try std.testing.expect(data.class_list.contains("bar"));
    try std.testing.expect(data.class_list.contains("baz"));

    // Removing class attribute clears classList
    Element.removeAttribute(element, "class");
    try std.testing.expectEqual(@as(usize, 0), data.class_list.length());
}

test "Element setClassName syncs with attribute" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    try Element.setClassName(element, "btn btn-primary");

    const class_attr = Element.getAttribute(element, "class");
    try std.testing.expectEqualStrings("btn btn-primary", class_attr.?);

    const data = Element.getData(element);
    try std.testing.expect(data.class_list.contains("btn"));
    try std.testing.expect(data.class_list.contains("btn-primary"));
}

test "Element toggleAttribute forced true" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "button");
    defer element.release();

    // Force true when missing
    var result = try Element.toggleAttribute(element, "disabled", true);
    try std.testing.expectEqual(true, result);
    try std.testing.expect(Element.hasAttribute(element, "disabled"));

    // Force true when present
    result = try Element.toggleAttribute(element, "disabled", true);
    try std.testing.expectEqual(true, result);
    try std.testing.expect(Element.hasAttribute(element, "disabled"));
}

test "Element toggleAttribute forced false" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "button");
    defer element.release();

    try Element.setAttribute(element, "disabled", "");

    // Force false when present
    var result = try Element.toggleAttribute(element, "disabled", false);
    try std.testing.expectEqual(false, result);
    try std.testing.expect(!Element.hasAttribute(element, "disabled"));

    // Force false when missing
    result = try Element.toggleAttribute(element, "disabled", false);
    try std.testing.expectEqual(false, result);
    try std.testing.expect(!Element.hasAttribute(element, "disabled"));
}

test "Element getAttributeNames empty" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    const names = try Element.getAttributeNames(element, allocator);
    defer allocator.free(names);

    try std.testing.expectEqual(@as(usize, 0), names.len);
}

test "Element getAttributeNames multiple" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "input");
    defer element.release();

    try Element.setAttribute(element, "type", "text");
    try Element.setAttribute(element, "name", "username");
    try Element.setAttribute(element, "required", "");

    const names = try Element.getAttributeNames(element, allocator);
    defer allocator.free(names);

    try std.testing.expectEqual(@as(usize, 3), names.len);

    // Check all names are present (order not guaranteed)
    var has_type = false;
    var has_name = false;
    var has_required = false;

    for (names) |name| {
        if (std.mem.eql(u8, name, "type")) has_type = true;
        if (std.mem.eql(u8, name, "name")) has_name = true;
        if (std.mem.eql(u8, name, "required")) has_required = true;
    }

    try std.testing.expect(has_type);
    try std.testing.expect(has_name);
    try std.testing.expect(has_required);
}

test "Element getElementById nested search" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const level1 = try Element.create(allocator, "div");
    _ = try root.appendChild(level1);

    const level2 = try Element.create(allocator, "div");
    _ = try level1.appendChild(level2);

    const target = try Element.create(allocator, "span");
    try Element.setAttribute(target, "id", "deep-target");
    _ = try level2.appendChild(target);

    const found = Element.getElementById(root, "deep-target");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(target, found.?);
}

test "Element getElementById not found" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const child = try Element.create(allocator, "span");
    try Element.setAttribute(child, "id", "exists");
    _ = try root.appendChild(child);

    const found = Element.getElementById(root, "nonexistent");
    try std.testing.expectEqual(@as(?*Node, null), found);
}

test "Element getElementsByTagName wildcard" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const child1 = try Element.create(allocator, "span");
    _ = try root.appendChild(child1);

    const child2 = try Element.create(allocator, "p");
    _ = try root.appendChild(child2);

    const child3 = try Element.create(allocator, "div");
    _ = try root.appendChild(child3);

    var list = NodeList.init(allocator);
    defer list.deinit();

    try Element.getElementsByTagName(root, "*", &list);
    try std.testing.expectEqual(@as(usize, 4), list.length()); // root + 3 children
}

test "Element getElementsByClassName single class" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const child1 = try Element.create(allocator, "div");
    try Element.setClassName(child1, "item");
    _ = try root.appendChild(child1);

    const child2 = try Element.create(allocator, "div");
    try Element.setClassName(child2, "item selected");
    _ = try root.appendChild(child2);

    const child3 = try Element.create(allocator, "div");
    try Element.setClassName(child3, "other");
    _ = try root.appendChild(child3);

    var list = NodeList.init(allocator);
    defer list.deinit();

    try Element.getElementsByClassName(root, "item", &list);
    try std.testing.expectEqual(@as(usize, 2), list.length());
}

test "Element getElementsByClassName multiple classes" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const child1 = try Element.create(allocator, "div");
    try Element.setClassName(child1, "item active");
    _ = try root.appendChild(child1);

    const child2 = try Element.create(allocator, "div");
    try Element.setClassName(child2, "item");
    _ = try root.appendChild(child2);

    const child3 = try Element.create(allocator, "div");
    try Element.setClassName(child3, "active");
    _ = try root.appendChild(child3);

    var list = NodeList.init(allocator);
    defer list.deinit();

    try Element.getElementsByClassName(root, "item active", &list);
    try std.testing.expectEqual(@as(usize, 1), list.length()); // Only child1 has both
}

test "Element getFirstElementChild with no elements" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const text = try Node.init(allocator, .text_node, "text");
    _ = try parent.appendChild(text);

    const first = Element.getFirstElementChild(parent);
    try std.testing.expectEqual(@as(?*Node, null), first);
}

test "Element getLastElementChild with no elements" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const text = try Node.init(allocator, .text_node, "text");
    _ = try parent.appendChild(text);

    const last = Element.getLastElementChild(parent);
    try std.testing.expectEqual(@as(?*Node, null), last);
}

test "Element getChildElementCount mixed nodes" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const text1 = try Node.init(allocator, .text_node, "text1");
    _ = try parent.appendChild(text1);

    const elem1 = try Element.create(allocator, "span");
    _ = try parent.appendChild(elem1);

    const text2 = try Node.init(allocator, .text_node, "text2");
    _ = try parent.appendChild(text2);

    const elem2 = try Element.create(allocator, "p");
    _ = try parent.appendChild(elem2);

    try std.testing.expectEqual(@as(usize, 2), Element.getChildElementCount(parent));
}

test "Element querySelector returns first match" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const child1 = try Element.create(allocator, "span");
    try Element.setClassName(child1, "item");
    _ = try root.appendChild(child1);

    const child2 = try Element.create(allocator, "span");
    try Element.setClassName(child2, "item");
    _ = try root.appendChild(child2);

    const found = try Element.querySelector(root, ".item");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(child1, found.?); // First match
}

test "Element querySelectorAll empty result" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const child = try Element.create(allocator, "span");
    _ = try root.appendChild(child);

    const list = try Element.querySelectorAll(root, ".nonexistent");
    defer {
        list.deinit();
        allocator.destroy(list);
    }

    try std.testing.expectEqual(@as(usize, 0), list.length());
}

// Memory leak test
test "Element operations do not leak memory" {
    const allocator = std.testing.allocator;

    var i: usize = 0;
    while (i < 50) : (i += 1) {
        const element = try Element.create(allocator, "div");
        defer element.release();

        // Attribute operations
        try Element.setAttribute(element, "id", "test");
        try Element.setAttribute(element, "class", "foo bar");
        try Element.setAttribute(element, "data-value", "123");

        _ = Element.getAttribute(element, "id");
        _ = Element.hasAttribute(element, "class");
        Element.removeAttribute(element, "data-value");

        // Class operations
        try Element.setClassName(element, "one two three");
        const class_name = try Element.getClassName(element);
        element.allocator.free(class_name);

        // Toggle operations
        _ = try Element.toggleAttribute(element, "hidden", null);
        _ = try Element.toggleAttribute(element, "hidden", true);

        // Attribute names
        const names = try Element.getAttributeNames(element, allocator);
        allocator.free(names);

        // Child element navigation
        const child = try Element.create(allocator, "span");
        _ = try element.appendChild(child);

        _ = Element.getFirstElementChild(element);
        _ = Element.getLastElementChild(element);
        _ = Element.getChildElementCount(element);

        // Selector operations
        _ = try Element.matches(element, "div.foo");
        _ = try Element.querySelector(element, ".bar");

        const list = try Element.querySelectorAll(element, "*");
        list.deinit();
        allocator.destroy(list);
    }
}

// ============================================================================
// Phase 3 Tests - Element Enhancement
// ============================================================================

test "Element closest - finds self" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();
    try Element.setClassName(element, "target");

    const found = try Element.closest(element, ".target");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(element, found.?);
}

test "Element closest - finds parent" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "article");
    defer parent.release();
    try Element.setClassName(parent, "post");

    const child = try Element.create(allocator, "p");
    _ = try parent.appendChild(child);

    const found = try Element.closest(child, "article.post");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(parent, found.?);
}

test "Element closest - finds grandparent" {
    const allocator = std.testing.allocator;

    const grandparent = try Element.create(allocator, "article");
    defer grandparent.release();
    try Element.setAttribute(grandparent, "id", "main");

    const parent = try Element.create(allocator, "section");
    _ = try grandparent.appendChild(parent);

    const child = try Element.create(allocator, "p");
    _ = try parent.appendChild(child);

    const found = try Element.closest(child, "#main");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(grandparent, found.?);
}

test "Element closest - no match returns null" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const child = try Element.create(allocator, "span");
    _ = try parent.appendChild(child);

    const found = try Element.closest(child, ".nonexistent");
    try std.testing.expectEqual(@as(?*Node, null), found);
}

test "Element closest - stops at document boundary" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const child = try Element.create(allocator, "span");
    _ = try root.appendChild(child);

    const found = try Element.closest(child, "body");
    try std.testing.expectEqual(@as(?*Node, null), found);
}

test "Element webkitMatchesSelector - basic matching" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "button");
    defer element.release();
    try Element.setAttribute(element, "id", "submit");
    try Element.setClassName(element, "btn primary");

    try std.testing.expect(try Element.webkitMatchesSelector(element, "button"));
    try std.testing.expect(try Element.webkitMatchesSelector(element, "#submit"));
    try std.testing.expect(try Element.webkitMatchesSelector(element, ".btn"));
    try std.testing.expect(try Element.webkitMatchesSelector(element, "button.primary"));
    try std.testing.expect(!try Element.webkitMatchesSelector(element, "input"));
}

test "Element insertAdjacentElement - beforebegin" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const target = try Element.create(allocator, "span");
    try Element.setAttribute(target, "id", "target");
    _ = try root.appendChild(target);

    const new_elem = try Element.create(allocator, "p");
    try Element.setAttribute(new_elem, "id", "new");

    const result = try Element.insertAdjacentElement(target, "beforebegin", new_elem);
    try std.testing.expect(result != null);
    try std.testing.expectEqual(new_elem, result.?);

    // Verify order
    const first_child = root.firstChild();
    try std.testing.expectEqual(new_elem, first_child.?);

    const second_child = new_elem.nextSibling();
    try std.testing.expectEqual(target, second_child.?);
}

test "Element insertAdjacentElement - afterbegin" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const existing = try Element.create(allocator, "span");
    _ = try parent.appendChild(existing);

    const new_elem = try Element.create(allocator, "p");
    const result = try Element.insertAdjacentElement(parent, "afterbegin", new_elem);
    try std.testing.expectEqual(new_elem, result.?);

    // Verify new_elem is first child
    const first_child = parent.firstChild();
    try std.testing.expectEqual(new_elem, first_child.?);

    const second_child = new_elem.nextSibling();
    try std.testing.expectEqual(existing, second_child.?);
}

test "Element insertAdjacentElement - beforeend" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const existing = try Element.create(allocator, "span");
    _ = try parent.appendChild(existing);

    const new_elem = try Element.create(allocator, "p");
    const result = try Element.insertAdjacentElement(parent, "beforeend", new_elem);
    try std.testing.expectEqual(new_elem, result.?);

    // Verify new_elem is last child
    const last_child = parent.lastChild();
    try std.testing.expectEqual(new_elem, last_child.?);

    const first_child = parent.firstChild();
    try std.testing.expectEqual(existing, first_child.?);
}

test "Element insertAdjacentElement - afterend" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const target = try Element.create(allocator, "span");
    _ = try root.appendChild(target);

    const new_elem = try Element.create(allocator, "p");
    const result = try Element.insertAdjacentElement(target, "afterend", new_elem);
    try std.testing.expectEqual(new_elem, result.?);

    // Verify order
    const first_child = root.firstChild();
    try std.testing.expectEqual(target, first_child.?);

    const second_child = target.nextSibling();
    try std.testing.expectEqual(new_elem, second_child.?);
}

test "Element insertAdjacentElement - case insensitive" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const new_elem = try Element.create(allocator, "span");

    // Test uppercase
    _ = try Element.insertAdjacentElement(parent, "BEFOREEND", new_elem);
    try std.testing.expectEqual(@as(usize, 1), parent.child_nodes.length());
}

test "Element insertAdjacentElement - invalid position" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const new_elem = try Element.create(allocator, "span");
    defer new_elem.release();

    const result = Element.insertAdjacentElement(parent, "invalid", new_elem);
    try std.testing.expectError(error.SyntaxError, result);
}

test "Element insertAdjacentElement - beforebegin without parent" {
    const allocator = std.testing.allocator;

    const element = try Element.create(allocator, "div");
    defer element.release();

    const new_elem = try Element.create(allocator, "span");
    defer new_elem.release();

    const result = try Element.insertAdjacentElement(element, "beforebegin", new_elem);
    try std.testing.expectEqual(@as(?*Node, null), result);
}

test "Element insertAdjacentText - all positions" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "div");
    defer root.release();

    const target = try Element.create(allocator, "span");
    _ = try root.appendChild(target);

    // beforebegin
    try Element.insertAdjacentText(target, "beforebegin", "Before");
    // afterbegin
    try Element.insertAdjacentText(target, "afterbegin", "Start");
    // beforeend
    try Element.insertAdjacentText(target, "beforeend", "End");
    // afterend
    try Element.insertAdjacentText(target, "afterend", "After");

    // Verify structure
    try std.testing.expectEqual(@as(usize, 3), root.child_nodes.length());
    try std.testing.expectEqual(@as(usize, 2), target.child_nodes.length());

    // Check text nodes
    const before_node = root.firstChild();
    try std.testing.expectEqual(NodeType.text_node, before_node.?.node_type);
    try std.testing.expectEqualStrings("Before", before_node.?.node_value.?);

    const start_node = target.firstChild();
    try std.testing.expectEqual(NodeType.text_node, start_node.?.node_type);
    try std.testing.expectEqualStrings("Start", start_node.?.node_value.?);
}

test "Element getPreviousElementSibling - skips text nodes" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const elem1 = try Element.create(allocator, "span");
    _ = try parent.appendChild(elem1);

    const text = try Node.init(allocator, .text_node, "#text");
    _ = try parent.appendChild(text);

    const elem2 = try Element.create(allocator, "p");
    _ = try parent.appendChild(elem2);

    const prev = Element.getPreviousElementSibling(elem2);
    try std.testing.expect(prev != null);
    try std.testing.expectEqual(elem1, prev.?);
}

test "Element getPreviousElementSibling - first element returns null" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const elem = try Element.create(allocator, "span");
    _ = try parent.appendChild(elem);

    const prev = Element.getPreviousElementSibling(elem);
    try std.testing.expectEqual(@as(?*Node, null), prev);
}

test "Element getPreviousElementSibling - only text nodes returns null" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const text1 = try Node.init(allocator, .text_node, "#text");
    _ = try parent.appendChild(text1);

    const text2 = try Node.init(allocator, .text_node, "#text");
    _ = try parent.appendChild(text2);

    const elem = try Element.create(allocator, "span");
    _ = try parent.appendChild(elem);

    const prev = Element.getPreviousElementSibling(elem);
    try std.testing.expectEqual(@as(?*Node, null), prev);
}

test "Element getNextElementSibling - skips text nodes" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const elem1 = try Element.create(allocator, "span");
    _ = try parent.appendChild(elem1);

    const text = try Node.init(allocator, .text_node, "#text");
    _ = try parent.appendChild(text);

    const elem2 = try Element.create(allocator, "p");
    _ = try parent.appendChild(elem2);

    const next = Element.getNextElementSibling(elem1);
    try std.testing.expect(next != null);
    try std.testing.expectEqual(elem2, next.?);
}

test "Element getNextElementSibling - last element returns null" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const elem = try Element.create(allocator, "span");
    _ = try parent.appendChild(elem);

    const next = Element.getNextElementSibling(elem);
    try std.testing.expectEqual(@as(?*Node, null), next);
}

test "Element getNextElementSibling - only text nodes returns null" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const elem = try Element.create(allocator, "span");
    _ = try parent.appendChild(elem);

    const text1 = try Node.init(allocator, .text_node, "#text");
    _ = try parent.appendChild(text1);

    const text2 = try Node.init(allocator, .text_node, "#text");
    _ = try parent.appendChild(text2);

    const next = Element.getNextElementSibling(elem);
    try std.testing.expectEqual(@as(?*Node, null), next);
}

test "Element getNextElementSibling - multiple elements" {
    const allocator = std.testing.allocator;

    const parent = try Element.create(allocator, "div");
    defer parent.release();

    const elem1 = try Element.create(allocator, "span");
    const elem2 = try Element.create(allocator, "p");
    const elem3 = try Element.create(allocator, "a");

    _ = try parent.appendChild(elem1);
    _ = try parent.appendChild(elem2);
    _ = try parent.appendChild(elem3);

    const next1 = Element.getNextElementSibling(elem1);
    try std.testing.expectEqual(elem2, next1.?);

    const next2 = Element.getNextElementSibling(elem2);
    try std.testing.expectEqual(elem3, next2.?);

    const next3 = Element.getNextElementSibling(elem3);
    try std.testing.expectEqual(@as(?*Node, null), next3);
}
