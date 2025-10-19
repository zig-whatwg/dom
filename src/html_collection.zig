//! HTMLCollection - Live Collection of Elements (WHATWG DOM Core)
//!
//! This module implements the WHATWG DOM HTMLCollection interface for generic documents.
//! Despite the "HTML" prefix, HTMLCollection is part of DOM Core and works with any document
//! type (XML, custom formats, etc.). It is NOT HTML-specific.
//!
//! ## WHATWG Specification
//!
//! Relevant specification sections:
//! - **§5.2 Interface HTMLCollection**: https://dom.spec.whatwg.org/#interface-htmlcollection
//! - **§4.2.6 Mixin ParentNode**: https://dom.spec.whatwg.org/#interface-parentnode (children)
//! - **§4.9 Interface Element**: https://dom.spec.whatwg.org/#dom-element-getelementsbytagname
//! - **§5 Collections**: https://dom.spec.whatwg.org/#collections
//!
//! ## WebIDL
//!
//! ```webidl
//! [Exposed=Window, LegacyUnenumerableNamedProperties]
//! interface HTMLCollection {
//!   readonly attribute unsigned long length;
//!   getter Element? item(unsigned long index);
//!   getter Element? namedItem(DOMString name);
//! };
//! ```
//!
//! ## Core Features
//!
//! ### Live Collection
//! HTMLCollection is a "live" collection - it automatically reflects DOM changes:
//! ```zig
//! const parent = try doc.createElement("container");
//! defer parent.prototype.release();
//!
//! const children = parent.children();
//! try std.testing.expectEqual(@as(usize, 0), children.length());
//!
//! // Add element child - collection updates automatically
//! const child = try doc.createElement("item");
//! _ = try parent.prototype.appendChild(&child.prototype);
//! try std.testing.expectEqual(@as(usize, 1), children.length()); // Now 1!
//! ```
//!
//! ### Multiple Use Cases
//! HTMLCollection supports three different backing strategies:
//!
//! 1. **children** property - filters Element nodes from parent's child list
//! 2. **Document.getElementsByTagName** - views Document's tag_map (O(1) access)
//! 3. **Document.getElementsByClassName** - document-wide tree traversal with bloom filters (Phase 3)
//! 4. **Element.getElementsBy*** - scoped subtree search with filtering
//!
//! ### Elements Only
//! Unlike NodeList (which includes all node types), HTMLCollection only includes Element nodes:
//! ```zig
//! const parent = try doc.createElement("parent");
//! defer parent.prototype.release();
//!
//! // Add mixed children
//! const elem1 = try doc.createElement("child1");
//! _ = try parent.prototype.appendChild(&elem1.prototype);
//!
//! const text = try doc.createTextNode("text content");
//! _ = try parent.prototype.appendChild(&text.prototype);
//!
//! const elem2 = try doc.createElement("child2");
//! _ = try parent.prototype.appendChild(&elem2.prototype);
//!
//! // childNodes has 3 nodes, children has 2 elements
//! const all_nodes = parent.prototype.childNodes();
//! const only_elements = parent.children();
//! try std.testing.expectEqual(@as(usize, 3), all_nodes.length());
//! try std.testing.expectEqual(@as(usize, 2), only_elements.length());
//! ```
//!
//! ## HTMLCollection Structure
//!
//! HTMLCollection is a lightweight view using a tagged union for different backing strategies:
//! - **children**: Pointer to parent node (filters Element nodes)
//! - **document_tagged**: Pointer to Document's ArrayList (tag_map only, Phase 3)
//! - **element_scoped**: Root element + filter (tag or class name)
//! - **document_scoped**: Document node + filter (for getElementsByClassName, Phase 3)
//!
//! Size: 16-24 bytes (depends on union variant)
//!
//! **Key Properties:**
//! - **Live**: Reflects DOM changes automatically
//! - **Non-owning**: Doesn't own elements, just provides access
//! - **Elements only**: Skips non-Element nodes (Text, Comment, etc.)
//! - **Zero-copy**: Just a view into existing tree/map structure
//! - **Generic**: Works with any document type (XML, custom), not HTML-specific
//!
//! ## Memory Management
//!
//! HTMLCollection is a stack-allocated value type (not heap-allocated):
//! ```zig
//! const parent = try doc.createElement("container");
//! defer parent.prototype.release();
//!
//! const children = parent.children();
//! // No defer needed - HTMLCollection is a plain struct value
//!
//! // HTMLCollection doesn't own elements - parent owns them
//! ```
//!
//! **Important:**
//! - HTMLCollection does NOT own the elements it references
//! - Elements are owned by their parent via tree structure
//! - Parent.release() frees all children automatically
//! - HTMLCollection is just a view (like a slice, but live and filtered)
//!
//! ## Usage Examples
//!
//! ### ParentNode.children Property
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const container = try doc.createElement("container");
//! defer container.prototype.release();
//!
//! // Add mixed children
//! const elem = try doc.createElement("item");
//! _ = try container.prototype.appendChild(&elem.prototype);
//!
//! const text = try doc.createTextNode("text");
//! _ = try container.prototype.appendChild(&text.prototype);
//!
//! // children filters to elements only
//! const children = container.children();
//! try std.testing.expectEqual(@as(usize, 1), children.length());
//! ```
//!
//! ### Document.getElementsByTagName()
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const widget1 = try doc.createElement("widget");
//! const widget2 = try doc.createElement("widget");
//! _ = try doc.prototype.appendChild(&widget1.prototype);
//! _ = try doc.prototype.appendChild(&widget2.prototype);
//!
//! // Live collection backed by Document's tag_map
//! const widgets = doc.getElementsByTagName("widget");
//! try std.testing.expectEqual(@as(usize, 2), widgets.length());
//!
//! // Add another - collection updates automatically
//! const widget3 = try doc.createElement("widget");
//! _ = try doc.prototype.appendChild(&widget3.prototype);
//! try std.testing.expectEqual(@as(usize, 3), widgets.length());
//! ```
//!
//! ### Element.getElementsByClassName()
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const container = try doc.createElement("container");
//! defer container.prototype.release();
//!
//! const item1 = try doc.createElement("item");
//! try item1.setAttribute("class", "active");
//! _ = try container.prototype.appendChild(&item1.prototype);
//!
//! const item2 = try doc.createElement("item");
//! try item2.setAttribute("class", "active");
//! _ = try container.prototype.appendChild(&item2.prototype);
//!
//! // Live collection scoped to container's subtree
//! const actives = container.getElementsByClassName("active");
//! try std.testing.expectEqual(@as(usize, 2), actives.length());
//! ```
//!
//! ## Performance Tips
//!
//! 1. **Cache Length** - length() traversal cost varies by backing type
//! 2. **Document.getElementsBy*** is Fast** - O(1) via tag_map/class_map
//! 3. **Element.getElementsBy*** is O(n)** - Traverses subtree each time
//! 4. **children is O(n)** - Traverses child list filtering Elements
//! 5. **Snapshot if Modifying** - Convert to array before modifying DOM during iteration
//!
//! ## Implementation Notes
//!
//! - HTMLCollection is a plain struct (16-24 bytes, tagged union)
//! - No heap allocation (stack-allocated value type)
//! - Document.getElementsBy* backed by tag_map/class_map (O(1) access)
//! - Element.getElementsBy* traverses subtree each call (O(n))
//! - children traverses child list each call filtering Elements (O(n))
//! - Live collection - automatically reflects DOM mutations
//! - Non-owning - elements owned by tree structure, not by HTMLCollection
//! - Generic design - works with any document type, not HTML-specific

const std = @import("std");
const Node = @import("node.zig").Node;
const Element = @import("element.zig").Element;
const NodeType = @import("node.zig").NodeType;

/// HTMLCollection - live collection of Element nodes.
///
/// Implements WHATWG DOM HTMLCollection interface for generic documents.
/// Despite "HTML" prefix, this is DOM Core and works with any document type.
///
/// This is a "live" collection that automatically reflects changes to the DOM tree.
/// Three backing strategies support different use cases:
/// - children: Views parent's element children
/// - document_tagged: Views Document's tag_map or class_map
/// - element_scoped: Filters elements in subtree by tag/class
///
/// ## WHATWG Specification
/// **WebIDL**: https://dom.spec.whatwg.org/#htmlcollection
/// **Spec**: https://dom.spec.whatwg.org/#interface-htmlcollection
///
/// ## Memory Management
/// HTMLCollection does NOT own the elements - it merely provides a view into the tree/maps.
/// Elements are owned by their parent via the tree structure.
/// Filter type for element_scoped collections
const Filter = union(enum) {
    tag_name: []const u8,
    class_name: []const u8,
};

pub const HTMLCollection = struct {
    impl: Implementation,

    const Implementation = union(enum) {
        /// For ParentNode.children - filters Element nodes from parent's child list
        children: *Node,

        /// For Document.getElementsByTagName - backed by tag_map (fast O(1) access)
        document_tagged: struct {
            elements: ?*const std.ArrayList(*Element),
        },

        /// For Element.getElementsBy* - scoped subtree search with filter
        element_scoped: struct {
            root: *Element,
            filter: Filter,
        },

        /// For Document.getElementsByClassName - document-wide tree traversal with filter
        /// (Phase 3: class_map removed, uses tree traversal with bloom filters)
        document_scoped: struct {
            document: *const Node, // Document node
            filter: Filter,
        },
    };

    /// Creates a collection for ParentNode.children (filters Element nodes from parent).
    ///
    /// ## Parameters
    /// - `parent`: Parent node whose element children to view
    ///
    /// ## Returns
    /// HTMLCollection viewing parent's element children
    pub fn initChildren(parent: *Node) HTMLCollection {
        return .{
            .impl = .{ .children = parent },
        };
    }

    /// Creates a collection for Document.getElementsBy* (backed by tag_map or class_map).
    ///
    /// ## Parameters
    /// - `elements`: ArrayList from Document's tag_map or class_map, or null for empty
    ///
    /// ## Returns
    /// HTMLCollection viewing Document's internal map
    pub fn initDocumentTagged(elements: ?*const std.ArrayList(*Element)) HTMLCollection {
        return .{
            .impl = .{ .document_tagged = .{ .elements = elements } },
        };
    }

    /// Creates a collection for Element.getElementsByTagName (scoped to subtree).
    ///
    /// ## Parameters
    /// - `root`: Root element whose descendants to search
    /// - `tag_name`: Tag name to filter by
    ///
    /// ## Returns
    /// HTMLCollection filtering root's descendants by tag name
    pub fn initElementByTagName(root: *Element, tag_name: []const u8) HTMLCollection {
        return .{
            .impl = .{
                .element_scoped = .{
                    .root = root,
                    .filter = .{ .tag_name = tag_name },
                },
            },
        };
    }

    /// Creates a collection for Element.getElementsByClassName (scoped to subtree).
    ///
    /// ## Parameters
    /// - `root`: Root element whose descendants to search
    /// - `class_name`: Class name to filter by
    ///
    /// ## Returns
    /// HTMLCollection filtering root's descendants by class name
    pub fn initElementByClassName(root: *Element, class_name: []const u8) HTMLCollection {
        return .{
            .impl = .{
                .element_scoped = .{
                    .root = root,
                    .filter = .{ .class_name = class_name },
                },
            },
        };
    }

    /// Creates a collection for Document.getElementsByClassName (document-wide search).
    ///
    /// Phase 3: Uses tree traversal with bloom filters instead of class_map.
    ///
    /// ## Parameters
    /// - `document`: Document node to search from
    /// - `class_name`: Class name to filter by
    ///
    /// ## Returns
    /// HTMLCollection filtering all document elements by class name
    pub fn initDocumentByClassName(document: *const Node, class_name: []const u8) HTMLCollection {
        return .{
            .impl = .{
                .document_scoped = .{
                    .document = document,
                    .filter = .{ .class_name = class_name },
                },
            },
        };
    }

    /// Returns the number of elements in the collection.
    ///
    /// Implements WHATWG DOM HTMLCollection.length property.
    ///
    /// ## WHATWG Specification
    /// **WebIDL**: `readonly attribute unsigned long length;`
    /// **Spec**: https://dom.spec.whatwg.org/#dom-htmlcollection-length
    ///
    /// ## Performance
    /// - **children**: O(n) - traverses child list filtering Elements
    /// - **document_tagged**: O(1) - ArrayList.items.len
    /// - **element_scoped**: O(n) - traverses subtree with filter
    ///
    /// ## Returns
    /// Number of elements in the collection
    pub fn length(self: *const HTMLCollection) usize {
        switch (self.impl) {
            .children => |parent| {
                // Count element children only
                var count: usize = 0;
                var current = parent.first_child;
                while (current) |node| {
                    if (node.node_type == .element) {
                        count += 1;
                    }
                    current = node.next_sibling;
                }
                return count;
            },
            .document_tagged => |tagged| {
                // Fast path: ArrayList backed by Document map (for tag lookups)
                if (tagged.elements) |list| {
                    return list.items.len;
                }
                return 0;
            },
            .element_scoped => |scoped| {
                // Count matching descendants in subtree
                return countMatchingDescendants(scoped.root, &scoped.filter);
            },
            .document_scoped => |scoped| {
                // Count matching elements in entire document
                return countMatchingInDocument(scoped.document, &scoped.filter);
            },
        }
    }

    /// Returns the element at the specified index.
    ///
    /// Implements WHATWG DOM HTMLCollection.item() method.
    ///
    /// ## WHATWG Specification
    /// **WebIDL**: `getter Element? item(unsigned long index);`
    /// **Spec**: https://dom.spec.whatwg.org/#dom-htmlcollection-item
    ///
    /// ## Parameters
    /// - `index`: Zero-based index of element to retrieve
    ///
    /// ## Returns
    /// Element at index or null if index >= length
    ///
    /// ## Performance
    /// - **children**: O(n) - traverses child list to index
    /// - **document_tagged**: O(1) - ArrayList direct access
    /// - **element_scoped**: O(n) - traverses subtree to index
    ///
    /// ## Example
    /// ```zig
    /// const child = collection.item(0); // First element
    /// if (child) |elem| {
    ///     std.debug.print("First element: {s}\n", .{elem.tag_name});
    /// }
    /// ```
    pub fn item(self: *const HTMLCollection, index: usize) ?*Element {
        switch (self.impl) {
            .children => |parent| {
                // Traverse child list filtering Elements
                var count: usize = 0;
                var current = parent.first_child;
                while (current) |node| {
                    if (node.node_type == .element) {
                        if (count == index) {
                            return @fieldParentPtr("prototype", node);
                        }
                        count += 1;
                    }
                    current = node.next_sibling;
                }
                return null;
            },
            .document_tagged => |tagged| {
                // Fast path: ArrayList backed by Document map (for tags)
                if (tagged.elements) |list| {
                    if (index >= list.items.len) {
                        return null;
                    }
                    return list.items[index];
                }
                return null;
            },
            .element_scoped => |scoped| {
                // Find nth matching descendant in subtree
                return findMatchingDescendant(scoped.root, &scoped.filter, index);
            },
            .document_scoped => |scoped| {
                // Find nth matching element in document
                return findMatchingInDocument(scoped.document, &scoped.filter, index);
            },
        }
    }

    /// Returns the element with the specified id or name attribute.
    ///
    /// Implements WHATWG DOM HTMLCollection.namedItem() method.
    ///
    /// ## WHATWG Specification
    /// **WebIDL**: `getter Element? namedItem(DOMString name);`
    /// **Spec**: https://dom.spec.whatwg.org/#dom-htmlcollection-nameditem
    ///
    /// ## Parameters
    /// - `name`: Value of id or name attribute to match
    ///
    /// ## Returns
    /// First element with matching id or name attribute, or null
    ///
    /// ## Algorithm (WHATWG DOM §5.2.1)
    /// 1. Search for element with id attribute matching name
    /// 2. If not found, search for element with name attribute matching name
    /// 3. Return first match or null
    ///
    /// ## Example
    /// ```zig
    /// const elem = collection.namedItem("submit-btn");
    /// ```
    pub fn namedItem(self: *const HTMLCollection, name: []const u8) ?*Element {
        // Search all elements in collection for matching id or name attribute
        const len = self.length();
        var i: usize = 0;
        while (i < len) : (i += 1) {
            if (self.item(i)) |elem| {
                // Check id attribute first
                if (elem.getId()) |id| {
                    if (std.mem.eql(u8, id, name)) {
                        return elem;
                    }
                }
                // Then check name attribute
                if (elem.getAttribute("name")) |attr_name| {
                    if (std.mem.eql(u8, attr_name, name)) {
                        return elem;
                    }
                }
            }
        }
        return null;
    }

    // ========================================================================
    // Helper Functions
    // ========================================================================

    /// Counts descendants matching the filter (for element_scoped).
    fn countMatchingDescendants(root: *Element, filter: *const Filter) usize {
        var count: usize = 0;
        var current = root.prototype.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);
                if (matchesFilter(elem, filter)) {
                    count += 1;
                }
                // Recursively count in descendants
                count += countMatchingDescendants(elem, filter);
            }
            current = node.next_sibling;
        }
        return count;
    }

    /// Finds the nth descendant matching the filter (for element_scoped).
    fn findMatchingDescendant(root: *Element, filter: *const Filter, target_index: usize) ?*Element {
        var current_index: usize = 0;
        return findMatchingDescendantHelper(root, filter, target_index, &current_index);
    }

    fn findMatchingDescendantHelper(
        root: *Element,
        filter: *const Filter,
        target_index: usize,
        current_index: *usize,
    ) ?*Element {
        var current = root.prototype.first_child;
        while (current) |node| {
            if (node.node_type == .element) {
                const elem: *Element = @fieldParentPtr("prototype", node);
                if (matchesFilter(elem, filter)) {
                    if (current_index.* == target_index) {
                        return elem;
                    }
                    current_index.* += 1;
                }
                // Recursively search descendants
                if (findMatchingDescendantHelper(elem, filter, target_index, current_index)) |found| {
                    return found;
                }
            }
            current = node.next_sibling;
        }
        return null;
    }

    /// Checks if element matches the filter.
    fn matchesFilter(elem: *Element, filter: *const Filter) bool {
        switch (filter.*) {
            .tag_name => |tag| {
                return std.mem.eql(u8, elem.tag_name, tag);
            },
            .class_name => |class| {
                const class_attr = elem.getClassName();
                if (class_attr.len == 0) {
                    return false;
                }
                // Check if class_attr contains class (space-separated)
                var iter = std.mem.splitScalar(u8, class_attr, ' ');
                while (iter.next()) |token| {
                    if (std.mem.eql(u8, token, class)) {
                        return true;
                    }
                }
                return false;
            },
        }
    }

    // Document-wide search helpers (Phase 3: for document_scoped variant)

    /// Counts matching elements in entire document (for document_scoped).
    fn countMatchingInDocument(document: *const Node, filter: *const Filter) usize {
        var count: usize = 0;
        // Traverse all elements in document tree
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var iter = ElementIterator.init(@constCast(document));
        while (iter.next()) |elem| {
            if (matchesFilter(elem, filter)) {
                count += 1;
            }
        }
        return count;
    }

    /// Finds the nth element matching filter in document (for document_scoped).
    fn findMatchingInDocument(document: *const Node, filter: *const Filter, target_index: usize) ?*Element {
        var current_index: usize = 0;
        // Traverse all elements in document tree
        const ElementIterator = @import("element_iterator.zig").ElementIterator;
        var iter = ElementIterator.init(@constCast(document));
        while (iter.next()) |elem| {
            if (matchesFilter(elem, filter)) {
                if (current_index == target_index) {
                    return elem;
                }
                current_index += 1;
            }
        }
        return null;
    }
};
