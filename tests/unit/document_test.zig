const std = @import("std");
const dom = @import("dom");

// Import all commonly used types
const Node = dom.Node;
const NodeType = dom.NodeType;
const Element = dom.Element;
const Text = dom.Text;
const Comment = dom.Comment;
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;
const StringPool = dom.StringPool;
const SelectorCache = dom.SelectorCache;

test "StringPool - string deduplication" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Intern same string twice
    const str1 = try pool.intern("test-element");
    const str2 = try pool.intern("test-element");

    // Should return same pointer (deduplicated)
    try std.testing.expectEqual(str1.ptr, str2.ptr);
    try std.testing.expectEqualStrings("test-element", str1);

    // Only one string allocated
    try std.testing.expectEqual(@as(usize, 1), pool.count());
}

test "StringPool - multiple strings" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Intern multiple different strings
    const custom1 = try pool.intern("my-custom-element");
    const custom2 = try pool.intern("my-custom-element");

    // Should return same pointer (deduplicated)
    try std.testing.expectEqual(custom1.ptr, custom2.ptr);
    try std.testing.expectEqualStrings("my-custom-element", custom1);

    // One string allocated
    try std.testing.expectEqual(@as(usize, 1), pool.count());

    // Add another string
    _ = try pool.intern("another-element");
    try std.testing.expectEqual(@as(usize, 2), pool.count());
}

test "StringPool - multiple unique strings" {
    const allocator = std.testing.allocator;

    var pool = StringPool.init(allocator);
    defer pool.deinit();

    // Intern multiple unique strings
    const str1 = try pool.intern("element-one");
    const str2 = try pool.intern("custom-element");
    const str3 = try pool.intern("element-three");

    try std.testing.expectEqualStrings("element-one", str1);
    try std.testing.expectEqualStrings("custom-element", str2);
    try std.testing.expectEqualStrings("element-three", str3);

    // Three unique strings allocated
    try std.testing.expectEqual(@as(usize, 3), pool.count());
}

test "Document - creation and cleanup" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.document, doc.prototype.node_type);
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));
    try std.testing.expectEqual(@as(usize, 0), doc.node_ref_count.load(.monotonic));

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("#document", doc.prototype.nodeName());
    try std.testing.expect(doc.prototype.nodeValue() == null);
}

test "Document - dual ref counting" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Initial external refs
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));

    // Acquire external ref
    doc.acquire();
    try std.testing.expectEqual(@as(usize, 2), doc.external_ref_count.load(.monotonic));

    // Release external ref
    doc.release();
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));
}

test "Document - createElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create element
    const elem = try doc.createElement("test-element");
    defer elem.prototype.release();

    // Verify element properties
    try std.testing.expectEqualStrings("test-element", elem.tag_name);
    try std.testing.expectEqual(&doc.prototype, elem.prototype.owner_document.?);
    try std.testing.expect(elem.prototype.node_id > 0);

    // Verify document's node ref count incremented
    try std.testing.expectEqual(@as(usize, 1), doc.node_ref_count.load(.monotonic));
}

test "Document - createTextNode" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create text node
    const text = try doc.createTextNode("Hello World");
    defer text.prototype.release();

    // Verify text properties
    try std.testing.expectEqualStrings("Hello World", text.data);
    try std.testing.expectEqual(&doc.prototype, text.prototype.owner_document.?);
    try std.testing.expect(text.prototype.node_id > 0);

    // Verify document's node ref count incremented
    try std.testing.expectEqual(@as(usize, 1), doc.node_ref_count.load(.monotonic));
}

test "Document - createComment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create comment node
    const comment = try doc.createComment(" TODO: implement ");
    defer comment.prototype.release();

    // Verify comment properties
    try std.testing.expectEqualStrings(" TODO: implement ", comment.data);
    try std.testing.expectEqual(&doc.prototype, comment.prototype.owner_document.?);
    try std.testing.expect(comment.prototype.node_id > 0);

    // Verify document's node ref count incremented
    try std.testing.expectEqual(@as(usize, 1), doc.node_ref_count.load(.monotonic));
}

test "Document - createDocumentFragment" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create document fragment
    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    // Verify fragment properties
    try std.testing.expect(fragment.prototype.node_type == .document_fragment);
    try std.testing.expectEqualStrings("#document-fragment", fragment.prototype.nodeName());
    try std.testing.expectEqual(&doc.prototype, fragment.prototype.owner_document.?);
    try std.testing.expect(fragment.prototype.node_id > 0);

    // Verify document's node ref count incremented
    try std.testing.expectEqual(@as(usize, 1), doc.node_ref_count.load(.monotonic));
}

test "Document - createDocumentFragment with children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();

    // Add children to fragment
    const elem1 = try doc.createElement("div");
    const elem2 = try doc.createElement("span");

    _ = try fragment.prototype.appendChild(&elem1.prototype);
    _ = try fragment.prototype.appendChild(&elem2.prototype);

    // Verify fragment has children
    try std.testing.expect(fragment.prototype.hasChildNodes());
    try std.testing.expectEqual(@as(usize, 2), fragment.prototype.childNodes().length());
}

test "Document - string interning in createElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create multiple elements with same tag
    const elem1 = try doc.createElement("test-element");
    defer elem1.prototype.release();

    const elem2 = try doc.createElement("test-element");
    defer elem2.prototype.release();

    // Tag names should point to same interned string
    try std.testing.expectEqual(elem1.tag_name.ptr, elem2.tag_name.ptr);

    // String pool should have: 5 pre-interned namespaces + 1 tag name = 6 total
    try std.testing.expectEqual(@as(usize, 6), doc.string_pool.count());
}

test "Document - multiple node types" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create various nodes
    const elem = try doc.createElement("test-element");
    defer elem.prototype.release();

    const text = try doc.createTextNode("content");
    defer text.prototype.release();

    const comment = try doc.createComment(" note ");
    defer comment.prototype.release();

    // All should have unique IDs
    try std.testing.expect(elem.prototype.node_id != text.prototype.node_id);
    try std.testing.expect(text.prototype.node_id != comment.prototype.node_id);
    try std.testing.expect(elem.prototype.node_id != comment.prototype.node_id);

    // All should reference document
    try std.testing.expectEqual(&doc.prototype, elem.prototype.owner_document.?);
    try std.testing.expectEqual(&doc.prototype, text.prototype.owner_document.?);
    try std.testing.expectEqual(&doc.prototype, comment.prototype.owner_document.?);

    // Document should track 3 node refs
    try std.testing.expectEqual(@as(usize, 3), doc.node_ref_count.load(.monotonic));
}

test "Document - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple document
    {
        const doc = try Document.init(allocator);
        defer doc.release();
    }

    // Test 2: Document with elements
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const elem1 = try doc.createElement("element-one");
        defer elem1.prototype.release();

        const elem2 = try doc.createElement("element-two");
        defer elem2.prototype.release();
    }

    // Test 3: Document with all node types
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        const elem = try doc.createElement("test-element");
        defer elem.prototype.release();

        const text = try doc.createTextNode("test");
        defer text.prototype.release();

        const comment = try doc.createComment(" test ");
        defer comment.prototype.release();
    }

    // Test 4: Document with string interning
    {
        const doc = try Document.init(allocator);
        defer doc.release();

        // Create elements with interning
        const elem1 = try doc.createElement("test-element");
        defer elem1.prototype.release();

        const elem2 = try doc.createElement("another-element");
        defer elem2.prototype.release();

        const elem3 = try doc.createElement("test-element"); // Reuse interned
        defer elem3.prototype.release();

        // Custom element
        const custom = try doc.createElement("my-custom-element");
        defer custom.prototype.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Document - external ref counting" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Initial state
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));

    // Acquire multiple times
    doc.acquire();
    doc.acquire();
    try std.testing.expectEqual(@as(usize, 3), doc.external_ref_count.load(.monotonic));

    // Release
    doc.release();
    try std.testing.expectEqual(@as(usize, 2), doc.external_ref_count.load(.monotonic));

    doc.release();
    try std.testing.expectEqual(@as(usize, 1), doc.external_ref_count.load(.monotonic));
}

test "Document - documentElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Initially no document element
    try std.testing.expect(doc.documentElement() == null);

    // Create and add root element (Phase 2 will do this via appendChild)
    const root_elem = try doc.createElement("root");
    defer root_elem.prototype.release();

    // Manually add to document children
    doc.prototype.first_child = &root_elem.prototype;
    doc.prototype.last_child = &root_elem.prototype;
    root_elem.prototype.parent_node = &doc.prototype;
    root_elem.prototype.setHasParent(true);

    // documentElement should return the root element
    const root = doc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqual(root_elem, root.?);
    try std.testing.expectEqualStrings("root", root.?.tag_name);

    // Clean up manual connection
    doc.prototype.first_child = null;
    doc.prototype.last_child = null;
    root_elem.prototype.parent_node = null;
    root_elem.prototype.setHasParent(false);
}

test "Document - documentElement with mixed children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Create comment (before root element)
    const comment = try doc.createComment(" metadata ");
    defer comment.prototype.release();

    // Create root element
    const root_elem = try doc.createElement("root");
    defer root_elem.prototype.release();

    // Manually add both to document (comment first, then root element)
    doc.prototype.first_child = &comment.prototype;
    doc.prototype.last_child = &root_elem.prototype;
    comment.prototype.next_sibling = &root_elem.prototype;
    comment.prototype.parent_node = &doc.prototype;
    root_elem.prototype.parent_node = &doc.prototype;
    root_elem.prototype.setHasParent(true);
    comment.prototype.setHasParent(true);

    // documentElement should skip comment and return root element
    const root = doc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqual(root_elem, root.?);

    // Clean up manual connections
    doc.prototype.first_child = null;
    doc.prototype.last_child = null;
    comment.prototype.next_sibling = null;
    comment.prototype.parent_node = null;
    root_elem.prototype.parent_node = null;
    root_elem.prototype.setHasParent(false);
    comment.prototype.setHasParent(false);
}

test "Document - doctype property returns null (no DocumentType yet)" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // No DocumentType children, so doctype() should return null
    try std.testing.expect(doc.doctype() == null);
}

test "Document - doctype property with element children" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Add an element child
    const elem = try doc.createElement("html");

    _ = try doc.prototype.appendChild(&elem.prototype);

    // Still no DocumentType, should return null
    try std.testing.expect(doc.doctype() == null);
}

test "SelectorCache - basic caching" {
    const allocator = std.testing.allocator;

    var cache = SelectorCache.init(allocator);
    defer cache.deinit();

    // Get selector (should parse and cache)
    const parsed1 = try cache.get("#main");
    try std.testing.expect(parsed1.fast_path == .simple_id);
    try std.testing.expectEqual(@as(usize, 1), cache.count());

    // Get same selector (should return cached)
    const parsed2 = try cache.get("#main");
    try std.testing.expect(parsed1 == parsed2); // Same pointer
    try std.testing.expectEqual(@as(usize, 1), cache.count());

    // Get different selector
    const parsed3 = try cache.get(".button");
    try std.testing.expect(parsed3.fast_path == .simple_class);
    try std.testing.expectEqual(@as(usize, 2), cache.count());
}

test "SelectorCache - fast path detection" {
    const allocator = std.testing.allocator;

    var cache = SelectorCache.init(allocator);
    defer cache.deinit();

    // ID selector
    const id_sel = try cache.get("#test");
    try std.testing.expect(id_sel.fast_path == .simple_id);
    try std.testing.expectEqualStrings("test", id_sel.identifier.?);

    // Class selector
    const class_sel = try cache.get(".button");
    try std.testing.expect(class_sel.fast_path == .simple_class);
    try std.testing.expectEqualStrings("button", class_sel.identifier.?);

    // Tag selector
    const tag_sel = try cache.get("div");
    try std.testing.expect(tag_sel.fast_path == .simple_tag);
    try std.testing.expectEqualStrings("div", tag_sel.identifier.?);

    // Generic selector
    const gen_sel = try cache.get("div > p");
    try std.testing.expect(gen_sel.fast_path == .generic);
    try std.testing.expect(gen_sel.identifier == null);
}

test "SelectorCache - FIFO eviction" {
    const allocator = std.testing.allocator;

    var cache = SelectorCache.init(allocator);
    cache.max_size = 3; // Small cache for testing
    defer cache.deinit();

    // Fill cache
    _ = try cache.get("#id1");
    _ = try cache.get("#id2");
    _ = try cache.get("#id3");
    try std.testing.expectEqual(@as(usize, 3), cache.count());

    // Add one more (should evict #id1)
    _ = try cache.get("#id4");
    try std.testing.expectEqual(@as(usize, 3), cache.count());

    // Verify #id1 was evicted
    const id1_again = try cache.get("#id1");
    try std.testing.expectEqual(@as(usize, 3), cache.count()); // Still 3 (evicted #id2)
    try std.testing.expectEqualStrings("#id1", id1_again.selector_string);
}

test "SelectorCache - clear" {
    const allocator = std.testing.allocator;

    var cache = SelectorCache.init(allocator);
    defer cache.deinit();

    // Add some entries
    _ = try cache.get("#main");
    _ = try cache.get(".button");
    _ = try cache.get("div");
    try std.testing.expectEqual(@as(usize, 3), cache.count());

    // Clear cache
    cache.clear();
    try std.testing.expectEqual(@as(usize, 0), cache.count());

    // Can add again
    _ = try cache.get("#main");
    try std.testing.expectEqual(@as(usize, 1), cache.count());
}

test "Document - selector cache integration" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    // Selector cache should be initialized
    try std.testing.expectEqual(@as(usize, 0), doc.selector_cache.count());

    // We'll test actual usage in the next step when we integrate with querySelector
}

test "Document - getElementById basic" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "submit");
    _ = try root.prototype.appendChild(&button.prototype);

    // O(1) lookup!
    const found = doc.getElementById("submit");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);

    // Not found
    const not_found = doc.getElementById("missing");
    try std.testing.expect(not_found == null);
}

test "Document - getElementById updates on setAttribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    _ = try root.prototype.appendChild(&button.prototype);

    // Initially no ID
    try std.testing.expect(doc.getElementById("test") == null);

    // Set ID
    try button.setAttribute("id", "test");
    const found1 = doc.getElementById("test");
    try std.testing.expect(found1 != null);
    try std.testing.expect(found1.? == button);

    // Change ID
    try button.setAttribute("id", "changed");
    try std.testing.expect(doc.getElementById("test") == null);
    const found2 = doc.getElementById("changed");
    try std.testing.expect(found2 != null);
    try std.testing.expect(found2.? == button);
}

test "Document - getElementById cleans up on removeAttribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "remove-test");
    _ = try root.prototype.appendChild(&button.prototype);

    // ID exists
    try std.testing.expect(doc.getElementById("remove-test") != null);

    // Remove ID attribute
    button.removeAttribute("id");
    try std.testing.expect(doc.getElementById("remove-test") == null);
}

test "Document - getElementById multiple elements" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create multiple elements with IDs
    const button1 = try doc.createElement("button");
    try button1.setAttribute("id", "btn1");
    _ = try root.prototype.appendChild(&button1.prototype);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("id", "btn2");
    _ = try root.prototype.appendChild(&button2.prototype);

    const button3 = try doc.createElement("button");
    try button3.setAttribute("id", "btn3");
    _ = try root.prototype.appendChild(&button3.prototype);

    // All should be findable
    try std.testing.expect(doc.getElementById("btn1").? == button1);
    try std.testing.expect(doc.getElementById("btn2").? == button2);
    try std.testing.expect(doc.getElementById("btn3").? == button3);
}

test "Document - querySelector uses getElementById for #id" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "target");
    _ = try root.prototype.appendChild(&button.prototype);

    // querySelector("#id") should use fast path with O(1) lookup
    const found = try doc.querySelector("#target");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

test "Document - getElementsByTagName basic" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button1 = try doc.createElement("button");
    _ = try root.prototype.appendChild(&button1.prototype);

    const button2 = try doc.createElement("button");
    _ = try root.prototype.appendChild(&button2.prototype);

    const div = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div.prototype);

    // Get all buttons
    const buttons = doc.getElementsByTagName("button");
    try std.testing.expectEqual(@as(usize, 2), buttons.length());
    try std.testing.expect(buttons.item(0).? == button1);
    try std.testing.expect(buttons.item(1).? == button2);

    // Get all divs
    const divs = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 1), divs.length());
    try std.testing.expect(divs.item(0).? == div);

    // Not found
    const spans = doc.getElementsByTagName("span");
    try std.testing.expectEqual(@as(usize, 0), spans.length());
}

test "Document - tag map maintained on createElement" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create multiple elements with same tag
    const div1 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div2.prototype);

    const div3 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div3.prototype);

    // Tag map should have all three
    const divs = doc.getElementsByTagName("div");
    try std.testing.expectEqual(@as(usize, 3), divs.length());
}

test "Document - tag map cleaned up on element removal" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const div1 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div2.prototype);

    // Should have 2 divs
    {
        const divs = doc.getElementsByTagName("div");
        try std.testing.expectEqual(@as(usize, 2), divs.length());
    }

    // Remove one div
    _ = try root.prototype.removeChild(&div1.prototype);
    div1.prototype.release();

    // Should have 1 div
    {
        const divs = doc.getElementsByTagName("div");
        try std.testing.expectEqual(@as(usize, 1), divs.length());
        try std.testing.expect(divs.item(0).? == div2);
    }
}

test "Document - getElementsByClassName basic" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn primary");
    _ = try root.prototype.appendChild(&button1.prototype);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn");
    _ = try root.prototype.appendChild(&button2.prototype);

    const div = try doc.createElement("div");
    try div.setAttribute("class", "container");
    _ = try root.prototype.appendChild(&div.prototype);

    // Get all "btn" elements
    const btns = doc.getElementsByClassName("btn");
    try std.testing.expectEqual(@as(usize, 2), btns.length());
    try std.testing.expect(btns.item(0).? == button1);
    try std.testing.expect(btns.item(1).? == button2);

    // Get all "primary" elements
    const primaries = doc.getElementsByClassName("primary");
    try std.testing.expectEqual(@as(usize, 1), primaries.length());
    try std.testing.expect(primaries.item(0).? == button1);

    // Get all "container" elements
    const containers = doc.getElementsByClassName("container");
    try std.testing.expectEqual(@as(usize, 1), containers.length());
    try std.testing.expect(containers.item(0).? == div);

    // Not found
    const notfound = doc.getElementsByClassName("notfound");
    try std.testing.expectEqual(@as(usize, 0), notfound.length());
}

test "Document - class map maintained on setAttribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const div = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div.prototype);

    // Initially no class
    {
        const elements = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 0), elements.length());
    }

    // Add class
    try div.setAttribute("class", "foo bar");
    {
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 1), foos.length());
        try std.testing.expect(foos.item(0).? == div);

        const bars = doc.getElementsByClassName("bar");
        try std.testing.expectEqual(@as(usize, 1), bars.length());
        try std.testing.expect(bars.item(0).? == div);
    }

    // Change class
    try div.setAttribute("class", "baz");
    {
        // Old classes should be gone
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 0), foos.length());

        const bars = doc.getElementsByClassName("bar");
        try std.testing.expectEqual(@as(usize, 0), bars.length());

        // New class should be present
        const bazs = doc.getElementsByClassName("baz");
        try std.testing.expectEqual(@as(usize, 1), bazs.length());
        try std.testing.expect(bazs.item(0).? == div);
    }

    // Add class
    try div.setAttribute("class", "foo bar");
    {
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 1), foos.length());
        try std.testing.expect(foos.item(0).? == div);

        const bars = doc.getElementsByClassName("bar");
        try std.testing.expectEqual(@as(usize, 1), bars.length());
        try std.testing.expect(bars.item(0).? == div);
    }

    // Change class
    try div.setAttribute("class", "baz");
    {
        // Old classes should be gone
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 0), foos.length());

        const bars = doc.getElementsByClassName("bar");
        try std.testing.expectEqual(@as(usize, 0), bars.length());

        // New class should be present
        const bazs = doc.getElementsByClassName("baz");
        try std.testing.expectEqual(@as(usize, 1), bazs.length());
        try std.testing.expect(bazs.item(0).? == div);
    }
}

test "Document - class map cleaned up on removeAttribute" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const div = try doc.createElement("div");
    try div.setAttribute("class", "foo bar");
    _ = try root.prototype.appendChild(&div.prototype);

    // Should have classes
    {
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 1), foos.length());
    }

    // Remove class attribute
    div.removeAttribute("class");

    // Should be empty
    {
        const foos = doc.getElementsByClassName("foo");
        try std.testing.expectEqual(@as(usize, 0), foos.length());

        const bars = doc.getElementsByClassName("bar");
        try std.testing.expectEqual(@as(usize, 0), bars.length());
    }
}

test "Document - class map cleaned up on element removal" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const elem1 = try doc.createElement("element");
    try elem1.setAttribute("class", "testclass1");
    _ = try root.prototype.appendChild(&elem1.prototype);

    const elem2 = try doc.createElement("element");
    try elem2.setAttribute("class", "testclass1");
    _ = try root.prototype.appendChild(&elem2.prototype);

    // Should have 2 elements with class "testclass1"
    {
        const results = doc.getElementsByClassName("testclass1");
        try std.testing.expectEqual(@as(usize, 2), results.length());
    }

    // Remove one element
    _ = try root.prototype.removeChild(&elem1.prototype);
    elem1.prototype.release();

    // Should have 1 element with class "testclass1"
    {
        const results = doc.getElementsByClassName("testclass1");
        try std.testing.expectEqual(@as(usize, 1), results.length());
        try std.testing.expect(results.item(0).? == elem2);
    }
}

test "Document - createDocumentType HTML5" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("", doctype.publicId);
    try std.testing.expectEqualStrings("", doctype.systemId);
}

test "Document - createDocumentType with public/system IDs" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType(
        "svg",
        "-//W3C//DTD SVG 1.1//EN",
        "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd",
    );
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("svg", doctype.name);
    try std.testing.expectEqualStrings("-//W3C//DTD SVG 1.1//EN", doctype.publicId);
    try std.testing.expectEqualStrings("http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd", doctype.systemId);
}

test "Document - doctype initially null" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    try std.testing.expect(doc.doctype() == null);
}

test "Document - doctype returns first DocumentType child" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const doctype = try doc.createDocumentType("html", "", "");
    _ = try doc.prototype.appendChild(&doctype.prototype);

    const dt = doc.doctype();
    try std.testing.expect(dt != null);
    try std.testing.expect(dt.? == doctype);
    try std.testing.expectEqualStrings("html", dt.?.name);
}

test "Document - createDocumentType interns strings" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const name = try allocator.dupe(u8, "html");
    defer allocator.free(name);

    const doctype = try doc.createDocumentType(name, "", "");
    defer doctype.prototype.release();

    // String should be interned (not the same pointer)
    try std.testing.expect(doctype.name.ptr != name.ptr);
    try std.testing.expectEqualStrings("html", doctype.name);
}

// ============================================================================
// Document.importNode() Tests (Phase 10)
// ============================================================================

test "Document - importNode shallow copy of element" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();
    const doc2 = try Document.init(allocator);
    defer doc2.release();

    // Create element in doc1 with attributes
    const elem1 = try doc1.createElement("container");
    try elem1.setAttribute("id", "original");
    try elem1.setAttribute("class", "test");
    _ = try doc1.prototype.appendChild(&elem1.prototype);

    // Import shallow copy to doc2
    const imported = try doc2.importNode(&elem1.prototype, false);
    defer imported.release();
    try std.testing.expect(imported.node_type == .element);

    const imported_elem: *Element = @fieldParentPtr("prototype", imported);

    // Verify it's a different node
    try std.testing.expect(imported != &elem1.prototype);

    // Verify attributes were copied
    try std.testing.expectEqualStrings("container", imported_elem.tag_name);
    try std.testing.expectEqualStrings("original", imported_elem.getAttribute("id").?);
    try std.testing.expectEqualStrings("test", imported_elem.getAttribute("class").?);

    // Verify ownership changed to doc2
    try std.testing.expect(imported.getOwnerDocument() == doc2);

    // Verify original unchanged
    try std.testing.expect(elem1.prototype.getOwnerDocument() == doc1);
    try std.testing.expectEqualStrings("original", elem1.getAttribute("id").?);
}

test "Document - importNode deep copy with children" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();
    const doc2 = try Document.init(allocator);
    defer doc2.release();

    // Create element tree in doc1
    const parent = try doc1.createElement("parent");
    _ = try doc1.prototype.appendChild(&parent.prototype);

    const child1 = try doc1.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);

    const child2 = try doc1.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);

    const text = try doc1.createTextNode("text content");
    _ = try child1.prototype.appendChild(&text.prototype);

    // Import deep copy to doc2
    const imported = try doc2.importNode(&parent.prototype, true);
    defer imported.release();
    const imported_elem: *Element = @fieldParentPtr("prototype", imported);

    // Verify structure was cloned
    try std.testing.expectEqualStrings("parent", imported_elem.tag_name);

    // Check children were copied
    var imported_child = imported.first_child;
    try std.testing.expect(imported_child != null);
    const imported_child1: *Element = @fieldParentPtr("prototype", imported_child.?);
    try std.testing.expectEqualStrings("child1", imported_child1.tag_name);

    imported_child = imported_child.?.next_sibling;
    try std.testing.expect(imported_child != null);
    const imported_child2: *Element = @fieldParentPtr("prototype", imported_child.?);
    try std.testing.expectEqualStrings("child2", imported_child2.tag_name);

    // Verify text node was copied
    const text_node = imported_child1.prototype.first_child;
    try std.testing.expect(text_node != null);
    try std.testing.expect(text_node.?.node_type == .text);

    // Verify all nodes owned by doc2
    try std.testing.expect(imported.getOwnerDocument() == doc2);
    try std.testing.expect(imported_child1.prototype.getOwnerDocument() == doc2);
    try std.testing.expect(imported_child2.prototype.getOwnerDocument() == doc2);
    try std.testing.expect(text_node.?.getOwnerDocument() == doc2);

    // Verify original tree unchanged
    try std.testing.expect(parent.prototype.first_child != null);
    try std.testing.expect(parent.prototype.getOwnerDocument() == doc1);
}

test "Document - importNode text node" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();
    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const text1 = try doc1.createTextNode("Hello, World!");
    defer text1.prototype.release();

    const imported = try doc2.importNode(&text1.prototype, false);
    defer imported.release();
    try std.testing.expect(imported.node_type == .text);

    const imported_text: *Text = @fieldParentPtr("prototype", imported);
    try std.testing.expectEqualStrings("Hello, World!", imported_text.data);

    // Verify ownership
    try std.testing.expect(imported.getOwnerDocument() == doc2);
    try std.testing.expect(text1.prototype.getOwnerDocument() == doc1);
}

test "Document - importNode comment node" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();
    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const comment1 = try doc1.createComment("This is a comment");
    defer comment1.prototype.release();

    const imported = try doc2.importNode(&comment1.prototype, false);
    defer imported.release();
    try std.testing.expect(imported.node_type == .comment);

    const imported_comment: *Comment = @fieldParentPtr("prototype", imported);
    try std.testing.expectEqualStrings("This is a comment", imported_comment.data);

    // Verify ownership
    try std.testing.expect(imported.getOwnerDocument() == doc2);
}

test "Document - importNode document fragment with children" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();
    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const frag = try doc1.createDocumentFragment();
    defer frag.prototype.release(); // Release orphaned fragment in doc1

    const frag_child1 = try doc1.createElement("child1");
    _ = try frag.prototype.appendChild(&frag_child1.prototype);

    const frag_child2 = try doc1.createElement("child2");
    _ = try frag.prototype.appendChild(&frag_child2.prototype);

    const imported = try doc2.importNode(&frag.prototype, true);
    defer imported.release(); // Release orphaned imported node in doc2

    try std.testing.expect(imported.node_type == .document_fragment);

    // Verify children were copied
    const child1 = imported.first_child;
    try std.testing.expect(child1 != null);
    try std.testing.expect(child1.?.node_type == .element);

    const child2 = child1.?.next_sibling;
    try std.testing.expect(child2 != null);
    try std.testing.expect(child2.?.node_type == .element);

    // Verify ownership
    try std.testing.expect(imported.getOwnerDocument() == doc2);
    try std.testing.expect(child1.?.getOwnerDocument() == doc2);
    try std.testing.expect(child2.?.getOwnerDocument() == doc2);
}

test "Document - importNode cannot import document" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();
    const doc2 = try Document.init(allocator);
    defer doc2.release();

    // Attempting to import a document should fail
    const result = doc2.importNode(&doc1.prototype, false);
    try std.testing.expectError(error.NotSupported, result);
}

test "Document - importNode shallow copy has no children" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();
    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const parent = try doc1.createElement("parent");
    defer parent.prototype.release(); // Release orphaned parent in doc1

    const parent_child = try doc1.createElement("child");
    _ = try parent.prototype.appendChild(&parent_child.prototype);

    // Shallow import should not copy children
    const imported = try doc2.importNode(&parent.prototype, false);
    defer imported.release(); // Release orphaned imported node in doc2

    try std.testing.expect(imported.first_child == null);
    try std.testing.expect(imported.last_child == null);
}

test "Document - importNode cloned node not connected" {
    const allocator = std.testing.allocator;

    const doc1 = try Document.init(allocator);
    defer doc1.release();
    const doc2 = try Document.init(allocator);
    defer doc2.release();

    const elem = try doc1.createElement("connected");
    _ = try doc1.prototype.appendChild(&elem.prototype);

    // Element is connected in doc1
    try std.testing.expect(elem.prototype.isConnected());

    // Imported node should not be connected
    const imported = try doc2.importNode(&elem.prototype, false);
    try std.testing.expect(!imported.isConnected());

    // After appending to doc2, it should be connected
    _ = try doc2.prototype.appendChild(imported);
    try std.testing.expect(imported.isConnected());
}

// ============================================================================
// Document Metadata Properties Tests
// ============================================================================

test "Document.getURL returns empty string by default" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const url = doc.getURL();
    try std.testing.expectEqualStrings("", url);
}

test "Document.getDocumentURI returns same as URL" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const url = doc.getURL();
    const uri = doc.getDocumentURI();
    try std.testing.expectEqualStrings(url, uri);
}

test "Document.getCompatMode returns CSS1Compat" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const mode = doc.getCompatMode();
    try std.testing.expectEqualStrings("CSS1Compat", mode);
}

test "Document.getCharacterSet returns UTF-8" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const charset = doc.getCharacterSet();
    try std.testing.expectEqualStrings("UTF-8", charset);
}

test "Document.getCharset is alias for characterSet" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const characterSet = doc.getCharacterSet();
    const charset = doc.getCharset();
    try std.testing.expectEqualStrings(characterSet, charset);
}

test "Document.getInputEncoding is alias for characterSet" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const characterSet = doc.getCharacterSet();
    const inputEncoding = doc.getInputEncoding();
    try std.testing.expectEqualStrings(characterSet, inputEncoding);
}

test "Document.getContentType returns application/xml" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const contentType = doc.getContentType();
    try std.testing.expectEqualStrings("application/xml", contentType);
}

// ============================================================================
// DOMImplementation Tests
// ============================================================================

test "Document.getImplementation returns DOMImplementation" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    // DOMImplementation is zero-sized, so just verify we can call methods on it
    const supported = impl.hasFeature();
    try std.testing.expect(supported);
}

test "DOMImplementation.hasFeature always returns true" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    try std.testing.expect(impl.hasFeature());
}

test "DOMImplementation.createDocumentType creates DocumentType" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const doctype = try impl.createDocumentType("html", "", "");
    defer doctype.prototype.release();

    try std.testing.expectEqualStrings("html", doctype.name);
    try std.testing.expectEqualStrings("", doctype.publicId);
    try std.testing.expectEqualStrings("", doctype.systemId);
}

test "DOMImplementation.createDocument creates empty document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const newDoc = try impl.createDocument(null, "", null);
    defer newDoc.release();

    // Empty document has no children
    try std.testing.expect(newDoc.prototype.first_child == null);
}

test "DOMImplementation.createDocument with root element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const newDoc = try impl.createDocument(null, "root", null);
    defer newDoc.release();

    // Document should have root element
    const root = newDoc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqualStrings("root", root.?.tag_name);
}

test "DOMImplementation.createDocument with namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const newDoc = try impl.createDocument(
        "http://www.w3.org/2000/svg",
        "svg",
        null,
    );
    defer newDoc.release();

    // Document should have root element with namespace
    const root = newDoc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqualStrings("svg", root.?.tag_name);
}

test "DOMImplementation.createDocument with doctype" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const impl = doc.getImplementation();
    const doctype = try impl.createDocumentType("html", "", "");
    defer doctype.prototype.release(); // Release our reference

    const newDoc = try impl.createDocument(null, "html", doctype);
    defer newDoc.release();
    // createDocument's appendChild acquired the doctype, so newDoc now owns it

    // Document should have both doctype and root element
    const dt = newDoc.doctype();
    try std.testing.expect(dt != null);
    try std.testing.expectEqualStrings("html", dt.?.name);

    const root = newDoc.documentElement();
    try std.testing.expect(root != null);
    try std.testing.expectEqualStrings("html", root.?.tag_name);
}

// === Namespace Support Tests ===

test "Document.createElementNS creates SVG element" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const circle = try doc.createElementNS("http://www.w3.org/2000/svg", "circle");
    defer circle.prototype.release();

    // Check namespace properties
    try std.testing.expectEqualStrings("http://www.w3.org/2000/svg", circle.namespace_uri.?);
    try std.testing.expect(circle.prefix == null);
    try std.testing.expectEqualStrings("circle", circle.local_name);
    try std.testing.expectEqualStrings("circle", circle.tag_name);
}

test "Document.createElementNS with prefix" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_rect = try doc.createElementNS("http://www.w3.org/2000/svg", "svg:rect");
    defer svg_rect.prototype.release();

    // Check namespace properties
    try std.testing.expectEqualStrings("http://www.w3.org/2000/svg", svg_rect.namespace_uri.?);
    try std.testing.expectEqualStrings("svg", svg_rect.prefix.?);
    try std.testing.expectEqualStrings("rect", svg_rect.local_name);
    try std.testing.expectEqualStrings("svg:rect", svg_rect.tag_name);
}

test "Document.createElementNS with null namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElementNS(null, "custom");
    defer elem.prototype.release();

    // Check namespace properties
    try std.testing.expect(elem.namespace_uri == null);
    try std.testing.expect(elem.prefix == null);
    try std.testing.expectEqualStrings("custom", elem.local_name);
    try std.testing.expectEqualStrings("custom", elem.tag_name);
}

test "Document.createElementNS with HTML namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const div = try doc.createElementNS("http://www.w3.org/1999/xhtml", "div");
    defer div.prototype.release();

    // Check namespace properties
    try std.testing.expectEqualStrings("http://www.w3.org/1999/xhtml", div.namespace_uri.?);
    try std.testing.expect(div.prefix == null);
    try std.testing.expectEqualStrings("div", div.local_name);
}

test "Document.createElementNS with MathML namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const math = try doc.createElementNS("http://www.w3.org/1998/Math/MathML", "math");
    defer math.prototype.release();

    // Check namespace properties
    try std.testing.expectEqualStrings("http://www.w3.org/1998/Math/MathML", math.namespace_uri.?);
    try std.testing.expect(math.prefix == null);
    try std.testing.expectEqualStrings("math", math.local_name);
}

test "Document.createElementNS invalid qualified name error" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Invalid: starts with digit
    try std.testing.expectError(error.InvalidCharacterError, doc.createElementNS(null, "123div"));

    // Invalid: starts with colon
    try std.testing.expectError(error.InvalidCharacterError, doc.createElementNS(null, ":div"));

    // Invalid: ends with colon
    try std.testing.expectError(error.InvalidCharacterError, doc.createElementNS(null, "div:"));

    // Invalid: multiple colons
    try std.testing.expectError(error.InvalidCharacterError, doc.createElementNS(null, "a:b:c"));

    // Invalid: contains space
    try std.testing.expectError(error.InvalidCharacterError, doc.createElementNS(null, "div span"));
}

test "Document.createElementNS uses pre-interned common namespaces" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Create two SVG elements
    const circle1 = try doc.createElementNS("http://www.w3.org/2000/svg", "circle");
    defer circle1.prototype.release();

    const circle2 = try doc.createElementNS("http://www.w3.org/2000/svg", "rect");
    defer circle2.prototype.release();

    // Both should use the same interned namespace string (pointer equality)
    try std.testing.expectEqual(circle1.namespace_uri.?.ptr, circle2.namespace_uri.?.ptr);
    try std.testing.expectEqual(doc.svg_namespace.ptr, circle1.namespace_uri.?.ptr);
}

test "Document common namespaces are interned on init" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Verify all common namespaces are pre-interned
    try std.testing.expectEqualStrings("http://www.w3.org/1999/xhtml", doc.html_namespace);
    try std.testing.expectEqualStrings("http://www.w3.org/2000/svg", doc.svg_namespace);
    try std.testing.expectEqualStrings("http://www.w3.org/1998/Math/MathML", doc.mathml_namespace);
    try std.testing.expectEqualStrings("http://www.w3.org/XML/1998/namespace", doc.xml_namespace);
    try std.testing.expectEqualStrings("http://www.w3.org/2000/xmlns/", doc.xmlns_namespace);
}
