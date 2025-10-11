//! Document Interface - WHATWG DOM Standard §4.5
//! ================================================
//!
//! The Document interface represents any web page loaded in the browser and serves as an
//! entry point into the web page's content, which is the DOM tree. It provides factory
//! methods for creating nodes and global query methods for finding elements.
//!
//! ## WHATWG Specification
//! - **Standard**: https://dom.spec.whatwg.org/#interface-document
//! - **Section**: §4.5 Interface Document
//!
//! ## MDN Documentation
//! - **Document**: https://developer.mozilla.org/en-US/docs/Web/API/Document
//! - **createElement**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createElement
//! - **createTextNode**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createTextNode
//! - **querySelector**: https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector
//!
//! ## Key Concepts
//!
//! ### Document Tree
//! A document represents the root of a DOM tree. It can contain:
//! - Exactly one Element node (the document element, typically `<html>`)
//! - Multiple Comment and ProcessingInstruction nodes
//! - Text nodes within the document element's descendants
//!
//! ### Owner Document
//! Every node has an owner document, set when the node is created. This ensures
//! nodes know which document they belong to, even when detached from the tree.
//!
//! ### Node Creation
//! Document provides factory methods (createElement, createTextNode, etc.) that
//! automatically set the owner_document property on created nodes.
//!
//! ## Architecture
//!
//! ```
//! Document
//! ├── node (Node) - Base node interface (#document)
//! ├── document_element (?*Node) - Root element (typically <html>)
//! └── allocator - Memory management
//! ```
//!
//! ## Usage Examples
//!
//! ### Basic Document Creation
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! // Create and attach document element
//! const html = try doc.createElement("html");
//! doc.document_element = html;
//! _ = try doc.node.appendChild(html);
//! ```
//!
//! ### Building a DOM Tree
//! ```zig
//! const doc = try Document.init(allocator);
//! defer doc.release();
//!
//! const html = try doc.createElement("html");
//! doc.document_element = html;
//! _ = try doc.node.appendChild(html);
//!
//! const body = try doc.createElement("body");
//! _ = try html.appendChild(body);
//!
//! const div = try doc.createElement("div");
//! try Element.setAttribute(div, "id", "content");
//! _ = try body.appendChild(div);
//!
//! const text = try doc.createTextNode("Hello, World!");
//! _ = try div.appendChild(&text.character_data.node);
//! ```
//!
//! ### Querying the DOM
//! ```zig
//! // Find by ID
//! if (doc.getElementById("content")) |element| {
//!     // Element found
//! }
//!
//! // Find with CSS selectors
//! if (try doc.querySelector(".highlight")) |element| {
//!     // First matching element
//! }
//!
//! const all_divs = try doc.querySelectorAll("div");
//! defer {
//!     all_divs.deinit();
//!     allocator.destroy(all_divs);
//! }
//! ```
//!
//! ### Creating Different Node Types
//! ```zig
//! // Elements
//! const div = try doc.createElement("div");
//! defer div.release();
//!
//! // Text nodes
//! const text = try doc.createTextNode("Content");
//! defer text.release();
//!
//! // Comments
//! const comment = try doc.createComment("TODO: Add more content");
//! defer comment.release();
//!
//! // Events
//! const event = try doc.createEvent("click");
//! defer event.release();
//! ```
//!
//! ## Memory Management
//!
//! Document owns its base node and manages the document tree. When released,
//! the document releases its node (which recursively releases all children).
//! Individual nodes created via factory methods must be either:
//! - Appended to the document tree (managed by the tree)
//! - Explicitly released if kept outside the tree
//!
//! ## Thread Safety
//!
//! Document is not thread-safe. All operations should be performed from a single thread.
//! For concurrent access, external synchronization is required.

const std = @import("std");
const Node = @import("node.zig").Node;
const NodeType = @import("node.zig").NodeType;
const Element = @import("element.zig").Element;
const Text = @import("text.zig").Text;
const Comment = @import("comment.zig").Comment;
const Event = @import("event.zig").Event;
const NodeList = @import("node_list.zig").NodeList;
const Range = @import("range.zig").Range;
const NodeIterator = @import("node_iterator.zig").NodeIterator;
const TreeWalker = @import("tree_walker.zig").TreeWalker;
const NodeFilter = @import("node_filter.zig");

/// Document represents a web document and serves as an entry point to the DOM tree.
///
/// See: https://dom.spec.whatwg.org/#interface-document
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Document
pub const Document = struct {
    const Self = @This();

    /// Base node interface (#document)
    node: *Node,

    /// The document element (root element, typically <html>)
    /// See: https://dom.spec.whatwg.org/#concept-document-element
    document_element: ?*Node,

    /// Allocator for memory management
    allocator: std.mem.Allocator,

    /// Initialize a new Document.
    ///
    /// Creates a document node with node type `document_node` and node name "#document".
    /// The document element is initially null and should be set by appending an element
    /// to the document.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-document
    ///
    /// ## Examples
    ///
    /// ### Basic Initialization
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    /// ```
    ///
    /// ### With Document Element
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const html = try doc.createElement("html");
    /// doc.document_element = html;
    /// _ = try doc.node.appendChild(html);
    /// ```
    ///
    /// ## Memory Management
    /// The caller is responsible for calling `release()` when done.
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .node = try Node.init(allocator, .document_node, "#document"),
            .document_element = null,
            .allocator = allocator,
        };
        return self;
    }

    /// Release the document and all its resources.
    ///
    /// Releases the document's node (which recursively releases all children)
    /// and frees the document structure itself.
    ///
    /// ## Examples
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    /// ```
    pub fn release(self: *Self) void {
        self.node.release();
        self.allocator.destroy(self);
    }

    /// Create a new element with the given tag name.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-createelement
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createElement
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The createElement(localName, options) method steps are:
    /// > 1. If localName is not a valid element local name, throw "InvalidCharacterError"
    /// > 2. If this is an HTML document, set localName to ASCII lowercase
    /// > 3. Return the result of creating an element
    ///
    /// This implementation preserves tag name case exactly as provided and sets the owner document.
    ///
    /// ## Parameters
    /// - `tag_name`: The element's tag name (case-preserved)
    ///
    /// ## Returns
    /// A new element node with the specified tag name.
    ///
    /// ## Examples
    ///
    /// ### Creating Elements
    /// ```zig
    /// const div = try doc.createElement("div");
    /// defer div.release();
    ///
    /// const span = try doc.createElement("span");
    /// defer span.release();
    /// ```
    ///
    /// ### Building a Tree
    /// ```zig
    /// const html = try doc.createElement("html");
    /// doc.document_element = html;
    /// _ = try doc.node.appendChild(html);
    ///
    /// const body = try doc.createElement("body");
    /// _ = try html.appendChild(body);
    /// ```
    ///
    /// ### With Attributes
    /// ```zig
    /// const div = try doc.createElement("div");
    /// defer div.release();
    /// try Element.setAttribute(div, "id", "main");
    /// try Element.setAttribute(div, "class", "container");
    /// ```
    ///
    /// ## Memory Management
    /// The returned node must be either:
    /// - Appended to the document tree (managed by the tree)
    /// - Explicitly released with `node.release()`
    pub fn createElement(self: *Self, tag_name: []const u8) !*Node {
        const element = try Element.create(self.allocator, tag_name);
        element.owner_document = self;
        return element;
    }

    /// Create a new text node with the given data.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-createtextnode
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createTextNode
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The createTextNode(data) method steps are to return a new Text node
    /// > whose data is data and node document is this.
    ///
    /// ## Parameters
    /// - `data`: The text content for the node
    ///
    /// ## Returns
    /// A new Text node with the specified content.
    ///
    /// ## Examples
    ///
    /// ### Basic Text Node
    /// ```zig
    /// const text = try doc.createTextNode("Hello, World!");
    /// defer text.release();
    /// ```
    ///
    /// ### Empty Text Node
    /// ```zig
    /// const empty = try doc.createTextNode("");
    /// defer empty.release();
    /// ```
    ///
    /// ### Adding to Element
    /// ```zig
    /// const div = try doc.createElement("div");
    /// defer div.release();
    ///
    /// const text = try doc.createTextNode("Content");
    /// _ = try div.appendChild(&text.character_data.node);
    /// ```
    ///
    /// ### Large Text
    /// ```zig
    /// const large_text = "Lorem ipsum dolor sit amet...";
    /// const text = try doc.createTextNode(large_text);
    /// defer text.release();
    /// ```
    ///
    /// ## Memory Management
    /// The returned text node must be either appended to the document tree
    /// or explicitly released.
    pub fn createTextNode(self: *Self, data: []const u8) !*Text {
        const text = try Text.init(self.allocator, data);
        text.character_data.node.owner_document = self;
        return text;
    }

    /// Create a new comment node with the given data.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-createcomment
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createComment
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The createComment(data) method steps are to return a new Comment node
    /// > whose data is data and node document is this.
    ///
    /// ## Parameters
    /// - `data`: The comment content
    ///
    /// ## Returns
    /// A new Comment node with the specified content.
    ///
    /// ## Examples
    ///
    /// ### Basic Comment
    /// ```zig
    /// const comment = try doc.createComment("TODO: Implement feature");
    /// defer comment.release();
    /// ```
    ///
    /// ### Empty Comment
    /// ```zig
    /// const empty = try doc.createComment("");
    /// defer empty.release();
    /// ```
    ///
    /// ### Adding to Document
    /// ```zig
    /// const comment = try doc.createComment("Copyright 2025");
    /// _ = try doc.node.appendChild(&comment.character_data.node);
    /// ```
    ///
    /// ### Documentation Comment
    /// ```zig
    /// const doc_comment = try doc.createComment(
    ///     "This section contains the main content"
    /// );
    /// defer doc_comment.release();
    /// ```
    ///
    /// ## Memory Management
    /// The returned comment node must be either appended to the document tree
    /// or explicitly released.
    pub fn createComment(self: *Self, data: []const u8) !*Comment {
        const comment = try Comment.init(self.allocator, data);
        comment.character_data.node.owner_document = self;
        return comment;
    }

    /// Create a new event with the given type.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-createevent
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createEvent
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The createEvent(interface) method is a legacy API for creating events.
    /// > Modern code should use event constructors instead.
    ///
    /// ## Parameters
    /// - `event_type`: The type of event (e.g., "click", "submit")
    ///
    /// ## Returns
    /// A new Event object with the specified type.
    ///
    /// ## Examples
    ///
    /// ### Creating Events
    /// ```zig
    /// const click_event = try doc.createEvent("click");
    /// defer click_event.release();
    ///
    /// const submit_event = try doc.createEvent("submit");
    /// defer submit_event.release();
    /// ```
    ///
    /// ### Dispatching Events
    /// ```zig
    /// const event = try doc.createEvent("custom");
    /// defer event.release();
    ///
    /// // Dispatch to an element
    /// if (doc.getElementById("button")) |button| {
    ///     try Element.dispatchEvent(button, event);
    /// }
    /// ```
    ///
    /// ## Note
    /// This is a legacy API. Modern code should use Event constructors directly.
    pub fn createEvent(self: *Self, event_type: []const u8) !*Event {
        return try Event.init(self.allocator, event_type, .{});
    }

    /// Create a new Range object.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-createrange
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createRange
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The createRange() method steps are to return a new live range with
    /// > (this, 0) as its start and end.
    ///
    /// ## Returns
    /// A new Range object with both start and end set to (document, 0).
    ///
    /// ## Examples
    ///
    /// ### Basic Range Creation
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// // Range is initially collapsed at document start
    /// try std.testing.expect(range.collapsed());
    /// ```
    ///
    /// ### Using with Document Content
    /// ```zig
    /// const range = try doc.createRange();
    /// defer range.deinit();
    ///
    /// const text = try doc.createTextNode("Hello");
    /// _ = try doc.node.appendChild(text.character_data.node);
    ///
    /// // Select the text node
    /// try range.selectNode(text.character_data.node);
    /// ```
    pub fn createRange(self: *Self) !*Range {
        const range = try Range.init(self.allocator);
        // Per WHATWG spec: Range starts at (document, 0)
        try range.setStart(self.node, 0);
        try range.setEnd(self.node, 0);
        return range;
    }

    /// Create a new NodeIterator over a subtree.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-createnodeiterator
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createNodeIterator
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The createNodeIterator(root, whatToShow, filter) method creates a new
    /// > NodeIterator object with the given root, whatToShow filter, and optional
    /// > callback filter.
    ///
    /// ## Parameters
    /// - `root`: The root node at which to begin the traversal
    /// - `what_to_show`: Bitmask of NodeFilter.SHOW_* constants (default: SHOW_ALL)
    /// - `filter`: Optional callback for custom filtering (can be null)
    ///
    /// ## Returns
    /// A new NodeIterator positioned before the root node.
    ///
    /// ## Examples
    ///
    /// ### Iterate All Nodes
    /// ```zig
    /// const iterator = try doc.createNodeIterator(
    ///     doc.node,
    ///     0xFFFFFFFF, // SHOW_ALL
    ///     null
    /// );
    /// defer iterator.release();
    ///
    /// while (try iterator.nextNode()) |node| {
    ///     // Process each node
    /// }
    /// ```
    ///
    /// ### Iterate Only Elements
    /// ```zig
    /// const iterator = try doc.createNodeIterator(
    ///     doc.node,
    ///     0x1, // SHOW_ELEMENT
    ///     null
    /// );
    /// defer iterator.release();
    /// ```
    pub fn createNodeIterator(
        self: *Self,
        root: *Node,
        what_to_show: u32,
        filter: ?NodeFilter.FilterCallback,
    ) !*NodeIterator {
        return try NodeIterator.init(self.allocator, root, what_to_show, filter);
    }

    /// Create a new TreeWalker over a subtree.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-createtreewalker
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/createTreeWalker
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The createTreeWalker(root, whatToShow, filter) method creates a new
    /// > TreeWalker object with the given root, whatToShow filter, and optional
    /// > callback filter.
    ///
    /// ## Parameters
    /// - `root`: The root node at which to begin the traversal
    /// - `what_to_show`: Bitmask of NodeFilter.SHOW_* constants (default: SHOW_ALL)
    /// - `filter`: Optional callback for custom filtering (can be null)
    ///
    /// ## Returns
    /// A new TreeWalker with currentNode set to root.
    ///
    /// ## Examples
    ///
    /// ### Tree Walking
    /// ```zig
    /// const walker = try doc.createTreeWalker(
    ///     doc.node,
    ///     0xFFFFFFFF, // SHOW_ALL
    ///     null
    /// );
    /// defer walker.release();
    ///
    /// // Walk through children
    /// if (try walker.firstChild()) |child| {
    ///     // Process first child
    /// }
    /// ```
    ///
    /// ### Element-Only Walking
    /// ```zig
    /// const walker = try doc.createTreeWalker(
    ///     root,
    ///     0x1, // SHOW_ELEMENT
    ///     null
    /// );
    /// defer walker.release();
    /// ```
    pub fn createTreeWalker(
        self: *Self,
        root: *Node,
        what_to_show: u32,
        filter: ?NodeFilter.FilterCallback,
    ) !*TreeWalker {
        return try TreeWalker.init(self.allocator, root, what_to_show, filter);
    }

    /// Find the first element with the specified ID.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-nonelementparentnode-getelementbyid
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementById
    ///
    /// ## WHATWG Specification (§4.2.4)
    /// > The getElementById(elementId) method steps are to return the first element,
    /// > in tree order, within this's descendants, whose ID is elementId;
    /// > otherwise, if there is no such element, null.
    ///
    /// ## Parameters
    /// - `id`: The ID attribute value to search for
    ///
    /// ## Returns
    /// The first element with the matching ID, or null if not found.
    ///
    /// ## Examples
    ///
    /// ### Finding by ID
    /// ```zig
    /// if (doc.getElementById("main")) |element| {
    ///     // Element found
    ///     const data = Element.getData(element);
    ///     std.debug.print("Found: {s}\n", .{data.tag_name});
    /// }
    /// ```
    ///
    /// ### Not Found
    /// ```zig
    /// const result = doc.getElementById("nonexistent");
    /// try std.testing.expect(result == null);
    /// ```
    ///
    /// ### Building and Finding
    /// ```zig
    /// const div = try doc.createElement("div");
    /// try Element.setAttribute(div, "id", "content");
    /// _ = try root.appendChild(div);
    ///
    /// const found = doc.getElementById("content");
    /// try std.testing.expectEqual(div, found.?);
    /// ```
    ///
    /// ## Performance
    /// O(n) where n is the number of descendants. Implementations may optimize
    /// this with ID indexes.
    pub fn getElementById(self: *const Self, id: []const u8) ?*Node {
        if (self.document_element) |root| {
            return Element.getElementById(root, id);
        }
        return null;
    }

    /// Get all elements with the specified tag name.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-getelementsbytagname
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByTagName
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The getElementsByTagName(qualifiedName) method returns an HTMLCollection
    /// > of all descendant elements whose qualified name matches qualifiedName.
    ///
    /// ## Parameters
    /// - `tag_name`: The tag name to search for (case-sensitive)
    ///
    /// ## Returns
    /// A NodeList containing all matching elements.
    ///
    /// ## Examples
    ///
    /// ### Finding All Divs
    /// ```zig
    /// const divs = try doc.getElementsByTagName("div");
    /// defer {
    ///     divs.deinit();
    ///     allocator.destroy(divs);
    /// }
    ///
    /// for (divs.items.items) |div| {
    ///     // Process each div
    /// }
    /// ```
    ///
    /// ### No Matches
    /// ```zig
    /// const list = try doc.getElementsByTagName("nonexistent");
    /// defer {
    ///     list.deinit();
    ///     allocator.destroy(list);
    /// }
    /// try std.testing.expectEqual(@as(usize, 0), list.length());
    /// ```
    ///
    /// ## Memory Management
    /// The returned NodeList must be deinitialized and destroyed by the caller.
    pub fn getElementsByTagName(self: *const Self, tag_name: []const u8) !*NodeList {
        const list = try self.allocator.create(NodeList);
        list.* = NodeList.init(self.allocator);

        if (self.document_element) |root| {
            try Element.getElementsByTagName(root, tag_name, list);
        }

        return list;
    }

    /// Get all elements with the specified class name(s).
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-getelementsbyclassname
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/getElementsByClassName
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The getElementsByClassName(classNames) method returns an HTMLCollection
    /// > of all descendant elements that have all the classes in classNames.
    ///
    /// ## Parameters
    /// - `class_names`: Space-separated list of class names
    ///
    /// ## Returns
    /// A NodeList containing all matching elements.
    ///
    /// ## Examples
    ///
    /// ### Single Class
    /// ```zig
    /// const items = try doc.getElementsByClassName("item");
    /// defer {
    ///     items.deinit();
    ///     allocator.destroy(items);
    /// }
    /// ```
    ///
    /// ### Multiple Classes
    /// ```zig
    /// const elements = try doc.getElementsByClassName("active important");
    /// defer {
    ///     elements.deinit();
    ///     allocator.destroy(elements);
    /// }
    /// ```
    ///
    /// ## Memory Management
    /// The returned NodeList must be deinitialized and destroyed by the caller.
    pub fn getElementsByClassName(self: *const Self, class_names: []const u8) !*NodeList {
        const list = try self.allocator.create(NodeList);
        list.* = NodeList.init(self.allocator);

        if (self.document_element) |root| {
            try Element.getElementsByClassName(root, class_names, list);
        }

        return list;
    }

    /// Find the first element matching a CSS selector.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-parentnode-queryselector
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector
    ///
    /// ## WHATWG Specification (§4.2.6)
    /// > The querySelector(selectors) method returns the first element that is
    /// > a descendant of this that matches selectors.
    ///
    /// Supports CSS selectors including:
    /// - Tag selectors: `div`, `span`
    /// - ID selectors: `#main`, `#content`
    /// - Class selectors: `.highlight`, `.active`
    /// - Attribute selectors: `[type="text"]`, `[disabled]`
    /// - Universal selector: `*`
    ///
    /// ## Parameters
    /// - `selector_str`: A CSS selector string
    ///
    /// ## Returns
    /// The first matching element, or null if no match is found.
    /// Returns an error if the selector is invalid.
    ///
    /// ## Examples
    ///
    /// ### ID Selector
    /// ```zig
    /// if (try doc.querySelector("#main")) |element| {
    ///     // Element found
    /// }
    /// ```
    ///
    /// ### Class Selector
    /// ```zig
    /// if (try doc.querySelector(".highlight")) |element| {
    ///     // First element with class "highlight"
    /// }
    /// ```
    ///
    /// ### Tag Selector
    /// ```zig
    /// if (try doc.querySelector("div")) |element| {
    ///     // First div element
    /// }
    /// ```
    ///
    /// ### Attribute Selector
    /// ```zig
    /// if (try doc.querySelector("[type='text']")) |element| {
    ///     // First element with type="text"
    /// }
    /// ```
    ///
    /// ## Performance
    /// O(n) where n is the number of descendants. More specific selectors
    /// (like ID selectors) may be optimized by implementations.
    pub fn querySelector(self: *const Self, selector_str: []const u8) !?*Node {
        if (self.document_element) |root| {
            return try Element.querySelector(root, selector_str);
        }
        return null;
    }

    /// Find all elements matching a CSS selector.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-parentnode-queryselectorall
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelectorAll
    ///
    /// ## WHATWG Specification (§4.2.6)
    /// > The querySelectorAll(selectors) method returns all elements that are
    /// > descendants of this that match selectors.
    ///
    /// Supports the same CSS selectors as querySelector().
    ///
    /// ## Parameters
    /// - `selector_str`: A CSS selector string
    ///
    /// ## Returns
    /// A NodeList containing all matching elements.
    /// Returns an error if the selector is invalid.
    ///
    /// ## Examples
    ///
    /// ### Finding All Divs
    /// ```zig
    /// const divs = try doc.querySelectorAll("div");
    /// defer {
    ///     divs.deinit();
    ///     allocator.destroy(divs);
    /// }
    /// ```
    ///
    /// ### Finding by Class
    /// ```zig
    /// const items = try doc.querySelectorAll(".item");
    /// defer {
    ///     items.deinit();
    ///     allocator.destroy(items);
    /// }
    ///
    /// for (items.items.items) |item| {
    ///     // Process each item
    /// }
    /// ```
    ///
    /// ### Complex Selector
    /// ```zig
    /// const inputs = try doc.querySelectorAll("[type='text']");
    /// defer {
    ///     inputs.deinit();
    ///     allocator.destroy(inputs);
    /// }
    /// ```
    ///
    /// ## Memory Management
    /// The returned NodeList must be deinitialized and destroyed by the caller.
    pub fn querySelectorAll(self: *const Self, selector_str: []const u8) !*NodeList {
        const list = try self.allocator.create(NodeList);
        list.* = NodeList.init(self.allocator);

        if (self.document_element) |root| {
            const root_list = try Element.querySelectorAll(root, selector_str);
            defer {
                root_list.deinit();
                self.allocator.destroy(root_list);
            }

            for (root_list.items.items) |item| {
                try list.items.append(self.allocator, item);
            }
        }

        return list;
    }

    /// Adopt a node from another document.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-adoptnode
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/adoptNode
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The adoptNode(node) method transfers a node from another document to this
    /// > document. The node's owner document is changed to this document.
    ///
    /// ## Parameters
    /// - `node`: The node to adopt
    ///
    /// ## Returns
    /// The adopted node (same reference, but now owned by this document).
    ///
    /// ## Examples
    ///
    /// ### Basic Adoption
    /// ```zig
    /// const other_doc = try Document.init(allocator);
    /// defer other_doc.release();
    ///
    /// const element = try other_doc.createElement("div");
    /// const adopted = doc.adoptNode(element);
    /// try std.testing.expectEqual(
    ///     @as(*anyopaque, @ptrCast(doc)),
    ///     adopted.owner_document.?
    /// );
    /// ```
    pub fn adoptNode(self: *Self, node: *Node) *Node {
        node.owner_document = self;
        return node;
    }

    /// Import a node from another document.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-importnode
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/importNode
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The importNode(node, deep) method creates a copy of a node from another
    /// > document. If deep is true, the copy includes all descendants.
    ///
    /// ## Parameters
    /// - `node`: The node to import (from another document)
    /// - `deep`: If true, recursively clone all descendants
    ///
    /// ## Returns
    /// A new node owned by this document, cloned from the original.
    ///
    /// ## Examples
    ///
    /// ### Shallow Import
    /// ```zig
    /// const other_doc = try Document.init(allocator);
    /// defer other_doc.release();
    ///
    /// const original = try other_doc.createElement("div");
    /// defer original.release();
    ///
    /// const imported = try doc.importNode(original, false);
    /// defer imported.release();
    /// ```
    ///
    /// ### Deep Import
    /// ```zig
    /// const imported = try doc.importNode(original, true);
    /// defer imported.release();
    /// // Includes all children of original
    /// ```
    pub fn importNode(self: *Self, node: *const Node, deep: bool) !*Node {
        const imported = try node.cloneNode(deep);
        imported.owner_document = self;
        return imported;
    }

    /// Get the document URI (currently not implemented).
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-documenturi
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/documentURI
    ///
    /// ## Returns
    /// null (not yet implemented)
    pub fn getDocumentURI(self: *const Self) ?[]const u8 {
        _ = self;
        return null;
    }

    /// Get the document's compatibility mode.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-compatmode
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/compatMode
    ///
    /// ## WHATWG Specification (§4.5)
    /// > Returns "BackCompat" if the document is in quirks mode, and "CSS1Compat"
    /// > if the document is in no-quirks (standards) mode.
    ///
    /// ## Returns
    /// "CSS1Compat" (standards mode)
    pub fn getCompatMode(self: *const Self) []const u8 {
        _ = self;
        return "CSS1Compat";
    }

    /// Get the document's character encoding.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-characterset
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/characterSet
    ///
    /// ## Returns
    /// "UTF-8" (the encoding name)
    pub fn getCharacterSet(self: *const Self) []const u8 {
        _ = self;
        return "UTF-8";
    }

    /// Get the document's character encoding (legacy alias).
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-charset
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/charset
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The charset attribute is a legacy alias of characterSet.
    ///
    /// ## Note
    /// This is a legacy API. Modern code should use getCharacterSet() instead.
    ///
    /// ## Returns
    /// "UTF-8" (the encoding name)
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const encoding = doc.getCharset();
    /// try std.testing.expectEqualStrings("UTF-8", encoding);
    /// ```
    pub fn getCharset(self: *const Self) []const u8 {
        return self.getCharacterSet();
    }

    /// Get the document's input encoding (legacy alias).
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-inputencoding
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/inputEncoding
    ///
    /// ## WHATWG Specification (§4.5)
    /// > The inputEncoding attribute is a legacy alias of characterSet.
    ///
    /// ## Note
    /// This is a legacy API. Modern code should use getCharacterSet() instead.
    ///
    /// ## Returns
    /// "UTF-8" (the encoding name)
    ///
    /// ## Example
    /// ```zig
    /// const doc = try Document.init(allocator);
    /// defer doc.release();
    ///
    /// const encoding = doc.getInputEncoding();
    /// try std.testing.expectEqualStrings("UTF-8", encoding);
    /// ```
    pub fn getInputEncoding(self: *const Self) []const u8 {
        return self.getCharacterSet();
    }

    /// Get the document's content type.
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-contenttype
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/contentType
    ///
    /// ## Returns
    /// "application/xml" (the MIME type)
    pub fn getContentType(self: *const Self) []const u8 {
        _ = self;
        return "application/xml";
    }

    /// Get the document type declaration (currently not implemented).
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-doctype
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/doctype
    ///
    /// ## Returns
    /// null (not yet implemented)
    pub fn getDoctype(self: *const Self) ?*anyopaque {
        _ = self;
        return null;
    }

    /// Get the DOM implementation (currently not implemented).
    ///
    /// **Spec**: https://dom.spec.whatwg.org/#dom-document-implementation
    /// **MDN**: https://developer.mozilla.org/en-US/docs/Web/API/Document/implementation
    ///
    /// ## Returns
    /// null (not yet implemented)
    pub fn getImplementation(self: *const Self) ?*anyopaque {
        _ = self;
        return null;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "Document creation" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expectEqual(NodeType.document_node, doc.node.node_type);
    try std.testing.expectEqualStrings("#document", doc.node.node_name);
}

test "Document createElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("div");
    defer element.release();

    const data = Element.getData(element);
    try std.testing.expectEqualStrings("div", data.tag_name);
    try std.testing.expectEqual(@as(*anyopaque, @ptrCast(doc)), element.owner_document.?);
}

test "Document createElement - empty tag name" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("");
    defer element.release();

    const data = Element.getData(element);
    try std.testing.expectEqualStrings("", data.tag_name);
}

test "Document createElement - special characters in tag name" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const element = try doc.createElement("my-custom-element");
    defer element.release();

    const data = Element.getData(element);
    try std.testing.expectEqualStrings("my-custom-element", data.tag_name);
}

test "Document createElement - multiple elements" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElement("div");
    defer div.release();

    const span = try doc.createElement("span");
    defer span.release();

    const p = try doc.createElement("p");
    defer p.release();

    const div_data = Element.getData(div);
    const span_data = Element.getData(span);
    const p_data = Element.getData(p);

    try std.testing.expectEqualStrings("div", div_data.tag_name);
    try std.testing.expectEqualStrings("span", span_data.tag_name);
    try std.testing.expectEqualStrings("p", p_data.tag_name);
}

test "Document createTextNode" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("Hello");
    defer text.release();

    try std.testing.expectEqualStrings("Hello", text.getData());
    try std.testing.expectEqual(@as(*anyopaque, @ptrCast(doc)), text.character_data.node.owner_document.?);
}

test "Document createTextNode - empty text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const text = try doc.createTextNode("");
    defer text.release();

    try std.testing.expectEqualStrings("", text.getData());
}

test "Document createTextNode - large text" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const large_text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " ++
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";

    const text = try doc.createTextNode(large_text);
    defer text.release();

    try std.testing.expectEqualStrings(large_text, text.getData());
}

test "Document createComment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("This is a comment");
    defer comment.release();

    try std.testing.expectEqualStrings("This is a comment", comment.getData());
}

test "Document createComment - empty comment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const comment = try doc.createComment("");
    defer comment.release();

    try std.testing.expectEqualStrings("", comment.getData());
}

test "Document createEvent" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const event = try doc.createEvent("click");
    defer event.deinit();

    try std.testing.expectEqualStrings("click", event.type_name);
}

test "Document tree operations" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const body = try doc.createElement("body");
    try Element.setAttribute(body, "id", "main");
    _ = try root.appendChild(body);

    const found = doc.getElementById("main");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(body, found.?);
}

test "Document getElementById - not found" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const found = doc.getElementById("nonexistent");
    try std.testing.expect(found == null);
}

test "Document getElementById - no document element" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const found = doc.getElementById("anything");
    try std.testing.expect(found == null);
}

test "Document getElementsByTagName" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const div1 = try doc.createElement("div");
    _ = try root.appendChild(div1);

    const div2 = try doc.createElement("div");
    _ = try root.appendChild(div2);

    const span = try doc.createElement("span");
    _ = try root.appendChild(span);

    const list = try doc.getElementsByTagName("div");
    defer {
        list.deinit();
        allocator.destroy(list);
    }

    try std.testing.expectEqual(@as(usize, 2), list.length());
}

test "Document getElementsByTagName - no matches" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const list = try doc.getElementsByTagName("nonexistent");
    defer {
        list.deinit();
        allocator.destroy(list);
    }

    try std.testing.expectEqual(@as(usize, 0), list.length());
}

test "Document getElementsByClassName" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const div1 = try doc.createElement("div");
    try Element.setClassName(div1, "item");
    _ = try root.appendChild(div1);

    const div2 = try doc.createElement("div");
    try Element.setClassName(div2, "item");
    _ = try root.appendChild(div2);

    const span = try doc.createElement("span");
    _ = try root.appendChild(span);

    const list = try doc.getElementsByClassName("item");
    defer {
        list.deinit();
        allocator.destroy(list);
    }

    try std.testing.expectEqual(@as(usize, 2), list.length());
}

test "Document querySelector" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const body = try doc.createElement("body");
    try Element.setAttribute(body, "id", "main");
    _ = try root.appendChild(body);

    const div = try doc.createElement("div");
    try Element.setClassName(div, "content");
    _ = try body.appendChild(div);

    const found_id = try doc.querySelector("#main");
    try std.testing.expect(found_id != null);
    try std.testing.expectEqual(body, found_id.?);

    const found_class = try doc.querySelector(".content");
    try std.testing.expect(found_class != null);
    try std.testing.expectEqual(div, found_class.?);

    const not_found = try doc.querySelector("#nonexistent");
    try std.testing.expect(not_found == null);
}

test "Document querySelector - tag selector" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const div1 = try doc.createElement("div");
    _ = try root.appendChild(div1);

    const div2 = try doc.createElement("div");
    _ = try root.appendChild(div2);

    const found = try doc.querySelector("div");
    try std.testing.expect(found != null);
    try std.testing.expectEqual(div1, found.?); // Returns first match
}

test "Document querySelector - no document element" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const found = try doc.querySelector("#anything");
    try std.testing.expect(found == null);
}

test "Document querySelectorAll" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const div1 = try doc.createElement("div");
    try Element.setClassName(div1, "item");
    _ = try root.appendChild(div1);

    const div2 = try doc.createElement("div");
    try Element.setClassName(div2, "item");
    _ = try root.appendChild(div2);

    const span = try doc.createElement("span");
    _ = try root.appendChild(span);

    const list = try doc.querySelectorAll(".item");
    defer {
        list.deinit();
        allocator.destroy(list);
    }

    try std.testing.expectEqual(@as(usize, 2), list.length());
}

test "Document querySelectorAll - no matches" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    doc.document_element = root;
    _ = try doc.node.appendChild(root);

    const list = try doc.querySelectorAll(".nonexistent");
    defer {
        list.deinit();
        allocator.destroy(list);
    }

    try std.testing.expectEqual(@as(usize, 0), list.length());
}

test "Document adoptNode" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const element = try doc1.createElement("div");
    defer element.release();

    try std.testing.expectEqual(@as(*anyopaque, @ptrCast(doc1)), element.owner_document.?);

    const adopted = doc2.adoptNode(element);
    try std.testing.expectEqual(@as(*anyopaque, @ptrCast(doc2)), adopted.owner_document.?);
    try std.testing.expectEqual(element, adopted);
}

test "Document importNode - shallow" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const original = try doc1.createElement("div");
    defer original.release();
    try Element.setAttribute(original, "id", "test");

    const child = try doc1.createElement("span");
    _ = try original.appendChild(child);

    const imported = try doc2.importNode(original, false);
    defer imported.release();

    try std.testing.expectEqual(@as(*anyopaque, @ptrCast(doc2)), imported.owner_document.?);

    // importNode creates a basic node clone, element data is not preserved
    // This is a limitation of the current cloneNode implementation
    try std.testing.expectEqual(NodeType.element_node, imported.node_type);

    // Shallow import should not include children
    try std.testing.expect(imported.firstChild() == null);

    // Original should still have child
    try std.testing.expect(original.firstChild() != null);
}

test "Document importNode - deep" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();

    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const original = try doc1.createElement("div");
    defer original.release();

    const child = try doc1.createElement("span");
    _ = try original.appendChild(child);

    const imported = try doc2.importNode(original, true);
    defer imported.release();

    try std.testing.expectEqual(@as(*anyopaque, @ptrCast(doc2)), imported.owner_document.?);

    // Deep import should include children
    try std.testing.expect(imported.firstChild() != null);

    const imported_child = imported.firstChild().?;
    // importNode creates a basic node clone, element data is not preserved
    // This is a limitation of the current cloneNode implementation
    try std.testing.expectEqual(NodeType.element_node, imported_child.node_type);
}

test "Document - integration test with multiple node types" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create document structure
    const html = try doc.createElement("html");
    doc.document_element = html;
    _ = try doc.node.appendChild(html);

    const head = try doc.createElement("head");
    _ = try html.appendChild(head);

    const body = try doc.createElement("body");
    try Element.setAttribute(body, "id", "main");
    _ = try html.appendChild(body);

    // Add content
    const h1 = try doc.createElement("h1");
    _ = try body.appendChild(h1);

    const title_text = try Node.init(allocator, .text_node, "Welcome");
    _ = try h1.appendChild(title_text);

    const div = try doc.createElement("div");
    try Element.setClassName(div, "content");
    _ = try body.appendChild(div);

    const p = try doc.createElement("p");
    _ = try div.appendChild(p);

    const paragraph_text = try Node.init(allocator, .text_node, "This is a paragraph.");
    _ = try p.appendChild(paragraph_text);

    const comment = try Node.init(allocator, .comment_node, "End of content");
    _ = try div.appendChild(comment);

    // Test queries
    const found_body = doc.getElementById("main");
    try std.testing.expectEqual(body, found_body.?);

    const found_h1 = try doc.querySelector("h1");
    try std.testing.expectEqual(h1, found_h1.?);

    const found_divs = try doc.getElementsByTagName("div");
    defer {
        found_divs.deinit();
        allocator.destroy(found_divs);
    }
    try std.testing.expectEqual(@as(usize, 1), found_divs.length());

    const found_content = try doc.querySelector(".content");
    try std.testing.expectEqual(div, found_content.?);
}

test "Document - memory leak test (factory methods)" {
    const allocator = std.testing.allocator;

    // Run 100 iterations to detect memory leaks
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const doc = try Document.init(allocator);
        defer doc.release();

        // Create various node types
        const element = try doc.createElement("div");
        defer element.release();

        const text = try doc.createTextNode("text");
        defer text.release();

        const comment = try doc.createComment("comment");
        defer comment.release();

        const event = try doc.createEvent("click");
        defer event.deinit();
    }
}

test "Document - memory leak test (query methods)" {
    const allocator = std.testing.allocator;

    // Run 100 iterations to detect memory leaks
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const doc = try Document.init(allocator);
        defer doc.release();

        const root = try doc.createElement("html");
        doc.document_element = root;
        _ = try doc.node.appendChild(root);

        const div = try doc.createElement("div");
        try Element.setAttribute(div, "id", "test");
        try Element.setClassName(div, "item");
        _ = try root.appendChild(div);

        _ = doc.getElementById("test");

        const list1 = try doc.getElementsByTagName("div");
        list1.deinit();
        allocator.destroy(list1);

        const list2 = try doc.getElementsByClassName("item");
        list2.deinit();
        allocator.destroy(list2);

        _ = try doc.querySelector("#test");

        const list3 = try doc.querySelectorAll(".item");
        list3.deinit();
        allocator.destroy(list3);
    }
}

test "Document - getters" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expectEqual(@as(?[]const u8, null), doc.getDocumentURI());
    try std.testing.expectEqualStrings("CSS1Compat", doc.getCompatMode());
    try std.testing.expectEqualStrings("UTF-8", doc.getCharacterSet());
    try std.testing.expectEqualStrings("application/xml", doc.getContentType());
    try std.testing.expectEqual(@as(?*anyopaque, null), doc.getDoctype());
    try std.testing.expectEqual(@as(?*anyopaque, null), doc.getImplementation());
}

test "Document - legacy charset and inputEncoding aliases" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Test legacy charset alias
    try std.testing.expectEqualStrings("UTF-8", doc.getCharset());
    try std.testing.expectEqualStrings(doc.getCharacterSet(), doc.getCharset());

    // Test legacy inputEncoding alias
    try std.testing.expectEqualStrings("UTF-8", doc.getInputEncoding());
    try std.testing.expectEqualStrings(doc.getCharacterSet(), doc.getInputEncoding());

    // All three should return the same value
    try std.testing.expectEqualStrings(doc.getCharacterSet(), doc.getCharset());
    try std.testing.expectEqualStrings(doc.getCharacterSet(), doc.getInputEncoding());
    try std.testing.expectEqualStrings(doc.getCharset(), doc.getInputEncoding());
}

test "Document.createRange - basic creation" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const range = try doc.createRange();
    defer range.deinit();

    // Range should be collapsed at document start (document, 0)
    try std.testing.expect(range.collapsed());
    try std.testing.expectEqual(doc.node, range.start_container.?);
    try std.testing.expectEqual(@as(usize, 0), range.start_offset);
    try std.testing.expectEqual(doc.node, range.end_container.?);
    try std.testing.expectEqual(@as(usize, 0), range.end_offset);
}

test "Document.createNodeIterator - basic creation" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create iterator showing all nodes (starting at document root)
    const iterator = try doc.createNodeIterator(doc.node, 0xFFFFFFFF, null);
    defer iterator.deinit();

    try std.testing.expectEqual(doc.node, iterator.root);
    try std.testing.expectEqual(@as(u32, 0xFFFFFFFF), iterator.what_to_show);
}

test "Document.createTreeWalker - basic creation" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create some content to walk
    const div = try doc.createElement("div");
    _ = try doc.node.appendChild(div);

    // Create tree walker
    const walker = try doc.createTreeWalker(doc.node, 0xFFFFFFFF, null);
    defer walker.deinit();

    try std.testing.expectEqual(doc.node, walker.root);
    try std.testing.expectEqual(doc.node, walker.current_node);
    try std.testing.expectEqual(@as(u32, 0xFFFFFFFF), walker.what_to_show);
}
