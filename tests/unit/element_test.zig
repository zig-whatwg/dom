const std = @import("std");
const dom = @import("dom");

// Import all commonly used types
const Node = dom.Node;
const NodeType = dom.NodeType;
const Element = dom.Element;
const Text = dom.Text;
const Document = dom.Document;
const BloomFilter = dom.BloomFilter;
const AttributeMap = dom.AttributeMap;

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
