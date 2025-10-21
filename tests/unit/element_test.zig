const std = @import("std");
const dom = @import("dom");

// Import all commonly used types
const Node = dom.Node;
const NodeType = dom.NodeType;
const Element = dom.Element;
const Text = dom.Text;
const Document = dom.Document;
const DocumentFragment = dom.DocumentFragment;
const BloomFilter = dom.BloomFilter;
const AttributeMap = dom.AttributeMap;
const Event = dom.Event;

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
    defer elem.prototype.release();

    // Verify node properties
    try std.testing.expectEqual(NodeType.element, elem.prototype.node_type);
    try std.testing.expectEqual(@as(u32, 1), elem.prototype.getRefCount());
    try std.testing.expectEqualStrings("element", elem.tag_name);

    // Verify vtable dispatch
    try std.testing.expectEqualStrings("element", elem.prototype.nodeName());
    try std.testing.expect(elem.prototype.nodeValue() == null);
}

test "Element - attributes" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.prototype.release();

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
    defer elem.prototype.release();

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
    defer elem.prototype.release();

    try elem.setAttribute("id", "original");
    try elem.setAttribute("class", "foo bar");

    // Clone (shallow)
    const cloned_node = try elem.prototype.cloneNode(false);
    defer cloned_node.release();

    const cloned: *Element = @fieldParentPtr("prototype", cloned_node);

    // Verify clone properties
    try std.testing.expectEqualStrings("element", cloned.tag_name);
    try std.testing.expectEqual(@as(usize, 2), cloned.attributeCount());
    try std.testing.expectEqualStrings("original", cloned.getAttribute("id").?);
    try std.testing.expectEqualStrings("foo bar", cloned.getAttribute("class").?);

    // Verify independent ref counts
    try std.testing.expectEqual(@as(u32, 1), elem.prototype.getRefCount());
    try std.testing.expectEqual(@as(u32, 1), cloned.prototype.getRefCount());
}

test "Element - memory leak test" {
    const allocator = std.testing.allocator;

    // Test 1: Simple creation
    {
        const elem = try Element.create(allocator, "element");
        defer elem.prototype.release();
    }

    // Test 2: With attributes
    {
        const elem = try Element.create(allocator, "element");
        defer elem.prototype.release();

        try elem.setAttribute("id", "test");
        try elem.setAttribute("class", "foo bar");
        try elem.setAttribute("data-value", "123");
    }

    // Test 3: Clone
    {
        const elem = try Element.create(allocator, "item");
        defer elem.prototype.release();

        try elem.setAttribute("id", "original");

        const cloned = try elem.prototype.cloneNode(false);
        defer cloned.release();
    }

    // Test 4: Multiple acquire/release
    {
        const elem = try Element.create(allocator, "p");
        defer elem.prototype.release();

        elem.prototype.acquire();
        defer elem.prototype.release();

        elem.prototype.acquire();
        defer elem.prototype.release();
    }

    // If we reach here without leaks, std.testing.allocator validates success
}

test "Element - ref counting" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.prototype.release();

    // Initial ref count
    try std.testing.expectEqual(@as(u32, 1), elem.prototype.getRefCount());

    // Acquire
    elem.prototype.acquire();
    try std.testing.expectEqual(@as(u32, 2), elem.prototype.getRefCount());

    // Release
    elem.prototype.release();
    try std.testing.expectEqual(@as(u32, 1), elem.prototype.getRefCount());
}

test "Element - id property" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "element");
    defer elem.prototype.release();

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
    defer elem.prototype.release();

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
    defer elem.prototype.release();

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
    defer elem.prototype.release();

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
    defer elem.prototype.release();

    // For non-namespaced elements, localName === tagName
    try std.testing.expectEqualStrings("div", elem.localName());
    try std.testing.expectEqualStrings(elem.tag_name, elem.localName());
}

test "Element - localName for custom element" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "my-custom-element");
    defer elem.prototype.release();

    try std.testing.expectEqualStrings("my-custom-element", elem.localName());
}

test "Element - queryById fast path" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "submit-btn");
    _ = try container.prototype.appendChild(&button.prototype);

    const span = try doc.createElement("span");
    try span.setAttribute("id", "label");
    _ = try container.prototype.appendChild(&span.prototype);

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

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn primary");
    _ = try container.prototype.appendChild(&button1.prototype);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn secondary");
    _ = try container.prototype.appendChild(&button2.prototype);

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

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button = try doc.createElement("button");
    _ = try container.prototype.appendChild(&button.prototype);

    const span = try doc.createElement("span");
    _ = try container.prototype.appendChild(&span.prototype);

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

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn primary");
    _ = try container.prototype.appendChild(&button1.prototype);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn secondary");
    _ = try container.prototype.appendChild(&button2.prototype);

    const span = try doc.createElement("span");
    try span.setAttribute("class", "primary");
    _ = try container.prototype.appendChild(&span.prototype);

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

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button1 = try doc.createElement("button");
    _ = try container.prototype.appendChild(&button1.prototype);

    const button2 = try doc.createElement("button");
    _ = try container.prototype.appendChild(&button2.prototype);

    const span = try doc.createElement("span");
    _ = try container.prototype.appendChild(&span.prototype);

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

test "Element - querySelector uses cache with simple ID" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "submit");
    _ = try container.prototype.appendChild(&button.prototype);

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

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("class", "primary");
    _ = try container.prototype.appendChild(&button.prototype);

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

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn");
    _ = try container.prototype.appendChild(&button1.prototype);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn");
    _ = try container.prototype.appendChild(&button2.prototype);

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

    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("div");
    _ = try doc.prototype.appendChild(&container.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "submit");
    try button.setAttribute("class", "btn primary");
    _ = try container.prototype.appendChild(&button.prototype);

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

test "Element - queryById uses id_map when available" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Build nested structure
    const container = try doc.createElement("div");
    _ = try root.prototype.appendChild(&container.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "deep-button");
    _ = try container.prototype.appendChild(&button.prototype);

    // queryById on root should find button via O(1) id_map lookup
    const found = root.queryById("deep-button");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

test "Element - queryById only returns descendants" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create two separate branches
    const branch1 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&branch1.prototype);

    const branch2 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&branch2.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "target");
    _ = try branch2.prototype.appendChild(&button.prototype);

    // queryById on branch1 should NOT find button (different subtree)
    const not_found = branch1.queryById("target");
    try std.testing.expect(not_found == null);

    // queryById on branch2 should find button
    const found = branch2.queryById("target");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

test "Element - querySelector #id uses id_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create deeply nested structure
    const div1 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("div");
    _ = try div1.prototype.appendChild(&div2.prototype);

    const div3 = try doc.createElement("div");
    _ = try div2.prototype.appendChild(&div3.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "deep-target");
    _ = try div3.prototype.appendChild(&button.prototype);

    // querySelector should use O(1) id_map lookup
    const found = try root.querySelector(allocator, "#deep-target");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

test "Element - setAttribute updates id_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    _ = try root.prototype.appendChild(&button.prototype);

    // Set ID
    try button.setAttribute("id", "original");
    try std.testing.expect(doc.getElementById("original").? == button);

    // Change ID - should update map
    try button.setAttribute("id", "changed");
    try std.testing.expect(doc.getElementById("original") == null);
    try std.testing.expect(doc.getElementById("changed").? == button);
}

test "Element - removeAttribute cleans id_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("id", "temp");
    _ = try root.prototype.appendChild(&button.prototype);

    // ID should be in map
    try std.testing.expect(doc.getElementById("temp").? == button);

    // Remove ID
    button.removeAttribute("id");
    try std.testing.expect(doc.getElementById("temp") == null);
}

test "Element - queryByTagName uses tag_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const div1 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div1.prototype);

    const button = try doc.createElement("button");
    _ = try div1.prototype.appendChild(&button.prototype);

    const div2 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div2.prototype);

    // queryByTagName should use O(k) tag_map lookup
    const found = root.queryByTagName("button");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

test "Element - queryAllByTagName uses tag_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const div1 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div1.prototype);

    const div2 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div2.prototype);

    const button = try doc.createElement("button");
    _ = try root.prototype.appendChild(&button.prototype);

    // queryAllByTagName should use tag_map
    const divs = try root.queryAllByTagName(allocator, "div");
    defer allocator.free(divs);
    try std.testing.expectEqual(@as(usize, 2), divs.len);
}

test "Element - querySelector tag uses tag_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    _ = try root.prototype.appendChild(&button.prototype);

    // querySelector("tag") should use O(k) tag_map lookup
    const found = try root.querySelector(allocator, "button");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

test "Element - queryByClass uses class_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const div1 = try doc.createElement("div");
    _ = try root.prototype.appendChild(&div1.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("class", "btn primary");
    _ = try div1.prototype.appendChild(&button.prototype);

    const div2 = try doc.createElement("div");
    try div2.setAttribute("class", "container");
    _ = try root.prototype.appendChild(&div2.prototype);

    // queryByClass should use O(k) class_map lookup
    const found = root.queryByClass("btn");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);

    // Should also find "primary"
    const primary = root.queryByClass("primary");
    try std.testing.expect(primary != null);
    try std.testing.expect(primary.? == button);
}

test "Element - queryAllByClass uses class_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button1 = try doc.createElement("button");
    try button1.setAttribute("class", "btn");
    _ = try root.prototype.appendChild(&button1.prototype);

    const button2 = try doc.createElement("button");
    try button2.setAttribute("class", "btn primary");
    _ = try root.prototype.appendChild(&button2.prototype);

    const div = try doc.createElement("div");
    try div.setAttribute("class", "container");
    _ = try root.prototype.appendChild(&div.prototype);

    // queryAllByClass should use class_map
    const btns = try root.queryAllByClass(allocator, "btn");
    defer allocator.free(btns);
    try std.testing.expectEqual(@as(usize, 2), btns.len);
}

test "Element - querySelector .class uses class_map" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("class", "btn");
    _ = try root.prototype.appendChild(&button.prototype);

    // querySelector(".class") should use O(k) class_map lookup
    const found = try root.querySelector(allocator, ".btn");
    try std.testing.expect(found != null);
    try std.testing.expect(found.? == button);
}

test "Element - class_map with multiple classes per element" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const button = try doc.createElement("button");
    try button.setAttribute("class", "btn btn-primary active");
    _ = try root.prototype.appendChild(&button.prototype);

    // Should find element by any of its classes
    const by_btn = root.queryByClass("btn");
    try std.testing.expect(by_btn == button);

    const by_primary = root.queryByClass("btn-primary");
    try std.testing.expect(by_primary == button);

    const by_active = root.queryByClass("active");
    try std.testing.expect(by_active == button);
}

test "Element - queryByClass only returns descendants" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const root = try doc.createElement("html");
    _ = try doc.prototype.appendChild(&root.prototype);

    const div = try doc.createElement("div");
    try div.setAttribute("class", "container");
    _ = try root.prototype.appendChild(&div.prototype);

    // Querying from div for "container" should not find itself
    const found = div.queryByClass("container");
    try std.testing.expect(found == null);
}

test "Element - toggleAttribute basic toggle" {
    const allocator = std.testing.allocator;
    const elem = try Element.create(allocator, "button");
    defer elem.prototype.release();

    // Initially no disabled attribute
    try std.testing.expect(!elem.hasAttribute("disabled"));

    // Toggle adds attribute
    const added = try elem.toggleAttribute("disabled", null);
    try std.testing.expect(added);
    try std.testing.expect(elem.hasAttribute("disabled"));

    // Toggle removes attribute
    const removed = try elem.toggleAttribute("disabled", null);
    try std.testing.expect(!removed);
    try std.testing.expect(!elem.hasAttribute("disabled"));
}

test "Element - toggleAttribute with force parameter" {
    const allocator = std.testing.allocator;
    const elem = try Element.create(allocator, "button");
    defer elem.prototype.release();

    // Force add (attribute not present)
    const forced_add = try elem.toggleAttribute("disabled", true);
    try std.testing.expect(forced_add);
    try std.testing.expect(elem.hasAttribute("disabled"));

    // Force add again (attribute already present) - should remain true
    const still_present = try elem.toggleAttribute("disabled", true);
    try std.testing.expect(still_present);
    try std.testing.expect(elem.hasAttribute("disabled"));

    // Force remove
    const forced_remove = try elem.toggleAttribute("disabled", false);
    try std.testing.expect(!forced_remove);
    try std.testing.expect(!elem.hasAttribute("disabled"));

    // Force remove again (attribute not present) - should remain false
    const still_absent = try elem.toggleAttribute("disabled", false);
    try std.testing.expect(!still_absent);
    try std.testing.expect(!elem.hasAttribute("disabled"));
}

test "Element - toggleAttribute with empty value" {
    const allocator = std.testing.allocator;
    const elem = try Element.create(allocator, "button");
    defer elem.prototype.release();

    // Toggle adds attribute with empty value
    _ = try elem.toggleAttribute("disabled", null);
    const value = elem.getAttribute("disabled");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("", value.?);
}

test "Element - children returns empty collection" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const collection = parent.children();
    try std.testing.expectEqual(@as(usize, 0), collection.length());
}

test "Element - children excludes non-element nodes" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    // Add mixed children: element, text, element, comment, element
    const elem1 = try doc.createElement("elem1");
    _ = try parent.prototype.appendChild(&elem1.prototype);

    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);

    const elem2 = try doc.createElement("elem2");
    _ = try parent.prototype.appendChild(&elem2.prototype);

    const comment = try doc.createComment("comment");
    _ = try parent.prototype.appendChild(&comment.prototype);

    const elem3 = try doc.createElement("elem3");
    _ = try parent.prototype.appendChild(&elem3.prototype);

    // children should only include elements
    const collection = parent.children();
    try std.testing.expectEqual(@as(usize, 3), collection.length());

    try std.testing.expectEqualStrings("elem1", collection.item(0).?.tag_name);
    try std.testing.expectEqualStrings("elem2", collection.item(1).?.tag_name);
    try std.testing.expectEqualStrings("elem3", collection.item(2).?.tag_name);
}

test "Element - children is live collection" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();

    const collection = parent.children();

    // Initially empty
    try std.testing.expectEqual(@as(usize, 0), collection.length());

    // Add element - collection updates
    const child1 = try doc.createElement("child1");
    _ = try parent.prototype.appendChild(&child1.prototype);
    try std.testing.expectEqual(@as(usize, 1), collection.length());

    // Add text - collection does NOT update
    const text = try doc.createTextNode("text");
    _ = try parent.prototype.appendChild(&text.prototype);
    try std.testing.expectEqual(@as(usize, 1), collection.length());

    // Add another element - collection updates
    const child2 = try doc.createElement("child2");
    _ = try parent.prototype.appendChild(&child2.prototype);
    try std.testing.expectEqual(@as(usize, 2), collection.length());

    // Remove element - collection updates
    _ = try parent.prototype.removeChild(&child1.prototype);
    child1.prototype.release(); // Manual release for removed node
    try std.testing.expectEqual(@as(usize, 1), collection.length());
    try std.testing.expectEqualStrings("child2", collection.item(0).?.tag_name);
}

test "Element - getElementsByTagName basic" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "root");
    defer root.prototype.release();

    const widget1 = try Element.create(allocator, "widget");
    _ = try root.prototype.appendChild(&widget1.prototype);

    const widget2 = try Element.create(allocator, "widget");
    _ = try root.prototype.appendChild(&widget2.prototype);

    const container = try Element.create(allocator, "container");
    _ = try root.prototype.appendChild(&container.prototype);

    // Get all widgets
    const widgets = root.getElementsByTagName("widget");
    try std.testing.expectEqual(@as(usize, 2), widgets.length());
    try std.testing.expect(widgets.item(0).? == widget1);
    try std.testing.expect(widgets.item(1).? == widget2);

    // Get all containers
    const containers = root.getElementsByTagName("container");
    try std.testing.expectEqual(@as(usize, 1), containers.length());
    try std.testing.expect(containers.item(0).? == container);

    // Not found
    const panels = root.getElementsByTagName("panel");
    try std.testing.expectEqual(@as(usize, 0), panels.length());
}

test "Element - getElementsByTagName nested" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "root");
    defer root.prototype.release();

    const container1 = try Element.create(allocator, "container");
    _ = try root.prototype.appendChild(&container1.prototype);

    const widget1 = try Element.create(allocator, "widget");
    _ = try container1.prototype.appendChild(&widget1.prototype);

    const container2 = try Element.create(allocator, "container");
    _ = try root.prototype.appendChild(&container2.prototype);

    const widget2 = try Element.create(allocator, "widget");
    _ = try container2.prototype.appendChild(&widget2.prototype);

    // Get all widgets from root
    const all_widgets = root.getElementsByTagName("widget");
    try std.testing.expectEqual(@as(usize, 2), all_widgets.length());

    // Get widgets from first container only
    const container1_widgets = container1.getElementsByTagName("widget");
    try std.testing.expectEqual(@as(usize, 1), container1_widgets.length());
    try std.testing.expect(container1_widgets.item(0).? == widget1);
}

test "Element - getElementsByClassName basic" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "root");
    defer root.prototype.release();

    const widget1 = try Element.create(allocator, "widget");
    try widget1.setAttribute("class", "primary active");
    _ = try root.prototype.appendChild(&widget1.prototype);

    const widget2 = try Element.create(allocator, "widget");
    try widget2.setAttribute("class", "primary");
    _ = try root.prototype.appendChild(&widget2.prototype);

    const container = try Element.create(allocator, "container");
    try container.setAttribute("class", "secondary");
    _ = try root.prototype.appendChild(&container.prototype);

    // Get all "primary" elements
    const primaries = root.getElementsByClassName("primary");
    try std.testing.expectEqual(@as(usize, 2), primaries.length());
    try std.testing.expect(primaries.item(0).? == widget1);
    try std.testing.expect(primaries.item(1).? == widget2);

    // Get all "active" elements
    const actives = root.getElementsByClassName("active");
    try std.testing.expectEqual(@as(usize, 1), actives.length());
    try std.testing.expect(actives.item(0).? == widget1);

    // Get all "secondary" elements
    const secondaries = root.getElementsByClassName("secondary");
    try std.testing.expectEqual(@as(usize, 1), secondaries.length());
    try std.testing.expect(secondaries.item(0).? == container);

    // Not found
    const notfound = root.getElementsByClassName("notfound");
    try std.testing.expectEqual(@as(usize, 0), notfound.length());
}

test "Element - getElementsByClassName nested" {
    const allocator = std.testing.allocator;

    const root = try Element.create(allocator, "root");
    defer root.prototype.release();

    const container1 = try Element.create(allocator, "container");
    try container1.setAttribute("class", "group");
    _ = try root.prototype.appendChild(&container1.prototype);

    const widget1 = try Element.create(allocator, "widget");
    try widget1.setAttribute("class", "item");
    _ = try container1.prototype.appendChild(&widget1.prototype);

    const container2 = try Element.create(allocator, "container");
    try container2.setAttribute("class", "group");
    _ = try root.prototype.appendChild(&container2.prototype);

    const widget2 = try Element.create(allocator, "widget");
    try widget2.setAttribute("class", "item");
    _ = try container2.prototype.appendChild(&widget2.prototype);

    // Get all "item" elements from root
    const all_items = root.getElementsByClassName("item");
    try std.testing.expectEqual(@as(usize, 2), all_items.length());

    // Get "item" elements from first container only
    const container1_items = container1.getElementsByClassName("item");
    try std.testing.expectEqual(@as(usize, 1), container1_items.length());
    try std.testing.expect(container1_items.item(0).? == widget1);
}

// ============================================================================
// Namespace Attribute Tests (Phase 15)
// ============================================================================

test "setAttributeNS and getAttributeNS basic usage" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set namespaced attribute
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");

    // Get by namespace and local name
    const value = elem.getAttributeNS(xml_ns, "lang");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("en", value.?);
}

test "getAttributeNS returns null for non-existent attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Get non-existent attribute
    const value = elem.getAttributeNS(xml_ns, "lang");
    try std.testing.expect(value == null);
}

test "setAttributeNS with null namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Set attribute with null namespace
    try elem.setAttributeNS(null, "attr", "value");

    // Get by null namespace
    const value = elem.getAttributeNS(null, "attr");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("value", value.?);
}

test "hasAttributeNS checks namespace and local name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set attribute
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");

    // Check existence
    try std.testing.expect(elem.hasAttributeNS(xml_ns, "lang"));
    try std.testing.expect(!elem.hasAttributeNS(xml_ns, "space"));
    try std.testing.expect(!elem.hasAttributeNS(null, "lang")); // Different namespace
}

test "removeAttributeNS removes namespaced attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set and verify
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");
    try std.testing.expect(elem.hasAttributeNS(xml_ns, "lang"));

    // Remove
    elem.removeAttributeNS(xml_ns, "lang");

    // Verify removed
    try std.testing.expect(!elem.hasAttributeNS(xml_ns, "lang"));
    try std.testing.expect(elem.getAttributeNS(xml_ns, "lang") == null);
}

test "namespaced and non-namespaced attributes are separate" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set both namespaced and non-namespaced attributes with same local name
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");
    try elem.setAttributeNS(null, "lang", "fr");

    // Both should exist independently
    try std.testing.expectEqualStrings("en", elem.getAttributeNS(xml_ns, "lang").?);
    try std.testing.expectEqualStrings("fr", elem.getAttributeNS(null, "lang").?);

    // Remove one shouldn't affect the other
    elem.removeAttributeNS(xml_ns, "lang");
    try std.testing.expect(elem.getAttributeNS(xml_ns, "lang") == null);
    try std.testing.expectEqualStrings("fr", elem.getAttributeNS(null, "lang").?);
}

test "setAttributeNS updates existing attribute" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set initial value
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");
    try std.testing.expectEqualStrings("en", elem.getAttributeNS(xml_ns, "lang").?);

    // Update value
    try elem.setAttributeNS(xml_ns, "xml:lang", "fr");
    try std.testing.expectEqualStrings("fr", elem.getAttributeNS(xml_ns, "lang").?);

    // Should still only have one attribute with this namespace+localName
    // (This is implicitly tested by the fact that we get the new value)
}

test "multiple namespaced attributes" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";
    const custom_ns = "http://example.com/custom";

    // Set multiple attributes with different namespaces
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");
    try elem.setAttributeNS(custom_ns, "custom:attr", "value");
    try elem.setAttributeNS(null, "regular", "normal");

    // Verify all exist
    try std.testing.expectEqualStrings("en", elem.getAttributeNS(xml_ns, "lang").?);
    try std.testing.expectEqualStrings("value", elem.getAttributeNS(custom_ns, "attr").?);
    try std.testing.expectEqualStrings("normal", elem.getAttributeNS(null, "regular").?);
}

// ============================================================================
// Namespace Validation Tests
// ============================================================================

test "setAttributeNS validates xml prefix requires XML namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Invalid: xml prefix with wrong namespace
    const result = elem.setAttributeNS("http://example.com", "xml:lang", "en");
    try std.testing.expectError(error.NamespaceError, result);
}

test "setAttributeNS validates xmlns prefix requires XMLNS namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Invalid: xmlns prefix with wrong namespace
    const result = elem.setAttributeNS("http://example.com", "xmlns:custom", "value");
    try std.testing.expectError(error.NamespaceError, result);
}

test "setAttributeNS validates invalid characters" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Invalid: starts with digit
    const result1 = elem.setAttributeNS(null, "9invalid", "value");
    try std.testing.expectError(error.InvalidCharacterError, result1);

    // Invalid: contains space
    const result2 = elem.setAttributeNS(null, "invalid name", "value");
    try std.testing.expectError(error.InvalidCharacterError, result2);

    // Invalid: empty name
    const result3 = elem.setAttributeNS(null, "", "value");
    try std.testing.expectError(error.InvalidCharacterError, result3);
}

test "setAttributeNS allows valid xml namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Valid: xml prefix with XML namespace
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");
    try std.testing.expectEqualStrings("en", elem.getAttributeNS(xml_ns, "lang").?);
}

test "setAttributeNS allows valid xmlns namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xmlns_ns = "http://www.w3.org/2000/xmlns/";

    // Valid: xmlns prefix with XMLNS namespace
    try elem.setAttributeNS(xmlns_ns, "xmlns:custom", "http://example.com");
    try std.testing.expectEqualStrings("http://example.com", elem.getAttributeNS(xmlns_ns, "custom").?);
}

test "Element namespace fields initialized correctly for non-namespaced element" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "div");
    defer elem.prototype.release();

    // Non-namespaced elements should have null namespace and prefix
    try std.testing.expectEqual(@as(?[]const u8, null), elem.namespace_uri);
    try std.testing.expectEqual(@as(?[]const u8, null), elem.prefix);

    // local_name should equal tag_name for non-namespaced elements
    try std.testing.expectEqualStrings("div", elem.local_name);
    try std.testing.expectEqualStrings("div", elem.tag_name);
    try std.testing.expectEqualStrings("div", elem.localName());
}

test "Element namespace fields via Document.createElement" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("span");
    defer elem.prototype.release();

    // createElement creates non-namespaced elements
    try std.testing.expectEqual(@as(?[]const u8, null), elem.namespace_uri);
    try std.testing.expectEqual(@as(?[]const u8, null), elem.prefix);
    try std.testing.expectEqualStrings("span", elem.local_name);
    try std.testing.expectEqualStrings("span", elem.tag_name);
}

test "Element.localName() returns local_name field" {
    const allocator = std.testing.allocator;

    const elem = try Element.create(allocator, "article");
    defer elem.prototype.release();

    const local = elem.localName();
    try std.testing.expectEqualStrings("article", local);
    try std.testing.expectEqual(elem.local_name.ptr, local.ptr); // Should be same pointer
}

// === Namespace Attribute Methods Tests ===

test "Element.setAttributeNS and getAttributeNS basic" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set namespaced attribute
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");

    // Get by namespace and local name
    const value = elem.getAttributeNS(xml_ns, "lang");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("en", value.?);
}

test "Element.setAttributeNS with different prefixes same namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set with "xml" prefix
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");

    // Try to set with "foo" prefix - should update same attribute
    try elem.setAttributeNS(xml_ns, "foo:lang", "fr");

    // Getting by (namespace, localName) should return updated value
    const value = elem.getAttributeNS(xml_ns, "lang");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("fr", value.?);
}

test "Element.hasAttributeNS" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";
    const svg_ns = "http://www.w3.org/2000/svg";

    // Initially no attributes
    try std.testing.expect(!elem.hasAttributeNS(xml_ns, "lang"));

    // Set attribute
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");

    // Now it exists
    try std.testing.expect(elem.hasAttributeNS(xml_ns, "lang"));

    // Different namespace
    try std.testing.expect(!elem.hasAttributeNS(svg_ns, "lang"));

    // Different local name
    try std.testing.expect(!elem.hasAttributeNS(xml_ns, "id"));
}

test "Element.removeAttributeNS" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set attribute
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");
    try std.testing.expect(elem.hasAttributeNS(xml_ns, "lang"));

    // Remove it
    elem.removeAttributeNS(xml_ns, "lang");

    // Should be gone
    try std.testing.expect(!elem.hasAttributeNS(xml_ns, "lang"));
    try std.testing.expect(elem.getAttributeNS(xml_ns, "lang") == null);
}

// Fixed: getAttributeNodeNS now preserves namespace info in returned Attr
test "Element.getAttributeNodeNS" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xlink_ns = "http://www.w3.org/1999/xlink";

    // Set attribute
    try elem.setAttributeNS(xlink_ns, "xlink:href", "#target");

    // Get Attr node
    const attr = try elem.getAttributeNodeNS(xlink_ns, "href");
    try std.testing.expect(attr != null);
    defer attr.?.node.release(); // Must release returned Attr node

    try std.testing.expectEqualStrings("#target", attr.?.value());
    try std.testing.expectEqualStrings("href", attr.?.local_name);

    // Verify namespace_uri is preserved
    try std.testing.expect(attr.?.namespace_uri != null);
    try std.testing.expectEqualStrings(xlink_ns, attr.?.namespace_uri.?);

    // Verify prefix is preserved
    try std.testing.expect(attr.?.prefix != null);
    try std.testing.expectEqualStrings("xlink", attr.?.prefix.?);
}

test "Element.setAttributeNodeNS" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xlink_ns = "http://www.w3.org/1999/xlink";

    // Create namespaced Attr
    const attr = try doc.createAttributeNS(xlink_ns, "xlink:href");
    defer attr.node.release();
    try attr.setValue("#target");

    // Set on element
    const old_attr = try elem.setAttributeNodeNS(attr);
    try std.testing.expect(old_attr == null); // No previous attribute

    // Verify it's set
    try std.testing.expectEqualStrings("#target", elem.getAttributeNS(xlink_ns, "href").?);

    // Verify attr is owned by element
    try std.testing.expect(attr.owner_element == elem);
}

test "Element namespace attributes mixed with non-namespaced" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    const xml_ns = "http://www.w3.org/XML/1998/namespace";

    // Set non-namespaced attribute
    try elem.setAttribute("id", "foo");

    // Set namespaced attribute
    try elem.setAttributeNS(xml_ns, "xml:lang", "en");

    // Set another non-namespaced attribute
    try elem.setAttribute("class", "bar");

    // Both types should work
    try std.testing.expectEqualStrings("foo", elem.getAttribute("id").?);
    try std.testing.expectEqualStrings("en", elem.getAttributeNS(xml_ns, "lang").?);
    try std.testing.expectEqualStrings("bar", elem.getAttribute("class").?);
}

test "Element.setAttributeNS with null namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const elem = try doc.createElement("element");
    defer elem.prototype.release();

    // Set attribute with null namespace
    try elem.setAttributeNS(null, "custom", "value");

    // Should be retrievable by null namespace
    const value = elem.getAttributeNS(null, "custom");
    try std.testing.expect(value != null);
    try std.testing.expectEqualStrings("value", value.?);

    // Should also work with regular getAttribute
    try std.testing.expectEqualStrings("value", elem.getAttribute("custom").?);
}

// ============================================================================
// getElementsByTagNameNS Tests
// ============================================================================

test "Document.getElementsByTagNameNS basic functionality" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";
    const xlink_ns = "http://www.w3.org/1999/xlink";

    // Create root container
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create some namespaced elements
    const circle1 = try doc.createElementNS(svg_ns, "circle");
    const circle2 = try doc.createElementNS(svg_ns, "circle");
    const rect = try doc.createElementNS(svg_ns, "rect");
    const link = try doc.createElementNS(xlink_ns, "link");

    _ = try root.prototype.appendChild(&circle1.prototype);
    _ = try root.prototype.appendChild(&circle2.prototype);
    _ = try root.prototype.appendChild(&rect.prototype);
    _ = try root.prototype.appendChild(&link.prototype);

    // Find all SVG circle elements
    const circles = doc.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 2), circles.length());

    // Find all SVG rect elements
    const rects = doc.getElementsByTagNameNS(svg_ns, "rect");
    try std.testing.expectEqual(@as(usize, 1), rects.length());

    // Find all xlink elements
    const links = doc.getElementsByTagNameNS(xlink_ns, "link");
    try std.testing.expectEqual(@as(usize, 1), links.length());

    // No matches
    const paths = doc.getElementsByTagNameNS(svg_ns, "path");
    try std.testing.expectEqual(@as(usize, 0), paths.length());
}

test "Document.getElementsByTagNameNS wildcard namespace" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";
    const mathml_ns = "http://www.w3.org/1998/Math/MathML";

    // Create root container
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create elements with same local name in different namespaces
    const svg_circle = try doc.createElementNS(svg_ns, "circle");
    const mathml_circle = try doc.createElementNS(mathml_ns, "circle");
    const no_ns_circle = try doc.createElement("circle");

    _ = try root.prototype.appendChild(&svg_circle.prototype);
    _ = try root.prototype.appendChild(&mathml_circle.prototype);
    _ = try root.prototype.appendChild(&no_ns_circle.prototype);

    // Wildcard namespace matches ALL circles regardless of namespace
    const all_circles = doc.getElementsByTagNameNS("*", "circle");
    try std.testing.expectEqual(@as(usize, 3), all_circles.length());

    // Specific namespace matches only that namespace
    const svg_only = doc.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 1), svg_only.length());

    const mathml_only = doc.getElementsByTagNameNS(mathml_ns, "circle");
    try std.testing.expectEqual(@as(usize, 1), mathml_only.length());

    // Null namespace matches only elements with no namespace
    const no_ns_only = doc.getElementsByTagNameNS(null, "circle");
    try std.testing.expectEqual(@as(usize, 1), no_ns_only.length());
}

test "Document.getElementsByTagNameNS wildcard local name" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";

    // Create root container
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create multiple SVG elements
    const circle = try doc.createElementNS(svg_ns, "circle");
    const rect = try doc.createElementNS(svg_ns, "rect");
    const path = try doc.createElementNS(svg_ns, "path");

    _ = try root.prototype.appendChild(&circle.prototype);
    _ = try root.prototype.appendChild(&rect.prototype);
    _ = try root.prototype.appendChild(&path.prototype);

    // Wildcard local name matches all elements in SVG namespace
    const all_svg = doc.getElementsByTagNameNS(svg_ns, "*");
    try std.testing.expectEqual(@as(usize, 3), all_svg.length());
}

test "Document.getElementsByTagNameNS double wildcard" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";

    // Create root container
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create elements with different namespaces
    const svg_circle = try doc.createElementNS(svg_ns, "circle");
    const div = try doc.createElement("div");
    const span = try doc.createElement("span");

    _ = try root.prototype.appendChild(&svg_circle.prototype);
    _ = try root.prototype.appendChild(&div.prototype);
    _ = try root.prototype.appendChild(&span.prototype);

    // Double wildcard matches ALL elements (including root)
    const all_elements = doc.getElementsByTagNameNS("*", "*");
    try std.testing.expectEqual(@as(usize, 4), all_elements.length());
}

test "Element.getElementsByTagNameNS scoped search" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";

    // Create nested structure
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const container1 = try doc.createElement("container");
    _ = try root.prototype.appendChild(&container1.prototype);

    const svg1 = try doc.createElementNS(svg_ns, "circle");
    const svg2 = try doc.createElementNS(svg_ns, "circle");
    _ = try container1.prototype.appendChild(&svg1.prototype);
    _ = try container1.prototype.appendChild(&svg2.prototype);

    const container2 = try doc.createElement("container");
    _ = try root.prototype.appendChild(&container2.prototype);

    const svg3 = try doc.createElementNS(svg_ns, "rect");
    _ = try container2.prototype.appendChild(&svg3.prototype);

    // Search from root finds all SVG circles
    const all_circles = root.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 2), all_circles.length());

    // Search from container1 finds only its circles
    const container1_circles = container1.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 2), container1_circles.length());

    // Search from container2 finds no circles (has rect instead)
    const container2_circles = container2.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 0), container2_circles.length());

    // Search for all SVG elements from root
    const all_svg = root.getElementsByTagNameNS(svg_ns, "*");
    try std.testing.expectEqual(@as(usize, 3), all_svg.length());
}

test "getElementsByTagNameNS is live" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";

    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Get collection before adding elements
    const circles = root.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 0), circles.length());

    // Add an element - collection should update
    const circle1 = try doc.createElementNS(svg_ns, "circle");
    _ = try root.prototype.appendChild(&circle1.prototype);
    try std.testing.expectEqual(@as(usize, 1), circles.length());

    // Add another element - collection should update again
    const circle2 = try doc.createElementNS(svg_ns, "circle");
    _ = try root.prototype.appendChild(&circle2.prototype);
    try std.testing.expectEqual(@as(usize, 2), circles.length());

    // Remove an element - collection should update
    const removed = try root.prototype.removeChild(&circle1.prototype);
    defer removed.release();
    try std.testing.expectEqual(@as(usize, 1), circles.length());
}

test "getElementsByTagNameNS with prefixed elements" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";

    // Create root container
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    // Create elements with prefixes
    const circle1 = try doc.createElementNS(svg_ns, "svg:circle");
    const circle2 = try doc.createElementNS(svg_ns, "circle");

    _ = try root.prototype.appendChild(&circle1.prototype);
    _ = try root.prototype.appendChild(&circle2.prototype);

    // Both should match by (namespace, localName) regardless of prefix
    const circles = doc.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 2), circles.length());
}

test "getElementsByTagNameNS case sensitive" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";

    // Create root container
    const root = try doc.createElement("root");
    _ = try doc.prototype.appendChild(&root.prototype);

    const circle_lower = try doc.createElementNS(svg_ns, "circle");
    const circle_upper = try doc.createElementNS(svg_ns, "CIRCLE");

    _ = try root.prototype.appendChild(&circle_lower.prototype);
    _ = try root.prototype.appendChild(&circle_upper.prototype);

    // Lowercase search finds only lowercase
    const lower_results = doc.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 1), lower_results.length());

    // Uppercase search finds only uppercase
    const upper_results = doc.getElementsByTagNameNS(svg_ns, "CIRCLE");
    try std.testing.expectEqual(@as(usize, 1), upper_results.length());
}

test "getElementsByTagNameNS empty document" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const svg_ns = "http://www.w3.org/2000/svg";

    // Search in empty document
    const results = doc.getElementsByTagNameNS(svg_ns, "circle");
    try std.testing.expectEqual(@as(usize, 0), results.length());

    // Wildcard search in empty document
    const all = doc.getElementsByTagNameNS("*", "*");
    try std.testing.expectEqual(@as(usize, 0), all.length());
}

// ============================================================================
// ParentNode.moveBefore() Tests
// ============================================================================

test "Element.moveBefore - move child to different position" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();
    const child1 = try doc.createElement("first");
    const child2 = try doc.createElement("second");
    const child3 = try doc.createElement("third");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Order: first, second, third
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), parent.prototype.first_child);
    try std.testing.expectEqual(@as(?*Node, &child3.prototype), parent.prototype.last_child);

    // Move child3 before child1
    try parent.moveBefore(&child3.prototype, &child1.prototype);

    // Order should now be: third, first, second
    try std.testing.expectEqual(@as(?*Node, &child3.prototype), parent.prototype.first_child);
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), child3.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), child1.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, null), child2.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), parent.prototype.last_child);

    // Verify parent relationships unchanged
    try std.testing.expectEqual(@as(?*Node, &parent.prototype), child1.prototype.parent_node);
    try std.testing.expectEqual(@as(?*Node, &parent.prototype), child2.prototype.parent_node);
    try std.testing.expectEqual(@as(?*Node, &parent.prototype), child3.prototype.parent_node);
}

test "Element.moveBefore - move to end with null child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();
    const child1 = try doc.createElement("first");
    const child2 = try doc.createElement("second");
    const child3 = try doc.createElement("third");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Move child1 to end (child = null)
    try parent.moveBefore(&child1.prototype, null);

    // Order should now be: second, third, first
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), parent.prototype.first_child);
    try std.testing.expectEqual(@as(?*Node, &child3.prototype), child2.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), child3.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, null), child1.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), parent.prototype.last_child);
}

test "Element.moveBefore - no-op when node equals child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();
    const child1 = try doc.createElement("first");
    const child2 = try doc.createElement("second");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    // Move child1 before itself (no-op)
    try parent.moveBefore(&child1.prototype, &child1.prototype);

    // Order unchanged: first, second
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), parent.prototype.first_child);
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), child1.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), parent.prototype.last_child);
}

test "Element.moveBefore - error when node not a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();
    const child = try doc.createElement("child");
    const orphan = try doc.createElement("orphan");
    defer orphan.prototype.release();

    _ = try parent.prototype.appendChild(&child.prototype);

    // Try to move orphan (not a child of parent)
    const result = parent.moveBefore(&orphan.prototype, &child.prototype);
    try std.testing.expectError(error.NotFoundError, result);
}

test "Element.moveBefore - error when child not a child" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();
    const child = try doc.createElement("child");
    const other = try doc.createElement("other");
    defer other.prototype.release();

    _ = try parent.prototype.appendChild(&child.prototype);

    // Try to move child before 'other' (not a child of parent)
    const result = parent.moveBefore(&child.prototype, &other.prototype);
    try std.testing.expectError(error.NotFoundError, result);
}

test "Element.moveBefore - move first child to middle" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();
    const child1 = try doc.createElement("first");
    const child2 = try doc.createElement("second");
    const child3 = try doc.createElement("third");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Move child1 before child3
    try parent.moveBefore(&child1.prototype, &child3.prototype);

    // Order should now be: second, first, third
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), parent.prototype.first_child);
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), child2.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child3.prototype), child1.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child3.prototype), parent.prototype.last_child);
}

test "Element.moveBefore - move last child to beginning" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    defer parent.prototype.release();
    const child1 = try doc.createElement("first");
    const child2 = try doc.createElement("second");
    const child3 = try doc.createElement("third");

    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);
    _ = try parent.prototype.appendChild(&child3.prototype);

    // Move child3 before child1
    try parent.moveBefore(&child3.prototype, &child1.prototype);

    // Order should now be: third, first, second
    try std.testing.expectEqual(@as(?*Node, &child3.prototype), parent.prototype.first_child);
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), child3.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), child1.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), parent.prototype.last_child);
}

test "DocumentFragment.moveBefore - works on DocumentFragment" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fragment = try doc.createDocumentFragment();
    defer fragment.prototype.release();
    const child1 = try doc.createElement("first");
    const child2 = try doc.createElement("second");

    _ = try fragment.prototype.appendChild(&child1.prototype);
    _ = try fragment.prototype.appendChild(&child2.prototype);

    // Move child2 before child1
    try fragment.moveBefore(&child2.prototype, &child1.prototype);

    // Order should now be: second, first
    try std.testing.expectEqual(@as(?*Node, &child2.prototype), fragment.prototype.first_child);
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), child2.prototype.next_sibling);
    try std.testing.expectEqual(@as(?*Node, &child1.prototype), fragment.prototype.last_child);
}

test "moveBefore - state preservation (connectedness)" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("parent");
    const child1 = try doc.createElement("first");
    const child2 = try doc.createElement("second");

    // Append to document (connected)
    _ = try doc.prototype.appendChild(&parent.prototype);
    _ = try parent.prototype.appendChild(&child1.prototype);
    _ = try parent.prototype.appendChild(&child2.prototype);

    // Verify connected
    try std.testing.expect(child1.prototype.isConnected());
    try std.testing.expect(child2.prototype.isConnected());

    // Move child2 before child1
    try parent.moveBefore(&child2.prototype, &child1.prototype);

    // Both should still be connected
    try std.testing.expect(child1.prototype.isConnected());
    try std.testing.expect(child2.prototype.isConnected());

    // Document should still be owner
    try std.testing.expectEqual(@as(?*Node, &doc.prototype), child1.prototype.owner_document);
    try std.testing.expectEqual(@as(?*Node, &doc.prototype), child2.prototype.owner_document);
}

test "Element delegation - clean WHATWG-compliant API" {
    const allocator = std.testing.allocator;

    const doc = try Document.init(allocator);
    defer doc.release();

    const parent = try doc.createElement("div");
    const child = try doc.createElement("span");
    const text = try doc.createTextNode("Hello");

    // NEW API: Clean, WHATWG-compliant (no .prototype needed)
    _ = try parent.appendChild(&child.prototype);
    _ = try child.appendChild(&text.prototype);

    // All delegation methods work
    try std.testing.expect(parent.hasChildNodes());
    try std.testing.expect(child.hasChildNodes());
    try std.testing.expectEqual(&child.prototype, parent.firstChild().?);
    try std.testing.expectEqual(&text.prototype, child.firstChild().?);

    // EventTarget delegation works too
    var called = false;
    const callback = struct {
        fn handle(event: *Event, ctx: *anyopaque) void {
            _ = event;
            const flag = @as(*bool, @ptrCast(@alignCast(ctx)));
            flag.* = true;
        }
    }.handle;

    try parent.addEventListener("test", callback, &called, false, false, false, null);
    var event = Event.init("test", .{});
    _ = try parent.dispatchEvent(&event);
    try std.testing.expect(called);
}
